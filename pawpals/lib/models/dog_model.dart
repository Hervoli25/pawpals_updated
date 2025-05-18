import 'package:uuid/uuid.dart';

class DogModel {
  final String id;
  final String name;
  final String breed;
  final int age; // Age in years
  final String size; // Small, Medium, Large
  final String? photoUrl;
  final String ownerId; // Reference to User
  final Map<String, dynamic>? temperament; // Optional temperament traits

  DogModel({
    String? id,
    required this.name,
    required this.breed,
    required this.age,
    required this.size,
    this.photoUrl,
    required this.ownerId,
    this.temperament,
  }) : id = id ?? const Uuid().v4();

  // Create a DogModel from a map (e.g., from Firestore)
  factory DogModel.fromMap(Map<String, dynamic> map) {
    return DogModel(
      id: map['id'],
      name: map['name'],
      breed: map['breed'],
      age: map['age'],
      size: map['size'],
      photoUrl: map['photoUrl'],
      ownerId: map['ownerId'],
      temperament: map['temperament'],
    );
  }

  // Convert DogModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'size': size,
      'photoUrl': photoUrl,
      'ownerId': ownerId,
      'temperament': temperament,
    };
  }

  // Create a copy of DogModel with some fields changed
  DogModel copyWith({
    String? id,
    String? name,
    String? breed,
    int? age,
    String? size,
    String? photoUrl,
    String? ownerId,
    Map<String, dynamic>? temperament,
  }) {
    return DogModel(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      size: size ?? this.size,
      photoUrl: photoUrl ?? this.photoUrl,
      ownerId: ownerId ?? this.ownerId,
      temperament: temperament ?? this.temperament,
    );
  }
}
