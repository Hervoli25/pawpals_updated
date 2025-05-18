import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_routes.dart';
import '../utils/constants.dart';

class PawPalsBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const PawPalsBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: BottomNavItems.items,
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.playmates);
        break;
      case 2:
        context.go(AppRoutes.dietaryPlanner);
        break;
      case 3:
        context.go(AppRoutes.appointments);
        break;
      case 4:
        context.go(AppRoutes.places);
        break;
    }
  }
}
