
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  Future<void> _respondToRequest(
    BuildContext context,
    String requestId,
    bool accept,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final firestore = FirebaseFirestore.instance;
    final requestRef =
        firestore.collection('connectionRequests').doc(requestId);

    try {
      final requestSnapshot = await requestRef.get();

      if (!requestSnapshot.exists) {
        throw Exception('Request not found.');
      }

      final requestData = requestSnapshot.data()!;

      if (requestData['receiverId'] != currentUser.uid ||
          requestData['status'] != 'pending') {
        throw Exception('This request is no longer available.');
      }

      if (!accept) {
        await requestRef.update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected.')),
          );
        }
        return;
      }

      final senderId = requestData['senderId'] as String;
      final receiverId = requestData['receiverId'] as String;

      final participants = [senderId, receiverId]..sort();

      final connectionId = participants.join('_');
      final conversationId = '${connectionId}_$requestId';

      final connectionRef =
          firestore.collection('connections').doc(connectionId);

      final conversationRef =
          firestore.collection('conversations').doc(conversationId);

      // Check whether this pair is already connected.
      final existingConnection = await connectionRef.get();

      final batch = firestore.batch();

      if (!existingConnection.exists) {
        batch.set(connectionRef, {
          'participants': participants,
          'requestId': requestId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      batch.set(conversationRef, {
        'participants': participants,
        'connectionId': connectionId,
        'lastMessage': '',
        'lastMessageSenderId': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(requestRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
        'connectionId': connectionId,
        'conversationId': conversationId,
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted! Chat is now available.'),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase error: ${e.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildIncomingRequests(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('connectionRequests')
          .where('receiverId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Could not load connection requests.'),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final requests = snapshot.data!.docs.where(
          (doc) => doc.data()['status'] == 'pending',
        ).toList();

        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Incoming Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...requests.map((request) {
                final senderId =
                    request.data()['senderId'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FutureBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(senderId)
                                .get(),
                            builder: (context, userSnapshot) {
                              final senderName =
                                  userSnapshot.data?.data()?['name'] ??
                                      'SkillSwap User';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderName.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Wants to connect with you',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          children: [
                            SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                onPressed: () => _respondToRequest(
                                  context,
                                  request.id,
                                  true,
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 34,
                              child: OutlinedButton(
                                onPressed: () => _respondToRequest(
                                  context,
                                  request.id,
                                  false,
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversations(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load messages: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = snapshot.data!.docs.where((doc) {
          return doc.data()['connectionId'] is String;
        }).toList();

        conversations.sort((a, b) {
          final aTime = a.data()['updatedAt'];
          final bTime = b.data()['updatedAt'];

          final aDate =
              aTime is Timestamp ? aTime.toDate() : DateTime(2000);
          final bDate =
              bTime is Timestamp ? bTime.toDate() : DateTime(2000);

          return bDate.compareTo(aDate);
        });

        if (conversations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No conversations yet.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text('Accept a connection request to start chatting.'),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final data = conversation.data();

            final participants =
                List<String>.from(data['participants'] ?? []);

            final otherUserId = participants.firstWhere(
              (id) => id != uid,
              orElse: () => '',
            );

            return FutureBuilder<
                DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnapshot) {
                final otherUserData = userSnapshot.data?.data();

                final otherUserName =
                    otherUserData?['name'] ?? 'SkillSwap User';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      otherUserName.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      (data['lastMessage'] ?? 'Start a conversation')
                          .toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: otherUserId.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  conversationId: conversation.id,
                                  otherUserId: otherUserId,
                                  otherUserName: otherUserName.toString(),
                                ),
                              ),
                            );
                          },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

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
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildIncomingRequests(currentUser.uid),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Conversations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildConversations(currentUser.uid),
          ),
        ],
      ),
    );
  }
}
