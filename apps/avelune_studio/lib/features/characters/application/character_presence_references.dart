import 'package:map_core/map_core_domain.dart';

enum CharacterPresenceSubject { step, state, badge }

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

class CharacterPresenceReferenceLoader {
  CharacterPresenceReferenceLoader({required this.ready, required this.load});

  final bool Function() ready;
  final Future<void> Function() load;
  String? requestedFor;
  bool failed = false;
  bool _disposed = false;

  Future<void> request(String entityId, {required bool needed}) async {
    if (_disposed || !needed || ready() || requestedFor == entityId) return;
    requestedFor = entityId;
    try {
      await load();
    } on Object {
      if (!_disposed) failed = true;
    }
  }

  void dispose() => _disposed = true;
}
