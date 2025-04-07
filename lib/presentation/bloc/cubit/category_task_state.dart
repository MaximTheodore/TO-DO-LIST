part of 'category_task_cubit.dart';

@immutable
sealed class CategoryTaskState {}

final class CategoryTaskInitial extends CategoryTaskState {}

final class CategoryTaskLoading extends CategoryTaskState {}

final class CategoryTaskLoaded extends CategoryTaskState {
  final List<CategoryTask> categories;

  CategoryTaskLoaded(this.categories);
}

final class CategoryTaskOperationSuccess extends CategoryTaskState {
  final String message;

  CategoryTaskOperationSuccess(this.message);
}

final class CategoryTaskError extends CategoryTaskState {
  final String message;

  CategoryTaskError(this.message);
}