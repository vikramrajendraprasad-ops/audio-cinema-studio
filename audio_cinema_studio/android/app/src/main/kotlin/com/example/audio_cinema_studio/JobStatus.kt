package com.example.audiocinemastudio

import java.io.File

object JobStatus {
    private val statusFile = File("/sdcard/AudioCinema/status.json")

    fun read(): String {
        if (!statusFile.exists()) return "idle"
        val text = statusFile.readText()
        return when {
            text.contains("processing") -> "processing"
            text.contains("done") -> "done"
            text.contains("error") -> "error"
            else -> "idle"
        }
    }
}
