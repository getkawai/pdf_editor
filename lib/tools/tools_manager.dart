import 'pdf_tool.dart';
import 'tools_registry.dart';
import 'text_to_pdf_tool.dart';
import 'image_to_pdf_tool.dart';
import 'merge_pdfs_tool.dart';
import 'compress_pdf_tool.dart';
import 'annotate_pdf_tool.dart';
import 'ai_pdf_tools.dart';
import 'bookmark_pdf_tool.dart';
import 'encrypt_pdf_tool.dart';
import 'decrypt_pdf_tool.dart';
import 'hyperlink_pdf_tool.dart';
import 'signature_pdf_tool.dart';
import 'pdf_a_conformance_tool.dart';
import 'table_to_pdf_tool.dart';
import 'list_to_pdf_tool.dart';
import 'ocr_pdf_tool.dart';

/// Manager for initializing and accessing PDF tools
class ToolsManager {
  static final ToolsManager _instance = ToolsManager._internal();
  late final ToolsRegistry _registry;

  factory ToolsManager() {
    return _instance;
  }

  ToolsManager._internal() {
    _registry = ToolsRegistry();
    _initializeTools();
  }

  /// Initialize all built-in tools
  void _initializeTools() {
    // Core tools
    _registry.registerTool(TextToPdfTool());
    _registry.registerTool(ImageToPdfTool());
    _registry.registerTool(MergePdfsTool());
    _registry.registerTool(CompressPdfTool());
    _registry.registerTool(AnnotatePdfTool());
    _registry.registerTool(OcropdfTool());

    // AI tools
    _registry.registerTool(AiPdfAssistantTool());
    _registry.registerTool(SummarizePdfTool());

    // Table and List tools
    _registry.registerTool(TableToPdfTool());
    _registry.registerTool(ListToPdfTool());
    _registry.registerTool(ParagraphToPdfTool());

    // Navigation and Interactive tools
    _registry.registerTool(HyperlinkPdfTool());
    _registry.registerTool(BookmarkPdfTool());
    _registry.registerTool(CreateBookmarkedPdfTool());

    // Security tools
    _registry.registerTool(EncryptPdfTool());
    _registry.registerTool(DecryptPdfTool());
    _registry.registerTool(SignaturePdfTool());
    _registry.registerTool(CreateSignedPdfTool());
    _registry.registerTool(VerifySignaturePdfTool());

    // PDF/A Conformance tools
    _registry.registerTool(PdfAConformanceTool());
    _registry.registerTool(ConvertToPdfATool());
  }

  /// Get the tools registry
  ToolsRegistry get registry => _registry;

  /// Get all available tools
  List<PdfTool> getAllTools() {
    return _registry.getAllTools();
  }

  /// Get a specific tool by ID
  PdfTool? getTool(String toolId) {
    return _registry.getTool(toolId);
  }

  /// Execute a tool by ID
  Future<PdfToolResult> executeTool(
    String toolId,
    Map<String, dynamic> parameters,
  ) async {
    final tool = _registry.getTool(toolId);
    if (tool == null) {
      return PdfToolResult.failure('Tool not found: $toolId');
    }

    final isAvailable = await tool.isAvailable();
    if (!isAvailable) {
      return PdfToolResult.failure('Tool not available: ${tool.name}');
    }

    return await tool.execute(parameters);
  }

  /// Check if a tool is available
  Future<bool> isToolAvailable(String toolId) async {
    final tool = _registry.getTool(toolId);
    if (tool == null) return false;
    return await tool.isAvailable();
  }
}
