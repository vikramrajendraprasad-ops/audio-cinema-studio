
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'models/cinema_config.dart';
import 'services/preset_service.dart';

void main() {
  runApp(const AudioCinemaStudioApp());
}

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
  Map<String, CinemaConfig> presets = {};

  Timer? statusTimer;
  String jobState = "idle"; // idle | processing | done | error

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    final loaded = await PresetService.loadPresets();
    setState(() => presets = loaded);
  }

  Map<String, dynamic> _configToMap() {
    return {
      'inputPath': inputFilePath ?? '',
      'profile': config.profile.name,
      'channels': config.channels.name,
      'intensity': config.intensity.name,
    };
  }

  void startStatusPolling() {
    statusTimer?.cancel();

    statusTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final file = File('/sdcard/AudioCinema/status.json');

      if (!await file.exists()) {
        setState(() => jobState = "idle");
        return;
      }

      try {
        final jsonMap = jsonDecode(await file.readAsString());
        final state = jsonMap['state'] ?? 'idle';

        setState(() => jobState = state);

        if (state == "done" || state == "error") {
          statusTimer?.cancel();
        }
      } catch (_) {
        setState(() => jobState = "idle");
      }
    });
  }

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
            const Text(
              'Cinema Conversion',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Termux info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'External Audio Engine Required',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Install Termux\n'
                      '2. Start Audio Cinema engine script\n'
                      '3. Keep Termux running in background\n\n'
                      'Processing happens outside this app.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pick audio file
            FilledButton.icon(
              icon: const Icon(Icons.audiotrack),
              label: Text(
                inputFilePath == null
                    ? 'Pick Audio File'
                    : 'Audio Selected',
              ),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.audio,
                );

                if (result != null && result.files.single.path != null) {
                  setState(() {
                    inputFilePath = result.files.single.path!;
                  });
                }
              },
            ),

            if (inputFilePath != null) ...[
              const SizedBox(height: 8),
              Text(
                inputFilePath!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],

            const SizedBox(height: 16),

            // Presets
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await PresetService.savePreset(
                        'Preset ${presets.length + 1}',
                        config,
                      );
                      await _loadPresets();
                    },
                    child: const Text('Save Preset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    hint: const Text('Load Preset'),
                    items: presets.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.key),
                          ),
                        )
                        .toList(),
                    onChanged: (name) {
                      if (name != null) {
                        setState(() {
                          config = presets[name]!;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Cinema profile
            const Text('Cinema Profile'),
            const SizedBox(height: 8),
            DropdownButtonFormField<CinemaProfile>(
              value: config.profile,
              items: const [
                DropdownMenuItem(
                  value: CinemaProfile.dolby,
                  child: Text('Dolby Cinema'),
                ),
                DropdownMenuItem(
                  value: CinemaProfile.sony,
                  child: Text('Sony Clarity'),
                ),
                DropdownMenuItem(
                  value: CinemaProfile.jbl,
                  child: Text('JBL Punch'),
                ),
                DropdownMenuItem(
                  value: CinemaProfile.bose,
                  child: Text('Bose Deep'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    config = config.copyWith(profile: value);
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Output channels
            const Text('Output Channels'),
            const SizedBox(height: 8),
            SegmentedButton<OutputChannels>(
              segments: const [
                ButtonSegment(
                  value: OutputChannels.stereo,
                  label: Text('Stereo'),
                ),
                ButtonSegment(
                  value: OutputChannels.surround51,
                  label: Text('5.1'),
                ),
                ButtonSegment(
                  value: OutputChannels.surround71,
                  label: Text('7.1'),
                ),
              ],
              selected: {config.channels},
              onSelectionChanged: (selection) {
                setState(() {
                  config = config.copyWith(channels: selection.first);
                });
              },
            ),

            const SizedBox(height: 24),

            // Intensity
            const Text('Profile Intensity'),
            const SizedBox(height: 8),
            SegmentedButton<ProfileIntensity>(
              segments: const [
                ButtonSegment(
                  value: ProfileIntensity.low,
                  label: Text('Low'),
                ),
                ButtonSegment(
                  value: ProfileIntensity.medium,
                  label: Text('Medium'),
                ),
                ButtonSegment(
                  value: ProfileIntensity.high,
                  label: Text('High'),
                ),
              ],
              selected: {config.intensity},
              onSelectionChanged: (selection) {
                setState(() {
                  config = config.copyWith(intensity: selection.first);
                });
              },
            ),

            const SizedBox(height: 24),

            // Progress UI
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
                      const Icon(Icons.pause_circle, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      jobState == "processing"
                          ? "Processing audio via external engine…"
                          : jobState == "done"
                              ? "Conversion completed successfully"
                              : jobState == "error"
                                  ? "Conversion failed"
                                  : "Idle",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Convert button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: inputFilePath == null
                    ? null
                    : () async {
                        setState(() => jobState = "processing");
                        startStatusPolling();

                        final payload = _configToMap();
                        await _channel.invokeMethod(
                          'setCinemaConfig',
                          payload,
                        );
                      },
                child: const Text('Send to Cinema Engine'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
