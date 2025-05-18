import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'gallery_screen.dart';

class PlaymatesScreen extends StatefulWidget {
  const PlaymatesScreen({super.key});

  @override
  State<PlaymatesScreen> createState() => _PlaymatesScreenState();
}

class _PlaymatesScreenState extends State<PlaymatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      final playdateProvider = Provider.of<PlaydateProvider>(
        context,
        listen: false,
      );

      final user = authProvider.user;

      if (user != null) {
        // Make sure dogs are loaded
        if (dogProvider.dogs.isEmpty) {
          await dogProvider.loadDogs(user.id);
        }

        // Load playdates
        await playdateProvider.loadPlaydates(user.id, user.dogIds);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playmates'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Find Playmates'), Tab(text: 'My Playdates')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreatePlaydateDialog(context);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: const [
                  // Find Playmates Tab
                  _FindPlaymatesTab(),

                  // My Playdates Tab
                  _MyPlaydatesTab(),
                ],
              ),
      bottomNavigationBar: const PawPalsBottomNavBar(currentIndex: 1),
    );
  }

  void _showCreatePlaydateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreatePlaydateDialog(),
    );
  }
}

class _FindPlaymatesTab extends StatelessWidget {
  const _FindPlaymatesTab();

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<DogProvider>(context);
    final dogs = dogProvider.dogs;

    if (dogs.isEmpty) {
      return const Center(child: Text('Add a dog to find playmates!'));
    }

    // In a real app, this would fetch potential playmates from a database
    // For demo, we'll show some mock data
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      children: [
        // Search and filter section
        const _SearchFilterSection(),
        const SizedBox(height: 16),

        // Potential playmates list
        const Text(
          'Dogs in your area',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // List of potential playmates
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5, // Mock data
          itemBuilder: (context, index) {
            return _PotentialPlaymateCard(
              name: 'Dog ${index + 1}',
              breed: 'Breed ${index + 1}',
              age: (index + 1) % 3 + 1,
              distance: (index + 1) * 0.5,
              imageUrl: '',
              onTap: () {
                // Show dog profile or initiate playdate
              },
            );
          },
        ),
      ],
    );
  }
}

class _SearchFilterSection extends StatelessWidget {
  const _SearchFilterSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search for dogs...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(label: 'Small Dogs', onSelected: (selected) {}),
              _FilterChip(label: 'Medium Dogs', onSelected: (selected) {}),
              _FilterChip(label: 'Large Dogs', onSelected: (selected) {}),
              _FilterChip(label: 'Puppies', onSelected: (selected) {}),
              _FilterChip(label: 'Nearby', onSelected: (selected) {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Function(bool) onSelected;

  const _FilterChip({required this.label, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        onSelected: onSelected,
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withAlpha(51), // 0.2 * 255 = 51
      ),
    );
  }
}

class _PotentialPlaymateCard extends StatelessWidget {
  final String name;
  final String breed;
  final int age;
  final double distance;
  final String? imageUrl;
  final VoidCallback onTap;

  const _PotentialPlaymateCard({
    required this.name,
    required this.breed,
    required this.age,
    required this.distance,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Dog avatar
              DogAvatar(imageUrl: imageUrl, size: 60),
              const SizedBox(width: 16),

              // Dog info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$breed, $age ${age == 1 ? 'year' : 'years'} old',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$distance miles away',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action button
              ElevatedButton(
                onPressed: () {
                  // Initiate playdate
                },
                child: const Text('Play'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPlaydatesTab extends StatelessWidget {
  const _MyPlaydatesTab();

  @override
  Widget build(BuildContext context) {
    final playdateProvider = Provider.of<PlaydateProvider>(context);
    final dogProvider = Provider.of<DogProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (playdateProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (playdateProvider.errorMessage != null) {
      return PawPalsErrorMessage(
        message: playdateProvider.errorMessage!,
        onRetry: () {
          playdateProvider.loadPlaydates(
            authProvider.user!.id,
            authProvider.user!.dogIds,
          );
        },
      );
    }

    final playdates = playdateProvider.playdates;

    if (playdates.isEmpty) {
      return const Center(
        child: Text('No playdates yet. Create one to get started!'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      children: [
        // Upcoming playdates
        const Text(
          'Upcoming Playdates',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // List of upcoming playdates
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: playdates.length,
          itemBuilder: (context, index) {
            final playdate = playdates[index];

            // Get dog names
            final dog1 = dogProvider.getDogById(playdate.dogId1);
            final dog2 = dogProvider.getDogById(playdate.dogId2);

            return _PlaydateCard(
              playdate: playdate,
              dog1Name: dog1?.name ?? 'Unknown Dog',
              dog2Name: dog2?.name ?? 'Unknown Dog',
              onTap: () {
                // Show playdate details
              },
            );
          },
        ),
      ],
    );
  }
}

class _PlaydateCard extends StatelessWidget {
  final PlaydateModel playdate;
  final String dog1Name;
  final String dog2Name;
  final VoidCallback onTap;

  const _PlaydateCard({
    required this.playdate,
    required this.dog1Name,
    required this.dog2Name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final statusColor = _getStatusColor(playdate.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dogs involved
              Text(
                '$dog1Name & $dog2Name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),

              // Date and time
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(playdate.date),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(playdate.date),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              if (playdate.location != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      playdate.location!,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Status and action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      playdate.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Gallery button
                  IconButton(
                    icon: const Icon(
                      Icons.photo_library,
                      color: AppColors.primary,
                    ),
                    tooltip: 'View Photos',
                    onPressed: () {
                      // Open gallery with dog pictures
                      final dogImages = List.generate(
                        12,
                        (index) => 'dog${index + 1}.jpg',
                      );

                      GalleryLauncher.openGallery(
                        context,
                        title: '$dog1Name & $dog2Name Playdate',
                        images: dogImages,
                      );
                    },
                  ),

                  // Action buttons based on status
                  if (playdate.status == 'Pending')
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            // Accept playdate
                            Provider.of<PlaydateProvider>(
                              context,
                              listen: false,
                            ).acceptPlaydate(playdate.id);
                          },
                          child: const Text('Accept'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Reject playdate
                            Provider.of<PlaydateProvider>(
                              context,
                              listen: false,
                            ).rejectPlaydate(playdate.id);
                          },
                          child: const Text('Decline'),
                        ),
                      ],
                    )
                  else if (playdate.status == 'Accepted')
                    TextButton(
                      onPressed: () {
                        // Cancel playdate
                        Provider.of<PlaydateProvider>(
                          context,
                          listen: false,
                        ).cancelPlaydate(playdate.id);
                      },
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Cancelled':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return AppColors.textPrimary;
    }
  }
}

class _CreatePlaydateDialog extends StatefulWidget {
  const _CreatePlaydateDialog();

  @override
  State<_CreatePlaydateDialog> createState() => _CreatePlaydateDialogState();
}

class _CreatePlaydateDialogState extends State<_CreatePlaydateDialog> {
  String? _selectedDogId;
  String? _selectedPlaymateId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<DogProvider>(context);
    final dogs = dogProvider.dogs;

    // For demo purposes, we'll use the same list of dogs as potential playmates
    final playmates = dogs;

    return AlertDialog(
      title: const Text('Create Playdate'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select your dog
            const Text('Your Dog'),
            DropdownButtonFormField<String>(
              value: _selectedDogId,
              hint: const Text('Select your dog'),
              items:
                  dogs.map((dog) {
                    return DropdownMenuItem<String>(
                      value: dog.id,
                      child: Text(dog.name),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDogId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Select playmate
            const Text('Playmate'),
            DropdownButtonFormField<String>(
              value: _selectedPlaymateId,
              hint: const Text('Select a playmate'),
              items:
                  playmates
                      .map((dog) {
                        // Don't show the selected dog as a playmate option
                        if (dog.id == _selectedDogId) {
                          return null;
                        }
                        return DropdownMenuItem<String>(
                          value: dog.id,
                          child: Text(dog.name),
                        );
                      })
                      .whereType<DropdownMenuItem<String>>()
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPlaymateId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Date and time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date'),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat('MMM d, yyyy').format(_selectedDate),
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time'),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = time;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Central Park Dog Run',
              ),
            ),
            const SizedBox(height: 16),

            // Details
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Any additional details',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _createPlaydate, child: const Text('Create')),
      ],
    );
  }

  Future<void> _createPlaydate() async {
    if (_selectedDogId == null || _selectedPlaymateId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select both dogs')));
      return;
    }

    // Combine date and time
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Create playdate
    final playdate = PlaydateModel(
      dogId1: _selectedDogId!,
      dogId2: _selectedPlaymateId!,
      date: dateTime,
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
      locationDetails:
          _detailsController.text.isNotEmpty ? _detailsController.text : null,
      status: 'Pending',
    );

    // Save playdate
    final success = await Provider.of<PlaydateProvider>(
      context,
      listen: false,
    ).createPlaydate(playdate);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playdate created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create playdate')),
      );
    }
  }
}
