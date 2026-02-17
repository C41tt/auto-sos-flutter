import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; 

class CloudService {
  // ==============================================================================
  // 🌐 ОНЛАЙН РЕЖИМ (Связь через Firebase)
  // ==============================================================================

  static Future<String> sendSOS(double lat, double lon, String note, String clientId) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection('sos_requests').add({
        'clientId': clientId,
        'lat': lat,
        'lon': lon,
        'title': note,
        'type': 'police',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'assignedWorkerId': null,
      });
      debugPrint('✅ SOS отправлен! ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Ошибка отправки SOS: $e');
      return '';
    }
  }

  static Stream<Map<String, dynamic>?> getSOSRequestStream(String sosId) {
    return FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(sosId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            data['id'] = doc.id;
            return data;
          }
          return null;
        });
  }
static Stream<List<Map<String, dynamic>>> getActiveSOSRequests() {
    return FirebaseFirestore.instance
        .collection('sos_requests')
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              })
              // 🔥 ФИЛЬТР: Оставляем только те, что созданы не позднее 24 часов назад
              .where((data) {
                if (data['timestamp'] == null) return false;
                DateTime created = (data['timestamp'] as Timestamp).toDate();
                return now.difference(created).inHours < 24; 
              })
              .toList();
        });
  }

  static Future<void> assignSOS(String sosId, String workerId) async {
    try {
      await FirebaseFirestore.instance.collection('sos_requests').doc(sosId).update({
        'status': 'assigned',
        'assignedWorkerId': workerId,
      });
      debugPrint('👷 Заявка $sosId принята работником $workerId');
    } catch (e) {
      debugPrint('Ошибка назначения: $e');
    }
  }
  
  static Future<void> closeSOS(String sosId) async {
    try {
      await FirebaseFirestore.instance.collection('sos_requests').doc(sosId).update({
        'status': 'closed',
      });
       await FirebaseFirestore.instance.collection('worker_locations').doc(sosId).delete();
    } catch (e) {
      debugPrint('Ошибка закрытия: $e');
    }
  }

  // ==============================================================================
  // 📍 ГЕОЛОКАЦИЯ В РЕАЛЬНОМ ВРЕМЕНИ
  // ==============================================================================

  static Future<void> updateWorkerLocation(String activeSosId, double lat, double lon, String status) async {
    await FirebaseFirestore.instance.collection('worker_locations').doc(activeSosId).set({
      'lat': lat,
      'lon': lon,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<Map<String, dynamic>?> getActiveWorkerLocation(String activeSosId) {
    return FirebaseFirestore.instance
        .collection('worker_locations')
        .doc(activeSosId)
        .snapshots()
        .map((doc) => doc.data());
  }

  // ==============================================================================
  // 💬 ЧАТ
  // ==============================================================================
  
  static Stream<List<Map<String, dynamic>>> getChatMessages(String sosId) {
    return FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(sosId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  static Future<void> sendChatMessage(String sosId, String sender, String text) async {
    await FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(sosId)
        .collection('messages')
        .add({
          'text': text,
          'sender': sender,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // ==============================================================================
  // 🛒 МАГАЗИН (НОВОЕ!)
  // ==============================================================================

  static Stream<List<Map<String, dynamic>>> getProductsByCategory(String category) {
    return FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  static Future<void> addProduct(String title, String category, String price, String desc, String seller, String phone) async {
    await FirebaseFirestore.instance.collection('products').add({
      'title': title,
      'category': category,
      'price': price,
      'desc': desc,
      'seller': seller,
      'phone': phone,
      'image': '', 
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}