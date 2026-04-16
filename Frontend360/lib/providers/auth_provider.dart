import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster360/services/api_service.dart';

class User {
  final String id;
  final String email;
  final String role;

  User({required this.id, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  String? _token;
  bool _isLoading = true;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    if (_token != null) {
      try {
        await fetchProfile();
      } catch (e) {
        // Token might be expired
        await logout();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final response = await _apiService.get('/auth/profile');
    _user = User.fromJson(response);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        body: {
          'username': email, 
          'password': password
        },
        isForm: true,
      );
      
      _token = response['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      
      await fetchProfile();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> register(String email, String password, String role) async {
    try {
      final response = await _apiService.post('/auth/register', body: {
        'email': email,
        'password': password,
        'role': role.toLowerCase(),
      });
      
      // Auto-login only if citizen
      if (role.toLowerCase() == 'citizen') {
        await login(email, password);
      }
      return response['message'] ?? 'Registered successfully';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
