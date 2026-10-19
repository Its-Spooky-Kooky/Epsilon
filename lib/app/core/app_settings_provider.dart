import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'widget_service.dart';
import 'events_provider.dart';

// -------------------------------------------------------------
// Plugin Appearance (Tag Background & Font Color)
// -------------------------------------------------------------

class PluginColorBundle {
  final Color tagColor;
  final Color textColor;

  const PluginColorBundle({
    required this.tagColor,
    required this.textColor,
  });

  String get tagHex => '#${tagColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  String get textHex => '#${textColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

Color parseHexColor(String hex, Color fallback) {
  try {
    String cleanHex = hex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    return Color(int.parse(cleanHex, radix: 16));
  } catch (_) {
    return fallback;
  }
}

class PluginAppearanceNotifier extends Notifier<Map<String, PluginColorBundle>> {
  static const Map<String, PluginColorBundle> defaults = {
    'cp_contest': PluginColorBundle(
      tagColor: Color(0xFF2979FF), // Blue
      textColor: Color(0xFFFFFFFF), // White
    ),
    'test': PluginColorBundle(
      tagColor: Color(0xFF7C4DFF), // Violet
      textColor: Color(0xFFFFFFFF), // White
    ),
  };

  @override
  Map<String, PluginColorBundle> build() {
    final storage = ref.watch(storageServiceProvider);
    final map = <String, PluginColorBundle>{};
    for (final entry in defaults.entries) {
      final pluginId = entry.key;
      final defaultBundle = entry.value;

      final tagHex = storage.getPluginTagColor(pluginId, defaultHex: defaultBundle.tagHex);
      final textHex = storage.getPluginTextColor(pluginId, defaultHex: defaultBundle.textHex);

      map[pluginId] = PluginColorBundle(
        tagColor: parseHexColor(tagHex, defaultBundle.tagColor),
        textColor: parseHexColor(textHex, defaultBundle.textColor),
      );
    }
    return map;
  }

  PluginColorBundle getColors(String pluginId) {
    if (state.containsKey(pluginId)) {
      return state[pluginId]!;
    }
    final defaultBundle = defaults[pluginId] ??
        const PluginColorBundle(tagColor: Color(0xFF00E5FF), textColor: Color(0xFF000000));

    final storage = ref.read(storageServiceProvider);
    final tagHex = storage.getPluginTagColor(pluginId, defaultHex: defaultBundle.tagHex);
    final textHex = storage.getPluginTextColor(pluginId, defaultHex: defaultBundle.textHex);

    final bundle = PluginColorBundle(
      tagColor: parseHexColor(tagHex, defaultBundle.tagColor),
      textColor: parseHexColor(textHex, defaultBundle.textColor),
    );
    state = {...state, pluginId: bundle};
    return bundle;
  }

  Future<void> setColors(String pluginId, Color tagColor, Color textColor) async {
    final storage = ref.read(storageServiceProvider);
    final bundle = PluginColorBundle(tagColor: tagColor, textColor: textColor);
    await storage.setPluginTagColor(pluginId, bundle.tagHex);
    await storage.setPluginTextColor(pluginId, bundle.textHex);

    state = {...state, pluginId: bundle};

    // Update Android Home Screen widget immediately with new colors
    try {
      final events = ref.read(appEventsProvider).value ?? [];
      await ref.read(widgetServiceProvider).updateCalendarWidgetEvents(
            events,
            ref: ref,
            force: true,
          );
    } catch (_) {}
  }
}

final pluginAppearanceProvider =
    NotifierProvider<PluginAppearanceNotifier, Map<String, PluginColorBundle>>(() {
  return PluginAppearanceNotifier();
});

// -------------------------------------------------------------
// App Theme Mode ('obsidian', 'amoled', 'midnight')
// -------------------------------------------------------------

enum AppThemeMode {
  obsidian('obsidian', 'Deep Obsidian', Color(0xFF0D0D0D), Color(0xFF141414)),
  amoled('amoled', 'AMOLED Pitch Black', Color(0xFF000000), Color(0xFF111111)),
  midnight('midnight', 'Midnight Charcoal', Color(0xFF161616), Color(0xFF1F1F1F));

  final String key;
  final String label;
  final Color backgroundColor;
  final Color surfaceColor;

  const AppThemeMode(this.key, this.label, this.backgroundColor, this.surfaceColor);

  static AppThemeMode fromKey(String key) {
    return AppThemeMode.values.firstWhere(
      (m) => m.key == key,
      orElse: () => AppThemeMode.obsidian,
    );
  }
}

class AppThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    final storage = ref.watch(storageServiceProvider);
    return AppThemeMode.fromKey(storage.getAppTheme(defaultTheme: 'obsidian'));
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setAppTheme(mode.key);
    state = mode;
  }
}

final appThemeNotifierProvider =
    NotifierProvider<AppThemeNotifier, AppThemeMode>(() {
  return AppThemeNotifier();
});

// -------------------------------------------------------------
// App Timezone ('auto', 'UTC', 'IST', 'EST', etc.)
// -------------------------------------------------------------

class TimezoneInfo {
  final String key;
  final String displayName;
  final int offsetMinutes; // Offset from UTC in minutes

  const TimezoneInfo({
    required this.key,
    required this.displayName,
    required this.offsetMinutes,
  });
}

class AppTimezoneState {
  final String timezoneKey;
  final String displayName;
  final int? customOffsetMinutes; // null = device auto

  const AppTimezoneState({
    required this.timezoneKey,
    required this.displayName,
    this.customOffsetMinutes,
  });

  bool get isAuto => timezoneKey == 'auto';
}

class AppTimezoneNotifier extends Notifier<AppTimezoneState> {
  static const List<TimezoneInfo> supportedTimezones = [
    TimezoneInfo(key: 'auto', displayName: 'Device Local (Auto)', offsetMinutes: 0),
    TimezoneInfo(key: 'UTC', displayName: 'UTC / GMT (UTC+00:00)', offsetMinutes: 0),
    TimezoneInfo(key: 'IST', displayName: 'India Standard Time (IST, UTC+05:30)', offsetMinutes: 330),
    TimezoneInfo(key: 'EST', displayName: 'Eastern Standard Time (EST, UTC-05:00)', offsetMinutes: -300),
    TimezoneInfo(key: 'EDT', displayName: 'Eastern Daylight Time (EDT, UTC-04:00)', offsetMinutes: -240),
    TimezoneInfo(key: 'CST', displayName: 'Central Standard Time (CST, UTC-06:00)', offsetMinutes: -360),
    TimezoneInfo(key: 'PST', displayName: 'Pacific Standard Time (PST, UTC-08:00)', offsetMinutes: -480),
    TimezoneInfo(key: 'PDT', displayName: 'Pacific Daylight Time (PDT, UTC-07:00)', offsetMinutes: -420),
    TimezoneInfo(key: 'BST', displayName: 'British Summer Time (BST, UTC+01:00)', offsetMinutes: 60),
    TimezoneInfo(key: 'CET', displayName: 'Central European Time (CET, UTC+01:00)', offsetMinutes: 60),
    TimezoneInfo(key: 'CEST', displayName: 'Central European Summer (CEST, UTC+02:00)', offsetMinutes: 120),
    TimezoneInfo(key: 'JST', displayName: 'Japan Standard Time (JST, UTC+09:00)', offsetMinutes: 540),
    TimezoneInfo(key: 'SGT', displayName: 'Singapore / China (SGT/CST, UTC+08:00)', offsetMinutes: 480),
    TimezoneInfo(key: 'AEST', displayName: 'Australian Eastern Time (AEST, UTC+10:00)', offsetMinutes: 600),
  ];

  @override
  AppTimezoneState build() {
    final storage = ref.watch(storageServiceProvider);
    final key = storage.getAppTimezone(defaultTz: 'auto');
    return _buildState(key);
  }

  AppTimezoneState _buildState(String key) {
    final found = supportedTimezones.firstWhere(
      (tz) => tz.key == key,
      orElse: () => supportedTimezones.first,
    );

    return AppTimezoneState(
      timezoneKey: found.key,
      displayName: found.displayName,
      customOffsetMinutes: found.key == 'auto' ? null : found.offsetMinutes,
    );
  }

  Future<void> setTimezone(String key) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setAppTimezone(key);
    state = _buildState(key);
  }

  /// Converts a UTC or local DateTime to the user's preferred timezone DateTime
  DateTime toTargetTime(DateTime dt) {
    if (state.isAuto || state.customOffsetMinutes == null) {
      return dt.toLocal();
    }

    final utc = dt.isUtc ? dt : dt.toUtc();
    return utc.add(Duration(minutes: state.customOffsetMinutes!));
  }

  String formatTime(DateTime dt, {String pattern = 'hh:mm a'}) {
    final target = toTargetTime(dt);
    return DateFormat(pattern).format(target);
  }

  String formatDate(DateTime dt, {String pattern = 'EEE, MMM d'}) {
    final target = toTargetTime(dt);
    return DateFormat(pattern).format(target);
  }

  String formatHeaderDate(DateTime dt) {
    final target = toTargetTime(dt);
    final nowTarget = toTargetTime(DateTime.now());

    final today = DateTime(nowTarget.year, nowTarget.month, nowTarget.day);
    final comp = DateTime(target.year, target.month, target.day);
    final diff = comp.difference(today).inDays;

    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'TOMORROW';
    return DateFormat('EEEE, MMM d').format(target).toUpperCase();
  }
}

final appTimezoneProvider =
    NotifierProvider<AppTimezoneNotifier, AppTimezoneState>(() {
  return AppTimezoneNotifier();
});

