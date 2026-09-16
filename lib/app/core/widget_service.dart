import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'plugin_interface.dart';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

/// Stub widget service — home screen widget support will be added in a future update.
/// For now this is a no-op to keep the architecture in place.
class WidgetService {
  /// Updates the home screen widget with the next upcoming contest details
  Future<void> updateNextContestWidget(EventItem? nextContest) async {
    // TODO: Implement native Android AppWidget in a future version.
    debugPrint('WidgetService: next contest → ${nextContest?.title ?? "none"}');
  }
}
