#!/bin/bash
mkdir -p tmp

echo -e "Building mog package and copying tests."
./scripts/build.sh package
mv mog.mojopkg tmp/
cp -R tests/ tmp/tests/

echo -e "\nBuilding binaries for all examples."
pytest tmp/tests

echo -e "Cleaning up the test directory."
rm -R tmp
