import 'pdf_tool.dart';
import 'tools_registry.dart';
import 'text_to_pdf_tool.dart';
import 'image_to_pdf_tool.dart';
import 'merge_pdfs_tool.dart';
import 'compress_pdf_tool.dart';
import 'annotate_pdf_tool.dart';
import 'ai_pdf_tools.dart';

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
    // Register all built-in tools
    _registry.registerTool(TextToPdfTool());
    _registry.registerTool(ImageToPdfTool());
    _registry.registerTool(MergePdfsTool());
    _registry.registerTool(CompressPdfTool());
    _registry.registerTool(AnnotatePdfTool());
    _registry.registerTool(AiPdfAssistantTool());
    _registry.registerTool(SummarizePdfTool());
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
  Future<PdfToolResult> executeTool(String toolId, Map<String, dynamic> parameters) async {
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
