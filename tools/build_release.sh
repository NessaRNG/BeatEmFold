#!/usr/bin/env bash
# Build rilis Beat 'Em Fold: bikin artifact yang siap di-upload ke GitHub Releases.
# Pakai: GODOT_BIN=/path/ke/godot tools/build_release.sh [version]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot-4.7.2}"
if [[ ! -x "$GODOT_BIN" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
  else
    echo "Godot CLI tidak ditemukan. Set GODOT_BIN ke binary Godot 4.7.x." >&2
    exit 1
  fi
fi

VERSION="${1:-$(git describe --tags --always --dirty 2>/dev/null || echo dev)}"
echo "==> Godot : $($GODOT_BIN --version)"
echo "==> Versi : $VERSION"

rm -rf build
mkdir -p build/linux build/windows build/web build/dist

echo "==> Export Linux..."
"$GODOT_BIN" --headless --path . --export-release "Linux" \
  build/linux/BeatEmFold.x86_64 > /tmp/beatemfold_export_linux.log 2>&1

echo "==> Export Windows..."
"$GODOT_BIN" --headless --path . --export-release "Windows Desktop" \
  build/windows/BeatEmFold.exe > /tmp/beatemfold_export_windows.log 2>&1

echo "==> Export Web..."
"$GODOT_BIN" --headless --path . --export-release "Web" \
  build/web/index.html > /tmp/beatemfold_export_web.log 2>&1

cp build/linux/BeatEmFold.x86_64 build/dist/BeatEmFold-Linux-x86_64
cp build/windows/BeatEmFold.exe   build/dist/BeatEmFold-Windows-x86_64.exe

echo "==> Zip Web (butuh semua file index.* disajikan bersama)..."
if command -v zip >/dev/null 2>&1; then
  ( cd build/web && zip -qr ../dist/BeatEmFold-Web.zip . )
else
  python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

src = Path("build/web")
out = Path("build/dist/BeatEmFold-Web.zip")
with ZipFile(out, "w", ZIP_DEFLATED) as zf:
    for path in sorted(src.rglob("*")):
        if path.is_file():
            zf.write(path, path.relative_to(src))
PY
fi

( cd build/dist && sha256sum BeatEmFold-* > SHA256SUMS )

echo
echo "==> Selesai. Asset rilis ada di: $ROOT/build/dist"
ls -lh build/dist
