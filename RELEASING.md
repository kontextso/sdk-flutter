# Releasing

- This document describes the process for cutting a new release of the **Kontext Flutter SDK**.
- Follow these steps to ensure consistency across releases.
- Replace version `1.0.0` with the proper one instead.

> Version tags use a `v` prefix (e.g. `v1.0.0`) to trigger the publish workflow.
> The version inside `pubspec.yaml` and `constants.dart` must NOT have the `v` prefix (e.g. `1.0.0`).

---

## 1. Create a release branch and test

1. Checkout branch `main`
2. Pull the latest changes
3. Create a new branch `release/1.0.0`
4. Make sure it builds: `flutter pub get && flutter analyze`
5. Run tests and make sure they are green: `flutter test ./test`
6. Run the example app on iOS and Android and make sure it's OK

## 2. Safety review

Before updating any version numbers, compare the new release against the previous one and verify it is safe to ship.

1. Open the GitHub diff between the previous tag and the current release branch:
   ```
   https://github.com/kontextso/sdk-flutter/compare/vPREV...vNEW
   ```
2. Review all changed files with a focus on:
   - **Native iOS/Android code** — check for iOS version requirement bumps, API changes, hard failures on missing data
   - **Public Dart API** — check for breaking changes in models, widgets, or services
   - **Privacy manifest** — verify `PrivacyInfo.xcprivacy` changes are intentional
   - **Dependencies** — review any version bumps in `pubspec.yaml` or `podspec`
3. Write a short review covering:
   - What is safe ✅
   - What to watch out for ⚠️
   - Final verdict (safe / needs more testing)
4. Post the review to the [#sdk-flutter](https://megabrainco.slack.com/archives/C095WJMH01X) Slack channel before proceeding.

## 3. Update the changelog

Edit `CHANGELOG.md` to include the new release notes at the top.

Standard release:
```markdown
## 1.0.0
* Add new feature.
* Fix some bug.
* Remove old feature.
```

If the release contains breaking changes, add a `### Breaking` section before the bullet points:
```markdown
## 2.0.0
### Breaking
Short description of what changed and what integrators need to do.

* Add new feature.
* Fix some bug.
```

## 4. Update pubspec.yaml

Update the version field in `pubspec.yaml`:

```yaml
version: 1.0.0
```

## 5. Update SDK version constant

Update the version in `lib/src/utils/constants.dart`:

```dart
const kSdkVersion = '1.0.0';
```

## 6. Commit changes

```bash
git add CHANGELOG.md pubspec.yaml lib/src/utils/constants.dart
git commit -m "Prepare release 1.0.0"
```

## 7. Open pull request

1. Create a PR to `main` named: "Release version 1.0.0" and use the last changelog entry as the PR description.
2. Merge the PR to `main`.

## 8. Create an annotated tag

The tag must be on a commit reachable from `main` — the publish workflow enforces this.

```bash
git checkout main
git pull
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
```

## 9. Approve the publish workflow

Pushing the tag triggers the `publish.yml` GitHub Actions workflow:

1. It verifies the tag is on `main`
2. Runs `pana` analysis and `dart pub publish --dry-run`
3. Pauses for **manual approval** in the `pubdev-release` environment
4. Go to the GitHub Actions run, review the pana/dry-run reports, and approve to publish to pub.dev

## 10. Verify

1. Check that the version is available on the [pub.dev page](https://pub.dev/packages/kontext_flutter_sdk).
2. Integrate the new version into the internal testing app and confirm it builds and runs.
3. Release the internal testing app with the updated SDK version.
