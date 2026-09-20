import 'dart:convert';
import 'dart:io';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test('scene publication needs no map and reopens canonical data', () async {
    final temporary = await Directory.systemTemp.createTemp('ui06_no_map_');
    final root = Directory(await temporary.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    const project = ProjectManifest(
      name: 'Scènes seules',
      maps: [],
      tilesets: [],
    );
    await File(
      '${root.path}/project.json',
    ).writeAsString(jsonEncode(project.toJson()));
    final session = ProjectSession(
      sessionId: root.path,
      name: project.name,
      directoryPath: root.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadProject(session);
    final scene = createSceneDraftInProject(
      project,
      name: 'Autonome',
    ).createdScene;
    final receipt = await LocalSceneAdapter(
      session: session,
      mapAdapter: maps,
    ).publishScene(base: null, current: scene);
    expect(receipt.catalog.changedPaths, ['project.json']);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(session);
    expect(reopened.maps, isEmpty);
    expect(reopened.scenes.single, scene);
  });

  group('real project', () {
    late Ui06SceneFixture fixture;
    late LocalSceneAdapter port;
    setUp(() async {
      fixture = await Ui06SceneFixture.create();
      port = LocalSceneAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
      );
    });
    tearDown(() => fixture.dispose());

    test(
      'target-only save preserves resource published since scene opened and all map bytes',
      () async {
        final mapFiles = [
          for (final entry in fixture.manifest.maps)
            File('${fixture.directory.path}/${entry.relativePath}'),
        ];
        final beforeMaps = [
          for (final file in mapFiles) await file.readAsBytes(),
        ];
        final imported =
            await LocalResourceAdapter(
              session: fixture.session,
              mapAdapter: fixture.maps,
            ).importImage(
              ResourceImageImport(
                sourcePath: '${fixture.directory.path}/assets/atelier.png',
                name: 'Atlas importé pendant édition',
                tileWidth: 16,
                tileHeight: 16,
              ),
            );
        final changed = updateSceneNodeLayout(
          fixture.scene,
          nodeId: fixture.scene.graph.nodes.last.id,
          x: 1000,
          y: 350,
        ).updatedScene;
        final receipt = await port.publishScene(
          base: fixture.scene,
          current: changed,
        );
        final reopened = await LocalMapWorkspaceAdapter().loadProject(
          fixture.session,
        );
        expect(reopened.scenes.single, changed);
        expect(
          reopened.tilesets.firstWhere(
            (value) => value.id == imported.createdTilesetId,
          ),
          imported.manifest.tilesets.firstWhere(
            (value) => value.id == imported.createdTilesetId,
          ),
        );
        expect(receipt.catalog.changedPaths, ['project.json']);
        expect([
          for (final file in mapFiles) await file.readAsBytes(),
        ], beforeMaps);
      },
    );

    test(
      'stale same-scene base is rejected after internal publication',
      () async {
        final changed = updateSceneNodeLayout(
          fixture.scene,
          nodeId: fixture.scene.graph.nodes.last.id,
          x: 1000,
          y: 350,
        ).updatedScene;
        await port.publishScene(base: fixture.scene, current: changed);
        final bytes = await File(
          '${fixture.directory.path}/project.json',
        ).readAsBytes();
        await expectLater(
          port.publishScene(base: fixture.scene, current: fixture.scene),
          throwsA(isA<SceneFailure>()),
        );
        expect(
          await File('${fixture.directory.path}/project.json').readAsBytes(),
          bytes,
        );
      },
    );

    test('external revision change is never overwritten', () async {
      final file = File('${fixture.directory.path}/project.json');
      final external = '${await file.readAsString()}\n';
      await file.writeAsString(external);
      await expectLater(
        port.publishScene(base: fixture.scene, current: fixture.scene),
        throwsA(isA<SceneFailure>()),
      );
      expect(await file.readAsString(), external);
    });

    test(
      'incomplete graph is refused without touching valid published file',
      () async {
        final file = File('${fixture.directory.path}/project.json');
        final before = await file.readAsBytes();
        final incomplete = removeSceneEdgeDraft(
          fixture.scene,
          fixture.scene.graph.edges.first.id,
        ).updatedScene;
        await expectLater(
          port.publishScene(base: fixture.scene, current: incomplete),
          throwsA(isA<SceneFailure>()),
        );
        expect(await file.readAsBytes(), before);
      },
    );

    test(
      'write interruption with external conflict preserves last valid scene',
      () async {
        final file = File('${fixture.directory.path}/project.json');
        final external = '${await file.readAsString()}\n';
        var injected = false;
        final failing = LocalSceneAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
          faultInjector: (context) async {
            if (!injected &&
                context.checkpoint ==
                    AuthoringTransactionCheckpoint.afterJournalPrepared) {
              injected = true;
              await file.writeAsString(external);
              throw const FileSystemException(
                'Injected external conflict before scene promotion',
              );
            }
          },
        );
        final changed = updateSceneNodeLayout(
          fixture.scene,
          nodeId: fixture.scene.graph.nodes.last.id,
          x: 1100,
          y: 400,
        ).updatedScene;
        await expectLater(
          failing.publishScene(base: fixture.scene, current: changed),
          throwsA(isA<SceneFailure>()),
        );
        expect(injected, true);
        expect(await file.readAsString(), external);
        expect(
          (await LocalMapWorkspaceAdapter().loadProject(
            fixture.session,
          )).scenes.single,
          fixture.scene,
        );
      },
    );

    test(
      'interrupted promotion is recovered and verified before success',
      () async {
        var interrupted = false;
        final recovering = LocalSceneAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
          faultInjector: (context) {
            if (!interrupted &&
                context.checkpoint ==
                    AuthoringTransactionCheckpoint.afterResourcePromoted) {
              interrupted = true;
              throw const FileSystemException(
                'Injected scene promotion failure',
              );
            }
          },
        );
        final changed = updateSceneNodeLayout(
          fixture.scene,
          nodeId: fixture.scene.graph.nodes.last.id,
          x: 1000,
          y: 350,
        ).updatedScene;
        final receipt = await recovering.publishScene(
          base: fixture.scene,
          current: changed,
        );
        expect(interrupted, true);
        expect(receipt.scene, changed);
        expect(
          (await LocalMapWorkspaceAdapter().loadProject(
            fixture.session,
          )).scenes.single,
          changed,
        );
      },
    );
  });
}
