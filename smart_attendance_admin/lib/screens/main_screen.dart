import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/ble_service.dart';

class MainScreen extends StatefulWidget {
  final String professorId;

  const MainScreen({super.key, required this.professorId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _firestoreService = FirestoreService();
  final _bleService = BleService();
  final _uuid = const Uuid();

  String? _professorName;
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  String? _selectedScheduleId;
  String? _semesterName;
  String? _scheduleInfo;
  String? _activeSessionUUID;
  String? _advertisedUUID;
  bool _isAdvertising = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessorData();
  }

  Future<void> _loadProfessorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courseIds = await _firestoreService.fetchProfessorCourses(widget.professorId);
      final List<Map<String, dynamic>> courses = [];

      for (var courseId in courseIds) {
        final courseDetails = await _firestoreService.fetchCourseDetails(courseId);
        if (courseDetails != null) {
          courses.add(courseDetails);
        }
      }

      setState(() {
        _courses = courses;
        _isLoading = false;
        if (_courses.isNotEmpty) {
          _onCourseSelected(_courses[0]['id']);
        }
      });
    } catch (e) {
      print('Error loading professor data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onCourseSelected(String courseId) async {
    setState(() {
      _selectedCourseId = courseId;
    });

    final schedule = await _firestoreService.fetchSchedule(courseId);
    if (schedule != null) {
      setState(() {
        _selectedScheduleId = schedule['id'];
        _scheduleInfo = '${schedule['day']} | ${schedule['startTime']} - ${schedule['endTime']}';
      });

      final semesterName = await _firestoreService.fetchSemesterName(schedule['semesterId']);
      setState(() {
        _semesterName = semesterName;
      });
    }
  }

  Future<void> _startAttendanceSession() async {
    if (_selectedCourseId == null || _selectedScheduleId == null) {
      _showSnackBar('Please select a course first', Colors.red);
      return;
    }

    // Check Bluetooth permissions
    final hasPermission = await _bleService.checkBluetoothPermissions();
    if (!hasPermission) {
      _showSnackBar('Bluetooth permissions are required', Colors.red);
      return;
    }

    // Check if Bluetooth is available
    final isAvailable = await _bleService.isBluetoothAvailable();
    if (!isAvailable) {
      _showSnackBar('Bluetooth is not available or enabled', Colors.red);
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Check for existing active session
    final activeUUID = await _firestoreService.checkExistingActiveSession(
      _selectedCourseId!,
      _selectedScheduleId!,
      today,
    );

    if (activeUUID != null) {
      _showCloseActiveSessionDialog(activeUUID, today);
      return;
    }

    _createNewSession(today);
  }

  void _showCloseActiveSessionDialog(String activeUUID, String date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Session Found'),
        content: const Text(
          'An attendance session is already active. Do you want to close it and start a new one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Current'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.closeSession(
                _selectedCourseId!,
                _selectedScheduleId!,
                date,
                activeUUID,
              );
              _showSnackBar('Previous session closed', Colors.green);
              _createNewSession(date);
            },
            child: const Text('Close & Start New'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewSession(String date) async {
    final uuid = _uuid.v4();

    setState(() {
      _advertisedUUID = uuid;
      _activeSessionUUID = uuid;
      _isAdvertising = true;
    });

    // Write to Firestore
    await _firestoreService.writeAttendanceSession(
      _selectedCourseId!,
      _selectedScheduleId!,
      date,
      uuid,
    );

    // Start BLE advertising
    await _bleService.startAdvertising(uuid);

    _showSnackBar('Attendance session started', Colors.green);
  }

  Future<void> _stopAttendanceSession() async {
    if (_activeSessionUUID == null) return;

    setState(() {
      _isAdvertising = false;
    });

    // Stop BLE advertising
    await _bleService.stopAdvertising();

    // Update Firestore
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _firestoreService.updateSessionStatus(
      _selectedCourseId!,
      _selectedScheduleId!,
      today,
      _activeSessionUUID!,
    );

    _showSnackBar('Attendance session stopped', Colors.orange);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Control'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_professorName != null)
                    Text(
                      'Welcome, $_professorName',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  const SizedBox(height: 24),
                  
                  // Course Dropdown
                  if (_courses.isNotEmpty) ...[
                    const Text(
                      'Select Course:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _courses.map((course) {
                        return DropdownMenuItem<String>(
                          value: course['id'],
                          child: Text(course['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _onCourseSelected(value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Schedule Info
                  if (_semesterName != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semester: $_semesterName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_scheduleInfo != null)
                              Text(
                                'Schedule: $_scheduleInfo',
                                style: const TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Bluetooth Animation
                  if (_isAdvertising)
                    SizedBox(
                      height: 200,
                      child: Lottie.asset(
                        'assets/animations/bluetooth_anim.json',
                        repeat: true,
                      ),
                    ),

                  // UUID Display
                  if (_advertisedUUID != null && _isAdvertising)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📡 Advertising UUID:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _advertisedUUID!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Control Buttons
                  ElevatedButton.icon(
                    onPressed: _isAdvertising ? null : _startAttendanceSession,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Attendance Session'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isAdvertising ? _stopAttendanceSession : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Attendance Session'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
