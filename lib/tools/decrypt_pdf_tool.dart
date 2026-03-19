import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class DecryptPdfTool implements PdfTool {
  @override
  String get id => 'decrypt_pdf';

  @override
  String get name => 'Decrypt PDF';

  @override
  String get description => 'Remove password protection from a PDF';

  @override
  String get iconName => 'Icons.lock_open';

  @override
  Map<String, String> get parametersSchema => {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List? pdfData = parameters['pdfData'] as Uint8List?;
      final String password = parameters['password'] as String? ?? '';

      if (pdfData == null || pdfData.isEmpty) {
        return PdfToolResult.failure('PDF data is required');
      }
      if (password.isEmpty) {
        return PdfToolResult.failure('Password is required');
      }

      final PdfDocument source = PdfDocument(
        inputBytes: pdfData,
        password: password,
      );
      final PdfDocument output = PdfDocument();

      for (int i = 0; i < source.pages.count; i++) {
        final PdfPage newPage = output.pages.add();
        final PdfTemplate template = source.pages[i].createTemplate();
        newPage.graphics.drawPdfTemplate(template, ui.Offset.zero);
      }

      final List<int> bytes = await output.save();
      source.dispose();
      output.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'pageCount': source.pages.count},
      );
    } catch (e) {
      return PdfToolResult.failure('Error decrypting PDF: $e');
    }
  }
}
