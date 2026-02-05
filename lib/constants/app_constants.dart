// lib/constants/app_constants.dart

/// Класс для хранения всех строковых констант приложения.
/// Помогает избежать опечаток и упрощает рефакторинг.
class AppConstants {
  // Ключи для SharedPreferences
  static const String userRole = 'user_role';

  // Значения ролей
  static const String driverRole = 'driver';
  static const String workerRole = 'worker';

  // Ключи для объектов Map (данные из CloudService/Firebase)
  static const String id = 'id';
  static const String lat = 'lat';
  static const String lon = 'lon';
  static const String title = 'title';
  static const String type = 'type';
  static const String status = 'status';
  static const String assignedWorkerId = 'assignedWorkerId';
  static const String text = 'text';
  static const String sender = 'sender';
  
  // ID отправителей в чате
  static const String botSender = 'bot';
}