
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LearningSessionScreen extends StatefulWidget {
  const LearningSessionScreen({super.key});

  static const Color primaryBlue = Color(0xFF075CF5);

  @override
  State<LearningSessionScreen> createState() =>
      _LearningSessionScreenState();
}

class _LearningSessionScreenState
    extends State<LearningSessionScreen> {
  static const Color primaryBlue = Color(0xFF075CF5);
  static const Color background = Color(0xFFF8F9FD);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _booking = false;
  bool _updating = false;

  String get _uid => _auth.currentUser!.uid;

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<Map<String, dynamic>?> _getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> _openBookingDialog(
    String connectionId,
    List<String> participants,
    String partnerId,
    String partnerName,
  ) async {
    final skillController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(
      const Duration(days: 1),
    );
    TimeOfDay selectedTime = const TimeOfDay(
      hour: 10,
      minute: 0,
    );
    int duration = 60;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Book a Learning Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('With $partnerName'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: skillController,
                      decoration: const InputDecoration(
                        labelText: 'What will you learn?',
                        hintText: 'Example: Python Programming',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                        color: primaryBlue,
                      ),
                      title: const Text('Date'),
                      subtitle: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time,
                        color: primaryBlue,
                      ),
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: duration,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 30,
                          child: Text('30 minutes'),
                        ),
                        DropdownMenuItem(
                          value: 45,
                          child: Text('45 minutes'),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('60 minutes'),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text('90 minutes'),
                        ),
                        DropdownMenuItem(
                          value: 120,
                          child: Text('120 minutes'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            duration = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _booking
                      ? null
                      : () async {
                          final skill = skillController.text.trim();

                          if (skill.isEmpty) {
                            _message('Please enter a skill or topic.');
                            return;
                          }

                          final scheduledAt = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          if (!scheduledAt.isAfter(DateTime.now())) {
                            _message('Choose a future date and time.');
                            return;
                          }

                          setState(() => _booking = true);

                          try {
                            await _db
                                .collection('learningSessions')
                                .add({
                              'requesterId': _uid,
                              'receiverId': partnerId,
                              'participants': participants,
                              'connectionId': connectionId,
                              'skill': skill,
                              'scheduledAt': Timestamp.fromDate(
                                scheduledAt,
                              ),
                              'durationMinutes': duration,
                              'status': 'pending',
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            _message('Session request sent!');
                          } catch (e) {
                            _message('Could not book session: $e');
                          } finally {
                            if (mounted) {
                              setState(() => _booking = false);
                            }
                          }
                        },
                  child: _booking
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send Request'),
                ),
              ],
            );
          },
        );
      },
    );

    skillController.dispose();
  }

  Future<void> _updateStatus(
    String sessionId,
    String status,
  ) async {
    if (_updating) return;

    setState(() => _updating = true);

    try {
      final update = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'completed') {
        update['completedAt'] = FieldValue.serverTimestamp();
      }

      await _db
          .collection('learningSessions')
          .doc(sessionId)
          .update(update);

      _message(
        status == 'accepted'
            ? 'Session accepted.'
            : status == 'rejected'
                ? 'Session rejected.'
                : 'Session marked as completed.',
      );
    } catch (e) {
      _message('Could not update session: $e');
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  Future<void> _showReviewDialog(
    String sessionId,
    String revieweeId,
    String revieweeName,
  ) async {
    int rating = 5;
    final commentController = TextEditingController();

    final reviewRef = _db
        .collection('learningSessions')
        .doc(sessionId)
        .collection('reviews')
        .doc(_uid);

    try {
      final existing = await reviewRef.get();

      if (existing.exists) {
        _message('You have already reviewed this session.');
        commentController.dispose();
        return;
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Review $revieweeName'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('How was your learning session?'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setDialogState(() {
                                rating = index + 1;
                              });
                            },
                            icon: Icon(
                              index < rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFFFB323),
                              size: 29,
                            ),
                          );
                        }),
                      ),
                      Text('$rating out of 5 stars'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        maxLength: 500,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Write your feedback (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        await reviewRef.set({
                          'reviewerId': _uid,
                          'revieweeId': revieweeId,
                          'rating': rating,
                          'comment': commentController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _message('Thank you for your review!');
                      } catch (e) {
                        _message('Could not submit review: $e');
                      }
                    },
                    child: const Text('Submit Review'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      _message('Could not open review: $e');
    } finally {
      commentController.dispose();
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _sessionCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status = (data['status'] ?? 'pending').toString();
    final participants = List<String>.from(
      data['participants'] ?? [],
    );

    final otherId = participants.firstWhere(
      (id) => id != _uid,
      orElse: () => '',
    );

    final isReceiver = data['receiverId'] == _uid;
    final isRequester = data['requesterId'] == _uid;

    final scheduledAt = data['scheduledAt'] is Timestamp
        ? (data['scheduledAt'] as Timestamp).toDate()
        : null;

    return FutureBuilder<Map<String, dynamic>?>(
      future: otherId.isEmpty ? Future.value(null) : _getUser(otherId),
      builder: (context, userSnapshot) {
        final otherName =
            (userSnapshot.data?['name'] ?? 'SkillSwap Partner').toString();

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (data['skill'] ?? 'Learning Session').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'With $otherName',
                  style: const TextStyle(
                    color: Color(0xFF526078),
                    fontSize: 13,
                  ),
                ),
                if (scheduledAt != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 13),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        TimeOfDay.fromDateTime(scheduledAt).format(context),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  '${data['durationMinutes'] ?? 60} minutes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 11),
                if (status == 'pending' && isReceiver)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _updating
                              ? null
                              : () => _updateStatus(doc.id, 'rejected'),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _updating
                              ? null
                              : () => _updateStatus(doc.id, 'accepted'),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                if (status == 'pending' && isRequester)
                  const Text(
                    'Waiting for your partner to respond.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                if (status == 'accepted')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _updating
                          ? null
                          : () => _updateStatus(doc.id, 'completed'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Completed'),
                    ),
                  ),
                if (status == 'completed')
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: _db
                        .collection('learningSessions')
                        .doc(doc.id)
                        .collection('reviews')
                        .doc(_uid)
                        .get(),
                    builder: (context, reviewSnapshot) {
                      final reviewed =
                          reviewSnapshot.data?.exists ?? false;

                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: reviewed || otherId.isEmpty
                              ? null
                              : () => _showReviewDialog(
                                    doc.id,
                                    otherId,
                                    otherName,
                                  ),
                          icon: const Icon(
                            Icons.star,
                            color: Color(0xFFFFB323),
                          ),
                          label: Text(
                            reviewed ? 'Review Submitted' : 'Give Review',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnections() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('connections')
          .where('participants', arrayContains: _uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Could not load connections.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        final connections = snapshot.data?.docs ?? [];

        if (connections.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'You do not have any connections yet. Connect with someone in Explore first.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: connections.map((connection) {
            final participants = List<String>.from(
              connection.data()['participants'] ?? [],
            );

            final partnerId = participants.firstWhere(
              (id) => id != _uid,
              orElse: () => '',
            );

            if (partnerId.isEmpty) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<Map<String, dynamic>?>(
              future: _getUser(partnerId),
              builder: (context, userSnapshot) {
                final partnerName =
                    (userSnapshot.data?['name'] ?? 'SkillSwap Partner')
                        .toString();

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryBlue.withOpacity(0.10),
                      child: const Icon(
                        Icons.person,
                        color: primaryBlue,
                      ),
                    ),
                    title: Text(
                      partnerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('Connected Skill Partner'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _booking
                          ? null
                          : () => _openBookingDialog(
                                connection.id,
                                participants,
                                partnerId,
                                partnerName,
                              ),
                      child: const Text('Book'),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSessionList() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('learningSessions')
          .where('participants', arrayContains: _uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load sessions: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        final sessions = [...?snapshot.data?.docs];

        sessions.sort((a, b) {
          final aTime = a.data()['scheduledAt'];
          final bTime = b.data()['scheduledAt'];

          final aDate = aTime is Timestamp
              ? aTime.toDate()
              : DateTime(2000);

          final bDate = bTime is Timestamp
              ? bTime.toDate()
              : DateTime(2000);

          return bDate.compareTo(aDate);
        });

        if (sessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(22),
            child: Text(
              'No learning sessions yet. Book a session with a connection.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: sessions.map(_sessionCard).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in first.'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF101828),
          elevation: 0,
          title: const Text(
            'Learning Session',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryBlue,
            tabs: [
              Tab(
                icon: Icon(Icons.people_outline),
                text: 'Connections',
              ),
              Tab(
                icon: Icon(Icons.calendar_month),
                text: 'My Sessions',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              color: primaryBlue,
              onRefresh: () async {
                await _db
                    .collection('connections')
                    .where('participants', arrayContains: _uid)
                    .get();
              },
              child: ListView(
                padding: const EdgeInsets.all(13),
                children: [
                  const Text(
                    'Book a Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Choose one of your connected skill partners.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 13),
                  _buildConnections(),
                ],
              ),
            ),
            RefreshIndicator(
              color: primaryBlue,
              onRefresh: () async {
                await _db
                    .collection('learningSessions')
                    .where('participants', arrayContains: _uid)
                    .get();
              },
              child: ListView(
                padding: const EdgeInsets.all(13),
                children: [
                  const Text(
                    'My Learning Sessions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSessionList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
