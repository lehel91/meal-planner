import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../pdf/pdf_service.dart';
import 'recipe_picker_sheet.dart';

class MealPlanScreen extends StatefulWidget {
  final AppDatabase db;

  const MealPlanScreen({super.key, required this.db});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  int _days = 7;

  DateTime get _start =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime get _end => _start.add(Duration(days: _days - 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          _DaysSelector(
            selected: _days,
            onChanged: (v) => setState(() => _days = v),
          ),
          Expanded(
            child: StreamBuilder<List<MealPlanWithRecipe>>(
              stream: widget.db.watchMealPlansForRange(_start, _end),
              builder: (context, snapshot) {
                final mealPlans = snapshot.data ?? [];
                final planMap = {
                  for (final mp in mealPlans)
                    DateTime(mp.mealPlan.date.year, mp.mealPlan.date.month,
                        mp.mealPlan.date.day): mp,
                };
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _days,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final date = _start.add(Duration(days: index));
                    final normalized =
                        DateTime(date.year, date.month, date.day);
                    final mp = planMap[normalized];
                    return _DayTile(
                      date: date,
                      mealPlan: mp,
                      onTap: () => _pickRecipe(date),
                      onRemove: mp != null
                          ? () => widget.db.removeMealPlan(mp.mealPlan.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRecipe(DateTime date) async {
    final recipe = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecipePickerSheet(db: widget.db),
    );
    if (recipe != null) {
      await widget.db.setMealPlan(date, recipe.id);
    }
  }

  Future<void> _exportPdf() async {
    final mealPlans =
        await widget.db.watchMealPlansForRange(_start, _end).first;
    if (mealPlans.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No meals planned yet')),
        );
      }
      return;
    }
    final days = List.generate(_days, (i) => _start.add(Duration(days: i)));
    await PdfService.generateAndShare(days, mealPlans);
  }
}

class _DaysSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DaysSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Plan for:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          ...[3, 5, 7, 14].map(
            (d) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$d days'),
                selected: selected == d,
                onSelected: (_) => onChanged(d),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final DateTime date;
  final MealPlanWithRecipe? mealPlan;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _DayTile({
    required this.date,
    required this.mealPlan,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Card(
      color: isToday ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('d').format(date),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              Text(
                DateFormat('MMM').format(date),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          mealPlan?.recipe.name ?? 'Tap to plan',
          style: TextStyle(
            fontWeight:
                mealPlan != null ? FontWeight.w600 : FontWeight.normal,
            color: mealPlan == null ? Colors.grey : null,
            fontStyle:
                mealPlan == null ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        subtitle: Text(
          DateFormat('EEEE').format(date),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mealPlan?.recipe.url != null)
              Icon(Icons.link,
                  size: 16, color: Theme.of(context).colorScheme.primary),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
