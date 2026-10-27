import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_warp_ladder_editor.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'ladder selection updates only its warp through Studio commands and undo',
    (tester) async {
      const warp = MapWarp(
        id: 'stairs',
        pos: GridPos(x: 1, y: 1),
        targetMapId: 'upper',
        targetPos: GridPos(x: 2, y: 2),
      );
      final map = MapData(
        id: 'lower',
        name: 'Lower',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(width: 4, depth: 4),
        warps: [warp],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
      );
      final commands = WarpEditingCommands(
        document,
        const ProjectManifest(name: 'Climb', maps: [], tilesets: []),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => MapWarpLadderEditor(
                warp: document.current.warps.single,
                onApply: (ladder) {
                  commands.configureLadder(warp.id, ladder);
                  refresh(() {});
                },
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('apply-warp-ladder')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monter').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-warp-ladder')));
      await tester.pumpAndSettle();
      expect(
        document.current.warps.single,
        warp.copyWith(ladder: MapWarpLadder()),
      );
      document.restore(redo: false);
      expect(document.current, map);
      commands.configureLadder(
        warp.id,
        MapWarpLadder(direction: MapWarpLadderDirection.down),
      );
      commands.retarget(warp.id, triggerMode: MapWarpTriggerMode.sceneOnly);
      expect(document.current.warps.single.ladder, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
