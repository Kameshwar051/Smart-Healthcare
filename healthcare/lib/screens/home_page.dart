import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _username = "User";
  bool _showWelcomeBanner = true;
  Map<String, dynamic>? _latestHealthData;

  StreamSubscription<DatabaseEvent>? _healthDataSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _listenToHealthData();
  }

  @override
  void dispose() {
    _healthDataSubscription?.cancel();
    super.dispose();
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

  void _listenToHealthData() {
    DatabaseReference ref = FirebaseDatabase.instance.ref('health_data');
    _healthDataSubscription = ref.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        Map data = event.snapshot.value as Map;
        List<MapEntry> entries = data.entries.toList()
          ..sort((a, b) => b.value['timestamp']
              .toString()
              .compareTo(a.value['timestamp'].toString()));

        Map<String, dynamic> latest = Map<String, dynamic>.from(entries.first.value);

        int latestTimestamp = int.tryParse(latest['timestamp'].toString()) ?? 0;
        int now = DateTime.now().millisecondsSinceEpoch;

        if ((now - latestTimestamp) <= 5000) {
          setState(() {
            _latestHealthData = latest;
          });
        } else {
          setState(() {
            _latestHealthData = null;
          });
        }
      } else {
        setState(() {
          _latestHealthData = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
        title: const Text('Smart Healthcare'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: _buildCustomDrawer(context),
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
                _latestHealthData == null
                    ? const Text("No readings found",
                        style: TextStyle(fontSize: 18))
                    : Column(
                        children: [
                          _buildHealthCard(
                            "❤️ Heart Rate",
                            "${_latestHealthData!['heart_rate']?.toStringAsFixed(1)} bpm",
                            'assets/heart.png',
                          ),
                          _buildHealthCard(
                            "🩸 SpO2",
                            "${_latestHealthData!['spo2']}%",
                            'assets/spo2.png',
                          ),
                          _buildHealthCard(
                            "🩺 BP",
                            "${_latestHealthData!['bp']?.toStringAsFixed(1)}",
                            'assets/bp.png',
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDrawer(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Drawer(
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withAlpha((0.2 * 255).toInt()),
                ),
              ),
            ),
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
                _buildDrawerItem(context, 'Generate Report',
                    Icons.insert_chart, '/report'),
                _buildDrawerItem(
                    context, 'Logout', Icons.exit_to_app, '/home'),
                _buildDrawerItem(context, 'About', Icons.info, '/about'),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
          Expanded(
            child: Column(
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
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _showWelcomeBanner = false;
              });
            },
          ),
        ],
      ),
    );
  }

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
