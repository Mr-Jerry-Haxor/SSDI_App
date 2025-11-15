import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class AttendanceViewScreen extends StatefulWidget {
  final String professorId;

  const AttendanceViewScreen({super.key, required this.professorId});

  @override
  State<AttendanceViewScreen> createState() => _AttendanceViewScreenState();
}

class _AttendanceViewScreenState extends State<AttendanceViewScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  String? _selectedScheduleId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _studentAttendanceList = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);

    try {
      // Get professor document
      final professorDoc = await _db.collection('Professor').doc(widget.professorId).get();
      
      if (!professorDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final courseIds = List<String>.from(professorDoc.data()?['CourseIds'] ?? []);
      final List<Map<String, dynamic>> courses = [];

      for (var courseId in courseIds) {
        final courseDoc = await _db.collection('Courses').doc(courseId).get();
        if (courseDoc.exists) {
          final courseData = courseDoc.data()!;
          courses.add({
            'id': courseDoc.id,
            'name': courseData['courseName'] ?? courseId,
            'code': courseData['courseCode'] ?? courseId,
          });
        }
      }

      setState(() {
        _courses = courses;
        _isLoading = false;
        if (_courses.isNotEmpty) {
          _selectedCourseId = _courses[0]['id'];
          _loadSchedule();
        }
      });
    } catch (e) {
      AppLogger.error('Error loading courses', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchedule() async {
    if (_selectedCourseId == null) return;

    try {
      final scheduleSnapshot = await _db
          .collection('Courses')
          .doc(_selectedCourseId)
          .collection('Schedule')
          .limit(1)
          .get();

      if (scheduleSnapshot.docs.isNotEmpty) {
        setState(() {
          _selectedScheduleId = scheduleSnapshot.docs.first.id;
        });
        _loadAttendanceData();
      }
    } catch (e) {
      AppLogger.error('Error loading schedule', e);
    }
  }

  Future<void> _loadAttendanceData() async {
    if (_selectedCourseId == null || _selectedScheduleId == null) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendanceDoc = await _db
          .collection('Courses')
          .doc(_selectedCourseId)
          .collection('Schedule')
          .doc(_selectedScheduleId)
          .collection('Attendance')
          .doc(dateStr)
          .get();

      if (!attendanceDoc.exists) {
        setState(() {
          _studentAttendanceList = [];
          _isLoading = false;
        });
        return;
      }

      final data = attendanceDoc.data()!;
      final studentAttendanceList = <Map<String, dynamic>>[];

      // Get enrolled students
      final scheduleDoc = await _db
          .collection('Courses')
          .doc(_selectedCourseId)
          .collection('Schedule')
          .doc(_selectedScheduleId)
          .get();

      final enrolledStudents = List<String>.from(
        scheduleDoc.data()?['StudentsEnrolled'] ?? []
      );

      // Parse attendance data for each session UUID
      for (var sessionEntry in data.entries) {
        final sessionUUID = sessionEntry.key;
        final sessionData = sessionEntry.value as Map<String, dynamic>;
        
        if (sessionData.containsKey('StudentAttendanceData')) {
          final attendanceData = sessionData['StudentAttendanceData'] as Map<String, dynamic>;
          
          for (var studentId in enrolledStudents) {
            if (attendanceData.containsKey(studentId)) {
              final studentData = attendanceData[studentId] as Map<String, dynamic>;
              
              // Get student details
              final studentDoc = await _db.collection('student').doc(studentId).get();
              final studentInfo = studentDoc.data();

              studentAttendanceList.add({
                'studentId': studentId,
                'firstName': studentInfo?['FirstName'] ?? 'Unknown',
                'lastName': studentInfo?['LastName'] ?? '',
                'email': studentInfo?['Email'] ?? '',
                'status': studentData['status'] ?? 'Unknown',
                'timestamp': studentData['timestamp'],
                'sessionUUID': sessionUUID,
              });
            }
          }
        }
      }

      // Add absent students
      final presentStudentIds = studentAttendanceList.map((s) => s['studentId']).toSet();
      for (var studentId in enrolledStudents) {
        if (!presentStudentIds.contains(studentId)) {
          final studentDoc = await _db.collection('student').doc(studentId).get();
          final studentInfo = studentDoc.data();

          studentAttendanceList.add({
            'studentId': studentId,
            'firstName': studentInfo?['FirstName'] ?? 'Unknown',
            'lastName': studentInfo?['LastName'] ?? '',
            'email': studentInfo?['Email'] ?? '',
            'status': 'Absent',
            'timestamp': null,
            'sessionUUID': null,
          });
        }
      }

      // Sort by name
      studentAttendanceList.sort((a, b) {
        final nameA = '${a['firstName']} ${a['lastName']}';
        final nameB = '${b['firstName']} ${b['lastName']}';
        return nameA.compareTo(nameB);
      });

      setState(() {
        _studentAttendanceList = studentAttendanceList;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading attendance data', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendanceData();
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '--';
    
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return DateFormat('hh:mm a').format(dateTime);
      }
      return '--';
    } catch (e) {
      return '--';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatisticsCard() {
    final totalStudents = _studentAttendanceList.length;
    final presentCount = _studentAttendanceList
        .where((s) => s['status'].toString().toLowerCase() == 'present')
        .length;
    final absentCount = totalStudents - presentCount;
    final attendanceRate = totalStudents > 0 
        ? (presentCount / totalStudents * 100).toStringAsFixed(1) 
        : '0.0';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Attendance Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', totalStudents.toString(), Colors.blue),
                _buildStatItem('Present', presentCount.toString(), Colors.green),
                _buildStatItem('Absent', absentCount.toString(), Colors.red),
                _buildStatItem('Rate', '$attendanceRate%', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAttendanceData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Course Selection
                if (_courses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _courses.map((course) {
                        return DropdownMenuItem<String>(
                          value: course['id'],
                          child: Text('${course['code']} - ${course['name']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCourseId = value;
                          });
                          _loadSchedule();
                        }
                      },
                    ),
                  ),

                // Date Selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Previous Day',
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          });
                          _loadAttendanceData();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: 'Next Day',
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          });
                          _loadAttendanceData();
                        },
                      ),
                    ],
                  ),
                ),

                // Statistics Card
                if (_studentAttendanceList.isNotEmpty)
                  _buildStatisticsCard(),

                // Student List
                Expanded(
                  child: _studentAttendanceList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance data for this date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _studentAttendanceList.length,
                          itemBuilder: (context, index) {
                            final student = _studentAttendanceList[index];
                            final status = student['status'] as String;
                            final statusColor = _getStatusColor(status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withValues(alpha: 0.2),
                                  child: Icon(
                                    status.toLowerCase() == 'present'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: statusColor,
                                  ),
                                ),
                                title: Text(
                                  '${student['firstName']} ${student['lastName']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['email'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (status.toLowerCase() == 'present')
                                      Text(
                                        'Time: ${_formatTimestamp(student['timestamp'])}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
