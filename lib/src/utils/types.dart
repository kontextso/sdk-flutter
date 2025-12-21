import 'package:kontext_flutter_sdk/src/models/ad_event.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

typedef OnEventCallback = void Function(AdEvent event);
typedef Json = Map<String, dynamic>;

enum OpenIframeComponent {
  modal({'open-component-iframe', 'close-component-iframe'}),
  skoverlay({'open-skoverlay-iframe', 'close-skoverlay-iframe'}),
  skstoreproduct({'open-skstoreproduct-iframe', 'close-skstoreproduct-iframe'});

  const OpenIframeComponent(this.types);

  final Set<String> types;

  static OpenIframeComponent? fromMessageType(Object? type) {
    if (type is! String) return null;
    return OpenIframeComponent.values.firstWhereOrElse(
      (component) => component.types.contains(type),
    );
  }
}
