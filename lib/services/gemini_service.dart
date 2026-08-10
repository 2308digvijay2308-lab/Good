import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/app_config.dart';

/// ============================================================================
/// GEMINI SERVICE
/// ----------------------------------------------------------------------------
/// Handles Gemini chat requests and streaming responses.
/// ============================================================================

class GeminiService {
  GeminiService({String? apiKey}) : _apiKey = apiKey ?? activeApiKey {
    _model = _buildModel();
  }

  final String _apiKey;
  late final GenerativeModel _model;

  final List<Content> _history = [];

  GenerativeModel _buildModel() {
    return GenerativeModel(
      model: geminiModel,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxOutputTokens,
      ),
      systemInstruction: Content.system(jarvisSystemPrompt),
    );
  }

  String get activeModel => geminiModel;

  bool hasTalked = false;

  Future<String> sendMessage(String userText) async {
    _validateApiKey();

    final chat = _model.startChat(history: _history);

    final userContent = Content.text(userText);
    _history.add(userContent);

    final response = await chat.sendMessage(userContent);

    final reply = response.text?.trim() ??
        'Sorry, I could not produce a response right now.';

    _history.add(Content.model([TextPart(reply)]));
    hasTalked = true;

    return reply;
  }

  Stream<String> streamMessage(String userText) async* {
    _validateApiKey();

    final chat = _model.startChat(history: _history);

    final userContent = Content.text(userText);
    _history.add(userContent);

    final response = chat.sendMessageStream(userContent);

    final buffer = StringBuffer();

    await for (final part in response) {
      final text = part.text;

      if (text != null && text.isNotEmpty) {
        buffer.write(text);
        yield buffer.toString();
      }
    }

    final finalText = buffer.toString();

    if (finalText.isNotEmpty) {
      _history.add(Content.model([TextPart(finalText)]));
    }

    hasTalked = true;
  }

  void clearHistory() {
    _history.clear();
    hasTalked = false;
  }

  void _validateApiKey() {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY') {
      throw const ApiKeyNotConfiguredException();
    }
  }
}

/// Thrown when the Gemini API key is not configured.
class ApiKeyNotConfiguredException implements Exception {
  const ApiKeyNotConfiguredException();

  @override
  String toString() =>
      'Gemini API key not configured. '
      'Set it using --dart-define=GEMINI_KEY=...';
}