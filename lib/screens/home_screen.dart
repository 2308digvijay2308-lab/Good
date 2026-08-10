import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../services/chat_database.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/mic_button.dart';
import '../widgets/status_indicator.dart';

/// ============================================================================
///  HOME SCREEN — the full JARVIS voice assistant UI.
///  Premium Material 3 Dark layout:
///    1. Top nav bar "PROJECT JARVIS" + green status node.
///    2. Center scrollable chat log.
///    3. Bottom input row (text field + Send).
///    4. Pulsing circular FAB mic button.
/// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---- Services -----------------------------------------------------------
  final GeminiService _gemini = GeminiService();
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();
  final ChatDatabase _db = ChatDatabase();
  final Uuid _uuid = const Uuid();

  // ---- UI state ------------------------------------------------------------
  final List<ChatMessage> _messages = [];
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  JarvisStatus _status = JarvisStatus.idle;
  bool _listening = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _tts.initialize();
    // Restore any persisted chat history from SQLite.
    try {
      final history = await _db.loadMessages();
      if (history.isNotEmpty) {
        setState(() => _messages.addAll(history));
        _scrollToBottom();
        return;
      }
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    }
    // Otherwise show a welcome bubble from JARVIS.
    _appendMessage(
      'Hello. I am JARVIS, your voice assistant. '
      'Ask me anything — or tap the mic to talk.',
      isUser: false,
    );
  }

  // ---- Message plumbing ----------------------------------------------------
  void _appendMessage(String text, {required bool isUser}) {
    final msg = ChatMessage.from(
      _uuid.v4(),
      text,
      isUser,
    );
    setState(() => _messages.add(msg));
    // Persist to SQLite (fire-and-forget; errors are non-fatal).
    _db.upsert(msg).catchError((_) {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---- Send (typed text) ----------------------------------------------------
  Future<void> _onSend() async {
    final text = _input.text.trim();
    if (text.isEmpty || _isSending) return;

    _input.clear();
    await _submit(text);
  }

  // ---- Shared submit path for typed AND spoken input ------------------------
  Future<void> _submit(String userText) async {
    if (_isSending) return;
    setState(() => _isSending = true);

    _appendMessage(userText, isUser: true);

    // Pending bubble that streams the reply.
    final pending = ChatMessage.pending(id: _uuid.v4(), isUser: false);
    setState(() {
      _messages.add(pending);
      _status = JarvisStatus.thinking;
    });
    // Persist the empty placeholder; we'll update its text as it streams.
    _db.upsert(pending).catchError((_) {});
    _scrollToBottom();

    try {
      await for (final partial in _gemini.streamMessage(userText)) {
        if (!mounted) return;
        setState(() {
          pending.text = partial;
          pending.isPending = false;
        });
        _db.updateText(pending.id, partial).catchError((_) {});
        _scrollToBottom();
      }
      setState(() {
        _status = JarvisStatus.idle;
        _isSending = false;
      });

      // Speak the finished reply.
      if (pending.text.isNotEmpty) {
        await _tts.speak(pending.text);
      }
    } on ApiKeyNotConfiguredException catch (_) {
      setState(() {
        _status = JarvisStatus.offline;
        _isSending = false;
      });
      _showKeyNotice();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        pending.text =
            'I hit an error while thinking: $e'.replaceAll('Exception', '');
        pending.isPending = false;
        _status = JarvisStatus.idle;
        _isSending = false;
      });
      _db.updateText(pending.id, pending.text).catchError((_) {});
    }
  }

  void _showKeyNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Gemini API key not set. Edit lib/config/app_config.dart '
          '(or use --dart-define=GEMINI_KEY=...).',
        ),
      ),
    );
  }

  // ---- Mic handler -----------------------------------------------------------
  Future<void> _onMicPressed() async {
    if (_listening) {
      await _speech.stopListening();
      setState(() {
        _listening = false;
        _status = JarvisStatus.idle;
      });
      return;
    }

    final ready = await _speech.initialize();
    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access the microphone / speech engine.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _listening = true;
      _status = JarvisStatus.listening;
      _input.clear();
    });

    String lastText = '';
    await _speech.startListening(
      onText: (text) {
        lastText = text;
        _input.text = text;
      },
      onListenDone: () async {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _status = JarvisStatus.idle;
        });
        if (lastText.trim().isNotEmpty) {
          await _submit(lastText.trim());
        }
      },
    );
  }

  // ---- Misc ------------------------------------------------------------------
  Future<void> _clearChat() async {
    _gemini.clearHistory();
    await _db.clearAll().catchError((_) {});
    if (mounted) {
      setState(() {
        _messages.clear();
        _status = JarvisStatus.idle;
      });
    }
  }

  Future<void> _toggleTts() async {
    final newVal = !_tts.speechEnabled;
    await _tts.setEnabled(newVal);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(newVal ? 'Voice output ON' : 'Voice output OFF'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _speech.dispose();
    _tts.stop();
    _db.dispose();
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---- BUILD ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12171E),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            // JARVIS logo mark.
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF009688)],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome,
                  color: Colors.black87, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROJECT JARVIS',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gemini 2.5 Flash',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Voice (TTS) toggle button.
          IconButton(
            tooltip: 'Toggle voice output',
            onPressed: _toggleTts,
            icon: Icon(
              _tts.speechEnabled ? Icons.volume_up_rounded : Icons.volume_off,
              color: _tts.speechEnabled
                  ? scheme.primary
                  : Colors.white38,
            ),
          ),
          // Active status node.
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Center(child: StatusIndicator(status: _status)),
          ),
          // Model label + status text.
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                _status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),

      // ---- Floating mic button ---------------------------------------------
      floatingActionButton: MicButton(
        listening: _listening,
        onPressed: _onMicPressed,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,

      body: SafeArea(
        child: Column(
          children: [
            // ---- Center scrollable chat log ---------------------------------
            Expanded(
              child: _messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.only(
                        top: 16,
                        bottom: 120,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return ChatBubble(
                          message: _messages[index],
                          isLast: index == _messages.length - 1,
                        );
                      },
                    ),
            ),

            // ---- Bottom input row -------------------------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF12171E),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      cursorColor: scheme.primary,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _onSend(),
                      decoration: InputDecoration(
                        hintText: 'Message JARVIS…',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0B0F14),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: scheme.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ---- Prominent Send button --------------------------------
                  Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isSending ? null : _onSend,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(
                          Icons.send_rounded,
                          color: scheme.onPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome,
              size: 64, color: Color(0xFF00E676)),
          const SizedBox(height: 16),
          Text(
            'JARVIS is online',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the mic or type below to begin.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
