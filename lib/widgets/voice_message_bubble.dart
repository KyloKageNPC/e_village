import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import '../models/chat_message_model.dart';

class VoiceMessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // Listen to player state
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Listen to duration
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Auto-reset when playback completes
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        _audioPlayer.seek(Duration.zero);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // If not initialized or completed, set the source
        if (_audioPlayer.processingState == ProcessingState.idle ||
            _audioPlayer.processingState == ProcessingState.completed) {
          setState(() => _isLoading = true);
          await _audioPlayer.setFilePath(widget.message.message);
          setState(() => _isLoading = false);
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing voice message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('h:mm a');

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe)
            Padding(
              padding: EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                widget.message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.purple.shade600 : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.isMe ? 20 : 4),
                topRight: Radius.circular(widget.isMe ? 4 : 20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play/Pause Button
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.purple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isMe
                                      ? Colors.white
                                      : Colors.purple.shade600,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.isMe
                                ? Colors.white
                                : Colors.purple.shade600,
                            size: 24,
                          ),
                  ),
                ),
                SizedBox(width: 12),

                // Waveform/Progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _duration.inMilliseconds > 0
                              ? _position.inMilliseconds /
                                  _duration.inMilliseconds
                              : 0,
                          backgroundColor: widget.isMe
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.purple.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isMe ? Colors.white : Colors.purple.shade600,
                          ),
                          minHeight: 3,
                        ),
                      ),
                      SizedBox(height: 6),

                      // Duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isMe
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.black54,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isMe
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),

                // Time
                Text(
                  dateFormat.format(widget.message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
