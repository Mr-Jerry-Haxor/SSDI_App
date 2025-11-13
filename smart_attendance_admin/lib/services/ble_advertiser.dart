import 'dart:async';
import 'package:flutter/services.dart';

class BleAdvertiser {
  static const MethodChannel _channel = MethodChannel('smart_attendance/ble_advertiser');

  // Start BLE advertising
  static Future<bool> startAdvertising(String uuid) async {
    try {
      final bool result = await _channel.invokeMethod('startAdvertising', {'uuid': uuid});
      return result;
    } on PlatformException catch (e) {
      print("Failed to start advertising: ${e.message}");
      return false;
    }
  }

  // Stop BLE advertising
  static Future<bool> stopAdvertising() async {
    try {
      final bool result = await _channel.invokeMethod('stopAdvertising');
      return result;
    } on PlatformException catch (e) {
      print("Failed to stop advertising: ${e.message}");
      return false;
    }
  }

  // Check if advertising is supported
  static Future<bool> isAdvertisingSupported() async {
    try {
      final bool result = await _channel.invokeMethod('isAdvertisingSupported');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check advertising support: ${e.message}");
      return false;
    }
  }
}
