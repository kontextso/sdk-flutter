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

  final String name;
  final String? id;
  final String? title;
  final String? greeting;
  final String? persona;
  final List<String>? tags;
  final String? avatarUrl;
  final bool? isNsfw;
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
