enum ChatRetentionMode {
  allTime,        // Messages stay forever (default)
  seenAndDelete,  // Delete after seen and user exits chat
  hour24,         // Delete after 24 hours
}

extension ChatRetentionModeExtension on ChatRetentionMode {
  String get displayName {
    switch (this) {
      case ChatRetentionMode.allTime:
        return 'All Time';
      case ChatRetentionMode.seenAndDelete:
        return 'Seen & Delete';
      case ChatRetentionMode.hour24:
        return '24 Hour Delete';
    }
  }

  String get description {
    switch (this) {
      case ChatRetentionMode.allTime:
        return 'Messages stay forever';
      case ChatRetentionMode.seenAndDelete:
        return 'Delete after seen and exit';
      case ChatRetentionMode.hour24:
        return 'Auto delete after 24 hours';
    }
  }

  String toValue() {
    return name;
  }

  static ChatRetentionMode fromValue(String? value) {
    if (value == null) return ChatRetentionMode.allTime;
    return ChatRetentionMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ChatRetentionMode.allTime,
    );
  }
}

class ChatModel {
  final String chatId;
  final String userId1;
  final String userId2;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final ChatRetentionMode retentionMode;

  ChatModel({
    required this.chatId,
    required this.userId1,
    required this.userId2,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.retentionMode = ChatRetentionMode.allTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'userId1': userId1,
      'userId2': userId2,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'retentionMode': retentionMode.toValue(),
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
      retentionMode: ChatRetentionModeExtension.fromValue(map['retentionMode']),
    );
  }

  ChatModel copyWith({
    String? chatId,
    String? userId1,
    String? userId2,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    ChatRetentionMode? retentionMode,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      retentionMode: retentionMode ?? this.retentionMode,
    );
  }
}

