import 'dart:typed_data';

/// Base interface for all PDF tools
abstract class PdfTool {
  /// Unique identifier for the tool
  String get id;

  /// Display name for the tool
  String get name;

  /// Description of what the tool does
  String get description;

  /// Icon data for the tool (to be used in UI)
  String get iconName;

  /// Check if the tool is available
  Future<bool> isAvailable();

  /// Execute the tool with the given parameters
  Future<PdfToolResult> execute(Map<String, dynamic> parameters);
}

/// Result from executing a PDF tool
class PdfToolResult {
  final bool success;
  final Uint8List? pdfData;
  final String? outputPath;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  PdfToolResult({
    required this.success,
    this.pdfData,
    this.outputPath,
    this.errorMessage,
    this.metadata,
  });

  factory PdfToolResult.success({
    Uint8List? pdfData,
    String? outputPath,
    Map<String, dynamic>? metadata,
  }) {
    return PdfToolResult(
      success: true,
      pdfData: pdfData,
      outputPath: outputPath,
      metadata: metadata,
    );
  }

  factory PdfToolResult.failure(String errorMessage) {
    return PdfToolResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Parameters for PDF tool execution
class PdfToolParameters {
  final Map<String, dynamic> _values;

  PdfToolParameters() : _values = {};

  void setString(String key, String value) {
    _values[key] = value;
  }

  void setInt(String key, int value) {
    _values[key] = value;
  }

  void setDouble(String key, double value) {
    _values[key] = value;
  }

  void setBool(String key, bool value) {
    _values[key] = value;
  }

  void setData(String key, Uint8List value) {
    _values[key] = value;
  }

  void setList(String key, List<String> value) {
    _values[key] = value;
  }

  String? getString(String key) {
    return _values[key] as String?;
  }

  int? getInt(String key) {
    return _values[key] as int?;
  }

  double? getDouble(String key) {
    return _values[key] as double?;
  }

  bool? getBool(String key) {
    return _values[key] as bool?;
  }

  Uint8List? getData(String key) {
    return _values[key] as Uint8List?;
  }

  List<String>? getList(String key) {
    return _values[key] as List<String>?;
  }

  Map<String, dynamic> toMap() {
    return Map.unmodifiable(_values);
  }
}
