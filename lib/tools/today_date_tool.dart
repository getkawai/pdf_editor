import 'pdf_tool.dart';

class TodayDateTool implements PdfTool {
  @override
  String get id => 'get_today_date';

  @override
  String get name => 'Get Today Date';

  @override
  String get description =>
      'Returns today\'s date. Use this for calendar or scheduling questions.';

  @override
  String get iconName => 'Icons.today';

  @override
  Map<String, String> get parametersSchema => const {};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PdfToolResult> execute(Map<String, dynamic> parameters) async {
    final today = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName = months[today.month - 1];
    final formatted = '${today.day} $monthName ${today.year}';

    return PdfToolResult.success(
      metadata: {'today_date': formatted},
    );
  }
}
