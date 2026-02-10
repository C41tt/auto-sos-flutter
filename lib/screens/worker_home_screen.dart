import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './cloud_service.dart';
import 'auth_screen.dart';
import 'map_screen.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role'); 
    await prefs.remove('worker_specialty');

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _acceptSOS(BuildContext context, Map<String, dynamic> req) async {
    final sosId = req['id'] as String;
    final prefs = await SharedPreferences.getInstance();
    final workerId = prefs.getString('device_id') ?? 'unknown_worker';

    await CloudService.assignSOS(sosId, workerId);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            isWorkerMode: true,
            activeSos: req,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель Специалиста'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Активные вызовы:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: CloudService.getActiveSOSRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Ошибка: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Center(child: Text('Нет активных заявок', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(req['title'] ?? 'SOS'),
                        subtitle: Text('Координаты: ${req['lat']?.toStringAsFixed(4)}, ${req['lon']?.toStringAsFixed(4)}'),
                        trailing: ElevatedButton(
                          onPressed: () => _acceptSOS(context, req),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                          child: const Text('ПРИНЯТЬ', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}