import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/realtime_storage_service.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String userName;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.userName,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      // No photo - show initials
      debugPrint('ProfileAvatar: No photoUrl for $userName');
      return CircleAvatar(
        radius: radius,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Check if this is a Realtime DB reference
    if (photoUrl!.startsWith('rtdb://profile/')) {
      final userId = photoUrl!.substring(15); // Remove 'rtdb://profile/'
      debugPrint('ProfileAvatar: Loading photo for userId: $userId from RTDB');

      // Use StreamBuilder for real-time updates! 🔥
      return StreamBuilder<String?>(
        stream: RealtimeStorageService().watchProfilePhoto(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('ProfileAvatar: Waiting for photo data for $userId');
            return CircleAvatar(
              radius: radius,
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            debugPrint('ProfileAvatar: Error loading photo for $userId: ${snapshot.error}');
            return CircleAvatar(
              radius: radius,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            debugPrint('ProfileAvatar: No photo data found for $userId in RTDB');
            // Fallback to initials
            return CircleAvatar(
              radius: radius,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          try {
            debugPrint('ProfileAvatar: Successfully loaded photo for $userId');
            final bytes = base64Decode(snapshot.data!);
            return CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(bytes),
            );
          } catch (e) {
            debugPrint('ProfileAvatar: Error decoding photo for $userId: $e');
            // Error decoding - show initials
            return CircleAvatar(
              radius: radius,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        },
      );
    }

    // Regular network image URL
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(photoUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        // Error loading network image - will show initials as child
      },
      child: FutureBuilder(
        future: precacheImage(NetworkImage(photoUrl!), context),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
