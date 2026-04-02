import 'package:map_core/map_core.dart';

/// IMPORTANT:
/// Le graphe scénario de l’éditeur est aujourd’hui une surface d’authoring.
/// Depuis le bridge MVP, une partie du graphe est consommée en runtime
/// (sources map/trigger/entity + exécution linéaire simple).
///
/// On conserve une constante centralisée pour éviter de disséminer des
/// booléens magiques dans les widgets / diagnostics.
const bool kScenarioGraphRuntimeExecutionConnected = true;

/// Niveau de support runtime d'un preset d'authoring.
///
/// Cette information permet d'être honnête côté UX :
/// - runtimeReady : exécuté réellement aujourd'hui.
/// - authoringBridge : utile pour structurer/lier le flow, sans exécution
///   directe garantie.
/// - planned : intention produit non finalisée côté runtime.
enum ScenarioPresetRuntimeSupport {
  runtimeReady,
  authoringBridge,
  planned,
}

enum ScenarioActionField {
  message,
  script,
  dialogue,
  map,
  event,
  entity,
  warp,
  trigger,
  trainer,
  flagName,
  variableName,
  variableValue,
}

/// Lecture "métier" d’un node pour guider l’interface utilisateur.
///
/// Cette catégorisation ne remplace pas [ScenarioNodeType] : elle fournit
/// une intention lisible "Blueprint-like" dans l’inspecteur.
enum ScenarioNodeIntent {
  source,
  condition,
  effect,
  dialogue,
  choice,
  end,
}

/// État d’exécution affiché dans l’UI.
///
/// - runtimeConnected: exécuté automatiquement par le runtime scénario.
/// - runtimeCapableNotConnected: correspond à une capacité runtime connue
///   (dialogue/script/combat/etc.) mais non branchée automatiquement au graphe.
/// - authoringBridge: sert de pont d’authoring/documentation.
/// - planned: intention future non finalisée.
enum ScenarioNodeExecutionState {
  runtimeConnected,
  runtimeCapableNotConnected,
  authoringBridge,
  planned,
}

class ScenarioActionPreset {
  const ScenarioActionPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.executionHint,
    this.runtimeSupport = ScenarioPresetRuntimeSupport.runtimeReady,
    this.fields = const <ScenarioActionField>{},
  });

  final String id;
  final String label;
  final String description;
  final String executionHint;
  final ScenarioPresetRuntimeSupport runtimeSupport;
  final Set<ScenarioActionField> fields;
}

String scenarioNodeTypeLabel(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start => 'Start',
    ScenarioNodeType.dialogue => 'Dialogue',
    ScenarioNodeType.action => 'Action',
    ScenarioNodeType.condition => 'Condition',
    ScenarioNodeType.choice => 'Choice',
    ScenarioNodeType.reference => 'Reference',
    ScenarioNodeType.end => 'End',
  };
}

String scenarioNodeTypeDescription(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start =>
      'Point d’entrée du scénario. Le flux commence ici.',
    ScenarioNodeType.dialogue =>
      'Affiche un dialogue ou lance une séquence dialoguée.',
    ScenarioNodeType.action => 'Déclenche une action gameplay ou narrative.',
    ScenarioNodeType.condition =>
      'Teste une condition puis redirige le flux selon le résultat.',
    ScenarioNodeType.choice =>
      'Propose un choix au joueur avec plusieurs branches.',
    ScenarioNodeType.reference =>
      'Pointe vers une ressource du projet ou un élément du monde.',
    ScenarioNodeType.end => 'Termine la séquence.',
  };
}

String scenarioNodeTypePickerLabel(ScenarioNodeType type) {
  return '${scenarioNodeTypeLabel(type)} — ${scenarioNodeTypeDescription(type)}';
}

String defaultScenarioNodeTitle(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start => 'Départ scénario',
    ScenarioNodeType.dialogue => 'Dialogue',
    ScenarioNodeType.action => 'Action',
    ScenarioNodeType.condition => 'Condition',
    ScenarioNodeType.choice => 'Choix',
    ScenarioNodeType.reference => 'Référence monde',
    ScenarioNodeType.end => 'Fin',
  };
}

const List<ScenarioActionPreset> scenarioActionPresets = <ScenarioActionPreset>[
  ScenarioActionPreset(
    id: 'showMessage',
    label: 'Afficher un message',
    description: 'Affiche un texte court directement dans la scène.',
    executionHint: 'Exécution simple, utile pour feedback joueur immédiat.',
    fields: {ScenarioActionField.message},
  ),
  ScenarioActionPreset(
    id: 'openDialogue',
    label: 'Ouvrir un dialogue',
    description: 'Lance une ressource de dialogue Yarn existante.',
    executionHint:
        'À privilégier pour les conversations. Requiert une ressource dialogue.',
    fields: {ScenarioActionField.dialogue},
  ),
  ScenarioActionPreset(
    id: 'runScript',
    label: 'Exécuter un script',
    description: 'Exécute un script scénario/runtime existant.',
    executionHint:
        'Idéal pour la logique procédurale. Requiert une ressource script.',
    fields: {ScenarioActionField.script},
  ),
  ScenarioActionPreset(
    id: 'startTrainerBattle',
    label: 'Démarrer un combat dresseur',
    description: 'Référence un dresseur pour enclencher un combat.',
    executionHint:
        'Réservé aux séquences de combat. Runtime graphe MVP: non exécuté automatiquement.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.trainer},
  ),
  ScenarioActionPreset(
    id: 'jumpToMapEvent',
    label: 'Cibler un event de map',
    description:
        'Liaison vers un event existant sur une map (jump/activation).',
    executionHint:
        'Authoring structurant : lie le scénario à un event monde existant.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map, ScenarioActionField.event},
  ),
  ScenarioActionPreset(
    id: 'triggerWarp',
    label: 'Utiliser un warp',
    description: 'Cible un warp existant sur la map sélectionnée.',
    executionHint: 'Authoring structurant : lie le flux à un warp de map.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map, ScenarioActionField.warp},
  ),
  ScenarioActionPreset(
    id: 'activateTrigger',
    label: 'Activer un trigger',
    description: 'Cible un trigger existant sur la map sélectionnée.',
    executionHint: 'Authoring structurant : lie le flux à un trigger existant.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map, ScenarioActionField.trigger},
  ),
  ScenarioActionPreset(
    id: 'referenceEntity',
    label: 'Cibler une entité',
    description: 'Référence une entité existante sur la map sélectionnée.',
    executionHint: 'Authoring structurant : pointe vers une entité du monde.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map, ScenarioActionField.entity},
  ),
  ScenarioActionPreset(
    id: 'setFlag',
    label: 'Activer un flag',
    description: 'Passe un story flag à true.',
    executionHint: 'Progression scénario classique.',
    fields: {ScenarioActionField.flagName},
  ),
  ScenarioActionPreset(
    id: 'clearFlag',
    label: 'Désactiver un flag',
    description: 'Passe un story flag à false.',
    executionHint: 'Rollback ou réinitialisation de progression.',
    fields: {ScenarioActionField.flagName},
  ),
  ScenarioActionPreset(
    id: 'custom',
    label: 'Custom / avancé',
    description:
        'Mode avancé. Permet de stocker un identifiant d’action personnalisé.',
    executionHint: 'À utiliser seulement si aucun preset standard ne convient.',
    runtimeSupport: ScenarioPresetRuntimeSupport.planned,
  ),
];

const List<ScenarioActionPreset> scenarioReferencePresets =
    <ScenarioActionPreset>[
  ScenarioActionPreset(
    id: 'referenceMap',
    label: 'Référence map',
    description: 'Pointe vers une map du projet.',
    executionHint: 'Documentation/lien explicite avec une map.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map},
  ),
  ScenarioActionPreset(
    id: 'sourceMapEnter',
    label: 'Déclencheur : entrée sur map',
    description: 'Point d’entrée déclenché quand le joueur arrive sur une map.',
    executionHint:
        'Source de flow orientée authoring. À relier vers une action ou un dialogue.',
    runtimeSupport: ScenarioPresetRuntimeSupport.runtimeReady,
    fields: {ScenarioActionField.map},
  ),
  ScenarioActionPreset(
    id: 'sourceTriggerEnter',
    label: 'Déclencheur : entrée dans zone/trigger',
    description:
        'Point d’entrée déclenché quand le joueur entre dans un trigger.',
    executionHint:
        'Source de flow orientée authoring. Choisis map + trigger existant.',
    runtimeSupport: ScenarioPresetRuntimeSupport.runtimeReady,
    fields: {ScenarioActionField.map, ScenarioActionField.trigger},
  ),
  ScenarioActionPreset(
    id: 'sourceEntityInteract',
    label: 'Déclencheur : interaction PNJ/entité',
    description: 'Point d’entrée déclenché lors d’une interaction avec entité.',
    executionHint:
        'Source de flow orientée authoring. Choisis map + entité cible.',
    runtimeSupport: ScenarioPresetRuntimeSupport.runtimeReady,
    fields: {ScenarioActionField.map, ScenarioActionField.entity},
  ),
  ScenarioActionPreset(
    id: 'referenceEvent',
    label: 'Référence event',
    description: 'Pointe vers un event d’une map donnée.',
    executionHint: 'Documentation/lien explicite avec un event.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map, ScenarioActionField.event},
  ),
  ScenarioActionPreset(
    id: 'referenceEntity',
    label: 'Référence entité',
    description: 'Pointe vers une entité d’une map donnée.',
    executionHint: 'Documentation/lien explicite avec une entité.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map, ScenarioActionField.entity},
  ),
  ScenarioActionPreset(
    id: 'referenceWarp',
    label: 'Référence warp',
    description: 'Pointe vers un warp d’une map donnée.',
    executionHint: 'Documentation/lien explicite avec un warp.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map, ScenarioActionField.warp},
  ),
  ScenarioActionPreset(
    id: 'referenceTrigger',
    label: 'Référence trigger',
    description: 'Pointe vers un trigger d’une map donnée.',
    executionHint: 'Documentation/lien explicite avec un trigger.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.map, ScenarioActionField.trigger},
  ),
  ScenarioActionPreset(
    id: 'referenceTrainer',
    label: 'Référence dresseur',
    description: 'Pointe vers un dresseur du projet.',
    executionHint: 'Documentation/lien explicite avec un dresseur.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.trainer},
  ),
  ScenarioActionPreset(
    id: 'referenceDialogue',
    label: 'Référence dialogue',
    description: 'Pointe vers un dialogue Yarn du projet.',
    executionHint: 'Documentation/lien explicite avec un dialogue.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.dialogue},
  ),
  ScenarioActionPreset(
    id: 'referenceScript',
    label: 'Référence script',
    description: 'Pointe vers un script scénario/runtime du projet.',
    executionHint: 'Documentation/lien explicite avec un script.',
    runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
    fields: {ScenarioActionField.script},
  ),
  ScenarioActionPreset(
    id: 'customReference',
    label: 'Custom / avancé',
    description: 'Référence personnalisée pour des besoins avancés.',
    executionHint:
        'À utiliser seulement si aucun preset de référence ne suffit.',
    runtimeSupport: ScenarioPresetRuntimeSupport.planned,
  ),
];

String scenarioRuntimeSupportLabel(ScenarioPresetRuntimeSupport support) {
  return switch (support) {
    ScenarioPresetRuntimeSupport.runtimeReady => 'Exécution runtime réelle',
    ScenarioPresetRuntimeSupport.authoringBridge =>
      'Authoring/orchestration (pont monde)',
    ScenarioPresetRuntimeSupport.planned => 'Préparation future',
  };
}

String scenarioNodeIntentLabel(ScenarioNodeIntent intent) {
  return switch (intent) {
    ScenarioNodeIntent.source => 'Source / déclencheur',
    ScenarioNodeIntent.condition => 'Test / condition',
    ScenarioNodeIntent.effect => 'Effet / action',
    ScenarioNodeIntent.dialogue => 'Étape dialogue',
    ScenarioNodeIntent.choice => 'Choix joueur',
    ScenarioNodeIntent.end => 'Fin de branche',
  };
}

ScenarioNodeIntent scenarioNodeIntent(
  ScenarioNode node, {
  ScenarioActionPreset? actionPreset,
}) {
  switch (node.type) {
    case ScenarioNodeType.start:
      return ScenarioNodeIntent.source;
    case ScenarioNodeType.condition:
      return ScenarioNodeIntent.condition;
    case ScenarioNodeType.dialogue:
      return ScenarioNodeIntent.dialogue;
    case ScenarioNodeType.choice:
      return ScenarioNodeIntent.choice;
    case ScenarioNodeType.end:
      return ScenarioNodeIntent.end;
    case ScenarioNodeType.action:
      return ScenarioNodeIntent.effect;
    case ScenarioNodeType.reference:
      if (scenarioPresetRepresentsTriggerSource(actionPreset?.id)) {
        return ScenarioNodeIntent.source;
      }
      return ScenarioNodeIntent.effect;
  }
}

ScenarioNodeExecutionState scenarioNodeExecutionState(
  ScenarioNode node, {
  ScenarioActionPreset? actionPreset,
  bool graphRuntimeConnected = kScenarioGraphRuntimeExecutionConnected,
}) {
  // Tant que le graphe n’est pas branché au runtime, on distingue explicitement
  // "capacité potentielle" et "exécution réelle".
  if (!graphRuntimeConnected) {
    if (actionPreset != null &&
        actionPreset.runtimeSupport == ScenarioPresetRuntimeSupport.planned) {
      return ScenarioNodeExecutionState.planned;
    }
    if (actionPreset != null &&
        actionPreset.runtimeSupport ==
            ScenarioPresetRuntimeSupport.runtimeReady) {
      return ScenarioNodeExecutionState.runtimeCapableNotConnected;
    }
    if (node.type == ScenarioNodeType.dialogue ||
        node.type == ScenarioNodeType.action) {
      return ScenarioNodeExecutionState.runtimeCapableNotConnected;
    }
    return ScenarioNodeExecutionState.authoringBridge;
  }

  if (actionPreset != null &&
      actionPreset.runtimeSupport == ScenarioPresetRuntimeSupport.planned) {
    return ScenarioNodeExecutionState.planned;
  }
  switch (node.type) {
    case ScenarioNodeType.choice:
      return ScenarioNodeExecutionState.authoringBridge;
    case ScenarioNodeType.start:
    case ScenarioNodeType.end:
    case ScenarioNodeType.condition:
      return ScenarioNodeExecutionState.runtimeConnected;
    case ScenarioNodeType.dialogue:
      final hasDialogue = (node.binding.dialogueId?.trim().isNotEmpty ?? false);
      final hasScript = (node.binding.scriptId?.trim().isNotEmpty ?? false);
      final hasMessage = (node.payload.message?.trim().isNotEmpty ?? false);
      return (hasDialogue || hasScript || hasMessage)
          ? ScenarioNodeExecutionState.runtimeConnected
          : ScenarioNodeExecutionState.authoringBridge;
    case ScenarioNodeType.action:
      if (actionPreset != null &&
          actionPreset.runtimeSupport ==
              ScenarioPresetRuntimeSupport.authoringBridge) {
        return ScenarioNodeExecutionState.authoringBridge;
      }
      final supports = scenarioRuntimeMvpSupportsActionKind(
        node.payload.actionKind,
        referenceMode: false,
      );
      return supports
          ? ScenarioNodeExecutionState.runtimeConnected
          : ScenarioNodeExecutionState.authoringBridge;
    case ScenarioNodeType.reference:
      if (actionPreset != null &&
          actionPreset.runtimeSupport ==
              ScenarioPresetRuntimeSupport.authoringBridge) {
        return ScenarioNodeExecutionState.authoringBridge;
      }
      final supports = scenarioRuntimeMvpSupportsActionKind(
        node.payload.actionKind,
        referenceMode: true,
      );
      return supports
          ? ScenarioNodeExecutionState.runtimeConnected
          : ScenarioNodeExecutionState.authoringBridge;
  }
}

String scenarioNodeExecutionStateLabel(ScenarioNodeExecutionState state) {
  return switch (state) {
    ScenarioNodeExecutionState.runtimeConnected => 'Exécution réelle',
    ScenarioNodeExecutionState.runtimeCapableNotConnected =>
      'Capable runtime, non branché automatiquement',
    ScenarioNodeExecutionState.authoringBridge => 'Pont d’authoring',
    ScenarioNodeExecutionState.planned => 'Prévu plus tard',
  };
}

String scenarioNodeExecutionStateDescription(ScenarioNodeExecutionState state) {
  return switch (state) {
    ScenarioNodeExecutionState.runtimeConnected =>
      'Ce node participe à un flow effectivement exécuté par le runtime.',
    ScenarioNodeExecutionState.runtimeCapableNotConnected =>
      'Le contenu est compatible runtime, mais le graphe scénario n’est pas encore consommé automatiquement.',
    ScenarioNodeExecutionState.authoringBridge =>
      'Ce node sert à organiser/documenter le flow et ses liens monde.',
    ScenarioNodeExecutionState.planned =>
      'Ce node/preset représente une intention produit encore non finalisée.',
  };
}

bool scenarioPresetRepresentsTriggerSource(String? presetId) {
  final normalized = presetId?.trim();
  if (normalized == null || normalized.isEmpty) {
    return false;
  }
  return normalized == 'sourceMapEnter' ||
      normalized == 'sourceTriggerEnter' ||
      normalized == 'sourceEntityInteract';
}

/// Action/preset réellement supporté par le bridge runtime MVP.
///
/// Cette fonction sert d'unique source pour l'UI de vérité runtime
/// (inspector, diagnostics, badges d'exécutabilité).
bool scenarioRuntimeMvpSupportsActionKind(
  String? actionKind, {
  required bool referenceMode,
}) {
  final normalized = actionKind?.trim();
  if (normalized == null || normalized.isEmpty) {
    return false;
  }
  if (referenceMode) {
    return normalized == 'sourceMapEnter' ||
        normalized == 'sourceTriggerEnter' ||
        normalized == 'sourceEntityInteract';
  }
  return normalized == 'runScript' ||
      normalized == 'openDialogue' ||
      normalized == 'showMessage' ||
      normalized == 'setFlag' ||
      normalized == 'clearFlag';
}

String scenarioNodeHumanSummary(ScenarioNode node) {
  final type = node.type;
  final actionKind = node.payload.actionKind?.trim();
  final binding = node.binding;
  if (type == ScenarioNodeType.start) {
    return 'Point de départ du flow.';
  }
  if (type == ScenarioNodeType.end) {
    return 'Fin de branche.';
  }
  if (type == ScenarioNodeType.dialogue) {
    final dialogue = binding.dialogueId?.trim();
    final script = binding.scriptId?.trim();
    if (dialogue != null && dialogue.isNotEmpty) {
      return 'Ouvre le dialogue "$dialogue".';
    }
    if (script != null && script.isNotEmpty) {
      return 'Dialogue/script lié via "$script".';
    }
    return 'Étape de dialogue (ressource non sélectionnée).';
  }
  if (type == ScenarioNodeType.condition) {
    final condition = node.payload.condition;
    if (condition == null) {
      return 'Branche conditionnelle sans condition configurée.';
    }
    return 'Teste la condition "${condition.type.name}".';
  }
  if (type == ScenarioNodeType.choice) {
    return 'Propose un choix joueur et redirige selon la branche.';
  }
  final preset = scenarioActionPresetById(
    actionKind,
    referenceMode: type == ScenarioNodeType.reference,
  );
  if (preset != null) {
    return '${preset.label}.';
  }
  if (actionKind != null && actionKind.isNotEmpty) {
    return 'Action/référence personnalisée "$actionKind".';
  }
  return 'Node ${scenarioNodeTypeLabel(type)} non configuré.';
}

ScenarioActionPreset? scenarioActionPresetById(
  String? id, {
  required bool referenceMode,
}) {
  final normalized = id?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final source =
      referenceMode ? scenarioReferencePresets : scenarioActionPresets;
  for (final preset in source) {
    if (preset.id == normalized) {
      return preset;
    }
  }
  return null;
}
