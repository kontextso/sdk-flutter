import 'dart:convert';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

class HttpClient {
  HttpClient._internal(this.baseUrl);

  final String baseUrl;

  static final HttpClient _instance = HttpClient._internal('https://server.develop.megabrain.co');

  factory HttpClient() => _instance;

  Future<Json> post(String path, {Json? body}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );

    print("Response status: ${response.statusCode}");
    return jsonDecode(response.body) as Json;
  }
}
