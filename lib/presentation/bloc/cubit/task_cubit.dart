import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:to_do_list_app/data/models/task_model.dart';
import 'package:to_do_list_app/domain/repositories/i_task_repository.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final ITaskRepository _repository;
  String _userId;

  TaskCubit(this._repository, this._userId) : super(TaskInitial()) {
    loadUserTasks();
  }

  void updateUserId(String newUserId) {
    _userId = newUserId;
    loadUserTasks();
  }

  Future<void> loadUserTasks() async {
    emit(TaskLoading());
    try {
      final userTasks = await _repository.getUserTasks(_userId);
      emit(TasksLoaded(userTasks));
    } catch (e) {
      emit(TaskError('Ошибка загрузки заданий: ${e.toString()}'));
    }
  }

  Future<void> loadTasks() async {
    emit(TaskLoading());
    try {
      final tasks = await _repository.getAll();
      final userTasks = tasks.where((task) => task.userId == _userId).toList();
      emit(TasksLoaded(userTasks));
    } catch (e) {
      emit(TaskError('Ошибка загрузки заданий: ${e.toString()}'));
    }
  }

  Future<void> addTask(Task task) async {
    try {
      emit(TaskLoading());
      await _repository.add(task.copyWith(userId: _userId));
      emit(TaskOperationSuccess('Задача успешно добавлена'));
      await loadUserTasks();
    } catch (e) {
      emit(TaskError('Не удалось добавить задачу: ${e.toString()}'));
    }
  }

  Future<void> updateTask(String id, Task task) async {
    try {
      emit(TaskLoading());
      await _repository.update(id, task.copyWith(userId: _userId));
      emit(TaskOperationSuccess('Задача успешно обновлена'));
      await loadUserTasks();
    } catch (e) {
      emit(TaskError('Не удалось обновить задачу: ${e.toString()}'));
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      emit(TaskLoading());
      await _repository.delete(id);
      emit(TaskOperationSuccess('Задача успешно удалена'));
      await loadUserTasks();
    } catch (e) {
      emit(TaskError('Не удалось удалить задачу: ${e.toString()}'));
    }
  }

  Future<void> toggleTaskCompletion(String id, Task task) async {
    try {
      emit(TaskLoading());
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedDay: DateTime.now(),
      );
      await _repository.update(id, updatedTask);
      emit(TaskCompletionToggled(id, updatedTask.isCompleted));
      await loadUserTasks();
    } catch (e) {
      emit(TaskError('Не удалось изменить статус задачи: ${e.toString()}'));
    }
  }

  Future<Task?> getTaskById(String id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      emit(TaskError('Не удалось получить задачу: ${e.toString()}'));
      return null;
    }
  }

  Future<void> loadCompletedTasks() async {
    emit(TaskLoading());
    try {
      final userTasks = await _repository.getUserTasks(_userId);
      final completedTasks = userTasks.where((task) => task.isCompleted).toList();
      emit(TasksLoaded(completedTasks));
    } catch (e) {
      emit(TaskError('Не удалось загрузить выполненные задачи: ${e.toString()}'));
    }
  }

  Future<void> loadActiveTasks() async {
    emit(TaskLoading());
    try {
      final userTasks = await _repository.getUserTasks(_userId);
      final activeTasks = userTasks.where((task) => !task.isCompleted).toList();
      emit(TasksLoaded(activeTasks));
    } catch (e) {
      emit(TaskError('Не удалось загрузить активные задачи: ${e.toString()}'));
    }
  }

  Future<void> searchTasks(String query) async {
    emit(TaskLoading());
    try {
      final userTasks = await _repository.getUserTasks(_userId);
      final filteredTasks = userTasks
          .where((task) => task.titleTask.toLowerCase().contains(query.toLowerCase()))
          .toList();
      emit(TasksLoaded(filteredTasks));
    } catch (e) {
      emit(TaskError('Не удалось найти задачи: ${e.toString()}'));
    }
  }

  Future<void> sortTasksByDate({bool ascending = true}) async {
    emit(TaskLoading());
    try {
      final userTasks = await _repository.getUserTasks(_userId);
      userTasks.sort((a, b) => ascending
          ? a.taskDay.compareTo(b.taskDay)
          : b.taskDay.compareTo(a.taskDay));
      emit(TasksLoaded(userTasks));
    } catch (e) {
      emit(TaskError('Не удалось отсортировать задачи: ${e.toString()}'));
    }
  }
}