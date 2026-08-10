#!/usr/bin/env bash
# ============================================================================
#  PROJECT JARVIS — RELEASE NOTES AUTO-GENERATION
# ----------------------------------------------------------------------------
#  Builds release notes from the git commit log since the last release tag
#  and writes them to a file for the Play upload workflow to consume.
#
#  Usage:
#    ./scripts/generate_release_notes.sh [outfile]
#    # default outfile: build/release_notes.txt
# ============================================================================
set -euo pipefail

OUT="${1:-build/release_notes.txt}"
mkdir -p "$(dirname "$OUT")"

# Last tag (or fall back to the very first commit).
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)
VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")

{
  echo "PROJECT JARVIS — v$VERSION"
  echo ""
  echo "What's new:"
  echo ""
  # Group commit subjects since the last tag, skipping the bump commit itself.
  git log --pretty=format:"- %s" "$LAST_TAG..HEAD" 2>/dev/null \
    | grep -viE "chore\(release\)|^merge" \
    | sort -u \
    || echo "- Initial release build."
  echo ""
} > "$OUT"

echo "Wrote release notes to $OUT"
