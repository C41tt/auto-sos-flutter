import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'map_screen.dart'; 
import 'worker_home_screen.dart'; // ⬅️ НОВЫЙ ЭКРАН ДЛЯ РАБОТНИКА

/// Экран выбора роли при первом запуске (заглушка авторизации)
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выберите свою роль')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Как вы будете использовать приложение?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Кнопка для Водителя (Клиента)
              _buildRoleButton(context, 'Водитель (Клиент)', 'driver', Icons.person, Colors.red),
              
              // Кнопка для Работника (Эвакуатор/СТО)
              _buildRoleButton(context, 'Работник Эвакуатора / СТО', 'worker', Icons.local_shipping, Colors.blue),
              
              const SizedBox(height: 30),
              const Text(
                'Роль сохраняется локально. Приложение запустится в этом режиме при следующем входе.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, String roleCode, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Text(title, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 70),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        onPressed: () async {
          // 📌 Логика сохранения роли
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', roleCode);
          
          debugPrint('Роль выбрана: $roleCode. Сохранено.');
          
          // Переход на соответствующий главный экран
          if (context.mounted) {
            Widget nextScreen;
            if (roleCode == 'driver') {
              nextScreen = const MapScreen();
            } else {
              // Если роль 'worker', переходим на WorkerHomeScreen
              nextScreen = const WorkerHomeScreen(); 
            }

            // Замена текущего экрана на новый (чтобы кнопка "Назад" не вела на выбор роли)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => nextScreen),
            );
          }
        },
      ),
    );
  }
}