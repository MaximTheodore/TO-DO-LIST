import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:to_do_list_app/core/services/firebase_api.dart';
import 'package:to_do_list_app/core/router.dart';
import 'package:to_do_list_app/data/repositories/category_task_repository_impl.dart';
import 'package:to_do_list_app/data/repositories/task_repository_impl.dart';
import 'package:to_do_list_app/firebase_options.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/auth_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/category_task_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/task_cubit.dart';
import 'package:to_do_list_app/core/theme/theme.dart';
import 'package:to_do_list_app/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();


  runApp(    
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(FirebaseAuth.instance),
        ),
        BlocProvider<TaskCubit>(
          create: (context) {
            final authCubit = context.read<AuthCubit>();
            final userId = authCubit.currentUser?.uid ?? 'guest';
            return TaskCubit(TaskRepositoryImpl(FirebaseFirestore.instance), userId);
          },
        ),
        BlocProvider<CategoryTaskCubit>(
          create: (_) => CategoryTaskCubit(CategoryTaskRepositoryImpl(firestore)),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'To-Do List App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
    );
  }
}