import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class DogProfileScreen extends StatefulWidget {
  final String? dogId;

  const DogProfileScreen({super.key, this.dogId});

  @override
  State<DogProfileScreen> createState() => _DogProfileScreenState();
}

class _DogProfileScreenState extends State<DogProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();

  String _selectedSize = 'Medium';
  int _age = 1;
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  // Temperament traits
  final Map<String, bool> _temperamentTraits = {
    'Friendly': false,
    'Energetic': false,
    'Calm': false,
    'Playful': false,
    'Shy': false,
    'Protective': false,
    'Independent': false,
    'Affectionate': false,
  };

  @override
  void initState() {
    super.initState();
    _loadDogData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _loadDogData() async {
    if (widget.dogId == null) return; // New dog, no data to load

    setState(() {
      _isLoading = true;
    });

    try {
      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      final dog = dogProvider.getDogById(widget.dogId!);

      if (dog != null) {
        _nameController.text = dog.name;
        _breedController.text = dog.breed;
        _age = dog.age;
        _selectedSize = dog.size;
        _imageUrl = dog.photoUrl;

        // Load temperament traits
        if (dog.temperament != null) {
          dog.temperament!.forEach((key, value) {
            if (_temperamentTraits.containsKey(key)) {
              _temperamentTraits[key] = value as bool;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dog data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dogProvider = Provider.of<DogProvider>(context, listen: false);

      final user = authProvider.user;
      if (user == null) throw Exception('User not logged in');

      // Prepare temperament data
      final Map<String, dynamic> temperament = {};
      _temperamentTraits.forEach((key, value) {
        if (value) temperament[key] = true;
      });

      // TODO: Upload image to API if _imageFile is not null
      // For now, we'll use a placeholder URL
      final String photoUrl = _imageUrl ?? '';

      if (widget.dogId == null) {
        // Create new dog
        final newDog = DogModel(
          name: _nameController.text,
          breed: _breedController.text,
          age: _age,
          size: _selectedSize,
          photoUrl: photoUrl,
          ownerId: user.id,
          temperament: temperament.isNotEmpty ? temperament : null,
        );

        final success = await dogProvider.addDog(newDog, user.id);
        if (!mounted) return;

        if (success) {
          // Show a success dialog before navigating back
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Success!'),
                  content: Text(
                    '${_nameController.text} has been added successfully!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to dogs screen
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(dogProvider.errorMessage ?? 'Failed to add dog'),
            ),
          );
        }
      } else {
        // Update existing dog
        final updatedDog = DogModel(
          id: widget.dogId,
          name: _nameController.text,
          breed: _breedController.text,
          age: _age,
          size: _selectedSize,
          photoUrl: photoUrl,
          ownerId: user.id,
          temperament: temperament.isNotEmpty ? temperament : null,
        );

        final success = await dogProvider.updateDog(updatedDog);
        if (!mounted) return;

        if (success) {
          // Show a success dialog before navigating back
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Success!'),
                  content: Text(
                    '${_nameController.text}\'s profile has been updated successfully!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to dogs screen
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(dogProvider.errorMessage ?? 'Failed to update dog'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
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
    final bool isNewDog = widget.dogId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewDog ? 'Add Your Dog' : 'Dog Profile'),
        actions: [
          if (!isNewDog)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDeleteDog,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dog photo
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: AppColors.secondary.withAlpha(
                                  51,
                                ),
                                backgroundImage: _getProfileImage(),
                                child:
                                    _imageFile == null && _imageUrl == null
                                        ? const Icon(
                                          Icons.pets,
                                          size: 60,
                                          color: AppColors.secondary,
                                        )
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  radius: 18,
                                  child: Icon(
                                    _imageFile == null && _imageUrl == null
                                        ? Icons.add_a_photo
                                        : Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name
                      PawPalsTextField(
                        label: 'Name',
                        hint: 'Enter your dog\'s name',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your dog\'s name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Breed
                      PawPalsTextField(
                        label: 'Breed',
                        hint: 'Enter your dog\'s breed',
                        controller: _breedController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your dog\'s breed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Age
                      Text(
                        'Age',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed:
                                _age > 1
                                    ? () {
                                      setState(() {
                                        _age--;
                                      });
                                    }
                                    : null,
                          ),
                          Text(
                            '$_age ${_age == 1 ? 'year' : 'years'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _age++;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Size
                      Text(
                        'Size',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'Small',
                            label: Text('Small'),
                          ),
                          ButtonSegment<String>(
                            value: 'Medium',
                            label: Text('Medium'),
                          ),
                          ButtonSegment<String>(
                            value: 'Large',
                            label: Text('Large'),
                          ),
                        ],
                        selected: {_selectedSize},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() {
                            _selectedSize = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Temperament
                      Text(
                        'Temperament',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select traits that describe your dog',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _temperamentTraits.entries.map((entry) {
                              return FilterChip(
                                label: Text(entry.key),
                                selected: entry.value,
                                onSelected: (selected) {
                                  setState(() {
                                    _temperamentTraits[entry.key] = selected;
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      PawPalsButton(
                        text: isNewDog ? 'Add Dog' : 'Save Changes',
                        onPressed: _saveDog,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return NetworkImage(_imageUrl!);
    }
    return null;
  }

  void _confirmDeleteDog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Dog'),
            content: const Text(
              'Are you sure you want to delete this dog? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteDog();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteDog() async {
    if (widget.dogId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dogProvider = Provider.of<DogProvider>(context, listen: false);
      final success = await dogProvider.deleteDog(widget.dogId!);

      if (!mounted) return;

      if (success) {
        // Get the dog name before popping
        final dogName = _nameController.text;

        // Show a success dialog before navigating back
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Success'),
                content: Text('$dogName has been deleted successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to dogs screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dogProvider.errorMessage ?? 'Failed to delete dog'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}