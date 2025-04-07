import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list_app/data/models/task_model.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/task_cubit.dart';
import 'package:to_do_list_app/presentation/widgets/edit_task_bottom_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Task> _allTasks = [];

  @override
  void initState() {
    super.initState();
    context.read<TaskCubit>().loadUserTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    context.read<TaskCubit>().searchTasks(query);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<TaskCubit>().loadUserTasks();
        context.go('/home');
        return false;
      },
      child:
      Scaffold(
        appBar: AppBar(
          title: const Text('Поиск'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.read<TaskCubit>().loadUserTasks();
              context.go('/home');
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<TaskCubit, TaskState>(
                  builder: (context, state) {
                    if (state is TasksLoaded) {
                      _allTasks = state.tasks;
                      return _buildSearchContent(_allTasks);
                    } else if (state is TaskError) {
                      return Center(child: Text('Ошибка: ${state.message}'));
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildSearchContent(List<Task> tasks) {
    final plannedTasks = tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = tasks.where((task) => task.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ExpansionTile(
          title: Row(
            children: [
              Text(
                'ЗАПЛАНИРОВАННОЕ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                plannedTasks.length.toString(),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          backgroundColor: Colors.orange[100], 
          collapsedBackgroundColor: Colors.orange[100],
          children: plannedTasks.isEmpty
              ? [const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Нет запланированных задач'),
                )]
              : plannedTasks.map((task) => _buildTaskCard(task)).toList(),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: Row(
            children: [
              Text(
                'ВЫПОЛНЕННОЕ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                completedTasks.length.toString(),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          backgroundColor: Colors.grey[200], 
          collapsedBackgroundColor: Colors.grey[200],
          children: completedTasks.isEmpty
              ? [const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Нет выполненных задач'),
                )]
              : completedTasks.map((task) => _buildTaskCard(task)).toList(),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => EditTaskBottomSheet(task: task),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (v) => context.read<TaskCubit>().toggleTaskCompletion(task.id!, task),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.titleTask,
                      style: TextStyle(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    if (task.taskReminderTime != null)
                      _buildTimeRow(Icons.notifications, task.taskReminderTime!),
                    if (task.taskTime != null)
                      _buildTimeRow(Icons.access_time, task.taskTime!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(IconData icon, DateTime time) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}