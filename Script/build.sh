#!/bin/bash

set -e

cd $(dirname $0)/..

if [ ! -f .root ]; then
    echo "[*] malformated project structure"
    exit 1
fi

if [ -z "$1" ]; then
    LIB_TAG=$(curl -s -L -o /dev/null -w "%{url_effective}\n" https://github.com/nih-at/libzip/releases/latest | sed 's|.*/tag/\(.*\)|\1|')

    if [ -z "$LIB_TAG" ]; then
        echo "[*] failed to get latest library tag"
        exit 1
    fi
else
    LIB_TAG=$1
fi
echo "[*] building for libzip tag: $LIB_TAG"

XCFRAMEWORK_PATH_ZIP="$(pwd)/build/libzip.xcframework.zip"
mkdir -p "$(dirname "$XCFRAMEWORK_PATH_ZIP")"
echo "[*] output: $XCFRAMEWORK_PATH_ZIP"

./Script/build-xcframework.sh $LIB_TAG $XCFRAMEWORK_PATH_ZIP
./Script/build-manifest.sh $XCFRAMEWORK_PATH_ZIP

echo "[*] done $(basename $0)"
