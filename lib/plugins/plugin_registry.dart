import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/plugin_interface.dart';

import 'cp_contest/cp_contest_plugin.dart';
import 'test/test_plugin.dart';

/// Central Plugin Registry
final registeredPlugins = <EpsilonPlugin>[CpContestPlugin(), TestPlugin()];

/// Provider exposing all registered plugins to the app
final pluginRegistryProvider = Provider<List<EpsilonPlugin>>((ref) {
  return registeredPlugins;
});
