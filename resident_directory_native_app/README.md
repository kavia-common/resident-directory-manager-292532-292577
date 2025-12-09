# Resident Directory Native App

An offline-first resident directory Flutter app (MVP) with:
- Residents list with search and filter
- Resident detail view
- Add/edit resident form with basic validation
- Local storage using SharedPreferences (offline-first)
- Ocean Professional theme (modern, clean UI with subtle shadows and rounded corners)
- Basic navigation and state management
- Mock seed data on first run

## Getting Started

Prerequisites:
- Flutter SDK (3.3+)
- Dart SDK as part of Flutter

Install dependencies:
```
flutter pub get
```

Run:
```
flutter run
```

Platforms: Android, iOS, Web (for preview in supported environments)

## Project Structure
```
lib/
  main.dart                 # Entry point with theme and routes
  theme/
    app_theme.dart         # Ocean Professional theme
  models/
    resident.dart          # Resident model and helpers
  storage/
    resident_storage.dart  # Local storage (SharedPreferences)
  providers/
    resident_provider.dart # In-memory state + persistence bridge
  screens/
    home_screen.dart       # Residents list + search/filter
    resident_detail_screen.dart
    resident_form_screen.dart
  widgets/
    resident_card.dart     # List item widget
    search_bar.dart        # Search input
```

## Notes
- Storage uses JSON in SharedPreferences. This is sufficient for MVP; future iterations may switch to SQLite if needed.
- No external services are used.
- Theme colors follow the Ocean Professional style guide.

## Linting
This project uses `flutter_lints`. Please follow Effective Dart.

