import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

class ReportPdfService {
  ReportPdfService._();

  static Future<void> exportToPdf({
    required String reportTitle,
    required List<String> columns,
    required List<List<String>> rows,
    required String appliedFilters,
    Map<String, dynamic>? summaryData,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final orange = PdfColor.fromHex('#FF8C00');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: orange, width: 2),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BOO PET CARE PLATFORM',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: orange,
                    ),
                  ),
                  pw.Text(
                    'Admin Analytics Report',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    reportTitle,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: $dateStr',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Boo Pet Care Platform  |  support@boo.co.ke  |  www.boo.co.ke  |  Nairobi, Kenya',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Text(
            reportTitle,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Filters applied: $appliedFilters',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          if (summaryData != null) ...[
            pw.Row(
              children: [
                ...summaryData.entries.take(4).map(
                      (e) => pw.Expanded(
                        child: pw.Container(
                          margin: const pw.EdgeInsets.all(4),
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: orange, width: 1.5),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(
                                '${e.value}',
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: orange,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                e.key,
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],
          pw.TableHelper.fromTextArray(
            headers: columns,
            data: rows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: orange),
            cellStyle: const pw.TextStyle(fontSize: 8),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: pw.TableBorder.all(
              color: PdfColors.grey200,
              width: 0.5,
            ),
          ),
          pw.SizedBox(height: 8),
          if (reportTitle.contains('Booking'))
            pw.Text(
              '* Revenue potential is indicative only. Boo does not process payments.',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey500,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          '${_fileName(reportTitle)}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf',
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: reportTitle,
      );
    }
  }

  static void exportToCsv({
    required String reportTitle,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    final csvData = [columns, ...rows];
    final csv = const ListToCsvConverter().convert(csvData);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        '${_fileName(reportTitle)}_${DateTime.now().millisecondsSinceEpoch}.csv',
      )
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static String _fileName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
