// lib/screens/map_flutter.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart'; // ⬅️ ИМПОРТ КОНСТАНТ

/// Запасная реализация карты (FlutterMap/OpenStreetMap).
class MapFlutter extends StatelessWidget {
  final LatLng? current;
  final List<Map<String, dynamic>> pois;
  final List<Map<String, dynamic>> cams;
  final ValueNotifier<bool> showPois;
  final ValueNotifier<bool> showCams;
  final bool isWorkerMode;
  final Map<String, dynamic>? activeSos;
  final LatLng? trackedWorkerLocation;

  const MapFlutter({
    super.key,
    this.current,
    required this.pois,
    required this.cams,
    required this.showPois,
    required this.showCams,
    this.isWorkerMode = false,
    this.activeSos,
    this.trackedWorkerLocation,
  });

  // Вспомогательный метод для генерации маркеров
  List<Marker> _getMarkers() {
    // ➡️ ИСПРАВЛЕНИЕ: Оборачиваем весь код в try-catch для защиты от падений
    try {
      final List<Marker> markers = [];

      // 1. Маркер текущего местоположения пользователя
      if (current != null) {
        markers.add(
          Marker(
            point: current!,
            width: 30.0,
            height: 30.0,
            builder: (context) => const Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 30.0,
            ),
          ),
        );
      }

      // 2. Маркер клиента SOS (только в режиме работника)
      if (isWorkerMode && activeSos != null) {
        final lat = activeSos![AppConstants.lat] as double;
        final lon = activeSos![AppConstants.lon] as double;

        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 40.0,
            height: 40.0,
            builder: (context) => const Icon(
              Icons.sos,
              color: Colors.red,
              size: 40.0,
            ),
          ),
        );
      }

      // 3. Маркер местоположения Работника
      if (trackedWorkerLocation != null) {
        markers.add(
          Marker(
            point: trackedWorkerLocation!,
            width: 35.0,
            height: 35.0,
            builder: (context) => const Icon(
              Icons.local_shipping,
              color: Colors.green,
              size: 35.0,
            ),
          ),
        );
      }

      // 4. Маркеры камер (Cams)
      if (showCams.value) {
        for (final cam in cams) {
          markers.add(
            Marker(
              point: LatLng(cam[AppConstants.lat] as double, cam[AppConstants.lon] as double),
              width: 30.0,
              height: 30.0,
              builder: (context) => Icon(
                Icons.camera_alt,
                color: Colors.orange.shade700,
                size: 30.0,
              ),
            ),
          );
        }
      }

      // 5. Маркеры POI
      if (showPois.value) {
        for (final poi in pois) {
          IconData iconData;
          Color color;
          switch (poi[AppConstants.type]) {
            case 'police':
              iconData = Icons.local_police;
              color = Colors.blue.shade700;
              break;
            case 'mchs':
              iconData = Icons.fire_truck;
              color = Colors.red.shade700;
              break;
            case 'evacuator':
              iconData = Icons.local_shipping;
              color = Colors.purple.shade700;
              break;
            case 'sto':
              iconData = Icons.car_repair;
              color = Colors.green.shade700;
              break;
            default:
              iconData = Icons.location_on;
              color = Colors.grey;
          }

          markers.add(
            Marker(
              point: LatLng(poi[AppConstants.lat] as double, poi[AppConstants.lon] as double),
              width: 35.0,
              height: 35.0,
              builder: (context) => Icon(
                iconData,
                color: color,
                size: 35.0,
              ),
            ),
          );
        }
      }

      return markers;
    } catch (e, stackTrace) {
      // Если произошла ошибка при разборе данных, выводим ее в консоль
      // и возвращаем пустой список, чтобы приложение не упало.
      debugPrint('Error creating markers for FlutterMap: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showPois,
      builder: (context, showPoisValue, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: showCams,
          builder: (context, showCamsValue, child) {
            final initialCenter = (isWorkerMode && activeSos != null)
                ? LatLng(activeSos![AppConstants.lat] as double, activeSos![AppConstants.lon] as double)
                : current ?? LatLng(51.169392, 71.449074); // ✅ ИСПРАВЛЕНО

            final initialZoom = (isWorkerMode && activeSos != null) ? 17.0 : 12.0;

            return Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    center: initialCenter,
                    zoom: initialZoom,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.offline_sos',
                    ),
                    MarkerLayer(markers: _getMarkers()),
                  ],
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Text(
                        'СИМУЛЯТОР / WEB: Используется Flutter Map (заглушка).',
                        style: TextStyle(
                            backgroundColor: Color.fromARGB(200, 255, 255, 0),
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}