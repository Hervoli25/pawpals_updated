import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/meal_plan_model.dart';

class DietaryPlannerScreen extends StatefulWidget {
  const DietaryPlannerScreen({super.key});

  @override
  State<DietaryPlannerScreen> createState() => _DietaryPlannerScreenState();
}

class _DietaryPlannerScreenState extends State<DietaryPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedDogId;
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
      final mealPlanProvider = Provider.of<MealPlanProvider>(
        context,
        listen: false,
      );

      final user = authProvider.user;

      if (user != null) {
        // Make sure dogs are loaded
        if (dogProvider.dogs.isEmpty) {
          await dogProvider.loadDogs(user.id);
        }

        // Set selected dog to first dog if not set
        if (_selectedDogId == null && dogProvider.dogs.isNotEmpty) {
          _selectedDogId = dogProvider.dogs.first.id;
        }

        // Load meal plans
        if (user.dogIds.isNotEmpty) {
          await mealPlanProvider.loadMealPlans(user.dogIds);
        }
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
        title: const Text('Dietary Planner'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today\'s Meal Plan'),
            Tab(text: 'Meal History'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : dogs.isEmpty
              ? const Center(child: Text('Add a dog to create meal plans'))
              : Column(
                children: [
                  // Dog selector
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Row(
                      children: [
                        const Text('My Dogs:'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  dogs
                                      .map(
                                        (dog) => _DogChip(
                                          name: dog.name,
                                          isSelected: dog.id == _selectedDogId,
                                          onTap: () {
                                            setState(() {
                                              _selectedDogId = dog.id;
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Today's Meal Plan
                        _selectedDogId != null
                            ? _TodaysMealPlanTab(dogId: _selectedDogId!)
                            : const Center(child: Text('Select a dog')),

                        // Meal History
                        _selectedDogId != null
                            ? _MealHistoryTab(dogId: _selectedDogId!)
                            : const Center(child: Text('Select a dog')),
                      ],
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: const PawPalsBottomNavBar(currentIndex: 2),
    );
  }
}

class _DogChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _DogChip({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onTap();
          }
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withAlpha(51), // 0.2 * 255 = 51
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _TodaysMealPlanTab extends StatelessWidget {
  final String dogId;

  const _TodaysMealPlanTab({required this.dogId});

  @override
  Widget build(BuildContext context) {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context);
    final dogProvider = Provider.of<DogProvider>(context);
    final dog = dogProvider.getDogById(dogId);
    final mealPlan = mealPlanProvider.getTodaysMealPlan(dogId);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final today = DateTime.now();

    if (mealPlanProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dog == null) {
      return const Center(child: Text('Dog not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's date
          Text(
            'Today\'s Meal Plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(today),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          if (mealPlan != null) ...[
            // Breakfast
            if (mealPlan.breakfast.isNotEmpty)
              _MealSection(
                title: 'Breakfast (8:00 AM)',
                dogName: dog.name,
                mealItems:
                    mealPlan.breakfast
                        .map(
                          (item) => _MealItem(
                            name: item.name,
                            description: item.description,
                            imageUrl: item.imageUrl,
                          ),
                        )
                        .toList(),
                onEdit:
                    () => _showEditMealDialog(context, 'Breakfast', mealPlan),
              ),
            if (mealPlan.breakfast.isNotEmpty) const SizedBox(height: 24),

            // Lunch
            if (mealPlan.lunch.isNotEmpty)
              _MealSection(
                title: 'Lunch (12:00 PM)',
                dogName: dog.name,
                mealItems:
                    mealPlan.lunch
                        .map(
                          (item) => _MealItem(
                            name: item.name,
                            description: item.description,
                            imageUrl: item.imageUrl,
                          ),
                        )
                        .toList(),
                onEdit: () => _showEditMealDialog(context, 'Lunch', mealPlan),
              ),
            if (mealPlan.lunch.isNotEmpty) const SizedBox(height: 24),

            // Dinner
            if (mealPlan.dinner.isNotEmpty)
              _MealSection(
                title: 'Dinner (6:00 PM)',
                dogName: dog.name,
                mealItems:
                    mealPlan.dinner
                        .map(
                          (item) => _MealItem(
                            name: item.name,
                            description: item.description,
                            imageUrl: item.imageUrl,
                          ),
                        )
                        .toList(),
                onEdit: () => _showEditMealDialog(context, 'Dinner', mealPlan),
              ),
            if (mealPlan.dinner.isNotEmpty) const SizedBox(height: 24),

            // Snacks
            if (mealPlan.snacks.isNotEmpty)
              _MealSection(
                title: 'Snacks',
                dogName: dog.name,
                mealItems:
                    mealPlan.snacks
                        .map(
                          (item) => _MealItem(
                            name: item.name,
                            description: item.description,
                            imageUrl: item.imageUrl,
                          ),
                        )
                        .toList(),
                onEdit: () => _showEditMealDialog(context, 'Snacks', mealPlan),
              ),
            if (mealPlan.snacks.isNotEmpty) const SizedBox(height: 24),
          ] else ...[
            // No meal plan for today
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('No meal plan for today. Create one below.'),
              ),
            ),
          ],

          // Add meal button
          Center(
            child: PawPalsButton(
              text: mealPlan == null ? 'Create Meal Plan' : 'Add Custom Meal',
              onPressed: () {
                _showAddMealDialog(context, dogId);
              },
              isFullWidth: false,
              icon: Icons.add,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, String dogId) {
    showDialog(
      context: context,
      builder: (context) => _AddMealDialog(dogId: dogId),
    );
  }

  void _showEditMealDialog(
    BuildContext context,
    String mealType,
    MealPlanModel mealPlan,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => _EditMealDialog(mealPlan: mealPlan, mealType: mealType),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final String dogName;
  final List<_MealItem> mealItems;
  final VoidCallback? onEdit;

  const _MealSection({
    required this.title,
    required this.dogName,
    required this.mealItems,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...mealItems.map((item) => _MealItemCard(item: item)),
      ],
    );
  }
}

class _MealItem {
  final String name;
  final String? description;
  final String? imageUrl;
  bool consumed = false;

  _MealItem({required this.name, this.description, this.imageUrl});
}

class _MealItemCard extends StatefulWidget {
  final _MealItem item;

  const _MealItemCard({required this.item});

  @override
  State<_MealItemCard> createState() => _MealItemCardState();
}

class _MealItemCardState extends State<_MealItemCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(
                  26,
                ), // 0.1 * 255 = 25.5 ≈ 26
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  widget.item.imageUrl != null &&
                          widget.item.imageUrl!.isNotEmpty
                      ? Image.network(widget.item.imageUrl!)
                      : const Icon(
                        Icons.restaurant,
                        color: AppColors.secondary,
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration:
                          widget.item.consumed
                              ? TextDecoration.lineThrough
                              : null,
                    ),
                  ),
                  if (widget.item.description != null &&
                      widget.item.description!.isNotEmpty)
                    Text(
                      widget.item.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        decoration:
                            widget.item.consumed
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                    ),
                ],
              ),
            ),
            Checkbox(
              value: widget.item.consumed,
              onChanged: (value) {
                setState(() {
                  widget.item.consumed = value ?? false;
                });

                // Show a snackbar to confirm the action
                if (widget.item.consumed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.item.name} marked as consumed'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MealHistoryTab extends StatelessWidget {
  final String dogId;

  const _MealHistoryTab({required this.dogId});

  @override
  Widget build(BuildContext context) {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context);
    final dogProvider = Provider.of<DogProvider>(context);
    final dog = dogProvider.getDogById(dogId);
    final mealPlans = mealPlanProvider.getMealPlansForDog(dogId);
    final dateFormat = DateFormat('MMMM d, yyyy');

    if (mealPlanProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dog == null) {
      return const Center(child: Text('Dog not found'));
    }

    if (mealPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No meal plans found for ${dog.name}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Meal Plan'),
              onPressed: () {
                _showAddMealDialog(context, dogId);
              },
            ),
          ],
        ),
      );
    }

    // Sort meal plans by date (newest first)
    mealPlans.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: mealPlans.length,
      itemBuilder: (context, index) {
        final mealPlan = mealPlans[index];
        final isToday = _isToday(mealPlan.date);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              _showMealPlanDetails(context, mealPlan, dog.name);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFormat.format(mealPlan.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(
                              51,
                            ), // 0.2 * 255 = 51
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Meal summary
                  _buildMealSummary('Breakfast', mealPlan.breakfast),
                  _buildMealSummary('Lunch', mealPlan.lunch),
                  _buildMealSummary('Dinner', mealPlan.dinner),
                  if (mealPlan.snacks.isNotEmpty)
                    _buildMealSummary('Snacks', mealPlan.snacks),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealSummary(String mealType, List<MealItem> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              mealType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              items.map((item) => item.name).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _showAddMealDialog(BuildContext context, String dogId) {
    showDialog(
      context: context,
      builder: (context) => _AddMealDialog(dogId: dogId),
    );
  }

  void _showMealPlanDetails(
    BuildContext context,
    MealPlanModel mealPlan,
    String dogName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) =>
              _MealPlanDetailsDialog(mealPlan: mealPlan, dogName: dogName),
    );
  }
}

class _AddMealDialog extends StatefulWidget {
  final String dogId;

  const _AddMealDialog({required this.dogId});

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<_AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedMealType = 'Breakfast';

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Meal Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal type
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Meal Type'),
                value: _selectedMealType,
                items:
                    _mealTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMealType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name',
                  hintText: 'e.g., Premium Kibble',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a food name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g., 1 cup, high-protein formula',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _addMealItem, child: const Text('Add')),
      ],
    );
  }

  Future<void> _addMealItem() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final mealPlanProvider = Provider.of<MealPlanProvider>(
        context,
        listen: false,
      );
      final mealPlan = mealPlanProvider.getTodaysMealPlan(widget.dogId);

      // Create new meal item
      final newItem = MealItem(
        name: _nameController.text,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        // Initially not consumed
      );

      if (mealPlan == null) {
        // Create new meal plan for today
        final today = DateTime.now();
        final newMealPlan = MealPlanModel(dogId: widget.dogId, date: today);

        // Add item to appropriate meal type
        final updatedMealPlan = _addItemToMealPlan(newMealPlan, newItem);

        // Save new meal plan
        await mealPlanProvider.addMealPlan(updatedMealPlan);
      } else {
        // Update existing meal plan
        final updatedMealPlan = _addItemToMealPlan(mealPlan, newItem);

        // Save updated meal plan
        await mealPlanProvider.updateMealPlan(updatedMealPlan);
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal item added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  MealPlanModel _addItemToMealPlan(MealPlanModel mealPlan, MealItem newItem) {
    switch (_selectedMealType) {
      case 'Breakfast':
        return mealPlan.copyWith(breakfast: [...mealPlan.breakfast, newItem]);
      case 'Lunch':
        return mealPlan.copyWith(lunch: [...mealPlan.lunch, newItem]);
      case 'Dinner':
        return mealPlan.copyWith(dinner: [...mealPlan.dinner, newItem]);
      case 'Snack':
        return mealPlan.copyWith(snacks: [...mealPlan.snacks, newItem]);
      default:
        return mealPlan;
    }
  }
}

class _EditMealDialog extends StatefulWidget {
  final MealPlanModel mealPlan;
  final String mealType;

  const _EditMealDialog({required this.mealPlan, required this.mealType});

  @override
  State<_EditMealDialog> createState() => _EditMealDialogState();
}

class _EditMealDialogState extends State<_EditMealDialog> {
  late List<MealItem> _items;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    switch (widget.mealType) {
      case 'Breakfast':
        _items = List.from(widget.mealPlan.breakfast);
        break;
      case 'Lunch':
        _items = List.from(widget.mealPlan.lunch);
        break;
      case 'Dinner':
        _items = List.from(widget.mealPlan.dinner);
        break;
      case 'Snacks':
        _items = List.from(widget.mealPlan.snacks);
        break;
      default:
        _items = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.mealType}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No items in this meal'),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle:
                          item.description != null
                              ? Text(item.description!)
                              : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _items.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

            // Add new item button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                onPressed: () {
                  _showAddItemDialog(context);
                },
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveMeal, child: const Text('Save')),
      ],
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Food Name',
                    hintText: 'e.g., Premium Kibble',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g., 1 cup, high-protein formula',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      _items.add(
                        MealItem(
                          name: nameController.text,
                          description:
                              descriptionController.text.isNotEmpty
                                  ? descriptionController.text
                                  : null,
                        ),
                      );
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveMeal() async {
    try {
      final mealPlanProvider = Provider.of<MealPlanProvider>(
        context,
        listen: false,
      );

      // Update meal plan with edited items
      MealPlanModel updatedMealPlan;

      switch (widget.mealType) {
        case 'Breakfast':
          updatedMealPlan = widget.mealPlan.copyWith(breakfast: _items);
          break;
        case 'Lunch':
          updatedMealPlan = widget.mealPlan.copyWith(lunch: _items);
          break;
        case 'Dinner':
          updatedMealPlan = widget.mealPlan.copyWith(dinner: _items);
          break;
        case 'Snacks':
          updatedMealPlan = widget.mealPlan.copyWith(snacks: _items);
          break;
        default:
          updatedMealPlan = widget.mealPlan;
      }

      // Save updated meal plan
      await mealPlanProvider.updateMealPlan(updatedMealPlan);

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}

class _MealPlanDetailsDialog extends StatelessWidget {
  final MealPlanModel mealPlan;
  final String dogName;

  const _MealPlanDetailsDialog({required this.mealPlan, required this.dogName});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return AlertDialog(
      title: Text('Meal Plan for ${dateFormat.format(mealPlan.date)}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dog: $dogName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Breakfast
            if (mealPlan.breakfast.isNotEmpty) ...[
              const Text(
                'Breakfast',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...mealPlan.breakfast.map((item) => _buildMealItemDetail(item)),
              const SizedBox(height: 16),
            ],

            // Lunch
            if (mealPlan.lunch.isNotEmpty) ...[
              const Text(
                'Lunch',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...mealPlan.lunch.map((item) => _buildMealItemDetail(item)),
              const SizedBox(height: 16),
            ],

            // Dinner
            if (mealPlan.dinner.isNotEmpty) ...[
              const Text(
                'Dinner',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...mealPlan.dinner.map((item) => _buildMealItemDetail(item)),
              const SizedBox(height: 16),
            ],

            // Snacks
            if (mealPlan.snacks.isNotEmpty) ...[
              const Text(
                'Snacks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...mealPlan.snacks.map((item) => _buildMealItemDetail(item)),
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
      ],
    );
  }

  Widget _buildMealItemDetail(MealItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
