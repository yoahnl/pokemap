import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';

void main() {
  group('SmartTileAuthoringController', () {
    test('chooses native defaults for each supported usage', () {
      final controller = SmartTileAuthoringController.blank();

      controller.selectUsage(SmartTileUsage.terrain);
      expect(controller.state.topology, SmartTileTopology.cardinal4);
      expect(controller.state.templateHint, SmartTileTemplateHint.edge16);

      controller.selectUsage(SmartTileUsage.path);
      expect(controller.state.topology, SmartTileTopology.blob8);
      expect(controller.state.templateHint, SmartTileTemplateHint.blob47);

      controller.selectUsage(SmartTileUsage.forestSurface);
      expect(controller.state.topology, SmartTileTopology.blob8);
      expect(controller.state.templateHint, SmartTileTemplateHint.blob47);
    });

    test('maps arbitrary atlas cells to weighted canonical variants', () {
      final controller = _configuredController();
      controller
        ..selectUsage(SmartTileUsage.path)
        ..addAtlasVariant(
          mask: smartTileNorthBit | smartTileEastBit,
          column: 7,
          row: 3,
          candidateId: 'common',
          weight: 7,
        )
        ..addAtlasVariant(
          mask: smartTileNorthBit | smartTileEastBit,
          column: 1,
          row: 5,
          candidateId: 'rare',
          weight: 2,
        );

      final preset = controller.compilePreset();
      final rule = preset.rules.single;

      expect(rule.id, smartTileCanonicalRuleId(0x03));
      expect(rule.signature.northEdge.kind, SmartTileMatchKind.same);
      expect(rule.signature.eastEdge.kind, SmartTileMatchKind.same);
      expect(rule.candidates.map((item) => item.id), ['common', 'rare']);
      expect(rule.candidates.map((item) => item.weight), [7, 2]);
      expect(
        (rule.candidates.first.parts.single.source as SmartTileFrameSource)
            .frame,
        const SmartTileFrameRef(
          atlasId: 'atlas-hanazuki',
          column: 7,
          row: 3,
        ),
      );
    });

    test('forest visuals preserve independent multi-part render channels', () {
      final controller = _configuredController();
      controller
        ..selectUsage(SmartTileUsage.forestSurface)
        ..addAtlasVariant(
          mask: 0xff,
          column: 2,
          row: 1,
          candidateId: 'forest-main',
          channel: SmartTileRenderChannel.understory,
        )
        ..addVisualPart(
          mask: 0xff,
          candidateId: 'forest-main',
          part: const SmartTileVisualPart(
            source: SmartTileVisualSource.frame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas-hanazuki',
                column: 4,
                row: 0,
                columnSpan: 2,
                rowSpan: 3,
              ),
            ),
            channel: SmartTileRenderChannel.canopy,
            offsetY: -64,
            footprintWidth: 2,
            footprintHeight: 3,
            anchorX: 32,
            anchorY: 96,
            drawOrder: 10,
          ),
        );

      final parts =
          controller.compilePreset().rules.single.candidates.single.parts;

      expect(parts, hasLength(2));
      expect(parts.first.channel, SmartTileRenderChannel.understory);
      expect(parts.last.channel, SmartTileRenderChannel.canopy);
      expect(parts.last.footprintWidth, 2);
      expect(parts.last.anchorY, 96);
    });

    test('animations remain catalog records separate from variant weights', () {
      final controller = _configuredController();
      controller
        ..selectUsage(SmartTileUsage.terrain)
        ..addAnimation(
          const ProjectSmartTileAnimation(
            id: 'grass-wind',
            name: 'Herbe au vent',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas-hanazuki',
                  column: 0,
                  row: 0,
                ),
                durationMs: 180,
              ),
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas-hanazuki',
                  column: 1,
                  row: 0,
                ),
                durationMs: 220,
              ),
            ],
          ),
        )
        ..addAnimationVariant(
          mask: 0x0f,
          animationId: 'grass-wind',
          candidateId: 'animated',
          weight: 3,
        );

      final compiled = controller.compileCatalog();

      expect(compiled.animations, hasLength(1));
      expect(compiled.animations.single.frames, hasLength(2));
      final candidate = compiled.presets.single.rules.single.candidates.single;
      expect(candidate.weight, 3);
      expect(
        (candidate.parts.single.source as SmartTileAnimationSource).animationId,
        'grass-wind',
      );
    });

    test('applying a draft is an explicit v4 in-memory upsert', () {
      final controller = _configuredController();
      controller
        ..selectUsage(SmartTileUsage.path)
        ..addAtlasVariant(
          mask: 0,
          column: 0,
          row: 0,
          candidateId: 'isolated',
        );
      const legacy = ProjectTerrainPreset(
        id: 'legacy-grass',
        name: 'Legacy grass',
        terrainType: TerrainType.grass,
        tilesetId: 'legacy',
      );
      const manifest = ProjectManifest(
        name: 'legacy-project',
        version: ProjectVersion.v3,
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        terrainPresets: <ProjectTerrainPreset>[legacy],
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
      );

      final next = controller.applyToManifest(manifest);

      expect(next.version, ProjectVersion.v4);
      expect(next.terrainPresets, [legacy]);
      expect(next.smartTileCatalog.presets.single.id, 'hanazuki');
      expect(next.smartTileCatalog.atlases.single.id, 'atlas-hanazuki');
      expect(next.smartTileCatalog.materials.single.id, 'grass');
    });
  });
}

SmartTileAuthoringController _configuredController() {
  final controller = SmartTileAuthoringController.blank();
  controller
    ..configureIdentity(
      id: 'hanazuki',
      name: 'Hanazuki',
      materialId: 'grass',
      materialName: 'Herbe Hanazuki',
    )
    ..configureAtlas(
      atlasId: 'atlas-hanazuki',
      atlasName: 'Atlas Hanazuki',
      tilesetId: 'tileset-hanazuki',
      geometry: const SmartTileGridGeometry(
        imageWidth: 320,
        imageHeight: 192,
        cellWidth: 32,
        cellHeight: 32,
      ),
    );
  return controller;
}
