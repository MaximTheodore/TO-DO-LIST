import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:to_do_list_app/data/models/task_model.dart';
import 'package:to_do_list_app/domain/repositories/i_task_repository.dart';

class TaskRepositoryImpl implements ITaskRepository {
  final FirebaseFirestore _firestore;

  TaskRepositoryImpl(this._firestore);

  @override
  Future<List<Task>> getAll() async {
    final snapshot = await _firestore.collection('tasks').get();
    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc, null))
        .toList();  
  }

  @override
  Future<Task?> getById(String id) async {
    final doc = await _firestore.collection('tasks').doc(id).get();
    return doc.exists ? Task.fromFirestore(doc, null) : null;
  }

  @override
  Future<String> add(Task item) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final docRef = await _firestore.collection('tasks').add({
      ...item.toFirestore(),
      'userId': userId,
    });
    return docRef.id;
  }

  @override
  Future<void> update(String id, Task item) async {
    await _firestore
        .collection('tasks')
        .doc(id)
        .update(item.toFirestore());
  }

  @override
  Future<void> delete(String id) async {
    await _firestore.collection('tasks').doc(id).delete();
  }
  @override
  Future<List<Task>> getUserTasks(String userId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc, null))
        .toList();
  }
}