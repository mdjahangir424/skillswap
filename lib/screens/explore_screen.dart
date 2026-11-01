
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';
  String selectedSort = 'Recommended';

  bool connecting = false;

  final List<String> categories = [
    'All',
    'Design',
    'Technology',
    'Language',
    'Business',
    'Music',
  ];

  final List<Color> avatarColors = const [
    Color(0xFFEDE9FE),
    Color(0xFFDBEAFE),
    Color(0xFFFCE7F3),
    Color(0xFFD1FAE5),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();
    }
    return [];
  }

  String _categoryFor(String skill) {
    final value = skill.toLowerCase();

    if ([
      'design', 'figma', 'photoshop', 'illustrator',
      'ui', 'ux', 'graphic'
    ].any(value.contains)) {
      return 'Design';
    }

    if ([
      'flutter', 'programming', 'developer', 'coding',
      'web', 'html', 'software', 'technology'
    ].any(value.contains)) {
      return 'Technology';
    }

    if ([
      'english', 'language', 'teaching', 'translation',
      'arabic', 'bangla'
    ].any(value.contains)) {
      return 'Language';
    }

    if ([
      'business', 'marketing', 'finance', 'management',
      'sales'
    ].any(value.contains)) {
      return 'Business';
    }

    if ([
      'music', 'guitar', 'singing', 'piano'
    ].any(value.contains)) {
      return 'Music';
    }

    return 'Other';
  }

  bool _matchesCategory(
    List<String> offered,
    List<String> wanted,
  ) {
    if (selectedCategory == 'All') return true;

    final allSkills = [...offered, ...wanted];

    return allSkills.any(
      (skill) => _categoryFor(skill) == selectedCategory,
    );
  }

  bool _matchesSearch(
    String name,
    List<String> offered,
    List<String> wanted,
  ) {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return true;

    return name.toLowerCase().contains(query) ||
        offered.any((skill) => skill.toLowerCase().contains(query)) ||
        wanted.any((skill) => skill.toLowerCase().contains(query));
  }

  Future<void> _connectWithUser(
    String otherUserId,
    String otherUserName,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    if (currentUser.uid == otherUserId) return;

    if (connecting) return;

    setState(() {
      connecting = true;
    });

    try {
      final participants = [
        currentUser.uid,
        otherUserId,
      ]..sort();

      final conversationId = participants.join('_');

      final conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final conversationSnapshot =
            await transaction.get(conversationRef);

        if (!conversationSnapshot.exists) {
          transaction.set(conversationRef, {
            'participants': participants,
            'lastMessage': '',
            'lastMessageSenderId': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not connect: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          connecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Explore Skills',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search skills or people...',
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101828),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected =
                        selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1558E8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1558E8)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475467),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'People to Connect',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedSort,
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
                        setState(() {
                          selectedSort = value;
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (currentUser == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('Please login to explore people.'),
                  ),
                )
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(25),
                          child: Text(
                            'Unable to load users. Please try again.',
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(
                            color: Color(0xFF1558E8),
                          ),
                        ),
                      );
                    }

                    final users = snapshot.data?.docs ?? [];

                    final filteredUsers = users.where((doc) {
                      if (doc.id == currentUser.uid) return false;

                      final data = doc.data();
                      final name = data['name']?.toString() ?? 'User';

                      final offered =
                          _toStringList(data['skillsOffered']);
                      final wanted =
                          _toStringList(data['skillsWanted']);

                      return _matchesSearch(name, offered, wanted) &&
                          _matchesCategory(offered, wanted);
                    }).toList();

                    if (selectedSort == 'Recently Joined') {
                      filteredUsers.sort((a, b) {
                        final aTime =
                            a.data()['createdAt'] as Timestamp?;
                        final bTime =
                            b.data()['createdAt'] as Timestamp?;

                        return (bTime?.millisecondsSinceEpoch ?? 0)
                            .compareTo(
                          aTime?.millisecondsSinceEpoch ?? 0,
                        );
                      });
                    }

                    if (filteredUsers.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'No people found.',
                            style: TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: filteredUsers.map((doc) {
                        final data = doc.data();

                        final name =
                            data['name']?.toString() ?? 'User';

                        final offered =
                            _toStringList(data['skillsOffered']);
                        final wanted =
                            _toStringList(data['skillsWanted']);

                        final color = avatarColors[
                            doc.id.hashCode.abs() % avatarColors.length];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: const Color(0xFFEAECF0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: color,
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1558E8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF101828),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          offered.isNotEmpty
                                              ? offered.join(', ')
                                              : 'New SkillSwap member',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    color: Color(0xFF1558E8),
                                    size: 19,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              const Text(
                                'Wants to learn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF667085),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                wanted.isNotEmpty
                                    ? wanted.join(', ')
                                    : 'Not specified yet',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF344054),
                                ),
                              ),

                              const SizedBox(height: 15),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: connecting
                                      ? null
                                      : () => _connectWithUser(
                                            doc.id,
                                            name,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF1558E8),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFFB8C9EF),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: Text(
                                    connecting ? 'Connecting...' : 'Connect',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
