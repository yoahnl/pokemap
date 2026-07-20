# NSC-44 — Map Events View 2.0

## Objectif

Remplacer la projection Map Events issue du Validator par une lecture exhaustive dédiée : sources physiques, Events V2/legacy et World Rules d'une map, avec conflits, références et navigations exactes.

## Frontières

- Le Map Editor reste propriétaire de la géométrie ; Map Events ne crée ni ne déplace une source.
- Le read model pur réutilise le catalogue spatial et la projection Event existants.
- Les Events outcome/global et sans source restent visibles dans une section hors map.
- Les migrations et le dual-read runtime restent NSC-45.
- Aucun code de phase 5 n'est ajouté.

## Plan TDD

1. Créer les tests core : map vide, source non liée, Event sans source/cross-map, liens multiples, conflit priorité/ordre et World Rule.
2. Construire `NarrativeMapEventsReadModel` comme composition immuable des catalogues existants et l'exporter.
3. Créer les tests widget pour filtres, synchronisation source/Event, aperçu, états vides et callbacks exacts.
4. Implémenter `MapEventsWorkspace` exclusivement avec les primitives/tokens du Design System.
5. Charger cette projection depuis le snapshot disque attesté et remplacer l'ancienne vue Validator dans `narrative_workspace_canvas.dart`.
6. Restaurer la même ligne après l'aller-retour Map Editor et brancher les deep links Event, Scene, Fact et World Rule.
7. Durcir le deep link Event Builder pour consommer la sélection de route exacte.
8. Vérifier core/editor ciblés, analyses, build macOS, couleurs brutes et diff.

## Gate

Pour chaque map, l'utilisateur peut répondre à « qu'est-ce qui peut arriver ici, dans quel ordre et pourquoi ? », ouvrir la source physique exacte et revenir sur la même ligne.
