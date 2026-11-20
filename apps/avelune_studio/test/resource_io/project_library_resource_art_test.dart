import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/rendering/contracts/character_workspace_visuals.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_resource_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('the library previews a character as a still sprite', (
    tester,
  ) async {
    const character = ProjectCharacterEntry(
      id: 'guide',
      name: 'Guide',
      tilesetId: 'atlas',
    );
    final visuals = _CharacterVisuals();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ProjectLibraryResourceArt(
            item: const ResourceItem(
              id: 'guide',
              name: 'Guide',
              kind: ResourceKind.images,
              character: character,
            ),
            project: workspaceProject,
            visuals: visuals,
            size: 96,
            compact: true,
          ),
        ),
      ),
    );

    expect(visuals.requested, [character]);
    expect(find.byKey(const ValueKey('character-preview')), findsOneWidget);
  });

  testWidgets('grid models queue their reads and release a failed slot', (
    tester,
  ) async {
    final visuals = _SpatialVisuals();
    final models = [
      for (final id in ['first', 'second', 'third']) _model(id),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Row(
            children: [
              for (final model in models)
                ProjectLibraryResourceArt(
                  item: ResourceItem(
                    id: model.id,
                    name: model.name,
                    kind: ResourceKind.decors,
                    model3d: model,
                  ),
                  project: workspaceProject,
                  visuals: visuals,
                  size: 96,
                  compact: true,
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(visuals.reads.keys, ['first', 'second']);
    visuals.reads['first']!.completeError(StateError('Source absente'));
    await tester.pump();
    await tester.pump();

    expect(visuals.reads.keys, ['first', 'second', 'third']);
    expect(find.bySemanticsLabel('Aperçu 3D indisponible'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry(
  id: id,
  name: id,
  sourceAssetId: 'asset-$id',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);

class _SpatialVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  final reads = <String, Completer<Uint8List>>{};

  @override
  Future<Uint8List> readModel(String modelId) =>
      reads.putIfAbsent(modelId, Completer.new).future;

  @override
  Future<Uint8List> readGroundImage(String tilesetId) =>
      throw UnsupportedError('Seul le modèle est demandé');

  @override
  Future<SpatialNpcPreview> spatialPreview(
    MapData map,
    ProjectManifest project,
  ) => throw UnsupportedError('Aucune carte active');
}

class _CharacterVisuals extends WorkspaceTestVisuals
    implements CharacterWorkspaceVisuals {
  final requested = <ProjectCharacterEntry>[];

  @override
  Widget characterThumbnail(
    ProjectCharacterEntry character, {
    double size = 48,
    EntityFacing facing = EntityFacing.south,
  }) {
    requested.add(character);
    return const SizedBox(key: ValueKey('character-preview'));
  }

  @override
  ProjectRegularAtlasTilesetSource? characterAtlas(
    ProjectCharacterEntry character,
  ) => null;

  @override
  Widget characterAnimationThumbnail(
    ProjectCharacterEntry character, {
    required double size,
    required EntityFacing facing,
    required CharacterAnimationState state,
    required int elapsedMs,
  }) => throw UnsupportedError('La grille utilise un sprite fixe');

  @override
  void setCharacterBrush(ProjectCharacterEntry? character) {}
}
