import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_surface_preset_draft.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TiledTsxSurfacePresetDraft', () {
    test('validates and builds a preset from an explicit isolated mapping', () {
      final catalog = _miniCatalog();
      final draft = const TiledTsxSurfacePresetDraft(
        id: 'water-tsx-surface',
        name: 'Water TSX Surface',
        categoryId: 'water',
        sortOrder: 7,
        roleAnimationIds: {
          SurfaceVariantRole.isolated: 'tech-animations-tile-99',
          SurfaceVariantRole.horizontal: 'tech-animations-tile-105',
        },
      );

      final validation = validateTiledTsxSurfacePresetDraft(
        draft: draft,
        catalog: catalog,
      );
      final preset = buildTiledTsxSurfacePresetFromDraft(
        draft: draft,
        catalog: catalog,
      );

      expect(validation.canCreate, isTrue);
      expect(validation.errors, isEmpty);
      expect(
        validation.warnings,
        contains(
          startsWith('Surface partielle'),
        ),
      );
      expect(preset.id, 'water-tsx-surface');
      expect(preset.name, 'Water TSX Surface');
      expect(preset.categoryId, 'water');
      expect(preset.sortOrder, 7);
      expect(
        preset.animationIdForRole(SurfaceVariantRole.isolated),
        'tech-animations-tile-99',
      );
      expect(
        preset.animationIdForRole(SurfaceVariantRole.horizontal),
        'tech-animations-tile-105',
      );
      expect(preset.animationIdForRole(SurfaceVariantRole.endNorth), isNull);
    });

    test('rejects duplicate preset ids', () {
      final existing = ProjectSurfacePreset(
        id: 'water-tsx-surface',
        name: 'Existing',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'tech-animations-tile-99',
            ),
          ],
        ),
      );
      final catalog = _miniCatalog(presets: [existing]);

      final validation = validateTiledTsxSurfacePresetDraft(
        draft: const TiledTsxSurfacePresetDraft(
          id: 'water-tsx-surface',
          name: 'Water TSX Surface',
          categoryId: null,
          sortOrder: 0,
          roleAnimationIds: {
            SurfaceVariantRole.isolated: 'tech-animations-tile-99',
          },
        ),
        catalog: catalog,
      );

      expect(validation.canCreate, isFalse);
      expect(
          validation.errors, contains('Identifiant de preset déjà utilisé.'));
    });

    test('requires isolated and known animation ids', () {
      final catalog = _miniCatalog();

      final missingIsolated = validateTiledTsxSurfacePresetDraft(
        draft: const TiledTsxSurfacePresetDraft(
          id: 'water-tsx-surface',
          name: 'Water TSX Surface',
          categoryId: null,
          sortOrder: 0,
          roleAnimationIds: {
            SurfaceVariantRole.horizontal: 'tech-animations-tile-100',
          },
        ),
        catalog: catalog,
      );
      final unknownAnimation = validateTiledTsxSurfacePresetDraft(
        draft: const TiledTsxSurfacePresetDraft(
          id: 'water-tsx-surface',
          name: 'Water TSX Surface',
          categoryId: null,
          sortOrder: 0,
          roleAnimationIds: {
            SurfaceVariantRole.isolated: 'missing-animation',
          },
        ),
        catalog: catalog,
      );

      expect(missingIsolated.canCreate, isFalse);
      expect(missingIsolated.errors, contains('Plein(center) obligatoire.'));
      expect(unknownAnimation.canCreate, isFalse);
      expect(
        unknownAnimation.errors,
        contains('Animation inconnue pour Plein : missing-animation.'),
      );
    });

    test('reports draft identity errors', () {
      final validation = validateTiledTsxSurfacePresetDraft(
        draft: const TiledTsxSurfacePresetDraft(
          id: ' ',
          name: '',
          categoryId: null,
          sortOrder: 0,
          roleAnimationIds: {},
        ),
        catalog: _miniCatalog(),
      );

      expect(validation.canCreate, isFalse);
      expect(validation.errors, contains('Identifiant surface obligatoire.'));
      expect(validation.errors, contains('Nom surface obligatoire.'));
      expect(validation.errors, contains('Plein(center) obligatoire.'));
    });

    test('builds a preset from the real Pokemon SDK TSX import output', () {
      final result = importTiledTsxSurfaceAnimationsFromXml(
        xml: _readTechAnimationsTsx(),
        options: const TiledTsxSurfaceAnimationImportOptions(
          atlasId: 'tech-animations',
          tilesetId: 'tech-nature-animations',
          animationIdPrefix: 'tech-animations',
        ),
      );
      final catalog = ProjectSurfaceCatalog(
        atlases: [result.atlas!],
        animations: result.animations,
      );

      final preset = buildTiledTsxSurfacePresetFromDraft(
        draft: const TiledTsxSurfacePresetDraft(
          id: 'water-tsx-surface',
          name: 'Water TSX Surface',
          categoryId: null,
          sortOrder: 0,
          roleAnimationIds: {
            SurfaceVariantRole.isolated: 'tech-animations-tile-99',
            SurfaceVariantRole.horizontal: 'tech-animations-tile-100',
          },
        ),
        catalog: catalog,
      );
      final next = surfaceStudioAppendPresetToWorkCatalog(
        catalog: catalog,
        preset: preset,
      );

      expect(result.animations, hasLength(242));
      expect(preset.animationIdForRole(SurfaceVariantRole.isolated),
          'tech-animations-tile-99');
      expect(preset.animationIdForRole(SurfaceVariantRole.horizontal),
          'tech-animations-tile-100');
      expect(next.animationCount, 242);
      expect(next.presetCount, 1);
      expect(next.presetById('water-tsx-surface'), preset);
    });
  });
}

ProjectSurfaceCatalog _miniCatalog({
  List<ProjectSurfacePreset> presets = const [],
}) {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'tech-animations',
        name: 'TECH-Animations',
        tilesetId: 'tech-nature-animations',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [
      _animation('tech-animations-tile-99', 1, 1),
      _animation('tech-animations-tile-105', 7, 1),
      _animation('tech-animations-tile-111', 13, 1),
    ],
    presets: presets,
  );
}

ProjectSurfaceAnimation _animation(String id, int column, int row) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: column,
            row: row,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}

String _readTechAnimationsTsx() {
  final repoRoot = Directory.current.parent.parent;
  final sdkProject = repoRoot
      .listSync()
      .whereType<Directory>()
      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
  final tsxFile = File(
    p.join(
      sdkProject.path,
      'Data',
      'Tiled',
      'Tilesets',
      'TECH-Animations.tsx',
    ),
  );
  return tsxFile.readAsStringSync();
}
