import 'dart:ui' show AppExitResponse;

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/event_providers.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/app/di/studio_lifecycle_providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

class _Events implements EventPort {
  _Events(this.maps, this.memory);

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

WorkspaceMemoryPort _memory() =>
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

void main() {
  late ControlledProjectSessionPort sessions;
  late WorkspaceMemoryPort memory;
  late ProviderContainer container;
  late _Events events;

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
    memory = _memory();
    events = _Events(controller, memory);
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
    await tester.tap(
      find.byKey(const ValueKey('map-story-element-entity:luth')),
    );
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
      find.byKey(ValueKey('map-story-behaviour-name-${_meeting.id}'));

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

  testWidgets('unsaved behaviours show in the header of every space', (
    tester,
  ) async {
    await open(tester);
    await editBehaviour(tester);
    expect(find.text('Non enregistré'), findsOneWidget);

    for (final space in ['construction', 'gameplay', 'ambiance', 'story']) {
      await tester.tap(find.byKey(ValueKey('map-space-$space')));
      await settle(tester);
      expect(find.text('Non enregistré'), findsOneWidget, reason: space);
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('studio-save')))
            .onPressed,
        isNotNull,
        reason: space,
      );
    }
  });

  testWidgets('the home entry asks first and Annuler keeps everything', (
    tester,
  ) async {
    await open(tester);
    editMap();
    await tester.pump();

    await goHome(tester);
    expect(find.text('Enregistrer les modifications ?'), findsOneWidget);
    await choose(tester, 'cancel');

    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(sessions.released, isEmpty);
    expect(memory.writes, 0);
    expect(controller().active!.current.name, 'Clairière modifiée');
    expect(find.text('Non enregistré'), findsOneWidget);
  });

  testWidgets('Ne pas enregistrer leaves the project without saving', (
    tester,
  ) async {
    await open(tester);
    editMap();
    await tester.pump();

    await goHome(tester);
    await choose(tester, 'discard');

    expect(sessions.released, [exampleA]);
    expect(find.byKey(const ValueKey('studio-home')), findsOneWidget);
    expect(memory.writes, 0);
    expect(events.published, isEmpty);
  });

  testWidgets('Enregistrer saves the map, then the behaviours, then leaves', (
    tester,
  ) async {
    await open(tester);
    await editBehaviour(tester);
    editMap();
    await tester.pump();

    await goHome(tester);
    await choose(tester, 'save');

    expect(memory.writes, 1);
    expect(events.published, [
      (id: _meeting.id, name: 'meeting', mapWrites: 1),
    ]);
    expect(sessions.released, [exampleA]);
    expect(find.byKey(const ValueKey('studio-home')), findsOneWidget);
  });

  testWidgets('a refused save keeps the project open', (tester) async {
    await open(tester);
    editMap();
    memory.failSave = true;
    await tester.pump();

    await goHome(tester);
    await choose(tester, 'save');

    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(sessions.released, isEmpty);
    expect(find.text('Échec de l’enregistrement'), findsOneWidget);
  });

  testWidgets('a clean project leaves without asking', (tester) async {
    await open(tester);
    await goHome(tester);

    expect(find.byKey(const ValueKey('studio-save-choice')), findsNothing);
    expect(sessions.released, [exampleA]);
  });

  testWidgets('saving while typing commits the field first', (tester) async {
    await open(tester);
    await openMeeting(tester);
    await tester.enterText(nameField(), 'Rencontre');
    await tester.pump();

    await pressWithControl(tester, LogicalKeyboardKey.keyS);

    expect(events.published, [
      (id: _meeting.id, name: 'Rencontre', mapWrites: 0),
    ]);
    expect(find.text('Enregistré'), findsOneWidget);
  });

  testWidgets('the save button commits the field being typed', (tester) async {
    await open(tester);
    editMap();
    await openMeeting(tester);
    await tester.enterText(nameField(), 'Rencontre');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('studio-save')));
    await settle(tester);

    expect(memory.writes, 1);
    expect(events.published, [
      (id: _meeting.id, name: 'Rencontre', mapWrites: 1),
    ]);
    expect(find.text('Enregistré'), findsOneWidget);
  });

  testWidgets('leaving while typing keeps the typed text', (tester) async {
    await open(tester);
    await openMeeting(tester);
    await tester.enterText(nameField(), 'Rencontre');
    await tester.pump();

    await goHome(tester);
    await choose(tester, 'save');

    expect(events.published, [
      (id: _meeting.id, name: 'Rencontre', mapWrites: 0),
    ]);
    expect(sessions.released, [exampleA]);
  });

  testWidgets('undo inside a text field never undoes the map', (tester) async {
    await open(tester);
    editMap();
    await openMeeting(tester);
    await tester.enterText(nameField(), 'Rencontre');
    await tester.pump();

    await pressWithControl(tester, LogicalKeyboardKey.keyZ);

    expect(controller().active!.current.name, 'Clairière modifiée');
    expect(events.published, isEmpty);
  });

  testWidgets('a project switch asks the same guard first', (tester) async {
    await open(tester);
    editMap();
    await tester.pump();
    final switching = ProjectSessionOpenController(
      session: container.read(projectSessionControllerProvider),
      chooseDirectory: () async => exampleB.directoryPath,
      allowSwitch: container
          .read(studioLifecycleControllerProvider)
          .confirmLeave,
    );
    addTearDown(switching.dispose);

    final opened = switching.open(browse: true);
    await settle(tester);
    await choose(tester, 'cancel');

    expect(await opened, isFalse);
    expect(sessions.requests, [exampleA.directoryPath]);
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(controller().active!.current.name, 'Clairière modifiée');
  });

  testWidgets('quitting asks first and Annuler keeps the app open', (
    tester,
  ) async {
    sizeView(tester);
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    addTearDown(session.dispose);
    final opening = session.open(exampleA.directoryPath);
    port.pending.single.complete(exampleA);
    await opening;
    memory = _memory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionControllerProvider.overrideWith((ref) => session),
          mapWorkspacePortProvider(exampleA).overrideWithValue(memory),
          workspaceVisualsLoaderProvider.overrideWithValue(
            (session, manifest) async => WorkspaceTestVisuals(),
          ),
        ],
        child: const StudioApp(),
      ),
    );
    await settle(tester);
    container = ProviderScope.containerOf(
      tester.element(find.byType(StudioApp)),
      listen: false,
    );
    editMap();
    await tester.pump();

    final cancelled = tester.binding.handleRequestAppExit();
    await settle(tester);
    await choose(tester, 'cancel');
    expect(await cancelled, AppExitResponse.cancel);
    expect(session.disposed, isFalse);
    expect(port.released, isEmpty);
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(controller().dirty, isTrue);

    final left = tester.binding.handleRequestAppExit();
    await settle(tester);
    await choose(tester, 'discard');
    expect(await left, AppExitResponse.exit);
    expect(memory.writes, 0);
    expect(session.disposed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
