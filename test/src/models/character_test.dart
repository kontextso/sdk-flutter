import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/character.dart';

void main() {
  group('Character.toJson', () {
    test('serialises required fields', () {
      final json = Character(id: 'c-1', name: 'Max').toJson();
      expect(json['id'], 'c-1');
      expect(json['name'], 'Max');
    });

    test('omits every optional field when left null', () {
      final json = Character(id: 'c-1', name: 'Max').toJson();
      expect(json.containsKey('avatarUrl'), isFalse);
      expect(json.containsKey('isNsfw'), isFalse);
      expect(json.containsKey('greeting'), isFalse);
      expect(json.containsKey('persona'), isFalse);
      expect(json.containsKey('tags'), isFalse);
      expect(json.length, 2);
    });

    test('serialises every optional field when provided', () {
      final json = Character(
        id: 'c-1',
        name: 'Max',
        avatarUrl: 'https://cdn.example/a.png',
        isNsfw: false,
        greeting: 'Hello',
        persona: 'friendly',
        tags: ['fantasy', 'adventure'],
      ).toJson();

      expect(json['avatarUrl'], 'https://cdn.example/a.png');
      expect(json['isNsfw'], false);
      expect(json['greeting'], 'Hello');
      expect(json['persona'], 'friendly');
      expect(json['tags'], ['fantasy', 'adventure']);
    });

    test('merges additionalProperties into the top level JSON', () {
      final json = Character(
        id: 'c-1',
        name: 'Max',
        additionalProperties: {'theme': 'dark', 'locale': 'cs-CZ'},
      ).toJson();

      expect(json['theme'], 'dark');
      expect(json['locale'], 'cs-CZ');
      expect(json['id'], 'c-1'); // core fields stay
    });

    test('additionalProperties cannot silently override core fields via a later key', () {
      // Spec: core fields are spread before additionalProperties in toJson,
      // so additionalProperties wins on a key collision. Document this here.
      final json = Character(
        id: 'c-1',
        name: 'Max',
        additionalProperties: {'name': 'OverriddenName'},
      ).toJson();
      expect(json['name'], 'OverriddenName');
    });
  });

  group('Character.toString', () {
    test('includes the id and name for diagnostics', () {
      final str = Character(id: 'c-1', name: 'Max').toString();
      expect(str, contains('c-1'));
      expect(str, contains('Max'));
    });
  });
}
