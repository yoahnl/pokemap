import 'package:avelune_studio/features/map_workspace/application/map_palette_intent.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

const _alice = ProjectCharacterEntry(
  id: 'alice',
  name: 'Alice',
  tilesetId: 'atlas',
);

ProjectSmartTilePreset _surface(
  String id,
  SmartTileUsage usage,
  String material,
) => ProjectSmartTilePreset(
  id: id,
  name: id,
  usage: usage,
  topology: SmartTileTopology.uniform,
  templateHint: SmartTileTemplateHint.simple,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: const SmartTileTransformPolicy(),
  defaultMaterialId: material,
  allowedMaterialIds: [material],
  rules: [
    SmartTileRule(
      id: 'fill',
      centerMatch: SmartTileSlotMatch.material(material),
      candidates: [
        SmartTileCandidate(
          id: 'fill',
          parts: [
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(atlasId: id, column: 0, row: 0),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  test('choosing decors without a decor names an unarmed selection', () {
    final view = MapWorkspaceEditingState();
    view.tool = StudioMapTool.select;
    final intent = mapPaletteIntent(view);
    expect(intent.action, 'Sélection');
    expect(intent.armed, isFalse);
    expect(intent.next, contains('Choisissez un décor'));
    view
      ..brush = workspaceElement
      ..tool = StudioMapTool.place;
    final armed = mapPaletteIntent(view);
    expect(armed.action, 'Placement de décor');
    expect(armed.group, MapIntentGroup.build);
    expect(armed.resource, 'Arbre');
    expect(armed.paletteTab, 'Décors');
    expect(armed.armed, isTrue);
  });

  test('moving from a cliff to a character never keeps the border active', () {
    final view = MapWorkspaceEditingState();
    view
      ..tool = StudioMapTool.border
      ..borderBlueprintId = 'falaise';
    expect(mapPaletteIntent(view).action, 'Tracé de bordure');
    view.character = _alice;
    view.prepareCharacterPlacement();
    final intent = mapPaletteIntent(view);
    expect(intent.group, MapIntentGroup.populate);
    expect(intent.action, 'Placement de personnage');
    expect(intent.paletteTab, 'Personnages');
    expect(intent.resource, 'Alice');
    expect(intent.resource, isNot(contains('falaise')));
  });

  test('collisions and spawn use no resource palette', () {
    final view = MapWorkspaceEditingState();
    for (final tool in [
      StudioMapTool.collisionPaint,
      StudioMapTool.collisionErase,
      StudioMapTool.spawn,
      StudioMapTool.gameplayZone,
    ]) {
      view.tool = tool;
      final intent = mapPaletteIntent(view);
      expect(intent.paletteTab, isNull, reason: '$tool');
      expect(intent.armed, isTrue, reason: '$tool');
    }
  });

  test('a terrain gesture is named from its native preset', () {
    final project = workspaceProject.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [
          ProjectSmartTileMaterial(
            id: 'sea',
            name: 'Mer',
            connectionGroupId: 'sea',
            pathSurfaceKind: PathSurfaceKind.water,
          ),
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Terre',
            connectionGroupId: 'dirt',
            pathSurfaceKind: PathSurfaceKind.path,
          ),
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Herbe',
            connectionGroupId: 'grass',
          ),
        ],
      ),
    );
    final view = MapWorkspaceEditingState()..tool = StudioMapTool.terrain;
    expect(mapPaletteIntent(view, project: project).armed, isFalse);
    for (final (preset, label) in [
      (_surface('grass', SmartTileUsage.terrain, 'grass'), 'Sol'),
      (_surface('path', SmartTileUsage.path, 'dirt'), 'Chemin'),
      (_surface('sea', SmartTileUsage.path, 'sea'), 'Eau'),
    ]) {
      view.terrain = preset;
      final intent = mapPaletteIntent(view, project: project);
      expect(intent.action, label);
      expect(intent.armed, isTrue);
    }
  });

  test('a 3D ground without terrain is not armed, relief and slope are', () {
    final view = MapWorkspaceEditingState()..tool = StudioMapTool.terrain;
    final ground = mapPaletteIntent(view, spatial: true);
    expect(ground.armed, isFalse);
    expect(ground.next, contains('Choisissez un sol, un chemin ou une eau'));
    view.spatialTerrainMode = SpatialTerrainMode.relief;
    expect(mapPaletteIntent(view, spatial: true).action, 'Relief');
    view.spatialTerrainMode = SpatialTerrainMode.ramp;
    final slope = mapPaletteIntent(view, spatial: true);
    expect(slope.action, 'Pente');
    expect(slope.usesPalette, isFalse);
  });

}
