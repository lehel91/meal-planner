import 'package:flutter/material.dart';

import 'data/app_repository.dart';
import 'features/meal_plan/meal_plan_screen.dart';
import 'features/recipes/recipes_screen.dart';
import 'features/shopping_list/shopping_list_screen.dart';
import 'shared/theme.dart';

class App extends StatefulWidget {
  final AppRepository repository;

  const App({super.key, required this.repository});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            RecipesScreen(repository: widget.repository),
            MealPlanScreen(repository: widget.repository),
            ShoppingListScreen(repository: widget.repository),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Recipes',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Meal Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Shopping',
            ),
          ],
        ),
      ),
    );
  }
}
