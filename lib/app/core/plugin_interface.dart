import 'package:flutter/material.dart';

/// Supported event statuses
enum EventStatus { upcoming, ongoing, past }

/// Universal Event Item representing an upcoming deadline or event.
@immutable
class EventItem {
  final String id;
  final String pluginId;
  final String platform; // e.g. 'LeetCode', 'Codeforces', 'CodeChef', 'AtCoder'
  final String series; // e.g. 'Weekly Contest', 'Div. 2', 'Starters'
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String url;
  final bool isReminderActive;

  const EventItem({
    required this.id,
    required this.pluginId,
    required this.platform,
    required this.series,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.url,
    this.isReminderActive = false,
  });

  EventStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return EventStatus.upcoming;
    if (now.isAfter(endTime)) return EventStatus.past;
    return EventStatus.ongoing;
  }

  EventItem copyWith({
    String? id,
    String? pluginId,
    String? platform,
    String? series,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? url,
    bool? isReminderActive,
  }) {
    return EventItem(
      id: id ?? this.id,
      pluginId: pluginId ?? this.pluginId,
      platform: platform ?? this.platform,
      series: series ?? this.series,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      url: url ?? this.url,
      isReminderActive: isReminderActive ?? this.isReminderActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pluginId': pluginId,
      'platform': platform,
      'series': series,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'url': url,
      'isReminderActive': isReminderActive,
    };
  }

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as String,
      pluginId: json['pluginId'] as String,
      platform: json['platform'] as String,
      series: json['series'] as String? ?? 'General',
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
      url: json['url'] as String? ?? '',
      isReminderActive: json['isReminderActive'] as bool? ?? false,
    );
  }
}

/// Abstract contract that every Epsilon Plugin must implement.
abstract class EpsilonPlugin {
  String get id;
  String get name;
  String get description;
  String get version;
  String get category => 'General';
  IconData get iconData => Icons.extension_outlined;
  bool get isInstalled;

  /// Fetches upcoming events within the specified days (default: 21 days / 3 weeks).
  Future<List<EventItem>> fetchEvents({
    int daysAhead = 21,
    bool forceRefresh = false,
  });

  /// Optional settings or preferences dialog for this plugin
  void openSettings(BuildContext context) {}
}
