import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for annotating PDFs (add text, highlights, etc.)
class AnnotatePdfTool implements PdfTool {
  @override
  String get id => 'annotate_pdf';

  @override
  String get name => 'Annotate PDF';

  @override
  String get description => 'Add annotations, highlights, and comments to PDF';

  @override
  String get iconName => 'Icons.edit_note';

  @override
  Map<String, String> get parametersSchema => {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List pdfData =
          parameters['pdfData'] as Uint8List? ?? Uint8List(0);
      final List<Map<String, dynamic>>? annotations =
          parameters['annotations'] as List<Map<String, dynamic>>?;
      final int pageNumber = parameters['pageNumber'] as int? ?? 1;

      if (pdfData.isEmpty) {
        return PdfToolResult.failure('PDF data is required');
      }

      if (annotations == null || annotations.isEmpty) {
        return PdfToolResult.failure('At least one annotation is required');
      }

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfData);

      // Validate page number
      if (pageNumber < 1 || pageNumber > document.pages.count) {
        document.dispose();
        return PdfToolResult.failure('Invalid page number');
      }

      final PdfPage page = document.pages[pageNumber - 1];

      // Apply annotations
      for (final annotation in annotations) {
        final String type = annotation['type'] as String;

        switch (type) {
          case 'text':
            _addTextAnnotation(page, annotation);
            break;
          case 'highlight':
            _addHighlightAnnotation(page, annotation);
            break;
          case 'rectangle':
            _addRectangleAnnotation(page, annotation);
            break;
          case 'circle':
            _addCircleAnnotation(page, annotation);
            break;
        }
      }

      // Save the annotated document
      final List<int> bytes = await document.save();
      final int pageCount = document.pages.count;
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': pageCount,
          'annotationsCount': annotations.length,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error annotating PDF: $e');
    }
  }

  void _addTextAnnotation(PdfPage page, Map<String, dynamic> annotation) {
    final String? text = annotation['text'] as String?;
    final double x = (annotation['x'] as num?)?.toDouble() ?? 50.0;
    final double y = (annotation['y'] as num?)?.toDouble() ?? 50.0;
    final double fontSize =
        (annotation['fontSize'] as num?)?.toDouble() ?? 12.0;
    final String? colorHex = annotation['color'] as String?;

    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, fontSize);
    final PdfBrush brush = colorHex != null
        ? PdfSolidBrush(_hexToColor(colorHex))
        : PdfBrushes.black;

    page.graphics.drawString(
      text ?? '',
      font,
      brush: brush,
      bounds: ui.Rect.fromLTWH(x, y, 200, 50),
    );
  }

  void _addHighlightAnnotation(PdfPage page, Map<String, dynamic> annotation) {
    final double x = (annotation['x'] as num?)?.toDouble() ?? 0.0;
    final double y = (annotation['y'] as num?)?.toDouble() ?? 0.0;
    final double width = (annotation['width'] as num?)?.toDouble() ?? 100.0;
    final double height = (annotation['height'] as num?)?.toDouble() ?? 20.0;

    final PdfPen pen = PdfPen(PdfColor(255, 255, 0, 128));
    page.graphics.drawRectangle(
      pen: pen,
      bounds: ui.Rect.fromLTWH(x, y, width, height),
    );
  }

  void _addRectangleAnnotation(PdfPage page, Map<String, dynamic> annotation) {
    final double x = (annotation['x'] as num?)?.toDouble() ?? 0.0;
    final double y = (annotation['y'] as num?)?.toDouble() ?? 0.0;
    final double width = (annotation['width'] as num?)?.toDouble() ?? 100.0;
    final double height = (annotation['height'] as num?)?.toDouble() ?? 100.0;
    final String? colorHex = annotation['color'] as String?;

    final PdfPen pen = PdfPen(
      colorHex != null ? _hexToColor(colorHex) : PdfColor(0, 0, 255, 255),
      width: 2,
    );
    page.graphics.drawRectangle(
      pen: pen,
      bounds: ui.Rect.fromLTWH(x, y, width, height),
    );
  }

  void _addCircleAnnotation(PdfPage page, Map<String, dynamic> annotation) {
    final double x = (annotation['x'] as num?)?.toDouble() ?? 0.0;
    final double y = (annotation['y'] as num?)?.toDouble() ?? 0.0;
    final double width = (annotation['width'] as num?)?.toDouble() ?? 100.0;
    final double height = (annotation['height'] as num?)?.toDouble() ?? 100.0;
    final String? colorHex = annotation['color'] as String?;

    final PdfPen pen = PdfPen(
      colorHex != null ? _hexToColor(colorHex) : PdfColor(0, 255, 0, 255),
      width: 2,
    );
    // Use rectangle as approximation for circle (simpler and works reliably)
    page.graphics.drawRectangle(
      pen: pen,
      bounds: ui.Rect.fromLTWH(x, y, width, height),
    );
  }

  // Circle/ellipse path creation removed - use drawRectangle instead for simplicity

  PdfColor _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    final int value = int.parse(hex, radix: 16);
    return PdfColor(
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    );
  }
}
