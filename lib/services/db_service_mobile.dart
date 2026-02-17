import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DBService {
  static Database? _db;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Инициализация базы данных для iOS/Android.
  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'offline_sos.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL,
            lon REAL,
            timestamp TEXT,
            note TEXT,
            sent INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE cams(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL,
            lon REAL,
            title TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE pois(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL,
            lon REAL,
            title TEXT,
            type TEXT 
          )
        ''');
      },
    );
    
    final poisCount = Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM pois'));
    if (poisCount == 0) {
        await importPoisFromJson('''
            [
                {"lat": 43.235, "lon": 76.90, "title": "Полицейский участок 102", "type": "police"},
                {"lat": 43.245, "lon": 76.92, "title": "Отдел МЧС 112", "type": "mchs"},
                {"lat": 43.250, "lon": 76.88, "title": "Круглосуточный эвакуатор", "type": "evacuator"},
                {"lat": 43.230, "lon": 76.89, "title": "СТО QuickFix", "type": "sto"}
            ]
        ''');
        await importCamsFromJson('''
            [
                {"lat": 43.230, "lon": 76.95, "title": "Камера (Антирадар) Абая"},
                {"lat": 43.220, "lon": 76.85, "title": "Камера (Антирадар) Саина"}
            ]
        ''');
    }
  }

  // =======================================================
  // БЛОК FIREBASE И АВТОРИЗАЦИИ (НОВЫЙ РЕКОДИНГ)
  // =======================================================

  /// Очистка роли пользователя
  static Future<void> clearSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    print('✅ Сохраненная роль успешно удалена.');
  }

  /// Регистрация или вход пользователя (вырезано из auth_screen)
  static Future<void> registerOrLoginUser({
    required String phone,
    required String name,
    required String role,
    required List<String> specialties,
  }) async {
    final userDoc = await _firestore.collection('users').doc(phone).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(phone).set({
        'name': name,
        'phone': phone,
        'role': role,
        'specialties': role == 'worker' ? specialties : [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    await prefs.setString('user_name', name);
    await prefs.setString('device_id', phone);
  }

  // =======================================================
  // SOS OFFLINE (Локальная БД)
  // =======================================================

  static Future<int> saveSOS(double lat, double lon, String note) async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.insert('sos', {
      'lat': lat,
      'lon': lon,
      'timestamp': DateTime.now().toIso8601String(),
      'note': note,
      'sent': 0, 
    });
  }
  
  static Future<List<Map<String, dynamic>>> getPendingSOS() async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.query('sos', where: 'sent = ?', whereArgs: [0]);
  }

  static Future<int> markSent(int id) async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.update('sos', {'sent': 1}, where: 'id = ?', whereArgs: [id]);
  }
  
  // =======================================================
  // Cams & POIS 
  // =======================================================

  static Future<void> importCamsFromJson(String jsonString) async {
    if (_db == null) throw Exception('DB not initialized');
    final List data = json.decode(jsonString);
    final batch = _db!.batch();
    batch.delete('cams'); 
    for (final item in data) {
      batch.insert('cams', {'lat': item['lat'], 'lon': item['lon'], 'title': item['title']});
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCams() async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.query('cams');
  }

  static Future<void> importPoisFromJson(String jsonString) async {
    if (_db == null) throw Exception('DB not initialized');
    final List data = json.decode(jsonString);
    final batch = _db!.batch();
    batch.delete('pois'); 
    for (final item in data) {
      batch.insert('pois', {'lat': item['lat'], 'lon': item['lon'], 'title': item['title'], 'type': item['type']});
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getPois() async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.query('pois');
  }
}