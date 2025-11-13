# 🔥 Firebase Setup Guide - Replace with Your Own Credentials

## 📋 Overview

This guide will help you replace the existing Firebase configuration with your own Firebase project credentials for both Admin and Student apps.

---

## 🎯 Step-by-Step Firebase Setup

### Step 1: Create Firebase Project

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com
   - Sign in with your Google account

2. **Create New Project**
   - Click "Add project" or "Create a project"
   - Enter project name: `smart-attendance-system` (or your preferred name)
   - Click "Continue"
   
3. **Google Analytics (Optional)**
   - Choose whether to enable Google Analytics
   - Click "Continue"
   - Select Analytics account (or create new)
   - Click "Create project"
   - Wait for project creation (30-60 seconds)

4. **Project Created!**
   - Click "Continue" to go to project dashboard

---

### Step 2: Set Up Firestore Database

1. **Create Firestore Database**
   - In Firebase Console, click "Firestore Database" in left menu
   - Click "Create database"
   
2. **Select Mode**
   - Choose **"Start in test mode"** (for development)
   - Click "Next"
   
3. **Select Location**
   - Choose closest region to your users (e.g., `us-central`, `asia-south1`)
   - Click "Enable"
   - Wait for database creation

4. **Add Sample Data (Optional)**
   - You can add collections manually or let the app create them
   - Required collections: `Professor`, `student`, `Courses`, `Semester`

---

### Step 3: Register Android Apps

#### For Admin App:

1. **Add Android App**
   - In Firebase Console, click ⚙️ (gear icon) → "Project settings"
   - Scroll down to "Your apps" section
   - Click Android icon to add Android app

2. **Register App**
   - **Android package name**: `com.codecatalyst.smartattendance.smart_attendance_admin`
   - **App nickname**: `Smart Attendance Admin` (optional)
   - **Debug signing certificate SHA-1**: (optional for now)
   - Click "Register app"

3. **Download google-services.json**
   - Click "Download google-services.json"
   - Save the file (you'll use it in next steps)
   - Click "Next"

4. **Skip Remaining Steps**
   - Click "Next" → "Next" → "Continue to console"

#### For Student App:

1. **Add Another Android App**
   - In Project settings, click "Add app" → Android icon

2. **Register Student App**
   - **Android package name**: `com.codecatalyst.smartattendance.smart_attendance_student`
   - **App nickname**: `Smart Attendance Student` (optional)
   - Click "Register app"

3. **Download google-services.json**
   - Download the file for student app
   - Click "Next" → "Next" → "Continue to console"

---

### Step 4: Register iOS Apps (When Ready)

#### For Admin App:

1. **Add iOS App**
   - In Project settings, click "Add app" → iOS icon

2. **Register iOS App**
   - **iOS bundle ID**: `com.codecatalyst.smartattendance.smartAttendanceAdmin`
   - **App nickname**: `Smart Attendance Admin iOS` (optional)
   - Click "Register app"

3. **Download GoogleService-Info.plist**
   - Download the file
   - You'll need this when building on Mac
   - Click "Next" → "Next" → "Continue to console"

#### For Student App:

1. **Add Another iOS App**
   - Click "Add app" → iOS icon

2. **Register iOS Student App**
   - **iOS bundle ID**: `com.codecatalyst.smartattendance.smartAttendanceStudent`
   - **App nickname**: `Smart Attendance Student iOS` (optional)
   - Click "Register app"

3. **Download GoogleService-Info.plist**
   - Download the file
   - Click "Next" → "Next" → "Continue to console"

---

## 📁 Files to Update

### Admin App Files

| Platform | File Location | File to Replace |
|----------|--------------|-----------------|
| **Android** | `smart_attendance_admin/android/app/` | `google-services.json` |
| **iOS** | `smart_attendance_admin/ios/Runner/` | `GoogleService-Info.plist` |
| **Dart** | `smart_attendance_admin/lib/` | `firebase_options.dart` |

### Student App Files

| Platform | File Location | File to Replace |
|----------|--------------|-----------------|
| **Android** | `smart_attendance_student/android/app/` | `google-services.json` |
| **iOS** | `smart_attendance_student/ios/Runner/` | `GoogleService-Info.plist` |
| **Dart** | `smart_attendance_student/lib/` | `firebase_options.dart` |

---

## 🔧 How to Replace Credentials

### Method 1: Manual Replacement (Simple)

#### For Admin App:

```bash
# Navigate to admin app
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_admin"

# Replace Android credentials
# 1. Delete old file
Remove-Item "android\app\google-services.json"

# 2. Copy your downloaded google-services.json
# Copy the file you downloaded from Firebase Console to:
# android\app\google-services.json
```

#### For Student App:

```bash
# Navigate to student app
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_student"

# Replace Android credentials
Remove-Item "android\app\google-services.json"

# Copy your downloaded google-services.json to:
# android\app\google-services.json
```

---

### Method 2: Using FlutterFire CLI (Recommended - Automatic)

This method automatically updates all Firebase configuration files.

#### Step 1: Install FlutterFire CLI

```bash
# Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# Verify installation
flutterfire --version
```

#### Step 2: Login to Firebase

```bash
# Login with your Google account
firebase login
```

If `firebase` command not found, install Firebase CLI:

```bash
# Install Firebase CLI using npm
npm install -g firebase-tools

# Or download from: https://firebase.google.com/docs/cli
```

#### Step 3: Configure Admin App

```bash
# Navigate to admin app
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_admin"

# Run FlutterFire configure
flutterfire configure

# You'll be prompted to:
# 1. Select your Firebase project
# 2. Choose platforms (Android, iOS)
# 3. Confirm package names
```

This will:
- ✅ Update `android/app/google-services.json`
- ✅ Update `ios/Runner/GoogleService-Info.plist`
- ✅ Regenerate `lib/firebase_options.dart`

#### Step 4: Configure Student App

```bash
# Navigate to student app
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_student"

# Run FlutterFire configure
flutterfire configure
```

---

## 📝 Manual Update of firebase_options.dart

If you prefer to manually update the Dart configuration file:

### Admin App: `smart_attendance_admin/lib/firebase_options.dart`

```dart
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY_HERE',                    // From Firebase Console
    appId: 'YOUR_APP_ID_HERE',                      // Format: 1:123456:android:abc123
    messagingSenderId: 'YOUR_SENDER_ID_HERE',       // Format: 123456789
    projectId: 'your-project-id',                   // Your Firebase project ID
    storageBucket: 'your-project-id.appspot.com',   // Your storage bucket
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY_HERE',
    appId: 'YOUR_IOS_APP_ID_HERE',                  // Format: 1:123456:ios:abc123
    messagingSenderId: 'YOUR_SENDER_ID_HERE',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosBundleId: 'com.codecatalyst.smartattendance.smartAttendanceAdmin',
  );
}
```

### Where to Find These Values:

1. **Go to Firebase Console** → Your Project
2. **Click ⚙️ (Settings)** → "Project settings"
3. **Scroll to "Your apps"**
4. **Click on your Android/iOS app**
5. **Scroll to "SDK setup and configuration"**
6. **Copy values from the JSON shown**

---

## ✅ Verification Steps

### After Replacing Credentials:

#### Step 1: Clean Build

```bash
# For Admin App
cd smart_attendance_admin
flutter clean
flutter pub get

# For Student App
cd ../smart_attendance_student
flutter clean
flutter pub get
```

#### Step 2: Test Android Build

```bash
# Build Admin App
cd smart_attendance_admin
flutter build apk --debug

# Build Student App
cd ../smart_attendance_student
flutter build apk --debug
```

#### Step 3: Run and Test

```bash
# Connect Android device
flutter devices

# Run Admin App
cd smart_attendance_admin
flutter run

# Try logging in - should connect to YOUR Firebase
```

#### Step 4: Verify in Firebase Console

1. Open Firebase Console
2. Go to Firestore Database
3. Run the app and try to login
4. You should see database queries in the "Usage" tab
5. Check if collections are created (Professor, student, Courses)

---

## 🔐 Security Rules

### Important: Set Up Firestore Security Rules

After replacing credentials, update your Firestore security rules:

1. **Go to Firebase Console** → Firestore Database
2. **Click "Rules" tab**
3. **Replace with these rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Professor collection - read/write for development
    match /Professor/{professorId} {
      allow read, write: if true;  // Change in production
    }
    
    // Student collection
    match /student/{studentId} {
      allow read, write: if true;  // Change in production
    }
    
    // Courses collection
    match /Courses/{courseId} {
      allow read, write: if true;  // Change in production
      
      // Nested Schedule
      match /Schedule/{scheduleId} {
        allow read, write: if true;
      }
      
      // Nested Attendance
      match /Attendance/{attendanceId} {
        allow read, write: if true;
      }
    }
    
    // Semester collection
    match /Semester/{semesterId} {
      allow read, write: if true;  // Change in production
    }
  }
}
```

4. **Click "Publish"**

⚠️ **Note**: These rules allow open access for testing. In production, add proper authentication checks.

---

## 🗃️ Database Structure to Create

Your Firebase project needs these collections:

### 1. Professor Collection

```javascript
// Document ID: professor email
{
  "email": "prof@university.edu",
  "name": "Professor Name",
  "password": "hashed_password",  // Store hashed in production
  "department": "Computer Science"
}
```

### 2. student Collection

```javascript
// Document ID: student ID
{
  "studentId": "STU001",
  "name": "Student Name",
  "email": "student@university.edu",
  "password": "hashed_password",
  "faceEnrolled": false
}
```

### 3. Courses Collection

```javascript
// Document ID: course code
{
  "courseCode": "CS101",
  "courseName": "Introduction to Programming",
  "professorEmail": "prof@university.edu",
  "semester": "Fall 2025",
  "section": "A"
}

// Subcollection: Schedule
Courses/{courseCode}/Schedule/{scheduleId}
{
  "day": "Monday",
  "startTime": "09:00 AM",
  "endTime": "10:30 AM",
  "room": "Room 101"
}

// Subcollection: Attendance
Courses/{courseCode}/Attendance/{sessionId}
{
  "sessionId": "uuid-here",
  "date": "2025-11-13",
  "startTime": "09:00 AM",
  "isActive": true,
  "students": [
    {
      "studentId": "STU001",
      "timestamp": "2025-11-13 09:05:00",
      "status": "present"
    }
  ]
}
```

### 4. Semester Collection

```javascript
{
  "semesterName": "Fall 2025",
  "startDate": "2025-08-15",
  "endDate": "2025-12-15"
}
```

---

## 🚀 Quick Setup Commands

```bash
# Complete setup for both apps
cd "d:\USA Assignments\sahasra\SSDI_App"

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Admin App
cd smart_attendance_admin
flutterfire configure --project=your-firebase-project-id
flutter clean && flutter pub get

# Configure Student App
cd ../smart_attendance_student
flutterfire configure --project=your-firebase-project-id
flutter clean && flutter pub get

# Test Admin App
cd ../smart_attendance_admin
flutter run

# Test Student App (in another terminal)
cd ../smart_attendance_student
flutter run
```

---

## 📋 Checklist

- [ ] Created Firebase project
- [ ] Enabled Firestore database
- [ ] Registered Android Admin app
- [ ] Registered Android Student app
- [ ] Downloaded google-services.json for Admin
- [ ] Downloaded google-services.json for Student
- [ ] Replaced Admin app google-services.json
- [ ] Replaced Student app google-services.json
- [ ] Ran `flutterfire configure` for Admin app
- [ ] Ran `flutterfire configure` for Student app
- [ ] Updated Firestore security rules
- [ ] Created sample Professor document
- [ ] Created sample student document
- [ ] Created sample Course document
- [ ] Tested Admin app login
- [ ] Tested Student app login
- [ ] Verified data in Firebase Console

---

## 🆘 Troubleshooting

### Error: "FirebaseOptions not configured"

**Solution**: Run `flutterfire configure` or manually update `firebase_options.dart`

### Error: "google-services.json not found"

**Solution**: Ensure file is in `android/app/` directory (not `android/` alone)

### Error: "Default FirebaseApp is not initialized"

**Solution**: Check that `Firebase.initializeApp()` is called in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### Build Error: "Execution failed for task ':app:processDebugGoogleServices'"

**Solution**: 
1. Package name in `google-services.json` must match `android/app/build.gradle`
2. Re-download correct `google-services.json` from Firebase Console

### Can't Connect to Firestore

**Solution**:
1. Check internet connection
2. Verify Firestore is enabled in Firebase Console
3. Check security rules allow access
4. Verify project ID matches

---

## 📞 Support Resources

- **Firebase Console**: https://console.firebase.google.com
- **FlutterFire Docs**: https://firebase.flutter.dev
- **Firebase CLI**: https://firebase.google.com/docs/cli
- **Firestore Docs**: https://firebase.google.com/docs/firestore

---

## ✨ Summary

To replace Firebase credentials:

1. **Create your Firebase project** (5 minutes)
2. **Register Android apps** (5 minutes)
3. **Download google-services.json files** (2 minutes)
4. **Run `flutterfire configure`** (2 minutes each app)
5. **Test apps** (5 minutes)

**Total Time: ~20 minutes**

After this, both apps will use YOUR Firebase project instead of the existing one! 🎉
