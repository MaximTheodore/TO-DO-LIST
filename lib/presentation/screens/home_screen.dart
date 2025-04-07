import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list_app/presentation/widgets/drawer.dart';
import 'package:to_do_list_app/data/models/task_model.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/auth_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/category_task_cubit.dart';
import 'package:to_do_list_app/presentation/widgets/add_task_bottom_sheet.dart';
import 'package:to_do_list_app/presentation/widgets/edit_task_bottom_sheet.dart';
import '../../data/models/category_task_model.dart';
import '../bloc/cubit/task_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> categories = [
    'ПРОПУЩЕННЫЕ',
    'СЕГОДНЯ',
    'ЗАВТРА',
    'НА НЕДЕЛЕ',
    'В ЭТОМ МЕСЯЦЕ',
    'ПОТОМ'
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.read<TaskCubit>().updateUserId(state.user.uid);
          context.read<TaskCubit>().loadUserTasks();
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Список дел'),
        ),
        drawer: const MainDrawer(),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRowButton(icon: Icons.list, title: 'Категории', link: '/cattasks'),
                  _buildRowButton(icon: Icons.search, title: 'Поиск', link: '/search'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Для добавления задачи\nнажмите на "+" внизу\nэкрана',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                  ),
                  Image.asset('assets/icons/ic_arrow_down.png', width: 50),
                ],
              ),
              Expanded(
                child: BlocBuilder<TaskCubit, TaskState>(
                  builder: (context, state) {
                    if (state is TasksLoaded) {
                      return _buildMainContent(state.tasks);
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => const AddTaskBottomSheet(),
            );
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 50),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildRowButton({required IconData icon, required String title, required String link}) {
    return Expanded(
      child: InkWell(
        onTap: () => context.go(link),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(width: 5),
              Text(title, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Task> tasks) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final categoryTasks = _getFilteredTasks(tasks, categories[index]);
        final completed = categoryTasks.where((t) => t.isCompleted).length;
        return ExpansionTile(
          backgroundColor: _getCategoryColor(categories[index]).withOpacity(0.1),
          collapsedBackgroundColor: _getCategoryColor(categories[index]).withOpacity(0.05),
          title: _buildCategoryTitle(categories[index], categoryTasks.length, completed),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          textColor: _getCategoryColor(categories[index]),
          collapsedTextColor: Theme.of(context).textTheme.titleMedium?.color,
          iconColor: _getCategoryColor(categories[index]),
          collapsedIconColor: Theme.of(context).iconTheme.color,
          children: categoryTasks.map((task) => _buildTaskCard(task)).toList(),
        );
      },
    );
  }

  Widget _buildCategoryTitle(String title, int total, [int completed = 0]) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text(
          title == 'СЕГОДНЯ' ? '$completed/$total' : '$total',
          style: const TextStyle(color: Colors.grey),
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
                    if (task.taskReminderTime != null) _buildTimeRow(Icons.notifications, task.taskReminderTime!),
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

  List<Task> _getFilteredTasks(List<Task> tasks, String category) {
    final now = DateTime.now();
    switch (category) {
      case 'ПРОПУЩЕННЫЕ':
        return tasks.where((t) => t.taskDay.isBefore(now) && !t.isCompleted).toList();
      case 'СЕГОДНЯ':
        return tasks.where((t) => _isSameDay(t.taskDay, now)).toList();
      case 'ЗАВТРА':
        return tasks.where((t) => _isSameDay(t.taskDay, now.add(const Duration(days: 1)))).toList();
      case 'НА НЕДЕЛЕ':
        return tasks.where((t) => t.taskDay.isAfter(now) && t.taskDay.difference(now).inDays <= 7).toList();
      case 'В ЭТОМ МЕСЯЦЕ':
        return tasks.where((t) => t.taskDay.month == now.month && t.taskDay.year == now.year).toList();
      case 'ПОТОМ':
        return tasks.where((t) => t.taskDay.difference(now).inDays > 31).toList();
      default:
        return [];
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'ПРОПУЩЕННЫЕ':
        return Colors.red;
      case 'СЕГОДНЯ':
        return Colors.green;
      case 'ЗАВТРА':
        return Colors.orange;
      case 'НА НЕДЕЛЕ':
        return Colors.blue;
      case 'В ЭТОМ МЕСЯЦЕ':
        return Colors.purple;
      case 'ПОТОМ':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}