import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ble_service.dart';
import '../services/firestore_service.dart';

class MainScreen extends StatefulWidget {
  final String studentId;

  const MainScreen({super.key, required this.studentId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _bleService = BleService();
  final _firestoreService = FirestoreService();

  String _scanStatus = 'Ready to scan';
  String? _detectedUUID;
  String? _courseInfo;
  bool _isScanning = false;
  bool _canLogAttendance = false;

  String? _activeSessionUUID;
  String? _courseId;
  String? _scheduleId;

  @override
  void initState() {
    super.initState();
    _bleService.onUuidDetected = _onUuidDetected;
    _checkPermissionsAndStartScan();
  }

  Future<void> _checkPermissionsAndStartScan() async {
    final hasPermission = await _bleService.checkBluetoothPermissions();
    if (!hasPermission) {
      setState(() {
        _scanStatus = 'Bluetooth permissions required';
      });
      return;
    }

    final isAvailable = await _bleService.isBluetoothAvailable();
    if (!isAvailable) {
      setState(() {
        _scanStatus = 'Bluetooth not available';
      });
      return;
    }

    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanStatus = '🔍 Scanning for attendance sessions...';
    });

    await _bleService.startScan();
  }

  void _onUuidDetected(String uuid) {
    if (_detectedUUID == uuid) return; // Already processed

    setState(() {
      _detectedUUID = uuid;
    });

    _checkActiveSession(uuid);
  }

  Future<void> _checkActiveSession(String uuid) async {
    final sessionData = await _firestoreService.checkActiveSessionInFirestore(uuid);

    if (sessionData != null) {
      setState(() {
        _activeSessionUUID = sessionData['sessionUUID'];
        _courseId = sessionData['courseId'];
        _scheduleId = sessionData['scheduleId'];
        _scanStatus = '✅ Active session found!';
      });

      await _bleService.stopScan();
      _verifyEnrollment();
    }
  }

  Future<void> _verifyEnrollment() async {
    if (_courseId == null || _scheduleId == null) return;

    final isEnrolled = await _firestoreService.verifyStudentEnrollment(
      _courseId!,
      _scheduleId!,
      widget.studentId,
    );

    setState(() {
      if (isEnrolled) {
        _courseInfo = 'You are enrolled in this course.\nTap below to log attendance.';
        _canLogAttendance = true;
      } else {
        _courseInfo = 'You are NOT enrolled in this course.';
        _canLogAttendance = false;
      }
    });
  }

  Future<void> _logAttendance() async {
    if (_courseId == null || _scheduleId == null || _activeSessionUUID == null) {
      _showSnackBar('No active session', Colors.red);
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final success = await _firestoreService.logAttendance(
      _courseId!,
      _scheduleId!,
      today,
      _activeSessionUUID!,
      widget.studentId,
    );

    if (success) {
      _showSnackBar('✅ Attendance logged successfully!', Colors.green);
      setState(() {
        _canLogAttendance = false;
      });
    } else {
      _showSnackBar('Failed to log attendance', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _bleService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _scanStatus,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isScanning)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_detectedUUID != null)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected UUID:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _detectedUUID!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_courseInfo != null)
              Card(
                color: _canLogAttendance ? Colors.green.shade50 : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _courseInfo!,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _canLogAttendance ? _logAttendance : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Log Attendance'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
