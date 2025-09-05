enum MessageRole { user, assistant }

/// A class representing a message in a conversation, either from the user or the assistant.
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

  /// Returns true if the message was sent by the user.
  bool get isUser => role == MessageRole.user;

  /// Returns true if the message was sent by the assistant.
  bool get isAssistant => role == MessageRole.assistant;

  /// Converts a JSON map to a [Message] instance.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'createdAt': createdAt.toUtc().toIso8601String(),
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
