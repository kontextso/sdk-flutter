enum MessageRole { user, assistant }

class Message {
  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final MessageRole role;
  final String content;
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
