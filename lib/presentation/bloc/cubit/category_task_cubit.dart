import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:to_do_list_app/data/models/category_task_model.dart';
import 'package:to_do_list_app/domain/repositories/i_repository.dart';

part 'category_task_state.dart';

class CategoryTaskCubit extends Cubit<CategoryTaskState> {
  final IRepository<CategoryTask> _repository;

  CategoryTaskCubit(this._repository) : super(CategoryTaskInitial()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    emit(CategoryTaskLoading());
    try {
      final categories = await _repository.getAll();
      emit(CategoryTaskLoaded(categories));
    } catch (e) {
      emit(CategoryTaskError('Ошибка загрузки: ${e.toString()}'));
    }
  }

  Future<void> addCategory(CategoryTask category) async {
    emit(CategoryTaskLoading());
    try {
      await _repository.add(category);
      emit(CategoryTaskOperationSuccess('Категория добавлена'));
      await loadCategories();
    } catch (e) {
      emit(CategoryTaskError('Ошибка добавления: ${e.toString()}'));
    }
  }

  Future<void> updateCategory(String id, CategoryTask category) async {
    emit(CategoryTaskLoading());
    try {
      await _repository.update(id, category);
      emit(CategoryTaskOperationSuccess('Категория обновлена'));
      await loadCategories();
    } catch (e) {
      emit(CategoryTaskError('Failed to update category: ${e.toString()}'));
    }
  }

  Future<void> deleteCategory(String id) async {
    emit(CategoryTaskLoading());
    try {
      await _repository.delete(id);
      emit(CategoryTaskOperationSuccess('Категория удалена'));
      await loadCategories(); 
    } catch (e) {
      emit(CategoryTaskError('Ошибка удаления: ${e.toString()}'));
    }
  }

  Future<CategoryTask?> getCategoryById(String id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      emit(CategoryTaskError('Ошибка получения категории: ${e.toString()}'));
      return null;
    }
  }
} 