class ParsedContestMetadata {
  final String platformId; // e.g. 'leet_code'
  final String platformDisplayName; // e.g. 'LeetCode'
  final String series; // e.g. 'Weekly Contest'

  const ParsedContestMetadata({
    required this.platformId,
    required this.platformDisplayName,
    required this.series,
  });
}

class SeriesParser {
  /// Maps raw site name from Kontests API or contest title to canonical platform and series
  static ParsedContestMetadata parse(String rawSite, String title) {
    final lowerSite = rawSite.toLowerCase();
    final lowerTitle = title.toLowerCase();

    // 1. LeetCode
    if (lowerSite.contains('leet') || lowerTitle.contains('leetcode')) {
      String series = 'General';
      if (lowerTitle.contains('biweekly') || lowerTitle.contains('bi-weekly')) {
        series = 'Biweekly Contest';
      } else if (lowerTitle.contains('weekly')) {
        series = 'Weekly Contest';
      }
      return const ParsedContestMetadata(
        platformId: 'leet_code',
        platformDisplayName: 'LeetCode',
        series: '',
      )._withSeries(series);
    }

    // 2. Codeforces
    if (lowerSite.contains('codeforces') ||
        lowerSite.contains('code_forces') ||
        lowerTitle.contains('codeforces')) {
      String series = 'General';
      if (lowerTitle.contains('div. 1') ||
          lowerTitle.contains('div 1') ||
          lowerTitle.contains('div1') ||
          lowerTitle.contains('div.1') ||
          lowerTitle.contains('division 1')) {
        series = 'Div. 1';
      } else if (lowerTitle.contains('div. 2') ||
          lowerTitle.contains('div 2') ||
          lowerTitle.contains('div2') ||
          lowerTitle.contains('div.2') ||
          lowerTitle.contains('division 2')) {
        series = 'Div. 2';
      } else if (lowerTitle.contains('div. 3') ||
          lowerTitle.contains('div 3') ||
          lowerTitle.contains('div3') ||
          lowerTitle.contains('div.3') ||
          lowerTitle.contains('division 3')) {
        series = 'Div. 3';
      } else if (lowerTitle.contains('div. 4') ||
          lowerTitle.contains('div 4') ||
          lowerTitle.contains('div4') ||
          lowerTitle.contains('div.4') ||
          lowerTitle.contains('division 4')) {
        series = 'Div. 4';
      } else if (lowerTitle.contains('educational')) {
        series = 'Educational Round';
      } else if (lowerTitle.contains('global')) {
        series = 'Global Round';
      }
      return const ParsedContestMetadata(
        platformId: 'codeforces',
        platformDisplayName: 'Codeforces',
        series: '',
      )._withSeries(series);
    }

    // 3. CodeChef
    if (lowerSite.contains('chef') || lowerTitle.contains('codechef')) {
      String series = 'General';
      if (lowerTitle.contains('starter') || lowerTitle.contains('starters')) {
        series = 'Starters';
      } else if (lowerTitle.contains('cook')) {
        series = 'Cook-Off';
      } else if (lowerTitle.contains('lunch')) {
        series = 'Lunchtime';
      }
      return const ParsedContestMetadata(
        platformId: 'code_chef',
        platformDisplayName: 'CodeChef',
        series: '',
      )._withSeries(series);
    }

    // 4. AtCoder
    if (lowerSite.contains('atcoder') ||
        lowerSite.contains('at_coder') ||
        lowerTitle.contains('atcoder')) {
      String series = 'General';
      if (lowerTitle.contains('abc') || lowerTitle.contains('beginner')) {
        series = 'Beginner Contest (ABC)';
      } else if (lowerTitle.contains('arc') || lowerTitle.contains('regular')) {
        series = 'Regular Contest (ARC)';
      } else if (lowerTitle.contains('agc') || lowerTitle.contains('grand')) {
        series = 'Grand Contest (AGC)';
      }
      return const ParsedContestMetadata(
        platformId: 'at_coder',
        platformDisplayName: 'AtCoder',
        series: '',
      )._withSeries(series);
    }

    // Fallback / Other
    return ParsedContestMetadata(
      platformId: lowerSite.replaceAll(' ', '_'),
      platformDisplayName: rawSite.isNotEmpty ? rawSite : 'Contest',
      series: 'General',
    );
  }
}

extension on ParsedContestMetadata {
  ParsedContestMetadata _withSeries(String s) {
    return ParsedContestMetadata(
      platformId: platformId,
      platformDisplayName: platformDisplayName,
      series: s,
    );
  }
}
