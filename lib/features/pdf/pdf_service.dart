import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/database.dart';
import '../../data/measurement_unit.dart';

class _ShoppingItem {
  final String name;
  final double? quantity;
  final MeasurementUnit? unit;

  _ShoppingItem({required this.name, this.quantity, this.unit});
}

class PdfService {
  static Future<void> generateAndShare(
    List<DateTime> days,
    List<MealPlanWithRecipe> mealPlans,
    Map<int, List<RecipeIngredientWithDetails>> ingredientsByRecipe,
  ) async {
    final planMap = {
      for (final mp in mealPlans)
        DateTime(mp.mealPlan.date.year, mp.mealPlan.date.month,
            mp.mealPlan.date.day): mp,
    };

    final shoppingItems = _aggregateShoppingList(mealPlans, ingredientsByRecipe);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Meal Plan',
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${DateFormat('MMM d').format(days.first)} – ${DateFormat('MMM d, yyyy').format(days.last)}',
            style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 24),
          ..._buildDayGrid(days, planMap),
          if (shoppingItems.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 16),
            pw.Text(
              'Shopping List',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            ..._buildShoppingListRows(shoppingItems),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'meal-plan-${DateFormat('yyyy-MM-dd').format(days.first)}.pdf',
    );
  }

  // ── Shopping list ─────────────────────────────────────────────────────────

  static List<_ShoppingItem> _aggregateShoppingList(
    List<MealPlanWithRecipe> mealPlans,
    Map<int, List<RecipeIngredientWithDetails>> ingredientsByRecipe,
  ) {
    final aggregated = <String, _ShoppingItem>{};

    for (final mp in mealPlans) {
      final items = ingredientsByRecipe[mp.recipe.id] ?? [];
      for (final item in items) {
        final key = '${item.ingredient.name}__${item.unit?.name ?? 'none'}';
        final existing = aggregated[key];
        if (existing != null) {
          if (existing.quantity != null && item.quantity != null) {
            aggregated[key] = _ShoppingItem(
              name: existing.name,
              quantity: existing.quantity! + item.quantity!,
              unit: existing.unit,
            );
          }
        } else {
          aggregated[key] = _ShoppingItem(
            name: item.ingredient.name,
            quantity: item.quantity,
            unit: item.unit,
          );
        }
      }
    }

    return aggregated.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<pw.Widget> _buildShoppingListRows(List<_ShoppingItem> items) {
    final rows = <pw.Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _buildShoppingItem(items[i])),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: i + 1 < items.length
                ? _buildShoppingItem(items[i + 1])
                : pw.SizedBox(),
          ),
        ],
      ));
      rows.add(pw.SizedBox(height: 6));
    }
    return rows;
  }

  static pw.Widget _buildShoppingItem(_ShoppingItem item) {
    final qty = item.quantity != null
        ? (item.quantity! % 1 == 0
            ? item.quantity!.toInt().toString()
            : item.quantity!.toString())
        : '';
    final unit = item.unit?.abbreviation ?? '';
    final label = [qty, unit, item.name].where((s) => s.isNotEmpty).join(' ');

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  // ── Day grid ──────────────────────────────────────────────────────────────

  static List<pw.Widget> _buildDayGrid(
    List<DateTime> days,
    Map<DateTime, MealPlanWithRecipe> planMap,
  ) {
    final rows = <pw.Widget>[];
    for (int i = 0; i < days.length; i += 2) {
      final leftDate = days[i];
      final leftNorm = DateTime(leftDate.year, leftDate.month, leftDate.day);

      pw.Widget right;
      if (i + 1 < days.length) {
        final rightDate = days[i + 1];
        final rightNorm =
            DateTime(rightDate.year, rightDate.month, rightDate.day);
        right = _buildDayEntry(rightDate, planMap[rightNorm]);
      } else {
        right = pw.SizedBox();
      }

      rows.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _buildDayEntry(leftDate, planMap[leftNorm])),
          pw.SizedBox(width: 8),
          pw.Expanded(child: right),
        ],
      ));
      rows.add(pw.SizedBox(height: 8));
    }
    return rows;
  }

  static pw.Widget _buildDayEntry(DateTime date, MealPlanWithRecipe? mp) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 44,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  DateFormat('d').format(date),
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  DateFormat('MMM').format(date),
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700),
                ),
                pw.Text(
                  DateFormat('EEE').format(date),
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: mp == null
                ? pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 6),
                    child: pw.Text(
                      'No meal planned',
                      style: pw.TextStyle(
                        color: PdfColors.grey500,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  )
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        mp.recipe.name,
                        style: pw.TextStyle(
                            fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                      if (mp.recipe.description != null) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          mp.recipe.description!,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                      if (mp.recipe.url != null) ...[
                        pw.SizedBox(height: 6),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: mp.recipe.url!,
                          width: 52,
                          height: 52,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
