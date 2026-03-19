# Firebase Analytics Setup Guide

## Overview

Firebase Analytics has been integrated into the PDF Editor app for comprehensive observability. The implementation includes automatic screen tracking and custom event logging for key user actions.

## Architecture

### Analytics Service (`lib/services/analytics_service.dart`)

A centralized singleton service that provides a clean API for logging events throughout the app.

**Key Features:**
- Singleton pattern for easy access
- Type-safe event logging
- Automatic debug logging in development mode
- Error handling to prevent analytics failures from affecting app functionality

## Tracked Events

### PDF Operations
| Event | Parameters | Description |
|-------|-----------|-------------|
| `open_pdf` | `source` | When user opens a PDF file |
| `view_pdf` | `document_id`, `page_count` | When user views a PDF |
| `create_pdf` | - | When user creates a new PDF |
| `edit_pdf` | `edit_type`, `details` | When user edits a PDF (add text, image, etc.) |
| `save_pdf` | `document_id`, `page_count` | When user saves a PDF |

### PDF Tools
| Event | Parameters | Description |
|-------|-----------|-------------|
| `use_pdf_tool` | `tool_name`, `result` | When user uses any PDF tool (merge, compress, etc.) |

### AI/LLM Features
| Event | Parameters | Description |
|-------|-----------|-------------|
| `open_ai_chat` | - | When user opens AI chat screen |
| `ai_message` | `message_type`, `message_length`, `model` | When user sends a message to AI |
| `ai_response` | `response_length`, `latency_ms`, `model` | When AI generates a response |

### Navigation
| Event | Parameters | Description |
|-------|-----------|-------------|
| `screen_view` | `firebase_screen`, `firebase_screen_class` | Automatic screen tracking |
| `open_tools_screen` | - | When user opens tools screen |

### Errors
| Event | Parameters | Description |
|-------|-----------|-------------|
| `error` | `error_type`, `error_message`, `screen` | When an error occurs |

## Usage Examples

### Basic Event Logging

```dart
import '../services/analytics_service.dart';

final AnalyticsService _analytics = AnalyticsService();

// Log a simple event
_analytics.logCreatePdf();

// Log an event with parameters
_analytics.logViewPdf(
  documentId: 'my_document.pdf',
  pageCount: 10,
);

// Log an error
_analytics.logError(
  errorType: 'file_picker_error',
  errorMessage: e.toString(),
  screen: 'home',
);
```

### AI Message Tracking

```dart
// Log user message
_analytics.logAiMessage(
  messageType: 'user',
  messageLength: userMessage.length,
  model: _selectedModel,
);

// Log AI response with latency
final latency = DateTime.now().difference(requestStartTime);
_analytics.logAiResponse(
  responseLength: response.content.length,
  latency: latency,
  model: _selectedModel,
);
```

### PDF Tool Usage

```dart
// Log tool selection
_analytics.logUsePdfTool(toolName: 'merge_pdfs');

// Log tool result
_analytics.logUsePdfTool(
  toolName: 'merge_pdfs',
  result: 'success',
);
```

## Firebase Console Setup

### 1. View Analytics Data

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **pdf-editor-2b696**
3. Navigate to **Analytics > Dashboard**

### 2. Key Reports

- **Events**: View all custom events (open_pdf, create_pdf, etc.)
- **Screens**: Automatic screen view tracking
- **User Engagement**: Session duration, retention, etc.
- **DebugView**: Real-time event testing (enable debug mode)

### 3. Enable Debug Mode

For testing, enable debug mode on your device:

```bash
# iOS Simulator
xcrun simctl launch booted com.example.pdfEditor --firebase-debug

# Android Emulator
adb shell setprop debug.firebase.analytics.app com.example.pdfEditor
```

Or add this to your code during development:

```dart
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
```

## Implementation Details

### Automatic Screen Tracking

The app uses `FirebaseAnalyticsObserver` for automatic screen view tracking:

```dart
// In main.dart
navigatorObservers: _buildNavigatorObservers(),

List<NavigatorObserver> _buildNavigatorObservers() {
  return <NavigatorObserver>[
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
  ];
}
```

### Error Handling

All analytics calls are wrapped in try-catch blocks to prevent analytics failures from affecting app functionality. Debug logs are printed in development mode.

## Privacy Considerations

- No personally identifiable information (PII) is logged
- File paths are not logged (only filenames)
- User IDs can be set for cross-device tracking if needed:
  ```dart
  AnalyticsService().setUserId(userId: 'user123');
  ```

## Future Enhancements

Consider adding:
- Conversion funnels for key user flows
- Custom audiences based on user behavior
- A/B testing integration
- Crashlytics integration (already set up in `main.dart`)

## Troubleshooting

### Events Not Showing Up

1. Check DebugView in Firebase Console
2. Ensure Firebase is properly initialized
3. Verify internet connectivity
4. Check that analytics collection is enabled

### Build Errors

Run `flutter analyze` to check for type errors or API mismatches.

## Dependencies

- `firebase_core: ^3.15.1`
- `firebase_analytics: ^11.4.6`
- `firebase_crashlytics: ^4.3.6`

## Related Files

- `lib/services/analytics_service.dart` - Central analytics service
- `lib/main.dart` - Firebase initialization and observer setup
- `lib/screens/home_screen.dart` - Home screen analytics
- `lib/screens/pdf_viewer_screen.dart` - PDF viewing analytics
- `lib/screens/pdf_editor_screen.dart` - PDF creation/editing analytics
- `lib/screens/llm_chat_screen.dart` - AI chat analytics
- `lib/screens/tools_screen.dart` - PDF tools analytics
