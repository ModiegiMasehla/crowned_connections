import 'package:crowned_connections/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

/// Values of geolocator's `LocationPermission` enum as sent over the platform channel.
const _denied = 0;
const _deniedForever = 1;
const _whileInUse = 2;

/// Replaces the location mock installed by `testApp` and records every call
/// the plugin receives, so tests can check what the app asked for.
List<String> mockLocation({
  bool servicesEnabled = true,
  required int permission,
  int? permissionAfterRequest,
  double latitude = -25.7479,
  double longitude = 28.2293,
}) {
  final calls = <String>[];
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(channel, (call) async {
    calls.add(call.method);
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return servicesEnabled;
      case 'checkPermission':
        return permission;
      case 'requestPermission':
        return permissionAfterRequest ?? permission;
      case 'getCurrentPosition':
        return <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.utc(2026, 10, 16).millisecondsSinceEpoch,
          'accuracy': 5.0,
          'altitude': 1200.0,
          'altitude_accuracy': 1.0,
          'heading': 0.0,
          'heading_accuracy': 0.0,
          'speed': 0.0,
          'speed_accuracy': 0.0,
          'is_mocked': false,
        };
    }
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void homeRoutes(FakeApi api) {
    api.json('GET', '/auth/me', {
      'user': {'id': 'u1', 'role': 'CUSTOMER'},
    });
    api.json('GET', '/search', {
      'results': [
        {
          'id': 's1',
          'name': 'Crowned Beauty Studio',
          'city': 'Pretoria',
          'province': 'Gauteng',
          'rating_avg': 4.8,
          'distance_km': 1.5,
        },
      ],
    });
  }

  Future<void> search(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Knotless Braids');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
  }

  testApp('sends the coordinates and says it is using the current location when permission is granted',
      (tester, api) async {
    mockLocation(permission: _whileInUse);
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester);

    final query = api.requestsTo('GET', '/search').single.url.queryParameters;
    expect(query['lat'], '-25.7479');
    expect(query['lng'], '28.2293');
    expect(find.text('Using current location'), findsOneWidget);
    expect(find.text('Near my location'), findsNothing);
    expect(find.text('Crowned Beauty Studio'), findsOneWidget);
  }, routes: homeRoutes);

  testApp('asks for permission when it has not been decided yet, then uses the location', (tester, api) async {
    final calls = mockLocation(permission: _denied, permissionAfterRequest: _whileInUse);
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester);

    expect(calls, contains('requestPermission'));
    expect(api.requestsTo('GET', '/search').single.url.queryParameters['lat'], '-25.7479');
    expect(find.text('Using current location'), findsOneWidget);
  }, routes: homeRoutes);

  testApp('does not ask for location until the user searches', (tester, api) async {
    final calls = mockLocation(permission: _denied, permissionAfterRequest: _whileInUse);
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    expect(find.text('Near my location'), findsOneWidget);
  }, routes: homeRoutes);

  testApp('still searches, without coordinates, when the user refuses permission', (tester, api) async {
    mockLocation(permission: _denied, permissionAfterRequest: _denied);
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester);

    final query = api.requestsTo('GET', '/search').single.url.queryParameters;
    expect(query.containsKey('lat'), isFalse);
    expect(query.containsKey('lng'), isFalse);
    expect(find.text('Location permission was not granted. You can still search manually.'), findsOneWidget);
    expect(find.text('Crowned Beauty Studio'), findsOneWidget);
    expect(find.text('Near my location'), findsOneWidget);
  }, routes: homeRoutes);

  testApp('never re-prompts when permission is permanently denied', (tester, api) async {
    final calls = mockLocation(permission: _deniedForever);
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester);

    expect(calls, isNot(contains('requestPermission')));
    expect(calls, isNot(contains('getCurrentPosition')));
    expect(find.text('Location permission was not granted. You can still search manually.'), findsOneWidget);
    expect(api.requestsTo('GET', '/search').single.url.queryParameters.containsKey('lat'), isFalse);
  }, routes: homeRoutes);

  testApp('forgets an earlier location when a later search has none (nothing is kept)', (tester, api) async {
    mockLocation(permission: _whileInUse);
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester);
    expect(find.text('Using current location'), findsOneWidget);

    // The user switches location services off, then searches again.
    mockLocation(servicesEnabled: false, permission: _whileInUse);
    await search(tester);

    final searches = api.requestsTo('GET', '/search');
    expect(searches, hasLength(2));
    expect(searches.first.url.queryParameters.containsKey('lat'), isTrue);
    expect(searches.last.url.queryParameters.containsKey('lat'), isFalse);
    expect(find.text('Please enable location services or search without location.'), findsOneWidget);
    expect(find.text('Near my location'), findsOneWidget);
  }, routes: homeRoutes);
}
