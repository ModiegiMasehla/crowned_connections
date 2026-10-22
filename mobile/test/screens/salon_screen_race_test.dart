import 'dart:async';
import 'package:crowned_connections/screens/salon_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../helpers/test_helpers.dart';

void main() {
  testApp('an older availability response cannot overwrite a new service',
      (tester, api) async {
    final oldResponse = Completer<http.Response>();
    api.onAsync('GET', '/availability', (request) async {
      if (request.url.queryParameters['serviceId'] == 'first') {
        return oldResponse.future;
      }
      return jsonResponse({
        'slots': [
          {
            'stylistId': 'new',
            'stylistName': 'Current service stylist',
            'startTime': '2030-10-20T09:00:00+02:00',
          }
        ]
      });
    });
    await pumpScreen(tester, const SalonScreen(salonId: 'salon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First service'));
    await tester.pump();
    await tester.tap(find.text('Second service'));
    await tester.pumpAndSettle();
    expect(find.text('Current service stylist'), findsOneWidget);
    oldResponse.complete(jsonResponse({
      'slots': [
        {
          'stylistId': 'old',
          'stylistName': 'Stale stylist',
          'startTime': '2030-10-20T08:00:00+02:00',
        }
      ]
    }));
    await tester.pumpAndSettle();
    expect(find.text('Stale stylist'), findsNothing);
    expect(find.text('Current service stylist'), findsOneWidget);
  }, routes: (api) {
    api.json('GET', '/salons/salon', {
      'salon': {'name': 'Salon', 'city': 'Pretoria', 'province': 'Gauteng'},
      'services': [
        {
          'id': 'first',
          'name': 'First service',
          'price_cents': 100,
          'duration_minutes': 30
        },
        {
          'id': 'second',
          'name': 'Second service',
          'price_cents': 200,
          'duration_minutes': 60
        },
      ],
      'staff': [],
    });
  });
}
