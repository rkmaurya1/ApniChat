enum MessageType { text, image, voice }

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? imageUrl;
  final String? voiceUrl;
  final MessageType type;
  final DateTime time;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.imageUrl,
    this.voiceUrl,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'type': type.name,
      'time': time.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
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
    );
  }
}

