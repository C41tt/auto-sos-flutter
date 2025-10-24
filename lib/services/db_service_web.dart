import 'dart:async';

class DBService {
  static Future<void> init() async {
    // Инициализация не требуется для заглушки в веб
  }

  // =======================================================
  // SOS (заглушки)
  // =======================================================

  static Future<int> saveSOS(double lat, double lon, String note) async {
    print('SOS сохранено как заглушка для веб: $lat, $lon. Примечание: $note');
    return 0; 
  }

  static Future<List<Map<String, dynamic>>> getPendingSOS() async {
    return []; // Заглушка: нет ожидающих SOS
  }

  static Future<int> markSent(int id) async {
    return 0; // Заглушка
  }
  
  // =======================================================
  // Cams (Антирадар)
  // =======================================================

  static Future<void> importCamsFromJson(String jsonString) async {
    // На веб-версии камеры не импортируются, используем статические данные
  }

  /// Получить камеры
  static Future<List<Map<String, dynamic>>> getCams() async {
    // Возвращаем тестовые данные камер для демонстрации на карте (Алматы)
    return [
      {'id': 1, 'lat': 43.230, 'lon': 76.95, 'title': 'Камера (Антирадар) Абая'},
      {'id': 2, 'lat': 43.220, 'lon': 76.85, 'title': 'Камера (Антирадар) Саина'},
      {'id': 3, 'lat': 43.260, 'lon': 76.90, 'title': 'Мобильный патруль'},
    ];
  }

  // =======================================================
  // POI (Points of Interest: Полиция, МЧС, Эвакуатор, СТО)
  // =======================================================
  
  static Future<void> importPoisFromJson(String jsonString) async {
    // На веб-версии POI не импортируются, используем статические данные
  }

  /// Получить точки интереса (POI)
  static Future<List<Map<String, dynamic>>> getPois() async {
    // Возвращаем тестовые данные POI для демонстрации на карте (Алматы)
    return [
      {'id': 101, 'lat': 43.235, 'lon': 76.90, 'title': 'Полицейский участок 102', 'type': 'police'},
      {'id': 102, 'lat': 43.245, 'lon': 76.92, 'title': 'Отдел МЧС 112', 'type': 'mchs'},
      {'id': 103, 'lat': 43.250, 'lon': 76.88, 'title': 'Круглосуточный эвакуатор', 'type': 'evacuator'},
      {'id': 104, 'lat': 43.230, 'lon': 76.89, 'title': 'СТО QuickFix', 'type': 'sto'}
    ];
  }
}