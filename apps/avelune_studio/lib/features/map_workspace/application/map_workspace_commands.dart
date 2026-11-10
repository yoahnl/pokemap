import '../../help/application/studio_help_families.dart';
import '../../help/application/studio_lexicon.dart';
import '../../commands/application/studio_command_entry.dart';

enum MapCommandKind { family, extra, history }

final class MapWorkspaceCommand {
  const MapWorkspaceCommand({
    required this.id,
    required this.label,
    required this.kind,
    required this.group,
    required this.howTo,
    this.keywords = const [],
    this.shortcut,
  });

  final String id, label, group, howTo;
  final MapCommandKind kind;
  final List<String> keywords;
  final String? shortcut;
}

final class MapCommandContext {
  const MapCommandContext({
    this.spatial = false,
    this.exterior = false,
    this.storyAvailable = false,
    this.canUndo = false,
    this.canRedo = false,
    this.paintReady = false,
  });

  final bool spatial, exterior, storyAvailable, canUndo, canRedo, paintReady;
}

const _spatialSupported = {
  'map.select',
  'map.decor',
  'map.terrain',
  'map.border',
  'map.environment',
  'map.paint',
  'map.erase-tiles',
  'map.pan',
  'map.erase-decor',
  'map.character',
  'map.spawn',
  'map.collisions',
  'map.collisions-paint',
  'map.collisions-erase',
  'map.warps',
  'map.connections',
  'map.palette',
  'map.resources',
  'map.undo',
  'map.redo',
  'map.ambiance',
};

const _exteriorSupported = {
  'map.select',
  'map.decor',
  'map.terrain',
  'map.border',
  'map.environment',
  'map.pan',
  'map.erase-tiles',
  'map.erase-decor',
  'map.palette',
  'map.resources',
  'map.undo',
  'map.redo',
};

const mapWorkspaceCommands = <MapWorkspaceCommand>[
  MapWorkspaceCommand(
    id: 'map.ambiance',
    label: 'Régler l’ambiance',
    kind: MapCommandKind.extra,
    group: 'Ambiance',
    keywords: ['ambiance', 'lumière', 'météo', 'jour', 'nuit', 'brume'],
    howTo: 'Ouvre l’ambiance de cette carte : lumière, météo, jour et nuit, effets visuels.',
  ),
  MapWorkspaceCommand(
    id: 'map.select',
    label: 'Sélection',
    kind: MapCommandKind.family,
    group: 'Outils',
    shortcut: 'Échap',
    keywords: ['sélectionner', 'choisir', 'modifier', 'inspecter', 'déplacer'],
    howTo: 'Cliquez un élément de la carte, ou choisissez-le dans l’onglet Contenu, pour voir ses propriétés dans l’inspecteur.',
  ),
  MapWorkspaceCommand(
    id: 'map.decor',
    label: 'Décors',
    kind: MapCommandKind.family,
    group: 'Construire',
    keywords: ['objet', 'meuble', 'maison', 'modèle 3d', 'placer', 'décor'],
    howTo: 'Choisissez un décor complet dans la palette, puis cliquez sur la carte pour le placer. Échap annule le placement en cours.',
  ),
  MapWorkspaceCommand(
    id: 'map.terrain',
    label: 'Terrains',
    kind: MapCommandKind.family,
    group: 'Construire',
    keywords: [
      'sol',
      'herbe',
      'chemin',
      'route',
      'eau',
      'sable',
      'peindre',
      'pente',
      'relief',
      'surface',
    ],
    howTo: 'Choisissez un sol, un chemin ou une eau dans la palette Terrains, puis peignez : les raccords se calculent automatiquement.',
  ),
  MapWorkspaceCommand(
    id: 'map.border',
    label: 'Bordures',
    kind: MapCommandKind.family,
    group: 'Construire',
    keywords: [
      'falaise',
      'berge',
      'rive',
      'contour',
      'corniche',
      'muret',
      'paroi',
    ],
    howTo: 'Choisissez un modèle de bordure publié, cliquez pour poser les points du contour, puis terminez le tracé dans la barre au-dessus de la carte.',
  ),
  MapWorkspaceCommand(
    id: 'map.environment',
    label: 'Environnements',
    kind: MapCommandKind.family,
    group: 'Construire',
    keywords: ['forêt', 'bois', 'arbres', 'végétation', 'répartir', 'buissons'],
    howTo: 'Choisissez un environnement, dessinez sa zone au pinceau ou en rectangle, préparez l’aperçu, puis appliquez les décors générés.',
  ),
  MapWorkspaceCommand(
    id: 'map.character',
    label: 'Placer un personnage',
    kind: MapCommandKind.extra,
    group: 'Peupler',
    keywords: ['pnj', 'habitant', 'dresseur', 'personnage'],
    howTo: 'Choisissez un personnage dans la palette, puis cliquez sur sa case de départ.',
  ),
  MapWorkspaceCommand(
    id: 'map.spawn',
    label: 'Placer le départ du joueur',
    kind: MapCommandKind.extra,
    group: 'Peupler',
    keywords: ['départ', 'début', 'apparition', 'spawn', 'joueur'],
    howTo: 'Cliquez la case où le joueur commence la partie.',
  ),
  MapWorkspaceCommand(
    id: 'map.sign',
    label: 'Placer un panneau',
    kind: MapCommandKind.extra,
    group: 'Peupler',
    keywords: ['panneau', 'pancarte', 'texte', 'lire'],
    howTo: 'Cliquez la case du panneau, puis écrivez son texte.',
  ),
  MapWorkspaceCommand(
    id: 'map.cut-tree',
    label: 'Placer un arbre à couper',
    kind: MapCommandKind.extra,
    group: 'Peupler',
    keywords: ['coupe', 'cs', 'obstacle', 'arbuste'],
    howTo: 'Choisissez le visuel de l’obstacle, puis cliquez sur sa case. La capacité requise se règle dans le panneau de l’obstacle.',
  ),
  MapWorkspaceCommand(
    id: 'map.boulder',
    label: 'Placer un rocher à pousser',
    kind: MapCommandKind.extra,
    group: 'Peupler',
    keywords: ['force', 'cs', 'obstacle', 'rocher'],
    howTo: 'Choisissez le visuel du rocher, puis cliquez sur sa case.',
  ),
  MapWorkspaceCommand(
    id: 'map.rock-smash',
    label: 'Placer un rocher à briser',
    kind: MapCommandKind.extra,
    group: 'Peupler',
    keywords: ['éclate-roc', 'cs', 'obstacle', 'rocher'],
    howTo: 'Choisissez le visuel du rocher, puis cliquez sur sa case.',
  ),
  MapWorkspaceCommand(
    id: 'map.zones',
    label: 'Zones',
    kind: MapCommandKind.family,
    group: 'Règles',
    keywords: [
      'rencontres',
      'hautes herbes',
      'pokémon sauvages',
      'zone de jeu',
      'danger',
    ],
    howTo: 'Tracez une zone de jeu sur la carte : rencontres, déplacement, effet ou danger.',
  ),
  MapWorkspaceCommand(
    id: 'map.story-zone',
    label: 'Dessiner une zone d’histoire',
    kind: MapCommandKind.extra,
    group: 'Règles',
    keywords: ['déclencheur', 'scène', 'événement', 'histoire'],
    howTo: 'Tracez la zone qui déclenche une scène ou une interaction.',
  ),
  MapWorkspaceCommand(
    id: 'map.collisions',
    label: 'Collisions',
    kind: MapCommandKind.family,
    group: 'Règles',
    keywords: ['bloquer', 'mur', 'obstacle', 'franchissable', 'passable'],
    howTo: 'Cliquez ou glissez pour bloquer les cases ; « Libérer les cases » efface. Chaque trait s’annule en une fois.',
  ),
  MapWorkspaceCommand(
    id: 'map.warps',
    label: 'Passages',
    kind: MapCommandKind.family,
    group: 'Règles',
    keywords: [
      'porte',
      'escalier',
      'entrée',
      'sortie',
      'téléporter',
      'échelle',
    ],
    howTo: 'Choisissez la carte de destination, puis cliquez sur la case du passage.',
  ),
  MapWorkspaceCommand(
    id: 'map.connections',
    label: 'Connexions',
    kind: MapCommandKind.family,
    group: 'Règles',
    keywords: ['bord', 'relier', 'carte voisine', 'raccorder'],
    howTo: 'Réglez le bord, la carte voisine et le décalage dans le panneau Connexions.',
  ),
  MapWorkspaceCommand(
    id: 'map.pan',
    label: 'Déplacer la vue',
    kind: MapCommandKind.extra,
    group: 'Outils',
    keywords: ['naviguer', 'explorer', 'faire glisser', 'main'],
    howTo: 'Faites glisser la carte pour explorer. Le zoom reste conservé.',
  ),
  MapWorkspaceCommand(
    id: 'map.paint',
    label: 'Peindre',
    kind: MapCommandKind.extra,
    group: 'Outils',
    keywords: ['pinceau', 'tuile'],
    howTo: 'Peint avec la ressource déjà choisie dans la palette.',
  ),
  MapWorkspaceCommand(
    id: 'map.erase-tiles',
    label: 'Gomme de tuiles',
    kind: MapCommandKind.extra,
    group: 'Outils',
    keywords: ['effacer', 'gomme', 'sol'],
    howTo: 'Effacez les tuiles et terrains sous le curseur.',
  ),
  MapWorkspaceCommand(
    id: 'map.erase-decor',
    label: 'Gomme de décors',
    kind: MapCommandKind.extra,
    group: 'Outils',
    keywords: ['effacer', 'supprimer', 'décor'],
    howTo:
        'Cliquez sur un décor pour effacer celui qui apparaît au premier plan.',
  ),
  MapWorkspaceCommand(
    id: 'map.palette',
    label: 'Palette complète',
    kind: MapCommandKind.extra,
    group: 'Outils',
    keywords: ['palette', 'ressources de la carte'],
    howTo: 'Rouvre la palette liée à l’outil actif.',
  ),
  MapWorkspaceCommand(
    id: 'map.resources',
    label: 'Gérer les ressources',
    kind: MapCommandKind.extra,
    group: 'Outils',
    keywords: ['bibliothèque', 'importer', 'atelier', 'préparer'],
    howTo: 'Ouvre la bibliothèque complète pour importer, préparer ou classer des ressources.',
  ),
  MapWorkspaceCommand(
    id: 'map.undo',
    label: 'Annuler',
    kind: MapCommandKind.history,
    group: 'Historique',
    shortcut: '⌘Z',
    keywords: ['défaire', 'retour'],
    howTo: 'Annule la dernière modification de la carte active.',
  ),
  MapWorkspaceCommand(
    id: 'map.redo',
    label: 'Rétablir',
    kind: MapCommandKind.history,
    group: 'Historique',
    shortcut: '⇧⌘Z',
    keywords: ['refaire'],
    howTo: 'Rétablit la dernière modification annulée de la carte active.',
  ),
];

MapWorkspaceCommand mapWorkspaceCommand(String id) =>
    mapWorkspaceCommands.singleWhere((command) => command.id == id);

MapWorkspaceCommand? mapWorkspaceCommandForLabel(String label) =>
    mapWorkspaceCommands.where((command) => command.label == label).firstOrNull;

String? mapCommandUnavailable(String id, MapCommandContext context) {
  if (context.exterior && !_exteriorSupported.contains(id)) {
    return 'Le décor extérieur ne porte que le décor : revenez à la zone jouable pour cette commande.';
  }
  if (context.spatial && !_spatialSupported.contains(id)) {
    return 'Cet outil n’est pas encore disponible sur les cartes 3D.';
  }
  return switch (id) {
    'map.story-zone' when !context.storyAvailable => 'Les zones d’histoire demandent l’espace Histoire, indisponible dans cette session.',
    'map.paint' when !context.paintReady =>
      'Choisissez d’abord une tuile, un décor ou un terrain dans la palette.',
    'map.undo' when !context.canUndo => 'Aucune modification à annuler.',
    'map.redo' when !context.canRedo => 'Aucune modification à rétablir.',
    'map.ambiance' when !context.spatial =>
      'L’ambiance se règle sur les cartes 3D.',
    _ => null,
  };
}

String? mapCommandUnavailableForLabel(String label, MapCommandContext context) {
  final command = mapWorkspaceCommandForLabel(label);
  return command == null ? null : mapCommandUnavailable(command.id, context);
}

List<StudioCommandEntry> mapCommandPaletteEntries(MapCommandContext context) =>
    [
      for (final command in mapWorkspaceCommands)
        StudioCommandEntry(
          id: command.id,
          label: command.label,
          group: command.group,
          help: command.howTo,
          keywords: command.keywords,
          shortcut: command.shortcut,
          unavailable: mapCommandUnavailable(command.id, context),
        ),
      for (final family in studioHelpFamilies)
        StudioCommandEntry(
          id: family.commandId ?? 'help.${family.number}',
          label: family.label,
          group: 'Comment faire',
          help: family.help,
          executable: family.commandId != null,
          unavailable: family.commandId == null
              ? null
              : mapCommandUnavailable(family.commandId!, context),
        ),
      for (final term in studioLexicon)
        StudioCommandEntry(
          id: 'lexicon.${term.term}',
          label: term.term,
          group: 'Lexique',
          help: term.definition,
          example: term.example,
          executable: false,
        ),
    ];
