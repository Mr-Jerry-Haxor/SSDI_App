import 'package:flutter/material.dart';
import '../services/admin_crud_service.dart';

class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() => _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  final _crudService = AdminCRUDService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final name = (student['name'] ?? '').toLowerCase();
          final email = (student['email'] ?? '').toLowerCase();
          final studentId = (student['studentId'] ?? '').toLowerCase();
          final department = (student['department'] ?? '').toLowerCase();
          return name.contains(query) ||
              email.contains(query) ||
              studentId.contains(query) ||
              department.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    final students = await _crudService.fetchAllStudents();
    setState(() {
      _students = students;
      _filteredStudents = students;
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        elevation: 2,
        actions: [
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Chip(
                  label: Text(
                    '${_filteredStudents.length} Students',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: colorScheme.primaryContainer,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
        backgroundColor: colorScheme.primary,
      ),
      body: Column(
        children: [
          // Search Bar
          if (_students.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.surface,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
            ),
          
          // List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'No students found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a student',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : _filteredStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text(
                                  'No matching students',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadStudents,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                final studentId = student['studentId'] ?? '';
                                final name = student['name'] ?? 'Unknown';
                                final email = student['email'] ?? '';
                                final department = student['department'] ?? '';
                                final enrolledCourses = student['enrolledCourses'] ?? [];
                                final coursesCount = enrolledCourses is List ? enrolledCourses.length : 0;
                                
                                final avatarText = name.isNotEmpty 
                                    ? name.substring(0, 1).toUpperCase()
                                    : 'S';
                                
                                final colors = [
                                  Colors.blue,
                                  Colors.green,
                                  Colors.purple,
                                  Colors.orange,
                                  Colors.teal,
                                ];
                                final avatarColor = colors[index % colors.length];
                                
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showAddEditDialog(student: student),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Hero(
                                            tag: 'student_${student['id']}',
                                            child: CircleAvatar(
                                              radius: 32,
                                              backgroundColor: avatarColor,
                                              child: Text(
                                                avatarText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        email,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'ID: $studentId',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                    ),
                                                    if (department.isNotEmpty) ...[
                                                      Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                                                      Text(
                                                        department,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                if (coursesCount > 0) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.primaryContainer,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '$coursesCount ${coursesCount == 1 ? "Course" : "Courses"}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: colorScheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton(
                                            icon: const Icon(Icons.more_vert),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 20),
                                                    SizedBox(width: 12),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                                    SizedBox(width: 12),
                                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showAddEditDialog(student: student);
                                              } else if (value == 'delete') {
                                                _deleteStudent(student['id'], name);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
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
