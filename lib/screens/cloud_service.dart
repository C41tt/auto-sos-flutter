// lib/screens/cloud_service.dart

import 'package:flutter/material.dart';
import 'dart:async'; 

// Имитация работы с Firebase (для демонстрации архитектуры)
class CloudService {
  // Имитация коллекции запросов SOS
  static final List<Map<String, dynamic>> _sosRequests = [
    {
      'id': 'sos_1',
      'clientId': 'user_a',
      'lat': 43.235,
      'lon': 76.900,
      'title': 'ДТП, требуется Эвакуатор',
      'type': 'evacuator',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      'status': 'active', // active, assigned, closed
      'assignedWorkerId': null, // ID работника, который принял запрос
    },
    {
      'id': 'sos_2',
      'clientId': 'user_b',
      'lat': 43.250,
      'lon': 76.850,
      'title': 'Прокол колеса, нужна помощь СТО',
      'type': 'sto',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
      'status': 'active',
      'assignedWorkerId': null,
    },
  ];
  
  // ➡️ Активные местоположения работников
  // Ключ: workerId (он же - sosId, который работник принял)
  static final Map<String, Map<String, dynamic>> _activeWorkers = {};

  /// Обновление местоположения работника (workerId = sosId)
  static Future<void> updateWorkerLocation(String workerId, double lat, double lon, String status) async {
    _activeWorkers[workerId] = {
      'lat': lat,
      'lon': lon,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    };
    debugPrint('CloudService: Обновлена позиция работника $workerId');
  }

  /// Получение потока местоположения Worker (workerId = sosId)
  static Stream<Map<String, dynamic>?> getActiveWorkerLocation(String sosId) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      // Работник использует sosId как свой ID во время выполнения запроса
      yield _activeWorkers[sosId]; 
    }
  }

  /// Получение потока данных активного SOS-запроса (для Клиента)
  static Stream<Map<String, dynamic>?> getSOSRequestStream(String sosId) async* {
      while (true) {
          await Future.delayed(const Duration(seconds: 3));
          try {
              final request = _sosRequests.firstWhere((req) => req['id'] == sosId, orElse: () => {});
              if (request.isNotEmpty) {
                  yield request;
              } else {
                  yield null;
              }
          } catch (e) {
              yield null;
          }
      }
  }

  /// Отправка SOS-запроса в облако
  static Future<String> sendSOS(double lat, double lon, String note, String clientId) async {
    debugPrint('CloudService: Отправка SOS в облако: $lat, $lon. Заметка: $note');
    await Future.delayed(const Duration(milliseconds: 500));

    final newId = 'sos_${_sosRequests.length + 1}';
    _sosRequests.add({
      'id': newId,
      'clientId': clientId,
      'lat': lat,
      'lon': lon,
      'title': note,
      'type': 'police', 
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'active',
      'assignedWorkerId': null,
    });

    return newId;
  }
  
  /// ➡️ Метод для назначения Работника на SOS
  static Future<void> assignSOS(String sosId, String workerId) async {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
          final index = _sosRequests.indexWhere((req) => req['id'] == sosId);
          if (index != -1 && _sosRequests[index]['status'] == 'active') {
              _sosRequests[index]['status'] = 'assigned';
              _sosRequests[index]['assignedWorkerId'] = workerId; // WorkerId = sosId
              debugPrint('CloudService: Запрос $sosId назначен работнику $workerId');
          }
      } catch (e) {
          debugPrint('CloudService: Ошибка при назначении SOS: $e');
      }
  }
  
  /// ➡️ Метод для закрытия SOS
  static Future<void> closeSOS(String sosId) async {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
          final index = _sosRequests.indexWhere((req) => req['id'] == sosId);
          if (index != -1) {
              _sosRequests[index]['status'] = 'closed';
              _activeWorkers.remove(sosId); // Удаляем трекинг работника
              debugPrint('CloudService: Запрос $sosId закрыт.');
          }
      } catch (e) {
          debugPrint('CloudService: Ошибка при закрытии SOS: $e');
      }
  }


  /// Получение потока активных SOS-запросов (только 'active')
  static Stream<List<Map<String, dynamic>>> getActiveSOSRequests() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      yield _sosRequests.where((req) => req['status'] == 'active').toList();
    }
  }

  // Методы для чата
  static final Map<String, List<Map<String, dynamic>>> _chatMessages = {}; // Хранение чатов в памяти

  static Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) async* {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Инициализация чата, если он новый
    if (!_chatMessages.containsKey(chatId)) {
        _chatMessages[chatId] = [
            {'sender': 'bot', 'text': 'Чат SOS $chatId: ИИ-помощник на связи.'},
            {'sender': 'bot', 'text': 'Опишите проблему.'},
        ];
    }

    while (true) {
      await Future.delayed(const Duration(seconds: 1)); 
      yield _chatMessages[chatId]!;
    }
  }

  static Future<void> sendChatMessage(String chatId, String sender, String text) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _chatMessages[chatId]?.add({
      'sender': sender,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
    debugPrint('CloudService: Сообщение отправлено в чат $chatId от $sender: $text');
  }
}