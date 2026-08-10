# JARVIS release ProGuard rules.
# Keep the Google AI SDK client intact (it uses reflection + R8 service lookup).
-keep class com.google.ai.client.generativeai.** { *; }
-keep class com.google.genai.** { *; }

# Keep Flutter engine plumbing untouched.
-keep class io.flutter.plugin.editing.** { *; }
