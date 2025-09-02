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

## Configuration

### 1. Character

Firstly, prepare information about assistant's Character if it is relevant for this conversation.

```dart
final character = Character(
  id: 'character_id', // Unique identifier for the character.
  name: 'character_name', // Name of the character.
  avatarUrl: 'https://example.com/avatar.png', // URL of the character's avatar image.
  isNsfw: false, // <bool> Whether the character is NSFW (Not Safe For Work).
  greeting: 'character_greeting', // A greeting message from the character.
  persona: 'character_persona', // A description of the character's persona.
  tags: ['tag1', 'tag2'], // Tags associated with the character.
  additionalProperties: {'key': 'value'}, // Additional properties that can be added to the character.
);
```

### 2. Regulatory

Secondly, prepare information about regulations.

```dart
final regulatory = Regulatory(
  // <int> Flag that indicates whether or not the request is subject to GDPR regulations (0 = No, 1 = Yes, null = Unknown).
  gdpr: 0,
  // Transparency and Consent Framework's Consent String data structure
  gdprConsent: 'gdpr_consent_string',
  // <int> Flag whether the request is subject to COPPA (0 = No, 1 = Yes, null = Unknown).
  coppa: 0,
  // Global Privacy Platform (GPP) consent string.
  gpp: 'gpp_consent_string',
  // List of the section(s) of the GPP string which should be applied for this transaction.
  gppSid: [1, 2],
  // Communicates signals regarding consumer privacy under US privacy regulation under CCPA and LSPA.
  usPrivacy: 'us_privacy_string',
);
```

## Quick start

Wrap your app (or the subtree that contains ad placements) with `AdsProvider`.
`AdsProvider` handles data fetching and needs access to the list of chat `messages`.

```dart
import 'package:kontext_flutter_sdk/kontext_flutter_sdk.dart';

AdsProvider(
  publisherToken: 'your_publisher_token', // Your unique publisher token.
  userId: 'user_id', // A unique string that should remain the same during the user’s lifetime.
  conversationId: 'conversation_id', // Unique identifier of the conversation.
  enabledPlacementCodes: ['your_code'], // A list of enabled placement codes for the ads.
  // A list of messages between the assistant and the user. Keep this in sync with your chat.
  messages: <Message>[],
  character: character, // Character information prepared earlier.
  advertisingId: 'advertising_id', // Device-specific identifier provided by the operating systems (IDFA/GAID)
  vendorId: 'vendor_id', // Vendor-specific ID.
  regulatory: regulatory, // Regulatory information prepared earlier.
  // Used to pass publisher-specific information to Kontext. Contents will be discussed with your account manager if needed.
  otherParams: {'theme': 'dark'},
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

> 💡 **Note:** `InlineAd` does not always display an ad — whether an ad is shown depends on the context of the ongoing conversation.
> If there is no ad to display, `InlineAd` automatically returns a `const SizedBox.shrink()`, so it won’t take up any extra space in your layout.


## Integration notes

- Place `AdsProvider` high enough in the widget tree to cover all screens/areas that can show ads.
- Keep the `messages` list up to date so the SDK can determine when and where to render ads.

## Troubleshooting

### Missing plugin warnings

If you see warnings like `MissingPluginException` or errors about a plugin not being registered, try the following:

```bash
flutter clean
flutter pub get
```

This clears cached build artifacts and ensures plugins are re-registered.
If the problem persists, try rebuilding your app `flutter run` or restarting your IDE.

## Documentation

For more information, see the documentation: [https://docs.kontext.so/sdk/flutter](https://docs.kontext.so/sdk/flutter)

## License
This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
