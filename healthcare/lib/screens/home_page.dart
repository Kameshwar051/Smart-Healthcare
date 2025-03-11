import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Smart Healthcare'),
        backgroundColor: Colors.blueAccent,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'Settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'Chat':
                  Navigator.pushNamed(context, '/chat');
                  break;
                case 'Generate Report':
                  Navigator.pushNamed(context, '/report');
                  break;
                case 'Logout':
                  Navigator.pushNamed(context, '/login');
                  break;
                case 'About':
                  Navigator.pushNamed(context, '/about');
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'Settings', child: Text('Settings')),
              const PopupMenuItem(value: 'Chat', child: Text('Chat')),
              const PopupMenuItem(value: 'Generate Report', child: Text('Generate Report')),
              const PopupMenuItem(value: 'Logout', child: Text('Logout')),
              const PopupMenuItem(value: 'About', child: Text('About')),
            ],
          ),
        ],
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView( // Fixed Overflow Issue
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildWelcomeBanner(),
                const SizedBox(height: 20),

                // Health Data ListView
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: healthData.length,
                  itemBuilder: (context, index) {
                    final data = healthData[index];
                    return _buildHealthCard(
                      data['title']!, 
                      data['value']!, 
                      data['color']!, 
                      'assets/${data['imagePath']!}'
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Welcome Banner
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome Back! 👋",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Stay healthy with real-time health updates",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Health Data List
  final List<Map<String, dynamic>> healthData = const [
    {'title': '❤️ Heart Rate', 'value': '75 bpm', 'color': Colors.red, 'imagePath': 'heart.png'},
    {'title': '🩸 SpO2', 'value': '98%', 'color': Colors.green, 'imagePath': 'spo2.png'},
    {'title': '🩺 BP', 'value': '120/80', 'color': Colors.orange, 'imagePath': 'bp.png'},
  ];

  // Health Data Card
  Widget _buildHealthCard(String title, String value, Color color, String imagePath) {
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
          Image.asset(imagePath, height: 40), // Icon Image
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
