import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/database.dart';
import '../shopping_list/shopping_list_utils.dart';

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

    final shoppingItems = aggregateShoppingList(mealPlans, ingredientsByRecipe);

    // Load fonts with full Unicode / extended-Latin support (covers ő, ű, á, etc.)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
        italic: fontItalic,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(
          PdfPageFormat.a4.width,
          PdfPageFormat.a4.height,
          marginLeft: 32,
          marginRight: 32,
          marginTop: 32,
          marginBottom: 32,
        ),
        build: (context) => [
          pw.Text(
            'Fridgenda – Meal Plan',
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

  static List<pw.Widget> _buildShoppingListRows(List<ShoppingItem> items) {
    final rows = <pw.Widget>[];
    for (int i = 0; i < items.length; i += 3) {
      rows.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _buildShoppingItem(items[i])),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: i + 1 < items.length
                ? _buildShoppingItem(items[i + 1])
                : pw.SizedBox(),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: i + 2 < items.length
                ? _buildShoppingItem(items[i + 2])
                : pw.SizedBox(),
          ),
        ],
      ));
      rows.add(pw.SizedBox(height: 6));
    }
    return rows;
  }

  static pw.Widget _buildShoppingItem(ShoppingItem item) {
    final label = formatShoppingItemLabel(item);

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

    for (int i = 0; i < days.length; i += 3) {
      final children = <pw.Widget>[];

      for (int j = 0; j < 3; j++) {
        if (j > 0) children.add(pw.SizedBox(width: 6));

        final idx = i + j;
        if (idx < days.length) {
          final date = days[idx];
          final norm = DateTime(date.year, date.month, date.day);
          children.add(
            pw.Expanded(child: _buildDayEntry(date, planMap[norm])),
          );
        } else {
          // Empty placeholder to keep grid alignment
          children.add(pw.Expanded(child: pw.SizedBox()));
        }
      }

      rows.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ));
      rows.add(pw.SizedBox(height: 6));
    }

    return rows;
  }

  static pw.Widget _buildDayEntry(DateTime date, MealPlanWithRecipe? mp) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Left: date + recipe name
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      DateFormat('d').format(date),
                      style: pw.TextStyle(
                          fontSize: 15, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      '${DateFormat('MMM').format(date)}  ${DateFormat('EEE').format(date)}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                if (mp == null)
                  pw.Text(
                    'No meal planned',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  )
                else
                  pw.Text(
                    mp.recipe.name,
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
              ],
            ),
          ),
          // Right: QR code or fixed-size placeholder to keep uniform card height
          if (mp?.recipe.url != null)
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: mp!.recipe.url!,
              width: 40,
              height: 40,
            )
          else
            pw.SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}
