import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_information_fixture.dart';
import '../domains/maps/border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture;
import '../support/glb_fixture.dart';

void main() {
  for (final cli in [false, true]) {
    test(
        '${cli ? 'CLI' : 'JSONL worker'} preserves explicit native Border playback and collision without starting default clips',
        () async {
      final fixture = spatialBorderAuthoringFixture();
      final bytes = animatedGlb();
      final model = ProjectModel3dEntry.fromJson({
        ...fixture.project.models3d.single.toJson(),
        'inspection': const GlbModel3dInspector().inspect(bytes).toJson()
      });
      final project = fixture.project.copyWith(
          models3d: [model],
          borderCatalog: const ProjectBorderCatalog.empty(),
          settings: fixture.project.settings.copyWith(
              defaultPlayerCharacterId: 'hero', tileWidth: 1, tileHeight: 1),
          tilesets: [
            const ProjectTilesetEntry(
                id: 'hero-sheet',
                name: 'Hero',
                relativePath: 'assets/hero.png',
                source: ProjectRegularAtlasTilesetSource(
                    assetId: 'hero-sprite',
                    pixelWidth: 1,
                    pixelHeight: 1,
                    tileWidth: 1,
                    tileHeight: 1))
          ],
          characters: [
            ProjectCharacterEntry(
                id: 'hero',
                name: 'Hero',
                tilesetId: 'hero-sheet',
                frameHeight: 1,
                animations: [
                  for (final direction in EntityFacing.values)
                    CharacterAnimation(
                        state: CharacterAnimationState.walk,
                        direction: direction,
                        sourceAssetId: 'hero-sprite',
                        frames: [
                          const CharacterAnimationFrame(
                              source: TilesetSourceRect(x: 0, y: 0))
                        ])
                ])
          ]);
      final host = await ResourceInformationFixture.create(
          project.copyWith(maps: [], models3d: []));
      addTearDown(host.dispose);
      final mapFile = File('${host.root.path}/maps/map.json');
      await mapFile.parent.create(recursive: true);
      await mapFile.writeAsString(jsonEncode(fixture.map.copyWith(layers: [
        MapLayer.border(
            id: 'border',
            name: 'Fence',
            content: BorderLayerContent(features: const []))
      ]).toJson()));
      final manifestFile = File('${host.root.path}/project.json');
      await manifestFile.writeAsString(jsonEncode(project.toJson()));
      final source = File('${host.root.path}/${model.relativePath}');
      await source.parent.create(recursive: true);
      await source.writeAsBytes(bytes);
      final artifact =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
      final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
      final heroBytes = img.encodePng(img.Image(width: 1, height: 1));
      final heroArtifact =
          ContentArtifactRef.fromBytes(heroBytes, mediaType: 'image/png');
      await File('${host.root.path}/assets/hero.png').writeAsBytes(heroBytes);
      await File('${host.root.path}/${assetBlobStorageKey(heroArtifact)}')
          .writeAsBytes(heroBytes);
      await File('${host.root.path}/assets/.pokemap-assets.json')
          .writeAsString(jsonEncode(AssetCatalog(records: [
        AssetRecord(
            id: model.sourceAssetId,
            logicalPath: model.relativePath,
            artifact: artifact),
        AssetRecord(
            id: 'hero-sprite',
            logicalPath: 'assets/hero.png',
            artifact: heroArtifact)
      ]).toJson()));
      await host.command('close', {'projectHandle': host.project});

      Future<AuthoringResult> Function(String, Map<String, Object?>) command =
          host.command;
      if (cli) {
        expect(Platform.resolvedExecutable, isNot(contains('flutter_tester')));
        final process = await Process.start(Platform.resolvedExecutable, [
          'run',
          'bin/pokemap_authoring.dart',
          '--root',
          host.root.path,
        ]);
        final responses = StreamIterator(process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter()));
        final errors = process.stderr.transform(utf8.decoder).join();
        addTearDown(() async {
          await process.stdin.close();
          expect(
              await process.exitCode.timeout(const Duration(seconds: 30)), 0);
          expect(await errors, isEmpty);
          await responses.cancel();
        });
        var sequence = 0;
        command = (name, args) async {
          final id = 'border-playback-${sequence++}';
          process.stdin
              .writeln(jsonEncode({'id': id, 'command': name, 'args': args}));
          await process.stdin.flush();
          expect(
              await responses.moveNext().timeout(const Duration(seconds: 30)),
              isTrue);
          final response = jsonDecode(responses.current);
          expect(response['requestId'], id);
          return AuthoringResult.fromJson(response);
        };
      }
      final described = await command('describe', {});
      expect(described.status, AuthoringResultStatus.success);
      final actions = (described.data['mutationActions'] as List).cast<Map>();
      final draftContract = actions.singleWhere(
          (value) => value['id'] == 'border.blueprint.draft.upsert');
      for (final field in [
        'animationIndex',
        'animationLoop',
        'animationSpeed',
        'blocksMovement'
      ]) {
        expect(draftContract['summary'], contains(field));
      }
      expect((draftContract['extensions'] as Map)['catalogFormatVersion'], 5);
      expect(
          actions.singleWhere(
              (value) => value['id'] == 'border.blueprint.publish')['summary'],
          contains('null animationIndex does not start a clip'));
      final opened = await command('open', {'projectRoot': host.root.path});
      expect(opened.status, AuthoringResultStatus.success,
          reason: jsonEncode(opened.toJson()));
      var handle = opened.data['projectHandle'] as String;
      var workspace = opened.data['workspaceHandle'] as String;
      var sequence = 0;
      Future<AuthoringResult> plan(
          String action, Map<String, Object?> parameters) async {
        final beforeManifest = await manifestFile.readAsBytes();
        final beforeMap = await mapFile.readAsBytes();
        final validated = await command('validate', {'projectHandle': handle});
        expect(validated.status, AuthoringResultStatus.success);
        final id = 'native-playback-${sequence++}';
        final result = await command('plan', {
          'projectHandle': handle,
          'request': AuthoringRequest(
                  requestId: id,
                  actionId: action,
                  actionVersion: 1,
                  workspaceHandle: workspace,
                  expectedRevision:
                      validated.data['snapshotRevision'] as String,
                  parameters: parameters,
                  idempotencyKey: id)
              .toJson()
        });
        expect(await manifestFile.readAsBytes(), beforeManifest);
        expect(await mapFile.readAsBytes(), beforeMap);
        return result;
      }

      Future<void> mutate(
          String action, Map<String, Object?> parameters) async {
        final planned = await plan(action, parameters);
        expect(planned.status, AuthoringResultStatus.success,
            reason: jsonEncode(planned.toJson()));
        final applied = await command('apply', {
          'projectHandle': handle,
          'planId': planned.data['planId'],
          'operationId': 'native-playback-apply-${sequence++}'
        });
        expect(applied.status, AuthoringResultStatus.success,
            reason: jsonEncode(applied.toJson()));
      }

      Map<String, dynamic> draft(Map<String, Object?> settings) {
        final value = encodeBorderBlueprintRecordJson(
            fixture.project.borderCatalog.records.single,
            formatVersion: 5);
        for (final primitive in ((value['draft'] as Map)['definition']
            as Map)['primitives'] as List) {
          for (final field in [
            'animationIndex',
            'animationLoop',
            'animationSpeed',
            'blocksMovement'
          ]) {
            primitive.remove(field);
          }
          (primitive as Map).addAll(settings);
        }
        return value;
      }

      for (final invalid in <Map<String, Object?>>[
        {'animationIndex': -1},
        {'animationIndex': .5},
        {'animationIndex': '0'},
        {'animationLoop': 'false'},
        {'animationLoop': null},
        {'animationSpeed': 0},
        {'animationSpeed': -.5},
        {'animationSpeed': 16.1},
        {'animationSpeed': '1'},
        {'blocksMovement': 0},
        {'blocksMovement': null},
      ]) {
        final rejected = await plan(
            'border.blueprint.draft.upsert', {'record': draft(invalid)});
        expect(rejected.status, AuthoringResultStatus.failure,
            reason: jsonEncode(invalid));
      }
      await mutate('border.blueprint.draft.upsert', {
        'record': draft({'animationIndex': 1})
      });
      final missingClip =
          await plan('border.blueprint.publish', {'blueprintId': 'fence'});
      expect(missingClip.status, AuthoringResultStatus.failure);
      expect(jsonEncode(missingClip.toJson()),
          contains('border.blueprint.publication_invalid'));
      await mutate('border.blueprint.draft.upsert', {
        'record': draft({
          'animationIndex': 0,
          'animationLoop': false,
          'animationSpeed': .5,
          'blocksMovement': false
        })
      });
      await mutate('border.blueprint.publish', {'blueprintId': 'fence'});
      final queried = await command('query', {
        'projectHandle': handle,
        'request': AuthoringQueryRequest(
            resourceKind: 'borderBlueprint',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: ['fence']).toJson()
      });
      expect(queried.status, AuthoringResultStatus.success);
      final record = (queried.data['items'] as List).single as Map;
      for (final section in ['draft', 'latestPublished']) {
        final primitives = ((record[section] as Map)['definition']
            as Map)['primitives'] as List;
        for (final primitive in primitives) {
          expect(primitive['animationIndex'], 0);
          expect(primitive['animationLoop'], isFalse);
          expect(primitive['animationSpeed'], .5);
          expect(primitive['blocksMovement'], isFalse);
        }
      }
      await mutate('border_layer.feature_create', {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'fence',
        'blueprintId': 'fence',
        'name': 'Fence',
        'seed': '17',
        'geometry': {
          'kind': 'stroke',
          'strokes': [
            {
              'id': 'line',
              'closed': false,
              'points': [
                for (final x in [1, 2, 3]) {'x': x, 'y': 1}
              ]
            }
          ]
        }
      });
      await mutate('border_layer.materialize_apply',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'});
      final materialized =
          MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(materialized.spatialScene!.instances, hasLength(3));
      for (final instance in materialized.spatialScene!.instances) {
        expect(instance.animationIndex, 0);
        expect(instance.animationLoop, isFalse);
        expect(instance.animationSpeed, .5);
        expect(instance.blocksMovement, isFalse);
      }
      final savedManifest = await manifestFile.readAsBytes();
      final savedMap = await mapFile.readAsBytes();
      await command('close', {'projectHandle': handle});
      final reopened = await command('open', {'projectRoot': host.root.path});
      expect(reopened.status, AuthoringResultStatus.success);
      handle = reopened.data['projectHandle'] as String;
      workspace = reopened.data['workspaceHandle'] as String;
      final restored = await command('query', {
        'projectHandle': handle,
        'request': AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: ['map']).toJson()
      });
      expect(restored.status, AuthoringResultStatus.success);
      final restoredMap = Map<String, dynamic>.from(
          (restored.data['items'] as List).single as Map)
        ..remove('resourceKind');
      expect(MapData.fromJson(restoredMap), materialized);
      expect(await manifestFile.readAsBytes(), savedManifest);
      expect(await mapFile.readAsBytes(), savedMap);
      final defaultRecord = draft({})..['id'] = 'default-fence';
      await mutate('border.blueprint.draft.upsert', {'record': defaultRecord});
      await mutate(
          'border.blueprint.publish', {'blueprintId': 'default-fence'});
      await mutate('border_layer.feature_create', {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'default-fence',
        'blueprintId': 'default-fence',
        'name': 'Default fence',
        'seed': '17',
        'geometry': {
          'kind': 'stroke',
          'strokes': [
            {
              'id': 'line',
              'closed': false,
              'points': [
                for (final x in [1, 2, 3]) {'x': x, 'y': 2}
              ]
            }
          ]
        }
      });
      await mutate('border_layer.materialize_apply',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'default-fence'});
      final defaultMap =
          MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(defaultMap.spatialScene!.instances, hasLength(6));
      final existingIds = materialized.spatialScene!.instances
          .map((instance) => instance.id)
          .toSet();
      expect(
          defaultMap.spatialScene!.instances
              .where((instance) => existingIds.contains(instance.id))
              .toList(),
          materialized.spatialScene!.instances);
      for (final instance in defaultMap.spatialScene!.instances
          .where((instance) => !existingIds.contains(instance.id))) {
        expect(instance.animationIndex, isNull);
        expect(instance.animationLoop, isTrue);
        expect(instance.animationSpeed, 1);
        expect(instance.blocksMovement, isTrue);
      }
      final projection = await const RuntimeProjectProjectionBuilder().build(
          projectRoot: host.root,
          profile: GamePackageExportProfile(
              gameId: 'games.example.border-playback',
              gameVersion: '0.1.0',
              title: 'Native Border playback',
              authorName: 'Yoahn',
              defaultLocale: 'fr',
              supportedLocales: ['fr']));
      final exported = MapData.fromJson(jsonDecode(
          utf8.decode(projection.payloadFiles['project/maps/map.json']!)));
      expect(exported.spatialScene, defaultMap.spatialScene);
      expect(projection.payloadFiles['project/${model.relativePath}'], bytes);
      await command('close', {'projectHandle': handle});
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
