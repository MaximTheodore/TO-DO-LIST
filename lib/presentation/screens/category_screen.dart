import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list_app/data/models/category_task_model.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/category_task_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/task_cubit.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryTaskCubit>().loadCategories();
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
          title: const Text('Категории'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.read<TaskCubit>().loadUserTasks();
              context.go('/home');
            },
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<CategoryTaskCubit, CategoryTaskState>(
            builder: (context, state) {
              if (state is CategoryTaskLoaded) {
                final categories = state.categories;
                if (categories.isEmpty) {
                  return const Center(child: Text('Нет категорий'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(category);
                  },
                );
              } else if (state is CategoryTaskError) {
                return Center(child: Text('Ошибка: ${state.message}'));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/add-category', extra: (CategoryTask newCategory) {
              context.read<CategoryTaskCubit>().addCategory(newCategory);
            });
          },
          child: const Icon(Icons.add, color: Colors.white, size: 30),
          shape: const CircleBorder(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      )
    );
  }

  Widget _buildCategoryCard(CategoryTask category) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Color(category.color), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          category.imageUrl.isNotEmpty
              ? Image.asset(
                  category.imageUrl,
                  width: 24,
                  height: 24,
                  color: Color(category.color),
                )
              : Icon(Icons.category, color: Color(category.color)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteCategory(category),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(CategoryTask category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию'),
        content: Text('Вы уверены, что хотите удалить категорию "${category.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (category.id != null) {
                context.read<CategoryTaskCubit>().deleteCategory(category.id!);
              }
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}