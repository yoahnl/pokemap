import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

import '../../map_gameplay/test/support/border_jump_fixture.dart';

void main() {
  for (final partitioned in [false, true]) {
    test(
      'narrative hydration skips decorative Border roots partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'runtime-narrative-roots-',
        );
        addTearDown(() => root.delete(recursive: true));
        final fixture = BorderJumpFixture();
        final project = _project(fixture);
        final map = fixture.map.copyWith(
          tilesetId: 'terrain',
          placedElements: const [
            MapPlacedElement(
              id: 'decor',
              layerId: 'objects',
              elementId: 'decor',
              pos: GridPos(x: 1, y: 1),
            ),
          ],
          entities: [
            const MapEntity(
              id: 'nurse',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 1, y: 2),
              npc: MapEntityNpcData(characterId: 'hero'),
            ),
            const MapEntity(
              id: 'object',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 2, y: 2),
              editorVisual: MapEntityEditorVisual(elementId: 'entity-visual'),
            ),
            MapEntity(
              id: 'healing-balls',
              kind: MapEntityKind.custom,
              pos: const GridPos(x: 3, y: 2),
              blocksMovement: false,
              healingDisplay: MapEntityHealingDisplayData(
                variantElementIds: [for (var i = 1; i <= 6; i++) 'healing-$i'],
              ),
            ),
          ],
          warps: [
            MapWarp(
              id: 'arrival',
              pos: const GridPos(x: 1, y: 1),
              targetMapId: fixture.map.id,
              targetPos: const GridPos(x: 1, y: 1),
              triggerMode: MapWarpTriggerMode.sceneOnly,
            ),
          ],
        );
        final catalog = await RuntimeProjectCatalog.open(
          await _write(root, project, partitioned),
        );
        addTearDown(catalog.dispose);
        final narrative = await catalog.manifestForNarrativeMaps([map]);
        expect(narrative.elements.map((value) => value.id).toSet(), {
          'entity-visual',
          'portrait',
          'orphan-illustration',
          for (var i = 1; i <= 6; i++) 'healing-$i',
        });
        expect(narrative.tilesets.map((value) => value.id).toSet(), {
          'actors',
          'dynamic',
        });
        expect(narrative.characters.single.id, 'hero');
        expect(
          narrative.characterStudioCatalog.portraitStates.single.id,
          'happy',
        );
        expect(narrative.borderCatalog.records, isEmpty);
        expect(narrative.borderCatalog.visualSnapshots, isEmpty);
        final full = await catalog.manifestForMaps([
          map,
        ], extraSceneIds: project.scenes.map((scene) => scene.id));
        expect(
          full.elements.map((value) => value.id).toSet(),
          project.elements.map((value) => value.id).toSet(),
        );
        expect(full.borderCatalog.records, isNotEmpty);
        expect(full.borderCatalog.visualSnapshots, isNotEmpty);
        expect(
          full.tilesets.map((value) => value.id),
          containsAll(['original-atlas', 'terrain', 'decor']),
        );
        final maps = [map];
        final expected = buildNarrativeEventProjectCatalog(
          project: full,
          maps: maps,
        );
        final actual = buildNarrativeEventProjectCatalog(
          project: narrative,
          maps: maps,
        );
        expect(
          actual.scenes.every((scene) => scene.buildable),
          isTrue,
          reason: [
            actual.diagnostics.map((value) => value.toDebugJson()).toList(),
            for (final scene in narrative.scenes)
              diagnoseSceneAgainstProject(
                    scene,
                    narrative,
                    mapsById: {map.id: map},
                  ).diagnostics
                  .map((value) => '${value.code}: ${value.message}')
                  .toList(),
          ].toString(),
        );
        expect(_semantics(actual), _semantics(expected));
        expect(actual.mapHashes, expected.mapHashes);
        expect(actual.manifestHash, isNot(expected.manifestHash));
        for (final event in actual.events) {
          expect(
            actual.resolveEvent(event.record.id).status,
            expected.resolveEvent(event.record.id).status,
          );
          final source = event.record.definitionOrNull!.source;
          expect(
            actual.resolveSource(source).status,
            expected.resolveSource(source).status,
          );
        }
        final fullSnapshot = await NarrativeEventRuntimeSnapshot.build(
          project: full,
          loadMap: (_) async => (project: full, map: map),
        );
        final leanSnapshot = await NarrativeEventRuntimeSnapshot.build(
          project: catalog.projectMetadata,
          loadMap: (_) async => (project: catalog.projectMetadata, map: map),
        );
        expect(
          _semantics(leanSnapshot.projectCatalog),
          _semantics(fullSnapshot.projectCatalog),
        );
        expect(
          _claims(leanSnapshot.legacyClaimIndex),
          _claims(fullSnapshot.legacyClaimIndex),
        );
        expect(leanSnapshot.mapsById, fullSnapshot.mapsById);
        expect(leanSnapshot.matchesProject(full), isTrue);
        expect(RuntimeProjectCatalog.ownerOf(narrative), same(catalog));
      },
    );
  }

  test('narrative hydration never reads deferred decorative objects', () async {
    final root = await Directory.systemTemp.createTemp(
      'narrative-unread-decor-',
    );
    addTearDown(() => root.delete(recursive: true));
    final fixture = BorderJumpFixture();
    final project = _project(fixture);
    final map = fixture.map.copyWith(
      tilesetId: 'terrain',
      placedElements: const [
        MapPlacedElement(
          id: 'decor',
          layerId: 'objects',
          elementId: 'decor',
          pos: GridPos(x: 1, y: 1),
        ),
      ],
    );
    final path = await _write(root, project, true);
    final publication = PortableCatalogPublication.encodeProject(project);
    final removed = <File, List<int>>{};
    for (final object in publication.storage.objects.entries) {
      final value = jsonDecode(utf8.decode(object.value)) as Map;
      final key = value['key'];
      if (key is! Map ||
          !const {
            'element:decor',
            'tileset:terrain',
            'borderRecord:ledge-blueprint',
          }.contains('${key['kind']}:${key['id']}')) {
        continue;
      }
      final file = File('${root.path}/catalog/objects/${object.key}.json');
      removed[file] = object.value;
      await file.delete();
    }
    expect(removed, hasLength(3));
    final catalog = await RuntimeProjectCatalog.open(path);
    addTearDown(catalog.dispose);
    final narrative = await catalog.manifestForNarrativeMaps([map]);
    expect(
      narrative.elements.map((value) => value.id),
      isNot(contains('decor')),
    );
    expect(narrative.borderCatalog.records, isEmpty);
    await expectLater(
      catalog.manifestForMap(map),
      throwsA(isA<FileSystemException>()),
    );
    for (final object in removed.entries) {
      await object.key.writeAsBytes(object.value);
    }
    final full = await catalog.manifestForMap(map);
    expect(full.elements.map((value) => value.id), contains('decor'));
    expect(full.tilesets.map((value) => value.id), contains('terrain'));
    expect(full.borderCatalog.records.single.id, 'ledge-blueprint');
  });
}

Future<String> _write(
  Directory root,
  ProjectManifest project,
  bool partitioned,
) async {
  final file = File('${root.path}/project.json');
  if (!partitioned) {
    await file.writeAsString(jsonEncode(project.toJson()));
    return file.path;
  }
  final publication = PortableCatalogPublication.encodeProject(project);
  await file.writeAsString(jsonEncode(publication.descriptor));
  for (final object in publication.storage.objects.entries) {
    final target = File('${root.path}/catalog/objects/${object.key}.json');
    await target.parent.create(recursive: true);
    await target.writeAsBytes(object.value);
  }
  return file.path;
}

Map<String, Object?> _semantics(NarrativeEventProjectCatalog catalog) => {
  'scenes': [for (final value in catalog.scenes) value.toDebugJson()],
  'events': [for (final value in catalog.events) value.toDebugJson()],
  'facts': [for (final value in catalog.facts) value.toDebugJson()],
  'diagnostics': [for (final value in catalog.diagnostics) value.toDebugJson()],
  'spatial': catalog.spatialSources.toDebugJson(),
  'outcomes': catalog.outcomeSources.toDebugJson(),
  'nativeMapIds': catalog.nativeMapIds,
  'mapHashes': catalog.mapHashes,
};

Map<String, Object?> _claims(ValidatedLegacyClaimIndex claims) => {
  'runtimeEvidenceValidated': claims.runtimeEvidenceValidated,
  'canEnterDualRead': claims.canEnterDualRead,
  'canRunDualRead': claims.canRunDualRead,
  'validBySource': claims.validBySource,
  'validByProvenance': claims.validByProvenance,
  'invalidBySource': claims.invalidBySource,
  'invalidByProvenance': claims.invalidByProvenance,
  'globalConflicts': claims.globalConflicts,
};

ProjectManifest _project(BorderJumpFixture fixture) =>
    PortableCatalogPublication.withProjectDynamicDependencies(
      fixture.project.copyWith(
        maps: [
          ProjectMapEntry(
            id: fixture.map.id,
            name: 'Field',
            relativePath: 'maps/field.json',
          ),
        ],
        settings: fixture.project.settings.copyWith(
          defaultPlayerCharacterId: 'hero',
        ),
        tilesets: [
          ...fixture.project.tilesets,
          for (final id in ['terrain', 'decor', 'actors', 'dynamic'])
            ProjectTilesetEntry(
              id: id,
              name: id,
              relativePath: '$id.png',
              source: ProjectRegularAtlasTilesetSource(
                assetId: id,
                pixelWidth: 128,
                pixelHeight: 128,
                tileWidth: 32,
                tileHeight: 32,
              ),
            ),
        ],
        elements: [
          ...fixture.project.elements,
          for (final id in [
            'decor',
            'entity-visual',
            'portrait',
            'orphan-illustration',
            for (var i = 1; i <= 6; i++) 'healing-$i',
          ])
            ProjectElementEntry(
              id: id,
              name: id,
              tilesetId: id == 'decor' ? 'decor' : 'actors',
              categoryId: 'original-modules',
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              ],
            ),
        ],
        characters: const [
          ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'actors',
            portraits: [
              CharacterPortraitVariant(
                portraitStateId: 'happy',
                assetId: 'portrait',
              ),
            ],
          ),
        ],
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          portraitStates: [
            CharacterPortraitStateDefinition(id: 'happy', displayName: 'Happy'),
          ],
        ),
        trainers: const [
          ProjectTrainerEntry(
            id: 'trainer',
            name: 'Trainer',
            trainerClass: 'Sage',
            characterId: 'hero',
            portraitElementId: 'portrait',
            team: [ProjectTrainerPokemonEntry(speciesId: 'rattata', level: 8)],
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_12345678-1234-7123-8123-123456789abc',
                name: 'Service',
                source: NarrativeEventSourceRef.mapEnter(fixture.map.id),
                conditions: const [],
                sceneId: 'service',
                reusePolicy: NarrativeEventReusePolicy.reusable,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
        scenes: [
          SceneAsset(
            id: 'service',
            name: 'Service',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'heal',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.openHeal(
                      displayEntityId: 'healing-balls',
                    ),
                  ),
                ),
                SceneNode(
                  id: 'end',
                  kind: SceneNodeKind.end,
                  payload: SceneEndPayload(),
                ),
              ],
              edges: [
                SceneEdge(
                  id: 'start-heal',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'heal',
                  kind: SceneEdgeKind.defaultFlow,
                ),
                for (final port in ['completed', 'cancelled'])
                  SceneEdge(
                    id: 'heal-$port',
                    fromNodeId: 'heal',
                    fromPortId: port,
                    toNodeId: 'end',
                    kind: SceneEdgeKind.actionCompleted,
                  ),
              ],
            ),
          ),
          SceneAsset(
            id: 'orphan',
            name: 'Orphan illustrated warp',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'warp',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.warp(
                      destinationMapId: fixture.map.id,
                      warpId: 'arrival',
                      presentation: SceneWarpPresentation(
                        mode: SceneWarpPresentationMode.illustrated,
                        illustrationElementId: 'orphan-illustration',
                      ),
                    ),
                  ),
                ),
                SceneNode(
                  id: 'end',
                  kind: SceneNodeKind.end,
                  payload: SceneEndPayload(),
                ),
              ],
              edges: [
                SceneEdge(
                  id: 'start-warp',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'warp',
                  kind: SceneEdgeKind.defaultFlow,
                ),
                for (final port in ['completed', 'blocked'])
                  SceneEdge(
                    id: 'warp-$port',
                    fromNodeId: 'warp',
                    fromPortId: port,
                    toNodeId: 'end',
                    kind: SceneEdgeKind.actionCompleted,
                  ),
              ],
            ),
          ),
        ],
      ),
      [
        CatalogDynamicDependency(
          owner: CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'actors'),
          targets: [
            CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'dynamic'),
          ],
        ),
      ],
    );
