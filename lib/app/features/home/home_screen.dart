import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/events_provider.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'package:epsilon/plugins/cp_contest/settings_sheet.dart';

import 'countdown_card.dart';
import 'timeline_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(appEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'EPSILON',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        actions: [
          // Plugin Preferences Icon Button
          IconButton(
            tooltip: 'Contest & Filter Preferences',
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => CpPluginSettingsSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: () async {
          await ref.read(appEventsProvider.notifier).refreshAll();
        },
        child: contestsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          error: (err, stack) => ListView(
            children: [
              const SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: Colors.white38,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load contests: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          ref.read(appEventsProvider.notifier).refreshAll(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (contests) {
            final upcomingList = contests
                .where((c) => c.status == EventStatus.upcoming)
                .toList();
            final nextContest = upcomingList.isNotEmpty
                ? upcomingList.first
                : null;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Active Plugin Summary Banner
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.tealAccent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.tealAccent,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'CP CONTEST PLUGIN ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.tealAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${contests.length} in 3 weeks',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),

                // Countdown Card for next upcoming contest
                if (nextContest != null) CountdownCard(contest: nextContest),

                // 3-Week Unified Timeline
                TimelineView(
                  contests: contests,
                ),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}
