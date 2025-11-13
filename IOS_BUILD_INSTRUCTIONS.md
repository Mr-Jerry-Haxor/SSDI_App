# iOS Build Instructions (macOS Required)

## Prerequisites

Since iOS app development requires macOS and Xcode, follow these steps **on a Mac computer**:

### 1. System Requirements
- **macOS** 13.0 (Ventura) or later
- **Xcode** 15.0 or later
- **Flutter SDK** 3.9.2 or later
- **CocoaPods** 1.11 or later

### 2. Install Required Tools on Mac

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install CocoaPods
sudo gem install cocoapods

# Verify installations
flutter doctor -v
pod --version
xcodebuild -version
```

---

## Building the iOS Admin App

### Step 1: Transfer Project to Mac

Option A: **Git Clone** (Recommended)
```bash
# On Mac
git clone <your-repository-url>
cd SSDI_App/smart_attendance_admin
```

Option B: **Manual Transfer**
- Copy entire `smart_attendance_admin` folder to Mac
- Use AirDrop, USB drive, or cloud storage

### Step 2: Install Dependencies on Mac

```bash
cd smart_attendance_admin

# Get Flutter packages
flutter clean
flutter pub get

# Install iOS pods
cd ios
pod install
cd ..
```

### Step 3: Open in Xcode

```bash
# Open workspace (NOT .xcodeproj)
cd ios
open Runner.xcworkspace
```

### Step 4: Configure Xcode Project

1. **Select Team**:
   - Click on `Runner` project in left sidebar
   - Select `Runner` target
   - Go to "Signing & Capabilities" tab
   - Select your **Team** (Apple Developer Account)
   - Xcode will automatically generate a Bundle Identifier

2. **Verify Swift Files**:
   - Check that `AppDelegate.swift` is visible
   - Check that `BleAdvertiser.swift` is visible
   - Both should be in the Runner folder

3. **Check Build Settings**:
   - Select `Runner` target
   - Go to "Build Settings" tab
   - Search for "Swift Language Version"
   - Should be set to "Swift 5"

### Step 5: Connect iOS Device

1. Connect iPhone or iPad via USB cable
2. Unlock the device
3. **Trust This Computer** prompt → Tap "Trust"
4. Enable **Developer Mode** on device:
   - Settings > Privacy & Security > Developer Mode → Enable
   - Device will restart

### Step 6: Build and Run

```bash
# From terminal
flutter devices  # Should show your iOS device

# Run on device
flutter run -d <device-id>
```

Or in Xcode:
1. Select your connected device from the device dropdown (top bar)
2. Click the "Play" button or press `Cmd + R`

---

## Troubleshooting

### Error: "No provisioning profile"
**Solution**:
```
1. Xcode → Preferences → Accounts
2. Add your Apple ID
3. Download Manual Profiles
4. Select Team in Signing & Capabilities
```

### Error: "pod install failed"
**Solution**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
```

### Error: "Swift Compiler Error"
**Solution**:
```
1. Xcode → Product → Clean Build Folder
2. Restart Xcode
3. Product → Build
```

### Error: "BleAdvertiser.swift not found"
**Solution**:
```
1. In Xcode, right-click Runner folder
2. Add Files to "Runner"
3. Select BleAdvertiser.swift
4. Ensure "Copy items if needed" is checked
5. Ensure Runner target is selected
```

---

## Testing on Physical Device

### Why Physical Device Required?
- **BLE advertising** requires real Bluetooth hardware
- iOS **Simulator does NOT support** Bluetooth Low Energy
- Must test on iPhone or iPad

### Recommended Test Devices
- iPhone 8 or later (iOS 14+)
- iPad Air 3 or later
- iPad Pro (any generation)

### Testing Checklist
1. ✅ App installs successfully
2. ✅ Bluetooth permission prompt appears
3. ✅ Grant Bluetooth permission
4. ✅ Login with professor credentials
5. ✅ Select course from dropdown
6. ✅ Tap "Start Attendance"
7. ✅ UUID appears in UI
8. ✅ Check Xcode console for "✅ iOS BLE Advertising started"
9. ✅ Use another device with BLE scanner app to verify
10. ✅ Student app can detect and log attendance

---

## Alternative: Use GitHub Actions for iOS Build

If you don't have a Mac, you can use GitHub Actions to build iOS apps:

### Create `.github/workflows/ios-build.yml`:

```yaml
name: iOS Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.7'
        channel: 'stable'
    
    - name: Install dependencies
      working-directory: ./smart_attendance_admin
      run: |
        flutter pub get
        cd ios
        pod install
    
    - name: Build iOS
      working-directory: ./smart_attendance_admin
      run: |
        flutter build ios --release --no-codesign
    
    - name: Upload IPA
      uses: actions/upload-artifact@v3
      with:
        name: ios-build
        path: smart_attendance_admin/build/ios/iphoneos/Runner.app
```

---

## Distribution Options

### Option 1: TestFlight (Recommended for Beta Testing)
1. Create app in App Store Connect
2. Archive app in Xcode
3. Upload to App Store Connect
4. Invite testers via email

### Option 2: Ad Hoc Distribution
1. Register device UDIDs in Apple Developer Portal
2. Create Ad Hoc provisioning profile
3. Build with Ad Hoc profile
4. Distribute IPA file to testers

### Option 3: Enterprise Distribution
1. Requires Apple Developer Enterprise Program ($299/year)
2. Can distribute to unlimited devices
3. No App Store review required

---

## Expected Build Output

### Successful Build Console Output:
```
✓ Built build/ios/iphoneos/Runner.app
✓ Installed Runner.app on <device-name>

Launching lib/main.dart on <device-name> in debug mode...
Running Xcode build...
Xcode build done.                                          15.2s
Syncing files to device <device-name>...                    58ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

An Observatory debugger and profiler on <device-name> is available at:
http://127.0.0.1:50001/...
The Flutter DevTools debugger and profiler on <device-name> is available at:
http://127.0.0.1:9101?uri=http://127.0.0.1:50001/...
```

### Xcode Console Output (when advertising):
```
✅ iOS BLE Advertising started for UUID: a1b2c3d4-e5f6-7890-1234-567890abcdef
Bluetooth is powered on
✅ Successfully started advertising
```

---

## Code Signing for Release

### Step 1: Create App ID
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Certificates, Identifiers & Profiles
3. Identifiers → + (Add)
4. App IDs → Continue
5. Enter Bundle ID: `com.codecatalyst.smart_attendance_admin`

### Step 2: Create Distribution Certificate
```bash
# In Xcode
1. Xcode → Preferences → Accounts
2. Manage Certificates
3. + → Apple Distribution
```

### Step 3: Build for Release
```bash
flutter build ios --release

# Or in Xcode:
# Product → Scheme → Edit Scheme → Run → Release
# Product → Archive
```

---

## Performance Optimization

### Build Size Optimization
```bash
# Enable tree shaking
flutter build ios --release --tree-shake-icons

# Split debug symbols
flutter build ios --release --split-debug-info=./debug-info
```

### Startup Time Optimization
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Already done ✅
  runApp(MyApp());
}
```

---

## Firebase iOS Configuration

### If Not Already Done:

1. **Go to [Firebase Console](https://console.firebase.google.com)**
2. Select your project
3. Add iOS app
4. Register app with Bundle ID: `com.codecatalyst.smart_attendance_admin`
5. Download `GoogleService-Info.plist`
6. **Copy file to**: `smart_attendance_admin/ios/Runner/`
7. Open Xcode, add file to Runner target
8. Run FlutterFire CLI:

```bash
cd smart_attendance_admin
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

---

## Summary

### What's Complete ✅
1. ✅ Swift BLE advertiser implementation
2. ✅ Platform channel bridge (Dart ↔ Swift)
3. ✅ Xcode project configuration
4. ✅ Bluetooth permissions in Info.plist
5. ✅ All Flutter dependencies configured

### What You Need to Do
1. 🍎 **Access a Mac** with Xcode
2. 📱 **Connect iOS device** (iPhone/iPad)
3. 🔨 **Build and test** the app
4. 🔍 **Verify BLE advertising** works
5. 🚀 **Deploy to TestFlight** or distribute

### Time Estimate
- **Initial build setup**: 30-60 minutes
- **Testing and debugging**: 1-2 hours
- **TestFlight submission**: 1-2 hours

---

## Support

If you encounter issues:
1. Check Xcode console for error messages
2. Run `flutter doctor -v` on Mac
3. Verify all permissions granted on device
4. Test BLE with scanner app first
5. Check Firebase configuration
6. Review logs in Console.app

**The iOS implementation is 100% complete and ready to build on macOS!** 🎉
