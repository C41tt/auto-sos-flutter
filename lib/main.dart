// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // ⬅️ ВКЛЮЧАЕМ ИМПОРТ

import 'screens/auth_screen.dart';
import 'screens/map_screen.dart'; // Для водителя
import 'screens/worker_home_screen.dart'; // Для работника
import 'services/db_service.dart';
import 'services/location_exchange_service.dart'; // сервис в lib/services/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация локальной БД
  await DBService.init();

  // ✅ ИНИЦИАЛИЗАЦИЯ FIREBASE (ТЕПЕРЬ ДОЛЖНА РАБОТАТЬ С GOOGLESERVICE-INFO.PLIST)
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase успешно инициализирован");
  } catch (e) {
    // В случае сбоя, по крайней мере, залогируем его и продолжим
    debugPrint("⚠️ Ошибка инициализации Firebase: $e");
  }
  

  // Получаем роль
  final prefs = await SharedPreferences.getInstance();
  final String? userRole = prefs.getString('user_role');

  runApp(MyApp(initialRole: userRole));
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  const MyApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Помощник: SOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
      home: HomeRouter(initialRole: initialRole),
    );
  }
}

class HomeRouter extends StatefulWidget {
  final String? initialRole;
  const HomeRouter({super.key, this.initialRole});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  final LocationExchangeService _locationService = LocationExchangeService.instance;
  StreamSubscription? _peerSub;

  @override
  void initState() {
    super.initState();
    _initLocationSharing();
  }

  Future<void> _initLocationSharing() async {
    // уникальный id устройства (простая генерация)
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('device_id');
    id ??= DateTime.now().millisecondsSinceEpoch.toString(); // временный уникальный id
    await prefs.setString('device_id', id);

    // Запускаем обмен (метод start(myId: ...) в твоём сервисе)
    await _locationService.start(myId: id, peerId: null, sendInterval: const Duration(seconds: 10));
    // Просто логируем, что вызов прошел.
    debugPrint("⚠️ start() завершился — проверь логи сервиса");

    // Подписываемся на поток peerLocationStream (возвращает PeerLocation?)
    _peerSub = _locationService.peerLocationStream.listen((peerLoc) {
      debugPrint("📍 Обновлён peer: $peerLoc");
      // здесь можно десяго: обновлять состояние карты и т.д.
    }, onError: (e) {
      debugPrint("Ошибка в peerLocationStream: $e");
    });

    debugPrint("✅ Обмен координатами запущен для устройства $id");
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    _locationService.stop();
    super.dispose();
  }

  Widget _selectScreen() {
    if (widget.initialRole == 'driver') return const MapScreen();
    if (widget.initialRole == 'worker') return const WorkerHomeScreen();
    return const AuthScreen();
  }

  @override
  Widget build(BuildContext context) {
    return _selectScreen();
  }
}
//salam Darkhan