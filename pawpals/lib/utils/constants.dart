import 'package:flutter/material.dart';

class AppConstants {
  // App info
  static const String appName = 'PawPals';
  static const String appVersion = '1.0.0';
  
  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Border radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;
  static const double borderRadiusCircular = 100.0;
  
  // Animation durations
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  
  // Dog sizes
  static const List<String> dogSizes = ['Small', 'Medium', 'Large'];
  
  // Appointment types
  static const List<String> appointmentTypes = [
    'Vet Checkup',
    'Grooming',
    'Training',
    'Vaccination',
    'Other'
  ];
  
  // Place categories
  static const List<String> placeCategories = [
    'Park',
    'Cafe',
    'Hotel',
    'Beach',
    'Restaurant',
    'Store',
    'Other'
  ];
  
  // Forum categories
  static const List<String> forumCategories = [
    'Training',
    'Health',
    'Nutrition',
    'Behavior',
    'Breeds',
    'General'
  ];
  
  // Default avatar
  static const String defaultAvatarUrl = 'assets/images/default_avatar.png';
  static const String defaultDogAvatarUrl = 'assets/images/default_dog.png';
}

// Bottom navigation items
class BottomNavItems {
  static const List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.pets),
      label: 'Playmates',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.restaurant_menu),
      label: 'Diet',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today),
      label: 'Appointments',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: 'Places',
    ),
  ];
}
