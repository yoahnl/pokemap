import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_studio_library.dart';

void main() {
  test('lists native v6 records without any legacy project data', () {
    final manifest = ProjectManifest(
      name: 'native library',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Dirt',
            connectionGroupId: 'dirt',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'native-path',
            name: 'Native path',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.blob8,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.explicit,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'dirt',
            allowedMaterialIds: <String>['dirt'],
            status: SmartTilePresetStatus.published,
          ),
        ],
      ),
    );

    final items = buildSmartTileStudioLibrary(manifest);

    expect(items, hasLength(1));
    expect(items.single.id, 'native-path');
    expect(items.single.usage, SmartTileUsage.path);
    expect(items.single.statusLabel, 'Publié');
  });

  test('an empty v6 catalog exposes no synthetic legacy entries', () {
    const manifest = ProjectManifest(
      name: 'empty library',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );

    final items = buildSmartTileStudioLibrary(manifest);

    expect(items, isEmpty);
  });

  test('lists canonical drafts as resumable no-code records', () {
    final manifest = ProjectManifest(
      name: 'draft library',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        drafts: const <ProjectSmartTileAuthoringDraft>[
          ProjectSmartTileAuthoringDraft(
            id: 'draft-grass',
            targetPresetId: 'grass',
            name: 'Herbe en cours',
            usage: SmartTileUsage.terrain,
            lastStage: SmartTileAuthoringStage.grid,
          ),
        ],
      ),
    );

    final items = buildSmartTileStudioLibrary(manifest);

    expect(items, hasLength(1));
    expect(items.single.key, 'draft:draft-grass');
    expect(items.single.statusLabel, 'Brouillon à reprendre');
    expect(items.single.isResumableDraft, isTrue);
    expect(
        items.single.canonicalDraft?.lastStage, SmartTileAuthoringStage.grid);
  });

  test('lists reusable patterns as native no-code records', () {
    final manifest = ProjectManifest(
      name: 'pattern library',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        patterns: const <ProjectSmartTilePattern>[
          ProjectSmartTilePattern(
            id: 'stone_patch',
            name: 'Pierre claire',
            usage: SmartTileUsage.path,
            width: 1,
            height: 1,
          ),
        ],
      ),
    );

    final items = buildSmartTileStudioLibrary(manifest);

    expect(items, hasLength(1));
    expect(items.single.key, 'pattern:stone_patch');
    expect(items.single.pattern, manifest.smartTileCatalog.patterns.single);
    expect(items.single.isPattern, isTrue);
    expect(items.single.statusLabel, 'Motif réutilisable');
  });
}
