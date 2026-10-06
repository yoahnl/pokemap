import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';
import '../support/map_tool_menu.dart';

Finder get hint => find.textContaining('Faites glisser');

void main() {
  GridPos decorAt(MapHostFixture f, String id) =>
      f.document.current.placedElements.firstWhere((item) => item.id == id).pos;

  Map<String, GridPos> decors(MapHostFixture f) => {
    for (final item in f.document.current.placedElements) item.id: item.pos,
  };

  testWidgets(
    'Déplacer moves the chosen decor by the offset it was grabbed at',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final before = decors(f);
      final entities = f.document.current.entities;
      final steps = f.document.undoCount;

      await f.rightClick(5, 4);
      await f.choose('Déplacer');
      expect(hint, findsOneWidget);
      await f.drag(5, 5, 8, 7);

      expect(decorAt(f, 'jardin-arbre'), const GridPos(x: 8, y: 6));
      expect(
        {...decors(f)}..remove('jardin-arbre'),
        {...before}..remove('jardin-arbre'),
        reason: 'the neighbours stayed where they were',
      );
      expect(f.document.current.entities, entities);
      expect(f.document.undoCount, steps + 1, reason: 'one history entry');
      expect(hint, findsNothing, reason: 'the instruction is released');

      f.document.restore(redo: false);
      await pumpFrames(tester);
      expect(decorAt(f, 'jardin-arbre'), const GridPos(x: 5, y: 4));
      f.document.restore(redo: true);
      await pumpFrames(tester);
      expect(decorAt(f, 'jardin-arbre'), const GridPos(x: 8, y: 6));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'a move made through the menu is saved and read back independently',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      await f.rightClick(5, 4);
      await f.choose('Déplacer');
      await f.drag(5, 5, 8, 7);

      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      for (var i = 0; i < 60 && f.document.dirty; i++) {
        await pumpIo(tester, frames: 3);
      }
      expect(f.document.dirty, isFalse, reason: f.document.error);

      final reopened = (await tester.runAsync(() async {
        final adapter = LocalMapWorkspaceAdapter();
        final project = await adapter.loadProject(f.source.session);
        return adapter.loadMap(
          f.source.session,
          project.maps.firstWhere((entry) => entry.id == f.document.base.mapId),
        );
      }))!;
      expect(
        reopened.map.placedElements
            .firstWhere((item) => item.id == 'jardin-arbre')
            .pos,
        const GridPos(x: 8, y: 6),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets('a decor chosen under another one is the one that moves', (
    tester,
  ) async {
    final f = await MapHostFixture.open(tester);
    final crate = decorAt(f, 'jardin-caisse');

    await f.rightClick(12, 6);
    await tester.tap(f.inMenu('Rocher bleu · Décor'));
    await pumpFrames(tester);
    await f.choose('Déplacer');
    await f.drag(12, 6, 12, 9);

    expect(decorAt(f, 'jardin-rocher'), const GridPos(x: 11, y: 8));
    expect(decorAt(f, 'jardin-caisse'), crate);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('the move still lands on the right cell after a zoom', (
    tester,
  ) async {
    final f = await MapHostFixture.open(tester);
    final start = f.transform;
    await f.zoomAt(6, 5, -80);
    expect(f.transform, isNot(start), reason: 'the view really zoomed');

    await f.rightClick(5, 4);
    await f.choose('Déplacer');
    await f.drag(6, 4, 7, 5);

    expect(decorAt(f, 'jardin-arbre'), const GridPos(x: 6, y: 5));
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('zoom controls and centering preserve the scale below 100 %', (
    tester,
  ) async {
    final f = await MapHostFixture.open(tester);
    final initialScale = f.transform.entry(0, 0);
    await tester.tap(find.byKey(const ValueKey('Zoom arrière')));
    await pumpFrames(tester);

    final zoomedScale = initialScale * .8;
    expect(f.transform.entry(0, 0), closeTo(zoomedScale, .001));
    expect(find.text('${(zoomedScale * 100).round()} %'), findsOneWidget);

    final view = tester
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
        .view;
    view.centerCell(
      const GridPos(x: 6, y: 5),
      const Size(900, 600),
      const Size(32, 32),
    );
    await pumpFrames(tester);
    expect(f.transform.entry(0, 0), closeTo(zoomedScale, .001));
    expect(find.text('${(zoomedScale * 100).round()} %'), findsOneWidget);

    view.transform.value = Matrix4.identity()..scaleByDouble(.1, .1, 1, 1);
    await pumpFrames(tester);
    await tester.tap(find.byKey(const ValueKey('Zoom avant')));
    await pumpFrames(tester);
    expect(f.transform.entry(0, 0), closeTo(.125, .001));
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
    'placing and moving outside the map explain the refusal without losing history',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final before = f.document.current;
      final steps = f.document.undoCount;

      await tester.tap(find.byKey(const ValueKey('decor-arbre')));
      await pumpFrames(tester);
      await f.tapCell(23, 15);

      expect(f.document.current, before);
      expect(f.document.undoCount, steps);
      expect(f.document.error, contains('dépasse les limites'));
      expect(find.textContaining('dépasse les limites'), findsOneWidget);

      await f.tapCell(20, 10);
      expect(
        f.document.current.placedElements.length,
        before.placedElements.length + 1,
      );
      expect(f.document.error, isNull);
      final placed = f.document.current.placedElements.last;

      await f.rightClick(20, 10);
      await f.choose('Déplacer');
      await f.drag(20, 10, 23, 15);

      expect(f.document.current.placedElements.last.pos, placed.pos);
      expect(f.document.error, contains('dépasse les limites'));
      expect(f.document.undoCount, steps + 1);

      await f.drag(20, 10, 18, 9);
      expect(
        f.document.current.placedElements.last.pos,
        const GridPos(x: 18, y: 9),
      );
      expect(f.document.error, isNull);
      expect(f.document.undoCount, steps + 2);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets('Escape during the preview cancels the move without a mutation', (
    tester,
  ) async {
    final f = await MapHostFixture.open(tester);
    final before = f.document.current;
    final steps = f.document.undoCount;

    await f.rightClick(5, 4);
    await f.choose('Déplacer');
    final gesture = await f.press(5, 5);
    await gesture.moveTo(f.cellAt(8, 7));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFrames(tester);
    await gesture.up();
    await pumpFrames(tester);

    expect(f.document.current, before);
    expect(f.document.undoCount, steps);
    expect(hint, findsNothing);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
    'Escape during an armed story zone preview leaves the zone in place',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      MapRect quai() => f.document.current.triggers
          .firstWhere((trigger) => trigger.id == 'quai')
          .area;
      final area = quai();
      final steps = f.document.undoCount;

      await f.rightClick(11, 9);
      await f.choose('Déplacer');
      final gesture = await f.press(11, 9);
      await gesture.moveTo(f.cellAt(15, 12));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpFrames(tester);
      await gesture.up();
      await pumpFrames(tester);

      expect(quai(), area);
      expect(f.document.undoCount, steps);
      expect(hint, findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'choosing another tool releases the armed move and its instruction',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final tree = decorAt(f, 'jardin-arbre');
      await f.rightClick(5, 4);
      await f.choose('Déplacer');
      expect(hint, findsOneWidget);

      await chooseMapExtraTool(tester, 'Dessiner une zone de jeu');
      await pumpFrames(tester);
      expect(hint, findsNothing, reason: 'the instruction no longer applies');
      await tester.tap(find.byKey(const ValueKey('Sélectionner')));
      await pumpFrames(tester);
      await f.drag(13, 7, 13, 9);

      expect(decorAt(f, 'jardin-arbre'), tree);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'an armed move never comes back after a round trip to another map',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      await f.rightClick(5, 4);
      await f.choose('Déplacer');
      await f.switchMap('Clairière');
      await f.switchMap('Jardin des essais');
      expect(hint, findsNothing);

      final tree = decorAt(f, 'jardin-arbre');
      await f.drag(13, 7, 13, 9);
      expect(
        decorAt(f, 'jardin-arbre'),
        tree,
        reason: 'the stale target was released, not moved from afar',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
