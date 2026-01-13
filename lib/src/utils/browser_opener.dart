import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

class BrowserOpener {
  const BrowserOpener();
  Future<bool> open(Uri uri) => uri.openInAppBrowser();
}
