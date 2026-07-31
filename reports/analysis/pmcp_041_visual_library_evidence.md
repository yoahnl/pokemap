# PMCP-041 — Evidence Pack bibliothèque visuelle

Date : 2026-07-31
Lot : `PMCP-041 — Bibliothèque visuelle`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot expose les tilesets, palettes, éléments et presets visuels comme des
ressources d’authoring validées et manipulables par le dispatcher canonique.
Les dimensions réelles d’un atlas et sa grille sont persistées dans le
manifeste ; chaque frame est contrôlée contre ces bornes. Un changement de
grille produit une prévisualisation déterministe de toutes les ressources
affectées avant mutation.

Les suppressions sont conservatrices : elles inspectent les références du
manifeste et de toutes les maps chargées. Les presets terrain, chemin, surface
et environnement restent reliés aux actions sémantiques de la phase 4, sans
introduire une seconde logique de peinture.

## Audit initial et continuité

État Git initial : arbre propre à
`9104512d feat(authoring): add secure asset store`.

L’audit initial a confirmé la présence de modèles visuels riches dans
`map_core`, mais a identifié trois lacunes bloquantes pour un authoring sûr :

- aucune métadonnée canonique ne décrivait les dimensions et la grille réelles
  des atlas ;
- un regrid ne permettait pas de connaître ses impacts avant application ;
- les suppressions ne parcouraient pas l’ensemble des références visuelles.

L’implémentation conserve donc les modèles canoniques existants et ajoute une
couche d’actions, de validation et d’impact dans `map_authoring`.

## Passes et verdicts

| Passe | Verdict | Signal |
|---|---|---|
| Audit / Architecture — agent assets | Conforme après corrections | A imposé atlas réel, impact de regrid et scan global des références |
| Implémentation | Conforme | Huit mutations visuelles enregistrées dans le dispatcher |
| Tests | Conforme | RED initial sur contrats absents, puis 5 tests contractuels et 13 tests assets verts |
| Build / Validation | Conforme | Suite package, analyse, format strict et smoke CLI verts |
| Critique finale | Conforme avec limite | L’éditeur consommera la façade lors de la migration dédiée de phase 7 |

## Contrats et zones modifiées

- `tileset_actions.dart` : spécification d’atlas, dimensions/grille,
  propriétés par tuile, validation de frames, preview de regrid, références et
  mutations upsert/delete.
- `palette_actions.dart` : mutations de palettes avec validation de toutes les
  frames contre les atlas persistés.
- `element_actions.dart` : mutations d’éléments et suppression protégée par un
  scan manifeste + maps.
- `preset_actions.dart` : mutations terrain/chemin et gate unifié pour les
  presets terrain, chemin, surface et environnement.
- `map_lifecycle_adapter.dart` : encodeur public réutilisable pour produire le
  document projet canonique sans dupliquer sa sérialisation.
- `map_mutation_dispatcher.dart` : enregistrement des huit nouvelles actions.
- `map_authoring.dart` : exports publics de la bibliothèque visuelle.

## Inventaire complet

Créés :

- `packages/map_authoring/lib/src/domains/assets/tileset_actions.dart`
- `packages/map_authoring/lib/src/domains/assets/palette_actions.dart`
- `packages/map_authoring/lib/src/domains/assets/element_actions.dart`
- `packages/map_authoring/lib/src/domains/assets/preset_actions.dart`
- `packages/map_authoring/test/domains/assets/visual_library_contract_test.dart`
- `reports/analysis/pmcp_041_visual_library_evidence.md`
- `reports/analysis/pmcp_041_visual_library_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart`
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`

Le contenu intégral des fichiers texte créés, hors rapports auto-référents,
est fourni dans l’annexe générée. Les zones exactes modifiées sont celles du
diff Git associé au commit dédié.

## Tests et résultats exacts

TDD rouge initial :

```text
dart test test/domains/assets/visual_library_contract_test.dart
exit 1 — TilesetAtlasSpec, TilesetActions, VisualLibraryException,
ElementActions et PresetActions absents.
```

Tests ciblés après intégration :

```text
dart test test/domains/assets/visual_library_contract_test.dart
00:00 +5: All tests passed!

dart test test/domains/assets
00:00 +13: All tests passed!
```

Suite et analyse :

```text
dart test
00:15 +243: All tests passed!

dart analyze
Analyzing map_authoring...
No issues found!

dart format --output=none --set-exit-if-changed lib test bin
Formatted 136 files (0 changed) in 0.22 seconds.
```

Meilleure validation build pour ce package CLI pur Dart :

```text
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host </dev/null
exit 0, stdout/stderr vides.
```

## Preuves de fin de lot

- Bornes réelles : une frame hors d’un atlas 64×48 / grille 16×16 est refusée
  avec un code stable.
- Regrid : le passage 16×16 vers 8×8 inventorie les impacts palette, élément,
  preset terrain et preset chemin dans un ordre déterministe.
- Suppression : un élément placé dans une map chargée bloque `element.delete`
  et retourne ses références.
- Parité sémantique : le gate de presets expose les actions `terrain.paint`,
  `path.paint`, `surface.paint` et `environment.generate_apply` déjà
  implémentées, sans dupliquer leurs algorithmes.
- Surface MCP : les huit mutations sont visibles dans le registre du
  dispatcher et héritent du plan/CAS/permission/audit/undo de la phase 3.

## Limites, risques et non-objectifs

- Les métadonnées d’atlas sont stockées sous une clé namespacée du manifeste
  pour préserver la compatibilité du schéma `map_core`. Une évolution future
  pourra les promouvoir en champs typés avec migration explicite.
- Ce lot ne réécrit pas les use cases Flutter de l’éditeur : leur bascule vers
  `map_authoring` est le scope prévu de PMCP-080, après stabilisation de toute
  la surface métier.
- Aucun statut du roadmap fangame n’est modifié et aucun lot `FG-*` ne change
  de statut.

## Auto-critique finale

Le scan par sérialisation des couches est volontairement conservateur : il
privilégie le refus d’une suppression ambiguë. Les références structurées du
manifeste sont, elles, inspectées par champs typés. Le stockage namespacé évite
un churn de génération dans `map_core`, au prix d’un contrat moins visible que
des champs de premier rang ; les parseurs stricts et les tests de bornes
compensent ce risque pour la phase actuelle.

État Git final attendu après commit : arbre propre sur
`feat(authoring): add visual library authoring`.
