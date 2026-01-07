import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:async';
import '../services/chat_service.dart';
import '../services/realtime_storage_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../utils/helpers.dart';
import '../utils/app_theme.dart';
import '../widgets/realtime_db_image.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/voice_message_player.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _realtimeStorageService = RealtimeStorageService();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  bool _isUploadingImage = false;
  bool _isRecording = false;
  bool _isUploadingVoice = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordingPath;
  final Set<String> _markedAsRead = {}; // Track which messages we've already marked as read
  ChatRetentionMode _currentRetentionMode = ChatRetentionMode.allTime;
  Timer? _cleanupTimer;
  bool _showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadRetentionMode();
    _startCleanupTimer();

    // Hide emoji picker when keyboard appears
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _focusNode.dispose();

    // Delete seen messages when receiver exits (for seenAndDelete mode)
    if (_currentRetentionMode == ChatRetentionMode.seenAndDelete) {
      _chatService.deleteMessagesSeenByReceiver(
        widget.currentUserId,
        widget.otherUser.uid,
      );
    }

    super.dispose();
  }

  Future<void> _loadRetentionMode() async {
    final mode = await _chatService.getChatRetentionMode(
      widget.currentUserId,
      widget.otherUser.uid,
    );
    if (mounted) {
      setState(() {
        _currentRetentionMode = mode;
      });
    }
  }

  void _startCleanupTimer() {
    // Run cleanup every hour
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      if (_currentRetentionMode == ChatRetentionMode.hour24) {
        try {
          await _chatService.deleteOldMessages(widget.currentUserId, widget.otherUser.uid);
        } catch (e) {
          debugPrint('Cleanup timer error: $e');
        }
      }
    });
  }

  Future<void> _updateRetentionMode(ChatRetentionMode mode) async {
    try {
      await _chatService.updateChatRetentionMode(
        widget.currentUserId,
        widget.otherUser.uid,
        mode,
      );
      setState(() {
        _currentRetentionMode = mode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Chat retention set to: ${mode.displayName}'),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }

      // If switching to 24 hour mode, delete old messages immediately
      if (mode == ChatRetentionMode.hour24) {
        await _chatService.deleteOldMessages(widget.currentUserId, widget.otherUser.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update retention mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markUnreadMessagesAsRead(List<MessageModel> messages) async {
    try {
      final unreadMessageIds = messages
          .where(
            (msg) =>
                msg.receiverId == widget.currentUserId &&
                !msg.isRead &&
                !_markedAsRead.contains(msg.id), // Don't mark if already marked
          )
          .map((msg) => msg.id)
          .toList();

      if (unreadMessageIds.isEmpty) return;

      // Add to set immediately to prevent duplicate marking
      _markedAsRead.addAll(unreadMessageIds);

      // Use batch update for instant real-time updates
      await _chatService.markMultipleMessagesAsRead(
        widget.currentUserId,
        widget.otherUser.uid,
        unreadMessageIds,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String text = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.otherUser.uid,
        text: text,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _showUploadProgress(String message, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (!isSuccess && !isError)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (isSuccess)
              const Icon(Icons.check_circle_rounded, color: Colors.white)
            else
              const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: isSuccess || isError ? 2 : 30),
        backgroundColor: isSuccess
            ? const Color(0xFF10B981)
            : isError
                ? const Color(0xFFEF4444)
                : const Color(0xFF6366F1),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required')),
          );
        }
        return;
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
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
        _recordingDuration = Duration.zero;
      });

      // Update duration every second
      _updateRecordingDuration();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  void _updateRecordingDuration() {
    if (!_isRecording) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration = _recordingDuration + const Duration(seconds: 1);
        });
        _updateRecordingDuration();
      }
    });
  }

  Future<void> _stopRecording({bool send = true}) async {
    try {
      if (!_isRecording) return;

      final path = await _audioRecorder.stop();
      if (path == null) {
        throw Exception('Recording path is null');
      }

      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });

      if (send && _recordingPath != null) {
        await _sendVoiceMessage(File(_recordingPath!));
      } else if (_recordingPath != null) {
        // Delete the recording if not sending
        try {
          await File(_recordingPath!).delete();
        } catch (e) {
          debugPrint('Error deleting recording: $e');
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _sendVoiceMessage(File audioFile) async {
    try {
      setState(() => _isUploadingVoice = true);
      _showUploadProgress('🎤 Processing voice...');

      _showUploadProgress('☁️ Uploading voice...');
      String voiceId = await _realtimeStorageService.uploadVoiceToRealtimeDB(
        audioFile,
        widget.currentUserId,
      );

      _showUploadProgress('📝 Creating message...');
      String voiceRef = 'rtdb://${widget.currentUserId}/$voiceId';

      _showUploadProgress('📤 Sending...');
      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.otherUser.uid,
        voiceUrl: voiceRef,
      );

      _showUploadProgress('✅ Voice message sent!', isSuccess: true);
      _scrollToBottom();

      // Clean up temporary file
      try {
        await audioFile.delete();
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
    } catch (e) {
      debugPrint('Error sending voice message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('❌ Failed: ${e.toString()}'),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFFEF4444),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _sendVoiceMessage(audioFile),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingVoice = false;
          _recordingPath = null;
          _recordingDuration = Duration.zero;
        });
      }
    }
  }

  Future<void> _sendImage() async {
    try {
      // Step 1: Pick image
      _showUploadProgress('📷 Opening gallery...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        return;
      }

      setState(() => _isUploadingImage = true);

      // Step 2: Reading image
      _showUploadProgress('📖 Reading image...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: Converting to Base64
      _showUploadProgress('🔄 Converting image...');

      // Step 4: Uploading to database
      _showUploadProgress('☁️ Uploading to database...');

      String imageId = await _realtimeStorageService.uploadImageToRealtimeDB(
        File(image.path),
        widget.currentUserId,
      );

      // Step 5: Creating message
      _showUploadProgress('📝 Creating message...');

      String imageRef = 'rtdb://${widget.currentUserId}/$imageId';

      // Step 6: Sending
      _showUploadProgress('📤 Sending...');

      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.otherUser.uid,
        imageUrl: imageRef,
      );

      // Success!
      _showUploadProgress('✅ Image sent successfully!', isSuccess: true);

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('❌ Failed: ${e.toString()}'),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFFEF4444),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _sendImage,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 16),
            Expanded(
              child: Text('Coming Soon - Voice Call feature is under development'),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _showDeleteMessageDialog(MessageModel message) {
    final bool isMyMessage = message.senderId == widget.currentUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Message',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_sweep, color: AppTheme.primaryColor),
              title: const Text(
                'Delete for me',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Message will be removed from your chat',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteMessageForMe(message);
              },
            ),
            if (isMyMessage) ...[
              const Divider(color: AppTheme.borderDark),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete for everyone',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Message will be removed for all',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessageForEveryone(message);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessageForMe(MessageModel message) async {
    try {
      await _chatService.deleteMessageForMe(
        widget.currentUserId,
        widget.otherUser.uid,
        message.id,
        widget.currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Message deleted for you'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessageForEveryone(MessageModel message) async {
    try {
      await _chatService.deleteMessage(
        widget.currentUserId,
        widget.otherUser.uid,
        message.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Message deleted for everyone'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: AppTheme.iconButtonDecoration,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient.scale(0.3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ProfileAvatar(
                    photoUrl: widget.otherUser.photoUrl,
                    userName: widget.otherUser.name,
                    radius: 20,
                  ),
                ),
                if (widget.otherUser.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.backgroundDark, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    widget.otherUser.isOnline
                        ? 'Online'
                        : widget.otherUser.lastSeen != null
                            ? 'Last seen ${Helpers.formatLastSeen(widget.otherUser.lastSeen)}'
                            : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.otherUser.isOnline
                          ? AppTheme.accentColor
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: AppTheme.iconButtonDecoration,
            child: IconButton(
              icon: const Icon(Icons.call, color: AppTheme.primaryColor, size: 22),
              onPressed: _startVoiceCall,
              tooltip: 'Voice Call - Coming Soon',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: AppTheme.iconButtonDecoration,
            child: PopupMenuButton<ChatRetentionMode>(
              icon: const Icon(Icons.more_vert, color: AppTheme.primaryColor, size: 22),
              tooltip: 'Chat Settings',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppTheme.cardDark,
              elevation: 8,
              offset: const Offset(0, 50),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.auto_delete, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Auto-Delete Messages',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: AppTheme.borderDark, thickness: 1),
                    ],
                  ),
                ),
                ...ChatRetentionMode.values.map((mode) {
                  final isSelected = mode == _currentRetentionMode;
                  return PopupMenuItem<ChatRetentionMode>(
                    value: mode,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppTheme.primaryColor, width: 1)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mode.displayName,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mode.description,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
              onSelected: (ChatRetentionMode mode) {
                if (mode != _currentRetentionMode) {
                  _updateRetentionMode(mode);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(
                widget.currentUserId,
                widget.otherUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Filter out deleted messages for current user
                final allMessages = snapshot.data ?? [];
                final visibleMessages = allMessages
                    .where((msg) => !msg.isDeletedForUser(widget.currentUserId))
                    .toList();

                if (visibleMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                // Mark all unread messages as read
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markUnreadMessagesAsRead(visibleMessages);
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleMessages.length,
                  itemBuilder: (context, index) {
                    MessageModel message = visibleMessages[index];
                    bool isMe = message.senderId == widget.currentUserId;

                    return GestureDetector(
                      onLongPress: () => _showDeleteMessageDialog(message),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Profile photo for other user's messages
                            if (!isMe) ...[
                              ProfileAvatar(
                                photoUrl: widget.otherUser.photoUrl,
                                userName: widget.otherUser.name,
                                radius: 16,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: isMe ? AppTheme.messageGradient : null,
                                color: isMe ? null : AppTheme.cardDark,
                                border: isMe
                                    ? null
                                    : Border.all(color: AppTheme.borderDark, width: 1),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isMe
                                        ? AppTheme.primaryColor.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message.type == MessageType.image &&
                                      message.imageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: RealtimeDBImage(
                                        imageRef: message.imageUrl!,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else if (message.type == MessageType.voice &&
                                      message.voiceUrl != null)
                                    VoiceMessagePlayer(
                                      voiceRef: message.voiceUrl!,
                                      isMe: isMe,
                                    )
                                  else if (message.text != null)
                                    Text(
                                      message.text!,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : AppTheme.textPrimary,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        Helpers.formatMessageTime(message.time),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMe
                                              ? Colors.white.withOpacity(0.8)
                                              : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                                          size: 16,
                                          color: message.isRead
                                              ? AppTheme.accentColor
                                              : Colors.white.withOpacity(0.7),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isMe) const SizedBox(width: 8),
                          ],
                        ),
                      ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                top: BorderSide(color: AppTheme.borderDark, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppTheme.cardDark,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Helpers.formatDuration(_recordingDuration),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _stopRecording(send: false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _stopRecording(send: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Send'),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            border: Border.all(color: AppTheme.borderDark, width: 1),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            children: [
                              // Image picker button
                              IconButton(
                                icon: _isUploadingImage
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                        ),
                                      )
                                    : const Icon(Icons.image_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                onPressed: _isUploadingImage || _isRecording || _isUploadingVoice
                                    ? null
                                    : _sendImage,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              // Mic button
                              GestureDetector(
                                onTap: _isRecording || _isUploadingVoice
                                    ? (_isRecording ? () => _stopRecording(send: true) : null)
                                    : _startRecording,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: _isRecording
                                      ? const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        )
                                      : null,
                                  child: _isUploadingVoice
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                          ),
                                        )
                                      : Icon(
                                          _isRecording ? Icons.stop : Icons.mic,
                                          color: _isRecording ? Colors.white : AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Text field
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  focusNode: _focusNode,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  maxLines: null,
                                  textCapitalization: TextCapitalization.sentences,
                                  onSubmitted: (_) => _sendMessage(),
                                  enabled: !_isRecording && !_isUploadingVoice,
                                ),
                              ),
                              // Emoji button
                              IconButton(
                                icon: Icon(
                                  _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                                  color: _showEmojiPicker ? AppTheme.primaryColor : AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: _isRecording || _isUploadingVoice
                                    ? null
                                    : () {
                                        setState(() {
                                          _showEmojiPicker = !_showEmojiPicker;
                                        });
                                        if (_showEmojiPicker) {
                                          _focusNode.unfocus();
                                        } else {
                                          _focusNode.requestFocus();
                                        }
                                      },
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: AppTheme.gradientButtonDecoration,
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: _isRecording || _isUploadingVoice ? null : _sendMessage,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  // Emoji Picker
                  if (_showEmojiPicker)
                    SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          _messageController.text += emoji.emoji;
                        },
                        config: Config(
                          height: 250,
                          checkPlatformCompatibility: true,
                          emojiViewConfig: EmojiViewConfig(
                            backgroundColor: AppTheme.cardDark,
                            columns: 7,
                            emojiSizeMax: 28,
                            verticalSpacing: 0,
                            horizontalSpacing: 0,
                            gridPadding: EdgeInsets.zero,
                            recentsLimit: 28,
                            replaceEmojiOnLimitExceed: false,
                            buttonMode: ButtonMode.MATERIAL,
                          ),
                          skinToneConfig: const SkinToneConfig(
                            enabled: true,
                            dialogBackgroundColor: Color(0xFF2E2E2E),
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            backgroundColor: AppTheme.surfaceDark,
                            iconColor: AppTheme.textSecondary,
                            iconColorSelected: AppTheme.primaryColor,
                            indicatorColor: AppTheme.primaryColor,
                            backspaceColor: AppTheme.primaryColor,
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(
                            backgroundColor: AppTheme.surfaceDark,
                            buttonIconColor: AppTheme.textSecondary,
                          ),
                          searchViewConfig: const SearchViewConfig(
                            backgroundColor: AppTheme.cardDark,
                            buttonIconColor: Colors.white,
                            hintText: 'Search emoji...',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

