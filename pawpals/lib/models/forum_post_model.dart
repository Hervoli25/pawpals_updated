import 'package:uuid/uuid.dart';

class Comment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  Comment({
    String? id,
    required this.userId,
    required this.content,
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      userId: map['userId'],
      content: map['content'],
      createdAt: map['createdAt'].toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
    };
  }
}

class ForumPostModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final List<String> tags;
  final List<Comment> comments;
  final int likes;

  ForumPostModel({
    String? id,
    required this.userId,
    required this.title,
    required this.content,
    DateTime? createdAt,
    List<String>? tags,
    List<Comment>? comments,
    int? likes,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    tags = tags ?? [],
    comments = comments ?? [],
    likes = likes ?? 0;

  factory ForumPostModel.fromMap(Map<String, dynamic> map) {
    return ForumPostModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      content: map['content'],
      createdAt: map['createdAt'].toDate(),
      tags: List<String>.from(map['tags'] ?? []),
      comments: (map['comments'] as List?)
          ?.map((item) => Comment.fromMap(item))
          .toList() ?? [],
      likes: map['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'tags': tags,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'likes': likes,
    };
  }

  ForumPostModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    List<String>? tags,
    List<Comment>? comments,
    int? likes,
  }) {
    return ForumPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
      likes: likes ?? this.likes,
    );
  }
}
