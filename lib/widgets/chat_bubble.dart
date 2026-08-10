import 'package:flutter/material.dart';

import '../models/chat_message.dart';

/// ============================================================================
///  CHAT BUBBLE — a single dynamic log entry.
///  User messages right-aligned, JARVIS messages left-aligned with an avatar.
/// ============================================================================

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.isLast = false,
  });

  final ChatMessage message;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFF1F6E43) // user green-tinted
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 300),
      child: message.isPending
          ? const SizedBox(
              width: 60,
              height: 18,
              child: LinearProgressIndicator(
                minHeight: 3,
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            )
          : Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                height: 1.4,
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _JarvisAvatar(),
            const SizedBox(width: 10),
          ],
          bubble,
        ],
      ),
    );
  }
}

class _JarvisAvatar extends StatelessWidget {
  const _JarvisAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF00E676), Color(0xFF009688)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.computer, size: 18, color: Colors.black87),
    );
  }
}
