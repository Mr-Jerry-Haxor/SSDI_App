import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  String? _professorId;
  String? _email;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get professorId => _professorId;
  String? get email => _email;

  void login(String professorId, String email) {
    _professorId = professorId;
    _email = email;
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _professorId = null;
    _email = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
