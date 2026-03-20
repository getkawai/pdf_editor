import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class AttachmentPdfTool implements PdfTool {
  @override
  String get id => 'attachment_pdf';

  @override
  String get name => 'Attachment';

  @override
  String get description => 'Add file attachments to a PDF';

  @override
  String get iconName => 'Icons.attach_file';

  @override
  Map<String, String> get parametersSchema => {
        'pdfData': 'Optional existing PDF data to add the attachment to',
        'attachmentData': 'Binary data for the file to attach',
        'fileName': 'File name for the attachment',
        'description': 'Optional attachment description',
        'mimeType': 'Optional attachment MIME type',
      };

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List? pdfData = parameters['pdfData'] as Uint8List?;
      final Uint8List? attachmentData = parameters['attachmentData'] as Uint8List?;
      final String fileName = parameters['fileName'] as String? ?? 'attachment.bin';
      final String? description = parameters['description'] as String?;
      final String? mimeType = parameters['mimeType'] as String?;

      if (attachmentData == null || attachmentData.isEmpty) {
        return PdfToolResult.failure('Attachment data is required');
      }

      final PdfDocument document = pdfData != null && pdfData.isNotEmpty
          ? PdfDocument(inputBytes: pdfData)
          : PdfDocument();

      if (document.pages.count == 0) {
        document.pages.add();
      }

      final PdfAttachment attachment = PdfAttachment(
        fileName,
        attachmentData,
        description: description,
        mimeType: mimeType,
      );

      document.attachments.add(attachment);

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'fileName': fileName},
      );
    } catch (e) {
      return PdfToolResult.failure('Error adding attachment: $e');
    }
  }
}
