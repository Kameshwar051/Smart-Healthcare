// ... imports remain the same
import 'dart:convert';
import 'dart:io' as io;
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
  final dbRef = FirebaseDatabase.instance.ref().child('health_data');

  //final User? _user = FirebaseAuth.instance.currentUser;

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
                  children: [
                    Expanded(
                      child: Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
                          child: Column(
                            children: [
                              const Text(
                                'Heart Rate vs Time',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    minY: 0,
                                    lineTouchData:
                                        LineTouchData(enabled: false),
                                    gridData: FlGridData(show: true),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: const Border(
                                        left: BorderSide(),
                                        bottom: BorderSide(),
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        axisNameSize: 32,
                                        axisNameWidget: const Text(
                                          'Heart Rate',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 42,
                                          interval: 10,
                                          getTitlesWidget: (value, meta) =>
                                              Padding(
                                            padding: const EdgeInsets.only(
                                                right: 4.0),
                                            child: Text(
                                              value.toInt().toString(),
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        axisNameSize: 32,
                                        axisNameWidget: const Text(
                                          'Time',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final int index = value.round();

                                              // Don't go out of bounds
                                              if (index < 0 ||
                                                  index >=
                                                      filteredData.length) {
                                                return const SizedBox.shrink();
                                              }

                                              // Show only a few evenly spaced labels (max 6)
                                              int total = filteredData.length;
                                              int step = (total / 5)
                                                  .ceil(); // show around 5–6 labels

                                              if (index % step != 0 &&
                                                  index != total - 1) {
                                                return const SizedBox.shrink();
                                              }

                                              final DateTime ts =
                                                  filteredData[index]
                                                      ['timestamp'] as DateTime;

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6),
                                                child: Text(
                                                  DateFormat.Hm().format(
                                                      ts), // You can change format here
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                              );
                                            }),
                                      ),
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
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
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
