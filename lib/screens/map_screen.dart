// lib/screens/map_screen.dart
import 'package:flutter/material.dart' hide Coords;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'dart:async';

import '../services/db_service.dart';
import './cloud_service.dart';
import '../widgets/news_feed.dart';
import 'chat_screen.dart';
import 'map_flutter.dart';
import 'map_yandex.dart';
import 'worker_home_screen.dart'; 

const String _userIconPath = 'lib/assets/icons/my_location.png';
const String _policeIconPath = 'lib/assets/icons/police.png';
const String _mchsIconPath = 'lib/assets/icons/mchs.png';
const String _evacuatorIconPath = 'lib/assets/icons/evacuator.png';
const String _cameraIconPath = 'lib/assets/icons/camera.png';

class MapScreen extends StatefulWidget {
  final bool isWorkerMode;
  final Map<String, dynamic>? activeSos;

  const MapScreen({
    super.key,
    this.isWorkerMode = false,
    this.activeSos,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  LatLng? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;
  List<Map<String, dynamic>> _pois = [];
  List<Map<String, dynamic>> _cams = [];
  final ValueNotifier<bool> _showPois = ValueNotifier(true);
  final ValueNotifier<bool> _showCams = ValueNotifier(true);
  String? _activeSosId;

  String? _assignedWorkerId;
  LatLng? _trackedWorkerLocation;
  StreamSubscription? _workerLocationSubscription;
  StreamSubscription? _sosStatusSubscription;
  bool _isListeningLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeSosId = widget.activeSos?['id'] as String?;
    _requestPermission();
    _loadPoisAndCams();

    if (!widget.isWorkerMode && _activeSosId != null) {
      _listenToSosStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _workerLocationSubscription?.cancel();
    _sosStatusSubscription?.cancel();
    _showPois.dispose();
    _showCams.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint("[LIFECYCLE] App resumed, re-checking permissions...");
      _checkPermissionStatus();
    }
  }
  
  Future<void> _checkPermissionStatus() async {
    final status = await perm.Permission.location.status;
    if (status.isGranted || status.isLimited) {
       if (!_isListeningLocation) {
         _listenToLocation();
       }
    } else {
      // Игнорируем permanentDenied здесь, чтобы не спамить
      debugPrint("[PERMISSIONS] Permission status: $status. Not listening to location.");
    }
  }

  Future<void> _requestPermission() async {
    var status = await perm.Permission.location.status;
    debugPrint("[PERMISSIONS] Initial permission status: $status");

    if (status.isGranted || status.isLimited) {
      debugPrint("[PERMISSIONS] Permission already granted. Starting location listen.");
      _listenToLocation();
      return;
    }

    // ИСПРАВЛЕНИЕ: Если разрешение denied навсегда, просто уведомляем.
    if (status.isPermanentlyDenied) {
      debugPrint("[PERMISSIONS] Permission permanently denied. User must manually enable it.");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Разрешите доступ к GPS в настройках.')),
         );
      }
      return;
    }

    // ИСПРАВЛЕНИЕ: Запрашиваем разрешение
    debugPrint("[PERMISSIONS] Permission not granted, requesting...");
    status = await perm.Permission.location.request();

    if (status.isGranted || status.isLimited) {
      debugPrint("[PERMISSIONS] Permission granted after request. Starting location listen.");
      _listenToLocation();
    } else {
      debugPrint('[PERMISSIONS] Location permission denied. Status: $status');
    }
  }

  void _listenToLocation() async {
    if (_isListeningLocation) return;
    debugPrint("[GPS] _listenToLocation called.");
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      debugPrint('[GPS] Location service is disabled. Requesting...');
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        debugPrint('[GPS] Location service request DENIED by user. GPS will not work.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пожалуйста, включите GPS на телефоне.')),
          );
        }
        return; 
      }
    }

    debugPrint("[GPS] Service is ON. Starting location stream...");
    _isListeningLocation = true;

    _locationSubscription =
        location.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        debugPrint("✅ [GPS] COORDINATES RECEIVED: Lat=${locationData.latitude}, Lon=${locationData.longitude}");
        if (mounted) {
          setState(() {
            _currentLocation =
                LatLng(locationData.latitude!, locationData.longitude!);
          });
        }
        if (widget.isWorkerMode && _activeSosId != null) {
          CloudService.updateWorkerLocation(_activeSosId!,
              locationData.latitude!, locationData.longitude!, 'moving');
        }
      }
    }, onError: (e) {
        debugPrint("💥 [GPS] ERROR in location stream: $e");
        _isListeningLocation = false;
    });
  }

  void _listenToSosStatus() {
    _sosStatusSubscription?.cancel();
    _sosStatusSubscription =
        CloudService.getSOSRequestStream(_activeSosId!).listen((request) {
      if (request != null && mounted) {
        final newWorkerId = request['assignedWorkerId'] as String?;
        final status = request['status'] as String?;

        if (status == 'closed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SOS-запрос закрыт Работником.')),
          );
          setState(() {
            _activeSosId = null;
            _assignedWorkerId = null;
            _trackedWorkerLocation = null;
          });
          _workerLocationSubscription?.cancel();
          _sosStatusSubscription?.cancel();
          return;
        }

        if (newWorkerId != null && newWorkerId != _assignedWorkerId) {
          setState(() {
            _assignedWorkerId = newWorkerId;
          });
          _listenToWorkerLocation(newWorkerId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('К вам назначен Работник!')),
          );
        } else if (newWorkerId == null && _assignedWorkerId != null) {
          _workerLocationSubscription?.cancel();
          setState(() {
            _assignedWorkerId = null;
            _trackedWorkerLocation = null;
          });
        }
      }
    });
  }

  void _listenToWorkerLocation(String workerId) {
    _workerLocationSubscription?.cancel();
    _workerLocationSubscription =
        CloudService.getActiveWorkerLocation(workerId).listen((location) {
      if (location != null && mounted) {
        setState(() {
          _trackedWorkerLocation =
              LatLng(location['lat'] as double, location['lon'] as double);
        });
      }
    });
  }

  void _loadPoisAndCams() async {
    final pois = await DBService.getPois();
    final cams = await DBService.getCams();
    if (mounted) {
      setState(() {
        _pois = pois;
        _cams = cams;
      });
    }
  }

  void _openSosChat(BuildContext context) {
    String? chatId = widget.isWorkerMode
        ? (widget.activeSos?['id'] as String?)
        : _activeSosId;

    if (chatId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(sosId: chatId)),
      );
    } else {
      if (_currentLocation != null) {
        _startNewSosProcess(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Не удалось определить ваше местоположение. Попробуйте позже.')),
        );
      }
    }
  }

  void _closeSosRequest(BuildContext context) async {
    final sosId = widget.activeSos!['id'] as String;
    await CloudService.closeSOS(sosId);

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WorkerHomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _startNewSosProcess(BuildContext context) async {
    final cloudId = await CloudService.sendSOS(_currentLocation!.latitude,
        _currentLocation!.longitude, 'Нужна помощь', 'client_id_temp');

    if (mounted) {
      setState(() {
        _activeSosId = cloudId;
      });
      _listenToSosStatus();
    }

    if (mounted) {
      _openSosChat(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("--- MAP_SCREEN BUILD --- _currentLocation is: $_currentLocation");
    
    final isChatActive = _activeSosId != null || widget.activeSos != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isWorkerMode ? 'Карта Клиента SOS' : 'Карта AI Помощник'),
        backgroundColor: widget.isWorkerMode ? Colors.blue.shade700 : Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () => _toggleLayers(),
            tooltip: 'Показать/Скрыть слои',
          ),
          if (widget.isWorkerMode && widget.activeSos != null)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
              onPressed: () => _closeSosRequest(context),
              tooltip: 'Закрыть SOS-запрос',
            ),
        ],
      ),
      body: Stack(
        children: [
          MapSwitcher(
            current: _currentLocation,
            pois: _pois,
            cams: _cams,
            showPois: _showPois,
            showCams: _showCams,
            isWorkerMode: widget.isWorkerMode,
            activeSos: widget.activeSos,
            trackedWorkerLocation: _trackedWorkerLocation,
          ),
          if (_currentLocation == null)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.red,
                color: Colors.white,
              ),
            ),
          if (!widget.isWorkerMode)
            const Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(height: 150, child: NewsFeed()),
            ),
          Positioned(
            right: 16,
            bottom: widget.isWorkerMode ? 16 : 160,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'sosBtn',
                  onPressed: () => _openSosChat(context),
                  backgroundColor: isChatActive ? Colors.green : Colors.red,
                  child: Icon(isChatActive ? Icons.chat : Icons.warning_amber),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'layersBtn',
                  onPressed: () => _toggleLayers(),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.layers_clear),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLayers() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('Точки интереса (Полиция/СТО)'),
              trailing: ValueListenableBuilder<bool>(
                valueListenable: _showPois,
                builder: (context, value, child) => Switch(
                  value: value,
                  onChanged: (val) => _showPois.value = val,
                ),
              ),
            ),
            ListTile(
              title: const Text('Камеры (Антирадар)'),
              trailing: ValueListenableBuilder<bool>(
                valueListenable: _showCams,
                builder: (context, value, child) => Switch(
                  value: value,
                  onChanged: (val) => _showCams.value = val,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class MapSwitcher extends StatelessWidget {
  final LatLng? current;
  final List<Map<String, dynamic>> pois;
  final List<Map<String, dynamic>> cams;
  final ValueNotifier<bool> showPois;
  final ValueNotifier<bool> showCams;
  final bool isWorkerMode;
  final Map<String, dynamic>? activeSos;
  final LatLng? trackedWorkerLocation;

  const MapSwitcher({
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

  @override
  Widget build(BuildContext context) {
    // 🛑 ИСПРАВЛЕНИЕ УСЛОВИЯ: 
    // Мы хотим использовать MapYandex на iOS/Android, кроме случаев Web, Linux, Windows, macOS.
    // Убираем условие "&& kDebugMode" для iOS, чтобы использовать Yandex Mapkit!
    bool useFallback = kIsWeb || 
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (useFallback) {
      // Это заглушка (MapFlutter) для не-мобильных платформ
      return MapFlutter(
        current: current,
        pois: pois,
        cams: cams,
        showPois: showPois,
        showCams: showCams,
        isWorkerMode: isWorkerMode,
        activeSos: activeSos,
        trackedWorkerLocation: trackedWorkerLocation,
      );
    } else {
      // ЭТО ТО, ЧТО НАМ НУЖНО: Yandex Mapkit для iOS и Android
      return MapYandex(
        current: current,
        pois: pois,
        cams: cams,
        showPois: showPois,
        showCams: showCams,
        isWorkerMode: isWorkerMode,
        activeSos: activeSos,
        trackedWorkerLocation: trackedWorkerLocation,
      );
    }
  }
}