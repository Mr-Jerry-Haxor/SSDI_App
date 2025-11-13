# 🔥 Firestore Database Setup Guide

## ✅ Status: Firebase Configured - Firestore Setup Required

Your Firebase project is configured, but you need to create the Firestore database and add initial data.

---

## 📋 Step-by-Step Firestore Setup

### Step 1: Create Firestore Database (5 minutes)

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com
   - Sign in with your Google account
   - Select project: **`smart-attendance-9fbcb`**

2. **Navigate to Firestore**
   - Click "Firestore Database" in the left sidebar
   - Click "Create database" button

3. **Select Mode**
   - Choose: **"Start in test mode"**
   - This allows read/write access for testing
   - Click "Next"

4. **Select Location**
   - Choose the closest region to you:
     - `us-central` (United States)
     - `us-east1` (South Carolina)
     - `europe-west` (Belgium)
     - `asia-south1` (Mumbai)
   - Click "Enable"

5. **Wait for Creation**
   - Database creation takes 30-60 seconds
   - You'll see "Cloud Firestore" dashboard when ready

---

### Step 2: Set Security Rules (2 minutes)

1. **Go to Rules Tab**
   - In Firestore Database, click "Rules" tab

2. **Update Rules**
   - Replace existing rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads and writes for testing
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. **Publish Rules**
   - Click "Publish" button
   - ⚠️ **Warning**: These rules are for testing only. Update for production!

---

### Step 3: Create Collections & Sample Data (10 minutes)

#### **Collection 1: Professor**

1. Click "Start collection"
2. **Collection ID**: `Professor`
3. Click "Next"

**Add Document 1:**
- **Document ID**: `prof@university.edu`
- Add fields:
  ```
  email (string): prof@university.edu
  Name (string): Dr. John Smith
  password (string): test123
  coursesTaught (array): ["CS101", "CS201"]
  ```
- Click "Save"

**Add Document 2:** (Optional - add more professors)
- **Document ID**: `jane@university.edu`
- Add fields:
  ```
  email (string): jane@university.edu
  Name (string): Dr. Jane Doe
  password (string): test123
  coursesTaught (array): ["MATH101"]
  ```
- Click "Save"

---

#### **Collection 2: student**

1. Click "+ Start collection"
2. **Collection ID**: `student`
3. Click "Next"

**Add Document 1:**
- **Document ID**: `STU001`
- Add fields:
  ```
  Email (string): student1@university.edu
  FirstName (string): Alice
  LastName (string): Johnson
  password (string): test123
  studentId (string): STU001
  ```
- Click "Save"

**Add Document 2:**
- **Document ID**: `STU002`
- Add fields:
  ```
  Email (string): student2@university.edu
  FirstName (string): Bob
  LastName (string): Williams
  password (string): test123
  studentId (string): STU002
  ```
- Click "Save"

**Add More Students** (repeat for STU003, STU004, etc.)

---

#### **Collection 3: Courses**

1. Click "+ Start collection"
2. **Collection ID**: `Courses`
3. Click "Next"

**Add Document 1:**
- **Document ID**: `CS101`
- Add fields:
  ```
  CourseCode (string): CS101
  CourseName (string): Introduction to Programming
  professorEmail (string): prof@university.edu
  Semester (string): Fall2025
  Section (string): A
  ```
- Click "Save"

**Add Document 2:**
- **Document ID**: `CS201`
- Add fields:
  ```
  CourseCode (string): CS201
  CourseName (string): Data Structures
  professorEmail (string): prof@university.edu
  Semester (string): Fall2025
  Section (string): B
  ```
- Click "Save"

---

#### **Subcollection: Schedule (under CS101)**

1. Click on the `CS101` document
2. Click "Start collection" (to create subcollection)
3. **Collection ID**: `Schedule`
4. Click "Next"

**Add Schedule Document:**
- **Document ID**: `MON_0900`
- Add fields:
  ```
  Day (string): Monday
  StartTime (string): 09:00 AM
  EndTime (string): 10:30 AM
  Semester (string): Fall2025
  StudentsEnrolled (array): ["STU001", "STU002", "STU003"]
  ```
- Click "Save"

**Repeat for CS201** (create Schedule subcollection with similar data)

---

#### **Subcollection: Attendance (under Schedule)**

This will be created automatically by the app when professors start attendance sessions.

Expected structure:
```
Courses/CS101/Schedule/MON_0900/Attendance/2025-11-13
  ├── <UUID>:
        ├── SessionUUID: <UUID string>
        ├── Status: Active
        ├── timestamp: <server timestamp>
        └── StudentAttendanceData:
              └── STU001:
                    ├── status: Present
                    └── timestamp: <timestamp>
```

---

#### **Collection 4: Semester**

1. Click "+ Start collection"
2. **Collection ID**: `Semester`
3. Click "Next"

**Add Document:**
- **Document ID**: `Fall2025`
- Add fields:
  ```
  Name (string): Fall 2025
  StartDate (string): 2025-08-15
  EndDate (string): 2025-12-15
  ```
- Click "Save"

---

### Step 4: Verify Database Structure

Your Firestore should now look like this:

```
📁 Firestore Database
├── 📂 Professor
│   ├── 📄 prof@university.edu
│   └── 📄 jane@university.edu
│
├── 📂 student
│   ├── 📄 STU001
│   ├── 📄 STU002
│   └── 📄 STU003
│
├── 📂 Courses
│   ├── 📄 CS101
│   │   └── 📂 Schedule
│   │       └── 📄 MON_0900
│   │           └── 📂 Attendance (created by app)
│   └── 📄 CS201
│       └── 📂 Schedule
│           └── 📄 TUE_1400
│               └── 📂 Attendance (created by app)
│
└── 📂 Semester
    └── 📄 Fall2025
```

---

## 🧪 Testing the Setup

### Test Admin App Login

**Credentials:**
- Email: `prof@university.edu`
- Password: `test123`

**Expected Result:**
- Login successful
- Courses displayed: CS101, CS201
- Can start attendance session

### Test Student App Login

**Credentials:**
- Email: `student1@university.edu`
- Password: `test123`

**Expected Result:**
- Login successful
- Prompted for face enrollment (first time)
- Can scan for active sessions

---

## 🔧 Quick Setup Commands

```bash
# Build and run Admin App
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_admin"
flutter run

# Build and run Student App (in another terminal)
cd "d:\USA Assignments\sahasra\SSDI_App\smart_attendance_student"
flutter run
```

---

## 📊 Field Naming Convention

**Important**: Your Firestore uses specific field names. Make sure they match:

| Collection | Field Names |
|------------|-------------|
| **Professor** | `email`, `Name`, `password`, `coursesTaught` |
| **student** | `Email`, `FirstName`, `LastName`, `password`, `studentId` |
| **Courses** | `CourseCode`, `CourseName`, `professorEmail`, `Semester`, `Section` |
| **Schedule** | `Day`, `StartTime`, `EndTime`, `Semester`, `StudentsEnrolled` |
| **Attendance** | `SessionUUID`, `Status`, `timestamp`, `StudentAttendanceData` |
| **Semester** | `Name`, `StartDate`, `EndDate` |

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Permission denied" errors

**Solution:**
- Check Firestore Rules tab
- Ensure test mode rules are published
- Verify `allow read, write: if true;` is set

### Issue 2: Login fails with correct credentials

**Solution:**
- Check exact field names (case-sensitive)
- Verify `Email` vs `email` field naming
- Check document IDs match email/studentId

### Issue 3: Courses not showing in Admin app

**Solution:**
- Verify `coursesTaught` array exists in Professor document
- Check course IDs match exactly (CS101, not cs101)
- Ensure Courses collection has matching documents

### Issue 4: Student enrollment verification fails

**Solution:**
- Check `StudentsEnrolled` array in Schedule document
- Verify student IDs match exactly
- Ensure student is enrolled in the course's schedule

---

## 🔐 Production Security Rules (Use Later)

When ready for production, update Firestore rules to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Professor collection
    match /Professor/{professorId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == professorId;
    }
    
    // Student collection
    match /student/{studentId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == studentId;
    }
    
    // Courses collection
    match /Courses/{courseId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Add professor check
      
      match /Schedule/{scheduleId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
        
        match /Attendance/{date} {
          allow read: if request.auth != null;
          allow write: if request.auth != null;
        }
      }
    }
    
    // Semester collection
    match /Semester/{semesterId} {
      allow read: if true;
      allow write: if false; // Admin only
    }
  }
}
```

---

## ✅ Verification Checklist

- [ ] Firestore database created
- [ ] Security rules set to test mode
- [ ] Professor collection created with sample data
- [ ] student collection created with sample data
- [ ] Courses collection created
- [ ] Schedule subcollection added to courses
- [ ] Semester collection created
- [ ] Admin app tested with login
- [ ] Student app tested with login
- [ ] Face enrollment working (student app)
- [ ] BLE advertising working (admin app)
- [ ] BLE scanning working (student app)
- [ ] Attendance logging tested end-to-end

---

## 🎯 Next Steps

1. ✅ **Complete Firestore setup** (follow this guide)
2. 🧪 **Test both apps** on Android devices
3. 📱 **Add more test data** (students, courses)
4. 🔐 **Update security rules** before production
5. 🚀 **Deploy to real users**

---

## 📞 Support

If you encounter issues:
1. Check Firebase Console → Firestore → Usage tab
2. Look for error messages in Flutter console
3. Verify network connectivity
4. Check that all field names match exactly

---

**Your Firebase is configured! Now just create the Firestore database following this guide.** 🚀
