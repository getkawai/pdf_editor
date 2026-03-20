import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class TablePdfTool implements PdfTool {
  @override
  String get id => 'table_pdf';

  @override
  String get name => 'Table PDF';

  @override
  String get description => 'Generate a table from CSV-like input';

  @override
  String get iconName => 'Icons.table_chart';

  @override
  Map<String, String> get parametersSchema => {
        'tableData': 'CSV-like text with rows separated by newlines',
        'hasHeader': 'Whether the first row is a header row',
      };

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final String rawTable = parameters['tableData'] as String? ?? '';
      final bool hasHeader = parameters['hasHeader'] as bool? ?? true;

      final List<List<String>> rows = _parseCsv(rawTable);
      if (rows.isEmpty) {
        return PdfToolResult.failure('Table data is required');
      }

      final int columnCount = rows.map((row) => row.length).fold<int>(0, (a, b) => a > b ? a : b);
      if (columnCount == 0) {
        return PdfToolResult.failure('Table must have at least one column');
      }

      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();

      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: columnCount);

      int startRowIndex = 0;
      if (hasHeader) {
        final PdfGridRow headerRow = grid.headers.add(1)[0];
        for (int i = 0; i < columnCount; i++) {
          headerRow.cells[i].value = i < rows[0].length ? rows[0][i] : '';
        }
        headerRow.style.font = PdfStandardFont(
          PdfFontFamily.helvetica,
          10,
          style: PdfFontStyle.bold,
        );
        startRowIndex = 1;
      }

      for (int i = startRowIndex; i < rows.length; i++) {
        final PdfGridRow row = grid.rows.add();
        for (int j = 0; j < columnCount; j++) {
          row.cells[j].value = j < rows[i].length ? rows[i][j] : '';
        }
      }

      grid.style.cellPadding = PdfPaddings(left: 5, top: 5, right: 5, bottom: 5);

      grid.draw(
        page: page,
        bounds: ui.Rect.fromLTWH(
          20,
          20,
          page.getClientSize().width - 40,
          page.getClientSize().height - 40,
        ),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'rowCount': rows.length, 'columnCount': columnCount},
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating table PDF: $e');
    }
  }

  List<List<String>> _parseCsv(String input) {
    final List<String> lines = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return lines.map((line) {
      return line.split(',').map((cell) => cell.trim()).toList();
    }).toList();
  }
}
