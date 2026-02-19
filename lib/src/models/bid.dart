enum AdDisplayPosition { afterAssistantMessage, afterUserMessage }

class Akk {
  Akk({required this.jws});

  final String jws;

  static Akk? fromJson(Map<String, dynamic> json) {
    try {
      return Akk(jws: json['jws'] as String);
    } catch (_) {
      return null;
    }
}

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Akk && jws == other.jws;
  }

  @override
  int get hashCode => jws.hashCode;

  @override
  String toString() => 'Akk(jws: $jws)';
}

class AttributionFidelity {
  AttributionFidelity({
    required this.fidelity,
    required this.signature,
    required this.nonce,
    required this.timestamp,
  });

  final int fidelity;
  final String signature;
  final String nonce;
  final String timestamp;

  static AttributionFidelity? fromJson(Map<String, dynamic> json) {
    try {
      return AttributionFidelity(
        fidelity: json['fidelity'] as int,
        signature: json['signature'] as String,
        nonce: json['nonce'] as String,
        timestamp: json['timestamp'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttributionFidelity &&
            fidelity == other.fidelity &&
            signature == other.signature &&
            nonce == other.nonce &&
            timestamp == other.timestamp;
  }

  @override
  int get hashCode => Object.hash(fidelity, signature, nonce, timestamp);

  @override
  String toString() {
    return 'AttributionFidelity(fidelity: $fidelity, signature: $signature, nonce: $nonce, timestamp: $timestamp)';
  }
}

class Skan {
  Skan({
    required this.version,
    required this.network,
    required this.itunesItem,
    required this.sourceApp,
    this.sourceIdentifier,
    this.campaign,
    this.fidelities,
    this.nonce,
    this.timestamp,
    this.signature,
  });

  final String version;
  final String network;
  final String itunesItem;
  final String sourceApp;
  final String? sourceIdentifier;
  final String? campaign;
  final List<AttributionFidelity>? fidelities;
  final String? nonce;
  final String? timestamp;
  final String? signature;

  static Skan? fromJson(Map<String, dynamic> json) {
    try {
      return Skan(
        version: json['version'] as String,
        network: json['network'] as String,
        itunesItem: json['itunesItem'] as String,
        sourceApp: json['sourceApp'] as String,
        sourceIdentifier: json['sourceIdentifier'] as String?,
        campaign: json['campaign'] as String?,
        fidelities: (json['fidelities'] as List<dynamic>?)
            ?.map((e) => AttributionFidelity.fromJson(e as Map<String, dynamic>))
            .whereType<AttributionFidelity>()
            .toList(),
        nonce: json['nonce'] as String?,
        timestamp: json['timestamp'] as String?,
        signature: json['signature'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Skan &&
            version == other.version &&
            network == other.network &&
            itunesItem == other.itunesItem &&
            sourceApp == other.sourceApp &&
            sourceIdentifier == other.sourceIdentifier &&
            campaign == other.campaign &&
            nonce == other.nonce &&
            timestamp == other.timestamp &&
            signature == other.signature;
  }

  @override
  int get hashCode => Object.hash(
        version,
        network,
        itunesItem,
        sourceApp,
        sourceIdentifier,
        campaign,
        nonce,
        timestamp,
        signature,
      );

  @override
  String toString() {
    return 'Skan(version: $version, network: $network, itunesItem: $itunesItem, '
        'sourceApp: $sourceApp, sourceIdentifier: $sourceIdentifier, campaign: $campaign, '
        'nonce: $nonce, timestamp: $timestamp, signature: $signature)';
  }
}


class Bid {
  Bid({
    required this.id,
    required this.code,
    this.revenue,
    required this.position,
    this.akk,
    this.skan,
  });

  final String id;
  final String code;
  final double? revenue;
  final AdDisplayPosition position;
  final Akk? akk;
  final Skan? skan;

  bool get isAfterAssistantMessage => position == AdDisplayPosition.afterAssistantMessage;

  bool get isAfterUserMessage => position == AdDisplayPosition.afterUserMessage;

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['bidId'] as String,
      code: json['code'] as String,
      revenue: _parseRevenue(json['revenue']),
      position: AdDisplayPosition.values.firstWhere(
        (position) => position.name == '${json['adDisplayPosition']}',
        orElse: () => AdDisplayPosition.afterAssistantMessage,
      ),
      akk: _parseAkk(json['akk']),
      skan: _parseSkan(json['skan']),
    );
  }

  static Akk? _parseAkk(Object? value) {
    if (value == null) return null;
    try {
      return Akk.fromJson(value as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Skan? _parseSkan(Object? value) {
    if (value == null) return null;
    try {
      return Skan.fromJson(value as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static double? _parseRevenue(Object? value) {
    if (value == null) return null;

    if (value is num) {
      if (!value.isFinite) return null;
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed == null || !parsed.isFinite) return null;
      return parsed;
    }

    return null;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Bid &&
            id == other.id &&
            code == other.code &&
            revenue == other.revenue &&
            position == other.position &&
            akk == other.akk &&
            skan == other.skan;
  }

  @override
  int get hashCode => Object.hash(id, code, revenue, position, akk, skan);

  @override
  String toString() {
    return 'Bid(id: $id, code: $code, revenue: $revenue, position: $position, akk: $akk, skan: $skan)';
  }
}
