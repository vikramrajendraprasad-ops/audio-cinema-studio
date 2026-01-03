
package com.example.audio_cinema_studio

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "audio_cinema/engine"
    private lateinit var cinemaEngine: CinemaEngine

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        cinemaEngine = CinemaEngine()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "setCinemaConfig" -> {
                    try {
                        val args = call.arguments as Map<*, *>

                        val inputPath = args["inputPath"] as String? ?: ""
                        val profile = args["profile"] as String
                        val channels = args["channels"] as String
                        val intensity = args["intensity"] as String

                        Log.d(
                            "AudioCinema",
                            "Flutter → Kotlin config received"
                        )

                        cinemaEngine.applyCinemaConfig(
                            inputPath = inputPath,
                            profile = profile,
                            channels = channels,
                            intensity = intensity
                        )

                        result.success("Cinema config received")

                    } catch (e: Exception) {
                        Log.e("AudioCinema", "Config error", e)
                        result.error("ENGINE_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
