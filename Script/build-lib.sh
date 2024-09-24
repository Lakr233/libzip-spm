#!/bin/bash

set -e

cd $(dirname $0)/..
if [ ! -f .root ]; then
    echo "[*] malformated project structure"
    exit 1
fi
ROOT_DIR=$(pwd)

BEGIN_TIME=$(date +%s)
echo "========================================"
echo "[*] starting build $BEGIN_TIME"
echo "========================================"

SOURCE_DIR=$1
SDK_PLATFORM=$2
PLATFORM=$3
EFFECTIVE_PLATFORM_NAME=$4
ARCHS=$5
MIN_VERSION=$6
INSTALL_PREFIX=$7

rm -rf "$INSTALL_PREFIX" || true
mkdir -p "$INSTALL_PREFIX" || true

echo "[*] source dir: $SOURCE_DIR"
echo "[*] sdk platform: $SDK_PLATFORM"
echo "[*] platform: $PLATFORM"
echo "[*] effective platform name: $EFFECTIVE_PLATFORM_NAME"
echo "[*] archs: $ARCHS"
echo "[*] min version: $MIN_VERSION"
echo "[*] install prefix: $INSTALL_PREFIX"

TEMP_SRC_DIR="$ROOT_DIR/build/temp_src/$(uuidgen)"
echo "[*] duplicated source code to temp dir: $TEMP_SRC_DIR"
mkdir -p "$TEMP_SRC_DIR" || true
cp -r "$SOURCE_DIR" "$TEMP_SRC_DIR/src"
SOURCE_DIR="$TEMP_SRC_DIR/src"
DELIVERED_PREFIXS=()

function cleanup {
  echo "[*] removing temp dir: $TEMP_SRC_DIR"
  rm -rf "$TEMP_SRC_DIR" || true
  for PREFIX in "${DELIVERED_PREFIXS[@]}"
  do
    echo "[*] removing temp dir: $PREFIX"
    rm -rf "$PREFIX" || true
  done
}
trap cleanup EXIT

for ARCH in $ARCHS
do
  pushd $SOURCE_DIR > /dev/null
  git clean -fdx -f > /dev/null
  git reset --hard > /dev/null
  popd > /dev/null

  echo "========================================"
  echo "==> $SDK_PLATFORM $ARCH $EFFECTIVE_PLATFORM_NAME"
  echo "========================================"

  PREFIX_DIR="$INSTALL_PREFIX.$ARCH"
  rm -rf "$PREFIX_DIR" || true
  mkdir -p "$PREFIX_DIR" || true

  USE_MIN_VERSION=true
  if [[ "$EFFECTIVE_PLATFORM_NAME" == "MAC_CATALYST_13_1" ]]; then
    export CFLAGS="-target $ARCH-apple-ios13.1-macabi -Wno-overriding-t-option"
  fi
  if [[ "$EFFECTIVE_PLATFORM_NAME" == "VISION_NOT_PRO" ]]; then
    export CFLAGS="-target $ARCH-apple-xros$MIN_VERSION"
    USE_MIN_VERSION=false
  fi
  if [[ "$EFFECTIVE_PLATFORM_NAME" == "VISION_NOT_PRO_SIMULATOR" ]]; then
    export CFLAGS="-target $ARCH-apple-xros$MIN_VERSION-simulator"
    USE_MIN_VERSION=false
  fi

  export CROSS_TOP="$(xcode-select --print-path)/Platforms/$PLATFORM.platform/Developer"
  export CROSS_SDK="$PLATFORM.sdk"
  export SDKROOT="$CROSS_TOP/SDKs/$CROSS_SDK"
  export CC="$(xcrun --find clang)"

  if [[ ! -z "${CFLAGS}" ]]; then 
      echo "    CFLAGS: $CFLAGS"
  fi

  pushd $SOURCE_DIR > /dev/null
  mkdir build
  cd build

  cmake .. \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_INSTALL_PREFIX=$PREFIX_DIR \
      -DENABLE_ZSTD=OFF \
      -DBUILD_TOOLS=OFF \
      -DBUILD_REGRESS=OFF \
      -DBUILD_OSSFUZZ=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_DOC=OFF \
      -DCMAKE_OSX_ARCHITECTURES=$ARCH \
      -DCMAKE_OSX_SYSROOT=$SDKROOT \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=$MIN_VERSION \
      -DCMAKE_C_COMPILER="$CC" \
      -DCMAKE_SYSTEM_NAME=Darwin

  echo "[*] building..."
  make -j$(nproc) 

  echo "[*] installing to $PREFIX_DIR..."
  make install

  popd > /dev/null

  DELIVERED_PREFIXS+=("$INSTALL_PREFIX.$ARCH")
done

rm -rf "$INSTALL_PREFIX" || true
mkdir -p "$INSTALL_PREFIX" || true

echo "========================================"
echo "[*] creating fat binaries..."
echo "[*] install prefix: $INSTALL_PREFIX"

echo "[*] copying header from: ${ARCHS%% *}"
cp -r "${DELIVERED_PREFIXS[0]}/include" "$INSTALL_PREFIX/include"

echo "[*] searching for static libs..."
STATIC_LIBS=()
pushd ${DELIVERED_PREFIXS[0]}/lib > /dev/null
for file in $(find . -type f -name "*.a")
do
  if [[ "$file" == ./* ]]; then
    file=${file:2}
  fi
  STATIC_LIBS+=("$file")
  echo "[*] found static lib: $file"
done
popd > /dev/null

echo "[*] creating fat static libs..."
pushd "$INSTALL_PREFIX" > /dev/null
mkdir -p "lib" || true
pushd "lib" > /dev/null
USED_LIBS=()
for file in "${STATIC_LIBS[@]}"
do
  echo "[*] creating fat static lib: $file"
  lipo -create $(for PREFIX in "${DELIVERED_PREFIXS[@]}"; do echo "$PREFIX/lib/$file"; done) -output "$file"
  USED_LIBS+=("$file")
done
echo "[*] merging static libs..."
libtool -static -o "zip.a" "${USED_LIBS[@]}"
file zip.a
rm -rf "${USED_LIBS[@]}" || true
popd > /dev/null
popd > /dev/null

# generate module map located at $BUILT_PRODUCTS_DIR/include/LIB/module.modulemap
pushd "$INSTALL_PREFIX/include/" > /dev/null
mkdir -p "czip" || true
pushd "czip" > /dev/null

echo "[*] generating module map..."
HEADER_FILE_LIST=();
for file in $(find .. -type f -name "*.h");
do
  HEADER_FILE_LIST+=("$file");
done
IFS=$'\n' HEADER_FILE_LIST=($(sort <<<"${HEADER_FILE_LIST[*]}"))

echo "module czip {" >> module.modulemap
for file in "${HEADER_FILE_LIST[@]}"
do
  echo "    header \"$file\"" >> module.modulemap
done
echo "    export *" >> module.modulemap
echo "}" >> module.modulemap
find . -type d -empty -delete
popd > /dev/null
popd > /dev/null

ELAPSED_TIME=$(expr $(date +%s) - $BEGIN_TIME)
echo "========================================"
echo "[*] finished build in $ELAPSED_TIME sec"
echo "========================================"

echo "[*] done $(basename $0)"
