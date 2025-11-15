import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class MainScreen extends StatefulWidget {
  final String studentId;

  const MainScreen({super.key, required this.studentId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final _bleService = BleService();
  final _firestoreService = FirestoreService();

  String _scanStatus = 'Initializing...';
  String? _detectedUUID;
  String? _courseInfo;
  bool _isScanning = false;
  bool _canLogAttendance = false;
  bool _hasLoggedAttendance = false;
  bool _isLoggingAttendance = false;

  String? _activeSessionUUID;
  String? _courseId;
  String? _scheduleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bleService.onUuidDetected = _onUuidDetected;
    Future.delayed(const Duration(milliseconds: 500), _checkPermissionsAndStartScan);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Resume scanning when app comes to foreground
      if (!_isScanning && !_hasLoggedAttendance) {
        _checkPermissionsAndStartScan();
      }
    } else if (state == AppLifecycleState.paused) {
      // Stop scanning when app goes to background to save battery
      _bleService.stopScan();
    }
  }

  Future<void> _checkPermissionsAndStartScan() async {
    try {
      final hasPermission = await _bleService.checkBluetoothPermissions();
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _scanStatus = '📱 Bluetooth and Location permissions required';
            _isScanning = false;
          });
        }
        return;
      }

      final isAvailable = await _bleService.isBluetoothAvailable();
      if (!isAvailable) {
        if (mounted) {
          setState(() {
            _scanStatus = '📡 Bluetooth is turned off or unavailable';
            _isScanning = false;
          });
        }
        return;
      }

      _startScan();
    } catch (e) {
      AppLogger.error('Error checking permissions', e);
      if (mounted) {
        setState(() {
          _scanStatus = '❌ Error checking permissions';
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _scanStatus = 'Requesting permissions...';
    });

    try {
      final hasPermission = await _bleService.checkBluetoothPermissions();
      
      if (hasPermission && mounted) {
        setState(() {
          _scanStatus = '✅ Permissions granted! Starting scan...';
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) await _checkPermissionsAndStartScan();
      } else if (mounted) {
        setState(() {
          _scanStatus = '❌ Permissions denied. Please enable Bluetooth and Location in Settings.';
        });
        _showSnackBar(
          'Please enable Bluetooth and Location permissions in your device settings',
          Colors.orange,
        );
      }
    } catch (e) {
      AppLogger.error('Error requesting permissions', e);
      if (mounted) {
        setState(() {
          _scanStatus = '❌ Error requesting permissions';
        });
      }
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    if (mounted) {
      setState(() {
        _isScanning = true;
        _scanStatus = '🔍 Scanning for nearby attendance sessions...';
        _detectedUUID = null;
        _courseInfo = null;
        _canLogAttendance = false;
      });
    }

    try {
      await _bleService.startScan();
      AppLogger.info('BLE scanning started successfully');
    } catch (e) {
      AppLogger.error('Error starting BLE scan', e);
      if (mounted) {
        setState(() {
          _scanStatus = '❌ Error starting scan. Please try again.';
          _isScanning = false;
        });
      }
    }
  }

  void _onUuidDetected(String uuid) {
    if (_detectedUUID == uuid) return; // Already processed this UUID

    AppLogger.info('UUID detected: $uuid');
    if (mounted) {
      setState(() {
        _detectedUUID = uuid;
        _scanStatus = '📡 Session detected! Verifying...';
      });
    }

    _checkActiveSession(uuid);
  }

  Future<void> _checkActiveSession(String uuid) async {
    try {
      final sessionData = await _firestoreService.checkActiveSessionInFirestore(uuid);

      if (sessionData != null && mounted) {
        setState(() {
          _activeSessionUUID = sessionData['sessionUUID'];
          _courseId = sessionData['courseId'];
          _scheduleId = sessionData['scheduleId'];
          _scanStatus = '✅ Active attendance session found!';
        });

        await _bleService.stopScan();
        if (mounted) {
          setState(() => _isScanning = false);
          await _verifyEnrollment();
        }
      } else if (mounted) {
        // No active session for this UUID, continue scanning
        setState(() {
          _scanStatus = '⚠️ No active session for this beacon. Keep scanning...';
        });
      }
    } catch (e) {
      AppLogger.error('Error checking active session', e);
      if (mounted) {
        setState(() {
          _scanStatus = '❌ Error verifying session';
        });
      }
    }
  }

  Future<void> _verifyEnrollment() async {
    if (_courseId == null || _scheduleId == null) return;

    try {
      final isEnrolled = await _firestoreService.verifyStudentEnrollment(
        _courseId!,
        _scheduleId!,
        widget.studentId,
      );

      if (!mounted) return;

      setState(() {
        if (isEnrolled) {
          _courseInfo = '✅ You are enrolled in this course\nTap below to log attendance';
          _canLogAttendance = !_hasLoggedAttendance;
        } else {
          _courseInfo = '⚠️ You are NOT enrolled in this course';
          _canLogAttendance = false;
        }
      });
    } catch (e) {
      AppLogger.error('Error verifying enrollment', e);
      if (mounted) {
        setState(() {
          _courseInfo = '❌ Error verifying enrollment';
          _canLogAttendance = false;
        });
      }
    }
  }

  Future<void> _logAttendance() async {
    if (_courseId == null || _scheduleId == null || _activeSessionUUID == null) {
      _showSnackBar('No active session available', Colors.red);
      return;
    }

    if (_hasLoggedAttendance) {
      _showSnackBar('You have already logged attendance for this session', Colors.orange);
      return;
    }

    if (_isLoggingAttendance) return; // Prevent double submission

    setState(() {
      _isLoggingAttendance = true;
      _scanStatus = 'Logging attendance...';
    });

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final success = await _firestoreService.logAttendance(
        _courseId!,
        _scheduleId!,
        today,
        _activeSessionUUID!,
        widget.studentId,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _hasLoggedAttendance = true;
          _canLogAttendance = false;
          _scanStatus = '🎉 Attendance logged successfully!';
          _isLoggingAttendance = false;
        });
        _showSnackBar('✅ Your attendance has been recorded', Colors.green);
        
        // Reset after 3 seconds to allow scanning for another session
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_isScanning) {
            setState(() {
              _hasLoggedAttendance = false;
              _detectedUUID = null;
              _courseInfo = null;
              _activeSessionUUID = null;
              _courseId = null;
              _scheduleId = null;
            });
            _checkPermissionsAndStartScan();
          }
        });
      } else {
        setState(() {
          _scanStatus = '❌ Failed to log attendance';
          _isLoggingAttendance = false;
        });
        _showSnackBar('Failed to log attendance. Please try again.', Colors.red);
      }
    } catch (e) {
      AppLogger.error('Error logging attendance', e);
      if (mounted) {
        setState(() {
          _scanStatus = '❌ Error logging attendance';
          _isLoggingAttendance = false;
        });
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : 
              color == Colors.red ? Icons.error : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bleService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isScanning ? null : () {
              setState(() {
                _detectedUUID = null;
                _courseInfo = null;
                _canLogAttendance = false;
                _hasLoggedAttendance = false;
              });
              _checkPermissionsAndStartScan();
            },
            tooltip: 'Refresh scan',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                authService.logout();
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!_isScanning) {
            setState(() {
              _detectedUUID = null;
              _courseInfo = null;
              _canLogAttendance = false;
              _hasLoggedAttendance = false;
            });
            await _checkPermissionsAndStartScan();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        _isScanning ? Icons.bluetooth_searching :
                        _canLogAttendance ? Icons.check_circle_outline :
                        Icons.bluetooth_disabled,
                        size: 48,
                        color: _isScanning ? colorScheme.primary :
                              _canLogAttendance ? Colors.green :
                              Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _scanStatus,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_scanStatus.contains('permission') || _scanStatus.contains('turned off'))
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: ElevatedButton.icon(
                            onPressed: _requestPermissions,
                            icon: const Icon(Icons.settings),
                            label: const Text('Grant Permissions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      if (_isScanning)
                        const Padding(
                          padding: EdgeInsets.only(top: 20.0),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // UUID Card
              if (_detectedUUID != null) ...[
                Card(
                  color: Colors.blue.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bluetooth_connected, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Detected Session',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            _detectedUUID!,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Course Info Card
              if (_courseInfo != null) ...[
                Card(
                  color: _canLogAttendance ? Colors.green.shade50 : Colors.orange.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _canLogAttendance ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          _canLogAttendance ? Icons.school : Icons.warning_amber_rounded,
                          size: 40,
                          color: _canLogAttendance ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _courseInfo!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _canLogAttendance ? Colors.green.shade900 : Colors.orange.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Log Attendance Button
              ElevatedButton.icon(
                onPressed: _canLogAttendance && !_hasLoggedAttendance && !_isLoggingAttendance 
                    ? _logAttendance 
                    : null,
                icon: _isLoggingAttendance 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(
                        _hasLoggedAttendance ? Icons.check_circle : Icons.check_circle_rounded,
                        size: 24,
                      ),
                label: Text(
                  _hasLoggedAttendance 
                      ? 'Attendance Logged' 
                      : _isLoggingAttendance 
                          ? 'Logging...' 
                          : 'Log Attendance',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _canLogAttendance ? Colors.green : null,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Help Card
              Card(
                color: Colors.blue.shade50,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'How it works',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem('Enable Bluetooth and Location permissions'),
                      _buildHelpItem('Stay near the attendance beacon in class'),
                      _buildHelpItem('App will automatically detect active sessions'),
                      _buildHelpItem('Tap "Log Attendance" when prompted'),
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

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
