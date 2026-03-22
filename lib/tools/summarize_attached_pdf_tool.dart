import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';
import '../llm/llm.dart';

class SummarizeAttachedPdfTool implements PdfTool {
  final LlmService _llmService;

  SummarizeAttachedPdfTool() : _llmService = LlmService();

  @override
  String get id => 'summarize_attached_pdf';

  @override
  String get name => 'Summarize Attached PDF';

  @override
  String get description => 'Summarize the attached PDF content.';

  @override
  String get iconName => 'Icons.auto_awesome';

  @override
  Map<String, String> get parametersSchema => const {};

  @override
  Future<bool> isAvailable() async {
    return await _llmService.initialize();
  }

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Uint8List pdfData =
          parameters['pdfData'] as Uint8List? ?? Uint8List(0);

      if (pdfData.isEmpty) {
        return PdfToolResult.failure('PDF data is required');
      }

      if (!_llmService.isModelLoaded) {
        final models = await _llmService.getModels();
        if (models.isEmpty) {
          return PdfToolResult.failure('No models available');
        }
        final loaded = await _llmService.loadModel(models.first);
        if (!loaded) {
          return PdfToolResult.failure(
            _llmService.lastError ?? 'Failed to load model',
          );
        }
      }

      final extractedText = _extractTextFromPdf(pdfData);
      if (extractedText.trim().isEmpty) {
        return PdfToolResult.failure('No text found in PDF');
      }

      final truncated =
          extractedText.length > 6000
              ? extractedText.substring(0, 6000)
              : extractedText;
      final request = LlmGenerationRequest(
        prompt: 'Please summarize the following PDF content:\n\n$truncated',
        systemPrompt: 'You are a helpful assistant that summarizes documents.',
        temperature: 0.4,
        maxTokens: 512,
        enableFunctionCalling: false,
      );

      final response = await _llmService.generate(request);
      if (!response.isComplete || response.errorMessage != null) {
        return PdfToolResult.failure(
          response.errorMessage ?? 'Summarization failed',
        );
      }

      return PdfToolResult.success(
        metadata: {'summary': response.content},
      );
    } catch (e) {
      return PdfToolResult.failure('Error: $e');
    }
  }

  String _extractTextFromPdf(Uint8List pdfData) {
    try {
      final document = PdfDocument(inputBytes: pdfData);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text;
    } catch (_) {
      return '';
    }
  }
}
