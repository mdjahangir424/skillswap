
import 'package:flutter/material.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  static const Color purple = Color(0xFF793BFF);
  static const Color brightBlue = Color(0xFF0878FF);

  void showMessage(BuildContext context, String message) {
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071747),
              Color(0xFF142B89),
              Color(0xFF071943),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative confetti
              const Positioned(
                left: 25,
                top: 115,
                child: Text(
                  '✦  ·  ✧',
                  style: TextStyle(
                    color: Color(0xFF28C8F4),
                    fontSize: 20,
                  ),
                ),
              ),
              const Positioned(
                right: 25,
                top: 120,
                child: Text(
                  '✦  ·  ✧',
                  style: TextStyle(
                    color: Color(0xFFFFC83D),
                    fontSize: 20,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      "It's a Match! 🎉",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'You and John Smith\nare a great match!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Profile images and match icon
                    SizedBox(
                      height: 112,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _profilePhoto(
                                'https://randomuser.me/api/portraits/men/75.jpg',
                                online: true,
                              ),
                              _profilePhoto(
                                'https://randomuser.me/api/portraits/men/32.jpg',
                              ),
                            ],
                          ),

                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: brightBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF9ABEFF),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: brightBlue.withOpacity(0.5),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.link,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Match details
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF203A83).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _matchDetail(
                            'Both are interested in:',
                            isHeading: true,
                          ),
                          const SizedBox(height: 8),
                          _matchDetail('Python & AI'),
                          const SizedBox(height: 8),
                          _matchDetail('Language: English'),
                          const SizedBox(height: 8),
                          _matchDetail('Skill Level: Intermediate+'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 17),

                    // Start Chat button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showMessage(
                            context,
                            'Chat feature will be connected later.',
                          );
                        },
                        icon: const Icon(
                          Icons.chat_bubble,
                          size: 17,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Start Chat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // View Profile button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          showMessage(
                            context,
                            'Profile details will be connected later.',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'View Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profilePhoto(String imageUrl, {bool online = false}) {
    return Stack(
      children: [
        Container(
          width: 94,
          height: 94,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8CCBFF),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFDCE7F5),
                  child: const Icon(
                    Icons.person,
                    size: 55,
                    color: Color(0xFF607A9C),
                  ),
                );
              },
            ),
          ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 3,
            child: Container(
              height: 23,
              width: 23,
              decoration: BoxDecoration(
                color: const Color(0xFF13C77B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.circle,
                color: Colors.white,
                size: 8,
              ),
            ),
          ),
      ],
    );
  }

  Widget _matchDetail(
    String text, {
    bool isHeading = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 19,
          height: 19,
          decoration: const BoxDecoration(
            color: Color(0xFF12C77B),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight:
                  isHeading ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
