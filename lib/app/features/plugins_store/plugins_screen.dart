import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/events_provider.dart';
import 'package:epsilon/plugins/plugin_registry.dart';

import 'plugin_card.dart';

class PluginsScreen extends ConsumerStatefulWidget {
  const PluginsScreen({super.key});

  @override
  ConsumerState<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends ConsumerState<PluginsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final installedPlugins = ref.watch(installedPluginsProvider);
    final allPlugins = ref.watch(pluginRegistryProvider);

    final filteredPlugins = allPlugins.where((plugin) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return plugin.name.toLowerCase().contains(q) ||
          plugin.description.toLowerCase().contains(q) ||
          plugin.category.toLowerCase().contains(q);
    }).toList();

    final installedList =
        filteredPlugins.where((p) => installedPlugins.contains(p.id)).toList();
    final availableList =
        filteredPlugins.where((p) => !installedPlugins.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'MARKETPLACE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search marketplace plugins...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF161616),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.tealAccent),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              children: [
                if (installedList.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DOWNLOADED PLUGINS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white38,
                          ),
                        ),
                        Text(
                          installedList.length.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final plugin in installedList)
                    PluginCard(
                      title: plugin.name,
                      category: plugin.category,
                      description: plugin.description,
                      version: plugin.version,
                      isInstalled: true,
                      onToggleInstall: (_) {
                        ref
                            .read(installedPluginsProvider.notifier)
                            .togglePlugin(plugin.id);
                      },
                    ),
                ],
                if (availableList.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AVAILABLE PLUGINS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white38,
                          ),
                        ),
                        Text(
                          availableList.length.toString(),
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  for (final plugin in availableList)
                    PluginCard(
                      title: plugin.name,
                      category: plugin.category,
                      description: plugin.description,
                      version: plugin.version,
                      isInstalled: false,
                      onToggleInstall: (_) {
                        ref
                            .read(installedPluginsProvider.notifier)
                            .togglePlugin(plugin.id);
                      },
                    ),
                ],
                if (installedList.isEmpty && availableList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        'No plugins found for "  + _searchQuery +  ',
 style: const TextStyle(color: Colors.white38, fontSize: 13),
 ),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }
}
