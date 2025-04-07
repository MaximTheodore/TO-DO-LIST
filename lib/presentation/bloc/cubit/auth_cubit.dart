import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/category_task_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/task_cubit.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _guestId;

  AuthCubit(this._auth) : super(AuthInitial()) {
    _checkCurrentUser();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _checkCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      if (currentUser.isAnonymous) {
        _guestId = currentUser.uid;
      }
      emit(Authenticated(currentUser));
    } else {
      await signInAnonymously();
    }
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      if (user.isAnonymous) {
        _guestId = user.uid;
      } else {
        _guestId = null;
      }
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  bool get isAuthenticated => _auth.currentUser != null;

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(BuildContext context, String email, String password) async {
    try {
      emit(AuthLoading());
      
      User? guestUser = _auth.currentUser;
      String? tempGuestId = _guestId;

      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = result.user!;


      if (tempGuestId != null && tempGuestId != user.uid) {
        await _mergeGuestData(tempGuestId, user);
      }
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Неправльный пароль или почта'));
    }
  }

  Future<void> signUp(BuildContext context, String email, String password) async {
    try {
      emit(AuthLoading());
      
      User? guestUser = _auth.currentUser;
      String? tempGuestId = _guestId;

      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = result.user!;

      if (tempGuestId != null && tempGuestId != user.uid) {
        await _mergeGuestData(tempGuestId, user);
      }

      emit(AuthOperationSuccess('Регистрация успешна'));
    } catch (e) {
      emit(AuthError('Неправльная почта или пароль'));
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      emit(AuthLoading());
      await _auth.signOut();
      await signInAnonymously();
    } catch (e) {
      emit(AuthError('Не удалось выйти из системы'));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      emit(AuthLoading());
      await _auth.sendPasswordResetEmail(email: email.trim());
      emit(ResetPasswordSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError('Не удалось отправить письмо'));
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      emit(AuthLoading());
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(AuthError('Нет активного пользователя для удаления'));
        return;
      }

      final userId = currentUser.uid;

      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in tasksSnapshot.docs) {
        await _firestore.collection('tasks').doc(doc.id).delete();
      }

      final categoriesSnapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in categoriesSnapshot.docs) {
        await _firestore.collection('categories').doc(doc.id).delete();
      }

      await currentUser.delete();
      if (currentUser.isAnonymous) {
        _guestId = null;
      }

      emit(Unauthenticated());
      await signInAnonymously();

      final newUserId = _auth.currentUser!.uid;
      context.read<TaskCubit>().updateUserId(newUserId);
      context.read<CategoryTaskCubit>().loadCategories();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        emit(AuthError('Требуется повторный вход для удаления аккаунта'));
      } else {
        emit(AuthError(_getErrorMessage(e.code)));
      }
    } catch (e) {
      emit(AuthError('Не удалось удалить аккаунт: ${e.toString()}'));
    }
  }

  Future<void> signInAnonymously() async {
    try {
      emit(AuthLoading());
      final result = await _auth.signInAnonymously();
      _guestId = result.user!.uid;
      emit(Authenticated(result.user!));
    } catch (e) {
      emit(AuthError('Ошибка анонимного входа: ${e.toString()}'));
    }
  }

  Future<void> _mergeGuestData(String guestId, User newUser) async {
    if (guestId == newUser.uid) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final guestTasksSnapshot = await _firestore
            .collection('tasks')
            .where('userId', isEqualTo: guestId)
            .get();
        
        final guestCategoriesSnapshot = await _firestore
            .collection('categories')
            .where('userId', isEqualTo: guestId)
            .get();

        if (guestTasksSnapshot.docs.isEmpty && guestCategoriesSnapshot.docs.isEmpty) {
          return;
        }

        for (final doc in guestTasksSnapshot.docs) {
          transaction.update(
            _firestore.collection('tasks').doc(doc.id),
            {'userId': newUser.uid},
          );
        }

        for (final doc in guestCategoriesSnapshot.docs) {
          transaction.update(
            _firestore.collection('categories').doc(doc.id),
            {'userId': newUser.uid},
          );
        }
      });

      await _deleteGuestUser(guestId);
      
    } catch (e) {
      emit(AuthError('Ошибка при слиянии данных: $e'));
    }
  }

  Future<void> _deleteGuestUser(String guestId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && !currentUser.isAnonymous) {
        _guestId = null;
        
        await _firestore.collection('deleted_users').doc(guestId).set({
          'uid': guestId,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      emit(AuthError('Не удалось очистить гостевой аккаунт: $e'));
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'invalid-email':
        return 'Некорректный email';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'weak-password':
        return 'Слабый пароль';
      case 'requires-recent-login':
        return 'Требуется повторный вход';
      default:
        return 'Произошла ошибка';
    }
  }
}