import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class HeaderFooterTool implements PdfTool {
  @override
  String get id => 'header_footer';

  @override
  String get name => 'Header & Footer';

  @override
  String get description => 'Add headers and footers to a PDF';

  @override
  String get iconName => 'Icons.view_headline';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final String headerText = parameters['headerText'] as String? ?? '';
      final String footerText = parameters['footerText'] as String? ?? '';
      final String bodyText = parameters['bodyText'] as String? ?? '';
      final int pageCount = parameters['pageCount'] as int? ?? 1;

      final PdfDocument document = PdfDocument();

      if (headerText.isNotEmpty) {
        final PdfPageTemplateElement headerTemplate =
            PdfPageTemplateElement(const ui.Rect.fromLTWH(0, 0, 515, 50));
        headerTemplate.graphics.drawString(
          headerText,
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: const ui.Rect.fromLTWH(20, 15, 480, 20),
        );
        document.template.top = headerTemplate;
      }

      if (footerText.isNotEmpty) {
        final PdfPageTemplateElement footerTemplate =
            PdfPageTemplateElement(const ui.Rect.fromLTWH(0, 0, 515, 50));
        footerTemplate.graphics.drawString(
          footerText,
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: const ui.Rect.fromLTWH(20, 15, 480, 20),
        );
        document.template.bottom = footerTemplate;
      }

      for (int i = 0; i < pageCount; i++) {
        final PdfPage page = document.pages.add();
        if (i == 0 && bodyText.isNotEmpty) {
          PdfTextElement(
            text: bodyText,
            font: PdfStandardFont(PdfFontFamily.helvetica, 12),
          ).draw(
            page: page,
            bounds: ui.Rect.fromLTWH(
              40,
              80,
              page.getClientSize().width - 80,
              page.getClientSize().height - 160,
            ),
            format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
          );
        }
      }

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'pageCount': pageCount},
      );
    } catch (e) {
      return PdfToolResult.failure('Error adding headers/footers: $e');
    }
  }
}
