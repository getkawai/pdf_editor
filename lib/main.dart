import 'package:flutter/material.dart';
import 'screens/app_root.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PdfEditorApp());
}

class PdfEditorApp extends StatelessWidget {
  const PdfEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Editor',
      debugShowCheckedModeBanner: false,
      navigatorObservers: _buildNavigatorObservers(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AppRoot(),
    );
  }

  List<NavigatorObserver> _buildNavigatorObservers() {
    return const <NavigatorObserver>[];
  }
}
