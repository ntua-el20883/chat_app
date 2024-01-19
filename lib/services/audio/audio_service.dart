import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  String? _tempPath; // Path for temporary audio file

  // Initialize the recorder
  Future<void> init() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

    Future<void> dispose() async {
    if (_isRecorderInitialized) {
      await _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }
    }

  // Start recording
  Future<void> startRecording() async {
    if (!_isRecorderInitialized) return;
    _tempPath = (await getTemporaryDirectory()).path + '/temp_audio.wav';
    await _recorder.startRecorder(toFile: _tempPath);
  }

  // Stop recording and get the file path
  Future<String?> stopRecording() async {
    if (!_isRecorderInitialized) return null;
    await _recorder.stopRecorder();
    return _tempPath;
  }

  // Upload audio to Firebase Storage
  Future<String?> uploadAudioFile(String filePath) async {
    File file = File(filePath);
    try {
      String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('uploads/$fileName')
          .putFile(file);

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading audio: $e');
      return null;
    }
  }
}
