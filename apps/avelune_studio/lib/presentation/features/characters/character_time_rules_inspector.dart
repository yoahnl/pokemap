import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_time_window.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'character_presence_rule.dart';

class CharacterTimeRulesInspector extends StatefulWidget {
  const CharacterTimeRulesInspector({
    super.key,
    required this.entity,
    required this.project,
    required this.mapName,
    required this.onReadinessChanged,
    required this.onVisibilityChanged,
    required this.onBattleChanged,
  });

  final MapEntity entity;
  final ProjectManifest project;
  final String mapName;
  final void Function(MapEntityRuntimePredicate?, DialogueRef?)
  onReadinessChanged;
  final ValueChanged<MapEntityNpcVisibilityRule?> onVisibilityChanged;
  final ValueChanged<MapEntityRuntimePredicate?> onBattleChanged;

  @override
  State<CharacterTimeRulesInspector> createState() =>
      _CharacterTimeRulesInspectorState();
}

class _CharacterTimeRulesInspectorState
    extends State<CharacterTimeRulesInspector> {
  ({MapEntityNpcVisibilityMode mode, MapEntityRuntimePredicateKind kind})?
  _storyDraft;
  CharacterPresenceReferences? _references;

  MapEntity get entity => widget.entity;
  List<ProjectDialogueEntry> get dialogues => widget.project.dialogues;

  CharacterPresenceReferences get references {
    final cached = _references;
    if (cached != null && identical(cached.project, widget.project)) {
      return cached;
    }
    return _references = CharacterPresenceReferences(widget.project);
  }

  @override
  void didUpdateWidget(CharacterTimeRulesInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.id != widget.entity.id) _storyDraft = null;
  }

  void _setVisibility(MapEntityNpcVisibilityRule? rule) {
    setState(() => _storyDraft = null);
    widget.onVisibilityChanged(rule);
  }

  @override
  Widget build(BuildContext context) {
    final npc = entity.npc!;
    final rule = npc.visibilityRule;
    final presence =
        rule == null || rule.mode == MapEntityNpcVisibilityMode.always
        ? null
        : rule.predicate;
    final presenceIsHours =
        rule?.mode == MapEntityNpcVisibilityMode.visibleWhen &&
        _isHours(presence);
    final storyDraft = _storyDraft;
    final storyRule = isCharacterStoryPresence(rule);
    final presenceMode = storyDraft != null || storyRule
        ? 'story'
        : rule == null || rule.mode == MapEntityNpcVisibilityMode.always
        ? 'always'
        : presenceIsHours
        ? 'hours'
        : 'advanced';
    final character = widget.project.characters
        .where((entry) => entry.id == npc.characterId)
        .firstOrNull;
    final battle = npc.trainerBattleWhen;
    final battleMode = battle == null
        ? 'always'
        : _isHours(battle)
        ? 'hours'
        : 'advanced';
    return StudioPanel(
      compact: true,
      title: 'Conditions du personnage',
      children: [
        _rule(
          prefix: 'npc-${entity.id}-presence',
          label: 'Présence sur la carte',
          mode: presenceMode,
          alwaysLabel: 'Toujours présent',
          hoursLabel: 'Présent pendant une plage horaire',
          storyLabel: 'Selon l’histoire (étape, état ou badge)',
          advancedDescription: rule?.predicate == null
              ? null
              : characterPresenceSentence(
                  rule!.mode,
                  references.describe(rule.predicate!).phrase,
                ),
          window: presenceIsHours ? presence!.timeWindow : null,
          onModeChanged: (mode) {
            if (mode == 'story') {
              if (!storyRule) {
                setState(
                  () => _storyDraft = (
                    mode: MapEntityNpcVisibilityMode.visibleWhen,
                    kind: MapEntityRuntimePredicateKind.stepCompleted,
                  ),
                );
              }
              return;
            }
            _setVisibility(
              mode == 'always'
                  ? null
                  : MapEntityNpcVisibilityRule(
                      mode: MapEntityNpcVisibilityMode.visibleWhen,
                      predicate: _predicate(
                        presence?.timeWindow ?? _defaultWindow,
                      ),
                    ),
            );
          },
          onWindowChanged: (start, end) => _setVisibility(
            MapEntityNpcVisibilityRule(
              mode: MapEntityNpcVisibilityMode.visibleWhen,
              predicate: _predicate(
                LocalTimeWindow(startMinute: start, endMinute: end),
              ),
            ),
          ),
        ),
        if (presenceMode == 'story')
          CharacterStoryPresenceEditor(
            key: ValueKey('npc-${entity.id}-story-presence'),
            prefix: 'npc-${entity.id}-presence',
            references: references,
            mode: storyDraft?.mode ?? rule!.mode,
            kind: storyDraft?.kind ?? rule!.predicate!.kind,
            refId: storyDraft == null ? rule!.predicate!.refId : null,
            onChanged: _setVisibility,
            onDraft: (mode, kind) =>
                setState(() => _storyDraft = (mode: mode, kind: kind)),
          ),
        const SizedBox(height: 8),
        Text(
          'Règle propre à ce personnage sur « ${widget.mapName} ». '
          'Le personnage réutilisable « ${character?.name ?? npc.characterId ?? 'sans ressource'} » n’est pas modifié.',
          key: ValueKey('npc-${entity.id}-presence-origin'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (npc.trainerId != null) ...[
          const SizedBox(height: 18),
          _rule(
            prefix: 'npc-${entity.id}-battle',
            label: 'Combat de dresseur',
            mode: battleMode,
            alwaysLabel: 'À toute heure',
            hoursLabel: 'Pendant une plage horaire',
            advancedDescription: null,
            window: _isHours(battle) ? battle!.timeWindow : null,
            onModeChanged: (mode) => widget.onBattleChanged(
              mode == 'always'
                  ? null
                  : _predicate(battle?.timeWindow ?? _defaultWindow),
            ),
            onWindowChanged: (start, end) => widget.onBattleChanged(
              _predicate(LocalTimeWindow(startMinute: start, endMinute: end)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'En dehors de cet horaire, le personnage utilise son dialogue habituel et ne défie pas le joueur.',
          ),
          const SizedBox(height: 18),
          ..._readiness(npc),
        ],
        if (npc.conditionalDialogues.isNotEmpty)
          CharacterDialogueVariants(entity: entity, references: references),
      ],
    );
  }

  List<Widget> _readiness(MapEntityNpcData npc) {
    final rule = npc.trainerBattleReadyWhen;
    final countRule =
        rule?.kind == MapEntityRuntimePredicateKind.partyUsableCountAtLeast;
    final mode = rule == null
        ? 'always'
        : countRule
        ? 'party'
        : 'advanced';
    final minimum = countRule ? rule!.minimumCount! : 2;
    final refusal = npc.trainerBattleNotReadyDialogue;
    MapEntityRuntimePredicate condition(int count) => MapEntityRuntimePredicate(
      kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
      minimumCount: count,
    );
    return [
      StudioSelect(
        key: ValueKey('npc-${entity.id}-readiness-mode'),
        label: 'Condition pour commencer le combat',
        value: mode,
        options: {
          'always': 'Aucune condition d’aptitude',
          'party': 'Minimum de Pokémon aptes au combat',
          if (mode == 'advanced') 'advanced': 'Règle avancée conservée',
        },
        onChanged: (value) {
          if (value == 'advanced') return;
          widget.onReadinessChanged(
            value == 'always' ? null : condition(minimum),
            value == 'always' ? null : refusal,
          );
        },
      ),
      if (countRule) ...[
        const SizedBox(height: 12),
        StudioSelect(
          key: ValueKey('npc-${entity.id}-readiness-minimum'),
          label: 'Pokémon aptes requis',
          value: '$minimum',
          options: {
            for (var count = 1; count <= 6; count++) '$count': '$count',
          },
          onChanged: (value) =>
              widget.onReadinessChanged(condition(int.parse(value)), refusal),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: ValueKey('npc-${entity.id}-readiness-refusal'),
          label: 'Dialogue si l’équipe n’est pas prête',
          value: refusal?.dialogueId ?? '',
          options: {
            '': 'Aucun dialogue : le combat reste bloqué',
            if (refusal != null &&
                !dialogues.any((d) => d.id == refusal.dialogueId))
              refusal.dialogueId: 'Dialogue conservé : ${refusal.dialogueId}',
            for (final dialogue in dialogues) dialogue.id: dialogue.name,
          },
          onChanged: (value) => widget.onReadinessChanged(
            rule,
            value.isEmpty
                ? null
                : value == refusal?.dialogueId
                ? refusal
                : DialogueRef(dialogueId: value),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Seuls les Pokémon avec au moins 1 PV comptent. Après une victoire contre ce dresseur, son dialogue de fin de combat reste utilisé.',
        ),
      ],
    ];
  }

  static const _defaultWindow = LocalTimeWindow(
    startMinute: 480,
    endMinute: 1200,
  );

  bool _isHours(MapEntityRuntimePredicate? predicate) =>
      predicate?.kind == MapEntityRuntimePredicateKind.localTimeWindow &&
      predicate?.timeWindow?.isValid == true;

  MapEntityRuntimePredicate _predicate(LocalTimeWindow window) =>
      MapEntityRuntimePredicate(
        kind: MapEntityRuntimePredicateKind.localTimeWindow,
        timeWindow: window,
      );

  Widget _rule({
    required String prefix,
    required String label,
    required String mode,
    required String alwaysLabel,
    required String hoursLabel,
    String? storyLabel,
    required String? advancedDescription,
    required LocalTimeWindow? window,
    required ValueChanged<String> onModeChanged,
    required void Function(int, int) onWindowChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSelect(
        key: ValueKey('$prefix-mode'),
        label: label,
        value: mode,
        options: {
          'always': alwaysLabel,
          'hours': hoursLabel,
          'story': ?storyLabel,
          if (mode == 'advanced') 'advanced': 'Règle avancée conservée',
        },
        onChanged: (value) {
          if (value != 'advanced') onModeChanged(value);
        },
      ),
      if (mode == 'advanced') ...[
        const SizedBox(height: 8),
        Text(
          [
            ?advancedDescription,
            'Cette règle avancée reste inchangée. Choisissez un autre mode uniquement pour la remplacer.',
          ].join(' '),
          key: ValueKey('$prefix-advanced'),
        ),
      ],
      if (window != null) ...[
        const SizedBox(height: 12),
        StudioTimeWindow(
          fieldKeyPrefix: '$prefix-window',
          startMinute: window.startMinute,
          endMinute: window.endMinute,
          onChanged: onWindowChanged,
        ),
      ],
    ],
  );
}
