import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'All';
  String searchText = '';
  bool highRatingFirst = false;

  final Color primaryBlue = const Color(0xFF0860F5);
  final Color backgroundColor = const Color(0xFFF6F8FE);

  final List<Map<String, dynamic>> people = [
    {
      'name': 'Ayesha Rahman',
      'flag': '🇧🇩',
      'teaches': 'Bangla, English',
      'learns': 'Graphic Design',
      'rating': 4.9,
      'reviews': '1.2k',
      'image': 'https://randomuser.me/api/portraits/women/44.jpg',
      'online': true,
      'verified': true,
      'type': 'Teaching',
    },
    {
      'name': 'John Smith',
      'flag': '🇺🇸',
      'teaches': 'Python, AI',
      'learns': 'Bengali',
      'rating': 4.8,
      'reviews': '980',
      'image': 'https://randomuser.me/api/portraits/men/32.jpg',
      'online': false,
      'verified': false,
      'type': 'Learning',
    },
    {
      'name': 'Priya Sharma',
      'flag': '🇮🇳',
      'teaches': 'Web Design',
      'learns': 'Video Editing',
      'rating': 4.9,
      'reviews': '720',
      'image': 'https://randomuser.me/api/portraits/women/68.jpg',
      'online': false,
      'verified': false,
      'type': 'Teaching',
    },
    {
      'name': 'Ahmed Hassan',
      'flag': '🇦🇪',
      'teaches': 'Arabic, English',
      'learns': 'Data Science',
      'rating': 4.7,
      'reviews': '610',
      'image': 'https://randomuser.me/api/portraits/men/75.jpg',
      'online': false,
      'verified': false,
      'type': 'Learning',
    },
  ];

  final Set<String> connectedPeople = {};

  List<Map<String, dynamic>> get filteredPeople {
    List<Map<String, dynamic>> result = people.where((person) {
      final name = person['name'].toString().toLowerCase();
      final teaches = person['teaches'].toString().toLowerCase();
      final learns = person['learns'].toString().toLowerCase();

      final matchesSearch = name.contains(searchText) ||
          teaches.contains(searchText) ||
          learns.contains(searchText);

      final matchesFilter = selectedFilter == 'All' ||
          person['type'] == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    if (highRatingFirst) {
      result.sort(
        (a, b) => (b['rating'] as double)
            .compareTo(a['rating'] as double),
      );
    }

    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort & Filter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Highest rating first'),
                value: highRatingFirst,
                activeColor: primaryBlue,
                onChanged: (value) {
                  setState(() {
                    highRatingFirst = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
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
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 5, 24, 15),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFFA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchText = value.toLowerCase().trim();
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search for skills...',
                    hintStyle: TextStyle(
                      color: Color(0xFF7183A8),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF7183A8),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),

            // Filter buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _filterButton('All'),
                  const SizedBox(width: 8),
                  _filterButton('Teaching'),
                  const SizedBox(width: 8),
                  _filterButton('Learning'),
                  const SizedBox(width: 8),
                  Container(
                    height: 36,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEFFA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: showFilterOptions,
                      icon: const Icon(
                        Icons.tune,
                        size: 21,
                        color: Color(0xFF26354F),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // People list
            Expanded(
              child: filteredPeople.isEmpty
                  ? const Center(
                      child: Text(
                        'No skills found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                      itemCount: filteredPeople.length,
                      itemBuilder: (context, index) {
                        final person = filteredPeople[index];

                        return _personCard(person);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String title) {
    final isSelected = selectedFilter == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = title;
          });
        },
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryBlue
                : const Color(0xFFEAEFFA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF26354F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _personCard(Map<String, dynamic> person) {
    final name = person['name'] as String;
    final isConnected = connectedPeople.contains(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8EA5D0).withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile photo
          Stack(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE6EAF5),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    person['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFE7EDFA),
                        child: const Icon(
                          Icons.person,
                          size: 42,
                          color: Color(0xFF8092B5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (person['online'] == true)
                Positioned(
                  right: 0,
                  bottom: 3,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF12C879),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Profile information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (person['verified'] == true)
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF1682F8),
                        size: 15,
                      ),
                    const SizedBox(width: 5),
                    Text(
                      person['flag'],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  'Teaches: ${person['teaches']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF26354F),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Learns: ${person['learns']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF26354F),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFB323),
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${person['rating']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(${person['reviews']})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF71809B),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 31,
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
                              ? const Color(0xFFE7EEFF)
                              : primaryBlue,
                          foregroundColor: isConnected
                              ? primaryBlue
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Text(
                          isConnected ? 'Connected' : 'Connect',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}