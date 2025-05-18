import 'package:uuid/uuid.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String? location;
  final String? locationDetails;
  final String? imageUrl;
  final String organizerId;
  final List<String> attendeeIds;

  EventModel({
    String? id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.location,
    this.locationDetails,
    this.imageUrl,
    required this.organizerId,
    List<String>? attendeeIds,
  }) : 
    id = id ?? const Uuid().v4(),
    attendeeIds = attendeeIds ?? [];

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: map['dateTime'].toDate(),
      location: map['location'],
      locationDetails: map['locationDetails'],
      imageUrl: map['imageUrl'],
      organizerId: map['organizerId'],
      attendeeIds: List<String>.from(map['attendeeIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime,
      'location': location,
      'locationDetails': locationDetails,
      'imageUrl': imageUrl,
      'organizerId': organizerId,
      'attendeeIds': attendeeIds,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? locationDetails,
    String? imageUrl,
    String? organizerId,
    List<String>? attendeeIds,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      locationDetails: locationDetails ?? this.locationDetails,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerId: organizerId ?? this.organizerId,
      attendeeIds: attendeeIds ?? this.attendeeIds,
    );
  }
}
