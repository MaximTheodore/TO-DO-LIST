import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/auth_cubit.dart';
import 'package:to_do_list_app/core/theme/theme_provider.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/task_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _prefs.setBool('notificationsEnabled', value);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт'),
        content: const Text('Вы уверены, что хотите удалить свой аккаунт? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<AuthCubit>().deleteAccount(context);
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final user = context.read<AuthCubit>().currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите в аккаунт, чтобы сбросить пароль')),
      );
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email не найден. Пожалуйста, войдите снова.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить пароль'),
        content: Text('Отправить письмо для сброса пароля на $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<AuthCubit>().sendPasswordResetEmail(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is ResetPasswordSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Письмо для сброса пароля отправлено')),
          );
        } else if (state is Unauthenticated) {
          context.go('/home');
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          context.read<TaskCubit>().loadUserTasks();
          context.go('/home');
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<TaskCubit>().loadUserTasks();
                context.go('/home');
              },
            ),
            title: const Text('Настройки'),
          ),
          body: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final user = context.read<AuthCubit>().currentUser;
              final isAuthenticatedUser = user != null && !user.isAnonymous;

              return ListView(
                children: [
                  _buildListTile(
                    icon: Icons.notifications,
                    iconColor: Colors.orange,
                    title: 'Уведомления',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) => _toggleNotifications(value),
                    ),
                  ),
                  _buildListTile(
                    icon: Icons.brightness_6,
                    iconColor: Colors.purple,
                    title: 'Тема',
                    trailing: Switch(
                      value: context.watch<ThemeProvider>().isDarkMode,
                      onChanged: (value) {
                        context.read<ThemeProvider>().toggleTheme(value);
                      },
                    ),
                  ),
                  if (isAuthenticatedUser) 
                    _buildListTile(
                      icon: Icons.email,
                      iconColor: Colors.green,
                      title: 'Восстановить пароль',
                      onTap: () => _resetPassword(context),
                    ),
                  _buildListTile(
                    icon: Icons.delete_forever,
                    iconColor: Colors.red,
                    title: 'Удалить все данные',
                    onTap: () => _deleteAccount(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}