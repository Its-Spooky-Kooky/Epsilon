import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/events_provider.dart';
import 'package:epsilon/plugins/plugin_registry.dart';

import 'plugin_card.dart';

class PluginsScreen extends ConsumerWidget {
  const PluginsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedPlugins = ref.watch(installedPluginsProvider);
    final plugins = ref.watch(pluginRegistryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'PLUGINS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          for (final plugin in plugins)
            PluginCard(
              title: plugin.name,
              category: plugin.category,
              description: plugin.description,
              version: plugin.version,
              isInstalled: installedPlugins.contains(plugin.id),
              onConfigure: () => plugin.openSettings(context),
              onToggleInstall: () {
                ref
                    .read(installedPluginsProvider.notifier)
                    .togglePlugin(plugin.id);
              },
            ),
        ],
      ),
    );
  }
}
