import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class EncryptPdfTool implements PdfTool {
  @override
  String get id => 'encrypt_pdf';

  @override
  String get name => 'Encrypt PDF';

  @override
  String get description => 'Encrypt a PDF with a password';

  @override
  String get iconName => 'Icons.lock';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List? pdfData = parameters['pdfData'] as Uint8List?;
      final String userPassword = parameters['userPassword'] as String? ?? '';
      final String ownerPassword = parameters['ownerPassword'] as String? ?? '';
      final String algorithm = parameters['algorithm'] as String? ?? 'aes256';

      if (pdfData == null || pdfData.isEmpty) {
        return PdfToolResult.failure('PDF data is required');
      }
      if (userPassword.isEmpty || ownerPassword.isEmpty) {
        return PdfToolResult.failure('User and owner passwords are required');
      }

      final PdfDocument document = PdfDocument(inputBytes: pdfData);
      final PdfSecurity security = document.security;

      security.userPassword = userPassword;
      security.ownerPassword = ownerPassword;
      security.algorithm = _parseAlgorithm(algorithm);

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'algorithm': algorithm},
      );
    } catch (e) {
      return PdfToolResult.failure('Error encrypting PDF: $e');
    }
  }

  PdfEncryptionAlgorithm _parseAlgorithm(String input) {
    switch (input.toLowerCase()) {
      case 'rc4_40':
      case 'rc4x40':
        return PdfEncryptionAlgorithm.rc4x40Bit;
      case 'rc4_128':
      case 'rc4x128':
        return PdfEncryptionAlgorithm.rc4x128Bit;
      case 'aes128':
        return PdfEncryptionAlgorithm.aesx128Bit;
      case 'aes256_rev6':
      case 'aes256r6':
        return PdfEncryptionAlgorithm.aesx256BitRevision6;
      case 'aes256':
      default:
        return PdfEncryptionAlgorithm.aesx256Bit;
    }
  }
}
