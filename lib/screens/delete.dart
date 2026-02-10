import 'package:shared_preferences/shared_preferences.dart';

// 1. Создайте функцию для очистки данных
Future<void> clearSavedRole() async {
  final prefs = await SharedPreferences.getInstance();
  
  // 2. Удалите ключ 'user_role'
  final success = await prefs.remove('user_role'); 
  
  if (success) {
    print('✅ Сохраненная роль успешно удалена. Перезапустите приложение.');
  } else {
    print('⚠️ Ключ "user_role" не найден или не удалось удалить.');
  }
}

// ...
// Затем вызовите эту функцию один раз.