import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/ble_service.dart';
import '../utils/logger.dart';
import 'attendance_view_screen.dart';

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
      AppLogger.error('Error loading professor data', e);
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Control'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View Attendance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceViewScreen(professorId: widget.professorId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Admin Settings',
            onPressed: () {
              Navigator.of(context).pushNamed('/admin_settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading professor data...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfessorData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_professorName != null)
                      Card(
                        elevation: 0,
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: colorScheme.primary,
                                child: const Icon(Icons.person, size: 36, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome back,',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      _professorName!,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Course Selection Card
                    if (_courses.isNotEmpty) ...[
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.school, color: colorScheme.primary),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Select Course',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCourseId,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                isExpanded: true,
                                items: _courses.map((course) {
                                    return DropdownMenuItem<String>(
                                      value: course['id'],
                                      child: Text(
                                        course['name'],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      _onCourseSelected(value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Schedule Info Card
                    if (_semesterName != null)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: colorScheme.primary),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Schedule Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.calendar_month, 'Semester', _semesterName!),
                              if (_scheduleInfo != null) ...[
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.schedule, 'Schedule', _scheduleInfo!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Session Status Card
                    if (_isAdvertising)
                      Card(
                        elevation: 4,
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.wifi_tethering,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Session Active',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          'Students can now mark attendance',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Bluetooth Animation
                              SizedBox(
                                height: 180,
                                child: Lottie.asset(
                                  'assets/animations/bluetooth_anim.json',
                                  repeat: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // UUID Display
                              if (_advertisedUUID != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.qr_code, color: Colors.green.shade700),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Session UUID:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        _advertisedUUID!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (!_isAdvertising && _selectedCourseId != null)
                      Card(
                        elevation: 2,
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.pause_circle_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Active Session',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a session to enable attendance tracking',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Control Buttons
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isAdvertising
                          ? ElevatedButton.icon(
                              key: const ValueKey('stop'),
                              onPressed: _stopAttendanceSession,
                              icon: const Icon(Icons.stop_circle, size: 24),
                              label: const Text('Stop Session'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            )
                          : ElevatedButton.icon(
                              key: const ValueKey('start'),
                              onPressed: _selectedCourseId == null ? null : _startAttendanceSession,
                              icon: const Icon(Icons.play_circle, size: 24),
                              label: const Text('Start Attendance Session'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                    ),
                    
                    if (_selectedCourseId == null && !_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No courses available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please contact admin to assign courses',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
