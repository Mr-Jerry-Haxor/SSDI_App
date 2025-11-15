import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Login student
  Future<Map<String, dynamic>?> loginStudent(String email, String password) async {
    try {
      final querySnapshot = await _db
          .collection('student')
          .where('Email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return {
          'id': doc.id,
          'firstName': data['FirstName'],
          'lastName': data['LastName'],
          'email': email,
        };
      }

      return null;
    } catch (e) {
      AppLogger.error('Login error', e);
      return null;
    }
  }

  // Check for active sessions
  Future<Map<String, dynamic>?> checkActiveSessionInFirestore(String scannedUuid) async {
    try {
      final querySnapshot = await _db.collectionGroup('Attendance').get();

      for (var document in querySnapshot.docs) {
        final data = document.data();

        for (var entry in data.entries) {
          if (entry.value is! Map) continue;

          final session = entry.value as Map<String, dynamic>;
          final storedUUID = session['SessionUUID'];
          final status = session['Status'];

          if (status == 'Active' && storedUUID != null) {
            final attendanceDoc = document.reference;
            final scheduleId = attendanceDoc.parent.parent?.id;
            final courseId = attendanceDoc.parent.parent?.parent.parent?.id;

            return {
              'sessionUUID': storedUUID,
              'courseId': courseId,
              'scheduleId': scheduleId,
            };
          }
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('Error checking active session', e);
      return null;
    }
  }

  // Verify student enrollment
  Future<bool> verifyStudentEnrollment(
      String courseId, String scheduleId, String studentId) async {
    try {
      final doc = await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .doc(scheduleId)
          .get();

      if (doc.exists) {
        final enrolled = doc.data()?['StudentsEnrolled'];
        if (enrolled is List) {
          return enrolled.contains(studentId);
        }
      }

      return false;
    } catch (e) {
      AppLogger.error('Error verifying enrollment', e);
      return false;
    }
  }

  // Log attendance
  Future<bool> logAttendance(
      String courseId, String scheduleId, String date, String uuid, String studentId) async {
    try {
      final attendanceDoc = _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .doc(scheduleId)
          .collection('Attendance')
          .doc(date);

      await attendanceDoc.update({
        '$uuid.StudentAttendanceData.$studentId': {
          'status': 'Present',
          'timestamp': FieldValue.serverTimestamp(),
        }
      });

      return true;
    } catch (e) {
      AppLogger.error('Error logging attendance', e);
      return false;
    }
  }

  // Create student (signup)
  Future<bool> createStudent({
    required String studentId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final docRef = _db.collection('student').doc(studentId);

      final doc = await docRef.get();
      if (doc.exists) {
        // Student ID already taken
        return false;
      }

      await docRef.set({
        'Email': email,
        'password': password,
        'FirstName': firstName,
        'LastName': lastName,
        'StudentID': studentId,
      });

      return true;
    } catch (e) {
      AppLogger.error('Error creating student', e);
      return false;
    }
  }
}
