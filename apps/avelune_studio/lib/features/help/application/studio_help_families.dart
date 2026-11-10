final class StudioHelpFamily {
  const StudioHelpFamily(this.number, this.title, this.help, [this.commandId]);
  final int number;
  final String title, help;
  final String? commandId;

  String get label => '${number.toString().padLeft(2, '0')} · $title';
}

const studioHelpFamilies = [
  StudioHelpFamily(
    1,
    'Créer et organiser les cartes',
    'Onglet Cartes de la colonne gauche : Nouvelle carte, Nouveau dossier et Sélection multiple pour classer ; le menu « … » d’une carte la renomme, la duplique ou la redimensionne.',
  ),
  StudioHelpFamily(
    2,
    'Sélectionner, déplacer et dupliquer',
    'Outil Sélection : cliquez un élément, Maj ou ⌘ + clic l’ajoute à la sélection, glissez pour déplacer. Dupliquer et tourner un groupe se font dans l’inspecteur.',
    'map.select',
  ),
  StudioHelpFamily(
    3,
    'Retrouver un objet masqué ou verrouillé',
    'Onglet Contenu : filtres Masqués et Verrouillés, recherche ; l’œil et le cadenas rétablissent l’élément sans déplacer ses voisins.',
  ),
  StudioHelpFamily(
    4,
    'Comprendre les superpositions',
    'Onglet Contenu : l’ordre de la liste indique ce qui passe devant ; Devant et Derrière se règlent dans l’inspecteur du décor.',
  ),
  StudioHelpFamily(
    5,
    'Peindre un sol, un chemin ou de l’eau',
    'Terrains : choisissez un sol, un chemin ou une eau dans la palette, puis peignez ; les raccords se calculent seuls.',
    'map.terrain',
  ),
  StudioHelpFamily(
    6,
    'Créer une falaise',
    'Bordures : choisissez un modèle publié, posez les angles du contour, relisez extrémités, coins et sens, puis Terminer le tracé.',
    'map.border',
  ),
  StudioHelpFamily(
    7,
    'Modifier une surface et sa pente',
    'Terrains, relief ou pente : sélectionnez la surface, réglez la hauteur et la montée, prévisualisez puis appliquez.',
    'map.terrain',
  ),
  StudioHelpFamily(
    8,
    'Ajouter un talus franchissable à sens unique',
    'Le saut se prépare sur le modèle, dans l’atelier Bordures, puis le talus se trace avec l’outil Bordures.',
    'map.border',
  ),
  StudioHelpFamily(
    9,
    'Répartir une forêt ou un environnement',
    'Environnements : choisissez un environnement, dessinez sa zone, voyez l’aperçu puis appliquez ; les arbres générés restent rattachés à leur zone.',
    'map.environment',
  ),
  StudioHelpFamily(
    10,
    'Éditer le décor extérieur',
    'Cible d’édition au-dessus de la carte : choisissez Décor extérieur, réglez les marges, puis peignez et placez en dehors de la zone jouable.',
  ),
  StudioHelpFamily(
    11,
    'Peindre et effacer les collisions',
    'Collisions : Bloquer les cases ou Libérer les cases, au clic ou en glissant ; chaque trait s’annule en une fois.',
    'map.collisions',
  ),
  StudioHelpFamily(
    12,
    'Créer une porte ou un escalier entre cartes',
    'Passages : choisissez la carte d’arrivée, cliquez la case du passage, puis réglez la case d’arrivée dans l’inspecteur.',
    'map.warps',
  ),
  StudioHelpFamily(
    13,
    'Relier deux bords de cartes',
    'Connexions : choisissez le bord, la carte voisine et le décalage dans le panneau Connexions.',
    'map.connections',
  ),
  StudioHelpFamily(
    14,
    'Placer le départ du joueur',
    'Peupler › Placer le départ du joueur, puis cliquez la case où la partie commence.',
    'map.spawn',
  ),
  StudioHelpFamily(
    15,
    'Placer un personnage et son interaction',
    'Peupler › Placer un personnage, choisissez-le dans la palette, cliquez sa case ; son interaction se règle dans l’inspecteur.',
    'map.character',
  ),
  StudioHelpFamily(
    16,
    'Changer l’apparence selon une condition',
    'Inspecteur du décor ou du personnage : la section des conditions masque ou montre le modèle selon la progression.',
  ),
  StudioHelpFamily(
    17,
    'Créer un arbre à couper ou un rocher',
    'Peupler › Placer un arbre à couper ou un rocher, choisissez son visuel, puis cliquez sa case.',
    'map.cut-tree',
  ),
  StudioHelpFamily(
    18,
    'Configurer une plateforme mobile',
    'Inspecteur d’un décor 3D : la section Plateforme sur trajet décrit les étapes et les quais.',
  ),
  StudioHelpFamily(
    19,
    'Régler la caméra du jeu',
    'Réglages du projet › Image et caméra pour tout le jeu ; Caméra du jeu dans le panneau de la carte pour cette carte seulement.',
  ),
  StudioHelpFamily(
    20,
    'Régler météo, lumière et atmosphère',
    'Ambiance dans la barre de la carte pour cette carte ; Réglages du projet › Temps et météo pour tout le jeu.',
  ),
  StudioHelpFamily(
    21,
    'Régler vélo, donjon et Corde Sortie',
    'Panneau de la carte : Déplacements et sortie… règle le vélo, le donjon et la Corde Sortie de cette carte.',
  ),
  StudioHelpFamily(
    22,
    'Dessiner une zone de jeu',
    'Zones : tracez une zone de rencontres, de déplacement, d’effet ou de danger.',
    'map.zones',
  ),
  StudioHelpFamily(
    23,
    'Trouver et classer les ressources',
    'Ressources : recherche, familles et filtres ; Gérer les ressources ouvre la bibliothèque complète.',
    'map.resources',
  ),
  StudioHelpFamily(
    24,
    'Importer une image, un modèle ou un pack',
    'Ressources : l’import montre ce qui sera ajouté avant de publier quoi que ce soit.',
    'map.resources',
  ),
  StudioHelpFamily(
    25,
    'Modifier ici ou modifier la ressource partagée',
    'Inspecteur : « Cette instance » agit sur la carte seulement ; la définition partagée s’ouvre dans Ressources.',
  ),
  StudioHelpFamily(
    26,
    'Analyser les usages avant remplacement ou suppression',
    'Ressources : les usages d’une ressource s’affichent avant de la remplacer ou de la supprimer.',
  ),
  StudioHelpFamily(
    27,
    'Distinguer ressource prête et pièces sources',
    'Ressources : les pièces sources restent dans la bibliothèque ; seules les ressources prêtes apparaissent dans la palette de la carte.',
  ),
  StudioHelpFamily(
    28,
    'Préparer et publier un profil de bordure',
    'Atelier Bordures : associez les pièces, vérifiez le motif, puis publiez le modèle pour le tracer sur les cartes.',
  ),
  StudioHelpFamily(
    29,
    'Préparer les motifs et animations de bordure',
    'Atelier Bordures : séquence des pièces et animations du modèle, avant publication.',
  ),
  StudioHelpFamily(
    30,
    'Préparer les raccords automatiques d’un terrain',
    'Atelier Terrain : motifs, pièces et règles de raccord d’un sol, d’un chemin ou d’une eau.',
  ),
  StudioHelpFamily(
    31,
    'Préparer un décor 2D et ses collisions',
    'Atelier Décors : image, découpe et collisions du décor.',
  ),
  StudioHelpFamily(
    32,
    'Régler collision et taille d’un modèle 3D',
    'Atelier Modèles 3D : échelle, collision et ancrage du modèle.',
  ),
  StudioHelpFamily(
    33,
    'Rendre un escalier franchissable',
    'Atelier Modèles 3D pour la rampe du modèle, puis Terrains en mode pente sur la carte.',
  ),
  StudioHelpFamily(
    34,
    'Éclairage, ombres et flamme d’un modèle',
    'Atelier Modèles 3D : lumière, ombre et flamme du modèle.',
  ),
  StudioHelpFamily(
    35,
    'Préparer les images et animations d’un personnage',
    'Atelier Personnage : identité, apparence, portraits et animations.',
  ),
  StudioHelpFamily(
    36,
    'Diagnostiquer une référence manquante',
    'Barre du bas de la carte : chaque incident sur les ressources ouvre sa source et propose de la réparer.',
  ),
  StudioHelpFamily(
    37,
    'Exporter et réutiliser un pack',
    'Ressources : un pack exporte des ressources avec leurs dépendances pour un autre projet.',
  ),
  StudioHelpFamily(
    38,
    'Assembler une scène en graphe visuel',
    'Histoire › Scènes : reliez les blocs du graphe ; le résumé lisible complète le graphe.',
  ),
  StudioHelpFamily(
    39,
    'Écrire un dialogue avec choix et résultats',
    'Histoire › Dialogues : répliques, choix et résultats de chaque choix.',
  ),
  StudioHelpFamily(
    40,
    'Relier un événement à une scène',
    'Histoire › Événements : choisissez la scène lancée et quand elle peut se rejouer.',
  ),
  StudioHelpFamily(
    41,
    'Déclencher une scène dans une zone d’histoire',
    'Sur la carte : Dessiner une zone d’histoire, puis reliez-la à son événement.',
    'map.story-zone',
  ),
  StudioHelpFamily(
    42,
    'Organiser histoires, étapes et progression',
    'Histoire › Histoires : chapitres, étapes et règles de progression.',
  ),
  StudioHelpFamily(
    43,
    'Mettre en scène une cinématique sur carte',
    'Histoire › Cinématiques : acteurs, déplacements et temps de la cinématique.',
  ),
  StudioHelpFamily(
    44,
    'Créer une présentation animée',
    'Histoire › Présentations : séquence plein écran, comme l’écran titre.',
  ),
  StudioHelpFamily(
    45,
    'Préparer une table de rencontres',
    'Sur la carte, Zones de rencontres ; les espèces, niveaux et probabilités se règlent dans la zone.',
    'map.zones',
  ),
  StudioHelpFamily(
    46,
    'Préparer un dresseur et son équipe',
    'Pokémon › Combats : dresseurs, équipes et règles de combat.',
  ),
  StudioHelpFamily(
    47,
    'Éditer espèces et capacités',
    'Pokémon › Pokédex et Attaques.',
  ),
  StudioHelpFamily(
    48,
    'Régler les objets et les règles de combat',
    'Pokémon › Objets et Combats.',
  ),
  StudioHelpFamily(
    49,
    'Créer la carte régionale et les arrivées de Vol',
    'Carte régionale : lieux, carte liée et arrivée de Vol de chaque lieu.',
  ),
  StudioHelpFamily(
    50,
    'Régler le projet et ses valeurs par défaut',
    'Réglages du projet : Général, Image et caméra, Temps et météo, Capacités de terrain et Sons.',
  ),
  StudioHelpFamily(
    51,
    'Tester la carte ou tester le jeu',
    'Tester la carte, dans la barre de la carte, lance la carte ouverte ; Test du jeu lance une partie depuis le départ.',
  ),
  StudioHelpFamily(
    52,
    'Exporter le jeu pour Avelune Player',
    'Accueil › Exporter le jeu… prépare le paquet pour Avelune Player.',
  ),
  StudioHelpFamily(
    53,
    'Annuler et rétablir sans perdre le contexte',
    '⌘Z annule et ⇧⌘Z rétablit la dernière modification de la carte ouverte ; chaque carte garde son historique.',
    'map.undo',
  ),
  StudioHelpFamily(
    54,
    'Afficher les panneaux utiles à la tâche',
    'Carte seule replie la colonne, la palette et l’inspecteur ; Palette et Inspecteur s’affichent à la demande. La disposition est mémorisée.',
  ),
  StudioHelpFamily(
    55,
    'Comprendre un problème et aller à sa source',
    'Barre du bas de la carte : chaque diagnostic ouvre l’élément ou la ressource en cause.',
  ),
];
