#!/usr/bin/env bash

set -euo pipefail

# Array of Gradle project names
tExtensions=(BasicExtension EntityExtension RoadNetworkExtension QuestExtension)

# Flags for what to build
BUILD_WEB=false
BUILD_ENGINE=false
BUILD_EXT=false

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --web) BUILD_WEB=true ;;
        --engine) BUILD_ENGINE=true ;;
        --ext) BUILD_EXT=true ;;
        *) echo "⚠️ Unknown argument: $arg" ;;
    esac
done

# === Build Web Panel ===
if [ "$BUILD_WEB" = true ]; then
    echo "=== Setup Flutter (using ./app/flutter) ==="
    export PATH="$(pwd)/app/flutter/bin:$PATH"

    echo "=== Get Flutter dependencies ==="
    cd ./app
    flutter pub get

    echo "=== Run Lint ==="
    flutter analyze || true

    echo "=== Run tests ==="
    flutter test

    echo "=== Build web app ==="
    flutter build web --release
    cd ..
fi

# === Build Engine ===
if [ "$BUILD_ENGINE" = true ]; then
    cd ./engine

    echo "=== Test Paper Engine ==="
    ./gradlew engine-paper:test --stacktrace --warning-mode none

    echo "=== Build Plugin ==="
    ./gradlew engine-paper:buildRelease -Pdebug=true --stacktrace --warning-mode none

    echo "=== Copy Plugin Jar to Server Plugins Directory ==="
    plugin_jar=(../jars/engine/Typewriter*.jar)
    plugin_target="../server/plugins/Typewriter.jar"
    mkdir -p "../server/plugins"

    if [[ -e "${plugin_jar[0]}" ]]; then
        if cp -v "${plugin_jar[0]}" "$plugin_target"; then
            echo "✅ Plugin jar copied successfully"
        else
            echo "❌ Failed to copy plugin jar"
        fi
    else
        echo "⚠️ Plugin jar not found at ${plugin_jar[0]}"
    fi
    cd ..
fi

# === Build Extensions ===
if [ "$BUILD_EXT" = true ]; then
    cd ./extensions

    for project in "${tExtensions[@]}"; do
        echo "=== Building $project ==="

        # Run tests and build with forced rebuild
        ./gradlew ":$project:test" ":$project:buildRelease" -Pdebug=true --scan --stacktrace --warning-mode none --rerun-tasks

        target_dir="../server/plugins/Typewriter/extensions"
        target_jar="../jars/extensions/$project.jar"
        mkdir -p "$target_dir"

        if [[ -e "$target_jar" ]]; then
            if cp -v "$target_jar" "$target_dir"; then
                echo "✅ Copied $project successfully"
            else
                echo "❌ Failed to copy $project"
            fi
        else
            echo "⚠️ Source jar not found for $project at $target_jar"
        fi
    done
    cd ..
fi

echo "✅ Pipeline finished successfully."