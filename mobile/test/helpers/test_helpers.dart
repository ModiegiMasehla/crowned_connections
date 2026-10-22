import 'dart:async';
import 'dart:convert';
import 'package:crowned_connections/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object data, {int status = 200}) =>
    http.Response(jsonEncode(data), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

class FakeApi {
  final requests = <http.Request>[];
  final _routes = <String, FutureOr<http.Response> Function(http.Request)>{};

  void on(String method, String path,
          http.Response Function(http.Request) handler) =>
      _routes['$method $path'] = handler;
  void onAsync(String method, String path,
          Future<http.Response> Function(http.Request) handler) =>
      _routes['$method $path'] = handler;
  void json(String method, String path, Object data, {int status = 200}) =>
      on(method, path, (_) => jsonResponse(data, status: status));
  List<http.Request> requestsTo(String method, String path) => requests
      .where((r) => r.method == method && r.url.path == '/api$path')
      .toList();

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path.replaceFirst(RegExp(r'^/api'), '');
    final handler = _routes['${request.method} $path'];
    if (handler == null) {
      throw StateError('No test route for ${request.method} $path');
    }
    return await handler(request);
  }
}

Future<void> pumpScreen(WidgetTester tester, Widget screen) =>
    tester.pumpWidget(MaterialApp(home: screen));

void testApp(
    String description, Future<void> Function(WidgetTester, FakeApi) body,
    {void Function(FakeApi)? routes}) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.token = null;
    final previous = ApiService.client;
    final api = FakeApi();
    final client = MockClient(api.handle);
    ApiService.client = client;
    const location = MethodChannel('flutter.baseflow.com/geolocator');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(location, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
        case 'requestPermission':
          return 2;
        case 'getCurrentPosition':
          return {
            'latitude': -25.7479,
            'longitude': 28.2293,
            'timestamp': DateTime.utc(2026, 10, 16).millisecondsSinceEpoch,
            'accuracy': 5.0,
            'altitude': 0.0,
            'altitude_accuracy': 0.0,
            'heading': 0.0,
            'heading_accuracy': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'is_mocked': false,
          };
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(location, null);
      client.close();
      ApiService.client = previous;
      ApiService.token = null;
    });
    routes?.call(api);
    await body(tester, api);
  });
}
