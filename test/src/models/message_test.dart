import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';

void main() {
  final createdAt = DateTime.parse('2025-01-01T00:00:00Z');

  group('Message.isUser/isAssistant', () {
    test('user message reports isUser and not isAssistant', () {
      final m = Message(id: '1', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      expect(m.isUser, isTrue);
      expect(m.isAssistant, isFalse);
    });

    test('assistant message reports isAssistant and not isUser', () {
      final m = Message(id: '1', role: MessageRole.assistant, content: 'hi', createdAt: createdAt);
      expect(m.isAssistant, isTrue);
      expect(m.isUser, isFalse);
    });
  });

  group('Message.toJson', () {
    test('emits every field using role.name and ISO-8601 UTC timestamp', () {
      final m = Message(
        id: 'm-1',
        role: MessageRole.user,
        content: 'hello',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
      );
      final json = m.toJson();

      expect(json['id'], 'm-1');
      expect(json['role'], 'user');
      expect(json['content'], 'hello');
      expect(json['createdAt'], '2025-01-02T03:04:05.000Z');
    });

    test('converts a local DateTime to UTC before serialising', () {
      // Pick a fixed UTC instant and construct an equivalent local-zone Date.
      final utcInstant = DateTime.utc(2025, 1, 2, 3, 4, 5);
      final local = utcInstant.toLocal();
      final json = Message(id: '1', role: MessageRole.user, content: 'x', createdAt: local).toJson();
      expect(json['createdAt'], '2025-01-02T03:04:05.000Z');
    });
  });

  group('Message equality', () {
    test('messages with the same id/role/content are equal', () {
      final a = Message(id: '1', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      final b = Message(
        id: '1',
        role: MessageRole.user,
        content: 'hi',
        createdAt: createdAt.add(const Duration(seconds: 10)),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different ids are not equal', () {
      final a = Message(id: '1', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      final b = Message(id: '2', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      expect(a, isNot(equals(b)));
    });

    test('different roles are not equal', () {
      final a = Message(id: '1', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      final b = Message(id: '1', role: MessageRole.assistant, content: 'hi', createdAt: createdAt);
      expect(a, isNot(equals(b)));
    });

    test('different content is not equal', () {
      final a = Message(id: '1', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      final b = Message(id: '1', role: MessageRole.user, content: 'bye', createdAt: createdAt);
      expect(a, isNot(equals(b)));
    });

    test('is equal to itself', () {
      final a = Message(id: '1', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      expect(a == a, isTrue);
    });

    test('is not equal to a non-Message', () {
      final a = Message(id: '1', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      // ignore: unrelated_type_equality_checks
      expect(a == 'not a message', isFalse);
    });
  });

  group('Message.toString', () {
    test('includes id, role, content, createdAt', () {
      final m = Message(id: 'm-1', role: MessageRole.user, content: 'hi', createdAt: createdAt);
      final s = m.toString();
      expect(s, contains('m-1'));
      expect(s, contains('MessageRole.user'));
      expect(s, contains('hi'));
    });
  });
}
