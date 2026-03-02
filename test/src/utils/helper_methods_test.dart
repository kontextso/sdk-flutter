import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/utils/helper_methods.dart';

void main() {
  group('deepHashObject', () {
    test('same primitive values produce same hash', () {
      expect(deepHashObject(42), deepHashObject(42));
      expect(deepHashObject('hello'), deepHashObject('hello'));
      expect(deepHashObject(null), deepHashObject(null));
    });

    test('different primitive values produce different hashes', () {
      expect(deepHashObject(1), isNot(deepHashObject(2)));
      expect(deepHashObject('a'), isNot(deepHashObject('b')));
    });

    test('same maps produce same hash', () {
      final a = {'x': 1, 'y': 2};
      final b = {'x': 1, 'y': 2};
      expect(deepHashObject(a), deepHashObject(b));
    });

    test('maps with same keys in different order produce same hash', () {
      final a = {'x': 1, 'y': 2};
      final b = {'y': 2, 'x': 1};
      expect(deepHashObject(a), deepHashObject(b));
    });

    test('maps with different values produce different hashes', () {
      final a = {'x': 1};
      final b = {'x': 2};
      expect(deepHashObject(a), isNot(deepHashObject(b)));
    });

    test('same lists produce same hash', () {
      expect(deepHashObject([1, 2, 3]), deepHashObject([1, 2, 3]));
    });

    test('lists with different order produce different hashes', () {
      expect(deepHashObject([1, 2, 3]), isNot(deepHashObject([3, 2, 1])));
    });

    test('nested structures produce same hash when equal', () {
      final a = {'key': [1, 2, {'nested': 'value'}]};
      final b = {'key': [1, 2, {'nested': 'value'}]};
      expect(deepHashObject(a), deepHashObject(b));
    });

    test('nested structures produce different hash when not equal', () {
      final a = {'key': [1, 2, {'nested': 'value'}]};
      final b = {'key': [1, 2, {'nested': 'different'}]};
      expect(deepHashObject(a), isNot(deepHashObject(b)));
    });
  });
}
