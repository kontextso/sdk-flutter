import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kontext_flutter_sdk/src/widgets/constants.dart';

typedef Json = Map<String, dynamic>;

class HttpClient {
  HttpClient._internal(this.baseUrl);

  final String baseUrl;

  static HttpClient? _instance;

  factory HttpClient({String? baseUrl}) {
    return _instance ??= HttpClient._internal(baseUrl ?? kDefaultAdServerUrl);
  }

  static void resetInstance() {
    _instance = null;
  }

  Future<({http.Response response, Json data})> post(String path, {Json? body}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );

    return (response: response, data: jsonDecode(response.body) as Json);
  }
}
