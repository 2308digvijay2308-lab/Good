import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ============================================================================
///  TTS SERVICE — Text-to-Speech voice synthesis output
/// ----------------------------------------------------------------------------
///  Wraps the native `flutter_tts` plugin for JARVIS' spoken replies.
/// ============================================================================

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _speaking = false;
  bool get speaking => _speaking;

  /// Whether spoken replies are enabled (toggle in UI).
  bool speechEnabled = true;

  Future<void> initialize() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setCompletionHandler(() => _speaking = false);
      _tts.setCancelHandler(() => _speaking = false);
      _tts.setErrorHandler((message) {
        debugPrint('TTS error: $message');
        _speaking = false;
      });
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!speechEnabled) return;
    try {
      _speaking = true;
      await _tts.speak(text);
    } catch (e) {
      _speaking = false;
      debugPrint('Speak failed: $e');
    }
  }

  Future<void> stop() async {
    _speaking = false;
    await _tts.stop();
  }

  Future<void> setEnabled(bool value) async {
    speechEnabled = value;
    if (!value && _speaking) await stop();
  }
}
