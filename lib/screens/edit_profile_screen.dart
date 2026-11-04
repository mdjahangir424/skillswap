import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color primaryBlue = Color(0xFF075CF5);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  List<String> _skillsOffered = [];
  List<String> _skillsWanted = [];

  String _photoUrl = '';
  Uint8List? _newPhotoBytes;

  bool _loading = true;
  bool _saving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_user!.uid);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _user;

    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final snapshot = await _userDoc.get();
      final data = snapshot.data() ?? <String, dynamic>{};

      _nameController.text =
          (data['name'] as String?) ?? user.displayName ?? '';

      // Email is displayed only. It cannot be edited.
      _emailController.text = user.email ?? '';

      _countryController.text =
          (data['country'] as String?) ?? '';

      _locationController.text =
          (data['location'] as String?) ?? '';

      _bioController.text =
          (data['bio'] as String?) ?? '';

      _photoUrl =
          (data['photoUrl'] as String?) ?? user.photoURL ?? '';

      _skillsOffered =
          List<String>.from(data['skillsOffered'] ?? const []);

      _skillsWanted =
          List<String>.from(data['skillsWanted'] ?? const []);
    } catch (e) {
      _showMessage('Could not load profile: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _choosePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _newPhotoBytes = bytes;
      });
    } catch (e) {
      _showMessage('Could not select photo: $e');
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_newPhotoBytes == null || _user == null) {
      return _photoUrl;
    }

    final fileName =
        'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(_user!.uid)
        .child(fileName);

    await ref.putData(
      _newPhotoBytes!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (_user == null || _saving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final uploadedPhotoUrl = await _uploadPhoto();

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'country': _countryController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        'skillsOffered': _skillsOffered,
        'skillsWanted': _skillsWanted,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (uploadedPhotoUrl != null &&
          uploadedPhotoUrl.isNotEmpty) {
        updates['photoUrl'] = uploadedPhotoUrl;
      }

      await _userDoc.set(
        updates,
        SetOptions(merge: true),
      );

      await _user!.updateDisplayName(
        _nameController.text.trim(),
      );

      if (uploadedPhotoUrl != null &&
          uploadedPhotoUrl.isNotEmpty) {
        await _user!.updatePhotoURL(uploadedPhotoUrl);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _showMessage(
        'Firebase error: ${e.message ?? e.code}',
      );
    } catch (e) {
      _showMessage('Could not save profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _addSkill(bool teach) async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          teach
              ? 'Add a skill you can teach'
              : 'Add a skill to learn',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter skill name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (text) {
            Navigator.pop(dialogContext, text.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                controller.text.trim(),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null ||
        value.trim().isEmpty ||
        !mounted) {
      return;
    }

    setState(() {
      final list = teach ? _skillsOffered : _skillsWanted;

      if (!list.any(
        (item) =>
            item.toLowerCase() == value.toLowerCase(),
      )) {
        list.add(value.trim());
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _locationController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FC),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _user == null
              ? const Center(
                  child: Text(
                    'Please sign in to edit your profile.',
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  const Color(0xFFE8EEFF),
                              backgroundImage:
                                  (_newPhotoBytes != null
                                      ? MemoryImage(
                                          _newPhotoBytes!,
                                        )
                                      : (_photoUrl.isNotEmpty
                                          ? NetworkImage(
                                              _photoUrl,
                                            )
                                          : null))
                                  as ImageProvider?,
                              child:
                                  _newPhotoBytes == null &&
                                          _photoUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 48,
                                          color: primaryBlue,
                                        )
                                      : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: _choosePhoto,
                                borderRadius:
                                    BorderRadius.circular(24),
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primaryBlue,
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          'Change profile photo',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _sectionTitle('Profile Information'),

                      _field(
                        'Full Name',
                        _nameController,
                        icon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                      ),

                      _field(
                        'Email Address',
                        _emailController,
                        icon: Icons.email_outlined,
                        readOnly: true,
                        helper:
                            'Email address cannot be changed here.',
                      ),

                      _field(
                        'Country',
                        _countryController,
                        icon: Icons.flag_outlined,
                      ),

                      _field(
                        'Location',
                        _locationController,
                        icon: Icons.location_on_outlined,
                      ),

                      _field(
                        'Bio',
                        _bioController,
                        icon: Icons.notes_outlined,
                        maxLines: 4,
                        hint: 'Tell others a little about yourself',
                      ),

                      const SizedBox(height: 12),

                      _sectionTitle('Skills I Can Teach'),

                      _skillEditor(_skillsOffered, true),

                      const SizedBox(height: 16),

                      _sectionTitle('Skills I Want to Learn'),

                      _skillEditor(_skillsWanted, false),

                      const SizedBox(height: 28),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(
                                  context,
                                  false,
                                ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
        top: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF202B45),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    String? hint,
    String? helper,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          prefixIcon: Icon(
            icon,
            color: Colors.blueGrey,
          ),
          filled: true,
          fillColor: readOnly
              ? const Color(0xFFEDEFF4)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFE4E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: primaryBlue,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _skillEditor(
    List<String> skills,
    bool teach,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...skills.map(
            (skill) => Chip(
              label: Text(skill),
              deleteIcon: const Icon(
                Icons.close,
                size: 17,
              ),
              onDeleted: () {
                setState(() {
                  skills.remove(skill);
                });
              },
              backgroundColor:
                  const Color(0xFFEAF0FF),
              side: BorderSide.none,
            ),
          ),

          ActionChip(
            avatar: const Icon(
              Icons.add,
              size: 18,
              color: primaryBlue,
            ),
            label: const Text('Add skill'),
            onPressed: () => _addSkill(teach),
            backgroundColor: Colors.white,
            side: const BorderSide(
              color: primaryBlue,
            ),
          ),

          if (skills.isEmpty)
            const Text(
              'No skills added yet.',
              style: TextStyle(
                color: Colors.blueGrey,
              ),
            ),
        ],
      ),
    );
  }
}
