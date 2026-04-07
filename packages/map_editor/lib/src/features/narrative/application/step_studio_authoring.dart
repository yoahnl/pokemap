import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// Schéma de document utilisé par le Step Studio v1.
///
/// Ce marqueur sert à:
/// - reconnaître les scénarios globaux déjà migrés vers un authoring Step v1;
/// - permettre des migrations non destructives plus tard;
/// - éviter de confondre ce document avec d'anciens metadata `step.*`.
const String kStepStudioSchemaVersion = 'step_studio_v1';

/// Clé metadata qui indique la version de schéma Step Studio.
const String kStepStudioSchemaMetadataKey = 'authoring.stepStudioSchema';

/// Clé metadata qui stocke le document Step Studio sérialisé en JSON.
const String kStepStudioDocumentMetadataKey = 'authoring.stepStudioDocument';

/// Modes d'activation d'une step (quand elle devient active).
///
/// On garde un vocabulaire "métier" et lisible plutôt que des noeuds
/// techniques, afin que l'éditeur reste no-code / low-code.
enum StepStudioActivationMode {
  atGameStart,
  afterPreviousStep,
  afterStep,
  afterOutcome,
  afterCutscene,
  whenFlagTrue,
}

String stepStudioActivationModeLabel(StepStudioActivationMode mode) {
  return switch (mode) {
    StepStudioActivationMode.atGameStart => 'Au début du jeu',
    StepStudioActivationMode.afterPreviousStep => 'Après l’étape précédente',
    StepStudioActivationMode.afterStep => 'Après une étape précise',
    StepStudioActivationMode.afterOutcome =>
      'Après un résultat pour l’histoire',
    StepStudioActivationMode.afterCutscene => 'Après une scène',
    StepStudioActivationMode.whenFlagTrue =>
      'Quand un état du monde est vrai',
  };
}

/// Modes de fin d’étape : condition enregistrée (quand elle est terminée).
enum StepStudioCompletionMode {
  whenCutsceneEnds,
  whenOutcomeEmitted,
  whenInteractionDone,
  whenFlagTrue,
  manual,
}

String stepStudioCompletionModeLabel(StepStudioCompletionMode mode) {
  return switch (mode) {
    StepStudioCompletionMode.whenCutsceneEnds =>
      'Quand une scène se termine',
    StepStudioCompletionMode.whenOutcomeEmitted =>
      'Quand un résultat est obtenu',
    StepStudioCompletionMode.whenInteractionDone =>
      'Quand une interaction clé a eu lieu',
    StepStudioCompletionMode.whenFlagTrue =>
      'Quand un état du monde est vrai',
    StepStudioCompletionMode.manual => 'Manuellement',
  };
}

/// Rôle d'une cutscene liée à une step.
///
/// On explicite la responsabilité de chaque scène pour éviter
/// "cutscene = step", ce qui était justement le problème produit.
enum StepStudioCutsceneRole {
  kickoff,
  main,
  completion,
  optional,
}

String stepStudioCutsceneRoleLabel(StepStudioCutsceneRole role) {
  return switch (role) {
    StepStudioCutsceneRole.kickoff => 'Scène de démarrage',
    StepStudioCutsceneRole.main => 'Scène principale',
    StepStudioCutsceneRole.completion => 'Scène qui conclut l’étape',
    StepStudioCutsceneRole.optional => 'Scène optionnelle',
  };
}

/// Catégorie créateur d’un résultat (libellés UI : étape / histoire / état monde).
enum StepStudioOutcomeScope {
  local,
  progression,
  world,
}

String stepStudioOutcomeScopeLabel(StepStudioOutcomeScope scope) {
  return switch (scope) {
    StepStudioOutcomeScope.local => 'Résultat de cette étape',
    StepStudioOutcomeScope.progression => 'Résultat pour l’histoire',
    StepStudioOutcomeScope.world => 'État du monde',
  };
}

/// Règles de présence persistante d'une entité après la step.
///
/// Exemple produit:
/// - Emma dehors visible avant la fin de l’étape.
/// - Emma labo visible après la fin de l’étape.
enum StepStudioPresenceRule {
  visibleBeforeStepCompletion,
  visibleAfterStepCompletion,
  hiddenAfterStepCompletion,
  visibleOnlyWhenCompleted,
}

String stepStudioPresenceRuleLabel(StepStudioPresenceRule rule) {
  return switch (rule) {
    StepStudioPresenceRule.visibleBeforeStepCompletion =>
      'Visible avant la fin de cette étape',
    StepStudioPresenceRule.visibleAfterStepCompletion =>
      'Visible après la fin de cette étape',
    StepStudioPresenceRule.hiddenAfterStepCompletion =>
      'Masquée après la fin de cette étape',
    StepStudioPresenceRule.visibleOnlyWhenCompleted =>
      'Visible seulement quand cette étape est terminée',
  };
}

/// Règle d'activation de step.
@immutable
class StepStudioActivationRule {
  const StepStudioActivationRule({
    required this.mode,
    this.stepId,
    this.outcomeId,
    this.cutsceneId,
    this.flagName,
  });

  final StepStudioActivationMode mode;
  final String? stepId;
  final String? outcomeId;
  final String? cutsceneId;
  final String? flagName;

  StepStudioActivationRule copyWith({
    StepStudioActivationMode? mode,
    Object? stepId = _unset,
    Object? outcomeId = _unset,
    Object? cutsceneId = _unset,
    Object? flagName = _unset,
  }) {
    return StepStudioActivationRule(
      mode: mode ?? this.mode,
      stepId: identical(stepId, _unset) ? this.stepId : stepId as String?,
      outcomeId:
          identical(outcomeId, _unset) ? this.outcomeId : outcomeId as String?,
      cutsceneId: identical(cutsceneId, _unset)
          ? this.cutsceneId
          : cutsceneId as String?,
      flagName:
          identical(flagName, _unset) ? this.flagName : flagName as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mode': mode.name,
        'stepId': stepId,
        'outcomeId': outcomeId,
        'cutsceneId': cutsceneId,
        'flagName': flagName,
      };

  factory StepStudioActivationRule.fromJson(Map<String, dynamic> json) {
    return StepStudioActivationRule(
      mode: _parseActivationMode(
        json['mode']?.toString(),
        fallback: StepStudioActivationMode.atGameStart,
      ),
      stepId: _trimOrNull(json['stepId']),
      outcomeId: _trimOrNull(json['outcomeId']),
      cutsceneId: _trimOrNull(json['cutsceneId']),
      flagName: _trimOrNull(json['flagName']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepStudioActivationRule &&
        other.mode == mode &&
        other.stepId == stepId &&
        other.outcomeId == outcomeId &&
        other.cutsceneId == cutsceneId &&
        other.flagName == flagName;
  }

  @override
  int get hashCode =>
      Object.hash(mode, stepId, outcomeId, cutsceneId, flagName);
}

/// Règle de validation de step.
@immutable
class StepStudioCompletionRule {
  const StepStudioCompletionRule({
    required this.mode,
    this.cutsceneId,
    this.outcomeId,
    this.interactionId,
    this.flagName,
  });

  final StepStudioCompletionMode mode;
  final String? cutsceneId;
  final String? outcomeId;
  final String? interactionId;
  final String? flagName;

  StepStudioCompletionRule copyWith({
    StepStudioCompletionMode? mode,
    Object? cutsceneId = _unset,
    Object? outcomeId = _unset,
    Object? interactionId = _unset,
    Object? flagName = _unset,
  }) {
    return StepStudioCompletionRule(
      mode: mode ?? this.mode,
      cutsceneId: identical(cutsceneId, _unset)
          ? this.cutsceneId
          : cutsceneId as String?,
      outcomeId:
          identical(outcomeId, _unset) ? this.outcomeId : outcomeId as String?,
      interactionId: identical(interactionId, _unset)
          ? this.interactionId
          : interactionId as String?,
      flagName:
          identical(flagName, _unset) ? this.flagName : flagName as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mode': mode.name,
        'cutsceneId': cutsceneId,
        'outcomeId': outcomeId,
        'interactionId': interactionId,
        'flagName': flagName,
      };

  factory StepStudioCompletionRule.fromJson(Map<String, dynamic> json) {
    return StepStudioCompletionRule(
      mode: _parseCompletionMode(
        json['mode']?.toString(),
        fallback: StepStudioCompletionMode.manual,
      ),
      cutsceneId: _trimOrNull(json['cutsceneId']),
      outcomeId: _trimOrNull(json['outcomeId']),
      interactionId: _trimOrNull(json['interactionId']),
      flagName: _trimOrNull(json['flagName']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepStudioCompletionRule &&
        other.mode == mode &&
        other.cutsceneId == cutsceneId &&
        other.outcomeId == outcomeId &&
        other.interactionId == interactionId &&
        other.flagName == flagName;
  }

  @override
  int get hashCode =>
      Object.hash(mode, cutsceneId, outcomeId, interactionId, flagName);
}

/// Référence de cutscene liée à une step.
@immutable
class StepStudioCutsceneLink {
  const StepStudioCutsceneLink({
    required this.cutsceneId,
    required this.role,
  });

  final String cutsceneId;
  final StepStudioCutsceneRole role;

  StepStudioCutsceneLink copyWith({
    String? cutsceneId,
    StepStudioCutsceneRole? role,
  }) {
    return StepStudioCutsceneLink(
      cutsceneId: cutsceneId ?? this.cutsceneId,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cutsceneId': cutsceneId,
        'role': role.name,
      };

  factory StepStudioCutsceneLink.fromJson(Map<String, dynamic> json) {
    return StepStudioCutsceneLink(
      cutsceneId: _trimOrEmpty(json['cutsceneId']),
      role: _parseCutsceneRole(
        json['role']?.toString(),
        fallback: StepStudioCutsceneRole.main,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepStudioCutsceneLink &&
        other.cutsceneId == cutsceneId &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(cutsceneId, role);
}

/// Résultat métier émis par la step.
@immutable
class StepStudioOutcomeDefinition {
  const StepStudioOutcomeDefinition({
    required this.label,
    required this.scope,
    required this.outcomeId,
  });

  final String label;
  final StepStudioOutcomeScope scope;

  /// Identifiant technique (généré) exposé en lecture dans l'UI.
  final String outcomeId;

  StepStudioOutcomeDefinition copyWith({
    String? label,
    StepStudioOutcomeScope? scope,
    String? outcomeId,
  }) {
    return StepStudioOutcomeDefinition(
      label: label ?? this.label,
      scope: scope ?? this.scope,
      outcomeId: outcomeId ?? this.outcomeId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'scope': scope.name,
        'outcomeId': outcomeId,
      };

  factory StepStudioOutcomeDefinition.fromJson(Map<String, dynamic> json) {
    return StepStudioOutcomeDefinition(
      label: _trimOrEmpty(json['label']),
      scope: _parseOutcomeScope(
        json['scope']?.toString(),
        fallback: StepStudioOutcomeScope.progression,
      ),
      outcomeId: _trimOrEmpty(json['outcomeId']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepStudioOutcomeDefinition &&
        other.label == label &&
        other.scope == scope &&
        other.outcomeId == outcomeId;
  }

  @override
  int get hashCode => Object.hash(label, scope, outcomeId);
}

/// Changement persistant de présence d'entité piloté par la progression.
@immutable
class StepStudioWorldChange {
  const StepStudioWorldChange({
    required this.mapId,
    required this.entityId,
    required this.presenceRule,
    this.note,
  });

  final String mapId;
  final String entityId;
  final StepStudioPresenceRule presenceRule;
  final String? note;

  StepStudioWorldChange copyWith({
    String? mapId,
    String? entityId,
    StepStudioPresenceRule? presenceRule,
    Object? note = _unset,
  }) {
    return StepStudioWorldChange(
      mapId: mapId ?? this.mapId,
      entityId: entityId ?? this.entityId,
      presenceRule: presenceRule ?? this.presenceRule,
      note: identical(note, _unset) ? this.note : note as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mapId': mapId,
        'entityId': entityId,
        'presenceRule': presenceRule.name,
        'note': note,
      };

  factory StepStudioWorldChange.fromJson(Map<String, dynamic> json) {
    return StepStudioWorldChange(
      mapId: _trimOrEmpty(json['mapId']),
      entityId: _trimOrEmpty(json['entityId']),
      presenceRule: _parsePresenceRule(
        json['presenceRule']?.toString(),
        fallback: StepStudioPresenceRule.visibleAfterStepCompletion,
      ),
      note: _trimOrNull(json['note']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepStudioWorldChange &&
        other.mapId == mapId &&
        other.entityId == entityId &&
        other.presenceRule == presenceRule &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(mapId, entityId, presenceRule, note);
}

/// Objet métier central d'une step (schéma d’authoring Step Studio v1).
///
/// ---------------------------------------------------------------------------
/// Deux familles de champs (ne pas les confondre — voir rapport consolidation §3)
/// ---------------------------------------------------------------------------
///
/// **A. Données structurées « intentionnelles »** — ce que le moteur ou la
/// projection narrative pourront un jour consommer directement (aujourd’hui
/// encore majoritairement côté éditeur, mais ce sont les seuls champs avec une
/// sémantique technique explicite : modes, IDs, listes typées) :
/// - [activation], [completion]
/// - [cutscenes] (références par id)
/// - [outcomes] (labels + `outcomeId` + scope)
/// - [worldChanges]
/// - [id], [name], [description], [order]
///
/// **B. Annotations d’affichage / mémo auteur** — persistées dans le JSON du
/// document pour Step Studio (surtout canvas pour `flow*Label`, inspecteur pour
/// le mémo `flowUnlocksStepId`), **sans autre consommateur**
/// dans ce dépôt : ni `map_gameplay`, ni `map_runtime`, ni les résumés de step
/// de la projection narrative (ces champs n’y figurent pas).
/// Ce ne sont **pas** des garde-fous runtime : ne pas en déduire une règle de
/// déblocage ou de validation exécutable tant qu’aucun pipeline ne les lit.
/// - [flowEntryLabel], [flowObjectiveLabel], [flowValidationLabel],
///   [flowExitLabel] : texte libre pour lisibilité no-code sur le canvas.
/// - [flowUnlocksStepId] : mémo éditeur uniquement (id d’une autre step du
///   même document). **Aucun effet** sur le runtime dans ce dépôt. Préférence
///   UX (passe 3) : affiché et édité surtout dans l’inspecteur « Notes sortie »,
///   pas sur le canvas central — pour limiter l’illusion de « lien actif ».
///
/// [flowObjectiveLabel] peut recouper [description] : la description reste la
/// fiche générale ; le libellé flux est optionnel et sert surtout au canvas.
@immutable
class StepStudioStep {
  const StepStudioStep({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.activation,
    required this.completion,
    this.cutscenes = const <StepStudioCutsceneLink>[],
    this.outcomes = const <StepStudioOutcomeDefinition>[],
    this.worldChanges = const <StepStudioWorldChange>[],
    this.flowEntryLabel = '',
    this.flowObjectiveLabel = '',
    this.flowValidationLabel = '',
    this.flowExitLabel = '',
    this.flowUnlocksStepId,
  });

  final String id;
  final String name;
  final String description;
  final int order;
  final StepStudioActivationRule activation;
  final StepStudioCompletionRule completion;
  final List<StepStudioCutsceneLink> cutscenes;
  final List<StepStudioOutcomeDefinition> outcomes;
  final List<StepStudioWorldChange> worldChanges;

  // ---------------------------------------------------------------------------
  // Annotations canvas / mémo auteur (famille B — voir doc de classe)
  // ---------------------------------------------------------------------------
  //
  // Uniquement : sérialisation JSON + affichage Step Studio. Pas de lecture
  // gameplay dans ce repo. Ne pas traiter comme « vérité runtime ».
  //
  // Vocabulaire UI (fil, variante, phrase…) = confort créateur ; les noms de
  // propriétés Dart / clés JSON restent `flow*` pour stabilité des sauvegardes.

  /// Note auteur sur le canvas : « quand cette étape commence » (langage humain).
  /// Le résumé technique affiché à côté vient de [activation], pas de ce texte.
  final String flowEntryLabel;

  /// Ligne optionnelle sur le canvas pour l’objectif ; la fiche step utilise
  /// aussi [name] et [description]. Redondance volontairement possible.
  final String flowObjectiveLabel;

  /// Note auteur : ce que la créatrice entend par « c’est validé ».
  /// La condition exécutable documentée est [completion] (+ outcomes associés).
  final String flowValidationLabel;

  /// Note auteur : conséquence narrative / design (texte libre), **sans** effet
  /// sur le graphe. À ne pas confondre avec [flowUnlocksStepId].
  final String flowExitLabel;

  /// Mémo éditeur : id d’une autre step du même document. Pas de branchement
  /// automatique. Canvas Step (passe 3) : ne montre que [flowExitLabel] ; ce
  /// champ se règle dans l’inspecteur pour éviter la confusion avec un déblocage.
  final String? flowUnlocksStepId;

  StepStudioStep copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    StepStudioActivationRule? activation,
    StepStudioCompletionRule? completion,
    List<StepStudioCutsceneLink>? cutscenes,
    List<StepStudioOutcomeDefinition>? outcomes,
    List<StepStudioWorldChange>? worldChanges,
    String? flowEntryLabel,
    String? flowObjectiveLabel,
    String? flowValidationLabel,
    String? flowExitLabel,
    Object? flowUnlocksStepId = _unset,
  }) {
    return StepStudioStep(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      activation: activation ?? this.activation,
      completion: completion ?? this.completion,
      cutscenes: cutscenes ?? this.cutscenes,
      outcomes: outcomes ?? this.outcomes,
      worldChanges: worldChanges ?? this.worldChanges,
      flowEntryLabel: flowEntryLabel ?? this.flowEntryLabel,
      flowObjectiveLabel: flowObjectiveLabel ?? this.flowObjectiveLabel,
      flowValidationLabel: flowValidationLabel ?? this.flowValidationLabel,
      flowExitLabel: flowExitLabel ?? this.flowExitLabel,
      flowUnlocksStepId: identical(flowUnlocksStepId, _unset)
          ? this.flowUnlocksStepId
          : flowUnlocksStepId as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'order': order,
        'activation': activation.toJson(),
        'completion': completion.toJson(),
        'cutscenes': cutscenes.map((entry) => entry.toJson()).toList(),
        'outcomes': outcomes.map((entry) => entry.toJson()).toList(),
        'worldChanges': worldChanges.map((entry) => entry.toJson()).toList(),
        'flowEntryLabel': flowEntryLabel,
        'flowObjectiveLabel': flowObjectiveLabel,
        'flowValidationLabel': flowValidationLabel,
        'flowExitLabel': flowExitLabel,
        'flowUnlocksStepId': flowUnlocksStepId,
      };

  factory StepStudioStep.fromJson(Map<String, dynamic> json) {
    final cutsceneJson = (json['cutscenes'] as List<dynamic>? ?? const []);
    final outcomeJson = (json['outcomes'] as List<dynamic>? ?? const []);
    final worldChangeJson =
        (json['worldChanges'] as List<dynamic>? ?? const []);
    return StepStudioStep(
      id: _trimOrEmpty(json['id']),
      name: _trimOrEmpty(json['name']),
      description: _trimOrEmpty(json['description']),
      order: (json['order'] as num?)?.toInt() ?? 0,
      activation: StepStudioActivationRule.fromJson(
        (json['activation'] as Map<String, dynamic>? ?? const {}),
      ),
      completion: StepStudioCompletionRule.fromJson(
        (json['completion'] as Map<String, dynamic>? ?? const {}),
      ),
      cutscenes: cutsceneJson
          .whereType<Map<String, dynamic>>()
          .map(StepStudioCutsceneLink.fromJson)
          .where((entry) => entry.cutsceneId.trim().isNotEmpty)
          .toList(growable: false),
      outcomes: outcomeJson
          .whereType<Map<String, dynamic>>()
          .map(StepStudioOutcomeDefinition.fromJson)
          .where((entry) =>
              entry.label.trim().isNotEmpty ||
              entry.outcomeId.trim().isNotEmpty)
          .toList(growable: false),
      // Ne pas exiger `entityId` non vide : l’UI peut persister une ligne
      // « brouillon » (map choisie, entité pas encore resélectionnée après
      // changement de map, etc.). Filtrer ici faisait disparaître ces lignes
      // après save + réhydratation alors qu’elles étaient bien dans le JSON.
      worldChanges: worldChangeJson
          .whereType<Map<String, dynamic>>()
          .map(StepStudioWorldChange.fromJson)
          .where((entry) => entry.mapId.trim().isNotEmpty)
          .toList(growable: false),
      flowEntryLabel: _trimOrEmpty(json['flowEntryLabel']),
      flowObjectiveLabel: _trimOrEmpty(json['flowObjectiveLabel']),
      flowValidationLabel: _trimOrEmpty(json['flowValidationLabel']),
      flowExitLabel: _trimOrEmpty(json['flowExitLabel']),
      flowUnlocksStepId: _trimOrNull(json['flowUnlocksStepId']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepStudioStep &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.order == order &&
        other.activation == activation &&
        other.completion == completion &&
        listEquals(other.cutscenes, cutscenes) &&
        listEquals(other.outcomes, outcomes) &&
        listEquals(other.worldChanges, worldChanges) &&
        other.flowEntryLabel == flowEntryLabel &&
        other.flowObjectiveLabel == flowObjectiveLabel &&
        other.flowValidationLabel == flowValidationLabel &&
        other.flowExitLabel == flowExitLabel &&
        other.flowUnlocksStepId == flowUnlocksStepId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        order,
        activation,
        completion,
        Object.hashAll(cutscenes),
        Object.hashAll(outcomes),
        Object.hashAll(worldChanges),
        flowEntryLabel,
        flowObjectiveLabel,
        flowValidationLabel,
        flowExitLabel,
        flowUnlocksStepId,
      );
}

/// Document Step Studio v1 porté par le scénario global unique.
@immutable
class StepStudioDocument {
  const StepStudioDocument({
    required this.globalStoryScenarioId,
    required this.steps,
    this.schemaVersion = kStepStudioSchemaVersion,
  });

  final String schemaVersion;
  final String globalStoryScenarioId;
  final List<StepStudioStep> steps;

  StepStudioDocument copyWith({
    String? schemaVersion,
    String? globalStoryScenarioId,
    List<StepStudioStep>? steps,
  }) {
    return StepStudioDocument(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      globalStoryScenarioId:
          globalStoryScenarioId ?? this.globalStoryScenarioId,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'globalStoryScenarioId': globalStoryScenarioId,
        'steps': steps.map((entry) => entry.toJson()).toList(growable: false),
      };

  String toMetadataJson() => jsonEncode(toJson());

  factory StepStudioDocument.fromJson(Map<String, dynamic> json) {
    final stepJson = (json['steps'] as List<dynamic>? ?? const []);
    final parsedSteps = stepJson
        .whereType<Map<String, dynamic>>()
        .map(StepStudioStep.fromJson)
        .where((entry) => entry.id.trim().isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
    return StepStudioDocument(
      schemaVersion:
          _trimOrNull(json['schemaVersion']) ?? kStepStudioSchemaVersion,
      globalStoryScenarioId:
          _trimOrNull(json['globalStoryScenarioId']) ?? 'global_story',
      steps: parsedSteps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepStudioDocument &&
        other.schemaVersion == schemaVersion &&
        other.globalStoryScenarioId == globalStoryScenarioId &&
        listEquals(other.steps, steps);
  }

  @override
  int get hashCode =>
      Object.hash(schemaVersion, globalStoryScenarioId, Object.hashAll(steps));
}

/// Résultat de parsing du document Step Studio.
@immutable
class StepStudioParseResult {
  const StepStudioParseResult({
    required this.document,
    required this.warnings,
    required this.usedLegacyFallback,
  });

  final StepStudioDocument document;
  final List<String> warnings;

  /// `true` quand le parseur a dû reconstruire la donnée à partir d'un
  /// fallback legacy (`step.*`) ou d'une valeur par défaut.
  final bool usedLegacyFallback;
}

/// Parse un scénario global vers le document Step Studio v1.
///
/// Stratégie:
/// 1) priorité au JSON `authoring.stepStudioDocument`,
/// 2) fallback legacy `step.*`,
/// 3) fallback minimal avec une step par défaut.
StepStudioParseResult parseStepStudioDocumentFromGlobalScenario(
  ScenarioAsset scenario,
) {
  final warnings = <String>[];

  if (scenario.scope != ScenarioScope.globalStory) {
    warnings.add(
      'Le Step Studio v1 est conçu pour un scénario de scope "globalStory".',
    );
  }

  final rawDocument = scenario.metadata[kStepStudioDocumentMetadataKey];
  if (rawDocument != null && rawDocument.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(rawDocument);
      if (decoded is Map<String, dynamic>) {
        final parsed = StepStudioDocument.fromJson(decoded);
        final normalized = _normalizeDocument(
          parsed.copyWith(globalStoryScenarioId: scenario.id),
        );
        return StepStudioParseResult(
          document: normalized,
          warnings: warnings,
          usedLegacyFallback: false,
        );
      }
      warnings.add(
        'Le document Step Studio metadata n\'est pas un objet JSON valide.',
      );
    } catch (error) {
      warnings.add(
        'Impossible de lire authoring.stepStudioDocument: $error',
      );
    }
  }

  final legacyStep = _legacyStepFromScenario(scenario);
  final fallback = StepStudioDocument(
    globalStoryScenarioId: scenario.id,
    steps: <StepStudioStep>[legacyStep],
  );
  return StepStudioParseResult(
    document: fallback,
    warnings: warnings,
    usedLegacyFallback: true,
  );
}

/// Applique un document Step Studio au scénario global canonique.
///
/// Ici on ne modifie pas le graphe runtime du scénario global: on enrichit
/// sa metadata d'authoring (responsabilité "éditeur"), de manière non
/// destructive et rétrocompatible avec l'existant.
ScenarioAsset applyStepStudioDocumentToGlobalScenario(
  ScenarioAsset scenario,
  StepStudioDocument document,
) {
  final normalized = _normalizeDocument(
    document.copyWith(globalStoryScenarioId: scenario.id),
  );
  final traceRows = <String>[];
  for (final step in normalized.steps) {
    for (final change in step.worldChanges) {
      traceRows.add(
        'step=${step.id}|map=${change.mapId}|entity=${change.entityId}|rule=${change.presenceRule.name}',
      );
    }
  }
  debugPrint(
    '[step_studio_trace] action=apply_document scenario=${scenario.id} rows=[${traceRows.join(';')}]',
  );
  final nextMetadata = <String, String>{
    ...scenario.metadata,
    kStepStudioSchemaMetadataKey: kStepStudioSchemaVersion,
    kStepStudioDocumentMetadataKey: normalized.toMetadataJson(),
  };
  final blob = nextMetadata[kStepStudioDocumentMetadataKey] ?? '';
  debugPrint(
    '[step_studio_trace] action=apply_document_metadata scenario=${scenario.id} contains_emma=${blob.contains("\"entityId\":\"emma\"")} contains_empty_entity=${blob.contains("\"entityId\":\"\"")}',
  );

  // Rétrocompatibilité UI/projection legacy:
  // on continue d'exposer la "première step" via `step.*`.
  if (normalized.steps.isNotEmpty) {
    final first = normalized.steps.first;
    nextMetadata['step.id'] = first.id;
    nextMetadata['step.name'] = first.name;
    nextMetadata['step.description'] = first.description;
    nextMetadata['step.cutsceneIds'] =
        first.cutscenes.map((entry) => entry.cutsceneId).join(',');
  } else {
    nextMetadata.remove('step.id');
    nextMetadata.remove('step.name');
    nextMetadata.remove('step.description');
    nextMetadata.remove('step.cutsceneIds');
  }

  return scenario.copyWith(metadata: nextMetadata);
}

/// Fabrique un document Step Studio minimal pour bootstrap no-code.
StepStudioDocument createDefaultStepStudioDocument({
  required String globalStoryScenarioId,
}) {
  final step = StepStudioStep(
    id: 'step_intro',
    name: 'Introduction',
    description: 'Première étape du scénario principal.',
    order: 0,
    activation: const StepStudioActivationRule(
      mode: StepStudioActivationMode.atGameStart,
    ),
    completion: const StepStudioCompletionRule(
      mode: StepStudioCompletionMode.manual,
    ),
  );
  return StepStudioDocument(
    globalStoryScenarioId: globalStoryScenarioId,
    steps: <StepStudioStep>[step],
  );
}

/// Génère un id de step lisible et unique.
String generateUniqueStepId(
  String seed, {
  required Iterable<String> existingIds,
}) {
  final base = _normalizeIdentifier(seed, fallback: 'step');
  var candidate = base;
  var index = 1;
  final existing = existingIds.toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$index';
    index++;
  }
  return candidate;
}

/// Génère un outcome id lisible sans demander d'ID technique brut à l'utilisateur.
String generateOutcomeIdFromLabel({
  required String stepId,
  required String label,
  required StepStudioOutcomeScope scope,
}) {
  final scopePrefix = switch (scope) {
    StepStudioOutcomeScope.local => 'local',
    StepStudioOutcomeScope.progression => 'progression',
    StepStudioOutcomeScope.world => 'world',
  };
  final normalizedLabel = _normalizeIdentifier(label, fallback: 'result');
  final normalizedStep = _normalizeIdentifier(stepId, fallback: 'step');
  return '$scopePrefix.$normalizedStep.$normalizedLabel';
}

String summarizeStepActivation(StepStudioStep step) {
  final activation = step.activation;
  return switch (activation.mode) {
    StepStudioActivationMode.atGameStart => 'Démarre au lancement du jeu',
    StepStudioActivationMode.afterPreviousStep =>
      'Démarre après l’étape précédente',
    StepStudioActivationMode.afterStep =>
      'Démarre après l’étape "${activation.stepId ?? '—'}"',
    StepStudioActivationMode.afterOutcome =>
      'Démarre après le résultat "${activation.outcomeId ?? '—'}"',
    StepStudioActivationMode.afterCutscene =>
      'Démarre après la scène "${activation.cutsceneId ?? '—'}"',
    StepStudioActivationMode.whenFlagTrue =>
      'Démarre quand "${activation.flagName ?? 'state'}" est vrai',
  };
}

String summarizeStepCompletion(StepStudioStep step) {
  final completion = step.completion;
  return switch (completion.mode) {
    StepStudioCompletionMode.whenCutsceneEnds =>
      'Se termine quand la scène "${completion.cutsceneId ?? '—'}" est finie',
    StepStudioCompletionMode.whenOutcomeEmitted =>
      'Se termine quand le résultat "${completion.outcomeId ?? '—'}" est obtenu',
    StepStudioCompletionMode.whenInteractionDone =>
      'Se termine après l’interaction "${completion.interactionId ?? '—'}"',
    StepStudioCompletionMode.whenFlagTrue =>
      'Se termine quand "${completion.flagName ?? 'state'}" est vrai',
    StepStudioCompletionMode.manual => 'Se termine manuellement',
  };
}

StepStudioStep _legacyStepFromScenario(ScenarioAsset scenario) {
  final metadata = scenario.metadata;
  final legacyId = _trimOrNull(metadata['step.id']) ?? '${scenario.id}_step';
  final legacyName = _trimOrNull(metadata['step.name']) ?? scenario.name;
  final legacyDescription = _trimOrNull(metadata['step.description']) ??
      (scenario.description.trim().isEmpty
          ? 'Étape dérivée du scénario global.'
          : scenario.description);

  final linkedCutsceneIds = _parseCsv(_trimOrNull(metadata['step.cutsceneIds']))
      .toList(growable: false);
  final cutscenes = linkedCutsceneIds
      .map(
        (cutsceneId) => StepStudioCutsceneLink(
          cutsceneId: cutsceneId,
          role: StepStudioCutsceneRole.main,
        ),
      )
      .toList(growable: false);

  final outcomes = scenario.declaredOutcomes
      .where((entry) => entry.trim().isNotEmpty)
      .map(
        (entry) => StepStudioOutcomeDefinition(
          label: entry,
          scope: StepStudioOutcomeScope.progression,
          outcomeId: entry,
        ),
      )
      .toList(growable: false);

  final completion = linkedCutsceneIds.isNotEmpty
      ? StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenCutsceneEnds,
          cutsceneId: linkedCutsceneIds.first,
        )
      : outcomes.isNotEmpty
          ? StepStudioCompletionRule(
              mode: StepStudioCompletionMode.whenOutcomeEmitted,
              outcomeId: outcomes.first.outcomeId,
            )
          : const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual);

  return StepStudioStep(
    id: _normalizeIdentifier(legacyId, fallback: '${scenario.id}_step'),
    name: legacyName.trim().isEmpty ? scenario.name : legacyName,
    description: legacyDescription,
    order: 0,
    activation: const StepStudioActivationRule(
      mode: StepStudioActivationMode.atGameStart,
    ),
    completion: completion,
    cutscenes: cutscenes,
    outcomes: outcomes,
    worldChanges: const <StepStudioWorldChange>[],
  );
}

StepStudioDocument _normalizeDocument(StepStudioDocument document) {
  // Normalisation défensive:
  // - IDs non vides + uniques,
  // - tri par order,
  // - labels/outcomes nettoyés,
  // - outcomeId auto-généré si absent.
  final usedStepIds = <String>{};
  final normalizedSteps = <StepStudioStep>[];

  final sorted = document.steps.toList(growable: false)
    ..sort((a, b) => a.order.compareTo(b.order));

  for (var index = 0; index < sorted.length; index++) {
    final step = sorted[index];
    final stepId = generateUniqueStepId(
      step.id.isEmpty ? step.name : step.id,
      existingIds: usedStepIds,
    );
    usedStepIds.add(stepId);

    final normalizedOutcomes = <StepStudioOutcomeDefinition>[];
    final usedOutcomeIds = <String>{};
    for (final outcome in step.outcomes) {
      final label = outcome.label.trim();
      if (label.isEmpty && outcome.outcomeId.trim().isEmpty) {
        continue;
      }
      final rawOutcomeId = outcome.outcomeId.trim().isEmpty
          ? generateOutcomeIdFromLabel(
              stepId: stepId,
              label: label.isEmpty ? 'result' : label,
              scope: outcome.scope,
            )
          : outcome.outcomeId.trim();
      var uniqueOutcomeId = rawOutcomeId;
      var suffix = 1;
      while (usedOutcomeIds.contains(uniqueOutcomeId)) {
        uniqueOutcomeId = '${rawOutcomeId}_$suffix';
        suffix++;
      }
      usedOutcomeIds.add(uniqueOutcomeId);
      normalizedOutcomes.add(
        outcome.copyWith(
          label: label.isEmpty ? uniqueOutcomeId : label,
          outcomeId: uniqueOutcomeId,
        ),
      );
    }

    var normalizedCompletion = step.completion;
    if (normalizedCompletion.mode == StepStudioCompletionMode.manual &&
        _trimOrNull(normalizedCompletion.cutsceneId) == null &&
        _trimOrNull(normalizedCompletion.outcomeId) == null &&
        _trimOrNull(normalizedCompletion.interactionId) == null &&
        _trimOrNull(normalizedCompletion.flagName) == null) {
      String? inferredCutsceneId;
      for (final link in step.cutscenes) {
        final cid = link.cutsceneId.trim();
        if (cid.isEmpty) {
          continue;
        }
        if (link.role == StepStudioCutsceneRole.main) {
          inferredCutsceneId = cid;
          break;
        }
        inferredCutsceneId ??= cid;
      }
      if (inferredCutsceneId != null) {
        normalizedCompletion = StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenCutsceneEnds,
          cutsceneId: inferredCutsceneId,
        );
        debugPrint(
          '[step_studio_trace] action=normalize_completion_autofix step=$stepId mode=manual->whenCutsceneEnds cutsceneId=$inferredCutsceneId',
        );
      }
    }

    normalizedSteps.add(
      step.copyWith(
        id: stepId,
        name: step.name.trim().isEmpty ? 'Step ${index + 1}' : step.name.trim(),
        description: step.description.trim(),
        order: index,
        outcomes: normalizedOutcomes,
        flowEntryLabel: step.flowEntryLabel.trim(),
        flowObjectiveLabel: step.flowObjectiveLabel.trim(),
        flowValidationLabel: step.flowValidationLabel.trim(),
        flowExitLabel: step.flowExitLabel.trim(),
        flowUnlocksStepId: _trimOrNull(step.flowUnlocksStepId),
        completion: normalizedCompletion,
      ),
    );
  }

  return document.copyWith(
    schemaVersion: kStepStudioSchemaVersion,
    steps: normalizedSteps,
  );
}

/// Validation défensive juste avant persistance du document Step Studio.
///
/// Invariant produit: une ligne `worldChanges` qui cible une map (mapId non vide)
/// doit cibler explicitement une entité (`entityId` non vide), sinon la règle
/// est ambiguë et ne peut pas être appliquée correctement par le runtime.
///
/// Cette validation est volontairement découplée de la normalisation:
/// - normaliser = rendre la forme stable/idempotente,
/// - valider = refuser les états métier incomplets.
List<String> validateStepStudioDocumentForPersistence(
  StepStudioDocument document,
) {
  final errors = <String>[];
  for (final step in document.steps) {
    for (final change in step.worldChanges) {
      final mapId = change.mapId.trim();
      final entityId = change.entityId.trim();
      if (mapId.isEmpty) {
        continue;
      }
      if (entityId.isNotEmpty) {
        continue;
      }
      errors.add(
        'step=${step.id}: worldChange mapId="$mapId" exige un entityId non vide.',
      );
    }
  }
  return errors;
}

StepStudioActivationMode _parseActivationMode(
  String? raw, {
  required StepStudioActivationMode fallback,
}) {
  for (final mode in StepStudioActivationMode.values) {
    if (mode.name == raw) {
      return mode;
    }
  }
  return fallback;
}

StepStudioCompletionMode _parseCompletionMode(
  String? raw, {
  required StepStudioCompletionMode fallback,
}) {
  for (final mode in StepStudioCompletionMode.values) {
    if (mode.name == raw) {
      return mode;
    }
  }
  return fallback;
}

StepStudioCutsceneRole _parseCutsceneRole(
  String? raw, {
  required StepStudioCutsceneRole fallback,
}) {
  for (final role in StepStudioCutsceneRole.values) {
    if (role.name == raw) {
      return role;
    }
  }
  return fallback;
}

StepStudioOutcomeScope _parseOutcomeScope(
  String? raw, {
  required StepStudioOutcomeScope fallback,
}) {
  for (final scope in StepStudioOutcomeScope.values) {
    if (scope.name == raw) {
      return scope;
    }
  }
  return fallback;
}

StepStudioPresenceRule _parsePresenceRule(
  String? raw, {
  required StepStudioPresenceRule fallback,
}) {
  for (final rule in StepStudioPresenceRule.values) {
    if (rule.name == raw) {
      return rule;
    }
  }
  return fallback;
}

String _normalizeIdentifier(String raw, {required String fallback}) {
  final normalized = raw
      .trim()
      .toLowerCase()
      // On conserve volontairement le point pour rester rétrocompatible
      // avec des IDs historiques de type `step.professor_intro`.
      .replaceAll(RegExp(r'[^a-z0-9_.]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'\.+'), '.')
      .replaceAll(RegExp(r'^[_.]|[_.]$'), '');
  return normalized.isEmpty ? fallback : normalized;
}

String? _trimOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String _trimOrEmpty(Object? value) => _trimOrNull(value) ?? '';

Iterable<String> _parseCsv(String? raw) sync* {
  if (raw == null || raw.trim().isEmpty) {
    return;
  }
  for (final token in raw.split(',')) {
    final value = token.trim();
    if (value.isNotEmpty) {
      yield value;
    }
  }
}

const Object _unset = Object();
