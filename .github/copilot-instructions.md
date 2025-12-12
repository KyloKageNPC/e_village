# AI Coding Agent Instructions for E-Village Banking Application

## Overview
This document provides essential guidelines for AI coding agents working on the E-Village Banking Application. The project is a Flutter-based application with a focus on village banking, financial tools, and user experience enhancements. The following instructions will help AI agents navigate the codebase, understand its architecture, and follow project-specific conventions.

---

## Project Architecture

### Key Components
1. **Frontend (Flutter)**
   - Located in the `lib/` directory.
   - Contains screens, widgets, models, providers, and services.
   - Example files:
     - `lib/main.dart`: Entry point of the application.
     - `lib/screens/`: Contains UI screens (e.g., `group_chat_screen.dart`).
     - `lib/services/`: Handles business logic and external integrations.

2. **Backend (Supabase)**
   - Database schema files are in the root directory (e.g., `supabase_schema.sql`).
   - Supabase is used for authentication, storage, and database operations.

3. **Platform-Specific Code**
   - Android: `android/`
   - iOS: `ios/`
   - Linux: `linux/`
   - macOS: `macos/`
   - Windows: `windows/`

4. **Testing**
   - Tests are located in the `test/` directory.
   - Example: `test/widget_test.dart`.

---

## Developer Workflows

### Building the Project
- Use `flutter pub get` to fetch dependencies.
- Run the app with `flutter run`.

### Testing
- Execute tests with `flutter test`.
- Ensure all widgets and services are covered.

### Debugging
- Use `flutter analyze` to identify issues.
- Use `flutter doctor` to verify the environment setup.

---

## Project-Specific Conventions

### Naming Conventions
- Use `snake_case` for file names (e.g., `group_chat_screen.dart`).
- Use `CamelCase` for class names (e.g., `GroupChatScreen`).
- Use `lowerCamelCase` for variables and methods (e.g., `fetchData`).

### State Management
- The project uses the `provider` package for state management.
- Example:
  ```dart
  ChangeNotifierProvider(
    create: (context) => ChatProvider(),
    child: GroupChatScreen(),
  );
  ```

### Database Integration
- SQL scripts for schema updates are in the root directory (e.g., `add_chat_tables.sql`).
- Follow the naming convention: `action_table_description.sql`.

---

## Integration Points

### External Dependencies
- **Supabase**: Used for backend services.
- **Firebase**: Used for push notifications.
- **Flutterwave**: Planned for mobile money integration.

### Communication Patterns
- Use `services/` for API calls and business logic.
- Use `providers/` for state management and data sharing.

---

## Examples

### Adding a New Feature
1. Create a new screen in `lib/screens/`.
2. Add state management logic in `lib/providers/`.
3. Implement business logic in `lib/services/`.
4. Update `pubspec.yaml` if new dependencies are required.

### Example: Adding Reactions to Chat Messages
```dart
void _showReactionPicker(String messageId) {
  showModalBottomSheet(
    context: context,
    builder: (context) => ReactionPicker(
      onEmojiSelected: (emoji) async {
        await chatProvider.addReaction(
          messageId: messageId,
          emoji: emoji,
        );
      },
    ),
  );
}
```

---

## Key Files and Directories
- `lib/main.dart`: Application entry point.
- `lib/screens/`: UI screens.
- `lib/services/`: Business logic.
- `lib/providers/`: State management.
- `supabase_schema.sql`: Database schema.
- `pubspec.yaml`: Dependency management.

---

## Additional Notes
- Refer to `PHASE_2_PLAN.md` for detailed implementation steps and priorities.
- Follow the timeline and success metrics outlined in the plan.
- Ensure all code is well-documented and tested.

---

## Questions or Issues
- Check the documentation in the `docs/` directory.
- Review code comments for guidance.
- Open a GitHub issue if further clarification is needed.