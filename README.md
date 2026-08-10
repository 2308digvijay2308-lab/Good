# 🤖 PROJECT JARVIS

An Android **AI Voice Assistant** built with Flutter, powered by **Google Gemini 2.5 Flash**.
It listens with the microphone (`speech_to_text`), reasons with the Gemini API
(`google_generative_ai`), and speaks back (`flutter_tts`) inside a premium
Material 3 dark interface.

---

## ✨ Features

- 🎙️ **Voice input** — tap the pulsing FAB mic to speak to JARVIS.
- 🧠 **Gemini 2.5 Flash** — streaming responses via the official Google AI SDK.
- 🔊 **Text-to-Speech** — JARVIS reads replies aloud; 🔊 toggle button in the top bar switches voice output on/off.
- 💬 **Scrollable chat log** — user right, JARVIS left with an animated "thinking" bubble.
- 🟢 **Active status node** — green idle / blue listening / amber thinking / grey offline.
- 🗄️ **Persistent history** — every message is saved to SQLite and restored on relaunch.
- 🚀 **Native splash screen** — branded JARVIS splash on launch (incl. Android 12 splash API).
- 🔏 **Release signing** — CI signs the APK from GitHub secrets (debug-key fallback).
- 🌑 **Material 3 Dark** premium theme.

---

## 🚀 Getting started (local)

```bash
# 1. Clone the repo
git clone <your-repo-url> project_jarvis
cd project_jarvis

# 2. Generate the full platform scaffolding (needed for the binary
#    Gradle wrapper jar + any missing platform resources):
flutter create --platforms=android --org com.example .

# 3. Set your Gemini API key (Google AI Studio):
#    open lib/config/app_config.dart → String geminiKey = "YOUR_API_KEY";

# 4. Install deps and run
flutter pub get
flutter run
```

### Set the API key the secure way (recommended)
Pass the key at build time instead of hard-coding it:
```bash
flutter run --dart-define=GEMINI_KEY=AIzaSy...
flutter build apk --release --dart-define=GEMINI_KEY=AIzaSy...
```

---

## 🔏 Release signing (optional)

By default the release APK is signed with the **debug key** (installable, but
not for Play Store). For a proper release build:

1. Create a keystore:
   `keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
2. Move it to `android/app/upload-keystore.jks` and copy
   `android/key.properties.example` → `android/key.properties`, filling in your
   passwords and alias.
3. **Or** (for CI) add these GitHub secrets — the workflow auto-generates the
   signing config:
   - `KEYSTORE_BASE64` — base64 of your `.jks` keystore
   - `KEYSTORE_PASSWORD` — store password
   - `KEY_PASSWORD` — key password
   - `KEY_ALIAS` — key alias

> ⚠️ `key.properties` and `*.jks` are git-ignored — never commit them.

---

## 📦 CI/CD — Build the release APK on GitHub Actions

1. Push this repo to **GitHub**.
2. (Optional but recommended) Add secrets:
   `Settings → Secrets and variables → Actions → New repository secret`
   - `Name: GEMINI_KEY` → your Gemini API key
   - `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` → signing (optional)
3. Trigger the workflow:
   - automatically on push to `main`, **or**
   - `Actions → "Build Release APK" → Run workflow`.
4. When it finishes, open the run and download the APK from
   **Artifacts → `project-jarvis-release`**.

The workflow:
- Installs **Java 17** and the **stable Flutter SDK**.
- Runs `yes | flutter doctor --android-licenses` to auto-accept all Android licenses.
- Runs `flutter pub get`, `flutter analyze`, `flutter test`.
- Configures release signing from secrets (debug-key fallback if absent).
- Builds with `flutter build apk --release` (injects `GEMINI_KEY` secret if set).
- Uploads `app-release.apk` as a downloadable artifact.

### 📱 Play Store (.aab) build — `Build Play Store Bundle`
Builds a **signed app bundle** for Google Play upload (requires the signing
secrets — Play rejects debug-signed bundles). Triggers manually or on a
`v*` tag push. Artifact: `project-jarvis-playstore-bundle`.

### 🚀 Auto-upload to Play — `Upload to Google Play`
Builds a signed `.aab` and uploads it straight to a Play Console track
(internal / alpha / beta / production). Requires one extra secret:
- `SERVICE_ACCOUNT_JSON` — JSON key of a Play service account with
  "Release to testing/production" permission (Play Console → Setup → API
  access). Then run the workflow and pick a track.

**Auto-chaining:** this workflow automatically starts after the
`Build Play Store Bundle` workflow **succeeds** (it rebuilds the AAB, so you
get a consistent, freshly-built bundle). A guard step skips the upload if the
parent build failed. So a single `v*` tag push can drive the whole pipeline.

### 🔖 Versioning — `scripts/bump_version.sh`
```bash
./scripts/bump_version.sh patch   # 1.0.0+1 -> 1.0.1+2
./scripts/bump_version.sh minor   # 1.0.1+2 -> 1.1.0+3
./scripts/bump_version.sh --code  # bump build code only (versionCode)
./scripts/bump_version.sh 2.0.0   # set explicit version
./scripts/bump_version.sh --auto  # versionCode = latest Play build + 1
```
It bumps `pubspec.yaml`, commits, tags `v<semver>` and pushes — the tag push
auto-triggers the Play Store bundle build.

**Auto versionCode:** `--auto` queries the Google Play API for the highest
versionCode already uploaded and sets the next one above it, so Play never
rejects with "versionCode already used". Requires the `SERVICE_ACCOUNT_JSON`
env var; without it, it falls back to `local versionCode + 1`.

**Auto release notes:** each bump runs `scripts/generate_release_notes.sh`,
which writes `build/release_notes.txt` from the git log since the last tag
(used automatically by the Play upload workflow).

---

## 🗂️ Project layout

```
lib/
  main.dart                      # App entry + Material 3 dark theme
  config/app_config.dart         # ⭐ Gemini key placeholder + model config
  models/chat_message.dart       # Chat bubble data model
  services/gemini_service.dart   # Gemini 2.5 Flash async handler
  services/speech_service.dart   # Microphone voice input
  services/tts_service.dart      # Text-to-Speech output
  services/chat_database.dart    # SQLite persistent chat history
  screens/home_screen.dart       # Full JARVIS UI
  widgets/status_indicator.dart  # Active status node
  widgets/chat_bubble.dart       # Dynamic chat log bubbles
  widgets/mic_button.dart        # Pulsing FAB mic
android/                         # Android config (manifest, gradle, signing, splash, icons)
  key.properties.example         # Release keystore template
.github/workflows/build_apk.yml  # CI/CD → signed release APK
```

---

## 🔐 Security note
Never commit a real `GEMINI_KEY`, `key.properties`, or your keystore. Keep the
`YOUR_API_KEY` placeholder in `app_config.dart` and use the `GEMINI_KEY` GitHub
**secret** for CI builds.

---

## 🛠️ Troubleshooting

- **"Gemini API key not configured"** → set the key in `app_config.dart` or pass `--dart-define=GEMINI_KEY=...`.
- **Build fails with missing `gradle-wrapper.jar`** → run `flutter create --platforms=android .` once and commit the generated `android/` files.
- **`gemini-2.5-flash` not available** → your key tier may not expose it; use `gemini-1.5-flash` in `app_config.dart` (model can be swapped freely).
- **APK not signed for Play Store** → configure the signing secrets / key.properties as described above.
