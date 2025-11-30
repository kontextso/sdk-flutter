import 'package:kontext_flutter_sdk/src/models/ad_event.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

typedef OnEventCallback = void Function(AdEvent event);
typedef Json = Map<String, dynamic>;

enum OpenIframeComponent {
  modal,
  skoverlay;

  static OpenIframeComponent? fromValue(dynamic value) {
    return OpenIframeComponent.values.firstWhereOrElse(
      (e) => e.name == (value is String ? value.toLowerCase() : null),
    );
  }
}
