# DS‑04 — Préflight des dépendances de maps

- **Date de clôture :** 2026-07-28
- **Lot exact :** `DS-04 — Préflight des dépendances`
- **Package principal :** `packages/map_editor`
- **Branche / HEAD :** `main` /
  `a3d741818c1961ac2f653da235bb30c20df75b00`
- **Verdict proposé :** **DONE**
- **Gate 0 globale :** **PARTIAL** — DS‑05 reste requis avant toute
  déclaration de lifecycle multi-fichier crash-safe.

## 1. Résumé exécutif

DS‑04 est implémenté et vérifié.

Les renommages et suppressions de maps passent désormais obligatoirement par
un préflight projet exhaustif. Celui-ci recharge chaque document déclaré par
son chemin de manifeste, contrôle son identité, délègue l’indexation au
`NarrativeDependencyIndex` canonique de `map_core`, puis :

- autorise l’opération seulement si l’index est complet et qu’aucun usage
  entrant n’existe ;
- bloque en mode conservateur si une map est illisible, incohérente, dupliquée
  ou si la cible n’est pas définie sans ambiguïté ;
- bloque également les auto-références ;
- garantit que le blocage survient avant toute écriture lifecycle ;
- remonte un résultat structuré jusqu’à l’explorateur World Maps ;
- présente les consommateurs connus dans une modale Design System sans
  contournement destructif ;
- ouvre l’usage choisi via l’intent canonique, jusqu’à la map et à la source
  physique exacte quand elle est ouvrable.

Le package complet est vert (`+4420`, 6 skips), le pack DS‑04 élargi est vert
(`+146`), le contrat d’index Core est vert (`+48`), l’analyse ne remonte aucun
problème et le build macOS release produit `PokeMap.app (44.7MB)`.

## 2. Contrat du lot et conformité

Le contrat provient de
`reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md`,
section `DS-04 — Préflight des dépendances`.

| Critère DS‑04 | Preuve | Verdict |
|---|---|---:|
| Rename/delete bloqués si référence entrante | préflight obligatoire dans `RenameMapUseCase` et `DeleteMapUseCase`, tests warp, New Game, Event V2 et auto-référence | **PASS** |
| Liste navigable des usages | `PokeMapDependencyInspector`, intents Core préservés, callback Explorer → Shell | **PASS** |
| Index incomplet = blocage conservateur | map illisible, mismatch d’identité, ID dupliqué, cible absente/ambiguë | **PASS** |
| Aucune écriture lors d’un blocage | compteurs repository/projet et ordre des use cases | **PASS** |
| Compatibilité DS‑03 | chargement révisionné via `loadMapDocument`, suites lifecycle révisionnées et Border réalignées | **PASS** |

### Non-objectifs maintenus

- aucune réécriture automatique des références ;
- aucune transaction durable multi-fichier : c’est DS‑05 ;
- aucune modification de schéma JSON ;
- aucune migration silencieuse d’ID/path legacy ;
- aucune refonte de rendu, de pile visuelle, de gomme, de déplacement ou de
  navigation Magic Mouse ;
- aucune opération Git d’écriture ;
- aucun cache d’index susceptible d’autoriser une suppression sur une vue
  périmée.

## 3. Audit initial

### 3.1 État trouvé

1. `map_core` possédait déjà l’autorité canonique
   `buildNarrativeDependencyIndex`, ses définitions/usages typés, ses
   résolutions et ses intents de navigation neutres.
2. Les use cases lifecycle de `map_editor` validaient les IDs, chemins,
   identités et révisions DS‑03, mais ne consultaient aucun index exhaustif
   avant rename/delete.
3. Le notifier possédait un garde-fou Event V2 partiel. Il protégeait une
   famille de références, mais ne couvrait ni warps, ni connexions, ni New
   Game, ni toutes les commandes/scènes/storylines/cinematics/world rules.
4. Le Design System exposait déjà `PokeMapDependencyInspector`, donc il était
   inutile et dangereux d’inventer une seconde représentation des usages.
5. L’explorateur World Maps appelait directement le notifier ; la résolution
   narrative existante savait déjà distinguer route interne, map externe et
   destination indisponible.
6. DS‑03 imposait de préserver les lectures révisionnées et les attestations
   de révision. Le préflight devait donc employer la même capacité repository.

### 3.2 Risques identifiés avant implémentation

- faux négatif si une map déclarée ne peut pas être lue ;
- faux négatif si le fichier chargé ne correspond pas à l’ID du manifeste ;
- double définition de map ;
- auto-référence prise à tort pour de la simple propriété ;
- écriture commencée avant le verdict ;
- régression des contrats CAS/révision DS‑03 ;
- UI qui affiche une liste partielle comme exhaustive ;
- reconstruction fragile d’une destination depuis un libellé humain ;
- churn accidentel dans un worktree déjà fortement modifié.

### 3.3 État Git initial

Capture avant édition DS‑04 :

```text
branch: main
HEAD: a3d741818c1961ac2f653da235bb30c20df75b00
git status --short --untracked-files=all: 103 lignes
```

Le worktree était déjà très sale. Les chevauchements connus avec DS‑04 étaient :

- déjà modifiés : `map_use_cases.dart`, `editor_notifier.dart`,
  `editor_shell_page.dart`, `world_tree_nodes.dart` ;
- déjà non suivis depuis DS‑01/02/03 :
  `map_lifecycle_use_cases_test.dart`,
  `map_revisioned_lifecycle_use_cases_test.dart`,
  `editor_notifier_map_activation_test.dart`.

Ces fichiers ont été étendus chirurgicalement. Aucun changement préexistant
n’a été restauré, écrasé, stashed ou nettoyé.

## 4. Architecture livrée

```mermaid
flowchart LR
  A[Explorateur World Maps] --> B[EditorNotifier + lease]
  B --> C[Rename/Delete use case]
  C --> D[MapDependencyPreflightService]
  D --> E[Recharge toutes les maps du manifeste]
  E --> F[Index canonique map_core]
  F -->|complet, 0 usage| G[Lifecycle autorisé]
  F -->|usage ou index incomplet| H[Exception + résultat structuré]
  H --> I[Modale Design System]
  I --> J[Intent canonique]
  J --> K[Narrative Studio ou map/source exacte]
```

### Décisions structurantes

- **Autorité unique :** le parcours des modèles reste dans `map_core`.
  `map_editor` ne duplique que le chargement, l’autorisation et la
  présentation.
- **Fail-closed :** toute connaissance partielle bloque ; les usages déjà
  connus restent visibles mais ne sont jamais présentés comme exhaustifs.
- **Même repository :** le provider construit le préflight depuis le même
  `MapRepository` que le lifecycle.
- **Révision DS‑03 :** si le repository est `RevisionedMapRepository`, le
  préflight appelle `loadMapDocument`.
- **Aucun override :** la modale explique et navigue ; elle ne propose pas
  « supprimer quand même ».
- **Intent intact :** l’UI ne parse pas `usage.path` pour reconstruire une
  destination.
- **Fermeture avant navigation :** la modale retourne l’intent via son résultat
  de route ; le callback n’est appelé qu’après disparition de la route.

## 5. Inventaire complet des fichiers

### 5.1 Fichiers créés par DS‑04

| Fichier | Rôle |
|---|---|
| `docs/superpowers/plans/2026-07-28-world-map-ds-04-dependency-preflight.md` | plan TDD et vérification ; ignoré par la règle historique `/docs/*` |
| `packages/map_editor/lib/src/application/services/map_dependency_preflight_service.dart` | contrat, diagnostics, exception et index fail-closed |
| `packages/map_editor/lib/src/ui/design_system/pokemap_dependency_preflight_dialog.dart` | modale DS, diagnostics et usages navigables |
| `packages/map_editor/test/application/services/map_dependency_preflight_service_test.dart` | couverture du service |
| `packages/map_editor/test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart` | couverture widget/navigation/fermeture |
| `reports/ui/world_map_editor_ds_04_dependency_preflight_2026-07-28.md` | présent Evidence Pack ; son contenu n’est pas récursivement reproduit |

### 5.2 Fichiers modifiés et zones précises

| Fichier | Zones/classes/fonctions DS‑04 | Raison et impact |
|---|---|---|
| `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart` | `RenameMapUseCase` lignes ~245–375 ; `DeleteMapUseCase` ~384–422 | dépendance explicite au service et `requireAllowed` avant toute écriture |
| `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart` | import ; `renameMapUseCase` ~296 ; `deleteMapUseCase` ~306 | injection du même repository ; churn de formatage hors zone retiré |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | imports ; `renameMap` ~3244–3305 ; `deleteMap` ~3307–3354 | résultat structuré, message exact, état inchangé sur blocage |
| `packages/map_editor/lib/src/ui/design_system/design_system.dart` | export ligne ~15 | rend la modale disponible via le barrel DS |
| `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart` | `_resolveExternalMap` ~507–535 | route l’owner New Game vers l’overview au lieu d’un faux target map |
| `packages/map_editor/lib/src/ui/panels/project_explorer/dialogs/world_group_dialogs.dart` | `showRenameMapDialog` ~264 ; `deleteMapWithDependencyPreflight` ~290 ; helper ~305 | attend le résultat et ouvre la modale |
| `packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart` | constructeurs/callbacks ~20–205 ; menu ~235–272 | propage la navigation et protège rename/delete |
| `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart` | callback public ~26–30 ; propagation ~277/288 | découple l’explorateur du routeur narratif |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | `openNarrativeResolution` ~317–386 ; callback ~388 ; wiring ~921 | ouvre la route interne ou active la map et sélectionne entity/trigger/event/warp |
| `packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart` | groupes Rename/Delete, fixture | prouve références, index incomplet et zéro écriture |
| `packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart` | constructeurs lifecycle | conserve la preuve DS‑03 avec la nouvelle dépendance obligatoire |
| `packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart` | groupe `DS-04 map dependency preflight handoff` ~710 | prouve la remontée UI structurée |
| `packages/map_editor/test/ui/canvas/narrative_studio_navigation_test.dart` | cas New Game ~352 | prouve le fallback interne exact |
| `packages/map_editor/test/narrative_event_source_dependency_guard_test.dart` | test notifier ~431 ; fake repository | remplace l’attente textuelle partielle par les usages canoniques et zéro mutation |
| `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart` | cas chargement projet ~66 | aligne le test sur le handshake explicite DS‑02 |
| `packages/map_editor/test/border_map_editing/pending_border_save_notifier_test.dart` | round-trip réel ~233 | charge une révision attestée avant le save DS‑03 |

## 6. Tests et preuves TDD

### 6.1 RED → GREEN

| Étape | Commande / résultat exact |
|---|---|
| Service RED | `flutter test --no-pub test/application/services/map_dependency_preflight_service_test.dart` → exit 1, symboles/service absents |
| Service GREEN initial | même commande → `+6: All tests passed!` ; couverture finale portée à `+8` |
| Lifecycle RED | `flutter test --no-pub test/application/use_cases/map_lifecycle_use_cases_test.dart` → `+34 -3`, uniquement les nouveaux scénarios échouaient |
| Lifecycle/DS‑03 GREEN | service + lifecycle + revisioned → `+48: All tests passed!` |
| Notifier RED | compilation : expression `void` inutilisable comme résultat |
| Notifier GREEN | suite d’activation → `+38: All tests passed!` à cette étape |
| Dialog RED | fichier/fonction absents |
| Dialog GREEN initial | `+2: All tests passed!` ; fermeture Escape ajoutée ensuite, total final `+3` |
| Navigation RED | New Game résolu `unavailable` au lieu de `internal` |
| Navigation GREEN | nouveau scénario vert |

### 6.2 Pack DS‑04 final élargi

```bash
cd packages/map_editor
flutter test --no-pub \
  test/application/services/map_dependency_preflight_service_test.dart \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart \
  test/ui/canvas/narrative_studio_navigation_test.dart \
  test/narrative_event_source_dependency_guard_test.dart \
  test/editor_notifier_project_dirty_state_test.dart \
  test/border_map_editing/pending_border_save_notifier_test.dart
```

Résultat exact :

```text
exit 0
+146: All tests passed!
```

### 6.3 Contrat canonique Core

```bash
cd packages/map_core
dart test test/narrative_dependency_index_test.dart
```

Résultat exact :

```text
exit 0
+48: All tests passed!
```

### 6.4 Suite package complète

Commande finale :

```bash
cd packages/map_editor
set -o pipefail
flutter test --no-pub 2>&1 |
  sed -n '/^Failing tests:/,$p; /All tests passed!/p'
```

Résultat exact :

```text
exit 0
05:48 +4420 ~6: All tests passed!
```

Historique honnête des passes intermédiaires :

1. une première suite complète a trouvé trois tests historiques encore alignés
   sur les contrats pré-DS‑03/04 :
   `pending_border_save_notifier_test.dart`,
   `editor_notifier_project_dirty_state_test.dart`,
   `narrative_event_source_dependency_guard_test.dart` ;
2. ils ont été rejoués isolément, corrigés uniquement dans leurs fixtures et
   attentes de contrat, puis ont donné `+41: All tests passed!` ;
3. une suite lancée avant les derniers ajustements a été interrompue ; Flutter
   a signalé des erreurs de finalisation de listeners temporaires ;
4. une passe suivante, anormalement longue, a signalé `+4413 ~6 -7`. La sortie
   finale nommait quatre tests dans trois fichiers et élidait les trois autres ;
5. les trois fichiers nommés ont été rejoués en série :

```bash
flutter test --no-pub --concurrency=1 \
  test/game_export/game_package_export_controller_test.dart \
  test/register_selbrume_two_tier_cliff_v3_organic_test.dart \
  test/selbrume_event_v2_persistence_migration_test.dart
```

Résultat :

```text
exit 0
+15: All tests passed!
```

La passe complète propre `+4420` ci-dessus est le verdict final retenu. Les
échecs intermédiaires ne sont ni masqués ni utilisés comme preuve verte.

## 7. Analyse, build et hygiène

### Analyse

```bash
cd packages/map_editor
flutter analyze --no-pub
```

```text
exit 0
Analyzing map_editor...
No issues found! (ran in 5.5s)
```

Une première analyse avant la clôture avait trouvé un import inutilisé ; il a
été retiré puis l’analyse a été relancée. Le résultat ci-dessus est la preuve
finale.

### Build

```bash
cd packages/map_editor
flutter build macos --release --no-pub
```

```text
exit 0
✓ Built build/macos/Build/Products/Release/PokeMap.app (44.7MB)
```

Le compilateur a émis des warnings Swift/Objective‑C dans
`audioplayers_darwin-6.5.0` et `video_player_avfoundation-2.11.0`
(actor isolation, API AVFoundation dépréciée, optionalité). Ils proviennent du
cache de dépendances, n’ont pas été modifiés et ne bloquent pas le build.

### Hygiène

| Commande | Résultat |
|---|---|
| `git diff --check` | exit 0, aucune sortie |
| scan `TODO/FIXME/HACK/placeholder` sur les nouveaux fichiers | exit 0, aucune occurrence |
| scan des lignes UI ajoutées pour `Color(0x`, `Colors.*`, `PokeMapPalette` | exit 0, aucune occurrence |
| inventaire des constructeurs `RenameMapUseCase` / `DeleteMapUseCase` | tous les call sites adaptés |

Le fichier provider avait subi un reformatage mécanique hors scope lors d’un
`dart format` ciblant le fichier entier. Cette dérive a été retirée avec
`apply_patch`; son diff final ne contient que 9 lignes utiles.

## 8. Verdicts des cinq passes séparées

| Passe imposée par `codex_rule.md` | Vérifications | Verdict |
|---|---|---:|
| Audit / Architecture | autorité Core, frontières de packages, réutilisation inspector/intents, séparation DS‑04/DS‑05 | **PASS** |
| Implémentation | index exhaustif, fail-closed, identité, duplication, ordre avant écriture, repository révisionné | **PASS avec risque TOCTOU documenté** |
| Tests | positif, négatif, garde-fous, auto-référence, UI, navigation, non-régressions DS‑02/03, package complet | **PASS** |
| Build / Validation | `+146`, `+48`, `+4420`, analyze 0, build release 0, diff-check 0 | **PASS** |
| Critique finale | churn, messages trompeurs, navigation non prouvée, latence, concurrence, worktree sale | **PASS avec réserves explicites** |

## 9. Auto-critique et risques restants

1. **Fenêtre TOCTOU inter-documents.** Le préflight relit tout juste avant
   l’opération, mais il n’existe pas encore de transaction projet qui verrouille
   les révisions de toutes les maps jusqu’au commit. Une autre source pourrait
   théoriquement gagner une référence après son indexation. DS‑05 doit définir
   le journal/commit et la politique de revalidation, sans prétendre à une
   atomicité multi-fichier inexistante.
2. **Coût O(nombre de maps), séquentiel.** C’est volontairement sûr, mais un
   très grand projet peut rendre rename/delete lent. Aucun cache ne doit être
   ajouté sans attestation de révision complète ; une progression UI sera utile.
3. **Navigation physique prouvée par contrats séparés.** Le test widget prouve
   que l’intent exact sort de la modale et les tests de résolution prouvent la
   route. Il n’existe pas encore de test widget end-to-end qui clique depuis le
   menu de l’arbre jusqu’à la sélection visuelle finale sur le canvas.
4. **Sources legacy.** Les intents sans source physique exploitable restent
   explicitement indisponibles. Aucune destination n’est inventée.
5. **New Game.** L’usage ouvre l’overview Narrative, qui est honnête mais moins
   précis qu’une future feuille de configuration New Game dédiée.
6. **Confirmation de suppression.** Le menu destructif préexistant lance la
   suppression directement si elle est sûre. Ajouter une confirmation produit
   explicite appartient à une tranche ergonomique ultérieure.
7. **Plan ignoré par Git.** `/docs/*` est ignoré par `.gitignore`; le plan existe
   dans le workspace et est reproduit intégralement en annexe, mais n’apparaît
   pas dans `git status`.
8. **Worktree partagé très sale.** Le statut final contient de nombreux travaux
   sans rapport. Aucun nettoyage n’a été effectué. Un commit futur devra
   sélectionner le périmètre intentionnel avec soin.

## 10. Statut proposé et suite

- **DS‑04 : proposé `DONE`.**
- **Gate 0 : reste `PARTIAL`.**
- **Prochain lot recommandé : `DS‑05 — Transaction lifecycle`.**

DS‑05 doit journaliser create/duplicate/rename/delete, reprendre
déterministiquement après crash et revalider les préconditions/révisions au
commit. Il ne doit pas masquer la réalité multi-fichier derrière un faux label
« atomique ».

Après DS‑05, la première tranche ergonomique à fort soulagement pourra traiter
la pile visuelle canonique et les interactions/navigation desktop, conformément
à l’audit initial.

## 11. État Git final

Le rapport a été créé sans `git add`, commit, stash, reset, checkout ou autre
écriture Git. `build/` reste ignoré.

```text
git status --short --untracked-files=all: 117 lignes
 M .github/workflows/pokemap_hub_product_certification.yml
 M apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
 M apps/pokemap_hub/test/saves/hub_save_store_atomic_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/narrative_command_descriptor.dart
 M packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
 M packages/map_core/lib/src/read_models/narrative_command_catalog.dart
 M packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart
 M packages/map_core/test/gameplay_roadmap_dashboard_test.dart
 M packages/map_core/test/linked_asset_public_contracts_test.dart
 M packages/map_core/test/narrative_command_catalog_test.dart
 M packages/map_core/test/narrative_command_contract_parity_test.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart
 M packages/map_editor/lib/game_export.dart
 M packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart
 M packages/map_editor/lib/src/application/services/narrative_template_catalog.dart
 M packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart
 M packages/map_editor/lib/src/domain/repositories/repositories.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart
 M packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart
 M packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/lib/src/ui/design_system/design_system.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/map_connections_panel.dart
 M packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer/dialogs/world_group_dialogs.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart
 M packages/map_editor/test/border_map_editing/pending_border_save_notifier_test.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
 M packages/map_editor/test/event_map_navigation_controller_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_controller_test.dart
 M packages/map_editor/test/game_export/game_package_export_dialog_test.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
 M packages/map_editor/test/narrative_event_source_dependency_guard_test.dart
 M packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart
 M packages/map_editor/test/narrative_global_search_performance_test.dart
 M packages/map_editor/test/narrative_large_project_workspace_performance_test.dart
 M packages/map_editor/test/narrative_template_catalog_test.dart
 M packages/map_editor/test/personalization/phase_6_personalization_studio_export_e2e_test.dart
 M packages/map_editor/test/scene_action_builder_test.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart
 M packages/map_editor/test/ui/canvas/narrative_event_map_banner_test.dart
 M packages/map_editor/test/ui/canvas/narrative_studio_navigation_test.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart
 D packages/map_runtime/test/le_train_m00_external_runtime_smoke_test.dart
 M packages/map_runtime/test/narrative_command_runtime_parity_test.dart
 M packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/map_core/lib/src/tooling/gameplay_roadmap_evidence.dart
?? packages/map_editor/dart_test.yaml
?? packages/map_editor/lib/src/application/services/map_dependency_preflight_service.dart
?? packages/map_editor/lib/src/application/services/project_map_id_policy.dart
?? packages/map_editor/lib/src/application/services/project_map_manifest_integrity_policy.dart
?? packages/map_editor/lib/src/domain/models/map_document_persistence.dart
?? packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart
?? packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart
?? packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_dependency_preflight_dialog.dart
?? packages/map_editor/test/application/services/map_dependency_preflight_service_test.dart
?? packages/map_editor/test/application/services/project_map_id_policy_test.dart
?? packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart
?? packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
?? packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart
?? packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart
?? packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart
?? packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart
?? packages/map_editor/test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart
?? packages/map_runtime/test/rendered_map_pixel_smoke_test.dart
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/gameplay/evidence/README.md
?? reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/01-empty-world-map-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/02-port-open-overview-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/03-inspector-scroll-layer-context-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/04-layers-expanded-truncated-actions-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md
?? reports/ui/world_map_editor_ds_03_atomic_revisioned_store_2026-07-28.md
?? reports/ui/world_map_editor_ds_04_dependency_preflight_2026-07-28.md
?? reports/ui/world_map_editor_foundation_ds_00_ds_02_2026-07-28.md
```

## 12. Contenu complet des fichiers créés

Conformément à `codex_rule.md`, tous les fichiers créés par DS‑04 sont reproduits
ci-dessous, sauf le présent rapport afin d’éviter une récursion infinie.

Les tests lifecycle/notifier déjà non suivis avant DS‑04 ne sont pas présentés
comme « créés » par ce lot ; leurs zones modifiées figurent dans l’inventaire.

### 12.1 — `docs/superpowers/plans/2026-07-28-world-map-ds-04-dependency-preflight.md`

Plan d’implémentation et de vérification (ignoré par /docs/*).

- Lignes : 479
- SHA-256 : `947f048f92eeeb205ae28129b2242b05fd66d8e5aab7f7f0849562486886d0c4`

````markdown
# World Map DS-04 Dependency Preflight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Empêcher tout rename/delete de map lorsque des références entrantes existent ou lorsque l’index projet ne peut pas être construit exhaustivement, puis présenter les usages connus dans une liste ouvrable.

**Architecture:** `map_core` reste la vérité de dépendances via `buildNarrativeDependencyIndex`; `map_editor` ajoute un préflight applicatif qui charge chaque map déclarée, contrôle son identité, inspecte la clé canonique `NarrativeDependencyKey.map(mapId)` et échoue en mode fermé. Les use cases rename/delete imposent ce préflight avant leur première écriture. Le notifier retourne le blocage structuré à l’UI, qui réutilise le Design System et les intents de navigation canoniques.

**Tech Stack:** Dart 3, Flutter desktop, Riverpod, `map_core` dependency read models, `flutter_test`.

**Adaptation aux règles du dépôt:** le worktree et les commits prescrits par le skill sont volontairement omis : `AGENTS.md` interdit les opérations Git d’écriture sans demande explicite. L’exécution reste inline dans l’arbre partagé et préserve les changements DS-01/02/03 déjà présents.

---

## File map

- Create: `packages/map_editor/lib/src/application/services/map_dependency_preflight_service.dart`
  - Résultat immutable, diagnostics de chargement, exception structurée et construction fail-closed de l’index.
- Modify: `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
  - Rend le préflight obligatoire dans `RenameMapUseCase` et `DeleteMapUseCase`.
- Modify: `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart`
  - Injecte explicitement le même type de préflight depuis le repository de maps.
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
  - Remplace le guard Event V2 partiel pour rename/delete par le résultat exhaustif des use cases et le retourne à la présentation.
- Create: `packages/map_editor/lib/src/ui/design_system/pokemap_dependency_preflight_dialog.dart`
  - Dialog Design System pour index complet bloqué ou index incomplet.
- Modify: `packages/map_editor/lib/src/ui/design_system/design_system.dart`
  - Exporte le nouveau composant.
- Modify: `packages/map_editor/lib/src/ui/panels/project_explorer/dialogs/world_group_dialogs.dart`
  - Affiche le détail après un rename bloqué.
- Modify: `packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart`
  - Affiche le détail après un delete bloqué et propage l’ouverture d’un usage.
- Modify: `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
  - Propage l’intent de navigation sans coupler l’explorateur au routeur Narrative Studio.
- Modify: `packages/map_editor/lib/src/ui/editor_shell_page.dart`
  - Résout l’intent canonique, ouvre le studio ou la map propriétaire, puis sélectionne l’objet physique si possible.
- Create: `packages/map_editor/test/application/services/map_dependency_preflight_service_test.dart`
  - Couverture du résultat autorisé, des familles de références, de l’auto-référence et du mode incomplet.
- Modify: `packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart`
  - Prouve qu’aucune écriture rename/delete ne démarre quand le préflight bloque.
- Modify: `packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart`
  - Prouve que le notifier conserve l’état et retourne le blocage structuré.
- Create: `packages/map_editor/test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart`
  - Prouve l’affichage des usages, l’action Ouvrir et le diagnostic incomplet.

### Task 1: Contrat pur et chargement exhaustif

- [x] **Step 1: écrire les tests RED du service**

Créer des scénarios qui expriment directement l’API souhaitée :

```dart
final result = await MapDependencyPreflightService(
  mapRepository: repository,
).inspect(
  workspace: workspace,
  project: project,
  mapId: 'target',
  operation: MapDependencyPreflightOperation.rename,
);

expect(result.isComplete, isTrue);
expect(result.isAllowed, isFalse);
expect(
  result.inspection.usages.map((usage) => usage.path),
  contains('maps[source].warps[0].targetMapId'),
);
```

Ajouter séparément :

```dart
expect(result.indexIssues.single.mapId, 'unreadable');
expect(result.isComplete, isFalse);
expect(result.isAllowed, isFalse);
```

et un cas sans référence :

```dart
expect(result.isComplete, isTrue);
expect(result.inspection.usages, isEmpty);
expect(result.isAllowed, isTrue);
```

- [x] **Step 2: lancer le test et vérifier RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub test/application/services/map_dependency_preflight_service_test.dart
```

Expected: échec de compilation parce que `MapDependencyPreflightService` n’existe pas encore.

- [x] **Step 3: implémenter le service minimal**

Le contrat de production doit conserver ces invariants :

```dart
enum MapDependencyPreflightOperation { rename, delete }

final class MapDependencyPreflightResult {
  const MapDependencyPreflightResult({
    required this.operation,
    required this.mapId,
    required this.inspection,
    required this.indexIssues,
  });

  final MapDependencyPreflightOperation operation;
  final String mapId;
  final NarrativeDependencyInspectionReadModel inspection;
  final List<MapDependencyIndexIssue> indexIssues;

  bool get isComplete =>
      indexIssues.isEmpty &&
      !inspection.isMissing &&
      !inspection.isAmbiguous;
  bool get isAllowed => isComplete && inspection.usages.isEmpty;
}
```

Le service doit :

```dart
for (final entry in project.maps) {
  try {
    final path = workspace.resolveMapPath(entry.relativePath);
    final map = await _mapRepository.loadMap(path);
    if (map.id != entry.id) {
      // Ajouter un diagnostic et ne pas indexer le mauvais document.
      continue;
    }
    maps.add(map);
  } on Object catch (error) {
    // Ajouter un diagnostic; ne jamais transformer l’échec en index complet.
  }
}
final index = buildNarrativeDependencyIndex(project: project, maps: maps);
final inspection = inspectNarrativeDependency(
  index,
  NarrativeDependencyKey.map(mapId),
);
```

`MapDependencyPreflightBlockedException.toString()` doit produire un message français qui indique explicitement qu’aucune écriture n’a été effectuée.

- [x] **Step 4: vérifier GREEN**

Run:

```bash
cd packages/map_editor
flutter test --no-pub test/application/services/map_dependency_preflight_service_test.dart
```

Expected: tous les tests du fichier passent.

### Task 2: Enforcement dans les use cases lifecycle

- [x] **Step 1: ajouter les tests RED rename/delete**

Dans `map_lifecycle_use_cases_test.dart`, créer :

```dart
test('rename blocks before writer I/O when another map targets it', () async {
  // source contient un warp targetMapId: target.
  await expectLater(
    fixture.rename.execute(
      fixture.workspace,
      fixture.project,
      'target',
      'renamed',
    ),
    throwsA(isA<MapDependencyPreflightBlockedException>()),
  );
  fixture.expectNoWriterIo();
});
```

et :

```dart
test('delete fails closed before writer I/O when one map cannot be indexed',
    () async {
  fixture.mapRepository.failLoadFor('/project/maps/unreadable.json');
  await expectLater(
    fixture.delete.execute(fixture.workspace, fixture.project, 'target'),
    throwsA(
      isA<MapDependencyPreflightBlockedException>().having(
        (error) => error.result.isComplete,
        'complete index',
        isFalse,
      ),
    ),
  );
  fixture.expectNoWriterIo();
});
```

- [x] **Step 2: vérifier RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub test/application/use_cases/map_lifecycle_use_cases_test.dart
```

Expected: les nouveaux tests montrent que rename/delete écrivent encore sans préflight.

- [x] **Step 3: injecter et imposer le service**

Les constructeurs deviennent explicitement dépendants du préflight :

```dart
RenameMapUseCase(
  this._mapRepo,
  this._projectRepo,
  this._dependencyPreflight,
);

DeleteMapUseCase(
  this._mapRepo,
  this._projectRepo,
  this._dependencyPreflight,
);
```

Après validation ID/manifeste et avant tout save/delete :

```dart
await _dependencyPreflight.requireAllowed(
  workspace: fs,
  project: project,
  mapId: oldId,
  operation: MapDependencyPreflightOperation.rename,
);
```

Le provider construit le service depuis le même `MapRepository`; aucune modification de fichier généré n’est nécessaire.

- [x] **Step 4: vérifier GREEN et la non-régression DS-03**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
```

Expected: les suites passent; les attentes de lecture sont ajustées uniquement lorsque le préflight exhaustif ajoute des lectures légitimes.

### Task 3: Remontée structurée dans le notifier

- [x] **Step 1: écrire le test RED**

Le test doit exiger le résultat sans mutation d’état :

```dart
final blocked = await notifier.deleteMap('target');

expect(blocked, isNotNull);
expect(blocked!.inspection.usages, isNotEmpty);
expect(notifier.state.project, same(project));
expect(notifier.state.activeMap, same(activeMap));
fixture.expectNoLifecycleWriterIo();
```

- [x] **Step 2: vérifier RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/features/editor/state/editor_notifier_map_activation_test.dart
```

Expected: `deleteMap`/`renameMap` retournent encore `void` ou le guard Event V2 partiel masque le résultat exhaustif.

- [x] **Step 3: implémenter le retour**

Les méthodes retournent :

```dart
Future<MapDependencyPreflightResult?> renameMap(
  String oldId,
  String newId,
)

Future<MapDependencyPreflightResult?> deleteMap(String mapId)
```

Elles interceptent uniquement l’exception structurée :

```dart
} on MapDependencyPreflightBlockedException catch (error) {
  if (_canAdoptMapDiskMutation(lease)) {
    state = state.copyWith(errorMessage: error.result.blockingMessage);
  }
  return error.result;
}
```

Le guard `NarrativeEventSourceDependencyGuard` reste disponible pour les mutations intra-map, mais n’est plus l’autorité rename/delete.

- [x] **Step 4: vérifier GREEN**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/features/editor/state/editor_notifier_map_activation_test.dart
```

Expected: test vert et état inchangé sur blocage.

### Task 4: Liste Design System et navigation

- [x] **Step 1: écrire les tests widget RED**

Tester le blocage complet :

```dart
await showPokeMapDependencyPreflightDialog(
  context: context,
  title: 'Suppression bloquée',
  message: 'La carte est encore utilisée.',
  inspection: inspection,
  onOpen: opened.add,
);
```

Assertions :

```dart
expect(find.text('Consommateurs'), findsOneWidget);
expect(find.text('maps[source].warps[0].targetMapId'), findsOneWidget);
await tester.tap(find.text('Ouvrir').first);
expect(opened.single, usage.navigationIntent);
```

Tester séparément l’index incomplet :

```dart
expect(find.textContaining('Index incomplet'), findsOneWidget);
expect(find.textContaining('unreadable.json'), findsOneWidget);
```

- [x] **Step 2: vérifier RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart
```

Expected: échec de compilation, composant absent.

- [x] **Step 3: implémenter et câbler**

Le composant doit composer uniquement :

```dart
Dialog(
  child: PokeMapPanel(
    child: PokeMapDependencyInspector(
      model: inspection,
      onOpen: onOpen,
    ),
  ),
)
```

avec `PokeMapDiagnosticCallout`, `PokeMapCard` et `PokeMapButton`; aucune couleur de feature hardcodée.

Le callback traverse :

```text
EditorShellPage
  -> ProjectExplorerPanel
  -> GroupNode / MapNode
  -> world_group_dialogs
  -> PokeMap dependency preflight dialog
```

L’éditeur résout `NarrativeDependencyNavigationIntent`; pour une source physique, il active la map via `requestEditorMapActivation`, puis appelle `selectEntity`, `selectMapEvent`, `selectWarp` ou `selectTrigger` selon `sourceKind`.

- [x] **Step 4: vérifier GREEN**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart \
  test/ui/design_system/pokemap_dependency_inspector_test.dart
```

Expected: les tests widget passent sans overflow ni couleur locale.

### Task 5: Vérification, cinq passes et Evidence Pack

- [x] **Step 1: formatter les seuls fichiers Dart DS-04**

Run:

```bash
cd packages/map_editor
dart format \
  lib/src/application/services/map_dependency_preflight_service.dart \
  lib/src/application/use_cases/map_use_cases.dart \
  lib/src/app/providers/editor/map_use_case_providers.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/design_system/design_system.dart \
  lib/src/ui/design_system/pokemap_dependency_preflight_dialog.dart \
  lib/src/ui/editor_shell_page.dart \
  lib/src/ui/panels/project_explorer_panel.dart \
  lib/src/ui/panels/project_explorer/dialogs/world_group_dialogs.dart \
  lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart \
  test/application/services/map_dependency_preflight_service_test.dart \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart
```

- [x] **Step 2: suite ciblée puis package complet**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/application/services/map_dependency_preflight_service_test.dart \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart \
  test/ui/design_system/pokemap_dependency_inspector_test.dart
flutter test --no-pub
```

- [x] **Step 3: analyse et build**

Run:

```bash
cd packages/map_editor
flutter analyze --no-pub
flutter build macos --release --no-pub
```

- [x] **Step 4: cinq passes séparées**

Consigner les verdicts :

1. **Audit / Architecture** — autorité unique de l’index, frontières DS-04/DS-05.
2. **Implémentation** — fail-closed avant écriture, commentaires/invariants.
3. **Tests** — positif, négatif, garde-fou, non-régression et preuve RED/GREEN.
4. **Build / Validation** — commandes fraîches et sorties exactes.
5. **Critique finale** — diff accidentel, UX trompeuse, navigation non prouvée, risques de concurrence.

- [x] **Step 5: produire le rapport**

Créer :

```text
reports/ui/world_map_editor_ds_04_dependency_preflight_2026-07-28.md
```

Le rapport suit `codex_rule.md`, inclut l’état Git initial/final, les zones de diff, le contenu complet de chaque fichier créé, les commandes exactes, les cinq verdicts, les limites et la recommandation de statut DS-04.
````

### 12.2 — `packages/map_editor/lib/src/application/services/map_dependency_preflight_service.dart`

Service applicatif fail-closed.

- Lignes : 234
- SHA-256 : `40b217e8ea010a8514fc3c2947d4e59db7d0f5e8689a83e8c8d839db7ffd0143`

````dart
import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../ports/project_workspace.dart';

/// Destructive map lifecycle operations protected by the DS-04 preflight.
enum MapDependencyPreflightOperation {
  rename,
  delete,
}

/// Why one declared map could not participate in the dependency index.
enum MapDependencyIndexIssueKind {
  duplicateManifestId,
  unreadableMap,
  identityMismatch,
  missingTargetDefinition,
  ambiguousTargetDefinition,
}

/// Stable, user-presentable evidence that the dependency index is incomplete.
final class MapDependencyIndexIssue {
  const MapDependencyIndexIssue({
    required this.kind,
    required this.mapId,
    required this.relativePath,
    required this.message,
  });

  final MapDependencyIndexIssueKind kind;
  final String mapId;
  final String relativePath;
  final String message;
}

/// Immutable DS-04 decision returned to both lifecycle code and presentation.
///
/// [inspection] is retained even when loading is incomplete. It lets the UI
/// show already-known usages without ever presenting that partial list as
/// exhaustive or using it to authorize a destructive operation.
final class MapDependencyPreflightResult {
  MapDependencyPreflightResult({
    required this.operation,
    required this.mapId,
    required this.inspection,
    required List<MapDependencyIndexIssue> indexIssues,
  }) : indexIssues = List<MapDependencyIndexIssue>.unmodifiable(indexIssues);

  final MapDependencyPreflightOperation operation;
  final String mapId;
  final NarrativeDependencyInspectionReadModel inspection;
  final List<MapDependencyIndexIssue> indexIssues;

  /// A complete index requires every manifest map and one canonical target.
  bool get isComplete =>
      indexIssues.isEmpty && !inspection.isMissing && !inspection.isAmbiguous;

  bool get hasIncomingReferences => inspection.usages.isNotEmpty;

  /// DS-04 is deliberately fail-closed: partial knowledge never authorizes.
  bool get isAllowed => isComplete && !hasIncomingReferences;

  String get operationLabel => switch (operation) {
        MapDependencyPreflightOperation.rename => 'renommage',
        MapDependencyPreflightOperation.delete => 'suppression',
      };

  String get dialogTitle => switch (operation) {
        MapDependencyPreflightOperation.rename => 'Renommage bloqué',
        MapDependencyPreflightOperation.delete => 'Suppression bloquée',
      };

  String get blockingMessage {
    if (!isComplete) {
      final count = indexIssues.length;
      final diagnosticLabel =
          count == 1 ? '1 diagnostic' : '$count diagnostics';
      return 'Action bloquée ($operationLabel de « $mapId ») : '
          'index incomplet ($diagnosticLabel). Aucune écriture n’a été '
          'effectuée.';
    }
    final count = inspection.usages.length;
    final usageLabel =
        count == 1 ? '1 usage entrant' : '$count usages entrants';
    final requiredAction = count == 1
        ? 'doit être retiré ou redirigé'
        : 'doivent être retirés ou redirigés';
    return 'Action bloquée ($operationLabel de « $mapId ») : '
        '$usageLabel $requiredAction. Aucune écriture n’a '
        'été effectuée.';
  }
}

/// Structured failure used to keep the navigable preflight result intact.
final class MapDependencyPreflightBlockedException implements Exception {
  const MapDependencyPreflightBlockedException(this.result);

  final MapDependencyPreflightResult result;

  @override
  String toString() => result.blockingMessage;
}

/// Builds the canonical project-wide incoming-reference preflight for a map.
///
/// The service intentionally reloads every manifest map from its authoritative
/// path immediately before a lifecycle mutation. A missing, malformed or
/// identity-mismatched document means a hidden incoming reference cannot be
/// ruled out, so the result stays blocked.
final class MapDependencyPreflightService {
  const MapDependencyPreflightService({
    required MapRepository mapRepository,
  }) : _mapRepository = mapRepository;

  final MapRepository _mapRepository;

  Future<MapDependencyPreflightResult> inspect({
    required ProjectWorkspace workspace,
    required ProjectManifest project,
    required String mapId,
    required MapDependencyPreflightOperation operation,
  }) async {
    final normalizedMapId = mapId.trim();
    final loadedMaps = <MapData>[];
    final issues = <MapDependencyIndexIssue>[];
    final seenIds = <String>{};

    for (final entry in project.maps) {
      if (!seenIds.add(entry.id)) {
        issues.add(
          MapDependencyIndexIssue(
            kind: MapDependencyIndexIssueKind.duplicateManifestId,
            mapId: entry.id,
            relativePath: entry.relativePath,
            message:
                'La map « ${entry.id} » apparaît plusieurs fois dans le manifeste.',
          ),
        );
        continue;
      }

      try {
        final path = workspace.resolveMapPath(entry.relativePath);
        final loaded = await _loadMapForIndex(path);
        if (loaded.id != entry.id) {
          issues.add(
            MapDependencyIndexIssue(
              kind: MapDependencyIndexIssueKind.identityMismatch,
              mapId: entry.id,
              relativePath: entry.relativePath,
              message: 'Le fichier « ${entry.relativePath} » déclare '
                  'l’identité « ${loaded.id} » au lieu de « ${entry.id} ».',
            ),
          );
          continue;
        }
        loadedMaps.add(loaded);
      } on Object catch (error) {
        issues.add(
          MapDependencyIndexIssue(
            kind: MapDependencyIndexIssueKind.unreadableMap,
            mapId: entry.id,
            relativePath: entry.relativePath,
            message: 'Impossible d’indexer « ${entry.relativePath} » : $error',
          ),
        );
      }
    }

    // Core owns the exhaustive typed traversal. The editor only owns loading,
    // lifecycle authorization and presentation of its canonical usages.
    final index = buildNarrativeDependencyIndex(
      project: project,
      maps: loadedMaps,
    );
    final inspection = inspectNarrativeDependency(
      index,
      NarrativeDependencyKey.map(normalizedMapId),
    );
    if (inspection.isMissing) {
      issues.add(
        MapDependencyIndexIssue(
          kind: MapDependencyIndexIssueKind.missingTargetDefinition,
          mapId: normalizedMapId,
          relativePath: '',
          message:
              'La cible « $normalizedMapId » est absente du manifeste des maps.',
        ),
      );
    } else if (inspection.isAmbiguous) {
      issues.add(
        MapDependencyIndexIssue(
          kind: MapDependencyIndexIssueKind.ambiguousTargetDefinition,
          mapId: normalizedMapId,
          relativePath: '',
          message:
              'La cible « $normalizedMapId » possède plusieurs définitions.',
        ),
      );
    }

    return MapDependencyPreflightResult(
      operation: operation,
      mapId: normalizedMapId,
      inspection: inspection,
      indexIssues: issues,
    );
  }

  Future<MapDependencyPreflightResult> requireAllowed({
    required ProjectWorkspace workspace,
    required ProjectManifest project,
    required String mapId,
    required MapDependencyPreflightOperation operation,
  }) async {
    final result = await inspect(
      workspace: workspace,
      project: project,
      mapId: mapId,
      operation: operation,
    );
    if (!result.isAllowed) {
      throw MapDependencyPreflightBlockedException(result);
    }
    return result;
  }

  Future<MapData> _loadMapForIndex(String path) async {
    if (_mapRepository case RevisionedMapRepository revisioned) {
      return (await revisioned.loadMapDocument(path)).map;
    }
    return _mapRepository.loadMap(path);
  }
}
````

### 12.3 — `packages/map_editor/lib/src/ui/design_system/pokemap_dependency_preflight_dialog.dart`

Modale Design System.

- Lignes : 193
- SHA-256 : `e053b53bf8b009dbceeab07910296bae13743c2aa94ead88809b424387affde8`

````dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';
import 'narrative/pokemap_dependency_inspector.dart';
import 'pokemap_button.dart';
import 'pokemap_diagnostic_callout.dart';
import 'pokemap_panel.dart';
import 'pokemap_section_header.dart';

const pokeMapDependencyPreflightDialogKey =
    ValueKey<String>('pokemap-dependency-preflight-dialog');

/// Presents a fail-closed map lifecycle result without offering a destructive
/// override.
///
/// Consumer navigation keeps the canonical Core intent intact. The dialog is
/// dismissed before [onOpen] runs so the destination is never hidden behind a
/// stale modal route.
Future<void> showPokeMapDependencyPreflightDialog(
  BuildContext context, {
  required String title,
  required String message,
  required NarrativeDependencyInspectionReadModel inspection,
  required List<String> indexDiagnostics,
  ValueChanged<NarrativeDependencyNavigationIntent>? onOpen,
}) async {
  final colors = context.pokeMapColors;
  final selectedIntent =
      await showGeneralDialog<NarrativeDependencyNavigationIntent>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer le détail des dépendances',
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _PokeMapDependencyPreflightDialog(
        title: title,
        message: message,
        inspection: inspection,
        indexDiagnostics: indexDiagnostics,
        onOpen: onOpen == null
            ? null
            : (intent) => Navigator.of(dialogContext).pop(intent),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
  if (selectedIntent != null) onOpen?.call(selectedIntent);
}

final class _PokeMapDependencyPreflightDialog extends StatelessWidget {
  const _PokeMapDependencyPreflightDialog({
    required this.title,
    required this.message,
    required this.inspection,
    required this.indexDiagnostics,
    required this.onOpen,
  });

  final String title;
  final String message;
  final NarrativeDependencyInspectionReadModel inspection;
  final List<String> indexDiagnostics;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(760.0, math.max(320.0, viewport.width - 48));
    final dialogHeight = math.min(760.0, math.max(320.0, viewport.height - 48));

    return SafeArea(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: FocusTraversalGroup(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                key: pokeMapDependencyPreflightDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: title,
                explicitChildNodes: true,
                child: SizedBox(
                  width: dialogWidth,
                  height: dialogHeight,
                  child: PokeMapPanel(
                    expandChild: true,
                    padding: EdgeInsets.zero,
                    header: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_tree_outlined,
                            color: colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    footer: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: PokeMapButton(
                          autofocus: true,
                          onPressed: () => Navigator.of(context).pop(),
                          variant: PokeMapButtonVariant.secondary,
                          child: const Text('Fermer'),
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PokeMapDiagnosticCallout(
                            severity: PokeMapDiagnosticSeverity.error,
                            title: 'Action non autorisée',
                            message: message,
                          ),
                          if (indexDiagnostics.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            PokeMapSectionHeader(
                              title: 'Index incomplet',
                              description:
                                  '${indexDiagnostics.length} diagnostic(s)',
                            ),
                            const SizedBox(height: 8),
                            for (var index = 0;
                                index < indexDiagnostics.length;
                                index++) ...[
                              if (index > 0) const SizedBox(height: 8),
                              PokeMapDiagnosticCallout(
                                severity: PokeMapDiagnosticSeverity.warning,
                                message: indexDiagnostics[index],
                              ),
                            ],
                          ],
                          const SizedBox(height: 18),
                          PokeMapDependencyInspector(
                            model: inspection,
                            onOpen: onOpen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
````

### 12.4 — `packages/map_editor/test/application/services/map_dependency_preflight_service_test.dart`

Tests du service.

- Lignes : 472
- SHA-256 : `ae2a8f69f154a6af668a51b3dc5199098eb7998b16e2c118df6eac6ae6539d37`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/map_dependency_preflight_service.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('MapDependencyPreflightService', () {
    test('allows a complete index without incoming references', () async {
      final fixture = _Fixture(
        project: _project(),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.rename,
      );

      expect(result.isComplete, isTrue);
      expect(result.inspection.isMissing, isFalse);
      expect(result.inspection.isAmbiguous, isFalse);
      expect(result.inspection.usages, isEmpty);
      expect(result.isAllowed, isTrue);
      expect(
        fixture.repository.loadedPaths,
        <String>[
          '/project/maps/source.json',
          '/project/maps/target.json',
        ],
      );
    });

    test('blocks every known incoming map usage with canonical navigation',
        () async {
      const sourceWithReferences = MapData(
        id: 'source',
        name: 'Source',
        size: GridSize(width: 8, height: 8),
        warps: <MapWarp>[
          MapWarp(
            id: 'warp_to_target',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'target',
            targetPos: GridPos(x: 2, y: 2),
          ),
        ],
        connections: <MapConnection>[
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'target',
          ),
        ],
      );
      final fixture = _Fixture(
        project: _project(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'target',
          ),
        ),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': sourceWithReferences,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.delete,
      );

      expect(result.isComplete, isTrue);
      expect(result.isAllowed, isFalse);
      expect(
        result.inspection.usages.map((usage) => usage.path),
        containsAll(<String>[
          'maps[source].warps[0].targetMapId',
          'maps[source].connections[0].targetMapId',
          'newGame.startMapId',
        ]),
      );
      final warpUsage = result.inspection.usages.singleWhere(
        (usage) => usage.path == 'maps[source].warps[0].targetMapId',
      );
      expect(warpUsage.navigationIntent?.mapId, 'source');
      expect(warpUsage.navigationIntent?.sourceKind, 'warp');
      expect(warpUsage.navigationIntent?.assetId, 'warp_to_target');
      expect(result.blockingMessage, contains('3 usages'));
      expect(result.blockingMessage, contains('Aucune écriture'));
    });

    test('blocks a self-reference instead of treating it as ownership',
        () async {
      const targetWithSelfWarp = MapData(
        id: 'target',
        name: 'Target',
        size: GridSize(width: 8, height: 8),
        warps: <MapWarp>[
          MapWarp(
            id: 'loop',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'target',
            targetPos: GridPos(x: 4, y: 4),
          ),
        ],
      );
      final fixture = _Fixture(
        project: _project(),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': targetWithSelfWarp,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.rename,
      );

      expect(result.isComplete, isTrue);
      expect(result.isAllowed, isFalse);
      expect(
        result.inspection.usages.single.path,
        'maps[target].warps[0].targetMapId',
      );
    });

    test('fails closed and keeps known usages when one map cannot be loaded',
        () async {
      final fixture = _Fixture(
        project: _project(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'target',
          ),
          extraMaps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'unreadable',
              name: 'Unreadable',
              relativePath: 'maps/unreadable.json',
            ),
          ],
        ),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.delete,
      );

      expect(result.isComplete, isFalse);
      expect(result.isAllowed, isFalse);
      expect(result.indexIssues, hasLength(1));
      expect(result.indexIssues.single.mapId, 'unreadable');
      expect(result.indexIssues.single.relativePath, 'maps/unreadable.json');
      expect(result.inspection.usages.map((usage) => usage.path),
          contains('newGame.startMapId'));
      expect(result.blockingMessage, contains('index incomplet'));
      expect(result.blockingMessage, contains('Aucune écriture'));
    });

    test('fails closed when a loaded document identity mismatches its entry',
        () async {
      final fixture = _Fixture(
        project: _project(),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': MapData(
            id: 'wrong',
            name: 'Wrong identity',
            size: GridSize(width: 8, height: 8),
          ),
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.rename,
      );

      expect(result.isComplete, isFalse);
      expect(result.isAllowed, isFalse);
      expect(result.indexIssues.single.mapId, 'target');
      expect(result.indexIssues.single.message, contains('wrong'));
    });

    test('fails closed when any manifest map id is duplicated', () async {
      final fixture = _Fixture(
        project: _project(
          extraMaps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'source',
              name: 'Duplicate source',
              relativePath: 'maps/duplicate-source.json',
            ),
          ],
        ),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.delete,
      );

      expect(result.isComplete, isFalse);
      expect(result.isAllowed, isFalse);
      expect(
        result.indexIssues,
        contains(
          isA<MapDependencyIndexIssue>()
              .having(
                (issue) => issue.kind,
                'kind',
                MapDependencyIndexIssueKind.duplicateManifestId,
              )
              .having((issue) => issue.mapId, 'map id', 'source'),
        ),
      );
      expect(
        fixture.repository.loadedPaths,
        isNot(contains('/project/maps/duplicate-source.json')),
      );
    });

    test('fails closed when the requested target is absent', () async {
      final fixture = _Fixture(
        project: _project(),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'missing',
        operation: MapDependencyPreflightOperation.rename,
      );

      expect(result.isComplete, isFalse);
      expect(result.isAllowed, isFalse);
      expect(result.inspection.isMissing, isTrue);
      expect(
        result.indexIssues,
        contains(
          isA<MapDependencyIndexIssue>().having(
            (issue) => issue.kind,
            'kind',
            MapDependencyIndexIssueKind.missingTargetDefinition,
          ),
        ),
      );
    });

    test('requireAllowed exposes the structured blocked result', () async {
      final fixture = _Fixture(
        project: _project(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'target',
          ),
        ),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      await expectLater(
        fixture.service.requireAllowed(
          workspace: fixture.workspace,
          project: fixture.project,
          mapId: 'target',
          operation: MapDependencyPreflightOperation.delete,
        ),
        throwsA(
          isA<MapDependencyPreflightBlockedException>()
              .having(
                (error) => error.result.mapId,
                'map id',
                'target',
              )
              .having(
                (error) => error.result.isComplete,
                'complete index',
                isTrue,
              ),
        ),
      );
      expect(fixture.repository.saveCalls, isZero);
      expect(fixture.repository.deleteCalls, isZero);
    });
  });
}

const _sourceMap = MapData(
  id: 'source',
  name: 'Source',
  size: GridSize(width: 8, height: 8),
);

const _targetMap = MapData(
  id: 'target',
  name: 'Target',
  size: GridSize(width: 8, height: 8),
);

ProjectManifest _project({
  ProjectNewGameConfig newGame = const ProjectNewGameConfig(),
  List<ProjectMapEntry> extraMaps = const <ProjectMapEntry>[],
}) {
  return ProjectManifest(
    name: 'DS-04',
    maps: <ProjectMapEntry>[
      const ProjectMapEntry(
        id: 'source',
        name: 'Source',
        relativePath: 'maps/source.json',
      ),
      const ProjectMapEntry(
        id: 'target',
        name: 'Target',
        relativePath: 'maps/target.json',
      ),
      ...extraMaps,
    ],
    tilesets: const <ProjectTilesetEntry>[],
    newGame: newGame,
  );
}

final class _Fixture {
  _Fixture({
    required this.project,
    required Map<String, MapData> mapsByPath,
  }) : repository = _MapRepository(mapsByPath);

  final ProjectManifest project;
  final _Workspace workspace = const _Workspace();
  final _MapRepository repository;

  MapDependencyPreflightService get service =>
      MapDependencyPreflightService(mapRepository: repository);
}

final class _MapRepository implements MapRepository {
  _MapRepository(this.mapsByPath);

  final Map<String, MapData> mapsByPath;
  final List<String> loadedPaths = <String>[];
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    return mapsByPath[path] ?? (throw StateError('Unreadable map at $path'));
  }

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    saveCalls += 1;
  }

  @override
  Future<void> deleteMap(String path) async {
    deleteCalls += 1;
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {
    throw UnimplementedError();
  }
}

final class _Workspace implements ProjectWorkspace {
  const _Workspace();

  @override
  String get projectRoot => '/project';

  @override
  String get projectManifestPath => '/project/project.json';

  @override
  String resolveMapPath(String relativePath) => '/project/$relativePath';

  @override
  String getMapPath(String mapId) => '/project/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/project/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/project/$relativePath';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> deleteDirectoryIfEmpty(String path) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRelativeFile(String relativePath) =>
      throw UnimplementedError();

  @override
  Future<bool> directoryExists(String path) async => true;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<String> readTextFile(String path) => throw UnimplementedError();

  @override
  Future<void> writeTextFile(String path, String contents) =>
      throw UnimplementedError();
}
````

### 12.5 — `packages/map_editor/test/ui/design_system/pokemap_dependency_preflight_dialog_test.dart`

Tests widget de la modale.

- Lignes : 160
- SHA-256 : `9649597b7089d8f529e31f19d06449a02e7d5513887adc57b57e3a0e1395179b`

````dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_dependency_preflight_dialog.dart';

void main() {
  const target = NarrativeDependencyKey.map('alpha');
  const intent = NarrativeDependencyNavigationIntent(
    kind: NarrativeDependencyTargetKind.sourceMap,
    assetId: 'to_alpha',
    mapId: 'beta',
    sourceKind: 'warp',
  );
  const usage = NarrativeDependencyUsage(
    target: target,
    owner: NarrativeDependencyKey.mapSource(
      mapId: 'beta',
      sourceKind: 'warp',
      sourceId: 'to_alpha',
    ),
    path: 'maps[beta].warps[0].targetMapId',
    criticality: NarrativeDependencyCriticality.runtimeBlocking,
    navigationIntent: intent,
  );
  final inspection = NarrativeDependencyInspectionReadModel(
    target: target,
    definitions: <NarrativeDependencyDefinition>[
      NarrativeDependencyDefinition(
        key: target,
        label: 'Alpha',
        path: 'maps[alpha]',
      ),
    ],
    usages: const <NarrativeDependencyUsage>[usage],
    issues: const <NarrativeDependencyIssue>[],
  );

  testWidgets('shows usages, index diagnostics and opens the exact intent',
      (tester) async {
    final opened = <NarrativeDependencyNavigationIntent>[];
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapDependencyPreflightDialog(
        context,
        title: 'Renommage bloqué',
        message: 'Aucune écriture n’a été effectuée.',
        inspection: inspection,
        indexDiagnostics: const <String>[
          'Impossible d’indexer maps/gamma.json.',
        ],
        onOpen: opened.add,
      ),
    );

    await tester.tap(find.text('Ouvrir le détail'));
    await tester.pumpAndSettle();

    expect(find.text('Renommage bloqué'), findsOneWidget);
    expect(find.text('Aucune écriture n’a été effectuée.'), findsOneWidget);
    expect(
      find.text('Impossible d’indexer maps/gamma.json.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('maps[beta].warps[0].targetMapId'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<Object>((
          'dependency-inspector-consumer-open',
          target,
          NarrativeDependencyKey.mapSource(
            mapId: 'beta',
            sourceKind: 'warp',
            sourceId: 'to_alpha',
          ),
          'maps[beta].warps[0].targetMapId',
        )),
      ),
    );
    await tester.pumpAndSettle();

    expect(opened, const <NarrativeDependencyNavigationIntent>[intent]);
    expect(find.text('Renommage bloqué'), findsNothing);
  });

  testWidgets('can be dismissed without navigation', (tester) async {
    final opened = <NarrativeDependencyNavigationIntent>[];
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapDependencyPreflightDialog(
        context,
        title: 'Suppression bloquée',
        message: 'Un usage entrant doit être retiré.',
        inspection: inspection,
        indexDiagnostics: const <String>[],
        onOpen: opened.add,
      ),
    );

    await tester.tap(find.text('Ouvrir le détail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.text('Suppression bloquée'), findsNothing);
  });

  testWidgets('Escape dismisses the modal without navigation', (tester) async {
    final opened = <NarrativeDependencyNavigationIntent>[];
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapDependencyPreflightDialog(
        context,
        title: 'Suppression bloquée',
        message: 'Un usage entrant doit être retiré.',
        inspection: inspection,
        indexDiagnostics: const <String>[],
        onOpen: opened.add,
      ),
    );

    await tester.tap(find.text('Ouvrir le détail'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.text('Suppression bloquée'), findsNothing);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onLaunch,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onLaunch(context),
            child: const Text('Ouvrir le détail'),
          ),
        ),
      ),
    ),
  );
}
````
