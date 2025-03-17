import 'dart:ui'; // Needed for blur effect
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _username = "User"; // Default username
  bool _showWelcomeBanner = true; // Controls visibility of welcome banner

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc['name'] ?? "User";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Allows controlling the drawer manually
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
        title: const Text('Smart Healthcare'),
        leading: IconButton(
          icon: const Icon(Icons.menu), // Hamburger menu icon
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),

      drawer: _buildCustomDrawer(context), // Custom Drawer with blur effect

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_showWelcomeBanner) _buildWelcomeBanner(),
                const SizedBox(height: 20),

                // Health Data ListView
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: healthData.length,
                  itemBuilder: (context, index) {
                    final data = healthData[index];
                    return _buildHealthCard(
                        data['title']!, data['value']!, data['imagePath']!);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Drawer with Blur Effect
  Widget _buildCustomDrawer(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75, // 3/4 width of screen
      child: Drawer(
        child: Stack(
          children: [
            // Blurred background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                    color: Colors.black.withAlpha((0.2 * 255).toInt())),
              ),
            ),

            // Drawer Menu Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.blueAccent),
                  child: const Text(
                    'Menu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                _buildDrawerItem(
                    context, 'Settings', Icons.settings, '/settings'),
                _buildDrawerItem(
                    context, 'Chat', Icons.chat, '/chat_front_page'),
                _buildDrawerItem(
                    context, 'Generate Report', Icons.insert_chart, '/report'),
                _buildDrawerItem(context, 'Logout', Icons.exit_to_app, '/home'),
                _buildDrawerItem(context, 'About', Icons.info, '/about'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Drawer Menu Item
  Widget _buildDrawerItem(
      BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  // Welcome Banner with Delete Button
  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, $_username! 👋",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Stay healthy with real-time health updates",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _showWelcomeBanner = false; // Hide welcome banner
              });
            },
          ),
        ],
      ),
    );
  }

  // Health Data List
  final List<Map<String, String>> healthData = [
    {'title': '❤️ Heart Rate', 'value': '75 bpm', 'imagePath': 'heart.png'},
    {'title': '🩸 SpO2', 'value': '98%', 'imagePath': 'spo2.png'},
    {'title': '🩺 BP', 'value': '120/80', 'imagePath': 'bp.png'},
  ];

  // Health Data Card
  Widget _buildHealthCard(String title, String value, String imagePath) {
    Color cardColor = title.contains('Heart')
        ? Colors.red
        : title.contains('SpO2')
            ? Colors.green
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: cardColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
