// lib/screens/worker_home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart'; // ⬅️ ИМПОРТ КОНСТАНТ
import './cloud_service.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';
import 'map_screen.dart';

/// Главный экран для Работника (СТО, Эвакуатор и т.д.)
class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  // Функция для выхода и сброса роли
  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userRole); // ⬅️ ИСПОЛЬЗУЕМ КОНСТАНТУ

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // ➡️ Логика принятия SOS
  void _acceptSOS(BuildContext context, Map<String, dynamic> req) async {
    final sosId = req[AppConstants.id] as String;

    // ➡️ ИСПРАВЛЕНИЕ: ID работника должен быть уникальным.
    // В реальном приложении он будет приходить из сервиса аутентификации.
    // Здесь мы его имитируем, чтобы избежать коллизий.
    final String workerId = 'worker_${DateTime.now().millisecondsSinceEpoch}';
    // TODO: Заменить на реальный ID работника из Firebase Auth или другого сервиса.

    await CloudService.assignSOS(sosId, workerId);

    // После принятия сразу переходим на карту клиента
    if (context.mounted) {
      _viewClientOnMap(context, req);
    }
  }

  // Логика перехода на карту клиента
  void _viewClientOnMap(BuildContext context, Map<String, dynamic> req) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель Работника'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Сменить роль / Выйти',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Активные SOS-запросы:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: CloudService.getActiveSOSRequests(),
              builder: (context, snapshot) {
                // ➡️ ИСПРАВЛЕНИЕ: Добавлена обработка ошибок
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка загрузки запросов: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 60, color: Colors.green.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'Нет активных SOS-запросов.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.warning, color: Colors.red.shade700),
                        title: Text(req[AppConstants.title] ?? 'Новый SOS-запрос'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${req[AppConstants.id]} | Тип: ${req[AppConstants.type]}'),
                            Text('Координаты: ${req[AppConstants.lat]?.toStringAsFixed(3)}, ${req[AppConstants.lon]?.toStringAsFixed(3)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () => _acceptSOS(context, req),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Принять'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.map, color: Colors.blue),
                              onPressed: () => _viewClientOnMap(context, req),
                              tooltip: 'Показать на карте',
                            ),
                          ],
                        ),
                        onTap: () => _viewClientOnMap(context, req),
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