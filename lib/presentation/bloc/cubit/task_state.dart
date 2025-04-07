part of 'task_cubit.dart';

@immutable
sealed class TaskState {}

final class TaskInitial extends TaskState {}

final class TaskLoading extends TaskState {}

final class TasksLoaded extends TaskState {
  final List<Task> tasks;

  TasksLoaded(this.tasks);
}

final class TaskOperationSuccess extends TaskState {
  final String message;

  TaskOperationSuccess(this.message);
}

final class TaskError extends TaskState {
  final String message;

  TaskError(this.message);
}

final class TaskCompletionToggled extends TaskState {
  final String taskId;
  final bool isCompleted;

  TaskCompletionToggled(this.taskId, this.isCompleted);
}