import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../services/realtime_storage_service.dart';
import '../utils/app_theme.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String voiceRef; // Format: rtdb://userId/voiceId
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.voiceRef,
    required this.isMe,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RealtimeStorageService _storageService = RealtimeStorageService();
  bool _isLoading = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _localFilePath;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadVoiceMessage();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  Future<void> _loadVoiceMessage() async {
    try {
      setState(() => _isLoading = true);

      // Parse voiceRef: rtdb://userId/voiceId
      final parts = widget.voiceRef.replaceFirst('rtdb://', '').split('/');
      if (parts.length != 2) {
        throw Exception('Invalid voice reference format');
      }
      final userId = parts[0];
      final voiceId = parts[1];

      // Get base64 audio from Realtime Database
      final base64Audio = await _storageService.getVoiceBase64(userId, voiceId);
      if (base64Audio == null) {
        throw Exception('Voice message not found');
      }

      // Decode base64 to bytes
      final audioBytes = base64Decode(base64Audio);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/voice_$voiceId.m4a');
      await file.writeAsBytes(audioBytes);
      _localFilePath = file.path;

      // Load audio player
      await _audioPlayer.setFilePath(_localFilePath!);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading voice message: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load voice message: $e')),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    // Clean up temporary file
    if (_localFilePath != null) {
      try {
        File(_localFilePath!).delete();
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe ? Colors.white : AppTheme.primaryColor,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isInitialized && _duration != Duration.zero)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: _duration == Duration.zero
                          ? 0
                          : _position.inMilliseconds.toDouble(),
                      max: _duration.inMilliseconds.toDouble(),
                      activeColor: widget.isMe
                          ? Colors.white
                          : AppTheme.primaryColor,
                      inactiveColor: widget.isMe
                          ? Colors.white.withOpacity(0.3)
                          : AppTheme.primaryColor.withOpacity(0.3),
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic,
                      size: 14,
                      color: widget.isMe
                          ? Colors.white.withOpacity(0.8)
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isInitialized && _duration != Duration.zero
                          ? _formatDuration(_position)
                          : '--:--',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isMe
                            ? Colors.white.withOpacity(0.8)
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isInitialized && _duration != Duration.zero) ...[
                      const Text(
                        ' / ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isMe
                              ? Colors.white.withOpacity(0.8)
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

