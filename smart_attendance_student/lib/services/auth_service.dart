import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  String? _studentId;
  String? _studentName;
  String? _email;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get studentId => _studentId;
  String? get studentName => _studentName;
  String? get email => _email;

  void login(String studentId, String name, String email) {
    _studentId = studentId;
    _studentName = name;
    _email = email;
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _studentId = null;
    _studentName = null;
    _email = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
