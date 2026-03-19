# PDF Editor

A Flutter application for viewing, creating, and editing PDF documents on iOS and Android.

## Package ID

- **Android**: `com.getkawai.pdf_editor`
- **iOS**: `com.getkawai.pdfEditor`

## Features

- **View PDFs**: Open and view PDF documents with page navigation
- **Create PDFs from Text**: Create new PDF documents with custom text content
- **Create PDFs from Images**: Convert images to PDF documents
- **Page Navigation**: Jump to specific pages, navigate next/previous
- **Text Selection**: Select and copy text from PDF documents

## Dependencies

- `syncfusion_flutter_pdf` - PDF creation and manipulation
- `syncfusion_flutter_pdfviewer` - PDF viewing
- `file_picker` - File selection for PDFs and images
- `path_provider` - Document storage location
- `permission_handler` - Permission management

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / Xcode for platform-specific development
- Java Development Kit (JDK) for Android builds

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies

### Running the App

```bash
# Run on connected device or emulator
flutter run

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android
```

### Building for Production

```bash
# Build Android APK
flutter build apk --release

# Build iOS app
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
└── screens/
    ├── home_screen.dart         # Home screen with navigation
    ├── pdf_viewer_screen.dart   # PDF viewer screen
    └── pdf_editor_screen.dart   # PDF creation screen
```

## Platform Configuration

### Android

Permissions added to `AndroidManifest.xml`:
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `MANAGE_EXTERNAL_STORAGE`

### iOS

Permissions added to `Info.plist`:
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `NSDocumentsFolderUsageDescription`
- File sharing enabled

## Usage

### Viewing a PDF

1. Launch the app
2. Tap "Open PDF"
3. Select a PDF file from your device
4. Use the navigation controls to browse pages

### Creating a PDF

1. Launch the app
2. Tap "Create New PDF"
3. Choose content type:
   - **Add Text**: Enter document title and content
   - **Add Image**: Select an image from your gallery
   - **Add Signature**: Draw a signature (placeholder)
4. The PDF will be saved to your device's documents folder

## License

This project uses Syncfusion Flutter PDF libraries which require either:
- A Syncfusion commercial license, or
- A Free Syncfusion Community License

See [Syncfusion License](https://www.syncfusion.com/sales/license) for details.

## Support

For issues or feature requests, please file an issue in the repository.
