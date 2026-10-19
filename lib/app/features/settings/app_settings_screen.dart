import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/app_settings_provider.dart';
import 'package:epsilon/app/core/events_provider.dart';
import 'package:epsilon/app/core/storage_service.dart';
import 'package:epsilon/app/core/widget_service.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeNotifierProvider);
    final tzState = ref.watch(appTimezoneProvider);
    final storage = ref.watch(storageServiceProvider);
    final leadMinutes = storage.getAlarmLeadMinutes();

    return Scaffold(
      backgroundColor: themeMode.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeMode.backgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // -------------------------------------------------------------
          // 1. Timezone Settings
          // -------------------------------------------------------------
          _buildSectionHeader('TIMEZONE'),
          Container(
            decoration: BoxDecoration(
              color: themeMode.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.public_rounded, color: Colors.tealAccent, size: 22),
              title: const Text(
                'Display Timezone',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              subtitle: Text(
                tzState.displayName,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              onTap: () => _showTimezonePicker(context, ref),
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------
          // 2. Theme Settings
          // -------------------------------------------------------------
          _buildSectionHeader('APP THEME'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeMode.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final isSelected = mode == themeMode;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    ref.read(appThemeNotifierProvider.notifier).setTheme(mode);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E88E5).withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2979FF)
                            : Colors.white.withValues(alpha: 0.05),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mode.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------
          // 3. Alarms & Timing
          // -------------------------------------------------------------
          _buildSectionHeader('ALARMS & TIMING'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeMode.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Alarm Ring Timing',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Before contest or event start',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
                DropdownButton<int>(
                  value: leadMinutes,
                  dropdownColor: const Color(0xFF222222),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 5,
                      child: Text('5 min before', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 10,
                      child: Text('10 min before', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 15,
                      child: Text('15 min before', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text('30 min before', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 60,
                      child: Text('1 hour before', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      storage.setAlarmLeadMinutes(val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Default alarm set to $val minutes before start.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------
          // 4. Calendar AppWidget & Sync
          // -------------------------------------------------------------
          _buildSectionHeader('HOME SCREEN CALENDAR WIDGET'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeMode.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.widgets_outlined, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      'Android Launcher Widget',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Displays month view with multi-event stacked pills and custom plugin colors. Add it by long-pressing an empty space on your phone home screen ➔ Widgets ➔ Epsilon.',
                  style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.tealAccent,
                      side: const BorderSide(color: Colors.tealAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text(
                      'Sync Calendar Widget Now',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      final events = ref.read(appEventsProvider).value ?? [];
                      await ref.read(widgetServiceProvider).updateCalendarWidgetEvents(
                            events,
                            ref: ref,
                            force: true,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Home screen calendar widget synchronized!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------
          // 5. Data & Cache
          // -------------------------------------------------------------
          _buildSectionHeader('DATA & REFRESH'),
          Container(
            decoration: BoxDecoration(
              color: themeMode.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  title: const Text('Refresh All Events', style: TextStyle(fontSize: 14, color: Colors.white)),
                  subtitle: const Text('Fetch latest contests from all platforms', style: TextStyle(fontSize: 12, color: Colors.white38)),
                  onTap: () async {
                    await ref.read(appEventsProvider.notifier).refreshAll();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Refreshed all events!'), duration: Duration(seconds: 2)),
                      );
                    }
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Clear Contest Cache', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                  subtitle: const Text('Remove stored contest data and refetch freshly', style: TextStyle(fontSize: 12, color: Colors.white38)),
                  onTap: () async {
                    await storage.saveCachedContests([]);
                    await ref.read(appEventsProvider.notifier).refreshAll();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contest cache cleared!'), duration: Duration(seconds: 2)),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // -------------------------------------------------------------
          // 6. About
          // -------------------------------------------------------------
          const Center(
            child: Column(
              children: [
                Text(
                  'EPSILON CP CONTEST DASHBOARD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white38,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.0.0+1',
                  style: TextStyle(fontSize: 11, color: Colors.white24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.white38,
        ),
      ),
    );
  }

  void _showTimezonePicker(BuildContext context, WidgetRef ref) {
    final currentTz = ref.read(appTimezoneProvider).timezoneKey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.public, color: Colors.tealAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Select Timezone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: AppTimezoneNotifier.supportedTimezones.length,
                    itemBuilder: (context, i) {
                      final item = AppTimezoneNotifier.supportedTimezones[i];
                      final isSelected = item.key == currentTz;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E88E5).withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2979FF)
                                : Colors.transparent,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          title: Text(
                            item.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          onTap: () {
                            ref.read(appTimezoneProvider.notifier).setTimezone(item.key);
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

