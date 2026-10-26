#!/bin/bash
# Crea le distribuzioni di Lumeria per macOS, Windows, Linux e ChromeOS.
# Uso: tools/make_distributions.sh
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
mkdir -p build/windows build/linux build/linux-arm64 build/chromeos
rm -f build/Lumeria-macOS.zip build/Lumeria-Windows.zip \
	build/Lumeria-Linux.tar.gz build/Lumeria-Linux-ARM64.tar.gz build/Lumeria-ChromeOS.zip

echo "== macOS =="
"$GODOT" --headless --path . --export-release "macOS" "build/Lumeria.app"
# La firma va fatta fuori da iCloud/Documenti: il file provider può
# riapplicare FinderInfo e codesign rifiuterebbe il bundle.
rm -rf /tmp/lumeria_sign
mkdir -p /tmp/lumeria_sign
ditto build/Lumeria.app /tmp/lumeria_sign/Lumeria.app
cp LICENSE NOTICE THIRD_PARTY_NOTICES.md /tmp/lumeria_sign/Lumeria.app/Contents/Resources/
xattr -cr /tmp/lumeria_sign/Lumeria.app
codesign --force --deep --sign - /tmp/lumeria_sign/Lumeria.app
codesign --verify --deep --strict /tmp/lumeria_sign/Lumeria.app
ditto -c -k --norsrc --keepParent /tmp/lumeria_sign/Lumeria.app build/Lumeria-macOS.zip

echo "== Windows =="
"$GODOT" --headless --path . --export-release "Windows" "build/windows/Lumeria.exe"
cp LICENSE NOTICE THIRD_PARTY_NOTICES.md build/windows/
(cd build/windows && zip -q -r ../Lumeria-Windows.zip .)

echo "== Linux =="
"$GODOT" --headless --path . --export-release "Linux" "build/linux/Lumeria.x86_64"
chmod +x build/linux/Lumeria.x86_64
cp LICENSE NOTICE THIRD_PARTY_NOTICES.md build/linux/
(cd build/linux && tar -czf ../Lumeria-Linux.tar.gz .)

echo "== Linux ARM64 =="
"$GODOT" --headless --path . --export-release "Linux ARM64" "build/linux-arm64/Lumeria.arm64"
chmod +x build/linux-arm64/Lumeria.arm64
cp LICENSE NOTICE THIRD_PARTY_NOTICES.md build/linux-arm64/
(cd build/linux-arm64 && tar -czf ../Lumeria-Linux-ARM64.tar.gz .)

echo "== ChromeOS (ambiente Linux) =="
cp build/linux/Lumeria.x86_64 build/chromeos/
cp LICENSE NOTICE THIRD_PARTY_NOTICES.md build/chromeos/
cp tools/chromeos/Lumeria.desktop build/chromeos/
cp tools/chromeos/LEGGIMI.txt build/chromeos/
(cd build/chromeos && zip -q -r ../Lumeria-ChromeOS.zip .)

echo
ls -lh build/*.zip build/*.tar.gz
