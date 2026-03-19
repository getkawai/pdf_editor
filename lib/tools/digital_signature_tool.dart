import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class DigitalSignatureTool implements PdfTool {
  @override
  String get id => 'digital_signature';

  @override
  String get name => 'Digital Signature';

  @override
  String get description => 'Digitally sign a PDF with a PFX certificate';

  @override
  String get iconName => 'Icons.draw';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List? pdfData = parameters['pdfData'] as Uint8List?;
      final Uint8List? pfxData = parameters['pfxData'] as Uint8List?;
      final String password = parameters['password'] as String? ?? '';
      final String? reason = parameters['reason'] as String?;

      if (pfxData == null || pfxData.isEmpty) {
        return PdfToolResult.failure('PFX certificate data is required');
      }
      if (password.isEmpty) {
        return PdfToolResult.failure('Certificate password is required');
      }

      final PdfDocument document = pdfData != null && pdfData.isNotEmpty
          ? PdfDocument(inputBytes: pdfData)
          : PdfDocument();

      final PdfPage page = document.pages.count > 0
          ? document.pages[0]
          : document.pages.add();

      final PdfSignatureField signatureField = PdfSignatureField(
        page,
        'Signature',
        bounds: const ui.Rect.fromLTWH(40, 40, 200, 60),
        signature: PdfSignature(
          certificate: PdfCertificate(pfxData, password),
          reason: reason,
        ),
      );

      document.form.fields.add(signatureField);

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'signed': true},
      );
    } catch (e) {
      return PdfToolResult.failure('Error signing PDF: $e');
    }
  }
}
