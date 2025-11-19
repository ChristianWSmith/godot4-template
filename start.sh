#!/usr/bin/env bash
## -----------------------------------------------------------------------------
## Project Startup Script
## -----------------------------------------------------------------------------
## start.sh is a cross-platform bootstrap script for managing a project's local
## Godot editor environment. It ensures consistent tooling across all machines
## without requiring the user to install Godot globally.
##
## Responsibilities:
## 1. **Determine Project Context**
##    - Locates the script directory.
##    - Reads the required Godot version from `.godot-version`.
##    - Initializes a private `.editor` directory used for all editor data.
##
## 2. **Version Synchronization**
##    - Detects when `.godot-version` has changed since the last startup.
##    - Clears and rebuilds the `.editor` directory when versions differ to
##      prevent stale editor caches, mismatched configs, or incompatible data.
##
## 3. **Platform Detection**
##    - Determines the current OS (`Linux`, `macOS`, or `Windows`) and maps it
##      to the correct Godot binary suffix required for downloading official
##      builds.
##
## 4. **Engine Download & Extraction**
##    - Checks whether the appropriate Godot editor binary already exists.
##    - If missing:
##        - Downloads the matching release from the official Godot builds repo.
##        - Extracts it into `.editor/`.
##        - Ensures the editor binary is executable.
##    - Supports proper `.app` bundle handling on macOS.
##
## 5. **Export Template Management**
##    - Verifies that export templates for the requested Godot version exist.
##    - If not:
##        - Downloads the appropriate `.tpz` archive.
##        - Extracts it into the required template directory structure.
##    - Ensures export presets will work out of the box for all platforms.
##
## 6. **Launching the Editor**
##    - Starts the downloaded Godot editor using the project's `project.godot`.
##    - Passes through any additional CLI arguments to Godot.
##
## This script provides a reproducible Godot environment, avoiding global system
## dependencies and guaranteeing that all contributors, CI pipelines, and build
## systems run the exact same Godot version and export templates.
## -----------------------------------------------------------------------------

set -euo pipefail

# Setup
GREEN='\033[0;32m'
NC='\033[0m'
LOG_PREFIX="${GREEN}[$(basename "${0}")]${NC}"

log() {
    echo -e "${LOG_PREFIX} ${@}"
}


# Get context
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
log "Root Dir: ${SCRIPT_DIR}"
GODOT_VERSION="$(cat "${SCRIPT_DIR}/.godot-version")"
log "Godot Version: ${GODOT_VERSION}"
EDITOR_DIR="${SCRIPT_DIR}/.editor"
mkdir -p "${EDITOR_DIR}"
EXPORT_TEMPLATES_DIR="${EDITOR_DIR}/editor_data/export_templates/$(echo "${GODOT_VERSION}" | tr '-' '.')"

if [ ! -e "${EDITOR_DIR}/.godot-version" ] || [ "${GODOT_VERSION}" != "$(cat "${EDITOR_DIR}/.godot-version")" ]; then
    log "Version changed, cleaning..."
    rm -rf "${EDITOR_DIR}"
    mkdir -p "${EDITOR_DIR}"
    cp "${SCRIPT_DIR}/.godot-version" "${EDITOR_DIR}/.godot-version"
fi

# Get the platform
platform="$(uname -s)"
log "Platform: ${platform}"
case "${platform}" in
    Linux*)          PLATFORM_SUFFIX="linux.x86_64";;
    Darwin*)         PLATFORM_SUFFIX="macos.universal";;
    CYGWIN*|MINGW*)  PLATFORM_SUFFIX="win64.exe";;
    *)
        echo "Unsupported platform: ${platform}"
        exit 1
esac


# Ensure we have the engine
log "Checking for engine..."
ENGINE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_${PLATFORM_SUFFIX}.zip"
touch "${EDITOR_DIR}/._sc_"
ENGINE_DOWNLOAD_FILE="${EDITOR_DIR}/$(basename "${ENGINE_URL}")"

if [[ "${platform}" =~ ^"Darwin" ]]; then
    EDITOR="${EDITOR_DIR}/Godot_v${GODOT_VERSION}.app"
else
    EDITOR="${EDITOR_DIR}/Godot_v${GODOT_VERSION}_${PLATFORM_SUFFIX}"
fi

if [ ! -e "${EDITOR}" ]; then
    log "Engine not found, checking for archive..."
    if [ ! -e "${ENGINE_DOWNLOAD_FILE}" ]; then
        log "Archive not found, downloading..."
        wget -O "${ENGINE_DOWNLOAD_FILE}" "${ENGINE_URL}" > /dev/null 2>&1
    else
        log "Archive found: ${ENGINE_DOWNLOAD_FILE}"
    fi
    pushd "${EDITOR_DIR}" > /dev/null 2>&1
    log "Extracting engine..."
    unzip "${ENGINE_DOWNLOAD_FILE}" > /dev/null 2>&1
    if [[ "${platform}" =~ ^"Darwin" ]]; then
        mv "Godot.app" "$(basename "${EDITOR}")"
    fi
    popd > /dev/null 2>&1

    chmod +x "${EDITOR}"
else
    log "Engine found: ${EDITOR}"
fi


# Ensure we have the export templates
log "Checking for export templates..."
EXPORT_TEMPLATES_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"
EXPORT_TEMPLATES_DOWNLOAD_FILE="${EDITOR_DIR}/$(basename "${EXPORT_TEMPLATES_URL}")"

if [ ! -e "${EXPORT_TEMPLATES_DIR}" ]; then
    log "Export templates not found, checking for archive..."
    pushd "${EDITOR_DIR}" > /dev/null 2>&1
    if [ ! -e "${EXPORT_TEMPLATES_DOWNLOAD_FILE}" ]; then
        log "Archive not found, downloading..."
        wget -O "${EXPORT_TEMPLATES_DOWNLOAD_FILE}" "${EXPORT_TEMPLATES_URL}" > /dev/null 2>&1
    else
        log "Archive found: ${EXPORT_TEMPLATES_DOWNLOAD_FILE}"
    fi
    log "Extracting export templates..."
    unzip "${EXPORT_TEMPLATES_DOWNLOAD_FILE}" > /dev/null 2>&1
    mkdir -p "${EXPORT_TEMPLATES_DIR}"
    mv templates/* "${EXPORT_TEMPLATES_DIR}"
    rm -rf templates
    popd > /dev/null 2>&1
else
    log "Export templates found: ${EXPORT_TEMPLATES_DIR}"
fi


# Start the editor
log "Starting Godot..."
if [[ "${platform}" =~ ^"Darwin" ]]; then
    "${EDITOR}/Contents/MacOS/Godot" "${SCRIPT_DIR}/project.godot" "$@"
else
    "${EDITOR}" "${SCRIPT_DIR}/project.godot" "$@"
fi
