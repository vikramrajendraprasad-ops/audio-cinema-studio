import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cinema_config.dart';

class PresetService {
  static const _key = 'cinema_presets';

  static Future<void> savePreset(
    String name,
    CinemaConfig config,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_key);
    final Map<String, dynamic> presets =
        raw == null ? {} : jsonDecode(raw);

    presets[name] = {
      'profile': config.profile.name,
      'channels': config.channels.name,
      'intensity': config.intensity.name,
    };

    await prefs.setString(_key, jsonEncode(presets));
  }

  static Future<Map<String, CinemaConfig>> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(raw);
    final Map<String, CinemaConfig> result = {};

    decoded.forEach((name, data) {
      result[name] = CinemaConfig(
        profile: CinemaProfile.values
            .firstWhere((e) => e.name == data['profile']),
        channels: OutputChannels.values
            .firstWhere((e) => e.name == data['channels']),
        intensity: ProfileIntensity.values
            .firstWhere((e) => e.name == data['intensity']),
      );
    });

    return result;
  }
}
