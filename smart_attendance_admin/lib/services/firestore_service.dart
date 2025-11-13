import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Login professor
  Future<Map<String, dynamic>?> loginProfessor(String email, String password) async {
    try {
      final querySnapshot = await _db
          .collection('Professor')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final storedPassword = doc.data()['password'];

      if (storedPassword == password) {
        return {
          'id': doc.id,
          'name': doc.data()['Name'],
          'email': email,
        };
      }

      return null;
    } catch (e) {
      AppLogger.error('Login error', e);
      return null;
    }
  }

  // Fetch professor's courses
  Future<List<String>> fetchProfessorCourses(String professorId) async {
    try {
      final doc = await _db.collection('Professor').doc(professorId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final courses = data['coursesTaught'];
        if (courses is List) {
          return List<String>.from(courses);
        }
      }
      return [];
    } catch (e) {
      AppLogger.error('Error fetching courses', e);
      return [];
    }
  }

  // Fetch course details
  Future<Map<String, dynamic>?> fetchCourseDetails(String courseId) async {
    try {
      final doc = await _db.collection('Courses').doc(courseId).get();
      if (doc.exists) {
        return {'id': courseId, 'name': doc.data()?['CourseName']};
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching course', e);
      return null;
    }
  }

  // Fetch schedule for course
  Future<Map<String, dynamic>?> fetchSchedule(String courseId) async {
    try {
      final querySnapshot = await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return {
          'id': doc.id,
          'day': data['Day'],
          'startTime': data['StartTime'],
          'endTime': data['EndTime'],
          'semesterId': data['Semester'],
        };
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching schedule', e);
      return null;
    }
  }

  // Fetch semester details
  Future<String> fetchSemesterName(String semesterId) async {
    try {
      final doc = await _db.collection('Semester').doc(semesterId).get();
      if (doc.exists) {
        return doc.data()?['Name'] ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      AppLogger.error('Error fetching semester', e);
      return 'Unknown';
    }
  }

  // Check for existing active session
  Future<String?> checkExistingActiveSession(
      String courseId, String scheduleId, String date) async {
    try {
      final doc = await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .doc(scheduleId)
          .collection('Attendance')
          .doc(date)
          .get();

      if (doc.exists && doc.data() != null) {
        final sessions = doc.data()!;
        for (var entry in sessions.entries) {
          if (entry.value is Map) {
            final sessionData = entry.value as Map<String, dynamic>;
            if (sessionData['Status'] == 'Active') {
              return sessionData['SessionUUID'] as String?;
            }
          }
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Error checking active session', e);
      return null;
    }
  }

  // Close existing session
  Future<void> closeSession(
      String courseId, String scheduleId, String date, String uuid) async {
    try {
      await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .doc(scheduleId)
          .collection('Attendance')
          .doc(date)
          .update({'$uuid.Status': 'Closed'});
    } catch (e) {
      AppLogger.error('Error closing session', e);
    }
  }

  // Write attendance session to Firestore
  Future<void> writeAttendanceSession(
      String courseId, String scheduleId, String date, String uuid) async {
    try {
      final docRef = _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .doc(scheduleId)
          .collection('Attendance')
          .doc(date);

      await docRef.set({
        uuid: {
          'SessionUUID': uuid,
          'Status': 'Active',
          'timestamp': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Error writing attendance', e);
    }
  }

  // Update session status
  Future<void> updateSessionStatus(
      String courseId, String scheduleId, String date, String uuid) async {
    try {
      await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .doc(scheduleId)
          .collection('Attendance')
          .doc(date)
          .update({'$uuid.Status': 'Closed'});
    } catch (e) {
      AppLogger.error('Error updating session', e);
    }
  }
}
