// This is a basic Flutter widget test for PDF Editor app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_editor/main.dart';

void main() {
  testWidgets('PDF Editor initial UI test', (WidgetTester tester) async {
    await tester.pumpWidget(const PdfEditorApp());
    await tester.pumpAndSettle();

    expect(find.text('PDF Editor'), findsAtLeastNWidgets(1));

    expect(
      find.text('Open, edit, or scan files with a fast local toolkit.'),
      findsOneWidget,
    );

    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    expect(find.text('Open PDF'), findsOneWidget);
    expect(find.text('Create New'), findsOneWidget);
    expect(find.text('Scan Doc'), findsNothing);
    expect(find.text('PDF Tools'), findsNothing);
    expect(find.text('AI Chat'), findsNothing);

    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner), findsNothing);
    expect(find.byIcon(Icons.build), findsNothing);
    expect(find.byIcon(Icons.smart_toy), findsNothing);
  });
}
