import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for converting table data to PDF with various styles
class TableToPdfTool implements PdfTool {
  @override
  String get id => 'table_to_pdf';

  @override
  String get name => 'Table to PDF';

  @override
  String get description => 'Generate PDF tables with different styles and formats';

  @override
  String get iconName => 'Icons.table_chart';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final List<List<dynamic>> data = parameters['data'] as List<List<dynamic>>? ?? [];
      final List<String>? headers = parameters['headers'] as List<String>?;
      final String title = parameters['title'] as String? ?? '';
      final String? fontFamily = parameters['fontFamily'] as String?;

      if (data.isEmpty) {
        return PdfToolResult.failure('Table data is required');
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      double yOffset = 50;

      // Add title if provided
      if (title.isNotEmpty) {
        final PdfFont titleFont = PdfStandardFont(
          _getFontFamily(fontFamily),
          24,
          style: PdfFontStyle.bold,
        );
        graphics.drawString(
          title,
          titleFont,
          bounds: ui.Rect.fromLTWH(50, yOffset, page.graphics.clientSize.width - 100, 50),
        );
        yOffset += 40;
      }

      // Create PDF grid
      final PdfGrid grid = PdfGrid();

      // Add columns
      final int columnCount = headers?.length ?? (data.isNotEmpty ? data[0].length : 0);
      for (int i = 0; i < columnCount; i++) {
        grid.columns.add();
      }

      // Add headers if provided
      if (headers != null && headers.isNotEmpty) {
        final PdfGridRow headerRow = grid.headers.add(1)[0];
        for (int i = 0; i < headers.length; i++) {
          headerRow.cells[i].value = headers[i];
        }
        // Style header row
        headerRow.style.backgroundBrush = PdfSolidBrush(PdfColor(68, 114, 196));
        headerRow.style.textBrush = PdfBrushes.white;
        headerRow.style.font = PdfStandardFont(_getFontFamily(fontFamily), 12, style: PdfFontStyle.bold);
      }

      // Add data rows
      for (final row in data) {
        final PdfGridRow gridRow = grid.rows.add();
        for (int i = 0; i < row.length; i++) {
          gridRow.cells[i].value = row[i].toString();
        }
      }

      // Apply manual styling
      // Apply alternating row colors
      for (int i = 0; i < grid.rows.count; i++) {
        final PdfGridRow row = grid.rows[i];
        if (i % 2 == 1) {
          row.style.backgroundBrush = PdfSolidBrush(PdfColor(240, 240, 240));
        }
        for (int j = 0; j < row.cells.count; j++) {
          row.cells[j].style.cellPadding = PdfPaddings(bottom: 5, left: 5, right: 5, top: 5);
          row.cells[j].stringFormat.alignment = PdfTextAlignment.center;
        }
      }

      // Draw the grid
      grid.draw(
        page: page,
        bounds: ui.Rect.fromLTWH(50, yOffset, page.getClientSize().width - 100, 0),
      );

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': 1,
          'rowCount': data.length,
          'columnCount': columnCount,
          'title': title,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating PDF table: $e');
    }
  }

  PdfFontFamily _getFontFamily(String? fontFamily) {
    switch (fontFamily?.toLowerCase()) {
      case 'times':
        return PdfFontFamily.timesRoman;
      case 'courier':
        return PdfFontFamily.courier;
      case 'helvetica':
      default:
        return PdfFontFamily.helvetica;
    }
  }
}
