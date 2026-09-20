import 'dart:io';
import 'package:avelune_studio/features/cinematics/domain/cinematic_port.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'load_desktop_capture_fonts.dart';
import 'm2_ui_fixture.dart';
import 'ui05_narrative_fixture.dart';
import 'ui07_story_fixture.dart';
import 'ui07_workspace_harness.dart';
import 'ui08_event_fixture.dart';

class Ui08WorkspaceHarness {
  Ui08WorkspaceHarness._(
    this.source,
    this.maps,
    this.visuals,
    this.narrative,
    this.events,
    this.ports,
  );
  final Ui07StoryFixture source;
  final WidgetMapController maps;
  final StudioMapResources visuals;
  final Ui05NarrativePort narrative;
  final Ui08EventPort events;
  final Ui07WorkspacePorts ports;
  final captureKey = GlobalKey();
  static Future<Ui08WorkspaceHarness> create(
    WidgetTester tester, {
    Ui07StoryFixture? fixture,
  }) async {
    await loadDesktopCaptureFonts();
    final source = fixture ?? await createUi08Fixture();
    final mapPort = Ui08MapPort(source.maps, tester);
    final maps = WidgetMapController(source.session, mapPort, tester);
    await maps.initialize();
    final visuals = await StudioMapResources.load(
      source.session,
      maps.project!,
    );
    mapPort.interactive = true;
    return Ui08WorkspaceHarness._(
      source,
      maps,
      visuals,
      Ui05NarrativePort(
        LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
        tester,
      ),
      Ui08EventPort(
        LocalEventAdapter(session: source.session, mapAdapter: source.maps),
        tester,
      ),
      Ui07WorkspacePorts(source, tester),
    );
  }

  Widget app({
    double textScale = 1,
    DialoguePort? dialoguePort,
    CinematicPort? cinematicPort,
  }) => RepaintBoundary(
    key: captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: studioTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: MapWorkspaceScreen(
        controller: maps,
        loadVisuals: (_, _) async => visuals,
        narrativePort: narrative,
        scenePort: ports,
        storyPort: ports,
        eventPort: events,
        dialoguePort: dialoguePort,
        cinematicPort: cinematicPort,
        runtimeBuilder: (_, _, _) => const SizedBox(),
        onClose: () async {},
        registerExitGuard: (_) {},
      ),
    ),
  );
  Future<Map<String, List<int>>> mapBytes() async => {
    for (final entry in maps.project!.maps)
      entry.relativePath: await File(
        '${source.directory.path}/${entry.relativePath}',
      ).readAsBytes(),
  };
  Future<void> dispose() async {
    maps.dispose();
    await source.dispose();
  }
}

class Ui08MapPort implements MapWorkspacePort {
  Ui08MapPort(this.delegate, this.tester);
  final MapWorkspacePort delegate;
  final WidgetTester tester;
  bool interactive = false;
  Future<T> _run<T>(Future<T> Function() action) async {
    if (!interactive) return action();
    final operation = tester.runAsync(() async {
      try {
        return (await action(), null);
      } catch (error) {
        return (null, error);
      }
    });
    WidgetResourcePort.pending = operation;
    try {
      final result = (await operation)!;
      if (result.$2 case final error?) throw error;
      return result.$1!;
    } finally {
      if (identical(WidgetResourcePort.pending, operation)) {
        WidgetResourcePort.pending = null;
      }
    }
  }

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      _run(() => delegate.loadProject(session));
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) => _run(() => delegate.loadMap(session, entry));
  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => delegate.saveMap(session, base, current);
}

class Ui08EventPort implements EventPort, EventRegistryModePort {
  Ui08EventPort(this.delegate, this.tester);
  final LocalEventAdapter delegate;
  final WidgetTester tester;
  int writes = 0;
  Future<T> _run<T>(Future<T> Function() action) async {
    final operation = tester.runAsync(() async {
      try {
        return (await action(), null);
      } catch (error) {
        return (null, error);
      }
    });
    WidgetResourcePort.pending = operation;
    try {
      final result = (await operation)!;
      if (result.$2 case final error?) throw error;
      return result.$1!;
    } finally {
      if (identical(WidgetResourcePort.pending, operation)) {
        WidgetResourcePort.pending = null;
      }
    }
  }

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) {
    writes++;
    return _run(
      () => delegate.publishEvent(id: id, base: base, current: current),
    );
  }

  @override
  Future<ResourceMutationReceipt> changeMode({
    required NarrativeEventRegistry? base,
    required EventSystemMode mode,
  }) => _run(() => delegate.changeMode(base: base, mode: mode));
}
