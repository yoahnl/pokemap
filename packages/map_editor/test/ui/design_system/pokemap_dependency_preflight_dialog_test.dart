import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_dependency_preflight_dialog.dart';

void main() {
  const target = NarrativeDependencyKey.map('alpha');
  const intent = NarrativeDependencyNavigationIntent(
    kind: NarrativeDependencyTargetKind.sourceMap,
    assetId: 'to_alpha',
    mapId: 'beta',
    sourceKind: 'warp',
  );
  const usage = NarrativeDependencyUsage(
    target: target,
    owner: NarrativeDependencyKey.mapSource(
      mapId: 'beta',
      sourceKind: 'warp',
      sourceId: 'to_alpha',
    ),
    path: 'maps[beta].warps[0].targetMapId',
    criticality: NarrativeDependencyCriticality.runtimeBlocking,
    navigationIntent: intent,
  );
  final inspection = NarrativeDependencyInspectionReadModel(
    target: target,
    definitions: <NarrativeDependencyDefinition>[
      NarrativeDependencyDefinition(
        key: target,
        label: 'Alpha',
        path: 'maps[alpha]',
      ),
    ],
    usages: const <NarrativeDependencyUsage>[usage],
    issues: const <NarrativeDependencyIssue>[],
  );

  testWidgets('shows usages, index diagnostics and opens the exact intent',
      (tester) async {
    final opened = <NarrativeDependencyNavigationIntent>[];
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapDependencyPreflightDialog(
        context,
        title: 'Renommage bloqué',
        message: 'Aucune écriture n’a été effectuée.',
        inspection: inspection,
        indexDiagnostics: const <String>[
          'Impossible d’indexer maps/gamma.json.',
        ],
        onOpen: opened.add,
      ),
    );

    await tester.tap(find.text('Ouvrir le détail'));
    await tester.pumpAndSettle();

    expect(find.text('Renommage bloqué'), findsOneWidget);
    expect(find.text('Aucune écriture n’a été effectuée.'), findsOneWidget);
    expect(
      find.text('Impossible d’indexer maps/gamma.json.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('maps[beta].warps[0].targetMapId'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<Object>((
          'dependency-inspector-consumer-open',
          target,
          NarrativeDependencyKey.mapSource(
            mapId: 'beta',
            sourceKind: 'warp',
            sourceId: 'to_alpha',
          ),
          'maps[beta].warps[0].targetMapId',
        )),
      ),
    );
    await tester.pumpAndSettle();

    expect(opened, const <NarrativeDependencyNavigationIntent>[intent]);
    expect(find.text('Renommage bloqué'), findsNothing);
  });

  testWidgets('can be dismissed without navigation', (tester) async {
    final opened = <NarrativeDependencyNavigationIntent>[];
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapDependencyPreflightDialog(
        context,
        title: 'Suppression bloquée',
        message: 'Un usage entrant doit être retiré.',
        inspection: inspection,
        indexDiagnostics: const <String>[],
        onOpen: opened.add,
      ),
    );

    await tester.tap(find.text('Ouvrir le détail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.text('Suppression bloquée'), findsNothing);
  });

  testWidgets('Escape dismisses the modal without navigation', (tester) async {
    final opened = <NarrativeDependencyNavigationIntent>[];
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapDependencyPreflightDialog(
        context,
        title: 'Suppression bloquée',
        message: 'Un usage entrant doit être retiré.',
        inspection: inspection,
        indexDiagnostics: const <String>[],
        onOpen: opened.add,
      ),
    );

    await tester.tap(find.text('Ouvrir le détail'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.text('Suppression bloquée'), findsNothing);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onLaunch,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onLaunch(context),
            child: const Text('Ouvrir le détail'),
          ),
        ),
      ),
    ),
  );
}
