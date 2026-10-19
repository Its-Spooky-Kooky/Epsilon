import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:epsilon/app/core/device_alarm_service.dart';
import 'package:epsilon/app/core/events_provider.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'package:epsilon/app/core/storage_service.dart';

class AlarmManagerSheet extends ConsumerWidget {
  const AlarmManagerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlarmIds = ref.watch(activeDeviceAlarmIdsProvider);
    final eventsAsync = ref.watch(appEventsProvider);
    final storage = ref.watch(storageServiceProvider);
    final alarmService = ref.watch(deviceAlarmServiceProvider);
    final leadMinutes = storage.getAlarmLeadMinutes();

    // Pool events from live provider and cached storage
    final List<EventItem> pool = [
      ...eventsAsync.value ?? [],
      ...storage.getCachedContests(),
    ];
    final Map<String, EventItem> uniqueMap = {for (final e in pool) e.id: e};

    // Filter to only events that have active alarms
    final List<EventItem> scheduledEvents = activeAlarmIds
        .map((id) => uniqueMap[id])
        .whereType<EventItem>()
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alarm_on, color: Colors.tealAccent, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'ALARM MANAGER',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activeAlarmIds.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.tealAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                if (activeAlarmIds.isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      for (final event in scheduledEvents) {
                        await ref
                            .read(activeDeviceAlarmIdsProvider.notifier)
                            .toggleAlarm(event);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All alarms cancelled'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),

          // Alarms List or Empty State
          Flexible(
            child: scheduledEvents.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alarm_off_outlined,
                            size: 42,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'No active alarms',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tap the alarm bell icon on any contest to schedule a 5-minute reminder.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: scheduledEvents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = scheduledEvents[index];
                      final alarmTime = alarmService.calculateAlarmTime(
                        item,
                        leadMinutes: leadMinutes,
                      );
                      final timeRemaining = alarmTime.difference(DateTime.now());

                      String timeRemainingStr;
                      if (timeRemaining.isNegative) {
                        timeRemainingStr = 'Fired / Starting now';
                      } else if (timeRemaining.inDays > 0) {
                        timeRemainingStr = 'in ${timeRemaining.inDays}d ${timeRemaining.inHours % 24}h';
                      } else if (timeRemaining.inHours > 0) {
                        timeRemainingStr = 'in ${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m';
                      } else if (timeRemaining.inMinutes > 0) {
                        timeRemainingStr = 'in ${timeRemaining.inMinutes}m';
                      } else {
                        timeRemainingStr = 'in ${timeRemaining.inSeconds}s';
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1B1B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.tealAccent.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Platform Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.tealAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.platform,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.tealAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Contest Name & Ring Time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.alarm,
                                        size: 12,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${DateFormat('MMM d, h:mm a').format(alarmTime)} • $timeRemainingStr',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Delete / Cancel Alarm Button
                            IconButton(
                              tooltip: 'Cancel Alarm',
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(activeDeviceAlarmIdsProvider.notifier)
                                    .toggleAlarm(item);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Alarm cancelled'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
