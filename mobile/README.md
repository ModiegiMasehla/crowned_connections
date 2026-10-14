# Flutter source setup

This repository contains the Crowned Connections Flutter source under `lib/` and its dependency configuration.

If your Flutter installation does not already contain Android/iOS platform wrappers, from this directory run once:

```bash
flutter create .
```

Then keep the existing `lib/` and `pubspec.yaml` files and apply the Google Maps configuration in `../docs/GOOGLE_MAPS.md`.

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

For a physical Android device, replace the API URL with the LAN IP of the development machine.
