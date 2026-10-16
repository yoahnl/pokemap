import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('catalog rejects a consumable escape rope marked as key-item', () {
    final report = validateProjectItemCatalog(
      const ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'rope',
            displayName: 'Corde Sortie',
            pocketId: 'items',
            tags: {'key-item'},
            uses: [
              ProjectItemUseDefinition(
                contexts: {ProjectItemUseContext.overworld},
                target: ProjectItemTargetKind.world,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.escapeRope(),
              ),
            ],
          ),
        ],
      ),
      capabilityTruth: itemSystemV1CapabilityTruth,
    );
    expect(report.hasBlockingDiagnostics, isTrue);
    expect(
      report.diagnostics.any(
        (diagnostic) => diagnostic.message.contains('objet clé'),
      ),
      isTrue,
    );
  });

  test('Escape Rope has a typed effect without a semantic action registry', () {
    final effect = ProjectItemEffectDefinition.fromJson({
      'kind': 'escape_rope',
    });
    expect(effect.toJson(), {'kind': 'escape_rope'});
    expect(effect.requireDeclaredSemanticAction({}), effect);
  });

  test('escape anchor survives both save mappings and JSON', () {
    final json = const GameState(saveId: 'escape').toJson();
    json['escapeReturnPoint'] = {
      'dungeonId': 'cave',
      'mapId': 'outside',
      'position': {'x': 3, 'y': 5},
      'facing': 'west',
    };
    final state = GameState.fromJson(json);
    final saved = saveDataFromGameState(state);
    final restored = gameStateFromSaveData(SaveData.fromJson(saved.toJson()));
    expect(restored.toJson()['escapeReturnPoint'], json['escapeReturnPoint']);
    expect(GameState.fromJson(restored.toJson()), restored);
  });

  test('map dungeon identity is explicit and survives JSON', () {
    final metadata = MapMetadata.fromJson({
      'allowEscapeRope': false,
      'escapeRopeDungeonId': 'cave',
    });
    expect(metadata.toJson()['escapeRopeDungeonId'], 'cave');
    expect(metadata.allowEscapeRope, isFalse);
  });
}
