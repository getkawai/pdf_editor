import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class HyperlinkPdfTool implements PdfTool {
  @override
  String get id => 'hyperlink_pdf';

  @override
  String get name => 'Hyperlink';

  @override
  String get description => 'Insert a hyperlink in a PDF document';

  @override
  String get iconName => 'Icons.link';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final String url = parameters['url'] as String? ?? '';
      final String text = parameters['text'] as String? ?? url;

      if (url.isEmpty) {
        return PdfToolResult.failure('URL is required');
      }

      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();

      final PdfTextWebLink link = PdfTextWebLink(
        url: url,
        text: text,
        font: PdfStandardFont(PdfFontFamily.helvetica, 14),
        brush: PdfSolidBrush(PdfColor(0, 0, 200)),
        pen: PdfPen(PdfColor(0, 0, 200)),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.left,
          lineAlignment: PdfVerticalAlignment.top,
        ),
      );

      link.draw(page, const ui.Offset(40, 60));

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'url': url},
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating hyperlink PDF: $e');
    }
  }
}
