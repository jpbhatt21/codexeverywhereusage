#!/bin/bash
set -euo pipefail

APP_NAME="CodexMenuBar"
SCHEME="CodexMenuBar"
CONFIG="Release"
BUILD_DIR="$(pwd)/build"
DMG_PATH="$(pwd)/../${APP_NAME}.dmg"

echo "Building ${APP_NAME}..."
xcodebuild -scheme "${SCHEME}" -configuration "${CONFIG}" \
  -derivedDataPath "${BUILD_DIR}" \
  BUILD_DIR="${BUILD_DIR}" \
  clean build 2>&1 | tail -5

APP_PATH="${BUILD_DIR}/Build/Products/${CONFIG}/${APP_NAME}.app"
if [ ! -d "${APP_PATH}" ]; then
  echo "Error: App not found at ${APP_PATH}"
  exit 1
fi

echo "Ad-hoc signing..."
codesign --force --deep --sign - "${APP_PATH}"

STAGING_DIR=$(mktemp -d)
cp -R "${APP_PATH}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

echo "Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov -format UDZO \
  "${DMG_PATH}"

codesign --force --sign - "${DMG_PATH}"

rm -rf "${STAGING_DIR}"

echo "Done: ${DMG_PATH}"
ls -lh "${DMG_PATH}"
