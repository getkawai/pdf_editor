import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for performing OCR on images and creating searchable PDFs
class OcropdfTool implements PdfTool {
  @override
  String get id => 'ocr_pdf';

  @override
  String get name => 'OCR PDF';

  @override
  String get description =>
      'Extract text from images and create searchable PDF';

  @override
  String get iconName => 'Icons.text_fields';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List imageData =
          parameters['imageData'] as Uint8List? ?? Uint8List(0);
      final String title = parameters['title'] as String? ?? 'OCR Document';
      final String languageCode = parameters['language'] as String? ?? 'en';

      if (imageData.isEmpty) {
        return PdfToolResult.failure('Image data is required');
      }

      // Map language code to TextRecognitionScript
      final TextRecognitionScript script = _getScriptFromLanguageCode(
        languageCode,
      );

      // Initialize text recognizer
      final textRecognizer = TextRecognizer(script: script);

      // Convert Uint8List to image package Image
      final img.Image? image = img.decodeImage(imageData);
      if (image == null) {
        await textRecognizer.close();
        return PdfToolResult.failure('Failed to decode image');
      }

      // Convert to grayscale for better OCR results
      final img.Image grayImage = img.grayscale(image);

      // Convert back to Uint8List for text recognition
      final Uint8List grayBytes = Uint8List.fromList(img.encodePng(grayImage));

      // Create input image for ML Kit
      final InputImage inputImage = InputImage.fromBytes(
        bytes: grayBytes,
        metadata: InputImageMetadata(
          size: ui.Size(
            grayImage.width.toDouble(),
            grayImage.height.toDouble(),
          ),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: 0,
        ),
      );

      // Recognize text
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      // Close the recognizer
      await textRecognizer.close();

      // Extract text
      final String extractedText = recognizedText.text;

      // Create PDF with text layer
      final PdfDocument document = PdfDocument();
      PdfPage page = document.pages.add();
      PdfGraphics graphics = page.graphics;

      // Add title
      double yOffset = 50;
      if (title.isNotEmpty) {
        final PdfFont titleFont = PdfStandardFont(
          PdfFontFamily.helvetica,
          24,
          style: PdfFontStyle.bold,
        );
        graphics.drawString(
          title,
          titleFont,
          bounds: ui.Rect.fromLTWH(
            50,
            yOffset,
            page.getClientSize().width - 100,
            50,
          ),
        );
        yOffset += 30;
      }

      // Add extracted text
      if (extractedText.isNotEmpty) {
        final PdfFont textFont = PdfStandardFont(PdfFontFamily.timesRoman, 12);
        final ui.Size textSize = textFont.measureString(extractedText);
        final double lineHeight = textSize.height;
        final double availableWidth = page.getClientSize().width - 100;

        // Simple text wrapping
        final List<String> lines = _wrapText(
          extractedText,
          textFont,
          availableWidth,
        );

        for (String line in lines) {
          // Check if we need a new page
          if (yOffset + lineHeight > page.getClientSize().height - 50) {
            // Add new page
            page = document.pages.add();
            graphics = page.graphics;
            yOffset = 50; // reset yOffset for the new page
          }
          graphics.drawString(
            line,
            textFont,
            bounds: ui.Rect.fromLTWH(50, yOffset, availableWidth, lineHeight),
          );
          yOffset += lineHeight;
        }
      } else {
        // No text found, add placeholder
        final PdfFont textFont = PdfStandardFont(PdfFontFamily.timesRoman, 12);
        graphics.drawString(
          'No text detected in the image.',
          textFont,
          bounds: ui.Rect.fromLTWH(
            50,
            yOffset,
            page.getClientSize().width - 100,
            20,
          ),
        );
      }

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        outputPath: null,
        metadata: {
          'pageCount': document.pages.count,
          'title': title,
          'extractedTextLength': extractedText.length,
          'language': languageCode,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error performing OCR: $e');
    }
  }

  /// Map language code to TextRecognitionScript
  TextRecognitionScript _getScriptFromLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'zh':
      case 'chs':
      case 'cht':
        return TextRecognitionScript.chinese;
      case 'ja':
        return TextRecognitionScript.japanese;
      case 'ko':
        return TextRecognitionScript.korean;
      case 'hi':
        return TextRecognitionScript.devanagiri;
      case 'en':
      default:
        return TextRecognitionScript.latin;
    }
  }

  /// Wrap text to fit within specified width
  List<String> _wrapText(String text, PdfFont font, double maxWidth) {
    final List<String> words = text.split(' ');
    final List<String> lines = [];
    String currentLine = '';

    for (String word in words) {
      final String testLine = currentLine.isEmpty ? word : '$currentLine $word';
      final ui.Size testSize = font.measureString(testLine);

      if (testSize.width <= maxWidth) {
        currentLine = testLine;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
        }
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }
}
