
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
      (doc) =>
          doc.data()['status'] == 'pending' &&
          doc.data()['senderId'] == currentUid,
    )) {
      return 'sent';
    }

    if (relatedRequests.any(
      (doc) =>
          doc.data()['status'] == 'pending' &&
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

  // Supports ISO country codes such as BD, US, IN, GB.
  String _countryFlag(Map<String, dynamic> data) {
    String code = (data['countryCode'] ??
            data['country_code'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();

    if (code.isEmpty) {
      final country = (data['country'] ??
              data['countryName'] ??
              '')
          .toString()
          .trim()
          .toLowerCase();

      const countryCodes = {
        'bangladesh': 'BD',
        'india': 'IN',
        'pakistan': 'PK',
        'united states': 'US',
        'usa': 'US',
        'united kingdom': 'GB',
        'uk': 'GB',
        'uae': 'AE',
        'united arab emirates': 'AE',
        'saudi arabia': 'SA',
        'canada': 'CA',
        'australia': 'AU',
        'japan': 'JP',
        'china': 'CN',
        'nepal': 'NP',
        'sri lanka': 'LK',
        'malaysia': 'MY',
        'singapore': 'SG',
        'indonesia': 'ID',
        'turkey': 'TR',
        'germany': 'DE',
        'france': 'FR',
      };

      code = countryCodes[country] ?? '';
    }

    if (code.length != 2 ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(code)) {
      return '';
    }

    return String.fromCharCodes(
      code.codeUnits.map((unit) => unit + 127397),
    );
  }

  Widget _buildAvatar(
    Map<String, dynamic> data,
    String name,
  ) {
    final photoUrl = (data['photoUrl'] ?? '').toString().trim();

    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 29,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: photoUrl.startsWith('http')
          ? NetworkImage(photoUrl)
          : null,
      child: photoUrl.startsWith('http')
          ? null
          : Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildSkillTags(
    List<String> skills, {
    int limit = 3,
  }) {
    if (skills.isEmpty) {
      return const Text(
        'Not added yet',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    final visibleSkills = skills.take(limit).toList();

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        ...visibleSkills.map(
          (skill) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              skill,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (skills.length > limit)
          Text(
            '+${skills.length - limit}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildRating(Map<String, dynamic> data) {
    final rating = data['rating'];
    final reviewCount = data['reviewCount'];

    if (rating is! num) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.orange, size: 16),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reviewCount is num) ...[
          const SizedBox(width: 3),
          Text(
            '(${reviewCount.toInt()})',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectionButton(
    String currentUid,
    String userId,
    String name,
  ) {
    return FutureBuilder<String>(
      future: _getRelationshipStatus(currentUid, userId),
      builder: (context, statusSnapshot) {
        final status = statusSnapshot.data ?? 'loading';

        String buttonText;
        IconData buttonIcon;

        switch (status) {
          case 'connected':
            buttonText = 'Connected';
            buttonIcon = Icons.check_circle;
            break;
          case 'sent':
            buttonText = 'Request Sent';
            buttonIcon = Icons.hourglass_top;
            break;
          case 'received':
            buttonText = 'Request Received';
            buttonIcon = Icons.mark_email_unread;
            break;
          case 'loading':
            buttonText = 'Checking...';
            buttonIcon = Icons.sync;
            break;
          default:
            buttonText = 'Connect';
            buttonIcon = Icons.person_add_alt_1;
        }

        final isConnected = status == 'connected';
        final isSent = status == 'sent';
        final isReceived = status == 'received';

        return SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected
                  ? Colors.green.shade50
                  : isSent
                      ? Colors.grey.shade200
                      : Theme.of(context).colorScheme.primary,
              foregroundColor: isConnected
                  ? Colors.green.shade800
                  : isSent
                      ? Colors.black54
                      : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: status == 'none' && !_sendingRequest
                ? () => _sendConnectionRequest(userId, name)
                : null,
            icon: Icon(buttonIcon, size: 15),
            label: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    String currentUid,
    QueryDocumentSnapshot<Map<String, dynamic>> userDoc,
  ) {
    final data = userDoc.data();

    final name = (data['name'] ?? 'SkillSwap User').toString();

    final offered =
        List<String>.from(data['skillsOffered'] ?? []);

    final wanted =
        List<String>.from(data['skillsWanted'] ?? []);

    final flag = _countryFlag(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(data, name),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (flag.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Text(
                          flag,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Teaches',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildSkillTags(offered, limit: 2),
                  const SizedBox(height: 5),
                  const Text(
                    'Learns',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildSkillTags(wanted, limit: 2),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildRating(data),
                      const Spacer(),
                      _buildConnectionButton(
                        currentUid,
                        userDoc.id,
                        name,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to explore skills.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Skills',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search skills...',
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(
            height: 43,
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
            padding: const EdgeInsets.fromLTRB(16, 7, 12, 5),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'People to learn with',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedSort,
                  underline: const SizedBox(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Recommended',
                      child: Text(
                        'Recommended',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Recently Joined',
                      child: Text(
                        'Recently Joined',
                        style: TextStyle(fontSize: 12),
                      ),
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
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
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
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(
                      context,
                      currentUser.uid,
                      users[index],
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
