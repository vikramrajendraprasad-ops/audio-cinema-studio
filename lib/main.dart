
import 'dart:async';
import 'dart:convert';
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
  // ──────────────────────────────────────────────
  // STATE
  // ──────────────────────────────────────────────
  String? selectedFilePath;
  String engineState = "IDLE";

  String selectedProfile = "Dolby";
  String selectedChannels = "Stereo";
  String selectedIntensity = "Medium";

  Timer? pollTimer;

  static const engineDir = "/storage/emulated/0/AudioCinema";

  // ──────────────────────────────────────────────
  // FILE PICKER
  // ──────────────────────────────────────────────
  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
      });
    }
  }

  // ──────────────────────────────────────────────
  // SEND JOB TO TERMUX ENGINE
  // ──────────────────────────────────────────────
  Future<void> sendToEngine() async {
    if (selectedFilePath == null) return;

    final dir = Directory(engineDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final job = {
      "input": selectedFilePath,
      "profile": selectedProfile.toLowerCase(),
      "channels": selectedChannels.toLowerCase(),
      "intensity": selectedIntensity.toLowerCase(),
    };

    final jobFile = File("$engineDir/job.json");
    await jobFile.writeAsString(jsonEncode(job), flush: true);

    setState(() {
      engineState = "PROCESSING";
    });

    startPolling();
  }

  // ──────────────────────────────────────────────
  // POLL STATUS.JSON
  // ──────────────────────────────────────────────
  void startPolling() {
    pollTimer?.cancel();

    pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final statusFile = File("$engineDir/status.json");

      if (!statusFile.existsSync()) return;

      final data = jsonDecode(await statusFile.readAsString());

      if (data["state"] != engineState) {
        setState(() {
          engineState = data["state"].toString().toUpperCase();
        });
      }

      if (data["state"] == "done" || data["state"] == "error") {
        pollTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Cinema Studio")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "External FFmpeg engine via Termux\n(Keep Termux running)",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickAudio,
              child: const Text("Pick Audio File"),
            ),

            if (selectedFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  selectedFilePath!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 20),

            DropdownButton<String>(
              value: selectedProfile,
              items: const [
                DropdownMenuItem(value: "Dolby", child: Text("Dolby Cinema")),
                DropdownMenuItem(value: "Sony", child: Text("Sony Clarity")),
                DropdownMenuItem(value: "JBL", child: Text("JBL Punch")),
                DropdownMenuItem(value: "Bose", child: Text("Bose Deep")),
              ],
              onChanged: (v) => setState(() => selectedProfile = v!),
            ),

            DropdownButton<String>(
              value: selectedChannels,
              items: const [
                DropdownMenuItem(value: "Stereo", child: Text("Stereo")),
                DropdownMenuItem(value: "5.1", child: Text("5.1")),
                DropdownMenuItem(value: "7.1", child: Text("7.1")),
              ],
              onChanged: (v) => setState(() => selectedChannels = v!),
            ),

            DropdownButton<String>(
              value: selectedIntensity,
              items: const [
                DropdownMenuItem(value: "Low", child: Text("Low")),
                DropdownMenuItem(value: "Medium", child: Text("Medium")),
                DropdownMenuItem(value: "High", child: Text("High")),
              ],
              onChanged: (v) => setState(() => selectedIntensity = v!),
            ),

            const SizedBox(height: 20),

            Text(
              "ENGINE STATUS: $engineState",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed:
                  engineState == "PROCESSING" ? null : sendToEngine,
              child: const Text("Send to Cinema Engine"),
            ),
          ],
        ),
      ),
    );
  }
}
