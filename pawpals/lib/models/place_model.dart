import 'package:uuid/uuid.dart';

class PlaceModel {
  final String id;
  final String name;
  final String category; // Park, Cafe, Hotel, etc.
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;
  final String? photoUrl;
  final double? rating; // Optional rating
  final Map<String, dynamic>? amenities; // Optional amenities

  PlaceModel({
    String? id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
    this.photoUrl,
    this.rating,
    this.amenities,
  }) : id = id ?? const Uuid().v4();

  // Create a PlaceModel from a map (e.g., from Firestore)
  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
      description: map['description'],
      photoUrl: map['photoUrl'],
      rating: map['rating'],
      amenities: map['amenities'],
    );
  }

  // Convert PlaceModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'photoUrl': photoUrl,
      'rating': rating,
      'amenities': amenities,
    };
  }

  // Create a copy of PlaceModel with some fields changed
  PlaceModel copyWith({
    String? id,
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    String? address,
    String? description,
    String? photoUrl,
    double? rating,
    Map<String, dynamic>? amenities,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      amenities: amenities ?? this.amenities,
    );
  }
}
