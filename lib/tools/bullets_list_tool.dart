import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

class BulletsAndListsTool implements PdfTool {
  @override
  String get id => 'bullets_lists';

  @override
  String get name => 'Bullets & Lists';

  @override
  String get description => 'Create ordered or unordered lists in a PDF';

  @override
  String get iconName => 'Icons.format_list_bulleted';

  @override
  Map<String, String> get parametersSchema => {
        'items': 'List items as an array or a newline-separated string',
        'ordered': 'Whether to render an ordered list (true) or unordered list (false)',
        'fontSize': 'Font size for list markers',
      };

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final Object? rawItems = parameters['items'];
      final bool ordered = parameters['ordered'] as bool? ?? true;
      final double fontSize = parameters['fontSize'] as double? ?? 12.0;

      final List<String> items = _parseItems(rawItems);
      if (items.isEmpty) {
        return PdfToolResult.failure('List items are required');
      }

      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();

      final PdfList list = ordered
          ? PdfOrderedList(
              items: PdfListItemCollection(items),
              marker: PdfOrderedMarker(
                style: PdfNumberStyle.numeric,
                font: PdfStandardFont(PdfFontFamily.helvetica, fontSize),
              ),
              markerHierarchy: true,
              format: PdfStringFormat(lineSpacing: 8),
              textIndent: 10,
            )
          : PdfUnorderedList(
              items: PdfListItemCollection(items),
              marker: PdfUnorderedMarker(
                font: PdfStandardFont(PdfFontFamily.helvetica, fontSize),
                style: PdfUnorderedMarkerStyle.disk,
              ),
              format: PdfStringFormat(lineSpacing: 8),
              textIndent: 10,
            );

      list.draw(
        page: page,
        bounds: ui.Rect.fromLTWH(
          40,
          40,
          page.getClientSize().width - 80,
          page.getClientSize().height - 80,
        ),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {'itemCount': items.length, 'ordered': ordered},
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating list PDF: $e');
    }
  }

  List<String> _parseItems(Object? rawItems) {
    if (rawItems is List<String>) {
      return rawItems.where((item) => item.trim().isNotEmpty).toList();
    }
    if (rawItems is String) {
      return rawItems
          .split(RegExp(r'\r?\n'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <String>[];
  }
}
