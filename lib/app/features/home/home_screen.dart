import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:epsilon/app/core/device_alarm_service.dart';
import 'package:epsilon/app/core/events_provider.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'package:epsilon/plugins/plugin_registry.dart';

import 'alarm_manager_sheet.dart';
import 'plugin_events_screen.dart';
import 'package:epsilon/app/core/app_settings_provider.dart';
import 'package:epsilon/app/features/settings/app_settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(appEventsProvider);
    final installedPluginIds = ref.watch(installedPluginsProvider);
    final allPlugins = ref.watch(pluginRegistryProvider);
    final themeMode = ref.watch(appThemeNotifierProvider);

    final activePlugins = allPlugins
        .where((plugin) => installedPluginIds.contains(plugin.id))
        .toList();

    return Scaffold(
      backgroundColor: themeMode.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeMode.backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'EPSILON',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        actions: [
          _buildAlarmManagerButton(context, ref),
          IconButton(
            tooltip: 'App Settings',
            icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: () async {
          await ref.read(appEventsProvider.notifier).refreshAll();
        },
        child: contestsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          error: (err, stack) => ListView(
            children: [
              const SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: Colors.white38,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load events: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          ref.read(appEventsProvider.notifier).refreshAll(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (allEvents) {
            if (activePlugins.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.extension_off_outlined, color: Colors.white24, size: 48),
                        SizedBox(height: 14),
                        Text(
                          'No plugins installed or active',
                          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Explore the Marketplace tab to enable plugins.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                for (final plugin in activePlugins)
                  _buildPluginModule(context, ref, plugin, allEvents),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPluginModule(
    BuildContext context,
    WidgetRef ref,
    EpsilonPlugin plugin,
    List<EventItem> allEvents,
  ) {
    final moduleEvents =
        allEvents.where((e) => e.pluginId == plugin.id).toList();
    final upcomingList = moduleEvents
        .where((e) =>
            e.status == EventStatus.upcoming || e.status == EventStatus.ongoing)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final nextEvent = upcomingList.isNotEmpty ? upcomingList.first : null;

    final pluginColors = ref.watch(pluginAppearanceProvider)[plugin.id] ??
        ref.read(pluginAppearanceProvider.notifier).getColors(plugin.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PluginEventsScreen(
                  plugin: plugin,
                  events: moduleEvents,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Module Icon, Title, and Chevron Arrow
                Row(
                  children: [
                    Icon(plugin.iconData, size: 16, color: pluginColors.tagColor),
                    const SizedBox(width: 8),
                    Text(
                      plugin.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Colors.white60,
                      ),
                    ),
                    const Spacer(),
                    if (moduleEvents.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${moduleEvents.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.white30,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Next upcoming event (minimal: name and time)
                if (nextEvent != null) ...[
                  Row(
                    children: [
                      if (nextEvent.platform.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: pluginColors.tagColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: pluginColors.tagColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            nextEvent.platform,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: pluginColors.tagColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          nextEvent.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 13, color: Colors.white38),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatEventTiming(nextEvent.startTime, ref),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'No upcoming events',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white30,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatEventTiming(DateTime dt, WidgetRef ref) {
    final tzNotifier = ref.watch(appTimezoneProvider.notifier);
    final now = DateTime.now();
    final diff = dt.difference(now);
    final timeStr = tzNotifier.formatTime(dt, pattern: 'h:mm a');

    final targetDt = tzNotifier.toTargetTime(dt);
    final nowDt = tzNotifier.toTargetTime(now);

    final today = DateTime(nowDt.year, nowDt.month, nowDt.day);
    final eventDate = DateTime(targetDt.year, targetDt.month, targetDt.day);
    final daysDiff = eventDate.difference(today).inDays;

    String dayPrefix;
    if (daysDiff == 0) {
      dayPrefix = 'Today';
    } else if (daysDiff == 1) {
      dayPrefix = 'Tomorrow';
    } else {
      dayPrefix = DateFormat('EEE, MMM d').format(targetDt);
    }

    if (diff.isNegative) {
      return '$dayPrefix at $timeStr (Ongoing)';
    }

    String countdown;
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      countdown = 'in ${diff.inDays}d ${hours}h';
    } else if (diff.inHours > 0) {
      final minutes = diff.inMinutes % 60;
      countdown = 'in ${diff.inHours}h ${minutes}m';
    } else if (diff.inMinutes > 0) {
      countdown = 'in ${diff.inMinutes}m';
    } else {
      countdown = 'starting now';
    }

    return '$dayPrefix, $timeStr • $countdown';
  }

  Widget _buildAlarmManagerButton(BuildContext context, WidgetRef ref) {
    final activeAlarmIds = ref.watch(activeDeviceAlarmIdsProvider);
    final count = activeAlarmIds.length;

    return IconButton(
      tooltip: 'Alarm Manager',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            count > 0 ? Icons.alarm_on : Icons.alarm_outlined,
            color: count > 0 ? Colors.tealAccent : Colors.white60,
            size: 22,
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.tealAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AlarmManagerSheet(),
        );
      },
    );
  }
}
