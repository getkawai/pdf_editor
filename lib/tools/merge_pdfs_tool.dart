import 'dart:typed_data';
import 'dart:ui' show Offset;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for merging multiple PDFs into one
class MergePdfsTool implements PdfTool {
  @override
  String get id => 'merge_pdfs';

  @override
  String get name => 'Merge PDFs';

  @override
  String get description => 'Merge multiple PDF documents into one';

  @override
  String get iconName => 'Icons.merge';

  @override
  Map<String, String> get parametersSchema => {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final List<Uint8List> pdfDataList =
          parameters['pdfDataList'] as List<Uint8List>? ?? [];

      if (pdfDataList.isEmpty) {
        return PdfToolResult.failure('At least one PDF document is required');
      }

      if (pdfDataList.length == 1) {
        return PdfToolResult.success(
          pdfData: pdfDataList[0],
          metadata: {'pageCount': _getPageCount(pdfDataList[0])},
        );
      }

      // Create a new PDF document
      final PdfDocument mergedDocument = PdfDocument();

      int totalPages = 0;

      // Iterate through each PDF and merge
      for (final pdfData in pdfDataList) {
        // Load the PDF document
        final PdfDocument document = PdfDocument(inputBytes: pdfData);

        // Copy all pages
        for (int i = 0; i < document.pages.count; i++) {
          final newPage = mergedDocument.pages.add();
          final template = document.pages[i].createTemplate();
          newPage.graphics.drawPdfTemplate(template, Offset.zero);
          totalPages++;
        }

        document.dispose();
      }

      // Save the merged document
      final List<int> bytes = await mergedDocument.save();
      mergedDocument.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': totalPages,
          'mergedDocuments': pdfDataList.length,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error merging PDFs: $e');
    }
  }

  int _getPageCount(Uint8List pdfData) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfData);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (e) {
      return 0;
    }
  }
}
