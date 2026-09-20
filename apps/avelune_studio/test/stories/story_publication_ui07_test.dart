import 'dart:convert';
import 'dart:io';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/stories/domain/story_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import '../support/story_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test(
    'story action preserves concurrent image import and every map byte',
    () async {
      final fixture = await Ui06SceneFixture.create();
      addTearDown(fixture.dispose);
      final mapFiles = [
        for (final map in fixture.manifest.maps)
          File('${fixture.directory.path}/${map.relativePath}'),
      ];
      final mapBytes = [for (final file in mapFiles) await file.readAsBytes()];
      final imported =
          await LocalResourceAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ).importImage(
            ResourceImageImport(
              sourcePath: '${fixture.directory.path}/assets/atelier.png',
              name: 'Import pendant histoire',
              tileWidth: 16,
              tileHeight: 16,
            ),
          );
      final story = backendStory('trip');
      final receipt = await LocalStoryAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
      ).publishStory(id: story.id, base: null, current: story);
      expect(receipt.changedPaths, ['project.json']);
      final reopened = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(reopened.storylines, [story]);
      expect(reopened.tilesets, imported.manifest.tilesets);
      expect(reopened.scenes, fixture.manifest.scenes);
      for (var i = 0; i < mapFiles.length; i++) {
        expect(await mapFiles[i].readAsBytes(), mapBytes[i]);
      }
    },
  );

  test(
    'same aggregate conflict and vanished target are refused without overwrite',
    () async {
      final main = backendStory('main'), side = backendStory('side');
      final f = await StoryBackendFixture.create(stories: [main, side]);
      addTearDown(f.dispose);
      final external = main.copyWith(title: 'Externe');
      await f.port.publishStory(id: main.id, base: main, current: external);
      await expectLater(
        f.port.publishStory(
          id: main.id,
          base: main,
          current: main.copyWith(title: 'Local'),
        ),
        throwsA(isA<StoryFailure>()),
      );
      await f.port.publishStory(id: main.id, base: external, current: null);
      final before = await File(
        '${f.directory.path}/project.json',
      ).readAsBytes();
      final linked = side.copyWith(
        relationships: [
          StorylineRelationship(
            id: 'r',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: side.id,
            targetStorylineId: main.id,
          ),
        ],
      );
      await expectLater(
        f.port.publishStory(
          id: side.id,
          base: side,
          current: linked,
          requiredStoryIds: {main.id},
        ),
        throwsA(isA<StoryFailure>()),
      );
      expect(
        await File('${f.directory.path}/project.json').readAsBytes(),
        before,
      );
    },
  );

  test(
    'interrupted promotion recovers; external journal conflict keeps draft and file',
    () async {
      final base = backendStory('trip');
      final f = await StoryBackendFixture.create(stories: [base]);
      addTearDown(f.dispose);
      var interrupted = false;
      final recovering = LocalStoryAdapter(
        session: f.workspace.session,
        mapAdapter: f.maps,
        faultInjector: (context) {
          if (!interrupted &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
            interrupted = true;
            throw const FileSystemException('Injected promotion failure');
          }
        },
      );
      final changed = base.copyWith(title: 'Nouveau titre');
      await recovering.publishStory(id: base.id, base: base, current: changed);
      expect(interrupted, true);
      expect((await f.readFresh()).storylines.single, changed);
      final file = File('${f.directory.path}/project.json');
      final external = '${await file.readAsString()}\n';
      var conflicted = false;
      final failing = LocalStoryAdapter(
        session: f.workspace.session,
        mapAdapter: f.maps,
        faultInjector: (context) async {
          if (!conflicted &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalPrepared) {
            conflicted = true;
            await file.writeAsString(external);
            throw const FileSystemException('Injected external conflict');
          }
        },
      );
      await expectLater(
        failing.publishStory(
          id: base.id,
          base: changed,
          current: changed.copyWith(title: 'Non écrit'),
        ),
        throwsA(isA<Exception>()),
      );
      expect(conflicted, true);
      expect(await file.readAsString(), external);
      expect(
        ProjectManifest.fromJson(
          jsonDecode(external) as Map<String, dynamic>,
        ).storylines.single,
        changed,
      );
    },
  );
}
