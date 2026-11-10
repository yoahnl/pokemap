import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_warp_drafts.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show MapWarpTransitionPreview, MapWarpTransitionOverlay;

void main() {
  test('transition starts unchanged with the canonical precise duration', () {
    final source = _map();
    final draft = MapWarpTransitionDraft(source.warps.first.transition);
    expect(draft.durationMs, '200');
    expect(draft.value, source.warps.first.transition);
    draft.reset(const MapWarpTransition(durationSeconds: .0254));
    expect(draft.durationMs, '25');
    expect(draft.value!.durationSeconds, .0254);
    draft.type = MapWarpTransitionType.hgss;
    expect(draft.value!.durationSeconds, .0254);
  });

  test('type and duration commit atomically through the shared operation with undo', () {
    final document = _document(_map());
    final original = document.current;
    final draft = MapWarpTransitionDraft(original.warps.first.transition)
      ..type = MapWarpTransitionType.hgss
      ..durationMs = '350'
      ..durationTouched = true;
    expect(document.current, same(original));
    WarpEditingCommands(
      document,
      _project,
    ).configureTransition('house', draft.value!);
    expect(
      document.current.warps.first.transition,
      const MapWarpTransition(
        type: MapWarpTransitionType.hgss,
        durationSeconds: .35,
      ),
    );
    expect(
      document.current.warps.first.targetMapId,
      original.warps.first.targetMapId,
    );
    expect(
      document.current.warps.first.targetPos,
      original.warps.first.targetPos,
    );
    expect(document.current.layers, original.layers);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, original);
    document.restore(redo: true);
    expect(
      document.current.warps.first.transition.type,
      MapWarpTransitionType.hgss,
    );
  });

  test('none survives JSON with canonical duration preserved', () {
    final document = _document(_map());
    final draft = MapWarpTransitionDraft(
      document.current.warps.first.transition,
    )..type = MapWarpTransitionType.none;
    WarpEditingCommands(
      document,
      _project,
    ).configureTransition('house', draft.value!);
    final restored = MapData.fromJson(document.current.toJson());
    expect(restored.warps.first.transition.type, MapWarpTransitionType.none);
    expect(restored.warps.first.transition.durationSeconds, .2);
  });

  test('invalid durations produce no applicable draft and no history', () {
    final document = _document(_map());
    final before = document.current;
    final draft = MapWarpTransitionDraft(before.warps.first.transition)
      ..durationTouched = true;
    for (final value in [
      '0',
      '-1',
      'NaN',
      'Infinity',
      '5001',
      '1.5',
      '1e3',
      '',
    ]) {
      draft.durationMs = value;
      expect(draft.value, isNull, reason: value);
    }
    expect(document.current, same(before));
    expect(document.undoCount, 0);
  });

  test('one and five thousand milliseconds remain available', () {
    final document = _document(_map());
    final draft = MapWarpTransitionDraft(
      document.current.warps.first.transition,
    )..durationTouched = true;
    for (final value in [1, 5000]) {
      draft.durationMs = '$value';
      WarpEditingCommands(
        document,
        _project,
      ).configureTransition('house', draft.value!);
      expect(
        document.current.warps.first.transition.durationSeconds,
        value / 1000,
      );
    }
  });

  test('retargeting preserves pending transition and latest target', () {
    final document = _document(_map());
    final draft = MapWarpTransitionDraft(
      document.current.warps.first.transition,
    )..type = MapWarpTransitionType.hgss;
    final commands = WarpEditingCommands(document, _project);
    commands.retarget('house', targetPos: const GridPos(x: 4, y: 5));
    commands.configureTransition('house', draft.value!);
    final warp = document.current.warps.first;
    expect(warp.targetPos, const GridPos(x: 4, y: 5));
    expect(warp.transition.type, MapWarpTransitionType.hgss);
    commands.retarget('house', triggerMode: MapWarpTriggerMode.onBump);
    expect(document.current.warps.first.transition, warp.transition);
  });

  test(
    'selection reset drops the former local draft and defaults remain staged',
    () {
      final document = _document(_map());
      final draft =
          MapWarpTransitionDraft(document.current.warps.first.transition)
            ..type = MapWarpTransitionType.hgss
            ..durationMs = '900'
            ..durationTouched = true;
      draft.reset(document.current.warps.last.transition);
      expect(draft.type, MapWarpTransitionType.none);
      expect(draft.durationMs, '100');
      expect(draft.value, document.current.warps.last.transition);
      draft.defaults();
      expect(draft.type, MapWarpTransitionType.fade);
      expect(draft.durationMs, '200');
      expect(document.undoCount, 0);
      WarpEditingCommands(
        document,
        _project,
      ).configureTransition('stairs', draft.value!);
      expect(document.current.warps.last.transition, const MapWarpTransition());
    },
  );

  testWidgets(
    'shared runtime preview animates and replays without map mutation',
    (tester) async {
      final document = _document(_map());
      final before = document.current;
      var replay = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, refresh) => Column(
              children: [
                Expanded(
                  child: MapWarpTransitionPreview(
                    key: ValueKey(replay),
                    transition: const MapWarpTransition(
                      type: MapWarpTransitionType.hgss,
                      durationSeconds: .4,
                    ),
                    child: const SizedBox(),
                  ),
                ),
                TextButton(
                  onPressed: () => refresh(() => replay++),
                  child: const Text('Rejouer'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final overlay = tester.widget<MapWarpTransitionOverlay>(
        find.byType(MapWarpTransitionOverlay),
      );
      expect(overlay.coverage, greaterThan(0));
      expect(overlay.coverage, lessThan(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rejouer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<MapWarpTransitionOverlay>(
              find.byType(MapWarpTransitionOverlay),
            )
            .coverage,
        greaterThan(0),
      );
      await tester.pumpWidget(const SizedBox());
      expect(document.current, before);
      expect(document.undoCount, 0);
    },
  );
}

EditableMapDocument _document(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
);

const _project = ProjectManifest(
  name: 'Transitions',
  tilesets: [],
  maps: [
    ProjectMapEntry(
      id: 'outside',
      name: 'Village',
      relativePath: 'outside.json',
    ),
    ProjectMapEntry(id: 'room', name: 'Maison', relativePath: 'room.json'),
  ],
);

MapData _map() => MapData(
  id: 'outside',
  name: 'Village',
  size: const GridSize(width: 8, height: 8),
  warps: const [
    MapWarp(
      id: 'house',
      pos: GridPos(x: 3, y: 3),
      targetMapId: 'room',
      targetPos: GridPos(x: 2, y: 2),
    ),
    MapWarp(
      id: 'stairs',
      pos: GridPos(x: 5, y: 3),
      targetMapId: 'room',
      targetPos: GridPos(x: 4, y: 4),
      transition: MapWarpTransition(
        type: MapWarpTransitionType.none,
        durationSeconds: .1,
      ),
    ),
  ],
);
