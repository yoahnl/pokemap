import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/items/item_effect_editor.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('battle PP presets select an attack target and remain valid', (
    tester,
  ) async {
    var definition = const ProjectItemDefinition(
      id: 'custom-pp-tool',
      displayName: 'Recharge',
      pocketId: 'medicine',
      uses: [
        ProjectItemUseDefinition(
          contexts: {ProjectItemUseContext.battle},
          target: ProjectItemTargetKind.partyMember,
          consumption: ProjectItemConsumptionPolicy.onApplied,
          effect: ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: 20,
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

    PokeMapDropdownField<String> picker() => tester.widget(
      find.byKey(const Key('item-effect-battle-effect-dropdown')),
    );
    final ppChoices = picker().items
        .where(
          (entry) => (jsonDecode(entry.value) as Map)['kind'] == 'restore_pp',
        )
        .toList();
    expect(ppChoices, hasLength(2));
    for (final choice in ppChoices) {
      picker().onChanged(choice.value);
      await tester.pump();
      final use = definition.uses.single;
      expect(use.target, ProjectItemTargetKind.partyMove);
      expect(use.effect.toJson(), jsonDecode(choice.value));
      expect(use.contexts, {ProjectItemUseContext.battle});
      expect(use.consumption, ProjectItemConsumptionPolicy.onApplied);
      expect(
        validateProjectItemCatalog(
          ProjectItemCatalog(schemaVersion: 1, entries: [definition]),
          capabilityTruth: itemSystemV1CapabilityTruth,
        ).hasBlockingDiagnostics,
        isFalse,
      );
    }
    final hp = picker().items.firstWhere(
      (entry) => (jsonDecode(entry.value) as Map)['kind'] == 'heal_hp',
    );
    picker().onChanged(hp.value);
    await tester.pump();
    expect(definition.uses.single.target, ProjectItemTargetKind.partyMember);
    expect(tester.takeException(), isNull);
  });
}
