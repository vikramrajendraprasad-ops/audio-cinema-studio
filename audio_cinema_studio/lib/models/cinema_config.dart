enum CinemaProfile {
  dolby,
  sony,
  jbl,
  bose,
}

enum OutputChannels {
  stereo,
  surround51,
  surround71,
}

enum ProfileIntensity {
  low,
  medium,
  high,
}

class CinemaConfig {
  final CinemaProfile profile;
  final OutputChannels channels;
  final ProfileIntensity intensity;

  const CinemaConfig({
    required this.profile,
    required this.channels,
    required this.intensity,
  });

  CinemaConfig copyWith({
    CinemaProfile? profile,
    OutputChannels? channels,
    ProfileIntensity? intensity,
  }) {
    return CinemaConfig(
      profile: profile ?? this.profile,
      channels: channels ?? this.channels,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  String toString() {
    return 'CinemaConfig(profile: $profile, channels: $channels, intensity: $intensity)';
  }
}
