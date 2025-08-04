#!/bin/bash

# Countdown Screensaver Build Script

echo "Building Countdown Screensaver..."

# Change to the screensaver directory
cd "$(dirname "$0")"

# Clean previous build
make clean

# Build the screensaver
make all

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "Build successful!"
    echo ""
    echo "To install the screensaver, run:"
    echo "  make install"
    echo ""
    echo "To test the screensaver, run:"
    echo "  make test"
    echo ""
else
    echo ""
    echo "Build failed!"
    exit 1
fi
