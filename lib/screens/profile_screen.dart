import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'notifications_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryBlue = const Color(0xFF075CF5);
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingPhoto = false;
  final Set<String> _skillOperations = <String>{};

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

      await currentUser!.updatePhotoURL(downloadUrl);

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

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );
  }

  String _normalizeSkill(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _skillOperationKey(String fieldName, String skill) {
    return '$fieldName::${skill.toLowerCase()}';
  }

  Future<void> showEditDialog(
    String title,
    List<String> items,
    String fieldName,
  ) async {
    if (currentUser == null) return;

    final newValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _AddSkillDialog(
        title: title,
        items: items,
      ),
    );

    if (!mounted || newValue == null) return;

    final normalizedValue = _normalizeSkill(newValue);
    if (normalizedValue.length < 2 || normalizedValue.length > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skill name must be 2–40 characters.'),
        ),
      );
      return;
    }

    final duplicate = items.any(
      (item) => _normalizeSkill(item).toLowerCase() ==
          normalizedValue.toLowerCase(),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This skill is already in your list.'),
        ),
      );
      return;
    }

    final operationKey = _skillOperationKey(fieldName, normalizedValue);
    if (_skillOperations.contains(operationKey)) return;

    setState(() => _skillOperations.add(operationKey));

    try {
      await _userDocument.set({
        fieldName: FieldValue.arrayUnion([normalizedValue]),
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
    } finally {
      if (mounted) setState(() => _skillOperations.remove(operationKey));
    }
  }

  Future<void> _deleteSkill(String item, bool isLearning) async {
    if (currentUser == null) return;

    final fieldName = isLearning ? 'skillsWanted' : 'skillsOffered';
    final operationKey = _skillOperationKey(fieldName, item);
    if (_skillOperations.contains(operationKey)) return;

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

    setState(() => _skillOperations.add(operationKey));
    try {
      await _userDocument.set({
        fieldName: FieldValue.arrayRemove([item]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill deleted successfully!')),
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
    } finally {
      if (mounted) setState(() => _skillOperations.remove(operationKey));
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

    await FirebaseAuth.instance.signOut();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _settingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                _settingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _editProfile();
                  },
                ),
                _settingsTile(
                  icon: Icons.lock_outline,
                  title: 'Privacy & Security',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Privacy & Security will be available soon.',
                        ),
                      ),
                    );
                  },
                ),
                _settingsTile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _logout();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? primaryBlue),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your profile.'),
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

        final data = snapshot.data?.data() ?? <String, dynamic>{};

        final String name =
            (data['name'] as String?) ??
            currentUser!.displayName ??
            'User';

        final String email = currentUser!.email ?? '';

        final String bio = (data['bio'] as String?) ?? '';

        final String photoUrl =
            (data['photoUrl'] as String?) ??
            currentUser!.photoURL ??
            '';

        final String location = (data['location'] as String?) ?? '';

        final String country = (data['country'] as String?) ?? '';

        final String countryCode =
            (data['countryCode'] as String?) ?? '';

        final List<String> skillsOffered =
            List<String>.from(data['skillsOffered'] ?? const []);

        final List<String> skillsWanted =
            List<String>.from(data['skillsWanted'] ?? const []);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  pinned: true,
                  title: const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.black87,
                      ),
                      onPressed: _showSettings,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
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
                          country: country,
                          countryCode: countryCode,
                        ),
                        const SizedBox(height: 22),
                        _buildProfileInformation(
                          name: name,
                          email: email,
                          location: location,
                          country: country,
                        ),
                        const SizedBox(height: 22),
                        _buildSkillsSection(
                          title: 'Skills I Can Teach',
                          skills: skillsOffered,
                          fieldName: 'skillsOffered',
                          isLearning: false,
                          onAdd: () => showEditDialog(
                            'Add a Skill You Can Teach',
                            skillsOffered,
                            'skillsOffered',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildSkillsSection(
                          title: 'Skills I Want to Learn',
                          skills: skillsWanted,
                          fieldName: 'skillsWanted',
                          isLearning: true,
                          onAdd: () => showEditDialog(
                            'Add a Skill You Want to Learn',
                            skillsWanted,
                            'skillsWanted',
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildAccountInformation(
                          email: email,
                          uid: currentUser!.uid,
                        ),
                        const SizedBox(height: 30),
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

  Widget _buildProfileHeader({
    required String name,
    required String email,
    required String bio,
    required String photoUrl,
    required String location,
    required String country,
    required String countryCode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFE8EEFF),
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFF075CF5),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: primaryBlue,
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
                            color: Colors.white,
                            size: 17,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          if (location.isNotEmpty || country.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    [
                      location,
                      if (country.isNotEmpty)
                        '${_countryFlag(countryCode)} $country',
                    ].where((e) => e.trim().isNotEmpty).join(', '),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue),
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

  Widget _buildProfileInformation({
    required String name,
    required String email,
    required String location,
    required String country,
  }) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _informationRow(
            Icons.person_outline,
            'Full Name',
            name,
          ),
          _informationRow(
            Icons.email_outlined,
            'Email',
            email,
          ),
          _informationRow(
            Icons.location_on_outlined,
            'Location',
            location.isEmpty ? 'Not added' : location,
          ),
          _informationRow(
            Icons.flag_outlined,
            'Country',
            country.isEmpty ? 'Not added' : country,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInformation({
    required String email,
    required String uid,
  }) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _informationRow(
            Icons.email_outlined,
            'Email Address',
            email,
          ),
          _informationRow(
            Icons.verified_user_outlined,
            'Account Status',
            currentUser?.emailVerified == true
                ? 'Verified'
                : 'Not verified',
          ),
          _informationRow(
            Icons.fingerprint,
            'User ID',
            uid,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection({
    required String title,
    required List<String> skills,
    required String fieldName,
    required bool isLearning,
    required VoidCallback onAdd,
  }) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
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
          ),
          const SizedBox(height: 10),
          if (skills.isEmpty)
            Text(
              'No skills added yet.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                final operationKey =
                    _skillOperationKey(fieldName, skill);
                final isBusy =
                    _skillOperations.contains(operationKey);

                return Container(
                  padding: const EdgeInsets.only(
                    left: 13,
                    right: 5,
                    top: 5,
                    bottom: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        skill,
                        style: const TextStyle(
                          color: Color(0xFF075CF5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: isBusy
                            ? null
                            : () => _deleteSkill(skill, isLearning),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: isBusy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFF075CF5),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _informationRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: primaryBlue,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  String? _errorText;

  String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _submit() {
    final value = _normalize(_controller.text);

    if (value.length < 2 || value.length > 40) {
      setState(() {
        _errorText = 'Enter a skill between 2 and 40 characters.';
      });
      return;
    }

    final duplicate = widget.items.any(
      (item) =>
          _normalize(item).toLowerCase() == value.toLowerCase(),
    );

    if (duplicate) {
      setState(() {
        _errorText = 'This skill is already in your list.';
      });
      return;
    }

    Navigator.pop(context, value);
  }

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
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Enter skill name',
          errorText: _errorText,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() {
              _errorText = null;
            });
          }
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String name;
  final String bio;

  const _EditProfileDialog({
    required this.name,
    required this.bio,
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
    _nameController = TextEditingController(text: widget.name);
    _bioController = TextEditingController(text: widget.bio);
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
            const SizedBox(height: 14),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
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
              'name': _nameController.text.trim(),
              'bio': _bioController.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}