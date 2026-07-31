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
            allowedMaterialIds: <String>['grass', 'dirt'],
            defaultMaterialId: 'dirt',
            rules: <SmartTileRule>[
              SmartTileRule(
                id: 'isolated',
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
  });
}
