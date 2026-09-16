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
      current.remove(event.id);
      state = current;
      await storage.saveUserAlarmIds(current);
      // Open device clock so user can review/dismiss
      await alarmService.showAlarms();
      return false;
    } else {
      // User requested to set alarm
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
    final availableIds = availableEvents.map((e) => e.id).toSet();
    final current = Set<String>.from(state);
    final filtered = current.intersection(availableIds);
    if (filtered.length != current.length) {
      state = filtered;
      final storage = ref.read(storageServiceProvider);
      await storage.saveUserAlarmIds(filtered);
    }
  }
}

class DeviceAlarmService {
  static const MethodChannel _channel = MethodChannel('com.epsilon.app/device_clock');

  DeviceAlarmService();

  /// Sets an alarm in the native device Clock application
  Future<bool> setAlarmForEvent(EventItem event, {int leadMinutes = 15}) async {
    if (kIsWeb) {
      debugPrint('Device alarms not supported on web.');
      return false;
    }

    try {
      final alarmTime = event.startTime.subtract(Duration(minutes: leadMinutes));
      final now = DateTime.now();

      // If the alarm time is already in the past, ring in 1 minute or at start time
      final effectiveAlarmTime = alarmTime.isBefore(now) ? event.startTime : alarmTime;

      final title = ': ';

      final bool? success = await _channel.invokeMethod<bool>('setAlarm', {
        'hour': effectiveAlarmTime.hour,
        'minutes': effectiveAlarmTime.minute,
        'title': title,
        'skipUi': true,
      });

      return success ?? false;
    } catch (e) {
      debugPrint('Error invoking setAlarm: ');
      return false;
    }
  }

  /// Opens the device Clock app alarms list
  Future<bool> showAlarms() async {
    if (kIsWeb) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>('showAlarms');
      return success ?? false;
    } catch (e) {
      debugPrint('Error invoking showAlarms: ');
      return false;
    }
  }
}
