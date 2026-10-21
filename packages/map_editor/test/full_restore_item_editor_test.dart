import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/items/item_effect_editor.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final context in ProjectItemUseContext.values) {
    testWidgets('Full Restore is guided and typed for $context', (
      tester,
    ) async {
      var definition = ProjectItemDefinition(
        id: 'medicine',
        displayName: 'Soin',
        pocketId: 'medicine',
        uses: [
          ProjectItemUseDefinition(
            contexts: {context},
            target: ProjectItemTargetKind.partyMove,
            consumption: ProjectItemConsumptionPolicy.never,
            effect: const ProjectItemEffectDefinition.restorePp(
              mode: ProjectItemAmountMode.full,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => ItemEffectEditor(
                  definition: definition,
                  onChanged: (value) => setState(() => definition = value),
                ),
              ),
            ),
          ),
        ),
      );
      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(Key('item-effect-${context.name}-effect-dropdown')),
      );
      final option = picker.items.singleWhere(
        (o) => (jsonDecode(o.value) as Map)['kind'] == 'full_restore',
      );
      expect(option.label, 'Soin Total');
      picker.onChanged(option.value);
      await tester.pump();
      final use = definition.uses.single;
      expect(use.effect, const ProjectItemEffectDefinition.fullRestore());
      expect(use.target, ProjectItemTargetKind.partyMember);
      expect(use.consumption, ProjectItemConsumptionPolicy.onApplied);
      expect(
        validateProjectItemCatalog(
          ProjectItemCatalog(schemaVersion: 1, entries: [definition]),
          capabilityTruth: itemSystemV1CapabilityTruth,
        ).hasBlockingDiagnostics,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
