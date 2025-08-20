# Kontext Flutter Chat Demo

This is a Flutter demo app that shows how to integrate the [Kontext Flutter SDK](https://pub.dev/packages/kontext_flutter_sdk) into a simple chat interface.
It supports light/dark mode toggling, inline ads under messages, and a simulated assistant response.

## ✨ Features

- iOS & Android support
- Light/Dark theme toggle
- Simple chat interface with user and assistant messages
- Inline ads displayed using `InlineAd` widget from Kontext SDK
- Simulated assistant replies for testing

## 📂 Project Structure

```
lib/
├── constants.dart # Publisher token & placement code
└── main.dart # App entry point, chat UI, ad integration
ios/
android/
pubspec.yaml
```

## 🛠️ Requirements

- **Flutter**: 3.24.0 or newer
- **Dart**: 3.5.0 or newer
- Kontext Flutter SDK

## 🚀 Getting Started

1. **Install dependencies**
   ```bash
   flutter pub get
   ```
2. **Set your Kontext SDK credentials**

In `lib/constants.dart`:

```dart
const String kPublisherToken = 'your-publisher-token';
const String kPlacementCode = 'your-placement-code';
```

4. **Run the app**

```bash
flutter run
```

## 📖 How it Works

1. Theme Toggle
The app uses a ThemeMode variable in DemoApp to toggle between light and dark themes.

2. AdsProvider
The entire chat area is wrapped with AdsProvider from the Kontext SDK, which receives:

publisherToken

userId and conversationId

Current chat messages

enabledPlacementCodes

3. Messages & Inline Ads
Each chat message is followed by an InlineAd widget, which displays an ad relevant to that message.

4. Simulated Assistant
When the user sends a message, a fake assistant reply appears after 2 seconds, so ads can be tested without a backend.


## 📖 How it Works

### 1. Theme Toggle
The app uses a `ThemeMode` variable in `DemoApp` to toggle between light and dark themes.

### 2. AdsProvider
The entire chat area is wrapped with `AdsProvider` from the Kontext SDK, which receives:
- `publisherToken`
- `userId` and `conversationId`
- Current chat `messages`
- `enabledPlacementCodes`

### 3. Messages & Inline Ads
Each chat message is followed by an `InlineAd` widget, which displays an ad relevant to that message.

### 4. Simulated Assistant
When the user sends a message, a fake assistant reply appears after 2 seconds, so ads can be tested without a backend.

---

## ⚠️ Notes
- This is a demo app — for production, replace the simulated assistant logic with your real backend or AI assistant.
- Make sure your `kPublisherToken` and `kPlacementCode` are correct, otherwise no ads will load.
- The app currently supports **only iOS and Android**. Other platform folders were removed for minimal setup.

---

## 🧹 Clean Build
If you run into issues, clean and rebuild:

```bash
flutter clean
flutter pub get
flutter run
```
