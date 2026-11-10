import 'package:map_core/map_core_domain.dart';

import 'world_draft_inputs.dart';
import 'world_workspace_controller.dart';

class WorldEditorWorkflow {
  const WorldEditorWorkflow({
    required this.controller,
    required this.inputs,
    required this.flushFocus,
    required this.changed,
    required this.confirmDependency,
  });

  final WorldWorkspaceController controller;
  final WorldDraftInputs inputs;
  final void Function() flushFocus;
  final void Function() changed;
  final Future<bool> Function(NarrativeFactDefinition) confirmDependency;

  bool flush() {
    flushFocus();
    return inputs.valid;
  }

  Future<void> save({required bool rules}) async {
    final id = rules ? controller.selectedRuleId : controller.selectedFactId;
    if (!flush() || id == null) return;
    if (!rules) {
      await controller.saveFact(id);
      changed();
      return;
    }
    final state = controller.unsavedRuleDependency(id);
    if (state != null && !await confirmDependency(state)) return;
    state == null
        ? await controller.saveRule(id)
        : await controller.saveRuleWithDependency(id);
    changed();
  }

  void create({required bool rules}) {
    if (!flush()) return;
    rules ? controller.createRule() : controller.createFact();
    changed();
  }

  bool commitFact(
    String id,
    String field,
    NarrativeFactDefinition Function(NarrativeFactDefinition)? change,
  ) {
    final key = '$id.$field';
    if (change == null) {
      inputs.invalidFields.add(key);
      changed();
      return false;
    }
    inputs.invalidFields.remove(key);
    final current = controller.fact(id);
    if (current != null) controller.editFact(change(current));
    changed();
    return true;
  }

  bool commitRuleLabel(String id, String value) {
    if (!inputs.accept('$id.label', value.trim().isNotEmpty)) {
      changed();
      return false;
    }
    controller.editRule(id, (draft) => draft.label = value);
    changed();
    return true;
  }

  bool commitFactLabel(String id, String value) => commitFact(
    id,
    'label',
    value.trim().isEmpty
        ? null
        : (current) => copyWorldFact(current, label: value),
  );

  bool commitFactInteger(String id, String raw) {
    final parsed = int.tryParse(raw.trim());
    return commitFact(
      id,
      'value',
      parsed == null
          ? null
          : (current) => copyWorldFact(
              current,
              initialValue: NarrativeValue.integer(parsed),
            ),
    );
  }

  bool commitExpectedInteger({
    required String ruleId,
    required String factId,
    required NarrativeFactOperator operator,
    required String raw,
  }) {
    final parsed = int.tryParse(raw.trim());
    if (!inputs.accept('$ruleId.expected', parsed != null)) {
      changed();
      return false;
    }
    controller.editRule(
      ruleId,
      (draft) => draft.source = WorldRuleSource.factValue(
        factId: factId,
        operator: operator,
        expectedValue: NarrativeValue.integer(parsed!),
      ),
    );
    changed();
    return true;
  }

  void applyPeriodicRewardCondition(
    String ruleId,
    PeriodicRewardReference reference,
    bool expectedValue,
  ) {
    controller.editRule(
      ruleId,
      (value) => value.source = WorldRuleSource.periodicRewardAvailable(
        reference: reference,
        expectedValue: expectedValue,
      ),
    );
  }

  Future<void> changeFactKind(
    NarrativeFactDefinition fact,
    NarrativeValueKind kind,
  ) async {
    if (!flush() || kind == fact.valueKind) return;
    final preview = controller.previewFactType(fact.id, kind);
    final impacted = preview?.usages ?? const [];
    if (impacted.isNotEmpty) {
      inputs.actionError =
          'Changement refusé : ${impacted.length} usage(s) incompatible(s).';
      changed();
      return;
    }
    if (fact.legacyFlagName != null && kind != NarrativeValueKind.boolean) {
      inputs.actionError =
          'La liaison historique n’existe que pour un booléen. Retirez-la '
          'explicitement avant de changer de type.';
      changed();
      return;
    }
    inputs.actionError = null;
    controller.editFact(
      NarrativeFactDefinition(
        id: fact.id,
        label: fact.label,
        description: fact.description,
        category: fact.category,
        initialValue: switch (kind) {
          NarrativeValueKind.boolean => const NarrativeValue.boolean(false),
          NarrativeValueKind.integer => NarrativeValue.integer(0),
          NarrativeValueKind.string => const NarrativeValue.string(''),
        },
        tags: fact.tags,
      ),
    );
    controller.reconcileSimulation();
    changed();
  }

  void applySource(String ruleId, WorldRuleSourcePickerOption option) {
    controller.editRule(ruleId, (draft) {
      draft.source = option.kind == WorldRuleSourceKind.fact
          ? WorldRuleSource.factValue(
              factId: option.sourceId,
              operator: NarrativeFactOperator.equals,
              expectedValue:
                  controller.fact(option.sourceId)?.initialValue ??
                  const NarrativeValue.boolean(true),
              label: option.label,
            )
          : WorldRuleSource(
              kind: option.kind,
              sourceId: option.sourceId,
              predicate: option.predicate,
              label: option.label,
            );
    });
    changed();
  }

  void applyTarget(String ruleId, WorldRuleTargetPickerOption option) {
    controller.editRule(ruleId, (draft) {
      draft.target = WorldRuleTarget(
        kind: option.kind,
        mapId: option.mapId,
        entityId: option.entityId,
        eventId: option.eventId,
        label: option.label,
      );
      final effect = draft.effect;
      if (effect != null &&
          !isWorldRuleEffectCompatibleWithTarget(option.kind, effect.kind)) {
        draft.effect = null;
      }
    });
    changed();
  }

  void applyAtmosphereTarget(String ruleId, String mapId) {
    controller.editRule(ruleId, (draft) {
      draft.target = WorldRuleTarget(
        kind: WorldRuleTargetKind.atmosphere,
        mapId: mapId,
      );
      draft.effect = WorldRuleEffect(
        kind: WorldRuleEffectKind.atmosphere,
        visualSettings: SpatialVisualPatch({
          SpatialVisualParameter.depthOfFieldEnabled: true,
        }),
      );
    });
    changed();
  }

  void applyEffect(
    String ruleId,
    WorldRuleEffectKind kind, {
    String? dialogueId,
  }) {
    controller.editRule(ruleId, (draft) {
      draft.effect = WorldRuleEffect(
        kind: kind,
        dialogueId: dialogueId,
        visualSettings: kind == WorldRuleEffectKind.atmosphere
            ? SpatialVisualPatch({
                SpatialVisualParameter.depthOfFieldEnabled: true,
              })
            : null,
      );
    });
    changed();
  }

  MapData previewMap(MapData map) {
    final report = controller.report;
    if (report == null) return map;
    final hidden = <String>{
      for (final state in report.entityStates)
        if (state.mapId == map.id && !state.visible) state.entityId,
    };
    if (hidden.isEmpty) return map;
    return map.copyWith(
      entities: [
        for (final entity in map.entities)
          if (!hidden.contains(entity.id)) entity,
      ],
    );
  }
}

NarrativeFactDefinition copyWorldFact(
  NarrativeFactDefinition current, {
  String? label,
  String? description,
  String? category,
  NarrativeValue? initialValue,
}) => NarrativeFactDefinition(
  id: current.id,
  label: label ?? current.label,
  description: description ?? current.description,
  category: category ?? current.category,
  initialValue: initialValue ?? current.initialValue,
  tags: current.tags,
  legacyFlagName: current.legacyFlagName,
);

({PeriodicRewardReference? reference, bool expectedValue})
worldPeriodicRewardSelection(WorldRuleSource? source) => (
  reference: source?.rewardReference,
  expectedValue: source?.predicate != WorldRuleSourcePredicate.isFalse,
);
