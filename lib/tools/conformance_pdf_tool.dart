import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class ConformancePdfTool implements PdfTool {
  @override
  String get id => 'conformance_pdf';

  @override
  String get name => 'PDF/A Conformance';

  @override
  String get description => 'Create PDF/A-1B, PDF/A-2B, or PDF/A-3B documents';

  @override
  String get iconName => 'Icons.verified';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final String level = parameters['conformanceLevel'] as String? ?? 'a1b';
      final String text = parameters['text'] as String? ?? 'Conformance document';
      final double fontSize = parameters['fontSize'] as double? ?? 12.0;
      final Uint8List? fontData = parameters['fontData'] as Uint8List?;

      final PdfDocument document = PdfDocument(
        conformanceLevel: _parseLevel(level),
      );

      final PdfPage page = document.pages.add();
      final PdfFont font = fontData != null
          ? PdfTrueTypeFont(fontData, fontSize)
          : PdfStandardFont(PdfFontFamily.helvetica, fontSize);

      page.graphics.drawString(
        text,
        font,
        bounds: const ui.Rect.fromLTWH(20, 20, 400, 50),
        brush: PdfBrushes.black,
      );

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'conformanceLevel': level},
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating conformance PDF: $e');
    }
  }

  PdfConformanceLevel _parseLevel(String input) {
    switch (input.toLowerCase()) {
      case 'a2b':
        return PdfConformanceLevel.a2b;
      case 'a3b':
        return PdfConformanceLevel.a3b;
      case 'a1b':
      default:
        return PdfConformanceLevel.a1b;
    }
  }
}
