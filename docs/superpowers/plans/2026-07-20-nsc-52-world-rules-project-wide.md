# NSC-52 — World Rules projet et authoring complet

## Objectif

Permettre aux World Rules de lire et cibler tout le projet, de rester entièrement modifiables après création et d'agir réellement sur les Narrative Events V2 au runtime.

## Frontières

- La map active non sauvegardée remplace sa version disque dans le snapshot.
- Les autres maps restent chargées depuis le manifeste projet.
- `mapEvent` désigne uniquement `MapData.events` legacy.
- `narrativeEvent` désigne uniquement le registre Event V2 projet.
- Aucun ID manuel n'est demandé dans l'authoring normal.
- Les erreurs de chargement projet bloquent l'édition au lieu de masquer une vue partielle.

## Plan TDD

1. Tester le snapshot multi-map, la priorité de la map active dirty et les chemins hors projet.
2. Tester l'authoring cross-map et la cible Event V2 distincte.
3. Étendre diagnostics et index de dépendances pour les namespaces legacy/V2.
4. Appliquer enabled/disabled/hidden à l'autorité de dispatch Event V2.
5. Raccorder le runtime réel et la persistance save/load.
6. Ajouter les pickers source/prédicat/cible/effet dans l'éditeur post-création.
7. Régénérer et inspecter le golden Facts/World Rules, puis exécuter le gate multi-package.

## Gate

Une règle peut cibler une map inactive ou un Event V2, être entièrement reconfigurée sans ID manuel, produire des diagnostics honnêtes et modifier le dispatch runtime après save/load.
