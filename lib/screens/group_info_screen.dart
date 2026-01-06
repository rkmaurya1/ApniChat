import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/group_chat_service.dart';
import '../services/realtime_storage_service.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/realtime_db_image.dart';
import '../utils/app_theme.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final _groupChatService = GroupChatService();
  final _realtimeStorageService = RealtimeStorageService();
  final _groupNameController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isEditingName = false;
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _updateGroupName(String currentName) async {
    if (_groupNameController.text.trim().isEmpty ||
        _groupNameController.text.trim() == currentName) {
      setState(() => _isEditingName = false);
      return;
    }

    try {
      await _groupChatService.updateGroupInfo(
        groupId: widget.groupId,
        groupName: _groupNameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group name updated'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _groupChatService.leaveGroup(
          groupId: widget.groupId,
          userId: widget.currentUserId,
        );

        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to leave group: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(
      String memberId, String memberName, bool isAdmin) async {
    if (isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove admin. Remove admin privileges first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $memberName from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _groupChatService.removeMemberFromGroup(
          groupId: widget.groupId,
          memberId: memberId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAdmin(
      String memberId, String memberName, bool isCurrentlyAdmin) async {
    try {
      if (isCurrentlyAdmin) {
        await _groupChatService.removeAdmin(
          groupId: widget.groupId,
          memberId: memberId,
        );
      } else {
        await _groupChatService.makeAdmin(
          groupId: widget.groupId,
          memberId: memberId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isCurrentlyAdmin ? 'Admin removed' : 'Admin privileges granted'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateGroupPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      // Upload to Realtime Database
      String photoId = await _realtimeStorageService.uploadImageToRealtimeDB(
        File(image.path),
        widget.currentUserId,
      );

      String photoUrl = 'rtdb://${widget.currentUserId}/$photoId';

      // Update group info
      await _groupChatService.updateGroupInfo(
        groupId: widget.groupId,
        groupPhotoUrl: photoUrl,
      );

      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group photo updated'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Group Info'),
          ],
        ),
      ),
      body: FutureBuilder<GroupModel?>(
        future: _groupChatService.getGroupDetails(widget.groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load group info'));
          }

          final group = snapshot.data!;
          final isAdmin = group.adminIds.contains(widget.currentUserId);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Group Photo with Edit Button
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isUploadingPhoto
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : group.groupPhotoUrl != null
                              ? ClipOval(
                                  child: RealtimeDBImage(
                                    imageRef: group.groupPhotoUrl!,
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 48,
                                ),
                    ),
                    if (isAdmin && !_isUploadingPhoto)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _updateGroupPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isEditingName)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _groupNameController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Group name',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) =>
                                _updateGroupName(group.groupName),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Color(0xFF10B981)),
                          onPressed: () => _updateGroupName(group.groupName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _isEditingName = false),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        group.groupName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                          onPressed: () {
                            _groupNameController.text = group.groupName;
                            setState(() => _isEditingName = true);
                          },
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  '${group.memberIds.length} members',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...group.memberIds.map((memberId) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(memberId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const SizedBox();
                            }

                            final userData =
                                userSnapshot.data!.data() as Map<String, dynamic>?;
                            if (userData == null) return const SizedBox();

                            final user = UserModel.fromMap(userData);
                            final isMemberAdmin =
                                group.adminIds.contains(memberId);
                            final isCurrentUser =
                                memberId == widget.currentUserId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      ProfileAvatar(
                                        photoUrl: user.photoUrl,
                                        userName: user.name,
                                        radius: 24,
                                      ),
                                      if (user.isOnline)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              user.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            if (isCurrentUser) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6366F1)
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'You',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6366F1),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (isMemberAdmin) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFF6366F1),
                                                      Color(0xFF8B5CF6)
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Admin',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isAdmin && !isCurrentUser)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        if (value == 'remove') {
                                          _removeMember(
                                              memberId, user.name, isMemberAdmin);
                                        } else if (value == 'toggle_admin') {
                                          _toggleAdmin(
                                              memberId, user.name, isMemberAdmin);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'toggle_admin',
                                          child: Row(
                                            children: [
                                              Icon(
                                                isMemberAdmin
                                                    ? Icons.remove_moderator
                                                    : Icons.admin_panel_settings,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(isMemberAdmin
                                                  ? 'Remove Admin'
                                                  : 'Make Admin'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_remove, size: 20),
                                              SizedBox(width: 12),
                                              Text('Remove from group'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _leaveGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text(
                        'Leave Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
