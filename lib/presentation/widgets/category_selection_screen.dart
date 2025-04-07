import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_list_app/data/models/category_task_model.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/auth_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/category_task_cubit.dart';

class CategorySelectionScreen extends StatefulWidget {
  final List<String> selectedCategories;
  final Function(List<String>) onCategoriesSelected;

  const CategorySelectionScreen({
    super.key,
    required this.selectedCategories,
    required this.onCategoriesSelected,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Выбрать категорию',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: () {
                      widget.onCategoriesSelected(_selectedCategories);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<CategoryTaskCubit, CategoryTaskState>(
              builder: (context, state) {
                if (state is CategoryTaskLoaded) {
                  final categories = state.categories;
                  return Column(
                    children: [
                      ...categories.map((category) => CheckboxListTile(
                        value: _selectedCategories.contains(category.id),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedCategories.add(category.id ?? category.title);
                            } else {
                              _selectedCategories.remove(category.id ?? category.title);
                            }
                          });
                        },
                        title: Text(category.title),
                        secondary: category.imageUrl.isNotEmpty
                            ? CircleAvatar(
                                radius: 12,
                                backgroundImage: AssetImage(category.imageUrl),
                              )
                            : Icon(Icons.category, color: Color(category.color)),
                      )).toList(),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Добавить категорию'),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => AddCategoryScreen(
                              onCategoryAdded: (newCategory) {
                                context.read<CategoryTaskCubit>().addCategory(newCategory);
                                setState(() => _selectedCategories.add(newCategory.id ?? newCategory.title));
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }
}
class CategoryList extends StatefulWidget {
  final List<CategoryTask> categories;
  final List<String> selectedCategories;
  final Function(List<String>) onCategoriesSelected;

  const CategoryList({Key? key,
    required this.categories,
    required this.selectedCategories,
    required this.onCategoriesSelected,
  }) : super(key: key);

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  late List<String> selectedCategories;

  @override
  void initState() {
    super.initState();
    selectedCategories = List.from(widget.selectedCategories);
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (selectedCategories.contains(categoryId)) {
        selectedCategories.remove(categoryId);
      } else {
        selectedCategories.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded( 
            child: ListView(
              children: [
                ...widget.categories.map((category) =>
                    CheckboxListTile(
                      value: selectedCategories.contains(category.id),
                      onChanged: (v) => _toggleCategory(category.id!),
                      title: Text(category.title),
                      secondary: Icon(Icons.category, color: Color(category.color)),
                    )),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Добавить категорию'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddCategoryScreen(
                              onCategoryAdded: (newCategory) {
                                context.read<CategoryTaskCubit>().addCategory(
                                    newCategory);
                                Navigator.pop(context); 

                                Future.delayed(const Duration(milliseconds: 500),
                                        () {
                                      setState(() {
                                      });
                                    });
                              },
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              child: const Icon(Icons.check),
              onPressed: () {
                widget.onCategoriesSelected(selectedCategories);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddCategoryScreen extends StatefulWidget {
  final Function(CategoryTask) onCategoryAdded;

  const AddCategoryScreen({super.key, required this.onCategoryAdded});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _categoryNameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  String _selectedIcon = 'assets/icons/finance/ic_bank_card_bitcoin.png';
  String _iconType = 'finance';

  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.yellow,
    Colors.orange, Colors.purple, Colors.teal, Colors.brown,
  ];

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Добавить категорию',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: _saveCategory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Название категории', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _categoryNameController,
              decoration: const InputDecoration(hintText: 'Введите название'),
            ),
            const SizedBox(height: 20),
            const Text('Цвет', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _colors.map((color) => GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Иконка', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: getIcons(_iconType).map((iconPath) => GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconPath),
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: _selectedIcon == iconPath
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(iconPath),
                  ),
                )).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => setState(() => _iconType = 'finance'),
                  child: const Text('Финансы'),
                ),
                TextButton(
                  onPressed: () => setState(() => _iconType = 'food'),
                  child: const Text('Еда и напитки'),
                ),
                TextButton(
                  onPressed: () => setState(() => _iconType = 'payment'),
                  child: const Text('Покупки'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> getIcons(String type) {
    switch (type) {
      case 'finance':
        return [
          'assets/icons/finance/ic_bank_card_bitcoin.png',
          'assets/icons/finance/ic_bitcoin.png',
          'assets/icons/finance/ic_broker.png',
          'assets/icons/finance/ic_card_payment.png',
          'assets/icons/finance/ic_money_box.png',
          'assets/icons/finance/ic_pay_date.png',
          'assets/icons/finance/ic_safe.png',
          'assets/icons/finance/ic_stack_money.png',
        ];
      case 'food':
        return [
          'assets/icons/food/ic_chiken.png',
          'assets/icons/food/ic_cocktail.png',
          'assets/icons/food/ic_jun.png',
          'assets/icons/food/ic_milk.png',
          'assets/icons/food/ic_soft_drinks.png',
          'assets/icons/food/ic_sweets.png',
          'assets/icons/food/ic_takeout.png',
          'assets/icons/food/ic_wine_cheese.png',
        ];
      case 'payment':
        return [
          'assets/icons/payment/ic_basket_shop.png',
          'assets/icons/payment/ic_buy.png',
          'assets/icons/payment/ic_hanger.png',
          'assets/icons/payment/ic_shoes.png',
          'assets/icons/payment/ic_shopping_cart.png',
          'assets/icons/payment/ic_washing_machine.png',
          'assets/icons/payment/ic_woman_clothes.png',
          'assets/icons/payment/ic_wristwatch.png',
        ];
      default:
        return [];
    }
  }

  void _saveCategory() {
    if (_categoryNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название категории')),
      );
      return;
    }

    final newCategory = CategoryTask(
      title: _categoryNameController.text,
      color: _selectedColor.value,
      imageUrl: _selectedIcon,
      userId: context.read<AuthCubit>().currentUser?.uid,
    );
    widget.onCategoryAdded(newCategory);
    Navigator.pop(context);
  }
}