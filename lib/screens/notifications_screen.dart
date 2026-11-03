
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primaryBlue = Color(0xFF1558E8);
  static const Color background = Color(0xFFF7F8FC);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _notifications {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications');
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showMessage('Could not update notification. Please try again.');
    }
  }

  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    final unread = documents.where((doc) {
      return doc.data()['isRead'] != true;
    }).toList();

    if (unread.isEmpty) {
      _showMessage('All notifications are already read.');
      return;
    }

    try {
      final batch = _db.batch();

      for (final doc in unread) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      _showMessage('All notifications marked as read.');
    } catch (e) {
      _showMessage('Could not update notifications. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'connection_request':
        return Icons.person_add_alt_1_rounded;
      case 'connection_accepted':
        return Icons.people_alt_rounded;
      case 'session_booking':
        return Icons.calendar_month_rounded;
      case 'session_accepted':
        return Icons.event_available_rounded;
      case 'session_rejected':
        return Icons.event_busy_rounded;
      case 'session_completed':
        return Icons.check_circle_outline_rounded;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'connection_request':
      case 'connection_accepted':
        return const Color(0xFFE8EEFF);
      case 'session_booking':
      case 'session_accepted':
        return const Color(0xFFE5F5EF);
      case 'session_rejected':
        return const Color(0xFFFFEAEA);
      case 'session_completed':
        return const Color(0xFFFFF2DE);
      case 'message':
        return const Color(0xFFF0EAFE);
      default:
        return const Color(0xFFE8EEFF);
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'connection_request':
      case 'connection_accepted':
        return primaryBlue;
      case 'session_booking':
      case 'session_accepted':
        return const Color(0xFF0A9870);
      case 'session_rejected':
        return Colors.red;
      case 'session_completed':
        return const Color(0xFFE58A16);
      case 'message':
        return const Color(0xFF7546D8);
      default:
        return primaryBlue;
    }
  }

  String _timeAgo(dynamic value) {
    if (value is! Timestamp) return 'Just now';

    final date = value.toDate();
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final isRead = data['isRead'] == true;

    return InkWell(
      onTap: isRead ? null : () => _markAsRead(document.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F5FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? const Color(0xFFEEF0F4)
                : const Color(0xFFD8E5FF),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _notificationColor(type),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _notificationIcon(type),
                color: _iconColor(type),
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: const Color(0xFF182230),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _timeAgo(data['createdAt']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF98A2B3),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: primaryBlue,
                size: 52,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF182230),
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'When you receive connection requests, '
              'session updates, or messages, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF182230),
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to view notifications.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF182230),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _notifications
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              final documents = snapshot.data?.docs ?? [];

              final hasUnread = documents.any(
                (doc) => doc.data()['isRead'] != true,
              );

              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(
                onPressed: () => _markAllAsRead(documents),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notifications
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 45,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Please check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return _buildEmptyState();
          }

          final unreadCount = documents
              .where((doc) => doc.data()['isRead'] != true)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Text(
                    '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    return _buildNotification(documents[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
