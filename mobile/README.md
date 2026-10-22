# Flutter setup and verification

This archive contains Flutter source and tests, but not complete Android/iOS
platform runners. The supplied AndroidManifest.xml is a configuration fragment,
not a launchable Android project.

With Flutter 3.24.5 installed, first run:

```bash
flutter pub get
flutter analyze
flutter test
```

For a device build, generate runners in a separate temporary project so Flutter
does not overwrite this app:

```bash
flutter create --platforms=android,ios --org za.co.crownedconnections crowned_connections
```

Copy its `android/` and `ios/` directories into this `mobile/` directory. Merge
the permissions and Maps metadata from the original Android manifest into
the generated manifest; preserve the generated activity and launcher intent.
Use HTTP cleartext only for local development; use HTTPS for releases.
Follow `../docs/GOOGLE_MAPS.md` for restricted platform API keys.
Add NSLocationWhenInUseUsageDescription to ios/Runner/Info.plist with:
"Your location is used only to find nearby salons when you search."
Configure Maps in the generated AppDelegate. Build iOS on macOS with Xcode.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

Use http://127.0.0.1:5000/api for the iOS simulator, or your computer's LAN
address for a physical phone. Verify permission denial, Maps, secure storage,
booking and owner decisions on real/emulated devices before submission.
South African appointment display is independent of the device timezone.
