import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import 'chat_screen.dart';
import 'users_screen.dart';
import 'profile_screen.dart';
import '../utils/helpers.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final chatService = ChatService();
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No chats yet. Start a new conversation!'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              ChatModel chat = snapshot.data![index];
              String otherUserId = chat.userId1 == currentUserId
                  ? chat.userId2
                  : chat.userId1;

              return StreamBuilder<UserModel?>(
                stream: authService.getUserDataStream(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircularProgressIndicator(),
                    );
                  }

                  UserModel? otherUser = userSnapshot.data;
                  if (otherUser == null) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: otherUser.photoUrl != null
                          ? NetworkImage(otherUser.photoUrl!)
                          : null,
                      child: otherUser.photoUrl == null
                          ? Text(otherUser.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(otherUser.name),
                    subtitle: Text(
                      chat.lastMessage ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (chat.lastMessageTime != null)
                          Text(
                            Helpers.formatMessageTime(chat.lastMessageTime!),
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (otherUser.isOnline)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            currentUserId: currentUserId,
                            otherUser: otherUser,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UsersScreen()),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}

