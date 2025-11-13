import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_advertiser.dart';

class BleService {
  // Check and request Bluetooth permissions
  Future<bool> checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.locationWhenInUse,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return false;
  }

  // Check if Bluetooth is supported and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        return false;
      }

      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      print('Bluetooth check error: $e');
      return false;
    }
  }

  // Start advertising using platform channel
  Future<void> startAdvertising(String uuid) async {
    print('Start advertising UUID: $uuid');
    
    if (Platform.isAndroid) {
      final success = await BleAdvertiser.startAdvertising(uuid);
      if (success) {
        print('✅ Android BLE advertising started');
      } else {
        print('❌ Android BLE advertising failed');
      }
    } else if (Platform.isIOS) {
      // iOS BLE advertising via platform channel (implemented in BleAdvertiser)
      final success = await BleAdvertiser.startAdvertising(uuid);
      if (success) {
        print('✅ iOS BLE advertising started');
      } else {
        print('❌ iOS BLE advertising failed');
      }
    }
  }

  // Stop advertising
  Future<void> stopAdvertising() async {
    print('Stop advertising');
    
    if (Platform.isAndroid) {
      await BleAdvertiser.stopAdvertising();
    } else if (Platform.isIOS) {
      await BleAdvertiser.stopAdvertising();
    }
  }
}
