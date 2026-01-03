import 'dart:convert';
import 'dart:io';

class CinemaEngineService {
  static const engineDir = '/storage/emulated/0/AudioCinema';

  static Future<void> sendJob({
    required String inputPath,
    required String profile,
    required String channels,
    required String intensity,
  }) async {
    final job = {
      "input": inputPath,
      "profile": profile,
      "channels": channels,
      "intensity": intensity,
    };

    final file = File('$engineDir/job.json');
    await file.writeAsString(jsonEncode(job));
  }

  static Future<Map<String, dynamic>> readStatus() async {
    final file = File('$engineDir/status.json');
    if (!await file.exists()) {
      return {"state": "unknown"};
    }
    return jsonDecode(await file.readAsString());
  }
}
