/// A single chat message rendered in the JARVIS log.
class ChatMessage {
  final String id;
  String text;
  final bool isUser;
  final DateTime timestamp;
  bool isPending;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isPending = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a message from persisted database data.
  factory ChatMessage.from(
    String id,
    String text,
    bool isUser, {
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      timestamp: timestamp,
    );
  }

  /// A placeholder bubble that will be filled as the reply streams.
  ChatMessage.pending({
    required this.id,
    required this.isUser,
  })  : text = '',
        isPending = true,
        timestamp = DateTime.now();
}