import 'package:flutter_inappwebview/flutter_inappwebview.dart' show WebUri;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

class KontextUrlBuilder {
  KontextUrlBuilder({required String baseUrl, String? path})
      : _baseUrl = baseUrl,
        _path = path;

  final String _baseUrl;
  String? _path;

  final Map<String, String> _params = {};

  KontextUrlBuilder setPath(String path) {
    _path = path;
    return this;
  }

  KontextUrlBuilder addParam(String key, String? value) {
    if (value != null && value.isNotEmpty) {
      _params[key] = value;
    }
    return this;
  }

  Uri? buildUri() {
    final base = Uri.tryParse(_baseUrl);
    if (base == null) {
      Logger.error('Invalid base URL: $_baseUrl');
      return null;
    }

    final resolved = _path != null ? base.resolve(_path!) : base;
    final merged = {...resolved.queryParameters, ..._params};
    return resolved.replace(queryParameters: merged.isEmpty ? null : merged);
  }

  WebUri? buildWebUri() {
    final uri = buildUri();
    if (uri == null) {
      return null;
    }
    return WebUri.uri(uri);
  }
}
