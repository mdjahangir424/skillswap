
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();

  final List<Map<String, dynamic>> messages = [
    {
      'text': "Hi! I'd like to learn\nBangla. Can you help?",
      'time': '9:15 AM',
      'isMe': false,
      'read': false,
    },
    {
      'text': "Sure! Let's schedule\na session.",
      'time': '9:16 AM',
      'isMe': true,
      'read': true,
    },
    {
      'text': 'Great! How about\nthis Sunday?',
      'time': '9:17 AM',
      'isMe': false,
      'read': false,
    },
    {
      'text': 'Perfect! 👍',
      'time': '9:18 AM',
      'isMe': true,
      'read': true,
    },
  ];

  final Color primaryBlue = const Color(0xFF075CF5);

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({
        'text': text,
        'time': TimeOfDay.now().format(context),
        'isMe': true,
        'read': false,
      });
    });

    messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void showActionMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  bottom: BorderSide(
                    color: Color(0xFFE9EDF5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      'https://randomuser.me/api/portraits/men/32.jpg',
                      width: 43,
                      height: 43,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const CircleAvatar(
                          radius: 21,
                          child: Icon(Icons.person),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'John Smith',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFF15BD75),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF15BD75),
                              ),
                            ),
                          ],
                        ),
                      ],
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

            // Messages
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                children: [
                  ...messages.map((message) {
                    return _messageBubble(message);
                  }),

                  const SizedBox(height: 12),

                  _learningSessionCard(),
                ],
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
                  top: BorderSide(
                    color: Color(0xFFE9EDF5),
                  ),
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
                        onSubmitted: (_) => sendMessage(),
                        decoration: const InputDecoration(
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
                    onTap: sendMessage,
                    child: Container(
                      height: 39,
                      width: 39,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
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

  Widget _messageBubble(Map<String, dynamic> message) {
    final bool isMe = message['isMe'] as bool;

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
                message['text'],
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

          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                message['time'],
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF71809B),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all,
                  size: 14,
                  color: message['read'] == true
                      ? const Color(0xFF1D8CFF)
                      : const Color(0xFF71809B),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _learningSessionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EAFE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: primaryBlue,
                  size: 28,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Session',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sun, Apr 27, 2025 • 7:00 PM',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF26354F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              onPressed: () {
                showActionMessage(
                  'Session confirmation will be connected later.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
