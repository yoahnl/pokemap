import 'package:map_core/map_core.dart';

final class ItemSystemAuthoringProbeAction {
  const ItemSystemAuthoringProbeAction(this.actionId, this.parameters);

  final String actionId;
  final Map<String, Object?> parameters;

  String get slug => actionId.replaceAll('.', '-').replaceAll('_', '-');
}

final itemSystemAuthoringProbeActions = <ItemSystemAuthoringProbeAction>[
  ItemSystemAuthoringProbeAction('item.create', <String, Object?>{
    'definition': const ProjectItemDefinition(
      id: 'cert-probe',
      displayName: 'Certification Probe',
      pocketId: 'custom',
    ).toJson(),
  }),
  ItemSystemAuthoringProbeAction('item.update', <String, Object?>{
    'itemId': 'cert-probe',
    'definition': const ProjectItemDefinition(
      id: 'cert-probe',
      displayName: 'Updated Certification Probe',
      pocketId: 'custom',
      buyPrice: 100,
    ).toJson(),
  }),
  const ItemSystemAuthoringProbeAction('item.clone', <String, Object?>{
    'sourceItemId': 'cert-probe',
    'newItemId': 'cert-copy',
    'displayName': 'Certification Copy',
  }),
  const ItemSystemAuthoringProbeAction('item.delete_apply', <String, Object?>{
    'itemId': 'cert-copy',
  }),
  ItemSystemAuthoringProbeAction('item.set_overworld_effect', <String, Object?>{
    'itemId': 'cert-probe',
    'use': const ProjectItemUseDefinition(
      contexts: <ProjectItemUseContext>{ProjectItemUseContext.overworld},
      target: ProjectItemTargetKind.partyMember,
      consumption: ProjectItemConsumptionPolicy.onApplied,
      effect: ProjectItemEffectDefinition.healHp(
        mode: ProjectItemAmountMode.flat,
        amount: 20,
      ),
    ).toJson(),
  }),
  ItemSystemAuthoringProbeAction('item.set_battle_effect', <String, Object?>{
    'itemId': 'cert-probe',
    'use': const ProjectItemUseDefinition(
      contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
      target: ProjectItemTargetKind.partyMember,
      consumption: ProjectItemConsumptionPolicy.onApplied,
      effect: ProjectItemEffectDefinition.healHp(
        mode: ProjectItemAmountMode.flat,
        amount: 15,
      ),
    ).toJson(),
  }),
  const ItemSystemAuthoringProbeAction(
    'item.set_held_effect',
    <String, Object?>{'itemId': 'cert-probe', 'heldEffectId': 'leftovers'},
  ),
  ItemSystemAuthoringProbeAction('item.set_capture_effect', <String, Object?>{
    'itemId': 'cert-probe',
    'capture': const ProjectCaptureItemDefinition(
      rateNumerator: 1,
      rateDenominator: 1,
      allowedEncounterKinds: <EncounterKind>{EncounterKind.walk},
    ).toJson(),
  }),
  ItemSystemAuthoringProbeAction('item.set_tm_hm_move', <String, Object?>{
    'itemId': 'cert-probe',
    'machine': const ProjectMoveMachineItemDefinition(
      moveId: 'protect',
      kind: ProjectMoveMachineKind.tm,
      consumable: true,
    ).toJson(),
  }),
];

final itemSystemRejectedAuthoringProbeActions =
    <ItemSystemAuthoringProbeAction>[
      ItemSystemAuthoringProbeAction(
        'item.set_battle_effect',
        <String, Object?>{
          'itemId': 'cert-probe',
          'use': const ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMove,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.restorePp(
              mode: ProjectItemAmountMode.flat,
              amount: 10,
            ),
          ).toJson(),
        },
      ),
      const ItemSystemAuthoringProbeAction(
        'item.set_held_effect',
        <String, Object?>{
          'itemId': 'cert-probe',
          'heldEffectId': 'never_registered_effect',
        },
      ),
      ItemSystemAuthoringProbeAction(
        'item.set_overworld_effect',
        <String, Object?>{
          'itemId': 'cert-probe',
          'use': const ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{ProjectItemUseContext.overworld},
            target: ProjectItemTargetKind.world,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.repel(steps: 100),
          ).toJson(),
        },
      ),
    ];

void verifyItemSystemAuthoringProbeState(
  ProjectItemCatalog catalog,
  String actionId,
) {
  ProjectItemDefinition? definitionFor(String id) {
    for (final definition in catalog.entries) {
      if (definition.id == id) return definition;
    }
    return null;
  }

  final probe = definitionFor('cert-probe');
  if (actionId == 'item.create') {
    _require(probe?.displayName == 'Certification Probe', actionId);
    return;
  }
  _require(probe != null, actionId);
  switch (actionId) {
    case 'item.update':
      _require(
        probe!.displayName == 'Updated Certification Probe' &&
            probe.buyPrice == 100,
        actionId,
      );
      return;
    case 'item.clone':
      final copy = definitionFor('cert-copy');
      _require(
        copy?.displayName == 'Certification Copy' && copy?.buyPrice == 100,
        actionId,
      );
      return;
    case 'item.delete_apply':
      _require(definitionFor('cert-copy') == null, actionId);
      return;
    case 'item.set_overworld_effect':
      final use = _useFor(probe!, ProjectItemUseContext.overworld);
      _require(
        use?.effect is ProjectItemHealHpEffectDefinition &&
            (use!.effect as ProjectItemHealHpEffectDefinition).amount == 20,
        actionId,
      );
      return;
    case 'item.set_battle_effect':
      final overworld = _useFor(probe!, ProjectItemUseContext.overworld);
      final battle = _useFor(probe, ProjectItemUseContext.battle);
      _require(
        overworld?.effect is ProjectItemHealHpEffectDefinition &&
            (overworld!.effect as ProjectItemHealHpEffectDefinition).amount ==
                20 &&
            battle?.effect is ProjectItemHealHpEffectDefinition &&
            (battle!.effect as ProjectItemHealHpEffectDefinition).amount == 15,
        actionId,
      );
      return;
    case 'item.set_held_effect':
      _require(probe!.heldEffectId == 'leftovers', actionId);
      return;
    case 'item.set_capture_effect':
      _require(
        probe!.capture?.rateNumerator == 1 &&
            probe.capture?.rateDenominator == 1 &&
            probe.capture!.allowedEncounterKinds.contains(EncounterKind.walk),
        actionId,
      );
      return;
    case 'item.set_tm_hm_move':
      _require(
        probe!.machine?.moveId == 'protect' &&
            probe.machine?.kind == ProjectMoveMachineKind.tm &&
            probe.machine?.consumable == true,
        actionId,
      );
      return;
    default:
      throw ArgumentError.value(actionId, 'actionId', 'is not a probe action');
  }
}

ProjectItemUseDefinition? _useFor(
  ProjectItemDefinition definition,
  ProjectItemUseContext context,
) {
  for (final use in definition.uses) {
    if (use.contexts.contains(context)) return use;
  }
  return null;
}

void _require(bool condition, String actionId) {
  if (!condition) {
    throw StateError('$actionId did not produce its expected semantic state.');
  }
}
