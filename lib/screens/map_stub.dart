import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart'; 

// Класс ValueNotifier для управления видимостью (как в map_screen)
import 'package:flutter/foundation.dart';

class MapPlatform extends StatelessWidget {
  final LatLng? current;
  // Добавлены параметры для совместимости с MapScreen
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

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Карта не доступна на текущей платформе. Требуется мобильное устройство или веб-браузер с поддержкой FlutterMap.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
