import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'spatial_terrain_draft_fixtures.dart';

void main() {
  test('published spatial presets preserve metadata and reject unsupported mirroring', () {
    final model = spatialPathDraft();
    final originalPart = model
        .partFor(0)!
        .copyWith(
          source: (model.partFor(0)!.source as SmartTileModel3dSource).copyWith(
            animationIndex: 0,
            followTerrain: false,
            offsetX: .125,
            offsetZ: -.375,
          ),
        );
    final preset = model.previewPreset.copyWith(
      name: 'Herbes',
      categoryId: 'custom',
      sortOrder: 7,
      seedSalt: 19,
      tags: ['hautes'],
      rules: [
        model.previewPreset.rules.single.copyWith(
          id: 'original-rule',
          candidates: [
            model.previewPreset.rules.single.candidates.single.copyWith(
              id: 'original-candidate',
              weight: 3,
              parts: [
                originalPart.copyWith(
                  offsetUnit: SmartTileOffsetUnit.cell,
                  offsetX: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final project = model.manifest.copyWith(
      models3d: [
        ProjectModel3dEntry(
          id: model.manifest.models3d.single.id,
          name: model.manifest.models3d.single.name,
          sourceAssetId: model.manifest.models3d.single.sourceAssetId,
          relativePath: model.manifest.models3d.single.relativePath,
          inspection: Model3dInspection(
            bounds: model.manifest.models3d.single.inspection.bounds,
            meshCount: 1,
            triangleCount: 4,
            animations: [
              Model3dAnimation(index: 0, name: 'Flow', durationSeconds: 1),
            ],
          ),
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: model.draft.materials,
        presets: [preset],
      ),
    );
    final draft = editableTerrainDraft(project, preset);
    expect(draft, isNotNull);
    final resumed = TerrainDraftController.resume(
      manifest: project,
      draft: draft!,
    );
    expect(resumed.previewPreset, preset);
    resumed.assignModel(project.models3d.single, quarterTurns: 2);
    expect(
      (resumed.partFor(0)!.source as SmartTileModel3dSource).offsetX,
      .125,
    );
    expect(
      (resumed.partFor(0)!.source as SmartTileModel3dSource).offsetZ,
      -.375,
    );
    expect(resumed.partFor(0)!.offsetX, 1);
    expect(resumed.partFor(0)!.offsetUnit, SmartTileOffsetUnit.cell);
    expect(
      (resumed.partFor(0)!.source as SmartTileModel3dSource).animationIndex,
      0,
    );
    expect(
      (resumed.partFor(0)!.source as SmartTileModel3dSource).followTerrain,
      isFalse,
    );
    final mirrored = draft.copyWith(
      rules: [
        draft.rules.single.copyWith(
          candidates: [
            draft.rules.single.candidates.single.copyWith(
              parts: [
                originalPart.copyWith(
                  transform: const SmartTileSpriteTransform(flipX: true),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      () => TerrainDraftController.resume(manifest: project, draft: mirrored),
      throwsStateError,
    );
    expect(
      () => TerrainDraftController.resume(
        manifest: project.copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.twoD),
        ),
        draft: draft,
      ),
      throwsStateError,
    );
  });

  test('shared creation excludes local models and scoped paths accept only their own map sources', () {
    final model = spatialPathDraft();
    final local = spatialPathModel('local');
    final other = spatialPathModel('other');
    final project = model.manifest.copyWith(
      models3d: [...model.manifest.models3d, local, other],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'local',
            familyId: 'vegetation',
            mapId: 'a',
          ),
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'other',
            familyId: 'vegetation',
            mapId: 'b',
          ),
        ],
      ),
    );
    expect(
      () => TerrainDraftController.spatial(
        manifest: project,
        model: local,
        id: 'new',
      ),
      throwsStateError,
    );
    model.manifest = project;
    final original = model.draft;
    model.assignModel(local);
    expect(model.draft, original);
    model.manifest = project.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ...project.resourceLibraryCatalog.entries,
          ResourceLibraryEntry(
            resourceKind: 'smartTilePreset',
            resourceId: 'grass',
            familyId: 'vegetation',
            mapId: 'a',
          ),
        ],
      ),
    );
    model.assignModel(local);
    expect(
      (model.partFor(0)!.source as SmartTileModel3dSource).modelId,
      'local',
    );
    final scoped = model.draft;
    model.assignModel(other);
    expect(model.draft, scoped);
    expect(terrainDraftCompatibilityProblem(model.manifest, scoped), isNull);
  });
}
