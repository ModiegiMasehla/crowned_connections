import 'dart:convert';

import 'package:crowned_connections/main.dart';
import 'package:crowned_connections/screens/appointments_screen.dart';
import 'package:crowned_connections/screens/home_screen.dart';
import 'package:crowned_connections/screens/login_screen.dart';
import 'package:crowned_connections/screens/owner_dashboard.dart';
import 'package:crowned_connections/screens/salon_screen.dart';
import 'package:crowned_connections/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

const _salonId = '20000000-0000-0000-0000-000000000001';

/// End-to-end journeys through the real app widget tree, against the fake API.
/// They mirror the demo: a customer finds and books, an owner accepts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> signIn(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), 'Password123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  testApp('a customer signs in, finds a salon, books a slot and sees it pending', (tester, api) async {
    await tester.pumpWidget(const CrownedConnectionsApp());
    expect(find.byType(LoginScreen), findsOneWidget);

    // 1. Sign in.
    await signIn(tester, 'customer@example.com');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(ApiService.token, 'customer-jwt');

    // 2. Search.
    await tester.enterText(find.byType(TextField), 'Knotless Braids');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    expect(find.text('Crowned Beauty Studio'), findsOneWidget);

    // 3. Open the salon and choose a service.
    await tester.tap(find.text('Crowned Beauty Studio'));
    await tester.pumpAndSettle();
    expect(find.byType(SalonScreen), findsOneWidget);
    await tester.tap(find.text('Knotless Braids'));
    await tester.pumpAndSettle();

    // 4. Book the slot.
    await tester.tap(find.widgetWithText(FilledButton, 'Book'));
    await tester.pumpAndSettle();
    expect(find.text('Booking requested'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final booking = api.requestsTo('POST', '/appointments').single;
    expect(booking.headers['Authorization'], 'Bearer customer-jwt');
    expect(jsonDecode(booking.body)['salonId'], _salonId);
    expect(jsonDecode(booking.body)['serviceId'], 'sv-knotless');

    // 5. Back on the home screen, My Appointments lists the pending booking.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentsScreen), findsOneWidget);
    expect(find.text('Knotless Braids'), findsOneWidget);
    expect(find.textContaining('Status: PENDING'), findsOneWidget);
  }, routes: (api) {
    final appointments = <Map<String, dynamic>>[];

    api.json('POST', '/auth/login', {'token': 'customer-jwt'});
    api.json('GET', '/auth/me', {
      'user': {'id': 'u1', 'role': 'CUSTOMER'},
    });
    api.json('GET', '/search', {
      'results': [
        {
          'id': _salonId,
          'name': 'Crowned Beauty Studio',
          'city': 'Pretoria',
          'province': 'Gauteng',
          'rating_avg': 4.8,
          'distance_km': 2.5,
        },
      ],
    });
    api.json('GET', '/salons/$_salonId', {
      'salon': {'id': _salonId, 'name': 'Crowned Beauty Studio', 'city': 'Pretoria', 'province': 'Gauteng'},
      'services': [
        {'id': 'sv-knotless', 'name': 'Knotless Braids', 'price_cents': 65000, 'duration_minutes': 180},
      ],
      'staff': [
        {'id': 'st-lead', 'display_name': 'Lead Stylist'},
      ],
    });
    api.json('GET', '/availability', {
      'slots': [
        {
          'stylistId': 'st-lead',
          'stylistName': 'Lead Stylist',
          'startTime': '2026-10-16T08:00:00+02:00',
          'endTime': '2026-10-16T11:00:00+02:00',
        },
      ],
    });
    api.on('POST', '/appointments', (_) {
      appointments.add({
        'id': 'a1',
        'service_name': 'Knotless Braids',
        'salon_name': 'Crowned Beauty Studio',
        'status': 'PENDING',
        'start_time': '2026-10-16T06:00:00Z',
      });
      return jsonResponse({
        'appointment': {'id': 'a1', 'status': 'PENDING'},
      }, status: 201);
    });
    api.on('GET', '/appointments', (_) => jsonResponse({'appointments': appointments}));
  });

  testApp('a salon owner signs in and accepts a pending booking', (tester, api) async {
    await tester.pumpWidget(const CrownedConnectionsApp());

    await signIn(tester, 'owner@example.com');
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.storefront));
    await tester.pumpAndSettle();
    expect(find.byType(OwnerDashboard), findsOneWidget);
    expect(find.textContaining('PENDING'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Accept'));
    await tester.pumpAndSettle();

    final decision = api.requestsTo('POST', '/appointments/a1/decision').single;
    expect(decision.headers['Authorization'], 'Bearer owner-jwt');
    expect(jsonDecode(decision.body), {'decision': 'CONFIRMED'});
    expect(find.textContaining('CONFIRMED'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Accept'), findsNothing);
  }, routes: (api) {
    var status = 'PENDING';

    api.json('POST', '/auth/login', {'token': 'owner-jwt'});
    api.json('GET', '/auth/me', {
      'user': {'id': 'u2', 'role': 'SALON_OWNER'},
    });
    api.on('GET', '/appointments', (_) => jsonResponse({
          'appointments': [
            {
              'id': 'a1',
              'service_name': 'Knotless Braids',
              'salon_name': 'Crowned Beauty Studio',
              'start_time': '2026-10-16T06:00:00Z',
              'status': status,
            },
          ],
        }));
    api.on('POST', '/appointments/a1/decision', (request) {
      status = jsonDecode(request.body)['decision'] as String;
      return jsonResponse({
        'appointment': {'id': 'a1', 'status': status},
      });
    });
  });

  testApp('signing out and in as a different user does not reuse the old token', (tester, api) async {
    await tester.pumpWidget(const CrownedConnectionsApp());

    await signIn(tester, 'customer@example.com');
    expect(ApiService.token, 'customer-jwt');

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(ApiService.token, isNull);

    await signIn(tester, 'owner@example.com');
    expect(ApiService.token, 'owner-jwt');
    expect(find.byIcon(Icons.storefront), findsOneWidget);

    // The first /auth/me after the second sign-in must carry the new token.
    final me = api.requestsTo('GET', '/auth/me');
    expect(me.first.headers['Authorization'], 'Bearer customer-jwt');
    expect(me.last.headers['Authorization'], 'Bearer owner-jwt');
  }, routes: (api) {
    var loginCount = 0;

    api.on('POST', '/auth/login', (_) {
      loginCount++;
      return jsonResponse({'token': loginCount == 1 ? 'customer-jwt' : 'owner-jwt'});
    });
    api.on('GET', '/auth/me', (request) {
      final owner = request.headers['Authorization'] == 'Bearer owner-jwt';
      return jsonResponse({
        'user': {'id': owner ? 'u2' : 'u1', 'role': owner ? 'SALON_OWNER' : 'CUSTOMER'},
      });
    });
  });
}
