#!/usr/bin/env bash
# Run ONCE from the project root:  bash setup_platforms.sh
# Generates android/ios/etc. (keeps lib/ and pubspec.yaml) and applies the
# native configuration needed by the `http` and `hive_flutter` dependencies.
set -e

flutter create --project-name post_reader_favorites --org edu.pnc --platforms=android,ios,macos,web,windows,linux .
flutter pub get

# --- Android: http needs INTERNET permission (debug/profile have it by default,
#     RELEASE builds do NOT, so add it to the main manifest) ----------------
MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  sed -i 's#<manifest xmlns:android="http://schemas.android.com/apk/res/android">#&\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$MANIFEST"
  echo "Added INTERNET permission to AndroidManifest.xml"
fi

# --- macOS: sandboxed apps need the network client entitlement --------------
for f in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
  if [ -f "$f" ] && ! grep -q "com.apple.security.network.client" "$f"; then
    sed -i 's#</dict>#\t<key>com.apple.security.network.client</key>\n\t<true/>\n</dict>#' "$f"
    echo "Added network.client entitlement to $f"
  fi
done

# iOS: nothing to add. JSONPlaceholder is HTTPS, so App Transport Security is satisfied.
# Hive's storage path comes from path_provider (a transitive dependency of
# hive_flutter) - its native plugins are registered automatically by `flutter pub get`.

echo "Done. Run:  flutter run"
