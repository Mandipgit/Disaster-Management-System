import 'package:flutter/material.dart';
import 'package:disaster360/services/api_service.dart';
import 'package:disaster360/services/session_service.dart';
export 'package:disaster360/models/user_model.dart'; // Export to prevent breaking other files
import 'package:disaster360/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SessionService _sessionService = SessionService();
  
  bool _isLoading = true;

  User? get user => _sessionService.currentUser;
  String? get token => _sessionService.token;
  bool get isAuthenticated => _sessionService.token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Listen to changes from SessionService
    _sessionService.sessionStream.listen((_) {
      notifyListeners();
    });
    _syncWithSession();
  }

  Future<void> _syncWithSession() async {
    if (_sessionService.token != null && _sessionService.currentUser == null) {
      // In case session service has token but no user, try to fetch profile
      try {
        await fetchProfile();
      } catch (e) {
        await logout();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final response = await _apiService.get('/auth/profile');
    final fetchedUser = User.fromJson(response);
    
    if (_sessionService.token != null) {
      await _sessionService.saveSession(_sessionService.token!, fetchedUser);
    }
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
      
      final newToken = response['access_token'];
      // Fetch profile immediately to complete session setup
      final profileResponse = await _apiService.get('/auth/profile', headers: {'Authorization': 'Bearer $newToken'});
      final newUser = User.fromJson(profileResponse);
      
      await _sessionService.saveSession(newToken, newUser);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    try {
      await _apiService.post(
        '/auth/profile',
        body: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
        },
      );
      await fetchProfile();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> register(String email, String password, String role, {String? fullName, String? phone, String? citizenshipNumber, String? citizenshipIssueDistrict, String? citizenshipIssueDate}) async {
    try {
      final response = await _apiService.post('/auth/register', body: {
        'email': email,
        'password': password,
        'role': role.toLowerCase(),
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (citizenshipNumber != null) 'citizenship_number': citizenshipNumber,
        if (citizenshipIssueDistrict != null) 'citizenship_issue_district': citizenshipIssueDistrict,
        if (citizenshipIssueDate != null) 'citizenship_issue_date': citizenshipIssueDate,
      });
      
      // Remove auto-login. User must verify email first.
      return response['message'] ?? 'Registered successfully';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _sessionService.clearSession();
  }

  Future<String> resendVerification(String email) async {
    try {
      final response = await _apiService.post('/auth/resend-verification', body: {
        'email': email,
      });
      return response['message'] ?? 'Verification email sent';
    } catch (e) {
      rethrow;
    }
  }
}
