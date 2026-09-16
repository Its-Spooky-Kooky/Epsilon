import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:epsilon/app/core/device_alarm_service.dart';
import 'package:epsilon/app/core/plugin_interface.dart';

class TimelineView extends ConsumerWidget {
  final List<EventItem> contests;

  const TimelineView({
    super.key,
    required this.contests,
  });

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'TOMORROW';
    return DateFormat('EEEE, MMM d').format(dt).toUpperCase();
  }

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
          padding: EdgeInsets.all(40.0),
          child: Text(
            'No upcoming contests found for the next 3 weeks.',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }

    // Group contests by calendar day
    final Map<String, List<EventItem>> grouped = {};
    for (final contest in contests) {
      final key = DateFormat('yyyy-MM-dd').format(contest.startTime);
      grouped.putIfAbsent(key, () => []).add(contest);
    }

    final keys = grouped.keys.toList()..sort();
    final activeAlarmIds = ref.watch(activeDeviceAlarmIdsProvider);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final dayKey = keys[index];
        final dayContests = grouped[dayKey]!;
        final headerText = _formatDateHeader(dayContests.first.startTime);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              child: Text(
                headerText,
                style: const TextStyle(
                  fontSize: 11,
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
    final timeStr = DateFormat('hh:mm a').format(item.startTime);
    final durationStr = _formatDuration(item.duration);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlarmSet
              ? Colors.tealAccent.withValues(alpha: 0.2)
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
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.platform,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
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
          tooltip: isAlarmSet ? 'Alarm Set (tap to toggle/manage)' : 'Set Alarm in Clock app',
          icon: Icon(
            isAlarmSet ? Icons.alarm_on : Icons.alarm_add_outlined,
            size: 20,
            color: isAlarmSet ? Colors.tealAccent : Colors.white24,
          ),
          onPressed: () async {
            final set = await ref.read(activeDeviceAlarmIdsProvider.notifier).toggleAlarm(item);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(set ? 'Alarm set in Clock app' : 'Alarm unmarked (manage in Clock)'),
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
