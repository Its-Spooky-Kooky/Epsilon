# Epsilon Plugins Directory

Welcome to the **Epsilon Plugins** directory! Epsilon is designed with a completely modular plugin architecture, allowing developers to create custom reminder and event feeds (such as Hackathons, GitHub releases, Internship deadlines, or custom webhooks).

---

## How to Create a New Plugin

### 1. Create your plugin folder
Create a new folder under `lib/plugins/`:
```text
lib/plugins/
├── cp_contest/
└── your_plugin_name/
    ├── your_plugin.dart
    ├── api_service.dart
    └── models/
```

### 2. Implement `EpsilonPlugin`
In your plugin class, implement the standard `EpsilonPlugin` contract:

```dart
import 'package:flutter/material.dart';
import 'package:epsilon/app/core/plugin_interface.dart';

class YourCustomPlugin implements EpsilonPlugin {
  @override
  String get id => 'your_plugin_id';

  @override
  String get name => 'My Custom Reminders';

  @override
  String get description => 'Tracks deadlines for my team.';

  @override
  String get version => '1.0.0';

  @override
  String get category => 'Productivity';

  @override
  IconData get iconData => Icons.work_outline;

  @override
  bool get isInstalled => true;

  @override
  void openSettings(BuildContext context) {
    // Show your custom bottom sheet or settings dialog
  }

  @override
  Future<List<EventItem>> fetchEvents({int daysAhead = 21, bool forceRefresh = false}) async {
    // Fetch and return your upcoming events
    return [];
  }
}
```

### 3. Register your plugin
Open [plugin_registry.dart](plugin_registry.dart) and add your plugin to `registeredPlugins`:

```dart
final registeredPlugins = <EpsilonPlugin>[
  CpContestPlugin(),
  YourCustomPlugin(), // <-- Your plugin is now active!
];
```

The app's **Plugins Marketplace** and **Timeline View** will automatically detect, display, and manage reminders for your plugin!

