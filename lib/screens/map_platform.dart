// Единый файл для импорта карты, который выберет нужную реализацию
export 'map_stub.dart'
    if (dart.library.io) 'map_yandex.dart'
    if (dart.library.html) 'map_web.dart';
