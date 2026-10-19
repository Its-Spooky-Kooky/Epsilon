import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:epsilon/plugins/cp_contest/models/platform_preference.dart';

import 'plugin_interface.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyPlatformPrefs = 'epsilon_platform_prefs_v1';
  static const String _keyCachedContests = 'epsilon_cached_contests_v1';
  static const String _keyInstalledPlugins = 'epsilon_installed_plugins';
  static const String _keyAlarmLeadMinutes = 'epsilon_alarm_lead_minutes_v1';
  static const String _keyUserAlarmIds = 'epsilon_user_alarm_ids_v1';

  static final Map<String, PlatformPreference> defaultPlatformPrefs = {
    'leet_code': const PlatformPreference(
      platformId: 'leet_code',
      displayName: 'LeetCode',
      isEnabled: true,
      seriesToggles: {'Weekly Contest': true, 'Biweekly Contest': true},
    ),
    'codeforces': const PlatformPreference(
      platformId: 'codeforces',
      displayName: 'Codeforces',
      isEnabled: true,
      seriesToggles: {
        'Div. 1': true,
        'Div. 2': true,
        'Div. 3': true,
        'Div. 4': true,
        'Educational Round': true,
        'Global Round': true,
      },
    ),
    'code_chef': const PlatformPreference(
      platformId: 'code_chef',
      displayName: 'CodeChef',
      isEnabled: true,
      seriesToggles: {'Starters': true, 'Cook-Off': true, 'Lunchtime': true},
    ),
    'at_coder': const PlatformPreference(
      platformId: 'at_coder',
      displayName: 'AtCoder',
      isEnabled: true,
      seriesToggles: {
        'Beginner Contest (ABC)': true,
        'Regular Contest (ARC)': true,
        'Grand Contest (AGC)': true,
      },
    ),
  };

  Map<String, PlatformPreference> getPlatformPreferences() {
    final raw = _prefs.getString(_keyPlatformPrefs);
    if (raw == null) {
      return Map<String, PlatformPreference>.from(defaultPlatformPrefs);
    }
    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      final result = <String, PlatformPreference>{};
      for (final entry in decoded.entries) {
        result[entry.key] = PlatformPreference.fromMap(
          entry.value as Map<String, dynamic>,
        );
      }
      for (final defaultEntry in defaultPlatformPrefs.entries) {
        if (!result.containsKey(defaultEntry.key)) {
          result[defaultEntry.key] = defaultEntry.value;
        }
      }
      return result;
    } catch (_) {
      return Map<String, PlatformPreference>.from(defaultPlatformPrefs);
    }
  }

  Future<void> savePlatformPreferences(
    Map<String, PlatformPreference> prefs,
  ) async {
    final map = prefs.map((key, value) => MapEntry(key, value.toMap()));
    await _prefs.setString(_keyPlatformPrefs, json.encode(map));
  }

  Future<void> updatePlatformPreference(PlatformPreference pref) async {
    final current = getPlatformPreferences();
    current[pref.platformId] = pref;
    await savePlatformPreferences(current);
  }

  List<EventItem> getCachedContests() {
    final raw = _prefs.getString(_keyCachedContests);
    if (raw == null) return [];
    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((item) => EventItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedContests(List<EventItem> contests) async {
    final list = contests.map((c) => c.toJson()).toList();
    await _prefs.setString(_keyCachedContests, json.encode(list));
  }

  Set<String> getInstalledPlugins() {
    final list = _prefs.getStringList(_keyInstalledPlugins);
    return list?.toSet() ?? {'cp_contest', 'test'};
  }

  Future<void> setPluginInstalled(String pluginId, bool installed) async {
    final set = getInstalledPlugins();
    if (installed) {
      set.add(pluginId);
    } else {
      set.remove(pluginId);
    }
    await _prefs.setStringList(_keyInstalledPlugins, set.toList());
  }

  int getAlarmLeadMinutes() {
    return _prefs.getInt(_keyAlarmLeadMinutes) ?? 5;
  }

  Future<void> setAlarmLeadMinutes(int minutes) async {
    await _prefs.setInt(_keyAlarmLeadMinutes, minutes);
  }

  Set<String> getUserAlarmIds() {
    final list = _prefs.getStringList(_keyUserAlarmIds);
    return list?.toSet() ?? <String>{};
  }

  Future<void> saveUserAlarmIds(Set<String> ids) async {
    await _prefs.setStringList(_keyUserAlarmIds, ids.toList());
  }

  // --- Plugin Colors Customization ---
  String getPluginTagColor(String pluginId, {String defaultHex = '#00E5FF'}) {
    return _prefs.getString('epsilon_plugin_${pluginId}_tag_color') ?? defaultHex;
  }

  Future<void> setPluginTagColor(String pluginId, String hex) async {
    await _prefs.setString('epsilon_plugin_${pluginId}_tag_color', hex);
  }

  String getPluginTextColor(String pluginId, {String defaultHex = '#000000'}) {
    return _prefs.getString('epsilon_plugin_${pluginId}_text_color') ?? defaultHex;
  }

  Future<void> setPluginTextColor(String pluginId, String hex) async {
    await _prefs.setString('epsilon_plugin_${pluginId}_text_color', hex);
  }

  // --- App Theme Preference ---
  String getAppTheme({String defaultTheme = 'obsidian'}) {
    return _prefs.getString('epsilon_app_theme') ?? defaultTheme;
  }

  Future<void> setAppTheme(String themeKey) async {
    await _prefs.setString('epsilon_app_theme', themeKey);
  }

  // --- App Timezone Preference ---
  String getAppTimezone({String defaultTz = 'auto'}) {
    return _prefs.getString('epsilon_app_timezone') ?? defaultTz;
  }

  Future<void> setAppTimezone(String timezone) async {
    await _prefs.setString('epsilon_app_timezone', timezone);
  }
}
