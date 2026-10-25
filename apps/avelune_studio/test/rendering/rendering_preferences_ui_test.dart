import 'dart:async';

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:avelune_studio/features/rendering/application/studio_rendering_preferences.dart';
import 'package:avelune_studio/presentation/features/rendering/studio_display_preferences.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => AveluneFrameRate.setLimit(60));
  tearDown(() => AveluneFrameRate.setLimit(60));

  testWidgets('display preferences are available without an open project', (
    tester,
  ) async {
    final search = TextEditingController();
    addTearDown(search.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: StudioApplicationFrame(
          search: search,
          onSearch: (_) {},
          onDestination: (_) {},
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.byTooltip('Affichage'), findsOneWidget);
  });

  testWidgets(
    'global display choice exposes exactly the five supported limits',
    (tester) async {
      final store = _Store();
      final preferences = StudioRenderingPreferences(store);
      addTearDown(preferences.dispose);
      await preferences.load();
      await _mount(tester, preferences);

      await tester.tap(find.byTooltip('Affichage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('60 images/s'));
      await tester.pumpAndSettle();

      for (final limit in [30, 45, 60, 90, 120]) {
        expect(find.text('$limit images/s'), findsWidgets);
      }
      expect(find.text('Illimité'), findsNothing);
      await tester.tap(find.text('90 images/s').last);
      await tester.pumpAndSettle();

      expect(preferences.limit, 90);
      expect(store.writes, [90]);
      expect(store.reads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending writes are not shown as saved and failure rolls back', (
    tester,
  ) async {
    final store = _Store(controlWrites: true);
    final preferences = StudioRenderingPreferences(store);
    addTearDown(preferences.dispose);
    await preferences.load();
    await _mount(tester, preferences);
    await tester.tap(find.byTooltip('Affichage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 images/s'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('45 images/s').last);
    await tester.pump();

    expect(find.text('Enregistrement…'), findsOneWidget);
    expect(find.text('Préférence enregistrée sur cet appareil.'), findsNothing);
    expect(AveluneFrameRate.limit, 45);
    store.pending.single.completeError(StateError('Disk unavailable'));
    await tester.pumpAndSettle();

    expect(find.text('60 images/s'), findsOneWidget);
    expect(find.text('Enregistrement…'), findsNothing);
    expect(find.textContaining('Impossible d’enregistrer'), findsOneWidget);
    expect(find.text('Préférence enregistrée sur cet appareil.'), findsNothing);
    expect(AveluneFrameRate.limit, 60);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing display preferences retains the mounted workspace', (
    tester,
  ) async {
    final store = _Store();
    final preferences = StudioRenderingPreferences(store);
    addTearDown(preferences.dispose);
    await preferences.load();
    final workspace = GlobalKey<_WorkspaceState>();
    await _mount(tester, preferences, child: _Workspace(key: workspace));
    final mounted = workspace.currentState;
    await tester.enterText(
      find.byType(TextField).last,
      'Brouillon non enregistré',
    );

    await tester.tap(find.byTooltip('Affichage'));
    await tester.pumpAndSettle();
    for (final limit in [30, 120]) {
      await tester.tap(find.text('${preferences.limit} images/s'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('$limit images/s').last);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Fermer les préférences d’affichage'));
    await tester.pumpAndSettle();

    expect(workspace.currentState, same(mounted));
    expect(mounted!.builds, 1);
    expect(find.text('Brouillon non enregistré'), findsOneWidget);
    expect(store.reads, 1);
    expect(store.writes, [30, 120]);
  });
}

Future<void> _mount(
  WidgetTester tester,
  StudioRenderingPreferences preferences, {
  Widget child = const SizedBox.expand(),
}) async {
  final search = TextEditingController();
  addTearDown(search.dispose);
  await tester.pumpWidget(
    StudioRenderingPreferencesScope(
      preferences: preferences,
      child: MaterialApp(
        theme: studioTheme(),
        home: StudioApplicationFrame(
          search: search,
          onSearch: (_) {},
          onDestination: (_) {},
          child: child,
        ),
      ),
    ),
  );
}

final class _Store implements StudioRenderingPreferencesStore {
  _Store({this.controlWrites = false});

  final bool controlWrites;
  int reads = 0;
  final writes = <int>[];
  final pending = <Completer<void>>[];

  @override
  Future<int?> load() async {
    reads++;
    return null;
  }

  @override
  Future<void> save(int limit) async {
    writes.add(limit);
    if (controlWrites) {
      final completion = Completer<void>();
      pending.add(completion);
      await completion.future;
    }
  }
}

class _Workspace extends StatefulWidget {
  const _Workspace({super.key});

  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    return Column(
      children: [
        const TextField(),
        Expanded(
          child: ListView.builder(
            itemCount: 1000,
            itemBuilder: (_, index) => Text('Carte sans rapport $index'),
          ),
        ),
      ],
    );
  }
}
