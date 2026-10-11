import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Mengelola penyimpanan sesi lokal (JWT token, user profile).
class SessionStore {
  static const String _tokenKey = 'tamjid_auth_token';
  static const String _userKey = 'tamjid_auth_user';

  static final SessionStore _instance = SessionStore._internal();
  factory SessionStore() => _instance;
  SessionStore._internal();

  String? _token;
  Map<String, dynamic>? _userData;

  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        _userData = jsonDecode(rawUser) as Map<String, dynamic>;
      } catch (_) {
        _userData = null;
      }
    }
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    _token = token;
    _userData = userData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  Future<void> clearSession() async {
    _token = null;
    _userData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
