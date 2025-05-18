import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common_widgets.dart';

class DogsScreen extends StatefulWidget {
  const DogsScreen({super.key});

  @override
  State<DogsScreen> createState() => _DogsScreenState();
}

class _DogsScreenState extends State<DogsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Schedule a check for newly added dog after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewlyAddedDog();
    });
  }

  void _checkForNewlyAddedDog() {
    final dogProvider = Provider.of<DogProvider>(context, listen: false);
    if (dogProvider.dogJustAdded && dogProvider.lastAddedDog != null) {
      final dog = dogProvider.lastAddedDog!;

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${dog.name} has been added successfully!'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              context.go('${AppRoutes.dogProfile}?id=${dog.id}');
            },
          ),
        ),
      );

      // Reset the flag
      dogProvider.resetDogJustAdded();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dogProvider = Provider.of<DogProvider>(context, listen: false);

      final user = authProvider.user;

      if (user != null) {
        // Load dogs
        await dogProvider.loadDogs(user.id);
      }
    } catch (e) {
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
    final dogProvider = Provider.of<DogProvider>(context);
    final dogs = dogProvider.dogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dogs'),
        automaticallyImplyLeading: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: dogs.isEmpty ? _buildEmptyState() : _buildDogsList(dogs),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go(AppRoutes.addDog);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 80, color: AppColors.secondary),
          const SizedBox(height: 16),
          const Text(
            'No dogs added yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your furry friends to get started',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          PawPalsButton(
            text: 'Add Dog',
            onPressed: () {
              context.go(AppRoutes.addDog);
            },
            icon: Icons.add,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDogsList(List<DogModel> dogs) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: dogs.length,
      itemBuilder: (context, index) {
        final dog = dogs[index];
        return _DogCard(
          dog: dog,
          onTap: () {
            context.go('${AppRoutes.dogProfile}?id=${dog.id}');
          },
        );
      },
    );
  }
}

class _DogCard extends StatelessWidget {
  final DogModel dog;
  final VoidCallback onTap;

  const _DogCard({required this.dog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Dog avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.secondary.withAlpha(51),
                backgroundImage:
                    dog.photoUrl != null && dog.photoUrl!.isNotEmpty
                        ? NetworkImage(dog.photoUrl!)
                        : null,
                child:
                    dog.photoUrl == null || dog.photoUrl!.isEmpty
                        ? const Icon(
                          Icons.pets,
                          size: 40,
                          color: AppColors.secondary,
                        )
                        : null,
              ),
              const SizedBox(width: 16),

              // Dog info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dog.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dog.breed,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dog.age} ${dog.age == 1 ? 'year' : 'years'} old • ${dog.size}',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Edit icon
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
