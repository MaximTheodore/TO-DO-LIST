import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/auth_cubit.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (!mounted) {
                return const SizedBox.shrink();
              }

              final user = context.read<AuthCubit>().currentUser;
              final isAuthenticated = user != null && !user.isAnonymous;

              if (isAuthenticated) {
                return Stack(
                  children: [
                    UserAccountsDrawerHeader(
                      currentAccountPicture: const CircleAvatar(
                        backgroundColor: Colors.white70,
                        backgroundImage: AssetImage('assets/icons/ic_user.png'),
                      ),
                      accountEmail: Text(
                        user.email ?? '',
                      ),
                      accountName: null,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Выход',
                        onPressed: () {
                          context.read<AuthCubit>().signOut(context);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/icons/ic_user.png'),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Гость',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          context.go('/auth');
                          Navigator.pop(context);
                        },
                        child: const Text('Регистрация'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Главный экран'),
            onTap: () {
              context.go('/home');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box_outlined),
            title: const Text('Выполненные задачи'),
            onTap: () {
              context.go('/completed_tasks');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              context.go('/settings');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}