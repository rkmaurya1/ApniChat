import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new group
  Future<String> createGroup({
    required String groupName,
    required String createdBy,
    required List<String> memberIds,
    String? groupPhotoUrl,
  }) async {
    try {
      String groupId = _uuid.v4();

      // Creator is always an admin and member
      List<String> finalMemberIds = memberIds.toSet().toList();
      if (!finalMemberIds.contains(createdBy)) {
        finalMemberIds.add(createdBy);
      }

      GroupModel group = GroupModel(
        groupId: groupId,
        groupName: groupName,
        groupPhotoUrl: groupPhotoUrl,
        memberIds: finalMemberIds,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        adminIds: [createdBy], // Creator is the first admin
      );

      await _firestore.collection('groups').doc(groupId).set(group.toMap());

      return groupId;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Send message to group
  Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    String? text,
    String? imageUrl,
    String? voiceUrl,
  }) async {
    try {
      String messageId = _uuid.v4();

      MessageModel message = MessageModel(
        id: messageId,
        senderId: senderId,
        groupId: groupId,
        text: text,
        imageUrl: imageUrl,
        voiceUrl: voiceUrl,
        type: imageUrl != null
            ? MessageType.image
            : voiceUrl != null
                ? MessageType.voice
                : MessageType.text,
        time: DateTime.now(),
        isRead: false,
        readBy: {senderId: true}, // Sender has read their own message
      );

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update group's last message
      await _firestore.collection('groups').doc(groupId).update({
        'lastMessage': text ?? (imageUrl != null ? 'Image' : 'Voice message'),
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessageSenderId': senderId,
      });
    } catch (e) {
      throw Exception('Failed to send group message: $e');
    }
  }

  // Get messages from a group
  Stream<List<MessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get all groups for a user
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      List<GroupModel> groups = snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data()))
          .toList();

      // Sort by last message time (most recent first)
      groups.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return groups;
    });
  }

  // Get group details
  Future<GroupModel?> getGroupDetails(String groupId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get group details: $e');
    }
  }

  // Add members to group
  Future<void> addMembersToGroup({
    required String groupId,
    required List<String> newMemberIds,
  }) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion(newMemberIds),
      });
    } catch (e) {
      throw Exception('Failed to add members: $e');
    }
  }

  // Remove member from group
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([memberId]),
        'adminIds': FieldValue.arrayRemove([memberId]), // Remove from admins too if they were
      });
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // Leave group
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      GroupModel? group = await getGroupDetails(groupId);
      if (group == null) return;

      // If the leaving user is the only admin, make another member admin
      if (group.adminIds.contains(userId) && group.adminIds.length == 1) {
        List<String> otherMembers = group.memberIds.where((id) => id != userId).toList();
        if (otherMembers.isNotEmpty) {
          await _firestore.collection('groups').doc(groupId).update({
            'adminIds': FieldValue.arrayUnion([otherMembers.first]),
          });
        }
      }

      await removeMemberFromGroup(groupId: groupId, memberId: userId);
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  // Update group info
  Future<void> updateGroupInfo({
    required String groupId,
    String? groupName,
    String? groupPhotoUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (groupName != null) updates['groupName'] = groupName;
      if (groupPhotoUrl != null) updates['groupPhotoUrl'] = groupPhotoUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('groups').doc(groupId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update group info: $e');
    }
  }

  // Make a member an admin
  Future<void> makeAdmin({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'adminIds': FieldValue.arrayUnion([memberId]),
      });
    } catch (e) {
      throw Exception('Failed to make admin: $e');
    }
  }

  // Remove admin privileges
  Future<void> removeAdmin({
    required String groupId,
    required String memberId,
  }) async {
    try {
      GroupModel? group = await getGroupDetails(groupId);
      if (group != null && group.adminIds.length > 1) {
        await _firestore.collection('groups').doc(groupId).update({
          'adminIds': FieldValue.arrayRemove([memberId]),
        });
      } else {
        throw Exception('Cannot remove the only admin');
      }
    } catch (e) {
      throw Exception('Failed to remove admin: $e');
    }
  }

  // Mark message as read by user
  Future<void> markGroupMessageAsRead({
    required String groupId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy.$userId': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Delete group (admin only)
  Future<void> deleteGroup(String groupId) async {
    try {
      // Delete all messages first
      QuerySnapshot messages = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete the group
      await _firestore.collection('groups').doc(groupId).delete();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }
}
