package com.yourbrand.audiocinemastudio.engine

class FfmpegCommandBuilder {

    fun build(
        inputPath: String,
        outputPath: String,
        profile: CinemaProfile,
        channels: OutputChannels,
        intensity: ProfileIntensity
    ): String {

        val profileFilter = when (profile) {
            CinemaProfile.DOLBY -> dolbyFilter(intensity)
            CinemaProfile.SONY  -> sonyFilter(intensity)
            CinemaProfile.JBL   -> jblFilter(intensity)
            CinemaProfile.BOSE  -> boseFilter(intensity)
        }

        val channelFilter = when (channels) {
            OutputChannels.STEREO -> "pan=stereo|c0=c0|c1=c1"
            OutputChannels.SURROUND_5_1 ->
                "pan=5.1|FL=c0|FR=c1|FC=0.5*c0+0.5*c1|LFE=lowpass=f=120|SL=c0|SR=c1"
            OutputChannels.SURROUND_7_1 ->
                "pan=7.1|FL=c0|FR=c1|FC=0.5*c0+0.5*c1|LFE=lowpass=f=120|BL=c0|BR=c1|SL=c0|SR=c1"
        }

        return """
            ffmpeg -y -i "$inputPath" \
            -filter_complex "$profileFilter,$channelFilter" \
            "$outputPath"
        """.trimIndent()
    }

    // ================= PROFILE FILTERS =================

    private fun dolbyFilter(intensity: ProfileIntensity): String =
        when (intensity) {
            ProfileIntensity.LOW    -> "aecho=0.8:0.9:500:0.2"
            ProfileIntensity.MEDIUM -> "aecho=0.8:0.9:1000:0.3"
            ProfileIntensity.HIGH   -> "aecho=0.8:0.9:1500:0.4,bass=g=4"
        }

    private fun sonyFilter(intensity: ProfileIntensity): String =
        when (intensity) {
            ProfileIntensity.LOW    -> "highpass=f=120"
            ProfileIntensity.MEDIUM -> "highpass=f=120,equalizer=f=3000:t=q:w=1:g=4"
            ProfileIntensity.HIGH   -> "highpass=f=120,equalizer=f=3000:t=q:w=1:g=6"
        }

    private fun jblFilter(intensity: ProfileIntensity): String =
        when (intensity) {
            ProfileIntensity.LOW    -> "bass=g=3:f=90"
            ProfileIntensity.MEDIUM -> "bass=g=6:f=90"
            ProfileIntensity.HIGH   -> "bass=g=8:f=90"
        }

    private fun boseFilter(intensity: ProfileIntensity): String =
        when (intensity) {
            ProfileIntensity.LOW    -> "lowpass=f=12000"
            ProfileIntensity.MEDIUM -> "lowpass=f=10000,bass=g=4"
            ProfileIntensity.HIGH   -> "lowpass=f=8000,bass=g=6"
        }
}
