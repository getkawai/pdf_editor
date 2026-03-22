import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'PDF Editor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Navigate',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _buildItem(
            context,
            index: 0,
            icon: Icons.smart_toy,
            label: 'AI Chat',
          ),
          _buildItem(
            context,
            index: 1,
            icon: Icons.home,
            label: 'Home',
          ),
          _buildItem(
            context,
            index: 2,
            icon: Icons.build,
            label: 'PDF Tools',
          ),
          _buildItem(
            context,
            index: 3,
            icon: Icons.document_scanner,
            label: 'Scan',
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = currentIndex == index;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: selected
            ? TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              )
            : null,
      ),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        onSelect(index);
      },
    );
  }
}
