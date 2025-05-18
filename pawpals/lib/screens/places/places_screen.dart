import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'map_view_tab.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Park',
    'Cafe',
    'Restaurant',
    'Hotel',
    'Beach',
    'Store',
  ];

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
      final placeProvider = Provider.of<PlaceProvider>(context, listen: false);

      // Load places
      await placeProvider.loadPlaces();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog-Friendly Places'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'List View'), Tab(text: 'Map View')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // List View Tab
                  _buildListView(),

                  // Map View Tab
                  MapViewTab(selectedCategory: _selectedCategory),
                ],
              ),
      bottomNavigationBar: const PawPalsBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        // Category filter
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),

        // Places list
        Expanded(child: _PlacesListView(selectedCategory: _selectedCategory)),
      ],
    );
  }
}

class _PlacesListView extends StatelessWidget {
  final String selectedCategory;

  const _PlacesListView({required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final placeProvider = Provider.of<PlaceProvider>(context);
    final places = placeProvider.places;

    // Filter places by category
    final filteredPlaces =
        selectedCategory == 'All'
            ? places
            : places
                .where((place) => place.category == selectedCategory)
                .toList();

    if (filteredPlaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              selectedCategory == 'All'
                  ? 'No dog-friendly places found'
                  : 'No $selectedCategory places found',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: filteredPlaces.length,
      itemBuilder: (context, index) {
        final place = filteredPlaces[index];
        return _PlaceCard(place: place);
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final PlaceModel place;

  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place image
          if (place.photoUrl != null && place.photoUrl!.isNotEmpty)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.network(
                place.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image, size: 50)),
            ),

          // Place details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (place.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            place.rating!.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Category
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(place.category).withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    place.category,
                    style: TextStyle(
                      color: _getCategoryColor(place.category),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Address
                if (place.address != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address!,
                          style: TextStyle(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                // Description
                if (place.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    place.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Amenities
                if (place.amenities != null && place.amenities!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Amenities',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        place.amenities!.entries
                            .where((entry) => entry.value == true)
                            .map((entry) {
                              return Chip(
                                label: Text(
                                  _formatAmenityName(entry.key),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.grey[200],
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            })
                            .toList(),
                  ),
                ],

                // View details button
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      onPressed: () {
                        // Open directions in maps app
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      onPressed: () {
                        _showPlaceDetails(context, place);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Park':
        return Colors.green;
      case 'Cafe':
        return Colors.brown;
      case 'Restaurant':
        return Colors.orange;
      case 'Hotel':
        return Colors.blue;
      case 'Beach':
        return Colors.cyan;
      case 'Store':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  String _formatAmenityName(String name) {
    // Convert snake_case to Title Case
    return name
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  void _showPlaceDetails(BuildContext context, PlaceModel place) {
    showDialog(
      context: context,
      builder: (context) => _PlaceDetailsDialog(place: place),
    );
  }
}

class _PlaceDetailsDialog extends StatelessWidget {
  final PlaceModel place;

  const _PlaceDetailsDialog({required this.place});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place image
            if (place.photoUrl != null && place.photoUrl!.isNotEmpty)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.network(
                  place.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image, size: 50)),
              ),

            // Place details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      if (place.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.rating!.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(place.category).withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      place.category,
                      style: TextStyle(
                        color: _getCategoryColor(place.category),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  if (place.address != null)
                    _DetailItem(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: place.address!,
                    ),

                  // Description
                  if (place.description != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(place.description!),
                  ],

                  // Amenities
                  if (place.amenities != null &&
                      place.amenities!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Amenities',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          place.amenities!.entries
                              .where((entry) => entry.value == true)
                              .map((entry) {
                                return Chip(
                                  label: Text(
                                    _formatAmenityName(entry.key),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.grey[200],
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              })
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.directions),
          label: const Text('Directions'),
          onPressed: () {
            Navigator.of(context).pop();
            // Open directions in maps app
          },
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Park':
        return Colors.green;
      case 'Cafe':
        return Colors.brown;
      case 'Restaurant':
        return Colors.orange;
      case 'Hotel':
        return Colors.blue;
      case 'Beach':
        return Colors.cyan;
      case 'Store':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  String _formatAmenityName(String name) {
    // Convert snake_case to Title Case
    return name
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
