import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'publishes model settings after a pending projection without rebuilding it',
    () async {
      final model = _model('house');
      final other = _model('tree');
      final workspace = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(
          manifest: workspaceProject.copyWith(models3d: [model, other]),
        ),
      );
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final visuals = _Visuals();
      final projection = WorkspaceVisualProjectionQueue(
        currentVisuals: () => visuals,
        activeMap: () => workspace.active?.current,
        isActive: () => !workspace.isDisposed,
        prepared: (_) {},
        failed: (error) => fail('$error'),
        changed: () {},
      );
      void synchronize() => projection.synchronize(workspace.visualProject);
      workspace.addListener(synchronize);
      synchronize();

      final first = model.copyWith(castsShadowsByDefault: true);
      final firstPublication = projection.acceptModelWorkshopReceipt(
        workspace,
        _receipt(workspace, first),
      );
      expect(visuals.publications, isEmpty);
      visuals.finishCatalog.complete();
      await firstPublication;

      await projection.acceptModelWorkshopReceipt(
        workspace,
        _receipt(workspace, model),
      );
      expect(visuals.publications, ['catalogue', 'house:true', 'house:false']);
      expect(visuals.activatedMaps, ['a']);
      expect(workspace.visualProject?.models3d, [model, other]);
      expect(visuals.lastManifest, same(workspace.visualProject));
    },
  );
}

ResourceMutationReceipt _receipt(
  MapWorkspaceController workspace,
  ProjectModel3dEntry model,
) {
  final before = workspace.project!;
  return ResourceMutationReceipt(
    before: before,
    manifest: before.copyWith(models3d: [model]),
    beforeRevision: 'before',
    revision: 'after',
    changedPaths: const ['catalog/HEAD.json'],
    changedModels: {model.id: model},
  );
}

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry(
  id: id,
  name: id,
  sourceAssetId: id,
  relativePath: 'assets/models3d/$id.glb',
  castsShadowsByDefault: false,
  inspection: Model3dInspection(
    bounds: Model3dBounds(min: Model3dVector3.zero, max: Model3dVector3.zero),
    meshCount: 1,
    triangleCount: 1,
  ),
);

class _Visuals extends WorkspaceTestVisuals
    implements ResourceWorkspaceVisuals, SpatialModelSourceWorkspaceVisuals {
  final finishCatalog = Completer<void>();
  final publications = <String>[];
  ProjectManifest? lastManifest;

  @override
  final modelSourceUpdates = SpatialModelSourceUpdates();

  @override
  Widget atlasPreview(String tilesetId) => const SizedBox();

  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}

  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {
    await finishCatalog.future;
    publications.add('catalogue');
    lastManifest = manifest;
  }

  @override
  Future<void> updateModelSources(
    ProjectManifest manifest,
    Map<String, ProjectModel3dEntry> definitions,
    Map<String, String> revisions,
  ) async {
    final model = definitions.values.single;
    publications.add('${model.id}:${model.castsShadowsByDefault}');
    lastManifest = manifest;
  }
}
