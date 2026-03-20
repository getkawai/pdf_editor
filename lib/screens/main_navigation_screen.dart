import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'tools_screen.dart';
import 'document_scanner_screen.dart';
import 'llm_chat_screen.dart';
import '../services/analytics_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final AnalyticsService _analytics = AnalyticsService();
  static const List<String> _tabLabels = [
    'home',
    'tools',
    'scan',
    'ai_chat',
  ];

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onNavigateToTab: _setTab),
      const ToolsScreen(),
      const DocumentScannerScreen(),
      const LlmChatScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _setTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Chat',
          ),
        ],
      ),
    );
  }

  void _setTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _logTabChange(index);
  }

  void _logTabChange(int index) {
    final label = _tabLabels[index];
    _analytics.logEvent(
      name: 'bottom_nav_select',
      parameters: {
        'tab_index': index,
        'tab_name': label,
      },
    );
    _analytics.logScreenView(
      screenName: 'tab_$label',
      screenClass: 'MainNavigationScreen',
    );
  }
}
