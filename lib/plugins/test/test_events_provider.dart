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
      state = _generateSingleEvent();
    });
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return _generateSingleEvent();
  }

  static DateTime? _targetTime;

  List<EventItem> _generateSingleEvent() {
    final now = DateTime.now();
    if (_targetTime == null || now.isAfter(_targetTime!.add(const Duration(seconds: 15)))) {
      // Loop or initialize 30-second countdown
      _targetTime = now.add(const Duration(seconds: 30));
    }

    final start = _targetTime!;
    final end = start.add(const Duration(minutes: 5));

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
    ];
  }

  void resetTimer() {
    _targetTime = DateTime.now().add(const Duration(seconds: 30));
    state = _generateSingleEvent();
  }
}
