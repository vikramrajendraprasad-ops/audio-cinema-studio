
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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
      theme: ThemeData(useMaterial3: true),
      home: const CinemaHome(),
    );
  }
}

class CinemaHome extends StatefulWidget {
  const CinemaHome({super.key});

  @override
  State<CinemaHome> createState() => _CinemaHomeState();
}

class _CinemaHomeState extends State<CinemaHome> {
  String? pickedPath;
  String status = "IDLE";

  String profile = "Dolby Cinema";
  String channels = "stereo";
  String intensity = "medium";

  Timer? poller;

  final String workDir = "/sdcard/AudioCinema";

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null) return;

    setState(() {
      pickedPath = result.files.single.path;
    });
  }

  Future<void> sendToCinemaEngine() async {
    if (pickedPath == null) return;

    final dir = Directory(workDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final inputFile = File(pickedPath!);
    final ext = inputFile.path.split('.').last;
    final inputCopy = "$workDir/input.$ext";
    final outputFile = "$workDir/output_${channels}.wav";

    await inputFile.copy(inputCopy);

    final filter = buildFilter(profile, channels, intensity);

    final job = File("$workDir/job.txt");
    await job.writeAsString(
      "$inputCopy\n$outputFile\n$filter\n",
      flush: true,
    );

    setState(() {
      status = "PROCESSING";
    });

    startPolling();
  }

  void startPolling() {
    poller?.cancel();
    poller = Timer.periodic(const Duration(seconds: 2), (_) async {
      final statusFile = File("$workDir/status.json");
      if (!statusFile.existsSync()) return;

      final content = await statusFile.readAsString();
      if (content.contains("done")) {
        poller?.cancel();
        setState(() {
          status = "DONE";
        });
      }
    });
  }

  String buildFilter(String profile, String channels, String intensity) {
    final gain = intensity == "low"
        ? "2"
        : intensity == "high"
            ? "6"
            : "4";

    switch (profile) {
      case "Sony Clarity":
        return "highpass=f=150,treble=g=$gain";
      case "JBL Punch":
        return "bass=g=$gain";
      case "Bose Deep":
        return "bass=g=8,lowpass=f=10000";
      default:
        return "stereotools=mlev=0.015625,bass=g=$gain";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Cinema Studio")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "This app uses an external FFmpeg engine via Termux.\nKeep Termux running in background.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickAudio,
              child: Text(pickedPath == null ? "Pick Audio File" : "Audio Selected"),
            ),

            if (pickedPath != null)
              Text(
                pickedPath!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 20),

            DropdownButton<String>(
              value: profile,
              items: const [
                DropdownMenuItem(value: "Dolby Cinema", child: Text("Dolby Cinema")),
                DropdownMenuItem(value: "Sony Clarity", child: Text("Sony Clarity")),
                DropdownMenuItem(value: "JBL Punch", child: Text("JBL Punch")),
                DropdownMenuItem(value: "Bose Deep", child: Text("Bose Deep")),
              ],
              onChanged: (v) => setState(() => profile = v!),
            ),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: channels,
              items: const [
                DropdownMenuItem(value: "stereo", child: Text("Stereo")),
                DropdownMenuItem(value: "5.1", child: Text("5.1")),
                DropdownMenuItem(value: "7.1", child: Text("7.1")),
              ],
              onChanged: (v) => setState(() => channels = v!),
            ),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: intensity,
              items: const [
                DropdownMenuItem(value: "low", child: Text("Low")),
                DropdownMenuItem(value: "medium", child: Text("Medium")),
                DropdownMenuItem(value: "high", child: Text("High")),
              ],
              onChanged: (v) => setState(() => intensity = v!),
            ),

            const SizedBox(height: 20),

            Text("STATUS: $status"),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: status == "PROCESSING" ? null : sendToCinemaEngine,
              child: const Text("Send to Cinema Engine"),
            ),
          ],
        ),
      ),
    );
  }
}
