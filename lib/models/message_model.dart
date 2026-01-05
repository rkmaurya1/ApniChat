enum MessageType { text, image, voice }

class MessageModel {
  final String id;
  final String senderId;
  final String? receiverId; // Nullable for group messages
  final String? groupId; // For group messages
  final String? text;
  final String? imageUrl;
  final String? voiceUrl;
  final MessageType type;
  final DateTime time;
  final bool isRead;
  final Map<String, bool>? readBy; // Track read status per user in groups
  final List<String>? deletedFor; // List of user IDs who deleted this message

  MessageModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.groupId,
    this.text,
    this.imageUrl,
    this.voiceUrl,
    required this.type,
    required this.time,
    this.isRead = false,
    this.readBy,
    this.deletedFor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'groupId': groupId,
      'text': text,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'type': type.name,
      'time': time.toIso8601String(),
      'isRead': isRead,
      'readBy': readBy,
      'deletedFor': deletedFor,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'],
      groupId: map['groupId'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      voiceUrl: map['voiceUrl'],
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      time: map['time'] != null
          ? DateTime.parse(map['time'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      readBy: map['readBy'] != null
          ? Map<String, bool>.from(map['readBy'])
          : null,
      deletedFor: map['deletedFor'] != null
          ? List<String>.from(map['deletedFor'])
          : null,
    );
  }

  // Check if message is deleted for a specific user
  bool isDeletedForUser(String userId) {
    return deletedFor?.contains(userId) ?? false;
  }
}

