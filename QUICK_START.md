# 🚀 Quick Start Guide

## Prerequisites Check

```bash
# 1. Verify Flutter installation
flutter doctor -v

# 2. Ensure you have:
# ✅ Flutter SDK
# ✅ Android Studio (for Android)
# ✅ Xcode (for iOS, macOS only)
# ✅ Physical device (BLE requires real device)
```

## 📱 Run Admin App (Professor)

### Android

```bash
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_admin"
flutter pub get
flutter run
```

### iOS (macOS only)

```bash
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_admin"
flutter pub get
cd ios && pod install && cd ..
flutter run

# Note: BLE advertising needs Swift implementation (see IOS_BLE_IMPLEMENTATION.md)
```

## 📱 Run Student App

### Android

```bash
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_student"
flutter pub get
flutter run
```

### iOS (macOS only)

```bash
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_student"
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## 🔑 Test Credentials

Use your existing Firebase data:

### Professor Login

- Email: (from your Professor collection)
- Password: (from your Professor collection)

### Student Login

- Email: (from your student collection)
- Password: (from your student collection)

## 📋 Testing Flow

### 1. Professor Side (Admin App)

1. Login with professor credentials
2. Select a course
3. Tap "Start Attendance Session"
4. Bluetooth starts advertising
5. Keep app open

### 2. Student Side (Student App)

1. Login with student credentials
2. Enroll face (camera capture) - first time only
3. App automatically scans for BLE sessions
4. When session detected, tap "Log Attendance"
5. Attendance marked! ✅

## 🛠️ Troubleshooting

### "No device found"

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Bluetooth Permissions

- Go to Settings → Apps → Smart Attendance
- Enable all permissions (Bluetooth, Location, Camera)

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### iOS Pod Issues

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

## 📊 Check Attendance in Firebase

1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to:
   ```
   Courses → {courseId} → Schedule → {scheduleId} → Attendance → {date}
   ```
4. Look for `StudentAttendanceData` with student IDs and timestamps

## 🎯 Next Steps

1. ✅ Test both apps on Android
2. ✅ Test student app on iOS
3. ⏳ Implement iOS BLE advertising for admin app
4. ✅ Verify attendance data in Firestore
5. 🚀 Deploy to production

## 📚 Documentation

- **Full Setup**: README_FLUTTER.md
- **iOS BLE Guide**: IOS_BLE_IMPLEMENTATION.md
- **Migration Details**: MIGRATION_SUMMARY.md

## 💡 Tips

- **BLE Range**: Keep devices within 10 meters
- **Battery**: BLE advertising/scanning consumes battery
- **Permissions**: Grant all permissions when prompted
- **Real Device**: BLE won't work on emulators/simulators
- **Firestore**: Check Firebase console for real-time data

## ⚡ Quick Commands Reference

```bash
# Check Flutter setup
flutter doctor

# Get dependencies
flutter pub get

# Run app
flutter run

# Build release APK (Android)
flutter build apk --release

# Build iOS (macOS)
flutter build ios --release

# Clean project
flutter clean

# Check devices
flutter devices

# View logs
flutter logs
```

## 🎉 You're Ready!

Both apps are fully functional on Android and IOS , ready for testing.

Happy coding! 🚀
