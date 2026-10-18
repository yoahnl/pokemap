import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final project = ProjectManifest(
    name: 'Action fixture',
    maps: const [],
    tilesets: const [],
    facts: [NarrativeFactDefinition(id: 'departure', label: 'Départ autorisé')],
  );

  Future<void> pump(
    WidgetTester tester, {
    SceneNodePayload? current,
    ProjectManifest? projectOverride,
    Future<Map<String, String>> Function()? loadMoves,
    required ValueChanged<SceneNodePayload> onApply,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: SingleChildScrollView(child: SceneActionForm(
            project: projectOverride ?? project,
            current: current,
            loadSpecies: _loadGiftSpecies,
            loadMoves: loadMoves ?? _loadGiftMoves,
            onApply: onApply,
          )),
        ),
      ),
    ),
  );

  testWidgets('action edits preserve opaque metadata until explicit apply', (
    tester,
  ) async {
    final original = SceneActionPayload.consequence(
      SceneConsequence.setFact(factId: 'departure', value: true),
      actionKind: 'author-label',
      parameters: const {'annotation': 'keep'},
    );
    final applied = <SceneNodePayload>[];
    await pump(tester, current: original, onApply: applied.add);
    expect(find.text('Départ autorisé'), findsOneWidget);
    expect(applied, isEmpty);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(applied, isEmpty);
    expect(
      original.consequence,
      SceneConsequence.setFact(factId: 'departure', value: true),
    );
    await tester.tap(find.text('Appliquer l’action'));
    final result = applied.single as SceneActionPayload;
    expect(result.parameters, original.parameters);
    expect(result.actionKind, original.actionKind);
    expect(
      result.consequence,
      SceneConsequence.setFact(factId: 'departure', value: false),
    );
  });

  testWidgets('catalog gifts keep imposed move references visible', (tester) async {
    final original = SceneActionPayload.consequence(SceneConsequence.givePokemonFromCatalog(
      speciesId: 'bird', formId: 'base', level: 8, moveIds: ['removed', 'tackle']));
    await pump(tester, current: original, onApply: (_) => fail('Missing references must block application'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scene-gift-move-mode')), findsOneWidget);
    expect(find.textContaining('removed'), findsWidgets);
    expect(tester.widget<StudioButton>(find.byWidgetPredicate((widget) => widget is StudioButton && widget.label == 'Appliquer l’action')).onPressed, isNull);
  });

  for (final interactive in [false, true]) {
    testWidgets('${interactive ? 'interactive' : 'consequence'} gifts guide creation and ordered moves', (tester) async {
      SceneNodePayload? submitted;
      await pump(tester, onApply: (value) => submitted = value);
      tester.widget<StudioSelect>(find.byWidgetPredicate((widget) => widget is StudioSelect && widget.label == 'Commande')).onChanged!(interactive ? 'receivePokemonFromCatalog' : 'givePokemonFromCatalog');
      await tester.pumpAndSettle();
      tester.widget<StudioSelect>(find.byWidgetPredicate((widget) => widget is StudioSelect && widget.label == 'Espèce')).onChanged!('bird');
      await tester.pump();
      expect(tester.widget<StudioSelect>(find.byWidgetPredicate((widget) => widget is StudioSelect && widget.label == 'Forme')).options.keys, ['base']);
      tester.widget<StudioSelect>(find.byKey(const ValueKey('scene-gift-move-mode'))).onChanged!('explicit');
      await tester.pumpAndSettle();
      tester.widget<StudioSelect>(find.byKey(const ValueKey('scene-gift-move-0'))).onChanged!('exceptional');
      await tester.pump();
      tester.widget<StudioButton>(find.byKey(const ValueKey('scene-gift-move-add'))).onPressed!();
      await tester.pump();
      tester.widget<StudioSelect>(find.byKey(const ValueKey('scene-gift-move-1'))).onChanged!('tackle');
      await tester.pump();
      tester.widget<StudioButton>(find.byKey(const ValueKey('scene-gift-move-down-0'))).onPressed!();
      await tester.pump();
      final apply = find.byWidgetPredicate((widget) => widget is StudioButton && widget.label == 'Ajouter l’action');
      tester.widget<StudioButton>(apply).onPressed!();
      final payload = submitted! as SceneActionPayload;
      expect((payload.consequence?.toJson() ?? payload.interactiveCommand!.toJson())['moveIds'], ['tackle', 'exceptional']);
      expect(submitted, isNotNull);
    });
  }

  testWidgets('gift moves reload when project changes with the same loader callback', (tester) async {
    var catalogue = {'tackle': 'Charge'};
    var loads = 0;
    Future<Map<String, String>> loader() async { loads++; return catalogue; }
    final original = SceneActionPayload.consequence(SceneConsequence.givePokemonFromCatalog(speciesId: 'bird', formId: 'base', level: 8, moveIds: ['tackle']));
    await pump(tester, current: original, loadMoves: loader, onApply: (_) {});
    await tester.pumpAndSettle();
    final apply = find.byWidgetPredicate((widget) => widget is StudioButton && widget.label == 'Appliquer l’action');
    expect(tester.widget<StudioButton>(apply).onPressed, isNotNull);
    catalogue = {'surf': 'Surf'};
    await pump(tester, current: original, loadMoves: loader, projectOverride: const ProjectManifest(name: 'Other project', maps: [], tilesets: []), onApply: (_) {});
    await tester.pumpAndSettle();
    expect(tester.widget<StudioButton>(apply).onPressed, isNull);
    final picker = tester.widget<StudioSelect>(find.byKey(const ValueKey('scene-gift-move-0')));
    expect(picker.value, 'tackle');
    expect(picker.options['tackle'], contains('introuvable'));
    expect(loads, 2);
  });

  testWidgets('gift moves keep their catalogue for equal manifest projections', (tester) async {
    var loads = 0;
    Future<Map<String, String>> loader() async { loads++; return {'tackle': 'Charge'}; }
    final original = SceneActionPayload.consequence(SceneConsequence.givePokemonFromCatalog(speciesId: 'bird', formId: 'base', level: 8, moveIds: ['tackle']));
    await pump(tester, current: original, loadMoves: loader, onApply: (_) {});
    await tester.pumpAndSettle();
    expect(loads, 1);
    await pump(tester, current: original, loadMoves: loader, projectOverride: project.copyWith(), onApply: (_) {});
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing references remain explicit and cannot apply', (
    tester,
  ) async {
    final original = SceneActionPayload.consequence(
      SceneConsequence.setFact(factId: 'removed', value: true),
    );
    var applied = false;
    await pump(tester, current: original, onApply: (_) => applied = true);
    expect(
      find.textContaining('Référence introuvable : removed'),
      findsOneWidget,
    );
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNull,
    );
    expect(applied, isFalse);
  });

  testWidgets('unsupported payload is retained until explicit replacement', (
    tester,
  ) async {
    final original = SceneActionPayload(
      actionKind: 'custom-untouched',
      parameters: const {'private': 'value'},
    );
    final applied = <SceneNodePayload>[];
    await pump(tester, current: original, onApply: applied.add);
    expect(find.textContaining('paramètres avancés'), findsOneWidget);
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Donner de l’argent').last);
    await tester.pumpAndSettle();
    expect(applied, isEmpty);
    await tester.enterText(find.byType(TextField), 'invalide');
    await tester.pump();
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '42');
    await tester.pump();
    await tester.tap(find.text('Appliquer l’action'));
    expect(
      (applied.single as SceneActionPayload).consequence,
      SceneConsequence.giveMoney(amount: 42),
    );
    expect(original.parameters, const {'private': 'value'});
  });
}

Future<Map<String, String>> _loadGiftMoves() async => {'exceptional': 'Capacité exceptionnelle', 'tackle': 'Charge', 'surf': 'Surf', 'fly': 'Vol'};

Future<List<PokemonSpeciesSummary>> _loadGiftSpecies() async => const [PokemonSpeciesSummary(
  id: 'bird', name: 'Oiseau', nationalDex: 1, generation: 1, types: ['normal'], formIds: ['base', 'sunny'], baseFormId: 'base', mediaRelativePath: '', enabled: true, relativePath: 'bird.json')];
