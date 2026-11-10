import 'package:avelune_studio/features/map_workspace/application/map_palette_intent.dart';
import 'package:avelune_studio/features/map_workspace/application/map_tool_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceEditingState state;
  late MapToolCommandRunner runner;
  String palette = '';
  int changes = 0, reveals = 0, resources = 0;

  setUp(() {
    state = MapWorkspaceEditingState();
    palette = 'Décors';
    changes = reveals = resources = 0;
    runner = MapToolCommandRunner(
      view: state,
      paletteTab: () => palette,
      selectPalette: (value) => palette = value,
      spatial: true,
      paletteVisible: false,
      onChanged: () => changes++,
      onMoreTools: () => reveals++,
      onResources: () => resources++,
    );
  });

  test('decor selection only arms placement when a resource is prepared', () {
    runner.runFamily('Décors');
    expect(state.tool, StudioMapTool.select);
    state.brush = workspaceElement;
    runner.runFamily('Décors');
    expect(state.tool, StudioMapTool.place);
    final intent = mapPaletteIntent(state, paletteTab: palette);
    expect(intent.armed, isTrue);
    expect(intent.resource, 'Arbre');
    expect(intent.group, MapIntentGroup.build);
    expect(changes, 2);
    expect(reveals, 2);
  });

  test(
    'spatial terrain family arms painting and publishes the palette intent',
    () {
      runner.runFamily('Terrains');
      expect(state.tool, StudioMapTool.terrain);
      expect(palette, 'Terrains');
      final intent = mapPaletteIntent(
        state,
        spatial: true,
        paletteTab: palette,
      );
      expect(intent.armed, isFalse);
      expect(intent.paletteTab, 'Terrains');
      expect(reveals, 1);
    },
  );

  test('warp and character commands select their resource families', () {
    runner.runExtra('Passages');
    expect(state.tool, StudioMapTool.select);
    expect(palette, 'Passages');
    state.warpDestination = workspaceEntries.last;
    runner.runExtra('Passages');
    expect(state.tool, StudioMapTool.warp);
    runner.runExtra('Placer un personnage');
    expect(state.tool, StudioMapTool.select);
    expect(palette, 'Personnages');
    state.character = const ProjectCharacterEntry(
      id: 'guide',
      name: 'Guide',
      tilesetId: 'atlas',
    );
    runner.runExtra('Placer un personnage');
    expect(state.tool, StudioMapTool.character);
    expect(reveals, 4);
  });

  test(
    'field obstacles restore decor choices from another resource family',
    () {
      for (final (label, kind) in [
        ('Placer un arbre à couper', FieldObstacleKind.cutTree),
        ('Placer un rocher à pousser', FieldObstacleKind.strengthBoulder),
        ('Placer un rocher à briser', FieldObstacleKind.rockSmashRock),
      ]) {
        runner.runExtra('Placer un personnage');
        expect(palette, 'Personnages');
        runner.runExtra(label);
        expect(state.tool, StudioMapTool.fieldObstacle);
        expect(state.fieldObstacleKind, kind);
        expect(palette, 'Décors');
      }
      runner.runFamily('Sélection');
      expect(state.tool, StudioMapTool.select);
      expect(
        mapPaletteIntent(state, paletteTab: 'Personnages').next,
        contains('personnage'),
      );
    },
  );

  test('resource navigation and history avoid document tool mutations', () {
    final tool = state.tool;
    runner.runExtra('Gérer les ressources');
    runner.run(mapWorkspaceCommand('map.undo'));
    expect(resources, 1);
    expect(changes, 0);
    expect(state.tool, tool);
  });

  test('profile restrictions remain explicit in the command data', () {
    const exterior = MapCommandContext(exterior: true, spatial: true);
    expect(
      mapCommandUnavailable('map.warps', exterior),
      contains('zone jouable'),
    );
    expect(
      mapCommandUnavailable(
        'map.zones',
        const MapCommandContext(spatial: true),
      ),
      contains('3D'),
    );
    expect(
      mapCommandUnavailable(
        'map.border',
        const MapCommandContext(spatial: true),
      ),
      isNull,
    );
    expect(
      mapCommandUnavailable('map.undo', const MapCommandContext()),
      isNotNull,
    );
  });
  test('tile arming clears incompatible brushes and preserves chosen tile', () {
    state.brush = workspaceElement;
    const tile = TileLayerPaletteEntry(tilesetId: 'sheet', localTileId: 7);
    state.selectTile(tile);
    expect(state.tile, tile);
    expect(state.brush, isNull);
    expect(state.terrain, isNull);
    expect(state.character, isNull);
    expect(state.tool, StudioMapTool.paint);
  });

  test(
    'pushable obstacle selection resets its policy but cut keeps its choice',
    () {
      state.fieldObstacleResetPolicy = FieldObstacleResetPolicy.persistent;
      state.selectFieldObstacleKind(FieldObstacleKind.cutTree);
      expect(
        state.fieldObstacleResetPolicy,
        FieldObstacleResetPolicy.persistent,
      );
      for (final kind in [
        FieldObstacleKind.strengthBoulder,
        FieldObstacleKind.iceBlock,
      ]) {
        state.fieldObstacleResetPolicy = FieldObstacleResetPolicy.persistent;
        state.selectFieldObstacleKind(kind);
        expect(state.fieldObstacleKind, kind);
        expect(
          state.fieldObstacleResetPolicy,
          FieldObstacleResetPolicy.mapInstance,
        );
      }
    },
  );

  test(
    'exterior target clears a pending move and disarms incompatible tools',
    () {
      const target = MapSelectionTarget(
        mapId: 'a',
        family: MapSelectionFamily.decor,
        id: 'tree',
      );
      state.pendingMove = target;
      state.tool = StudioMapTool.warp;
      state.prepareExteriorEditing(true);
      expect(state.pendingMove, isNull);
      expect(state.tool, StudioMapTool.select);
      state.tool = StudioMapTool.place;
      state.prepareExteriorEditing(true);
      expect(state.tool, StudioMapTool.place);
      state.tool = StudioMapTool.warp;
      state.prepareExteriorEditing(false);
      expect(state.tool, StudioMapTool.warp);
    },
  );
}
