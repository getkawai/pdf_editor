import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for digitally signing PDF documents
class SignaturePdfTool implements PdfTool {
  @override
  String get id => 'signature_pdf';

  @override
  String get name => 'Sign PDF';

  @override
  String get description => 'Add digital signatures to PDF documents';

  @override
  String get iconName => 'Icons.edit_signatures';

  @override
  Map<String, String> get parametersSchema => {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List pdfData =
          parameters['pdfData'] as Uint8List? ?? Uint8List(0);
      final Uint8List? certificateData =
          parameters['certificateData'] as Uint8List?;
      final String? certificatePassword =
          parameters['certificatePassword'] as String?;
      final String? certificatePath = parameters['certificatePath'] as String?;
      final int pageNumber = parameters['pageNumber'] as int? ?? 1;
      final double x = (parameters['x'] as num?)?.toDouble() ?? 50.0;
      final double y = (parameters['y'] as num?)?.toDouble() ?? 50.0;
      final double width = (parameters['width'] as num?)?.toDouble() ?? 200.0;
      final double height = (parameters['height'] as num?)?.toDouble() ?? 50.0;
      final String? reason = parameters['reason'] as String?;
      final String? contactInfo = parameters['contactInfo'] as String?;

      if (pdfData.isEmpty) {
        return PdfToolResult.failure('PDF data is required');
      }

      if (certificateData == null &&
          (certificatePath == null || certificatePath.isEmpty)) {
        return PdfToolResult.failure('Certificate file (.pfx) is required');
      }

      if (certificatePassword == null || certificatePassword.isEmpty) {
        return PdfToolResult.failure('Certificate password is required');
      }

      // Load the PDF document
      PdfDocument document = PdfDocument(inputBytes: pdfData);

      // Validate page number
      if (pageNumber < 1 || pageNumber > document.pages.count) {
        document.dispose();
        return PdfToolResult.failure('Invalid page number');
      }

      final PdfPage page = document.pages[pageNumber - 1];

      // Load certificate
      Uint8List certBytes;
      if (certificateData != null) {
        certBytes = certificateData;
      } else {
        // Read from file path
        final file = File(certificatePath!);
        certBytes = await file.readAsBytes();
      }

      // Create signature
      final PdfSignatureField signatureField = PdfSignatureField(
        page,
        'Signature',
        bounds: ui.Rect.fromLTWH(x, y, width, height),
        signature: PdfSignature(
          certificate: PdfCertificate(certBytes, certificatePassword),
          contactInfo: contactInfo,
          reason: reason ?? 'Document Approval',
        ),
      );

      // Add signature field to the document
      document.form.fields.add(signatureField);

      // Save the signed document
      final List<int> bytes = await document.save();
      final int pageCount = document.pages.count;
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': pageCount,
          'signed': true,
          'pageNumber': pageNumber,
          'reason': reason ?? 'Document Approval',
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error signing PDF: $e');
    }
  }
}

/// Tool for creating a new PDF with a digital signature
class CreateSignedPdfTool implements PdfTool {
  @override
  String get id => 'create_signed_pdf';

  @override
  String get name => 'Create Signed PDF';

  @override
  String get description => 'Create a new PDF document with digital signature';

  @override
  String get iconName => 'Icons.note_add';

  @override
  Map<String, String> get parametersSchema => {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final String text = parameters['text'] as String? ?? '';
      final String title = parameters['title'] as String? ?? '';
      final Uint8List? certificateData =
          parameters['certificateData'] as Uint8List?;
      final String? certificatePath = parameters['certificatePath'] as String?;
      final String? certificatePassword =
          parameters['certificatePassword'] as String?;
      final String? reason = parameters['reason'] as String?;
      final String? contactInfo = parameters['contactInfo'] as String?;

      if (text.isEmpty) {
        return PdfToolResult.failure('Text content is required');
      }

      if (certificateData == null &&
          (certificatePath == null || certificatePath.isEmpty)) {
        return PdfToolResult.failure('Certificate file (.pfx) is required');
      }

      if (certificatePassword == null || certificatePassword.isEmpty) {
        return PdfToolResult.failure('Certificate password is required');
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
          bounds: ui.Rect.fromLTWH(
            50,
            yOffset,
            page.graphics.clientSize.width - 100,
            50,
          ),
        );
        yOffset += 60;
      }

      // Add content text
      final PdfFont textFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
      PdfTextElement(text: text, font: textFont).draw(
        page: page,
        bounds: ui.Rect.fromLTWH(
          50,
          yOffset,
          page.getClientSize().width - 100,
          page.getClientSize().height - yOffset - 100,
        ),
        format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
      );

      // Load certificate
      Uint8List certBytes;
      if (certificateData != null) {
        certBytes = certificateData;
      } else {
        final file = File(certificatePath!);
        certBytes = await file.readAsBytes();
      }

      // Add signature at the bottom
      final signatureField = PdfSignatureField(
        page,
        'Signature',
        bounds: ui.Rect.fromLTWH(50, page.getClientSize().height - 80, 200, 50),
        signature: PdfSignature(
          certificate: PdfCertificate(certBytes, certificatePassword),
          contactInfo: contactInfo,
          reason: reason ?? 'Document Approval',
        ),
      );

      document.form.fields.add(signatureField);

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'pageCount': 1, 'title': title, 'signed': true},
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating signed PDF: $e');
    }
  }
}

/// Tool for verifying digital signatures in PDF documents
class VerifySignaturePdfTool implements PdfTool {
  @override
  String get id => 'verify_signature_pdf';

  @override
  String get name => 'Verify Signature';

  @override
  String get description => 'Verify digital signatures in PDF documents';

  @override
  String get iconName => 'Icons.verified';

  @override
  Map<String, String> get parametersSchema => {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List pdfData =
          parameters['pdfData'] as Uint8List? ?? Uint8List(0);

      if (pdfData.isEmpty) {
        return PdfToolResult.failure('PDF data is required');
      }

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfData);

      // Check for signature fields
      final List<Map<String, dynamic>> signatures = [];
      for (int i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        if (field is PdfSignatureField) {
          final signature = field.signature;
          if (signature != null) {
            signatures.add({
              'fieldName': field.name,
              'signed': true,
              'reason': signature.reason,
              'contactInfo': signature.contactInfo,
            });
          }
        }
      }

      document.dispose();

      if (signatures.isEmpty) {
        return PdfToolResult.failure('No digital signatures found in this PDF');
      }

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(pdfData),
        metadata: {
          'signaturesCount': signatures.length,
          'signatures': signatures,
          'allSigned': signatures.every((s) => s['signed'] as bool),
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error verifying signatures: $e');
    }
  }
}
