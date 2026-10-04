import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('deprecated publication remains readable for existing features', () {
    final fixture = placementFixture();
    expect(
        const BorderActions()
            .requirePublishedBlueprint(fixture.manifest, 'fence'),
        fixture.manifest.borderCatalog.records.first.latestPublished);
  });

  test('new feature cannot select a deprecated publication', () {
    final fixture = placementFixture();
    expect(
        () => const BorderActions().build(
                placementContext(fixture, 'border_layer.feature_create', {
              'featureId': 'new',
              'name': 'Nouveau trait',
              'blueprintId': 'fence',
              'seed': '17',
              'geometry': encodeBorderFeatureJson(
                  fixture.map.layers
                      .whereType<BorderLayer>()
                      .single
                      .content
                      .features
                      .single,
                  formatVersion: BorderLayerContent
                      .latestSupportedFormatVersion)['geometry']
            })),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'border.blueprint_deprecated')));
  });

  test('new stroke cannot extend a deprecated publication', () {
    final fixture = placementFixture();
    expect(
        () => const BorderActions()
                .build(placementContext(fixture, 'border_layer.stroke_add', {
              'featureId': 'existing',
              'strokeId': 'new',
              'points': [
                {'x': 2, 'y': 2},
                {'x': 3, 'y': 2}
              ]
            })),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'border.blueprint_deprecated')));
  });

  test('existing geometry can still be updated after deprecation', () {
    final fixture = placementFixture();
    final mutation = const BorderActions()
        .build(placementContext(fixture, 'border_layer.stroke_update', {
      'featureId': 'existing',
      'strokeId': 'line',
      'points': [
        {'x': 1, 'y': 1},
        {'x': 2, 'y': 1}
      ]
    }));
    expect(mutation.changeSet.changes.single.resource.id, 'map');
  });

  test('relink cannot select a deprecated target', () {
    final fixture = placementFixture();
    expect(
        () => const BorderActions().planRelink(
            manifest: fixture.manifest,
            map: fixture.map,
            layerId: 'border',
            featureId: 'existing',
            targetBlueprintId: 'other',
            tileSizePx: const GridSize(width: 32, height: 32),
            resolverVersion: 1),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'border.blueprint_deprecated')));
  });
}

({ProjectSnapshot snapshot, ProjectManifest manifest, MapData map})
    placementFixture() {
  final definition = BorderBlueprintDraftDefinition(
      name: 'Clôture',
      sortOrder: 0,
      previewSeed: BorderSignedInt64.zero,
      template: BorderBlueprintTemplate.masonryLine,
      primitives: const [],
      defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1));
  final record = BorderBlueprintRecord(
      id: 'fence',
      isDeprecated: true,
      draft: BorderBlueprintDraft(baseRevision: 1, definition: definition),
      latestPublished: BorderBlueprintRevision(
          revision: 1,
          definition: BorderBlueprintPublishedDefinition(
              name: definition.name,
              sortOrder: 0,
              previewSeed: definition.previewSeed,
              template: definition.template,
              primitives: const [],
              defaults: definition.defaults)));
  final map = MapData(
      id: 'map',
      name: 'Carte',
      version: ProjectVersion.v8,
      size: const GridSize(width: 6, height: 6),
      layers: [
        BorderLayer(
            id: 'border',
            name: 'Bordures',
            content: BorderLayerContent(features: [
              BorderFeature(
                  id: 'existing',
                  name: 'Trait conservé',
                  blueprintId: 'fence',
                  seed: BorderSignedInt64.zero,
                  overrides: const [],
                  keepOutRegions: const [],
                  geometry: BorderStrokeGeometry(strokes: [
                    BorderStroke(id: 'line', closed: false, points: const [
                      GridPos(x: 1, y: 1),
                      GridPos(x: 2, y: 1),
                      GridPos(x: 3, y: 1)
                    ])
                  ]))
            ]))
      ]);
  final manifest = ProjectManifest(
      name: 'Bordures',
      pokemon: const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
      version: ProjectVersion.v8,
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Carte', relativePath: 'map.json')
      ],
      tilesets: const [],
      borderCatalog: ProjectBorderCatalog(records: [
        record,
        BorderBlueprintRecord(
            id: 'other',
            draft: record.draft,
            latestPublished: record.latestPublished,
            isDeprecated: true)
      ]));
  final resources = {
    'project': utf8.encode(jsonEncode(manifest.toJson())),
    'map:map': utf8.encode(jsonEncode(map.toJson()))
  };
  return (
    manifest: manifest,
    map: map,
    snapshot: ProjectSnapshot(
        projectHandle: const ProjectHandle('border-placement'),
        revision: computeAuthoringBytesFingerprint(resources['project']!,
            logicalName: 'project.json'),
        manifest: manifest,
        maps: [map],
        resourceBytes: resources,
        resourceFingerprints: {
          for (final entry in resources.entries)
            entry.key: computeAuthoringBytesFingerprint(entry.value,
                logicalName:
                    entry.key == 'project' ? 'project.json' : 'map.json')
        },
        resourceStorageKeys: {'project': 'project.json', 'map:map': 'map.json'})
  );
}

AuthoringPlanningContext placementContext(
        ({
          ProjectSnapshot snapshot,
          ProjectManifest manifest,
          MapData map
        }) fixture,
        String action,
        Map<String, Object?> parameters) =>
    AuthoringPlanningContext(
        snapshot: fixture.snapshot,
        planId: 'placement-plan',
        seed: 1,
        request: AuthoringRequest(
            requestId: 'placement',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: 'workspace',
            expectedRevision: fixture.snapshot.revision,
            idempotencyKey: 'placement',
            parameters: {'mapId': 'map', 'layerId': 'border', ...parameters}));
