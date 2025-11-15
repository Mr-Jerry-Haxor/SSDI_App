import 'package:flutter/material.dart';
import '../services/admin_crud_service.dart';

class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() => _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  final _crudService = AdminCRUDService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    final students = await _crudService.fetchAllStudents();
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? student}) async {
    final nameController = TextEditingController(text: student?['name'] ?? '');
    final emailController = TextEditingController(text: student?['email'] ?? '');
    final studentIdController = TextEditingController(text: student?['studentId'] ?? '');
    final deptController = TextEditingController(text: student?['department'] ?? '');
    final coursesController = TextEditingController(
        text: student != null && student['enrolledCourses'] is List
            ? (student['enrolledCourses'] as List).join(', ')
            : '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student == null ? 'Add Student' : 'Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deptController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: coursesController,
                decoration: const InputDecoration(
                  labelText: 'Enrolled Courses (comma separated)',
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
              if (nameController.text.isEmpty || emailController.text.isEmpty || studentIdController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final studentData = {
                'name': nameController.text,
                'email': emailController.text,
                'studentId': studentIdController.text,
                'department': deptController.text,
                'enrolledCourses': coursesController.text.isEmpty
                    ? []
                    : coursesController.text.split(',').map((e) => e.trim()).toList(),
              };

              bool success;
              if (student == null) {
                // For new student, use the studentId as document ID
                success = await _crudService.addStudent(
                  studentIdController.text.trim(),
                  studentData,
                );
              } else {
                success = await _crudService.updateStudent(student['id'], studentData);
              }

              if (!context.mounted) return;
              Navigator.pop(context, success);
            },
            child: Text(student == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadStudents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(student == null
              ? 'Student added successfully'
              : 'Student updated successfully'),
        ),
      );
    }
  }

  Future<void> _deleteStudent(String studentId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$studentName"?'),
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
      final success = await _crudService.deleteStudent(studentId);
      if (!mounted) return;
      if (success) {
        await _loadStudents();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete student')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(
                  child: Text(
                    'No students found\nTap + to add a student',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStudents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final studentId = student['studentId'] ?? '';
                      final avatarText = studentId.length >= 2 ? studentId.substring(0, 2).toUpperCase() : (studentId.isNotEmpty ? studentId[0].toUpperCase() : 'S');
                      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              avatarText,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            student['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${student['email'] ?? ''}\n${student['department'] ?? ''} • ID: $studentId',
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
                                _showAddEditDialog(student: student);
                              } else if (value == 'delete') {
                                _deleteStudent(student['id'], student['name'] ?? '');
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
