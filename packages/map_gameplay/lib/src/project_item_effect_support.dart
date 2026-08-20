import 'package:map_core/map_core.dart';

/// Ce que le runtime bêta sait réellement exécuter d'un effet d'objet.
///
/// BETA-ITM-007, critère « unsupported effect UI ». Deux effets sont
/// AUTHORABLES SANS ÊTRE EXÉCUTABLES : `repel` (FG-065, explicitement DEFERRED
/// hors MVP) et `semanticAction`, qui est une porte de sortie vers une action
/// nommée que le moteur bêta ne résout pas. Un auteur pouvait donc fabriquer une
/// Repousse dans l'Item Studio et la voir échouer en silence à l'usage, avec
/// `PlayerItemUseFailure.unsupportedCapability`.
///
/// Le verdict était écrit QUATRE FOIS — une fois ici dans map_gameplay, trois
/// fois dans map_runtime — donc quatre occasions de dériver. Ce fichier en fait
/// la source unique, et l'éditeur lit exactement la même.
enum ProjectItemEffectRuntimeSupport {
  /// Le runtime applique cet effet.
  supported,

  /// Le runtime refuse cet effet, quel que soit le contexte.
  ///
  /// L'auteur doit le savoir AVANT de livrer, pas au premier playtest.
  unsupported,
}

/// Verdict de support pour un effet d'objet.
///
/// `ProjectItemEffectDefinition` n'est pas `sealed`, donc le compilateur ne peut
/// PAS exiger l'exhaustivité ici — le `_` final est imposé par le langage, pas
/// choisi. Il retombe sur `unsupported`, ce qui est le repli sûr : un effet
/// inconnu doit être annoncé comme inexécutable, jamais promis.
///
/// Ce que le compilateur ne garantit pas, un test le garantit :
/// `project_item_effect_support_test` énumère les six sous-classes du modèle et
/// exige un verdict pour chacune, donc en ajouter une septième sans décider fait
/// échouer la suite au lieu de la classer inexécutable en silence.
ProjectItemEffectRuntimeSupport projectItemEffectRuntimeSupport(
  ProjectItemEffectDefinition effect,
) {
  return switch (effect) {
    ProjectItemHealHpEffectDefinition() ||
    ProjectItemCureStatusEffectDefinition() ||
    ProjectItemReviveEffectDefinition() ||
    ProjectItemRestorePpEffectDefinition() =>
      ProjectItemEffectRuntimeSupport.supported,
    ProjectItemRepelEffectDefinition() ||
    ProjectItemSemanticActionEffectDefinition() =>
      ProjectItemEffectRuntimeSupport.unsupported,
    _ => ProjectItemEffectRuntimeSupport.unsupported,
  };
}

/// Raison lisible par un auteur, ou `null` quand l'effet est exécutable.
///
/// Le texte s'adresse à quelqu'un qui construit un objet dans l'éditeur, pas à
/// un développeur : il dit ce qui va se passer et pourquoi, sans code d'erreur.
String? projectItemEffectUnsupportedReason(
  ProjectItemEffectDefinition effect,
) {
  return switch (effect) {
    ProjectItemHealHpEffectDefinition() ||
    ProjectItemCureStatusEffectDefinition() ||
    ProjectItemReviveEffectDefinition() ||
    ProjectItemRestorePpEffectDefinition() =>
      null,
    ProjectItemRepelEffectDefinition() =>
      'La Repousse est hors du périmètre de la bêta : l’objet sera authorable '
          'mais restera sans effet en jeu.',
    ProjectItemSemanticActionEffectDefinition() =>
      'Une action sémantique nommée n’est pas résolue par le moteur de la bêta : '
          'l’objet restera sans effet en jeu.',
    _ => 'Cet effet n’est pas exécutable par le moteur de la bêta : l’objet '
        'restera sans effet en jeu.',
  };
}
