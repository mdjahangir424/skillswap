import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryBlue = const Color(0xFF075CF5);
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingPhoto = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid);
  }

  String _countryFlag(String countryCode) {
    final code = countryCode.trim().toUpperCase();

    if (code.length != 2 ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(code)) {
      return '';
    }

    return String.fromCharCodes(
      code.codeUnits.map((value) => value + 127397),
    );
  }

  Future<void> _uploadProfilePhoto() async {
    if (currentUser == null || _isUploadingPhoto) return;

    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (selectedImage == null) return;
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      final Uint8List imageBytes = await selectedImage.readAsBytes();

      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(currentUser!.uid)
          .child(fileName);

      await storageReference.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final String downloadUrl =
          await storageReference.getDownloadURL();

      await _userDocument.set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.message ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not upload photo: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

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
          const SnackBar(
            content: Text('Name cannot be empty.'),
          ),
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
        SnackBar(
          content: Text('Firebase error: ${e.message ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile: $e'),
        ),
      );
    }
  }

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
        const SnackBar(
          content: Text('Successfully added!'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.message ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

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

      await _userDocument.set({
        fieldName: FieldValue.arrayRemove([item]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skill deleted successfully!'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.message ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete skill: $e'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'Are you sure you want to log out of SkillSwap?',
        ),
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
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not log out: $e'),
        ),
      );
    }
  }

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
                onTap: () {
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Privacy & Security'),
                onTap: () {
                  Navigator.pop(sheetContext);
                },
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your profile.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocument.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data?.data() ?? {};

        final String name = (data['name'] as String?) ??
            currentUser!.displayName ??
            'User';

        final String email = currentUser!.email ?? '';

        final String bio = (data['bio'] as String?) ?? '';

        final String photoUrl = (data['photoUrl'] as String?) ??
            currentUser!.photoURL ??
            '';

        final String location = (data['location'] as String?) ?? '';

        final String countryCode =
            (data['countryCode'] as String?) ?? '';

        final List<String> skillsOffered =
            List<String>.from(data['skillsOffered'] ?? []);

        final List<String> skillsWanted =
            List<String>.from(data['skillsWanted'] ?? []);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'My Profile',
              style: TextStyle(
                color: Color(0xFF1D2433),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                onPressed: showSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF1D2433),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(
                  name: name,
                  email: email,
                  bio: bio,
                  photoUrl: photoUrl,
                  location: location,
                  countryCode: countryCode,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  'Skills I Can Teach',
                  onAdd: () => showEditDialog(
                    'Add a Skill',
                    skillsOffered,
                    'skillsOffered',
                  ),
                ),
                const SizedBox(height: 12),
                _buildSkillsList(
                  skillsOffered,
                  isLearning: false,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  'Skills I Want to Learn',
                  onAdd: () => showEditDialog(
                    'Add a Learning Goal',
                    skillsWanted,
                    'skillsWanted',
                  ),
                ),
                const SizedBox(height: 12),
                _buildSkillsList(
                  skillsWanted,
                  isLearning: true,
                ),
                const SizedBox(height: 24),
                _buildAccountInformation(
                  email: email,
                  location: location,
                  countryCode: countryCode,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required String email,
    required String bio,
    required String photoUrl,
    required String location,
    required String countryCode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: primaryBlue.withOpacity(0.1),
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 52,
                        color: Color(0xFF075CF5),
                      )
                    : null,
              ),
              InkWell(
                onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF075CF5),
                    shape: BoxShape.circle,
                  ),
                  child: _isUploadingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2433),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${_countryFlag(countryCode)} $location',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF626B7A),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: Color(0xFF075CF5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    required VoidCallback onAdd,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2433),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: TextButton.styleFrom(
            foregroundColor: primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsList(
    List<String> skills, {
    required bool isLearning,
  }) {
    if (skills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9ECF3)),
        ),
        child: Text(
          isLearning
              ? 'No learning goals added yet.'
              : 'No skills added yet.',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: isLearning
                ? const Color(0xFFFFF4E5)
                : const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                skill,
                style: TextStyle(
                  color: isLearning
                      ? const Color(0xFFB76E00)
                      : primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _deleteSkill(skill, isLearning),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isLearning
                      ? const Color(0xFFB76E00)
                      : primaryBlue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountInformation({
    required String email,
    required String location,
    required String countryCode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2433),
            ),
          ),
          const SizedBox(height: 18),
          _buildInformationRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: email.isEmpty ? 'Not available' : email,
          ),
          const Divider(height: 24),
          _buildInformationRow(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: location.isEmpty ? 'Not added' : location,
          ),
          const Divider(height: 24),
          _buildInformationRow(
            icon: Icons.flag_outlined,
            title: 'Country',
            value: countryCode.isEmpty
                ? 'Not added'
                : '${_countryFlag(countryCode)} $countryCode',
          ),
        ],
      ),
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2433),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialBio;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialBio,
  });

  @override
  State<_EditProfileDialog> createState() =>
      _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName,
    );
    _bioController = TextEditingController(
      text: widget.initialBio,
    );
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
              maxLines: 3,
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
            Navigator.pop(
              context,
              {
                'name': _nameController.text,
                'bio': _bioController.text,
              },
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

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
  final TextEditingController _controller =
      TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter skill name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.pop(context, value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.pop(context, value);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}