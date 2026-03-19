import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_tool.dart';

/// Tool for creating PDF documents with lists and bullets
class ListToPdfTool implements PdfTool {
  @override
  String get id => 'list_to_pdf';

  @override
  String get name => 'List to PDF';

  @override
  String get description => 'Create PDF documents with ordered and unordered lists';

  @override
  String get iconName => 'Icons.format_list_bulleted';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final List<Map<String, dynamic>> items = parameters['items'] as List<Map<String, dynamic>>? ?? [];
      final String title = parameters['title'] as String? ?? '';
      final String listType = parameters['listType'] as String? ?? 'unordered';
      final String? fontFamily = parameters['fontFamily'] as String?;
      final double fontSize = (parameters['fontSize'] as num?)?.toDouble() ?? 12.0;

      if (items.isEmpty) {
        return PdfToolResult.failure('At least one list item is required');
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      double yOffset = 50;

      // Add title if provided
      if (title.isNotEmpty) {
        final PdfFont titleFont = PdfStandardFont(
          _getFontFamily(fontFamily),
          24,
          style: PdfFontStyle.bold,
        );
        graphics.drawString(
          title,
          titleFont,
          bounds: ui.Rect.fromLTWH(50, yOffset, page.graphics.clientSize.width - 100, 50),
        );
        yOffset += 60;
      }

      // Create list items
      final List<String> listItems = items.map((item) => item['text'] as String).toList();

      if (listType.toLowerCase() == 'ordered') {
        // Create ordered list (numbered)
        final PdfOrderedList orderedList = PdfOrderedList(
          items: PdfListItemCollection(listItems),
          marker: PdfOrderedMarker(
            style: PdfNumberStyle.numeric,
            font: PdfStandardFont(_getFontFamily(fontFamily), fontSize),
          ),
          markerHierarchy: true,
          format: PdfStringFormat(lineSpacing: 10),
          textIndent: 10,
        );

        // Handle nested lists (sublists)
        for (int i = 0; i < items.length; i++) {
          final subItems = items[i]['subItems'] as List<dynamic>?;
          if (subItems != null && subItems.isNotEmpty) {
            final subItemTexts = subItems.map((sub) => sub as String).toList();
            orderedList.items[i].subList = PdfUnorderedList(
              marker: PdfUnorderedMarker(
                font: PdfStandardFont(_getFontFamily(fontFamily), fontSize - 2),
                style: PdfUnorderedMarkerStyle.disk,
              ),
              items: PdfListItemCollection(subItemTexts),
              textIndent: 10,
              indent: 20,
            );
          }
        }

        // Draw the ordered list
        orderedList.draw(
          page: page,
          bounds: ui.Rect.fromLTWH(
            50,
            yOffset,
            page.getClientSize().width - 100,
            page.getClientSize().height - yOffset - 50,
          ),
        );
      } else {
        // Create unordered list (bullets)
        final PdfUnorderedList unorderedList = PdfUnorderedList(
          marker: PdfUnorderedMarker(
            font: PdfStandardFont(_getFontFamily(fontFamily), fontSize),
            style: PdfUnorderedMarkerStyle.disk,
          ),
          items: PdfListItemCollection(listItems),
          textIndent: 10,
          indent: 20,
        );

        // Handle nested lists (sublists)
        for (int i = 0; i < items.length; i++) {
          final subItems = items[i]['subItems'] as List<dynamic>?;
          if (subItems != null && subItems.isNotEmpty) {
            final subItemTexts = subItems.map((sub) => sub as String).toList();
            unorderedList.items[i].subList = PdfUnorderedList(
              marker: PdfUnorderedMarker(
                font: PdfStandardFont(_getFontFamily(fontFamily), fontSize - 2),
                style: PdfUnorderedMarkerStyle.circle,
              ),
              items: PdfListItemCollection(subItemTexts),
              textIndent: 10,
              indent: 20,
            );
          }
        }

        // Draw the unordered list
        unorderedList.draw(
          page: page,
          bounds: ui.Rect.fromLTWH(
            50,
            yOffset,
            page.getClientSize().width - 100,
            page.getClientSize().height - yOffset - 50,
          ),
        );
      }

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': 1,
          'title': title,
          'listType': listType,
          'itemsCount': items.length,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating PDF with lists: $e');
    }
  }

  PdfFontFamily _getFontFamily(String? fontFamily) {
    switch (fontFamily?.toLowerCase()) {
      case 'times':
        return PdfFontFamily.timesRoman;
      case 'courier':
        return PdfFontFamily.courier;
      case 'helvetica':
      default:
        return PdfFontFamily.helvetica;
    }
  }
}

/// Tool for creating PDF with paragraphs and formatted text
class ParagraphToPdfTool implements PdfTool {
  @override
  String get id => 'paragraph_to_pdf';

  @override
  String get name => 'Paragraph to PDF';

  @override
  String get description => 'Create PDF documents with formatted paragraphs';

  @override
  String get iconName => 'Icons.format_paragraph';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final List<Map<String, dynamic>> paragraphs = parameters['paragraphs'] as List<Map<String, dynamic>>? ?? [];
      final String title = parameters['title'] as String? ?? '';
      final String? fontFamily = parameters['fontFamily'] as String?;
      final double fontSize = (parameters['fontSize'] as num?)?.toDouble() ?? 12.0;

      if (paragraphs.isEmpty) {
        return PdfToolResult.failure('At least one paragraph is required');
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      double yOffset = 50;

      // Add title if provided
      if (title.isNotEmpty) {
        final PdfFont titleFont = PdfStandardFont(
          _getFontFamily(fontFamily),
          24,
          style: PdfFontStyle.bold,
        );
        graphics.drawString(
          title,
          titleFont,
          bounds: ui.Rect.fromLTWH(50, yOffset, page.graphics.clientSize.width - 100, 50),
        );
        yOffset += 60;
      }

      // Add paragraphs
      for (final paragraph in paragraphs) {
        final String text = paragraph['text'] as String;
        final bool isHeading = paragraph['isHeading'] as bool? ?? false;

        final font = isHeading
            ? PdfStandardFont(_getFontFamily(fontFamily), fontSize + 4, style: PdfFontStyle.bold)
            : PdfStandardFont(_getFontFamily(fontFamily), fontSize);

        final result = PdfTextElement(
          text: text,
          font: font,
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        ).draw(
          page: page,
          bounds: ui.Rect.fromLTWH(
            50,
            yOffset,
            page.getClientSize().width - 100,
            page.getClientSize().height - yOffset - 50,
          ),
          format: PdfLayoutFormat(
            layoutType: PdfLayoutType.paginate,
          ),
        );

        if (result != null) {
          yOffset = result.bounds.bottom + 20;
        } else {
          yOffset += 30;
        }
      }

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();

      return PdfToolResult.success(
        pdfData: Uint8List.fromList(bytes),
        metadata: {
          'pageCount': 1,
          'title': title,
          'paragraphsCount': paragraphs.length,
        },
      );
    } catch (e) {
      return PdfToolResult.failure('Error creating PDF with paragraphs: $e');
    }
  }

  PdfFontFamily _getFontFamily(String? fontFamily) {
    switch (fontFamily?.toLowerCase()) {
      case 'times':
        return PdfFontFamily.timesRoman;
      case 'courier':
        return PdfFontFamily.courier;
      case 'helvetica':
      default:
        return PdfFontFamily.helvetica;
    }
  }
}
