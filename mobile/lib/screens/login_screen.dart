import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ApiService.post('/auth/login',
          {'email': email.text.trim(), 'password': password.text});
      await ApiService.saveToken(data['token']);
      if (mounted)
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('👑',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 56)),
                        const Text('Crowned Connections',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Where Your Crown Meets Its Perfect Match.',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        TextField(
                            controller: email,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextField(
                            controller: password,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder())),
                        if (error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(error!,
                                  style: const TextStyle(color: Colors.red))),
                        const SizedBox(height: 18),
                        FilledButton(
                            onPressed: loading ? null : login,
                            child: Text(loading ? 'Signing in...' : 'Sign in')),
                        TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen())),
                            child: const Text('Create an account'))
                      ],
                    )))),
      );
}
