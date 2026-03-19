import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class ShapesPdfTool implements PdfTool {
  @override
  String get id => 'shapes_pdf';

  @override
  String get name => 'Shapes';

  @override
  String get description => 'Draw basic shapes on a PDF page';

  @override
  String get iconName => 'Icons.crop_square';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final String shapeType = (parameters['shapeType'] as String? ?? 'all').toLowerCase();

      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      final PdfPen pen = PdfPen(PdfColor(40, 70, 140), width: 2);
      final PdfBrush brush = PdfSolidBrush(PdfColor(180, 200, 235));

      if (shapeType == 'rectangle' || shapeType == 'all') {
        graphics.drawRectangle(
          pen: pen,
          brush: brush,
          bounds: const ui.Rect.fromLTWH(40, 40, 160, 100),
        );
      }

      if (shapeType == 'ellipse' || shapeType == 'all') {
        graphics.drawEllipse(
          const ui.Rect.fromLTWH(240, 40, 160, 100),
          pen: pen,
          brush: PdfSolidBrush(PdfColor(255, 220, 180)),
        );
      }

      if (shapeType == 'line' || shapeType == 'all') {
        graphics.drawLine(
          PdfPen(PdfColor(200, 80, 80), width: 3),
          const ui.Offset(40, 180),
          const ui.Offset(400, 180),
        );
      }

      if (shapeType == 'polygon' || shapeType == 'all') {
        graphics.drawPolygon(
          <ui.Offset>[
            const ui.Offset(60, 230),
            const ui.Offset(140, 210),
            const ui.Offset(220, 250),
            const ui.Offset(180, 320),
            const ui.Offset(90, 310),
          ],
          pen: PdfPen(PdfColor(80, 120, 80), width: 2),
          brush: PdfSolidBrush(PdfColor(180, 230, 180)),
        );
      }

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'shapeType': shapeType},
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating shapes PDF: $e');
    }
  }
}
