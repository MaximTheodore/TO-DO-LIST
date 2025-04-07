import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list_app/data/models/category_task_model.dart';
import 'package:to_do_list_app/data/models/task_model.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/category_task_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/task_cubit.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list_app/presentation/widgets/edit_task_bottom_sheet.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TaskCubit>().loadCompletedTasks();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<TaskCubit>().loadUserTasks();
        context.go('/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Выполненные задачи'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.read<TaskCubit>().loadUserTasks();
              context.go('/home');
            },
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<TaskCubit, TaskState>(
            builder: (context, state) {
              if (state is TasksLoaded) {
                if (state.tasks.isEmpty) {
                  return const Center(child: Text('Нет выполненных задач'));
                }
                return _buildMainContent(state.tasks);
              } else if (state is TaskError) {
                return Center(child: Text('Ошибка: ${state.message}'));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Task>> groupedTasks = {};

    for (var task in tasks) {
      if (task.completedDay != null) {
        final taskDate = DateTime(
          task.completedDay!.year,
          task.completedDay!.month,
          task.completedDay!.day,
        );

        String dateKey;
        if (taskDate == today) {
          dateKey = 'СЕГОДНЯ';
        } else if (taskDate == yesterday) {
          dateKey = 'ВЧЕРА';
        } else {
          dateKey = DateFormat('dd.MM.yyyy').format(task.completedDay!);
        }

        if (!groupedTasks.containsKey(dateKey)) {
          groupedTasks[dateKey] = [];
        }
        groupedTasks[dateKey]!.add(task);
      }
    }

    final sortedDates = groupedTasks.keys.toList()
      ..sort((a, b) {
        if (a == 'СЕГОДНЯ') return -1;
        if (b == 'СЕГОДНЯ') return 1;
        if (a == 'ВЧЕРА') return -1;
        if (b == 'ВЧЕРА') return 1;
        return DateFormat('dd.MM.yyyy')
            .parse(b)
            .compareTo(DateFormat('dd.MM.yyyy').parse(a));
      });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final categoryTasks = groupedTasks[date]!;
        return ExpansionTile(
          initiallyExpanded: true,
          backgroundColor: _getDateColor(date).withOpacity(0.1),
          collapsedBackgroundColor: _getDateColor(date).withOpacity(0.05),
          title: _buildCategoryTitle(date, categoryTasks.length),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          textColor: _getDateColor(date),
          collapsedTextColor: Theme.of(context).textTheme.titleMedium?.color,
          iconColor: _getDateColor(date),
          collapsedIconColor: Theme.of(context).iconTheme.color,
          children: categoryTasks.map((task) => _buildTaskCard(task)).toList(),
        );
      },
    );
  }

  Widget _buildCategoryTitle(String title, int total) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text('$total', style: const TextStyle(color: Colors.grey)),
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
                    if (task.taskTime != null) _buildTimeRow(Icons.access_time, task.taskTime!),
                  ],
                ),
              ),
              if (task.taskCategories.isNotEmpty) _buildCategoryIcon(task.taskCategories.first),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String categoryId) {
    final categoryState = context.watch<CategoryTaskCubit>().state;
    if (categoryState is CategoryTaskLoaded) {
      final category = categoryState.categories.firstWhere(
        (cat) => cat.id == categoryId || cat.title == categoryId,
        orElse: () => CategoryTask(
          title: 'Неизвестно',
          imageUrl: 'assets/icons/ic_question.png',
          color: Colors.grey.value,
        ),
      );
      return Image.asset(
        category.imageUrl.isNotEmpty ? category.imageUrl : 'assets/icons/ic_question.png',
        width: 24,
        height: 24,
        color: Color(category.color),
      );
    }
    return const Icon(Icons.category, color: Colors.grey);
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

  Color _getDateColor(String date) {
    switch (date) {
      case 'СЕГОДНЯ':
        return Colors.teal;
      case 'ВЧЕРА':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
}