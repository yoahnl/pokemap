# Encounter Studio — clôture de la phase 4

Date : 2026-08-10

Branche : `feature/encounter-studio-phase-1`

Worktree : `/Users/karim/.config/superpowers/worktrees/pokemonProject/encounter-studio-phase-1`

## Verdict

La phase 4 est clôturable.

- `ENS-040 — Authoring Transport & Runtime End-to-End Certification` : **DONE**.
- `ENS-041 — Package Gates & Closure Evidence` : **DONE**, avec les échecs globaux préexistants et hors scope détaillés ci-dessous.
- `FG-108 — Encounter-table validation` : **PARTIAL au mieux**, sans modification de la roadmap mécanique. Les espèces, niveaux, poids et références de table disposent de validations ciblées, mais les conditions dépendant des flags et variables ne sont pas certifiées de bout en bout.

Les deux actions Encounter sont prouvées sur les quatre transports attendus :

- `campaign.encounter_table.upsert` ;
- `campaign.encounter_table.delete` ;
- transports : `directApi`, `cli`, `editor`, `mcp`.

Le résumé global PMCP reste volontairement `transportCertificationComplete: false` : seules quatre actions sur les 232 actions canoniques disposent actuellement d'une certification complète sur les quatre transports. Ce statut global n'invalide pas la certification ciblée des deux actions Encounter.

## État Git initial

- HEAD initial de phase 4 : `e4a41b593 feat(encounters): complete Encounter Studio phase 3`.
- Worktree initial : propre.
- Aucun changement Smart Tiles, modèle de projet, schéma ou runtime n'était requis pour cette phase.

## Audit initial

L'audit a confirmé que la persistance Encounter utilisait déjà les actions canoniques et que le runtime consommait déjà les tables persistées. Le manque réel était la preuve de transport :

- le manifeste de parité ne déclarait aucun chemin end-to-end pour les deux actions Encounter ;
- la parité API directe / JSONL n'était pas testée sur un payload complet ;
- le serveur MCP n'avait pas de scénario couvrant création, relecture, confirmation destructive et suppression ;
- l'éditeur et le runtime possédaient déjà les chemins fonctionnels nécessaires à la certification ciblée.

La solution a donc été volontairement limitée à la certification et aux tests, sans introduire une seconde API ni modifier les données de jeu.

## Lot ENS-040

Commit : `dfc488dcd test(encounters): certify authoring transport parity`

### Fichiers et zones modifiés

| Fichier | Zone | Changement |
|---|---:|---|
| `packages/map_authoring/lib/src/parity/full_authoring_parity.dart` | 327-340 | Publication des quatre chemins de preuve end-to-end pour `upsert` et `delete`. |
| `packages/map_authoring/test/parity/full_authoring_parity_test.dart` | 156-157, 263-347, 590-674 | Assertions de certification et scénario sémantique identique entre API directe et JSONL/CLI, avec entrées, taux et tags. |
| `tools/pokemap_mcp/test/mutation_server.test.ts` | 900-1014 | Scénario MCP complet : découverte, ouverture, validation, création, relecture, refus sans confirmation, suppression confirmée et fermeture. |

Diff du lot : 3 fichiers, 344 insertions.

### TDD et preuve ciblée

Le test de parité a d'abord échoué parce que `endToEndVerifiedTransports` était vide pour les actions Encounter. Après ajout de la preuve, un premier passage a révélé que le test réutilisait une révision de reçu au lieu de la révision du snapshot relu ; le test a été corrigé pour reproduire le vrai contrat de transport.

Commandes finales :

```text
cd packages/map_authoring
dart test test/domains/gameplay/campaign_content_authoring_test.dart test/parity/full_authoring_parity_test.dart
```

Résultat : `+13: All tests passed!`

```text
cd packages/map_editor
flutter test test/authoring_api/editor_mutation_parity_test.dart test/encounter_studio_panel_test.dart
```

Résultat : `+21: All tests passed!`

Une première invocation avec `test/editor_mutation_parity_test.dart` a échoué au chargement parce que le fichier se trouve sous `test/authoring_api/`. La commande corrigée ci-dessus est la preuve retenue.

```text
cd packages/map_runtime
flutter test test/wild_battle_end_to_end_flow_test.dart
```

Résultat : `+17: All tests passed!`

```text
cd tools/pokemap_mcp
npm run check && npm test
```

Résultat isolé final : TypeScript propre, `39` tests, `39` réussites, `0` échec.

### Conformance PMCP

```text
cd packages/map_authoring
dart run tool/pmcp085_conformance.dart
```

Résultat :

- `resourceCount: 62` ;
- `mutationActionCount: 232` ;
- `blockedOrMissingCount: 0` ;
- `catalogComplete: true` ;
- `endToEndVerifiedMutationActionCount: 6` ;
- `fullyEndToEndVerifiedMutationActionCount: 4` ;
- `transportCertificationComplete: false` au niveau du catalogue entier.

### MCP live

Le serveur MCP configuré a été interrogé en conditions réelles. Il pointe encore vers le checkout principal, et non vers ce worktree. La preuve live a couvert :

- découverte de `campaign.encounter_table.upsert` et `campaign.encounter_table.delete` ;
- ouverture et validation d'un projet temporaire autorisé ;
- planification et application d'une table avec deux espèces, taux et tags ;
- relecture exacte via la ressource agrégée `project` avec le masque `encounterTables` ;
- fermeture du workspace.

La requête directe `resourceKind: encounterTable` renvoie actuellement `query.resource_kind_unsupported`. La relecture canonique disponible passe donc par l'agrégat `project`; cette limite est explicite et ne masque pas une preuve fictive.

Le projet temporaire a été déplacé dans la Corbeille à `/Users/karim/.Trash/codex-encounter-live-gbgD61`. Il reste récupérable.

## Lot ENS-041

### Gates globales

#### `map_authoring`

```text
cd packages/map_authoring
dart test -r expanded
```

Résultat isolé : `+479 -2`, deux échecs sans rapport avec Encounter :

- `test/registry/action_registry_test.dart` attend encore l'ancien inventaire minimal et n'inclut pas `projectPresentationProfile` ;
- `test/tooling/jsonl_worker_test.dart` compare un golden `describe` antérieur à cette même ressource.

Une première exécution en parallèle avait produit `+475 -10`, dont huit échecs benchmark. Ils ont disparu lors de l'exécution isolée et sont classés comme contention de la passe parallèle.

```text
dart analyze
```

Résultat : `No issues found!`

#### `map_editor`

```text
cd packages/map_editor
flutter test
```

La suite a atteint `+5153 ~11 -134` en `12:29`, puis a été interrompue après blocage du dernier worker Narrative. Les échecs observés sont hors scope Encounter :

- fixtures Selbrume Smart Tiles v2 refusées par le schéma v6 ;
- ressources, références et goldens Narrative manquants ;
- appels `runAsync` réentrants dans `narrative_event_map_banner_test.dart` ;
- timeout `pumpAndSettle` dans `pokemap_right_inspector_resize_test.dart` ;
- export externe dépendant de l'environnement local ;
- anciennes attentes Border Map.

Aucun test Encounter n'a échoué dans cette passe. La matrice Encounter isolée a ensuite été rejouée :

```text
flutter test test/encounter_tables_panel_test.dart test/encounter_studio_golden_test.dart test/encounter_probability_projection_test.dart test/encounter_tables_panel_mounting_test.dart test/encounter_table_use_cases_test.dart test/encounter_studio_panel_test.dart test/encounter_studio_responsive_test.dart
```

Résultat : `+30: All tests passed!`

```text
flutter analyze
```

Résultat : 378 diagnostics existants, soit 377 `info` et un `warning` dans `test/personalization/project_intro_video_import_service_test.dart:50`. Aucun `error`.

```text
flutter build macos
```

Résultat : `Built build/macos/Build/Products/Release/PokeMap.app (51.1MB)`. Les avertissements proviennent de `video_player_avfoundation` et d'une icône macOS non assignée.

#### `map_runtime`

```text
cd packages/map_runtime
flutter test test/wild_battle_end_to_end_flow_test.dart
```

Résultat : `+17: All tests passed!`

#### `tools/pokemap_mcp`

La première passe lancée en même temps que les suites Flutter a subi des timeouts et a été interrompue. La passe isolée finale est la preuve retenue :

```text
cd tools/pokemap_mcp
npm run check && npm test
```

Résultat : TypeScript propre ; `39` tests, `39` réussites, `0` échec, durée `92668.590542 ms`.

## Parité et non-objectifs

- API directe : prouvée.
- JSONL/CLI : prouvé.
- Éditeur : prouvé via `AuthoringMutationAdapter` et l'UI Encounter.
- MCP : prouvé par le test serveur et par une mutation live.
- Runtime : prouvé par les 17 scénarios de rencontre et combat sauvage.
- Aucun format JSON manuel n'est requis dans le parcours utilisateur.
- Aucun nouveau modèle, champ de schéma, contrat runtime ou primitive UI n'a été ajouté en phase 4.
- La certification globale des 232 actions PMCP n'est pas un objectif de cette phase.

## Auto-critique finale

### Architecture

**PASS.** La phase ne contourne pas `map_authoring`, ne couple pas l'éditeur au runtime et ne crée pas de transport spécial Encounter.

### Implémentation

**PASS.** Le diff de production se limite à la publication de preuves de parité. Le reste est du test de transport. Aucun churn adjacent n'a été introduit.

### Tests

**PASS ciblé / gates globales documentées.** Toutes les preuves Encounter passent. Les suites globales ont été exécutées ; leurs échecs hors scope sont nommés et n'ont pas été maquillés en succès.

### Build

**PASS.** La cible macOS Release est construite avec succès.

### Risques résiduels

- Le serveur MCP live configuré reste celui du checkout principal jusqu'à intégration et reconstruction de cette branche ; son résumé de parité peut donc être en retard sur la source du worktree.
- `encounterTable` n'est pas encore une ressource de lecture directe ; la relecture utilise `project.encounterTables`.
- `FG-108` ne peut pas devenir `DONE` tant que les conditions basées sur flags et variables ne sont pas validées de bout en bout.
- Les deux attentes globales `map_authoring` et les dettes globales `map_editor` restent à traiter dans des lots séparés pour éviter de mélanger leur correction à Encounter Studio.

## État Git attendu après clôture

- un commit ENS-040 dédié ;
- un commit ENS-041 dédié contenant ce rapport ;
- aucun fichier de build ou artefact temporaire suivi ;
- worktree propre ;
- aucun push effectué.
