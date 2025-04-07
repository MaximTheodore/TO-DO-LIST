import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryTask {
  final String? id;
  final String title;
  final String imageUrl;
  final int color;
  String? userId;

  CategoryTask({
    this.id,
    required this.title,
    required this.imageUrl,
    required this.color,
    this.userId
  });

  factory CategoryTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot){
    final data = snapshot.data()!;
    return CategoryTask(
      id: snapshot.id.toString(),
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      color: data['color'],
      userId: data['userId']
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'color': color,
      'userId': userId
    };
  }
}