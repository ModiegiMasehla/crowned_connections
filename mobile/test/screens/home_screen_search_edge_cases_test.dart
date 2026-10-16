import 'dart:async';

import 'package:crowned_connections/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/test_helpers.dart';

Map<String, dynamic> salon(String id, String name) => {
      'id': id,
      'name': name,
      'city': 'Pretoria',
      'province': 'Gauteng',
      'rating_avg': 4.5,
      'distance_km': 4.0,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void signedInCustomer(FakeApi api) {
    api.json('GET', '/auth/me', {
      'user': {'id': 'u1', 'role': 'CUSTOMER'},
    });
  }

  Future<void> search(WidgetTester tester, String term) async {
    await tester.enterText(find.byType(TextField), term);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
  }

  testApp('shows a progress bar while the search runs and hides it afterwards', (tester, api) async {
    final response = Completer<http.Response>();
    api.onAsync('GET', '/search', (_) => response.future);
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.enterText(find.byType(TextField), 'Box Braids');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    response.complete(jsonResponse({
      'results': [salon('s1', 'Crowned Beauty Studio')],
    }));
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Crowned Beauty Studio'), findsOneWidget);
  }, routes: signedInCustomer);

  testApp('sends terms with spaces and ampersands intact', (tester, api) async {
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester, 'Wash & Blow');

    final query = api.requestsTo('GET', '/search').single.url.queryParameters;
    expect(query['q'], 'Wash & Blow');
    expect(query['radiusKm'], '25');
  }, routes: (api) {
    signedInCustomer(api);
    api.json('GET', '/search', {'results': []});
  });

  testApp('sends an empty term when nothing has been typed', (tester, api) async {
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(api.requestsTo('GET', '/search').single.url.queryParameters['q'], '');
  }, routes: (api) {
    signedInCustomer(api);
    api.json('GET', '/search', {'results': []});
  });

  testApp('a new search replaces the previous results', (tester, api) async {
    var term = '';
    api.on('GET', '/search', (request) {
      term = request.url.queryParameters['q'] ?? '';
      return jsonResponse({
        'results': [
          term == 'Silk Press' ? salon('s2', 'Natural Crown Centurion') : salon('s1', 'Crowned Beauty Studio'),
        ],
      });
    });
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester, 'Knotless Braids');
    expect(find.text('Crowned Beauty Studio'), findsOneWidget);

    await search(tester, 'Silk Press');

    expect(find.text('Natural Crown Centurion'), findsOneWidget);
    expect(find.text('Crowned Beauty Studio'), findsNothing);
    expect(find.byType(ListTile), findsOneWidget);
  }, routes: signedInCustomer);

  testApp('returns to the search prompt when a search finds nothing', (tester, api) async {
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester, 'Something nobody offers');

    expect(find.byType(ListTile), findsNothing);
    expect(find.textContaining('Search for a hairstyle'), findsOneWidget);
  }, routes: (api) {
    signedInCustomer(api);
    api.json('GET', '/search', {'results': []});
  });

  testApp('a failed search keeps the page usable for another try', (tester, api) async {
    var attempts = 0;
    api.on('GET', '/search', (_) {
      attempts++;
      return attempts == 1
          ? jsonResponse({'message': 'Search is temporarily unavailable'}, status: 503)
          : jsonResponse({
              'results': [salon('s1', 'Crowned Beauty Studio')],
            });
    });
    await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await search(tester, 'Braids');
    expect(find.text('Search is temporarily unavailable'), findsOneWidget);

    await search(tester, 'Braids');

    expect(find.text('Search is temporarily unavailable'), findsNothing);
    expect(find.text('Crowned Beauty Studio'), findsOneWidget);
  }, routes: signedInCustomer);
}
