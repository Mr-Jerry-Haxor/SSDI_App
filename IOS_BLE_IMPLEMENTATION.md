# iOS BLE Advertising Implementation Guide

## Overview
This guide explains how to implement BLE advertising for iOS in the Smart Attendance Admin app.

## iOS Native Code (Swift)

### 1. Create Swift BLE Advertiser

Create file: `smart_attendance_admin/ios/Runner/BleAdvertiser.swift`

```swift
import Flutter
import CoreBluetooth

class BleAdvertiser: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager?
    private var advertisingUUID: CBUUID?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising(uuidString: String) -> Bool {
        guard let uuid = UUID(uuidString: uuidString) else {
            print("Invalid UUID string")
            return false
        }
        
        advertisingUUID = CBUUID(nsuuid: uuid)
        
        if peripheralManager?.state == .poweredOn {
            let advertisementData: [String: Any] = [
                CBAdvertisementDataServiceUUIDsKey: [advertisingUUID!],
                CBAdvertisementDataLocalNameKey: ""
            ]
            
            peripheralManager?.startAdvertising(advertisementData)
            print("✅ iOS BLE Advertising started for UUID: \\(uuidString)")
            return true
        } else {
            print("❌ Bluetooth is not powered on")
            return false
        }
    }
    
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        print("🛑 iOS BLE Advertising stopped")
    }
    
    func isAdvertisingSupported() -> Bool {
        return peripheralManager?.state == .poweredOn
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unsupported:
            print("Bluetooth is not supported")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .resetting:
            print("Bluetooth is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("Unknown bluetooth state")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("❌ Failed to start advertising: \\(error.localizedDescription)")
        } else {
            print("✅ Successfully started advertising")
        }
    }
}
```

### 2. Update AppDelegate.swift

Update file: `smart_attendance_admin/ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var bleAdvertiser: BleAdvertiser?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let bleChannel = FlutterMethodChannel(name: "smart_attendance/ble_advertiser",
                                              binaryMessenger: controller.binaryMessenger)
        
        bleAdvertiser = BleAdvertiser()
        
        bleChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            switch call.method {
            case "startAdvertising":
                if let args = call.arguments as? Dictionary<String, Any>,
                   let uuid = args["uuid"] as? String {
                    let success = self.bleAdvertiser?.startAdvertising(uuidString: uuid) ?? false
                    result(success)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT",
                                      message: "UUID is required",
                                      details: nil))
                }
                
            case "stopAdvertising":
                self.bleAdvertiser?.stopAdvertising()
                result(true)
                
            case "isAdvertisingSupported":
                let supported = self.bleAdvertiser?.isAdvertisingSupported() ?? false
                result(supported)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### 3. Update Info.plist

Ensure these keys are in `smart_attendance_admin/ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to advertise attendance sessions</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to advertise attendance sessions</string>
```

### 4. Update Xcode Project

1. Open `smart_attendance_admin/ios/Runner.xcworkspace` in Xcode
2. Right-click on `Runner` folder → Add Files to "Runner"
3. Select `BleAdvertiser.swift`
4. Ensure it's added to Runner target
5. Build and run

## Testing

### Test on Real Device
BLE advertising requires a real iOS device (won't work on simulator).

```bash
cd smart_attendance_admin
flutter run
```

### Verify Advertising
Use a BLE scanner app like:
- **LightBlue** (iOS App Store)
- **nRF Connect** (iOS/Android)

Scan for the UUID being advertised.

## Common Issues

### 1. Swift Version Mismatch
```
Error: Swift version mismatch
```

**Solution**: In Xcode, set Swift Language Version to 5.0 in Build Settings.

### 2. Bridging Header
If Xcode asks for bridging header, create `Runner-Bridging-Header.h`:

```objective-c
//
//  Use this file to import your target's public headers
//  that you would like to expose to Swift.
//

```

### 3. Bluetooth Permission Denied
Ensure user grants Bluetooth permission when prompted.

## Platform Channel Architecture

```
Flutter (Dart)                     iOS (Swift)
───────────────                   ─────────────
BleService                        
    │                             
    │ calls                       
    ↓                             
BleAdvertiser                     
    │ (MethodChannel)             
    │────────────────────────────→ AppDelegate
    │                                   │
    │                                   │ delegates
    │                                   ↓
    │                              BleAdvertiser
    │                                   │
    │                                   │ uses
    │                                   ↓
    │                              CBPeripheralManager
    │←───────────────────────────── (CoreBluetooth)
    │ result                      
    ↓                             
UI Update                         
```

## Next Steps

1. Implement the Swift code above
2. Test on physical iOS device
3. Verify advertising with BLE scanner
4. Integrate with existing Flutter UI
5. Handle edge cases (Bluetooth off, permissions denied)

## Production Considerations

- Add proper error handling
- Implement advertising state monitoring
- Handle app backgrounding (advertising stops when app backgrounds on iOS)
- Consider using background modes (requires special entitlement)
- Add logging and analytics
- Test battery impact
- Comply with Apple's BLE guidelines

## References

- [Apple CoreBluetooth Documentation](https://developer.apple.com/documentation/corebluetooth)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [CBPeripheralManager](https://developer.apple.com/documentation/corebluetooth/cbperipheralmanager)
