import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;

/// Enum representing all possible ad event types.
enum AdEventType {
  adClicked('ad.clicked'),
  adViewed('ad.viewed'),
  adFilled('ad.filled'),
  adNoFill('ad.no-fill'),
  adRenderStarted('ad.render-started'),
  adRenderCompleted('ad.render-completed'),
  adError('ad.error'),
  rewardGranted('reward.granted'),
  videoStarted('video.started'),
  videoCompleted('video.completed'),
  unknown('unknown');

  const AdEventType(this.value);

  /// The string value of the event type.
  final String value;

  /// Creates an [AdEventType] from a string value.
  static AdEventType fromString(String? value) {
    return AdEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AdEventType.unknown,
    );
  }
}

/// Represents an advertisement-related event within the SDK.
class AdEvent {
  AdEvent({
    required this.type,
    this.code,
    this.skipCode,
    this.id,
    this.content,
    this.messageId,
    this.url,
    this.format,
    this.area,
    this.message,
    this.errCode,
  });

  static const String skipCodeAdsDisabled = 'ads_disabled';
  static const String skipCodeUnFilledBid = 'unfilled_bid';
  static const String skipCodeIllegalContent = 'illegal_content';
  static const String skipCodeContextTooShort = 'context_too_short';
  static const String skipCodeTrafficDropped = 'traffic_dropped';
  static const String skipCodeSessionDisabled = 'session_disabled';
  static const String skipCodeAdGenerationSkipped = 'ad_generation_skipped';
  static const String skipCodeUnknown = 'unknown';
  static const String skipCodeError = 'error';

  /// The type of the ad event.
  final AdEventType type;

  /// The ad format code that identifies the displayed ad.
  final String? code;

  /// The skip code indicating the reason for [AdEventType.adNoFill] events.
  /// This can be one of the predefined AdEvent.skipCode* constants (e.g., 'unfilled_bid', 'session_disabled', 'unknown', 'error'),
  /// or a custom code provided by the server.
  final String? skipCode;

  /// Bid ID (used in multiple events).
  final String? id;

  /// Ad content (used in [AdEventType.adClicked] and [AdEventType.adViewed]).
  final String? content;

  /// ID of the message (used in [AdEventType.adClicked] and [AdEventType.adViewed]).
  final String? messageId;

  /// URL of the ad to be opened (used in [AdEventType.adClicked]).
  final String? url;

  /// Format (used in [AdEventType.adClicked] and [AdEventType.adViewed]).
  final String? format;

  /// Area where the user clicked (used in [AdEventType.adClicked]).
  final String? area;

  /// Error message (used in [AdEventType.adError]).
  final String? message;

  /// Error code (used in [AdEventType.adError]).
  final String? errCode;

  /// Creates an [AdEvent] instance from a JSON object.
  factory AdEvent.fromJson(Json json) {
    try {
      final payloadData = (json['payload'] as Json?) ?? {};
      return AdEvent(
        type: AdEventType.fromString(json['name'] as String?),
        code: json['code'] as String?,
        id: payloadData['id'] as String?,
        content: payloadData['content'] as String?,
        messageId: payloadData['messageId'] as String?,
        url: payloadData['url'] as String?,
        format: payloadData['format'] as String?,
        area: payloadData['area'] as String?,
        message: payloadData['message'] as String?,
        errCode: payloadData['errCode'] as String?,
      );
    } catch (e, stack) {
      Logger.exception(e, stack);
    }
    return AdEvent(type: AdEventType.unknown);
  }

  @override
  String toString() => 'AdEvent(type: $type, code: $code, skipCode: $skipCode, id: $id, content: $content, messageId: $messageId, url: $url, format: $format, area: $area, message: $message, errCode: $errCode)';
}
