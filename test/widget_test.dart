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
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PdfEditorApp());

    // Verify that the app title is shown in the home screen.
    expect(find.text('PDF Editor'), findsAtLeastNWidgets(1));

    // Verify that the subtitle is present.
    expect(find.text('View, create, and edit PDF documents'), findsOneWidget);

    // Verify that the info action button is present in the AppBar.
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    // Verify that the main action buttons are present.
    expect(find.text('Open PDF'), findsOneWidget);
    expect(find.text('Create New'), findsOneWidget);
    expect(find.text('Scan Doc'), findsOneWidget);
    expect(find.text('PDF Tools'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);

    // Verify that the icons are present.
    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner), findsOneWidget);
    expect(find.byIcon(Icons.build), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy), findsOneWidget);
  });
}
