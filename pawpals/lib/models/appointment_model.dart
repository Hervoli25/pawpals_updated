import 'package:uuid/uuid.dart';

class AppointmentModel {
  final String id;
  final String dogId;
  final String title;
  final DateTime dateTime;
  final String? location;
  final String? notes;
  final String type; // Vet, Grooming, Training, etc.
  final bool isCompleted;

  AppointmentModel({
    String? id,
    required this.dogId,
    required this.title,
    required this.dateTime,
    this.location,
    this.notes,
    required this.type,
    bool? isCompleted,
  }) : 
    id = id ?? const Uuid().v4(),
    isCompleted = isCompleted ?? false;

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'],
      dogId: map['dogId'],
      title: map['title'],
      dateTime: map['dateTime'].toDate(),
      location: map['location'],
      notes: map['notes'],
      type: map['type'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dogId': dogId,
      'title': title,
      'dateTime': dateTime,
      'location': location,
      'notes': notes,
      'type': type,
      'isCompleted': isCompleted,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? dogId,
    String? title,
    DateTime? dateTime,
    String? location,
    String? notes,
    String? type,
    bool? isCompleted,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      dogId: dogId ?? this.dogId,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
