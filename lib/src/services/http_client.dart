import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;

class HttpClient {
  HttpClient._internal(this.baseUrl, this._client);

  final String baseUrl;
  final http.Client _client;

  static HttpClient? _instance;

  factory HttpClient({String? baseUrl, http.Client? client}) {
    return _instance ??= HttpClient._internal(
      baseUrl ?? kDefaultAdServerUrl,
      client ?? http.Client(),
    );
  }

  static void resetInstance() {
    _instance = null;
  }

  Future<({http.Response response, Json data})> post(
    String path, {
    Duration timeout = const Duration(seconds: 60),
    Json? body,
    Json? headers,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            ...headers ?? {},
          },
          body: jsonEncode(body ?? {}),
        )
        .timeout(timeout);

    final resBody = response.body;
    if (resBody.isEmpty) {
      return (response: response, data: <String, dynamic>{});
    }

    final decoded = jsonDecode(resBody);
    if (decoded is! Json) {
      throw FormatException('Expected JSON object, got: $decoded');
    }

    return (response: response, data: decoded);
  }
}
