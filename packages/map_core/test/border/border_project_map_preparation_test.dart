import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('coordinated Border project/map preparation', () {
    test('returns two validated V2 values and leaves both sources unchanged',
        () {
      final manifest = _manifest();
      final map = _map();
      final sourceManifestJson = jsonEncode(manifest.toJson());
      final sourceMapJson = jsonEncode(map.toJson());
      final sourceCollisionJson = jsonEncode(map.layers.single.toJson());

      final result = prepareFirstBorderDraftAndLayer(
        manifest: manifest,
        map: map,
        draftRecord: _record('coast'),
        layerId: 'borders',
        layerName: 'Bordures',
      );

      expect(result.manifest.version, ProjectVersion.v2);
      expect(result.manifest.borderCatalog.records.single.id, 'coast');
      expect(result.map.version, ProjectVersion.v2);
      expect(result.map.layers.last, isA<BorderLayer>());
      expect(result.map.layers.last.id, 'borders');
      expect(() => ProjectValidator.validate(result.manifest), returnsNormally);
      expect(
        () => MapValidator.validate(
          result.map,
          projectDialogueContext: result.manifest,
        ),
        returnsNormally,
      );
      expect(jsonEncode(manifest.toJson()), sourceManifestJson);
      expect(jsonEncode(map.toJson()), sourceMapJson);
      expect(jsonEncode(result.map.layers.first.toJson()), sourceCollisionJson);
      expect(result.map.placedElements, map.placedElements);
      expect(result.map.mapMetadata, map.mapMetadata);
      expect(result.map.properties, map.properties);
    });

    test('rejects a manifest that already owns Border catalog content', () {
      final manifest = _manifest(borderCatalog: _catalog('existing'));
      final map = _map();
      final manifestBefore = jsonEncode(manifest.toJson());
      final mapBefore = jsonEncode(map.toJson());

      expect(
        () => prepareFirstBorderDraftAndLayer(
          manifest: manifest,
          map: map,
          draftRecord: _record('coast'),
          layerId: 'borders',
          layerName: 'Bordures',
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            'First Border creation requires an empty project Border catalog',
          ),
        ),
      );
      expect(jsonEncode(manifest.toJson()), manifestBefore);
      expect(jsonEncode(map.toJson()), mapBefore);
    });

    test('map operation failure never returns the prepared manifest', () {
      final manifest = _manifest();
      final map = _map(
        layers: const <MapLayer>[
          MapLayer.collision(
            id: 'borders',
            name: 'Existing',
            collisions: <bool>[false, false, false, false],
          ),
        ],
      );
      final manifestBefore = jsonEncode(manifest.toJson());
      final mapBefore = jsonEncode(map.toJson());

      expect(
        () => prepareFirstBorderDraftAndLayer(
          manifest: manifest,
          map: map,
          draftRecord: _record('coast'),
          layerId: 'borders',
          layerName: 'Bordures',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(jsonEncode(manifest.toJson()), manifestBefore);
      expect(jsonEncode(map.toJson()), mapBefore);
      expect(manifest.version, ProjectVersion.v1);
      expect(manifest.borderCatalog.isEmpty, isTrue);
    });

    test('strict preflight rejects an invalid prepared manifest atomically',
        () {
      final duplicate = const ProjectMapEntry(
        id: 'port',
        name: 'Port',
        relativePath: 'maps/port.json',
      );
      final manifest = _manifest(maps: <ProjectMapEntry>[
        duplicate,
        duplicate,
      ]);
      final map = _map();
      final mapBefore = jsonEncode(map.toJson());

      expect(
        () => prepareFirstBorderDraftAndLayer(
          manifest: manifest,
          map: map,
          draftRecord: _record('coast'),
          layerId: 'borders',
          layerName: 'Bordures',
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('Duplicate map ID'),
          ),
        ),
      );
      expect(jsonEncode(map.toJson()), mapBefore);
      expect(map.version, ProjectVersion.v1);
      expect(map.layers, hasLength(1));
    });

    test('strict preflight rejects an invalid prepared map atomically', () {
      final manifest = _manifest();
      final map = _map(
        layers: const <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            tiles: <int>[0],
          ),
        ],
      );
      final manifestBefore = jsonEncode(manifest.toJson());

      expect(
        () => prepareFirstBorderDraftAndLayer(
          manifest: manifest,
          map: map,
          draftRecord: _record('coast'),
          layerId: 'borders',
          layerName: 'Bordures',
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('expected 4'),
          ),
        ),
      );
      expect(jsonEncode(manifest.toJson()), manifestBefore);
      expect(manifest.version, ProjectVersion.v1);
      expect(manifest.borderCatalog.isEmpty, isTrue);
      expect(map.layers, hasLength(1));
    });

    test('rejects an existing Border layer even under a different id', () {
      final manifest = _manifest();
      final map = _map(
        layers: const <MapLayer>[
          MapLayer.border(id: 'existing-border', name: 'Existing'),
        ],
      ).copyWith(version: ProjectVersion.v2);

      expect(
        () => prepareFirstBorderDraftAndLayer(
          manifest: manifest,
          map: map,
          draftRecord: _record('coast'),
          layerId: 'new-border',
          layerName: 'Bordures',
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            'First Border creation requires a map without Border layers',
          ),
        ),
      );
      expect(map.layers.single.id, 'existing-border');
    });

    test('rejects a published or nonzero-base draft record', () {
      final manifest = _manifest();
      final map = _map();

      for (final record in <BorderBlueprintRecord>[
        _record('published', published: true),
        _record('edited', baseRevision: 1),
      ]) {
        expect(
          () => prepareFirstBorderDraftAndLayer(
            manifest: manifest,
            map: map,
            draftRecord: record,
            layerId: 'borders',
            layerName: 'Bordures',
          ),
          throwsA(isA<ValidationException>()),
          reason: record.id,
        );
      }
    });

    test('rejects insert indexes instead of clamping them', () {
      final manifest = _manifest();
      final map = _map();

      for (final index in <int>[-1, map.layers.length + 1]) {
        expect(
          () => prepareFirstBorderDraftAndLayer(
            manifest: manifest,
            map: map,
            draftRecord: _record('coast'),
            layerId: 'borders',
            layerName: 'Bordures',
            insertIndex: index,
          ),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              'Invalid first Border layer insertIndex: $index',
            ),
          ),
        );
      }
    });
  });
}

ProjectManifest _manifest({
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'port',
      name: 'Port',
      relativePath: 'maps/port.json',
    ),
  ],
  ProjectBorderCatalog borderCatalog = const ProjectBorderCatalog.empty(),
}) =>
    ProjectManifest(
      name: 'Border project',
      maps: maps,
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: borderCatalog,
      globalProperties: const <String, dynamic>{'keep': 'manifest'},
    );

MapData _map({
  List<MapLayer> layers = const <MapLayer>[
    MapLayer.collision(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[true, false, false, true],
    ),
  ],
}) =>
    MapData(
      id: 'port',
      name: 'Port',
      size: const GridSize(width: 2, height: 2),
      layers: layers,
      mapMetadata: const MapMetadata(
        displayName: 'Port des Brisants',
        tags: <String>['coast'],
      ),
      properties: const <String, dynamic>{'keep': 'map'},
    );

ProjectBorderCatalog _catalog(String id) => ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[_record(id)],
    );

BorderBlueprintRecord _record(
  String id, {
  int baseRevision = 0,
  bool published = false,
}) =>
    BorderBlueprintRecord(
      id: id,
      draft: BorderBlueprintDraft(
        baseRevision: baseRevision,
        definition:
            BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>(
          name: 'Border $id',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.organicEdge,
          primitives: const <BorderPrimitiveDraft>[],
          defaults: BorderGenerationParams(
            irregularityPermille: 0,
            detailDensityPermille: 0,
            variationPermille: 0,
            maxOverlapPx: 0,
            gapTolerancePx: 0,
            depthRows: 1,
          ),
          sortOrder: 0,
        ),
      ),
      latestPublished: published
          ? BorderBlueprintRevision(
              revision: 1,
              definition: BorderBlueprintDefinition<BorderPublishedPrimitive,
                  BorderPublishedGround>(
                name: 'Published $id',
                previewSeed: BorderSignedInt64.zero,
                template: BorderBlueprintTemplate.organicEdge,
                primitives: const <BorderPublishedPrimitive>[],
                defaults: BorderGenerationParams(
                  irregularityPermille: 0,
                  detailDensityPermille: 0,
                  variationPermille: 0,
                  maxOverlapPx: 0,
                  gapTolerancePx: 0,
                  depthRows: 1,
                ),
                sortOrder: 0,
              ),
            )
          : null,
    );
