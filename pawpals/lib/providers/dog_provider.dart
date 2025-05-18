import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // To get auth token

import '../models/dog_model.dart'; // Assuming DogModel is compatible
// import '../services/api_service.dart'; // A dedicated API service would be better

class DogProvider extends ChangeNotifier {
  // Replace with your actual API base URL
  final String _apiBaseUrl = 'http://localhost:5000/api'; // Example Flask API URL
  List<DogModel> _dogs = [];
  bool _isLoading = false;
  String? _errorMessage;
  DogModel? _lastAddedDog;
  bool _dogJustAdded = false;

  List<DogModel> get dogs => _dogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DogModel? get lastAddedDog => _lastAddedDog;
  bool get dogJustAdded => _dogJustAdded;

  // Helper to get auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  void resetDogJustAdded() {
    _dogJustAdded = false;
    // notifyListeners(); // Only notify if this state change should trigger UI update directly
  }

  Future<void> loadDogs(String userId) async { // userId might not be needed if API infers from token
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated.';
      _isLoading = false;
      _status = AuthStatus.unauthenticated; // Assuming AuthStatus enum is accessible or handled
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/dogs'), // Endpoint to get dogs for the authenticated user
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _dogs = responseData.map((data) => DogModel.fromJson(data)).toList();
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to load dogs.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addDog(DogModel dog, String userId) async { // userId might be inferred from token on backend
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
      // DogModel.toJson() should produce a map compatible with the API
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/dogs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dog.toJson()), // Assuming dog.toJson() exists and is correct
      );

      if (response.statusCode == 201) { // 201 Created
        final newDogData = json.decode(response.body);
        final newDog = DogModel.fromJson(newDogData); // API should return the created dog with ID
        _dogs.add(newDog);
        _lastAddedDog = newDog;
        _dogJustAdded = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to add dog.';
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

  Future<bool> updateDog(DogModel updatedDog) async {
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
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/dogs/${updatedDog.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedDog.toJson()), // Assuming updatedDog.toJson() exists
      );

      if (response.statusCode == 200) {
        final index = _dogs.indexWhere((dog) => dog.id == updatedDog.id);
        if (index != -1) {
          _dogs[index] = DogModel.fromJson(json.decode(response.body)); // API returns updated dog
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to update dog.';
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

  Future<bool> deleteDog(String dogId) async {
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
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/dogs/$dogId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content is also common for DELETE
        _dogs.removeWhere((dog) => dog.id == dogId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to delete dog.';
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

  DogModel? getDogById(String dogId) {
    try {
      return _dogs.firstWhere((dog) => dog.id == dogId);
    } catch (e) {
      // If not found, or _dogs is empty
      return null;
    }
  }
}

// Placeholder for AuthStatus if not globally available or imported from AuthProvider
// enum AuthStatus { initial, authenticated, unauthenticated, authenticating, error }

