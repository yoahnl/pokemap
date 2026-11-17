import 'package:avelune_studio/presentation/features/map_builder/map_builder_interaction_trigger_card.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/app/di/event_providers.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

class _Events extends Fake implements EventPort {}

final _meeting = NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-000000000101',
    name: 'meeting',
    source: NarrativeEventSourceRef.entityInteract('a', 'luth'),
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: 0,
  ),
  enabled: true,
);

final _project = workspaceProject.copyWith(
  scenes: [
    SceneAsset(
      id: 'scene',
      name: 'Scène',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
          ),
        ],
        edges: [
          SceneEdge(
            id: 'start-end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    ),
  ],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: [_meeting],
    legacyClaims: const [],
  ),
);

void main() {
  late ProviderContainer container;

  MapWorkspaceController controller() =>
      container.read(mapWorkspaceControllerProvider(exampleA));

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = ControlledProjectSessionPort();
    final memory = WorkspaceMemoryPort(manifest: _project)
      ..saved['a'] = workspaceMap('a').copyWith(
        entities: const [
          MapEntity(
            id: 'luth',
            name: 'Luth',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 2),
            npc: MapEntityNpcData(displayName: 'Luth'),
          ),
        ],
      );
    container = ProviderContainer(
      overrides: [
        projectSessionPortProvider.overrideWithValue(sessions),
        projectDirectoryPickerProvider.overrideWithValue(
          () async => exampleA.directoryPath,
        ),
        mapWorkspacePortProvider(exampleA).overrideWithValue(memory),
        workspaceVisualsLoaderProvider.overrideWithValue(
          (session, manifest) async => WorkspaceTestVisuals(),
        ),
        eventPortProvider(exampleA).overrideWithValue(_Events()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: studioTheme(), home: const StudioRoot()),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('studio-home-import')));
    await tester.pump();
    sessions.pending.single.complete(exampleA);
    await settle(tester);
  }

  Future<void> showSpace(WidgetTester tester, String space) async {
    await tester.tap(find.byKey(ValueKey('map-space-$space')));
    await settle(tester);
  }

  Future<String> ruleName(WidgetTester tester) async {
    final card = find.byKey(ValueKey('map-interaction-trigger-${_meeting.id}'));
    if (card.evaluate().isEmpty) {
      await tester.tap(
        find.byKey(const ValueKey('map-story-element-entity:luth')),
      );
      await settle(tester);
      await tester.tap(find.text('Déclencheurs'));
      await settle(tester);
    }
    return tester
        .widget<MapBuilderInteractionTriggerCard>(
          find.ancestor(
            of: card,
            matching: find.byType(MapBuilderInteractionTriggerCard),
          ),
        )
        .record
        .name;
  }

  Future<void> undo(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  testWidgets(
    'Construction and Interactions share the map and the story draft',
    (tester) async {
      await open(tester);
      final document = controller().active!;
      document.commit(document.current.copyWith(name: 'Clairière modifiée'));
      controller().notify();
      await showSpace(tester, 'story');
      expect(await ruleName(tester), 'meeting');
      await tester.tap(
        find.byKey(ValueKey('map-interaction-trigger-actions-${_meeting.id}')),
      );
      await settle(tester);
      await tester.tap(find.text('Renommer'));
      await settle(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(ValueKey('map-story-behaviour-name-${_meeting.id}')),
          matching: find.byType(TextField),
        ),
        'Rencontre modifiée',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      await showSpace(tester, 'construction');
      expect(
        find.byKey(const ValueKey('map-interaction-triggers')),
        findsNothing,
      );
      await showSpace(tester, 'story');

      expect(identical(controller().active, document), isTrue);
      expect(document.current.name, 'Clairière modifiée');
      expect(find.text('Non enregistré'), findsOneWidget);
      expect(await ruleName(tester), 'Rencontre modifiée');

      await undo(tester);
      expect(await ruleName(tester), 'meeting');
      expect(document.current.name, 'Clairière modifiée');

      await undo(tester);
      expect(document.current.name, isNot('Clairière modifiée'));
      expect(await ruleName(tester), 'meeting');
    },
  );
}
