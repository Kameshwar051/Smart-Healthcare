import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class GlobalAnomalyListener extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const GlobalAnomalyListener({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<GlobalAnomalyListener> createState() => _GlobalAnomalyListenerState();
}

class _GlobalAnomalyListenerState extends State<GlobalAnomalyListener> {
  final DatabaseReference _anomalyRef = FirebaseDatabase.instance
      .ref('anomaly_status/SHDkL255fATBKdCl7go27teqmSH2/anomaly_detected');

  bool _showAnomaly = false;

  @override
  void initState() {
    super.initState();

    _anomalyRef.onValue.listen((event) {
      final value = event.snapshot.value;

      if (value == true && !_isExcludedRoute()) {
        if (!_showAnomaly) {
          setState(() => _showAnomaly = true);
        }
      } else {
        if (_showAnomaly) {
          setState(() => _showAnomaly = false);
        }
      }
    });
  }

  bool _isExcludedRoute() {
    return widget.currentRoute == '/login' || widget.currentRoute == '/signup';
  }

  Future<void> _dismiss() async {
    await _anomalyRef.set(false);
    setState(() => _showAnomaly = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showAnomaly && !_isExcludedRoute())
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 10,
              color: Colors.redAccent,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "⚠️ Anomaly detected in heart rate!",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _dismiss,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
