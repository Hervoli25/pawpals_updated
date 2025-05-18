import 'package:uuid/uuid.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePic;
  final String? password; // Only used for registration, not stored
  final List<String> dogIds; // References to Dog objects

  UserModel({
    String? id,
    required this.name,
    required this.email,
    this.profilePic,
    this.password,
    List<String>? dogIds,
  }) : 
    id = id ?? const Uuid().v4(),
    dogIds = dogIds ?? [];

  // Create a UserModel from a map (e.g., from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      profilePic: map['profilePic'],
      dogIds: List<String>.from(map['dogIds'] ?? []),
    );
  }

  // Convert UserModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'dogIds': dogIds,
    };
  }

  // Create a copy of UserModel with some fields changed
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePic,
    String? password,
    List<String>? dogIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      password: password ?? this.password,
      dogIds: dogIds ?? this.dogIds,
    );
  }
}
