
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();

  final Color primaryBlue = const Color(0xFF075CF5);

  bool isSending = false;

  CollectionReference<Map<String, dynamic>> get messagesCollection =>
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages');

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (text.isEmpty || currentUser == null || isSending) return;

    if (text.length > 5000) {
      showActionMessage('Message cannot exceed 5000 characters.');
      return;
    }

    setState(() {
      isSending = true;
    });

    messageController.clear();

    try {
      final conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final conversationSnapshot =
            await transaction.get(conversationRef);

        if (!conversationSnapshot.exists) {
          throw Exception('Conversation not found.');
        }

        final participants = List<String>.from(
          conversationSnapshot.data()?['participants'] ?? [],
        );

        if (!participants.contains(currentUser.uid)) {
          throw Exception('You are not a participant in this chat.');
        }

        final messageRef = messagesCollection.doc();

        transaction.set(messageRef, {
          'senderId': currentUser.uid,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(conversationRef, {
          'lastMessage': text,
          'lastMessageSenderId': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        messageController.text = text;
        showActionMessage('Message failed to send. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  void showActionMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE9EDF5)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF172033),
                    ),
                  ),
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: const Color(0xFFE8F0FF),
                    child: Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFF1558E8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.otherUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showActionMessage(
                        'Voice calling will be connected later.',
                      );
                    },
                    icon: Icon(
                      Icons.call,
                      color: primaryBlue,
                      size: 23,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showActionMessage(
                        'Video calling will be connected later.',
                      );
                    },
                    icon: Icon(
                      Icons.videocam_outlined,
                      color: primaryBlue,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),

            // Real-time Messages
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: messagesCollection
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load messages.'),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1558E8),
                      ),
                    );
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Say hello and start learning together!',
                        style: TextStyle(
                          color: Color(0xFF71809B),
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (scrollController.hasClients) {
                      scrollController.jumpTo(
                        scrollController.position.maxScrollExtent,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data();

                      final isMe =
                          data['senderId'] == currentUser.uid;

                      return _messageBubble(
                        text: data['text']?.toString() ?? '',
                        time: formatTime(data['createdAt'] as Timestamp?),
                        isMe: isMe,
                      );
                    },
                  );
                },
              ),
            ),

            // Message Input
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE9EDF5)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      showActionMessage(
                        'File attachment will be connected later.',
                      );
                    },
                    icon: const Icon(
                      Icons.attach_file,
                      color: Color(0xFF526B91),
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF1FA),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: messageController,
                        maxLength: 5000,
                        onSubmitted: (_) => sendMessage(),
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Color(0xFF71809B),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isSending ? null : sendMessage,
                    child: Container(
                      height: 39,
                      width: 39,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: isSending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble({
    required String text,
    required String time,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment:
                isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? primaryBlue
                    : const Color(0xFFE4E9F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : const Color(0xFF172033),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF71809B),
            ),
          ),
        ],
      ),
    );
  }
}
