import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AchievementsScreen(),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Title ----------
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Achievements',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---------- Top banner ----------
              const _HeroBanner(),
              const SizedBox(height: 24),

              // ---------- Your Stats header ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Row(
                      children: [
                        Text('See All'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ---------- Stats grid (2 x 2) ----------
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: const [
                  StatCard(
                    icon: Icons.menu_book_rounded,
                    iconColor: Color(0xFF1E6FEB),
                    value: '12',
                    label: 'Courses',
                  ),
                  StatCard(
                    icon: Icons.groups_rounded,
                    iconColor: Color(0xFF2DA3F5),
                    value: '482',
                    label: 'Connections',
                  ),
                  StatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Color(0xFFFF7A00),
                    value: '28',
                    label: 'Day Streak',
                  ),
                  StatCard(
                    icon: Icons.star_rounded,
                    iconColor: Color(0xFFFFB300),
                    value: '4.8',
                    label: 'Rating',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---------- Next goal ----------
              const _NextGoalCard(progress: 0.75),
            ],
          ),
        ),
      ),
    );
  }
}

// =============== Banner ===============
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2BA8), Color(0xFF5B3FD0)],
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 96, color: Color(0xFFFFC107)),
          SizedBox(height: 8),
          Text(
            "You're Awesome!",
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Keep learning and growing!',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// =============== Reusable stat card ===============
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// =============== Next goal card ===============
class _NextGoalCard extends StatelessWidget {
  final double progress; // 0.0 - 1.0

  const _NextGoalCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2BA8), Color(0xFF5B3FD0)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Goal:',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const Text(
                  'Reach Expert Level',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.star_rounded, size: 48, color: Color(0xFFFFC107)),
        ],
      ),
    );
  }
}