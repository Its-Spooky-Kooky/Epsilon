import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'plugin_interface.dart';
import 'storage_service.dart';

final deviceAlarmServiceProvider = Provider<DeviceAlarmService>((ref) {
  return DeviceAlarmService();
});

final activeDeviceAlarmIdsProvider =
    NotifierProvider<ActiveDeviceAlarmIdsNotifier, Set<String>>(() {
  return ActiveDeviceAlarmIdsNotifier();
});

class ActiveDeviceAlarmIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getUserAlarmIds();
  }

  Future<bool> toggleAlarm(EventItem event) async {
    final alarmService = ref.read(deviceAlarmServiceProvider);
    final storage = ref.read(storageServiceProvider);
    final current = Set<String>.from(state);

    if (current.contains(event.id)) {
      // User requested to turn off alarm
      await alarmService.cancelAlarm(event.id);
      current.remove(event.id);
      state = current;
      await storage.saveUserAlarmIds(current);
      return false;
    } else {
      // User requested to set alarm (default 5 mins lead)
      final leadMinutes = storage.getAlarmLeadMinutes();
      final success = await alarmService.setAlarmForEvent(event, leadMinutes: leadMinutes);
      if (success) {
        current.add(event.id);
        state = current;
        await storage.saveUserAlarmIds(current);
        return true;
      }
      return false;
    }
  }

  Future<void> reconcileWithAvailableEvents(List<EventItem> availableEvents) async {
    if (availableEvents.isEmpty) return;

    final now = DateTime.now();
    // Only clean up alarms for events that are actually in the past (ended)
    final pastEventIds = availableEvents
        .where((e) => e.endTime.isBefore(now))
        .map((e) => e.id)
        .toSet();

    if (pastEventIds.isNotEmpty) {
      final current = Set<String>.from(state);
      final remaining = current.difference(pastEventIds);
      if (remaining.length != current.length) {
        state = remaining;
        final storage = ref.read(storageServiceProvider);
        await storage.saveUserAlarmIds(remaining);
      }
    }
  }
}

class DeviceAlarmService {
  static const MethodChannel _channel = MethodChannel('com.epsilon.app/device_clock');
  final Map<String, Timer> _webTimers = {};

  DeviceAlarmService();

  /// Calculates the exact trigger time for an event.
  /// If the event begins in less than `leadMinutes` (e.g. 30s test event),
  /// the alarm triggers at `event.startTime`.
  /// Otherwise, it triggers `leadMinutes` before `event.startTime`.
  DateTime calculateAlarmTime(EventItem event, {int leadMinutes = 5}) {
    final now = DateTime.now();
    final leadDuration = Duration(minutes: leadMinutes);
    final diff = event.startTime.difference(now);

    if (diff <= leadDuration) {
      return event.startTime;
    } else {
      return event.startTime.subtract(leadDuration);
    }
  }

  /// Sets an exact alarm using the native Android AlarmManager (or in-memory Timer on web)
  Future<bool> setAlarmForEvent(EventItem event, {int leadMinutes = 5}) async {
    final effectiveAlarmTime = calculateAlarmTime(event, leadMinutes: leadMinutes);
    final epochMillis = effectiveAlarmTime.millisecondsSinceEpoch;
    final title = '${event.platform}: ${event.title}';
    final diffToStart = event.startTime.difference(effectiveAlarmTime);
    final message = diffToStart.inMinutes > 0
        ? 'Contest starts in ${diffToStart.inMinutes} minutes!'
        : 'Contest is starting now!';

    if (kIsWeb) {
      final delay = effectiveAlarmTime.difference(DateTime.now());
      _webTimers[event.id]?.cancel();
      if (!delay.isNegative) {
        _webTimers[event.id] = Timer(delay, () {
          debugPrint('WEB ALARM TRIGGERED: $title - $message');
        });
      }
      return true;
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>('setAlarm', {
        'id': event.id,
        'epochMillis': epochMillis,
        'title': title,
        'message': message,
      });

      return success ?? false;
    } catch (e) {
      debugPrint('Error invoking setAlarm: $e');
      return false;
    }
  }

  /// Cancels an alarm directly in the native Android AlarmManager
  Future<bool> cancelAlarm(String eventId) async {
    if (kIsWeb) {
      _webTimers[eventId]?.cancel();
      _webTimers.remove(eventId);
      return true;
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>('cancelAlarm', {
        'id': eventId,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('Error invoking cancelAlarm: $e');
      return false;
    }
  }
}
