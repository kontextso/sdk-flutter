import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show ChromeSafariBrowser, WebUri, ChromeSafariBrowserSettings, InAppBrowser;
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/utils/helper_methods.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';

extension DeepHashExt on Object? {
  int get deepHash => deepHashObject(this);
}

extension ListExtension<E> on List<E> {
  E? firstWhereOrElse(bool Function(E element) test, {E Function()? orElse}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return orElse?.call();
  }

  E? lastWhereOrElse(bool Function(E element) test, {E Function()? orElse}) {
    for (int i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return orElse?.call();
  }

  List<E>? get nullIfEmpty {
    return isEmpty ? null : this;
  }
}

extension MessageListExtension on List<Message> {
  List<Message> getLastMessages({int count = 30}) {
    return length > count ? sublist(length - count) : this;
  }
}

extension MapExtension<K, V> on Map<K, V> {
  V? getOrNull(K key) {
    if (containsKey(key)) {
      return this[key];
    }
    return null;
  }
}

extension StringExtension on String {
  String? get nullIfEmpty {
    final cleaned = trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}

extension UriExtension on Uri {
  bool get isHttp {
    final scheme = this.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  bool get isImageAsset {
    final normalizedPath = path.toLowerCase();
    return normalizedPath.endsWith('.gif') ||
        normalizedPath.endsWith('.png') ||
        normalizedPath.endsWith('.jpg') ||
        normalizedPath.endsWith('.jpeg') ||
        normalizedPath.endsWith('.webp') ||
        normalizedPath.endsWith('.avif') ||
        normalizedPath.endsWith('.svg');
  }

  bool get isAtomexTrackerClick {
    final host = this.host.toLowerCase();
    if (host != 'trk.atomex.net') {
      return false;
    }
    final path = this.path.toLowerCase();
    return path.contains('tracker.fcgi/clk');
  }

  /// Extract and decode nested destination from common click tracker pattern:
  /// `...?url=https%3A%2F%2Fapp.appsflyer.com%2F...`
  Uri? get urlQueryParamAsUri {
    final raw = queryParameters['url']?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final direct = Uri.tryParse(raw);
    if (direct?.hasScheme == true) {
      return direct;
    }

    var decoded = raw;
    for (var i = 0; i < 3; i++) {
      try {
        final next = Uri.decodeComponent(decoded);
        if (next == decoded) {
          break;
        }
        decoded = next;
      } catch (_) {
        break;
      }

      final parsed = Uri.tryParse(decoded);
      if (parsed?.hasScheme == true) {
        return parsed;
      }
    }

    return null;
  }

  bool get isStore => isGooglePlay || isAppStore;

  bool get isGooglePlay {
    final host = this.host.toLowerCase();
    final scheme = this.scheme.toLowerCase();
    return host == 'play.google.com' || host == 'market.android.com' || scheme == 'market' || scheme == 'intent';
  }

  bool get isAppStore {
    final host = this.host.toLowerCase();
    final scheme = this.scheme.toLowerCase();
    return host == 'apps.apple.com' || scheme == 'itms-apps';
  }

  bool matchesAllowedOrigins(List<String> allowedOrigins) {
    final url = toString();
    return allowedOrigins.any(
      (origin) {
        if (url.startsWith(origin)) return true;
        try {
          return this.origin == origin || host == origin;
        } catch (_) {
          return host == origin;
        }
      },
    );
  }

  Future<bool> openInAppBrowser() async {
    try {
      final normalizedUri = isAppStore ? replace(scheme: 'https') : this;
      final webUri = WebUri.uri(normalizedUri);

      if (!isHttp) {
        await InAppBrowser.openWithSystemBrowser(url: webUri);
        return true;
      }

      await ChromeSafariBrowser().open(
        url: webUri,
        settings: ChromeSafariBrowserSettings(barCollapsingEnabled: true),
      );
      return true;
    } catch (e, stack) {
      Logger.exception(e, stack);
      return false;
    }
  }

  Uri replacePath(String newPath) {
    final params = queryParameters;
    return replace(path: newPath, queryParameters: params.isEmpty ? null : params);
  }
}

extension DoubleExtension on double {
  double? get nullIfNaN => isNaN ? null : this;
}
