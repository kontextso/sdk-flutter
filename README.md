# Kontext.so Flutter SDK

The official Flutter SDK for integrating Kontext.so ads into your mobile applications.

## Requirements

- **Flutter**: 3.24.5 or newer
- A [Kontext.so publisher account](https://docs.kontext.so/publishers#getting-started-is-easy) to obtain your `publisherToken` and ad `code`.

## Installation

Add the package to your `pubspec.yaml`:

~~~yaml
dependencies:
  kontext_flutter_sdk: ^<latest_version>
~~~

Then install:

~~~bash
flutter pub get
~~~

## Quick start

Wrap your app (or the subtree that contains ad placements) with `AdsProvider`.
`AdsProvider` handles data fetching and needs access to the list of chat `messages`.

~~~dart
AdsProvider(
  publisherToken: 'your_publisher_token',
  userId: 'user_id',
  conversationId: 'conversation_id',
  messages: <Message>[], // keep this in sync with your chat
  child: YourChatWidget(),
)
~~~

## Display your first ad

An **ad slot** is a place in your UI where an ad is rendered.
In most cases, this will be under a chat message.
During onboarding, you receive a `code` for each ad slot or ad format you want to show.

Example using the `InlineAd` format:

~~~dart
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
~~~

## Integration notes

- Place `AdsProvider` high enough in the widget tree to cover all screens/areas that can show ads.
- Keep the `messages` list up to date so the SDK can determine when and where to render ads.

## Documentation

For advanced usage, supported formats, and configuration details, see the docs:
https://docs.kontext.so
