
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color primaryBlue = Color(0xFF075CF5);
  static const Color darkBlue = Color(0xFF073A91);
  static const Color pageBackground = Color(0xFFF8F9FD);
  static const Color tagBackground = Color(0xFFEEF3FF);

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedCategory = 'All';
  String _selectedSort = 'Recommended';
  bool _sendingRequest = false;

  final Map<String, Future<String>> _relationshipCache = {};

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

    final outgoingFuture = requests
        .where('senderId', isEqualTo: currentUid)
        .where('receiverId', isEqualTo: otherUid)
        .get();

    final incomingFuture = requests
        .where('senderId', isEqualTo: otherUid)
        .where('receiverId', isEqualTo: currentUid)
        .get();

    final results = await Future.wait([
      outgoingFuture,
      incomingFuture,
    ]);

    final outgoing = results[0].docs;
    final incoming = results[1].docs;
    final allRequests = [...outgoing, ...incoming];

    if (allRequests.any(
      (doc) => doc.data()['status'] == 'accepted',
    )) {
      return 'connected';
    }

    if (outgoing.any(
      (doc) => doc.data()['status'] == 'pending',
    )) {
      return 'sent';
    }

    if (incoming.any(
      (doc) => doc.data()['status'] == 'pending',
    )) {
      return 'received';
    }

    return 'none';
  }

  Future<String> _getCachedRelationshipStatus(
    String currentUid,
    String otherUid,
  ) {
    return _relationshipCache.putIfAbsent(
      otherUid,
      () => _getRelationshipStatus(currentUid, otherUid),
    );
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
        _relationshipCache[receiverId] = Future.value(status);

        if (mounted) {
          setState(() {});

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

      _relationshipCache[receiverId] = Future.value('sent');

      if (mounted) {
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection request sent to $receiverName.',
            ),
          ),
        );
      }
    } on FirebaseException catch (e) {
      _relationshipCache.remove(receiverId);

      if (mounted) {
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase error: ${e.message}'),
          ),
        );
      }
    } catch (e) {
      _relationshipCache.remove(receiverId);

      if (mounted) {
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send request: $e'),
          ),
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
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 25,
      backgroundColor: primaryBlue,
      backgroundImage: photoUrl.startsWith('http')
          ? NetworkImage(photoUrl)
          : null,
      child: photoUrl.startsWith('http')
          ? null
          : Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildSkillTags(
    List<String> skills, {
    int limit = 2,
  }) {
    if (skills.isEmpty) {
      return const Text(
        'Not added yet',
        style: TextStyle(fontSize: 11, color: Colors.grey),
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
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: tagBackground,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              skill,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (skills.length > limit)
          Text(
            '+${skills.length - limit}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
      ],
    );
  }

  Widget _buildRating(Map<String, dynamic> data) {
    final rating = data['rating'];
    final reviewCount = data['reviewCount'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          color: Colors.orange,
          size: 15,
        ),
        const SizedBox(width: 3),
        if (rating is num)
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          const Text(
            'New',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (reviewCount is num && reviewCount > 0) ...[
          const SizedBox(width: 3),
          Text(
            '(${reviewCount.toInt()})',
            style: const TextStyle(
              fontSize: 10,
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
      future: _getCachedRelationshipStatus(currentUid, userId),
      builder: (context, statusSnapshot) {
        final status = statusSnapshot.hasError
            ? 'error'
            : statusSnapshot.data ?? 'loading';

        String buttonText;
        IconData buttonIcon;

        switch (status) {
          case 'connected':
            buttonText = 'Connected';
            buttonIcon = Icons.check_circle_outline;
            break;
          case 'sent':
            buttonText = 'Request Sent';
            buttonIcon = Icons.hourglass_top;
            break;
          case 'received':
            buttonText = 'Request Received';
            buttonIcon = Icons.mark_email_unread_outlined;
            break;
          case 'loading':
            buttonText = 'Checking';
            buttonIcon = Icons.sync;
            break;
          case 'error':
            buttonText = 'Retry';
            buttonIcon = Icons.refresh;
            break;
          default:
            buttonText = 'Connect';
            buttonIcon = Icons.person_add_alt_1;
        }

        final isConnected = status == 'connected';
        final isSent = status == 'sent';

        return SizedBox(
          height: 32,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected
                  ? Colors.green.shade50
                  : isSent
                      ? Colors.grey.shade200
                      : primaryBlue,
              foregroundColor: isConnected
                  ? Colors.green.shade800
                  : isSent
                      ? Colors.black54
                      : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: status == 'none' && !_sendingRequest
                ? () => _sendConnectionRequest(userId, name)
                : status == 'error'
                    ? () {
                        setState(() {
                          _relationshipCache.remove(userId);
                        });
                      }
                    : null,
            icon: Icon(buttonIcon, size: 13),
            label: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 10,
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

    final offered = List<String>.from(data['skillsOffered'] ?? []);
    final wanted = List<String>.from(data['skillsWanted'] ?? []);
    final flag = _countryFlag(data);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(
          color: Color(0xFFE8ECF3),
          width: 0.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(data, name),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ),
                      if (flag.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          flag,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Teaches',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildSkillTags(offered),
                  const SizedBox(height: 4),
                  const Text(
                    'Learns',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildSkillTags(wanted),
                  const SizedBox(height: 7),
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

    final blueTheme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: primaryBlue,
        secondary: primaryBlue,
      ),
      scaffoldBackgroundColor: pageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF101828),
        elevation: 0,
      ),
      chipTheme: Theme.of(context).chipTheme.copyWith(
        selectedColor: primaryBlue.withOpacity(0.12),
        secondarySelectedColor: primaryBlue.withOpacity(0.12),
        checkmarkColor: primaryBlue,
        labelStyle: const TextStyle(fontSize: 12),
      ),
    );

    return Theme(
      data: blueTheme,
      child: Scaffold(
        backgroundColor: pageBackground,
        appBar: AppBar(
          title: const Text(
            'Explore Skills',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search skills...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: primaryBlue,
                  ),
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
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFDCE3F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFDCE3F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryBlue,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 39,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      showCheckmark: true,
                      checkmarkColor: primaryBlue,
                      selectedColor: primaryBlue.withOpacity(0.12),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? primaryBlue
                            : const Color(0xFFDCE3F0),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? primaryBlue : const Color(0xFF344054),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 5, 10, 3),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'People to learn with',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedSort,
                    underline: const SizedBox(),
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: primaryBlue,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Recommended',
                        child: Text(
                          'Recommended',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Recently Joined',
                        child: Text(
                          'Recently Joined',
                          style: TextStyle(fontSize: 11),
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
                      child: CircularProgressIndicator(
                        color: primaryBlue,
                      ),
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
                    padding: const EdgeInsets.fromLTRB(10, 3, 10, 12),
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
      ),
    );
  }
}
