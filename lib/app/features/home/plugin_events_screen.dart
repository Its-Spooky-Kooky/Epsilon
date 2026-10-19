import 'package:flutter/material.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'timeline_view.dart';

class PluginEventsScreen extends StatelessWidget {
  final EpsilonPlugin plugin;
  final List<EventItem> events;

  const PluginEventsScreen({
    super.key,
    required this.plugin,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          plugin.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Configure ${plugin.name}',
            icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
            onPressed: () => plugin.openSettings(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: events.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No upcoming events found.',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            )
          : TimelineView(
              contests: events,
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
            ),
    );
  }
}
