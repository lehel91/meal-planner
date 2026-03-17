import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/database.dart';

class PdfService {
  static Future<void> generateAndShare(
    List<DateTime> days,
    List<MealPlanWithRecipe> mealPlans,
  ) async {
    final planMap = {
      for (final mp in mealPlans)
        DateTime(mp.mealPlan.date.year, mp.mealPlan.date.month,
            mp.mealPlan.date.day): mp,
    };

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
          ...days.map((date) {
            final normalized = DateTime(date.year, date.month, date.day);
            return _buildDayEntry(date, planMap[normalized]);
          }),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'meal-plan-${DateFormat('yyyy-MM-dd').format(days.first)}.pdf',
    );
  }

  static pw.Widget _buildDayEntry(DateTime date, MealPlanWithRecipe? mp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Date column
          pw.SizedBox(
            width: 56,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  DateFormat('d').format(date),
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  DateFormat('MMM').format(date),
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700),
                ),
                pw.Text(
                  DateFormat('EEE').format(date),
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Recipe details
          pw.Expanded(
            child: mp == null
                ? pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
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
                            fontSize: 15, fontWeight: pw.FontWeight.bold),
                      ),
                      if (mp.recipe.description != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          mp.recipe.description!,
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey700),
                        ),
                      ],
                      if (mp.recipe.url != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          mp.recipe.url!,
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.blue),
                        ),
                      ],
                    ],
                  ),
          ),
          // QR code for recipes with a URL
          if (mp?.recipe.url != null) ...[
            pw.SizedBox(width: 12),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: mp!.recipe.url!,
              width: 72,
              height: 72,
            ),
          ],
        ],
      ),
    );
  }
}
