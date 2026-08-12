import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import 'item_studio_gateway.dart';

final class ItemEffectEditor extends StatelessWidget {
  const ItemEffectEditor({
    super.key,
    required this.definition,
    required this.onChanged,
    this.heldEffectOptions = const <ItemStudioOption>[],
    this.moveOptions = const <ItemStudioOption>[],
  });

  final ProjectItemDefinition definition;
  final ValueChanged<ProjectItemDefinition> onChanged;
  final List<ItemStudioOption> heldEffectOptions;
  final List<ItemStudioOption> moveOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Utilisation',
          description: 'Choisis où et comment cet objet agit.',
        ),
        PokeMapToggleTile(
          key: const Key('item-effect-overworld-toggle'),
          label: 'Utilisable dans le monde',
          description: 'Depuis le sac, hors combat.',
          value: _useFor(ProjectItemUseContext.overworld) != null,
          onChanged: (enabled) =>
              _toggleUse(ProjectItemUseContext.overworld, enabled),
        ),
        if (_useFor(ProjectItemUseContext.overworld) case final use?) ...[
          const SizedBox(height: 8),
          _UseEditor(
            context: ProjectItemUseContext.overworld,
            use: use,
            onChanged: (value) =>
                _replaceUse(ProjectItemUseContext.overworld, value),
          ),
        ],
        const SizedBox(height: 8),
        PokeMapToggleTile(
          key: const Key('item-effect-battle-toggle'),
          label: 'Utilisable en combat',
          description: 'Depuis le sac pendant un combat.',
          value: _useFor(ProjectItemUseContext.battle) != null,
          onChanged: (enabled) =>
              _toggleUse(ProjectItemUseContext.battle, enabled),
        ),
        if (_useFor(ProjectItemUseContext.battle) case final use?) ...[
          const SizedBox(height: 8),
          _UseEditor(
            context: ProjectItemUseContext.battle,
            use: use,
            onChanged: (value) =>
                _replaceUse(ProjectItemUseContext.battle, value),
          ),
        ],
        const SizedBox(height: 16),
        const PokeMapSectionHeader(
          title: 'Capacités spéciales',
          description: 'Capture, capsule technique et effet tenu.',
        ),
        PokeMapToggleTile(
          key: const Key('item-effect-capture-toggle'),
          label: 'Objet de capture',
          description: 'Autorise la capture pendant une rencontre.',
          value: definition.capture != null,
          onChanged: _toggleCapture,
        ),
        if (definition.capture case final capture?) ...[
          const SizedBox(height: 8),
          _CaptureEditor(
            capture: capture,
            onChanged: (value) =>
                onChanged(definition.copyWith(capture: value).normalized()),
          ),
        ],
        const SizedBox(height: 8),
        PokeMapToggleTile(
          key: const Key('item-effect-machine-toggle'),
          label: 'Capsule technique',
          description: moveOptions.isEmpty
              ? 'Aucune capacité n’est encore déclarée dans ce catalogue.'
              : 'Enseigne une capacité choisie dans le projet.',
          value: definition.machine != null,
          onChanged: moveOptions.isEmpty ? (_) {} : _toggleMachine,
        ),
        if (definition.machine case final machine?) ...[
          const SizedBox(height: 8),
          _MachineEditor(
            machine: machine,
            moveOptions: _withCurrentOption(moveOptions, machine.moveId),
            onChanged: (value) =>
                onChanged(definition.copyWith(machine: value).normalized()),
          ),
        ],
        const SizedBox(height: 8),
        PokeMapToggleTile(
          key: const Key('item-effect-held-toggle'),
          label: 'Effet lorsqu’il est tenu',
          description: heldEffectOptions.isEmpty
              ? 'Aucun effet tenu n’est encore déclaré dans ce catalogue.'
              : 'Applique un effet de combat supporté.',
          value: definition.heldEffectId != null,
          onChanged: heldEffectOptions.isEmpty ? (_) {} : _toggleHeld,
        ),
        if (definition.heldEffectId case final heldEffectId?) ...[
          const SizedBox(height: 8),
          PokeMapDropdownField<String>(
            key: const Key('item-effect-held-dropdown'),
            label: 'Effet tenu',
            value: heldEffectId,
            items: <PokeMapDropdownItem<String>>[
              for (final option in _withCurrentOption(
                heldEffectOptions,
                heldEffectId,
              ))
                PokeMapDropdownItem<String>(
                  value: option.id,
                  label: option.label,
                ),
            ],
            onChanged: (value) => onChanged(
              definition.copyWith(heldEffectId: value).normalized(),
            ),
          ),
        ],
      ],
    );
  }

  ProjectItemUseDefinition? _useFor(ProjectItemUseContext context) {
    for (final use in definition.uses) {
      if (use.contexts.contains(context)) return use;
    }
    return null;
  }

  void _toggleUse(ProjectItemUseContext context, bool enabled) {
    if (!enabled) {
      onChanged(
        definition.copyWith(uses: _withoutContext(context)).normalized(),
      );
      return;
    }
    _replaceUse(
      context,
      ProjectItemUseDefinition(
        contexts: <ProjectItemUseContext>{context},
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      ),
    );
  }

  void _replaceUse(
    ProjectItemUseContext context,
    ProjectItemUseDefinition replacement,
  ) {
    onChanged(
      definition
          .copyWith(
            uses: <ProjectItemUseDefinition>[
              ..._withoutContext(context),
              replacement.copyWith(contexts: <ProjectItemUseContext>{context}),
            ],
          )
          .normalized(),
    );
  }

  List<ProjectItemUseDefinition> _withoutContext(
    ProjectItemUseContext context,
  ) {
    return <ProjectItemUseDefinition>[
      for (final use in definition.uses)
        if (!use.contexts.contains(context))
          use
        else if (use.contexts.length > 1)
          use.copyWith(
            contexts: use.contexts.difference(<ProjectItemUseContext>{context}),
          ),
    ];
  }

  void _toggleCapture(bool enabled) {
    onChanged(
      definition
          .copyWith(
            capture: enabled
                ? ProjectCaptureItemDefinition(
                    rateNumerator: 1,
                    rateDenominator: 1,
                    allowedEncounterKinds: EncounterKind.values.toSet(),
                  )
                : null,
          )
          .normalized(),
    );
  }

  void _toggleMachine(bool enabled) {
    onChanged(
      definition
          .copyWith(
            machine: enabled
                ? ProjectMoveMachineItemDefinition(
                    moveId: moveOptions.first.id,
                    kind: ProjectMoveMachineKind.tm,
                    consumable: true,
                  )
                : null,
          )
          .normalized(),
    );
  }

  void _toggleHeld(bool enabled) {
    onChanged(
      definition
          .copyWith(heldEffectId: enabled ? heldEffectOptions.first.id : null)
          .normalized(),
    );
  }
}

final class _UseEditor extends StatelessWidget {
  const _UseEditor({
    required this.context,
    required this.use,
    required this.onChanged,
  });

  final ProjectItemUseContext context;
  final ProjectItemUseDefinition use;
  final ValueChanged<ProjectItemUseDefinition> onChanged;

  @override
  Widget build(BuildContext buildContext) {
    final effects = _effectOptions(context, use.effect);
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapDropdownField<ProjectItemTargetKind>(
            label: 'Cible',
            value: use.target,
            items: const <PokeMapDropdownItem<ProjectItemTargetKind>>[
              PokeMapDropdownItem(
                value: ProjectItemTargetKind.partyMember,
                label: 'Équipier',
              ),
              PokeMapDropdownItem(
                value: ProjectItemTargetKind.partyMove,
                label: 'Capacité d’un équipier',
              ),
              PokeMapDropdownItem(
                value: ProjectItemTargetKind.world,
                label: 'Monde',
              ),
              PokeMapDropdownItem(
                value: ProjectItemTargetKind.none,
                label: 'Aucune cible',
              ),
            ],
            onChanged: (value) => onChanged(use.copyWith(target: value)),
          ),
          const SizedBox(height: 8),
          PokeMapDropdownField<ProjectItemConsumptionPolicy>(
            label: 'Consommation',
            value: use.consumption,
            items: const <PokeMapDropdownItem<ProjectItemConsumptionPolicy>>[
              PokeMapDropdownItem(
                value: ProjectItemConsumptionPolicy.onApplied,
                label: 'Quand l’effet est appliqué',
              ),
              PokeMapDropdownItem(
                value: ProjectItemConsumptionPolicy.never,
                label: 'Jamais',
              ),
            ],
            onChanged: (value) => onChanged(use.copyWith(consumption: value)),
          ),
          const SizedBox(height: 8),
          PokeMapDropdownField<String>(
            key: Key('item-effect-${context.name}-effect-dropdown'),
            label: 'Effet',
            value: _effectIdentity(use.effect),
            items: <PokeMapDropdownItem<String>>[
              for (final option in effects)
                PokeMapDropdownItem<String>(value: option.$1, label: option.$2),
            ],
            onChanged: (value) => onChanged(
              use.copyWith(effect: _decodeEffect(value)).normalized(),
            ),
          ),
        ],
      ),
    );
  }
}

final class _CaptureEditor extends StatelessWidget {
  const _CaptureEditor({required this.capture, required this.onChanged});

  final ProjectCaptureItemDefinition capture;
  final ValueChanged<ProjectCaptureItemDefinition> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = '${capture.rateNumerator}/${capture.rateDenominator}';
    final ratios = <String>{current, '1/1', '3/2', '2/1', '3/1'};
    return PokeMapCard(
      child: PokeMapDropdownField<String>(
        label: 'Bonus de capture',
        value: current,
        items: <PokeMapDropdownItem<String>>[
          for (final ratio in ratios)
            PokeMapDropdownItem<String>(
              value: ratio,
              label: '× ${_ratioLabel(ratio)}',
            ),
        ],
        onChanged: (value) {
          final parts = value.split('/');
          onChanged(
            capture
                .copyWith(
                  rateNumerator: int.parse(parts.first),
                  rateDenominator: int.parse(parts.last),
                )
                .normalized(),
          );
        },
      ),
    );
  }
}

final class _MachineEditor extends StatelessWidget {
  const _MachineEditor({
    required this.machine,
    required this.moveOptions,
    required this.onChanged,
  });

  final ProjectMoveMachineItemDefinition machine;
  final List<ItemStudioOption> moveOptions;
  final ValueChanged<ProjectMoveMachineItemDefinition> onChanged;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapDropdownField<String>(
            label: 'Capacité enseignée',
            value: machine.moveId,
            items: <PokeMapDropdownItem<String>>[
              for (final option in moveOptions)
                PokeMapDropdownItem<String>(
                  value: option.id,
                  label: option.label,
                ),
            ],
            onChanged: (value) =>
                onChanged(machine.copyWith(moveId: value).normalized()),
          ),
          const SizedBox(height: 8),
          PokeMapDropdownField<ProjectMoveMachineKind>(
            label: 'Type de capsule',
            value: machine.kind,
            items: const <PokeMapDropdownItem<ProjectMoveMachineKind>>[
              PokeMapDropdownItem(
                value: ProjectMoveMachineKind.tm,
                label: 'CT',
              ),
              PokeMapDropdownItem(
                value: ProjectMoveMachineKind.hm,
                label: 'CS',
              ),
            ],
            onChanged: (value) => onChanged(
              machine
                  .copyWith(
                    kind: value,
                    consumable:
                        value == ProjectMoveMachineKind.tm &&
                        machine.consumable,
                  )
                  .normalized(),
            ),
          ),
          if (machine.kind == ProjectMoveMachineKind.tm) ...[
            const SizedBox(height: 8),
            PokeMapToggleTile(
              label: 'Consommée après apprentissage',
              value: machine.consumable,
              onChanged: (value) =>
                  onChanged(machine.copyWith(consumable: value).normalized()),
            ),
          ],
        ],
      ),
    );
  }
}

List<(String, String)> _effectOptions(
  ProjectItemUseContext context,
  ProjectItemEffectDefinition current,
) {
  final values =
      <(ProjectItemEffectDefinition, String)>[
        (
          const ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: 20,
          ),
          'Soigne 20 PV',
        ),
        (
          const ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.full,
          ),
          'Restaure tous les PV',
        ),
        (
          const ProjectItemEffectDefinition.cureStatus(
            mode: ProjectItemStatusCureMode.all,
          ),
          'Soigne tous les statuts',
        ),
        (
          const ProjectItemEffectDefinition.revive(
            rateNumerator: 1,
            rateDenominator: 2,
          ),
          'Ranime avec la moitié des PV',
        ),
        (
          const ProjectItemEffectDefinition.restorePp(
            mode: ProjectItemAmountMode.flat,
            amount: 10,
          ),
          'Restaure 10 PP',
        ),
      ]..removeWhere(
        (option) => !itemSystemV1CapabilityTruth.supportsUse(
          context,
          projectItemEffectCapabilityOf(option.$1),
        ),
      );
  final currentIdentity = _effectIdentity(current);
  if (!values.any((option) => _effectIdentity(option.$1) == currentIdentity)) {
    values.insert(0, (current, 'Effet actuel'));
  }
  return <(String, String)>[
    for (final option in values) (_effectIdentity(option.$1), option.$2),
  ];
}

String _effectIdentity(ProjectItemEffectDefinition effect) {
  return jsonEncode(effect.toJson());
}

ProjectItemEffectDefinition _decodeEffect(String identity) {
  return ProjectItemEffectDefinition.fromJson(
    Map<String, dynamic>.from(jsonDecode(identity) as Map),
  );
}

List<ItemStudioOption> _withCurrentOption(
  List<ItemStudioOption> options,
  String currentId,
) {
  if (options.any((option) => option.id == currentId)) return options;
  return <ItemStudioOption>[
    ItemStudioOption(id: currentId, label: _humanize(currentId)),
    ...options,
  ];
}

String _humanize(String value) {
  return value
      .split(RegExp(r'[_\-.]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _ratioLabel(String ratio) {
  final parts = ratio.split('/');
  final value = int.parse(parts.first) / int.parse(parts.last);
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
