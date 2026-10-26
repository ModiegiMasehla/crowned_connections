import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final first = TextEditingController(),
      last = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  String role = 'CUSTOMER';
  bool loading = false;
  String? error;
  Future<void> register() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final d = await ApiService.post('/auth/register', {
        'email': email.text.trim(),
        'password': password.text,
        'role': role,
        'firstName': first.text.trim(),
        'lastName': last.text.trim()
      });
      await ApiService.saveToken(d['token']);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(
            controller: first,
            decoration: const InputDecoration(labelText: 'First name')),
        TextField(
            controller: last,
            decoration: const InputDecoration(labelText: 'Last name')),
        TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email')),
        TextField(
            controller: password,
            obscureText: true,
            decoration:
            const InputDecoration(labelText: 'Password (8+ characters)')),
        DropdownButtonFormField<String>(
            initialValue: role,
            items: const [
              DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer')),
              DropdownMenuItem(value: 'SALON_OWNER', child: Text('Salon owner'))
            ],
            onChanged: (v) => setState(() => role = v!),
            decoration: const InputDecoration(labelText: 'Account type')),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: loading ? null : register,
            child: Text(loading ? 'Creating...' : 'Create account')),
      ]));
}