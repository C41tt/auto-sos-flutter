// lib/services/location_exchange_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import '../services/cloud_service.dart';

class PeerLocation {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  PeerLocation({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });
}

class LocationExchangeService {
  LocationExchangeService._private();
  static final LocationExchangeService instance = LocationExchangeService._private();

  final Location _location = Location();

  StreamSubscription<LocationData>? _locSub;
  StreamSubscription<Map<String, dynamic>?>? _peerSub;

  final StreamController<PeerLocation?> _peerLocationController = StreamController.broadcast();
  
  Stream<PeerLocation?> get peerLocationStream => _peerLocationController.stream;

  bool _running = false;

  Future<void> start({
    required String myId,
    String? peerId,
    Duration sendInterval = const Duration(seconds: 5),
  }) async {
    if (_running) return;
    _running = true;

    // 1) Проверяем ТОЛЬКО то, включен ли GPS на телефоне.
    //    Запрос РАЗРЕШЕНИЯ ПРИЛОЖЕНИЮ теперь делает MapScreen.
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        debugPrint('[LocationExchangeService] Location service is disabled.');
        _running = false; // <-- Сбрасываем флаг перед выходом
        return;
      }
    }
    
    // ➡️ БЛОК ЗАПРОСА РАЗРЕШЕНИЙ УДАЛЕН, ТАК КАК ЭТИМ ТЕПЕРЬ ЗАНИМАЕТСЯ MAPSCREEN
    
    try {
      await _location.enableBackgroundMode(enable: true);
    } catch (e) {
      debugPrint('[LocationExchangeService] enableBackgroundMode failed: $e');
    }

    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: sendInterval.inMilliseconds,
      distanceFilter: 5,
    );

    _locSub = _location.onLocationChanged.listen((LocationData data) async {
      if (data.latitude == null || data.longitude == null) return;
      try {
        await CloudService.updateWorkerLocation(
          myId,
          data.latitude!,
          data.longitude!,
          "active",
        );
      } catch (e) {
        debugPrint('Ошибка отправки локации в CloudService: $e');
      }
    }, onError: (err) {
      debugPrint('[LocationExchangeService] onLocationChanged error: $err');
    });

    if (peerId != null) {
      _subscribeToPeer(peerId);
    }
    debugPrint("[LocationExchangeService] Service started.");
  }

  void _subscribeToPeer(String peerId) {
    try {
      final s = CloudService.getActiveWorkerLocation(peerId);
      _peerSub = s.listen((Map<String, dynamic>? data) {
        if (data != null && data['lat'] != null && data['lon'] != null) {
          final pl = PeerLocation(
            latitude: data['lat'],
            longitude: data['lon'],
            timestamp: data['timestamp'] != null 
                ? DateTime.tryParse(data['timestamp']) 
                : null,
          );
          _peerLocationController.add(pl);
        } else {
          _peerLocationController.add(null);
        }
      }, onError: (e) {
        debugPrint('Ошибка подписки на peer location: $e');
      });
    } catch (e) {
      debugPrint('CloudService.getActiveWorkerLocation не доступен или выбрасывает: $e\n');
    }
  }

  void changePeer(String? peerId) {
    _peerSub?.cancel();
    if (peerId != null) {
      _subscribeToPeer(peerId);
    } else {
      _peerLocationController.add(null);
    }
  }

  Future<void> stop() async {
    _locSub?.cancel();
    _peerSub?.cancel();
    _peerLocationController.add(null);
    _running = false;
    try {
      await _location.enableBackgroundMode(enable: false);
    } catch (_) {}
  }
  
  void dispose() {
    _locSub?.cancel();
    _peerSub?.cancel();
    _peerLocationController.close();
  }
}