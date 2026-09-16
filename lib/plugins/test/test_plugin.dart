import 'package:flutter/material.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'test_settings_sheet.dart';

class TestPlugin implements EpsilonPlugin {
  @override
  String get id => 'test';

  @override
  String get name => 'Test 30s Timer';

  @override
  String get description => 'Simulates a 30-second contest event to verify native alarm triggering.';

  @override
  String get version => '1.0.0';

  @override
  String get category => 'Testing';

  @override
  IconData get iconData => Icons.timer_outlined;

  @override
  bool get isInstalled => true;

  @override
  void openSettings(BuildContext context) {
    TestSettingsSheet.show(context);
  }

  @override
  Future<List<EventItem>> fetchEvents({int daysAhead = 21, bool forceRefresh = false}) async {
    return [];
  }
}
