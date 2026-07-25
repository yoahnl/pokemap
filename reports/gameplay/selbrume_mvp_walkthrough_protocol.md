# Selbrume MVP — protocole de walkthrough humain

**Lot :** FG-186 — Selbrume Release Candidate Walkthrough  
**Version :** 2026-07-23  
**Plateforme cible :** macOS Apple Silicon  
**Durée indicative :** 30 à 60 minutes  
**But :** prouver qu'une personne peut parcourir le package de release depuis
New Game jusqu'à l'épilogue, sans modifier le projet ni la sauvegarde.

## 1. Artefact à tester

Le walkthrough doit utiliser exclusivement :

```text
examples/playable_runtime_host/build/mvp-release/selbrume-macos.zip
```

Avant de commencer :

1. vérifier le SHA-256 de l'archive contre
   `selbrume-macos.manifest.json` ;
2. vérifier que le commit candidat, le tree hash du projet et le SHA du package
   sont identiques dans le manifest et le receipt final ;
3. utiliser un profil de préférences vierge ;
4. déplacer hors du chemin de test toute sauvegarde antérieure ;
5. ne pas modifier `selbrume/project.json` ou les maps pendant la recette.

## 2. Réglages de recette

- Lancer `PokeMap Selbrume.app` depuis le package construit.
- Conserver les contrôles de debug désactivés.
- En particulier, conserver **Collisions** désactivé : l'overlay pixel est un
  outil de diagnostic, pas une condition de jeu, et son coût de rendu perturbe
  la mesure de fluidité du parcours normal.
- Les captures doivent montrer le jeu et, quand nécessaire, le panneau de
  statut avec map et position. Le panneau n'est pas une preuve suffisante à lui
  seul : chaque checkpoint doit aussi être recoupé avec le comportement observé
  ou la sauvegarde produite par l'application.

## 3. Parcours obligatoire

### A. New Game et introduction

1. Démarrer une nouvelle partie.
2. Parler à Maël et choisir un starter.
3. Ouvrir Party et Bag ; vérifier le starter et le kit de départ.
4. Aller au Port des Brisants et terminer l'alerte d'introduction.

**Checkpoint receipt :** `new-game`.

### B. Rival, défaite et reprise

1. Déclencher la scène de Lysa.
2. Perdre volontairement le premier combat.
3. Vérifier le retour vers une source de soin.
4. Revenir au Port, redéclencher la rencontre et gagner.
5. Vérifier la récompense, la progression et le déblocage du Marais/Surf.

### C. Marais, capture et quête

1. Entrer dans le Marais Salants.
2. Déclencher une rencontre sauvage et capturer un Pokémon.
3. Fermer complètement la file post-combat.
4. Vérifier que la Party contient le Pokémon capturé et que la Ball a été
   consommée.
5. Parler à Mado et accepter la quête.
6. Trouver les trois cristaux et les trois indices.
7. Revenir à Mado et vérifier la récompense ainsi que l'étape suivante.

**Checkpoint receipt :** `capture`.

### D. Save/reload réel

1. Sauvegarder depuis l'application au milieu du parcours.
2. Fermer complètement l'application.
3. Relancer le même package et charger la sauvegarde.
4. Vérifier la map, la position, la Party, le Bag, les flags et les étapes.
5. Vérifier qu'aucun événement one-shot déjà consommé ne se rejoue.

**Checkpoint receipt :** `save-reload`.

### E. Phare et épilogue

1. Revenir au Port et terminer les interactions de Soline, du pêcheur et du
   nid de Goélise.
2. Traverser le Passage grâce au déblocage obtenu.
3. Rejoindre le Phare, parler à Yvon et récupérer la clé.
4. Lire le journal de la cabane puis la note du Phare.
5. Terminer les deux gardiens et le combat final.
6. Effectuer un dernier save/reload avant le retour.
7. Revenir au Port et déclencher l'épilogue.
8. Vérifier que la progression finale reste présente après sauvegarde.

**Checkpoint receipt :** `ending`.

## 4. Preuves minimales

Le receipt doit contenir exactement une entrée passée pour :

```text
new-game
capture
save-reload
ending
```

Chaque entrée référence au moins une capture ou un extrait précis de la
sauvegarde. Les preuves supplémentaires sont conservées sous :

```text
reports/gameplay/evidence/selbrume_mvp_walkthrough_2026-07-23/
```

## 5. Règle de décision

- **GO interdit** avec un P0 ou P1 non résolu.
- Un P2/P3 peut être accepté uniquement s'il est décrit, non bloquant pour le
  parcours normal et accompagné de son contournement.
- Un crash, une sauvegarde irrécupérable, un softlock de progression, un combat
  obligatoire impossible ou un épilogue inaccessible est au minimum P1.
- Un défaut limité aux outils de debug ne suffit pas à invalider le gameplay
  normal, mais doit rester visible dans le rapport.

## 6. Nettoyage après recette

1. Fermer l'application.
2. Supprimer uniquement la sauvegarde et les préférences créées par ce
   walkthrough.
3. Restaurer les préférences antérieures si elles avaient été mises de côté.
4. Vérifier que le dépôt ne contient que les captures, le receipt et les
   rapports attendus.
