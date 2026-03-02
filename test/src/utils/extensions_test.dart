import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

void main() {
  group('ListExtension', () {
    group('firstWhereOrElse', () {
      test('returns first matching element', () {
        final list = [1, 2, 3, 4];
        expect(list.firstWhereOrElse((e) => e > 2), 3);
      });

      test('returns null when no match and no orElse', () {
        final list = [1, 2, 3];
        expect(list.firstWhereOrElse((e) => e > 10), null);
      });

      test('calls orElse when no match', () {
        final list = [1, 2, 3];
        expect(list.firstWhereOrElse((e) => e > 10, orElse: () => 99), 99);
      });
    });

    group('lastWhereOrElse', () {
      test('returns last matching element', () {
        final list = [1, 2, 3, 4];
        expect(list.lastWhereOrElse((e) => e < 4), 3);
      });

      test('returns null when no match and no orElse', () {
        final list = [1, 2, 3];
        expect(list.lastWhereOrElse((e) => e > 10), null);
      });

      test('calls orElse when no match', () {
        final list = [1, 2, 3];
        expect(list.lastWhereOrElse((e) => e > 10, orElse: () => 99), 99);
      });
    });

    group('nullIfEmpty', () {
      test('returns null for empty list', () {
        expect(<int>[].nullIfEmpty, null);
      });

      test('returns the list when non-empty', () {
        expect([1, 2].nullIfEmpty, [1, 2]);
      });
    });
  });

  group('MessageListExtension', () {
    Message makeMessage(String id) => Message(
          id: id,
          role: MessageRole.user,
          content: 'msg $id',
          createdAt: DateTime.now(),
        );

    test('returns all messages when count is not exceeded', () {
      final messages = List.generate(5, (i) => makeMessage('$i'));
      expect(messages.getLastMessages(count: 10), messages);
    });

    test('returns last N messages when list exceeds count', () {
      final messages = List.generate(35, (i) => makeMessage('$i'));
      final result = messages.getLastMessages(count: 30);
      expect(result.length, 30);
      expect(result.first.id, '5');
      expect(result.last.id, '34');
    });

    test('defaults to last 30 messages', () {
      final messages = List.generate(40, (i) => makeMessage('$i'));
      expect(messages.getLastMessages().length, 30);
    });
  });

  group('MapExtension', () {
    test('returns value when key exists', () {
      final map = {'a': 1, 'b': 2};
      expect(map.getOrNull('a'), 1);
    });

    test('returns null when key does not exist', () {
      final map = {'a': 1};
      expect(map.getOrNull('z'), null);
    });

    test('returns null value when key exists but value is null', () {
      final map = <String, int?>{'a': null};
      expect(map.getOrNull('a'), null);
    });
  });

  group('StringExtension', () {
    test('returns null for empty string', () {
      expect(''.nullIfEmpty, null);
    });

    test('returns null for whitespace-only string', () {
      expect('   '.nullIfEmpty, null);
    });

    test('returns trimmed string for non-empty string', () {
      expect('hello'.nullIfEmpty, 'hello');
    });

    test('trims whitespace before checking', () {
      expect('  hi  '.nullIfEmpty, 'hi');
    });
  });

  group('DoubleExtension', () {
    test('returns null for NaN', () {
      expect(double.nan.nullIfNaN, null);
    });

    test('returns value for valid double', () {
      expect(3.14.nullIfNaN, 3.14);
    });

    test('returns value for zero', () {
      expect(0.0.nullIfNaN, 0.0);
    });

    test('returns value for infinity', () {
      expect(double.infinity.nullIfNaN, double.infinity);
    });
  });
}
