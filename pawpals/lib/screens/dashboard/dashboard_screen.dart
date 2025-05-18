import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  void _showProfileMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to profile screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to settings screen
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (shouldLogout == true) {
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go(AppRoutes.onboarding);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkAuthAndLoadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (authProvider.isAuthenticated) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get providers before async operations
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );
      final playdateProvider = Provider.of<PlaydateProvider>(
        context,
        listen: false,
      );
      final mealPlanProvider = Provider.of<MealPlanProvider>(
        context,
        listen: false,
      );
      final placeProvider = Provider.of<PlaceProvider>(context, listen: false);

      final user = authProvider.user;

      if (user != null) {
        // Load data
        await dogProvider.loadDogs(user.id);

        if (!mounted) return;
        await appointmentProvider.loadAppointments(user.id);

        if (!mounted) return;
        await playdateProvider.loadPlaydates(user.id, user.dogIds);

        if (!mounted) return;
        await mealPlanProvider.loadMealPlans(user.dogIds);

        if (!mounted) return;
        await placeProvider.loadPlaces();
      }
    } catch (e) {
      // Handle error
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      // If no user, redirect to onboarding
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.onboarding);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          const SizedBox(width: 8),
          ProfileAvatar(
            imageUrl: user.profilePic,
            size: 36,
            onTap: () {
              _showProfileMenu(context);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      _GreetingSection(userName: user.name),
                      const SizedBox(height: 24),

                      // Upcoming Playdates
                      _SectionTitle(
                        title: 'Upcoming Playdates',
                        onSeeAll: () => context.go(AppRoutes.playmates),
                      ),
                      const SizedBox(height: 8),
                      const _UpcomingPlaydatesSection(),
                      const SizedBox(height: 24),

                      // My Dogs
                      _SectionTitle(
                        title: 'My Dogs',
                        onSeeAll: () => context.go(AppRoutes.dogs),
                      ),
                      const SizedBox(height: 8),
                      const _MyDogsSection(),
                      const SizedBox(height: 24),

                      // Reminders
                      _SectionTitle(
                        title: 'Reminders',
                        onSeeAll: () => context.go(AppRoutes.appointments),
                      ),
                      const SizedBox(height: 8),
                      const _RemindersSection(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _QuickActionsSection(),

                      // Logout Button
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          // Show confirmation dialog
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text(
                                    'Are you sure you want to logout?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );

                          if (shouldLogout == true) {
                            // Get the provider before async gap
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );

                            // Perform logout
                            await authProvider.logout();

                            // Check if still mounted before navigation
                            if (mounted) {
                              context.go(AppRoutes.onboarding);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: const PawPalsBottomNavBar(currentIndex: 0),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  final String userName;

  const _GreetingSection({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, $userName!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome to PawPals',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionTitle({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}

class _UpcomingPlaydatesSection extends StatelessWidget {
  const _UpcomingPlaydatesSection();

  @override
  Widget build(BuildContext context) {
    // Placeholder data
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const DogAvatar(size: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Max & Bella',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today, 3:00 PM',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Central Park',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.pets, size: 50, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

class _RemindersSection extends StatelessWidget {
  const _RemindersSection();

  @override
  Widget build(BuildContext context) {
    // Placeholder data
    return Column(
      children: [
        _ReminderCard(
          title: 'Vet Appointment',
          dogName: 'Max',
          date: 'Tomorrow, 10:00 AM',
          icon: Icons.medical_services,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _ReminderCard(
          title: 'Grooming',
          dogName: 'Bella',
          date: 'Friday, 2:00 PM',
          icon: Icons.content_cut,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final String title;
  final String dogName;
  final String date;
  final IconData icon;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.title,
    required this.dogName,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dogName,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 16,
      runSpacing: 16,
      children: [
        _QuickActionItem(
          icon: Icons.pets,
          label: 'My Dogs',
          onTap: () => context.go(AppRoutes.dogs),
        ),
        _QuickActionItem(
          icon: Icons.people,
          label: 'Find Playmates',
          onTap: () => context.go(AppRoutes.playmates),
        ),
        _QuickActionItem(
          icon: Icons.fastfood,
          label: 'Meal Plan',
          onTap: () => context.go(AppRoutes.dietaryPlanner),
        ),
        _QuickActionItem(
          icon: Icons.map,
          label: 'Dog-Friendly Places',
          onTap: () => context.go(AppRoutes.places),
        ),
        _QuickActionItem(
          icon: Icons.forum,
          label: 'Community',
          onTap: () => context.go(AppRoutes.community),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MyDogsSection extends StatelessWidget {
  const _MyDogsSection();

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<DogProvider>(context);
    final dogs = dogProvider.dogs;

    if (dogs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.pets, size: 50, color: AppColors.secondary),
              const SizedBox(height: 8),
              const Text(
                'No dogs added yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              PawPalsButton(
                text: 'Add Dog',
                onPressed: () => context.go(AppRoutes.addDog),
                isFullWidth: false,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dogs.length + 1, // +1 for the "Add Dog" card
        itemBuilder: (context, index) {
          if (index == dogs.length) {
            // "Add Dog" card
            return _DogCard(
              name: 'Add Dog',
              imageUrl: null,
              onTap: () => context.go(AppRoutes.addDog),
              isAddCard: true,
            );
          }

          final dog = dogs[index];
          return _DogCard(
            name: dog.name,
            imageUrl: dog.photoUrl,
            onTap: () => context.go('${AppRoutes.dogProfile}?id=${dog.id}'),
            isAddCard: false,
          );
        },
      ),
    );
  }
}

class _DogCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isAddCard;

  const _DogCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
    required this.isAddCard,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 100,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      isAddCard
                          ? AppColors.primary.withAlpha(25)
                          : AppColors.secondary.withAlpha(51),
                  backgroundImage:
                      !isAddCard && imageUrl != null && imageUrl!.isNotEmpty
                          ? NetworkImage(imageUrl!)
                          : null,
                  child:
                      isAddCard || imageUrl == null || imageUrl!.isEmpty
                          ? Icon(
                            isAddCard ? Icons.add : Icons.pets,
                            size: 30,
                            color:
                                isAddCard
                                    ? AppColors.primary
                                    : AppColors.secondary,
                          )
                          : null,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isAddCard ? FontWeight.normal : FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
