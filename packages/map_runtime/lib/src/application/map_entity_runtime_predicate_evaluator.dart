// Évaluation des prédicats PNJ (visibilité + variantes de dialogue).
//
// Sources de vérité runtime :
// - [GameState.storyFlags.activeFlags] pour flag set / unset ;
// - [PlayerProgression.completedStepIds] pour steps ;
// - [PlayerProgression.completedCutsceneIds] pour scénarios locaux terminés
//   (nœud `end` → reachedEnd) ;
// - [GlobalStoryChapterStepIndex] pour chapitres (toutes les steps du chapitre
//   doivent être complétées).
//
// Limites volontaires :
// - Pas d’évaluation « outcome » ou autre signal non persisté ici.
// - Les ids sont ceux du projet (authoring) ; l’éditeur doit les choisir en liste.

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart' show partyHasAtLeastUsableMembers;

import 'global_story_chapter_runtime.dart';

class MapEntityRuntimePredicateEvaluator {
  MapEntityRuntimePredicateEvaluator({
    required this.gameState,
    required this.chapterIndex,
    this.localMinuteOfDay,
  });

  final GameState gameState;
  final GlobalStoryChapterStepIndex chapterIndex;
  final int? localMinuteOfDay;

  // `late final` et non des getters : chaque évaluation de prédicat
  // reconstruisait ces Sets depuis les listes de progression, pour chaque
  // variante de dialogue et chaque PNJ.
  late final Set<String> _flags = gameState.storyFlags.activeFlags;

  late final Set<String> _completedSteps = gameState
      .progression
      .completedStepIds
      .toSet();

  late final Set<String> _completedCutscenes = gameState
      .progression
      .completedCutsceneIds
      .toSet();

  /// Évalue un prédicat auteur (une condition atomique).
  bool evaluatePredicate(MapEntityRuntimePredicate predicate) {
    if (predicate.kind == MapEntityRuntimePredicateKind.partyUsableCountAtLeast) {
      final minimum = predicate.minimumCount;
      return predicate.refId.isEmpty && predicate.timeWindow == null && minimum != null &&
          partyHasAtLeastUsableMembers(gameState.party, minimum);
    }
    if (predicate.minimumCount != null) return false;
    if (predicate.kind == MapEntityRuntimePredicateKind.localTimeWindow) {
      return predicate.refId.isEmpty &&
          predicate.timeWindow != null &&
          localMinuteOfDay != null &&
          predicate.timeWindow!.contains(localMinuteOfDay!);
    }
    if (predicate.timeWindow != null) return false;
    final ref = predicate.refId.trim();
    if (ref.isEmpty) {
      return false;
    }
    return switch (predicate.kind) {
      MapEntityRuntimePredicateKind.partyUsableCountAtLeast => false,
      MapEntityRuntimePredicateKind.localTimeWindow => false,
      MapEntityRuntimePredicateKind.badgeOwned =>
        gameState.trainerProfile.badgeIds.contains(ref),
      MapEntityRuntimePredicateKind.badgeNotOwned =>
        !gameState.trainerProfile.badgeIds.contains(ref),
      MapEntityRuntimePredicateKind.storyFlagSet => _flags.contains(ref),
      MapEntityRuntimePredicateKind.storyFlagUnset => !_flags.contains(ref),
      MapEntityRuntimePredicateKind.stepCompleted => _completedSteps.contains(
        ref,
      ),
      MapEntityRuntimePredicateKind.stepNotCompleted =>
        !_completedSteps.contains(ref),
      MapEntityRuntimePredicateKind.chapterCompleted =>
        chapterIndex.isChapterCompleted(ref, _completedSteps),
      MapEntityRuntimePredicateKind.chapterNotCompleted =>
        chapterIndex.isChapterNotCompleted(ref, _completedSteps),
      MapEntityRuntimePredicateKind.cutsceneCompleted =>
        _completedCutscenes.contains(ref),
      MapEntityRuntimePredicateKind.cutsceneNotCompleted =>
        !_completedCutscenes.contains(ref),
    };
  }

  /// Le PNJ doit exister sur la grille (collision + interaction + rendu logique).
  ///
  /// - Pas de règle ou mode [MapEntityNpcVisibilityMode.always] → visible.
  /// - [MapEntityNpcVisibilityMode.visibleWhen] → visible si le prédicat est vrai.
  /// - [MapEntityNpcVisibilityMode.hiddenWhen] → visible si le prédicat est faux.
  bool isNpcPresentOnMap(MapEntity entity) {
    if (entity.kind != MapEntityKind.npc) {
      return true;
    }
    final npc = entity.npc;
    if (npc == null) {
      return true;
    }
    final rule = npc.visibilityRule;
    if (rule == null || rule.mode == MapEntityNpcVisibilityMode.always) {
      return true;
    }
    final pred = rule.predicate;
    if (pred == null) {
      // Donnée invalide côté authoring ; comportement sûr : masquer.
      return false;
    }
    if (pred.timeWindow != null &&
        pred.kind != MapEntityRuntimePredicateKind.localTimeWindow) {
      return false;
    }
    if (pred.kind == MapEntityRuntimePredicateKind.localTimeWindow &&
        (pred.refId.isNotEmpty ||
            pred.timeWindow?.isValid != true ||
            localMinuteOfDay == null ||
            localMinuteOfDay! < 0 ||
            localMinuteOfDay! >= 1440)) {
      return false;
    }
    if (pred.minimumCount != null && pred.kind != MapEntityRuntimePredicateKind.partyUsableCountAtLeast) return false;
    if (pred.kind == MapEntityRuntimePredicateKind.partyUsableCountAtLeast &&
        (pred.refId.isNotEmpty || pred.timeWindow != null || pred.minimumCount == null || pred.minimumCount! < 1 || pred.minimumCount! > maxPlayerPartySize)) {return false;}
    final satisfied = evaluatePredicate(pred);
    return switch (rule.mode) {
      MapEntityNpcVisibilityMode.always => true,
      MapEntityNpcVisibilityMode.visibleWhen => satisfied,
      MapEntityNpcVisibilityMode.hiddenWhen => !satisfied,
    };
  }

  /// Résolution dialogue : **première variante dont la condition est vraie**,
  /// sinon [MapEntityNpcData.dialogue] (peut être null).
  DialogueRef? resolveNpcDialogue(MapEntityNpcData npc) {
    for (final row in npc.conditionalDialogues) {
      if (evaluatePredicate(row.when)) {
        return row.dialogue;
      }
    }
    return npc.dialogue;
  }
}
