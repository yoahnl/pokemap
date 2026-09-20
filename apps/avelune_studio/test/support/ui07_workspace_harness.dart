import 'dart:io';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/features/stories/domain/story_port.dart';
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

class Ui07WorkspaceHarness {
  Ui07WorkspaceHarness._(
    this.source,
    this.maps,
    this.visuals,
    this.narrative,
    this.ports,
  );
  final Ui07StoryFixture source;
  final WidgetMapController maps;
  final StudioMapResources visuals;
  final Ui05NarrativePort narrative;
  final Ui07WorkspacePorts ports;
  final captureKey = GlobalKey();
  int closes = 0;

  static Future<Ui07WorkspaceHarness> create(
    WidgetTester tester, {
    bool withStories = true,
  }) async {
    await loadDesktopCaptureFonts();
    final source = await Ui07StoryFixture.create(withStories: withStories);
    final maps = WidgetMapController(source.session, source.maps, tester);
    await maps.initialize();
    final visuals = await StudioMapResources.load(
      source.session,
      maps.project!,
    );
    return Ui07WorkspaceHarness._(
      source,
      maps,
      visuals,
      Ui05NarrativePort(
        LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
        tester,
      ),
      Ui07WorkspacePorts(source, tester),
    );
  }

  Widget app({double textScale = 1}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: studioTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: RepaintBoundary(
      key: captureKey,
      child: MapWorkspaceScreen(
        controller: maps,
        loadVisuals: (_, _) async => visuals,
        narrativePort: narrative,
        storyPort: ports,
        scenePort: ports,
        runtimeBuilder: (_, _, _) => const SizedBox(),
        onClose: () async {
          closes++;
        },
        registerExitGuard: (_) {},
      ),
    ),
  );

  Future<void> settleWrites(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await WidgetResourcePort.pending;
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
  }

  Future<Map<String, List<int>>> mapBytes() async => {
    for (final entry in source.manifest.maps)
      entry.relativePath: await File(
        '${source.directory.path}/${entry.relativePath}',
      ).readAsBytes(),
  };
  Future<void> dispose() async {
    maps.dispose();
    await source.dispose();
  }
}

class Ui07WorkspacePorts implements StoryPort, ScenePort {
  Ui07WorkspacePorts(this.source, this.tester);
  final Ui07StoryFixture source;
  final WidgetTester tester;
  int storyWrites = 0, sceneWrites = 0;
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
  Future<ResourceMutationReceipt> publishStory({
    required String id,
    required StorylineAsset? base,
    required StorylineAsset? current,
    Set<String> requiredStoryIds = const {},
    Set<String> requiredFactIds = const {},
    Set<String> requiredSceneIds = const {},
  }) {
    storyWrites++;
    return _run(
      () => source.port.publishStory(
        id: id,
        base: base,
        current: current,
        requiredStoryIds: requiredStoryIds,
        requiredFactIds: requiredFactIds,
        requiredSceneIds: requiredSceneIds,
      ),
    );
  }

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) => _run(() => source.port.publishFact(base: base, current: current));
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) {
    sceneWrites++;
    return _run(
      () => LocalSceneAdapter(
        session: source.session,
        mapAdapter: source.maps,
      ).publishScene(base: base, current: current),
    );
  }
}
