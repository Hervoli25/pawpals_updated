import 'package:flutter/material.dart';
import '../models/models.dart';

class AppointmentProvider extends ChangeNotifier {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get upcoming appointments
  List<AppointmentModel> getUpcomingAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((appointment) => 
            appointment.dateTime.isAfter(now) && 
            !appointment.isCompleted)
        .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Get appointments for a specific dog
  List<AppointmentModel> getAppointmentsForDog(String dogId) {
    return _appointments
        .where((appointment) => appointment.dogId == dogId)
        .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // For demo purposes, we'll use a simple method to load appointments
  // In a real app, this would fetch from a database or API
  Future<void> loadAppointments(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Demo data
      final now = DateTime.now();
      _appointments = [
        AppointmentModel(
          id: 'appt1',
          dogId: 'dog1',
          title: 'Vet Checkup',
          dateTime: now.add(const Duration(days: 1, hours: 10)),
          location: 'PetCare Clinic',
          notes: 'Annual checkup and vaccinations',
          type: 'Vet Checkup',
        ),
        AppointmentModel(
          id: 'appt2',
          dogId: 'dog2',
          title: 'Grooming',
          dateTime: now.add(const Duration(days: 3, hours: 14)),
          location: 'Pawsome Grooming',
          notes: 'Full service grooming',
          type: 'Grooming',
        ),
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAppointment(AppointmentModel appointment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _appointments.add(appointment);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAppointment(AppointmentModel updatedAppointment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final index = _appointments.indexWhere(
          (appointment) => appointment.id == updatedAppointment.id);
      if (index != -1) {
        _appointments[index] = updatedAppointment;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Appointment not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _appointments.removeWhere((appointment) => appointment.id == appointmentId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAppointmentComplete(String appointmentId, bool isCompleted) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final index = _appointments.indexWhere(
          (appointment) => appointment.id == appointmentId);
      if (index != -1) {
        final updated = _appointments[index].copyWith(isCompleted: isCompleted);
        _appointments[index] = updated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Appointment not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
