import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class MealPlanProvider extends ChangeNotifier {
  // Replace with your actual API base URL
  final String _apiBaseUrl = 'http://localhost:5000/api';
  Map<String, List<MealPlanModel>> _mealPlans = {}; // dogId -> list of meal plans
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Helper to get auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Get meal plans for a specific dog
  List<MealPlanModel> getMealPlansForDog(String dogId) {
    return _mealPlans[dogId] ?? [];
  }

  // Get today's meal plan for a specific dog
  MealPlanModel? getTodaysMealPlan(String dogId) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final dogMealPlans = _mealPlans[dogId] ?? [];
    try {
      return dogMealPlans.firstWhere((mealPlan) {
        final mealPlanDate = DateTime(
          mealPlan.date.year,
          mealPlan.date.month,
          mealPlan.date.day,
        );
        return mealPlanDate.isAtSameMomentAs(todayDate);
      });
    } catch (e) {
      return null;
    }
  }

  // Load meal plans from API
  Future<void> loadMealPlans(List<String> dogIds) async {
    if (dogIds.isEmpty) return;

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
      final Map<String, List<MealPlanModel>> mealPlans = {};

      // Query API for meal plans for each dog
      for (final dogId in dogIds) {
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/dogs/$dogId/meal-plans'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> responseData = json.decode(response.body);
          
          if (responseData.isNotEmpty) {
            // Convert API data to MealPlanModel objects
            final dogMealPlans = responseData.map((data) => MealPlanModel.fromMap(data)).toList();
            mealPlans[dogId] = dogMealPlans;
          } else {
            // If no meal plans exist for this dog, create default ones
            final today = DateTime.now();

            // Create default meal plan for today
            final defaultMealPlan = MealPlanModel(
              dogId: dogId,
              date: today,
              breakfast: [
                MealItem(
                  name: '1 cup premium kibble',
                  description: 'High-quality dry food',
                ),
              ],
              lunch: [
                MealItem(
                  name: '½ cup cooked vegetables',
                  description: 'Carrots, green beans, and peas',
                ),
              ],
              dinner: [
                MealItem(
                  name: '1 cup premium kibble',
                  description: 'High-quality dry food',
                ),
              ],
              snacks: [
                MealItem(
                  name: 'Training treats',
                  description: 'Small, low-calorie treats for training',
                ),
              ],
            );

            // Save the default meal plan to API
            await addMealPlan(defaultMealPlan);

            // Add to local state
            mealPlans[dogId] = [defaultMealPlan];
          }
        } else {
          final responseData = json.decode(response.body);
          _errorMessage = responseData['message'] ?? 'Failed to load meal plans for dog $dogId.';
        }
      }

      _mealPlans = mealPlans;
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMealPlan(MealPlanModel mealPlan) async {
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
        Uri.parse('$_apiBaseUrl/meal-plans'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(mealPlan.toMap()),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final newMealPlan = MealPlanModel.fromMap(responseData);
        
        // Update local state
        final dogId = mealPlan.dogId;
        if (!_mealPlans.containsKey(dogId)) {
          _mealPlans[dogId] = [];
        }

        _mealPlans[dogId]!.add(newMealPlan);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to add meal plan.';
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

  Future<bool> updateMealPlan(MealPlanModel updatedMealPlan) async {
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
        Uri.parse('$_apiBaseUrl/meal-plans/${updatedMealPlan.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedMealPlan.toMap()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final updatedPlan = MealPlanModel.fromMap(responseData);
        
        // Update local state
        final dogId = updatedPlan.dogId;
        final mealPlans = _mealPlans[dogId] ?? [];

        final index = mealPlans.indexWhere(
          (mealPlan) => mealPlan.id == updatedPlan.id,
        );

        if (index != -1) {
          mealPlans[index] = updatedPlan;
          _mealPlans[dogId] = mealPlans;
        } else {
          // If not found in local state, add it
          if (!_mealPlans.containsKey(dogId)) {
            _mealPlans[dogId] = [];
          }
          _mealPlans[dogId]!.add(updatedPlan);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to update meal plan.';
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

  Future<bool> deleteMealPlan(String dogId, String mealPlanId) async {
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
        Uri.parse('$_apiBaseUrl/meal-plans/$mealPlanId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Update local state
        final mealPlans = _mealPlans[dogId] ?? [];
        mealPlans.removeWhere((mealPlan) => mealPlan.id == mealPlanId);
        _mealPlans[dogId] = mealPlans;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to delete meal plan.';
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