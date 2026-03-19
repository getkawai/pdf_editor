import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class RtlTextTool implements PdfTool {
  @override
  String get id => 'rtl_text';

  @override
  String get name => 'RTL / Unicode Text';

  @override
  String get description => 'Render Unicode text with optional RTL layout';

  @override
  String get iconName => 'Icons.format_textdirection_r_to_l';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final String text = parameters['text'] as String? ?? '';
      final String title = parameters['title'] as String? ?? '';
      final bool isRtl = parameters['isRtl'] as bool? ?? true;
      final double fontSize = parameters['fontSize'] as double? ?? 14.0;
      final Uint8List? fontData = parameters['fontData'] as Uint8List?;

      if (text.isEmpty) {
        return PdfToolResult.failure('Text content is required');
      }

      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      double yOffset = 40;

      if (title.isNotEmpty) {
        graphics.drawString(
          title,
          PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
          bounds: ui.Rect.fromLTWH(40, yOffset, page.getClientSize().width - 80, 30),
        );
        yOffset += 40;
      }

      final PdfFont font = fontData != null
          ? PdfTrueTypeFont(fontData, fontSize)
          : PdfStandardFont(PdfFontFamily.helvetica, fontSize);

      final PdfStringFormat format = PdfStringFormat(
        alignment: isRtl ? PdfTextAlignment.right : PdfTextAlignment.left,
        textDirection:
            isRtl ? PdfTextDirection.rightToLeft : PdfTextDirection.leftToRight,
      );

      graphics.drawString(
        text,
        font,
        bounds: ui.Rect.fromLTWH(
          40,
          yOffset,
          page.getClientSize().width - 80,
          page.getClientSize().height - yOffset - 40,
        ),
        format: format,
      );

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'rtl': isRtl},
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating RTL text PDF: $e');
    }
  }
}
