import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epsilon/main.dart';
import 'package:epsilon/app/core/storage_service.dart';
import 'package:epsilon/app/core/plugin_interface.dart';
import 'package:epsilon/plugins/cp_contest/cp_contest_plugin.dart';

class _MockCpContestsNotifier extends CpContestsNotifier {
  @override
  Future<List<EventItem>> build() async {
    return [];
  }
}

void main() {
  testWidgets('Epsilon app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          cpContestsProvider.overrideWith(() => _MockCpContestsNotifier()),
        ],
        child: const EpsilonApp(),
      ),
    );

    expect(find.text('EPSILON'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
  });
}
