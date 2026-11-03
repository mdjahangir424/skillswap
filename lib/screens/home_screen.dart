
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'achievements_screen.dart';
import 'learning_session_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const blue = Color(0xFF1558E8);
  static const purple = Color(0xFF6035D9);

  User? get currentUser => FirebaseAuth.instance.currentUser;

  void openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _navigateFromDrawer(int index) {
    Navigator.pop(context);
    widget.onNavigate(index);
  }

  void _openDrawerScreen(Widget screen) {
    Navigator.pop(context);
    openScreen(screen);
  }

  Future<void> _logout() async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'Are you sure you want to log out of SkillSwap?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not log out: $e')),
      );
    }
  }

  void _showInformation(String title, String message) {
    Navigator.pop(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = currentUser;

    return Drawer(
      width: 300,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          color: purple,
                          size: 34,
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SkillSwap',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF253A8B),
                              ),
                            ),
                            Text(
                              'Learn. Teach. Exchange.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  if (user != null)
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data() ?? {};

                        final name =
                            (data['name'] as String?) ??
                            user.displayName ??
                            'SkillSwap User';

                        final email =
                            (data['email'] as String?) ??
                            user.email ??
                            '';

                        final photoUrl =
                            (data['photoUrl'] as String?) ?? '';

                        return InkWell(
                          onTap: () => _navigateFromDrawer(3),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 27,
                                  backgroundColor:
                                      const Color(0xFFE5ECFA),
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: blue,
                                          size: 30,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF182230),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 15,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const Divider(height: 1),

                  _drawerItem(
                    Icons.home_outlined,
                    'Home',
                    onTap: () => _navigateFromDrawer(0),
                  ),
                  _drawerItem(
                    Icons.person_outline,
                    'My Profile',
                    onTap: () => _navigateFromDrawer(3),
                  ),
                  _drawerItem(
                    Icons.school_outlined,
                    'My Skills',
                    onTap: () => _navigateFromDrawer(3),
                  ),
                  _drawerItem(
                    Icons.people_outline,
                    'My Connections',
                    onTap: () => _openDrawerScreen(
                      const LearningSessionScreen(),
                    ),
                  ),
                  _drawerItem(
                    Icons.calendar_month_outlined,
                    'My Sessions',
                    onTap: () => _openDrawerScreen(
                      const LearningSessionScreen(),
                    ),
                  ),
                  _drawerItem(
                    Icons.notifications_none,
                    'Notifications',
                    onTap: () => _showInformation(
                      'Notifications',
                      'Your notifications feature will be available in a future update.',
                    ),
                  ),
                  _drawerItem(
                    Icons.emoji_events_outlined,
                    'Achievements',
                    onTap: () => _openDrawerScreen(
                      const AchievementsScreen(),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Divider(height: 20),
                  ),

                  _drawerItem(
                    Icons.settings_outlined,
                    'Settings',
                    onTap: () => _showInformation(
                      'Settings',
                      'Settings options will be added in a future update.',
                    ),
                  ),
                  _drawerItem(
                    Icons.help_outline,
                    'Help & Support',
                    onTap: () => _showInformation(
                      'Help & Support',
                      'SkillSwap support information will be added soon.',
                    ),
                  ),
                  _drawerItem(
                    Icons.info_outline,
                    'About SkillSwap',
                    onTap: () => _showInformation(
                      'About SkillSwap',
                      'SkillSwap — Learn. Teach. Exchange.',
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            _drawerItem(
              Icons.logout,
              'Logout',
              color: Colors.red,
              onTap: _logout,
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 12, top: 2),
              child: Text(
                'SkillSwap • Version 1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title, {
    required VoidCallback onTap,
    Color color = const Color(0xFF344054),
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      leading: Icon(icon, size: 22, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: purple,
                    size: 30,
                  ),
                  const Text(
                    'SkillSwap',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF253A8B),
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 29,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Welcome
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Rafiq! 👋',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Let's grow together!",
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 27,
                    backgroundColor: Color(0xFFDCE7F8),
                    child: Icon(
                      Icons.person,
                      color: blue,
                      size: 32,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Skill progress card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4628D8),
                      Color(0xFF087CCB),
                      Color(0xFF11BDA9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Skill Level',
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                'Intermediate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Learning Progress',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          '68%',
                          style: TextStyle(
                            color: Colors.yellow.shade300,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const LinearProgressIndicator(
                        value: 0.68,
                        minHeight: 10,
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation(
                          Color(0xFF20D5ED),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.12,
                children: [
                  _actionCard(
                    Icons.search,
                    'Find a',
                    'Skill Partner',
                    const Color(0xFFEDE9FF),
                    purple,
                    () => widget.onNavigate(1),
                  ),
                  _actionCard(
                    Icons.add_circle,
                    'Offer',
                    'Your Skill',
                    const Color(0xFFE0F5F0),
                    const Color(0xFF0AA77A),
                    () => widget.onNavigate(3),
                  ),
                  _actionCard(
                    Icons.calendar_month,
                    'Book a',
                    'Session',
                    const Color(0xFFFFF0E5),
                    const Color(0xFFFF8A24),
                    () => openScreen(
                      const LearningSessionScreen(),
                    ),
                  ),
                  _actionCard(
                    Icons.emoji_events,
                    'View',
                    'Achievements',
                    const Color(0xFFE8EEFF),
                    blue,
                    () => openScreen(
                      const AchievementsScreen(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Popular skills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Skills',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigate(1),
                    child: const Text(
                      'See All →',
                      style: TextStyle(color: blue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _skillCard('🇬🇧', 'English', '(12k+)'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _skillCard(
                      '💻',
                      'Programming',
                      '(15k+)',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(
    IconData icon,
    String first,
    String second,
    Color background,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: iconColor),
            const SizedBox(height: 10),
            Text(
              first,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              second,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillCard(
    String icon,
    String name,
    String count,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 23)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  count,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
