import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'gift inspector edits guided native payload and shows the three real routes',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gift = SceneInteractiveCommand.receivePokemonFromCatalog(
        speciesId: 'bird',
        formId: 'bronze',
        level: 17,
        nicknamePolicy: ScenePokemonGiftNicknamePolicy.disabled,
        nicknameMaxGraphemes: 10,
        pokedexPresentationPolicy:
            ScenePokemonGiftPokedexPresentationPolicy.whenNewAndPokedexVisible,
      );
      SceneInteractiveCommand? submitted;
      String? updatedNodeId;
      final node = SceneNode(
        id: 'gift',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(gift),
      );
      final graph = SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          node,
        ],
      );
      final scene = SceneAsset(id: 'gift-scene', name: 'Gift', graph: graph);
      final summary = NarrativeSceneSummary(
        id: scene.id,
        name: scene.name,
        nodeCount: 1,
        edgeCount: 0,
        declaredOutcomeCount: 0,
        declaredOutcomes: [],
        tags: [],
        graph: graph,
        layout: scene.layout,
        diagnostics: diagnoseScene(scene),
        outcomeDefinitions: [],
      );
      const species = SceneConsequenceCatalogSection(
        status: SceneConsequenceCatalogStatus.ready,
        message: '',
        options: [
          SceneConsequenceCatalogOption(
            id: 'bird',
            label: 'Bird',
            primaryFormId: 'bronze',
            formIds: ['sunny', 'bronze'],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: SceneNodeReadOnlyInspector(
                  scene: summary,
                  selectedNodeId: 'gift',
                  consequenceCatalogs: const SceneConsequenceCatalogs(
                    items: SceneConsequenceCatalogSection.loading(),
                    species: species,
                  ),
                  onUpdateInteractiveCommand:
                      ({required nodeId, required command}) async {
                        updatedNodeId = nodeId;
                        submitted = command;
                        return true;
                      },
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(SceneActionBuilder), findsOneWidget);
      expect(find.text('party / pc / noCapacity'), findsWidgets);
      expect(find.text('Aucune conséquence typée.'), findsNothing);
      final policy = tester.widget<PokeMapDropdownField<String>>(
        find.byWidgetPredicate(
          (w) =>
              w is PokeMapDropdownField<String> &&
              w.label == 'Proposer un surnom',
        ),
      );
      expect(policy.value, 'disabled');
      policy.onChanged('offer');
      await tester.pump();
      final submit = find.byKey(const ValueKey('scene-action-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(updatedNodeId, 'gift');
      expect(
        (submitted as SceneReceivePokemonFromCatalogInteractiveCommand)
            .nicknamePolicy,
        ScenePokemonGiftNicknamePolicy.offer,
      );
      expect(submitted!.toJson()['level'], 17);
    },
  );
}
