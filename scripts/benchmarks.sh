#!/bin/bash

TEMP_DIR=~/tmp
PACKAGE_NAME=mog
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and running benchmarks."
cp -R benchmarks/ $TEMP_DIR
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg

echo "[INFO] Running benchmarks..."
magic run mojo $TEMP_DIR/run.mojo

echo "[INFO] Cleaning up the benchmarks directory."
rm -R $TEMP_DIR
