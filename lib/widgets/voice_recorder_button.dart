import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderButton extends StatefulWidget {
  final Function(String filePath) onVoiceSent;

  const VoiceRecorderButton({
    super.key,
    required this.onVoiceSent,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  DateTime? _recordingStartTime;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _checkPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/voice_$timestamp.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingStartTime = DateTime.now();
        _recordingDuration = 0;
      });

      // Update recording duration
      _updateRecordingDuration();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateRecordingDuration() {
    if (_isRecording && _recordingStartTime != null) {
      setState(() {
        _recordingDuration =
            DateTime.now().difference(_recordingStartTime!).inSeconds;
      });

      // Max 5 minutes (300 seconds)
      if (_recordingDuration >= 300) {
        _stopAndSendRecording();
        return;
      }

      Future.delayed(Duration(seconds: 1), () {
        if (_isRecording) {
          _updateRecordingDuration();
        }
      });
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
        _recordingDuration = 0;
      });

      if (path != null) {
        widget.onVoiceSent(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
        _recordingDuration = 0;
      });
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();

      // Delete the recording file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingStartTime = null;
        _recordingDuration = 0;
      });
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel button
            InkWell(
              onTap: _cancelRecording,
              child: Container(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 8),

            // Recording indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),

            // Duration
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(width: 12),

            // Send button
            InkWell(
              onTap: _stopAndSendRecording,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.purple.shade600,
      child: IconButton(
        icon: Icon(Icons.mic, color: Colors.white, size: 20),
        onPressed: _startRecording,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
