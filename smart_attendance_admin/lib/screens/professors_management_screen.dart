import 'package:flutter/material.dart';
import '../services/admin_crud_service.dart';

class ProfessorsManagementScreen extends StatefulWidget {
  const ProfessorsManagementScreen({super.key});

  @override
  State<ProfessorsManagementScreen> createState() => _ProfessorsManagementScreenState();
}

class _ProfessorsManagementScreenState extends State<ProfessorsManagementScreen> {
  final _crudService = AdminCRUDService();
  List<Map<String, dynamic>> _professors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessors();
  }

  Future<void> _loadProfessors() async {
    setState(() {
      _isLoading = true;
    });

    final professors = await _crudService.fetchAllProfessors();
    setState(() {
      _professors = professors;
      _isLoading = false;
    });
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? professor}) async {
    final nameController = TextEditingController(text: professor?['Name'] ?? '');
    final emailController = TextEditingController(text: professor?['email'] ?? '');
    final deptController = TextEditingController(text: professor?['Department'] ?? '');
    final phoneController = TextEditingController(text: professor?['phoneNumber'] ?? '');
    final coursesController = TextEditingController(
        text: professor != null && professor['coursesTaught'] is List
            ? (professor['coursesTaught'] as List).join(', ')
            : '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(professor == null ? 'Add Professor' : 'Edit Professor'),
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
                controller: deptController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: coursesController,
                decoration: const InputDecoration(
                  labelText: 'Courses Taught (comma separated)',
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
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final professorData = {
                'Name': nameController.text,
                'email': emailController.text,
                'Department': deptController.text,
                'phoneNumber': phoneController.text,
                'coursesTaught': coursesController.text.isEmpty
                    ? []
                    : coursesController.text.split(',').map((e) => e.trim()).toList(),
              };

              bool success;
              if (professor == null) {
                success = await _crudService.addProfessor(professorData);
              } else {
                success = await _crudService.updateProfessor(professor['id'], professorData);
              }

              if (!context.mounted) return;
              Navigator.pop(context, success);
            },
            child: Text(professor == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadProfessors();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(professor == null
              ? 'Professor added successfully'
              : 'Professor updated successfully'),
        ),
      );
    }
  }

  Future<void> _deleteProfessor(String professorId, String professorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$professorName"?'),
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
      final success = await _crudService.deleteProfessor(professorId);
      if (!mounted) return;
      if (success) {
        await _loadProfessors();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professor deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete professor')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Professors'),
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Professor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _professors.isEmpty
              ? const Center(
                  child: Text(
                    'No professors found\nTap + to add a professor',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfessors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _professors.length,
                    itemBuilder: (context, index) {
                      final professor = _professors[index];
                      final name = professor['Name'] ?? '';
                      final avatarText = name.length >= 2 ? name.substring(0, 2).toUpperCase() : (name.isNotEmpty ? name[0].toUpperCase() : 'P');
                      
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
                            '${professor['email'] ?? ''}\n${professor['Department'] ?? ''} • ${professor['phoneNumber'] ?? ''}',
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
                                _showAddEditDialog(professor: professor);
                              } else if (value == 'delete') {
                                _deleteProfessor(professor['id'], name);
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
