import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flutter_ai_toolkit/src/styles/chat_input_style.dart';
import '../flutter_ai_toolkit/src/styles/llm_chat_view_style.dart';
import '../flutter_ai_toolkit/src/styles/llm_message_style.dart';
import '../flutter_ai_toolkit/src/styles/suggestion_style.dart';
import '../flutter_ai_toolkit/src/styles/user_message_style.dart';

class AppTheme {
  static const Color _seed = Color(0xFF0D9488);
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _surfaceTint = Color(0xFFF8FAFC);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.light,
      ).copyWith(
        primary: _seed,
        secondary: _accent,
        surface: const Color(0xFFF7F7F5),
        surfaceContainerHighest: const Color(0xFFF0F2EF),
        surfaceTint: _surfaceTint,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      scaffoldBackgroundColor: const Color(0xFFF7F7F5),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _seed.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontWeight: FontWeight.w600);
            }
            return null;
          },
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      scaffoldBackgroundColor: const Color(0xFF0F1211),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF151A19),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2221),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _seed.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontWeight: FontWeight.w600);
            }
            return null;
          },
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2B2F2E),
        thickness: 1,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final headline = GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
    );
    final body = GoogleFonts.inter(
      fontWeight: FontWeight.w400,
    );

    return base.copyWith(
      headlineLarge: headline.copyWith(fontSize: 34),
      headlineMedium: headline.copyWith(fontSize: 28),
      titleLarge: headline.copyWith(fontSize: 22),
      titleMedium: headline.copyWith(fontSize: 18),
      titleSmall: headline.copyWith(fontSize: 16),
      bodyLarge: body.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: body.copyWith(fontSize: 14, height: 1.4),
      bodySmall: body.copyWith(fontSize: 12, height: 1.4),
      labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: body.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }

  static LlmChatViewStyle chatStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outline = colorScheme.outlineVariant;
    final surface = colorScheme.surface;
    final surfaceAlt = colorScheme.surfaceContainerHighest;

    return LlmChatViewStyle(
      backgroundColor: surface,
      menuColor: surface,
      progressIndicatorColor: colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      messageSpacing: 8,
      userMessageStyle: UserMessageStyle(
        textStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      llmMessageStyle: LlmMessageStyle(
        icon: Icons.smart_toy,
        iconColor: colorScheme.primary,
        iconDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        decoration: BoxDecoration(
          color: surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outline),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      chatInputStyle: ChatInputStyle(
        textStyle: theme.textTheme.bodyMedium,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.hintColor,
        ),
        hintText: 'Tulis pesan...',
        backgroundColor: surface,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: outline),
        ),
      ),
      suggestionStyle: SuggestionStyle(
        textStyle: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outline),
        ),
      ),
    );
  }
}
