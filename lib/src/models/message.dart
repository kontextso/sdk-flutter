enum MessageRole { user, assistant }

class Message {
  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  /// A unique identifier for the message.
  final String id;

  /// The role of the message sender, either [MessageRole.user] or [MessageRole.assistant].
  final MessageRole role;

  /// The text content of the message.
  final String content;

  /// The timestamp when the message was created.
  final DateTime createdAt;

  bool get isUser => role == MessageRole.user;

  bool get isAssistant => role == MessageRole.assistant;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Message && id == other.id && role == other.role && content == other.content);
  }

  @override
  int get hashCode => Object.hash(id, role, content);

  @override
  String toString() {
    return 'Message(id: $id, role: $role, content: $content, createdAt: $createdAt)';
  }
}
