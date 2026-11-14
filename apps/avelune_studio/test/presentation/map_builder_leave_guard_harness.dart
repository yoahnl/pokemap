import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/event_providers.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

late ControlledProjectSessionPort sessions;
late WorkspaceMemoryPort memory;
late ProviderContainer container;
late LeaveGuardEvents events;

MapWorkspaceController controller() =>
    container.read(mapWorkspaceControllerProvider(exampleA));

Future<void> settle(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void sizeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> open(WidgetTester tester) async {
  sizeView(tester);
  sessions = ControlledProjectSessionPort();
  memory = leaveGuardMemory();
  events = LeaveGuardEvents(controller, memory);
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
      eventPortProvider(exampleA).overrideWithValue(events),
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

void editMap() {
  final document = controller().active!;
  document.commit(document.current.copyWith(name: 'Clairière modifiée'));
  controller().notify();
}

Future<void> openMeeting(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('map-space-story')));
  await settle(tester);
  await tester.tap(find.byKey(const ValueKey('map-story-element-entity:luth')));
  await settle(tester);
}

Future<void> editBehaviour(WidgetTester tester) async {
  await openMeeting(tester);
  tester
      .widget<StudioSelect>(find.byKey(const ValueKey('map-story-after')))
      .onChanged!('eachTime');
  await settle(tester);
}

Finder nameField() =>
    find.byKey(ValueKey('map-story-behaviour-name-${leaveGuardMeeting.id}'));

Future<void> goHome(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Accueil du projet'));
  await settle(tester);
}

Future<void> choose(WidgetTester tester, String choice) async {
  expect(find.byKey(const ValueKey('studio-save-choice')), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('studio-save-choice-$choice')));
  await settle(tester);
}

Future<void> pressWithControl(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await settle(tester);
}

class LeaveGuardEvents implements EventPort {
  LeaveGuardEvents(this.maps, this.memory);

  final MapWorkspaceController Function() maps;
  final WorkspaceMemoryPort memory;
  final published = <({String id, String? name, int mapWrites})>[];

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) async {
    published.add((id: id, name: current?.name, mapWrites: memory.writes));
    final before = maps().project!;
    final registry = before.eventRegistry!;
    return ResourceMutationReceipt(
      before: before,
      manifest: before.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: registry.schemaVersion,
          mode: registry.mode,
          records: [
            for (final record in registry.records)
              if (record.id != id) record else ?current,
          ],
          legacyClaims: registry.legacyClaims,
        ),
      ),
      beforeRevision: 'e${published.length - 1}',
      revision: 'e${published.length}',
      changedPaths: const ['project.json'],
    );
  }
}

final leaveGuardMeeting = NarrativeEventRecord.configuredStructurallyUnchecked(
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
    records: [leaveGuardMeeting],
    legacyClaims: const [],
  ),
);

WorkspaceMemoryPort leaveGuardMemory() =>
    WorkspaceMemoryPort(manifest: _project)
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
