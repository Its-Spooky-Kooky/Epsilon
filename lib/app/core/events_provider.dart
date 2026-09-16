import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/device_alarm_service.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'package:epsilon/app/core/storage_service.dart';
import 'package:epsilon/app/core/widget_service.dart';
import 'package:epsilon/plugins/cp_contest/cp_contest_plugin.dart';
import 'package:epsilon/plugins/test/test_events_provider.dart';

/// Provider for installed plugin IDs
final installedPluginsProvider =
    NotifierProvider<InstalledPluginsNotifier, Set<String>>(() {
      return InstalledPluginsNotifier();
    });

class InstalledPluginsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getInstalledPlugins();
  }

  Future<void> togglePlugin(String pluginId) async {
    final storage = ref.read(storageServiceProvider);
    final current = Set<String>.from(state);
    final willInstall = !current.contains(pluginId);
    await storage.setPluginInstalled(pluginId, willInstall);
    state = storage.getInstalledPlugins();
    ref.invalidate(appEventsProvider);
  }
}

/// Unified provider for all events across all installed plugins
final appEventsProvider =
    AsyncNotifierProvider<AppEventsNotifier, List<EventItem>>(() {
      return AppEventsNotifier();
    });

class AppEventsNotifier extends AsyncNotifier<List<EventItem>> {
  @override
  Future<List<EventItem>> build() async {
    final installed = ref.watch(installedPluginsProvider);
    final widgetService = ref.watch(widgetServiceProvider);

    final List<EventItem> combined = [];

    // CP Contest Plugin events
    if (installed.contains('cp_contest')) {
      final cpAsync = ref.watch(cpContestsProvider);
      final cpList = cpAsync.value ?? [];
      combined.addAll(cpList);
    }

    // Test 30s Timer Plugin events
    if (installed.contains('test')) {
      final testList = ref.watch(testEventsProvider);
      combined.addAll(testList);
    }

    // Sort chronologically by start time
    combined.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Reconcile user-enabled device alarms
    await ref
        .read(activeDeviceAlarmIdsProvider.notifier)
        .reconcileWithAvailableEvents(combined);

    // Update Android Home Widget
    final upcoming = combined
        .where((e) => e.status == EventStatus.upcoming)
        .toList();
    await widgetService.updateNextContestWidget(
      upcoming.isNotEmpty ? upcoming.first : null,
    );

    return combined;
  }

  Future<void> refreshAll() async {
    state = const AsyncValue.loading();
    try {
      final installed = ref.read(installedPluginsProvider);
      if (installed.contains('cp_contest')) {
        await ref
            .read(cpContestsProvider.notifier)
            .refreshContests(forceRefresh: true);
      }
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
