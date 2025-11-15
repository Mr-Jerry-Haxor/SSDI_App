import 'package:flutter/material.dart';
import '../services/admin_crud_service.dart';

class SemestersManagementScreen extends StatefulWidget {
  const SemestersManagementScreen({super.key});

  @override
  State<SemestersManagementScreen> createState() => _SemestersManagementScreenState();
}

class _SemestersManagementScreenState extends State<SemestersManagementScreen> {
  final _crudService = AdminCRUDService();
  List<Map<String, dynamic>> _semesters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() {
      _isLoading = true;
    });

    final semesters = await _crudService.fetchAllSemesters();
    setState(() {
      _semesters = semesters;
      _isLoading = false;
    });
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? semester}) async {
    final nameController = TextEditingController(text: semester?['Name'] ?? '');
    final yearController = TextEditingController(
        text: semester != null ? semester['Year'].toString() : '');
    final startDateController = TextEditingController(text: semester?['StartDate'] ?? '');
    final endDateController = TextEditingController(text: semester?['EndDate'] ?? '');
    final statusController = TextEditingController(text: semester?['Status'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(semester == null ? 'Add Semester' : 'Edit Semester'),
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
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: startDateController,
                decoration: const InputDecoration(
                  labelText: 'Start Date (ISO format)',
                  hintText: '2024-01-15',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endDateController,
                decoration: const InputDecoration(
                  labelText: 'End Date (ISO format)',
                  hintText: '2024-05-15',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  hintText: 'Active, Upcoming, Completed',
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
              if (nameController.text.isEmpty || yearController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final semesterData = {
                'Name': nameController.text,
                'Year': int.tryParse(yearController.text) ?? 0,
                'StartDate': startDateController.text,
                'EndDate': endDateController.text,
                'Status': statusController.text,
              };

              bool success;
              if (semester == null) {
                success = await _crudService.addSemester(semesterData);
              } else {
                success = await _crudService.updateSemester(semester['id'], semesterData);
              }

              if (!context.mounted) return;
              Navigator.pop(context, success);
            },
            child: Text(semester == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadSemesters();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(semester == null
              ? 'Semester added successfully'
              : 'Semester updated successfully'),
        ),
      );
    }
  }

  Future<void> _deleteSemester(String semesterId, String semesterName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$semesterName"?'),
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
      final success = await _crudService.deleteSemester(semesterId);
      if (!mounted) return;
      if (success) {
        await _loadSemesters();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semester deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete semester')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Semesters'),
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Semester'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _semesters.isEmpty
              ? const Center(
                  child: Text(
                    'No semesters found\nTap + to add a semester',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSemesters,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _semesters.length,
                    itemBuilder: (context, index) {
                      final semester = _semesters[index];
                      final name = semester['Name'] ?? '';
                      final avatarText = name.length >= 2 ? name.substring(0, 2).toUpperCase() : (name.isNotEmpty ? name[0].toUpperCase() : 'S');
                      
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
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Year: ${semester['Year'] ?? ''} • ${semester['Status'] ?? ''}\n${semester['StartDate'] ?? ''} - ${semester['EndDate'] ?? ''}',
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
                                _showAddEditDialog(semester: semester);
                              } else if (value == 'delete') {
                                _deleteSemester(semester['id'], name);
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
