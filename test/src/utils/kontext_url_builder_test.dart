import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:kontext_flutter_sdk/src/utils/kontext_url_builder.dart';

void main() {
  test('constructor with baseUrl only', () {
    final uri = KontextUrlBuilder(baseUrl: 'https://example.com').buildUri();
    expect(uri?.toString(), 'https://example.com');
  });

  test('constructor with baseUrl and path', () {
    final uri = KontextUrlBuilder(baseUrl: 'https://example.com', path: '/api').buildUri();
    expect(uri?.toString(), 'https://example.com/api');
  });

  test('addParam method', () {
    final uri =
        KontextUrlBuilder(baseUrl: 'https://example.com').addParam('key1', 'value1').addParam('key2', 'value2').buildUri();
    expect(uri?.toString(), 'https://example.com?key1=value1&key2=value2');
  });

  test('replacePath method', () {
    final uri = KontextUrlBuilder(baseUrl: 'https://example.com', path: '/api/frame')
        .addParam('key1', 'value1')
        .addParam('key2', 'value2').buildUri();
    final newUri = uri?.replacePath('/newApi/modal');
    expect(newUri?.toString(), 'https://example.com/newApi/modal?key1=value1&key2=value2');
  });
}
