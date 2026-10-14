import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();
  runApp(const CrownedConnectionsApp());
}

class CrownedConnectionsApp extends StatelessWidget {
  const CrownedConnectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crowned Connections',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6D4C5B)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFAFC),
      ),
      home: ApiService.token == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
