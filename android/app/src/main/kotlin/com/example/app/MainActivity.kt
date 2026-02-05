package com.example.app // ⚠️ ОСТАВЬ СВОЮ ПЕРВУЮ СТРОКУ КАК ЕСТЬ!
import android.app.Application
import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.android.FlutterActivity // Добавь если ругается

class MainApplication: Application() { // Если класс называется MainActivity, оставь MainActivity
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("c30ca45b-564e-4260-8dad-c82f6238aa0c") // [cite: 62]
    }
}