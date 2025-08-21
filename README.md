# Kontext.so Flutter SDK

The official Flutter SDK for integrating Kontext.so ads into your mobile applications.

## Requirements

- **Flutter**: 3.24.0 or newer
- **Dart**: 3.5.0 or newer
- **Android**: `minSdkVersion >= 21`, `compileSdk >= 34`, [AGP](https://developer.android.com/build/releases/gradle-plugin) version `>= 7.3.0` (use [Android Studio - Android Gradle plugin Upgrade Assistant](https://developer.android.com/build/agp-upgrade-assistant) for help), support for `androidx` (see [AndroidX Migration](https://flutter.dev/docs/development/androidx-migration) to migrate an existing app)
- **iOS**: `12.0+, --ios-language swift`, Xcode version `>= 15.0`
- A [Kontext.so publisher account](https://docs.kontext.so/publishers#getting-started-is-easy) to obtain your `publisherToken` and ad `code`.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  kontext_flutter_sdk: ^<latest_version>
```

Then install:

```bash
flutter pub get
```

## WebView prerequisites (`flutter_inappwebview`)

This SDK renders ads inside a WebView using [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview).
To avoid initialization issues, add this to your app entry point:

```dart
import 'package:flutter/widgets.dart';

void main() {
  // Must be first so plugins are ready.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}
```

Make sure your project meets the Android min/compile SDK and iOS/Xcode requirements listed above.
If you run into other issues, verify your project meets the plugin’s platform requirements: [https://inappwebview.dev/docs/intro/](https://inappwebview.dev/docs/intro/)

## Quick start

Wrap your app (or the subtree that contains ad placements) with `AdsProvider`.
`AdsProvider` handles data fetching and needs access to the list of chat `messages`.

```dart
import 'package:kontext_flutter_sdk/kontext_flutter_sdk.dart';

AdsProvider(
  publisherToken: 'your_publisher_token',
  userId: 'user_id',
  conversationId: 'conversation_id',
  enabledPlacementCodes: ['your_code'], // ad codes you received during onboarding
  messages: <Message>[], // keep this in sync with your chat
  child: YourChatWidget(),
)
```

## Display your first ad

An **ad slot** is a place in your UI where an ad is rendered.
In most cases, this will be under a chat message.
During onboarding, you receive a `code` for each ad slot or ad format you want to show.

Example using the `InlineAd` format:

```dart
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final message = messages[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message.content),
        InlineAd(
          code: 'your_code',
          messageId: message.id,
        ),
      ],
    );
  },
)
```

## Integration notes

- Place `AdsProvider` high enough in the widget tree to cover all screens/areas that can show ads.
- Keep the `messages` list up to date so the SDK can determine when and where to render ads.

## Documentation

For advanced usage, supported formats, and configuration details, see the docs:
https://docs.kontext.so/sdk/flutter

## License
This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
