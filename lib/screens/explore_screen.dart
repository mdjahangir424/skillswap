import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'All';
  String selectedSort = 'Recommended';

  final List<String> categories = [
    'All',
    'Design',
    'Technology',
    'Language',
    'Business',
    'Music',
  ];

  final List<Map<String, dynamic>> people = [
    {
      'name': 'Ayesha Rahman',
      'skill': 'UI/UX Designer',
      'learn': 'Flutter Development',
      'category': 'Design',
      'rating': '4.9',
      'image': 'A',
      'color': Color(0xFFEDE9FE),
    },
    {
      'name': 'John Smith',
      'skill': 'Flutter Developer',
      'learn': 'Graphic Design',
      'category': 'Technology',
      'rating': '4.8',
      'image': 'J',
      'color': Color(0xFFDBEAFE),
    },
    {
      'name': 'Priya Sharma',
      'skill': 'English Teacher',
      'learn': 'Web Development',
      'category': 'Language',
      'rating': '4.9',
      'image': 'P',
      'color': Color(0xFFFCE7F3),
    },
    {
      'name': 'Ahmed Hassan',
      'skill': 'Digital Marketer',
      'learn': 'UI/UX Design',
      'category': 'Business',
      'rating': '4.7',
      'image': 'A',
      'color': Color(0xFFD1FAE5),
    },
  ];

  final Set<String> connectedPeople = {};

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredPeople {
    List<Map<String, dynamic>> result = people.where((person) {
      final query = searchController.text.toLowerCase();

      final matchesSearch =
          person['name'].toString().toLowerCase().contains(query) ||
          person['skill'].toString().toLowerCase().contains(query) ||
          person['learn'].toString().toLowerCase().contains(query);

      final matchesCategory =
          selectedCategory == 'All' ||
          person['category'] == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    if (selectedSort == 'Top Rated') {
      result.sort(
        (a, b) => double.parse(b['rating'])
            .compareTo(double.parse(a['rating'])),
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SizedBox(
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Explore Skills',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search skills or people...',
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Category heading
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101828),
                ),
              ),

              const SizedBox(height: 12),

              // Category filters
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1558E8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1558E8)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475467),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // People heading and sorting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'People to Connect',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedSort,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'Recommended',
                        child: Text('Recommended'),
                      ),
                      DropdownMenuItem(
                        value: 'Top Rated',
                        child: Text('Top Rated'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSort = value;
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // People list
              if (filteredPeople.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'No people found.',
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ...filteredPeople.map((person) {
                  final name = person['name'] as String;
                  final isConnected = connectedPeople.contains(name);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFEAECF0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: person['color'],
                              child: Text(
                                person['image'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1558E8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF101828),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    person['skill'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFDB022),
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              person['rating'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          'Wants to learn',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          person['learn'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF344054),
                          ),
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (isConnected) {
                                  connectedPeople.remove(name);
                                } else {
                                  connectedPeople.add(name);
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isConnected
                                  ? const Color(0xFFE8F0FF)
                                  : const Color(0xFF1558E8),
                              foregroundColor: isConnected
                                  ? const Color(0xFF1558E8)
                                  : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: Text(
                              isConnected ? 'Connected' : 'Connect',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}