import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart'; // Для ValueNotifier

/// Веб-реализация карты (FlutterMap с OpenStreetMap)
class MapPlatform extends StatelessWidget {
  final LatLng? current;
  final List<Map<String, dynamic>> pois;
  final List<Map<String, dynamic>> cams;
  final ValueNotifier<bool> showPois;
  final ValueNotifier<bool> showCams;

  const MapPlatform({
    this.current,
    required this.pois,
    required this.cams,
    required this.showPois,
    required this.showCams,
    Key? key,
  }) : super(key: key);

  // Вспомогательная функция для создания маркера
  Marker _buildMarker(LatLng point, IconData icon, Color color) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      builder: (ctx) => Icon(icon, size: 30, color: color),
    );
  }

  // Создание списка маркеров POI
  List<Marker> _buildPoisMarkers() {
    return pois.map((poi) {
      // Определяем иконку по типу (из DBService)
      IconData icon;
      Color color;
      switch (poi['type']) {
        case 'police':
          icon = Icons.local_police;
          color = Colors.blue.shade700;
          break;
        case 'mchs':
          icon = Icons.fire_truck;
          color = Colors.red.shade700;
          break;
        case 'evacuator':
          icon = Icons.airport_shuttle;
          color = Colors.orange.shade700;
          break;
        default:
          icon = Icons.location_pin;
          color = Colors.green;
      }
      return _buildMarker(
        LatLng(poi['lat'], poi['lon']), 
        icon, 
        color
      );
    }).toList();
  }

  // Создание списка маркеров Камер
  List<Marker> _buildCamsMarkers() {
    return cams.map((cam) {
      return _buildMarker(
        LatLng(cam['lat'], cam['lon']), 
        Icons.camera, 
        Colors.black
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Начальная точка - Алматы (Казахстан), если локация не определена
    final initialCenter = current ?? LatLng(43.238949, 76.889709); 

    return FlutterMap(
      options: MapOptions(
        center: initialCenter,
        zoom: 12, // Устанавливаем разумный зум для города
        maxZoom: 18,
      ),
      children: [
        // 1. Слой тайлов (OpenStreetMap)
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.offlinesos',
        ),
        
        // 2. Слой маркеров
        ValueListenableBuilder<bool>(
          valueListenable: showPois,
          builder: (context, showPoisValue, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: showCams,
              builder: (context, showCamsValue, child) {
                
                List<Marker> allMarkers = [];

                // Маркер текущего местоположения
                if (current != null) {
                  allMarkers.add(
                    _buildMarker(
                      current!, 
                      Icons.person_pin_circle, 
                      Colors.red.shade900
                    )
                  );
                }
                
                // POI (Полиция/МЧС)
                if (showPoisValue) {
                  allMarkers.addAll(_buildPoisMarkers());
                }

                // Камеры (Антирадар)
                if (showCamsValue) {
                  allMarkers.addAll(_buildCamsMarkers());
                }

                return MarkerLayer(markers: allMarkers);
              },
            );
          },
        ),
      ],
    );
  }
}
