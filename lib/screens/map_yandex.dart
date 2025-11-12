// lib/screens/map_yandex.dart

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'cloud_service.dart';

const String _userIconPath = 'lib/assets/icons/my_location.png';
const String _clientPinPath = 'lib/assets/icons/client.png';
const String _policeIconPath = 'lib/assets/icons/police.png';
const String _mchsIconPath = 'lib/assets/icons/mchs.png';
const String _evacuatorPinPath = 'lib/assets/icons/evacuator.png';
const String _cameraIconPath = 'lib/assets/icons/camera.png';


class MapYandex extends StatefulWidget {
  final LatLng? current;
  final List<Map<String, dynamic>> pois;
  final List<Map<String, dynamic>> cams;
  final ValueNotifier<bool> showPois;
  final ValueNotifier<bool> showCams;
  final bool isWorkerMode;
  final Map<String, dynamic>? activeSos;
  final LatLng? trackedWorkerLocation;

  const MapYandex({
    this.current,
    required this.pois,
    required this.cams,
    required this.showPois,
    required this.showCams,
    Key? key,
    this.isWorkerMode = false,
    this.activeSos,
    this.trackedWorkerLocation,
  }) : super(key: key);

  @override
  State<MapYandex> createState() => _MapYandexState();
}

class _MapYandexState extends State<MapYandex> {
  YandexMapController? _mapController;
  List<MapObject> mapObjects = [];
  bool _initialMovePerformed = false; 

  void _moveToLocation(Point point, {double zoom = 15.0}) {
    if (_mapController == null) {
      debugPrint("Map controller is not ready yet.");
      return;
    }
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: zoom),
      ),
      // duration: 1.5, // MapAnimation ожидает double для секунд
      animation: MapAnimation(type: MapAnimationType.smooth,
      duration: 1.5), 
    );
  }

  @override
  void initState() {
    super.initState();
    widget.showPois.addListener(_updateMapObjects);
    widget.showCams.addListener(_updateMapObjects);
  }

  @override
  void didUpdateWidget(MapYandex oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. Плавное перемещение камеры при первом получении GPS
    if (widget.current != null && oldWidget.current == null && !_initialMovePerformed) {
      if (!widget.isWorkerMode) {
        _moveToLocation(
          Point(latitude: widget.current!.latitude, longitude: widget.current!.longitude),
          zoom: 15.0,
        );
        _initialMovePerformed = true; // Устанавливаем флаг, чтобы не центрировать постоянно
      }
    }
    
    // 2. Если GPS просто обновился, обновляем только маркер
    _updateMapObjects(); 
  }

  @override
  void dispose() {
    widget.showPois.removeListener(_updateMapObjects);
    widget.showCams.removeListener(_updateMapObjects);
    super.dispose();
  }

  void _updateMapObjects() {
    final List<MapObject> newObjects = [];
    if (widget.current != null) {
      // ИСПРАВЛЕНИЕ: Плавное перемещение маркера для создания эффекта "слежения"
      newObjects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('current_location_point'),
          point: Point(latitude: widget.current!.latitude, longitude: widget.current!.longitude),
          icon: PlacemarkIcon.single(PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(_userIconPath),
            scale: 0.2,
          )),
          isDraggable: false, 
        ),
      );
    }
    // ✅ НОВЫЙ КОД (Блок 1) — Работник видит Клиента как client.png
    if (widget.isWorkerMode && widget.activeSos != null) {
      final sosLat = widget.activeSos!['lat'] as double;
      final sosLon = widget.activeSos!['lon'] as double;
      final sosPoint = Point(latitude: sosLat, longitude: sosLon);
      
      newObjects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('sos_client_point'),
          point: sosPoint,
          icon: PlacemarkIcon.single(PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(_clientPinPath), // 🚀 ВСЕГДА client.png
            scale: 0.25,
          )),
          onTap: (PlacemarkMapObject object, Point point) {
            _moveToLocation(sosPoint, zoom: 17.0);
          }
        ),
      );
    }
    // ✅ НОВЫЙ КОД (Блок 2) — Клиент видит Работника как evacuator.png
    // ⚠️ Важно: Этот блок должен выполняться ТОЛЬКО для Клиента (isWorkerMode = false)
    if (!widget.isWorkerMode && widget.trackedWorkerLocation != null) { // 🚀 ДОБАВЛЕНА ПРОВЕРКА РОЛИ
        final workerPoint = Point(latitude: widget.trackedWorkerLocation!.latitude, longitude: widget.trackedWorkerLocation!.longitude);
        newObjects.add(
            PlacemarkMapObject(
                mapId: const MapObjectId('worker_location_point'),
                point: workerPoint,
                icon: PlacemarkIcon.single(PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage(_evacuatorPinPath), // 🚀 ИСПОЛЬЗУЕМ evacuator.png
                    scale: 0.2,
                )),
                isDraggable: false,
            ),
        );
    }
    if (widget.showPois.value) {
      for (final poi in widget.pois) {
        String iconPath;
        switch (poi['type']) {
          case 'police': iconPath = _policeIconPath; break;
          case 'mchs': iconPath = _mchsIconPath; break;
          case 'evacuator': iconPath = _evacuatorPinPath; break;
          default: iconPath = _userIconPath;
        }
        newObjects.add(
          PlacemarkMapObject(
            mapId: MapObjectId('poi_${poi['id']}'),
            point: Point(latitude: poi['lat'], longitude: poi['lon']),
            icon: PlacemarkIcon.single(PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage(iconPath),
              scale: 0.15,
            )),
          ),
        );
      }
    }
    if (widget.showCams.value) {
      for (final cam in widget.cams) {
        newObjects.add(
          PlacemarkMapObject(
            mapId: MapObjectId('cam_${cam['id']}'),
            point: Point(latitude: cam['lat'], longitude: cam['lon']),
            icon: PlacemarkIcon.single(PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage(_cameraIconPath),
              scale: 0.1,
            )),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        mapObjects = newObjects;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return YandexMap(
      onMapCreated: (controller) {
        _mapController = controller;
        
        // ИСПРАВЛЕНИЕ: При создании карты, если GPS нет, показываем общий вид (Астана, зум 5.0).
        if (!_initialMovePerformed) {
             _moveToLocation(
              widget.current != null 
                  ? Point(latitude: widget.current!.latitude, longitude: widget.current!.longitude)
                  : const Point(latitude: 51.169392, longitude: 71.449074), 
              zoom: widget.current != null ? 15.0 : 5.0,
            );
            // Если у нас уже есть current при старте, считаем, что первое перемещение выполнено
            if (widget.current != null) {
              _initialMovePerformed = true;
            }
        }
        
        _updateMapObjects();
      },
      mapObjects: mapObjects,
    );
  }
}