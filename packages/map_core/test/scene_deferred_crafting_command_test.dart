import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final definition = DeferredCraftingDefinition(
    serviceId: 'artisan',
    label: 'Atelier',
    recipes: [
      DeferredCraftingRecipe(
        recipeId: 'red',
        label: 'Balle rouge',
        inputItemId: 'fruit',
        inputQuantity: 2,
        outputItemId: 'ball',
        outputQuantity: 1,
      ),
    ],
  );
  test(
    'crafting command round trips inline recipes and stable service identity',
    () {
      final wire = {'kind': 'openCrafting', 'definition': definition.toJson()};
      final command = SceneInteractiveCommand.fromJson(wire);
      expect(command.toJson(), wire);
      expect(command.outputPortIds, ['completed', 'cancelled']);
      expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
      expect(
        diagnoseInteractiveCommand(
          command: command,
          project: const ProjectManifest(
            name: 'Crafting',
            maps: [],
            tilesets: [],
          ),
        ),
        isEmpty,
      );
    },
  );
  test(
    'crafting rejects unknown command fields and malformed recipe definitions',
    () {
      expect(
        () => SceneInteractiveCommand.fromJson({
          'kind': 'openCrafting',
          'definition': definition.toJson(),
          'unknown': true,
        }),
        throwsFormatException,
      );
      expect(
        () => SceneInteractiveCommand.fromJson({
          'kind': 'openCrafting',
          'definition': {...definition.toJson(), 'recipes': []},
        }),
        throwsFormatException,
      );
    },
  );
}
