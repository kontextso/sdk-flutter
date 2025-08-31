import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

enum NetworkType { wifi, cellular, ethernet, other }

enum NetworkDetail {
  twoG('2g'),
  threeG('3g'),
  fourG('4g'),
  fiveG('5g'),
  lte('lte'),
  nr('nr'),
  hspa('hspa'),
  edge('edge'),
  gprs('gprs'),
  other('other');

  const NetworkDetail(this.name);

  final String name;
}

class DeviceNetwork {
  DeviceNetwork._({
    required this.userAgent,
    required this.type,
    required this.detail,
    required this.carrier,
  });

  final String? userAgent;
  final NetworkType? type;
  final NetworkDetail? detail;
  final String? carrier;

  static const _ch = MethodChannel('kontext_flutter_sdk/device_network');

  Map<String, dynamic> toJson() => {
        if (userAgent != null) 'userAgent': userAgent,
        if (type != null) 'type': type!.name,
        if (detail != null) 'detail': detail!.name,
        if (carrier != null) 'carrier': carrier,
      };

  static Future<DeviceNetwork> init() async {
    if (kIsWeb) {
      return DeviceNetwork._(userAgent: null, type: null, detail: null, carrier: null);
    }

    String? userAgent;
    NetworkType? type;
    NetworkDetail? detail;
    String? carrier;

    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('getNetworkInfo');
      userAgent = m?['userAgent'] as String?;
      type = _getNetworkType(m?['type'] as String?);
      detail = _getNetworkDetail(m?['detail'] as String?);
      carrier = m?['carrier'] as String?;
    } catch (e) {
      Logger.error('Failed to get network info: $e');
    }

    return DeviceNetwork._(
      userAgent: userAgent,
      type: type,
      detail: detail,
      carrier: carrier,
    );
  }

  static NetworkType? _getNetworkType(String? type) {
    return NetworkType.values.firstWhereOrElse((t) => t.name == type);
  }

  static NetworkDetail? _getNetworkDetail(String? detail) {
    return NetworkDetail.values.firstWhereOrElse((d) => d.name == detail);
  }
}
