#!/bin/sh -ue
#****h* utils/gen_man
# NAME
#  gen_man
# DESCRIPTION
#  Script to generate man pages using pandoc
# AUTHOR
#  Masaki Waga
# HISTORY
#   - 2024/06/29: initial version
# COPYRIGHT
#  Copyright (c) 2024 Masaki Waga
#  Released under the MIT license
#  https://opensource.org/licenses/mit-license.php
#
# USAGE
#  ./gen_man.sh
# PORTABILITY
#  pandoc is required to run this script
#
#******

cd "$(dirname "$0")" || exit 1

## Check if pandoc is installed
if ! command -v pandoc > /dev/null; then
    printf "pandoc is not installed. Please install pandocto run this script\n"
    exit 1
fi

## Generate target directory
mkdir -p ./man/

for file in ./*.sh; do
    title="$(basename "$file" .sh)"
    pandoc -s -V title:"$title" -V section:1 -V header:'FalCAuN-ARCH-COMP Utilities Manual' -V footer:'FalCAuN-ARCH-COMP' -f ./scrdoc/scrdoc.lua "$file" -o "./man/$title.1"
done

for file in ./*.awk; do
    title="$(basename "$file" .awk)"
    pandoc -s -V title:"$title" -V section:1 -V header:'FalCAuN-ARCH-COMP Utilities Manual' -V footer:'FalCAuN-ARCH-COMP' -f ./scrdoc/scrdoc.lua "$file" -o "./man/$title.1"
done
