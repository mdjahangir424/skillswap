
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to view messages.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              child: Text('Unable to load conversations.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1558E8),
              ),
            );
          }

          final conversations = snapshot.data?.docs ?? [];

          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 55,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Connect with someone to start chatting.',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            );
          }

          conversations.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTime = aData['updatedAt'] as Timestamp?;
            final bTime = bData['updatedAt'] as Timestamp?;

            return (bTime?.millisecondsSinceEpoch ?? 0)
                .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final data =
                  conversation.data() as Map<String, dynamic>;

              final participants =
                  List<String>.from(data['participants'] ?? []);

              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) {
                return const SizedBox.shrink();
              }

              return _ConversationTile(
                conversationId: conversation.id,
                otherUserId: otherUserId,
                lastMessage: data['lastMessage'] ?? '',
                updatedAt: data['updatedAt'] as Timestamp?,
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String conversationId;
  final String otherUserId;
  final String lastMessage;
  final Timestamp? updatedAt;

  const _ConversationTile({
    required this.conversationId,
    required this.otherUserId,
    required this.lastMessage,
    required this.updatedAt,
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
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFFE8EEFF),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Loading...'),
          );
        }

        final userData = snapshot.data?.data()
            as Map<String, dynamic>?;

        final name = userData?['name']?.toString() ?? 'SkillSwap User';
        final initial = name.isNotEmpty
            ? name[0].toUpperCase()
            : 'U';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 7,
          ),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFE8EEFF),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF1558E8),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF172B4D),
            ),
          ),
          subtitle: Text(
            lastMessage.isEmpty ? 'Start a conversation' : lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 13,
            ),
          ),
          trailing: Text(
            _formatTime(updatedAt),
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 11,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  conversationId: conversationId,
                  otherUserId: otherUserId,
                  otherUserName: name,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
