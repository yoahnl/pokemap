import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  test('canonical catalog declares the complete native ledge profile', () {
    for (final id in [
      'border.blueprint.draft.upsert',
      'border.blueprint.publish',
    ]) {
      final descriptor = BorderCatalogActions.descriptors.singleWhere(
        (action) => action.id == id,
      );
      expect(descriptor.extensions['ledgeLine'], {
        'template': 'ledgeLine',
        'minimumCatalogFormatVersion': 7,
        'geometry': 'stroke',
        'alignment': 'gridEdges',
        'modulesPerUnitEdge': 1,
        'primitiveRole': 'structureLarge',
        'orientation': 'nativeCardinal',
        'frameSize': 'oneCell',
        'automaticRotation': false,
        'flipX': false,
        'sourceOrigin': 'carrierCellOrigin',
        'jumpOwner': 'borderBlueprint',
        'jumpSideChangesVisuals': false,
        'visualGapTolerance': {
          'property': 'definition.defaults.gapTolerancePx',
          'unit': 'pixels',
          'default': 0,
          'maximum': 'lessThanOneCell',
          'coverage': 'allAdmissibleVariantPairs',
          'changesCollision': false,
        },
      });
    }
  });

  for (final gap in [0, 8]) {
    test(
      'draft and publication retain the native south module with gap $gap',
      () async {
        final template = BorderBlueprintTemplate.values.byName('ledgeLine');
        final pixels = img.Image(width: 32, height: 32, numChannels: 4);
        for (var y = 16; y < 32; y++) {
          for (var x = 0; x < 32 - gap; x++) {
            pixels.setPixelRgba(x, y, x * 7, y * 5, 80, 255);
          }
        }
        final bytes = img.encodePng(pixels);
        const anchor = BorderPixelPos(x: 16, y: 31);
        final preparation = const CanonicalBorderSnapshotCompiler().prepare(
          sourceElementId: 'south',
          anchorPx: anchor,
          frames: [
            CanonicalBorderSourceFrame(
              sourceProjectRelativePath: 'assets/tilesets/south.png',
              encodedImageBytes: bytes,
            ),
          ],
        );
        final primitive = BorderPrimitiveDraft(
          id: 'source1212',
          sourceElementId: 'south',
          role: BorderPrimitiveRole.structureLarge,
          authoredOrientation: BorderPrimitiveOrientation.south,
          weight: 1,
          anchorPx: anchor,
          transforms: BorderTransformPolicy(
            allowedQuarterTurns: [0],
            allowFlipX: false,
          ),
          currentMetrics: preparation.metrics,
        );
        final rules = BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: gap,
          depthRows: 1,
          allowAutoRotation: false,
        );
        final record = BorderBlueprintRecord(
          id: 'source-rebords',
          draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: BorderBlueprintDraftDefinition(
              name: 'Rebords source',
              previewSeed: BorderSignedInt64.zero,
              template: template,
              primitives: [primitive],
              defaults: rules,
              jumpBehavior: BorderJumpBehavior(side: BorderLineSide.inverted),
              sortOrder: 0,
            ),
          ),
        );
        final project = ProjectManifest(
          name: 'Native ledge authoring',
          settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
          maps: const [],
          tilesets: const [
            ProjectTilesetEntry(
              id: 'source',
              name: 'Source',
              relativePath: 'assets/tilesets/south.png',
            ),
          ],
          elements: const [
            ProjectElementEntry(
              id: 'south',
              name: 'Rebord sud',
              tilesetId: 'source',
              categoryId: 'border',
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              ],
            ),
          ],
        );
        final artifacts = MemoryArtifactStore(
          maximumArtifactBytes: 1024 * 1024,
        );
        final actions = BorderCatalogActions(artifactStore: artifacts);
        final draftMutation = await actions.build(
          catalogContext(
            catalogSnapshot([], project: project),
            'border.blueprint.draft.upsert',
            {
              'record': encodeBorderBlueprintRecordJson(
                record,
                formatVersion: 7,
              ),
            },
          ),
        );
        final drafted = _manifest(draftMutation);
        expect(drafted.borderCatalog.formatVersion, 7);
        final artifact = await artifacts.put(
          bytes,
          declaredMediaType: 'image/png',
        );
        final publishedMutation = await actions
            .build(
              catalogContext(
                catalogSnapshot([], project: drafted),
                'border.blueprint.publish',
                {
                  'blueprintId': record.id,
                  'primitiveSources': [
                    {
                      'primitiveId': primitive.id,
                      'frames': [
                        {
                          'artifactHandle': artifact.reference.handle,
                          'sourceProjectRelativePath':
                              'assets/tilesets/south.png',
                        },
                      ],
                    },
                  ],
                },
              ),
            )
            .catchError((Object error) {
              if (error is MapAuthoringException) {
                fail('${error.code}: ${jsonEncode(error.details)}');
              }
              throw error;
            });
        final reopened = ProjectManifest.fromJson(
          jsonDecode(jsonEncode(_manifest(publishedMutation).toJson())),
        );
        final published =
            reopened.borderCatalog.records.single.latestPublished!;
        expect(reopened.borderCatalog.formatVersion, 7);
        expect(published.definition.template, template);
        expect(
          published.definition.jumpBehavior,
          record.draft.definition.jumpBehavior,
        );
        final visual = published.definition.primitives.single;
        expect(visual.authoredOrientation, BorderPrimitiveOrientation.south);
        expect(visual.anchorPx, anchor);
        expect(
          visual.publishedMetrics.pixelSize,
          const GridSize(width: 32, height: 32),
        );
        expect(
          visual.publishedMetrics.opaqueBounds,
          BorderPixelRect(x: 0, y: 16, width: 32 - gap, height: 16),
        );
        expect(visual.transforms.allowedQuarterTurns, [0]);
        expect(visual.transforms.allowFlipX, false);
        expect(publishedMutation.preview['projectWidePreflight'], 'passed');
        final feature = BorderFeature(
          id: 'ledge',
          name: 'Rebord',
          blueprintId: record.id,
          seed: BorderSignedInt64.zero,
          geometry: BorderStrokeGeometry(
            alignment: BorderStrokeAlignment.gridEdges,
            strokes: [
              BorderStroke(
                id: 'source-edge',
                points: [const GridPos(x: 2, y: 3), const GridPos(x: 3, y: 3)],
                closed: false,
              ),
            ],
          ),
          overrides: const [],
          keepOutRegions: const [],
        );
        final map = catalogMap('route').copyWith(
          layers: [
            MapLayer.border(
              id: 'rebords',
              name: 'Rebords',
              content: BorderLayerContent(
                formatVersion: 3,
                features: [feature],
              ),
            ),
            ...catalogMap('route').layers,
          ],
        );
        final mapProject = reopened.copyWith(
          maps: [
            ProjectMapEntry(
              id: map.id,
              name: map.name,
              relativePath: 'maps/route.json',
            ),
          ],
        );
        final applied = await MapMutationDispatcher.canonical().build(
          catalogContext(
            catalogSnapshot([map], project: mapProject),
            'border_layer.materialize_apply',
            {
              'mapId': map.id,
              'layerId': 'rebords',
              'featureId': feature.id,
              'tileWidthPx': 32,
              'tileHeightPx': 32,
              'resolverVersion': borderResolverVersion,
            },
          ),
        );
        final saved = MapData.fromJson(
          jsonDecode(
            utf8.decode(
              applied.changeSet.changes
                  .singleWhere((change) => change.resource.kind == 'map')
                  .afterBytes!,
            ),
          ),
        );
        final stored = saved.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single;
        final placement = stored.materialization!.placements.single;
        expect(placement.primitiveId, primitive.id);
        expect(placement.topLeftWorldPx, const BorderPixelPos(x: 64, y: 96));
        expect(
          placement.opaqueWorldBoundsPx,
          BorderPixelRect(x: 64, y: 112, width: 32 - gap, height: 16),
        );
        expect(
          placement.transform,
          BorderSpriteTransform(quarterTurns: 0, flipX: false),
        );
        expect(saved.gameplayZones, isEmpty);
        expect((saved.layers.first as BorderLayer).content.formatVersion, 3);
        expect(saved.layers.skip(1), map.layers.skip(1));
      },
    );
  }
}

ProjectManifest _manifest(AuthoringMutationDraft mutation) =>
    ProjectManifest.fromJson(
      jsonDecode(
        utf8.decode(
          mutation.changeSet.changes
              .singleWhere((change) => change.resource.kind == 'project')
              .afterBytes!,
        ),
      ),
    );
