import 'package:kontext_flutter_sdk/src/models/bid.dart' show Skan;

Map<String, dynamic> skanToMap(Skan skan) => {
  'version': skan.version,
  'network': skan.network,
  'itunesItem': skan.itunesItem,
  'sourceApp': skan.sourceApp,
  if (skan.sourceIdentifier != null) 'sourceIdentifier': skan.sourceIdentifier,
  if (skan.campaign != null) 'campaign': skan.campaign,
  if (skan.nonce != null) 'nonce': skan.nonce,
  if (skan.timestamp != null) 'timestamp': skan.timestamp,
  if (skan.signature != null) 'signature': skan.signature,
  if (skan.fidelities != null)
    'fidelities': skan.fidelities!
        .map((f) => {
              'fidelity': f.fidelity,
              'nonce': f.nonce,
              'timestamp': f.timestamp,
              'signature': f.signature,
            })
        .toList(),
};