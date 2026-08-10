import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

/// ============================================================================
///  SPEECH SERVICE — microphone voice-input engine
/// ----------------------------------------------------------------------------
///  Wraps the native `speech_to_text` plugin. Handles engine initialisation,
///  permission requests, listening lifecycle and transcription callbacks.
/// ============================================================================

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _available = false;
  bool _listening = false;

  bool get available => _available;
  bool get listening => _listening;

  String _localeId = 'en_US';

  /// Initialise the speech engine + request mic permission.
  /// Returns true when ready to listen.
  Future<bool> initialize() async {
    if (_available) return true;

    _available = await _speech.initialize(
      onStatus: (status) {
  if (status == 'done' || status == 'notListening') {
    _listening = false;
  }
},
      onError: (error) {
        _listening = false;
      },
    );

    if (_available) {
      _localeId = _speech.localeId ?? 'en_US';
    }
    return _available;
  }

  /// Start listening and continuously push recognised words to [onText].
  Future<void> startListening({
    required void Function(String recognizedText) onText,
    void Function()? onListenDone,
  }) async {
    if (!_available) {
      final ok = await initialize();
      if (!ok) return;
    }

    _listening = true;
    await _speech.listen(
      localeId: _localeId,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (result) {
        final text = result.recognizedWords;
        if (text.isNotEmpty) onText(text);
        if (result.finalResult && onListenDone != null) {
          _listening = false;
          onListenDone();
        }
      },
    );
  }

  /// Stop listening and return the final recognised string if any.
  Future<void> stopListening() async {
    _listening = false;
    await _speech.stop();
  }

  Future<void> dispose() async {
    if (_listening) {
      await _speech.stop();
    }
  }
}
