import 'pdf_tool.dart';

/// Registry for managing PDF tools
class ToolsRegistry {
  static final ToolsRegistry _instance = ToolsRegistry._internal();
  final Map<String, PdfTool> _tools = {};

  factory ToolsRegistry() {
    return _instance;
  }

  ToolsRegistry._internal();

  /// Register a tool
  void registerTool(PdfTool tool) {
    _tools[tool.id] = tool;
  }

  /// Unregister a tool
  void unregisterTool(String toolId) {
    _tools.remove(toolId);
  }

  /// Get a tool by ID
  PdfTool? getTool(String toolId) {
    return _tools[toolId];
  }

  /// Get all registered tools
  List<PdfTool> getAllTools() {
    return _tools.values.toList();
  }

  /// Check if a tool is registered
  bool isToolRegistered(String toolId) {
    return _tools.containsKey(toolId);
  }

  /// Get tools by category
  List<PdfTool> getToolsByCategory(String category) {
    return _tools.values
        .where((tool) => tool.id.startsWith(category))
        .toList();
  }

  /// Clear all tools (useful for testing)
  void clear() {
    _tools.clear();
  }
}
