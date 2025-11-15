import 'package:flutter/material.dart';
import '../services/admin_crud_service.dart';

class SchedulesManagementScreen extends StatefulWidget {
  const SchedulesManagementScreen({super.key});

  @override
  State<SchedulesManagementScreen> createState() => _SchedulesManagementScreenState();
}

class _SchedulesManagementScreenState extends State<SchedulesManagementScreen> {
  final _crudService = AdminCRUDService();
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _schedules = [];
  String? _selectedCourseId;
  bool _isLoadingCourses = true;
  bool _isLoadingSchedules = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    final courses = await _crudService.fetchAllCourses();
    setState(() {
      _courses = courses;
      _isLoadingCourses = false;
    });
  }

  Future<void> _loadSchedules() async {
    if (_selectedCourseId == null) return;

    setState(() {
      _isLoadingSchedules = true;
    });

    final schedules = await _crudService.fetchCourseSchedules(_selectedCourseId!);
    setState(() {
      _schedules = schedules;
      _isLoadingSchedules = false;
    });
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? schedule}) async {
    if (_selectedCourseId == null) return;

    final dayController = TextEditingController(text: schedule?['Day'] ?? '');
    final startTimeController = TextEditingController(text: schedule?['StartTime'] ?? '');
    final endTimeController = TextEditingController(text: schedule?['EndTime'] ?? '');
    final semesterController = TextEditingController(text: schedule?['Semester'] ?? '');
    final roomController = TextEditingController(text: schedule?['RoomNumber'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule == null ? 'Add Schedule' : 'Edit Schedule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dayController,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  hintText: 'Monday, Tuesday, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: '09:00 AM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: '10:30 AM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: semesterController,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dayController.text.isEmpty || startTimeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final scheduleData = {
                'Day': dayController.text,
                'StartTime': startTimeController.text,
                'EndTime': endTimeController.text,
                'Semester': semesterController.text,
                'RoomNumber': roomController.text,
              };

              bool success;
              if (schedule == null) {
                success = await _crudService.addCourseSchedule(_selectedCourseId!, scheduleData);
              } else {
                success = await _crudService.updateCourseSchedule(_selectedCourseId!, schedule['id'], scheduleData);
              }

              if (!context.mounted) return;
              Navigator.pop(context, success);
            },
            child: Text(schedule == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadSchedules();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(schedule == null
              ? 'Schedule added successfully'
              : 'Schedule updated successfully'),
        ),
      );
    }
  }

  Future<void> _deleteSchedule(String scheduleId, String day) async {
    if (_selectedCourseId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the schedule for "$day"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _crudService.deleteCourseSchedule(_selectedCourseId!, scheduleId);
      if (!mounted) return;
      if (success) {
        await _loadSchedules();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete schedule')),
        );
      }
    }
  }

  String _getDayAbbreviation(String day) {
    if (day.length >= 3) {
      return day.substring(0, 3).toUpperCase();
    }
    return day.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedules'),
        elevation: 2,
      ),
      floatingActionButton: _selectedCourseId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Schedule'),
            )
          : null,
      body: _isLoadingCourses
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Course',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCourseId,
                        decoration: const InputDecoration(
                          hintText: 'Choose a course',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course['id'],
                            child: Text(
                              '${course['CourseCode']} - ${course['CourseName']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCourseId = value;
                            _schedules = [];
                          });
                          if (value != null) {
                            _loadSchedules();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedCourseId == null
                      ? const Center(
                          child: Text(
                            'Please select a course to view schedules',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : _isLoadingSchedules
                          ? const Center(child: CircularProgressIndicator())
                          : _schedules.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No schedules found\nTap + to add a schedule',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadSchedules,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _schedules.length,
                                    itemBuilder: (context, index) {
                                      final schedule = _schedules[index];
                                      final day = schedule['Day'] ?? '';
                                      
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.blue,
                                            child: Text(
                                              _getDayAbbreviation(day),
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                          title: Text(
                                            day,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            '${schedule['StartTime'] ?? ''} - ${schedule['EndTime'] ?? ''}\nRoom: ${schedule['RoomNumber'] ?? ''} • ${schedule['Semester'] ?? ''}',
                                          ),
                                          isThreeLine: true,
                                          trailing: PopupMenuButton(
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showAddEditDialog(schedule: schedule);
                                              } else if (value == 'delete') {
                                                _deleteSchedule(schedule['id'], day);
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
    );
  }
}
