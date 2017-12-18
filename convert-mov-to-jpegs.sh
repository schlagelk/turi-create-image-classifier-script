#!/bin/bash

set -e

if [ "$(uname)" != "Darwin" ]; then
    echo "I am only to be run on macOS!"
    exit 1;
fi

for file in *; do
    if [ ${file: -4} == ".MOV" ]; then
        echo "${file} found, will be converted into some training jpegs"
        dirname="${file%%.*}"
        echo "creating training images in $dirname for $file"
        mkdir -p turi_files/images-raw/$dirname
        mkdir -p training_images/$dirname
        # extract frames from each .mov
        ./extract-frames.swift -inputMoviePath $file -outputImagesPath turi_files/images-raw/$dirname/
        echo "Wih sips, downresing images"
        sips --resampleHeightWidthMax 640 turi_files/images-raw/$dirname/* --out training_images/$dirname/ 1>/dev/null  2>/dev/null
        echo "Number of $dirname images:"
        ls -1 training_images/$dirname/ | wc -l
        echo "Cleaning up now k thx bye"
        rm -rf turi_files
    fi
done
