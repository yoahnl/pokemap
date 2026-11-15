import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_card_tile.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_painters.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

final _scene = SceneAsset(
  id: 'scene',
  name: 'Scene',
  graph: graphOf(
    [
      startNode(),
      conditionNode('check'),
      battleNode('fight'),
      endNode('won'),
      endNode('lost'),
    ],
    [
      link('start', 'check'),
      link('check', 'fight', port: 'true'),
      link('check', 'lost', port: 'false'),
      SceneEdge(
        id: 'fight.victory',
        fromNodeId: 'fight',
        fromPortId: 'victory',
        toNodeId: 'won',
        kind: SceneEdgeKind.battleVictory,
      ),
      SceneEdge(
        id: 'fight.defeat',
        fromNodeId: 'fight',
        fromPortId: 'defeat',
        toNodeId: 'lost',
        kind: SceneEdgeKind.battleDefeat,
      ),
    ],
  ),
);

final _canvas = GlobalKey<SceneGraphCanvasState>();

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _pump(
  WidgetTester tester, {
  SceneAsset? scene,
  List<String> path = const [],
  Map<String, String> choices = const {},
  Map<String, String> dialogues = const {},
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SceneGraphCanvas(
          key: _canvas,
          scene: scene ?? _scene,
          project: null,
          pathNodeIds: path,
          pathChoices: choices,
          dialogueNames: dialogues,
        ),
      ),
    ),
  );
}

SceneGraphCardTile _tile(WidgetTester tester, String id) =>
    tester.widget<SceneGraphCardTile>(_key('scene-graph-card-$id'));

Future<void> _click(
  WidgetTester tester,
  Offset at, {
  int buttons = kPrimaryButton,
}) async {
  final gesture = await tester.startGesture(
    at,
    kind: PointerDeviceKind.mouse,
    buttons: buttons,
  );
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('every step is drawn with its exits and the scene fits on open', (
    tester,
  ) async {
    await _pump(tester);

    final canvas = tester.getRect(_key('scene-graph-canvas'));
    for (final id in ['start', 'check', 'fight', 'won', 'lost']) {
      final card = tester.getRect(_key('scene-graph-card-$id'));
      expect(canvas.contains(card.topLeft), isTrue, reason: id);
      expect(canvas.contains(card.bottomRight), isTrue, reason: id);
    }
    expect(_key('scene-graph-port-fight-victory'), findsOneWidget);
    expect(_key('scene-graph-port-fight-defeat'), findsOneWidget);
    expect(find.text('Victoire'), findsOneWidget);
    expect(find.text('Combat'), findsOneWidget);
    expect(_key('scene-graph-port-won-completed'), findsNothing);
    expect(find.text('100 %'), findsOneWidget);
  });

  testWidgets('click, Shift+click and a marquee select steps; a click in the '
      'void clears them', (tester) async {
    await _pump(tester);
    final state = _canvas.currentState!;
    Offset centre(String id) => tester.getCenter(_key('scene-graph-card-$id'));

    await _click(tester, centre('check'));
    expect(state.selection, {'check'});
    expect(_tile(tester, 'check').selected, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await _click(tester, centre('fight'));
    expect(state.selection, {'check', 'fight'});
    await _click(tester, centre('check'));
    expect(state.selection, {'fight'});
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

    final corner = tester.getRect(_key('scene-graph-canvas')).topLeft;
    await _click(tester, corner + const Offset(4, 4));
    expect(state.selection, isEmpty);
    expect(_tile(tester, 'fight').selected, isFalse);

    final marquee = await tester.startGesture(
      corner + const Offset(4, 4),
      kind: PointerDeviceKind.mouse,
    );
    await marquee.moveTo(centre('fight'));
    await tester.pump();
    expect(state.selection, {'start', 'check', 'fight'});
    await marquee.up();
    await tester.pump();
    expect(state.selection, {'start', 'check', 'fight'});
  });

  testWidgets('right-drag and two fingers move the view, the wheel and a '
      'pinch zoom around the pointer, Show all frames the scene again', (
    tester,
  ) async {
    await _pump(tester);
    final state = _canvas.currentState!;
    final fitted = state.camera!;
    final centre = tester.getCenter(_key('scene-graph-canvas'));

    final drag = await tester.startGesture(
      centre,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await drag.moveBy(const Offset(100, 50));
    await drag.up();
    await tester.pump();
    expect(state.camera!.pan, fitted.pan + const Offset(100, 50));
    expect(state.selection, isEmpty);

    final pointer = TestPointer(7, PointerDeviceKind.mouse);
    final under = state.camera!.toWorld(centre);
    tester.binding.handlePointerEvent(pointer.hover(centre));
    tester.binding.handlePointerEvent(pointer.scroll(const Offset(0, -80)));
    await tester.pump();
    expect(state.camera!.scale, greaterThan(fitted.scale));
    expect(state.camera!.toWorld(centre).dx, closeTo(under.dx, 1e-6));
    expect(find.text('${(state.camera!.scale * 100).round()} %'), findsOne);

    final trackpad = TestPointer(8, PointerDeviceKind.trackpad);
    final before = state.camera!;
    tester.binding.handlePointerEvent(trackpad.panZoomStart(centre));
    tester.binding.handlePointerEvent(
      trackpad.panZoomUpdate(centre, pan: const Offset(-30, 0), scale: 1.25),
    );
    tester.binding.handlePointerEvent(trackpad.panZoomEnd());
    await tester.pump();
    expect(state.camera!.scale, closeTo(before.scale * 1.25, 1e-6));
    expect(state.camera!.pan, isNot(before.pan));

    await tester.tap(_key('scene-graph-show-all'));
    await tester.pump();
    expect(state.camera, fitted);
  });

  testWidgets('the previewed path lights its steps and links', (tester) async {
    await _pump(tester, path: ['start', 'check', 'fight', 'won']);

    for (final id in ['start', 'check', 'fight', 'won']) {
      expect(_tile(tester, id).onPath, isTrue, reason: id);
    }
    expect(_tile(tester, 'lost').onPath, isFalse);
    final wires = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<SceneGraphWirePainter>()
        .single;
    expect(wires.pathEdgeIds, {
      'start.completed',
      'check.true',
      'fight.victory',
    });
  });

  testWidgets('only the chosen exit lights up when several exits reach the '
      'same step, and cards name their dialogue and action', (tester) async {
    SceneEdge give(String port) => SceneEdge(
      id: 'give.$port',
      fromNodeId: 'give',
      fromPortId: port,
      toNodeId: 'end',
      kind: SceneEdgeKind.actionCompleted,
    );
    final scene = SceneAsset(
      id: 'gift',
      name: 'Gift',
      graph: graphOf(
        [startNode(), dialogueNode('talk'), giveNode('give'), endNode('end')],
        [
          link('start', 'talk'),
          link('talk', 'give'),
          give('received'),
          give('bagFull'),
        ],
      ),
    );

    await _pump(
      tester,
      scene: scene,
      path: ['start', 'talk', 'give', 'end'],
      choices: {'give': 'bagFull'},
      dialogues: {'talk': 'Bonjour du professeur'},
    );

    final wires = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<SceneGraphWirePainter>()
        .single;
    expect(wires.pathEdgeIds, {
      'start.completed',
      'talk.completed',
      'give.bagFull',
    });
    expect(find.text('Bonjour du professeur'), findsOneWidget);
    expect(find.text('Sac plein'), findsOneWidget);
    expect(find.text('Introuvable'), findsNothing);
    expect(
      find.descendant(
        of: _key('scene-graph-card-give'),
        matching: find.text('Donner un objet'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'a required exit left unlinked is shown in the warning colour, as the engine rates it',
    (tester) async {
      final scene = SceneAsset(
        id: 'half',
        name: 'Half',
        graph: graphOf(
          [startNode(), conditionNode('check'), endNode('end')],
          [link('start', 'check'), link('check', 'end', port: 'true')],
        ),
      );
      await _pump(tester, scene: scene);

      Color? colour(String text) => tester
          .widget<Text>(
            find.descendant(
              of: _key('scene-graph-card-check'),
              matching: find.text(text),
            ),
          )
          .style
          ?.color;
      final warning = StudioColors.of(
        tester.element(_key('scene-graph-canvas')),
      ).warning;
      expect(colour('Sinon'), warning);
      expect(colour('Alors'), isNot(warning));
    },
  );
}
