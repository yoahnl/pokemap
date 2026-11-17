import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_outline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

void main() {
  testWidgets('scene search finds a step by its real shared dialogue name', (
    tester,
  ) async {
    final search = TextEditingController();
    final focus = FocusNode();
    addTearDown(search.dispose);
    addTearDown(focus.dispose);
    final shown = <String>[];
    final scene = SceneAsset(
      id: 'scene',
      name: 'Scène',
      graph: graphOf(
        [startNode(), dialogueNode('ask'), endNode('end')],
        [link('start', 'ask'), link('ask', 'end')],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 204,
            child: SceneGraphOutline(
              scene: scene,
              selection: const {'ask'},
              dialogues: {
                'talk': ProjectDialogueEntry(
                  id: 'talk',
                  name: 'Lettre du refuge',
                  relativePath: 'talk.yarn',
                ),
              },
              factNames: const {},
              search: search,
              searchFocus: focus,
              onShow: shown.add,
            ),
          ),
        ),
      ),
    );
    final field = find.byType(TextField);
    await tester.enterText(field, '  REFUGE ');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('scene-graph-outline-start')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('scene-graph-outline-end')), findsNothing);
    final result = find.byKey(const ValueKey('scene-graph-outline-ask'));
    expect(tester.widget<StudioChoice>(result).selected, isTrue);
    await tester.tap(result);
    expect(shown, ['ask']);
    expect(search.text, '  REFUGE ');
    await tester.enterText(field, 'inconnu');
    await tester.pumpAndSettle();
    expect(result, findsNothing);
    expect(find.text('Aucune étape ne correspond.'), findsOneWidget);
  });
}
