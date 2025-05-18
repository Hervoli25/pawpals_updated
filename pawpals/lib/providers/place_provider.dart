import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place_model.dart'; // Ensure PlaceModel is compatible with new schema

class PlaceProvider extends ChangeNotifier {
  final String _apiBaseUrl = 'http://localhost:5000/api'; // Example Flask API URL
  List<PlaceModel> _places = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PlaceModel> get places => _places;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Get places by category - now fetches from API
  Future<void> loadPlacesByCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    // Some place fetching might be public, some might need auth
    // Adjust headers if token is not needed for this specific endpoint
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/places?category=$category'), // Example API endpoint
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _places = responseData.map((data) => PlaceModel.fromJson(data)).toList();
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to load places by category.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Get nearby places - now fetches from API
  Future<List<PlaceModel>> getNearbyPlaces(
    double latitude,
    double longitude,
    double radiusInKm, {
    String? category, // Optional category filter
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    List<PlaceModel> nearbyPlaces = [];
    try {
      String url = '$_apiBaseUrl/places/nearby?latitude=$latitude&longitude=$longitude&radius=$radiusInKm';
      if (category != null && category.isNotEmpty) {
        url += '&category=$category';
      }
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        nearbyPlaces = responseData.map((data) => PlaceModel.fromJson(data)).toList();
        _places = nearbyPlaces; // Optionally update the main list or handle separately
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to get nearby places.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
    return nearbyPlaces;
  }

  // Load all places (or a paginated list) - now fetches from API
  Future<void> loadPlaces({Map<String, String>? queryParams}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    String queryString = Uri(queryParameters: queryParams).query;
    final url = Uri.parse('$_apiBaseUrl/places${queryString.isNotEmpty ? '?$queryString' : ''}');

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _places = responseData.map((data) => PlaceModel.fromJson(data)).toList();
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to load places.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<PlaceModel?> getPlaceDetails(String placeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/places/$placeId'), headers: headers);
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return PlaceModel.fromJson(json.decode(response.body));
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to load place details.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> addPlace(PlaceModel place) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated to add a place.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/places'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(place.toJson()), // Ensure PlaceModel has toJson()
      );

      if (response.statusCode == 201) {
        final newPlace = PlaceModel.fromJson(json.decode(response.body));
        _places.add(newPlace);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to add place.';
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

  Future<bool> updatePlace(PlaceModel updatedPlace) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated to update a place.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/places/${updatedPlace.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedPlace.toJson()),
      );

      if (response.statusCode == 200) {
        final index = _places.indexWhere((p) => p.id == updatedPlace.id);
        if (index != -1) {
          _places[index] = PlaceModel.fromJson(json.decode(response.body));
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to update place.';
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

  Future<bool> deletePlace(String placeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'User not authenticated to delete a place.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/places/$placeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _places.removeWhere((p) => p.id == placeId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = json.decode(response.body)['message'] ?? 'Failed to delete place.';
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
}

