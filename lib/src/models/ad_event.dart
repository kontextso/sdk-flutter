import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;

/// Represents an advertisement-related event within the SDK.
///
/// Supported events:
///
/// ad.clicked
///  • The user has clicked the ad.
///  Payload:
///    id: Bid ID
///    content: Ad content
///    messageId: ID of the message
///    url: URL of the ad to be opened
///
/// ad.viewed
///  • The user has viewed the ad.
///  Payload:
///    id: Bid ID
///    content: Ad content
///    messageId: ID of the message
///
/// ad.filled
///  • Ad is available and can be rendered (bids array is not empty).
///  Payload: empty
///
/// ad.no-fill
///  • Ad is not available (bids array is empty).
///  Payload: empty
///
/// ad.render-started
///  • Triggered before the first token was received.
///  Payload:
///    id: Bid ID
///
/// ad.render-completed
///  • Triggered after the last token was received.
///  Payload:
///    id: Bid ID
///
/// ad.error
///  • Triggered when an error occurs.
///  Payload:
///    message: Error message
///    errCode: Error code
///
/// reward.granted
///  • Triggered when the user receives reward.
///  Payload:
///    id: Bid ID
///
/// video.started
///  • Video playback started.
///  Payload:
///    id: Bid ID
///
/// video.completed
///  • Video playback finished.
///  Payload:
///    id: Bid ID
class AdEvent {
  AdEvent({
    required this.name,
    this.code,
    this.payload = const {},
  });

  /// The name of the event (e.g., 'ad.clicked', 'ad.viewed').
  final String name;

  /// The ad format code that identifies the displayed ad.
  final String? code;

  /// Additional data associated with the event.
  final Json payload;

  /// Creates an [AdEvent] instance from a JSON object.
  factory AdEvent.fromJson(Json json) {
    try {
      return AdEvent(
        name: json['name'] as String,
        code: json['code'] as String?,
        payload: (json['payload'] as Json?) ?? {},
      );
    } catch (e, stack) {
      Logger.exception(e, stack);
    }
    return AdEvent(name: 'unknown', payload: {});
  }

  @override
  String toString() => 'AdEvent(name: $name, code: $code, payload: $payload)';
}
