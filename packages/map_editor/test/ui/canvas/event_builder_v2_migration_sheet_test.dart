import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_migration_persistence_models.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_migration_preview_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_migration_sheet.dart';

import '../../support/event_registry_persistence_fixtures.dart';

void main() {
  testWidgets('shows a no-code preview and cancel performs no write',
      (tester) async {
    late EventRegistryPersistenceFixture fixture;
    late List<int> before;
    late NarrativeEventMigrationPreview preview;
    await tester.runAsync(() async {
      fixture = await createPersistenceFixture(map: _legacyMap());
      before = await fixture.readBytes();
      preview = await NarrativeEventMigrationPreviewUseCase(
        ids: _Ids(),
        clock: () => DateTime.utc(2026, 7, 17, 10),
      ).preview(fixture.projectPath);
    });
    addTearDown(fixture.dispose);
    var cancelled = false;
    var commitCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: EventBuilderV2MigrationSheet(
            preview: preview,
            onCancel: () => cancelled = true,
            onCommit: () async {
              commitCalls++;
              return const NarrativeEventMigrationPersistenceResult(
                status: NarrativeEventMigrationPersistenceStatus.committed,
                code: 'committed',
                message: 'Migration enregistrée.',
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Préparer les événements V2'), findsOneWidget);
    expect(find.text('1 événement à créer'), findsOneWidget);
    expect(find.text('1 lien de compatibilité'), findsOneWidget);
    expect(find.textContaining('mode de jeu reste inchangé'), findsOneWidget);
    expect(find.textContaining('evmr_'), findsNothing);
    expect(
      tester.widget(find.byKey(const ValueKey('event-migration-commit'))),
      isA<Widget>(),
    );

    await tester.tap(find.byKey(const ValueKey('event-migration-cancel')));
    await tester.pump();
    expect(cancelled, isTrue);
    expect(commitCalls, 0);
    final after = await tester.runAsync(fixture.readBytes);
    expect(after, before);
  });

  testWidgets('commit reports a successful persisted migration',
      (tester) async {
    final prepared = await _preparePreview(tester);
    addTearDown(prepared.fixture.dispose);
    var commitCalls = 0;
    await _pumpSheet(
      tester,
      preview: prepared.preview,
      onCommit: () async {
        commitCalls++;
        return const NarrativeEventMigrationPersistenceResult(
          status: NarrativeEventMigrationPersistenceStatus.committed,
          code: 'migrationCommitted',
          message: 'Migration enregistrée.',
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('event-migration-commit')));
    await tester.pump();

    expect(commitCalls, 1);
    expect(
      find.byKey(const ValueKey('event-migration-result')),
      findsOneWidget,
    );
    expect(find.text('Opération terminée'), findsOneWidget);
    expect(find.text('Migration enregistrée.'), findsOneWidget);
  });

  testWidgets('recovery reports a fail-closed state without invoking commit',
      (tester) async {
    final prepared = await _preparePreview(tester);
    addTearDown(prepared.fixture.dispose);
    var commitCalls = 0;
    var recoveryCalls = 0;
    await _pumpSheet(
      tester,
      preview: prepared.preview,
      onCommit: () async {
        commitCalls++;
        return const NarrativeEventMigrationPersistenceResult(
          status: NarrativeEventMigrationPersistenceStatus.committed,
          code: 'unexpected',
          message: 'Ne doit pas être appelé.',
        );
      },
      onRecover: () async {
        recoveryCalls++;
        return const NarrativeEventMigrationPersistenceResult(
          status: NarrativeEventMigrationPersistenceStatus.blocked,
          code: 'backupHashMismatch',
          message: 'La récupération est bloquée.',
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('event-migration-recover')));
    await tester.pump();

    expect(recoveryCalls, 1);
    expect(commitCalls, 0);
    expect(find.text('Action requise'), findsOneWidget);
    expect(find.text('La récupération est bloquée.'), findsOneWidget);
  });

  testWidgets('offers a separate V2 activation for a legacy-free project',
      (tester) async {
    late EventRegistryPersistenceFixture fixture;
    late NarrativeEventMigrationPreview preview;
    await tester.runAsync(() async {
      fixture = await createPersistenceFixture(
        registry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const <NarrativeEventRecord>[],
          legacyClaims: const <LegacySourceClaim>[],
        ),
        map: const MapData(
          id: 'map_a',
          name: 'Map A',
          size: GridSize(width: 8, height: 6),
        ),
      );
      preview = await NarrativeEventMigrationPreviewUseCase(
        ids: _Ids(),
        clock: () => DateTime.utc(2026, 7, 17, 10),
      ).preview(fixture.projectPath);
    });
    addTearDown(fixture.dispose);
    var activationCalls = 0;

    await _pumpSheet(
      tester,
      preview: preview,
      onCommit: () async => const NarrativeEventMigrationPersistenceResult(
        status: NarrativeEventMigrationPersistenceStatus.noOp,
        code: 'unused',
        message: 'Unused',
      ),
      onActivateV2: () async {
        activationCalls++;
        return const NarrativeEventMigrationPersistenceResult(
          status: NarrativeEventMigrationPersistenceStatus.committed,
          code: 'eventV2Activated',
          message: 'Event V2 est maintenant actif pour ce projet.',
        );
      },
    );

    expect(find.text('Projet sans événement historique'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('event-migration-activate-v2')),
    );
    await tester.pump();

    expect(activationCalls, 1);
    expect(find.text('Opération terminée'), findsOneWidget);
    expect(
      find.text('Event V2 est maintenant actif pour ce projet.'),
      findsOneWidget,
    );
  });
}

Future<
    ({
      EventRegistryPersistenceFixture fixture,
      NarrativeEventMigrationPreview preview,
    })> _preparePreview(WidgetTester tester) async {
  late EventRegistryPersistenceFixture fixture;
  late NarrativeEventMigrationPreview preview;
  await tester.runAsync(() async {
    fixture = await createPersistenceFixture(map: _legacyMap());
    preview = await NarrativeEventMigrationPreviewUseCase(
      ids: _Ids(),
      clock: () => DateTime.utc(2026, 7, 17, 10),
    ).preview(fixture.projectPath);
  });
  return (fixture: fixture, preview: preview);
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required NarrativeEventMigrationPreview preview,
  required Future<NarrativeEventMigrationPersistenceResult> Function() onCommit,
  Future<NarrativeEventMigrationPersistenceResult> Function()? onRecover,
  Future<NarrativeEventMigrationPersistenceResult> Function()? onActivateV2,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: EventBuilderV2MigrationSheet(
          preview: preview,
          onCancel: () {},
          onCommit: onCommit,
          onRecover: onRecover,
          onActivateV2: onActivateV2,
        ),
      ),
    ),
  );
  await tester.pump();
}

MapData _legacyMap() {
  return const MapData(
    id: 'map_a',
    name: 'Map A',
    size: GridSize(width: 8, height: 6),
    layers: [MapLayer.object(id: 'events', name: 'Events')],
    entities: [
      MapEntity(
        id: 'npc_a',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'legacy_a',
        title: 'Rencontre legacy',
        position: EventPosition(layerId: 'events', x: 1, y: 1),
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'npc_a',
        },
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
          ),
        ],
      ),
    ],
  );
}

final class _Ids implements NarrativeEventMigrationIdSource {
  var event = 0;
  var receipt = 0;

  @override
  String nextEventId() =>
      'evt_019abcde-0000-7000-8000-${(++event).toString().padLeft(12, '0')}';

  @override
  String nextReceiptId() =>
      'evmr_019abcde-0000-7000-8000-${(++receipt).toString().padLeft(12, '0')}';
}
