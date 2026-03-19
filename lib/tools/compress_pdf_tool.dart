import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for compressing PDF files
class CompressPdfTool implements PdfTool {
  @override
  String get id => 'compress_pdf';

  @override
  String get name => 'Compress PDF';

  @override
  String get description => 'Reduce PDF file size';

  @override
  String get iconName => 'Icons.compress';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List pdfData = parameters['pdfData'] as Uint8List? ?? Uint8List(0);

      if (pdfData.isEmpty) {
        return PdfToolResult.failure('PDF data is required');
      }

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfData);
      final int originalPageCount = document.pages.count;
      
      // Save the document (Syncfusion automatically applies compression)
      final List<int> bytes = await document.save();
      final int compressedSize = bytes.length;
      document.dispose();

      final int originalSize = pdfData.lengthInBytes;
      final double compressionRatio = originalSize > 0 
          ? ((originalSize - compressedSize) / originalSize) * 100 
          : 0;

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'originalSize': originalSize,
          'compressedSize': compressedSize,
          'compressionRatio': compressionRatio,
          'pageCount': originalPageCount,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error compressing PDF: $e');
    }
  }
}
