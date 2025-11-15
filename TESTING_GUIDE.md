# Smart Attendance App - Testing Guide

## 🧪 Comprehensive Testing Checklist

---

## 1. **Initial Setup Testing**

### Flutter Student App Build:

```bash
cd smart_attendance_student
flutter clean
flutter pub get
flutter analyze
flutter build apk --release  # For Android
flutter build ios --release  # For iOS (on macOS)
```

**Expected Results:**

- ✅ `flutter analyze`: No issues found
- ✅ Build completes without errors
- ✅ APK/IPA generated successfully

---

## 2. **Authentication Flow Testing**

### Login Screen Tests:

#### Test 1.1: **Valid Login**

- **Steps:**
  1. Launch app
  2. Wait for splash screen (2 seconds)
  3. Enter valid email and password
  4. Tap "Login"
- **Expected:**
  - ✅ Loading indicator appears
  - ✅ Welcome message: "✅ Welcome back, [FirstName]!"
  - ✅ Navigates to Face Enrollment (if no face data) OR Main Screen (if face exists)

#### Test 1.2: **Invalid Credentials**

- **Steps:**
  1. Enter wrong email/password
  2. Tap "Login"
- **Expected:**
  - ✅ Error snackbar: "❌ Invalid email or password"
  - ✅ User stays on login screen

#### Test 1.3: **Email Validation**

- **Steps:**
  1. Enter email without "@" symbol
  2. Try to submit
- **Expected:**
  - ✅ Validation error: "Please enter a valid email"
  - ✅ Login button disabled until valid

#### Test 1.4: **Password Validation**

- **Steps:**
  1. Enter password less than 6 characters
  2. Try to submit
- **Expected:**
  - ✅ Validation error: "Password must be at least 6 characters"
  - ✅ Login button disabled until valid

#### Test 1.5: **Password Visibility Toggle**

- **Steps:**
  1. Enter password
  2. Tap eye icon
  3. Tap eye icon again
- **Expected:**
  - ✅ Password text hidden initially
  - ✅ Password text visible after first tap
  - ✅ Password text hidden after second tap

#### Test 1.6: **Network Error Handling**

- **Steps:**
  1. Turn off WiFi/mobile data
  2. Attempt login
- **Expected:**
  - ✅ Error snackbar: "❌ Login error: [error message]"
  - ✅ App doesn't crash
  - ✅ Can retry after network restored

---

## 3. **Face Enrollment Testing**

### Test 2.1: **Camera Permission Denied**

- **Steps:**
  1. Login for first time
  2. Deny camera permission
- **Expected:**
  - ✅ Shows permission request UI
  - ✅ "Grant Camera Permission" button visible
  - ✅ Explanation text displayed

### Test 2.2: **Camera Permission Granted**

- **Steps:**
  1. Tap "Grant Camera Permission"
  2. Allow in system dialog
- **Expected:**
  - ✅ Camera preview appears
  - ✅ "Capture Face" button enabled
  - ✅ Front camera selected

### Test 2.3: **Successful Face Capture**

- **Steps:**
  1. Position face in camera
  2. Tap "Capture Face"
  3. Wait for processing
- **Expected:**
  - ✅ "Processing..." indicator appears
  - ✅ Face detected message
  - ✅ "Processing face..." message
  - ✅ Success message: "✅ Face registered successfully!"
  - ✅ Navigates to Main Screen

### Test 2.4: **No Face Detected**

- **Steps:**
  1. Point camera at wall/non-face object
  2. Tap "Capture Face"
- **Expected:**
  - ✅ Warning message: "No face detected. Please try again."
  - ✅ Can retry immediately

### Test 2.5: **Multiple Faces**

- **Steps:**
  1. Have 2+ people in camera view
  2. Tap "Capture Face"
- **Expected:**
  - ✅ Uses first detected face
  - ✅ Successfully enrolls

---

## 4. **Main Screen / Attendance Logging Testing**

### Test 3.1: **Bluetooth Permission Denied**

- **Steps:**
  1. Navigate to Main Screen with BLE permissions denied
- **Expected:**
  - ✅ Status: "📱 Bluetooth and Location permissions required"
  - ✅ "Grant Permissions" button visible
  - ✅ No scanning occurs

### Test 3.2: **Bluetooth Turned Off**

- **Steps:**
  1. Turn off Bluetooth in device settings
  2. View Main Screen
- **Expected:**
  - ✅ Status: "📡 Bluetooth is turned off or unavailable"
  - ✅ "Grant Permissions" button visible
  - ✅ Guidance to enable Bluetooth

### Test 3.3: **Bluetooth Permission Granted**

- **Steps:**
  1. Tap "Grant Permissions"
  2. Allow all required permissions
- **Expected:**
  - ✅ Status: "✅ Permissions granted! Starting scan..."
  - ✅ Transitions to: "🔍 Scanning for nearby attendance sessions..."
  - ✅ Linear progress indicator appears

### Test 3.4: **BLE Beacon Detection**

- **Steps:**
  1. Ensure active session with BLE beacon nearby
  2. Wait for detection
- **Expected:**
  - ✅ Status: "📡 Session detected! Verifying..."
  - ✅ UUID card appears with detected session ID
  - ✅ Status changes to: "✅ Active attendance session found!"

### Test 3.5: **Enrollment Verification - Enrolled**

- **Steps:**
  1. Be enrolled in the detected course
  2. Wait for verification
- **Expected:**
  - ✅ Green enrollment card appears
  - ✅ Message: "✅ You are enrolled in this course\nTap below to log attendance"
  - ✅ "Log Attendance" button enabled

### Test 3.6: **Enrollment Verification - Not Enrolled**

- **Steps:**
  1. Detect session for non-enrolled course
- **Expected:**
  - ✅ Orange warning card appears
  - ✅ Message: "⚠️ You are NOT enrolled in this course"
  - ✅ "Log Attendance" button disabled

### Test 3.7: **Successful Attendance Logging**

- **Steps:**
  1. Be enrolled and session detected
  2. Tap "Log Attendance"
- **Expected:**
  - ✅ Button shows loading indicator
  - ✅ Status: "Logging attendance..."
  - ✅ Success snackbar: "✅ Your attendance has been recorded"
  - ✅ Status: "🎉 Attendance logged successfully!"
  - ✅ Button changes to "Attendance Logged" (disabled)
  - ✅ After 3 seconds, resets and starts new scan

### Test 3.8: **Duplicate Attendance Prevention**

- **Steps:**
  1. Log attendance successfully
  2. Try to tap button again before reset
- **Expected:**
  - ✅ Button disabled
  - ✅ OR shows message: "You have already logged attendance"

### Test 3.9: **Refresh Functionality**

- **Steps:**
  1. Pull down to refresh
  2. OR tap refresh icon in app bar
- **Expected:**
  - ✅ Resets all state
  - ✅ Starts new scan
  - ✅ Clears previous UUID/course info

### Test 3.10: **No Active Session**

- **Steps:**
  1. Detect BLE beacon with no active session
- **Expected:**
  - ✅ Status: "⚠️ No active session for this beacon. Keep scanning..."
  - ✅ Continues scanning for other beacons

### Test 3.11: **Network Error During Logging**

- **Steps:**
  1. Disable network after detection
  2. Try to log attendance
- **Expected:**
  - ✅ Error snackbar with network error message
  - ✅ Can retry after network restored

---

## 5. **App Lifecycle Testing**

### Test 4.1: **App Backgrounding During Scan**

- **Steps:**
  1. Start BLE scan
  2. Press Home button (background app)
  3. Wait 10 seconds
  4. Resume app
- **Expected:**
  - ✅ Scan stops when backgrounded (battery saving)
  - ✅ Scan resumes when app comes to foreground
  - ✅ No crash or state loss

### Test 4.2: **App Killing & Restart**

- **Steps:**
  1. Log in and enroll face
  2. Kill app completely
  3. Restart app
- **Expected:**
  - ✅ Splash screen appears
  - ✅ Checks stored authentication
  - ✅ Navigates directly to Main Screen (logged in)
  - ✅ Face data persists (no re-enrollment needed)

### Test 4.3: **Screen Rotation**

- **Steps:**
  1. On any screen, rotate device
- **Expected:**
  - ✅ UI adapts to new orientation
  - ✅ No state loss
  - ✅ No crashes

---

## 6. **Logout Testing**

### Test 5.1: **Logout Flow**

- **Steps:**
  1. From Main Screen, tap logout icon
  2. Confirm in dialog
- **Expected:**
  - ✅ Confirmation dialog appears
  - ✅ "Logout" and "Cancel" buttons visible
  - ✅ On "Logout", navigates to Login Screen
  - ✅ Authentication state cleared
  - ✅ BLE scan stops

### Test 5.2: **Logout Cancellation**

- **Steps:**
  1. Tap logout icon
  2. Tap "Cancel" in dialog
- **Expected:**
  - ✅ Dialog dismisses
  - ✅ Remains on Main Screen
  - ✅ Scanning continues

---

## 7. **UI/UX Polish Testing**

### Test 6.1: **Animations**

- **Verify:**
  - ✅ Splash screen fade-in (800ms)
  - ✅ Login screen fade-in (800ms)
  - ✅ Button hover effects
  - ✅ Snackbar slide-up animation

### Test 6.2: **Color Consistency**

- **Verify:**
  - ✅ Primary green (#2E7D32) used throughout
  - ✅ Success green for positive actions
  - ✅ Warning orange for alerts
  - ✅ Error red for failures
  - ✅ Info blue for help/guidance

### Test 6.3: **Typography**

- **Verify:**
  - ✅ Titles bold and prominent
  - ✅ Body text readable (size 14-16)
  - ✅ Monospace for UUID display
  - ✅ Consistent font weights

### Test 6.4: **Spacing & Alignment**

- **Verify:**
  - ✅ 16px padding on screens
  - ✅ 8-24px spacing between elements
  - ✅ Cards properly aligned
  - ✅ Buttons full-width where appropriate

---

## 8. **Error Scenarios Testing**

### Test 7.1: **Firebase Connection Lost**

- **Steps:**
  1. Block Firebase in firewall/hosts
  2. Attempt operations
- **Expected:**
  - ✅ Graceful error messages
  - ✅ No crashes
  - ✅ Can retry when connection restored

### Test 7.2: **Malformed Data**

- **Steps:**
  1. Manually corrupt Firestore data
  2. Attempt to log in / verify enrollment
- **Expected:**
  - ✅ Catches errors
  - ✅ Shows generic error message
  - ✅ Logs error details (AppLogger)

### Test 7.3: **Camera Failure**

- **Steps:**
  1. Use camera in another app
  2. Try face enrollment
- **Expected:**
  - ✅ Error message: "Camera error: [details]"
  - ✅ Can retry after closing other app

---

## 9. **Performance Testing**

### Test 8.1: **BLE Scan Battery Usage**

- **Steps:**
  1. Let app scan for 30 minutes
  2. Check battery usage in device settings
- **Expected:**
  - ✅ Reasonable battery consumption (<5% per hour)
  - ✅ Scan stops in background automatically

### Test 8.2: **Memory Leaks**

- **Steps:**
  1. Use app for extended period (30+ minutes)
  2. Navigate between screens multiple times
  3. Monitor memory usage
- **Expected:**
  - ✅ Memory stable (no continuous growth)
  - ✅ Proper disposal of resources

### Test 8.3: **App Size**

- **Verify:**
  - ✅ APK size reasonable (~40-60 MB)
  - ✅ No unnecessary assets included

---

## 10. **Security & Privacy Testing**

### Test 9.1: **Face Data Storage**

- **Steps:**
  1. Enroll face
  2. Check SharedPreferences
- **Verify:**
  - ✅ Only embeddings stored (not raw images)
  - ✅ Data encrypted by Android/iOS
  - ✅ Data cleared on logout

### Test 9.2: **Session Validation**

- **Steps:**
  1. Try to log attendance with invalid session UUID
- **Expected:**
  - ✅ Firestore rules prevent unauthorized access
  - ✅ Error handled gracefully

---

## 11. **Platform-Specific Testing**

### Android Specific:

#### Test 10.1: **Android 12+ Bluetooth Permissions**

- **Verify:**
  - ✅ BLUETOOTH_SCAN permission requested
  - ✅ BLUETOOTH_CONNECT permission requested
  - ✅ Location permission for BLE scanning

#### Test 10.2: **Android Navigation**

- **Verify:**
  - ✅ Back button behavior correct
  - ✅ App doesn't exit unexpectedly
  - ✅ Confirms before logout on back press (if implemented)

### iOS Specific (If Testing on iOS):

#### Test 10.3: **iOS Camera Permission**

- **Verify:**
  - ✅ Camera usage description in Info.plist
  - ✅ Permission dialog shows correct text

#### Test 10.4: **iOS Bluetooth Permission**

- **Verify:**
  - ✅ Bluetooth usage description in Info.plist
  - ✅ Permission dialog shows correct text

---

## 12. **Accessibility Testing**

### Test 11.1: **Screen Reader**

- **Steps:**
  1. Enable TalkBack (Android) or VoiceOver (iOS)
  2. Navigate app
- **Expected:**
  - ✅ All buttons have labels
  - ✅ Status messages read aloud
  - ✅ Navigation logical

### Test 11.2: **Font Scaling**

- **Steps:**
  1. Increase device font size to max
  2. Check all screens
- **Expected:**
  - ✅ Text scales properly
  - ✅ No overflow
  - ✅ Still readable

---

## 🎯 Test Summary Template

### Test Session Report:

**Date:** ________________
**Tester:** ________________
**Device:** ________________
**OS Version:** ________________
**App Version:** ________________

**Tests Passed:** ____ / ____
**Tests Failed:** ____ / ____
**Critical Issues:** ____
**Minor Issues:** ____

**Overall Status:** 🟢 Pass / 🟡 Pass with Issues / 🔴 Fail

---

## 🐛 Bug Report Template

**Bug ID:** ________________
**Severity:** Critical / Major / Minor
**Screen:** ________________
**Steps to Reproduce:**

**Expected Behavior:**

**Actual Behavior:**

**Screenshots/Logs:**

**Device Info:**

- Model:
- OS:
- App Version:

---

## ✅ Pre-Release Checklist

Before deploying to production:

- [ ] All critical tests passed
- [ ] No unhandled crashes
- [ ] Performance acceptable
- [ ] Battery usage reasonable
- [ ] Security verified
- [ ] Privacy policies followed
- [ ] Firebase configured correctly
- [ ] API keys secured
- [ ] Error logging enabled
- [ ] Analytics configured (if applicable)
- [ ] App store metadata prepared
- [ ] Screenshots captured
- [ ] Release notes written
- [ ] Version number updated
- [ ] Signed APK/IPA generated
- [ ] Beta testing completed
- [ ] User documentation ready

---

**Status:** Ready for testing ✅
