import 'package:uuid/uuid.dart';

class PlaydateModel {
  final String id;
  final String dogId1; // First dog in the playdate
  final String dogId2; // Second dog in the playdate
  final DateTime date;
  final String? location; // Optional location name
  final String? locationDetails; // Optional location details
  final String status; // Pending, Accepted, Rejected, Completed

  PlaydateModel({
    String? id,
    required this.dogId1,
    required this.dogId2,
    required this.date,
    this.location,
    this.locationDetails,
    required this.status,
  }) : id = id ?? const Uuid().v4();

  // Create a PlaydateModel from a map (e.g., from Firestore)
  factory PlaydateModel.fromMap(Map<String, dynamic> map) {
    return PlaydateModel(
      id: map['id'],
      dogId1: map['dogId1'],
      dogId2: map['dogId2'],
      date: map['date'].toDate(), // Convert Firestore Timestamp to DateTime
      location: map['location'],
      locationDetails: map['locationDetails'],
      status: map['status'],
    );
  }

  // Convert PlaydateModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dogId1': dogId1,
      'dogId2': dogId2,
      'date': date, // Firestore will convert DateTime to Timestamp
      'location': location,
      'locationDetails': locationDetails,
      'status': status,
    };
  }

  // Create a copy of PlaydateModel with some fields changed
  PlaydateModel copyWith({
    String? id,
    String? dogId1,
    String? dogId2,
    DateTime? date,
    String? location,
    String? locationDetails,
    String? status,
  }) {
    return PlaydateModel(
      id: id ?? this.id,
      dogId1: dogId1 ?? this.dogId1,
      dogId2: dogId2 ?? this.dogId2,
      date: date ?? this.date,
      location: location ?? this.location,
      locationDetails: locationDetails ?? this.locationDetails,
      status: status ?? this.status,
    );
  }
}
