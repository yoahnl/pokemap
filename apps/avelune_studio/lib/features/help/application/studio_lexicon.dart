final class StudioLexiconTerm {
  const StudioLexiconTerm(this.term, this.definition, this.example);
  final String term, definition, example;
}

const studioLexicon = [
  StudioLexiconTerm(
    'Projet',
    'Le dossier de travail ouvert dans Avelune Studio : cartes, ressources, histoire et réglages.',
    'Exemple : « Mon aventure » et tout ce qu’il contient.',
  ),
  StudioLexiconTerm(
    'Jeu',
    'Ce que les joueurs installent dans Avelune Player, exporté depuis le projet.',
    'Exemple : le paquet exporté de « Mon aventure ».',
  ),
  StudioLexiconTerm(
    'Carte',
    'Un lieu jouable : sol, décors, personnages, passages et règles. « Tester la carte » lance ce lieu.',
    'Exemple : « Bourg Géon » ou « Maison du joueur ».',
  ),
  StudioLexiconTerm(
    'Carte régionale',
    'La vue d’ensemble de la région, avec ses lieux et ses arrivées de Vol. Elle ne se parcourt pas case par case.',
    'Exemple : la carte de Johto ouverte depuis le menu du jeu.',
  ),
  StudioLexiconTerm(
    'Scène',
    'Un enchaînement narratif en graphe : dialogues, choix, mouvements et récompenses. Une scène n’est pas une carte.',
    'Exemple : « Le professeur remet le premier Pokémon ».',
  ),
  StudioLexiconTerm(
    'Événement',
    'Ce qui déclenche une scène sur une carte : parler, toucher une case, entrer dans une zone.',
    'Exemple : parler au professeur lance sa scène.',
  ),
  StudioLexiconTerm(
    'Présentation',
    'Une séquence animée plein écran, jouée hors de la carte.',
    'Exemple : l’écran titre ou l’introduction.',
  ),
  StudioLexiconTerm(
    'Ressource',
    'Un élément réutilisable de la bibliothèque : décor, terrain, bordure, environnement, personnage ou son.',
    'Exemple : le décor « Lit simple ».',
  ),
  StudioLexiconTerm(
    'Occurrence',
    'Une utilisation d’une ressource posée sur une carte. La modifier ici ne change pas la ressource partagée.',
    'Exemple : le lit posé dans la chambre du joueur.',
  ),
];
