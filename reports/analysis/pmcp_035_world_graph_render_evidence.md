# PMCP-035 — Evidence Pack relations inter-maps, graphe et rendu

Date : 2026-07-31

Lot : `PMCP-035`

Verdict proposé : `DONE`

## 1. Résultat livré

Le lot ferme la Phase 4 avec une API pure et typée pour :

- le CRUD des warps et connexions ;
- la création, mise à jour et suppression de paires réciproques ;
- les change sets récupérables touchant les deux maps ;
- l'inspection déterministe du graphe, les ensembles connecté/déconnecté,
  le pathfinding et les diagnostics de cohérence ;
- la preview d'alignement des connexions ;
- le rendu révisionné d'une map, région ou sélection de layers via port ;
- les overlays collision effective, zones, warps et entités en PNG ;
- l'absence d'un modèle persistant de coordonnées mondiales inventé.

Les actions à suffixe `_apply` utilisent la commande générique `plan` de
l'Authoring API pour leur dry-run. Des pseudo-actions `_plan` distinctes ne
sont donc pas enregistrées, conformément au précédent `map.delete_apply` : un
même builder pur produit le plan gelé ensuite appliqué par la transaction.

## 2. Audit initial

État Git initial : arbre propre sur `5fe4c6763` (`feat(authoring): add spatial map authoring`).

Constats :

- `map_core` fournissait déjà `MapWarp`, `MapConnection` et leurs opérations
  locales, mais ne validait pas la cohérence entre plusieurs documents ;
- les use cases historiques de `map_editor` savaient créer un retour, mais la
  sauvegarde de la cible restait séparée de celle du document source ;
- la Phase 3 fournissait déjà le journal, le CAS par ressource, la reprise et
  la compensation nécessaires pour sécuriser un change set de deux maps ;
- aucun graphe canonique ne réunissait warps et connexions ;
- aucun port path-free ne liait un rendu de map à la révision exacte lue ;
- le projet ne persiste aucune coordonnée globale des maps. Ce lot devait
  préserver cette vérité au lieu de déduire une disposition depuis l'UI.

La documentation Flame configurée a été consultée pour le rendu hors écran,
mais les recherches n'ont retourné aucun résultat exploitable. L'adaptateur
retenu n'utilise donc pas un lifecycle Flame inventé : il produit un raster
diagnostique déterministe avec la dépendance `image` déjà présente dans
`map_runtime`.

## 3. Passes nommées et verdicts

Aucun sub-agent n'a été lancé, conformément à la contrainte d'exécution active.
Les passes indépendantes demandées par les règles de rapport ont été réalisées
localement.

| Passe | Objet | Verdict |
|---|---|---|
| `Audit inter-maps` | Modèles core, use cases editor, transaction Phase 3, absence de layout | Conforme |
| `TDD contrats` | Test rouge sur actions, graphe et port absents, puis implémentation minimale | Conforme |
| `Transaction récupérable` | Crash après promotion de la première map, reprise et cohérence des deux maps | Conforme |
| `Relations réciproques` | Create/update/delete warp et connection avec invariants inverses | Conforme |
| `World graph` | Tri stable, connexité dirigée, déconnectés, BFS, diagnostics | Conforme |
| `Rendu révisionné` | Map/région/layers, PNG et quatre overlays, refus d'un résultat stale | Conforme |
| `Architecture` | `map_authoring` reste pur ; l'adaptateur raster reste propriétaire de `map_runtime` | Conforme |
| `Régression` | Suites complètes/focalisées et analyses des packages concernés | Conforme |
| `Auto-review` | Contrats stricts, bornes, déterminisme, contenu de l'annexe et whitespace | Conforme avec limites documentées |

## 4. Implémentation

### 4.1 Warps et connexions

`warp_connection_actions.dart:63-987` expose onze mutations canoniques :

- `warp.create`, `warp.update`, `warp.delete` ;
- `warp.create_reciprocal_apply`, `warp.update_pair_apply`,
  `warp.delete_pair_apply` ;
- `connection.upsert`, `connection.delete` ;
- `connection.create_bidirectional_apply`,
  `connection.update_bidirectional_apply`,
  `connection.delete_bidirectional_apply`.

Le même domaine fournit list/get, `validateWarpTarget`,
`validateWarpPairs`, `validateConnections` et `previewAlignment`. Les paires
de warps inversent positions, cible, mode, padding et facings ; les connexions
inversent direction et offset. Les paramètres inconnus et cibles hors projet
ou hors limites sont refusés avec des codes stables.

`warp_connection_actions.dart:540-624` construit un seul
`AuthoringChangeSet` à partir des préimages exactes des deux documents. Le
journal transactionnel existant assure ensuite CAS, staging, promotion,
reprise, compensation, historique et undo.

### 4.2 Graphe monde

`world_graph_queries.dart:1-358` construit un graphe dirigé et trié à partir
des connexions et warps chargés. Il expose :

- `inspect` avec nœuds, arêtes et diagnostics ;
- `listConnected` et `listDisconnected` depuis une map ;
- `findPath` par BFS et voisinage trié ;
- `validateConsistency` ;
- un modèle logique `render` sans coordonnées persistées.

Les diagnostics couvrent document/manifest manquant, cible absente, position
de warp hors limites, connexion sans overlap et réciproque incohérente.

### 4.3 Port et adaptateur de rendu

`map_render_port.dart:14-312` définit `MapRenderRequest`, `MapRenderResult`,
`MapRenderPort` et `MapRenderQueries`. La requête doit porter une
`AuthoringResourceRef(kind: map)` avec SHA-256, une map possédée par le
manifest, une région interne et des IDs de layers connus. La façade rejette un
résultat dont la révision, la région ou les dimensions divergent de la requête.

`runtime_authoring_map_render_adapter.dart:10-303` implémente le port dans le
package runtime. Il génère un PNG déterministe, rend la totalité ou une région,
respecte une sélection de layers et superpose :

- collision effective issue de PMCP-034 ;
- zones de gameplay ;
- warps ;
- footprints d'entités.

Le résultat consigne les dimensions, la révision source, la région, les layers,
les overlays et leurs nombres effectivement visibles.

### 4.4 Exposition

- `map_authoring.dart:41-52` exporte actions, graphe et port ;
- `map_mutation_dispatcher.dart:17-118` enregistre les onze mutations ;
- `map_runtime.dart:119-120` exporte l'adaptateur ;
- `map_runtime/pubspec.yaml:31-32` déclare la dépendance locale vers
  `map_authoring` ; aucun lockfile ignoré n'est ajouté au commit.

## 5. Inventaire complet

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/pubspec.yaml`

Créés :

- `packages/map_authoring/lib/src/domains/maps/warp_connection_actions.dart`
- `packages/map_authoring/lib/src/domains/maps/world_graph_queries.dart`
- `packages/map_authoring/lib/src/ports/map_render_port.dart`
- `packages/map_authoring/test/domains/maps/warp_connection_transaction_test.dart`
- `packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart`
- `packages/map_runtime/test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart`
- `reports/analysis/pmcp_035_world_graph_render_evidence.md`
- `reports/analysis/pmcp_035_world_graph_render_evidence_appendix.md`

Le contenu intégral des six fichiers source/test créés est reproduit dans
`pmcp_035_world_graph_render_evidence_appendix.md`. Les fichiers de rapport ne
se recopient pas eux-mêmes afin d'éviter une récursion documentaire.

## 6. Zones de diff précises

- `warp_connection_actions.dart:14-60` : contrats de preview et diagnostic ;
- `warp_connection_actions.dart:63-290` : catalogue, queries et dispatch ;
- `warp_connection_actions.dart:292-529` : workflows warp/connection ;
- `warp_connection_actions.dart:540-987` : change set multi-map, validation et helpers ;
- `world_graph_queries.dart:11-97` : contrats sérialisables ;
- `world_graph_queries.dart:101-291` : inspection, connexité, pathfinding et rendu logique ;
- `map_render_port.dart:14-151` : requête/résultat révisionnés ;
- `map_render_port.dart:153-312` : port, façade et validations de scope ;
- `runtime_authoring_map_render_adapter.dart:10-303` : raster et overlays ;
- `warp_connection_transaction_test.dart:1-634` : preuves domaine, graphe, port et recovery ;
- `runtime_authoring_map_render_adapter_test.dart:1-154` : preuve PNG et overlays.

## 7. Commandes et résultats exacts

### TDD initial

```text
cd packages/map_authoring
dart test test/domains/maps/warp_connection_transaction_test.dart
```

Résultat rouge attendu : échec de compilation sur
`WarpConnectionActions`, `WorldGraphQueries`, `MapRenderRequest` et
`MapRenderOverlay` absents.

```text
cd packages/map_runtime
flutter test test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart
```

Résultat rouge attendu : fichier et classe
`RuntimeAuthoringMapRenderAdapter` absents.

### Dépendances et format

```text
cd packages/map_runtime
flutter pub get
Changed 1 dependency!
```

```text
cd packages/map_authoring
dart format lib/map_authoring.dart lib/src/domains/maps/map_mutation_dispatcher.dart lib/src/domains/maps/warp_connection_actions.dart lib/src/domains/maps/world_graph_queries.dart lib/src/ports/map_render_port.dart test/domains/maps/warp_connection_transaction_test.dart
Formatted 6 files (0 changed) in 0.02 seconds.
```

```text
cd packages/map_runtime
dart format lib/map_runtime.dart lib/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart
Formatted 3 files (0 changed) in 0.02 seconds.
```

### Tests et analyses

```text
cd packages/map_authoring
dart test test/domains/maps/warp_connection_transaction_test.dart
00:00 +10: All tests passed!

dart test
00:13 +230: All tests passed!

dart analyze
Analyzing map_authoring...
No issues found!
```

```text
cd packages/map_runtime
flutter test test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart
00:00 +2: All tests passed!

flutter test
03:42 +2276 ~1: All tests passed!

flutter analyze
Analyzing map_runtime...
No issues found!
```

```text
cd packages/map_editor
flutter test test/application/use_cases/map_lifecycle_use_cases_test.dart test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
00:00 +42: All tests passed!
```

```text
cd packages/map_core
dart analyze
Analyzing map_core...
No issues found!
```

### CLI et Git

```text
cd packages/map_authoring
dart run bin/pokemap_authoring.dart --root ../../examples/playable_runtime_host </dev/null
```

Résultat : code 0, stdout/stderr vides.

Le `git diff --cached --check` final est exécuté après staging et doit rester
sans sortie. Un diagnostic de processus lancé pendant la longue suite runtime
a affiché des arguments d'un processus externe ; cette sortie non pertinente
et potentiellement sensible n'est volontairement pas reproduite.

## 8. Décisions et non-objectifs

- Le graphe est dirigé : une relation à sens unique est traversable uniquement
  dans le sens authoré. Les opérations de paire créent les deux arêtes.
- `validateWarpPairs` est une validation explicite de paires ; les warps à sens
  unique restent autorisés par le CRUD et par le graphe général.
- Aucun `worldLayout` global, aucune coordonnée de map et aucun éditeur de monde
  fictif ne sont créés. `WorldGraphRenderModel` ne transporte que nœuds/arêtes
  et `hasPersistentLayout: false`.
- L'adaptateur raster est une preuve diagnostique, pas une capture asset-perfect
  du jeu. Le port permet de substituer plus tard un renderer fidèle sans
  changer les contrats MCP.
- Les use cases historiques de `map_editor` ne sont pas recâblés vers une
  session Authoring complète dans ce lot. Leur comportement est caractérisé
  par 42 tests ; le chemin MCP canonique utilise dès maintenant la transaction
  récupérable multi-map.

## 9. Auto-critique et risques

- `warp_connection_actions.dart` est volumineux car il regroupe catalogue,
  parsing strict, invariants et construction transactionnelle. Une séparation
  interne future sera pertinente si de nouveaux types de relations arrivent.
- La collision effective du rendu reconstruit son index par requête. Le résultat
  est sûr et déterministe ; une cache indexée par révision nécessitera du
  profilage avant d'être ajoutée.
- Le raster diagnostique représente les cellules sémantiquement et ne charge
  pas encore les atlases, animations, ombres ou matériaux runtime réels.
- La cohérence des connexions exige une réciproque exacte dans le diagnostic du
  graphe ; le CRUD unitaire continue volontairement à permettre une étape
  intermédiaire unidirectionnelle.
- Les tests de recovery prouvent la reprise avant/arrière via le moteur Phase 3,
  mais ne simulent pas chaque checkpoint pour ce domaine ; la matrice complète
  des checkpoints reste couverte par les tests transactionnels génériques.

## 10. Clôture

Les preuves fonctionnelles, transactionnelles, architecturales, visuelles et
de régression sont réunies. `PMCP-035` peut être proposé `DONE` après son commit
dédié. Ce commit ferme les six lots PMCP-030 à PMCP-035 de la Phase 4.
