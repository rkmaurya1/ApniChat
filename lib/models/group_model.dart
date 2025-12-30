class GroupModel {
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final List<String> adminIds;

  GroupModel({
    required this.groupId,
    required this.groupName,
    this.groupPhotoUrl,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.adminIds,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'memberIds': memberIds,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'adminIds': adminIds,
    };
  }

  // Create from Firestore document
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      groupId: map['groupId'] as String,
      groupName: map['groupName'] as String,
      groupPhotoUrl: map['groupPhotoUrl'] as String?,
      memberIds: List<String>.from(map['memberIds'] as List),
      createdBy: map['createdBy'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'] as String)
          : null,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      adminIds: List<String>.from(map['adminIds'] as List),
    );
  }

  // Copy with method for easy updates
  GroupModel copyWith({
    String? groupId,
    String? groupName,
    String? groupPhotoUrl,
    List<String>? memberIds,
    String? createdBy,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    List<String>? adminIds,
  }) {
    return GroupModel(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
      memberIds: memberIds ?? this.memberIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      adminIds: adminIds ?? this.adminIds,
    );
  }
}
