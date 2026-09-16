import 'dart:convert';

/// Represents a platform and its 2-level toggle configuration:
/// Level 1: Platform isEnabled
/// Level 2: Series-specific toggles (e.g., Weekly Contest: true/false)
class PlatformPreference {
  final String platformId; // e.g. 'leetcode', 'codeforces', 'codechef', 'atcoder'
  final String displayName;
  final bool isEnabled;
  final Map<String, bool> seriesToggles;

  const PlatformPreference({
    required this.platformId,
    required this.displayName,
    this.isEnabled = true,
    this.seriesToggles = const {},
  });

  bool isSeriesEnabled(String series) {
    if (!isEnabled) return false;
    // Default to true if not explicitly toggled off
    return seriesToggles[series] ?? true;
  }

  PlatformPreference copyWith({
    String? platformId,
    String? displayName,
    bool? isEnabled,
    Map<String, bool>? seriesToggles,
  }) {
    return PlatformPreference(
      platformId: platformId ?? this.platformId,
      displayName: displayName ?? this.displayName,
      isEnabled: isEnabled ?? this.isEnabled,
      seriesToggles: seriesToggles ?? Map<String, bool>.from(this.seriesToggles),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platformId': platformId,
      'displayName': displayName,
      'isEnabled': isEnabled,
      'seriesToggles': seriesToggles,
    };
  }

  factory PlatformPreference.fromMap(Map<String, dynamic> map) {
    return PlatformPreference(
      platformId: map['platformId'] as String,
      displayName: map['displayName'] as String,
      isEnabled: map['isEnabled'] as bool? ?? true,
      seriesToggles: (map['seriesToggles'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          {},
    );
  }

  String toJson() => json.encode(toMap());

  factory PlatformPreference.fromJson(String source) =>
      PlatformPreference.fromMap(json.decode(source) as Map<String, dynamic>);
}

