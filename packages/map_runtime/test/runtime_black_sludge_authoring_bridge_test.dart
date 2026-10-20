import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';

void main() {
  test(
    'authored Black Sludge remains executable through a custom item identity',
    () {
      const catalog = ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'koga-held-sludge',
            displayName: 'Boue Noire',
            pocketId: 'items',
            heldEffectId: 'black_sludge',
          ),
        ],
      );
      expect(
        validateProjectItemCatalog(
          catalog,
          capabilityTruth: itemSystemV1CapabilityTruth,
        ).hasBlockingDiagnostics,
        isFalse,
        reason: 'The executable native effect must be authorable for the HGSS Koga team',
      );
      final resolution = resolveRuntimeHeldItemEffect(
        itemCatalog: ItemCatalogSnapshot.fromCatalog(catalog),
        itemId: 'koga-held-sludge',
      );
      expect(resolution.status, RuntimeHeldItemSupportStatus.supported);
      expect(resolution.heldEffectId, 'black_sludge');
      expect(
        ItemEffectRegistry().supportsHeldEffect(resolution.heldEffectId!),
        isTrue,
      );
    },
  );

  test(
    'an unknown sludge effect is still refused rather than treated as passive',
    () {
      const catalog = ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'unknown-sludge',
            displayName: 'Unknown Sludge',
            pocketId: 'items',
            heldEffectId: 'future_sludge',
          ),
        ],
      );
      expect(
        validateProjectItemCatalog(
          catalog,
          capabilityTruth: itemSystemV1CapabilityTruth,
        ).hasBlockingDiagnostics,
        isTrue,
      );
      final resolution = resolveRuntimeHeldItemEffect(
        itemCatalog: ItemCatalogSnapshot.fromCatalog(catalog),
        itemId: 'unknown-sludge',
      );
      expect(resolution.status, RuntimeHeldItemSupportStatus.unsupported);
    },
  );
}
