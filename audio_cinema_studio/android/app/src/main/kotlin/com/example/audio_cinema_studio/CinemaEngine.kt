package com.yourbrand.audiocinemastudio

import android.os.Environment
import android.util.Log
import com.yourbrand.audiocinemastudio.engine.*
import java.io.File

class CinemaEngine {

    private val commandBuilder = FfmpegCommandBuilder()

    private val bridgeDir: File =
        File(Environment.getExternalStorageDirectory(), "AudioCinema")

    private val jobFile: File =
        File(bridgeDir, "job.txt")

    fun applyCinemaConfig(
        inputPath: String,
        profile: String,
        channels: String,
        intensity: String
    ): Boolean {

        // Ensure bridge directory exists
        if (!bridgeDir.exists()) {
            bridgeDir.mkdirs()
        }

        val cinemaProfile = CinemaProfile.valueOf(profile.uppercase())

        val outputChannels = when (channels.lowercase()) {
            "stereo" -> OutputChannels.STEREO
            "surround51" -> OutputChannels.SURROUND_5_1
            "surround71" -> OutputChannels.SURROUND_7_1
            else -> OutputChannels.STEREO
        }

        val profileIntensity =
            ProfileIntensity.valueOf(intensity.uppercase())

        val outputPath = bridgeDir.absolutePath +
                "/output_" + System.currentTimeMillis() + ".wav"

        val ffmpegCommand = commandBuilder.build(
            inputPath = inputPath,
            outputPath = outputPath,
            profile = cinemaProfile,
            channels = outputChannels,
            intensity = profileIntensity
        )

        Log.d("CinemaEngine", "Writing FFmpeg job to file bridge")
        Log.d("CinemaEngine", ffmpegCommand)

        jobFile.writeText(ffmpegCommand)

        return true
    }
}
