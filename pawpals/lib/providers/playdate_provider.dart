import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playdate_model.dart'; // Ensure PlaydateModel is compatible

class PlaydateProvider extends ChangeNotifier {
  final String _apiBaseUrl = 'http://localhost:5000/api'; // Example Flask API URL
  List<PlaydateModel> _playdates = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PlaydateModel> get playdates => _playdates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Get upcoming playdates for a specific dog ID (owned by the user or involved)
  Future<void> loadUpcomingPlaydatesForDog(String dogId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playdates/dog/$dogId?status=upcoming'), // Example endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _playdates = responseData.map((data) => PlaydateModel.fromJson(data)).toList();
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to load upcoming playdates.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Get all playdates for a specific dog ID
  Future<void> loadAllPlaydatesForDog(String dogId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playdates/dog/$dogId'), // Example endpoint for all playdates of a dog
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _playdates = responseData.map((data) => PlaydateModel.fromJson(data)).toList();
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to load all playdates.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
  }
  
  // Load all playdates for the authenticated user (across all their dogs)
  Future<void> loadUserPlaydates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playdates/user'), // Endpoint for user's playdates
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _playdates = responseData.map((data) => PlaydateModel.fromJson(data)).toList();
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to load user playdates.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPlaydate(PlaydateModel playdate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playdates'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(playdate.toJson()), // Ensure PlaydateModel has toJson()
      );

      if (response.statusCode == 201) {
        final newPlaydate = PlaydateModel.fromJson(json.decode(response.body));
        _playdates.add(newPlaydate);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to create playdate.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlaydateStatus(String playdateId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.patch( // Using PATCH for partial update (status only)
        Uri.parse('$_apiBaseUrl/playdates/$playdateId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final updatedPlaydate = PlaydateModel.fromJson(json.decode(response.body));
        final index = _playdates.indexWhere((p) => p.id == playdateId);
        if (index != -1) {
          _playdates[index] = updatedPlaydate;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to update playdate status.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelPlaydate(String playdateId) async {
    return updatePlaydateStatus(playdateId, 'cancelled'); // Using the ENUM value from schema
  }

  Future<bool> acceptPlaydate(String playdateId) async {
    return updatePlaydateStatus(playdateId, 'accepted');
  }

  Future<bool> rejectPlaydate(String playdateId) async {
    return updatePlaydateStatus(playdateId, 'declined');
  }

  Future<bool> completePlaydate(String playdateId) async {
    return updatePlaydateStatus(playdateId, 'completed');
  }
}

