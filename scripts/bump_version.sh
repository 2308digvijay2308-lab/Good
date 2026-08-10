#!/usr/bin/env bash
# ============================================================================
#  PROJECT JARVIS — VERSION BUMP AUTOMATION
# ----------------------------------------------------------------------------
#  Bumps the version in pubspec.yaml and tags the release on GitHub so the
#  Play Store (.aab) workflow builds with a consistent, incremented version.
#
#  Version format (pubspec):  <major>.<minor>.<patch>+<buildCode>
#    version: 1.2.3+45   ->  versionName "1.2.3"  /  versionCode 45
#
#  Usage:
#    ./scripts/bump_version.sh major|minor|patch   # bump semver + build code
#    ./scripts/bump_version.sh --code              # bump build code only
#    ./scripts/bump_version.sh 2.0.0               # set explicit semver + build code
#    ./scripts/bump_version.sh --auto              # bump versionCode above the
#                                                    latest Play upload (uses
#                                                    SERVICE_ACCOUNT_JSON if set,
#                                                    else falls back to local+1)
# ============================================================================
set -euo pipefail

PUBSPEC="pubspec.yaml"
[ -f "$PUBSPEC" ] || { echo "Error: $PUBSPEC not found in $(pwd)"; exit 1; }

# --- Read current version ---------------------------------------------------
LINE=$(grep -E '^version:' "$PUBSPEC" | head -n1 | sed -E 's/^version:[[:space:]]*//; s/\r//')
BASE="${LINE%%+*}"; CODE="${LINE##*+}"
[ "$CODE" = "$LINE" ] && CODE="1"          # no build code present
IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE"
MAJOR=${MAJOR:-0}; MINOR=${MINOR:-0}; PATCH=${PATCH:-0}

ARG="${1:-patch}"

# --- Auto mode: compare against the latest Play upload -----------------------
if [ "$ARG" = "--auto" ]; then
  PLAY_CODE=""
  if [ -n "${SERVICE_ACCOUNT_JSON:-}" ]; then
    PKG=$(grep -E 'applicationId' android/app/build.gradle | head -n1 \
          | sed -E 's/.*"([^"]+)".*/\1/')
    [ -n "$PKG" ] || PKG="com.example.project_jarvis"
    PLAY_CODE=$(python3 scripts/next_version_code.py "$PKG" 2>/dev/null || true)
  fi
  if [ -n "$PLAY_CODE" ] && [ "$PLAY_CODE" -gt "$CODE" ]; then
    CODE="$PLAY_CODE"
    echo "Latest versionCode on Play: $CODE"
  else
    echo "Using local versionCode: $CODE"
  fi
  CODE=$((CODE + 1))
  echo "--> Auto bump: versionCode = $CODE"
  ARG="--code"   # only code changes; keep semver
fi

case "$ARG" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0;;
  minor) MINOR=$((MINOR + 1)); PATCH=0;;
  patch) PATCH=$((PATCH + 1));;
  --code) :;;                               # keep semver
  *)
    if [[ "$ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      MAJOR="${ARG%%.*}"; MINOR="$(echo "$ARG" | cut -d. -f2)"; PATCH="${ARG##*.}"
    else
      PATCH=$((PATCH + 1)); echo "Unknown arg '$ARG' -> patch bump."
    fi;;
esac

NEW="$MAJOR.$MINOR.$PATCH+$CODE"
NEW_BASE="$MAJOR.$MINOR.$PATCH"

# --- Apply to pubspec --------------------------------------------------------
sed -E -i "s/^version:[[:space:]]*.*/version: $NEW/" "$PUBSPEC"
echo "Bumped version: $LINE  ->  $NEW"

# --- Generate release notes ---------------------------------------------------
if [ -x scripts/generate_release_notes.sh ]; then
  bash scripts/generate_release_notes.sh build/release_notes.txt 2>/dev/null || true
  git add build/release_notes.txt 2>/dev/null || true
fi

# --- Commit + tag -------------------------------------------------------------
git add "$PUBSPEC"
git -c user.name="JARVIS" -c user.email="jarvis@local" commit -qm "chore(release): bump to $NEW_BASE (build $CODE)"
git tag -f "v$NEW_BASE"
git push -f origin "v$NEW_BASE"
git push -f origin "$(git branch --show-current)"

echo "Tagged: v$NEW_BASE"
echo "The tag push auto-triggers the 'Build Play Store Bundle' workflow."
