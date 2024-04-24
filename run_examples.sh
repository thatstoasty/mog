#!/bin/bash
mkdir ./temp
mojo package mog -I ./external -o ./temp/mog.mojopkg

echo -e "Building binaries for all examples...\n"
mojo build examples/readme/basic.mojo -o temp/basic
mojo build examples/readme/layout.mojo -o temp/layout
mojo build examples/table/ansi.mojo -o temp/ansi

echo -e "Executing examples...\n"
cd temp
./basic
./layout
./ansi

cd ..
rm -R ./temp
