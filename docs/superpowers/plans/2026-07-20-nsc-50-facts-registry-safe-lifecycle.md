# NSC-50 — Facts Registry projet et cycle de vie sûr

## Objectif

Faire du registry Fact booléen V1 une API projet traçable : recherche et filtres, renommage de label sans changement d'ID, duplication, valeur initiale/runtime explicite et suppression bloquée par l'index de dépendances exhaustif.

## Frontières

- Conserver le wire booléen V1 ; les valeurs bool/int/string appartiennent à NSC-51.
- Réutiliser `NarrativeDependencyIndex` comme unique inventaire des consommateurs.
- Ne jamais réécrire automatiquement un ID technique lors d'un changement de label.
- Ne charger que les maps fournies ; le snapshot projet entier arrive en NSC-52.
- Ne pas commencer NSC-51 dans ce commit.

## Plan TDD

1. Ajouter les tests rouges de duplication et de suppression Event V2/New Game via l'index canonique.
2. Étendre les tests existants de l'index qui couvrent Scene, Storyline, WorldRule et legacy.
3. Ajouter les tests rouges du read model : catégories, portée lecteur/producteur, valeur initiale false explicite et override runtime absent/présent.
4. Implémenter les opérations pures minimales et brancher le read model sur l'index.
5. Ajouter les tests widget rouges pour filtres et duplication no-code.
6. Brancher l'UI et la persistance in-memory sans couleur brute ni ID manuel.
7. Vérifier core/editor ciblés, suites package, analyses et build macOS.

## Gate

Un Fact booléen peut être trouvé, filtré, renommé et dupliqué ; sa valeur et tous ses producteurs/consommateurs sont visibles, et aucune suppression référencée n'est possible.
