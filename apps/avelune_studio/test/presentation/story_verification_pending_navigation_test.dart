import 'dart:async';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import '../verification/verification_fakes.dart';
import 'story_interactions_support.dart';
import 'story_memory_harness.dart';

Future<void> _tap(WidgetTester tester, String key) async {
  final target = interactionKey(key);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await settleMemory(tester);
}

Future<
  ({
    WorkspaceMemoryPort maps,
    MapOnlyWorld world,
    FakeVerificationPort verification,
    EditableMapDocument active,
  })
>
_report(
  WidgetTester tester, {
  NarrativeProjectDiagnosticDestination destination =
      NarrativeProjectDiagnosticDestination.event,
  String mapId = 'a',
}) async {
  final first = interactionRecord(guideTalk, 'a', 'guide', 'Parler au guide');
  final second = interactionRecord(motherTalk, 'b', 'mother', 'Parler à Maman');
  final index = memoryIndex()
    ..titlesByKind[NarrativeTitleKind.events] = [
      NarrativeTitle(id: first.id, title: first.name),
      NarrativeTitle(id: second.id, title: second.name),
    ];
  final verification = FakeVerificationPort(
    diagnostics: [
      verificationDiagnostic(
        'destination',
        destination,
        mapId: mapId,
        eventId: destination == NarrativeProjectDiagnosticDestination.event
            ? (mapId == 'a' ? guideTalk : motherTalk)
            : null,
      ),
    ],
  );
  late MapOnlyWorld world;
  final maps = await openMemoryStudio(
    tester,
    index,
    verification: verification,
    world: (maps) => world = MapOnlyWorld(maps, readSaved: true),
    project: memoryProject.copyWith(
      maps: workspaceEntries,
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [first, second],
        legacyClaims: const [],
      ),
    ),
    initialMaps: {
      'b': workspaceMap('b').copyWith(
        entities: const [
          MapEntity(
            id: 'mother',
            name: 'Maman',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 4, y: 4),
            npc: MapEntityNpcData(displayName: 'Maman'),
          ),
        ],
      ),
    },
  );
  await openTrame(tester);
  await _tap(tester, 'story-section-verification');
  await _tap(tester, 'verification-start');
  return (
    maps: maps,
    world: world,
    verification: verification,
    active: interactionMaps(tester).active!,
  );
}

void main() {
  testWidgets('the same trigger opens twice and returns to the same report', (
    tester,
  ) async {
    final report = await _report(tester);
    for (var i = 0; i < 2; i++) {
      await _tap(tester, 'verification-open-0');
      expect(
        interactionKey('map-story-behaviour-name-$guideTalk'),
        findsOneWidget,
      );
      expect(interactionMaps(tester).active, same(report.active));
      await _tap(tester, 'story-return');
      expect(interactionKey('verification-view'), findsOneWidget);
      expect(interactionMaps(tester).active, same(report.active));
    }
    expect(report.verification.analyses, 1);
  });

  for (final reopen in [false, true]) {
    testWidgets(
      'a trigger with an unreadable saved map is unavailable, reopen=$reopen',
      (tester) async {
        final report = await _report(tester);
        if (reopen) {
          await _tap(tester, 'verification-open-0');
          expect(
            interactionKey('map-story-behaviour-name-$guideTalk'),
            findsOneWidget,
          );
          await _tap(tester, 'story-return');
        }
        final before = report.world.loaded.length;
        final map = report.active.current;
        report.maps.failedMap = 'a';

        await _tap(tester, 'verification-open-0');

        expect(report.world.loaded.skip(before), ['a']);
        expect(
          interactionKey('verification-destination-unavailable'),
          findsOneWidget,
        );
        expect(interactionKey('verification-view'), findsOneWidget);
        expect(interactionMaps(tester).active, same(report.active));
        expect(report.active.current, same(map));
      },
    );
  }

  for (final destination in [
    NarrativeProjectDiagnosticDestination.map,
    NarrativeProjectDiagnosticDestination.event,
  ]) {
    testWidgets(
      'a new report supersedes a pending ${destination.name} opening',
      (tester) async {
        final report = await _report(
          tester,
          mapId: 'b',
          destination: destination,
        );
        final gate = report.maps.loadGate = Completer<void>();
        await _tap(tester, 'verification-open-0');
        expect(report.world.loaded, ['b']);
        expect(interactionKey('verification-view'), findsOneWidget);
        await _tap(tester, 'verification-start');
        expect(report.verification.analyses, 2);

        report.maps.loadGate = null;
        gate.complete();
        await settleMemory(tester);

        expect(interactionKey('verification-view'), findsOneWidget);
        expect(
          interactionKey('verification-destination-unavailable'),
          findsNothing,
        );
        expect(interactionMaps(tester).active, same(report.active));
        expect(interactionKey('story-return'), findsNothing);
        await _tap(tester, 'verification-open-0');
        if (destination == NarrativeProjectDiagnosticDestination.map) {
          expect(interactionMaps(tester).active!.base.mapId, 'b');
        } else {
          expect(
            interactionKey('map-story-behaviour-name-$motherTalk'),
            findsOneWidget,
          );
          expect(interactionMaps(tester).active, same(report.active));
        }
        await _tap(tester, 'story-return');
        expect(interactionKey('verification-view'), findsOneWidget);
        expect(interactionMaps(tester).active, same(report.active));
      },
    );
  }

  testWidgets('changing tabs supersedes a pending map opening', (tester) async {
    final report = await _report(
      tester,
      mapId: 'b',
      destination: NarrativeProjectDiagnosticDestination.map,
    );
    final gate = report.maps.loadGate = Completer<void>();
    await _tap(tester, 'verification-open-0');
    expect(report.world.loaded, ['b']);
    await _tap(tester, 'story-section-trame');

    report.maps.loadGate = null;
    gate.complete();
    await settleMemory(tester);

    expect(interactionKey('verification-view'), findsNothing);
    expect(interactionMaps(tester).active, same(report.active));
    expect(interactionKey('story-return'), findsNothing);
    await _tap(tester, 'story-section-verification');
    expect(interactionKey('verification-view'), findsOneWidget);
    expect(report.verification.analyses, 1);
  });

  testWidgets(
    'a failed read after leaving Verification does not show an error',
    (tester) async {
      final report = await _report(
        tester,
        mapId: 'b',
        destination: NarrativeProjectDiagnosticDestination.map,
      );
      final gate = report.maps.loadGate = Completer<void>();
      await _tap(tester, 'verification-open-0');
      expect(report.world.loaded, ['b']);
      await _tap(tester, 'story-section-trame');
      await _tap(tester, 'story-section-verification');

      report.maps.failedMap = 'b';
      report.maps.loadGate = null;
      gate.complete();
      await settleMemory(tester);

      expect(interactionKey('verification-view'), findsOneWidget);
      expect(
        interactionKey('verification-destination-unavailable'),
        findsNothing,
      );
      expect(interactionMaps(tester).active, same(report.active));
      await _tap(tester, 'verification-open-0');
      expect(
        interactionKey('verification-destination-unavailable'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'returning during map activation abandons the diagnostic opening',
    (tester) async {
      final report = await _report(
        tester,
        mapId: 'b',
        destination: NarrativeProjectDiagnosticDestination.map,
      );
      final preflight = report.maps.loadGate = Completer<void>();
      await _tap(tester, 'verification-open-0');
      expect(report.world.loaded, ['b']);
      final reads = report.maps.reads;
      final activation = report.maps.loadGate = Completer<void>();
      preflight.complete();
      await settleMemory(tester);
      expect(report.maps.reads, reads + 1);
      expect(interactionKey('story-return'), findsOneWidget);
      await _tap(tester, 'story-return');
      expect(interactionKey('verification-view'), findsOneWidget);

      report.maps.loadGate = null;
      activation.complete();
      await settleMemory(tester);

      expect(interactionKey('verification-view'), findsOneWidget);
      expect(
        interactionKey('verification-destination-unavailable'),
        findsNothing,
      );
      expect(interactionMaps(tester).active, same(report.active));
    },
  );
}
