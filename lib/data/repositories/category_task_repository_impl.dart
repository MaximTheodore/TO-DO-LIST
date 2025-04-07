import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:to_do_list_app/data/models/category_task_model.dart';
import 'package:to_do_list_app/domain/repositories/i_repository.dart';

class CategoryTaskRepositoryImpl implements IRepository<CategoryTask> {
  final FirebaseFirestore _firestore;

  CategoryTaskRepositoryImpl(this._firestore);

  @override
  Future<List<CategoryTask>> getAll() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final snapshot = await _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => CategoryTask.fromFirestore(doc))
        .toList();
  }

  @override
  Future<CategoryTask?> getById(String id) async {
    final doc = await _firestore.collection('categories').doc(id).get();
    return doc.exists ? CategoryTask.fromFirestore(doc) : null;
  }

  @override
  Future<String> add(CategoryTask item) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final docRef = await _firestore.collection('categories').add({
      ...item.toFirestore(),
      'userId': userId,
    });
    return docRef.id;
  }

  @override
  Future<void> update(String id, CategoryTask item) async {
    await _firestore
        .collection('categories')
        .doc(id)
        .update(item.toFirestore());
  }

  @override
  Future<void> delete(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }
}