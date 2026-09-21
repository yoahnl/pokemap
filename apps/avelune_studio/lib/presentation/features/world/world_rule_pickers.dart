part of 'world_workspace_page.dart';

extension _WorldRulePickers on _WorldWorkspacePageState {
  String _sourceSummary(WorldRuleSource source) => switch (source.kind) {
    WorldRuleSourceKind.fact =>
      '${controller.fact(source.sourceId)?.label ?? 'État absent : ${source.sourceId}'} '
          '${_operatorLabel(source.factOperator ?? NarrativeFactOperator.equals)} '
          '${_valueLabel(source.expectedFactValue ?? const NarrativeValue.boolean(true))}',
    WorldRuleSourceKind.storyStepCompletion =>
      '${source.label ?? source.sourceId} · '
          '${source.predicate == WorldRuleSourcePredicate.completed ? 'terminée' : 'non terminée'}',
    WorldRuleSourceKind.consumedEvent =>
      '${source.label ?? source.sourceId} · '
          '${source.predicate == WorldRuleSourcePredicate.consumed ? 'consommé' : 'non consommé'}',
  };

  String _targetSummary(WorldRuleTarget target) =>
      target.label ??
      switch (target.kind) {
        WorldRuleTargetKind.mapEntity => 'Personnage ${target.entityId}',
        WorldRuleTargetKind.npcDialogue => 'Dialogue de ${target.entityId}',
        WorldRuleTargetKind.mapEvent => 'Événement ${target.eventId}',
        WorldRuleTargetKind.narrativeEvent => 'Événement ${target.eventId}',
      };

  Future<T?> _choose<T>(String title, List<(T, String, String)> options) =>
      showDialog<T>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 460,
            height: 420,
            child: options.isEmpty
                ? const StudioEmptyState(
                    title: 'Aucun choix disponible',
                    description:
                        'Le projet ne propose rien de compatible ici pour '
                        'l’instant.',
                  )
                : ListView(
                    children: [
                      for (final option in options)
                        ListTile(
                          title: Text(option.$2),
                          subtitle: option.$3.isEmpty ? null : Text(option.$3),
                          onTap: () => Navigator.pop(context, option.$1),
                        ),
                    ],
                  ),
          ),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Future<void> _pickSource(WorldRuleDraft draft) async {
    if (!flush()) return;
    final chosen =
        await _choose<WorldRuleSourcePickerOption>('Choisir la condition', [
          for (final option in controller.model.sourceOptions)
            (option, option.label, option.subtitle),
        ]);
    if (chosen == null || !mounted) return;
    controller.editRule(draft.id, (d) {
      d.source = chosen.kind == WorldRuleSourceKind.fact
          ? WorldRuleSource.factValue(
              factId: chosen.sourceId,
              operator: NarrativeFactOperator.equals,
              expectedValue:
                  controller.fact(chosen.sourceId)?.initialValue ??
                  const NarrativeValue.boolean(true),
              label: chosen.label,
            )
          : WorldRuleSource(
              kind: chosen.kind,
              sourceId: chosen.sourceId,
              predicate: chosen.predicate,
              label: chosen.label,
            );
    });
    refresh();
  }

  /// Changing the target drops an effect the model no longer allows, rather
  /// than keeping a combination the projection would refuse.
  Future<void> _pickTarget(WorldRuleDraft draft) async {
    if (!flush()) return;
    final chosen =
        await _choose<WorldRuleTargetPickerOption>('Choisir la cible', [
          for (final option in controller.model.targetOptions)
            (option, option.label, option.subtitle),
        ]);
    if (chosen == null || !mounted) return;
    controller.editRule(draft.id, (d) {
      d.target = WorldRuleTarget(
        kind: chosen.kind,
        mapId: chosen.mapId,
        entityId: chosen.entityId,
        eventId: chosen.eventId,
        label: chosen.label,
      );
      final effect = d.effect;
      if (effect != null &&
          !isWorldRuleEffectCompatibleWithTarget(chosen.kind, effect.kind)) {
        d.effect = null;
      }
    });
    refresh();
  }

  Future<void> _pickEffect(WorldRuleDraft draft) async {
    if (!flush()) return;
    final options = controller.effectsFor(draft.id);
    final chosen =
        await _choose<WorldRuleEffectPickerOption>('Choisir l’effet', [
          for (final option in options)
            (
              option,
              _effectLabel(option.effectKind),
              option.requiresDialogue
                  ? 'Demande un dialogue de remplacement'
                  : '',
            ),
        ]);
    if (chosen == null || !mounted) return;
    String? dialogueId;
    if (chosen.requiresDialogue) {
      dialogueId =
          await _choose<String>('Choisir le dialogue de remplacement', [
            for (final option in controller.model.dialogueOptions)
              (option.dialogueId, option.label, option.subtitle),
          ]);
      if (dialogueId == null || !mounted) return;
    }
    controller.editRule(
      draft.id,
      (d) => d.effect = WorldRuleEffect(
        kind: chosen.effectKind,
        dialogueId: dialogueId,
      ),
    );
    refresh();
  }

  Future<void> _deleteRule(WorldRuleDraft draft) async {
    if (!flush()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${draft.label} » ?'),
        content: const Text(
          'La cible et le dialogue référencés ne sont pas supprimés.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Supprimer',
            variant: StudioButtonVariant.destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteRule(draft.id);
    refresh();
  }
}
