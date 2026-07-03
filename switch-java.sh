#!/bin/bash

# Java Version Switcher Script

echo "Available Java versions:"
echo "========================"

if command -v sdk &> /dev/null || [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk list java | grep installed

    echo ""
    echo "Current Java version:"
    java -version

    echo ""
    echo "To switch Java version, use:"
    echo "sdk use java <version>"
    echo "sdk default java <version>"
else
    echo "SDKMAN not found. Please install SDKMAN first."
fi
