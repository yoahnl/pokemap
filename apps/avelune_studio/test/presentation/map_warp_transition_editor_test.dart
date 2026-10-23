import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_warp_inspector.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show MapWarpTransitionPreview, MapWarpTransitionOverlay;

void main() {
  Future<_Harness> pump(WidgetTester tester, {MapData? source}) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = source ?? _map();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
    );
    var selected = map.warps.first.id;
    late StateSetter refresh;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, rebuild) {
                  refresh = rebuild;
                  return MapWarpInspector(
                    document: document,
                    project: _project,
                    warp: document.current.warps.singleWhere(
                      (warp) => warp.id == selected,
                    ),
                    onChanged: () => rebuild(() {}),
                    onDeleted: () {},
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    return _Harness(
      document,
      () => refresh(() {}),
      (id) => refresh(() => selected = id),
    );
  }

  Finder select() => find.byWidgetPredicate(
    (widget) => widget is StudioSelect && widget.label == 'Transition d’écran',
  );
  Finder duration() => find.descendant(
    of: find.byKey(const ValueKey('warp-transition-duration')),
    matching: find.byType(TextField),
  );
  StudioButton button(WidgetTester tester, String key) =>
      tester.widget<StudioButton>(find.byKey(ValueKey(key)));
  Future<void> pick(WidgetTester tester, String value) async {
    await tester.ensureVisible(select());
    await tester.tap(
      find.descendant(
        of: select(),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.ensureVisible(
      find.byKey(const ValueKey('apply-warp-transition')),
    );
    await tester.tap(find.byKey(const ValueKey('apply-warp-transition')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'an active Studio passage offers its screen transition independently of a 3D door',
    (tester) async {
      await pump(tester);
      expect(find.text('Transition d’écran'), findsOneWidget);
      expect(find.text('Fondu noir'), findsOneWidget);
      expect(find.text('Porte animée'), findsNothing);
      expect(tester.widget<TextField>(duration()).controller!.text, '200');
      expect(button(tester, 'apply-warp-transition').onPressed, isNull);
    },
  );

  testWidgets(
    'HGSS type and duration commit atomically through the shared warp operation',
    (tester) async {
      final harness = await pump(tester);
      final original = harness.document.current;
      await pick(tester, 'Obturateur (style HGSS)');
      await tester.enterText(duration(), '350');
      await tester.pump();
      expect(harness.document.current, original);
      await apply(tester);
      expect(
        harness.document.current.warps.first.transition,
        const MapWarpTransition(
          type: MapWarpTransitionType.hgss,
          durationSeconds: .35,
        ),
      );
      expect(
        harness.document.current.warps.first.targetMapId,
        original.warps.first.targetMapId,
      );
      expect(
        harness.document.current.warps.first.targetPos,
        original.warps.first.targetPos,
      );
      expect(harness.document.current.layers, original.layers);
      expect(harness.document.undoCount, 1);
      harness.document.restore(redo: false);
      harness.refresh();
      await tester.pump();
      expect(harness.document.current, original);
      expect(find.text('Fondu noir'), findsOneWidget);
      harness.document.restore(redo: true);
      harness.refresh();
      await tester.pump();
      expect(find.text('Obturateur (style HGSS)'), findsOneWidget);
      expect(tester.widget<TextField>(duration()).controller!.text, '350');
    },
  );

  testWidgets(
    'none is a persisted choice with the canonical duration preserved',
    (tester) async {
      final harness = await pump(tester);
      await pick(tester, 'Aucune');
      await apply(tester);
      expect(
        harness.document.current.warps.first.transition,
        const MapWarpTransition(type: MapWarpTransitionType.none),
      );
      final restored = MapData.fromJson(
        jsonDecode(jsonEncode(harness.document.current.toJson())),
      );
      expect(restored.warps.first.transition.type, MapWarpTransitionType.none);
      expect(restored.warps.first.transition.durationSeconds, .2);
    },
  );

  testWidgets(
    'invalid durations cannot apply or preview and never change history',
    (tester) async {
      final harness = await pump(tester);
      final before = harness.document.current;
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
        await tester.enterText(duration(), value);
        await tester.pump();
        expect(
          button(tester, 'apply-warp-transition').onPressed,
          isNull,
          reason: value,
        );
        expect(
          button(tester, 'preview-warp-transition').onPressed,
          isNull,
          reason: value,
        );
        expect(
          find.text('Indiquez un nombre entier de 1 à 5 000 ms.'),
          findsOneWidget,
        );
      }
      expect(harness.document.current, before);
      expect(harness.document.undoCount, 0);
    },
  );

  testWidgets('one and five thousand milliseconds remain available', (
    tester,
  ) async {
    final harness = await pump(tester);
    for (final value in [1, 5000]) {
      await tester.enterText(duration(), '$value');
      await tester.pump();
      await apply(tester);
      expect(
        harness.document.current.warps.first.transition.durationSeconds,
        value / 1000,
      );
    }
  });

  testWidgets(
    'retargeting keeps transition settings and a pending transition never overwrites the target',
    (tester) async {
      final harness = await pump(tester);
      await pick(tester, 'Obturateur (style HGSS)');
      final commands = WarpEditingCommands(harness.document, _project);
      commands.retarget('house', targetPos: const GridPos(x: 4, y: 5));
      harness.refresh();
      await tester.pump();
      await apply(tester);
      final warp = harness.document.current.warps.first;
      expect(warp.targetPos, const GridPos(x: 4, y: 5));
      expect(warp.transition.type, MapWarpTransitionType.hgss);
      commands.retarget('house', triggerMode: MapWarpTriggerMode.onBump);
      expect(harness.document.current.warps.first.transition, warp.transition);
    },
  );

  testWidgets('switching the selected passage discards the other local draft', (
    tester,
  ) async {
    final harness = await pump(tester);
    await pick(tester, 'Obturateur (style HGSS)');
    await tester.enterText(duration(), '900');
    harness.select('stairs');
    await tester.pump();
    expect(find.text('Aucune'), findsOneWidget);
    expect(tester.widget<TextField>(duration()).controller!.text, '100');
    expect(button(tester, 'apply-warp-transition').onPressed, isNull);
    expect(harness.document.undoCount, 0);
  });

  testWidgets(
    'reset stages fade and two hundred milliseconds until explicitly applied',
    (tester) async {
      final source = _map();
      final harness = await pump(
        tester,
        source: source.copyWith(
          warps: [
            source.warps.first.copyWith(
              transition: const MapWarpTransition(
                type: MapWarpTransitionType.hgss,
                durationSeconds: .7,
              ),
            ),
          ],
        ),
      );
      await tester.ensureVisible(find.byTooltip('Valeurs par défaut'));
      await tester.tap(find.byTooltip('Valeurs par défaut'));
      await tester.pump();
      expect(
        harness.document.current.warps.single.transition.type,
        MapWarpTransitionType.hgss,
      );
      expect(find.text('Fondu noir'), findsOneWidget);
      expect(tester.widget<TextField>(duration()).controller!.text, '200');
      await apply(tester);
      expect(
        harness.document.current.warps.single.transition,
        const MapWarpTransition(),
      );
    },
  );

  testWidgets(
    'opening a rounded imported duration never mutates its precise value',
    (tester) async {
      final source = _map();
      final transition = const MapWarpTransition(durationSeconds: .0254);
      final harness = await pump(
        tester,
        source: source.copyWith(
          warps: [source.warps.first.copyWith(transition: transition)],
        ),
      );
      expect(tester.widget<TextField>(duration()).controller!.text, '25');
      expect(button(tester, 'apply-warp-transition').onPressed, isNull);
      expect(harness.document.current.warps.single.transition, transition);
      expect(harness.document.dirty, isFalse);
    },
  );

  testWidgets(
    'passive arrival points do not offer outgoing screen transitions',
    (tester) async {
      final source = _map();
      await pump(
        tester,
        source: source.copyWith(
          warps: [
            source.warps.first.copyWith(
              triggerMode: MapWarpTriggerMode.sceneOnly,
              targetMapId: source.id,
              targetPos: source.warps.first.pos,
            ),
          ],
        ),
      );
      expect(find.text('Transition d’écran'), findsNothing);
    },
  );

  testWidgets(
    'preview uses the shared animated runtime widget without mutating the map',
    (tester) async {
      final harness = await pump(tester);
      final before = jsonEncode(harness.document.current.toJson());
      await pick(tester, 'Obturateur (style HGSS)');
      await tester.enterText(duration(), '400');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('preview-warp-transition')),
      );
      await tester.tap(find.byKey(const ValueKey('preview-warp-transition')));
      await tester.pump();
      expect(find.byType(MapWarpTransitionPreview), findsOneWidget);
      expect(
        tester
            .widget<MapWarpTransitionPreview>(
              find.byType(MapWarpTransitionPreview),
            )
            .transition,
        const MapWarpTransition(
          type: MapWarpTransitionType.hgss,
          durationSeconds: .4,
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
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(find.byType(MapWarpTransitionPreview), findsNothing);
      expect(jsonEncode(harness.document.current.toJson()), before);
      expect(harness.document.undoCount, 0);
    },
  );
}

class _Harness {
  _Harness(this.document, this.refresh, this.select);
  final EditableMapDocument document;
  final VoidCallback refresh;
  final ValueChanged<String> select;
}

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
