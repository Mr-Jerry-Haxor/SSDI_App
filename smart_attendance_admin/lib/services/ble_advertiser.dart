import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class BleAdvertiser {
  static const MethodChannel _channel = MethodChannel('smart_attendance/ble_advertiser');

  // Start BLE advertising
  static Future<bool> startAdvertising(String uuid) async {
    try {
      final bool result = await _channel.invokeMethod('startAdvertising', {'uuid': uuid});
      return result;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to start advertising", e);
      return false;
    }
  }

  // Stop BLE advertising
  static Future<bool> stopAdvertising() async {
    try {
      final bool result = await _channel.invokeMethod('stopAdvertising');
      return result;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to stop advertising", e);
      return false;
    }
  }

  // Check if advertising is supported
  static Future<bool> isAdvertisingSupported() async {
    try {
      final bool result = await _channel.invokeMethod('isAdvertisingSupported');
      return result;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to check advertising support", e);
      return false;
    }
  }
}
