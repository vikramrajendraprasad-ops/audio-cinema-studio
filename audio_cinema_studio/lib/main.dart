
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'models/cinema_config.dart';

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

  Map<String, dynamic> _configToMap() {
    return {
      'inputPath': inputFilePath ?? '',
      'profile': config.profile.name,
      'channels': config.channels.name,
      'intensity': config.intensity.name,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Cinema Studio'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cinema Conversion',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Pick File
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

            const SizedBox(height: 24),

            // Cinema Profile
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

            // Output Channels
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

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: inputFilePath == null
                    ? null
                    : () async {
                        final payload = _configToMap();

                        try {
                          final result = await _channel.invokeMethod(
                            'setCinemaConfig',
                            payload,
                          );
                          debugPrint('Native response: $result');
                        } catch (e) {
                          debugPrint('Platform error: $e');
                        }
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
