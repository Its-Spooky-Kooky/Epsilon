import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:epsilon/app/core/app_settings_provider.dart';
import 'package:epsilon/app/core/device_alarm_service.dart';
import 'package:epsilon/app/core/plugin_interface.dart';

class TimelineView extends ConsumerWidget {
  final List<EventItem> contests;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const TimelineView({
    super.key,
    required this.contests,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  String _formatDuration(Duration d) {
    if (d.inMinutes == 0) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Text(
            'No upcoming events for this module.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }

    final tzNotifier = ref.watch(appTimezoneProvider.notifier);

    // Group contests by calendar day in target timezone
    final Map<String, List<EventItem>> grouped = {};
    for (final contest in contests) {
      final targetDate = tzNotifier.toTargetTime(contest.startTime);
      final key = DateFormat('yyyy-MM-dd').format(targetDate);
      grouped.putIfAbsent(key, () => []).add(contest);
    }

    final keys = grouped.keys.toList()..sort();
    final activeAlarmIds = ref.watch(activeDeviceAlarmIdsProvider);

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final dayKey = keys[index];
        final dayContests = grouped[dayKey]!;
        final headerText = tzNotifier.formatHeaderDate(dayContests.first.startTime);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Text(
                headerText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white38,
                ),
              ),
            ),
            ...dayContests.map((item) => _buildContestItem(context, ref, item, activeAlarmIds.contains(item.id))),
          ],
        );
      },
    );
  }

  Widget _buildContestItem(BuildContext context, WidgetRef ref, EventItem item, bool isAlarmSet) {
    final tzNotifier = ref.watch(appTimezoneProvider.notifier);
    final timeStr = tzNotifier.formatTime(item.startTime, pattern: 'hh:mm a');
    final durationStr = _formatDuration(item.duration);

    final pluginColors = ref.watch(pluginAppearanceProvider)[item.pluginId] ??
        ref.read(pluginAppearanceProvider.notifier).getColors(item.pluginId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlarmSet
              ? pluginColors.tagColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          onTap: () {
            if (item.url.isNotEmpty) {
              launchUrl(
                Uri.parse(item.url),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pluginColors.tagColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: pluginColors.tagColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  item.platform,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: pluginColors.tagColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.series,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    if (durationStr.isNotEmpty) ...[
                      const Text(' • ', style: TextStyle(color: Colors.white24)),
                      Text(
                        durationStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          trailing: IconButton(
            tooltip: isAlarmSet ? 'Alarm active (tap to cancel)' : 'Set alarm (5m before)',
            icon: Icon(
              isAlarmSet ? Icons.alarm_on : Icons.alarm_add_outlined,
              size: 20,
              color: isAlarmSet ? Colors.tealAccent : Colors.white24,
            ),
            onPressed: () async {
              final set = await ref.read(activeDeviceAlarmIdsProvider.notifier).toggleAlarm(item);
              if (context.mounted) {
                final diff = item.startTime.difference(DateTime.now());
                final message = set
                    ? (diff.inMinutes <= 5
                        ? 'Alarm set for ${DateFormat('h:mm:ss a').format(item.startTime)}'
                        : 'Alarm set for 5 min before contest')
                    : 'Alarm cancelled';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
