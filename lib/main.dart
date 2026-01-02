
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const AudioCinemaApp());
}

class AudioCinemaApp extends StatelessWidget {
  const AudioCinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Cinema Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const AudioCinemaHome(),
    );
  }
}

class AudioCinemaHome extends StatefulWidget {
  const AudioCinemaHome({super.key});

  @override
  State<AudioCinemaHome> createState() => _AudioCinemaHomeState();
}

class _AudioCinemaHomeState extends State<AudioCinemaHome> {
  String? pickedFilePath;
  String jobState = 'idle';

  String cinemaProfile = 'Dolby Cinema';
  String channels = 'Stereo';
  String intensity = 'Medium';

  final List<String> profiles = [
    'Dolby Cinema',
    'Sony Clarity',
    'JBL Punch',
    'Bose Deep',
  ];

  // 🔑 Ensure shared directory
  Future<Directory> ensureCinemaDir() async {
    final dir = Directory('/sdcard/AudioCinema');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // 🎵 Pick audio
  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        pickedFilePath = result.files.single.path!;
      });
    }
  }

  // 🚀 Send job to Termux engine
  Future<void> sendToCinemaEngine() async {
    if (pickedFilePath == null) return;

    final cinemaDir = await ensureCinemaDir();

    // Copy input file to shared storage
    final inputFile = File(pickedFilePath!);
    final ext = p.extension(inputFile.path);
    final sharedInput = p.join(cinemaDir.path, 'input$ext');
    await inputFile.copy(sharedInput);

    // Output file
    final outputFile = p.join(
      cinemaDir.path,
      'output_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    // Build FFmpeg command (basic – profiles can modify later)
    final cmd = 'ffmpeg -y -i "$sharedInput" "$outputFile"';

    // Write job.txt
    final jobFile = File(p.join(cinemaDir.path, 'job.txt'));
    await jobFile.writeAsString(cmd);

    // Write status.json
    final statusFile = File(p.join(cinemaDir.path, 'status.json'));
    await statusFile.writeAsString('{"state":"queued"}');

    setState(() {
      jobState = 'processing';
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'This app uses an external FFmpeg engine via Termux.\n'
                  'Keep Termux running in background.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: pickAudio,
              icon: const Icon(Icons.music_note),
              label: Text(
                pickedFilePath == null ? 'Pick Audio File' : 'Audio Selected',
              ),
            ),

            if (pickedFilePath != null) ...[
              const SizedBox(height: 8),
              Text(
                pickedFilePath!,
                style: const TextStyle(fontSize: 12),
              ),
            ],

            const SizedBox(height: 24),

            const Text('Cinema Profile'),
            DropdownButton<String>(
              value: cinemaProfile,
              isExpanded: true,
              items: profiles
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => cinemaProfile = v!),
            ),

            const SizedBox(height: 16),
            const Text('Output Channels'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Stereo', label: Text('Stereo')),
                ButtonSegment(value: '5.1', label: Text('5.1')),
                ButtonSegment(value: '7.1', label: Text('7.1')),
              ],
              selected: {channels},
              onSelectionChanged: (s) => setState(() => channels = s.first),
            ),

            const SizedBox(height: 16),
            const Text('Profile Intensity'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Low', label: Text('Low')),
                ButtonSegment(value: 'Medium', label: Text('Medium')),
                ButtonSegment(value: 'High', label: Text('High')),
              ],
              selected: {intensity},
              onSelectionChanged: (s) => setState(() => intensity = s.first),
            ),

            const SizedBox(height: 24),
            Card(
              color: jobState == 'processing'
                  ? Colors.orange.shade100
                  : Colors.grey.shade200,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      jobState == 'processing'
                          ? Icons.autorenew
                          : Icons.pause,
                    ),
                    const SizedBox(width: 8),
                    Text(jobState.toUpperCase()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  pickedFilePath == null ? null : sendToCinemaEngine,
              child: const Text('Send to Cinema Engine'),
            ),
          ],
        ),
      ),
    );
  }
}
