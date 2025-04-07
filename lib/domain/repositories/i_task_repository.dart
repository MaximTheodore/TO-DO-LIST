import 'package:to_do_list_app/data/models/task_model.dart';
import 'package:to_do_list_app/domain/repositories/i_repository.dart';

abstract class ITaskRepository extends IRepository<Task> {
  Future<List<Task>> getUserTasks(String userId);
}