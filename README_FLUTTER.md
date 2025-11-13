# Smart Attendance System - Flutter Apps

This project contains two Flutter applications for a Smart Attendance system:
1. **Smart Attendance Admin** - Professor app for managing attendance sessions
2. **Smart Attendance Student** - Student app for marking attendance

Both apps are compatible with **iOS and Android** devices.

## 🏗️ Architecture

### Backend
- **Firebase Firestore**: Cloud database for storing professors, students, courses, schedules, and attendance records
- **Collections Structure**:
  - `Professor`: Professor profiles and courses taught
  - `student`: Student profiles
  - `Courses`: Course information with nested `Schedule` and `Attendance` collections
  - `Semester`: Semester information

### Technologies
- **Flutter**: Cross-platform mobile framework
- **Bluetooth Low Energy (BLE)**: For proximity-based attendance
- **Face Recognition**: TensorFlow Lite FaceNet model for student verification
- **Google ML Kit**: Face detection
- **Firebase**: Backend services

## 📱 App Features

### Admin App (Professor)
- ✅ Login with email/password
- ✅ View and select courses
- ✅ Start/Stop Bluetooth LE attendance sessions
- ✅ Real-time session management
- ✅ Animated Bluetooth status indicator

### Student App
- ✅ Login with email/password
- ✅ Face enrollment on first login
- ✅ Automatic BLE scanning for attendance sessions
- ✅ Course enrollment verification
- ✅ One-tap attendance marking
- ✅ Face recognition verification

## 🚀 Setup Instructions

### Prerequisites
1. **Flutter SDK**: Install from https://flutter.dev/docs/get-started/install
2. **Xcode** (for iOS): Install from Mac App Store
3. **Android Studio** (for Android): Install from https://developer.android.com/studio
4. **Firebase Project**: Configured with Firestore

### Installation Steps

#### 1. Clone and Navigate
```bash
cd "d:\USA Assignments\sahasra\SSDI_App"
```

#### 2. Admin App Setup
```bash
cd smart_attendance_admin

# Install dependencies
flutter pub get

# For iOS (macOS only)
cd ios
pod install
cd ..

# Run on device
flutter run

# Build for release
flutter build apk  # Android
flutter build ios  # iOS
```

#### 3. Student App Setup
```bash
cd ../smart_attendance_student

# Install dependencies
flutter pub get

# For iOS (macOS only)
cd ios
pod install
cd ..

# Run on device
flutter run

# Build for release
flutter build apk  # Android
flutter build ios  # iOS
```

## 📝 Firebase Configuration

### Android
- Google Services JSON files are already configured:
  - Admin: `smart_attendance_admin/android/app/google-services.json`
  - Student: `smart_attendance_student/android/app/google-services.json`

### iOS
For iOS deployment, you need to:
1. Register iOS apps in Firebase Console
2. Download `GoogleService-Info.plist` files
3. Add them to iOS project:
   - Admin: `smart_attendance_admin/ios/Runner/GoogleService-Info.plist`
   - Student: `smart_attendance_student/ios/Runner/GoogleService-Info.plist`
4. Update `firebase_options.dart` with iOS app IDs

## 🔐 Permissions

### Admin App
**Android:**
- Bluetooth
- Bluetooth Admin
- Bluetooth Advertise
- Bluetooth Connect
- Bluetooth Scan
- Location (required for BLE)

**iOS:**
- Bluetooth
- Location When In Use

### Student App
**Android:**
- Bluetooth
- Bluetooth Scan
- Bluetooth Connect
- Location (required for BLE)
- Camera (for face enrollment)

**iOS:**
- Bluetooth
- Location When In Use
- Camera

All permissions are already configured in AndroidManifest.xml and Info.plist files.

## 🎯 Usage Flow

### Professor (Admin App)
1. Login with professor credentials
2. Select a course from dropdown
3. Tap "Start Attendance Session"
4. Students can now mark attendance via BLE proximity
5. Tap "Stop Attendance Session" when complete

### Student
1. Login with student credentials
2. Enroll face on first login (camera capture)
3. Keep app open during class
4. App automatically detects professor's BLE session
5. Verify enrollment and tap "Log Attendance"

## 🔧 Important Notes

### BLE Advertising Limitation
Flutter's `flutter_blue_plus` package supports BLE **scanning** but not **advertising** natively. For production deployment:

**Admin App - Platform Channels Required:**
- Android: Implement `BluetoothLeAdvertiser` in native Kotlin/Java
- iOS: Implement `CBPeripheralManager` in native Swift/Objective-C

A platform channel bridge is needed in `lib/services/ble_service.dart` to call native advertising code.

### Face Recognition
- Model: FaceNet (160x160 input, 512-dim embedding)
- Model file: `smart_attendance_student/assets/models/facenet.tflite`
- Storage: Local SharedPreferences (embeddings)
- Threshold: Configurable cosine similarity

### Database Structure
```
Firestore Structure:
├── Professor/{professorId}
│   ├── Name
│   ├── email
│   ├── password
│   └── coursesTaught[]
├── student/{studentId}
│   ├── FirstName
│   ├── LastName
│   ├── Email
│   └── password
├── Courses/{courseId}
│   ├── CourseName
│   └── Schedule/{scheduleId}
│       ├── Day
│       ├── StartTime
│       ├── EndTime
│       ├── Semester
│       ├── StudentsEnrolled[]
│       └── Attendance/{date}
│           └── {sessionUUID}
│               ├── SessionUUID
│               ├── Status (Active/Closed)
│               ├── timestamp
│               └── StudentAttendanceData/{studentId}
│                   ├── status
│                   └── timestamp
└── Semester/{semesterId}
    └── Name
```

## 🐛 Troubleshooting

### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get

# For iOS pod issues
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Permission Issues (iOS)
Ensure Info.plist contains all required usage descriptions.

### Bluetooth Not Working
- Enable Bluetooth on device
- Grant all required permissions
- Check device supports BLE (most modern phones do)

## 📦 Dependencies

### Admin App
- firebase_core, cloud_firestore, firebase_auth
- flutter_blue_plus (BLE)
- provider (state management)
- lottie (animations)
- permission_handler
- uuid, intl

### Student App  
- All admin dependencies PLUS:
- camera (face capture)
- google_ml_kit (face detection)
- tflite_flutter (FaceNet inference)
- image (processing)
- shared_preferences (storage)

## 🏁 Production Deployment

### Android
```bash
flutter build apk --release  # APK
flutter build appbundle      # Play Store
```

### iOS
```bash
flutter build ios --release
# Open Xcode for signing and App Store submission
open ios/Runner.xcworkspace
```

### Pre-deployment Checklist
- [ ] Configure proper Firebase iOS apps
- [ ] Implement native BLE advertising
- [ ] Add proper code signing (iOS)
- [ ] Update app icons
- [ ] Test on real devices
- [ ] Configure proper security rules in Firestore
- [ ] Enable Firebase Analytics (optional)

## 📄 License
This project is for educational purposes.

## 👥 Support
For issues, check:
1. Flutter Doctor: `flutter doctor -v`
2. Logs: `flutter logs`
3. Firebase Console for backend errors
