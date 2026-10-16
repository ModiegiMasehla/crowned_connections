import 'package:crowned_connections/screens/appointments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

Map<String, dynamic> appointment(String id, String service, String status) => {
      'id': id,
      'service_name': service,
      'salon_name': 'Crowned Beauty Studio',
      'status': status,
      'start_time': '2026-10-16T06:00:00Z',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pullToRefresh(WidgetTester tester) async {
    // The test screen is 1600px tall and RefreshIndicator needs a drag of
    // about a quarter of that, so pull well past it.
    await tester.fling(find.byType(ListView), const Offset(0, 900), 1000);
    await tester.pumpAndSettle();
  }

  testApp('pulling down reloads the appointments and shows the new status', (tester, api) async {
    await pumpScreen(tester, const AppointmentsScreen());
    await tester.pumpAndSettle();
    expect(find.textContaining('Status: PENDING'), findsOneWidget);

    await pullToRefresh(tester);

    expect(api.requestsTo('GET', '/appointments'), hasLength(2));
    expect(find.textContaining('Status: CONFIRMED'), findsOneWidget);
    expect(find.textContaining('Status: PENDING'), findsNothing);
  }, routes: (api) {
    var loads = 0;
    api.on('GET', '/appointments', (_) {
      loads++;
      return jsonResponse({
        'appointments': [appointment('a1', 'Knotless Braids', loads == 1 ? 'PENDING' : 'CONFIRMED')],
      });
    });
  });

  testApp('a successful refresh clears an earlier error', (tester, api) async {
    await pumpScreen(tester, const AppointmentsScreen());
    await tester.pumpAndSettle();
    expect(find.text('Server is waking up'), findsOneWidget);
    expect(find.text('You have no appointments yet.'), findsOneWidget);

    await pullToRefresh(tester);

    expect(find.text('Server is waking up'), findsNothing);
    expect(find.text('Silk Press'), findsOneWidget);
    expect(find.text('You have no appointments yet.'), findsNothing);
  }, routes: (api) {
    var loads = 0;
    api.on('GET', '/appointments', (_) {
      loads++;
      return loads == 1
          ? jsonResponse({'message': 'Server is waking up'}, status: 503)
          : jsonResponse({
              'appointments': [appointment('a2', 'Silk Press', 'CONFIRMED')],
            });
    });
  });

  testApp('a failed refresh keeps the appointments already on screen and shows the error', (tester, api) async {
    await pumpScreen(tester, const AppointmentsScreen());
    await tester.pumpAndSettle();
    expect(find.text('Knotless Braids'), findsOneWidget);

    await pullToRefresh(tester);

    expect(find.text('Knotless Braids'), findsOneWidget);
    expect(find.text('Server is waking up'), findsOneWidget);
  }, routes: (api) {
    var loads = 0;
    api.on('GET', '/appointments', (_) {
      loads++;
      return loads == 1
          ? jsonResponse({
              'appointments': [appointment('a1', 'Knotless Braids', 'PENDING')],
            })
          : jsonResponse({'message': 'Server is waking up'}, status: 503);
    });
  });
}
