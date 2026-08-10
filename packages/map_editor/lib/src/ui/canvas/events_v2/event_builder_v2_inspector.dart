import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/state/narrative_event_validation_state.dart';
import '../../design_system/design_system.dart';

class EventBuilderV2Inspector extends StatelessWidget {
  const EventBuilderV2Inspector({
    super.key,
    required this.event,
    this.onChangeSource,
    this.onSeeOnMap,
    this.onOpenScene,
    this.onChangeBehavior,
    this.onManageEvaluationOrder,
    this.validationItems = const [],
    this.onValidationAction,
  });

  final NarrativeEventProjectSummary? event;
  final VoidCallback? onChangeSource;
  final VoidCallback? onSeeOnMap;
  final VoidCallback? onOpenScene;
  final VoidCallback? onChangeBehavior;
  final VoidCallback? onManageEvaluationOrder;
  final List<NarrativeEventValidationItem> validationItems;
  final ValueChanged<NarrativeEventValidationItem>? onValidationAction;

  @override
  Widget build(BuildContext context) {
    final selected = event;
    return PokeMapPanel(
      borderRadius: 8,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: const Padding(
        padding: EdgeInsets.fromLTRB(16, 11, 16, 9),
        child: Text(
          'INSPECTEUR D’ÉVÉNEMENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
          ),
        ),
      ),
      child: selected == null
          ? Center(
              child: Semantics(
                key: const ValueKey('event-builder-v2-inspector-neutral'),
                label: 'Inspecteur en attente d’un événement',
                child: const ExcludeSemantics(
                  child: PokeMapIconTile(
                    icon: CupertinoIcons.slider_horizontal_3,
                    tone: PokeMapTone.neutral,
                    size: 48,
                    iconSize: 20,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              key: const ValueKey('event-builder-v2-inspector-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InspectorSummary(event: selected),
                  if (validationItems.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    _InspectorSection(
                      key: const ValueKey(
                        'event-builder-v2-inspector-validation-diagnostics',
                      ),
                      title: 'Validation du projet',
                      tone: PokeMapTone.warning,
                      children: [
                        for (var index = 0;
                            index < validationItems.length;
                            index++) ...[
                          if (index > 0) const SizedBox(height: 7),
                          PokeMapDiagnosticCallout(
                            key: ValueKey(
                              'event-builder-v2-diagnostic-${validationItems[index].diagnostic.stableKey}',
                            ),
                            severity: _diagnosticSeverity(
                              validationItems[index].diagnostic.severity,
                            ),
                            title: _diagnosticTitle(
                              validationItems[index].diagnostic.severity,
                            ),
                            message: validationItems[index].diagnostic.message,
                            actionLabel: validationItems[index].actionable &&
                                    onValidationAction != null
                                ? 'Ouvrir'
                                : null,
                            onAction: validationItems[index].actionable &&
                                    onValidationAction != null
                                ? () => onValidationAction!(
                                      validationItems[index],
                                    )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 15),
                  _InspectorSection(
                    key: const ValueKey('event-builder-v2-inspector-source'),
                    title: 'Source du déclencheur',
                    tone: selected.source.available
                        ? PokeMapTone.narrative
                        : PokeMapTone.warning,
                    children: [
                      _InspectorField(
                        label: 'Type',
                        value: selected.source.sourceTypeLabel,
                        icon: CupertinoIcons.bolt_fill,
                        tone: selected.source.available
                            ? PokeMapTone.narrative
                            : PokeMapTone.warning,
                      ),
                      const SizedBox(height: 5),
                      _InspectorField(
                        label: 'Cible',
                        value: selected.source.humanSentence,
                        icon: selected.source.available
                            ? CupertinoIcons.person_crop_circle
                            : CupertinoIcons.exclamationmark_triangle_fill,
                        tone: selected.source.available
                            ? PokeMapTone.narrative
                            : PokeMapTone.warning,
                      ),
                      if (selected.source.mapLabel != null) ...[
                        const SizedBox(height: 5),
                        _InspectorField(
                          label: 'Portée dérivée · lecture seule',
                          value: selected.source.mapLabel!,
                          icon: CupertinoIcons.map_fill,
                          tone: PokeMapTone.map,
                        ),
                        const SizedBox(height: 5),
                        const _InspectorField(
                          label: 'Édition physique',
                          value: 'PNJ, objet, zone et géométrie · Map Editor',
                          icon: CupertinoIcons.map,
                          tone: PokeMapTone.map,
                        ),
                      ],
                      if (!selected.readOnly &&
                          (onChangeSource != null || onSeeOnMap != null)) ...[
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (onChangeSource != null)
                              PokeMapButton(
                                onPressed: onChangeSource,
                                size: PokeMapButtonSize.small,
                                variant: PokeMapButtonVariant.secondary,
                                child: Text(
                                  selected.source.source == null
                                      ? 'Choisir un élément'
                                      : selected.source.available
                                          ? 'Changer d’élément'
                                          : 'Rebrancher l’élément',
                                ),
                              ),
                            if (_isSpatialAndAvailable(selected) &&
                                onSeeOnMap != null)
                              PokeMapButton(
                                onPressed: onSeeOnMap,
                                size: PokeMapButtonSize.small,
                                variant: PokeMapButtonVariant.ghost,
                                leading: const Icon(
                                  CupertinoIcons.map_pin_ellipse,
                                ),
                                child: const Text('Voir sur la carte'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 13),
                  _InspectorSection(
                    key: const ValueKey(
                      'event-builder-v2-inspector-conditions',
                    ),
                    title: 'Conditions',
                    tone: selected.conditions.valid
                        ? PokeMapTone.info
                        : PokeMapTone.warning,
                    children: [
                      const _InspectorField(
                        label: 'Mode',
                        value: 'Toutes (AND) doivent être remplies',
                        icon: CupertinoIcons.checkmark_alt_circle_fill,
                        tone: PokeMapTone.info,
                      ),
                      if (selected.conditions.details.isEmpty) ...[
                        const SizedBox(height: 5),
                        _InspectorField(
                          label: 'Configuration',
                          value: selected.conditions.humanLabel,
                          icon: selected.conditions.valid
                              ? CupertinoIcons.list_bullet
                              : CupertinoIcons.exclamationmark_triangle_fill,
                          tone: selected.conditions.valid
                              ? PokeMapTone.info
                              : PokeMapTone.warning,
                        ),
                      ],
                      for (var index = 0;
                          index < selected.conditions.details.length;
                          index++) ...[
                        const SizedBox(height: 5),
                        _InspectorField(
                          label: 'Condition ${index + 1}',
                          value: selected.conditions.details[index].humanLabel,
                          icon: selected.conditions.details[index].resolved
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.exclamationmark_triangle_fill,
                          tone: selected.conditions.details[index].resolved
                              ? PokeMapTone.info
                              : PokeMapTone.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 13),
                  _InspectorSection(
                    key: const ValueKey('event-builder-v2-inspector-scene'),
                    title: 'Scene liée',
                    tone: selected.scene.valid
                        ? PokeMapTone.success
                        : PokeMapTone.warning,
                    readOnly: true,
                    children: [
                      _InspectorField(
                        label: 'Orchestration',
                        value: selected.scene.humanLabel,
                        icon: CupertinoIcons.play_rectangle_fill,
                        tone: selected.scene.valid
                            ? PokeMapTone.success
                            : PokeMapTone.warning,
                      ),
                      const SizedBox(height: 5),
                      _InspectorField(
                        label: 'Impact de la Scene · lecture seule',
                        value: _sceneImpactLabel(selected.projection),
                        icon: CupertinoIcons.bolt_circle_fill,
                        tone: PokeMapTone.narrative,
                      ),
                      for (var index = 0;
                          index < selected.projection.outcomeLabels.length;
                          index++) ...[
                        const SizedBox(height: 5),
                        _InspectorField(
                          label: 'Résultat ${index + 1} · lecture seule',
                          value: selected.projection.outcomeLabels[index],
                          icon: CupertinoIcons.flag_fill,
                          tone: PokeMapTone.narrative,
                        ),
                      ],
                      for (var index = 0;
                          index < selected.projection.consequences.length;
                          index++) ...[
                        const SizedBox(height: 5),
                        _InspectorField(
                          label: 'Conséquence ${index + 1} · lecture seule',
                          value: selected
                              .projection.consequences[index].humanLabel,
                          icon: CupertinoIcons.bolt_circle_fill,
                          tone: PokeMapTone.warning,
                        ),
                      ],
                      if (selected.scene.sceneId != null &&
                          onOpenScene != null) ...[
                        const SizedBox(height: 7),
                        PokeMapButton(
                          onPressed: onOpenScene,
                          size: PokeMapButtonSize.small,
                          variant: PokeMapButtonVariant.ghost,
                          leading: const Icon(
                            CupertinoIcons.arrow_up_right_square,
                          ),
                          child: const Text('Ouvrir la Scene'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 13),
                  _InspectorSection(
                    key: const ValueKey('event-builder-v2-inspector-behavior'),
                    title: 'Comportement',
                    tone: PokeMapTone.brand,
                    children: [
                      _InspectorField(
                        label: 'Réutilisation',
                        value: _lifecycleExplanation(selected.lifecycle),
                        icon: CupertinoIcons.repeat,
                        tone: PokeMapTone.brand,
                      ),
                      if (selected.lifecycle.resetPolicy
                          is! NarrativeEventResetNever) ...[
                        const SizedBox(height: 5),
                        _InspectorField(
                          label: 'Réarmement',
                          value: _resetPolicyExplanation(
                            selected.lifecycle.resetPolicy,
                          ),
                          icon: CupertinoIcons.refresh,
                          tone: PokeMapTone.brand,
                        ),
                      ],
                      const SizedBox(height: 5),
                      _InspectorField(
                        label: 'Priorité',
                        value: '${selected.lifecycle.priority ?? 0} '
                            '(ordre ${selected.lifecycle.order ?? 0})',
                        icon: CupertinoIcons.arrow_up_arrow_down,
                        tone: PokeMapTone.brand,
                      ),
                      const SizedBox(height: 5),
                      const _InspectorField(
                        label: 'Règle de concurrence',
                        value: 'La priorité la plus haute gagne, puis l’ordre '
                            'le plus bas.',
                        icon: CupertinoIcons.list_number,
                        tone: PokeMapTone.brand,
                      ),
                      if (selected.lifecycle.hasActiveCompetition) ...[
                        const SizedBox(height: 5),
                        _InspectorField(
                          label: 'Concurrence',
                          value:
                              '${selected.lifecycle.activeCandidateCount} événements actifs sur cet élément',
                          icon: CupertinoIcons.list_number,
                          tone: PokeMapTone.warning,
                        ),
                      ],
                      if (!selected.readOnly && onChangeBehavior != null) ...[
                        const SizedBox(height: 7),
                        PokeMapButton(
                          onPressed: onChangeBehavior,
                          size: PokeMapButtonSize.small,
                          variant: PokeMapButtonVariant.ghost,
                          child: const Text('Modifier'),
                        ),
                      ],
                    ],
                  ),
                  if (onManageEvaluationOrder != null &&
                      selected.lifecycle.hasActiveCompetition) ...[
                    const SizedBox(height: 13),
                    _InspectorSection(
                      key: const ValueKey(
                        'event-builder-v2-inspector-conflict',
                      ),
                      title: 'Concurrence sur cet élément',
                      tone: PokeMapTone.warning,
                      children: [
                        const _InspectorField(
                          label: 'Ordre d’évaluation',
                          value:
                              'Le suivant peut être évalué si le premier est inéligible.',
                          icon: CupertinoIcons.list_number,
                          tone: PokeMapTone.warning,
                        ),
                        const SizedBox(height: 7),
                        PokeMapButton(
                          onPressed: onManageEvaluationOrder,
                          size: PokeMapButtonSize.small,
                          variant: PokeMapButtonVariant.ghost,
                          child: const Text(
                            'Gérer l’ordre de déclenchement',
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (selected.diagnostics.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    _InspectorSection(
                      key: const ValueKey(
                        'event-builder-v2-inspector-diagnostics',
                      ),
                      title: 'À vérifier',
                      tone:
                          _diagnosticTone(selected.diagnostics.first.severity),
                      children: [
                        for (var index = 0;
                            index < selected.diagnostics.length;
                            index++) ...[
                          _InspectorField(
                            label: _diagnosticLabel(
                              selected.diagnostics[index].severity,
                            ),
                            value: selected.diagnostics[index].message,
                            icon: _diagnosticIcon(
                              selected.diagnostics[index].severity,
                            ),
                            tone: _diagnosticTone(
                              selected.diagnostics[index].severity,
                            ),
                          ),
                          if (index < selected.diagnostics.length - 1)
                            const SizedBox(height: 5),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _InspectorSummary extends StatelessWidget {
  const _InspectorSummary({required this.event});

  final NarrativeEventProjectSummary event;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokeMapIconTile(
          icon: CupertinoIcons.bolt_horizontal_circle_fill,
          tone: event.readOnly ? PokeMapTone.warning : PokeMapTone.narrative,
          size: 44,
          iconSize: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  PokeMapBadge(
                    label: event.readOnly
                        ? 'Ancien format à convertir'
                        : _eventStateLabel(event),
                    variant: event.readOnly
                        ? PokeMapBadgeVariant.warning
                        : event.enabled == true
                            ? PokeMapBadgeVariant.success
                            : PokeMapBadgeVariant.neutral,
                    icon: Icon(
                      event.readOnly
                          ? CupertinoIcons.lock
                          : event.enabled == true
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                    ),
                  ),
                  if (event.readOnly)
                    const PokeMapBadge(
                      label: 'Lecture seule',
                      variant: PokeMapBadgeVariant.neutral,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({
    super.key,
    required this.title,
    required this.tone,
    required this.children,
    this.readOnly = false,
  });

  final String title;
  final PokeMapTone tone;
  final List<Widget> children;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return Semantics(
      container: true,
      label: readOnly ? '$title, lecture seule' : title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.circle_fill, size: 5, color: toneColors.icon),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: toneColors.text,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (readOnly)
                const PokeMapBadge(
                  label: 'Lecture seule',
                  variant: PokeMapBadgeVariant.neutral,
                  icon: Icon(CupertinoIcons.lock),
                ),
            ],
          ),
          const SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }
}

class _InspectorField extends StatelessWidget {
  const _InspectorField({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 6,
      backgroundColor: toneColors.soft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: toneColors.icon),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: toneColors.text,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSpatialAndAvailable(NarrativeEventProjectSummary event) {
  final source = event.source.source;
  if (source == null || !event.source.available) return false;
  return source.when(
    entityInteract: (_, _) => true,
    triggerEnter: (_, _) => true,
    mapEnter: (_) => true,
    outcomeReceived: (_) => false,
  );
}

String _sceneImpactLabel(NarrativeEventProjectionSummary projection) {
  return '${_countLabel(projection.outcomeLabels.length, 'résultat', 'résultats')} · '
      '${_countLabel(projection.consequences.length, 'conséquence', 'conséquences')} · '
      '${_countLabel(projection.worldRules.length, 'règle monde', 'règles monde')}';
}

String _lifecycleExplanation(NarrativeEventLifecycleSummary lifecycle) {
  return switch (lifecycle.reusePolicy) {
    NarrativeEventReusePolicy.oneShot =>
      'Une seule fois : après succès, la sauvegarde le marque consommé.',
    NarrativeEventReusePolicy.reusable =>
      'Réutilisable : chaque nouvelle occurrence réévalue toutes les conditions.',
    null => lifecycle.humanLabel,
  };
}

String _resetPolicyExplanation(NarrativeEventResetPolicy? policy) {
  return switch (policy) {
    NarrativeEventResetOnMapReentry() =>
      'Après une vraie sortie puis une nouvelle entrée sur la map.',
    NarrativeEventResetOnOutcomeReceived(:final outcome) =>
      'À la réception de ${outcome.producerKind.name} · ${outcome.outcomeId}.',
    _ => 'Jamais',
  };
}

String _countLabel(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

String _eventStateLabel(NarrativeEventProjectSummary event) {
  if (event.readOnly) return 'Lecture seule';
  if (event.enabled == true) return 'Actif';
  if (event.status == NarrativeEventProjectStatus.draftIncomplete) {
    return 'Brouillon';
  }
  return 'Inactif';
}

String _diagnosticLabel(NarrativeEventProjectSummarySeverity severity) =>
    switch (severity) {
      NarrativeEventProjectSummarySeverity.info => 'Information',
      NarrativeEventProjectSummarySeverity.warning => 'Avertissement',
      NarrativeEventProjectSummarySeverity.error => 'Erreur',
    };

IconData _diagnosticIcon(NarrativeEventProjectSummarySeverity severity) =>
    switch (severity) {
      NarrativeEventProjectSummarySeverity.info => CupertinoIcons.info_circle,
      NarrativeEventProjectSummarySeverity.warning =>
        CupertinoIcons.exclamationmark_triangle_fill,
      NarrativeEventProjectSummarySeverity.error =>
        CupertinoIcons.xmark_octagon_fill,
    };

PokeMapTone _diagnosticTone(NarrativeEventProjectSummarySeverity severity) =>
    switch (severity) {
      NarrativeEventProjectSummarySeverity.info => PokeMapTone.info,
      NarrativeEventProjectSummarySeverity.warning => PokeMapTone.warning,
      NarrativeEventProjectSummarySeverity.error => PokeMapTone.danger,
    };

PokeMapDiagnosticSeverity _diagnosticSeverity(
  NarrativeEventValidationSeverity severity,
) =>
    switch (severity) {
      NarrativeEventValidationSeverity.info => PokeMapDiagnosticSeverity.info,
      NarrativeEventValidationSeverity.warning =>
        PokeMapDiagnosticSeverity.warning,
      NarrativeEventValidationSeverity.error => PokeMapDiagnosticSeverity.error,
    };

String _diagnosticTitle(NarrativeEventValidationSeverity severity) =>
    switch (severity) {
      NarrativeEventValidationSeverity.info => 'Information',
      NarrativeEventValidationSeverity.warning => 'À vérifier',
      NarrativeEventValidationSeverity.error => 'À corriger',
    };
