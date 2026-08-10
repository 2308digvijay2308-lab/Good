#!/usr/bin/env bash
# ============================================================================
#  PROJECT JARVIS — AUTO-DEPLOY SCRIPT
# ----------------------------------------------------------------------------
#  One-command pipeline for GitHub Actions cloud builds:
#    1. Generates missing platform scaffolding (Gradle wrapper, etc).
#    2. Commits & pushes the repo to GitHub.
#    3. Sets repo secrets via the `gh` CLI (API key + optional signing).
#    4. Triggers the "Build Release APK" workflow.
#    5. Waits for it to finish and prints the APK download URL.
#
#  Prerequisites:
#    - GitHub CLI:  https://cli.github.com   (auth: `gh auth login`)
#    - Flutter SDK on PATH (for the `flutter create` step, if needed).
#
#  Usage:
#    ./deploy.sh                          # interactive
#    GEMINI_KEY=AIza... ./deploy.sh       # provide key as env var
#    ./deploy.sh --org com.example        # custom Android org
# ============================================================================
set -euo pipefail

# ---- Configuration ---------------------------------------------------------
REPO_NAME="project_jarvis"
DEFAULT_ORG="com.example"
BRANCH="main"

# ---- Colours ---------------------------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[JARVIS]${NC} $*"; }
warn()  { echo -e "${YELLOW}[JARVIS]${NC} $*"; }
die()   { echo -e "${RED}[JARVIS]${NC} $*" >&2; exit 1; }

# ---- 0. Pre-flight ----------------------------------------------------------
command -v gh  >/dev/null 2>&1 || die "GitHub CLI not found. Install: https://cli.github.com and run: gh auth login"
gh auth status >/dev/null 2>&1 || die "Not logged into GitHub. Run: gh auth login"

# ---- 1. Scaffold if needed --------------------------------------------------
if [ ! -f "android/gradlew" ] || [ ! -f "android/gradlew.bat" ]; then
  warn "Missing Android Gradle wrapper — running 'flutter create' to generate it..."
  command -v flutter >/dev/null 2>&1 || die "Flutter not found. Install it first (needed once for scaffolding)."
  flutter create --platforms=android --org "${2:-$DEFAULT_ORG}" "$REPO_NAME" 2>/dev/null \
    || flutter create --platforms=android --org "${2:-$DEFAULT_ORG}" .
fi
cd "$REPO_NAME" 2>/dev/null || true

# ---- 2. Git init + push -----------------------------------------------------
if [ ! -d ".git" ]; then
  git init -q
  git add .
  git -c user.name="JARVIS" -c user.email="jarvis@local" commit -qm "Project JARVIS — initial commit"
  git branch -M "$BRANCH"
fi

# Determine GitHub repo (current origin or create via gh).
REMOTE=$(git remote get-url origin 2>/dev/null || true)
if [ -z "$REMOTE" ]; then
  read -rp "GitHub repo name (e.g. myusername/project_jarvis): " GH_REPO
  [ -n "$GH_REPO" ] || GH_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo)"
fi
if [ -z "${GH_REPO:-}" ]; then
  GH_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "${GITHUB_REPOSITORY:-}")"
fi
[ -n "${GH_REPO:-}" ] || die "Could not determine GitHub repo. Pass it as GH_REPO=user/repo or set an origin."

info "Pushing to https://github.com/$GH_REPO on branch '$BRANCH' ..."
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$GH_REPO.git"
git add -A
git -c user.name="JARVIS" -c user.email="jarvis@local" commit -qm "Project JARVIS — build" 2>/dev/null || true
git push -f origin "$BRANCH"

# ---- 3. Set secrets -----------------------------------------------------------
# API key (required). Accepts $GEMINI_KEY env var or prompts.
GEMINI_KEY="${GEMINI_KEY:-}"
if [ -z "$GEMINI_KEY" ]; then
  read -rsp "Paste your Gemini API key (input hidden): " GEMINI_KEY; echo
fi
if [ -n "$GEMINI_KEY" ]; then
  echo "$GEMINI_KEY" | gh secret set GEMINI_KEY --repo "$GH_REPO" --body - >/dev/null 2>&1 \
    && info "Secret GEMINI_KEY set." || warn "Could not set GEMINI_KEY (does it already exist?)."
else
  warn "No GEMINI_KEY provided — app will run but replies need a key."
fi

# Optional signing secrets — set only if env vars are provided.
if [ -n "${KEYSTORE_BASE64:-}" ]; then
  echo "$KEYSTORE_BASE64" | gh secret set KEYSTORE_BASE64 --repo "$GH_REPO" --body - >/dev/null 2>&1 && info "Secret KEYSTORE_BASE64 set."
fi
if [ -n "${KEYSTORE_PASSWORD:-}" ]; then
  gh secret set KEYSTORE_PASSWORD --repo "$GH_REPO" --body "$KEYSTORE_PASSWORD" >/dev/null 2>&1 && info "Secret KEYSTORE_PASSWORD set."
fi
if [ -n "${KEY_PASSWORD:-}" ]; then
  gh secret set KEY_PASSWORD --repo "$GH_REPO" --body "$KEY_PASSWORD" >/dev/null 2>&1 && info "Secret KEY_PASSWORD set."
fi
if [ -n "${KEY_ALIAS:-}" ]; then
  gh secret set KEY_ALIAS --repo "$GH_REPO" --body "$KEY_ALIAS" >/dev/null 2>&1 && info "Secret KEY_ALIAS set."
fi

# ---- 4. Trigger workflow ------------------------------------------------------
info "Triggering 'Build Release APK' workflow..."
RUN_ID=$(gh run list --repo "$GH_REPO" --workflow "build_apk.yml" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
if [ -z "$RUN_ID" ]; then
  gh workflow run "Build Release APK" --repo "$GH_REPO" --ref "$BRANCH" || die "Could not trigger workflow."
  sleep 8
  RUN_ID=$(gh run list --repo "$GH_REPO" --workflow "build_apk.yml" --limit 1 --json databaseId -q '.[0].databaseId')
fi
[ -n "$RUN_ID" ] || die "Could not find the workflow run."

info "Workflow run #$RUN_ID started. Watching status (this can take 5-10 min)..."
gh run watch "$RUN_ID" --repo "$GH_REPO" --exit-status

# ---- 5. Print download URL -----------------------------------------------------
info "Build finished successfully!"
ART_ID=$(gh api "/repos/$GH_REPO/actions/runs/$RUN_ID/artifacts" -q '.artifacts[0].id' 2>/dev/null || true)
if [ -n "$ART_ID" ]; then
  echo
  info "DOWNLOAD LINK:"
  echo "  https://github.com/$GH_REPO/actions/runs/$RUN_ID/artifacts/$ART_ID"
  echo
  info "Or grab it in the browser: Actions → run #$RUN_ID → Artifacts → project-jarvis-release"
else
  warn "Workflow succeeded but no artifact found. Check the run page."
fi
