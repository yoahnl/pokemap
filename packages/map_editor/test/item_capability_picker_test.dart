import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/items/item_capability_picker.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final testCase in <(ItemCapabilityRequirement, String, List<String>)>[
    (
      ItemCapabilityRequirement.any,
      'potion',
      <String>['Potion', 'Poké Ball', 'CT Coupe', 'Restes'],
    ),
    (ItemCapabilityRequirement.overworld, 'potion', <String>['Potion']),
    (ItemCapabilityRequirement.battle, 'potion', <String>['Potion']),
    (ItemCapabilityRequirement.capture, 'poke-ball', <String>['Poké Ball']),
    (ItemCapabilityRequirement.machine, 'tm-cut', <String>['CT Coupe']),
    (ItemCapabilityRequirement.held, 'leftovers', <String>['Restes']),
  ]) {
    testWidgets('filters ${testCase.$1.name} from canonical capabilities', (
      tester,
    ) async {
      await _pumpPicker(tester, requirement: testCase.$1, value: testCase.$2);

      final dropdown = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const Key('capability-picker')),
      );
      final labels = dropdown.items.map((item) => item.label).toList();

      expect(labels, containsAll(testCase.$3));
      expect(labels, isNot(contains('Objet cassé')));
      expect(
        labels.where((label) => label != 'Aucun objet').length,
        testCase.$3.length,
      );
    });
  }

  testWidgets('keeps an incompatible current value visible without raw id', (
    tester,
  ) async {
    await _pumpPicker(
      tester,
      requirement: ItemCapabilityRequirement.capture,
      value: 'missing-ball-id',
    );

    final dropdown = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const Key('capability-picker')),
    );

    expect(
      dropdown.items.map((item) => item.label),
      contains('Référence indisponible'),
    );
    expect(find.textContaining('missing-ball-id'), findsNothing);
  });
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required ItemCapabilityRequirement requirement,
  required String value,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      home: Scaffold(
        body: ItemCapabilityPicker(
          fieldKey: const Key('capability-picker'),
          label: 'Objet',
          definitions: _definitions,
          readinessByItemId: const <String, bool>{'broken': false},
          requirement: requirement,
          value: value,
          allowEmpty: true,
          onChanged: (_) {},
        ),
      ),
    ),
  );
}

final List<ProjectItemDefinition> _definitions = <ProjectItemDefinition>[
  const ProjectItemDefinition(
    id: 'potion',
    displayName: 'Potion',
    pocketId: 'medicine',
    uses: <ProjectItemUseDefinition>[
      ProjectItemUseDefinition(
        contexts: <ProjectItemUseContext>{
          ProjectItemUseContext.overworld,
          ProjectItemUseContext.battle,
        },
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      ),
    ],
  ),
  ProjectItemDefinition(
    id: 'poke-ball',
    displayName: 'Poké Ball',
    pocketId: 'poke-balls',
    capture: ProjectCaptureItemDefinition(
      rateNumerator: 1,
      rateDenominator: 1,
      allowedEncounterKinds: EncounterKind.values.toSet(),
    ),
  ),
  const ProjectItemDefinition(
    id: 'tm-cut',
    displayName: 'CT Coupe',
    pocketId: 'machines',
    machine: ProjectMoveMachineItemDefinition(
      moveId: 'cut',
      kind: ProjectMoveMachineKind.tm,
      consumable: true,
    ),
  ),
  const ProjectItemDefinition(
    id: 'leftovers',
    displayName: 'Restes',
    pocketId: 'items',
    heldEffectId: 'leftovers',
  ),
  const ProjectItemDefinition(
    id: 'broken',
    displayName: 'Objet cassé',
    pocketId: 'items',
  ),
];
