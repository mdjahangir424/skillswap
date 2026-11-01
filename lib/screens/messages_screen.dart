
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const Color primaryBlue = Color(0xFF1558E8);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view messages.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE9EDF5),
                  ),
                ),
              ),
              child: const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101828),
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('conversations')
                    .where(
                      'participants',
                      arrayContains: currentUser.uid,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Unable to load conversations.\nPlease check your connection and security rules.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primaryBlue,
                      ),
                    );
                  }

                  final conversations = snapshot.data?.docs ?? [];

                  conversations.sort((a, b) {
                    final aTime = a.data()['updatedAt'] as Timestamp?;
                    final bTime = b.data()['updatedAt'] as Timestamp?;

                    return (bTime?.millisecondsSinceEpoch ?? 0)
                        .compareTo(
                      aTime?.millisecondsSinceEpoch ?? 0,
                    );
                  });

                  if (conversations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 75,
                              width: 75,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F0FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 35,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Connect with people in Explore to start a conversation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF667085),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final data = conversation.data();

                      final participants =
                          List<String>.from(
                        data['participants'] ?? [],
                      );

                      final otherUserId = participants.firstWhere(
                        (id) => id != currentUser.uid,
                        orElse: () => '',
                      );

                      if (otherUserId.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _ConversationTile(
                        otherUserId: otherUserId,
                        lastMessage:
                            data['lastMessage']?.toString() ?? '',
                        updatedAt: data['updatedAt'] as Timestamp?,
                        conversationId: conversation.id,
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

class _ConversationTile extends StatelessWidget {
  final String otherUserId;
  final String lastMessage;
  final Timestamp? updatedAt;
  final String conversationId;

  const _ConversationTile({
    required this.otherUserId,
    required this.lastMessage,
    required this.updatedAt,
    required this.conversationId,
  });

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();

        final name = userData?['name']?.toString() ??
            'SkillSwap User';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEAECF0),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFE8F0FF),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF1558E8),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF101828),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                lastMessage.isEmpty
                    ? 'Start a conversation'
                    : lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667085),
                ),
              ),
            ),
            trailing: Text(
              _formatTime(updatedAt),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF667085),
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chat screen connection is coming in the next step.',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
