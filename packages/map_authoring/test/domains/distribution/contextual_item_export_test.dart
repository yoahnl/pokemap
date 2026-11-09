import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final contextual in [false, true]) {
    test(
        'canonical spatial export declares item capabilities contextual=$contextual',
        () async {
      final root =
          await Directory.systemTemp.createTemp('context-item-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final scene = SceneAsset(
          id: 'secret',
          name: 'Secret',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ], edges: [
            SceneEdge(
                id: 'edge',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow)
          ]));
      final original = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!))
              as Map<String, dynamic>);
      final project = original.copyWith(
          groups: const [
            ProjectMapGroup(
                id: 'cave', name: 'Cave', type: MapGroupType.dungeon)
          ],
          scenes: [
            if (contextual) scene
          ],
          pokemon:
              original.pokemon.copyWith(catalogFiles: {'items': 'items.json'}));
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map
          .copyWith(
              mapMetadata: map.mapMetadata.copyWith(
                  escapeRopeDungeonId: 'cave',
                  contextualItemUses: contextual
                      ? const [
                          ContextualItemUseRule(
                              id: 'secret-use',
                              itemId: 'rope',
                              sceneId: 'secret')
                        ]
                      : const []))
          .toJson()));
      files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
      files['project/items.json'] = utf8.encode(jsonEncode(
          const ProjectItemCatalog(schemaVersion: 1, entries: [
        ProjectItemDefinition(
            id: 'rope', displayName: 'Corde', pocketId: 'items')
      ]).toJson()));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final result = await const CanonicalGamePackageExportService().build(
          projectRoot: root,
          mode: GamePackageExportMode.localTest,
          profile: GamePackageExportProfile(
              gameId: 'games.test.contextual',
              gameVersion: '0.1.0',
              title: 'Context',
              authorName: 'Fixture',
              defaultLocale: 'fr',
              supportedLocales: ['fr']));
      expect(result.manifest.compatibility.requiredCapabilities,
          contains(OverworldItemCapabilities.spatialEscapeRopeCapabilityId));
      expect(
          result.manifest.compatibility.requiredCapabilities
              .contains(OverworldItemCapabilities.contextualUseCapabilityId),
          contextual);
      final archive =
          ZipDecoder().decodeBytes(result.packageBytes, verify: true);
      final exportedMap = MapData.fromJson(jsonDecode(
              utf8.decode(archive.findFile('project/maps/map.json')!.content))
          as Map<String, dynamic>);
      expect(
          exportedMap.contextualItemUses,
          contextual
              ? map.mapMetadata.copyWith(contextualItemUses: const [
                  ContextualItemUseRule(
                      id: 'secret-use', itemId: 'rope', sceneId: 'secret')
                ]).contextualItemUses
              : isEmpty);
      final payload = {
        for (final file
            in archive.files.where((file) => file.name.startsWith('project/')))
          file.name: file.content
      };
      final legacy = result.manifest.toJson();
      final compatibility = legacy['compatibility'] as Map;
      compatibility['requiredCapabilities'] =
          (compatibility['requiredCapabilities'] as List)
              .where((capability) =>
                  capability !=
                  (contextual
                      ? OverworldItemCapabilities.contextualUseCapabilityId
                      : OverworldItemCapabilities
                          .spatialEscapeRopeCapabilityId))
              .toList();
      final withoutCapability =
          const GamePackageManifestCodec().decodeJson(legacy);
      if (contextual) {
        expect(
            () => const GamePackageBuilder()
                .build(manifest: withoutCapability, payloadFiles: payload),
            throwsA(isA<GamePackageFormatException>()));
      } else {
        expect(
            () => const GamePackageBuilder()
                .build(manifest: withoutCapability, payloadFiles: payload),
            returnsNormally);
      }
    });
  }
}
