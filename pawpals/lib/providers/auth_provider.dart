import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // For storing auth token

import '../models/user_model.dart'; // Assuming UserModel is updated for PostgreSQL

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

class AuthProvider extends ChangeNotifier {
  // Replace with your actual API base URL
  final String _apiBaseUrl = 'http://localhost:5000/api/auth'; // Example Flask API URL

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _authToken;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get authToken => _authToken;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _authToken != null;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('authToken') || !prefs.containsKey('userData')) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _authToken = prefs.getString('authToken');
    final userDataString = prefs.getString('userData');
    if (_authToken == null || userDataString == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = UserModel.fromJson(json.decode(userDataString));
      _status = AuthStatus.authenticated;
      // Optionally: Validate token with API here
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      // Clear invalid stored data
      await prefs.remove('authToken');
      await prefs.remove('userData');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Email and password cannot be empty';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _user = UserModel.fromJson(responseData['user']);
        _authToken = responseData['token'];
        _status = AuthStatus.authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', _authToken!);
        await prefs.setString('userData', json.encode(_user!.toJson()));

        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Login failed. Please check your credentials.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        _errorMessage = 'All fields are required';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) { // Assuming 201 for successful creation
        final responseData = json.decode(response.body);
        _user = UserModel.fromJson(responseData['user']);
        _authToken = responseData['token'];
        _status = AuthStatus.authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', _authToken!);
        await prefs.setString('userData', json.encode(_user!.toJson()));
        
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Registration failed.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = null;
    notifyListeners(); // For potential loading state

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        // UI should show a success message based on this return
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to send password reset email.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _authToken = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userData');
    // Optionally: Call a /logout endpoint on the API to invalidate server-side session/token if any
    // try {
    //   await http.post(Uri.parse('$_apiBaseUrl/logout'), headers: {'Authorization': 'Bearer $_authToken'});
    // } catch (e) {
    //   // Log error, but proceed with client-side logout
    // }
    notifyListeners();
  }

  // This method might be used to validate token or refresh user data
  Future<void> checkAuthStatus() async {
    if (_authToken == null) {
      await _tryAutoLogin(); // Attempt to load from storage if not already loaded
      return;
    }
    // If token exists, you might want to validate it with the server
    // For simplicity, we assume if token is present and user data loaded, it's authenticated.
    // A more robust implementation would call an API endpoint like /me or /validate-token
    if (_status != AuthStatus.authenticated) { // If auto-login failed or wasn't attempted
        _status = AuthStatus.unauthenticated;
        notifyListeners();
    }
  }
}

