import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_screen.dart';
import 'auth_screen.dart';
import 'worker_home_screen.dart';
import 'product_list_screen.dart'; // ✅ 1. ВАЖНО: Импорт витрины

class MenuScreen extends StatefulWidget {
  final bool isWorker; // Если true, показываем кнопку заказов

  const MenuScreen({super.key, required this.isWorker});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // ЦВЕТА
  static const Color bgColor = Color(0xFF0F1012); 
  static const Color cardColor = Color(0xFF25282B); 
  static const Color iconColor = Colors.white70;

  List<Map<String, dynamic>> navigationStack = [];

  // --- ЛОГИКА ВЫХОДА ---
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Полный сброс

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // --- НАВИГАЦИЯ ---
  void _goToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(isWorkerMode: widget.isWorker),
      ),
    );
  }

  void _goToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkerHomeScreen()),
    );
  }

  void _openCategory(String title, List<String> items) {
    setState(() {
      navigationStack.add({'title': title, 'items': items});
    });
  }

  void _goBack() => setState(() => navigationStack.removeLast());

  @override
  Widget build(BuildContext context) {
    String currentTitle = navigationStack.isEmpty ? 'AUTO SOS' : navigationStack.last['title'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: navigationStack.isNotEmpty 
          ? IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: _goBack)
          : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(currentTitle, key: ValueKey(currentTitle), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        actions: [
          if (navigationStack.isEmpty)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              onPressed: _logout,
              tooltip: "Выйти",
            )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: navigationStack.isEmpty ? _buildMainMenu() : _buildSubMenu(),
      ),
    );
  }

  Widget _buildMainMenu() {
    return ListView(
      key: const ValueKey('main'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildProfileSection(),
        const SizedBox(height: 25),
        _buildSectionWrapper([
          
          // СПЕЦИАЛЬНАЯ КНОПКА ДЛЯ РАБОТНИКА
          if (widget.isWorker)
             _buildActionRow(Icons.notifications_active, "🔥 Активные вызовы", Colors.orange, _goToOrders),

          // КНОПКА КАРТЫ (ДЛЯ ВСЕХ)
          _buildActionRow(Icons.map_outlined, "Карта города", Colors.blue, _goToMap),
          
          _buildRow(Icons.build_outlined, "СТО", ["Вулканизация", "Эвакуатор", "Техпомощь"]),
          _buildRow(Icons.shopping_bag_outlined, "Магазин", [
            "Автозапчасти", "Масла и жидкости", "Аксессуары для авто", 
            "Мотозапчасти", "Шины, диски и колёса", "Авторазборы", 
            "Запчасти для спец техники", "Прочие запчасти"
          ]),
          _buildRow(Icons.no_drinks_outlined, "Трезвый водитель", null),
          _buildRow(Icons.shield_outlined, "Авто страхование", null),
          _buildRow(Icons.gavel_outlined, "Авто адвокат", null),
          _buildRow(Icons.local_shipping_outlined, "Авто перевозчик", null),
        ]),
      ],
    );
  }

  // ПРОФИЛЬ (КРУГЛЫЙ)
  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10), 
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF3A3D41), 
              shape: BoxShape.circle, 
            ),
            child: const Center(
              child: Icon(Icons.person, size: 55, color: Colors.white38),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Дархан Садык", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                Text(
                  widget.isWorker ? "🛠️ Мастер" : "🚗 Водитель",
                  style: TextStyle(color: widget.isWorker ? Colors.blue : Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white24), 
            onPressed: _logout
          ),
        ],
      ),
    );
  }

  Widget _buildSubMenu() {
    List<String> items = navigationStack.last['items'];
    return ListView(
      key: ValueKey(navigationStack.length),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _buildSectionWrapper(
          items.map((item) {
            List<String>? next;
            
            // ПОЛНЫЙ ТЕКСТ КАТЕГОРИЙ (КАК ТЫ ПРОСИЛ)
            if (item == "Автозапчасти") {
              next = [
                "Двигатель", "Выхлопная система", "ГБО", "Автоэлектрика", 
                "Система зажигания", "Трансмиссия и КПП", "Автостекла", "Фильтры", 
                "Фары и освещение", "Зеркала заднего вида", "Тормозная система", 
                "Ходовая и подвеска", "Рулевое управление", "Кузовные детали", 
                "Топливная система", "Системы обогрева", "Подача воздуха", 
                "Очистка окон", "Детали салона", "Прочие запчасти"
              ];
            } else if (item == "Масла и жидкости") {
              next = [
                "Все в Масла и технические жидкости",
                "Автомасла / смазки (Моторные, Трансмиссионные, Антифриз, Тормозная...)",
                "Автохимия и автокосметика"
              ];
            } else if (item == "Аксессуары для авто") {
              next = [
                "Все в Аксессуары", 
                "Автозвук (FM, Магнитолы, Сабвуферы...)", 
                "Автоэлектроника (GPS, Радары, Парктроники...)", 
                "Аксессуары для салона", "Багажные системы", "Брызговики", 
                "Ветровики", "Чехлы и накидки", "Автоинструменты", 
                "Тюнинг", "Диагностика"
              ];
            } else if (item == "Мотозапчасти") {
              next = ["Все в Мото", "Запчасти", "Экипировка", "Аксессуары"];
            } else if (item == "Шины, диски и колёса") {
              next = ["Все в Шины", "Автошины", "Мотошины", "Диски", "Колеса в сборе", "Колпаки"];
            }

            return _buildRow(null, item, next);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRow(IconData? icon, String title, List<String>? subItems) {
    return InkWell(
      onTap: () {
        if (subItems != null) {
          _openCategory(title, subItems);
        } else {
          // ✅ 2. ВАЖНО: Если подкатегорий нет — открываем ВИТРИНУ ТОВАРОВ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductListScreen(categoryTitle: title),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5))
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, color: iconColor, size: 24), const SizedBox(width: 15)],
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16))),
            // Стрелочка только если есть вложенность
            if (subItems != null)
              const Icon(Icons.chevron_right, color: Colors.white10, size: 20),
          ],
        ),
      ),
    );
  }

  // Строка для действий (Карта, Заказы)
  Widget _buildActionRow(IconData icon, String title, Color accent, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5))
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 24), 
            const SizedBox(width: 15),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
            const Icon(Icons.arrow_forward, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWrapper(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
      child: Column(children: children),
    );
  }
}