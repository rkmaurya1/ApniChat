class ChatModel {
  final String chatId;
  final String userId1;
  final String userId2;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;

  ChatModel({
    required this.chatId,
    required this.userId1,
    required this.userId2,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'userId1': userId1,
      'userId2': userId2,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      userId1: map['userId1'] ?? '',
      userId2: map['userId2'] ?? '',
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
    );
  }
}

