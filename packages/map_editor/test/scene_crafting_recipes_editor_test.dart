import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_crafting_recipes_editor.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'canonical action builder reopens recipes and preserves service identity',
    (tester) async {
      final definition = DeferredCraftingDefinition(
        serviceId: 'artisan-stable',
        label: 'Artisan',
        recipes: [
          DeferredCraftingRecipe(
            recipeId: 'red-ball',
            label: 'Balle rouge',
            inputItemId: 'fruit',
            inputQuantity: 2,
            outputItemId: 'ball',
            outputQuantity: 1,
          ),
        ],
      );
      SceneNodePayload? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionBuilder(
                initialPayload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.openCrafting(definition: definition),
                ),
                project: const ProjectManifest(
                  name: 'Craft',
                  maps: [],
                  tilesets: [],
                ),
                pickerOptions: const {
                  NarrativeCommandParameterKind.item: [
                    SceneActionPickerOption(id: 'fruit', label: 'Fruit rouge'),
                    SceneActionPickerOption(id: 'ball', label: 'Balle'),
                  ],
                },
                onSubmit: (value) => result = value,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final button = find.byKey(const ValueKey('scene-action-submit'));
      expect(tester.widget<PokeMapButton>(button).onPressed, isNotNull);
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(
        ((result as SceneActionPayload).interactiveCommand
                as SceneOpenCraftingInteractiveCommand)
            .definition,
        definition,
      );
    },
  );
  testWidgets(
    'recipe rows use catalog pickers and preserve stable identities',
    (tester) async {
      var recipes = <Map<String, dynamic>>[
        {
          'recipeId': 'red-ball',
          'label': 'Balle rouge',
          'inputItemId': 'fruit',
          'inputQuantity': 2,
          'outputItemId': 'ball',
          'outputQuantity': 1,
        },
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => SceneCraftingRecipesEditor(
                  value: recipes,
                  items: const {'fruit': 'Fruit rouge', 'ball': 'Balle'},
                  onChanged: (next) => setState(() => recipes = next),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(PokeMapDropdownField<String>), findsNWidgets(2));
      await tester.enterText(
        find.byKey(const ValueKey('crafting-recipe-0-label')),
        'Balle améliorée',
      );
      expect(recipes.single['recipeId'], 'red-ball');
      expect(recipes.single['label'], 'Balle améliorée');
      await tester.ensureVisible(
        find.byKey(const ValueKey('crafting-recipe-add')),
      );
      await tester.tap(find.byKey(const ValueKey('crafting-recipe-add')));
      await tester.pump();
      expect(recipes, hasLength(2));
      expect(recipes.map((recipe) => recipe['recipeId']).toSet(), hasLength(2));
    },
  );
}
