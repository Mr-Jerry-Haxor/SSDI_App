import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class AdminCRUDService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== COURSES ====================
  
  Future<List<Map<String, dynamic>>> fetchAllCourses() async {
    try {
      final querySnapshot = await _db.collection('Courses').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'CourseName': data['CourseName'] ?? '',
          'CourseCode': data['CourseCode'] ?? '',
          'professorEmail': data['professorEmail'] ?? '',
          'Semester': data['Semester'] ?? '',
          'Section': data['Section'] ?? '',
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching courses', e);
      return [];
    }
  }

  Future<bool> addCourse(String courseCode, Map<String, dynamic> courseData) async {
    try {
      await _db.collection('Courses').doc(courseCode).set(courseData);
      return true;
    } catch (e) {
      AppLogger.error('Error adding course', e);
      return false;
    }
  }

  Future<bool> updateCourse(String courseId, Map<String, dynamic> courseData) async {
    try {
      await _db.collection('Courses').doc(courseId).update(courseData);
      return true;
    } catch (e) {
      AppLogger.error('Error updating course', e);
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      // Delete all schedules first
      final schedules = await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .get();
      
      for (var schedule in schedules.docs) {
        await schedule.reference.delete();
      }
      
      // Delete course
      await _db.collection('Courses').doc(courseId).delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting course', e);
      return false;
    }
  }

  // ==================== PROFESSORS ====================
  
  Future<List<Map<String, dynamic>>> fetchAllProfessors() async {
    try {
      final querySnapshot = await _db.collection('Professor').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'Name': data['Name'] ?? '',
          'email': data['email'] ?? '',
          'Department': data['Department'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'coursesTaught': data['coursesTaught'] ?? [],
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching professors', e);
      return [];
    }
  }

  Future<bool> addProfessor(Map<String, dynamic> professorData) async {
    try {
      await _db.collection('Professor').add(professorData);
      return true;
    } catch (e) {
      AppLogger.error('Error adding professor', e);
      return false;
    }
  }

  Future<bool> updateProfessor(String professorId, Map<String, dynamic> professorData) async {
    try {
      await _db.collection('Professor').doc(professorId).update(professorData);
      return true;
    } catch (e) {
      AppLogger.error('Error updating professor', e);
      return false;
    }
  }

  Future<bool> deleteProfessor(String professorId) async {
    try {
      await _db.collection('Professor').doc(professorId).delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting professor', e);
      return false;
    }
  }

  // ==================== SEMESTERS ====================
  
  Future<List<Map<String, dynamic>>> fetchAllSemesters() async {
    try {
      final querySnapshot = await _db.collection('Semester').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'Name': data['Name'] ?? '',
          'StartDate': data['StartDate'] ?? '',
          'EndDate': data['EndDate'] ?? '',
          'Year': data['Year'] ?? '',
          'Status': data['Status'] ?? 'Inactive',
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching semesters', e);
      return [];
    }
  }

  Future<bool> addSemester(Map<String, dynamic> semesterData) async {
    try {
      await _db.collection('Semester').add(semesterData);
      return true;
    } catch (e) {
      AppLogger.error('Error adding semester', e);
      return false;
    }
  }

  Future<bool> updateSemester(String semesterId, Map<String, dynamic> semesterData) async {
    try {
      await _db.collection('Semester').doc(semesterId).update(semesterData);
      return true;
    } catch (e) {
      AppLogger.error('Error updating semester', e);
      return false;
    }
  }

  Future<bool> deleteSemester(String semesterId) async {
    try {
      await _db.collection('Semester').doc(semesterId).delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting semester', e);
      return false;
    }
  }

  // ==================== STUDENTS ====================
  
  Future<List<Map<String, dynamic>>> fetchAllStudents() async {
    try {
      final querySnapshot = await _db.collection('student').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Normalize student document fields to expected keys used by UI
        final firstName = (data['FirstName'] as String?) ?? (data['firstName'] as String?) ?? '';
        final lastName = (data['LastName'] as String?) ?? (data['lastName'] as String?) ?? '';
        final name = (data['name'] as String?) ?? (('$firstName $lastName').trim());
        final email = (data['Email'] as String?) ?? (data['email'] as String?) ?? '';
        final department = (data['Department'] as String?) ?? (data['department'] as String?) ?? '';
        final enrolledCourses = (data['enrolledCourses'] is List) ? List<String>.from(data['enrolledCourses']) :
            ((data['StudentsEnrolled'] is List) ? List<String>.from(data['StudentsEnrolled']) : <String>[]);

        return {
          'id': doc.id,
          'name': name,
          'email': email,
          'FirstName': firstName,
          'LastName': lastName,
          'studentId': data['studentId'] ?? data['studentID'] ?? doc.id,
          'password': data['password'] ?? '',
          'department': department,
          'enrolledCourses': enrolledCourses,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching students', e);
      return [];
    }
  }

  Future<bool> addStudent(String studentId, Map<String, dynamic> studentData) async {
    try {
      await _db.collection('student').doc(studentId).set(studentData);
      return true;
    } catch (e) {
      AppLogger.error('Error adding student', e);
      return false;
    }
  }

  Future<bool> updateStudent(String studentId, Map<String, dynamic> studentData) async {
    try {
      await _db.collection('student').doc(studentId).update(studentData);
      return true;
    } catch (e) {
      AppLogger.error('Error updating student', e);
      return false;
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    try {
      await _db.collection('student').doc(studentId).delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting student', e);
      return false;
    }
  }

  // ==================== COURSE SCHEDULES ====================
  
  Future<List<Map<String, dynamic>>> fetchCourseSchedules(String courseId) async {
    try {
      final querySnapshot = await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'Day': data['Day'] ?? '',
          'StartTime': data['StartTime'] ?? '',
          'EndTime': data['EndTime'] ?? '',
          'Semester': data['Semester'] ?? '',
          'RoomNumber': data['RoomNumber'] ?? '',
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching course schedules', e);
      return [];
    }
  }

  Future<bool> addCourseSchedule(String courseId, Map<String, dynamic> scheduleData) async {
    try {
      await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .add(scheduleData);
      return true;
    } catch (e) {
      AppLogger.error('Error adding schedule', e);
      return false;
    }
  }

  Future<bool> updateCourseSchedule(
      String courseId, String scheduleId, Map<String, dynamic> scheduleData) async {
    try {
      await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .doc(scheduleId)
          .update(scheduleData);
      return true;
    } catch (e) {
      AppLogger.error('Error updating schedule', e);
      return false;
    }
  }

  Future<bool> deleteCourseSchedule(String courseId, String scheduleId) async {
    try {
      await _db
          .collection('Courses')
          .doc(courseId)
          .collection('Schedule')
          .doc(scheduleId)
          .delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting schedule', e);
      return false;
    }
  }

  // ==================== HELPER METHODS ====================
  
  /// Get all course codes for multi-select
  Future<List<String>> fetchAllCourseCodes() async {
    try {
      final querySnapshot = await _db.collection('Courses').get();
      return querySnapshot.docs
          .map((doc) => doc.data()['CourseCode'] as String?)
          .where((code) => code != null)
          .cast<String>()
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching course codes', e);
      return [];
    }
  }

  /// Get all student IDs for multi-select
  Future<List<Map<String, String>>> fetchAllStudentOptions() async {
    try {
      final querySnapshot = await _db.collection('student').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': '${data['FirstName']} ${data['LastName']} (${doc.id})',
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching student options', e);
      return [];
    }
  }

  /// Get all semester names for multi-select
  Future<List<String>> fetchAllSemesterNames() async {
    try {
      final querySnapshot = await _db.collection('Semester').get();
      return querySnapshot.docs
          .map((doc) => doc.data()['Name'] as String?)
          .where((name) => name != null)
          .cast<String>()
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching semester names', e);
      return [];
    }
  }

  /// Get all professor emails for multi-select
  Future<List<Map<String, String>>> fetchAllProfessorOptions() async {
    try {
      final querySnapshot = await _db.collection('Professor').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'email': data['email'] as String,
          'name': data['Name'] as String,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching professor options', e);
      return [];
    }
  }
}

