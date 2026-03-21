import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/analytics_service.dart';

class PdfEditorScreen extends StatefulWidget {
  const PdfEditorScreen({super.key});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String? _selectedImagePath;
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path!;
        });
        _showAddImageDialog();
        
        // Log analytics
        _analytics.logEditPdf(editType: 'add_image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
        
        // Log error
        _analytics.logError(
          errorType: 'image_picker_error',
          errorMessage: e.toString(),
          screen: 'pdf_editor',
        );
      }
    }
  }

  Future<void> _createPDF({
    String? text,
    String? imagePath,
    Uint8List? signatureData,
  }) async {
    try {
      // Create a new PDF document
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      double yOffset = 50;

      // Add title if provided
      if (_titleController.text.isNotEmpty) {
        final PdfFont titleFont = PdfStandardFont(
          PdfFontFamily.helvetica,
          24,
          style: PdfFontStyle.bold,
        );
        graphics.drawString(
          _titleController.text,
          titleFont,
          bounds: Rect.fromLTWH(50, yOffset, page.graphics.clientSize.width - 100, 50),
        );
        yOffset += 60;
      }

      // Add text if provided
      if (text != null && text.isNotEmpty) {
        final PdfFont textFont = PdfStandardFont(PdfFontFamily.helvetica, 14);
        graphics.drawString(
          text,
          textFont,
          bounds: Rect.fromLTWH(50, yOffset, page.graphics.clientSize.width - 100, 200),
        );
        yOffset += 220;
      }

      // Add image if provided
      if (imagePath != null) {
        final File imageFile = File(imagePath);
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final PdfImage pdfImage = PdfBitmap(imageBytes);

        final double imageWidth = 200;
        final double imageHeight = (pdfImage.height * imageWidth) / pdfImage.width;

        graphics.drawImage(
          pdfImage,
          Rect.fromLTWH(50, yOffset, imageWidth, imageHeight),
        );
        yOffset += imageHeight + 20;
      }

      // Add signature if provided
      if (signatureData != null) {
        final PdfImage signatureImage = PdfBitmap(signatureData);
        final double signatureWidth = 200;
        final double signatureHeight = (signatureImage.height * signatureWidth) / signatureImage.width;

        graphics.drawImage(
          signatureImage,
          Rect.fromLTWH(50, yOffset, signatureWidth, signatureHeight),
        );
      }

      // Save the document
      final Directory? appDir = await getApplicationDocumentsDirectory();
      final String dirPath = appDir!.path;
      final String fileName = _titleController.text.isEmpty
          ? 'document_${DateTime.now().millisecondsSinceEpoch}.pdf'
          : '${_titleController.text.replaceAll(' ', '_')}.pdf';

      final File file = File('$dirPath/$fileName');
      await file.writeAsBytes(await document.save());
      document.dispose();

      // Log analytics
      _analytics.logSavePdf(
        documentId: fileName,
        pageCount: 1,
      );
      _analytics.logEditPdf(
        editType: text != null ? 'add_text' : imagePath != null ? 'add_image' : 'create',
        details: 'title: ${_titleController.text.isNotEmpty ? 'yes' : 'no'}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: $fileName'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
        
        // Log error
        _analytics.logError(
          errorType: 'pdf_creation_error',
          errorMessage: e.toString(),
          screen: 'pdf_editor',
        );
      }
    }
  }

  Future<void> _showAddTextDialog() async {
    _textController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Content Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createPDF(text: _textController.text);
            },
            child: const Text('Create PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddImageDialog() async {
    if (_selectedImagePath == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image to PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              File(_selectedImagePath!),
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedImagePath = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createPDF(imagePath: _selectedImagePath);
              setState(() {
                _selectedImagePath = null;
              });
            },
            child: const Text('Create PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSignatureDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Draw Signature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRect(
                child: CustomPaint(
                  size: const Size(300, 200),
                  painter: _SignaturePainter(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Signature drawing requires additional setup.\nFor now, use text or image options.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // For simplicity, create a placeholder signature PDF
              Navigator.pop(context);
              _createPDF(text: 'Signature placeholder');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title',
                hintText: 'Enter document title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose a starting point',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Add text, image, or signature to generate a new PDF.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildToolCard(
              icon: Icons.text_fields,
              title: 'Add Text',
              description: 'Create a PDF with text content',
              onTap: _showAddTextDialog,
            ),
            const SizedBox(height: 12),
            _buildToolCard(
              icon: Icons.image,
              title: 'Add Image',
              description: 'Create a PDF from an image',
              onTap: _pickImage,
            ),
            const SizedBox(height: 12),
            _buildToolCard(
              icon: Icons.edit,
              title: 'Add Signature',
              description: 'Signature pad coming soon',
              onTap: _showAddSignatureDialog,
              isDisabled: true,
            ),
            const SizedBox(height: 24),
            if (_selectedImagePath != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Image selected: ${_selectedImagePath!.split('/').last}',
                        style: TextStyle(color: Colors.green.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedImagePath = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isDisabled
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDisabled
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.note_add,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a clean document fast',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Start with a title, then add content.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw a placeholder text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Signature pad\n(Placeholder)',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
