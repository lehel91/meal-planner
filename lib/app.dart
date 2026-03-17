import 'package:flutter/material.dart';

import 'data/database.dart';
import 'features/meal_plan/meal_plan_screen.dart';
import 'features/recipes/recipes_screen.dart';
import 'shared/theme.dart';

class App extends StatefulWidget {
  final AppDatabase db;

  const App({super.key, required this.db});

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
            RecipesScreen(db: widget.db),
            MealPlanScreen(db: widget.db),
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
          ],
        ),
      ),
    );
  }
}
