import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

enum CharacterPresenceSubject { step, state, badge }

class CharacterReferenceScope extends InheritedWidget {
  const CharacterReferenceScope({
    super.key,
    required this.ready,
    required this.load,
    this.openInteractionScene,
    required super.child,
  });

  final bool Function() ready;
  final Future<void> Function() load;
  final Future<void> Function(MapEntity entity)? openInteractionScene;

  static CharacterReferenceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CharacterReferenceScope>();

  @override
  bool updateShouldNotify(CharacterReferenceScope oldWidget) =>
      ready != oldWidget.ready ||
      load != oldWidget.load ||
      openInteractionScene != oldWidget.openInteractionScene;
}

final class CharacterPresenceReference {
  const CharacterPresenceReference({
    required this.key,
    required this.refId,
    required this.label,
    this.detail,
  });
  final String key, refId, label;
  final String? detail;
}

final class CharacterPresenceReferences {
  CharacterPresenceReferences(
    this.project, {
    this.ready = true,
    this.failed = false,
  });
  final ProjectManifest project;
  final bool ready, failed;

  late final List<CharacterPresenceReference> steps = [
    for (final story in project.storylines)
      for (final chapter in story.chapters)
        for (final step in chapter.steps)
          CharacterPresenceReference(
            key: step.id,
            refId: step.id,
            label: step.title,
            detail: '${story.title} · ${chapter.title}',
          ),
  ];

  late final List<CharacterPresenceReference> states = [
    for (final fact in project.facts)
      if (fact.valueKind == NarrativeValueKind.boolean &&
          project.facts.where((value) => value.id == fact.id).length == 1 &&
          project.facts
                  .where(
                    (value) =>
                        (value.legacyFlagName ?? value.id) ==
                        (fact.legacyFlagName ?? fact.id),
                  )
                  .length ==
              1)
        CharacterPresenceReference(
          key: fact.id,
          refId: fact.legacyFlagName ?? fact.id,
          label: fact.label,
          detail: fact.category.isEmpty ? null : fact.category,
        ),
  ];

  late final List<CharacterPresenceReference> badges = [
    for (final badge in project.badges)
      if (badge.id.trim().isNotEmpty)
        CharacterPresenceReference(
          key: badge.id,
          refId: badge.id,
          label: badge.label,
        ),
  ];

  List<CharacterPresenceReference> of(CharacterPresenceSubject subject) =>
      switch (subject) {
        CharacterPresenceSubject.step => steps,
        CharacterPresenceSubject.state => states,
        CharacterPresenceSubject.badge => badges,
      };

  CharacterPresenceReference? resolve(MapEntityRuntimePredicate predicate) {
    final subject = characterPresenceSubject(predicate.kind);
    if (subject == null) return null;
    return of(subject)
        .where((reference) => reference.refId == predicate.refId)
        .firstOrNull;
  }

  ({String phrase, bool missing}) describe(
    MapEntityRuntimePredicate predicate,
  ) {
    final reference = resolve(predicate);
    final id = predicate.refId;
    String named(String? label) => label != null
        ? '« $label »'
        : ready
        ? '« $id » (introuvable)'
        : '« $id »';
    final scenario = project.scenarios
        .where((value) => value.id == id)
        .firstOrNull;
    final window = predicate.timeWindow;
    final phrase = switch (predicate.kind) {
      MapEntityRuntimePredicateKind.stepCompleted =>
        'l’étape ${named(reference?.label)} est terminée',
      MapEntityRuntimePredicateKind.stepNotCompleted =>
        'l’étape ${named(reference?.label)} n’est pas encore terminée',
      MapEntityRuntimePredicateKind.storyFlagSet =>
        'l’état ${named(reference?.label)} est activé',
      MapEntityRuntimePredicateKind.storyFlagUnset =>
        'l’état ${named(reference?.label)} est désactivé',
      MapEntityRuntimePredicateKind.badgeOwned =>
        'le badge ${named(reference?.label)} est obtenu',
      MapEntityRuntimePredicateKind.badgeNotOwned =>
        'le badge ${named(reference?.label)} n’est pas encore obtenu',
      MapEntityRuntimePredicateKind.chapterCompleted =>
        'le chapitre « $id » est terminé',
      MapEntityRuntimePredicateKind.chapterNotCompleted =>
        'le chapitre « $id » n’est pas encore terminé',
      MapEntityRuntimePredicateKind.cutsceneCompleted =>
        'la cinématique « ${scenario?.name ?? id} » a été jouée',
      MapEntityRuntimePredicateKind.cutsceneNotCompleted =>
        'la cinématique « ${scenario?.name ?? id} » n’a pas encore été jouée',
      MapEntityRuntimePredicateKind.partyUsableCountAtLeast =>
        'l’équipe compte au moins ${predicate.minimumCount ?? '?'} Pokémon aptes au combat',
      MapEntityRuntimePredicateKind.localTimeWindow =>
        window == null
            ? 'l’heure du jeu est dans une plage non définie'
            : 'l’heure du jeu est entre ${_clock(window.startMinute)} et ${_clock(window.endMinute)}',
    };
    final missing =
        ready &&
        characterPresenceSubject(predicate.kind) != null &&
        reference == null;
    return (phrase: phrase, missing: missing);
  }
}

String _clock(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

CharacterPresenceSubject? characterPresenceSubject(
  MapEntityRuntimePredicateKind kind,
) => switch (kind) {
  MapEntityRuntimePredicateKind.stepCompleted ||
  MapEntityRuntimePredicateKind.stepNotCompleted =>
    CharacterPresenceSubject.step,
  MapEntityRuntimePredicateKind.storyFlagSet ||
  MapEntityRuntimePredicateKind.storyFlagUnset =>
    CharacterPresenceSubject.state,
  MapEntityRuntimePredicateKind.badgeOwned ||
  MapEntityRuntimePredicateKind.badgeNotOwned => CharacterPresenceSubject.badge,
  _ => null,
};

bool isCharacterStoryPresence(MapEntityNpcVisibilityRule? rule) {
  final predicate = rule?.predicate;
  return rule != null &&
      predicate != null &&
      rule.mode != MapEntityNpcVisibilityMode.always &&
      characterPresenceSubject(predicate.kind) != null &&
      predicate.timeWindow == null &&
      predicate.minimumCount == null;
}

String characterPresenceSentence(
  MapEntityNpcVisibilityMode mode,
  String phrase,
) => switch (mode) {
  MapEntityNpcVisibilityMode.always => 'Dans le jeu : toujours présent.',
  MapEntityNpcVisibilityMode.visibleWhen =>
    'Dans le jeu : présent seulement quand $phrase.',
  MapEntityNpcVisibilityMode.hiddenWhen =>
    'Dans le jeu : absent dès que $phrase.',
};

const _conditionLabels = {
  'stepCompleted': 'L’étape d’histoire est terminée',
  'stepNotCompleted': 'L’étape d’histoire n’est pas encore terminée',
  'storyFlagSet': 'L’état d’histoire est activé',
  'storyFlagUnset': 'L’état d’histoire est désactivé',
  'badgeOwned': 'Le badge est obtenu',
  'badgeNotOwned': 'Le badge n’est pas encore obtenu',
};

class CharacterStoryPresenceEditor extends StatefulWidget {
  const CharacterStoryPresenceEditor({
    super.key,
    required this.prefix,
    required this.references,
    required this.mode,
    required this.kind,
    required this.refId,
    required this.onChanged,
    required this.onDraft,
  });

  final String prefix;
  final CharacterPresenceReferences references;
  final MapEntityNpcVisibilityMode mode;
  final MapEntityRuntimePredicateKind kind;
  final String? refId;
  final ValueChanged<MapEntityNpcVisibilityRule> onChanged;
  final void Function(
    MapEntityNpcVisibilityMode mode,
    MapEntityRuntimePredicateKind kind,
  )
  onDraft;

  @override
  State<CharacterStoryPresenceEditor> createState() =>
      _CharacterStoryPresenceEditorState();
}

class _CharacterStoryPresenceEditorState
    extends State<CharacterStoryPresenceEditor> {
  final _search = TextEditingController();
  var _query = '';
  bool? _testMet;

  static const _limit = 30;

  @override
  void didUpdateWidget(CharacterStoryPresenceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (characterPresenceSubject(oldWidget.kind) !=
        characterPresenceSubject(widget.kind)) {
      _search.clear();
      _query = '';
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  MapEntityNpcVisibilityRule _rule(
    MapEntityNpcVisibilityMode mode,
    MapEntityRuntimePredicateKind kind,
    String refId,
  ) => MapEntityNpcVisibilityRule(
    mode: mode,
    predicate: MapEntityRuntimePredicate(kind: kind, refId: refId),
  );

  void _changeKind(MapEntityRuntimePredicateKind kind) {
    final refId = widget.refId;
    if (refId != null &&
        characterPresenceSubject(kind) ==
            characterPresenceSubject(widget.kind)) {
      widget.onChanged(_rule(widget.mode, kind, refId));
    } else {
      widget.onDraft(widget.mode, kind);
    }
  }

  void _changeMode(MapEntityNpcVisibilityMode mode) {
    final refId = widget.refId;
    if (refId != null) {
      widget.onChanged(_rule(mode, widget.kind, refId));
    } else {
      widget.onDraft(mode, widget.kind);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.prefix;
    final subject = characterPresenceSubject(widget.kind)!;
    final source = widget.references.of(subject);
    final refId = widget.refId;
    final predicate = refId == null
        ? null
        : MapEntityRuntimePredicate(kind: widget.kind, refId: refId);
    final description = predicate == null
        ? null
        : widget.references.describe(predicate);
    final needle = _query.trim().toLowerCase();
    final matches = [
      for (final reference in source)
        if (needle.isEmpty ||
            '${reference.label} ${reference.detail ?? ''} ${reference.refId}'
                .toLowerCase()
                .contains(needle))
          reference,
    ];
    final (subjectName, article) = switch (subject) {
      CharacterPresenceSubject.step => ('étape d’histoire', 'une'),
      CharacterPresenceSubject.state => ('état d’histoire', 'un'),
      CharacterPresenceSubject.badge => ('badge', 'un'),
    };
    final textTheme = Theme.of(context).textTheme;
    if (!widget.references.ready) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          widget.references.failed
              ? 'Les étapes, états et badges du projet n’ont pas pu être chargés. La règle reste inchangée.'
              : 'Chargement des étapes, états et badges du projet…',
          key: ValueKey('$prefix-loading'),
        ),
      );
    }
    final met = _testMet ?? true;
    final present =
        met == (widget.mode == MapEntityNpcVisibilityMode.visibleWhen);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        StudioSelect(
          key: ValueKey('$prefix-effect'),
          label: 'Effet sur la carte',
          value: widget.mode.name,
          options: const {
            'visibleWhen': 'Présent seulement si…',
            'hiddenWhen': 'Absent dès que…',
          },
          onChanged: (value) =>
              _changeMode(MapEntityNpcVisibilityMode.values.byName(value)),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: ValueKey('$prefix-condition'),
          label: 'Condition',
          value: widget.kind.name,
          options: _conditionLabels,
          onChanged: (value) =>
              _changeKind(MapEntityRuntimePredicateKind.values.byName(value)),
        ),
        const SizedBox(height: 12),
        if (refId == null)
          Text(
            'Choisissez $article $subjectName ci-dessous. Rien n’est enregistré avant ce choix.',
            key: ValueKey('$prefix-pending'),
          )
        else if (description!.missing)
          StudioNotice(
            key: ValueKey('$prefix-missing'),
            'Référence introuvable conservée : $refId. Elle reste enregistrée tant que vous n’en choisissez pas une autre.',
            isError: true,
          ),
        const SizedBox(height: 8),
        if (source.isEmpty)
          Text(
            'Aucun${article == 'une' ? 'e' : ''} $subjectName dans ce projet.',
          )
        else ...[
          StudioSearchField(
            key: ValueKey('$prefix-search'),
            controller: _search,
            label: 'Rechercher $article $subjectName',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 6),
          for (final reference in matches.take(_limit))
            StudioChoice(
              key: ValueKey('$prefix-ref-${reference.key}'),
              label: reference.label,
              subtitle: reference.detail,
              selected: reference.refId == refId,
              onTap: () => widget.onChanged(
                _rule(widget.mode, widget.kind, reference.refId),
              ),
            ),
          if (matches.isEmpty) const Text('Aucun résultat.'),
          if (matches.length > _limit)
            Text(
              '${matches.length - _limit} autres résultats : précisez la recherche.',
              style: textTheme.bodySmall,
            ),
        ],
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            characterPresenceSentence(widget.mode, description.phrase),
            key: ValueKey('$prefix-result'),
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text('Tester la règle', style: textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              StudioChoice(
                key: ValueKey('$prefix-test-met'),
                dense: true,
                label: 'Condition remplie',
                selected: met,
                onTap: () => setState(() => _testMet = true),
              ),
              StudioChoice(
                key: ValueKey('$prefix-test-unmet'),
                dense: true,
                label: 'Condition non remplie',
                selected: !met,
                onTap: () => setState(() => _testMet = false),
              ),
            ],
          ),
          Text(
            present ? 'Le personnage est présent sur la carte.' : 'Le personnage est absent : il ne bloque pas le passage et ne peut pas être abordé.',
            key: ValueKey('$prefix-test-outcome'),
          ),
        ],
      ],
    );
  }
}

class CharacterDialogueVariants extends StatelessWidget {
  const CharacterDialogueVariants({
    super.key,
    required this.entity,
    required this.references,
  });

  final MapEntity entity;
  final CharacterPresenceReferences references;

  @override
  Widget build(BuildContext context) {
    final npc = entity.npc!;
    final dialogues = {
      for (final dialogue in references.project.dialogues)
        dialogue.id: dialogue.name,
    };
    String dialogueLabel(String id) => dialogues[id] != null
        ? '« ${dialogues[id]} »'
        : references.ready
        ? 'Dialogue introuvable conservé : $id'
        : '« $id »';
    final fallback = npc.dialogue?.dialogueId;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Text('Variantes de dialogue', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Testées dans l’ordre : la première condition remplie l’emporte. Elles sont conservées telles quelles ; ce panneau ne les modifie pas.',
          style: textTheme.bodySmall,
        ),
        for (final (index, variant) in npc.conditionalDialogues.indexed)
          Padding(
            key: ValueKey('npc-${entity.id}-dialogue-variant-$index'),
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${index + 1}. Si ${references.describe(variant.when).phrase} : ${dialogueLabel(variant.dialogue.dialogueId)}',
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            fallback == null || fallback.isEmpty
                ? 'Sinon : aucun dialogue.'
                : 'Sinon : dialogue habituel ${dialogueLabel(fallback)}.',
          ),
        ),
      ],
    );
  }
}
