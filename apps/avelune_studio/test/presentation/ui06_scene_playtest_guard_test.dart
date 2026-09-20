import 'dart:async';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  testWidgets(
    'scene changed while the following real map save waits cannot launch an old scene',
    (tester) async {
      final fixture = (await tester.runAsync(Ui06SceneFixture.create))!;
      addTearDown(fixture.dispose);
      final delayed = (await tester.runAsync(
        () async => _DelayedMapPort(fixture.maps),
      ))!;
      final maps = MapWorkspaceController(fixture.session, delayed);
      addTearDown(maps.dispose);
      await tester.runAsync(maps.initialize);
      final scenes = SceneWorkspaceController(
        maps,
        LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
        changed: () {},
      );
      addTearDown(scenes.dispose);
      expect(scenes.open(fixture.scene.id), isTrue);
      final scene = scenes.active!;
      scene.rename('Rencontre préparée');
      final savedSnapshot = scene.current;
      maps.active!.commit(
        maps.active!.current.copyWith(name: 'Carte modifiée'),
      );
      late WorkspaceActions actions;
      var launches = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              actions = WorkspaceActions(
                controller: maps,
                context: () => context,
                mounted: () => true,
                changed: () {},
                resources: () => null,
                narrative: () => null,
                scenes: () => scenes,
                runtimeBuilder: (_, _, _) {
                  launches++;
                  return const SizedBox();
                },
              );
              return const Scaffold(body: Text('Éditeur'));
            },
          ),
        ),
      );
      late Future<void> running;
      var completed = false;
      await tester.runAsync(() async {
        running = actions.test().whenComplete(() => completed = true);
        try {
          await Future.any([
            delayed.entered.future,
            running.then((_) {
              if (!delayed.entered.isCompleted) {
                throw StateError(
                  'Test arrêté avant la sauvegarde carte : ${scenes.error}',
                );
              }
            }),
          ]).timeout(const Duration(seconds: 5));
          expect(scene.dirty, isFalse);
          expect(scene.saved, savedSnapshot);
          expect(scene.move('start', 90, 260), isTrue);
          expect(scene.dirty, isTrue);
        } finally {
          if (!delayed.release.isCompleted) delayed.release.complete();
        }
        await delayed.finished.future.timeout(const Duration(seconds: 5));
        await running.timeout(const Duration(seconds: 5));
      });
      await tester.pump();
      expect(launches, 0);
      expect(completed, isTrue);
      expect(actions.testing, isFalse);
      expect(
        scene.error,
        'Une scène a encore changé. Enregistrez-la avant de tester.',
      );
      expect(scenes.error, scene.error);
      expect(scene.dirty, isTrue);
      expect(maps.active!.dirty, isFalse);
      final fresh = (await tester.runAsync(
        () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
      ))!;
      expect(fresh.scenes.single, savedSnapshot);
      expect(scene.current, isNot(savedSnapshot));
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _DelayedMapPort implements MapWorkspacePort {
  _DelayedMapPort(this.delegate);
  final MapWorkspacePort delegate;
  final entered = Completer<void>();
  final release = Completer<void>();
  final finished = Completer<void>();
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      delegate.loadProject(session);
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) => delegate.loadMap(session, entry);
  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    entered.complete();
    await release.future;
    try {
      return await delegate.saveMap(session, base, current);
    } finally {
      finished.complete();
    }
  }
}
