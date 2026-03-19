import 'package:flutter/material.dart';
import '../../tools/tools.dart';
import '../../services/analytics_service.dart';

/// Widget for visual table editor UI
class TableEditorWidget extends StatefulWidget {
  final PdfTool tool;
  final AnalyticsService analytics;
  final Function(Map<String, dynamic>) onExecute;

  const TableEditorWidget({
    super.key,
    required this.tool,
    required this.analytics,
    required this.onExecute,
  });

  @override
  State<TableEditorWidget> createState() => _TableEditorWidgetState();
}

class _TableEditorWidgetState extends State<TableEditorWidget> {
  final List<List<String>> _tableData = [
    ['Header 1', 'Header 2', 'Header 3', 'Header 4'],
    ['Row 1, Col 1', 'Row 1, Col 2', 'Row 1, Col 3', 'Row 1, Col 4'],
    ['Row 2, Col 1', 'Row 2, Col 2', 'Row 2, Col 3', 'Row 2, Col 4'],
  ];
  int _selectedRow = 0;
  int _selectedCol = 0;
  bool _hasHeader = true;
  final TextEditingController _titleController = TextEditingController();
  String _selectedStyle = 'listtable4';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _tableData.add(List.generate(_tableData.first.length, (_) => ''));
    });
  }

  void _removeRow() {
    if (_tableData.length > 1) {
      setState(() {
        _tableData.removeAt(_selectedRow);
        if (_selectedRow >= _tableData.length) {
          _selectedRow = _tableData.length - 1;
        }
      });
    }
  }

  void _addCol() {
    setState(() {
      for (var row in _tableData) {
        row.add('');
      }
    });
  }

  void _removeCol() {
    if (_tableData.first.length > 1) {
      setState(() {
        for (var row in _tableData) {
          row.removeAt(_selectedCol);
        }
        if (_selectedCol >= _tableData.first.length) {
          _selectedCol = _tableData.first.length - 1;
        }
      });
    }
  }

  void _updateCell(String value) {
    setState(() {
      _tableData[_selectedRow][_selectedCol] = value;
    });
  }

  Future<void> _createTable() async {
    final headers = _hasHeader && _tableData.isNotEmpty ? _tableData.first : null;
    final data = _hasHeader && _tableData.length > 1 
        ? _tableData.sublist(1) 
        : _tableData;

    widget.onExecute({
      'title': _titleController.text,
      'headers': headers,
      'data': data,
      'style': _selectedStyle,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title input
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Table Title (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // Options row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStyle,
                  decoration: const InputDecoration(
                    labelText: 'Style',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'listtable1', child: Text('Style 1')),
                    DropdownMenuItem(value: 'listtable2', child: Text('Style 2')),
                    DropdownMenuItem(value: 'listtable3', child: Text('Style 3')),
                    DropdownMenuItem(value: 'listtable4', child: Text('Style 4 (Default)')),
                  ],
                  onChanged: (value) => setState(() => _selectedStyle = value ?? 'listtable4'),
                ),
              ),
              const SizedBox(width: 16),
              SwitchListTile(
                title: const Text('Has Header'),
                value: _hasHeader,
                onChanged: (value) => setState(() => _hasHeader = value),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table controls
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add),
                label: const Text('Add Row'),
              ),
              ElevatedButton.icon(
                onPressed: _tableData.length > 1 ? _removeRow : null,
                icon: const Icon(Icons.remove),
                label: const Text('Remove Row'),
              ),
              ElevatedButton.icon(
                onPressed: _addCol,
                icon: const Icon(Icons.add),
                label: const Text('Add Column'),
              ),
              ElevatedButton.icon(
                onPressed: _tableData.first.length > 1 ? _removeCol : null,
                icon: const Icon(Icons.remove),
                label: const Text('Remove Column'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table preview
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  _hasHeader ? Colors.blue.shade100 : Colors.grey.shade200,
                ),
                columns: List.generate(
                  _tableData.first.length,
                  (colIndex) => DataColumn(
                    label: SizedBox(
                      width: 120,
                      child: Text(
                        _hasHeader && colIndex < _tableData.first.length
                            ? _tableData[0][colIndex]
                            : 'Col ${colIndex + 1}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                rows: List.generate(
                  _hasHeader ? _tableData.length - 1 : _tableData.length,
                  (rowIndex) {
                    final actualRowIndex = _hasHeader ? rowIndex + 1 : rowIndex;
                    return DataRow(
                      selected: actualRowIndex == _selectedRow,
                      onSelectChanged: (selected) {
                        setState(() => _selectedRow = actualRowIndex);
                      },
                      cells: List.generate(
                        _tableData.first.length,
                        (colIndex) => DataCell(
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRow = actualRowIndex;
                                _selectedCol = colIndex;
                              });
                              _showEditCellDialog();
                            },
                            child: SizedBox(
                              width: 120,
                              child: Text(
                                _tableData[actualRowIndex][colIndex],
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selected cell editor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Cell: Row ${_selectedRow + 1}, Col ${_selectedCol + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cell Content',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateCell,
                    controller: TextEditingController(
                      text: _tableData[_selectedRow][_selectedCol],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Create button
          ElevatedButton.icon(
            onPressed: _createTable,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Create PDF Table'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCellDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Cell (${_selectedRow + 1}, ${_selectedCol + 1})'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Cell Content',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(
            text: _tableData[_selectedRow][_selectedCol],
          ),
          onChanged: _updateCell,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
