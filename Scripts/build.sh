#!/bin/bash

# Countdown Wallpaper Build Script

echo "🏗️  Building Countdown Wallpaper..."

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo "❌ Swift is not installed. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# Build the application
swift build --configuration release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"

    # Copy the executable to a more convenient location
    mkdir -p build
    cp .build/release/CountdownWallpaper build/

    echo "📍 Executable created at: build/CountdownWallpaper"

    # Ask if user wants to run the app
    if [ "$1" = "--run" ] || [ "$1" = "-r" ]; then
        echo "🚀 Starting Countdown Wallpaper..."
        ./build/CountdownWallpaper
    else
        echo ""
        echo "To run the application:"
        echo "  ./build/CountdownWallpaper"
        echo ""
        echo "Or rebuild and run with:"
        echo "  ./build.sh --run"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
