#!/bin/bash

set -e

# some pretty colors
YEWOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [ "$(uname)" != "Darwin" ]; then
    echo "${RED}I am only to be run on macOS!"
    exit 1;
fi

for file in *; do
    if [ ${file: -4} == ".MOV" ]; then
        echo "${YEWOW}${file} found, lets make some jpegs${NC}"
        dirname="${file%%.*}"
        echo "creating training images in /$dirname for $file"
        mkdir -p turi_files/images-raw/$dirname
        mkdir -p training_images/$dirname
        # extract frames from each .mov
        ./extract-frames.swift -inputMoviePath $file -outputImagesPath turi_files/images-raw/$dirname/
        echo "with sips, downresing images"
        sips --resampleHeightWidthMax 640 turi_files/images-raw/$dirname/* --out training_images/$dirname/ 1>/dev/null  2>/dev/null
        echo "number of $dirname images:"
        ls -1 training_images/$dirname/ | wc -l
    fi
done

echo "${GREEN}cleaning up now, k thx bye${NC}"
rm -rf turi_files
