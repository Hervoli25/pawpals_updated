import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/models.dart';
import '../../providers/place_provider.dart';
import '../../utils/app_theme.dart';

class MapViewTab extends StatefulWidget {
  final String? selectedCategory;

  const MapViewTab({super.key, this.selectedCategory});

  @override
  State<MapViewTab> createState() => _MapViewTabState();
}

class _MapViewTabState extends State<MapViewTab> {
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};

  // Default center on New York City
  static const LatLng _defaultCenter = LatLng(40.7128, -74.0060);

  // User's current location
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Get the user's current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Move camera to current location if map is ready
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
      }

      // Load nearby places
      _loadNearbyPlaces();
    } catch (e) {
      setState(() {
        _locationError = e.toString();
        _isLoadingLocation = false;
      });
    }
  }

  // Load nearby places based on current location
  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null) return;

    try {
      final placeProvider = Provider.of<PlaceProvider>(context, listen: false);

      // Get nearby places within 5km radius
      final nearbyPlaces = await placeProvider.getNearbyPlaces(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        5.0, // 5km radius
      );

      // If we have places, update markers and fit map
      if (mounted) {
        setState(() {
          // If we have a selected category, filter the places
          if (widget.selectedCategory != null &&
              widget.selectedCategory != 'All') {
            final filteredPlaces =
                nearbyPlaces
                    .where((place) => place.category == widget.selectedCategory)
                    .toList();

            _updateMarkers(filteredPlaces);

            if (filteredPlaces.isNotEmpty && _mapController != null) {
              // Create a list of all points to include in the bounds
              final points = <LatLng>[
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                ...filteredPlaces.map((p) => LatLng(p.latitude, p.longitude)),
              ];

              _fitMapToPoints(points);
            }
          } else {
            _updateMarkers(nearbyPlaces);

            if (nearbyPlaces.isNotEmpty && _mapController != null) {
              // Create a list of all points to include in the bounds
              final points = <LatLng>[
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                ...nearbyPlaces.map((p) => LatLng(p.latitude, p.longitude)),
              ];

              _fitMapToPoints(points);
            }
          }
        });
      }
    } catch (e) {
      // Error will be handled by the provider
      if (mounted) {
        setState(() {
          _locationError = 'Error loading nearby places: ${e.toString()}';
        });
      }
    }
  }

  // Fit map to show all points
  void _fitMapToPoints(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    // Create bounds from all points
    final bounds = LatLngBounds(
      southwest: LatLng(
        points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
        points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
        points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
      ),
    );

    // Animate camera to fit all points
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // 50 is padding
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeProvider = Provider.of<PlaceProvider>(context);
    final places = placeProvider.places;

    // Filter places by category if needed
    final filteredPlaces =
        widget.selectedCategory == null || widget.selectedCategory == 'All'
            ? places
            : places
                .where((place) => place.category == widget.selectedCategory)
                .toList();

    // Update markers
    _updateMarkers(filteredPlaces);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target:
                _currentPosition != null
                    ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                    : _defaultCenter,
            zoom: 14,
          ),
          markers: Set<Marker>.of(_markers.values),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;

            // If we have current location, move to it
            if (_currentPosition != null) {
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  14,
                ),
              );

              // Load nearby places
              _loadNearbyPlaces();
            }
            // Otherwise, if we have places, fit the map to show all of them
            else if (filteredPlaces.isNotEmpty) {
              _fitMapToPlaces(filteredPlaces);
            }
          },
        ),

        // Refresh button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'refresh_map',
            backgroundColor: Theme.of(context).primaryColor,
            tooltip: 'Refresh nearby places',
            onPressed: () {
              if (_currentPosition != null) {
                _loadNearbyPlaces();
              } else {
                _getCurrentLocation();
              }
            },
            child: const Icon(Icons.refresh),
          ),
        ),

        // Location loading indicator
        if (_isLoadingLocation)
          const Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Getting location...'),
                  ],
                ),
              ),
            ),
          ),

        // Location error message
        if (_locationError != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location error: $_locationError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _getCurrentLocation,
                      tooltip: 'Try again',
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Places loading indicator
        if (placeProvider.isLoading)
          const Center(child: CircularProgressIndicator()),

        // Places error message
        if (placeProvider.errorMessage != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading places',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    placeProvider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    onPressed: () {
                      if (_currentPosition != null) {
                        _loadNearbyPlaces();
                      } else {
                        _getCurrentLocation();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _updateMarkers(List<PlaceModel> places) {
    _markers.clear();

    // Add user's current location marker if available
    if (_currentPosition != null) {
      final userMarkerId = const MarkerId('user_location');
      final userMarker = Marker(
        markerId: userMarkerId,
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'You are here',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndex: 2, // Place above other markers
      );

      _markers['user_location'] = userMarker;
    }

    // Add place markers
    for (final place in places) {
      final markerId = MarkerId(place.id);

      final marker = Marker(
        markerId: markerId,
        position: LatLng(place.latitude, place.longitude),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.category,
          onTap: () => _showPlaceDetails(context, place),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getCategoryHue(place.category),
        ),
        zIndex: 1,
      );

      _markers[place.id] = marker;
    }
  }

  double _getCategoryHue(String category) {
    switch (category) {
      case 'Park':
        return BitmapDescriptor.hueGreen;
      case 'Cafe':
        return BitmapDescriptor.hueOrange;
      case 'Restaurant':
        return BitmapDescriptor.hueRed;
      case 'Hotel':
        return BitmapDescriptor.hueBlue;
      case 'Beach':
        return BitmapDescriptor.hueCyan;
      case 'Store':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueRose;
    }
  }

  void _fitMapToPlaces(List<PlaceModel> places) {
    if (places.isEmpty || _mapController == null) return;

    // Create bounds from all places
    final bounds = LatLngBounds(
      southwest: LatLng(
        places.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
        places.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        places.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
        places.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
      ),
    );

    // Animate camera to fit all markers
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // 50 is padding
    );
  }

  void _showPlaceDetails(BuildContext context, PlaceModel place) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(place.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Chip(
                    label: Text(place.category),
                    backgroundColor: _getCategoryColor(place.category),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  if (place.address != null) ...[
                    const Text(
                      'Address:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(place.address!),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (place.description != null) ...[
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(place.description!),
                    const SizedBox(height: 16),
                  ],

                  // Rating
                  if (place.rating != null) ...[
                    Row(
                      children: [
                        const Text(
                          'Rating: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${place.rating}'),
                        const SizedBox(width: 4),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Amenities
                  if (place.amenities != null &&
                      place.amenities!.isNotEmpty) ...[
                    const Text(
                      'Amenities:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          place.amenities!.entries
                              .where((entry) => entry.value == true)
                              .map(
                                (entry) => Chip(
                                  label: Text(_formatAmenityName(entry.key)),
                                  backgroundColor: Colors.grey[200],
                                ),
                              )
                              .toList(),
                    ),
                  ],
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
                  _openDirections(place);
                },
              ),
            ],
          ),
    );
  }

  String _formatAmenityName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
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

  void _openDirections(PlaceModel place) {
    // This would typically open the maps app with directions
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${place.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
