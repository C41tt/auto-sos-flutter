import UIKit
import Flutter
import YandexMapsMobile
import os

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Логируем старт приложения (появится в log stream / Xcode console)
    print("APP START: didFinishLaunchingWithOptions called")
    let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
    print("Bundle identifier: \(bundleId)")

    // Попытка взять ключ "впаянный" прямо здесь (быстрая страховка)
    var apiKey = "c30ca45b-564e-4260-8dad-c82f6238aa0c"

    // Если по какой-то причине строка пустая (или пробелы) — попробуем прочитать из Info.plist Backup:
    if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      if let infoKey = Bundle.main.object(forInfoDictionaryKey: "MapKitApiKey") as? String {
        apiKey = infoKey
        print("Info.plist MapKitApiKey found (used as fallback)")
      } else {
        print("No API key hardcoded and no MapKitApiKey in Info.plist")
      }
    } else {
      print("Hardcoded API key present (length: \(apiKey.count))")
    }

    // Финальная проверка и передача ключа в SDK
    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      // Если ключ пуст — логируем и не вызываем setApiKey (чтобы легче было отлавливать)
      print("⚠️ MapKit API key is EMPTY. YMKMapKit.setApiKey will NOT be called.")
      os_log("MapKit API key is empty. Please set MapKitApiKey in Info.plist or hardcode it in AppDelegate.", type: .error)
    } else {
      print("Setting MapKit API key (len: \(trimmed.count)) -> calling YMKMapKit.setApiKey")
      YMKMapKit.setApiKey(trimmed)
      print("YMKMapKit.setApiKey called")
    }

    // Регистрируем плагины Flutter (после установки ключа)
    GeneratedPluginRegistrant.register(with: self)

    // Возвращаем управление системе
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}