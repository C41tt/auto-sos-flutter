import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBService {
  static Database? _db;

  /// Инициализация базы данных для iOS/Android.
  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'offline_sos.db'),
      version: 1,
      onCreate: (db, version) async {
        // Таблица SOS (для офлайн-отправки)
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

        // Таблица cams (для Антирадара)
        await db.execute('''
          CREATE TABLE cams(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL,
            lon REAL,
            title TEXT
          )
        ''');

        // Таблица POIS (Points of Interest: Полиция, МЧС, Эвакуатор, СТО)
        await db.execute('''
          CREATE TABLE pois(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL,
            lon REAL,
            title TEXT,
            type TEXT 
            -- Здесь можно добавить 'status' TEXT для Эвакуаторов/СТО
          )
        ''');
      },
    );
    
    // ПРОВЕРКА: Если база данных POI пуста, загружаем тестовые данные
    final poisCount = Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM pois'));
    if (poisCount == 0) {
        // Тестовые данные для Алматы, Казахстан
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
  // SOS (Экстренные вызовы)
  // =======================================================

  /// Сохранить запрос SOS в локальную базу данных
  static Future<int> saveSOS(double lat, double lon, String note) async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.insert('sos', {
      'lat': lat,
      'lon': lon,
      'timestamp': DateTime.now().toIso8601String(), // Сохраняем время
      'note': note,
      'sent': 0, // Не отправлено
    });
  }
  
  /// Получить неотправленные запросы SOS
  static Future<List<Map<String, dynamic>>> getPendingSOS() async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.query('sos', where: 'sent = ?', whereArgs: [0]);
  }

  /// Отметить запрос SOS как отправленный
  static Future<int> markSent(int id) async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.update(
      'sos', 
      {'sent': 1}, 
      where: 'id = ?', 
      whereArgs: [id],
    );
  }
  
  // =======================================================
  // Cams (Антирадар)
  // =======================================================

  /// Импорт камер из JSON (с очисткой старых данных)
  static Future<void> importCamsFromJson(String jsonString) async {
    if (_db == null) throw Exception('DB not initialized');
    final List data = json.decode(jsonString);
    final batch = _db!.batch();
    batch.delete('cams'); 
    for (final item in data) {
      batch.insert('cams', {
        'lat': item['lat'],
        'lon': item['lon'],
        'title': item['title'],
      });
    }
    await batch.commit(noResult: true);
  }

  /// Получить камеры
  static Future<List<Map<String, dynamic>>> getCams() async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.query('cams');
  }

  // =======================================================
  // POI (Points of Interest: Полиция, МЧС, Эвакуатор, СТО)
  // =======================================================
  
  /// Импорт POI из JSON (с очисткой старых данных)
  static Future<void> importPoisFromJson(String jsonString) async {
    if (_db == null) throw Exception('DB not initialized');
    final List data = json.decode(jsonString);
    final batch = _db!.batch();
    batch.delete('pois'); 
    for (final item in data) {
      batch.insert('pois', {
        'lat': item['lat'],
        'lon': item['lon'],
        'title': item['title'],
        'type': item['type'], // 'police', 'mchs', 'evacuator', 'sto'
      });
    }
    await batch.commit(noResult: true);
  }

  /// Получить точки интереса (POI)
  static Future<List<Map<String, dynamic>>> getPois() async {
    if (_db == null) throw Exception('DB not initialized');
    return await _db!.query('pois');
  }
}