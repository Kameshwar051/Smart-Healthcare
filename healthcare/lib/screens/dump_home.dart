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
    {
      'title': '❤️ Heart Rate',
      'value': '75 bpm',
      'imagePath': 'assets/heart.png'
    },
    {'title': '🩸 SpO2', 'value': '98%', 'imagePath': 'assets/spo2.png'},
    {'title': '🩺 BP', 'value': '120/80', 'imagePath': 'assets/bp.png'},
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


/*
import 'dart:convert';
import 'dart:io' as io; // Only used on non-web
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html; // ✅ Replaces dart:html

class GenerateReportPage extends StatefulWidget {
  const GenerateReportPage({super.key});

  @override
  State<GenerateReportPage> createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  final dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://healthcare-578bf-default-rtdb.firebaseio.com/',
  ).ref().child('health_data');

  List<Map<String, dynamic>> filteredData = [];
  DateTime? _startDate;
  DateTime? _endDate;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 1));
    _endDate = now;
    fetchData();
  }

  Future<void> fetchData() async {
    final snapshot = await dbRef.get();
    final data = <Map<String, dynamic>>[];

    for (final child in snapshot.children) {
      final val = child.value as Map?;
      if (val == null) continue;

      final ts = DateTime.tryParse(val['timestamp'] ?? '');
      if (ts != null && _startDate != null && _endDate != null) {
        if (ts.isAfter(_startDate!) && ts.isBefore(_endDate!)) {
          data.add({
            'timestamp': ts,
            'heart_rate': val['heart_rate'],
            'spo2': val['spo2'],
            'bp': val['bp']
          });
        }
      }
    }

    setState(() => filteredData = data);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      fetchData();
    }
  }

  Future<void> _exportCSV() async {
    final csvData = [
      ['Timestamp', 'Heart Rate', 'SpO2', 'BP'],
      ...filteredData.map((e) => [
            DateFormat('yyyy-MM-dd HH:mm:ss').format(e['timestamp']),
            e['heart_rate'],
            e['spo2'],
            e['bp'],
          ])
    ];
    final csv = const ListToCsvConverter().convert(csvData);

    if (kIsWeb) {
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "health_report.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/health_report.csv');
      await file.writeAsString(csv);
      Share.shareXFiles([XFile(file.path)], text: 'Health Report CSV');
    }
  }

  Future<void> _exportChart() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      if (kIsWeb) {
        final blob = html.Blob([image]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "heart_rate_chart.png")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getTemporaryDirectory();
        final file = io.File('${dir.path}/chart.png');
        await file.writeAsBytes(image);
        Share.shareXFiles([XFile(file.path)], text: 'Heart Rate Chart');
      }
    }
  }

  List<FlSpot> get _chartSpots {
    return filteredData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['heart_rate'].toDouble()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Report"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                _startDate != null && _endDate != null
                    ? "${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}"
                    : "Select Duration",
              ),
            ),
            const SizedBox(height: 20),
            if (filteredData.isEmpty)
              const Center(child: Text("No readings found."))
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Heart Rate vs Time",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Screenshot(
                        controller: _screenshotController,
                        child: LineChart(
                          LineChartData(
                            titlesData: FlTitlesData(show: true),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _chartSpots,
                                isCurved: true,
                                color: Colors.redAccent,
                                barWidth: 3,
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.redAccent.withAlpha(100),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _exportChart,
                          icon: const Icon(Icons.image),
                          label: const Text("Download Chart"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _exportCSV,
                          icon: const Icon(Icons.file_download),
                          label: const Text("Download CSV"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


import 'dart:convert';
import 'dart:io' as io; // Only used on non-web
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class GenerateReportPage extends StatefulWidget {
  const GenerateReportPage({super.key});

  @override
  State<GenerateReportPage> createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  final dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://healthcare-578bf-default-rtdb.firebaseio.com/',
  ).ref().child('health_data');

  List<Map<String, dynamic>> filteredData = [];
  DateTime? _startDate;
  DateTime? _endDate;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 1));
    _endDate = now;
    fetchData();
  }

  Future<void> fetchData() async {
    final snapshot = await dbRef.get();
    final data = <Map<String, dynamic>>[];

    for (final child in snapshot.children) {
      final val = child.value as Map?;
      if (val == null) continue;

      final ts = DateTime.tryParse(val['timestamp'] ?? '');
      if (ts != null && _startDate != null && _endDate != null) {
        if (ts.isAfter(_startDate!) && ts.isBefore(_endDate!)) {
          data.add({
            'timestamp': ts,
            'heart_rate': val['heart_rate'],
            'spo2': val['spo2'],
            'bp': val['bp']
          });
        }
      }
    }

    setState(() => filteredData = data);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      fetchData();
    }
  }

  Future<void> _exportCSV() async {
    final csvData = [
      ['Timestamp', 'Heart Rate', 'SpO2', 'BP'],
      ...filteredData.map((e) => [
            DateFormat('yyyy-MM-dd HH:mm:ss').format(e['timestamp']),
            e['heart_rate'],
            e['spo2'],
            e['bp'],
          ])
    ];
    final csv = const ListToCsvConverter().convert(csvData);

    if (kIsWeb) {
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "health_report.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/health_report.csv');
      await file.writeAsString(csv);
      Share.shareXFiles([XFile(file.path)], text: 'Health Report CSV');
    }
  }

  Future<void> _exportChart() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      if (kIsWeb) {
        final blob = html.Blob([image]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "heart_rate_chart.png")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getTemporaryDirectory();
        final file = io.File('${dir.path}/chart.png');
        await file.writeAsBytes(image);
        Share.shareXFiles([XFile(file.path)], text: 'Heart Rate Chart');
      }
    }
  }

  List<FlSpot> get _chartSpots {
    return filteredData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['heart_rate'].toDouble()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Report"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                _startDate != null && _endDate != null
                    ? "${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}"
                    : "Select Duration",
              ),
            ),
            const SizedBox(height: 20),
            if (filteredData.isEmpty)
              const Center(child: Text("No readings found."))
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text(
                                'Heart Rate vs Time',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    minY: 0,
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        axisNameWidget: const Padding(
                                          padding: EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            'Heart Rate',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 10,
                                          reservedSize: 42,
                                          getTitlesWidget: (value, meta) =>
                                              Padding(
                                            padding: const EdgeInsets.only(
                                                right: 6.0),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        axisNameWidget: const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Time',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval:
                                              (_chartSpots.length / 5).clamp(1, 10),
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >=
                                                filteredData.length) {
                                              return const Text('');
                                            }
                                            final ts = filteredData[value.toInt()]
                                                ['timestamp'];
                                            return Text(
                                              DateFormat.Hm().format(ts),
                                              style: const TextStyle(fontSize: 10),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: Colors.grey.withOpacity(0.2),
                                        strokeWidth: 1,
                                      ),
                                      getDrawingVerticalLine: (value) => FlLine(
                                        color: Colors.grey.withOpacity(0.2),
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: const Border(
                                        left: BorderSide(),
                                        bottom: BorderSide(),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _chartSpots,
                                        isCurved: true,
                                        color: Colors.redAccent,
                                        barWidth: 3,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.redAccent.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        dotData: FlDotData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _exportChart,
                          icon: const Icon(Icons.image),
                          label: const Text("Download Chart"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _exportCSV,
                          icon: const Icon(Icons.file_download),
                          label: const Text("Download CSV"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

*/