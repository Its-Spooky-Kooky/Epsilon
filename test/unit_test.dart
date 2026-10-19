import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epsilon/app/core/app_settings_provider.dart';
import 'package:epsilon/app/core/device_alarm_service.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'package:epsilon/plugins/cp_contest/series_parser.dart';
import 'package:epsilon/plugins/cp_contest/models/platform_preference.dart';
import 'package:epsilon/plugins/test/test_events_provider.dart';

void main() {
  group('SeriesParser tests', () {
    test('Correctly parses LeetCode contests', () {
      final weekly = SeriesParser.parse('LeetCode', 'Weekly Contest 415');
      expect(weekly.platformId, 'leet_code');
      expect(weekly.series, 'Weekly Contest');

      final biweekly = SeriesParser.parse('LeetCode', 'Biweekly Contest 139');
      expect(biweekly.platformId, 'leet_code');
      expect(biweekly.series, 'Biweekly Contest');
    });

    test('Correctly parses Codeforces divisions', () {
      final div2 = SeriesParser.parse(
        'Codeforces',
        'Codeforces Round 970 (Div. 2)',
      );
      expect(div2.platformId, 'codeforces');
      expect(div2.series, 'Div. 2');

      final div3 = SeriesParser.parse(
        'Codeforces',
        'Codeforces Round 971 (Div. 3)',
      );
      expect(div3.platformId, 'codeforces');
      expect(div3.series, 'Div. 3');

      final div4 = SeriesParser.parse(
        'Codeforces',
        'Codeforces Round 999 (Div. 4)',
      );
      expect(div4.platformId, 'codeforces');
      expect(div4.series, 'Div. 4');

      final edu = SeriesParser.parse(
        'Codeforces',
        'Educational Codeforces Round 170',
      );
      expect(edu.platformId, 'codeforces');
      expect(edu.series, 'Educational Round');
    });

    test('Correctly parses CodeChef series', () {
      final starters = SeriesParser.parse('CodeChef', 'Starters 152');
      expect(starters.platformId, 'code_chef');
      expect(starters.series, 'Starters');
    });

    test('Correctly parses AtCoder series', () {
      final abc = SeriesParser.parse('AtCoder', 'AtCoder Beginner Contest 371');
      expect(abc.platformId, 'at_coder');
      expect(abc.series, 'Beginner Contest (ABC)');
    });
  });

  group('PlatformPreference 2-Level Toggle tests', () {
    test('Disabling platform disables all series', () {
      const pref = PlatformPreference(
        platformId: 'at_coder',
        displayName: 'AtCoder',
        isEnabled: false,
        seriesToggles: {'Beginner Contest (ABC)': true},
      );

      expect(pref.isSeriesEnabled('Beginner Contest (ABC)'), isFalse);
    });

    test('Disabling Div. 4 on Codeforces disables Div. 4 only', () {
      const pref = PlatformPreference(
        platformId: 'codeforces',
        displayName: 'Codeforces',
        isEnabled: true,
        seriesToggles: {'Div. 2': true, 'Div. 4': false},
      );

      expect(pref.isSeriesEnabled('Div. 2'), isTrue);
      expect(pref.isSeriesEnabled('Div. 4'), isFalse);
    });

    test('Enabling platform respects individual series toggles', () {
      const pref = PlatformPreference(
        platformId: 'leet_code',
        displayName: 'LeetCode',
        isEnabled: true,
        seriesToggles: {'Weekly Contest': true, 'Biweekly Contest': false},
      );

      expect(pref.isSeriesEnabled('Weekly Contest'), isTrue);
      expect(pref.isSeriesEnabled('Biweekly Contest'), isFalse);
    });
  });

  group('TestPlugin 30s Timer tests', () {
    test('Generates test events including 30s timer and future dates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events = container.read(testEventsProvider);
      expect(events.length, 3);
      expect(events.first.id, 'test_30s_timer_event');
      expect(events.first.series, '30s Timer');
      expect(events[1].id, 'test_tomorrow_event');
      expect(events[2].id, 'test_future_event');
    });
  });

  group('DeviceAlarmService tests', () {
    test('Calculates 5-minute lead time for regular contests', () {
      final service = DeviceAlarmService();
      final now = DateTime.now();
      final startTime = now.add(const Duration(hours: 2));
      final event = EventItem(
        id: 'contest_1',
        pluginId: 'cp_contest',
        platform: 'LeetCode',
        series: 'Weekly',
        title: 'Weekly Contest 415',
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 2)),
        duration: const Duration(hours: 2),
        url: '',
      );

      final alarmTime = service.calculateAlarmTime(event, leadMinutes: 5);
      final expected = startTime.subtract(const Duration(minutes: 5));
      expect(alarmTime.millisecondsSinceEpoch, expected.millisecondsSinceEpoch);
    });

    test('Preserves exact start time for 30s test event without subtracting into past', () {
      final service = DeviceAlarmService();
      final now = DateTime.now();
      final startTime = now.add(const Duration(seconds: 30));
      final event = EventItem(
        id: 'test_30s',
        pluginId: 'test',
        platform: 'Test',
        series: '30s Timer',
        title: '30s Alarm Test Event',
        startTime: startTime,
        endTime: startTime.add(const Duration(minutes: 5)),
        duration: const Duration(minutes: 5),
        url: '',
      );

      final alarmTime = service.calculateAlarmTime(event, leadMinutes: 5);
      expect(alarmTime.millisecondsSinceEpoch, startTime.millisecondsSinceEpoch);
    });
  });

  group('App Settings & Appearance tests', () {
    test('AppThemeMode keys and labels resolve properly', () {
      expect(AppThemeMode.fromKey('amoled'), AppThemeMode.amoled);
      expect(AppThemeMode.fromKey('midnight'), AppThemeMode.midnight);
      expect(AppThemeMode.fromKey('obsidian'), AppThemeMode.obsidian);
      expect(AppThemeMode.fromKey('unknown'), AppThemeMode.obsidian);
    });

    test('PluginColorBundle hex conversion is accurate', () {
      const bundle = PluginColorBundle(
        tagColor: Color(0xFF00E5FF),
        textColor: Color(0xFF000000),
      );
      expect(bundle.tagHex, '#00E5FF');
      expect(bundle.textHex, '#000000');
    });

    test('parseHexColor handles various hex formats and fallbacks', () {
      expect(parseHexColor('#7C4DFF', Colors.white).toARGB32(), const Color(0xFF7C4DFF).toARGB32());
      expect(parseHexColor('7C4DFF', Colors.white).toARGB32(), const Color(0xFF7C4DFF).toARGB32());
      expect(parseHexColor('invalid', Colors.white).toARGB32(), Colors.white.toARGB32());
    });

    test('AppTimezoneState correctly identifies auto vs custom timezone', () {
      const autoTz = AppTimezoneState(timezoneKey: 'auto', displayName: 'Auto');
      expect(autoTz.isAuto, true);

      const istTz = AppTimezoneState(
        timezoneKey: 'IST',
        displayName: 'India Standard Time',
        customOffsetMinutes: 330,
      );
      expect(istTz.isAuto, false);
      expect(istTz.customOffsetMinutes, 330);
    });
  });
}
