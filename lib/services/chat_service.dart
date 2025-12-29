import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  String _getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<String> getOrCreateChatId(String userId1, String userId2) async {
    String chatId = _getChatId(userId1, userId2);

    DocumentSnapshot chatDoc =
        await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      ChatModel chat = ChatModel(
        chatId: chatId,
        userId1: userId1,
        userId2: userId2,
      );
      await _firestore.collection('chats').doc(chatId).set(chat.toMap());
    }

    return chatId;
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    String? text,
    String? imageUrl,
    String? voiceUrl,
  }) async {
    try {
      String chatId = await getOrCreateChatId(senderId, receiverId);
      String messageId = _uuid.v4();

      MessageModel message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
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
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text ?? (imageUrl != null ? 'Image' : 'Voice message'),
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessageSenderId': senderId,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<MessageModel>> getMessages(String userId1, String userId2) {
    String chatId = _getChatId(userId1, userId2);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> markMessageAsRead(
      String userId1, String userId2, String messageId) async {
    String chatId = _getChatId(userId1, userId2);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('userId1', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data()))
            .toList())
        .asyncMap((chats) async {
      List<ChatModel> allChats = List.from(chats);
      QuerySnapshot otherChats = await _firestore
          .collection('chats')
          .where('userId2', isEqualTo: userId)
          .get();
      allChats.addAll(
          otherChats.docs.map((doc) => ChatModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
      allChats.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      return allChats;
    });
  }
}

