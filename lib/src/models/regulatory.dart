import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

/// Regulatory compliance information.
class Regulatory {
  Regulatory({
    this.gdpr,
    this.gdprConsent,
    this.coppa,
    this.gpp,
    this.gppSid,
    this.usPrivacy,
  });

  /// Flag that indicates whether or not the request is subject to GDPR regulations (0 = No, 1 = Yes, null = Unknown).
  final int? gdpr;

  /// When GDPR regulations are in effect this attribute contains the Transparency and Consent Framework's Consent String data structure
  ///
  /// https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md#about-the-transparency--consent-string-tc-string
  final String? gdprConsent;

  /// Flag whether the request is subject to COPPA (0 = No, 1 = Yes, null = Unknown).
  ///
  /// https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa
  final int? coppa;

  /// Global Privacy Platform (GPP) consent string.
  ///
  /// https://github.com/InteractiveAdvertisingBureau/Global-Privacy-Platform
  final String? gpp;

  /// List of the section(s) of the GPP string which should be applied for this transaction.
  final List<int>? gppSid;

  /// Communicates signals regarding consumer privacy under US privacy regulation under CCPA and LSPA.
  ///
  /// https://github.com/InteractiveAdvertisingBureau/USPrivacy/blob/master/CCPA/US%20Privacy%20String.md
  final String? usPrivacy;

  Map<String, dynamic> toJson() {
    final consent = gdprConsent?.nullIfEmpty;
    final gppNullIfEmpty = gpp?.nullIfEmpty;
    final privacy = usPrivacy?.nullIfEmpty;
    return {
      if (gdpr != null) 'gdpr': gdpr,
      if (consent != null) 'gdprConsent': consent,
      if (coppa != null) 'coppa': coppa,
      if (gppNullIfEmpty != null) 'gpp': gppNullIfEmpty,
      if (gppSid != null) 'gppSid': gppSid,
      if (privacy != null) 'usPrivacy': privacy,
    };
  }
}
