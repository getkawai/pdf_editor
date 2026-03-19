import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for converting text to PDF
class TextToPdfTool implements PdfTool {
  @override
  String get id => 'text_to_pdf';

  @override
  String get name => 'Text to PDF';

  @override
  String get description => 'Convert text content to PDF document';

  @override
  String get iconName => 'Icons.text_fields';

  @override
  Map<String, String> get parametersSchema => {
        'text': 'The main text content to convert to a PDF file',
        'title': 'An optional title for the PDF file',
      };

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final String text = parameters['text'] as String? ?? '';
      final String title = parameters['title'] as String? ?? '';
      final String fontFamily = parameters['fontFamily'] as String? ?? 'helvetica';
      final double fontSize = parameters['fontSize'] as double? ?? 12.0;

      if (text.isEmpty) {
        return PdfToolResult.failure('Text content is required');
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
        yOffset += 60;
      }

      // Add content text
      final PdfFont textFont = PdfStandardFont(
        _getFontFamily(fontFamily),
        fontSize,
      );
      
      // Draw text with pagination support
      PdfTextElement(
        text: text,
        font: textFont,
      ).draw(
        page: page,
        bounds: ui.Rect.fromLTWH(
          50,
          yOffset,
          page.getClientSize().width - 100,
          page.getClientSize().height - yOffset - 50,
        ),
        format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
      );

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': document.pages.count,
          'title': title,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating PDF: $e');
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
