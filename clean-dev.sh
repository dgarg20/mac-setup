#!/bin/bash

# Development Environment Cleanup Script

echo "Cleaning development environment..."

# Clean Maven
if [ -d ~/.m2/repository ]; then
    echo "Cleaning Maven repository..."
    find ~/.m2/repository -name "*.lastUpdated" -delete
    find ~/.m2/repository -name "_remote.repositories" -delete
fi

# Clean Gradle
if [ -d ~/.gradle ]; then
    echo "Cleaning Gradle cache..."
    rm -rf ~/.gradle/caches/
    rm -rf ~/.gradle/daemon/
fi

# Clean Docker
if command -v docker &> /dev/null; then
    echo "Cleaning Docker..."
    docker system prune -f
    docker volume prune -f
fi

# Clean npm cache (if Node.js is installed)
if command -v npm &> /dev/null; then
    echo "Cleaning npm cache..."
    npm cache clean --force
fi

echo "Development environment cleanup completed!"
