import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import screens (to be created)
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/playmates/playmates_screen.dart';
import '../screens/dietary_planner/dietary_planner_screen.dart';
import '../screens/dog_profile/dog_profile_screen.dart';
import '../screens/dogs/dogs_screen.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/places/places_screen.dart';
import '../screens/community/community_screen.dart';

class AppRoutes {
  static const String splash = 
      '/'; // Splash screen is the initial route
  static const String onboarding = 
      '/onboarding'; // Onboarding screen route
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String playmates = '/playmates';
  static const String dietaryPlanner = '/dietary-planner';
  static const String dogProfile = '/dog-profile';
  static const String addDog = '/add-dog';
  static const String dogs = '/dogs';
  static const String appointments = '/appointments';
  static const String places = '/places';
  static const String community = '/community';

  static final GoRouter router = GoRouter(
    initialLocation: splash, // Set initial location to splash screen
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(), // Route for Splash Screen
      ),
      GoRoute(
        path: onboarding, // Path for Onboarding Screen
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: playmates,
        builder: (context, state) => const PlaymatesScreen(),
      ),
      GoRoute(
        path: dietaryPlanner,
        builder: (context, state) => const DietaryPlannerScreen(),
      ),
      GoRoute(
        path: dogProfile,
        builder: (context, state) {
          final dogId = state.uri.queryParameters['id'];
          return DogProfileScreen(dogId: dogId);
        },
      ),
      GoRoute(
        path: addDog,
        builder: (context, state) => const DogProfileScreen(),
      ),
      GoRoute(path: dogs, builder: (context, state) => const DogsScreen()),
      GoRoute(
        path: appointments,
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(path: places, builder: (context, state) => const PlacesScreen()),
      GoRoute(
        path: community,
        builder: (context, state) => const CommunityScreen(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(child: Text('Route not found: ${state.uri}')),
        ),
  );
}
