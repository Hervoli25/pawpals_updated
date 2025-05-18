import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class PlacesService {
  // Replace with your actual API base URL
  final String _apiBaseUrl = 'http://localhost:5000/api';

  // Helper to get auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Get all places
  Future<List<PlaceModel>> getPlaces() async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/places'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return PlaceModel(
            id: item['id'],
            name: item['name'] ?? 'Unknown Place',
            category: item['type'] ?? 'Other',
            latitude: item['location_latitude'],
            longitude: item['location_longitude'],
            address: '${item['address_street'] ?? ''}, ${item['address_city'] ?? ''}',
            description: item['description'],
            photoUrl: item['images_urls']?.isNotEmpty == true ? item['images_urls'][0] : null,
            rating: item['rating'] != null ? (item['rating'] as num).toDouble() : null,
            amenities: item['amenities'] as Map<String, dynamic>?,
          );
        }).toList();
      } else {
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get places by category
  Future<List<PlaceModel>> getPlacesByCategory(String category) async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/places?type=$category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return PlaceModel(
            id: item['id'],
            name: item['name'] ?? 'Unknown Place',
            category: item['type'] ?? 'Other',
            latitude: item['location_latitude'],
            longitude: item['location_longitude'],
            address: '${item['address_street'] ?? ''}, ${item['address_city'] ?? ''}',
            description: item['description'],
            photoUrl: item['images_urls']?.isNotEmpty == true ? item['images_urls'][0] : null,
            rating: item['rating'] != null ? (item['rating'] as num).toDouble() : null,
            amenities: item['amenities'] as Map<String, dynamic>?,
          );
        }).toList();
      } else {
        throw Exception('Failed to load places by category: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get nearby places
  Future<List<PlaceModel>> getNearbyPlaces(
    double latitude,
    double longitude,
    double radiusInKm,
  ) async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/places/nearby?lat=$latitude&lng=$longitude&radius=$radiusInKm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return PlaceModel(
            id: item['id'],
            name: item['name'] ?? 'Unknown Place',
            category: item['type'] ?? 'Other',
            latitude: item['location_latitude'],
            longitude: item['location_longitude'],
            address: '${item['address_street'] ?? ''}, ${item['address_city'] ?? ''}',
            description: item['description'],
            photoUrl: item['images_urls']?.isNotEmpty == true ? item['images_urls'][0] : null,
            rating: item['rating'] != null ? (item['rating'] as num).toDouble() : null,
            amenities: item['amenities'] as Map<String, dynamic>?,
          );
        }).toList();
      } else {
        throw Exception('Failed to load nearby places: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add a new place
  Future<PlaceModel> addPlace(PlaceModel place) async {
    try {
      final token = await _getAuthToken();
      
      final data = {
        'name': place.name,
        'type': place.category,
        'location_latitude': place.latitude,
        'location_longitude': place.longitude,
        'address_street': place.address?.split(',')[0]?.trim(),
        'address_city': place.address?.split(',').length > 1 ? place.address?.split(',')[1]?.trim() : null,
        'description': place.description,
        'images_urls': place.photoUrl != null ? [place.photoUrl] : [],
        'rating': place.rating,
        'amenities': place.amenities,
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/places'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        final item = json.decode(response.body);
        return PlaceModel(
          id: item['id'],
          name: item['name'],
          category: item['type'],
          latitude: item['location_latitude'],
          longitude: item['location_longitude'],
          address: '${item['address_street'] ?? ''}, ${item['address_city'] ?? ''}',
          description: item['description'],
          photoUrl: item['images_urls']?.isNotEmpty == true ? item['images_urls'][0] : null,
          rating: item['rating'] != null ? (item['rating'] as num).toDouble() : null,
          amenities: item['amenities'] as Map<String, dynamic>?,
        );
      } else {
        throw Exception('Failed to add place: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing place
  Future<void> updatePlace(PlaceModel place) async {
    try {
      final token = await _getAuthToken();
      
      final data = {
        'name': place.name,
        'type': place.category,
        'location_latitude': place.latitude,
        'location_longitude': place.longitude,
        'address_street': place.address?.split(',')[0]?.trim(),
        'address_city': place.address?.split(',').length > 1 ? place.address?.split(',')[1]?.trim() : null,
        'description': place.description,
        'images_urls': place.photoUrl != null ? [place.photoUrl] : [],
        'rating': place.rating,
        'amenities': place.amenities,
      };

      final response = await http.put(
        Uri.parse('$_apiBaseUrl/places/${place.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update place: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a place
  Future<void> deletePlace(String placeId) async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/places/$placeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete place: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get dog parks specifically
  Future<List<PlaceModel>> getDogParks() async {
    return getPlacesByCategory('Park');
  }

  // Get nearby dog parks
  Future<List<PlaceModel>> getNearbyDogParks(
    double latitude,
    double longitude,
    double radiusInKm,
  ) async {
    try {
      final List<PlaceModel> nearbyPlaces = await getNearbyPlaces(
        latitude,
        longitude,
        radiusInKm,
      );
      return nearbyPlaces.where((place) => place.category == 'Park').toList();
    } catch (e) {
      rethrow;
    }
  }
}