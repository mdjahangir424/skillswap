
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryBlue = const Color(0xFF075CF5);

  User? get currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid);
  }

  // Edit Profile
  Future<void> _editProfile() async {
    if (currentUser == null) return;

    try {
      final snapshot = await _userDocument.get();
      final data = snapshot.data() ?? {};

      final name = (data['name'] as String?) ??
          currentUser!.displayName ??
          '';

      final bio = (data['bio'] as String?) ?? '';

      if (!mounted) return;

      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => _EditProfileDialog(
          initialName: name,
          initialBio: bio,
        ),
      );

      if (!mounted || result == null) return;

      final newName = result['name']!.trim();
      final newBio = result['bio']!.trim();

      if (newName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name cannot be empty.')),
        );
        return;
      }

      await _userDocument.set({
        'name': newName,
        'bio': newBio,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await currentUser!.updateDisplayName(newName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase error: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $e')),
      );
    }
  }

  // Add Skills and Learning Goals
  Future<void> showEditDialog(
    String title,
    List<String> items,
    String fieldName,
  ) async {
    if (currentUser == null) return;

    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => _AddSkillDialog(
        title: title,
        items: items,
      ),
    );

    if (!mounted || newValue == null || newValue.trim().isEmpty) {
      return;
    }

    try {
      await _userDocument.set({
        fieldName: FieldValue.arrayUnion([newValue.trim()]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully added!')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase error: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  // Delete Skill
  Future<void> _deleteSkill(String item, bool isLearning) async {
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Skill?'),
        content: Text('Do you want to delete "$item"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final fieldName =
          isLearning ? 'skillsWanted' : 'skillsOffered';

      await _userDocument.update({
        fieldName: FieldValue.arrayRemove([item]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skill deleted successfully!'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase error: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete skill: $e')),
      );
    }
  }

  // Settings
  void showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Account Settings'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _editProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Notifications'),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Privacy & Security'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to view your profile.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocument.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Unable to load profile. Please try again.'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FD),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF075CF5),
              ),
            ),
          );
        }

        final data = snapshot.data?.data() ?? {};

        final String name =
            (data['name'] as String?) ??
            currentUser!.displayName ??
            'SkillSwap User';

        final String email =
            (data['email'] as String?) ??
            currentUser!.email ??
            '';

        final String bio =
            (data['bio'] as String?) ??
            'Passionate about learning\nand sharing skills with the world.';

        final String photoUrl =
            (data['photoUrl'] as String?) ?? '';

        final List<String> skills =
            _getStringList(data['skillsOffered']);

        final List<String> learningGoals =
            _getStringList(data['skillsWanted']);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          onPressed: showSettings,
                          icon: Icon(
                            Icons.settings_outlined,
                            color: primaryBlue,
                            size: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(21, 8, 21, 20),
                    child: Column(
                      children: [
                        // Profile Photo
                        Stack(
                          children: [
                            Container(
                              width: 116,
                              height: 116,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF9FC4D2),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _defaultAvatar();
                                        },
                                      )
                                    : _defaultAvatar(),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 4,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile photo upload will be connected later.',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0BAA65),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🇧🇩', style: TextStyle(fontSize: 15)),
                            SizedBox(width: 6),
                            Text(
                              'Bangladesh',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF24334F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF24334F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                icon: Icons.star,
                                iconColor: const Color(0xFFFFB323),
                                value: '4.8',
                                label: 'Rating',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                icon: Icons.groups,
                                iconColor: const Color(0xFF2589F8),
                                value: '245',
                                label: 'Connections',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionHeader(
                          'My Skills',
                          onEdit: () => showEditDialog(
                            'Skills',
                            skills,
                            'skillsOffered',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildChips(skills, false),
                        const SizedBox(height: 18),
                        _sectionHeader(
                          'My Learning Goals',
                          onEdit: () => showEditDialog(
                            'Learning Goals',
                            learningGoals,
                            'skillsWanted',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildChips(learningGoals, true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFFDDE8F0),
      child: const Icon(
        Icons.person,
        size: 70,
        color: Color(0xFF8092A8),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      height: 89,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF101828),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF26354F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    required VoidCallback onEdit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF171D2B),
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Text(
            'Edit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  // Long press any skill to delete
  Widget _buildChips(List<String> items, bool isLearning) {
    if (items.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No skills added yet. Tap Edit to add.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF667085),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: items.map((item) {
          return GestureDetector(
            onLongPress: () => _deleteSkill(item, isLearning),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: isLearning
                    ? const Color(0xFFE9E5FF)
                    : const Color(0xFFE1EAFE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLearning
                      ? const Color(0xFF3D348B)
                      : const Color(0xFF0752D8),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Add Skills Dialog
class _AddSkillDialog extends StatefulWidget {
  final String title;
  final List<String> items;

  const _AddSkillDialog({
    required this.title,
    required this.items,
  });

  @override
  State<_AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<_AddSkillDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.items.isEmpty
                ? 'No items added yet.'
                : widget.items.join(', '),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter a new item',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.of(context).pop(value);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Edit Profile Dialog
class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialBio;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialBio,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text,
              'bio': _bioController.text,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
