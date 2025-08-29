enum NetworkType { wifi, cellular, ethernet, unknown }

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
  unknown('unknown');

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

  static Future<DeviceNetwork> init() async {
    return DeviceNetwork._(
      userAgent: null, // TODO
      type: null, // TODO
      detail: null, // TODO
      carrier: null, // TODO
    );
  }
}
