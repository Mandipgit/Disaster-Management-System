import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:disaster360/models/user_model.dart';

class SessionService {
  // Singleton pattern
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  User? _currentUser;
  String? _token;
  
  final StreamController<User?> _sessionController = StreamController<User?>.broadcast();

  Stream<User?> get sessionStream => _sessionController.stream;
  User? get currentUser => _currentUser;
  String? get token => _token;

  Future<void> initialize() async {
    _token = await _storage.read(key: 'auth_token');
    final userJsonStr = await _storage.read(key: 'user_profile');
    
    if (_token != null && userJsonStr != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        _currentUser = User.fromJson(userMap);
      } catch (e) {
        _currentUser = null;
        _token = null;
      }
    } else {
      _currentUser = null;
      _token = null;
    }
    
    _sessionController.add(_currentUser);
  }

  Future<void> saveSession(String token, User user) async {
    _token = token;
    _currentUser = user;
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_profile', value: jsonEncode(user.toJson()));
    _sessionController.add(_currentUser);
  }

  Future<void> clearSession() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_profile');
    _sessionController.add(null);
  }
}
