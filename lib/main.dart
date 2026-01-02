
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const AudioCinemaStudioApp());
}

/* ===================== ENUMS ===================== */

enum CinemaProfile { dolby, sony, jbl, bose }
enum OutputChannels { stereo, surround51, surround71 }
enum ProfileIntensity { low, medium, high }

/* ===================== CONFIG MODEL ===================== */

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
}

/* ===================== APP ===================== */

class AudioCinemaStudioApp extends StatelessWidget {
  const AudioCinemaStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Cinema Studio',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const CinemaScreen(),
    );
  }
}

/* ===================== SCREEN ===================== */

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key});

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> {
  static const MethodChannel _channel =
      MethodChannel('audio_cinema/engine');

  CinemaConfig config = const CinemaConfig(
    profile: CinemaProfile.dolby,
    channels: OutputChannels.stereo,
    intensity: ProfileIntensity.medium,
  );

  String? inputFilePath;
  Timer? statusTimer;
  String jobState = "idle"; // idle | processing | done | error

  int hoaOrder = 1;
  bool binaural = true;

  /* ===================== STATUS POLLING ===================== */

  void startStatusPolling() {
    statusTimer?.cancel();
    statusTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final file = File('/sdcard/AudioCinema/status.json');
      if (!await file.exists()) return;
      try {
        final map = jsonDecode(await file.readAsString());
        final state = map['state'] ?? 'idle';
        setState(() => jobState = state);
        if (state == "done" || state == "error") {
          statusTimer?.cancel();
        }
      } catch (_) {}
    });
  }

  /* ===================== OUTPUT LIST ===================== */

  List<FileSystemEntity> listOutputs() {
    final dir = Directory('/sdcard/AudioCinema');
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .where((f) =>
            f.path.endsWith('.wav') ||
            f.path.endsWith('.ac3') ||
            f.path.endsWith('.flac'))
        .toList()
        .reversed
        .toList();
  }

  /* ===================== UI ===================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Cinema Studio'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /* ===== INFO ===== */
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'This app uses an external FFmpeg engine via Termux.\n'
                  'Keep Termux running in background.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /* ===== FILE PICKER ===== */
            FilledButton.icon(
              icon: const Icon(Icons.audiotrack),
              label: Text(inputFilePath == null
                  ? 'Pick Audio File'
                  : 'Audio Selected'),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.audio,
                );
                if (result != null) {
                  setState(() {
                    inputFilePath = result.files.single.path;
                  });
                }
              },
            ),

            if (inputFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  inputFilePath!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const Divider(height: 32),

            /* ===== CINEMA PROFILE ===== */
            const Text('Cinema Profile'),
            DropdownButtonFormField<CinemaProfile>(
              value: config.profile,
              items: const [
                DropdownMenuItem(
                    value: CinemaProfile.dolby,
                    child: Text('Dolby Cinema')),
                DropdownMenuItem(
                    value: CinemaProfile.sony,
                    child: Text('Sony Clarity')),
                DropdownMenuItem(
                    value: CinemaProfile.jbl,
                    child: Text('JBL Punch')),
                DropdownMenuItem(
                    value: CinemaProfile.bose,
                    child: Text('Bose Deep')),
              ],
              onChanged: (v) =>
                  setState(() => config = config.copyWith(profile: v)),
            ),

            const SizedBox(height: 16),

            /* ===== CHANNELS ===== */
            const Text('Output Channels'),
            SegmentedButton<OutputChannels>(
              segments: const [
                ButtonSegment(
                    value: OutputChannels.stereo, label: Text('Stereo')),
                ButtonSegment(
                    value: OutputChannels.surround51, label: Text('5.1')),
                ButtonSegment(
                    value: OutputChannels.surround71, label: Text('7.1')),
              ],
              selected: {config.channels},
              onSelectionChanged: (s) =>
                  setState(() => config = config.copyWith(channels: s.first)),
            ),

            const SizedBox(height: 16),

            /* ===== INTENSITY ===== */
            const Text('Profile Intensity'),
            SegmentedButton<ProfileIntensity>(
              segments: const [
                ButtonSegment(
                    value: ProfileIntensity.low, label: Text('Low')),
                ButtonSegment(
                    value: ProfileIntensity.medium, label: Text('Medium')),
                ButtonSegment(
                    value: ProfileIntensity.high, label: Text('High')),
              ],
              selected: {config.intensity},
              onSelectionChanged: (s) =>
                  setState(() => config = config.copyWith(intensity: s.first)),
            ),

            const Divider(height: 32),

            /* ===== PROGRESS ===== */
            Card(
              color: jobState == "processing"
                  ? Colors.orange.shade50
                  : jobState == "done"
                      ? Colors.green.shade50
                      : jobState == "error"
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (jobState == "processing")
                      const CircularProgressIndicator()
                    else if (jobState == "done")
                      const Icon(Icons.check_circle, color: Colors.green)
                    else if (jobState == "error")
                      const Icon(Icons.error, color: Colors.red)
                    else
                      const Icon(Icons.pause_circle),
                    const SizedBox(width: 12),
                    Text(jobState.toUpperCase()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            /* ===== CONVERT ===== */
            FilledButton(
              onPressed: inputFilePath == null
                  ? null
                  : () async {
                      setState(() => jobState = "processing");
                      startStatusPolling();

                      await _channel.invokeMethod(
                        'setCinemaConfig',
                        {
                          'inputPath': inputFilePath,
                          'profile': config.profile.name,
                          'channels': config.channels.name,
                          'intensity': config.intensity.name,
                        },
                      );
                    },
              child: const Text('Send to Cinema Engine'),
            ),

            OutlinedButton(
              onPressed: jobState == "processing"
                  ? () => File('/sdcard/AudioCinema/cancel.txt')
                      .writeAsStringSync('cancel')
                  : null,
              child: const Text('Cancel'),
            ),

            const Divider(height: 32),

            /* ===== AMB3D / HOA ===== */
            const Text(
              'Spatial Audio (amb3d)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            DropdownButton<int>(
              value: hoaOrder,
              items: const [
                DropdownMenuItem(value: 1, child: Text('HOA Order 1')),
                DropdownMenuItem(value: 2, child: Text('HOA Order 2')),
                DropdownMenuItem(value: 3, child: Text('HOA Order 3')),
              ],
              onChanged: (v) => setState(() => hoaOrder = v!),
            ),

            SwitchListTile(
              title: const Text('Binaural Decode'),
              value: binaural,
              onChanged: (v) => setState(() => binaural = v),
            ),

            FilledButton(
              onPressed: inputFilePath == null
                  ? null
                  : () {
                      final cmd =
                          'ffmpeg -i "$inputFilePath" '
                          '-af "ambisonic=order=$hoaOrder'
                          '${binaural ? ",headphone=ir=builtin" : ""}" '
                          '/sdcard/AudioCinema/hoa_${DateTime.now().millisecondsSinceEpoch}.wav';

                      File('/sdcard/AudioCinema/job.txt')
                          .writeAsStringSync(cmd);
                      startStatusPolling();
                    },
              child: const Text('Run amb3d Engine'),
            ),

            const Divider(height: 32),

            /* ===== OUTPUT FILES ===== */
            const Text(
              'Output Files',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ...listOutputs().map((f) => ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(f.path.split('/').last),
                  subtitle: Text(f.path),
                )),
          ],
        ),
      ),
    );
  }
}
