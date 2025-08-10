class Character {
  Character({
    required this.name,
    this.id,
    this.title,
    this.greeting,
    this.persona,
    this.tags,
    this.avatarUrl,
    this.isNsfw,
    this.additionalProperties,
  });

  /// Name of the character.
  final String name;

  /// Unique identifier for the character.
  final String? id;

  /// Title of the character.
  final String? title;

  /// A greeting message from the character.
  final String? greeting;

  /// A description of the character's persona.
  final String? persona;

  /// Tags associated with the character.
  final List<String>? tags;

  /// URL of the character's avatar image.
  final String? avatarUrl;

  /// Whether the character is NSFW (Not Safe For Work).
  final bool? isNsfw;

  /// Additional properties that can be added to the character.
  final Map<String, dynamic>? additionalProperties;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'title': title,
      'greeting': greeting,
      'persona': persona,
      'tags': tags,
      'avatarUrl': avatarUrl,
      'isNsfw': isNsfw,
      if (additionalProperties != null) ...additionalProperties!,
    };
  }

  @override
  String toString() {
    return 'Character(name: $name, id: $id, title: $title, greeting: $greeting, persona: $persona, tags: $tags, avatarUrl: $avatarUrl, isNsfw: $isNsfw, additionalProperties: $additionalProperties)';
  }
}
