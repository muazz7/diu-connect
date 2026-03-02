import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  String? _userName;
  String? _role;
  String? _email;
  String? _studentId;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get role => _role;
  String? get email => _email;
  String? get studentId => _studentId;

  String get baseUrl => ApiConfig.baseUrl;

  // ── Demo accounts for testing ──
  static const _demoAccounts = {
    'student@diu.edu.bd': {
      'password': 'password123',
      'name': 'Demo Student',
      'role': 'STUDENT',
      'id': 'demo-student-001',
      'studentId': '242-35-123',
    },
    'teacher@gmail.com': {
      'password': 'password123',
      'name': 'Demo Teacher',
      'role': 'TEACHER',
      'id': 'demo-teacher-001',
    },
    'admin@gmail.com': {
      'password': 'password123',
      'name': 'Admin',
      'role': 'ADMIN',
      'id': 'demo-admin-001',
    },
  };

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    final savedUserId = prefs.getString('userId');
    final savedUserName = prefs.getString('userName');
    final savedRole = prefs.getString('role');
    final savedEmail = prefs.getString('email');
    final savedStudentId = prefs.getString('studentId');

    if (savedToken != null && savedUserId != null && savedRole != null) {
      _token = savedToken;
      _userId = savedUserId;
      _userName = savedUserName;
      _role = savedRole;
      _email = savedEmail;
      _studentId = savedStudentId;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Check demo accounts first
    final demo = _demoAccounts[email.toLowerCase().trim()];
    if (demo != null) {
      await Future.delayed(const Duration(milliseconds: 400)); // Simulate
      _isLoading = false;

      if (demo['password'] == password) {
        _token = 'demo-token-${demo['id']}';
        _userId = demo['id'];
        _userName = demo['name'];
        _role = demo['role'];
        _email = email.toLowerCase().trim();
        _studentId = demo['studentId'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userId', _userId!);
        await prefs.setString('userName', _userName ?? '');
        await prefs.setString('role', _role!);
        await prefs.setString('email', _email!);
        if (_studentId != null) await prefs.setString('studentId', _studentId!);

        notifyListeners();
        return {'success': true};
      } else {
        notifyListeners();
        return {'success': false, 'error': 'Incorrect password'};
      }
    }

    // Real API login
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _userId = data['user']['id'];
        _userName = data['user']['name'];
        _role = data['user']['role'];
        _email = data['user']['email'] ?? email.trim();
        _studentId = data['user']['studentId'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userId', _userId!);
        await prefs.setString('userName', _userName ?? '');
        await prefs.setString('role', _role!);
        if (_email != null) await prefs.setString('email', _email!);
        if (_studentId != null) await prefs.setString('studentId', _studentId!);

        notifyListeners();
        return {'success': true};
      }

      final errorData = jsonDecode(response.body);
      notifyListeners();
      return {'success': false, 'error': errorData['error'] ?? 'Login failed'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password, String role,
      {String? studentId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'studentId': studentId,
        }),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        return {'success': true};
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['error'] ?? 'Registration failed'
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userName = null;
    _role = null;
    _email = null;
    _studentId = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
