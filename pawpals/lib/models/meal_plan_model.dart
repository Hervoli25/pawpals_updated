import 'package:uuid/uuid.dart';

class MealItem {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final Map<String, dynamic>? nutritionInfo;

  MealItem({
    String? id,
    required this.name,
    this.description,
    this.imageUrl,
    this.nutritionInfo,
  }) : id = id ?? const Uuid().v4();

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      nutritionInfo: map['nutritionInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'nutritionInfo': nutritionInfo,
    };
  }
}

class MealPlanModel {
  final String id;
  final String dogId;
  final DateTime date;
  final List<MealItem> breakfast;
  final List<MealItem> lunch;
  final List<MealItem> dinner;
  final List<MealItem> snacks;

  MealPlanModel({
    String? id,
    required this.dogId,
    required this.date,
    List<MealItem>? breakfast,
    List<MealItem>? lunch,
    List<MealItem>? dinner,
    List<MealItem>? snacks,
  }) : 
    id = id ?? const Uuid().v4(),
    breakfast = breakfast ?? [],
    lunch = lunch ?? [],
    dinner = dinner ?? [],
    snacks = snacks ?? [];

  factory MealPlanModel.fromMap(Map<String, dynamic> map) {
    return MealPlanModel(
      id: map['id'],
      dogId: map['dogId'],
      date: map['date'].toDate(),
      breakfast: (map['breakfast'] as List?)
          ?.map((item) => MealItem.fromMap(item))
          .toList() ?? [],
      lunch: (map['lunch'] as List?)
          ?.map((item) => MealItem.fromMap(item))
          .toList() ?? [],
      dinner: (map['dinner'] as List?)
          ?.map((item) => MealItem.fromMap(item))
          .toList() ?? [],
      snacks: (map['snacks'] as List?)
          ?.map((item) => MealItem.fromMap(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dogId': dogId,
      'date': date,
      'breakfast': breakfast.map((item) => item.toMap()).toList(),
      'lunch': lunch.map((item) => item.toMap()).toList(),
      'dinner': dinner.map((item) => item.toMap()).toList(),
      'snacks': snacks.map((item) => item.toMap()).toList(),
    };
  }

  MealPlanModel copyWith({
    String? id,
    String? dogId,
    DateTime? date,
    List<MealItem>? breakfast,
    List<MealItem>? lunch,
    List<MealItem>? dinner,
    List<MealItem>? snacks,
  }) {
    return MealPlanModel(
      id: id ?? this.id,
      dogId: dogId ?? this.dogId,
      date: date ?? this.date,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snacks: snacks ?? this.snacks,
    );
  }
}
