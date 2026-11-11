import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_item_action_matrix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const _tileset = ProjectTilesetEntry(
  id: 'atlas',
  name: 'Exemple',
  relativePath: 'atlas.png',
);

ResourceItem _decor() => const ResourceItem(
  id: 'tree',
  name: 'Arbre',
  kind: ResourceKind.decors,
  element: workspaceElement,
);
ResourceItem _image() => const ResourceItem(
  id: 'atlas',
  name: 'Exemple',
  kind: ResourceKind.images,
  tileset: _tileset,
);
ResourceItem _terrain() => const ResourceItem(
  id: 'grass',
  name: 'Herbe',
  kind: ResourceKind.terrains,
  terrain: ProjectSmartTilePreset(
    id: 'grass',
    name: 'Herbe',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.uniform,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: SmartTileTransformPolicy(),
    defaultMaterialId: 'grass',
    allowedMaterialIds: ['grass'],
  ),
);
ResourceItem _model() => ResourceItem(
  id: 'lamp',
  name: 'Lamp',
  kind: ResourceKind.decors,
  model3d: ProjectModel3dEntry(
    id: 'lamp',
    name: 'Lamp',
    sourceAssetId: 'model3d_lamp',
    relativePath: 'assets/models3d/lamp.glb',
    inspection: Model3dInspection(
      bounds: Model3dBounds(
        min: Model3dVector3.zero,
        max: Model3dVector3(x: 1, y: 1, z: 1),
      ),
      meshCount: 1,
      triangleCount: 4,
    ),
  ),
);

List<String> _labels(
  ResourceItem item, {
  bool information = true,
  bool move = true,
  bool usages = true,
  bool replace = true,
  bool remove = true,
  bool duplicate = true,
  bool terrainEdit = true,
}) => [
  for (final entry in resourceItemActionMatrix(
    item,
    onInformation: information,
    onMove: move,
    onUsages: usages,
    onReplace: replace,
    onRemove: remove,
    onDuplicate: duplicate,
    onTerrainEdit: terrainEdit,
  ))
    entry.label,
];

void main() {
  test('a terrain offers edit, rename, move, usages, duplicate and remove in that order', () {
    expect(_labels(_terrain()), [
      'Modifier les raccords',
      'Renommer le terrain…',
      'Déplacer vers…',
      'Voir les usages dans le projet',
      'Dupliquer le terrain…',
      'Supprimer le terrain…',
    ]);
  });

  test('an image sheet offers information, move, usages, replacement and sheet removal', () {
    expect(_labels(_image()), [
      'Modifier les informations',
      'Déplacer vers…',
      'Voir les usages dans le projet',
      'Remplacer l’image source…',
      'Supprimer la planche…',
    ]);
  });

  test('a decor definition offers move, usages, duplication and definition removal only', () {
    expect(_labels(_decor()), [
      'Déplacer vers…',
      'Voir les usages dans le projet',
      'Dupliquer la définition…',
      'Supprimer la définition…',
    ]);
  });

  test('a 3D model has no catalogue action and missing handlers hide their entries', () {
    expect(_labels(_model()), isEmpty);
    expect(
      _labels(_terrain(), terrainEdit: false, remove: false, duplicate: false),
      [
        'Renommer le terrain…',
        'Déplacer vers…',
        'Voir les usages dans le projet',
      ],
    );
    expect(
      _labels(
        _image(),
        information: false,
        move: false,
        usages: false,
        replace: false,
        remove: false,
      ),
      isEmpty,
    );
  });

  test('only the removal entries are destructive', () {
    final destructive = {
      for (final item in [_terrain(), _image(), _decor()])
        for (final entry in resourceItemActionMatrix(
          item,
          onInformation: true,
          onMove: true,
          onUsages: true,
          onReplace: true,
          onRemove: true,
          onDuplicate: true,
          onTerrainEdit: true,
        ))
          if (entry.kind.destructive) entry.kind,
    };
    expect(destructive, {
      ResourceItemActionKind.removeTerrain,
      ResourceItemActionKind.remove,
    });
  });
}
