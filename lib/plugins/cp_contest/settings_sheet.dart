import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/storage_service.dart';
import 'cp_contest_plugin.dart';

class CpPluginSettingsSheet extends ConsumerWidget {
  const CpPluginSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CpPluginSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsMap = ref.watch(cpPreferencesProvider);
    final storage = ref.watch(storageServiceProvider);
    final leadMinutes = storage.getAlarmLeadMinutes();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CP Contest Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure platforms and contest series to display.',
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alarm Ring Timing',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DropdownButton<int>(
                    value: leadMinutes,
                    dropdownColor: const Color(0xFF222222),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 5,
                        child: Text('5 mins before', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 10,
                        child: Text('10 mins before', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 15,
                        child: Text('15 mins before', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text('30 mins before', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        storage.setAlarmLeadMinutes(val);
                        ref.read(cpPreferencesProvider.notifier).reconcileReminders();
                      }
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: prefsMap.values.map((platformPref) {
                    final isPlatformOn = platformPref.isEnabled;
                    final notifier = ref.read(cpPreferencesProvider.notifier);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B1B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPlatformOn
                              ? Colors.white12
                              : Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Text(
                              platformPref.displayName.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.8,
                                color: isPlatformOn
                                    ? Colors.white
                                    : Colors.white38,
                              ),
                            ),
                            value: isPlatformOn,
                            activeThumbColor: Colors.white,
                            onChanged: (val) => notifier.togglePlatform(
                              platformPref.platformId,
                              val,
                            ),
                          ),
                          if (isPlatformOn &&
                              platformPref.seriesToggles.isNotEmpty) ...[
                            const Divider(color: Colors.white10, height: 1),
                            ...platformPref.seriesToggles.entries.map((entry) {
                              final seriesName = entry.key;
                              final isSeriesOn = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: SwitchListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                  ),
                                  title: Text(
                                    seriesName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isSeriesOn
                                          ? Colors.white70
                                          : Colors.white30,
                                    ),
                                  ),
                                  value: isSeriesOn,
                                  activeThumbColor: Colors.tealAccent,
                                  onChanged: (val) => notifier.toggleSeries(
                                    platformPref.platformId,
                                    seriesName,
                                    val,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
