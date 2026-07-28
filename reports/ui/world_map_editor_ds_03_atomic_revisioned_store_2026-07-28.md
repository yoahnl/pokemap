# Evidence Pack — World Map DS-03 Atomic Revisioned Store

## 0. Identité du lot et verdict

- **Lot exact :** `DS-03 — Atomic Revisioned Map Store`
- **Date de clôture :** 2026-07-28
- **Gap d’audit traité :** `WM-03` — persistance map non atomique et
  last-write-wins.
- **Package :** `packages/map_editor`
- **Branche / HEAD :** `main` /
  `a3d741818c1961ac2f653da235bb30c20df75b00`
- **Verdict DS-03 :** **PASS**
- **Gate 0 global :** **PARTIAL** — DS-04 et DS-05 restent volontairement
  ouverts.
- **Écriture Git :** aucune. Aucun `add`, commit, stash, reset, restore,
  checkout, merge, push ou nettoyage.

Le lot met toutes les écritures produit de map concernées par DS-03 derrière
une révision SHA-256 des octets réellement chargés, un fichier temporaire
frère flushé, un journal préparé, une seconde comparaison juste avant le
rename, une vérification après commit et une récupération déterministe.

Le changement externe n’est plus écrasé silencieusement par la sauvegarde de
la map active : l’éditeur conserve la map locale, l’historique et l’état dirty,
retourne un conflit et demande explicitement de recharger.

## 1. Règles et méthode suivies

Le fichier `codex_rule.md` a été lu intégralement avant la rédaction de ce
rapport. Les workflows locaux lus et appliqués sont :

- `skills/README.md` ;
- `skills/writing-plans/SKILL.md` ;
- `skills/test-driven-development/SKILL.md` ;
- `skills/verification-before-completion/SKILL.md` ;
- `skills/executing-plans/SKILL.md` ;
- `skills/finishing-a-development-branch/SKILL.md` ;
- `/Users/karim/.codex/skills/karpathy-guidelines/SKILL.md`.

Les règles du dépôt interdisent les écritures Git sans demande explicite.
L’exigence worktree/branche du workflow d’exécution a donc été adaptée au
worktree partagé existant, sans mutation Git.

L’instruction développeur active interdisait de lancer des sub-agents sans
demande explicite de l’utilisateur. Conformément au fallback autorisé par
`codex_rule.md`, cinq passes séparées et nommées ont été effectuées par l’agent
principal.

## 2. Résumé exécutif

### Ce qui est désormais vrai

1. Une lecture réelle retourne la map validée avec la révision SHA-256 de ses
   octets exacts.
2. Une sauvegarde stricte exige soit l’absence de cible, soit la révision
   exacte chargée.
3. Le payload est écrit dans un temporaire frère, flushé puis relu et hashé.
4. Un journal préparé et flushé décrit `before` / `after`.
5. Une seconde CAS est exécutée immédiatement avant le rename atomique.
6. Le fichier final est relu et son hash vérifié avant succès.
7. Les interruptions avant et après rename sont récupérées sans choix
   heuristique destructeur.
8. Les writers coopératifs sont sérialisés par queue locale et lock fichier
   exclusif inter-processus.
9. Les créations, duplications et cibles de renommage exigent l’absence.
10. Les suppressions et sources de renommage exigent leur révision chargée.
11. Le warp réciproque vers une autre map est sauvegardé par CAS.
12. La sauvegarde active, l’affectation de tileset et la récupération Event
    propagent et avancent l’attestation de révision.
13. Une activation de snapshot non attesté ne peut pas obtenir implicitement
    le droit d’écraser le disque.
14. Le changement de projet purge toutes les attestations.
15. Le renommage d’une map active déplace son attestation vers le nouveau
    chemin.

### Frontière d’architecture

```text
LOAD
  chemin autorisé
      -> lock canonique
      -> récupération du journal éventuel
      -> lecture octets
      -> SHA-256
      -> décodage + validation
      -> MapData + révision attestée

SAVE
  MapData local + révision attendue
      -> lock canonique
      -> CAS initiale
      -> temp frère + flush + hash
      -> journal préparé + flush
      -> seconde CAS
      -> rename final atomique
      -> hash + décodage final
      -> nouvelle révision attestée
```

DS-03 garantit la frontière d’un **document map unique**. La transaction
durable multi-fichiers `map + project.json` n’est pas revendiquée.

## 3. Remise en cause et cadrage du prompt

La demande « faire le DS-03 » était cohérente avec l’audit précédent et ne
nécessitait pas de renommer le lot. Deux limites ont néanmoins été imposées
par les preuves du dépôt :

- `MapRepository` est implémenté par de nombreuses fakes historiques. Modifier
  directement toutes ses méthodes aurait créé un churn non pertinent. Une
  capacité séparée `RevisionedMapRepository` conserve la compatibilité source.
- Les use cases create/duplicate/rename/delete modifient plusieurs fichiers.
  DS-03 sécurise chaque mutation map et ses compensations, mais ne peut pas
  prétendre rendre atomique l’ensemble map + manifeste. Ce point reste DS-05.

La stratégie retenue est donc plus petite et plus sûre : nouvelle frontière
stricte pour le repository filesystem réel, fallback legacy uniquement pour
les fakes non révisionnées, et aucun changement de schéma JSON.

## 4. Audit initial

### Fichiers et contrats observés

- `lib/src/domain/repositories/repositories.dart` exposait uniquement
  `saveMap/loadMap/deleteMap/renameMap`, sans révision.
- `FileMapRepository.saveMap` écrivait la cible finale sans CAS portée par
  l’appelant.
- `CreateMapUseCase`, `DuplicateMapUseCase` et `RenameMapUseCase` faisaient des
  séquences check/read/write multi-fichiers.
- `DeleteMapUseCase` supprimait sans prouver que le fichier était encore celui
  qui avait été chargé.
- `CreateReciprocalWarpUseCase` relisait puis sauvegardait une cible non active
  par last-write-wins.
- `EditorNotifier.saveActiveMap` ne conservait aucune révision durable.
- `AssignTilesetToMapUseCase` écrivait directement la map.
- la fondation DS-00→DS-02 apportait déjà confinement de chemins, identifiants
  canoniques et gateway unique d’activation ; ces invariants devaient rester
  intacts.
- la création/récupération Event possède son propre journal transactionnel.
  Une régression a prouvé que son adoption mémoire relisait cependant la map
  sans transmettre la nouvelle révision au notifier.

### Tests et rapports pertinents lus

- `reports/ui/world_map_editor_audit_2026-07-28/`
  `world_map_editor_ultra_complete_audit.md` ;
- `reports/ui/world_map_editor_foundation_ds_00_ds_02_2026-07-28.md` ;
- tests lifecycle map existants ;
- tests activation/guard DS-02 ;
- tests du banner Event et de sa récupération concurrente ;
- test roundtrip d’une session réelle.

### Risques initiaux

- écrasement d’une édition externe ;
- cible create/duplicate/rename remplacée après un check trop ancien ;
- suppression d’une version externe pendant rollback ;
- état intermédiaire après interruption ;
- faux succès après rename déjà visible ;
- writers simultanés dans deux processus ;
- cache de révision survivant à un changement de projet ;
- snapshot mémoire obtenant un droit d’écriture non prouvé ;
- rupture des nombreuses fakes `MapRepository` ;
- fausse déclaration d’atomicité multi-fichiers.

### Non-objectifs confirmés

- aucun DS-04 (index de dépendances) ;
- aucun DS-05 (transaction durable map + manifeste) ;
- aucune fusion automatique d’éditions divergentes ;
- aucune refonte visuelle ou d’interaction ;
- aucun changement de schéma map ;
- aucune migration des IDs ou chemins legacy ;
- aucune modification du runtime/Flame.

## 5. Verdict des cinq passes séparées

| Passe | Travail effectué | Verdict |
|---|---|---|
| Audit / Architecture | contrats, writers, lifecycle, fondation DS-00→DS-02, journal Event et limites multi-fichiers examinés | **PASS** — capacité séparée et frontière single-map cohérentes |
| Implémentation | invariants du lock, temp, flush, hash, journal, double CAS, rename, récupération et propagation UI relus ligne par ligne | **PASS avec réserves documentées** — aucune violation de package ni de schéma |
| Tests | RED réels, checkpoints injectés, conflits, récupération, lifecycle, notifier et régression Event exécutés | **PASS** — le pack final compte 459 tests verts |
| Build / Validation | format, analyse package, diff check et build macOS release frais | **PASS** — analyse sans issue, app release produite |
| Critique finale | recherche de writers de contournement, attestations manquantes, checkpoint non testé, symlinks, suppression CAS et renommage actif | **PASS après corrections** — un flux Event réel et quatre preuves manquantes ont été ajoutés/corrigés |

## 6. Inventaire complet du lot

### Fichiers créés

| Fichier | Rôle |
|---|---|
| `docs/superpowers/plans/2026-07-28-world-map-ds-03-atomic-revisioned-store.md` | plan TDD et checklist DS-03 ; fichier ignoré par l’état Git courant |
| `packages/map_editor/lib/src/domain/models/map_document_persistence.dart` | préconditions, document révisionné et résultat de récupération |
| `packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart` | canonicalisation, queue locale et lock OS |
| `packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart` | protocole atomique, journal et récupération |
| `packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart` | 17 preuves du store réel |
| `packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart` | 5 preuves des capacités lifecycle/warp |
| `packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart` | 8 preuves d’attestation et conflits dans l’éditeur |
| `reports/ui/world_map_editor_ds_03_atomic_revisioned_store_2026-07-28.md` | présent Evidence Pack |

### Fichiers modifiés par DS-03

| Fichier | Zones actuelles | Raison et impact |
|---|---|---|
| `packages/map_editor/lib/src/domain/repositories/repositories.dart` | lignes 25–50, `RevisionedMapRepository` | ajoute la capacité stricte sans casser `MapRepository` |
| `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart` | lignes 266–376, `FileMapRepository` | délègue au store atomique, expose load/save/delete/recover révisionnés |
| `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart` | 16–63, 64–207, 244–469, 514–559 | load/save révisionnés, expected-absence, delete CAS, résultat de rename |
| `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart` | 394–485 | affectation de tileset CAS avec nouvelle révision |
| `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart` | 96–203 | warp réciproque non actif chargé et sauvegardé avec la même révision |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | 203–217, 1133–1175, 1756–2326, 2727–2850, 3243–3372, 3803–3868 | cache attesté, save conflict, lifecycle, snapshots, cleanup Event et tileset |

Le worktree contenait déjà de nombreuses modifications avant DS-03, y compris
dans `map_use_cases.dart` et `editor_notifier.dart`. Un `git diff` global ne
peut donc pas servir de patch DS-03 isolé. Les classes/fonctions et plages
ci-dessus sont la délimitation précise du lot ; les fichiers nouvellement créés
sont reproduits intégralement en annexe.

### Découpage précis des modifications

#### Contrat repository

```dart
abstract interface class RevisionedMapRepository implements MapRepository {
  Future<RevisionedMapDocument> loadMapDocument(String path);
  Future<RevisionedMapDocument> saveMapDocument(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
    ProjectManifest? projectDialogueContext,
  });
  Future<void> deleteMapDocument(
    String path, {
    required String expectedRevision,
  });
  Future<MapDocumentRecoveryResult> recoverMapDocument(String path);
}
```

#### Repository filesystem

- `FileMapRepository implements RevisionedMapRepository` ;
- `saveMap` reste une compatibilité atomique replace-latest ;
- `saveMapDocument` valide, encode, exécute la CAS et vérifie le document
  durable ;
- `loadMapDocument` passe d’abord par la récupération puis décode ;
- `deleteMapDocument` exige la révision exacte ;
- `recoverMapDocument` expose le résultat produit.

#### Use cases lifecycle

- `CreateMapUseCase` : target `absent`, compensation par révision créée ;
- `DuplicateMapUseCase` : target `absent`, compensation par révision créée ;
- `RenameMapUseCase.executeRevisioned` : source chargée avec révision, target
  `absent`, suppression source avec la révision chargée, résultat map/révision ;
- `DeleteMapUseCase` : suppression de la source seulement si sa révision
  chargée est encore courante ;
- `CreateReciprocalWarpUseCase` : target non active sauvegardée avec sa
  révision de lecture.

#### Éditeur

- `_mapDocumentRevisionAttestations` est indexé par chemin absolu normalisé ;
- l’attestation de snapshot lie la révision à l’identité exacte de l’objet lu ;
- `_renewProjectSessionIdentity` purge toutes les attestations ;
- `activateMap`, create et read-only snapshot mémorisent seulement une
  révision réellement retournée par le repository ;
- `saveActiveMap` refuse une attestation absente/périmée, conserve l’état local
  et retourne `ActiveMapSaveOutcome.conflict` ;
- un succès avance la révision seulement après revalidation de la lease ;
- rename déplace l’attestation, delete la retire ;
- l’affectation de tileset utilise la révision active ;
- l’adoption d’un nettoyage Event propage la révision du snapshot disque
  nettoyé, y compris lors d’un rebase d’édition locale.

## 7. Tests créés et couverture

### Store atomique — 17 tests

1. révisions malformées refusées avant I/O ;
2. hash exact des octets durables ;
3. expected-absence refuse une cible existante ;
4. révision périmée préserve les octets externes ;
5. delete CAS préserve une modification externe ;
6. cible symlink refusée ;
7. temp frère flushé et vérifié ;
8. seconde CAS préserve une édition externe ;
9. temp corrompu refusé ;
10. échec pré-rename conserve la cible ;
11. échec callback post-rename vérifié comme commit ;
12. échec avant vérification finale vérifié comme commit ;
13. crash préparé complété si baseline inchangée ;
14. crash post-rename nettoyé sans réécriture ;
15. divergence avant/après bloque la récupération ;
16. temp orphelin sans journal supprimé ;
17. writers concurrents sérialisés par le lock.

Chaque valeur de `AtomicMapDocumentWriteCheckpoint` est désormais exercée par
injection.

### Lifecycle révisionné — 5 tests

- create utilise `absent` ;
- duplicate utilise `absent` ;
- rename supprime la source avec sa révision ;
- delete utilise la révision chargée ;
- warp réciproque sauvegarde la cible avec la même révision.

### EditorNotifier — 8 tests

- deux sauvegardes normales avancent la révision ;
- édition externe : conflit et état local/historique préservés ;
- reload après conflit puis save ;
- snapshot non attesté : fail closed ;
- tileset du layer actif : CAS ;
- changement de projet : cache vidé ;
- rename actif : attestation déplacée ;
- création : révision prête pour le save suivant.

### Non-régressions

- lifecycle DS-00/01 ;
- activation et guard DS-02 ;
- navigation Event ;
- toolbar ;
- bridge et routes Event ;
- shell editor ;
- banner/récupération Event ;
- roundtrip session réelle.

## 8. Journal TDD RED → GREEN

### RED contrat/store

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/infrastructure/repositories/atomic_map_document_persistence_test.dart
```

Résultat initial : **exit 1**, compilation rouge attendue sur les types
`MapDocumentWritePrecondition`, `RevisionedMapDocument`,
`AtomicMapDocumentPersistence` et les méthodes révisionnées absentes.

Après la première implémentation : **12/13 tests verts** ; le seul échec venait
du test de lock qui attachait son matcher après la future fautive. Le matcher a
été attaché avant de libérer le premier writer, sans changement du comportement
produit.

Premier GREEN store : `+13: All tests passed!`. La suite finale comporte 17
tests après la passe critique.

### RED lifecycle

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
```

Résultat : **exit 1, 5/5 scénarios rouges**. Les use cases appelaient encore
les chemins legacy save/load/delete.

Premier pack GREEN store + lifecycle :

```text
+52: All tests passed!
```

### RED notifier

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/features/editor/state/editor_notifier_map_revision_test.dart
```

Résultat exact : **`+1 -4: Some tests failed.`**

- sauvegarde externe attendue `conflict`, obtenue `saved` ;
- reload conflict idem ;
- snapshot non attesté attendu `conflict`, obtenu `saved` ;
- tileset externe attendu en erreur, `errorMessage == null` ;
- création puis save était déjà verte.

Premier GREEN notifier : `+5: All tests passed!`, ensuite étendu à 8 tests.

### Régression produit découverte

Un premier pack large après intégration a échoué :

```text
+454 -1: Some tests failed.
```

Test exact :

```text
NS-EVENT-V2-25 map source creation banner cleanup rebases the exact owner
deletion over unrelated concurrent map edits
```

Erreur exacte utile :

```text
Expected: 'Concurrent map label'
Actual:   ''
```

Cause : `adoptPersistedNarrativeEventSourceCleanup` relisait le snapshot
nettoyé via `MapRepository.loadMap` et adoptait la map sans mémoriser sa
révision. Le save strict échouait donc fermé et l’édition concurrente restait
uniquement en mémoire.

Correction : ajout de `LoadMapUseCase.executeAbsolutePath`, adoption du
`LoadedMapDocumentResult`, puis mémorisation de la révision seulement après
validation et adoption du snapshot/rebase.

Relance isolée :

```bash
flutter test --no-pub --reporter expanded \
  test/ui/canvas/narrative_event_map_banner_test.dart \
  --plain-name \
  "NS-EVENT-V2-25 map source creation banner cleanup rebases the exact owner deletion over unrelated concurrent map edits"
```

Résultat : **`+1: All tests passed!`**.

## 9. Vérifications finales fraîches

### Format

```bash
cd packages/map_editor
dart format --output=none --set-exit-if-changed \
  lib/src/domain/models/map_document_persistence.dart \
  lib/src/domain/repositories/repositories.dart \
  lib/src/infrastructure/repositories/map_document_write_lock.dart \
  lib/src/infrastructure/repositories/atomic_map_document_persistence.dart \
  lib/src/infrastructure/repositories/file_repositories.dart \
  lib/src/application/use_cases/map_use_cases.dart \
  lib/src/application/use_cases/project_tileset_use_cases.dart \
  lib/src/application/use_cases/warp_use_cases.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/infrastructure/repositories/atomic_map_document_persistence_test.dart \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart \
  test/features/editor/state/editor_notifier_map_revision_test.dart
```

Résultat exact : **exit 0 — `Formatted 12 files (0 changed) in 0.17
seconds.`**

### Tests de cœur finaux

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/infrastructure/repositories/atomic_map_document_persistence_test.dart \
  test/features/editor/state/editor_notifier_map_revision_test.dart
```

Résultat exact : **exit 0 — `+25: All tests passed!`**.

### Pack DS-00→DS-03 final

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact \
  test/application/services/project_map_id_policy_test.dart \
  test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart \
  test/infrastructure/repositories/atomic_map_document_persistence_test.dart \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/features/editor/application/map_activation_coordinator_test.dart \
  test/features/editor/state/editor_notifier_map_revision_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/features/editor/presentation/map_activation_guard_test.dart \
  test/event_map_navigation_controller_test.dart \
  test/top_toolbar_test.dart \
  test/ui/panels/narrative_event_map_bridge_panel_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/event_builder_workspace_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart \
  test/ui/canvas/narrative_event_map_banner_test.dart \
  test/editor_notifier_real_session_roundtrip_test.dart
```

Résultat exact : **exit 0 — `00:22 +459: All tests passed!`**.

Il s’agit d’un pack ciblé élargi, pas de la totalité du package
`flutter test`. Aucune affirmation de suite package complète n’est faite.

### Analyse

```bash
cd packages/map_editor
flutter analyze --no-pub
```

Résultat exact : **exit 0 — `No issues found! (ran in 6.7s)`**.

### Build macOS release

```bash
cd packages/map_editor
flutter build macos --release --no-pub
```

Résultat exact : **exit 0 —
`✓ Built build/macos/Build/Products/Release/PokeMap.app (44.6MB)`**.

### Diff check

```bash
git diff --check -- \
  packages/map_editor/lib/src/domain/repositories/repositories.dart \
  packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart \
  packages/map_editor/lib/src/application/use_cases/map_use_cases.dart \
  packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart \
  packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart \
  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
```

Résultat exact : **exit 0, aucune sortie**.

## 10. État Git initial

État capturé avant les éditions DS-03 :

```text
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
 M packages/map_editor/lib/src/application/services/narrative_template_catalog.dart
 M packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart
 M packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart
 M packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart
 M packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/map_connections_panel.dart
 M packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart
 M packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
 M packages/map_editor/test/event_map_navigation_controller_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_controller_test.dart
 M packages/map_editor/test/game_export/game_package_export_dialog_test.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
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
?? packages/map_editor/lib/src/application/services/project_map_id_policy.dart
?? packages/map_editor/lib/src/application/services/project_map_manifest_integrity_policy.dart
?? packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart
?? packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_editor/test/application/services/project_map_id_policy_test.dart
?? packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart
?? packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart
?? packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart
?? packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart
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
?? reports/ui/world_map_editor_foundation_ds_00_ds_02_2026-07-28.md
```

## 11. État Git final

État capturé après création du présent Evidence Pack. Branche `main`, HEAD
`a3d741818c1961ac2f653da235bb30c20df75b00`.

```text
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
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/map_connections_panel.dart
 M packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart
 M packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
 M packages/map_editor/test/event_map_navigation_controller_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_controller_test.dart
 M packages/map_editor/test/game_export/game_package_export_dialog_test.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
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
?? packages/map_editor/lib/src/application/services/project_map_id_policy.dart
?? packages/map_editor/lib/src/application/services/project_map_manifest_integrity_policy.dart
?? packages/map_editor/lib/src/domain/models/map_document_persistence.dart
?? packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart
?? packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart
?? packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart
?? packages/map_editor/test/application/services/project_map_id_policy_test.dart
?? packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart
?? packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
?? packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart
?? packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart
?? packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart
?? packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart
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
?? reports/ui/world_map_editor_foundation_ds_00_ds_02_2026-07-28.md
```

## 12. Auto-critique et risques restants

### Ce qui a été activement vérifié

- aucune couleur/UI ad hoc ajoutée ;
- aucune dépendance ou génération ajoutée ;
- aucun changement `map_core`, runtime ou schéma map par DS-03 ;
- aucun writer produit ciblé ne contourne sciemment la CAS ;
- les readers purs restent compatibles ;
- la récupération Event conserve ses propres invariants et transmet désormais
  l’attestation ;
- les erreurs après rename ne sont pas automatiquement présentées comme un
  échec ;
- les preuves couvrent tous les checkpoints injectables.

### Risques techniques résiduels

1. **Fenêtre non coopérative après la seconde CAS.** Un autre programme qui
   ignore le lock peut écrire entre la dernière lecture et le `rename`. Dart
   n’expose pas une primitive portable rename-if-revision. La fenêtre est
   minimisée, les writers PokeMap sont verrouillés, mais elle n’est pas
   mathématiquement supprimée pour un writer externe hostile.
2. **Pas de fsync explicite du dossier parent.** Les handles temp/journal sont
   flushés et les contenus relus, mais `dart:io` ne fournit pas ici une preuve
   portable de durabilité du directory entry contre une coupure électrique au
   pire instant.
3. **Atomicité single-map seulement.** Create/duplicate/rename/delete peuvent
   encore être interrompus entre map et manifeste. Les compensations sont
   révisionnées, mais DS-05 reste nécessaire.
4. **Compatibilité legacy.** `MapRepository.saveMap` reste replace-latest pour
   les fakes et quelques appels historiques. Les chemins produit DS-03
   identifiés utilisent la capacité stricte ; une future API pourra réduire
   encore le legacy.
5. **Nettoyage retryable.** Un échec de suppression d’artefact peut laisser un
   journal/temp stable ; l’accès suivant le récupère. L’absence absolue
   d’artefact sous erreur permanente de permissions n’est pas prouvée.
6. **Pack ciblé, pas suite package totale.** 459 tests à haut signal ont été
   exécutés ; la totalité de `packages/map_editor/test` n’a pas été relancée.
7. **Worktree partagé très sale.** Les changements DS-03 coexistent avec des
   travaux antérieurs non liés. Aucun nettoyage ou isolement Git n’était
   autorisé.

### Auto-critique finale

La première intégration était trop centrée sur le flux map principal : le pack
large a révélé que l’adoption de récupération Event créait elle aussi une
nouvelle baseline disque. Le fail-closed empêchait heureusement l’écrasement,
mais rendait impossible la sauvegarde de l’édition locale rebasée. La bonne
correction était de propager la révision réelle à ce point d’adoption, pas de
réintroduire une sauvegarde legacy.

La première matrice de tests omettait aussi `beforeCommitVerification`, les
révisions malformées, le delete CAS réel et le déplacement d’attestation au
rename. La passe critique les a ajoutés avant clôture.

Le lot ne doit pas être présenté comme une garantie ACID globale : il fournit
une frontière single-document nettement plus sûre, avec les limites POSIX/Dart
ci-dessus explicitement reconnues.

## 13. Statut et suites proposées

- `DS-03` : **proposé DONE / PASS avec preuves fraîches**.
- `Gate 0` : **PARTIAL**.
- prochain lot recommandé : **DS-04**, index de dépendances et usages entrants
  navigables ;
- puis **DS-05**, transaction durable multi-fichiers map + manifeste et
  récupération de lifecycle ;
- seulement après Gate 0, engager la refonte ergonomique/visuelle profonde.

Ces suites ne sont pas implémentées dans ce lot.

## Annexe A — Contenu intégral des fichiers créés

Le présent rapport n’est pas inclus dans lui-même.


### A.1 — `docs/superpowers/plans/2026-07-28-world-map-ds-03-atomic-revisioned-store.md`

````markdown
# World Map DS-03 Atomic Revisioned Store Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist every World Map document through a same-directory,
flush-verified, SHA-256 revisioned compare-and-swap boundary that detects
external changes and deterministically recovers interrupted single-map writes.

**Architecture:** Keep the legacy `MapRepository` contract source-compatible
for existing test fakes, and add a separate `RevisionedMapRepository` capability
implemented by `FileMapRepository`. Put byte-level atomicity, cross-process
locking, journal inspection and recovery in focused infrastructure classes.
The active editor records the exact revision returned by the load/save boundary
and refuses to overwrite a map when that revision is missing or stale.

**Tech Stack:** Dart 3, Flutter desktop, `dart:io`, `map_core` SHA-256
fingerprints, Riverpod, `package:path`, `flutter_test`.

**Repository constraints:** The repository is on `main` with a heavily dirty
shared worktree. The direct user request authorizes implementation in the
current tree, while `AGENTS.md` forbids branch/worktree creation and every Git
write without separate authorization. Preserve unrelated edits and do not
commit, stage, stash, reset, restore, switch or clean.

---

## Scope

Included:

- byte revision contract for one map file;
- same-directory temporary file;
- explicit file-handle flush;
- SHA-256 verification of temporary and committed bytes;
- compare-and-swap against the revision captured at load;
- second CAS immediately before atomic rename;
- process-local queue plus OS file lock;
- deterministic write journal and safe recovery;
- failure injection at every durable checkpoint;
- expected-absence writes for create/duplicate/rename targets;
- revision-checked delete for lifecycle sources;
- active editor revision tracking and external-conflict feedback;
- reciprocal-warp and active-layer tileset direct writers;
- focused tests, regression pack, analyzer, macOS build and evidence report.

Excluded:

- DS-04 dependency indexing and navigable incoming-reference lists;
- DS-05 durable multi-file transactions for map + manifest lifecycle;
- automatic merge of divergent local and external map edits;
- broad World Map visual/interaction redesign;
- changes to map JSON schema;
- migration of legacy IDs or paths.

## Files

Create:

- `packages/map_editor/lib/src/domain/models/map_document_persistence.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart`
- `packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart`
- `packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart`
- `reports/ui/world_map_editor_ds_03_atomic_revisioned_store_2026-07-28.md`

Modify:

- `packages/map_editor/lib/src/domain/repositories/repositories.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- focused existing tests only when the new explicit contract requires an
  assertion update.

No generated provider/model file is expected to change.

---

### Task 1: Define the revisioned map repository contract

**Files:**

- Create:
  `packages/map_editor/lib/src/domain/models/map_document_persistence.dart`
- Modify:
  `packages/map_editor/lib/src/domain/repositories/repositories.dart`
- Create:
  `packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart`

- [x] **Step 1: Write the contract-first RED tests**

The test imports the new persistence and domain types and specifies:

```dart
test('returns the SHA-256 revision of the exact durable map bytes', () async {
  final saved = await repository.saveMapDocument(
    map,
    path,
    precondition: const MapDocumentWritePrecondition.absent(),
  );

  expect(saved.revision, narrativeEventBytesFingerprint(
    await File(path).readAsBytes(),
  ));
  expect((await repository.loadMapDocument(path)).revision, saved.revision);
});

test('rejects a stale revision without changing external bytes', () async {
  final baseline = await repository.loadMapDocument(path);
  await File(path).writeAsString(externalJson, flush: true);
  final externalBytes = await File(path).readAsBytes();

  await expectLater(
    repository.saveMapDocument(
      localMap,
      path,
      precondition:
          MapDocumentWritePrecondition.revision(baseline.revision),
    ),
    throwsA(isA<EditorConflictException>()),
  );
  expect(await File(path).readAsBytes(), externalBytes);
});
```

The domain contract is:

```dart
sealed class MapDocumentWritePrecondition {
  const MapDocumentWritePrecondition();
  const factory MapDocumentWritePrecondition.absent() =
      MapDocumentMustBeAbsent;
  const factory MapDocumentWritePrecondition.revision(String revision) =
      MapDocumentMustMatchRevision;
}

final class RevisionedMapDocument {
  const RevisionedMapDocument({
    required this.map,
    required this.revision,
  });

  final MapData map;
  final String revision;
}

abstract interface class RevisionedMapRepository implements MapRepository {
  Future<RevisionedMapDocument> loadMapDocument(String path);
  Future<RevisionedMapDocument> saveMapDocument(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
    ProjectManifest? projectDialogueContext,
  });
  Future<void> deleteMapDocument(
    String path, {
    required String expectedRevision,
  });
  Future<MapDocumentRecoveryResult> recoverMapDocument(String path);
}
```

- [x] **Step 2: Run RED**

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/infrastructure/repositories/atomic_map_document_persistence_test.dart
```

Expected: compilation failure because the DS-03 types and persistence do not
exist.

- [x] **Step 3: Add the minimal immutable domain types**

The recovery result exposes only product-relevant outcomes:

```dart
enum MapDocumentRecoveryStatus {
  clear,
  discardedIncompleteWrite,
  completedInterruptedWrite,
  cleanedCommittedWrite,
}
```

Revision constructors reject blank or malformed non-SHA-256 values before I/O.
Existing `MapRepository` methods remain unchanged.

- [x] **Step 4: Re-run the test**

Expected: it advances past missing domain symbols and remains RED on the
missing atomic implementation.

---

### Task 2: Implement the atomic byte store and recovery protocol

**Files:**

- Create:
  `packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart`
- Create:
  `packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart`
- Test:
  `packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart`

- [x] **Step 1: Extend RED coverage for the durable checkpoints**

Cover:

```dart
test('flushes and verifies a sibling temp before target replacement', () {});
test('second CAS preserves an external write made before rename', () {});
test('corrupted flushed temp is rejected without touching the target', () {});
test('failure before rename keeps original bytes visible', () {});
test('post-rename callback failure is verified as committed', () {});
test('prepared crash is completed by recovery when baseline still matches',
    () {});
test('post-rename crash is cleaned by recovery without rewriting target',
    () {});
test('recovery blocks when target diverged from both before and after', () {});
test('orphan temp without a journal is discarded safely', () {});
test('concurrent writers serialize through the same OS lock', () {});
```

- [x] **Step 2: Run RED and confirm the expected missing behavior**

Run the Task 1 command. Each new test must fail for a specific missing
checkpoint/recovery behavior, not from a malformed fixture.

- [x] **Step 3: Implement canonical locking**

`withMapDocumentWriteLock` must:

1. reject a target that is itself a symlink;
2. canonicalize the existing target or its real parent;
3. serialize in-process callers by canonical target path;
4. take an exclusive `RandomAccessFile.lock` on a SHA-256-addressed file under
   the system temporary directory;
5. release the lock/queue in `finally`.

- [x] **Step 4: Implement the prepared-write journal**

Use fixed, target-addressed sibling artifacts:

```text
.pokemap-map-<path-hash>.after.tmp
.pokemap-map-<path-hash>.journal.json
.pokemap-map-<path-hash>.journal.rewrite.tmp
```

The journal contains schema version, canonical target/temp paths, expected
absence or exact before revision, and expected after revision. It is written
through its own flushed rewrite temp and renamed before the map CAS.

- [x] **Step 5: Implement atomic write**

In one lock:

1. recover/clean any prior safe artifact;
2. read the exact current bytes and check the caller precondition;
3. serialize the requested bytes to the sibling temp;
4. flush the temp handle;
5. hash the reread temp and compare it to the expected after revision;
6. flush and promote the journal;
7. reread the target for the second CAS;
8. rename the temp over the final path;
9. reread/hash/decode the final file;
10. delete journal artifacts only after the durable revision is proven.

All known pre-rename failures clean safe artifacts. A dedicated injected
interruption sentinel deliberately preserves artifacts so tests can reproduce a
process crash without killing the test runner.

- [x] **Step 6: Implement deterministic recovery**

Under the same lock:

- final == after: verify and clean committed artifacts;
- final == before (or expected absent) and valid temp == after: finish rename,
  verify and clean;
- no journal: discard orphan temp/rewrite files;
- missing temp while final still equals before: discard the incomplete intent;
- final differs from both before and after: throw a conflict and preserve all
  evidence.

- [x] **Step 7: Run GREEN**

Run the Task 1 command. Expected: all atomic-store tests pass with no artifact
left after clear/committed/recovered paths.

---

### Task 3: Wire `FileMapRepository` and lifecycle use cases

**Files:**

- Modify:
  `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- Modify:
  `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
- Modify:
  `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart`
- Test:
  `packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart`

- [x] **Step 1: Add lifecycle RED tests with a revision-capable repository**

Cover:

```dart
test('Create uses expected-absence instead of check-then-overwrite', () {});
test('Duplicate uses expected-absence for its target', () {});
test('Rename revision-checks source deletion', () {});
test('Delete refuses a source changed after its load', () {});
test('reciprocal warp CAS preserves an externally changed target', () {});
```

- [x] **Step 2: Run RED**

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/application/use_cases/map_lifecycle_use_cases_test.dart
```

Expected: revision-capable fake records legacy unconditional writes/deletes.

- [x] **Step 3: Delegate repository I/O**

`FileMapRepository` validates/encodes `MapData`, delegates bytes to
`AtomicMapDocumentPersistence`, and verifies the decoded durable map. Its legacy
`saveMap` remains callable but is now an atomic replace-latest operation.
`loadMap` delegates to `loadMapDocument(...).map`, so every product read passes
the recovery gate.

- [x] **Step 4: Add internal capability helpers**

Use cases branch only on:

```dart
if (_mapRepo case RevisionedMapRepository revisioned) {
  // exact revision or expected absence
} else {
  // source-compatible legacy fake path
}
```

Create/duplicate/rename targets use `absent`; loaded lifecycle sources carry
their exact revision; delete and rename cleanup use revision-checked deletion.
No multi-file atomicity is claimed.

- [x] **Step 5: Make reciprocal warp revisioned**

For a non-active target, load a `RevisionedMapDocument`, calculate the mutation
from that exact snapshot, then save with its revision. A second-CAS conflict
must leave the external target unchanged and propagate to the existing UI
error path.

- [x] **Step 6: Run GREEN**

Run Task 2 plus the atomic-store test. Expected: all pass.

---

### Task 4: Protect active-map saves and direct tileset writes

**Files:**

- Create:
  `packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart`
- Modify:
  `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
- Modify:
  `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart`
- Modify:
  `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

- [x] **Step 1: Write notifier RED tests against real files**

Cover:

```dart
test('load records the durable revision and a normal save advances it', () {});
test('external edit after load returns conflict and preserves local dirty map',
    () {});
test('conflict does not advance savedMapSnapshot or clear undo history', () {});
test('reload after conflict adopts the external revision', () {});
test('active-layer tileset assignment uses the loaded revision', () {});
test('project replacement clears every cached map revision', () {});
test('snapshot activation without an attested revision cannot overwrite disk',
    () {});
```

- [x] **Step 2: Run RED**

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/features/editor/state/editor_notifier_map_revision_test.dart
```

Expected: the current editor performs a last-write-wins save.

- [x] **Step 3: Add revision-aware load/save methods**

`LoadMapUseCase.executeDocument` returns the migrated `MapData` plus the exact
revision when supported. `SaveMapUseCase.executeRevisioned` requires that
revision for `RevisionedMapRepository`, returns the durable new revision, and
retains the legacy path only for non-revisioned fakes.

- [x] **Step 4: Track revision attestations in `EditorNotifier`**

Maintain a private normalized-path revision cache:

- clear it on project session renewal;
- populate it only after a revisioned load is successfully adopted;
- cache read-only snapshot revisions;
- update it only after a verified save;
- remove it on delete and move it on rename;
- never infer a revision from reserialized `MapData`.

- [x] **Step 5: Fail closed on external conflict**

`saveActiveMap` catches `EditorConflictException` separately, keeps local
document/history/dirty state, returns `ActiveMapSaveOutcome.conflict`, and tells
the user to reload or resolve the external version. It must not mark the map
saved or advance the revision.

- [x] **Step 6: Make active-layer tileset assignment revisioned**

Add a revisioned execution path that returns both updated map and durable
revision. The notifier passes the active attestation and updates the cache only
after the lease is still current.

- [x] **Step 7: Run GREEN**

Run the notifier revision test plus:

```bash
flutter test --no-pub --reporter compact \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/features/editor/presentation/map_activation_guard_test.dart \
  test/editor_notifier_real_session_roundtrip_test.dart
```

Expected: revision tests and DS-02 activation regressions all pass.

---

### Task 5: Verification and DS-03 evidence

**Files:**

- Create:
  `reports/ui/world_map_editor_ds_03_atomic_revisioned_store_2026-07-28.md`

- [x] **Step 1: Format the explicit DS-03 files**

```bash
cd packages/map_editor
dart format --output=none --set-exit-if-changed <explicit DS-03 Dart files>
```

Expected: exit 0, zero changed on the final pass.

- [x] **Step 2: Run the expanded DS-00→DS-03 regression pack**

Include atomic store, lifecycle, notifier revision, activation, guard, banner,
Event navigation, top toolbar and real-session roundtrip suites. Preserve the
exact command and totals.

- [x] **Step 3: Run package analysis**

```bash
cd packages/map_editor
flutter analyze --no-pub
```

Expected: exit 0, no issues.

- [x] **Step 4: Build macOS release**

```bash
cd packages/map_editor
flutter build macos --release --no-pub
```

Expected: exit 0; record third-party warnings without attributing them to
DS-03.

- [x] **Step 5: Check the diff**

```bash
git diff --check -- <tracked DS-03 files>
git status --short --untracked-files=all
```

Expected: clean DS-03 diff check; preserve and disclose all unrelated dirty
entries.

- [x] **Step 6: Write the evidence report**

Read `codex_rule.md` before writing. Include:

- initial audit and DS-03 contract;
- five named passes/verdicts;
- exact created/modified file inventory;
- full content of every created file except the report itself;
- exact diff hunks/zones;
- RED/GREEN commands and results;
- initial/final Git status;
- self-critique, risks and explicit DS-04/DS-05 deferrals.

- [x] **Step 7: Final self-review**

Check every DS-03 requirement line-by-line. Do not mark Gate 0 `DONE`: DS-04
and DS-05 remain open even if DS-03 passes.
````

### A.2 — `packages/map_editor/lib/src/domain/models/map_document_persistence.dart`

````dart
import 'package:map_core/map_core.dart';

/// The disk state that must still be true when a map write commits.
///
/// This is deliberately byte-revision based: rebuilding an equivalent
/// [MapData] object must never manufacture permission to overwrite bytes that
/// were loaded by another process.
sealed class MapDocumentWritePrecondition {
  const MapDocumentWritePrecondition();

  const factory MapDocumentWritePrecondition.absent() = MapDocumentMustBeAbsent;

  factory MapDocumentWritePrecondition.revision(String revision) =
      MapDocumentMustMatchRevision;
}

final class MapDocumentMustBeAbsent extends MapDocumentWritePrecondition {
  const MapDocumentMustBeAbsent();
}

final class MapDocumentMustMatchRevision extends MapDocumentWritePrecondition {
  MapDocumentMustMatchRevision(String revision)
      : revision = requireMapDocumentRevision(revision);

  final String revision;
}

/// A validated map paired with the SHA-256 fingerprint of its exact disk bytes.
final class RevisionedMapDocument {
  RevisionedMapDocument({
    required this.map,
    required String revision,
  }) : revision = requireMapDocumentRevision(revision);

  final MapData map;
  final String revision;
}

enum MapDocumentRecoveryStatus {
  clear,
  discardedIncompleteWrite,
  completedInterruptedWrite,
  cleanedCommittedWrite,
}

/// Product-facing result of inspecting and resolving one interrupted write.
final class MapDocumentRecoveryResult {
  MapDocumentRecoveryResult({
    required this.status,
    required this.targetPath,
    String? revision,
  }) : revision =
            revision == null ? null : requireMapDocumentRevision(revision);

  final MapDocumentRecoveryStatus status;
  final String targetPath;
  final String? revision;
}

String requireMapDocumentRevision(String revision) {
  final normalized = revision.trim();
  if (!_mapDocumentRevisionPattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      revision,
      'revision',
      'must be a lowercase SHA-256 byte fingerprint',
    );
  }
  return normalized;
}

final RegExp _mapDocumentRevisionPattern = RegExp(
  r'^sha256:[0-9a-f]{64}$',
);
````

### A.3 — `packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart`

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';

final _mapDocumentWriteQueues = <String, Future<void>>{};

/// Serializes writers by canonical target both in-process and across processes.
///
/// The lock file lives outside the project so locking never creates authoring
/// artifacts that could be mistaken for project content.
Future<T> withMapDocumentWriteLock<T>(
  String mapPath,
  Future<T> Function(String canonicalMapPath) action,
) async {
  final canonicalMapPath = await canonicalMapDocumentPath(mapPath);
  final previous =
      _mapDocumentWriteQueues[canonicalMapPath] ?? Future<void>.value();
  final turn = Completer<void>();
  final tail = previous.then((_) => turn.future);
  _mapDocumentWriteQueues[canonicalMapPath] = tail;
  await previous;

  RandomAccessFile? handle;
  var locked = false;
  try {
    final pathHash = narrativeEventBytesFingerprint(
      utf8.encode(canonicalMapPath),
    ).substring(7, 31);
    final lockDirectory = Directory(
      p.join(Directory.systemTemp.path, 'pokemap-map-document-locks'),
    );
    await lockDirectory.create(recursive: true);
    final lockFile = File(p.join(lockDirectory.path, '$pathHash.lock'));
    handle = await lockFile.open(mode: FileMode.append);
    await handle.lock(FileLock.exclusive);
    locked = true;
    return await action(canonicalMapPath);
  } finally {
    if (handle != null) {
      if (locked) await handle.unlock();
      await handle.close();
    }
    turn.complete();
    if (identical(_mapDocumentWriteQueues[canonicalMapPath], tail)) {
      _mapDocumentWriteQueues.remove(canonicalMapPath);
    }
  }
}

Future<String> canonicalMapDocumentPath(String mapPath) async {
  final requested = File(p.normalize(p.absolute(mapPath)));
  // Following a symlink here would move the CAS boundary away from the path
  // the project manifest authorized.
  final requestedType = await FileSystemEntity.type(
    requested.path,
    followLinks: false,
  );
  if (requestedType == FileSystemEntityType.link) {
    throw EditorValidationException(
      'A map document cannot be persisted through a symbolic link: '
      '${requested.path}',
    );
  }
  if (requestedType == FileSystemEntityType.directory) {
    throw EditorValidationException(
      'A map document path resolves to a directory: ${requested.path}',
    );
  }

  if (requestedType == FileSystemEntityType.file) {
    return p.normalize(await requested.resolveSymbolicLinks());
  }

  await requested.parent.create(recursive: true);
  final canonicalParent = p.normalize(
    await requested.parent.resolveSymbolicLinks(),
  );
  return p.normalize(p.join(canonicalParent, p.basename(requested.path)));
}
````

### A.4 — `packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart`

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../domain/models/map_document_persistence.dart';
import 'map_document_write_lock.dart';

enum AtomicMapDocumentWriteCheckpoint {
  afterInitialRead,
  afterTempFlushed,
  afterJournalPrepared,
  beforeSecondCompareAndSwap,
  afterMapRenamed,
  beforeCommitVerification,
}

final class AtomicMapDocumentWriteContext {
  const AtomicMapDocumentWriteContext({
    required this.targetPath,
    required this.tempPath,
    required this.journalPath,
    required this.beforeRevision,
    required this.expectedAfterRevision,
  });

  final String targetPath;
  final String tempPath;
  final String journalPath;
  final String? beforeRevision;
  final String expectedAfterRevision;
}

typedef AtomicMapDocumentFaultInjector = FutureOr<void> Function(
  AtomicMapDocumentWriteCheckpoint checkpoint,
  AtomicMapDocumentWriteContext context,
);

/// Fault-injection sentinel that models process termination.
///
/// Unlike ordinary injected failures, this deliberately leaves durable
/// artifacts in place so a subsequent repository instance exercises recovery.
final class AtomicMapDocumentSimulatedCrash implements Exception {
  const AtomicMapDocumentSimulatedCrash();
}

final class AtomicMapDocumentBytes {
  AtomicMapDocumentBytes({
    required List<int> bytes,
    required String revision,
  })  : bytes = List<int>.unmodifiable(bytes),
        revision = requireMapDocumentRevision(revision);

  final List<int> bytes;
  final String revision;
}

/// Single-map byte store with a recoverable prepared-write protocol.
///
/// The journal and flushed payload are siblings of the final map so the final
/// rename stays on one filesystem. Multi-file map + manifest atomicity is
/// intentionally outside this DS-03 boundary and belongs to DS-05.
final class AtomicMapDocumentPersistence {
  const AtomicMapDocumentPersistence({this.faultInjector});

  final AtomicMapDocumentFaultInjector? faultInjector;

  Future<AtomicMapDocumentBytes> read(String targetPath) {
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      return _readRequired(canonicalTargetPath);
    });
  }

  Future<String> replaceLatest(
    String targetPath,
    List<int> bytes,
  ) {
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      final currentRevision = await _currentRevision(canonicalTargetPath);
      final precondition = currentRevision == null
          ? const MapDocumentWritePrecondition.absent()
          : MapDocumentWritePrecondition.revision(currentRevision);
      return _writeLocked(
        canonicalTargetPath,
        bytes,
        precondition,
      );
    });
  }

  Future<String> write(
    String targetPath,
    List<int> bytes, {
    required MapDocumentWritePrecondition precondition,
  }) {
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      return _writeLocked(canonicalTargetPath, bytes, precondition);
    });
  }

  Future<void> deleteLatest(String targetPath) {
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      final file = File(canonicalTargetPath);
      if (await file.exists()) {
        await file.delete();
      }
    });
  }

  Future<void> delete(
    String targetPath, {
    required String expectedRevision,
  }) {
    final normalizedRevision = requireMapDocumentRevision(expectedRevision);
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      final currentRevision = await _currentRevision(canonicalTargetPath);
      if (currentRevision != normalizedRevision) {
        throw const EditorConflictException(
          'The map changed outside the editor before deletion.',
        );
      }
      final file = File(canonicalTargetPath);
      if (!await file.exists()) {
        throw const EditorConflictException(
          'The map disappeared before deletion.',
        );
      }
      await file.delete();
      if (await file.exists()) {
        throw const EditorPersistenceException(
          'The map remained visible after deletion.',
        );
      }
    });
  }

  Future<MapDocumentRecoveryResult> recover(String targetPath) {
    return withMapDocumentWriteLock(
      targetPath,
      _recoverLocked,
    );
  }

  Future<String> _writeLocked(
    String canonicalTargetPath,
    List<int> bytes,
    MapDocumentWritePrecondition precondition,
  ) async {
    final afterBytes = List<int>.unmodifiable(bytes);
    final afterRevision = narrativeEventBytesFingerprint(afterBytes);
    final paths = _artifactPaths(canonicalTargetPath);
    final beforeRevision = await _currentRevision(canonicalTargetPath);
    final context = AtomicMapDocumentWriteContext(
      targetPath: canonicalTargetPath,
      tempPath: paths.tempPath,
      journalPath: paths.journalPath,
      beforeRevision: beforeRevision,
      expectedAfterRevision: afterRevision,
    );
    await _checkpoint(
      AtomicMapDocumentWriteCheckpoint.afterInitialRead,
      context,
    );
    _requirePrecondition(precondition, beforeRevision);

    final tempFile = File(paths.tempPath);
    var renameVisible = false;
    try {
      await _writeFlushed(tempFile, afterBytes);
      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.afterTempFlushed,
        context,
      );
      final tempRevision = narrativeEventBytesFingerprint(
        await tempFile.readAsBytes(),
      );
      if (tempRevision != afterRevision) {
        throw const EditorPersistenceException(
          'The flushed temporary map does not match the requested bytes.',
        );
      }

      final journal = _MapDocumentWriteJournal(
        targetPath: canonicalTargetPath,
        tempPath: paths.tempPath,
        expectedRevision: switch (precondition) {
          MapDocumentMustBeAbsent() => null,
          MapDocumentMustMatchRevision(:final revision) => revision,
        },
        expectAbsent: precondition is MapDocumentMustBeAbsent,
        afterRevision: afterRevision,
      );
      await _writeJournal(paths, journal);
      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.afterJournalPrepared,
        context,
      );

      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.beforeSecondCompareAndSwap,
        context,
      );
      // Recheck immediately before rename. Cooperative writers are also held
      // by the shared OS lock; this second CAS catches non-cooperative changes
      // observed after the initial snapshot.
      _requirePrecondition(
        precondition,
        await _currentRevision(canonicalTargetPath),
      );

      await tempFile.rename(canonicalTargetPath);
      // From this point an exception is not automatically a failed save: the
      // new bytes may already be the visible committed document.
      renameVisible = true;
      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.afterMapRenamed,
        context,
      );
      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.beforeCommitVerification,
        context,
      );
      final committedRevision = await _currentRevision(canonicalTargetPath);
      if (committedRevision != afterRevision) {
        throw const EditorPersistenceException(
          'The committed map revision cannot be verified.',
        );
      }
      await _cleanup(paths);
      return afterRevision;
    } on AtomicMapDocumentSimulatedCrash {
      rethrow;
    } on EditorConflictException {
      if (!renameVisible) await _cleanup(paths);
      rethrow;
    } on Object catch (error) {
      if (!renameVisible) {
        await _cleanup(paths);
        if (error is EditorPersistenceException) rethrow;
        throw EditorPersistenceException(
          'The map was not replaced atomically: $error',
        );
      }
      try {
        final committedRevision = await _currentRevision(canonicalTargetPath);
        if (committedRevision == afterRevision) {
          await _cleanup(paths);
          return afterRevision;
        }
      } on Object {
        // The journal remains the recovery evidence for an ambiguous commit.
      }
      throw EditorPersistenceException(
        'The map replacement is ambiguous and requires recovery: $error',
      );
    }
  }

  Future<MapDocumentRecoveryResult> _recoverLocked(
    String canonicalTargetPath,
  ) async {
    final paths = _artifactPaths(canonicalTargetPath);
    await _requireSafeArtifactType(paths.tempPath);
    await _requireSafeArtifactType(paths.journalPath);
    await _requireSafeArtifactType(paths.journalRewritePath);

    final journalFile = File(paths.journalPath);
    final tempFile = File(paths.tempPath);
    final rewriteFile = File(paths.journalRewritePath);
    final journalExists = await journalFile.exists();
    if (!journalExists) {
      // A payload without its flushed intent is never safe to promote.
      final discarded = await tempFile.exists() || await rewriteFile.exists();
      await _deleteIfExists(tempFile);
      await _deleteIfExists(rewriteFile);
      return MapDocumentRecoveryResult(
        status: discarded
            ? MapDocumentRecoveryStatus.discardedIncompleteWrite
            : MapDocumentRecoveryStatus.clear,
        targetPath: canonicalTargetPath,
        revision: await _currentRevision(canonicalTargetPath),
      );
    }

    late final _MapDocumentWriteJournal journal;
    try {
      journal = _MapDocumentWriteJournal.fromJson(
        jsonDecode(await journalFile.readAsString()),
      );
      journal.requireMatches(
        targetPath: canonicalTargetPath,
        tempPath: paths.tempPath,
      );
    } on Object catch (error) {
      throw EditorConflictException(
        'Map recovery is blocked by an invalid write journal: $error',
      );
    }
    await _deleteIfExists(rewriteFile);

    final currentRevision = await _currentRevision(canonicalTargetPath);
    if (currentRevision == journal.afterRevision) {
      // The rename committed before interruption; recovery only removes the
      // stable evidence files and never rewrites the final map.
      await _cleanup(paths);
      return MapDocumentRecoveryResult(
        status: MapDocumentRecoveryStatus.cleanedCommittedWrite,
        targetPath: canonicalTargetPath,
        revision: currentRevision,
      );
    }

    if (!await tempFile.exists()) {
      if (journal.matchesBefore(currentRevision)) {
        await _cleanup(paths);
        return MapDocumentRecoveryResult(
          status: MapDocumentRecoveryStatus.discardedIncompleteWrite,
          targetPath: canonicalTargetPath,
          revision: currentRevision,
        );
      }
      throw const EditorConflictException(
        'Map recovery is blocked because the target changed and the prepared '
        'temporary map is missing.',
      );
    }

    final tempRevision = narrativeEventBytesFingerprint(
      await tempFile.readAsBytes(),
    );
    if (tempRevision != journal.afterRevision) {
      throw const EditorConflictException(
        'Map recovery is blocked because the prepared temporary map is '
        'corrupted.',
      );
    }
    if (!journal.matchesBefore(currentRevision)) {
      throw const EditorConflictException(
        'Map recovery is blocked because the target changed after the '
        'interrupted write.',
      );
    }

    await tempFile.rename(canonicalTargetPath);
    final recoveredRevision = await _currentRevision(canonicalTargetPath);
    if (recoveredRevision != journal.afterRevision) {
      throw const EditorConflictException(
        'Map recovery renamed the temporary file but could not verify it.',
      );
    }
    await _cleanup(paths);
    return MapDocumentRecoveryResult(
      status: MapDocumentRecoveryStatus.completedInterruptedWrite,
      targetPath: canonicalTargetPath,
      revision: recoveredRevision,
    );
  }

  Future<void> _checkpoint(
    AtomicMapDocumentWriteCheckpoint checkpoint,
    AtomicMapDocumentWriteContext context,
  ) async {
    await faultInjector?.call(checkpoint, context);
  }
}

final class _MapDocumentWriteJournal {
  const _MapDocumentWriteJournal({
    this.schemaVersion = 1,
    required this.targetPath,
    required this.tempPath,
    required this.expectedRevision,
    required this.expectAbsent,
    required this.afterRevision,
  });

  factory _MapDocumentWriteJournal.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Map write journal must be an object.');
    }
    final json = <String, Object?>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
    if (json.length != value.length) {
      throw const FormatException('Map write journal keys must be strings.');
    }
    final schemaVersion = json['schemaVersion'];
    final targetPath = json['targetPath'];
    final tempPath = json['tempPath'];
    final expectedRevision = json['expectedRevision'];
    final expectAbsent = json['expectAbsent'];
    final afterRevision = json['afterRevision'];
    if (schemaVersion != 1 ||
        targetPath is! String ||
        tempPath is! String ||
        expectAbsent is! bool ||
        afterRevision is! String ||
        (expectedRevision != null && expectedRevision is! String)) {
      throw const FormatException('Map write journal fields are invalid.');
    }
    return _MapDocumentWriteJournal(
      schemaVersion: schemaVersion as int,
      targetPath: targetPath,
      tempPath: tempPath,
      expectedRevision: expectedRevision as String?,
      expectAbsent: expectAbsent,
      afterRevision: requireMapDocumentRevision(afterRevision),
    );
  }

  final int schemaVersion;
  final String targetPath;
  final String tempPath;
  final String? expectedRevision;
  final bool expectAbsent;
  final String afterRevision;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'targetPath': targetPath,
        'tempPath': tempPath,
        'expectedRevision': expectedRevision,
        'expectAbsent': expectAbsent,
        'afterRevision': afterRevision,
      };

  void requireMatches({
    required String targetPath,
    required String tempPath,
  }) {
    if (p.normalize(this.targetPath) != p.normalize(targetPath) ||
        p.normalize(this.tempPath) != p.normalize(tempPath) ||
        expectAbsent == (expectedRevision != null)) {
      throw const FormatException(
        'Map write journal does not match its target artifacts.',
      );
    }
    if (expectedRevision != null) {
      requireMapDocumentRevision(expectedRevision!);
    }
  }

  bool matchesBefore(String? currentRevision) {
    if (expectAbsent) return currentRevision == null;
    return currentRevision == expectedRevision;
  }
}

typedef _MapDocumentArtifactPaths = ({
  String tempPath,
  String journalPath,
  String journalRewritePath,
});

_MapDocumentArtifactPaths _artifactPaths(String canonicalTargetPath) {
  final identity = narrativeEventBytesFingerprint(
    utf8.encode(p.normalize(canonicalTargetPath)),
  ).substring(7, 31);
  final prefix = p.join(
    p.dirname(canonicalTargetPath),
    '.pokemap-map-$identity',
  );
  return (
    tempPath: '$prefix.after.tmp',
    journalPath: '$prefix.journal.json',
    journalRewritePath: '$prefix.journal.rewrite.tmp',
  );
}

Future<void> _writeJournal(
  _MapDocumentArtifactPaths paths,
  _MapDocumentWriteJournal journal,
) async {
  final bytes = utf8.encode(
    const JsonEncoder.withIndent('  ').convert(journal.toJson()),
  );
  final rewrite = File(paths.journalRewritePath);
  await _writeFlushed(rewrite, bytes);
  await rewrite.rename(paths.journalPath);
}

Future<void> _writeFlushed(File file, List<int> bytes) async {
  await file.parent.create(recursive: true);
  final handle = await file.open(mode: FileMode.write);
  try {
    await handle.writeFrom(bytes);
    await handle.flush();
  } finally {
    await handle.close();
  }
}

Future<AtomicMapDocumentBytes> _readRequired(String targetPath) async {
  final file = File(targetPath);
  if (!await file.exists()) {
    throw EditorNotFoundException('Map file not found: $targetPath');
  }
  final bytes = await file.readAsBytes();
  return AtomicMapDocumentBytes(
    bytes: bytes,
    revision: narrativeEventBytesFingerprint(bytes),
  );
}

Future<String?> _currentRevision(String targetPath) async {
  final type = await FileSystemEntity.type(targetPath, followLinks: false);
  if (type == FileSystemEntityType.notFound) return null;
  if (type != FileSystemEntityType.file) {
    throw EditorConflictException(
      'The map target is no longer a regular file: $targetPath',
    );
  }
  return narrativeEventBytesFingerprint(
    await File(targetPath).readAsBytes(),
  );
}

void _requirePrecondition(
  MapDocumentWritePrecondition precondition,
  String? currentRevision,
) {
  switch (precondition) {
    case MapDocumentMustBeAbsent():
      if (currentRevision != null) {
        throw const EditorConflictException(
          'A map already exists at the requested path.',
        );
      }
    case MapDocumentMustMatchRevision(:final revision):
      if (currentRevision != revision) {
        throw const EditorConflictException(
          'The map changed outside the editor.',
        );
      }
  }
}

Future<void> _requireSafeArtifactType(String path) async {
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.notFound ||
      type == FileSystemEntityType.file) {
    return;
  }
  throw EditorConflictException(
    'Map recovery artifact is not a regular file: $path',
  );
}

Future<void> _cleanup(_MapDocumentArtifactPaths paths) async {
  await _deleteIfExists(File(paths.tempPath));
  await _deleteIfExists(File(paths.journalRewritePath));
  await _deleteIfExists(File(paths.journalPath));
}

Future<void> _deleteIfExists(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // Cleanup remains retryable because target-addressed artifacts are stable.
  }
}
````

### A.5 — `packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart`

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/atomic_map_document_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AtomicMapDocumentPersistence', () {
    test('rejects malformed revisions before filesystem I/O', () {
      expect(
        () => MapDocumentWritePrecondition.revision(''),
        throwsArgumentError,
      );
      expect(
        () => MapDocumentWritePrecondition.revision('sha256:not-a-hash'),
        throwsArgumentError,
      );
    });

    test('returns the SHA-256 revision of the exact durable map bytes',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);

      final saved = await fixture.repository.saveMapDocument(
        _map(name: 'Initial'),
        fixture.mapPath,
        precondition: const MapDocumentWritePrecondition.absent(),
      );

      expect(
        saved.revision,
        narrativeEventBytesFingerprint(
          await File(fixture.mapPath).readAsBytes(),
        ),
      );
      final loaded = await fixture.repository.loadMapDocument(fixture.mapPath);
      expect(loaded.map, saved.map);
      expect(loaded.revision, saved.revision);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('expected absence refuses to replace an existing map', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.saveMapDocument(
          _map(name: 'Unexpected replacement'),
          fixture.mapPath,
          precondition: const MapDocumentWritePrecondition.absent(),
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('rejects a stale revision without changing external bytes', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      await fixture.writeMap(_map(name: 'External'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.saveMapDocument(
          _map(name: 'Local'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('revision-checked delete preserves an externally changed map',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      await fixture.writeMap(_map(name: 'External before delete'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.deleteMapDocument(
          fixture.mapPath,
          expectedRevision: baseline.revision,
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
    });

    test('rejects a map target that is a symbolic link', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final realPath = p.join(fixture.root.path, 'real-map.json');
      await fixture.repository.saveMap(
        _map(name: 'Real target'),
        realPath,
      );
      final originalBytes = await File(realPath).readAsBytes();
      await Directory(p.dirname(fixture.mapPath)).create(recursive: true);
      await Link(fixture.mapPath).create(realPath);

      await expectLater(
        fixture.repository.saveMapDocument(
          _map(name: 'Must not follow link'),
          fixture.mapPath,
          precondition: const MapDocumentWritePrecondition.absent(),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(await File(realPath).readAsBytes(), originalBytes);
    });

    test('flushes and verifies a sibling temp before target replacement',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();
      String? tempPath;
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, context) async {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterTempFlushed) {
              tempPath = context.tempPath;
              expect(
                p.normalize(p.dirname(context.tempPath)),
                p.normalize(p.dirname(context.targetPath)),
              );
              expect(await File(context.tempPath).exists(), isTrue);
              expect(await File(context.targetPath).readAsBytes(), beforeBytes);
              expect(
                narrativeEventBytesFingerprint(
                  await File(context.tempPath).readAsBytes(),
                ),
                context.expectedAfterRevision,
              );
            }
          },
        ),
      );

      await repository.saveMapDocument(
        _map(name: 'Updated'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );

      expect(tempPath, isNotNull);
      expect(await File(tempPath!).exists(), isFalse);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('second CAS preserves an external write made before rename', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      List<int>? externalBytes;
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) async {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.beforeSecondCompareAndSwap) {
              await fixture.writeMap(_map(name: 'External during save'));
              externalBytes = await File(fixture.mapPath).readAsBytes();
            }
          },
        ),
      );

      await expectLater(
        repository.saveMapDocument(
          _map(name: 'Local'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(externalBytes, isNotNull);
      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('corrupted flushed temp is rejected without touching the target',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, context) async {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterTempFlushed) {
              await File(context.tempPath).writeAsString(
                '{"corrupted":true}',
                flush: true,
              );
            }
          },
        ),
      );

      await expectLater(
        repository.saveMapDocument(
          _map(name: 'Updated'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<EditorPersistenceException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('failure before rename leaves original bytes visible', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterJournalPrepared) {
              throw const FileSystemException('Injected pre-rename failure');
            }
          },
        ),
      );

      await expectLater(
        repository.saveMapDocument(
          _map(name: 'Updated'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<EditorPersistenceException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('post-rename callback failure is verified as committed', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterMapRenamed) {
              throw const FileSystemException('Injected post-rename failure');
            }
          },
        ),
      );

      final saved = await repository.saveMapDocument(
        _map(name: 'Committed'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );

      expect(
        (await repository.loadMapDocument(fixture.mapPath)).map.name,
        'Committed',
      );
      expect(
        saved.revision,
        narrativeEventBytesFingerprint(
          await File(fixture.mapPath).readAsBytes(),
        ),
      );
      expect(await fixture.artifacts(), isEmpty);
    });

    test('pre-verification callback failure is verified as committed',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.beforeCommitVerification) {
              throw const FileSystemException(
                'Injected commit-verification failure',
              );
            }
          },
        ),
      );

      final saved = await repository.saveMapDocument(
        _map(name: 'Committed before verification'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );

      expect(
        (await repository.loadMapDocument(fixture.mapPath)).map.name,
        'Committed before verification',
      );
      expect(
        saved.revision,
        narrativeEventBytesFingerprint(
          await File(fixture.mapPath).readAsBytes(),
        ),
      );
      expect(await fixture.artifacts(), isEmpty);
    });

    test('prepared crash is completed when baseline still matches', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final crashingRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterJournalPrepared) {
              throw const AtomicMapDocumentSimulatedCrash();
            }
          },
        ),
      );

      await expectLater(
        crashingRepository.saveMapDocument(
          _map(name: 'Recovered'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );
      expect(
        (await fixture.repository.loadMapDocument(fixture.mapPath)).map.name,
        'Recovered',
      );
      expect(await fixture.artifacts(), isEmpty);
    });

    test('post-rename crash is cleaned without rewriting the committed target',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final crashingRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterMapRenamed) {
              throw const AtomicMapDocumentSimulatedCrash();
            }
          },
        ),
      );

      await expectLater(
        crashingRepository.saveMapDocument(
          _map(name: 'Committed before crash'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );
      final committedBytes = await File(fixture.mapPath).readAsBytes();

      final recovery =
          await fixture.repository.recoverMapDocument(fixture.mapPath);

      expect(
        recovery.status,
        MapDocumentRecoveryStatus.cleanedCommittedWrite,
      );
      expect(await File(fixture.mapPath).readAsBytes(), committedBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('recovery blocks when target diverged from before and after',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final crashingRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterJournalPrepared) {
              throw const AtomicMapDocumentSimulatedCrash();
            }
          },
        ),
      );
      await expectLater(
        crashingRepository.saveMapDocument(
          _map(name: 'Interrupted local'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );
      await fixture.writeMap(_map(name: 'External after crash'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.recoverMapDocument(fixture.mapPath),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
      expect(await fixture.artifacts(), isNotEmpty);
    });

    test('orphan temp without a journal is discarded safely', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();
      final crashingRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterTempFlushed) {
              throw const AtomicMapDocumentSimulatedCrash();
            }
          },
        ),
      );
      await expectLater(
        crashingRepository.saveMapDocument(
          _map(name: 'Never prepared'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );

      final recovery =
          await fixture.repository.recoverMapDocument(fixture.mapPath);

      expect(
        recovery.status,
        MapDocumentRecoveryStatus.discardedIncompleteWrite,
      );
      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('concurrent writers serialize through the same OS lock', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final firstEntered = Completer<void>();
      final releaseFirst = Completer<void>();
      final secondEntered = Completer<void>();
      final firstRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) async {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterInitialRead) {
              firstEntered.complete();
              await releaseFirst.future;
            }
          },
        ),
      );
      final secondRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterInitialRead) {
              secondEntered.complete();
            }
          },
        ),
      );

      final first = firstRepository.saveMapDocument(
        _map(name: 'First'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );
      await firstEntered.future;
      final second = secondRepository.saveMapDocument(
        _map(name: 'Second'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );
      final secondExpectation = expectLater(
        second,
        throwsA(isA<EditorConflictException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(secondEntered.isCompleted, isFalse);
      releaseFirst.complete();
      await first;
      await secondExpectation;
      expect(secondEntered.isCompleted, isTrue);
      expect(
        (await fixture.repository.loadMapDocument(fixture.mapPath)).map.name,
        'First',
      );
    });
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.mapPath,
    required this.repository,
  });

  static Future<_Fixture> create() async {
    final root =
        await Directory.systemTemp.createTemp('pokemap_atomic_map_document_');
    return _Fixture(
      root: root,
      mapPath: p.join(root.path, 'maps', 'alpha.json'),
      repository: FileMapRepository(),
    );
  }

  static Future<_Fixture> createWithBaseline() async {
    final fixture = await create();
    await fixture.repository.saveMapDocument(
      _map(name: 'Baseline'),
      fixture.mapPath,
      precondition: const MapDocumentWritePrecondition.absent(),
    );
    return fixture;
  }

  final Directory root;
  final String mapPath;
  final FileMapRepository repository;

  Future<void> writeMap(MapData map) async {
    final file = File(mapPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
      flush: true,
    );
  }

  Future<List<FileSystemEntity>> artifacts() async {
    final directory = Directory(p.dirname(mapPath));
    if (!await directory.exists()) return const [];
    return directory
        .list(followLinks: false)
        .where(
          (entry) => p.basename(entry.path).startsWith('.pokemap-map-'),
        )
        .toList();
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

MapData _map({required String name}) => MapData(
      id: 'alpha',
      name: name,
      size: const GridSize(width: 1, height: 1),
      layers: const <MapLayer>[
        TileLayer(
          id: 'base',
          name: 'Base',
          tiles: <int>[0],
        ),
        TerrainLayer(
          id: 'terrain',
          name: 'Terrain',
          terrains: <TerrainType>[TerrainType.none],
        ),
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[false],
        ),
      ],
    );
````

### A.6 — `packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart`

````dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/application/use_cases/warp_use_cases.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('revisioned map lifecycle', () {
    test('Create uses expected absence instead of a legacy overwrite',
        () async {
      final fixture = _Fixture();

      await CreateMapUseCase(fixture.maps, fixture.projects).execute(
        fixture.workspace,
        fixture.project(),
        'alpha',
        2,
        2,
      );

      expect(fixture.maps.legacySaves, isEmpty);
      expect(fixture.maps.revisionedSaves, hasLength(1));
      expect(
        fixture.maps.revisionedSaves.single.precondition,
        isA<MapDocumentMustBeAbsent>(),
      );
      expect(
          fixture.maps.revisionedSaves.single.path, '/project/maps/alpha.json');
    });

    test('Duplicate uses expected absence for its target', () async {
      final fixture = _Fixture();
      fixture.maps.seed('/project/maps/alpha.json', _map('alpha'));

      await DuplicateMapUseCase(fixture.maps, fixture.projects).execute(
        fixture.workspace,
        fixture.project(entries: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
        ]),
        'alpha',
      );

      expect(fixture.maps.legacySaves, isEmpty);
      expect(fixture.maps.revisionedLoads, <String>[
        '/project/maps/alpha.json',
      ]);
      expect(fixture.maps.revisionedSaves, hasLength(1));
      expect(
        fixture.maps.revisionedSaves.single.precondition,
        isA<MapDocumentMustBeAbsent>(),
      );
      expect(
        fixture.maps.revisionedSaves.single.path,
        '/project/maps/alpha_copy.json',
      );
    });

    test('Rename revision-checks its source deletion', () async {
      final fixture = _Fixture();
      final sourceRevision =
          fixture.maps.seed('/project/maps/alpha.json', _map('alpha'));

      await RenameMapUseCase(fixture.maps, fixture.projects).execute(
        fixture.workspace,
        fixture.project(entries: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
        ]),
        'alpha',
        'beta',
      );

      expect(fixture.maps.legacyLoads, isEmpty);
      expect(fixture.maps.legacySaves, isEmpty);
      expect(fixture.maps.legacyDeletes, isEmpty);
      expect(
        fixture.maps.revisionedSaves.single.precondition,
        isA<MapDocumentMustBeAbsent>(),
      );
      expect(
        fixture.maps.revisionedDeletes.single,
        (path: '/project/maps/alpha.json', revision: sourceRevision),
      );
    });

    test('Delete refuses to use an unversioned source delete', () async {
      final fixture = _Fixture();
      final sourceRevision =
          fixture.maps.seed('/project/maps/alpha.json', _map('alpha'));

      await DeleteMapUseCase(fixture.maps, fixture.projects).execute(
        fixture.workspace,
        fixture.project(entries: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
        ]),
        'alpha',
      );

      expect(fixture.maps.legacyLoads, isEmpty);
      expect(fixture.maps.legacyDeletes, isEmpty);
      expect(
        fixture.maps.revisionedDeletes.single,
        (path: '/project/maps/alpha.json', revision: sourceRevision),
      );
    });

    test('reciprocal warp saves the exact loaded target revision', () async {
      final fixture = _Fixture();
      final targetRevision =
          fixture.maps.seed('/project/maps/beta.json', _map('beta'));
      final source = _map('alpha').copyWith(
        warps: const <MapWarp>[
          MapWarp(
            id: 'to_beta',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'beta',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      await CreateReciprocalWarpUseCase(fixture.maps).execute(
        fixture.workspace,
        fixture.project(entries: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
          ProjectMapEntry(
            id: 'beta',
            name: 'Beta',
            relativePath: 'maps/beta.json',
          ),
        ]),
        sourceMap: source,
        sourceWarp: source.warps.single,
      );

      expect(fixture.maps.legacyLoads, isEmpty);
      expect(fixture.maps.legacySaves, isEmpty);
      expect(fixture.maps.revisionedSaves, hasLength(1));
      final precondition = fixture.maps.revisionedSaves.single.precondition;
      expect(precondition, isA<MapDocumentMustMatchRevision>());
      expect(
        (precondition as MapDocumentMustMatchRevision).revision,
        targetRevision,
      );
    });
  });
}

final class _Fixture {
  final _Workspace workspace = _Workspace();
  final _RevisionedRecordingMapRepository maps =
      _RevisionedRecordingMapRepository();
  final _RecordingProjectRepository projects = _RecordingProjectRepository();

  ProjectManifest project({
    List<ProjectMapEntry> entries = const <ProjectMapEntry>[],
  }) {
    return ProjectManifest(
      name: 'DS-03',
      maps: entries,
      tilesets: const <ProjectTilesetEntry>[],
    );
  }
}

final class _RevisionedRecordingMapRepository
    implements RevisionedMapRepository {
  final Map<String, RevisionedMapDocument> documents =
      <String, RevisionedMapDocument>{};
  final List<String> legacyLoads = <String>[];
  final List<({MapData map, String path})> legacySaves =
      <({MapData map, String path})>[];
  final List<String> legacyDeletes = <String>[];
  final List<String> revisionedLoads = <String>[];
  final List<
      ({
        MapData map,
        String path,
        MapDocumentWritePrecondition precondition,
      })> revisionedSaves = [];
  final List<({String path, String revision})> revisionedDeletes = [];

  String seed(String path, MapData map) {
    final revision = _revision('$path:${map.id}:${map.name}');
    documents[path] = RevisionedMapDocument(map: map, revision: revision);
    return revision;
  }

  @override
  Future<MapData> loadMap(String path) async {
    legacyLoads.add(path);
    return documents[path]!.map;
  }

  @override
  Future<RevisionedMapDocument> loadMapDocument(String path) async {
    revisionedLoads.add(path);
    return documents[path]!;
  }

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    legacySaves.add((map: map, path: path));
  }

  @override
  Future<RevisionedMapDocument> saveMapDocument(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
    ProjectManifest? projectDialogueContext,
  }) async {
    revisionedSaves.add(
      (map: map, path: path, precondition: precondition),
    );
    final saved = RevisionedMapDocument(
      map: map,
      revision: _revision('$path:${map.id}:${map.name}:saved'),
    );
    documents[path] = saved;
    return saved;
  }

  @override
  Future<void> deleteMap(String path) async {
    legacyDeletes.add(path);
    documents.remove(path);
  }

  @override
  Future<void> deleteMapDocument(
    String path, {
    required String expectedRevision,
  }) async {
    revisionedDeletes.add((path: path, revision: expectedRevision));
    documents.remove(path);
  }

  @override
  Future<MapDocumentRecoveryResult> recoverMapDocument(String path) async {
    return MapDocumentRecoveryResult(
      status: MapDocumentRecoveryStatus.clear,
      targetPath: path,
      revision: documents[path]?.revision,
    );
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}
}

final class _RecordingProjectRepository implements ProjectRepository {
  final List<ProjectManifest> saves = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) async =>
      throw UnimplementedError();

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saves.add(project);
  }
}

final class _Workspace implements ProjectWorkspace {
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
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  Future<void> writeTextFile(String path, String contents) async {}

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      layers: const <MapLayer>[],
    );

String _revision(String seed) => narrativeEventBytesFingerprint(
      utf8.encode(seed),
    );
````

### A.7 — `packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart`

````dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('EditorNotifier map revision', () {
    test('normal saves advance the durable revision', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);

      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'First save',
        ),
      );
      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Second save',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath))
            .mapMetadata
            .displayName,
        'Second save',
      );
    });

    test('external edit conflicts and preserves local dirty history', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      final savedBefore = notifier.state.savedMapSnapshot;
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Local edit',
        ),
      );
      final localBeforeSave = notifier.state.activeMap;
      final undoBeforeSave = notifier.state.mapUndoStack;
      await fixture.writeMap(_map(name: 'External edit'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      final outcome = await notifier.saveActiveMap();

      expect(outcome, ActiveMapSaveOutcome.conflict);
      expect(notifier.state.activeMap, localBeforeSave);
      expect(notifier.state.savedMapSnapshot, savedBefore);
      expect(notifier.state.mapUndoStack, undoBeforeSave);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.errorMessage, contains('modifiée en dehors'));
      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
    });

    test('reload after conflict adopts external revision and can save again',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'First local edit',
        ),
      );
      await fixture.writeMap(_map(name: 'External edit'));
      expect(
        await notifier.saveActiveMap(),
        ActiveMapSaveOutcome.conflict,
      );

      expect(
        await notifier.activateMap(
          'maps/alpha.json',
          forceReload: true,
        ),
        MapActivationOutcome.activated,
      );
      expect(notifier.state.activeMap!.name, 'External edit');
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Edit after reload',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath))
            .mapMetadata
            .displayName,
        'Edit after reload',
      );
    });

    test('snapshot activation without an attested revision cannot overwrite',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;

      expect(
        notifier.activateNarrativeEventMapSnapshot(_map(name: 'Snapshot')),
        isTrue,
      );
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Unattested local edit',
        ),
      );
      final beforeBytes = await File(fixture.mapPath).readAsBytes();

      final outcome = await notifier.saveActiveMap();

      expect(outcome, ActiveMapSaveOutcome.conflict);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.errorMessage, contains('recharger'));
      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
    });

    test('active-layer tileset assignment uses the loaded revision', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      expect(notifier.state.activeLayerId, 'base');
      await fixture.writeMap(_map(name: 'External tileset race'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      await notifier.assignTilesetToActiveLayer('alternate');

      expect(notifier.state.errorMessage, contains('changed outside'));
      expect(notifier.state.activeMap!.layers.first, isA<TileLayer>());
      expect(
        (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
        'base_tiles',
      );
      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
    });

    test('project replacement clears cached map revisions', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      final attestedSnapshot = notifier.state.activeMap!;
      final otherRoot = Directory(p.join(fixture.root.path, 'other_project'));
      await otherRoot.create();
      final otherManifestPath = p.join(otherRoot.path, 'project.json');
      await FileProjectRepository().saveProject(
        const ProjectManifest(
          name: 'Other project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        otherManifestPath,
      );

      expect(
        await notifier.activateProject(otherManifestPath),
        MapActivationOutcome.activated,
      );
      notifier.state = EditorState(
        projectRootPath: fixture.root.path,
        project: fixture.project,
      );
      expect(
        notifier.activateNarrativeEventMapSnapshot(attestedSnapshot),
        isTrue,
      );
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Must stay local',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.conflict);
    });

    test('renaming the active map moves its durable revision', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);

      await notifier.renameMap('alpha', 'beta');
      expect(notifier.state.activeMap?.id, 'beta');
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Edited after rename',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      final renamedPath = p.join(fixture.root.path, 'maps', 'beta.json');
      expect(
        (await FileMapRepository().loadMap(renamedPath))
            .mapMetadata
            .displayName,
        'Edited after rename',
      );
    });

    test('newly created map receives a revision for its next save', () async {
      final fixture = await _Fixture.create(projectWithMap: false);
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;

      await notifier.createMap('alpha', 2, 2);
      expect(notifier.state.activeMap?.id, 'alpha');
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Created then edited',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath))
            .mapMetadata
            .displayName,
        'Created then edited',
      );
    });
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.project,
    required this.mapPath,
    required this.container,
  });

  static Future<_Fixture> create({bool projectWithMap = true}) async {
    final root =
        await Directory.systemTemp.createTemp('pokemap_map_revision_editor_');
    final mapPath = p.join(root.path, 'maps', 'alpha.json');
    final project = _project(projectWithMap: projectWithMap);
    if (projectWithMap) {
      await FileMapRepository().saveMap(
        _map(name: 'Baseline'),
        mapPath,
        projectDialogueContext: project,
      );
    }
    final container = ProviderContainer();
    final fixture = _Fixture(
      root: root,
      project: project,
      mapPath: mapPath,
      container: container,
    );
    fixture.notifier.state = EditorState(
      projectRootPath: root.path,
      project: project,
    );
    return fixture;
  }

  final Directory root;
  final ProjectManifest project;
  final String mapPath;
  final ProviderContainer container;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> load(EditorNotifier notifier) async {
    expect(
      await notifier.activateMap('maps/alpha.json'),
      MapActivationOutcome.activated,
    );
  }

  Future<void> writeMap(MapData map) {
    return FileMapRepository().saveMap(
      map,
      mapPath,
      projectDialogueContext: project,
    );
  }

  Future<void> dispose() async {
    container.dispose();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

ProjectManifest _project({required bool projectWithMap}) => ProjectManifest(
      name: 'DS-03 editor',
      maps: projectWithMap
          ? const <ProjectMapEntry>[
              ProjectMapEntry(
                id: 'alpha',
                name: 'Alpha',
                relativePath: 'maps/alpha.json',
              ),
            ]
          : const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'base_tiles',
          name: 'Base tiles',
          relativePath: 'tilesets/base.png',
          scope: TilesetScope.global,
        ),
        ProjectTilesetEntry(
          id: 'alternate',
          name: 'Alternate',
          relativePath: 'tilesets/alternate.png',
          scope: TilesetScope.global,
        ),
      ],
    );

MapData _map({required String name}) => MapData(
      id: 'alpha',
      name: name,
      size: const GridSize(width: 2, height: 2),
      tilesetId: 'base_tiles',
      layers: const <MapLayer>[
        TileLayer(
          id: 'base',
          name: 'Base',
          tilesetId: 'base_tiles',
          tiles: <int>[0, 0, 0, 0],
        ),
        TerrainLayer(
          id: 'terrain',
          name: 'Terrain',
          terrains: <TerrainType>[
            TerrainType.none,
            TerrainType.none,
            TerrainType.none,
            TerrainType.none,
          ],
        ),
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[false, false, false, false],
        ),
      ],
    );
````
