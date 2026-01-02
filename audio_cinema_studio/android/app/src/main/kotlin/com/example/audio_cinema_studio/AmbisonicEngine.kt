package com.yourbrand.audiocinemastudio

import android.util.Log

class AmbisonicEngine {

    fun applyHoa(
        inputPath: String,
        order: Int,        // 1st, 2nd, 3rd
        binaural: Boolean
    ): String {

        val filter = when (order) {
            1 -> "ambisonic=order=1"
            2 -> "ambisonic=order=2"
            3 -> "ambisonic=order=3"
            else -> "ambisonic=order=1"
        }

        val binauralPart =
            if (binaural) ",headphone=ir=builtin"
            else ""

        val command =
            "ffmpeg -i \"$inputPath\" -af \"$filter$binauralPart\" output_hoa.wav"

        Log.d("AmbisonicEngine", command)
        return command
    }
}
