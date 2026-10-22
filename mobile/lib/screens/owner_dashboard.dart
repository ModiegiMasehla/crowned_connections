import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/salon_time.dart';
import 'package:intl/intl.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});
  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  List<dynamic> appointments = [];
  bool loading = true;
  String? error;
  Future<void> load() async {
    try {
      final d = await ApiService.get('/appointments');
      appointments = d['appointments'] as List<dynamic>;
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> decision(String id, String decision) async {
    try {
      await ApiService.post(
          '/appointments/$id/decision', {'decision': decision});
      await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Salon Owner')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Appointment requests',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              if (appointments.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('No appointments yet.')),
              ...appointments.map((a) => Card(
                  child: ListTile(
                      title: Text(a['service_name'] ?? 'Appointment'),
                      subtitle: Text(
                          '${a['salon_name']}\n${DateFormat('EEE, d MMM yyyy HH:mm').format(salonTime(DateTime.parse(a['start_time'])))}\n${a['status']}'),
                      isThreeLine: true,
                      trailing: a['status'] == 'PENDING'
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              TextButton(
                                  onPressed: () =>
                                      decision(a['id'], 'CONFIRMED'),
                                  child: const Text('Accept')),
                              TextButton(
                                  onPressed: () =>
                                      decision(a['id'], 'DECLINED'),
                                  child: const Text('Decline')),
                            ])
                          : null)))
            ]));
}
