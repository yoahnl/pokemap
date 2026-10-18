import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'support/content_recipe_fixture.dart';

void main() {
  for (final id in ['orchard', 'observatory']) {
    test(
      'the $id recipe authors typed narrative and visual resources idempotently',
      () async {
        final root = await Directory.systemTemp.createTemp('canonical-recipe-');
        addTearDown(() => root.delete(recursive: true));
        final project = Directory('${root.path}/project')..createSync();
        final input = Directory('${root.path}/input')..createSync();
        final png = img.encodePng(
          img.Image(width: 4, height: 4, numChannels: 4)
            ..setPixelRgba(0, 0, 12, 34, 56, 127),
        );
        await File('${input.path}/sprite.png').writeAsBytes(png);
        await File('${project.path}/project.json').writeAsString(
          jsonEncode(
            ProjectManifest(name: id, maps: [], tilesets: []).toJson(),
          ),
        );
        final fact = NarrativeFactDefinition(id: 'fact_$id', label: id);
        final dialogue = ProjectDialogueEntry(
          id: '$id-intro',
          name: 'Synthetic introduction',
          relativePath: 'dialogues/$id.yarn',
        );
        final source = 'title: Intro\n---\nA synthetic $id line.\n===\n';
        final scene = SceneAsset(
          id: '$id-scene',
          name: 'Synthetic scene',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'done',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ],
          ),
        );
        final element = ProjectElementEntry(
          id: '$id-sprite',
          name: 'Synthetic sprite',
          tilesetId: '$id-atlas',
          categoryId: 'synthetic',
          frames: [
            const TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
        );
        final actions = <Map<String, dynamic>>[
          {
            'resource': {'kind': 'tileset', 'id': '$id-atlas'},
            'present': null,
            'absent': {
              'actionId': 'tileset.import_image',
              'parameters': {
                'tilesetId': '$id-atlas',
                'name': 'Synthetic atlas',
                'artifactHandle': {r'$binding': 'image'},
                'tileWidth': 4,
                'tileHeight': 4,
              },
            },
          },
          {
            'resource': {
              'kind': 'project',
              'id': 'project',
              'collection': 'elements',
              'memberId': element.id,
            },
            'matches': element.toJson(),
            'present': {
              'actionId': 'element.upsert',
              'parameters': {
                'element': element.toJson(),
                'category': const ProjectElementCategory(
                  id: 'synthetic',
                  name: 'Synthetic',
                ).toJson(),
              },
            },
            'absent': {
              'actionId': 'element.upsert',
              'parameters': {
                'element': element.toJson(),
                'category': const ProjectElementCategory(
                  id: 'synthetic',
                  name: 'Synthetic',
                ).toJson(),
              },
            },
          },
          {
            'resource': {'kind': 'fact', 'id': fact.id},
            'present': null,
            'absent': {
              'actionId': 'fact.create',
              'parameters': {'fact': fact.toJson()},
            },
          },
          {
            'resource': {'kind': 'dialogue', 'id': dialogue.id},
            'present': null,
            'absent': {
              'actionId': 'dialogue.create',
              'parameters': {'entry': dialogue.toJson(), 'source': source},
            },
          },
          {
            'resource': {
              'kind': 'project',
              'id': 'project',
              'collection': 'scenes',
              'memberId': scene.id,
            },
            'matches': scene.toJson(),
            'present': {
              'actionId': 'scene.upsert',
              'parameters': {'scene': scene.toJson()},
            },
            'absent': {
              'actionId': 'scene.upsert',
              'parameters': {'scene': scene.toJson()},
            },
          },
        ];
        final recipe = <String, dynamic>{
          'schemaVersion': 1,
          'id': id,
          'validation': 'authoring',
          'artifacts': {
            'image': {
              'input': 'media',
              'path': 'sprite.png',
              'mediaType': 'image/png',
              'sha256': sha256.convert(png).toString(),
            },
          },
          'actions': actions,
        };
        expect(
          await replayContentRecipeFixture(
            project,
            recipe,
            inputs: {'media': input},
          ),
          isNotEmpty,
        );
        expect(
          await replayContentRecipeFixture(
            project,
            recipe,
            inputs: {'media': input},
          ),
          isEmpty,
        );
        final bytes = await File('${project.path}/project.json').readAsBytes();
        final saved = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        );
        expect(saved.facts.single, fact);
        expect(saved.scenes.single.id, scene.id);
        expect(saved.elements.single.id, element.id);
        expect(
          await File(
            '${project.path}/${saved.tilesets.single.relativePath}',
          ).readAsBytes(),
          png,
        );
        expect(
          await File('${project.path}/${dialogue.relativePath}').readAsString(),
          source,
        );
        await File('${input.path}/sprite.png').writeAsString('replaced');
        await expectLater(
          replayContentRecipeFixture(project, recipe, inputs: {'media': input}),
          throwsFormatException,
        );
        expect(await File('${project.path}/project.json').readAsBytes(), bytes);
      },
    );
  }
}
