# 📊 Backend Data Flow & Storage Architecture

## Overview
This document explains how data is stored, retrieved, and synchronized between the Flutter apps and Firebase Firestore.

## 🗄️ Firebase Firestore Database Structure

### Collections Hierarchy

```
smartattendance-76e43 (Firebase Project)
│
├── Professor/
│   └── {professorId} (Document)
│       ├── Name: string
│       ├── email: string
│       ├── password: string (plain text - migrate to Firebase Auth in production)
│       └── coursesTaught: array<string> (array of courseIds)
│
├── student/
│   └── {studentId} (Document)
│       ├── FirstName: string
│       ├── LastName: string
│       ├── Email: string
│       └── password: string (plain text - migrate to Firebase Auth in production)
│
├── Courses/
│   └── {courseId} (Document)
│       ├── CourseName: string
│       └── Schedule/ (Subcollection)
│           └── {scheduleId} (Document)
│               ├── Day: string (e.g., "Monday")
│               ├── StartTime: string (e.g., "09:00 AM")
│               ├── EndTime: string (e.g., "10:30 AM")
│               ├── Semester: string (semesterId reference)
│               ├── StudentsEnrolled: array<string> (array of studentIds)
│               └── Attendance/ (Subcollection)
│                   └── {date} (Document, format: "yyyy-MM-dd", e.g., "2025-11-13")
│                       └── {sessionUUID} (Map/Object)
│                           ├── SessionUUID: string
│                           ├── Status: string ("Active" or "Closed")
│                           ├── timestamp: Timestamp (Firestore server timestamp)
│                           └── StudentAttendanceData: map<string, object>
│                               └── {studentId}: object
│                                   ├── status: string ("Present")
│                                   └── timestamp: Timestamp
│
└── Semester/
    └── {semesterId} (Document)
        └── Name: string (e.g., "Fall 2025")
```

## 🔄 Data Flow Diagrams

### 1. Professor Login Flow

```
Admin App                     Firestore                    Response
─────────                     ─────────                    ────────
    │                             │                           │
    │ Enter email/password        │                           │
    │──────────────────────────>  │                           │
    │                             │                           │
    │ Query Professor collection  │                           │
    │ WHERE email == input        │                           │
    │────────────────────────────>│                           │
    │                             │                           │
    │                             │ Find matching document    │
    │                             │ Compare password field    │
    │                             │────────────────────────>  │
    │                             │                           │
    │<────────────────────────────│─────────────────────────  │
    │ Return {id, Name, email}    │                           │
    │                             │                           │
    │ Store in AuthService        │                           │
    │ Navigate to MainScreen      │                           │
```

### 2. Start Attendance Session Flow

```
Admin App                     Firestore                    BLE
─────────                     ─────────                    ────
    │                             │                           │
    │ Tap "Start Session"         │                           │
    │                             │                           │
    │ Generate UUID               │                           │
    │ uuid = UUID.v4()            │                           │
    │                             │                           │
    │ Check existing session      │                           │
    │ GET Attendance/{today}      │                           │
    │────────────────────────────>│                           │
    │<────────────────────────────│                           │
    │                             │                           │
    │ If active session exists:   │                           │
    │ → Show dialog               │                           │
    │ → Close old session         │                           │
    │                             │                           │
    │ Write new session           │                           │
    │ SET Attendance/{today}      │                           │
    │ {                           │                           │
    │   uuid: {                   │                           │
    │     SessionUUID: uuid,      │                           │
    │     Status: "Active",       │                           │
    │     timestamp: now()        │                           │
    │   }                         │                           │
    │ }                           │                           │
    │────────────────────────────>│                           │
    │                             │ Document created          │
    │                             │                           │
    │ Start BLE advertising       │                           │
    │─────────────────────────────────────────────────────────>│
    │                             │                           │
    │                             │                  Advertising
    │                             │                  UUID as
    │                             │                  service
```

### 3. Student Attendance Flow

```
Student App                   BLE                      Firestore
───────────                   ────                     ─────────
    │                          │                           │
    │ Start BLE scan            │                           │
    │──────────────────────────>│                           │
    │                          │                           │
    │ Detect advertised UUID    │                           │
    │<──────────────────────────│                           │
    │                          │                           │
    │ Query all Attendance docs │                           │
    │ using collectionGroup()   │                           │
    │──────────────────────────────────────────────────────>│
    │                          │                           │
    │                          │  Search all Attendance    │
    │                          │  subcollections for:      │
    │                          │  - SessionUUID == uuid    │
    │                          │  - Status == "Active"     │
    │                          │                           │
    │<──────────────────────────────────────────────────────│
    │ Return {sessionUUID,      │                           │
    │         courseId,         │                           │
    │         scheduleId}       │                           │
    │                          │                           │
    │ Get Schedule doc          │                           │
    │ to check enrollment       │                           │
    │──────────────────────────────────────────────────────>│
    │<──────────────────────────────────────────────────────│
    │ StudentsEnrolled array    │                           │
    │                          │                           │
    │ If enrolled:             │                           │
    │   Enable "Log" button     │                           │
    │                          │                           │
    │ Tap "Log Attendance"      │                           │
    │                          │                           │
    │ UPDATE Attendance/{date}  │                           │
    │ {                         │                           │
    │   uuid.StudentAttendance  │                           │
    │   Data.studentId: {       │                           │
    │     status: "Present",    │                           │
    │     timestamp: now()      │                           │
    │   }                       │                           │
    │ }                         │                           │
    │──────────────────────────────────────────────────────>│
    │                          │                           │
    │                          │  Attendance logged!       │
    │<──────────────────────────────────────────────────────│
```

### 4. Face Enrollment Flow

```
Student App              Camera/ML Kit          TensorFlow Lite      SharedPreferences
───────────              ──────────────         ────────────────     ─────────────────
    │                         │                        │                    │
    │ Open camera             │                        │                    │
    │────────────────────────>│                        │                    │
    │                         │                        │                    │
    │ Capture image           │                        │                    │
    │<────────────────────────│                        │                    │
    │                         │                        │                    │
    │ Detect face             │                        │                    │
    │────────────────────────>│                        │                    │
    │<────────────────────────│                        │                    │
    │ Face bounding box       │                        │                    │
    │                         │                        │                    │
    │ Crop face from image    │                        │                    │
    │                         │                        │                    │
    │ Resize to 160x160       │                        │                    │
    │ Normalize pixels        │                        │                    │
    │                         │                        │                    │
    │ Run FaceNet inference   │                        │                    │
    │────────────────────────────────────────────────────>│                    │
    │                         │                        │                    │
    │                         │  Model processes       │                    │
    │                         │  Returns 512-dim       │                    │
    │                         │  embedding vector      │                    │
    │<────────────────────────────────────────────────────│                    │
    │                         │                        │                    │
    │ Save embedding          │                        │                    │
    │────────────────────────────────────────────────────────────────────────>│
    │                         │                        │                    │
    │                         │                        │  Stored as JSON    │
    │                         │                        │  in key:           │
    │                         │                        │  "face_embedding"  │
```

## 💾 Local Storage (Student App)

### SharedPreferences Keys

```dart
// Student authentication
"STUDENT_ID": String          // Student document ID
"STUDENT_NAME": String        // Full name
"STUDENT_EMAIL": String       // Email address

// Face recognition
"face_embedding": String      // JSON-encoded array of doubles (512 values)
```

### Face Embedding Format

```json
{
  "face_embedding": "[0.123, -0.456, 0.789, ... (512 values total)]"
}
```

## 🔍 Query Patterns

### 1. Login Query (Professor)
```dart
QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  .collection('Professor')
  .where('email', isEqualTo: email)
  .get();
```

### 2. Login Query (Student)
```dart
QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  .collection('student')
  .where('Email', isEqualTo: email)
  .where('password', isEqualTo: password)
  .get();
```

### 3. Fetch Courses
```dart
DocumentSnapshot doc = await FirebaseFirestore.instance
  .collection('Professor')
  .doc(professorId)
  .get();

List<String> courseIds = doc.data()['coursesTaught'];
```

### 4. Find Active Session (CollectionGroup Query)
```dart
QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  .collectionGroup('Attendance')
  .get();

// Then filter in-memory for active sessions
```

### 5. Log Attendance
```dart
await FirebaseFirestore.instance
  .collection('Courses')
  .doc(courseId)
  .collection('Schedule')
  .doc(scheduleId)
  .collection('Attendance')
  .doc(date)  // e.g., "2025-11-13"
  .update({
    '$uuid.StudentAttendanceData.$studentId': {
      'status': 'Present',
      'timestamp': FieldValue.serverTimestamp(),
    }
  });
```

## 📈 Data Synchronization

### Real-time Updates
Firestore provides real-time synchronization by default:

```dart
// Listen to attendance changes (example)
FirebaseFirestore.instance
  .collection('Courses')
  .doc(courseId)
  .collection('Schedule')
  .doc(scheduleId)
  .collection('Attendance')
  .doc(date)
  .snapshots()
  .listen((snapshot) {
    // Auto-updates when data changes
  });
```

### Offline Support
Firestore SDK includes offline persistence:
- Data cached locally
- Writes queued when offline
- Auto-syncs when connection restored

## 🔐 Security Considerations

### Current Implementation
⚠️ **For Development Only**

```
- Plain text passwords stored in Firestore
- No Firestore security rules shown
- Client-side authentication only
- No encryption for face embeddings
```

### Production Recommendations

1. **Authentication**
```dart
// Migrate to Firebase Authentication
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

2. **Firestore Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Professors can only access their courses
    match /Courses/{courseId}/Schedule/{scheduleId}/Attendance/{date} {
      allow write: if get(/databases/$(database)/documents/Professor/$(request.auth.uid))
                     .data.coursesTaught.hasAny([courseId]);
    }
    
    // Students can only log their own attendance
    match /Courses/{courseId}/Schedule/{scheduleId}/Attendance/{date} {
      allow update: if request.auth.uid in 
                      get(/databases/$(database)/documents/Courses/$(courseId)/Schedule/$(scheduleId))
                      .data.StudentsEnrolled;
    }
  }
}
```

3. **Encrypt Face Data**
```dart
// Use flutter_secure_storage instead of SharedPreferences
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'face_embedding', value: encryptedData);
```

## 📊 Data Flow Summary

1. **Login**: Query Firestore → Validate → Store session
2. **Course Selection**: Fetch from Professor.coursesTaught → Get Course details
3. **Start Session**: Generate UUID → Write to Attendance → Advertise BLE
4. **Student Scan**: Detect UUID → Query Attendance → Verify enrollment
5. **Log Attendance**: Update Attendance document → Add student entry
6. **Face Enrollment**: Capture → Detect → Extract embedding → Store locally

All operations use Firebase Firestore for backend storage with local caching and real-time sync capabilities.
