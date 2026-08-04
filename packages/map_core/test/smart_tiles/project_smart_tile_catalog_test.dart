import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSmartTileCatalog', () {
    test('round-trips the complete native authoring contract', () {
      final catalog = ProjectSmartTileCatalog(
        categories: <ProjectSmartTileCategory>[
          ProjectSmartTileCategory(
            id: 'hanazuki',
            name: 'Hanazuki',
          ),
        ],
        atlases: <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'hanazuki-ground',
            name: 'Hanazuki ground',
            tilesetId: 'ground',
            cellWidth: 32,
            cellHeight: 32,
            originX: 4,
            originY: 5,
            marginX: 2,
            marginY: 3,
            spacingX: 4,
            spacingY: 4,
            columns: 8,
            rows: 8,
            pixelOffsetX: -2,
            pixelOffsetY: 3,
          ),
        ],
        materials: <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Herbe',
            connectionGroupId: 'ground',
          ),
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Terre',
            connectionGroupId: 'ground',
            pathSurfaceKind: PathSurfaceKind.path,
          ),
        ],
        animations: <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(
            id: 'grass-breeze',
            name: 'Herbe légère',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'hanazuki-ground',
                  column: 0,
                  row: 0,
                ),
                durationMs: 180,
              ),
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'hanazuki-ground',
                  column: 1,
                  row: 0,
                ),
                durationMs: 180,
              ),
            ],
          ),
        ],
        presets: <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'hanazuki-path',
            name: 'Chemin organique d’Hanazuki',
            categoryId: 'hanazuki',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.blob8,
            templateHint: SmartTileTemplateHint.blob47,
            boundaryPolicy: SmartTileBoundaryPolicy.empty,
            status: SmartTilePresetStatus.draft,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.templateAndExplicit,
              requiredScenarios: <SmartTileCoverageScenario>[
                SmartTileCoverageScenario(
                  id: 'dirt-center',
                  centerMaterialId: 'dirt',
                  signature: SmartTileExactSignature(
                    northEdge: 'grass',
                    eastEdge: 'dirt',
                  ),
                ),
              ],
            ),
            transformPolicy: SmartTileTransformPolicy(
              allowHFlip: true,
              allowVFlip: true,
              allowQuarterTurns: true,
              preferUntransformed: false,
            ),
            allowedMaterialIds: <String>['grass', 'dirt'],
            defaultMaterialId: 'dirt',
            rules: <SmartTileRule>[
              SmartTileRule(
                id: 'isolated',
                centerMatch: SmartTileSlotMatch.material('dirt'),
                signature: SmartTileSignature(
                  northEdge: SmartTileSlotMatch.different(),
                  eastEdge: SmartTileSlotMatch.different(),
                  southEdge: SmartTileSlotMatch.different(),
                  westEdge: SmartTileSlotMatch.different(),
                ),
                candidates: <SmartTileCandidate>[
                  SmartTileCandidate(
                    id: 'isolated-a',
                    weight: 2,
                    parts: <SmartTileVisualPart>[
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                          frame: SmartTileFrameRef(
                            atlasId: 'hanazuki-ground',
                            column: 2,
                            row: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final decoded = ProjectSmartTileCatalog.fromJson(
        jsonDecode(jsonEncode(catalog.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, catalog);
      expect(
        decoded.atlases.single.sourceRectFor(column: 2, row: 3),
        const SmartTileSourceRect(
          x: 78,
          y: 116,
          width: 32,
          height: 32,
        ),
      );
      expect(decoded.isNotEmpty, isTrue);
      expect(decoded.formatVersion, 4);
      expect(
        decoded.materials
            .singleWhere((item) => item.id == 'dirt')
            .pathSurfaceKind,
        PathSurfaceKind.path,
      );
      expect(
        decoded.presets.single.transformPolicy,
        const SmartTileTransformPolicy(
          allowHFlip: true,
          allowVFlip: true,
          allowQuarterTurns: true,
          preferUntransformed: false,
        ),
      );
    });

    test('addresses every cell of an ERW-shaped 55 by 72 atlas', () {
      const atlas = ProjectSmartTileAtlas(
        id: 'erw-terrain',
        name: 'ERW terrain metadata',
        tilesetId: 'erw-terrain-image',
        columns: 55,
        rows: 72,
      );

      expect(
        atlas.sourceRectFor(column: 54, row: 71),
        const SmartTileSourceRect(
          x: 1728,
          y: 2272,
          width: 32,
          height: 32,
        ),
      );
      expect(
        () => atlas.sourceRectFor(column: 55, row: 71),
        throwsRangeError,
      );
    });

    test('empty catalog is const, immutable, and round-trips', () {
      const catalog = ProjectSmartTileCatalog.empty();

      expect(catalog.isEmpty, isTrue);
      expect(
        () => catalog.presets.add(
          const ProjectSmartTilePreset(
            id: 'forbidden',
            name: 'Forbidden mutation',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.cardinal4,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: <String>['grass'],
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        ProjectSmartTileCatalog.fromJson(catalog.toJson()),
        catalog,
      );
    });

    test('legacy non-empty catalogs are rejected but empty ones normalize', () {
      for (final raw in <Map<String, dynamic>>[
        <String, dynamic>{
          'formatVersion': 1,
          'materials': <Object?>[
            <String, Object?>{
              'id': 'grass',
              'name': 'Grass',
              'connectionGroupId': 'ground',
            },
          ],
        },
        <String, dynamic>{
          'materials': <Object?>[
            <String, Object?>{
              'id': 'grass',
              'name': 'Grass',
              'connectionGroupId': 'ground',
            },
          ],
        },
        <String, dynamic>{
          'formatVersion': 1,
          'wangSets': <Object?>[],
        },
      ]) {
        expect(
          () => ProjectSmartTileCatalog.fromJson(raw),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('smart_tile_catalog_v1_unsupported'),
            ),
          ),
        );
      }

      expect(
        ProjectSmartTileCatalog.fromJson(<String, dynamic>{
          'formatVersion': 1,
          'materials': <Object?>[],
        }),
        const ProjectSmartTileCatalog.empty(),
      );
      expect(
        ProjectSmartTileCatalog.fromJson(<String, dynamic>{}),
        const ProjectSmartTileCatalog.empty(),
      );
    });

    test('catalog formatVersion is a strict positive supported JSON integer',
        () {
      for (final invalid in <Object?>['2', 2.5, 0, -1]) {
        expect(
          () => ProjectSmartTileCatalog.fromJson(<String, dynamic>{
            'formatVersion': invalid,
          }),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('smart_tile_catalog_version_invalid'),
            ),
          ),
          reason: '$invalid',
        );
      }
      expect(
        () => ProjectSmartTileCatalog.fromJson(<String, dynamic>{
          'formatVersion': 5,
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('smart_tile_catalog_version_unsupported'),
          ),
        ),
      );
      for (final invalid in <int>[1, 2, 3]) {
        expect(
          () => ProjectSmartTileCatalog(formatVersion: invalid),
          throwsArgumentError,
          reason: 'programmatic format $invalid',
        );
      }
    });

    test('a 2 by 3 visual footprint remains owned by one candidate part', () {
      const candidate = SmartTileCandidate(
        id: 'large-owner',
        parts: <SmartTileVisualPart>[
          SmartTileVisualPart(
            source: SmartTileVisualSource.frame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas',
                column: 0,
                row: 0,
                columnSpan: 2,
                rowSpan: 3,
              ),
            ),
            footprintWidth: 2,
            footprintHeight: 3,
          ),
        ],
      );

      final decoded = SmartTileCandidate.fromJson(candidate.toJson());

      expect(decoded, candidate);
      expect(decoded.parts, hasLength(1));
      expect(decoded.parts.single.footprintWidth, 2);
      expect(decoded.parts.single.footprintHeight, 3);
    });

    test('Simple topology and template round-trip with stable JSON values', () {
      const preset = ProjectSmartTilePreset(
        id: 'simple',
        name: 'Simple',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(allowHFlip: true),
        defaultMaterialId: 'dirt',
        allowedMaterialIds: <String>['dirt'],
      );

      final decoded = ProjectSmartTilePreset.fromJson(preset.toJson());

      expect(decoded, preset);
      expect(preset.toJson()['topology'], 'uniform');
      expect(preset.toJson()['templateHint'], 'simple');
      expect(decoded.transformPolicy.allowHFlip, isTrue);
    });

    test('historical legacy_20 template is rejected during JSON decoding', () {
      final json = const ProjectSmartTilePreset(
        id: 'native-only',
        name: 'Native only',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        templateHint: SmartTileTemplateHint.edge16,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      ).toJson()
        ..['templateHint'] = 'legacy_20';

      expect(
        () => ProjectSmartTilePreset.fromJson(json),
        throwsArgumentError,
      );
    });

    test('malformed slot matches fail closed during JSON decoding', () {
      for (final invalid in <Map<String, dynamic>>[
        <String, dynamic>{'kind': 'material'},
        <String, dynamic>{'kind': 'material', 'materialId': ''},
        <String, dynamic>{'kind': 'any', 'materialId': 'grass'},
      ]) {
        expect(
          () => SmartTileSlotMatch.fromJson(invalid),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('smart_tile_slot_match_invalid'),
            ),
          ),
          reason: '$invalid',
        );
      }
    });

    test('unsafe frame lower bounds fail closed during JSON decoding', () {
      for (final invalid in <Map<String, dynamic>>[
        <String, dynamic>{
          'atlasId': 'atlas',
          'column': -1,
          'row': 0,
          'columnSpan': 1,
          'rowSpan': 1,
        },
        <String, dynamic>{
          'atlasId': 'atlas',
          'column': 0,
          'row': 0,
          'columnSpan': 0,
          'rowSpan': 1,
        },
      ]) {
        expect(
          () => SmartTileFrameRef.fromJson(invalid),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('smart_tile_frame_ref_invalid'),
            ),
          ),
          reason: '$invalid',
        );
      }
    });

    test('fractional JSON integers never truncate into Smart Tile state', () {
      const part = SmartTileVisualPart(
        source: SmartTileVisualSource.frame(
          frame: SmartTileFrameRef(
            atlasId: 'atlas',
            column: 0,
            row: 0,
          ),
        ),
      );
      const animationFrame = ProjectSmartTileAnimationFrame(
        frame: SmartTileFrameRef(
          atlasId: 'atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      );
      const preset = ProjectSmartTilePreset(
        id: 'preset',
        name: 'Preset',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      );
      final cases = <({
        Map<String, dynamic> json,
        Object Function(Map<String, dynamic>) decode,
        String field,
      })>[
        (
          json: <String, dynamic>{
            ...const SmartTileSourceRect(
              x: 0,
              y: 0,
              width: 1,
              height: 1,
            ).toJson(),
            'x': 1.5,
          },
          decode: SmartTileSourceRect.fromJson,
          field: 'x',
        ),
        (
          json: <String, dynamic>{...part.toJson(), 'offsetX': 1.5},
          decode: SmartTileVisualPart.fromJson,
          field: 'offsetX',
        ),
        (
          json: <String, dynamic>{
            ...const SmartTileCandidate(id: 'candidate').toJson(),
            'weight': 1.5,
          },
          decode: SmartTileCandidate.fromJson,
          field: 'weight',
        ),
        (
          json: <String, dynamic>{
            ...const ProjectSmartTileCategory(
              id: 'category',
              name: 'Category',
            ).toJson(),
            'sortOrder': 1.5,
          },
          decode: ProjectSmartTileCategory.fromJson,
          field: 'sortOrder',
        ),
        (
          json: <String, dynamic>{
            ...const ProjectSmartTileAtlas(
              id: 'atlas',
              name: 'Atlas',
              tilesetId: 'tiles',
              columns: 1,
              rows: 1,
            ).toJson(),
            'pixelOffsetX': 1.5,
          },
          decode: ProjectSmartTileAtlas.fromJson,
          field: 'pixelOffsetX',
        ),
        (
          json: <String, dynamic>{
            ...const ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'ground',
            ).toJson(),
            'editorColorArgb': 1.5,
          },
          decode: ProjectSmartTileMaterial.fromJson,
          field: 'editorColorArgb',
        ),
        (
          json: <String, dynamic>{
            ...animationFrame.toJson(),
            'durationMs': 1.5,
          },
          decode: ProjectSmartTileAnimationFrame.fromJson,
          field: 'durationMs',
        ),
        (
          json: <String, dynamic>{...preset.toJson(), 'seedSalt': 1.5},
          decode: ProjectSmartTilePreset.fromJson,
          field: 'seedSalt',
        ),
      ];

      for (final testCase in cases) {
        expect(
          () => testCase.decode(testCase.json),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('smart_tile_integer_invalid'),
            ),
          ),
          reason: testCase.field,
        );
      }
    });
  });
}
