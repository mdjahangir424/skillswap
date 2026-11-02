
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedSort = 'Recommended';
  bool _sendingRequest = false;

  final List<String> _categories = [
    'All',
    'Design',
    'Technology',
    'Language',
    'Business',
    'Music',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryForUser(Map<String, dynamic> data) {
    final skills = [
      ...(data['skillsOffered'] as List? ?? []),
      ...(data['skillsWanted'] as List? ?? []),
    ];

    final text = skills.join(' ').toLowerCase();

    if (text.contains('design') ||
        text.contains('figma') ||
        text.contains('photoshop') ||
        text.contains('illustrator') ||
        text.contains('graphic') ||
        text.contains('ui') ||
        text.contains('ux')) {
      return 'Design';
    }

    if (text.contains('flutter') ||
        text.contains('programming') ||
        text.contains('developer') ||
        text.contains('coding') ||
        text.contains('web') ||
        text.contains('html') ||
        text.contains('software') ||
        text.contains('technology')) {
      return 'Technology';
    }

    if (text.contains('english') ||
        text.contains('language') ||
        text.contains('teaching') ||
        text.contains('translation') ||
        text.contains('arabic') ||
        text.contains('bangla')) {
      return 'Language';
    }

    if (text.contains('business') ||
        text.contains('marketing') ||
        text.contains('finance') ||
        text.contains('management') ||
        text.contains('sales')) {
      return 'Business';
    }

    if (text.contains('music') ||
        text.contains('guitar') ||
        text.contains('singing') ||
        text.contains('piano')) {
      return 'Music';
    }

    return 'All';
  }

  Future<String> _getRelationshipStatus(
    String currentUid,
    String otherUid,
  ) async {
    final requests =
        FirebaseFirestore.instance.collection('connectionRequests');

    final outgoing = await requests
        .where('senderId', isEqualTo: currentUid)
        .get();

    final incoming = await requests
        .where('receiverId', isEqualTo: currentUid)
        .get();

    final relatedRequests = [
      ...outgoing.docs.where(
        (doc) => doc.data()['receiverId'] == otherUid,
      ),
      ...incoming.docs.where(
        (doc) => doc.data()['senderId'] == otherUid,
      ),
    ];

    if (relatedRequests.any(
      (doc) => doc.data()['status'] == 'accepted',
    )) {
      return 'connected';
    }

    if (relatedRequests.any(
      (doc) => doc.data()['status'] == 'pending' &&
          doc.data()['senderId'] == currentUid,
    )) {
      return 'sent';
    }

    if (relatedRequests.any(
      (doc) => doc.data()['status'] == 'pending' &&
          doc.data()['senderId'] == otherUid,
    )) {
      return 'received';
    }

    return 'none';
  }

  Future<void> _sendConnectionRequest(
    String receiverId,
    String receiverName,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || _sendingRequest) return;

    setState(() => _sendingRequest = true);

    try {
      final status = await _getRelationshipStatus(
        currentUser.uid,
        receiverId,
      );

      if (status != 'none') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'connected'
                    ? 'You are already connected.'
                    : status == 'sent'
                        ? 'Request already sent.'
                        : 'This user has already sent you a request.',
              ),
            ),
          );
        }
        return;
      }

      final requestRef = FirebaseFirestore.instance
          .collection('connectionRequests')
          .doc();

      await requestRef.set({
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to $receiverName.'),
          ),
        );

        setState(() {});
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingRequest = false);
      }
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return true;

    final name = (data['name'] ?? '').toString().toLowerCase();
    final offered = (data['skillsOffered'] as List? ?? [])
        .join(' ')
        .toLowerCase();
    final wanted = (data['skillsWanted'] as List? ?? [])
        .join(' ')
        .toLowerCase();

    return name.contains(query) ||
        offered.contains(query) ||
        wanted.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to explore skills.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Skills',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search people or skills...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'People to learn with',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedSort,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Recommended',
                      child: Text('Recommended'),
                    ),
                    DropdownMenuItem(
                      value: 'Recently Joined',
                      child: Text('Recently Joined'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSort = value);
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final users = snapshot.data!.docs.where((doc) {
                  if (doc.id == currentUser.uid) return false;

                  final data = doc.data();

                  if (!_matchesSearch(data)) return false;

                  if (_selectedCategory != 'All' &&
                      _categoryForUser(data) != _selectedCategory) {
                    return false;
                  }

                  return true;
                }).toList();

                if (_selectedSort == 'Recently Joined') {
                  users.sort((a, b) {
                    final aTime = a.data()['createdAt'];
                    final bTime = b.data()['createdAt'];

                    final aDate = aTime is Timestamp
                        ? aTime.toDate()
                        : DateTime(2000);
                    final bDate = bTime is Timestamp
                        ? bTime.toDate()
                        : DateTime(2000);

                    return bDate.compareTo(aDate);
                  });
                }

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No users found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final data = userDoc.data();

                    final name =
                        (data['name'] ?? 'SkillSwap User').toString();

                    final offered =
                        List<String>.from(data['skillsOffered'] ?? []);

                    final wanted =
                        List<String>.from(data['skillsWanted'] ?? []);

                    final initial =
                        name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (offered.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const Text(
                                'Skills Offered',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: offered.map((skill) {
                                  return Chip(
                                    label: Text(skill),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],

                            if (wanted.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Skills Wanted',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: wanted.map((skill) {
                                  return Chip(
                                    label: Text(skill),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: FutureBuilder<String>(
                                future: _getRelationshipStatus(
                                  currentUser.uid,
                                  userDoc.id,
                                ),
                                builder: (context, statusSnapshot) {
                                  final status =
                                      statusSnapshot.data ?? 'loading';

                                  String buttonText;
                                  switch (status) {
                                    case 'connected':
                                      buttonText = 'Connected';
                                      break;
                                    case 'sent':
                                      buttonText = 'Request Sent';
                                      break;
                                    case 'received':
                                      buttonText = 'Request Received';
                                      break;
                                    case 'loading':
                                      buttonText = 'Checking...';
                                      break;
                                    default:
                                      buttonText = 'Send Request';
                                  }

                                  final enabled = status == 'none' &&
                                      !_sendingRequest;

                                  return ElevatedButton.icon(
                                    onPressed: enabled
                                        ? () => _sendConnectionRequest(
                                              userDoc.id,
                                              name,
                                            )
                                        : null,
                                    icon: Icon(
                                      status == 'connected'
                                          ? Icons.check_circle
                                          : status == 'sent'
                                              ? Icons.hourglass_top
                                              : status == 'received'
                                                  ? Icons.mark_email_unread
                                                  : Icons.person_add_alt_1,
                                    ),
                                    label: Text(buttonText),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
