import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  test('crafting requires an explicit capability only when a Scene uses it',
      () {
    const empty = ProjectManifest(name: 'Empty', maps: [], tilesets: []);
    expect(
        SpatialGameplayCapabilities.requiresDeferredCrafting(empty), isFalse);
    final definition = DeferredCraftingDefinition(
        serviceId: 'artisan',
        label: 'Artisan',
        recipes: [
          DeferredCraftingRecipe(
              recipeId: 'ball',
              label: 'Ball',
              inputItemId: 'fruit',
              inputQuantity: 1,
              outputItemId: 'ball',
              outputQuantity: 1)
        ]);
    final project = empty.copyWith(scenes: [
      SceneAsset(
          id: 'craft',
          name: 'Craft',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'craft',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.openCrafting(
                        definition: definition)))
          ]))
    ]);
    expect(
        SpatialGameplayCapabilities.requiresDeferredCrafting(project), isTrue);
  });
  test('host announces crafting with its owned durable Scene checkpoint', () {
    expect(AveluneRuntimeCompatibility.host().capabilities,
        contains(SpatialGameplayCapabilities.deferredCraftingCapabilityId));
  });
}
