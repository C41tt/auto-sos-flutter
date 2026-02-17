import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; 

import 'screens/auth_screen.dart';
import 'screens/menu_screen.dart';
import 'services/db_service_mobile.dart'; // ✅ Исправлен импорт на наш новый сервис
import 'services/location_exchange_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();
}

Future<void> _initializeApp() async {
  await DBService.init(); 

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase подключен");
  } catch (e) {
    debugPrint("⚠️ Ошибка Firebase: $e");
  }
  
  final prefs = await SharedPreferences.getInstance();
  final String? userRole = prefs.getString('user_role');

  runApp(AppRoot(initialRole: userRole));
}

class AppRoot extends StatefulWidget {
  final String? initialRole;
  const AppRoot({super.key, this.initialRole});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver { 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      // ✅ РЕКОДИНГ: Вызываем функцию очистки из нашего сервиса
      DBService.clearSavedRole();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyApp(initialRole: widget.initialRole);
  }
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  const MyApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUTO SOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
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
  
  @override
  void initState() {
    super.initState();
    _initLocationSharing();
  }

  Future<void> _initLocationSharing() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('device_id');
    if (id == null) {
      id = DateTime.now().millisecondsSinceEpoch.toString(); 
      await prefs.setString('device_id', id);
    }

    // Включаем трансляцию для работника, чтобы Клиент мог видеть его
    if (widget.initialRole == 'worker') {
      await _locationService.start(
        myId: id, 
        peerId: null, 
        sendInterval: const Duration(seconds: 10)
      );
    }
  }

  @override
  void dispose() {
    _locationService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialRole == 'driver') {
      return const MenuScreen(isWorker: false);
    }
    
    if (widget.initialRole == 'worker') {
      return const MenuScreen(isWorker: true);
    }

    return const AuthScreen();
  }
}