import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Discussion'), Tab(text: 'Events')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Discussion Tab
          _DiscussionTab(),

          // Events Tab
          _EventsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to create new post or event based on current tab
          if (_tabController.index == 0) {
            _showCreatePostDialog(context);
          } else {
            _showCreateEventDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreatePostDialog(),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateEventDialog(),
    );
  }
}

class _DiscussionTab extends StatelessWidget {
  const _DiscussionTab();

  @override
  Widget build(BuildContext context) {
    // For demo purposes, we'll show some mock forum posts
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      children: [
        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search discussions...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),

        // Topic filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TopicChip(label: 'All Topics', isSelected: true, onTap: () {}),
              _TopicChip(label: 'Training', isSelected: false, onTap: () {}),
              _TopicChip(label: 'Health', isSelected: false, onTap: () {}),
              _TopicChip(label: 'Nutrition', isSelected: false, onTap: () {}),
              _TopicChip(label: 'Behavior', isSelected: false, onTap: () {}),
              _TopicChip(label: 'Breeds', isSelected: false, onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Forum posts
        _ForumPostCard(
          title: 'Tips for socializing a shy dog?',
          author: 'DogLover123',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          content:
              'My 2-year-old rescue is very shy around other dogs. Any tips for helping her become more comfortable in social settings?',
          commentCount: 12,
          likeCount: 24,
          tags: ['Training', 'Behavior'],
        ),
        const SizedBox(height: 16),

        _ForumPostCard(
          title: 'Best dog-friendly hiking trails?',
          author: 'HikingWithDogs',
          date: DateTime.now().subtract(const Duration(days: 1)),
          content:
              'Looking for recommendations for dog-friendly hiking trails in the area. Preferably with water access for swimming!',
          commentCount: 8,
          likeCount: 15,
          tags: ['Activities', 'Outdoors'],
        ),
        const SizedBox(height: 16),

        _ForumPostCard(
          title: 'Grain-free diet pros and cons?',
          author: 'HealthyPup',
          date: DateTime.now().subtract(const Duration(days: 2)),
          content:
              'I\'ve been hearing mixed things about grain-free diets. What are your experiences? Any recommendations?',
          commentCount: 20,
          likeCount: 18,
          tags: ['Nutrition', 'Health'],
        ),
        const SizedBox(height: 16),

        _ForumPostCard(
          title: 'Separation anxiety solutions',
          author: 'WorriedOwner',
          date: DateTime.now().subtract(const Duration(days: 3)),
          content:
              'My dog has severe separation anxiety. I\'ve tried everything but nothing seems to work. Any advice would be appreciated!',
          commentCount: 15,
          likeCount: 32,
          tags: ['Behavior', 'Training'],
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onTap();
          }
        },
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  final String title;
  final String author;
  final DateTime date;
  final String content;
  final int commentCount;
  final int likeCount;
  final List<String> tags;

  const _ForumPostCard({
    required this.title,
    required this.author,
    required this.date,
    required this.content,
    required this.commentCount,
    required this.likeCount,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),

            // Author and date
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  child: Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  author,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(date),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Text(content, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up_outlined),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    Text('$likeCount'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    Text('$commentCount'),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // View full post
                  },
                  child: const Text('View Discussion'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    // For demo purposes, we'll show some mock events
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      children: [
        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search events...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),

        // Event type filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TopicChip(label: 'All Events', isSelected: true, onTap: () {}),
              _TopicChip(label: 'Meetups', isSelected: false, onTap: () {}),
              _TopicChip(label: 'Training', isSelected: false, onTap: () {}),
              _TopicChip(label: 'Adoption', isSelected: false, onTap: () {}),
              _TopicChip(label: 'Fundraisers', isSelected: false, onTap: () {}),
              _TopicChip(label: 'Shows', isSelected: false, onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Upcoming events section
        const Text(
          'Upcoming Events',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),

        // Event cards
        _EventCard(
          title: 'Central Park Dog Meetup',
          date: DateTime.now().add(const Duration(days: 3)),
          location: 'Central Park, New York',
          organizer: 'NYC Dog Lovers',
          attendeeCount: 24,
          imageUrl: '',
          description:
              'Join us for a fun afternoon at Central Park with your furry friends! All breeds welcome.',
        ),
        const SizedBox(height: 16),

        _EventCard(
          title: 'Basic Obedience Training Workshop',
          date: DateTime.now().add(const Duration(days: 7)),
          location: 'PetSmart Training Center',
          organizer: 'Professional Dog Trainers Association',
          attendeeCount: 12,
          imageUrl: '',
          description:
              'Learn basic obedience commands and techniques from professional trainers.',
        ),
        const SizedBox(height: 16),

        _EventCard(
          title: 'Adoption Day at Animal Shelter',
          date: DateTime.now().add(const Duration(days: 10)),
          location: 'City Animal Shelter',
          organizer: 'Animal Rescue League',
          attendeeCount: 50,
          imageUrl: '',
          description:
              'Find your perfect furry companion! Many dogs and puppies looking for forever homes.',
        ),
        const SizedBox(height: 24),

        // Past events section
        const Text(
          'Past Events',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),

        _EventCard(
          title: 'Dog-Friendly Beach Day',
          date: DateTime.now().subtract(const Duration(days: 5)),
          location: 'Brighton Beach',
          organizer: 'Beach Dogs Club',
          attendeeCount: 35,
          imageUrl: '',
          description:
              'A day of fun in the sun and sand with your four-legged friends!',
          isPast: true,
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String location;
  final String organizer;
  final int attendeeCount;
  final String imageUrl;
  final String description;
  final bool isPast;

  const _EventCard({
    required this.title,
    required this.date,
    required this.location,
    required this.organizer,
    required this.attendeeCount,
    required this.imageUrl,
    required this.description,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.event, size: 50)),
          ),

          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                      dateFormat.format(date),
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
                      timeFormat.format(date),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
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
                        location,
                        style: TextStyle(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Organizer
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Organized by: $organizer',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),

                // Attendees and action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16),
                        const SizedBox(width: 4),
                        Text('$attendeeCount attending'),
                      ],
                    ),
                    isPast
                        ? OutlinedButton(
                          onPressed: () {
                            // View event details
                          },
                          child: const Text('View Details'),
                        )
                        : ElevatedButton(
                          onPressed: () {
                            // RSVP to event
                          },
                          child: const Text('RSVP'),
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
}

class _CreatePostDialog extends StatefulWidget {
  const _CreatePostDialog();

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _selectedTags = [];

  final List<String> _availableTags = [
    'Training',
    'Health',
    'Nutrition',
    'Behavior',
    'Breeds',
    'Activities',
    'Outdoors',
    'Products',
    'Grooming',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a descriptive title',
              ),
            ),
            const SizedBox(height: 16),

            // Content
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Share your thoughts, questions, or experiences',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Tags
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
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
        ElevatedButton(
          onPressed: () {
            // Create post
            if (_titleController.text.isNotEmpty &&
                _contentController.text.isNotEmpty) {
              // In a real app, this would save the post to a database
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post created successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in all required fields'),
                ),
              );
            }
          },
          child: const Text('Post'),
        ),
      ],
    );
  }
}

class _CreateEventDialog extends StatefulWidget {
  const _CreateEventDialog();

  @override
  State<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<_CreateEventDialog> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _selectedType = 'Meetup';

  final List<String> _eventTypes = [
    'Meetup',
    'Training',
    'Adoption',
    'Fundraiser',
    'Show',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                hintText: 'Enter a descriptive title',
              ),
            ),
            const SizedBox(height: 16),

            // Event type
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Event Type'),
              value: _selectedType,
              items:
                  _eventTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Date and time
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('MMM d, yyyy').format(_selectedDate),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    controller: TextEditingController(
                      text: _selectedTime.format(context),
                    ),
                    onTap: () async {
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
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Enter the event location',
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Provide details about the event',
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
        ElevatedButton(
          onPressed: () {
            // Create event
            if (_titleController.text.isNotEmpty &&
                _locationController.text.isNotEmpty &&
                _descriptionController.text.isNotEmpty) {
              // In a real app, this would save the event to a database
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event created successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in all required fields'),
                ),
              );
            }
          },
          child: const Text('Create Event'),
        ),
      ],
    );
  }
}
