#!/bin/bash
mkdir ./tmp
./scripts/build.sh package
mv mog.mojopkg tmp/

echo -e "Building binaries for all examples...\n"
mojo build examples/basic.mojo -o tmp/basic
mojo build examples/layout.mojo -o tmp/layout
mojo build examples/ansi.mojo -o tmp/ansi

echo -e "Executing examples...\n"
cd tmp
./basic
./layout
./ansi

cd ..
rm -R ./tmp
