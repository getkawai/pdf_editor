import 'package:flutter/material.dart';
import '../../tools/tools.dart';
import '../../services/analytics_service.dart';

/// Widget for visual bullets and lists editor UI
class ListsEditorWidget extends StatefulWidget {
  final PdfTool tool;
  final AnalyticsService analytics;
  final Function(Map<String, dynamic>) onExecute;

  const ListsEditorWidget({
    super.key,
    required this.tool,
    required this.analytics,
    required this.onExecute,
  });

  @override
  State<ListsEditorWidget> createState() => _ListsEditorWidgetState();
}

class _ListsEditorWidgetState extends State<ListsEditorWidget> {
  final List<Map<String, dynamic>> _items = [];
  bool _isOrdered = false;
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  int? _editingIndex;

  void _addItem() {
    if (_itemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter list item text')),
      );
      return;
    }

    setState(() {
      if (_editingIndex != null) {
        _items[_editingIndex!]['text'] = _itemController.text;
        _editingIndex = null;
      } else {
        _items.add({'text': _itemController.text, 'subItems': <String>[]});
      }
      _itemController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _editItem(int index) {
    setState(() {
      _editingIndex = index;
      _itemController.text = _items[index]['text'];
    });
  }

  void _addSubItem(int parentIndex) {
    showDialog(
      context: context,
      builder: (context) {
        final subItemController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Sub-item'),
          content: TextField(
            controller: subItemController,
            decoration: const InputDecoration(
              labelText: 'Sub-item text',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (subItemController.text.isNotEmpty) {
                  setState(() {
                    _items[parentIndex]['subItems'].add(subItemController.text);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeSubItem(int parentIndex, int subIndex) {
    setState(() {
      _items[parentIndex]['subItems'].removeAt(subIndex);
    });
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final temp = _items[index];
        _items[index] = _items[index - 1];
        _items[index - 1] = temp;
      });
    }
  }

  void _moveDown(int index) {
    if (index < _items.length - 1) {
      setState(() {
        final temp = _items[index];
        _items[index] = _items[index + 1];
        _items[index + 1] = temp;
      });
    }
  }

  Future<void> _createList() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one list item')),
      );
      return;
    }

    widget.onExecute({
      'title': _titleController.text,
      'items': _items,
      'listType': _isOrdered ? 'ordered' : 'unordered',
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 16),
          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Document Title (Optional)',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // List type toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'List Type',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioGroup<bool>(
                          groupValue: _isOrdered,
                          onChanged: (value) =>
                              setState(() => _isOrdered = value ?? false),
                          child: Column(
                            children: [
                              RadioListTile<bool>(
                                title: const Text('Bulleted'),
                                subtitle: const Text('• Item 1\n• Item 2'),
                                value: false,
                              ),
                              RadioListTile<bool>(
                                title: const Text('Numbered'),
                                subtitle: const Text('1. Item 1\n2. Item 2'),
                                value: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Add item input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingIndex != null
                        ? 'Edit Item #${_editingIndex! + 1}'
                        : 'Add New Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      labelText: 'List item text',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        _editingIndex != null ? Icons.edit : Icons.add,
                      ),
                    ),
                    maxLines: 2,
                    onSubmitted: (_) => _addItem(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: Icon(
                          _editingIndex != null ? Icons.save : Icons.add,
                        ),
                        label: Text(
                          _editingIndex != null ? 'Save' : 'Add Item',
                        ),
                      ),
                      if (_editingIndex != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _editingIndex = null;
                              _itemController.clear();
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List preview
          if (_items.isNotEmpty) ...[
            const Text(
              'List Preview:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minHeight: 100),
                child: _isOrdered
                    ? OrderedListView(
                        items: _items,
                        onEdit: _editItem,
                        onDelete: _removeItem,
                        onMoveUp: _moveUp,
                        onMoveDown: _moveDown,
                        onAddSubItem: _addSubItem,
                        onRemoveSubItem: _removeSubItem,
                      )
                    : UnorderedListView(
                        items: _items,
                        onEdit: _editItem,
                        onDelete: _removeItem,
                        onMoveUp: _moveUp,
                        onMoveDown: _moveDown,
                        onAddSubItem: _addSubItem,
                        onRemoveSubItem: _removeSubItem,
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Create button
          ElevatedButton.icon(
            onPressed: _items.isNotEmpty ? _createList : null,
            icon: const Icon(Icons.format_list_bulleted),
            label: const Text('Create PDF with List'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.format_list_bulleted,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build a clean list',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add bullets or numbered items, then export to PDF.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UnorderedListView extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final Function(int) onMoveUp;
  final Function(int) onMoveDown;
  final Function(int) onAddSubItem;
  final Function(int, int) onRemoveSubItem;

  const UnorderedListView({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddSubItem,
    required this.onRemoveSubItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('• ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    item['text'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 0:
                        onEdit(index);
                        break;
                      case 1:
                        onDelete(index);
                        break;
                      case 2:
                        onMoveUp(index);
                        break;
                      case 3:
                        onMoveDown(index);
                        break;
                      case 4:
                        onAddSubItem(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0, child: Text('Edit')),
                    const PopupMenuItem(value: 1, child: Text('Delete')),
                    const PopupMenuItem(value: 2, child: Text('Move Up')),
                    const PopupMenuItem(value: 3, child: Text('Move Down')),
                    const PopupMenuItem(value: 4, child: Text('Add Sub-item')),
                  ],
                ),
              ],
            ),
            if ((item['subItems'] as List).isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (item['subItems'] as List).asMap().entries.map((
                    subEntry,
                  ) {
                    final subIndex = subEntry.key;
                    final subItem = subEntry.value;
                    return Row(
                      children: [
                        const Text('◦ ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            subItem,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => onRemoveSubItem(index, subIndex),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
}

class OrderedListView extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final Function(int) onMoveUp;
  final Function(int) onMoveDown;
  final Function(int) onAddSubItem;
  final Function(int, int) onRemoveSubItem;

  const OrderedListView({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddSubItem,
    required this.onRemoveSubItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${index + 1}.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item['text'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 0:
                        onEdit(index);
                        break;
                      case 1:
                        onDelete(index);
                        break;
                      case 2:
                        onMoveUp(index);
                        break;
                      case 3:
                        onMoveDown(index);
                        break;
                      case 4:
                        onAddSubItem(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0, child: Text('Edit')),
                    const PopupMenuItem(value: 1, child: Text('Delete')),
                    const PopupMenuItem(value: 2, child: Text('Move Up')),
                    const PopupMenuItem(value: 3, child: Text('Move Down')),
                    const PopupMenuItem(value: 4, child: Text('Add Sub-item')),
                  ],
                ),
              ],
            ),
            if ((item['subItems'] as List).isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (item['subItems'] as List).asMap().entries.map((
                    subEntry,
                  ) {
                    final subIndex = subEntry.key;
                    final subItem = subEntry.value;
                    return Row(
                      children: [
                        const Text('◦ ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            subItem,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => onRemoveSubItem(index, subIndex),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
}
