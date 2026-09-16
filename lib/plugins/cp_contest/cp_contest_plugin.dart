import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'package:epsilon/app/core/storage_service.dart';
import 'package:epsilon/app/core/widget_service.dart';

import 'api_service.dart';
import 'models/contest_model.dart';
import 'models/platform_preference.dart';
import 'series_parser.dart';
import 'settings_sheet.dart';

/// Provider for CP API Service
final cpApiServiceProvider = Provider<CpApiService>((ref) => CpApiService());

/// Modern Riverpod Notifier for 2-Level Platform Preferences
final cpPreferencesProvider =
    NotifierProvider<CpPreferencesNotifier, Map<String, PlatformPreference>>(
      () {
        return CpPreferencesNotifier();
      },
    );

class CpPreferencesNotifier extends Notifier<Map<String, PlatformPreference>> {
  @override
  Map<String, PlatformPreference> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getPlatformPreferences();
  }

  /// Level 1: Toggle entire platform on/off
  Future<void> togglePlatform(String platformId, bool isEnabled) async {
    final current = state[platformId];
    if (current == null) return;

    final updated = current.copyWith(isEnabled: isEnabled);
    final newState = Map<String, PlatformPreference>.from(state)
      ..[platformId] = updated;
    state = newState;
    final storage = ref.read(storageServiceProvider);
    await storage.savePlatformPreferences(newState);
    reconcileReminders();
  }

  /// Level 2: Toggle recurring contest series on/off
  Future<void> toggleSeries(
    String platformId,
    String series,
    bool isEnabled,
  ) async {
    final current = state[platformId];
    if (current == null) return;

    final updatedSeriesToggles = Map<String, bool>.from(current.seriesToggles);
    updatedSeriesToggles[series] = isEnabled;

    final updated = current.copyWith(seriesToggles: updatedSeriesToggles);
    final newState = Map<String, PlatformPreference>.from(state)
      ..[platformId] = updated;
    state = newState;
    final storage = ref.read(storageServiceProvider);
    await storage.savePlatformPreferences(newState);
    reconcileReminders();
  }

  void reconcileReminders() {
    ref.invalidate(cpContestsProvider);
  }
}

/// Provider for upcoming 3-week contests
final cpContestsProvider =
    AsyncNotifierProvider<CpContestsNotifier, List<EventItem>>(() {
      return CpContestsNotifier();
    });

class CpContestsNotifier extends AsyncNotifier<List<EventItem>> {
  List<KontestRawItem> _cachedRawContests = [];

  List<EventItem> _filterContests(
    List<EventItem> items,
    Map<String, PlatformPreference> prefs,
  ) {
    return items.where((item) {
      final meta = SeriesParser.parse(item.platform, item.title);
      final platformPref = prefs[meta.platformId];
      if (platformPref == null) return true;
      if (!platformPref.isEnabled) return false;
      return platformPref.isSeriesEnabled(item.series);
    }).toList();
  }

  @override
  Future<List<EventItem>> build() async {
    final storage = ref.watch(storageServiceProvider);
    final prefs = ref.watch(cpPreferencesProvider);
    final cached = storage.getCachedContests();

    if (cached.isNotEmpty) {
      // Filter cached items immediately against active preferences
      final filtered = _filterContests(cached, prefs);
      Future.microtask(() => refreshContests(forceRefresh: false));
      return filtered;
    }
    return _fetchAndProcess(daysAhead: 21);
  }

  Future<List<EventItem>> refreshContests({bool forceRefresh = true}) async {
    state = const AsyncValue.loading();
    try {
      final items = await _fetchAndProcess(
        daysAhead: 21,
        forceRefresh: forceRefresh,
      );
      state = AsyncValue.data(items);
      return items;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  Future<List<EventItem>> _fetchAndProcess({
    int daysAhead = 21,
    bool forceRefresh = false,
  }) async {
    final api = ref.read(cpApiServiceProvider);
    final storage = ref.read(storageServiceProvider);
    final prefs = ref.read(cpPreferencesProvider);
    final widgetService = ref.read(widgetServiceProvider);

    if (_cachedRawContests.isEmpty || forceRefresh) {
      _cachedRawContests = await api.fetchAllContests();
    }

    final now = DateTime.now();
    final horizonEnd = now.add(Duration(days: daysAhead));

    final List<EventItem> allValid = [];

    for (final raw in _cachedRawContests) {
      final startTime = raw.parsedStartTime;
      final endTime = raw.parsedEndTime ?? (startTime?.add(raw.parsedDuration));

      if (startTime == null || endTime == null) continue;
      if (endTime.isBefore(now)) continue;
      if (startTime.isAfter(horizonEnd)) continue;

      final meta = SeriesParser.parse(raw.site, raw.name);

      final id =
          '${meta.platformId}_${raw.name}_${startTime.millisecondsSinceEpoch}'
              .replaceAll(' ', '_');

      allValid.add(
        EventItem(
          id: id,
          pluginId: 'cp_contest',
          platform: meta.platformDisplayName,
          series: meta.series,
          title: raw.name,
          startTime: startTime,
          endTime: endTime,
          duration: raw.parsedDuration,
          url: raw.url,
          isReminderActive: true,
        ),
      );
    }

    allValid.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Persist all 3-week contests so turning a platform back on works offline without re-fetching
    await storage.saveCachedContests(allValid);

    // Filter by user platform and sub-series preferences
    final filtered = _filterContests(allValid, prefs);

    final upcomingList = filtered
        .where((e) => e.status == EventStatus.upcoming)
        .toList();
    await widgetService.updateNextContestWidget(
      upcomingList.isNotEmpty ? upcomingList.first : null,
    );

    return filtered;
  }
}

/// The concrete CP Contest Plugin implementation
class CpContestPlugin implements EpsilonPlugin {
  @override
  String get id => 'cp_contest';

  @override
  String get name => 'CP Contest Reminder';

  @override
  String get description =>
      'Aggregates 3 weeks of contests from LeetCode, Codeforces, CodeChef, and AtCoder with clean series toggles.';

  @override
  String get version => '1.0.0';

  @override
  String get category => 'Coding & Contests';

  @override
  IconData get iconData => Icons.code_rounded;

  @override
  bool get isInstalled => true;

  @override
  void openSettings(BuildContext context) {
    CpPluginSettingsSheet.show(context);
  }

  @override
  Future<List<EventItem>> fetchEvents({
    int daysAhead = 21,
    bool forceRefresh = false,
  }) async {
    return [];
  }
}
