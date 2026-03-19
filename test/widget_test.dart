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

    // Verify that the main action buttons are present.
    expect(find.text('Open PDF'), findsOneWidget);
    expect(find.text('Create New PDF'), findsOneWidget);

    // Verify that the initial icon is present.
    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
  });
}
