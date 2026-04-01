import 'package:map_core/map_core.dart';

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

class ScenarioActionPreset {
  const ScenarioActionPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.executionHint,
    this.fields = const <ScenarioActionField>{},
  });

  final String id;
  final String label;
  final String description;
  final String executionHint;
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
        'Réservé aux séquences de combat. Vérifie que le trainer existe.',
    fields: {ScenarioActionField.trainer},
  ),
  ScenarioActionPreset(
    id: 'jumpToMapEvent',
    label: 'Cibler un event de map',
    description:
        'Liaison vers un event existant sur une map (jump/activation).',
    executionHint:
        'Authoring structurant : lie le scénario à un event monde existant.',
    fields: {ScenarioActionField.map, ScenarioActionField.event},
  ),
  ScenarioActionPreset(
    id: 'triggerWarp',
    label: 'Utiliser un warp',
    description: 'Cible un warp existant sur la map sélectionnée.',
    executionHint: 'Authoring structurant : lie le flux à un warp de map.',
    fields: {ScenarioActionField.map, ScenarioActionField.warp},
  ),
  ScenarioActionPreset(
    id: 'activateTrigger',
    label: 'Activer un trigger',
    description: 'Cible un trigger existant sur la map sélectionnée.',
    executionHint: 'Authoring structurant : lie le flux à un trigger existant.',
    fields: {ScenarioActionField.map, ScenarioActionField.trigger},
  ),
  ScenarioActionPreset(
    id: 'referenceEntity',
    label: 'Cibler une entité',
    description: 'Référence une entité existante sur la map sélectionnée.',
    executionHint: 'Authoring structurant : pointe vers une entité du monde.',
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
  ),
];

const List<ScenarioActionPreset> scenarioReferencePresets =
    <ScenarioActionPreset>[
  ScenarioActionPreset(
    id: 'referenceMap',
    label: 'Référence map',
    description: 'Pointe vers une map du projet.',
    executionHint: 'Documentation/lien explicite avec une map.',
    fields: {ScenarioActionField.map},
  ),
  ScenarioActionPreset(
    id: 'referenceEvent',
    label: 'Référence event',
    description: 'Pointe vers un event d’une map donnée.',
    executionHint: 'Documentation/lien explicite avec un event.',
    fields: {ScenarioActionField.map, ScenarioActionField.event},
  ),
  ScenarioActionPreset(
    id: 'referenceEntity',
    label: 'Référence entité',
    description: 'Pointe vers une entité d’une map donnée.',
    executionHint: 'Documentation/lien explicite avec une entité.',
    fields: {ScenarioActionField.map, ScenarioActionField.entity},
  ),
  ScenarioActionPreset(
    id: 'referenceWarp',
    label: 'Référence warp',
    description: 'Pointe vers un warp d’une map donnée.',
    executionHint: 'Documentation/lien explicite avec un warp.',
    fields: {ScenarioActionField.map, ScenarioActionField.warp},
  ),
  ScenarioActionPreset(
    id: 'referenceTrigger',
    label: 'Référence trigger',
    description: 'Pointe vers un trigger d’une map donnée.',
    executionHint: 'Documentation/lien explicite avec un trigger.',
    fields: {ScenarioActionField.map, ScenarioActionField.trigger},
  ),
  ScenarioActionPreset(
    id: 'referenceTrainer',
    label: 'Référence dresseur',
    description: 'Pointe vers un dresseur du projet.',
    executionHint: 'Documentation/lien explicite avec un dresseur.',
    fields: {ScenarioActionField.trainer},
  ),
  ScenarioActionPreset(
    id: 'referenceDialogue',
    label: 'Référence dialogue',
    description: 'Pointe vers un dialogue Yarn du projet.',
    executionHint: 'Documentation/lien explicite avec un dialogue.',
    fields: {ScenarioActionField.dialogue},
  ),
  ScenarioActionPreset(
    id: 'referenceScript',
    label: 'Référence script',
    description: 'Pointe vers un script scénario/runtime du projet.',
    executionHint: 'Documentation/lien explicite avec un script.',
    fields: {ScenarioActionField.script},
  ),
  ScenarioActionPreset(
    id: 'customReference',
    label: 'Custom / avancé',
    description: 'Référence personnalisée pour des besoins avancés.',
    executionHint:
        'À utiliser seulement si aucun preset de référence ne suffit.',
  ),
];

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
