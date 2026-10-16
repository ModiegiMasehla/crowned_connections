import 'package:crowned_connections/screens/salon_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

const _salonId = '20000000-0000-0000-0000-000000000001';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void routes(FakeApi api) {
    api.json('GET', '/salons/$_salonId', {
      'salon': {
        'id': _salonId,
        'name': 'Crowned Beauty Studio',
        'city': 'Pretoria',
        'province': 'Gauteng',
        'rating_avg': 4.8,
      },
      'services': [
        {'id': 'sv-knotless', 'name': 'Knotless Braids', 'price_cents': 65000, 'duration_minutes': 180},
        {'id': 'sv-silk', 'name': 'Silk Press', 'price_cents': 30000, 'duration_minutes': 120},
      ],
      'staff': [
        {'id': 'st-lead', 'display_name': 'Lead Stylist'},
        {'id': 'st-thandi', 'display_name': 'Thandi'},
      ],
    });
    api.json('GET', '/availability', {'slots': []});
  }

  Future<void> chooseService(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  /// Opens the stylist drop-down (currently showing [current]) and picks [name].
  Future<void> chooseStylist(WidgetTester tester, {required String current, required String name}) async {
    await tester.tap(find.text(current));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Map<String, String> lastAvailabilityQuery(FakeApi api) =>
      api.requestsTo('GET', '/availability').last.url.queryParameters;

  Future<void> openSalon(WidgetTester tester) async {
    await pumpScreen(tester, const SalonScreen(salonId: _salonId));
    await tester.pumpAndSettle();
  }

  group('stylist', () {
    testApp('defaults to "Any available" and sends no stylist', (tester, api) async {
      await openSalon(tester);
      await chooseService(tester, 'Knotless Braids');

      expect(find.text('Any available'), findsOneWidget);
      expect(lastAvailabilityQuery(api).containsKey('stylistId'), isFalse);
    }, routes: routes);

    testApp('choosing a stylist reloads the slots for that stylist', (tester, api) async {
      await openSalon(tester);
      await chooseService(tester, 'Knotless Braids');

      await chooseStylist(tester, current: 'Any available', name: 'Thandi');

      expect(api.requestsTo('GET', '/availability'), hasLength(2));
      expect(lastAvailabilityQuery(api)['stylistId'], 'st-thandi');
      expect(lastAvailabilityQuery(api)['serviceId'], 'sv-knotless');
    }, routes: routes);

    testApp('going back to "Any available" drops the stylist filter', (tester, api) async {
      await openSalon(tester);
      await chooseService(tester, 'Knotless Braids');
      await chooseStylist(tester, current: 'Any available', name: 'Thandi');

      await chooseStylist(tester, current: 'Thandi', name: 'Any available');

      expect(api.requestsTo('GET', '/availability'), hasLength(3));
      expect(lastAvailabilityQuery(api).containsKey('stylistId'), isFalse);
    }, routes: routes);

    testApp('keeps the chosen stylist when a different service is picked', (tester, api) async {
      await openSalon(tester);
      await chooseService(tester, 'Knotless Braids');
      await chooseStylist(tester, current: 'Any available', name: 'Thandi');

      await chooseService(tester, 'Silk Press');

      expect(lastAvailabilityQuery(api)['serviceId'], 'sv-silk');
      expect(lastAvailabilityQuery(api)['stylistId'], 'st-thandi');
    }, routes: routes);
  });

  group('date', () {
    testApp('cancelling the date picker changes nothing', (tester, api) async {
      await openSalon(tester);
      await chooseService(tester, 'Knotless Braids');
      expect(api.requestsTo('GET', '/availability'), hasLength(1));

      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(api.requestsTo('GET', '/availability'), hasLength(1));
    }, routes: routes);

    testApp('confirming the date picker reloads the slots for the shown date', (tester, api) async {
      await openSalon(tester);
      await chooseService(tester, 'Knotless Braids');
      final firstDate = lastAvailabilityQuery(api)['date'];

      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(api.requestsTo('GET', '/availability'), hasLength(2));
      expect(lastAvailabilityQuery(api)['date'], firstDate);
      expect(lastAvailabilityQuery(api)['date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    }, routes: routes);
  });
}
