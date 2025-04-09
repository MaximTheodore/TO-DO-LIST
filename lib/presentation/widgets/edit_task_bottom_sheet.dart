import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list_app/core/services/firebase_api.dart';
import 'package:to_do_list_app/data/models/category_task_model.dart';
import 'package:to_do_list_app/data/models/task_model.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/category_task_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/task_cubit.dart';
import 'package:to_do_list_app/presentation/widgets/category_selection_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class EditTaskBottomSheet extends StatefulWidget {
  final Task task;

  const EditTaskBottomSheet({super.key, required this.task});

  @override
  State<EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends State<EditTaskBottomSheet> {
  late TextEditingController _taskTitleController;
  late TextEditingController _subtaskController;
  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  late TimeOfDay? _reminderTime;
  late List<String> _selectedCategories;
  late List<String> _subtasks;
  String? _titleError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _taskTitleController = TextEditingController(text: widget.task.titleTask);
    _subtaskController = TextEditingController();
    _selectedDate = widget.task.taskDay;
    _selectedTime = widget.task.taskTime != null ? TimeOfDay.fromDateTime(widget.task.taskTime!) : null;
    _reminderTime = widget.task.taskReminderTime != null ? TimeOfDay.fromDateTime(widget.task.taskReminderTime!) : null;
    _selectedCategories = List.from(widget.task.taskCategories);
    _subtasks = List.from(widget.task.subtasks);
    _requestExactAlarmPermission(); 
  }
  int _generateNotificationId() {
    final baseId = widget.task.id.hashCode.abs();
    return baseId % 2147483647;
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      print("Checking SCHEDULE_EXACT_ALARM permission status...");
      final status = await Permission.scheduleExactAlarm.status;
      print("Permission status: $status");
      if (status.isDenied) {
        print("Requesting SCHEDULE_EXACT_ALARM permission...");
        final result = await Permission.scheduleExactAlarm.request();
        print("Request result: $result");
        if (result.isPermanentlyDenied) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Требуется разрешение'),
                content: const Text('Пожалуйста, разрешите точные уведомления в настройках'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await openAppSettings();
                    },
                    child: const Text('Открыть настройки'),
                  ),
                ],
              ),
            );
          }
        } else if (result.isDenied) {
          print("User denied permission");
        }
      } else {
        print("Permission already granted");
      }
    } catch (e) {
      print('Ошибка при запросе разрешения: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при запросе разрешения: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deleteTask(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.check, color: Colors.white),
                        onPressed: () => _updateTask(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            TextField(
              controller: _taskTitleController,
              decoration: InputDecoration(
                labelText: 'Название задачи',
                errorText: _titleError,
              ),
              onChanged: (value) {
                setState(() {
                  _titleError = value.isEmpty ? 'Введите название задачи' : null;
                });
              },
            ),
            _buildCategorySelector(context),
            _buildSubtaskField(),
            if (_subtasks.isNotEmpty) _buildSubtasksList(),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Дата выполнения'),
              trailing: Text(
                _selectedDate != null
                    ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                    : 'Не выбрано',
                style: const TextStyle(color: Colors.grey),
              ),
              subtitle: _dateError != null
                  ? Text(_dateError!, style: const TextStyle(color: Colors.red))
                  : null,
              onTap: () => _selectDate(context),
            ),
            _buildTimeSelector(
              context,
              'Время выполнения',
              Icons.access_time,
              _selectedTime,
              () => _selectTime(context, isReminder: false),
            ),
            _buildTimeSelector(
              context,
              'Напоминание',
              Icons.notifications,
              _reminderTime,
              () => _selectTime(context, isReminder: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final state = context.read<CategoryTaskCubit>().state;
    List<CategoryTask> categories = [];
    if (state is CategoryTaskLoaded) {
      categories = state.categories;
    }

    final existingCategoryIds = categories.map((c) => c.id).toSet();
    final filteredSelectedCategories = _selectedCategories
        .where((catId) => existingCategoryIds.contains(catId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('Выбрать категорию'),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => CategorySelectionScreen(
                selectedCategories: _selectedCategories,
                onCategoriesSelected: (categories) {
                  setState(() {
                    _selectedCategories = categories;
                  });
                },
              ),
            );
          },
        ),
        if (filteredSelectedCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: filteredSelectedCategories.map((catId) {
                final category = categories.firstWhere((c) => c.id == catId);
                return Chip(
                  label: Text(category.title),
                  avatar: category.imageUrl.isNotEmpty
                      ? Image.asset(category.imageUrl,
                          width: 32, height: 32, color: Color(category.color))
                      : null,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtaskField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _subtaskController,
              decoration: const InputDecoration(labelText: 'Добавить под задачу'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              if (_subtaskController.text.isNotEmpty) {
                setState(() {
                  _subtasks.add(_subtaskController.text);
                  _subtaskController.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksList() {
    return Column(
      children: _subtasks.map((subtask) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(subtask)),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                setState(() => _subtasks.remove(subtask));
              },
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildDateTimeSelector(
    BuildContext context,
    String label,
    IconData icon,
    DateTime? value,
    VoidCallback onPressed,
  ) {
    String displayText = value != null ? DateFormat('dd.MM.yyyy').format(value) : 'Не выбрано';
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(displayText, style: const TextStyle(color: Colors.grey)),
      onTap: onPressed,
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    IconData icon,
    TimeOfDay? value,
    VoidCallback onPressed,
  ) {
    String displayText = value != null
        ? '${value.hour}:${value.minute.toString().padLeft(2, '0')}'
        : 'Не выбрано';
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(displayText, style: const TextStyle(color: Colors.grey)),
      onTap: onPressed,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context, {required bool isReminder}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isReminder ? _reminderTime = picked : _selectedTime = picked);
    }
  }


  void _updateTask(BuildContext context) {
    setState(() {
      _titleError = _taskTitleController.text.isEmpty ? 'Введите название задачи' : null;
      _dateError = _selectedDate == null ? 'Выберите дату выполнения' : null;
    });

    if (_titleError != null || _dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните обязательные поля')),
      );
      return;
    }

    final taskDate = _selectedDate!;
    final taskTime = _selectedTime != null
        ? DateTime(taskDate.year, taskDate.month, taskDate.day, _selectedTime!.hour, _selectedTime!.minute)
        : widget.task.taskTime;
    final reminderTime = _reminderTime != null
        ? DateTime(taskDate.year, taskDate.month, taskDate.day, _reminderTime!.hour, _reminderTime!.minute)
        : widget.task.taskReminderTime;

    final updatedTask = widget.task.copyWith(
      titleTask: _taskTitleController.text,
      taskDay: taskDate,
      taskTime: taskTime,
      taskReminderTime: reminderTime,
      taskCategories: _selectedCategories,
      subtasks: _subtasks,
    );

    final firebaseApi = FirebaseApi();
    final taskId = _generateNotificationId();
    
    firebaseApi.cancelNotification(taskId);
    
    context.read<TaskCubit>().updateTask(widget.task.id!, updatedTask).then((_) {
      if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
        firebaseApi.scheduleNotification(
          id: taskId,
          title: 'Напоминание: ${updatedTask.titleTask}',
          body: 'Время выполнить задачу!',
          scheduledTime: reminderTime,
        ).catchError((error) {
          print('Ошибка при планировании уведомления: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка уведомления: $error')),
            );
          }
        });
      }
    }).catchError((error) {
      print('Ошибка при обновлении задачи: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении задачи: $error')),
        );  
      }
    }).whenComplete(() {
      if (mounted) Navigator.pop(context);
    });
  }

  void _deleteTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу'),
        content: const Text('Вы уверены, что хотите удалить эту задачу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final firebaseApi = FirebaseApi();
              final taskId = _generateNotificationId();
              firebaseApi.cancelNotification(taskId);
              context.read<TaskCubit>().deleteTask(widget.task.id!);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}