#!/usr/bin/env bash
set -e

# Build and package if ApexNotch.app does not exist or if flag --build is passed
if [ ! -d "ApexNotch.app" ] || [ "$1" == "--build" ]; then
    echo "• Building and packaging ApexNotch.app..."
    ./Scripts/package_app.sh
fi

echo "• Launching ApexNotch..."
open ApexNotch.app
echo "ApexNotch is now active! Check your screen notch or menu bar icon."
