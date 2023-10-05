#!/bin/bash
set -e

function build() {
  xcrun clang main.m -O3 \
    -arch "$1" -o "$2" \
    -mmacosx-version-min=11.0 \
    -F /System/Library/PrivateFrameworks \
    -framework CoreGraphics \
    -framework CoreUI \
    -framework Foundation \
    -framework ImageIO \
    -framework UniformTypeIdentifiers
  strip "$2"
}

build arm64 /tmp/acdumper-arm64
build x86_64 /tmp/acdumper-x86_64
xcrun lipo -create /tmp/acdumper-arm64 /tmp/acdumper-x86_64 -output acdumper
