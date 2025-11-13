import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class BleService {
  bool _isScanning = false;
  Function(String)? onUuidDetected;

  bool get isScanning => _isScanning;

  // Check and request Bluetooth permissions
  Future<bool> checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return false;
  }

  // Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        return false;
      }

      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      AppLogger.error('Bluetooth check error', e);
      return false;
    }
  }

  // Start BLE scanning
  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _isScanning = true;

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final serviceUuids = result.advertisementData.serviceUuids;
          if (serviceUuids.isNotEmpty) {
            final uuid = serviceUuids.first.toString();
            AppLogger.info('Detected UUID: $uuid');
            onUuidDetected?.call(uuid);
          }
        }
      });

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
    } catch (e) {
      AppLogger.error('Scan error', e);
      _isScanning = false;
    }
  }

  // Stop BLE scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
    } catch (e) {
      AppLogger.error('Stop scan error', e);
    }
  }
}
