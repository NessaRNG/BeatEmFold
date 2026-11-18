#!/usr/bin/env bash
# Upload artifact dari build/dist ke GitHub Releases di repo ini.
# Butuh GITHUB_TOKEN / GH_TOKEN dengan scope "repo" (atau `gh auth login`).
# Pakai: GITHUB_TOKEN=xxx tools/publish_release.sh v0.1.0 "Judul Rilis"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${1:?Pakai: tools/publish_release.sh <tag> [judul]}"
TITLE="${2:-$TAG}"
DIST="$ROOT/build/dist"

if [[ ! -d "$DIST" ]]; then
  echo "Folder $DIST belum ada. Jalankan tools/build_release.sh dulu." >&2
  exit 1
fi

REPO="$(git remote get-url origin | sed -E 's#.*github.com[:/](.+?)(\.git)?$#\1#')"
[[ -n "$REPO" ]] || { echo "Gagal deteksi repo dari remote origin." >&2; exit 1; }

if command -v gh >/dev/null 2>&1; then
  echo "==> Upload pakai gh CLI ke $REPO ($TAG)"
  gh release create "$TAG" "$DIST"/* \
    --repo "$REPO" \
    --title "$TITLE" \
    --generate-notes \
    --verify-tag
  exit 0
fi

TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
[[ -n "$TOKEN" ]] || { echo "Butuh GITHUB_TOKEN/GH_TOKEN atau gh CLI yang sudah login." >&2; exit 1; }

echo "==> Buat release $TAG di $REPO lewat GitHub API..."
API="https://api.github.com/repos/$REPO"
BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT

cat > "$BODY" <<JSON
{
  "tag_name": "$TAG",
  "name": "$TITLE",
  "body": "Build otomatis Beat 'Em Fold.\n\nUnduh sesuai platform:\n- **Linux**: \`BeatEmFold-Linux-x86_64\` (chmod +x lalu jalankan)\n- **Windows**: \`BeatEmFold-Windows-x86_64.exe\`\n- **Browser**: ekstrak \`BeatEmFold-Web.zip\` lalu buka lewat web server statis\n\nCek integritas dengan \`sha256sum -c SHA256SUMS\`.",
  "draft": false,
  "prerelease": false
}
JSON

RESP="$(curl -sS --fail -X POST "$API/releases" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  --data-binary @"$BODY")" || {
    echo "Gagal membuat release. Cek token dan permission repo." >&2
    exit 1
  }

UPLOAD_URL="$(printf '%s' "$RESP" | grep -m1 '"upload_url"' | cut -d'"' -f4)"
[[ -n "$UPLOAD_URL" ]] || { echo "Respons API tidak punya upload_url." >&2; exit 1; }

echo "==> Upload aset..."
for file in "$DIST"/*; do
  name="$(basename "$file")"
  printf '  - %s\n' "$name"
  curl -sS --fail -X POST "${UPLOAD_URL%%\{*}?name=$name" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"$file" > /dev/null
done

echo "==> Selesai: https://github.com/$REPO/releases/tag/$TAG"
