import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'models/contest_model.dart';

class CpApiService {
  final Dio _dio;

  CpApiService([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'Epsilon-Contest-App/1.0',
              },
            ),
          );

  /// Fetches raw contest list from active CP APIs (CompeteAPI & Codeforces) concurrently
  Future<List<KontestRawItem>> fetchAllContests() async {
    final List<KontestRawItem> results = [];
    final Set<String> seen = {};

    // Execute both fetches concurrently for maximum speed
    final responses = await Future.wait([
      _fetchFromCompeteApi(),
      _fetchFromCodeforcesApi(),
    ]);

    for (final list in responses) {
      for (final contest in list) {
        final key =
            '${contest.site.toLowerCase()}_${contest.name.toLowerCase()}';
        if (seen.add(key)) {
          results.add(contest);
        }
      }
    }

    return results;
  }

  Future<List<KontestRawItem>> _fetchFromCompeteApi() async {
    try {
      final response = await _dio.get(
        'https://competeapi.vercel.app/contests/upcoming',
      );
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => KontestRawItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('CompeteAPI fetch error: $e');
    }
    return [];
  }

  Future<List<KontestRawItem>> _fetchFromCodeforcesApi() async {
    try {
      final response = await _dio.get(
        'https://codeforces.com/api/contest.list?gym=false',
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == 'OK' && data['result'] is List) {
          final List list = data['result'] as List;
          final List<KontestRawItem> cfContests = [];
          for (final item in list) {
            if (item is Map<String, dynamic> && item['phase'] == 'BEFORE') {
              final id = item['id'];
              final name = item['name'] as String? ?? 'Codeforces Contest';
              final durationSec = (item['durationSeconds'] ?? 7200).toString();
              final startSec = item['startTimeSeconds'] as int?;
              if (startSec != null) {
                final startDt = DateTime.fromMillisecondsSinceEpoch(
                  startSec * 1000,
                  isUtc: true,
                );
                final endDt = startDt.add(
                  Duration(seconds: int.tryParse(durationSec) ?? 7200),
                );
                cfContests.add(
                  KontestRawItem(
                    name: name,
                    url: 'https://codeforces.com/contest/$id',
                    startTimeStr: startDt.toIso8601String(),
                    endTimeStr: endDt.toIso8601String(),
                    durationSecondsStr: durationSec,
                    site: 'codeforces',
                    status: 'BEFORE',
                    in24Hours: (startDt.difference(DateTime.now()).inHours < 24)
                        ? 'Yes'
                        : 'No',
                  ),
                );
              }
            }
          }
          return cfContests;
        }
      }
    } catch (e) {
      debugPrint('Codeforces API fetch error: $e');
    }
    return [];
  }
}
