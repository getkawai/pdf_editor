import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'tools_screen.dart';
import 'document_scanner_screen.dart';
import 'llm_chat_screen.dart';
import 'widgets/app_drawer.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const int _chatIndex = 0;

  int _currentIndex = _chatIndex;

  @override
  Widget build(BuildContext context) {
    final drawer = _buildDrawer();
    final screens = <Widget>[
      LlmChatScreen(drawer: drawer),
      HomeScreen(onNavigateToTab: _setTab, drawer: drawer),
      ToolsScreen(drawer: drawer),
      DocumentScannerScreen(drawer: drawer),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }

  void _setTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildDrawer() {
    return AppDrawer(
      currentIndex: _currentIndex,
      onSelect: _setTab,
    );
  }
}
