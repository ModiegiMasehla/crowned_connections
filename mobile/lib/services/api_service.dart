import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );
  static const storage = FlutterSecureStorage();

  static String? token;

  static Future<void> loadToken() async {
    token = await storage.read(key: 'token');
  }

  static Map<String,String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static const _timeout = Duration(seconds: 20);

  static Future<Map<String,dynamic>> post(String path, Map<String,dynamic> body) async {
    final r = await http
        .post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(r);
  }

  static Future<Map<String,dynamic>> get(String path) async {
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: headers).timeout(_timeout);
    return _handle(r);
  }

  /// Decodes the response and turns HTTP errors into readable messages.
  /// Spring returns the human-readable reason in `message`, not `error`.
  static Future<Map<String,dynamic>> _handle(http.Response r) async {
    Map<String,dynamic> data = <String,dynamic>{};
    if (r.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(r.bodyBytes));
        if (decoded is Map<String,dynamic>) data = decoded;
      } catch (_) {
        // Non-JSON body (e.g. proxy error page); fall through to status handling.
      }
    }
    if (r.statusCode >= 400) {
      if (r.statusCode == 401 && token != null) await clearToken();
      final msg = data['message'] ?? data['error'];
      throw Exception(msg is String && msg.isNotEmpty ? msg : 'Request failed (${r.statusCode})');
    }
    return data;
  }

  static Future<void> saveToken(String value) async {
    token = value;
    await storage.write(key: 'token', value: value);
  }

  static Future<void> clearToken() async {
    token = null;
    await storage.delete(key: 'token');
  }
}
