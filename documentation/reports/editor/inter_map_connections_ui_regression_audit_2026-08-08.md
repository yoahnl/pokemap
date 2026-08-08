# Audit de régression UI — connexions physiques entre maps

## 1. Identification du lot

- **Nom exact** : Audit de régression UI — connexions physiques entre maps.
- **Date de vérification** : 8 août 2026.
- **Surface** : `packages/map_editor`, workspace **World Maps**.
- **Lot mécanique adjacent** : `FG-090 — Warp Command V0`, actuellement `PARTIAL` dans la roadmap. Ce lot est adjacent mais ne couvre pas à lui seul les connexions physiques de bord de carte.
- **Verdict global** : **régression confirmée, impact fonctionnel élevé pour l’authoring no-code**.

Le moteur, le schéma et les mutations de l’API canonique savent toujours représenter et exécuter une `MapConnection`. La régression est localisée au shell desktop : le panneau historique `MapConnectionsPanel` existe encore, mais son unique montage de production passe par `MapInspectorPanel`, qui a été retiré du workspace World Map le 30 juillet 2026. L’inspecteur adaptatif qui l’a remplacé ne propose aucune destination « Connexions ». L’audit révèle en plus une parité MCP incomplète pour la lecture et le diagnostic sémantiques, malgré des mutations `connection.*` opérationnelles.

## 2. Scope et non-objectifs

### Inclus

- confirmer l’absence du point d’entrée visible à partir de la capture utilisateur et du shell actuel ;
- distinguer les connexions physiques de bord (`MapConnection`) des warps (`MapWarp`) ;
- tracer le modèle, l’éditeur, l’API canonique, JSONL/CLI, MCP, gameplay et runtime ;
- dater la régression dans l’historique Git ;
- inventorier les tests qui ont permis ou figé la régression ;
- proposer un lot de correction borné.

### Exclus

- aucune correction produit ;
- aucune modification de roadmap ;
- aucune migration de données ;
- aucun changement runtime ou de schéma ;
- aucune opération Git d’écriture.

## 3. État Git initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat : sortie vide, worktree propre.

## 4. Parcours audité et état UX

La capture fournie par l’utilisateur montre une map ouverte dans **World Maps**, le toolbelt en haut et l’inspecteur **Calques** à droite. Aucun contrôle « Connexions » n’est visible dans le toolbelt, l’en-tête de map ou l’inspecteur adaptatif.

| Étape | Action utilisateur | Santé | Constat |
|---|---|---|---|
| 1 | Ouvrir **World Maps** et sélectionner une map | Saine | La map, les calques et les outils sont accessibles. |
| 2 | Chercher la configuration des maps adjacentes | Dégradée | Aucun point d’entrée « Connexions » dans le shell courant. |
| 3 | Créer, éditer, supprimer ou ouvrir une connexion nord/sud/est/ouest | Bloquée | Le panneau qui porte ces opérations n’est plus monté. |
| 4 | Placer ou sélectionner un warp | Partielle, mais distincte | `WarpPropertiesPanel` reste accessible via **Placer** ou la sélection d’un warp. Un warp ne remplace pas une continuité physique de bord. |

### Risques UX et accessibilité

- La capacité n’est pas seulement difficile à découvrir : aucun contrôle atteignable ne monte son panneau.
- Les connexions déjà présentes ne disposent plus d’un résumé de map, d’un badge ou d’un chemin clavier dans le shell courant.
- L’alternative apparente « Placer > warp » induit une confusion de modèle : porte/escalier/téléportation et continuité de bord ne sont pas équivalents.
- Il est impossible d’évaluer le focus, les libellés sémantiques ou l’ordre clavier d’un contrôle absent. Cet audit ne revendique donc pas une conformité WCAG complète.
- La capture originale provenait d’un chemin temporaire macOS, expiré avant la consolidation du rapport. Elle a été inspectée dans la conversation mais n’a pas pu être copiée dans le dépôt ; les conclusions structurelles reposent aussi sur le code et les tests exécutés.

## 5. Audit initial du code

### 5.1 Le panneau historique existe encore

`packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart:477-491` conserve la section **Connexions**, son badge `activeMap.connections.length` et `MapConnectionsPanel(embedded: true)`.

`packages/map_editor/lib/src/ui/panels/map_connections_panel.dart:12-22` définit toujours le panneau. Il propose, pour chaque direction cardinale :

- un picker de map cible ;
- un offset entier ;
- l’enregistrement via `saveMapConnection` ;
- l’ouverture de la map cible via `requestEditorConnectedMapActivation` ;
- la suppression via `deleteMapConnection`.

Les appels sont encore présents dans `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:7778-7867`.

### 5.2 Le shell courant ne peut plus le monter

`packages/map_editor/lib/src/features/editor/application/world_map_tool_family.dart:21-29` déclare les kinds d’inspecteur : `paint`, `erase`, `place`, `objectSelection`, `cellSelection`, `layers`, `environment`, `empty`. Il n’existe aucun kind `connections`.

`packages/map_editor/lib/src/features/editor/presentation/world_map/adaptive_map_inspector.dart:170-204` projette exactement ces huit corps et ne référence pas `MapConnectionsPanel`.

La recherche de production suivante :

```bash
rg -n 'MapConnectionsPanel|MapInspectorPanel' packages/map_editor/lib
```

ne trouve `MapConnectionsPanel` que dans sa propre définition et dans `MapInspectorPanel`. `MapInspectorPanel` n’a plus d’instanciation dans le shell de production.

Le test `packages/map_editor/test/editor_shell_page_smoke_test.dart:77-89` exige même que `AdaptiveMapInspector` soit présent et que `MapInspectorPanel` soit absent.

### 5.3 Les warps ont été remigrés, pas les connexions physiques

Le nouveau workspace contient `warp` dans `WorldMapPlacementSubtool` (`world_map_tool_family.dart:12-19`) et projette `WarpPropertiesPanel` lors du placement ou de la sélection d’un warp. Il ne s’agit donc pas d’une disparition générale des transitions inter-maps : la perte concerne spécifiquement l’authoring map-scoped des connexions de bord.

## 6. Cause racine et historique Git

La cause racine est le cutover vers l’inspecteur adaptatif sans checklist de parité fonctionnelle du panneau historique.

### Chronologie

1. Le commit `104e2aacd42a3a076d1a73ed874655a56dbb0790` du 29 juillet 2026 caractérisait encore la seam World Map en exigeant un descendant `MapInspectorPanel`.
2. Le commit `db26f41ea6b0062fca28fd7c0b60230fe0de71da` du 30 juillet 2026, `feat(map-editor): integrate adaptive map inspector`, supprime l’import et l’injection `inspectorSlot: const MapInspectorPanel()`, puis branche `AdaptiveMapInspector`.
3. Le même commit transforme le test pour exiger `MapInspectorPanel == findsNothing`, sans ajouter de kind, de bouton ni de test « Connexions » dans l’inspecteur adaptatif.

### Pourquoi les tests n’ont pas protégé la fonctionnalité

- Les tests de migration validaient la nouvelle structure du shell, pas l’inventaire fonctionnel de l’ancien inspecteur.
- `adaptive_map_inspector_test.dart` vérifie qu’un corps existe pour chaque kind déclaré ; comme `connections` n’est pas dans l’enum, le test est vert tout en ignorant la capacité.
- Aucun test de `packages/map_editor/test` ne référence `saveMapConnection`, `deleteMapConnection`, `requestEditorConnectedMapActivation` ou `MapConnectionEditingService`.
- Il manque un test widget end-to-end : workspace World Map réel → ouvrir Connexions → choisir une map → sauver → relire le modèle → ouvrir/supprimer.

## 7. État des contrats hors UI

| Couche | Statut | Preuve |
|---|---|---|
| Schéma `map_core` | **SUPPORTED** | `MapConnection(direction, targetMapId, offset)` dans `map_data.dart:447-456`. |
| Gameplay pur | **SUPPORTED** | sortie de bord → `ConnectionTriggered` dans `gameplay_step.dart:37-54`; résolution d’arrivée dans `gameplay_connection.dart:3-40`. |
| Runtime | **SUPPORTED** | consommation de `ConnectionTriggered` dans `playable_map_game.dart:4350-4356`. |
| API canonique `map_authoring` | **SUPPORTED** | cinq actions : `connection.upsert`, `connection.delete`, create/update/delete bidirectionnelles. |
| JSONL/CLI | **SUPPORTED** | PMCP-085 et full parity verts. |
| MCP live — mutations | **SUPPORTED** | `pokemap_describe` expose les cinq actions `connection.*`; les dry-runs JSONL et MCP bidirectionnels réussissent. |
| MCP live — lecture/diagnostic | **PARTIAL** | `mapConnection` est absent des `resourceKinds` requêtables ; la lecture générique de `map` ne remplace pas les opérations sémantiques prévues. |
| Transport editor canonique | **MISSING** | le catalogue le déclare, mais aucun `actionId: connection.*` ni test/consommateur canonique n’existe dans `map_editor`. |
| UI desktop actuelle | **MISSING** | aucun kind/corps/point d’entrée `connections`. |
| Ancien chemin de mutation editor | **DEBT** | `MapConnectionsPanel` passe encore par des use cases locaux `map_editor`, pas par l’adapter canonique `map_authoring`. |

Le bloc `fullParity` de `pokemap_describe` rapporte `mapConnection` comme supporté et annonce le transport editor, mais le catalogue top-level ne publie pas cette ressource parmi les `resourceKinds` et le code editor ne consomme aucune action canonique `connection.*`. Un `pokemap_query(resourceKind: mapConnection)` échoue avec `query.resource_kind_unsupported`, et un `map get` avec le field mask `id,connections` échoue avec `query.field_mask_unknown`. Le catalogue cible prévoit pourtant `connection.list/get/preview_alignment/validate` et `world_graph.*`. Selon la règle de parité PokeMap, la lecture générique du JSON de `map` et une déclaration de catalogue sans consommateur editor sont insuffisantes : la parité globale doit donc être déclarée `PARTIAL`.

Autre nuance : une référence de connexion absente est classée comme warning d’authoring ; `pokemap_validate` ne la rend pas globalement bloquante. Les mutations canoniques refusent bien une cible absente, mais le diagnostic d’un projet legacy reste moins strict.

## 8. Recommandation de correction

### Lot recommandé

**WM-CONN-01 — Restaurer l’authoring canonique des connexions physiques dans l’inspecteur adaptatif.**

### Critères d’acceptation minimaux

1. Ajouter un point d’entrée visible et nommé **Connexions** dans le workspace World Map.
2. Ajouter un `WorldMapInspectorKind.connections` et un corps adaptatif dédié fondé sur les widgets du design system.
3. Conserver le picker guidé de map, l’offset, le résumé par direction, l’ouverture de la cible et la suppression.
4. Ne pas remonter simplement le panneau legacy inchangé : router les mutations via les actions canoniques `map_authoring`.
5. Rendre explicite le choix **sens unique** ou **créer/mettre à jour la réciproque** ; le comportement par défaut reste une décision produit à valider pendant le lot.
6. Afficher les conflits : absence de recouvrement, connexion opposée incompatible, cible manquante, état sale et échec de révision.
7. Ajouter un test shell qui échoue si le point d’entrée disparaît, puis des tests de création, modification, réciproque, ouverture et suppression.
8. Rejouer la parité direct API / JSONL / editor / MCP des mutations et un smoke runtime de sortie de bord.

### Follow-up MCP séparé

**PMCP-CONN-READ — Exposer la lecture et le diagnostic sémantiques des connexions.** Ce chantier ne doit pas élargir le correctif UI `WM-CONN-01`. Il couvre `mapConnection`, `connection.list/get/preview_alignment/validate`, `world_graph.*`, le field mask documenté et l’alignement honnête du catalogue PMCP-085 avec le serveur live.

### Non-recommandation

Réinjecter globalement `MapInspectorPanel` serait une régression architecturale : cela réintroduirait tout l’ancien inspecteur parallèlement au nouveau et conserverait un chemin de mutation editor spécifique. La correction doit porter la capacité dans l’architecture adaptative actuelle.

## 9. Roadmap

`FG-090 — Warp Command V0` reste `PARTIAL`. L’audit ne propose pas `DONE` :

- la roadmap distingue explicitement le warp authoré des connexions physiques ;
- la régression UI ne casse pas le handler/runtime de warp ;
- elle ouvre un gap d’authoring d’exploration à traiter dans un lot editor dédié, sans modifier la roadmap dans cette tâche.

## 10. Vérifications exécutées

### Découverte et historique en lecture seule

```bash
rg -n 'MapConnectionsPanel|MapInspectorPanel' packages/map_editor/lib
rg -n 'saveMapConnection|deleteMapConnection|MapConnectionEditingService' \
  packages/map_editor/lib packages/map_editor/test
git log --all -p -S'MapInspectorPanel' -- \
  packages/map_editor/lib/src/ui/editor_shell_page.dart \
  packages/map_editor/test/editor_shell_page_smoke_test.dart
git show db26f41ea6b0062fca28fd7c0b60230fe0de71da -- \
  packages/map_editor/lib/src/ui/editor_shell_page.dart \
  packages/map_editor/test/editor_shell_page_smoke_test.dart
```

Résultat : panneau présent mais aucune instanciation de production ; aucun test editor des opérations de connexion ; cutover identifié sans ambiguïté dans `db26f41ea`.

### Tests UI ciblés

```bash
cd packages/map_editor
flutter test test/editor_shell_page_smoke_test.dart \
  test/features/editor/presentation/world_map/adaptive_map_inspector_test.dart \
  test/features/editor/application/world_map_inspector_projector_test.dart
```

Résultat : **52 tests passés, 0 échec**. Le premier test confirme aussi l’absence actuelle de `MapInspectorPanel`.

### Contrats d’authoring et parité

```bash
cd packages/map_authoring
dart test test/domains/maps/warp_connection_transaction_test.dart \
  test/parity/full_authoring_parity_test.dart
```

Résultat : **16 tests passés, 0 échec**.

Nuance de couverture : `full_authoring_parity_test.dart` prouve ses goldens `map.create` et `presentation.update`, pas une mutation `connection.*` spécifique. Le contrat dédié `warp_connection_transaction_test.dart` couvre les cinq actions de connexion côté API directe.

Vérifications supplémentaires des passes spécialisées :

```bash
dart test test/domains/maps/warp_connection_transaction_test.dart
dart test test/parity/full_authoring_parity_test.dart
dart test test/tooling/jsonl_mutation_worker_test.dart
```

Résultats : respectivement **10/10**, **6/6** et **2/2**, sans échec. Le dernier test vérifie le worker JSONL générique, pas une connexion spécifique.

```bash
dart run tool/pmcp085_conformance.dart && dart analyze
```

Résultat : exit `0`; PMCP-085 rapporte `resourceCount: 62`, `mutationActionCount: 229`, `blockedOrMissingCount: 0`, `catalogComplete: true`; analyse : **No issues found**.

### Gameplay

```bash
cd packages/map_gameplay
dart test test/narrative_physical_reachability_validator_test.dart
```

Résultat : **10 tests passés, 0 échec**, dont les deux cas de suivi de connexions physiques.

Filtre supplémentaire :

```bash
dart test test/narrative_physical_reachability_validator_test.dart --name connection
```

Résultat : **2/2**, sans échec.

### Runtime ciblé

```bash
cd packages/map_runtime
flutter test test/playable_map_game_input_test.dart --plain-name connection
```

Résultat : **9/9**, sans échec.

### MCP

```bash
cd tools/pokemap_mcp
npm run check && npm test
```

Résultat : TypeScript check et build réussis ; **36 tests passés, 0 échec**.

Le `pokemap_describe` live retourne `ok: true` et expose les cinq actions de mutation avec transports `cli`, `directApi`, `editor`, `mcp`. Deux dry-runs ad hoc de `connection.create_bidirectional_apply`, l’un via JSONL et l’autre via MCP, ont réussi sur la fixture `golden_fangame_slice` : deux chemins `/connections`, `golden_route` et `golden_town`, recouvrement `5`, `applicable: false` en dry-run.

En revanche, il n’existe pas encore de test JSONL permanent spécifique à `connection.*`, et la ressource sémantique `mapConnection` n’est pas requêtable dans le catalogue live.

#### Payloads live reproductibles

Les handles opaques sont volontairement remplacés par `<handle>` et `<workspaceHandle>`.

```json
{}
```

`pokemap_describe` : `ok: true`, 62 ressources de parité, 229 mutations, 0 manquante/bloquée, 12 resource kinds requêtables, `mapConnection` non requêtable, cinq mutations `connection.*` publiées.

```json
{
  "projectHandle": "<handle>",
  "resourceKind": "mapConnection",
  "operation": "list"
}
```

Résultat : `ok: false`, `query.resource_kind_unsupported`, non retryable.

```json
{
  "projectHandle": "<handle>",
  "resourceKind": "map",
  "operation": "get",
  "ids": ["golden_route"],
  "fieldMask": ["id", "connections"]
}
```

Résultat : `ok: false`, `query.field_mask_unknown`, non retryable.

Ouverture JSONL préalable :

```json
{
  "id": "o",
  "command": "open",
  "args": {
    "projectRoot": "<repo-root>/examples/playable_runtime_host/golden_fangame_slice"
  }
}
```

Query préalable pour obtenir la révision :

```json
{
  "id": "q",
  "command": "query",
  "args": {
    "projectHandle": "<handle>",
    "request": {
      "resourceKind": "map",
      "operation": "list",
      "view": "summary",
      "ids": [],
      "fieldMask": [],
      "filters": {},
      "sort": [],
      "pageSize": 1
    }
  }
}
```

Plan JSONL/CLI exact :

```json
{
  "id": "p",
  "command": "plan",
  "args": {
    "projectHandle": "<handle>",
    "request": {
      "requestId": "audit-jsonl-connection-5",
      "actionId": "connection.create_bidirectional_apply",
      "actionVersion": 1,
      "workspaceHandle": "<workspaceHandle>",
      "parameters": {
        "mapId": "golden_route",
        "direction": "east",
        "targetMapId": "golden_town",
        "offset": 0
      },
      "expectedRevision": "sha256:4bfb16c58403d8640a6be7c8be9915264a2dab14f3b0fd36d1fead51f1b53979",
      "idempotencyKey": "audit-jsonl-connection-20260808-5",
      "dryRun": true
    }
  }
}
```

Résultat compact : open/query/plan `success`, deux maps modifiées, directions east/west, recouvrement `5`, deux chemins `/connections`, `applicable: false`, raison `dry_run`.

Plan MCP exact :

```json
{
  "projectHandle": "<handle>",
  "request": {
    "requestId": "audit-map-connection-plan-20260808-b",
    "actionId": "connection.create_bidirectional_apply",
    "actionVersion": 1,
    "workspaceHandle": "<workspaceHandle>",
    "parameters": {
      "mapId": "golden_route",
      "direction": "east",
      "targetMapId": "golden_town",
      "offset": 0
    },
    "expectedRevision": "sha256:4bfb16c58403d8640a6be7c8be9915264a2dab14f3b0fd36d1fead51f1b53979",
    "idempotencyKey": "audit-map-connection-plan-20260808-b",
    "dryRun": true
  }
}
```

Résultat : `ok: true`, deux ressources `map` (`golden_route`, `golden_town`), deux opérations `replace /connections`, directions east/west, recouvrement `5`, garantie multi-map `recoverable`, non applicable car dry-run.

Incident de vérification non produit : un premier filtre `jq` du résultat PMCP utilisait la clé inexistante `.actions` et a quitté avec le code `5`. Le même contrôle a été relancé avec la clé correcte `.mutationActions` et a confirmé les cinq actions.

### Analyse Flutter

```bash
cd packages/map_editor
flutter analyze
```

Résultat : exit `1`, **9 infos** `prefer_const_constructors`, toutes dans `test/features/editor/presentation/world_map/world_map_smart_tile_density_wiring_test.dart`. Elles sont hors scope et n’ont pas été modifiées.

Analyse ciblée :

```bash
flutter analyze \
  lib/src/ui/panels/map_connections_panel.dart \
  lib/src/ui/panels/map_inspector_panel.dart \
  lib/src/features/editor/presentation/world_map/adaptive_map_inspector.dart \
  lib/src/features/editor/application/world_map_inspector_projector.dart
```

Résultat : **No issues found**.

### Build

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat : exit `0`, `✓ Built build/macos/Build/Products/Debug/PokeMap.app`.

### Hygiène Markdown

```bash
bash tools/scripts/check_markdown_hygiene.sh
```

Résultat initial : exit `1`, car la limite par défaut est zéro nouveau Markdown.

Interprétation appliquée du `AGENTS.md` racine : une demande explicite d’audit autorise un unique rapport consolidé sous `documentation/reports/<domain>/`. L’override a donc été borné à ce seul document :

```bash
POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh
```

Résultat final : exit `0`, `1 new Markdown file(s), all in canonical locations`.

## 11. Verdict des passes spécialisées

| Passe | Verdict |
|---|---|
| Audit / Architecture | Modèle, mutations canoniques, gameplay et runtime présents ; montage UI absent et lecture/diagnostic MCP sémantique seulement partiels. |
| UI / Historique | Régression confirmée dans `db26f41ea` : retrait de `MapInspectorPanel`, omission de `MapConnectionsPanel` dans l’inspecteur adaptatif. |
| Implémentation | **N/A par scope** : aucune correction demandée ni autorisée. |
| Tests | Suites ciblées vertes ; zéro consommation `connection.*` dans les tests/editor adapters, aucun test JSONL permanent spécifique et aucune protection de parité fonctionnelle « Connexions ». |
| Build / Validation | Build macOS vert ; analyse ciblée verte ; analyse package non verte à cause de 9 infos hors scope. |
| Critique finale | Premier verdict `À CORRIGER` : parité MCP surévaluée, chantier MCP mélangé au lot UI, sévérité non étayée et clôture incomplète ; points corrigés. La seconde relecture a contesté l’autorisation du fichier persistant. Objection non retenue : le `AGENTS.md` racine autorise explicitement un rapport consolidé quand le prompt demande un audit, ce qui est le cas ; l’override reste borné à `1`. |

## 12. Fichiers modifiés

Un seul fichier est créé :

- `documentation/reports/editor/inter_map_connections_ui_regression_audit_2026-08-08.md`
  - zones : verdict, audit initial, historique, matrice de parité, preuves de commandes, recommandations, risques et auto-critique ;
  - raison : conserver une preuve d’audit consolidée ;
  - impact produit : aucun, documentation uniquement.

Aucun test, fichier Dart, manifeste, fixture ou fichier généré n’est modifié.

## 13. Limites, risques et auto-critique

### Limites conservées

- Aucun parcours manuel cliquable n’a été rejoué dans l’application desktop ; la capture utilisateur, la composition widget et les tests shell constituent les preuves UI.
- Le test MCP complet prouve le serveur et la parité générique ; aucune mutation d’un projet utilisateur réel n’a été effectuée.
- Les dry-runs JSONL/MCP ont utilisé une fixture de dépôt et n’ont écrit aucune donnée.
- L’audit n’affirme pas que l’ancien `MapConnectionsPanel` est prêt à être remonté tel quel : son chemin de mutation local doit être remplacé ou adapté.

### Risques du futur correctif

- créer deux systèmes parallèles si le panneau legacy est remonté sans adapter canonique ;
- n’éditer qu’un côté d’une connexion et laisser une réciproque incohérente ;
- perdre l’état sale, undo/redo ou les garde-fous de révision ;
- mélanger connexion physique et warp dans les libellés ;
- ajouter un kind sans point d’entrée réellement découvrable ou testable au clavier.

### Auto-critique

Le diagnostic est robuste sur la cause et le périmètre parce que le diff historique, la composition actuelle, le test shell et les contrats exécutés convergent. La critique indépendante a toutefois détecté une surévaluation initiale de la parité MCP : le rapport distingue désormais mutations, transport editor et lecture sémantique, et sépare le follow-up MCP du correctif UI. La preuve visuelle durable est plus faible : la capture originale n’a pas pu être conservée après expiration du fichier temporaire. Une passe manuelle lors du lot de correction devra capturer : ouverture de **Connexions**, création réciproque, navigation vers la cible, sauvegarde/rechargement et sortie de bord en playtest.

## 14. État Git final

Après vérification Markdown et avant critique finale :

```text
?? documentation/reports/editor/inter_map_connections_ui_regression_audit_2026-08-08.md
```

Aucun autre fichier suivi ou non suivi n’est présent dans le statut.
