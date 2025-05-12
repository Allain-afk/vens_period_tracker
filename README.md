# Ven's Period Tracker

A simple and user-friendly app to help individuals track their menstrual cycles, similar in functionality to the Flo app.

## Features

- **Cycle Tracking**: Log start/end of periods, symptoms, mood, and flow intensity
- **Predictions**: Automatically predicts future periods, fertile windows, and ovulation
- **Calendar View**: Visual timeline of cycles and important dates
- **Reminders**: Custom notifications for upcoming periods or fertile days
- **Health Insights**: General tips and cycle insights
- **Data Backup**: Local storage with Hive

## Screenshots

*Screenshots will be added after the app is built*

## Tech Stack

- **Framework**: Flutter (Dart)
- **Local Storage**: Hive
- **UI Libraries**: Material Design
- **Notifications**: flutter_local_notifications
- **State Management**: Provider

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter extensions
- Android or iOS device/emulator

### Installation

1. Clone this repository
   ```
   git clone https://github.com/yourusername/vens_period_tracker.git
   ```

2. Navigate to the project directory
   ```
   cd vens_period_tracker
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Generate Hive adapters
   ```
   flutter pub run build_runner build
   ```

5. Run the app
   ```
   flutter run
   ```

## Usage

### First Time Setup

1. Open the app and you'll be logged in as a guest automatically
2. Navigate to the Profile screen to update your name
3. Use the "+" button to add your first period data
4. The app will start making predictions after you've added at least one period

### Regular Usage

- **Calendar View**: The main screen shows a calendar with all your period and fertility data
- **Add Period**: Tap the "+" button to log a new period
- **View Insights**: Navigate to the Insights tab to see statistics and patterns
- **Profile**: Update your name and view your cycle information

## Privacy

All your data is stored locally on your device and is not shared with anyone.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 