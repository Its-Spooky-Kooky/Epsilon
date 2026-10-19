import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/plugin_interface.dart';

final testEventsProvider =
    NotifierProvider<TestEventsNotifier, List<EventItem>>(() {
  return TestEventsNotifier();
});

class TestEventsNotifier extends Notifier<List<EventItem>> {
  Timer? _ticker;

  @override
  List<EventItem> build() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = _generateEvents();
    });
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return _generateEvents();
  }

  static DateTime? _targetTime;

  List<EventItem> _generateEvents() {
    final now = DateTime.now();
    if (_targetTime == null || now.isAfter(_targetTime!.add(const Duration(seconds: 15)))) {
      // Loop or initialize 30-second countdown
      _targetTime = now.add(const Duration(seconds: 30));
    }

    final start = _targetTime!;
    final end = start.add(const Duration(minutes: 5));

    // Test Event 2: Tomorrow at 2:00 PM
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0);

    // Test Event 3: In 5 days at 10:00 AM
    final futureDay = now.add(const Duration(days: 5));
    final futureStart = DateTime(futureDay.year, futureDay.month, futureDay.day, 10, 0);

    return [
      EventItem(
        id: 'test_30s_timer_event',
        pluginId: 'test',
        platform: 'Test',
        series: '30s Timer',
        title: '30s Alarm Test Event',
        startTime: start,
        endTime: end,
        duration: const Duration(minutes: 5),
        url: '',
        isReminderActive: true,
      ),
      EventItem(
        id: 'test_tomorrow_event',
        pluginId: 'test',
        platform: 'Test',
        series: 'Sprint',
        title: 'Test: Code Sprint',
        startTime: tomorrowStart,
        endTime: tomorrowStart.add(const Duration(hours: 2)),
        duration: const Duration(hours: 2),
        url: '',
        isReminderActive: false,
      ),
      EventItem(
        id: 'test_future_event',
        pluginId: 'test',
        platform: 'Test',
        series: 'Hackathon',
        title: 'Test: Hackathon',
        startTime: futureStart,
        endTime: futureStart.add(const Duration(hours: 6)),
        duration: const Duration(hours: 6),
        url: '',
        isReminderActive: false,
      ),
    ];
  }

  void resetTimer() {
    _targetTime = DateTime.now().add(const Duration(seconds: 30));
    state = _generateEvents();
  }
}
