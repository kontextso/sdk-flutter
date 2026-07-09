# Kontext Flutter SDK

A lightweight Flutter SDK for integrating Kontext's AI-powered ads into your iOS and Android apps.

📚 Full documentation: [Kontext Flutter SDK](https://docs.kontext.so/sdk/flutter)

## iOS setup: SKAdNetwork attribution (required)

For install attribution (SKAdNetwork) to work, your **host app** must list Kontext's ad network
identifier in its `Info.plist`. Without this entry, ads still serve and render normally, but
Apple will not attribute installs — there is no error or warning; attribution silently never fires.

Add to your app's `ios/Runner/Info.plist` (or your app target's `Info.plist`):

```xml
<key>SKAdNetworkItems</key>
<array>
	<dict>
		<key>SKAdNetworkIdentifier</key>
		<string>mp7rpxwdrx.skadnetwork</string>
	</dict>
</array>
```

If your app already has an `SKAdNetworkItems` array (most apps with ads do), just append the
`mp7rpxwdrx.skadnetwork` entry to it. See the [example app's Info.plist](example/ios/Runner/Info.plist)
for a working reference. Shipping this change requires a regular App Store release of your app.
