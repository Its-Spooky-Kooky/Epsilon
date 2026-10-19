import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'plugin_interface.dart';
import 'app_settings_provider.dart';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.epsilon.app/device_clock');
  String? _lastJson;

  /// Updates the Android home screen calendar AppWidget with all active events
  Future<void> updateCalendarWidgetEvents(
    List<EventItem> events, {
    dynamic ref,
    bool force = false,
  }) async {
    if (kIsWeb) return;

    try {
      final list = events.map((e) {
        String tagColor = e.pluginId == 'test' ? '#7C4DFF' : '#2979FF';
        String textColor = '#FFFFFF';

        if (ref != null) {
          try {
            final bundle = ref.read(pluginAppearanceProvider.notifier).getColors(e.pluginId);
            tagColor = bundle.tagHex;
            textColor = bundle.textHex;
          } catch (_) {}
        }

        return {
          'id': e.id,
          'pluginId': e.pluginId,
          'platform': e.platform,
          'title': e.title,
          'startTime': e.startTime.toIso8601String(),
          'endTime': e.endTime.toIso8601String(),
          'tagColor': tagColor,
          'textColor': textColor,
        };
      }).toList();

      final eventsJson = jsonEncode(list);
      if (eventsJson == _lastJson && !force) return;
      _lastJson = eventsJson;

      await _channel.invokeMethod('updateWidgetEvents', {
        'eventsJson': eventsJson,
      });
      debugPrint('WidgetService: Updated ${events.length} events to Calendar AppWidget');
    } catch (e) {
      debugPrint('WidgetService error updating widget: $e');
    }
  }

  /// Backward compatible helper
  Future<void> updateNextContestWidget(EventItem? nextContest) async {
    debugPrint('WidgetService: next contest → ${nextContest?.title ?? "none"}');
  }
}
