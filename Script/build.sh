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

if [ -n "$2" ]; then
    DOWNLOAD_URL=$2
else
    DEFAULT_REPO_SLUG="${LIBZIP_SPM_REPO_SLUG:-Lakr233/libzip-spm}"
    REPO_SLUG=$(git config --get remote.origin.url | sed -E 's#(git@github.com:|https://github.com/|git://github.com/)([^/?]+/[^/.?]+)(\\.git)?/?(\\?.*)?$#\\2#')
    if [ -z "$REPO_SLUG" ]; then
        REPO_SLUG="$DEFAULT_REPO_SLUG"
        echo "[*] warning: failed to determine remote.origin.url, defaulting manifest download repo to $REPO_SLUG"
    fi
    STORAGE_RELEASE_TAG="storage.${LIB_TAG#v}"
    DOWNLOAD_URL="https://github.com/$REPO_SLUG/releases/download/$STORAGE_RELEASE_TAG/libzip.xcframework.zip"
fi
echo "[*] manifest download url: $DOWNLOAD_URL"

XCFRAMEWORK_PATH_ZIP="$(pwd)/build/libzip.xcframework.zip"
mkdir -p "$(dirname "$XCFRAMEWORK_PATH_ZIP")"
echo "[*] output: $XCFRAMEWORK_PATH_ZIP"

./Script/build-xcframework.sh $LIB_TAG $XCFRAMEWORK_PATH_ZIP
./Script/build-manifest.sh $XCFRAMEWORK_PATH_ZIP $DOWNLOAD_URL

echo "[*] done $(basename $0)"
