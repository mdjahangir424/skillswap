
import 'package:flutter/material.dart';

class LearningSessionScreen extends StatelessWidget {
  const LearningSessionScreen({super.key});

  static const Color primaryBlue = Color(0xFF075CF5);
  static const Color purple = Color(0xFF5930DF);

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showFeedbackDialog(BuildContext context) {
    int rating = 5;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Give Feedback'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rate your learning session'),
                  const SizedBox(height: 15),
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
                          size: 30,
                        ),
                      );
                    }),
                  ),
                  Text('$rating out of 5 stars'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    showMessage(
                      context,
                      'Thank you for your feedback!',
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header - Back Arrow Fixed on Left
            SizedBox(
              height: 57,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Learning Session',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),

                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 19,
                          color: Color(0xFF526B91),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Learning illustration
                    _buildIllustration(),

                    const SizedBox(height: 12),

                    // Course information
                    const Text(
                      'Python Programming',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'with Priya Sharma',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 19),

                    // Date and duration
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 27,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: primaryBlue,
                            size: 25,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apr 27, 2025',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '7:00 PM',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            color: primaryBlue,
                            size: 25,
                          ),
                          const SizedBox(width: 9),
                          const Text(
                            '60 min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Completion status
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9F3DE),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 33,
                            height: 33,
                            decoration: const BoxDecoration(
                              color: Color(0xFF13AA70),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session Completed!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF172033),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Great job! Keep learning.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF26354F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Give Feedback button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => showFeedbackDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text(
                            'Give Feedback',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    // Download Certificate button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: SizedBox(
                        width: double.infinity,
                        height: 43,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showMessage(
                              context,
                              'Certificate generation will be connected later.',
                            );
                          },
                          icon: const Icon(
                            Icons.download,
                            color: primaryBlue,
                            size: 21,
                          ),
                          label: const Text(
                            'Download Certificate',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172033),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE1EAFF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 168,
      width: double.infinity,
      color: const Color(0xFFE5E5FF),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Plants
          const Positioned(
            left: 12,
            bottom: 15,
            child: Icon(
              Icons.spa,
              color: Color(0xFF39A75A),
              size: 57,
            ),
          ),
          const Positioned(
            right: 12,
            bottom: 15,
            child: Icon(
              Icons.spa,
              color: Color(0xFF39A75A),
              size: 57,
            ),
          ),

          // Laptop
          Container(
            width: 190,
            height: 125,
            decoration: BoxDecoration(
              color: const Color(0xFF172D4B),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: const Color(0xFF263D61),
                width: 4,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF253D70),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.laptop_mac,
                    size: 43,
                    color: Color(0xFFB8D6FF),
                  ),
                  SizedBox(height: 4),
                  Icon(
                    Icons.code,
                    size: 35,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // Instructor avatar
          Positioned(
            right: 8,
            bottom: 10,
            child: Container(
              width: 57,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFF243A62),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 43,
                color: Colors.white,
              ),
            ),
          ),

          // Table / laptop base
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              color: const Color(0xFFD9C6B7),
            ),
          ),
        ],
      ),
    );
  }
}
