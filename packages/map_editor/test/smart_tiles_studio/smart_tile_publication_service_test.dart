import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart';

void main() {
  group('SmartTilePublicationService', () {
    const service = SmartTilePublicationService();

    test('blocks an incomplete preset without mutating the manifest', () {
      final manifest = _manifest(
        _preset(rules: <SmartTileRule>[_rule(0)]),
      );

      final result = service.publish(manifest: manifest, presetId: 'edge');

      expect(result.published, isFalse);
      expect(result.manifest, same(manifest));
      expect(
        result.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.incomplete'),
      );
      expect(
        manifest.smartTileCatalog.presets.single.status,
        SmartTilePresetStatus.draft,
      );
    });

    test('publishes a complete preset as an explicit v4 transaction', () {
      final manifest = _manifest(
        _preset(
          rules: <SmartTileRule>[
            for (var mask = 0; mask < 16; mask++) _rule(mask),
          ],
        ),
        version: ProjectVersion.v3,
      );

      final result = service.publish(manifest: manifest, presetId: 'edge');

      expect(result.published, isTrue);
      expect(result.diagnostics.where((item) => item.isError), isEmpty);
      expect(result.manifest.version, ProjectVersion.v4);
      expect(
        result.manifest.smartTileCatalog.presets.single.status,
        SmartTilePresetStatus.published,
      );
      expect(
        manifest.smartTileCatalog.presets.single.status,
        SmartTilePresetStatus.draft,
        reason: 'the publication service is immutable',
      );
    });
  });
}

ProjectManifest _manifest(
  ProjectSmartTilePreset preset, {
  ProjectVersion version = ProjectVersion.v4,
}) {
  return ProjectManifest(
    name: 'Publication test',
    version: version,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tileset.png',
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tileset',
          columns: 4,
          rows: 4,
        ),
      ],
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'grass',
        ),
      ],
      presets: <ProjectSmartTilePreset>[preset],
    ),
  );
}

ProjectSmartTilePreset _preset({required List<SmartTileRule> rules}) {
  return ProjectSmartTilePreset(
    id: 'edge',
    name: 'Edge',
    usage: SmartTileUsage.terrain,
    topology: SmartTileTopology.cardinal4,
    templateHint: SmartTileTemplateHint.edge16,
    status: SmartTilePresetStatus.draft,
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>['grass'],
    rules: rules,
  );
}

SmartTileRule _rule(int mask) => SmartTileRule(
      id: smartTileCanonicalRuleId(mask),
      signature: smartTileSignatureForMask(
        mask,
        topology: SmartTileTopology.cardinal4,
      ),
      candidates: const <SmartTileCandidate>[
        SmartTileCandidate(
          id: 'visual',
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
