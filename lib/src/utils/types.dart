import 'package:kontext_flutter_sdk/src/models/ad_event.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

typedef OnEventCallback = void Function(AdEvent event);
typedef Json = Map<String, dynamic>;

enum OpenIframeComponent {
  modal('open-component-iframe'),
  skoverlay('open-skoverlay-iframe');

  const OpenIframeComponent(this.type);

  final String type;

  static OpenIframeComponent? fromMessageType(dynamic type) {
    return OpenIframeComponent.values.firstWhereOrElse(
      (e) => e.type == (type is String ? type.toLowerCase() : null),
    );
  }
}
