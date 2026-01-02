package com.yourbrand.audiocinemastudio

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "audio_cinema/engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setCinemaConfig" -> {
                    val args = call.arguments as Map<*, *>
                    Log.d("AudioCinema", "Received config: $args")
                    result.success("Config received successfully")
                }
                else -> result.notImplemented()
            }
        }
    }
}
