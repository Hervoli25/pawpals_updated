import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );
      final dogProvider = Provider.of<DogProvider>(context, listen: false);

      final user = authProvider.user;

      if (user != null) {
        // Make sure dogs are loaded
        if (dogProvider.dogs.isEmpty) {
          await dogProvider.loadDogs(user.id);
        }

        // Load appointments
        await appointmentProvider.loadAppointments(user.id);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAppointmentDialog(context),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Calendar
                  _buildCalendar(),

                  // Appointments for selected day
                  Expanded(child: _buildAppointmentsList()),
                ],
              ),
      bottomNavigationBar: const PawPalsBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildCalendar() {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final appointments = appointmentProvider.appointments;

    // Create a map of dates with appointments
    final Map<DateTime, List<AppointmentModel>> appointmentMap = {};
    for (final appointment in appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );

      if (appointmentMap[date] == null) {
        appointmentMap[date] = [];
      }

      appointmentMap[date]!.add(appointment);
    }

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: (day) {
        return appointmentMap[DateTime(day.year, day.month, day.day)] ?? [];
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withAlpha(128),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final dogProvider = Provider.of<DogProvider>(context);
    final appointments = appointmentProvider.appointments;

    // Filter appointments for the selected day
    final selectedDayAppointments =
        appointments.where((appointment) {
          return isSameDay(appointment.dateTime, _selectedDay);
        }).toList();

    // Sort by time
    selectedDayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (selectedDayAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No appointments for ${DateFormat('MMMM d, yyyy').format(_selectedDay)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Appointment'),
              onPressed: () => _showAddAppointmentDialog(context),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: selectedDayAppointments.length,
      itemBuilder: (context, index) {
        final appointment = selectedDayAppointments[index];
        final dog = dogProvider.getDogById(appointment.dogId);

        return _AppointmentCard(
          appointment: appointment,
          dogName: dog?.name ?? 'Unknown Dog',
          onTap: () => _showAppointmentDetails(context, appointment),
        );
      },
    );
  }

  void _showAddAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddAppointmentDialog(),
    );
  }

  void _showAppointmentDetails(
    BuildContext context,
    AppointmentModel appointment,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AppointmentDetailsDialog(appointment: appointment),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final String dogName;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.dogName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeFormat.format(appointment.dateTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(appointment.type).withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      appointment.type,
                      style: TextStyle(
                        color: _getTypeColor(appointment.type),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Appointment details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For $dogName',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    if (appointment.location != null) ...[
                      const SizedBox(height: 4),
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
                              appointment.location!,
                              style: TextStyle(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status indicator
              Checkbox(
                value: appointment.isCompleted,
                onChanged: (value) {
                  // Update appointment status
                  Provider.of<AppointmentProvider>(
                    context,
                    listen: false,
                  ).markAppointmentComplete(appointment.id, value ?? false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Vet':
        return Colors.red;
      case 'Grooming':
        return Colors.blue;
      case 'Training':
        return Colors.green;
      case 'Medication':
        return Colors.orange;
      case 'Vaccination':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }
}

class _AddAppointmentDialog extends StatefulWidget {
  const _AddAppointmentDialog();

  @override
  State<_AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<_AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedDogId;
  String _selectedType = 'Vet';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  final List<String> _appointmentTypes = [
    'Vet',
    'Grooming',
    'Training',
    'Medication',
    'Vaccination',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<DogProvider>(context);
    final dogs = dogProvider.dogs;

    return AlertDialog(
      title: const Text('Add Appointment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dog selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Dog'),
                value: _selectedDogId,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a dog';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Annual Checkup',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Type'),
                value: _selectedType,
                items:
                    _appointmentTypes.map((type) {
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
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'e.g., City Vet Clinic',
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any additional details',
                ),
                maxLines: 3,
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
        ElevatedButton(onPressed: _saveAppointment, child: const Text('Save')),
      ],
    );
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Combine date and time
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create appointment
      final appointment = AppointmentModel(
        dogId: _selectedDogId!,
        title: _titleController.text,
        dateTime: dateTime,
        location:
            _locationController.text.isNotEmpty
                ? _locationController.text
                : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        type: _selectedType,
      );

      // Save appointment
      final success = await Provider.of<AppointmentProvider>(
        context,
        listen: false,
      ).addAppointment(appointment);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add appointment')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}

class _AppointmentDetailsDialog extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentDetailsDialog({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<DogProvider>(context);
    final dog = dogProvider.getDogById(appointment.dogId);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return AlertDialog(
      title: Text(appointment.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor(appointment.type).withAlpha(26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              appointment.type,
              style: TextStyle(
                color: _getTypeColor(appointment.type),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dog
          _DetailItem(
            icon: Icons.pets,
            label: 'Dog',
            value: dog?.name ?? 'Unknown Dog',
          ),

          // Date and time
          _DetailItem(
            icon: Icons.calendar_today,
            label: 'Date',
            value: dateFormat.format(appointment.dateTime),
          ),
          _DetailItem(
            icon: Icons.access_time,
            label: 'Time',
            value: timeFormat.format(appointment.dateTime),
          ),

          // Location
          if (appointment.location != null)
            _DetailItem(
              icon: Icons.location_on,
              label: 'Location',
              value: appointment.location!,
            ),

          // Notes
          if (appointment.notes != null) ...[
            const SizedBox(height: 8),
            const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(appointment.notes!),
          ],

          // Status
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: appointment.isCompleted,
                onChanged: (value) {
                  // Update appointment status
                  Provider.of<AppointmentProvider>(
                    context,
                    listen: false,
                  ).markAppointmentComplete(appointment.id, value ?? false);
                  Navigator.of(context).pop();
                },
              ),
              Text(
                appointment.isCompleted ? 'Completed' : 'Pending',
                style: TextStyle(
                  color: appointment.isCompleted ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _confirmDeleteAppointment(context, appointment);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Vet':
        return Colors.red;
      case 'Grooming':
        return Colors.blue;
      case 'Training':
        return Colors.green;
      case 'Medication':
        return Colors.orange;
      case 'Vaccination':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  void _confirmDeleteAppointment(
    BuildContext context,
    AppointmentModel appointment,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Appointment'),
            content: const Text(
              'Are you sure you want to delete this appointment?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  final success = await Provider.of<AppointmentProvider>(
                    context,
                    listen: false,
                  ).deleteAppointment(appointment.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Appointment deleted successfully'
                              : 'Failed to delete appointment',
                        ),
                      ),
                    );
                  }
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
