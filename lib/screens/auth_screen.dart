import 'package:flutter/material.dart';
import 'menu_screen.dart'; 
import '../services/db_service_mobile.dart'; // ✅ Подключаем наш сервис

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _selectedRole; // 'driver' или 'worker'
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Список выбранных специальностей (для профи)
  final List<String> _selectedSpecialties = [];
  bool _isLoading = false;

  final List<String> _allSpecialties = [
    '🚗 Эвакуатор', '🔧 Автомеханик', '⚡ Автоэлектрик', '🛞 Шиномонтаж',
    '🔋 Прикурить', '⛽ Подвоз топлива', '🔑 Вскрытие замков',
  ];

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните имя и телефон')));
      return;
    }

    if (_selectedRole == 'worker' && _selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите хотя бы одну специализацию')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ РЕКОДИНГ: Вызываем чистую функцию из сервиса вместо простыни кода
      await DBService.registerOrLoginUser(
        phone: phone,
        name: name,
        role: _selectedRole!,
        specialties: _selectedSpecialties,
      );

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MenuScreen(
              isWorker: _selectedRole == 'worker',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedRole == null ? _buildRoleSelection() : _buildRegistrationForm(),
    );
  }

  // Экран 1: Выбор кто ты
  Widget _buildRoleSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("КТО ВЫ?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        _roleButton("Я ВОДИТЕЛЬ", "Нужна помощь на дороге", Icons.directions_car, Colors.red, () => setState(() => _selectedRole = 'driver')),
        const SizedBox(height: 20),
        _roleButton("Я СПЕЦИАЛИСТ", "Оказываю услуги помощи", Icons.build, Colors.blue.shade800, () => setState(() => _selectedRole = 'worker')),
      ],
    );
  }

  // Экран 2: Ввод данных
  Widget _buildRegistrationForm() {
    bool isWorker = _selectedRole == 'worker';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Text(isWorker ? "РЕГИСТРАЦИЯ МАСТЕРА" : "РЕГИСТРАЦИЯ ВОДИТЕЛЯ", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Номер телефона', border: OutlineInputBorder())),
          
          if (isWorker) ...[
            const SizedBox(height: 25),
            const Text("Выберите ваши услуги:", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _allSpecialties.map((spec) {
                final isSelected = _selectedSpecialties.contains(spec);
                return FilterChip(
                  label: Text(spec),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val ? _selectedSpecialties.add(spec) : _selectedSpecialties.remove(spec);
                    });
                  },
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 40),
          _isLoading 
            ? const CircularProgressIndicator() 
            : ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWorker ? Colors.blue.shade800 : Colors.red,
                  minimumSize: const Size(double.infinity, 55)
                ),
                child: const Text("ПОДТВЕРДИТЬ", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
          TextButton(onPressed: () => setState(() => _selectedRole = null), child: const Text("Назад"))
        ],
      ),
    );
  }

  Widget _roleButton(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: ListTile(
        onTap: onTap,
        tileColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(icon, color: Colors.white, size: 30),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}