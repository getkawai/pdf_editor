import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for converting images to PDF
class ImageToPdfTool implements PdfTool {
  @override
  String get id => 'image_to_pdf';

  @override
  String get name => 'Image to PDF';

  @override
  String get description => 'Convert images to PDF document';

  @override
  String get iconName => 'Icons.image';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List imageData = parameters['imageData'] as Uint8List? ?? Uint8List(0);
      final String title = parameters['title'] as String? ?? '';
      final String fitMode = parameters['fitMode'] as String? ?? 'fit';

      if (imageData.isEmpty) {
        return PdfToolResult.failure('Image data is required');
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      double yOffset = 50;

      // Add title if provided
      if (title.isNotEmpty) {
        final PdfFont titleFont = PdfStandardFont(
          PdfFontFamily.helvetica,
          24,
          style: PdfFontStyle.bold,
        );
        graphics.drawString(
          title,
          titleFont,
          bounds: ui.Rect.fromLTWH(50, yOffset, page.graphics.clientSize.width - 100, 50),
        );
        yOffset += 20;
      }

      // Load the image
      final PdfImage pdfImage = PdfBitmap(imageData);

      // Calculate image dimensions based on fit mode
      double imageWidth;
      double imageHeight;
      final double availableWidth = page.getClientSize().width - 100;
      final double availableHeight = page.getClientSize().height - yOffset - 50;

      switch (fitMode) {
        case 'fit':
          final double widthRatio = availableWidth / pdfImage.width;
          final double heightRatio = availableHeight / pdfImage.height;
          final double scale = widthRatio < heightRatio ? widthRatio : heightRatio;
          imageWidth = pdfImage.width * scale;
          imageHeight = pdfImage.height * scale;
          break;
        case 'fill':
          final double widthRatio = availableWidth / pdfImage.width;
          final double heightRatio = availableHeight / pdfImage.height;
          final double scale = widthRatio > heightRatio ? widthRatio : heightRatio;
          imageWidth = pdfImage.width * scale;
          imageHeight = pdfImage.height * scale;
          break;
        case 'stretch':
        default:
          imageWidth = availableWidth;
          imageHeight = availableHeight;
          break;
      }

      // Draw the image
      graphics.drawImage(
        pdfImage,
        ui.Rect.fromLTWH(
          50 + (availableWidth - imageWidth) / 2,
          yOffset + (availableHeight - imageHeight) / 2,
          imageWidth,
          imageHeight,
        ),
      );

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': 1,
          'title': title,
          'imageWidth': pdfImage.width,
          'imageHeight': pdfImage.height,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating PDF from image: $e');
    }
  }
}
