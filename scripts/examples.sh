#!/bin/bash

TEMP_DIR=~/tmp
PACKAGE_NAME=mog
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and example binaries."
cp -a examples/. $TEMP_DIR
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg
magic run mojo build $TEMP_DIR/basic.mojo -o $TEMP_DIR/basic
magic run mojo build $TEMP_DIR/layout.mojo -o $TEMP_DIR/layout
magic run mojo build $TEMP_DIR/ansi.mojo -o $TEMP_DIR/ansi
magic run mojo run $TEMP_DIR/pokemon.mojo # temporary, it segfaults otherwise
# magic run mojo build $TEMP_DIR/pokemon.mojo -o $TEMP_DIR/pokemon

echo "[INFO] Running examples..."
$TEMP_DIR/basic
$TEMP_DIR/layout
$TEMP_DIR/ansi
# $TEMP_DIR/pokemon

echo "[INFO] Cleaning up the example directory."
rm -R $TEMP_DIR
