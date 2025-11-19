#!/usr/bin/env bash
## -----------------------------------------------------------------------------
## Project Build Script
## -----------------------------------------------------------------------------
## build.sh is a platform-aware wrapper for exporting the game using Godot’s
## command-line export system. It ensures consistent build outputs across all
## environments and always uses the locally-managed editor instance provided
## by `start.sh`.
##
## Responsibilities:
##
## 1. **Determine Build Context**
##    - Locates the project root via the script’s directory.
##    - Ensures the top-level `build/` directory exists for storing artifacts.
##
## 2. **Build Type Handling**
##    - Accepts a single optional argument specifying the build type:
##         `debug`   (default)
##         `release`
##    - Normalizes the input to lowercase.
##    - Maps the chosen type to the correct Godot CLI export flag:
##         `--export-debug`   or
##         `--export-release`
##    - Rejects unsupported build types early with a clear error.
##
## 3. **Platform Detection**
##    - Uses `uname -s` to determine the current OS.
##    - Maps each OS to:
##         - The correct Godot export preset name.
##         - The correct output artifact filename:
##               Linux   → game
##               macOS   → game.app
##               Windows → game.exe
##    - Ensures unsupported platforms fail gracefully.
##
## 4. **Delegation to start.sh**
##    - Launches the Godot editor *headlessly* using the project's managed
##      local engine installation.
##    - Passes through:
##         - `--verbose` for detailed export logs
##         - `--headless` to avoid GUI usage
##         - The correct export flag (debug/release)
##         - The export preset name (per-platform)
##         - The output path inside `build/`
##
##    Example internally invoked command:
##        start.sh --verbose --headless --export-release "Linux" "build/game"
##
## By routing all builds through start.sh, this script ensures that exporting the
## game always uses:
##   - the correct Godot version,
##   - correct export templates,
##   - and an isolated, reproducible local environment.
## -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"
EDITOR_DIR="${SCRIPT_DIR}/.editor"

BUILD_TYPE="${1:-debug}"
BUILD_TYPE="$(echo "${BUILD_TYPE}" | tr '[:upper:]' '[:lower:]')"

case "${BUILD_TYPE}" in
    debug)
        BUILD_TYPE_ARG="--export-debug"
        ;;
    release)
        BUILD_TYPE_ARG="--export-release"
        ;;
    *)
        echo "Unsupported build type: ${BUILD_TYPE}"
        exit 1
esac


# Get the platform
platform="$(uname -s)"
case "${platform}" in
    Linux*)
        TARGET="Linux"
        ARTIFACT="game"
        ;;
    Darwin*)
        TARGET="macOS"
        ARTIFACT="game.app"
        ;;
    CYGWIN*|MINGW*)
        TARGET="Windows Desktop"
        ARTIFACT="game.exe"
        ;;
    *)
        echo "Unsupported platform: ${platform}"
        exit 1
esac


# Ensure editor sanity
if [ ! -e "${EDITOR_DIR}" ]; then
    "${SCRIPT_DIR}/start.sh" --editor --quit-after 1 --headless
fi


# Build
"${SCRIPT_DIR}/start.sh" --verbose --headless $BUILD_TYPE_ARG "${TARGET}" "build/${ARTIFACT}"
