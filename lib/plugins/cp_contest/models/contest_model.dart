/// Raw response model from Kontests API
class KontestRawItem {
  final String name;
  final String url;
  final String startTimeStr;
  final String endTimeStr;
  final String durationSecondsStr;
  final String site;
  final String status;
  final String in24Hours;

  const KontestRawItem({
    required this.name,
    required this.url,
    required this.startTimeStr,
    required this.endTimeStr,
    required this.durationSecondsStr,
    required this.site,
    required this.status,
    required this.in24Hours,
  });

  factory KontestRawItem.fromJson(Map<String, dynamic> json) {
    String startStr = '';
    if (json['startTime'] != null) {
      if (json['startTime'] is int) {
        startStr = DateTime.fromMillisecondsSinceEpoch(
          json['startTime'] as int,
          isUtc: true,
        ).toIso8601String();
      } else {
        startStr = json['startTime'].toString();
      }
    } else {
      startStr = json['start_time'] as String? ?? '';
    }

    String endStr = '';
    if (json['endTime'] != null) {
      if (json['endTime'] is int) {
        endStr = DateTime.fromMillisecondsSinceEpoch(
          json['endTime'] as int,
          isUtc: true,
        ).toIso8601String();
      } else {
        endStr = json['endTime'].toString();
      }
    } else {
      endStr = json['end_time'] as String? ?? '';
    }

    String durationSec = '0';
    if (json['duration'] != null) {
      if (json['duration'] is int) {
        final val = json['duration'] as int;
        durationSec = (val > 100000 ? val ~/ 1000 : val).toString();
      } else {
        durationSec = json['duration'].toString();
      }
    }

    return KontestRawItem(
      name: (json['title'] ?? json['name'] ?? 'Untitled Contest').toString(),
      url: (json['url'] ?? '').toString(),
      startTimeStr: startStr,
      endTimeStr: endStr,
      durationSecondsStr: durationSec,
      site: (json['site'] ?? '').toString(),
      status: (json['status'] ?? 'BEFORE').toString(),
      in24Hours: (json['in_24_hours'] ?? 'No').toString(),
    );
  }

  DateTime? get parsedStartTime {
    if (startTimeStr.isEmpty) return null;
    try {
      return DateTime.parse(startTimeStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? get parsedEndTime {
    if (endTimeStr.isEmpty) return null;
    try {
      return DateTime.parse(endTimeStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  Duration get parsedDuration {
    final double? seconds = double.tryParse(durationSecondsStr);
    if (seconds != null) {
      return Duration(seconds: seconds.toInt());
    }
    return Duration.zero;
  }
}
