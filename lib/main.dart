
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const AudioCinemaApp());
}

class AudioCinemaApp extends StatelessWidget {
  const AudioCinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audio Cinema Studio',
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

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    if (await Permission.manageExternalStorage.isGranted) return;
    await Permission.manageExternalStorage.request();
  }

  Future<Directory> ensureCinemaDir() async {
    final dir = Directory('/sdcard/AudioCinema');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => pickedFilePath = result.files.single.path!);
    }
  }

  Future<void> sendToEngine() async {
    if (pickedFilePath == null) return;

    final dir = await ensureCinemaDir();
    final input = File(pickedFilePath!);
    final ext = p.extension(input.path);

    final sharedInput = p.join(dir.path, 'input$ext');
    await input.copy(sharedInput);

    final output = p.join(
      dir.path,
      'output_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    final cmd = 'ffmpeg -y -i "$sharedInput" "$output"';

    await File(p.join(dir.path, 'job.txt')).writeAsString(cmd);
    await File(p.join(dir.path, 'status.json'))
        .writeAsString('{"state":"queued"}');

    setState(() => jobState = 'processing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Cinema Studio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.music_note),
              label: Text(
                pickedFilePath == null ? 'Pick Audio File' : 'Audio Selected',
              ),
              onPressed: pickAudio,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: pickedFilePath == null ? null : sendToEngine,
              child: const Text('Send to Cinema Engine'),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'STATUS: ${jobState.toUpperCase()}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
