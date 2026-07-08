# Development

## Prerequisites

- [Homebrew](https://brew.sh)
- Flutter: `brew install --cask flutter`
- Xcode (for iOS simulator): install from the App Store
- Verify your setup: `flutter doctor`

## Getting started

```bash
git clone git@github.com:kontextso/sdk-flutter.git
cd sdk-flutter
flutter pub get
open -a Simulator
cd example
flutter run
```

## Project structure

```
lib/
  src/
    device_app_info/   # Device and app metadata collection
    models/            # Data models
    services/          # Core SDK services
    utils/             # Utilities
    widgets/           # UI components (ad views)
  kontext_flutter_sdk.dart  # Public API entry point
example/               # Example app
test/                  # Unit tests
```

## Useful commands

**Setup & dependencies**
| Command | Description |
|---|---|
| `flutter doctor` | Check environment health |
| `flutter pub get` | Install dependencies |
| `flutter pub upgrade` | Upgrade dependencies |
| `flutter pub add <package>` | Add a dependency |
| `flutter pub outdated` | Show outdated packages |

**Running**
| Command | Description |
|---|---|
| `flutter run` | Run on connected device/simulator |
| `flutter run -d chrome` | Run in browser |
| `flutter run --release` | Run in release mode |
| `flutter devices` | List connected devices/simulators |
| `flutter logs` | Show device logs |

**Building**
| Command | Description |
|---|---|
| `flutter build ios` | Build iOS |
| `flutter build apk` | Build Android APK |
| `flutter build appbundle` | Build Android App Bundle |

**Code quality**
| Command | Description |
|---|---|
| `flutter analyze` | Static analysis / lint |
| `flutter format .` | Format all Dart files |
| `flutter clean` | Clear build cache (fixes many weird issues) |

**Testing**
| Command | Description |
|---|---|
| `flutter test` | Run all tests |
| `flutter test test/my_test.dart` | Run a single file |
| `flutter test --coverage` | Run with coverage |

## Code coverage

Requires `lcov`: `brew install lcov`

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Release process

See [RELEASING.md](RELEASING.md).
