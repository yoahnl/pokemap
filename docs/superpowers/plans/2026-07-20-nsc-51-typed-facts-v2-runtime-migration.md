# NSC-51 — Facts typés V2 et migration runtime

## Objectif

Introduire une valeur narrative fermée bool/int/string partagée par le wire, le save, Event, Scene, Storyline, New Game et WorldRule, tout en conservant le comportement et le JSON booléens historiques.

## Frontières

- Le bool V1 reste lisible et produit le même sens sans migration manuelle.
- Les variables `ScriptCondition.variable*` restent un contrat legacy distinct.
- Les comparaisons invalides échouent fermé avant runtime.
- `existingPartyFactId` ne peut cibler qu'un Fact booléen.
- Aucun chargement projet/WorldRule cross-map de NSC-52 dans ce commit.

## Plan TDD

1. Tester NarrativeValue, opérateurs, bornes int et Unicode.
2. Tester codecs Fact/runtime/New Game/Event/Scene/Storyline/WorldRule/Save et compatibilité bool.
3. Migrer le resolver/writer runtime puis les consumers Event, Scene et WorldRule.
4. Bloquer les changements de type dont les usages sont incompatibles via l'index canonique.
5. Ajouter les pickers no-code de type, opérateur et valeur dans les surfaces principales.
6. Ajouter une matrice cross-consumer runtime et save/load.
7. Exécuter codegen package-scoped, tests, analyses et builds.

## Gate

Les trois types effectuent un round-trip Editor/save/runtime, les opérateurs sont validés par type et les projets bool V1 gardent leur comportement.
