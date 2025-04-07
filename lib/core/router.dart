import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list_app/data/models/category_task_model.dart';
import 'package:to_do_list_app/presentation/screens/auth_screen.dart';
import 'package:to_do_list_app/presentation/screens/category_screen.dart';
import 'package:to_do_list_app/presentation/screens/completed_tasks_screen.dart';
import 'package:to_do_list_app/presentation/screens/home_screen.dart';
import 'package:to_do_list_app/presentation/screens/search_screen.dart';
import 'package:to_do_list_app/presentation/screens/settings_screen.dart';
import 'package:to_do_list_app/presentation/widgets/category_selection_screen.dart';
import 'package:animations/animations.dart';

final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0); 
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: Curves.easeInOut)),
          );
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: Curves.easeInOut)),
          );
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: Curves.easeInOut)),
          );
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/cattasks',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CategoryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: Curves.easeInOut)),
          );
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: Curves.easeInOut)),
          );
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/completed_tasks',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CompletedTasksScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: Curves.easeInOut)),
          );
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/categories',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: CategorySelectionScreen(
          selectedCategories: state.extra as List<String>? ?? [],
          onCategoriesSelected: (categories) {
            Navigator.pop(context, categories);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: Curves.easeInOut)),
          );
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/add-category',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: AddCategoryScreen(
          onCategoryAdded: state.extra as Function(CategoryTask),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(
            tween.chain(CurveTween(curve: Curves.easeInOut)),
          );
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
  ],
);