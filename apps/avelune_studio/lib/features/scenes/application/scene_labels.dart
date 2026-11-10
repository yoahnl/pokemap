import 'package:map_core/map_core_domain.dart';

String scenePortLabel(String id) => switch (id) {
  'true' => 'Oui',
  'false' => 'Non',
  'completed' => 'Continuer',
  'received' => 'Reçu',
  'alreadyClaimed' => 'Déjà reçu aujourd’hui',
  'bagFull' => 'Sac plein',
  'blocked' => 'Indisponible',
  'victory' => 'Victoire',
  'defeat' => 'Défaite',
  'default' => 'Sinon',
  'error' => 'Erreur',
  _ => id,
};

String sceneKindLabel(SceneNodeKind kind) => switch (kind) {
  SceneNodeKind.start => 'Début',
  SceneNodeKind.end => 'Fin',
  SceneNodeKind.yarnDialogue => 'Dialogue',
  SceneNodeKind.condition => 'Condition',
  SceneNodeKind.action => 'Action',
  SceneNodeKind.battle => 'Combat',
  SceneNodeKind.cinematic => 'Cinématique',
  SceneNodeKind.presentationCinematic => 'Présentation',
  SceneNodeKind.branchByOutcome => 'Branchement',
  SceneNodeKind.merge => 'Convergence',
};

String sceneBlockLabel(SceneNodeKind kind) => sceneKindLabel(kind);

String sceneNodeName(SceneGraph graph, String id) {
  final node = graph.nodes.where((item) => item.id == id).firstOrNull;
  if (node == null) return id;
  final title = node.title?.trim();
  return title == null || title.isEmpty ? sceneKindLabel(node.kind) : title;
}
