
import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const Color primaryBlue = Color(0xFF075CF5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const SizedBox(
              height: 55,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 25,
                    color: Color(0xFF172033),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(21, 5, 21, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Achievement banner
                    _achievementBanner(),

                    const SizedBox(height: 14),

                    // Stats heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Stats',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF101828),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _showAllStats(context);
                          },
                          child: const Text(
                            'See All →',
                            style: TextStyle(
                              color: Color(0xFF173B9A),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Statistics grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 9,
                      childAspectRatio: 1.75,
                      children: const [
                        _StatCard(
                          icon: Icons.menu_book,
                          iconColor: Color(0xFF1682F8),
                          value: '12',
                          label: 'Courses',
                        ),
                        _StatCard(
                          icon: Icons.groups,
                          iconColor: Color(0xFF1682F8),
                          value: '482',
                          label: 'Connections',
                        ),
                        _StatCard(
                          icon: Icons.local_fire_department,
                          iconColor: Color(0xFFFF791C),
                          value: '28',
                          label: 'Day Streak',
                        ),
                        _StatCard(
                          icon: Icons.star,
                          iconColor: Color(0xFFFFB323),
                          value: '4.8',
                          label: 'Rating',
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    // Next goal card
                    _nextGoalCard(),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievementBanner() {
    return Container(
      width: double.infinity,
      height: 157,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6336D8),
            Color(0xFF29218D),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 40,
            top: 55,
            child: Icon(
              Icons.star,
              color: Color(0xFFFFD42A),
              size: 18,
            ),
          ),
          const Positioned(
            right: 40,
            top: 62,
            child: Icon(
              Icons.star,
              color: Color(0xFFFFD42A),
              size: 18,
            ),
          ),
          const Positioned(
            left: 70,
            top: 42,
            child: Icon(
              Icons.auto_awesome,
              color: Color(0xFFFFD42A),
              size: 12,
            ),
          ),
          const Positioned(
            right: 76,
            top: 43,
            child: Icon(
              Icons.auto_awesome,
              color: Color(0xFF33C8FF),
              size: 13,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFC928),
                size: 76,
              ),
              const SizedBox(height: 3),
              const Text(
                "You're Awesome!",
                style: TextStyle(
                  color: Color(0xFFFFD92E),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Keep learning and growing!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextGoalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5834D6),
            Color(0xFF172FAD),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Goal:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reach Expert Level',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.star,
                color: Color(0xFFFFD42A),
                size: 39,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: 0.75,
              minHeight: 10,
              backgroundColor: Color(0xFF17247B),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFE9E9FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllStats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Achievements',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 18),
                ListTile(
                  leading: Icon(Icons.menu_book, color: Colors.blue),
                  title: Text('12 Courses Completed'),
                ),
                ListTile(
                  leading: Icon(Icons.groups, color: Colors.blue),
                  title: Text('482 Connections'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                  title: Text('28 Day Learning Streak'),
                ),
                ListTile(
                  leading: Icon(Icons.star, color: Colors.amber),
                  title: Text('4.8 Average Rating'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDF1FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 26,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF101828),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF26354F),
            ),
          ),
        ],
      ),
    );
  }
}
