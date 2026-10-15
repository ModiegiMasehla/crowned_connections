import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> appointments = [];
  bool loading = true;
  String? error;

  Future<void> load() async {
    try {
      final data = await ApiService.get('/appointments');
      appointments = data['appointments'] as List<dynamic>;
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                  if (appointments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: Text('You have no appointments yet.')),
                    ),
                  ...appointments.map((a) {
                    final date = DateTime.tryParse(a['start_time'].toString())?.toLocal();
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.calendar_month)),
                        title: Text(a['service_name'] ?? 'Appointment'),
                        subtitle: Text(
                          '${a['salon_name']}\n'
                          '${date == null ? a['start_time'] : DateFormat('EEE, d MMM yyyy • HH:mm').format(date)}\n'
                          'Status: ${a['status']}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
