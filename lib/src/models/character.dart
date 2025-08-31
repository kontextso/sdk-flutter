/// The character object used in a conversation.
class Character {
  Character({
    required this.id,
    required this.name,
    this.greeting,
    this.persona,
    this.tags,
    this.avatarUrl,
    this.isNsfw,
    this.additionalProperties,
  });

  /// Unique identifier for the character.
  final String id;

  /// Name of the character.
  final String name;

  /// URL of the character's avatar image.
  final String? avatarUrl;

  /// Whether the character is NSFW (Not Safe For Work).
  final bool? isNsfw;

  /// A greeting message from the character.
  final String? greeting;

  /// A description of the character's persona.
  final String? persona;

  /// Tags associated with the character.
  final List<String>? tags;

  /// Additional properties that can be added to the character.
  final Map<String, dynamic>? additionalProperties;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (isNsfw != null) 'isNsfw': isNsfw,
      if (greeting != null) 'greeting': greeting,
      if (persona != null) 'persona': persona,
      if (tags != null) 'tags': tags,
      if (additionalProperties != null) ...additionalProperties!,
    };
  }

  @override
  String toString() {
    return 'Character(name: $name, id: $id, greeting: $greeting, persona: $persona, tags: $tags, avatarUrl: $avatarUrl, isNsfw: $isNsfw, additionalProperties: $additionalProperties)';
  }
}
