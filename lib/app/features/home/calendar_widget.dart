import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:epsilon/app/core/device_alarm_service.dart';
import 'package:epsilon/app/core/events_provider.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'package:epsilon/plugins/plugin_registry.dart';

Color getPluginColor(String pluginId) {
  switch (pluginId) {
    case 'cp_contest':
      return const Color(0xFF00E5FF); // Vibrant Cyan / Teal
    case 'test':
      return const Color(0xFF7C4DFF); // Deep Purple (matches user's screenshot)
    default:
      return const Color(0xFFFF9100); // Amber / Orange
  }
}

class CalendarWidget extends ConsumerStatefulWidget {
  const CalendarWidget({super.key});

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(appEventsProvider);
    final allEvents = eventsAsync.value ?? [];
    final activeAlarmIds = ref.watch(activeDeviceAlarmIdsProvider);
    final allPlugins = ref.watch(pluginRegistryProvider);
    final installedPluginIds = ref.watch(installedPluginsProvider);
    final activePlugins = allPlugins
        .where((p) => installedPluginIds.contains(p.id))
        .toList();

    // Group events by yyyy-MM-dd
    final Map<String, List<EventItem>> eventsByDay = {};
    for (final event in allEvents) {
      final key = DateFormat('yyyy-MM-dd').format(event.startTime);
      eventsByDay.putIfAbsent(key, () => []).add(event);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Days in current month
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    // Weekday: Monday is 1, Sunday is 7
    final leadingDays = firstDayOfMonth.weekday - 1;
    final prevMonthDays = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    final totalCells = ((leadingDays + daysInMonth) / 7).ceil() * 7;

    final selectedDateKey = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : null;
    final selectedDayEvents = selectedDateKey != null
        ? (eventsByDay[selectedDateKey] ?? [])
        : <EventItem>[];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: Navigation (< MONTH >) & Today Jump Button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                      onPressed: _prevMonth,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Previous Month',
                    ),
                    Text(
                      DateFormat('MMM').format(_currentMonth).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                      onPressed: _nextMonth,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Next Month',
                    ),
                  ],
                ),
                // Today Button: rounded badge like [19] in screenshot
                InkWell(
                  onTap: _jumpToToday,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white38, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${now.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Weekdays Header: M T W T F S S (Sunday in Red)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: const [
                _WeekdayLabel('M'),
                _WeekdayLabel('T'),
                _WeekdayLabel('W'),
                _WeekdayLabel('T'),
                _WeekdayLabel('F'),
                _WeekdayLabel('S'),
                _WeekdayLabel('S', isSunday: true),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // 3. Days Grid (7 Columns)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 3,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                DateTime cellDate;
                bool isCurrentMonth = false;

                if (index < leadingDays) {
                  // Previous month leading days
                  final dayNum = prevMonthDays - leadingDays + 1 + index;
                  cellDate = DateTime(_currentMonth.year, _currentMonth.month - 1, dayNum);
                } else if (index < leadingDays + daysInMonth) {
                  // Current month days
                  final dayNum = index - leadingDays + 1;
                  cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                  isCurrentMonth = true;
                } else {
                  // Next month trailing days
                  final dayNum = index - (leadingDays + daysInMonth) + 1;
                  cellDate = DateTime(_currentMonth.year, _currentMonth.month + 1, dayNum);
                }

                final dayKey = DateFormat('yyyy-MM-dd').format(cellDate);
                final dayEvents = eventsByDay[dayKey] ?? [];

                final isToday = cellDate.year == today.year &&
                    cellDate.month == today.month &&
                    cellDate.day == today.day;
                final isSelected = _selectedDate != null &&
                    cellDate.year == _selectedDate!.year &&
                    cellDate.month == _selectedDate!.month &&
                    cellDate.day == _selectedDate!.day;
                final isSunday = cellDate.weekday == DateTime.sunday;

                // Color calculation for day number
                Color dateColor;
                if (!isCurrentMonth) {
                  dateColor = isSunday
                      ? Colors.redAccent.withValues(alpha: 0.35)
                      : Colors.white24;
                } else if (isSunday) {
                  dateColor = Colors.redAccent;
                } else {
                  dateColor = Colors.white;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Colors.white, width: 1.4)
                          : isSelected
                              ? Border.all(color: Colors.tealAccent.withValues(alpha: 0.5), width: 1)
                              : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Date Number
                        Text(
                          '${cellDate.day}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                            color: dateColor,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Event Chips (colored by plugin)
                        if (dayEvents.isNotEmpty) ...[
                          for (final event in dayEvents.take(1))
                            _buildEventChip(event),
                          if (dayEvents.length > 1)
                            Container(
                              margin: const EdgeInsets.only(top: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final extra in dayEvents.skip(1).take(2))
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: getPluginColor(extra.pluginId),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Plugin Color Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final plugin in activePlugins)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: getPluginColor(plugin.id),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        plugin.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 5. Selected Day Events Preview
          if (selectedDayEvents.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                DateFormat('EEEE, MMM d').format(_selectedDate!).toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white38,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              itemCount: selectedDayEvents.length,
              itemBuilder: (context, idx) {
                final ev = selectedDayEvents[idx];
                final isAlarm = activeAlarmIds.contains(ev.id);
                final pluginColor = getPluginColor(ev.pluginId);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B1B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: pluginColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pluginColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ev.platform,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: pluginColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ev.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(ev.startTime),
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isAlarm ? 'Cancel Alarm' : 'Set Alarm (5m before)',
                        icon: Icon(
                          isAlarm ? Icons.alarm_on : Icons.alarm_add_outlined,
                          size: 18,
                          color: isAlarm ? Colors.tealAccent : Colors.white38,
                        ),
                        onPressed: () async {
                          final set = await ref
                              .read(activeDeviceAlarmIdsProvider.notifier)
                              .toggleAlarm(ev);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(set ? 'Alarm set for 5m before' : 'Alarm cancelled'),
                                duration: const Duration(seconds: 2),
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
          ],
        ],
      ),
    );
  }

  Widget _buildEventChip(EventItem event) {
    final color = getPluginColor(event.pluginId);

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications, size: 7, color: Colors.white),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  final bool isSunday;

  const _WeekdayLabel(this.label, {this.isSunday = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isSunday ? Colors.redAccent : Colors.white70,
          ),
        ),
      ),
    );
  }
}

