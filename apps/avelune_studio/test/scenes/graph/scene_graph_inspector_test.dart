import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../../game_memory/game_memory_fakes.dart';
import '../../presentation/story_memory_harness.dart';
import '../steps/scene_step_fixtures.dart';

final _project = memoryProject.copyWith(
  facts: [memoryFact('met', 'Rencontre'), memoryFact('seen', 'Vu le phare')],
);

SceneAsset _scene(List<SceneNode> nodes, List<SceneEdge> edges) =>
    SceneAsset(id: 'scene', name: 'Scene', graph: graphOf(nodes, edges));

final _sound = _scene(
  [startNode(), factNode('remember'), endNode('end')],
  [link('start', 'remember'), link('remember', 'end')],
);

Future<void> _pump(
  WidgetTester tester, {
  required SceneAsset scene,
  Set<String> selection = const {},
  bool editable = true,
  ValueChanged<SceneNode>? onEdit,
  ValueChanged<String>? onShow,
}) => tester.pumpWidget(
  MaterialApp(
    theme: studioTheme(),
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SceneGraphInspector(
          scene: scene,
          project: _project,
          map: null,
          selection: selection,
          checks: checkSceneGraph(scene),
          editable: editable,
          onEdit: onEdit ?? (_) {},
          onShow: onShow ?? (_) {},
        ),
      ),
    ),
  ),
);

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('with nothing selected it lists the problems and shows the '
      'step of the one clicked', (tester) async {
    final shown = <String>[];
    final scene = _scene(
      [startNode(), waitNode('alone'), endNode('end')],
      [link('start', 'end'), link('alone', 'end')],
    );

    await _pump(tester, scene: scene, onShow: shown.add);

    expect(_key('scene-graph-checks'), findsOneWidget);
    expect(
      find.text('Cette étape n’est jamais atteinte depuis le début.'),
      findsOneWidget,
    );
    await tester.tap(
      find.text('Cette étape n’est jamais atteinte depuis le début.'),
    );
    expect(shown, ['alone']);
  });

  testWidgets('a sound scene says it has no problem', (tester) async {
    await _pump(tester, scene: _sound);

    expect(find.text('Aucun problème dans cette scène.'), findsOneWidget);
  });

  testWidgets('one selected step shows its settings and edits it', (
    tester,
  ) async {
    final edits = <SceneNode>[];

    await _pump(
      tester,
      scene: _sound,
      selection: {'remember'},
      onEdit: edits.add,
    );

    expect(_key('scene-graph-inspector-remember'), findsOneWidget);
    expect(_key('scene-graph-checks'), findsNothing);
    tester.widget<StudioSelect>(_key('story-step-fact-remember')).onChanged!(
      'seen',
    );
    final payload = edits.single.payload as SceneActionPayload;
    expect((payload.consequence as SceneSetFactConsequence).factId, 'seen');
  });

  testWidgets('read-only settings cannot be changed; several steps are '
      'only counted', (tester) async {
    await _pump(
      tester,
      scene: _sound,
      selection: {'remember'},
      editable: false,
    );
    expect(
      tester.widget<StudioSelect>(_key('story-step-fact-remember')).onChanged,
      isNull,
    );

    await _pump(tester, scene: _sound, selection: {'remember', 'end'});
    expect(find.text('2 étapes sélectionnées'), findsOneWidget);
  });

  testWidgets('no reachable end blocks saving and reads differently from '
      'an end that is never reached', (tester) async {
    await _pump(
      tester,
      scene: _scene(
        [startNode(), waitNode('wait'), endNode('end')],
        [link('start', 'wait')],
      ),
    );

    expect(
      find.text('Aucune fin n’est atteignable depuis le début.'),
      findsOneWidget,
    );
    expect(find.text('Cette fin n’est jamais atteinte.'), findsOneWidget);
    expect(find.text('Bloque l’enregistrement'), findsOneWidget);
  });
}
