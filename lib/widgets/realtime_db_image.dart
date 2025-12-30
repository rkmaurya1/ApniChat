import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/realtime_storage_service.dart';

class RealtimeDBImage extends StatelessWidget {
  final String imageRef;
  final double? width;
  final double? height;
  final BoxFit fit;

  const RealtimeDBImage({
    super.key,
    required this.imageRef,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this is a Realtime DB reference
    if (!imageRef.startsWith('rtdb://')) {
      // Fallback to network image for old Storage URLs
      return Image.network(
        imageRef,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width ?? 200,
            height: height ?? 200,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 48),
          );
        },
      );
    }

    // Parse Realtime DB reference: rtdb://userId/imageId
    final uri = imageRef.substring(7); // Remove 'rtdb://'
    final parts = uri.split('/');
    if (parts.length != 2) {
      return Container(
        width: width ?? 200,
        height: height ?? 200,
        color: Colors.grey[300],
        child: const Icon(Icons.error, size: 48),
      );
    }

    final userId = parts[0];
    final imageId = parts[1];

    return FutureBuilder<String?>(
      future: RealtimeStorageService().getImageBase64(userId, imageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width ?? 200,
            height: height ?? 200,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            width: width ?? 200,
            height: height ?? 200,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 48),
          );
        }

        try {
          final bytes = base64Decode(snapshot.data!);
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
          );
        } catch (e) {
          return Container(
            width: width ?? 200,
            height: height ?? 200,
            color: Colors.grey[300],
            child: const Icon(Icons.error, size: 48),
          );
        }
      },
    );
  }
}
