# Google Maps setup

V1 uses `google_maps_flutter`.

## Android

In a real generated Flutter project, add the Google Maps API key to the `<application>` section of:

`android/app/src/main/AndroidManifest.xml`

Use a restricted Android key in Google Cloud Console.

## iOS

Enable Maps SDK for iOS and add the key through `GMSServices.provideAPIKey(...)` in the iOS runner.

## APIs

For the V1 app, enable the Maps SDK needed by the platform. If you later add address autocomplete/geocoding, enable the appropriate Google Places/Geocoding APIs separately and apply API restrictions.

Never commit a production key to Git. Use platform-specific secrets/configuration in CI for release builds.
