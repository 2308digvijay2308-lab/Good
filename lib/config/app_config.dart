/// ============================================================================
///  PROJECT JARVIS — APPLICATION CONFIGURATION LAYER
/// ----------------------------------------------------------------------------
///  This is the single repository-initialization point for the app.
///  Replace the placeholder below with your real Google AI Studio API key.
///
///  ⚠️  SECURITY NOTE FOR GITHUB USERS
///  Do NOT hard-code a real key in a public repo. Options:
///    - Use `--dart-define=GEMINI_KEY=...` and reference `String.fromEnvironment`.
///    - Set the key as a GitHub Actions Secret and inject it at build time.
///    - Keep this placeholder and wire a backend proxy instead.
///
///  This file keeps the requested `String geminiKey = "YOUR_API_KEY";`
///  placeholder exactly as specified, but also reads an env override so your
///  CI build can inject the real key without committing it.
/// ============================================================================

/// REQUIRED placeholder — replace with your Google AI Studio API key.
/// e.g.  String geminiKey = "AIzaSy...";
String geminiKey = "YOUR_API_KEY";

/// Optional compile-time override: pass --dart-define=GEMINI_KEY=... at build.
const String _envKey = String.fromEnvironment('GEMINI_KEY', defaultValue: '');

/// The active Gemini model used by the AI core.
const String geminiModel = 'gemini-2.5-flash';

/// Tuning knobs for the assistant personality / safety.
const double temperature = 0.7;
const int maxOutputTokens = 1024;

/// Fallback internal reference to the resolved key.
/// (If the env override exists it wins; otherwise the placeholder above.)
String get activeApiKey => _envKey.isNotEmpty ? _envKey : geminiKey;

/// A short system prompt that shapes JARVIS' behaviour.
const String jarvisSystemPrompt = '''
You are JARVIS, a highly capable and efficient AI voice assistant inspired by
a premium, witty personal assistant. You are concise, articulate, and helpful.
Answer the user's questions clearly and directly. Keep answers brief unless a
fuller explanation is genuinely useful. You always stay on-topic and helpful.
''';
