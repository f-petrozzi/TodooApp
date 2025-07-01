# Todoo

Todoo is a personal note and task manager built in Swift for iOS. It allows users to quickly add, organize, and complete notes or sub-tasks. The app features offline support with a local SQLite database, AI-powered note generation, Siri integration, and alarm scheduling through Apple Shortcuts.

## Key Features

- Manual and AI-generated note creation
- Subnotes for task nesting
- Completion toggles with visual feedback
- Alarm scheduling using Apple Shortcuts
- Daily automation to manage alarms
- Siri Shortcuts integration for voice commands
- Local storage using SQLite (no login or cloud dependency)
- Modern SwiftUI interface optimized for iOS 18

## Technologies Used

- Swift and SwiftUI
- SQLite via custom `DatabaseManager`
- App Intents for Siri Shortcut support
- OpenAI API for note generation
- Apple Shortcuts for alarm integration
- ISO8601 date formatting for cross-component communication

## How to Run

1. Clone the repository from GitHub.
2. Open the `.xcodeproj` or `.xcworkspace` file in Xcode.
3. Make sure your signing identity is set to your Apple ID (free developer account).
4. Select a physical iPhone running iOS 18 or later.
5. Run the project on your device.
6. For alarm features:
- Set up a Shortcut named `ScheduleNoteAlarm` that accepts `Text` input and creates an iOS alarm.
- Follow in-app instructions to link your alarm shortcut.

> Note: Alarm scheduling only works on real devices due to Apple Shortcuts limitations in the simulator.

## Future Improvements

- Add support for note categories (Today, Future, Recurring, Done)
- Block alarm creation for past times
- Cloud sync across devices using free developer-friendly methods
- Inline editing of notes and time
- UI polish and accessibility enhancements

## What I Learned

Building Todoo helped me learn and apply:

- Integrating a local SQLite database with Swift
- Building a clean SwiftUI interface with multi-view navigation
- Handling App Intents and Siri Shortcuts for custom voice commands
- Scheduling and managing alarms using Apple Shortcuts and x-callback-urls
- Structuring an app around a reactive `ObservableObject` architecture
- Working with APIs and parsing AI-generated content
