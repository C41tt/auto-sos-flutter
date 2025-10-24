class DBService {
  // Инициализация (заглушка)
  static Future<void> init() async {}
  
  // SOS (заглушки)
  static Future<int> saveSOS(double lat, double lon, String note) async => 0;
  static Future<List<Map<String,dynamic>>> getPendingSOS() async => [];
  static Future<int> markSent(int id) async => 0;
  
  // Cams (Антирадар - заглушки)
  static Future<void> importCamsFromJson(String jsonString) async {}
  static Future<List<Map<String,dynamic>>> getCams() async => [];

  // POI (Точки интереса - заглушки)
  static Future<void> importPoisFromJson(String jsonString) async {}
  static Future<List<Map<String,dynamic>>> getPois() async => [];
}
