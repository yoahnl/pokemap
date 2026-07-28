# DS‑05 — Transaction lifecycle — Evidence Pack

- **Date :** 2026-07-28
- **Branche :** `main`
- **HEAD de départ :** `a3d741818c19`
- **Package principal :** `packages/map_editor`
- **Demande :** implémenter DS‑05, puis commit et push
- **Verdict du lot :** **proposé DONE**
- **Gate 0 globale :** **PARTIAL** — DS‑06 (Resize impact plan) reste à traiter

## 1. Résumé exécutif

DS‑05 remplace les compensations best-effort du chemin produit par un protocole
de lifecycle durable pour les quatre mutations de carte :

- create ;
- duplicate ;
- rename ;
- delete.

Le protocole écrit d’abord une intention complète et vérifiable dans
`.pokemap/recovery/world-map-lifecycle.json`, puis fait progresser séparément
la cible map, `project.json` et l’éventuelle suppression source. Chaque
document conserve sa propre atomicité mono-fichier ; le journal rend la
séquence **récupérable**, jamais « atomique multi-fichier ».

À chaque reprise, le coordinateur relit les octets durables et accepte
uniquement les états `before` ou `after` attestés. Toute divergence de
manifeste, de révision source ou de cible indépendante bloque la récupération
et conserve le journal pour diagnostic.

Le chemin produit Riverpod injecte ce coordinateur dans Create, Duplicate,
Rename et Delete. L’ouverture et la sauvegarde générique d’un projet passent
aussi par une barrière de récupération. Une sauvegarde générique capturée avant
la reprise est rejetée si la reprise a changé la révision exacte du manifeste :
elle ne peut donc pas écraser le delta lifecycle fraîchement commité.

## 2. Audit initial et critères DS‑05

Sources de cadrage :

- `reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md` ;
- `reports/ui/world_map_editor_ds_03_atomic_revisioned_store_2026-07-28.md` ;
- `reports/ui/world_map_editor_ds_04_dependency_preflight_2026-07-28.md` ;
- `codex_rule.md` ;
- `AGENTS.md`.

Critères explicites du lot :

1. journaliser create/duplicate/rename/delete ;
2. reprendre déterministiquement après crash ;
3. revalider préconditions et révisions au commit ;
4. ne jamais masquer la réalité multi-fichier derrière un faux label
   « atomique ».

Constat avant DS‑05 :

- DS‑03 sécurisait chaque map individuellement par temp + flush + hash + CAS ;
- DS‑04 empêchait rename/delete si des dépendances entrantes étaient présentes ;
- les use cases lifecycle conservaient encore une compensation mémoire
  best-effort entre map et manifeste ;
- aucune preuve durable ne permettait de conclure proprement une interruption
  entre ces deux fichiers.

## 3. Architecture retenue

### 3.1 Séquence durable

```text
lock lifecycle projet
  -> récupérer tout journal antérieur
  -> relire project.json et attester sa révision exacte
  -> revalider la source map
  -> écrire le journal prepared (flush + hash + rename)
  -> garantir la cible map (absence CAS ou contenu identique)
  -> écrire project.json avec expectedRevision exacte
  -> supprimer la source avec expectedRevision exacte si rename/delete
  -> écrire le statut committed
  -> effacer le journal
```

Le statut journalisé aide l’observabilité mais n’est jamais l’autorité unique :
la reprise redérive la situation depuis le manifeste, la source et la cible.

### 3.2 États de reprise

| État durable observé | Décision |
|---|---|
| aucun journal | accès normal |
| manifeste `before`, révision exacte, source exacte | roll-forward |
| manifeste `after`, cible exacte | terminer suppression/cleanup |
| cible absente mais payload journalisé et manifeste `after` | recréer la cible de façon absence-only |
| cible indépendante | blocage, preuve conservée |
| source changée avant suppression | blocage, preuve conservée |
| manifeste ni `before` ni `after` | blocage, preuve conservée |
| journal invalide/inconnu | blocage, preuve conservée |
| journal `committed` restant après crash | cleanup idempotent |

### 3.3 Frontières

- modèles et orchestration : couche application `map_editor` ;
- I/O, lock OS, journal et adaptateurs CAS : infrastructure `map_editor` ;
- aucun ajout Flutter/Flame dans les contrats purs concernés ;
- aucune nouvelle primitive UI locale ;
- aucune couleur hardcodée ;
- aucun changement de schéma `map_core`.

## 4. Décisions et non-objectifs

Décisions :

- intention roll-forward, pas rollback deviné ;
- journal contenant le snapshot cible complet et ses empreintes ;
- transaction ID déterministe dérivé de l’intention ;
- validation stricte du delta : seule la liste `maps` peut changer ;
- create/duplicate ajoutent exactement une entrée ;
- rename remplace exactement l’entrée source ;
- delete retire exactement l’entrée source ;
- chemins limités lexicalement à `maps/*.json` et documents non réguliers
  refusés par la passerelle ;
- journal et lock symlink/non-fichier refusés ;
- compatibilité conservée pour les anciens fakes non révisionnés, mais ce
  fallback est explicitement décrit comme non récupérable.

Non-objectifs :

- pas de transaction filesystem multi-fichier prétendument atomique ;
- pas de redesign visuel ;
- pas de resize impact plan (DS‑06) ;
- pas de modification des formats projet/map ;
- pas de nettoyage des modifications concurrentes hors World Map.

## 5. Inventaire DS‑05

### 5.1 Fichiers créés

| Fichier | Rôle |
|---|---|
| `packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart` | intention durable, validation, coordinateur, récupération |
| `packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart` | queue, lock OS, journal flush/hash/rename et adaptateurs CAS |
| `packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart` | state machine, crashs, divergences et validation |
| `packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart` | vraies écritures, restart, invalidité, symlink et barrière générique |
| `packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart` | Create/Duplicate/Rename/Delete réels via coordinateur |
| `packages/map_editor/test/app/providers/map_lifecycle_provider_wiring_test.dart` | preuve du chemin produit Riverpod |
| `reports/ui/world_map_editor_ds_05_transaction_lifecycle_2026-07-28.md` | présent Evidence Pack ; contenu non reproduit récursivement |

Métadonnées fraîches :

```text
    1020 packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart
     315 packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart
     548 packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart
     348 packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart
     244 packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart
      73 packages/map_editor/test/app/providers/map_lifecycle_provider_wiring_test.dart
    2548 total
fa7e237cfb082951a4cb3b5e8d9d106e5f4990ececf306b98c161e19116f7ccd  packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart
8ebed9615aea17b6dc01f49633e322295a8288eb91f054d3170da4fcf36009b6  packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart
ba8c6007d71fe953f64ba8cda9194bd1f0b45b748ec0c791e48e992b76ed6122  packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart
2890a92c79fc6e5cdeb6ea75c9f88815cb63148225f6cdf2ab64c7324b02317f  packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart
1023f2310dba8843afa6cf464fb4a3daf2467b01a4b297f3b8d70fadd310a984  packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart
151c0b1a0d51c152d66fdca9dbb260962d04ffba329dc95667062e8105856e00  packages/map_editor/test/app/providers/map_lifecycle_provider_wiring_test.dart
```

### 5.2 Fichiers modifiés et zones

| Fichier | Zone DS‑05 | Effet |
|---|---|---|
| `lib/src/domain/models/map_document_persistence.dart` | encodeur/révision canonique partagés | journal et store calculent exactement les mêmes octets |
| `lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart` | `expectedRevision` | CAS exact de `project.json` au commit |
| `lib/src/infrastructure/repositories/file_repositories.dart` | `FileProjectRepository`, `FileMapRepository` | barrière recovery, précondition de save générique, encodeur canonique |
| `lib/src/application/use_cases/map_use_cases.dart` | constructeurs et branches Create/Duplicate/Rename/Delete | route produit DS‑05, fallback fakes isolé |
| `lib/src/app/providers/core/repository_providers.dart` | provider manuel du coordinateur | composition gateway réel + repository révisionné |
| `lib/src/app/providers/editor/map_use_case_providers.dart` | injection des quatre use cases | DS‑05 actif dans l’application |
| `test/atomic_project_manifest_persistence_test.dart` | stale exact revision | preuve CAS même si le modèle est identique |
| `test/features/editor/state/editor_notifier_map_revision_test.dart` | fixture projet durable | état test aligné sur l’invariant produit DS‑05 |

Hunks Git observables par rapport à HEAD (ils peuvent agréger des lots World Map
antérieurs dans les fichiers partagés) :

```text
diff --git a/packages/map_editor/lib/src/app/providers/core/repository_providers.dart b/packages/map_editor/lib/src/app/providers/core/repository_providers.dart
@@ -12,0 +13 @@ import '../../../application/services/narrative_activity_journal.dart';
@@ -25,0 +27 @@ import '../../../infrastructure/repositories/file_narrative_document_recovery_st
@@ -33,0 +36,9 @@ part 'repository_providers.g.dart';
@@ -35 +46,4 @@ final fileProjectRepositoryProvider = Provider<FileProjectRepository>((ref) {
diff --git a/packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart b/packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart
@@ -3,0 +4 @@ import 'package:riverpod_annotation/riverpod_annotation.dart';
@@ -31,2 +32 @@ AddEntityToMapUseCase addEntityToMapUseCase(Ref ref) {
@@ -37,2 +37 @@ UpdateEntityOnMapUseCase updateEntityOnMapUseCase(
@@ -43,2 +42 @@ DeleteEntityFromMapUseCase deleteEntityFromMapUseCase(
@@ -57,2 +55 @@ PaintTileOnMapUseCase paintTileOnMapUseCase(Ref ref) {
@@ -68,2 +65 @@ EraseTileOnMapUseCase eraseTileOnMapUseCase(Ref ref) {
@@ -74,2 +70 @@ EraseTilePatternOnMapUseCase eraseTilePatternOnMapUseCase(
@@ -80,2 +75 @@ PaintCollisionOnMapUseCase paintCollisionOnMapUseCase(
@@ -86,2 +80 @@ PaintCollisionPatternOnMapUseCase paintCollisionPatternOnMapUseCase(
@@ -92,2 +85 @@ EraseCollisionOnMapUseCase eraseCollisionOnMapUseCase(
@@ -98,2 +90 @@ EraseCollisionPatternOnMapUseCase eraseCollisionPatternOnMapUseCase(
@@ -109,2 +100 @@ PaintPathOnMapUseCase paintPathOnMapUseCase(Ref ref) {
@@ -120,2 +110 @@ ErasePathOnMapUseCase erasePathOnMapUseCase(Ref ref) {
@@ -126,2 +115 @@ ErasePathPatternOnMapUseCase erasePathPatternOnMapUseCase(
@@ -132,2 +120 @@ AssignPathPresetToLayerUseCase assignPathPresetToLayerUseCase(
@@ -138,2 +125 @@ SetPathLayerPropertiesUseCase setPathLayerPropertiesUseCase(
@@ -144,2 +130 @@ PaintTerrainPatternOnMapUseCase paintTerrainPatternOnMapUseCase(
@@ -150,2 +135 @@ EraseTerrainOnMapUseCase eraseTerrainOnMapUseCase(
@@ -166,2 +150 @@ AddTriggerToMapUseCase addTriggerToMapUseCase(Ref ref) {
@@ -172,2 +155 @@ UpdateTriggerOnMapUseCase updateTriggerOnMapUseCase(
@@ -178,2 +160 @@ DeleteTriggerFromMapUseCase deleteTriggerFromMapUseCase(
@@ -184,2 +165 @@ ResolveMapConnectionTargetUseCase resolveMapConnectionTargetUseCase(
@@ -193,2 +173 @@ UpsertMapConnectionUseCase upsertMapConnectionUseCase(
@@ -204,2 +183 @@ UpdateWarpOnMapUseCase updateWarpOnMapUseCase(Ref ref) {
@@ -210,2 +188 @@ DeleteWarpFromMapUseCase deleteWarpFromMapUseCase(
@@ -216,2 +193 @@ ValidateWarpTargetMapUseCase validateWarpTargetMapUseCase(
@@ -237,2 +213 @@ DeleteMapLayerUseCase deleteMapLayerUseCase(Ref ref) {
@@ -248,2 +223 @@ MoveMapLayerUseCase moveMapLayerUseCase(Ref ref) {
@@ -254,2 +228 @@ ReorderMapLayersUseCase reorderMapLayersUseCase(
@@ -260,2 +233 @@ SetMapLayerVisibilityUseCase setMapLayerVisibilityUseCase(
@@ -274,0 +247,2 @@ CreateMapUseCase createMapUseCase(Ref ref) {
@@ -289,2 +263 @@ ResizeMapUseCase resizeMapUseCase(Ref ref) {
@@ -295,0 +269 @@ RenameMapUseCase renameMapUseCase(Ref ref) {
@@ -297 +271 @@ RenameMapUseCase renameMapUseCase(Ref ref) {
@@ -298,0 +273,3 @@ RenameMapUseCase renameMapUseCase(Ref ref) {
@@ -303,0 +281 @@ DeleteMapUseCase deleteMapUseCase(Ref ref) {
@@ -305 +283 @@ DeleteMapUseCase deleteMapUseCase(Ref ref) {
@@ -306,0 +285,3 @@ DeleteMapUseCase deleteMapUseCase(Ref ref) {
@@ -314,0 +296,2 @@ DuplicateMapUseCase duplicateMapUseCase(Ref ref) {
@@ -319,2 +302 @@ DuplicateMapUseCase duplicateMapUseCase(Ref ref) {
@@ -325,2 +307 @@ AddGameplayZoneToMapUseCase addGameplayZoneToMapUseCase(
@@ -331,2 +312 @@ UpdateGameplayZoneOnMapUseCase updateGameplayZoneOnMapUseCase(
diff --git a/packages/map_editor/lib/src/application/use_cases/map_use_cases.dart b/packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
@@ -1,0 +2 @@ import 'package:map_core/map_core.dart';
@@ -3,0 +5 @@ import '../../domain/repositories/repositories.dart';
@@ -5,0 +8,4 @@ import '../ports/project_workspace.dart';
@@ -7,0 +14,4 @@ import 'project_use_case_support.dart';
@@ -17,0 +28,30 @@ class SaveMapUseCase {
@@ -22,0 +63 @@ class SaveMapUseCase {
@@ -28,0 +70 @@ class CreateMapUseCase {
@@ -30 +72,5 @@ class CreateMapUseCase {
@@ -35,5 +81,10 @@ class CreateMapUseCase {
@@ -43,2 +94,2 @@ class CreateMapUseCase {
@@ -71 +122 @@ class CreateMapUseCase {
@@ -72,0 +124,5 @@ class CreateMapUseCase {
@@ -75,2 +130,0 @@ class CreateMapUseCase {
@@ -80,2 +134,2 @@ class CreateMapUseCase {
@@ -88 +142,36 @@ class CreateMapUseCase {
@@ -99,0 +189,8 @@ class LoadMapUseCase {
@@ -101,2 +198,9 @@ class LoadMapUseCase {
@@ -124,0 +229,2 @@ class LoadMapUseCase {
@@ -162,0 +269,2 @@ class RenameMapUseCase {
@@ -164 +272,6 @@ class RenameMapUseCase {
@@ -168,2 +281,36 @@ class RenameMapUseCase {
@@ -171 +318,11 @@ class RenameMapUseCase {
@@ -173 +330,11 @@ class RenameMapUseCase {
@@ -175 +342,2 @@ class RenameMapUseCase {
@@ -178,3 +346,7 @@ class RenameMapUseCase {
@@ -182,2 +354,10 @@ class RenameMapUseCase {
@@ -185 +365,26 @@ class RenameMapUseCase {
@@ -186,0 +392,7 @@ class RenameMapUseCase {
@@ -188,9 +399,0 @@ class RenameMapUseCase {
@@ -198,3 +401,9 @@ class RenameMapUseCase {
@@ -202,4 +410,0 @@ class RenameMapUseCase {
@@ -207,0 +413,12 @@ class RenameMapUseCase {
@@ -210,0 +428,6 @@ class RenameMapUseCase {
@@ -213,0 +437,2 @@ class DeleteMapUseCase {
@@ -215 +440,6 @@ class DeleteMapUseCase {
@@ -219,2 +449,13 @@ class DeleteMapUseCase {
@@ -224,0 +466,21 @@ class DeleteMapUseCase {
@@ -225,0 +488,5 @@ class DeleteMapUseCase {
@@ -233,0 +501 @@ class DuplicateMapUseCase {
@@ -235 +503,5 @@ class DuplicateMapUseCase {
@@ -239,6 +511,11 @@ class DuplicateMapUseCase {
@@ -246,2 +523 @@ class DuplicateMapUseCase {
@@ -248,0 +525,6 @@ class DuplicateMapUseCase {
@@ -250 +532,3 @@ class DuplicateMapUseCase {
@@ -252,4 +535,0 @@ class DuplicateMapUseCase {
@@ -266 +546,42 @@ class DuplicateMapUseCase {
@@ -270,0 +592,91 @@ class DuplicateMapUseCase {
diff --git a/packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart b/packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart
@@ -85,0 +86 @@ final class AtomicProjectManifestPersistence
@@ -125,0 +127 @@ final class AtomicProjectManifestPersistence
@@ -140,0 +143 @@ final class AtomicProjectManifestPersistence
@@ -189,0 +193,10 @@ final class AtomicProjectManifestPersistence
diff --git a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
@@ -16,0 +17 @@ import '../../application/ports/project_workspace.dart';
@@ -17,0 +19 @@ import '../../application/services/pokemon_project_data_reader.dart';
@@ -18,0 +21 @@ import '../../domain/repositories/repositories.dart';
@@ -22,0 +26,2 @@ import 'project_manifest_write_lock.dart';
@@ -28,2 +33,4 @@ class FileProjectRepository
@@ -36,0 +44 @@ class FileProjectRepository
@@ -97 +105,6 @@ class FileProjectRepository
@@ -99,4 +112,5 @@ class FileProjectRepository
@@ -105,0 +120,38 @@ class FileProjectRepository
@@ -185,0 +238,6 @@ class FileProjectRepository
@@ -264 +322,7 @@ bool _sameEventRegistry(
@@ -276,4 +340,27 @@ class FileMapRepository implements MapRepository {
@@ -283,0 +371,5 @@ class FileMapRepository implements MapRepository {
@@ -285,3 +377,5 @@ class FileMapRepository implements MapRepository {
@@ -290,3 +384,6 @@ class FileMapRepository implements MapRepository {
@@ -302,4 +399,18 @@ class FileMapRepository implements MapRepository {
diff --git a/packages/map_editor/test/atomic_project_manifest_persistence_test.dart b/packages/map_editor/test/atomic_project_manifest_persistence_test.dart
@@ -77,0 +78,34 @@ void main() {
```

## 6. Couverture comportementale

Le service et la passerelle couvrent notamment :

- happy path create ;
- crash après journal prepared ;
- crash après cible écrite et reprise par une nouvelle instance ;
- crash rename/delete et cleanup source ;
- divergence du manifeste ;
- divergence de la révision source ;
- source stale avant préparation : conflit sans journal ;
- collision cible ;
- révision exacte du manifeste ;
- journal committed nettoyé idempotemment ;
- mutation d’un champ projet hors `maps` refusée ;
- journal altéré dont le delta lifecycle est invalide ;
- exception async après journal classée recovery-required ;
- racine JSON inconnue de `project.json` préservée ;
- ouverture projet précédée par recovery ;
- sauvegarde générique stale après recovery rejetée ;
- journal invalide conservé ;
- rewrite orphelin sans intention stable supprimé ;
- chemin cible hors `maps/` refusé avant I/O durable ;
- journal symlink refusé ;
- Create/Duplicate/Rename/Delete au niveau use case ;
- wiring Riverpod prouvant que le repository legacy ne reçoit pas l’écriture.

## 7. Journal TDD RED → GREEN

| Cycle | RED observé | Correction minimale | GREEN |
|---|---|---|---|
| Contrat service | types/service absents, compilation impossible | record + gateway + coordinateur | 9 scénarios initiaux verts |
| Gateway/CAS projet | `expectedRevision` et gateway absents | passerelle réelle + CAS manifeste | 19 tests verts sur le pack concerné |
| Use cases | paramètres `lifecycleTransactions` absents | injection optionnelle et branches transactionnelles | 4 opérations vertes |
| Composition | le faux `ProjectRepository` était encore appelé | provider coordinateur injecté | test wiring vert |
| Fixture notifier | deux tests partaient d’un projet impossible seulement en mémoire | écrire `project.json` dans la fixture | 8 tests notifier verts |
| Erreur async post-journal | `StateError` s’échappait du `try` | attendre explicitement `_rollForwardLocked` | test ciblé vert |
| Save générique vs recovery | save stale terminait sans erreur et écrasait le delta | capturer/réexiger la révision exacte autour de la barrière | test ciblé vert |

Dernier RED exact du cycle de concurrence :

```text
Expected: throws <Instance of 'EditorConflictException'>
Actual: Future<void> emitted null
exit code 1
```

GREEN correspondant :

```text
+1: All tests passed!
exit code 0
```

## 8. Vérifications finales fraîches

### 8.1 Pack ciblé DS‑03/04/05

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact \
  test/application/services/map_lifecycle_transaction_service_test.dart \
  test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart \
  test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart \
  test/app/providers/map_lifecycle_provider_wiring_test.dart \
  test/atomic_project_manifest_persistence_test.dart \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/features/editor/state/editor_notifier_map_revision_test.dart
```

Résultat exact :

```text
00:05 +126: All tests passed!
exit code 0
```

### 8.2 Suite complète package

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact
```

Résultat exact récupéré dans le journal du runner :

```text
05:23 +4447 ~6: 6 skipped tests.
05:23 +4447 ~6: All other tests passed!
flutter_test_exit=0
```

Le compteur ciblé et le compteur global sont rapportés séparément ; aucun total
n’est extrapolé.

### 8.3 Analyse

Commande :

```bash
cd packages/map_editor
flutter analyze --no-pub
```

Résultat exact :

```text
Analyzing map_editor...
No issues found! (ran in 5.7s)
exit code 0
```

### 8.4 Format et whitespace

Commandes :

```bash
cd packages/map_editor
dart format --output=none --set-exit-if-changed <14 fichiers DS-05>
git diff --check
```

Résultats :

```text
Formatted 14 files (0 changed) in 0.06 seconds.
git diff --check: aucune sortie
exit code 0
```

### 8.5 Build macOS release

Commande :

```bash
cd packages/map_editor
flutter build macos --release --no-pub
```

Résultat exact :

```text
✓ Built build/macos/Build/Products/Release/PokeMap.app (44.7MB)
exit code 0
```

Warnings non bloquants et hors diff DS‑05 :

- `audioplayers_darwin 6.5.0` : diagnostics Swift actor isolation/capture ;
- `video_player_avfoundation 2.11.0` : dépréciation
  `AVKeyValueStatus` et optionalité de `createArgsCodec`.

Aucune génération Riverpod n’a été nécessaire : le provider DS‑05 est manuel
et aucun fichier généré n’a changé.

### 8.6 Snapshot exact de l’index Git

Le contenu staged a été exporté avec `git checkout-index` dans un répertoire
temporaire, afin de vérifier le futur commit sans les modifications concurrentes
restées dans le worktree.

Résultats :

```text
flutter analyze --no-pub
No issues found! (ran in 17.5s)

pack ciblé DS-03/04/05
00:12 +126: All tests passed!

flutter build macos --release --no-pub
✓ Built build/macos/Build/Products/Release/PokeMap.app (44.6MB)
```

Le premier essai de build de cet export s’est arrêté avant compilation parce
que `git checkout-index` n’exporte pas
`macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`, qui est
ignoré par Git. Après copie de ce seul répertoire généré depuis le workspace
déjà validé, le même snapshot staged a produit le build release ci-dessus.
Cette étape n’a modifié aucun fichier source ni l’index.

## 9. Verdicts des cinq passes séparées

Contrainte d’exécution : la directive supérieure de cette session interdisait
de créer des sub-agents sans demande explicite de l’utilisateur. Les cinq
verdicts exigés ont donc été produits comme cinq relectures séquentielles
indépendantes, sans prétendre qu’il s’agit de sub-agents.

| Passe | Vérifications | Verdict |
|---|---|---|
| Audit / Architecture | critères DS‑05, frontières, ordre durable, vérité mono/multi-fichier, Gate 0 | **PASS** |
| Implémentation | await async, CAS exact, idempotence, conservation du journal, paths, composition | **PASS** |
| Tests | RED/GREEN, crashs, divergences, I/O réel, use cases et wiring | **PASS** |
| Build / Validation | 126 ciblés, 4 447 globaux, 6 skipped, analyse, format, diff-check, release | **PASS** |
| Critique finale | sur-promesse, scénarios non prouvés, scope Git concurrent, risques résiduels | **PASS avec risques documentés** |

## 10. Auto-critique et risques

### Ce que la preuve établit fortement

- chaque lifecycle produit passe par une intention durable avant mutation ;
- les quatre opérations possèdent une preuve d’intégration réelle ;
- les révisions source, cible et projet sont revalidées ;
- un restart avec nouvelle instance termine une transaction préparée ;
- un état indépendant est bloqué plutôt que deviné ;
- un save générique stale ne peut pas écraser le manifeste après recovery ;
- la suite package complète reste verte.

### Risques résiduels

1. **Durabilité de répertoire.** Les fichiers sont flushés et renommés, mais
   Dart n’expose pas ici un fsync portable du répertoire après rename. Une
   perte d’alimentation au niveau filesystem reste plus forte que le crash
   processus simulé.
2. **Altération adversariale de chemins.** Le produit valide les chemins via
   `ProjectFileSystem`, et la gateway refuse les documents finaux non
   réguliers. Un attaquant local capable de remplacer un répertoire intermédiaire
   par un symlink entre validation et I/O reste un TOCTOU hors modèle de menace
   desktop normal.
3. **Fallback de compatibilité.** Les fakes historiques non révisionnés
   conservent la compensation best-effort pour ne pas casser leurs contrats.
   Le composition root produit prouve qu’il n’utilise pas ce chemin.
4. **Un journal à la fois.** Le protocole sérialise volontairement un seul
   lifecycle World Map par projet. C’est sûr mais non parallèle.
5. **DS‑06 restant.** Le resize destructif n’est pas couvert par DS‑05.

### Risques de sur- et sous-correction

- Sur-correction évitée : pas de nouveau schéma, pas de transaction distribuée,
  pas de refonte UI glissée dans ce lot.
- Sous-correction évitée : le lot ne s’arrête pas à un try/catch ou un rollback
  mémoire ; la preuve survit au redémarrage.
- Limite assumée : DS‑05 protège les opérations structurales ; les futures
  mutations multi-documents devront explicitement réutiliser ou étendre le
  protocole.

## 11. Statut proposé

- **DS‑05 : proposé `DONE`.**
- **Gate 0 : reste `PARTIAL` jusqu’à DS‑06.**
- Prochaine étape de sûreté : DS‑06 — Resize impact plan.
- Première tranche ergonomique ensuite : pile visuelle canonique et navigation
  desktop, conformément à l’audit.

## 12. État Git

### 12.1 État initial DS‑05

Le lot a démarré dans le worktree partagé très sale hérité de DS‑04 :

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

Nombre d’entrées : **118**.

### 12.2 État avant création du rapport

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
 M packages/map_editor/lib/src/app/providers/core/repository_providers.dart
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
 M packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart
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
 M packages/map_editor/test/atomic_project_manifest_persistence_test.dart
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
?? packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart
?? packages/map_editor/lib/src/application/services/project_map_id_policy.dart
?? packages/map_editor/lib/src/application/services/project_map_manifest_integrity_policy.dart
?? packages/map_editor/lib/src/domain/models/map_document_persistence.dart
?? packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart
?? packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart
?? packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart
?? packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_dependency_preflight_dialog.dart
?? packages/map_editor/test/app/providers/map_lifecycle_provider_wiring_test.dart
?? packages/map_editor/test/application/services/map_dependency_preflight_service_test.dart
?? packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart
?? packages/map_editor/test/application/services/project_map_id_policy_test.dart
?? packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart
?? packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
?? packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart
?? packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart
?? packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart
?? packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart
?? packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart
?? packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart
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

Nombre d’entrées : **126**.

Le commit demandé sera construit avec des chemins/hunks explicites. Les travaux
gameplay, hub, runtime, export, scène, performance, fichiers Xcode et autres
éléments hors World Map resteront non stagés. Le résultat post-push est fourni
dans le handoff final, car un rapport ne peut pas contenir de façon
auto-référentielle le hash final du commit qui le contient.

+### 12.3 État après création et relecture du rapport

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
 M packages/map_editor/lib/src/app/providers/core/repository_providers.dart
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
 M packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart
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
 M packages/map_editor/test/atomic_project_manifest_persistence_test.dart
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
?? packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart
?? packages/map_editor/lib/src/application/services/project_map_id_policy.dart
?? packages/map_editor/lib/src/application/services/project_map_manifest_integrity_policy.dart
?? packages/map_editor/lib/src/domain/models/map_document_persistence.dart
?? packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart
?? packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart
?? packages/map_editor/lib/src/infrastructure/repositories/map_document_write_lock.dart
?? packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_dependency_preflight_dialog.dart
?? packages/map_editor/test/app/providers/map_lifecycle_provider_wiring_test.dart
?? packages/map_editor/test/application/services/map_dependency_preflight_service_test.dart
?? packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart
?? packages/map_editor/test/application/services/project_map_id_policy_test.dart
?? packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart
?? packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
?? packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart
?? packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart
?? packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart
?? packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart
?? packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart
?? packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart
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
?? reports/ui/world_map_editor_ds_05_transaction_lifecycle_2026-07-28.md
?? reports/ui/world_map_editor_foundation_ds_00_ds_02_2026-07-28.md
```

Nombre d’entrées : **127**. Le seul nouvel élément de cette étape est le
présent Evidence Pack. Aucun artefact de build n’est suivi.


## 13. Contenu complet des fichiers créés

Le présent rapport n’est pas reproduit récursivement. Le plan sous
`docs/superpowers/plans` est ignoré par Git, mais son contenu est conservé ici
comme preuve de méthode.

### `docs/superpowers/plans/2026-07-28-world-map-ds-05-transaction-lifecycle.md`

~~~~markdown
# World Map DS-05 Transaction Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make World Map create, duplicate, rename and delete operations
recoverable across the map-document and `project.json` boundaries, with durable
intent, revision revalidation and honest recovery states.

**Architecture:** Add an application-level transaction record and coordinator
behind a filesystem gateway. The gateway durably stores one project-scoped
write-ahead journal, reuses the DS-03 revisioned map repository and the existing
atomic project-manifest writer, and serializes lifecycle operations with a
separate OS lock. The coordinator always inspects real durable state during
recovery; journal phases are evidence, never a claim of multi-file atomicity.

**Tech Stack:** Dart 3, Flutter desktop, `dart:io`, `map_core` validated JSON
models and SHA-256 fingerprints, Riverpod, `package:path`, `flutter_test`.

**Repository constraints:** Work runs on `main` because the user explicitly
requested implementation followed by a push. The shared worktree already
contains many unrelated changes, so no worktree, stash, reset, cleanup or broad
staging is allowed. The final commit must select only the World Map audit and
DS-00 through DS-05 files.

---

## Scope

Included:

- durable journal for create, duplicate, rename and delete;
- full validated target-map payload in the temporary journal so prepared
  operations can roll forward after a crash;
- exact source-map and initial project revisions;
- revision/absence checks immediately before every durable mutation;
- operation order that never makes a manifest point at a target that has not
  been written;
- deterministic, idempotent roll-forward recovery;
- fail-closed recovery when project, source or target diverged independently;
- separate project-scoped process and OS transaction lock;
- recovery barrier before normal project load/save;
- fault injection at every durable lifecycle checkpoint;
- existing legacy fallback only for non-revisioned test repositories;
- focused tests, full editor regression, analyzer, macOS release build and
  tracked Evidence Pack.

Excluded:

- claiming atomic multi-file replacement;
- automatic merge of independently changed manifests or maps;
- undo/history UI for completed lifecycle operations;
- visual rendering, layer priority, mouse navigation or tool ergonomics;
- schema changes to `MapData` or `ProjectManifest`;
- silent migration of legacy IDs or paths;
- generalized transactions for unrelated Narrative/Pokemon authoring flows.

## File map

Create:

- `packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart`
  — immutable request/journal/result contracts and deterministic coordinator.
- `packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart`
  — durable journal, filesystem/CAS adapter and project-scoped lock.
- `packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart`
  — protocol and recovery characterization with a durable in-memory gateway.
- `packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart`
  — real-file crash/restart and confinement evidence.
- `packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart`
  — create/duplicate/rename/delete integration through the transaction boundary.
- `reports/ui/world_map_editor_ds_05_transaction_lifecycle_2026-07-28.md`
  — complete Evidence Pack required by `codex_rule.md`.

Modify:

- `packages/map_editor/lib/src/domain/models/map_document_persistence.dart`
  — one canonical map-byte encoder/revision helper shared by DS-03 and DS-05.
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
  — reuse canonical encoding and place project load/save behind recovery.
- `packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart`
  — optional exact expected-revision check in addition to semantic CAS.
- `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
  — route product lifecycle operations through the coordinator.
- `packages/map_editor/lib/src/app/providers/core/repository_providers.dart`
  — compose one filesystem transaction coordinator and project recovery barrier.
- `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart`
  — inject the coordinator into all four lifecycle use cases.
- `packages/map_editor/test/atomic_project_manifest_persistence_test.dart`
  — exact-revision regression.

No generated Riverpod file should change because DS-05 uses manual providers
and constructor injection only.

---

### Task 1: Specify the lifecycle protocol in RED

**Files:**

- Create:
  `packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart`

- [ ] **Step 1: Write the coordinator contract tests**

The wished-for API is:

```dart
final coordinator = MapLifecycleTransactionCoordinator(gateway);
await coordinator.execute(
  MapLifecycleTransactionRequest.create(
    projectPath: '/project/project.json',
    beforeProject: before,
    afterProject: after,
    targetPath: '/project/maps/town.json',
    targetMap: town,
  ),
);
```

The tests must prove:

```dart
expect(gateway.project, after);
expect(gateway.maps[targetPath]!.map, town);
expect(gateway.journal, isNull);
```

They must also inject `MapLifecycleSimulatedCrash` after journal preparation,
target persistence, project persistence and source cleanup, reconstruct a new
coordinator, call `recover(projectPath)`, and assert the exact final state.

- [ ] **Step 2: Add negative recovery cases**

Cover:

```dart
await expectLater(
  coordinator.recover(projectPath),
  throwsA(isA<ProjectRecoveryBlockedException>()),
);
expect(gateway.journal, isNotNull);
```

for a divergent project snapshot, a changed source revision and a colliding
target revision. Also prove a second recovery is a no-op after successful
cleanup.

- [ ] **Step 3: Run RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/application/services/map_lifecycle_transaction_service_test.dart
```

Expected: compilation failure because the DS-05 contracts do not exist.

---

### Task 2: Implement the application transaction coordinator

**Files:**

- Create:
  `packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart`
- Modify:
  `packages/map_editor/lib/src/domain/models/map_document_persistence.dart`

- [ ] **Step 1: Add canonical map bytes**

Move the exact pretty-JSON encoding contract behind:

```dart
List<int> encodeMapDocumentBytes(MapData map) => utf8.encode(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );

String mapDocumentRevisionFor(MapData map) =>
    narrativeEventBytesFingerprint(encodeMapDocumentBytes(map));
```

The File repository and transaction record must use this single function so a
journal cannot predict a revision different from DS-03 persistence.

- [ ] **Step 2: Add immutable transaction models**

Define:

```dart
enum MapLifecycleOperation { create, duplicate, rename, delete }
enum MapLifecycleTransactionStatus {
  prepared,
  targetWritten,
  projectWritten,
  sourceRemoved,
  committed,
}
enum MapLifecycleRecoveryStatus { clear, recovered }
```

`MapLifecycleTransactionRecord` stores schema version, transaction ID,
operation, phase, exact initial project revision, before/after manifests,
optional source path/revision, optional target path/map and the predicted target
revision. `fromJson` validates every required field and rejects unknown schema
versions or impossible operation shapes.

- [ ] **Step 3: Add the gateway and coordinator**

The gateway exposes synchronized execution, project/map snapshots, CAS
project/map writes, CAS map delete, atomic journal read/write/clear, and a
journal path for diagnostics.

The coordinator algorithm is:

```text
lock project lifecycle
recover any existing record
read and match exact before project revision
revalidate source revision
write prepared journal
ensure target is absent or exact, then write it
CAS project before -> after
delete rename/delete source only after project is after
write committed evidence
clear journal
```

Recovery ignores optimistic phase claims and derives action from durable
project/map state. A matching before state rolls forward; a matching after state
finishes repair/cleanup; any third state throws
`ProjectRecoveryBlockedException` without clearing evidence.

- [ ] **Step 4: Run GREEN**

Run the Task 1 command. Expected: all coordinator tests pass.

---

### Task 3: Specify and implement durable filesystem recovery

**Files:**

- Create:
  `packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart`
- Create:
  `packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart`
- Modify:
  `packages/map_editor/test/atomic_project_manifest_persistence_test.dart`
- Modify:
  `packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart`
- Modify:
  `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

- [ ] **Step 1: Write RED filesystem tests**

Use a temporary PokeMap project and real `FileMapRepository`. Prove:

- journal writes are flushed and atomically renamed under
  `.pokemap/recovery/world-map-lifecycle.json`;
- a crash followed by a new gateway instance rolls forward;
- unknown `project.json` root members and raw Event registry data survive;
- a malformed/tampered journal blocks recovery;
- paths outside the project `maps/` directory are rejected;
- orphan journal rewrite files without an authoritative journal are discarded;
- normal project load recovers a pending lifecycle record first.

- [ ] **Step 2: Add exact project revision RED**

Extend `atomic_project_manifest_persistence_test.dart`:

```dart
final expected = narrativeEventBytesFingerprint(await file.readAsBytes());
await mutateOnlyUnknownRootMember(file);
final result = await persistence.persistProjectDocument(
  projectPath: file.path,
  operationId: 'ds05-exact-cas',
  before: before,
  after: after,
  expectedRevision: expected,
);
expect(result.code, 'staleProjectRevision');
```

Expected RED: the named parameter does not exist.

- [ ] **Step 3: Implement the file gateway**

Use a stable process queue plus a dedicated OS file lock. Validate the stable
journal and rewrite artifact types without following symlinks. Journal rewrites
must use an explicitly flushed file handle and same-filesystem rename.

Map reads/writes/deletes delegate to `RevisionedMapRepository`. Project writes
delegate to `AtomicProjectManifestPersistence.persistProjectDocument` with the
recorded exact revision.

- [ ] **Step 4: Add the optional project revision precondition**

In `_persistLocked`, reject before preparing a temp file when:

```dart
expectedRevision != null && beforeRevision != expectedRevision
```

Existing callers omit the parameter and retain their current semantic-CAS
behavior.

- [ ] **Step 5: Put FileProjectRepository behind recovery**

Add an optional coordinator dependency. When present, `loadProject` and
`saveProject` run inside `runAfterRecovery`, holding the lifecycle lock through
their existing project-manifest lock. Direct test construction without the
dependency remains source-compatible.

- [ ] **Step 6: Run GREEN**

Run:

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/atomic_project_manifest_persistence_test.dart \
  test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart
```

Expected: all tests pass with no leaked journal/temp artifacts.

---

### Task 4: Route all product lifecycle use cases through DS-05

**Files:**

- Create:
  `packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart`
- Modify:
  `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
- Modify:
  `packages/map_editor/lib/src/app/providers/core/repository_providers.dart`
- Modify:
  `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart`
- Modify:
  `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

- [ ] **Step 1: Write RED use-case integration tests**

Inject a real coordinator into each use case and prove:

- create produces target + manifest and no journal;
- duplicate records the exact loaded source revision;
- rename writes the new map and manifest before deleting the old revision;
- delete removes the manifest entry before deleting the exact source revision;
- an interrupted operation is recovered when `FileProjectRepository.loadProject`
  opens the project.

- [ ] **Step 2: Add optional constructor injection**

Each use case receives:

```dart
MapLifecycleTransactionCoordinator? lifecycleTransactions
```

When present, it submits one validated request before any lifecycle writer I/O.
When absent, the existing legacy implementation remains for historical
non-revisioned fakes; comments must identify it as a compatibility path, not
the product safety contract.

- [ ] **Step 3: Compose the real coordinator once**

Add a manual provider that returns a coordinator only when the configured map
repository implements `RevisionedMapRepository`. Inject it into
`FileProjectRepository` and all four lifecycle use cases. Do not add a generated
Riverpod annotation.

- [ ] **Step 4: Run GREEN and focused regression**

Run:

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded \
  test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/features/editor/state/editor_notifier_map_revision_test.dart
```

Expected: all tests pass; legacy fakes preserve their existing call assertions.

---

### Task 5: Verify, critique, report, commit and push

**Files:**

- Create:
  `reports/ui/world_map_editor_ds_05_transaction_lifecycle_2026-07-28.md`

- [ ] **Step 1: Format and run the complete focused pack**

```bash
cd packages/map_editor
dart format \
  lib/src/application/services/map_lifecycle_transaction_service.dart \
  lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart \
  lib/src/domain/models/map_document_persistence.dart \
  lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart \
  lib/src/infrastructure/repositories/file_repositories.dart \
  lib/src/application/use_cases/map_use_cases.dart \
  lib/src/app/providers/core/repository_providers.dart \
  lib/src/app/providers/editor/map_use_case_providers.dart \
  test/application/services/map_lifecycle_transaction_service_test.dart \
  test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart \
  test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart \
  test/atomic_project_manifest_persistence_test.dart
```

Then rerun all DS-00 through DS-05 focused tests.

- [ ] **Step 2: Run package-wide verification**

```bash
cd packages/map_editor
flutter test --no-pub
flutter analyze --no-pub
flutter build macos --release --no-pub
```

Record exact exit codes and final result lines.

- [ ] **Step 3: Run five separate critical passes**

Because higher-priority session instructions prohibit spawning agents unless
the user explicitly requests delegation, perform and name five independent
self-review passes:

1. Audit / Architecture;
2. Implementation;
3. Tests;
4. Build / Validation;
5. Final Critique.

The final critique searches for accidental files, unsupported atomicity claims,
unrevalidated revisions, unsafe journal paths, journal-clearing errors,
unproven recovery branches and scope mixing.

- [ ] **Step 4: Write the Evidence Pack**

Follow `codex_rule.md`: initial/final Git state, complete file inventory,
created-file contents, precise modified zones/diffs, command outputs, five pass
verdicts, non-goals, limits, risks and proposed lot status.

- [ ] **Step 5: Stage only the World Map scope**

Inspect the candidate path list and staged diff. Never use `git add -A` or
`git add .`. Include the World Map audit and DS-00 through DS-05 implementation,
tests and reports; exclude gameplay, Hub, runtime and machine-local artifacts.

- [ ] **Step 6: Commit and push**

```bash
git commit -m "feat(map-editor): secure world map lifecycle transactions"
git push origin main
```

Verify `HEAD`, `origin/main`, staged/unstaged state and report unrelated
remaining worktree changes without modifying them.

---

## Self-review

- **Spec coverage:** All audit bullets are mapped: four journalled operations,
  deterministic recovery and explicit non-atomic wording. The DS-04 follow-up
  requirement to revalidate revisions at commit is covered for project,
  source and target.
- **Placeholder scan:** No implementation step uses TBD/TODO or delegates an
  unspecified behavior.
- **Type consistency:** The same coordinator/request/record/gateway names are
  used in tests, production wiring and report tasks.
- **Risk boundary:** Full map/project snapshots increase temporary journal
  size but avoid inventing recovery data. Divergence blocks rather than merges.
  Broader World Map ergonomics remains outside DS-05.
~~~~

### `packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart`

~~~~dart
import 'dart:async';
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/map_document_persistence.dart';
import '../errors/application_errors.dart';

/// Lifecycle mutations covered by the DS-05 durable intent protocol.
///
/// These names describe product operations. They deliberately do not contain
/// the word "atomic": each individual file is replaced atomically, while the
/// journal makes the multi-file lifecycle recoverable rather than atomic.
enum MapLifecycleOperation { create, duplicate, rename, delete }

/// Last durable evidence written to the lifecycle journal.
///
/// Recovery never trusts this phase alone. It always re-reads project and map
/// bytes because a process can stop between a file commit and the next phase
/// rewrite.
enum MapLifecycleTransactionStatus {
  prepared,
  targetWritten,
  projectWritten,
  sourceRemoved,
  committed,
}

enum MapLifecycleRecoveryStatus { clear, recovered }

enum MapLifecycleTransactionCheckpoint {
  afterJournalPrepared,
  afterTargetWritten,
  afterProjectWritten,
  afterSourceRemoved,
  beforeJournalCleared,
}

typedef MapLifecycleTransactionFaultInjector = FutureOr<void> Function(
  MapLifecycleTransactionCheckpoint checkpoint,
  MapLifecycleTransactionRecord record,
);

/// Fault-injection sentinel that represents process termination.
///
/// Production exceptions are reported as recovery-required or blocked. This
/// sentinel is intentionally rethrown unchanged so restart tests can prove that
/// durable journal evidence, rather than in-memory compensation, performs the
/// recovery.
final class MapLifecycleSimulatedCrash implements Exception {
  const MapLifecycleSimulatedCrash();
}

final class MapLifecycleProjectSnapshot {
  MapLifecycleProjectSnapshot({
    required this.project,
    required String revision,
  }) : revision = requireMapDocumentRevision(revision);

  final ProjectManifest project;
  final String revision;
}

final class MapLifecycleTransactionRequest {
  const MapLifecycleTransactionRequest._({
    required this.operation,
    required this.projectPath,
    required this.beforeProject,
    required this.afterProject,
    this.sourcePath,
    this.sourceRevision,
    this.targetPath,
    this.targetMap,
  });

  factory MapLifecycleTransactionRequest.create({
    required String projectPath,
    required ProjectManifest beforeProject,
    required ProjectManifest afterProject,
    required String targetPath,
    required MapData targetMap,
  }) {
    return MapLifecycleTransactionRequest._(
      operation: MapLifecycleOperation.create,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      targetPath: targetPath,
      targetMap: targetMap,
    );
  }

  factory MapLifecycleTransactionRequest.duplicate({
    required String projectPath,
    required ProjectManifest beforeProject,
    required ProjectManifest afterProject,
    required String sourcePath,
    required String sourceRevision,
    required String targetPath,
    required MapData targetMap,
  }) {
    return MapLifecycleTransactionRequest._(
      operation: MapLifecycleOperation.duplicate,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      sourceRevision: requireMapDocumentRevision(sourceRevision),
      targetPath: targetPath,
      targetMap: targetMap,
    );
  }

  factory MapLifecycleTransactionRequest.rename({
    required String projectPath,
    required ProjectManifest beforeProject,
    required ProjectManifest afterProject,
    required String sourcePath,
    required String sourceRevision,
    required String targetPath,
    required MapData targetMap,
  }) {
    return MapLifecycleTransactionRequest._(
      operation: MapLifecycleOperation.rename,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      sourceRevision: requireMapDocumentRevision(sourceRevision),
      targetPath: targetPath,
      targetMap: targetMap,
    );
  }

  factory MapLifecycleTransactionRequest.delete({
    required String projectPath,
    required ProjectManifest beforeProject,
    required ProjectManifest afterProject,
    required String sourcePath,
    required String sourceRevision,
  }) {
    return MapLifecycleTransactionRequest._(
      operation: MapLifecycleOperation.delete,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      sourceRevision: requireMapDocumentRevision(sourceRevision),
    );
  }

  final MapLifecycleOperation operation;
  final String projectPath;
  final ProjectManifest beforeProject;
  final ProjectManifest afterProject;
  final String? sourcePath;
  final String? sourceRevision;
  final String? targetPath;
  final MapData? targetMap;
}

/// Durable write-ahead evidence for one map lifecycle mutation.
///
/// The full validated target map is temporary recovery data, not a second
/// source of truth. Keeping it in the journal lets a prepared transaction roll
/// forward even when the process stopped before creating its target document.
final class MapLifecycleTransactionRecord {
  static const schemaVersion = 1;

  MapLifecycleTransactionRecord._({
    required this.transactionId,
    required this.operation,
    required this.status,
    required this.projectPath,
    required String projectBeforeRevision,
    required this.beforeProject,
    required this.afterProject,
    this.sourcePath,
    String? sourceRevision,
    this.targetPath,
    this.targetMap,
    String? targetRevision,
  })  : projectBeforeRevision =
            requireMapDocumentRevision(projectBeforeRevision),
        sourceRevision = sourceRevision == null
            ? null
            : requireMapDocumentRevision(sourceRevision),
        targetRevision = targetRevision == null
            ? null
            : requireMapDocumentRevision(targetRevision) {
    _validateShape();
  }

  factory MapLifecycleTransactionRecord.fromRequest({
    required MapLifecycleTransactionRequest request,
    required String canonicalProjectPath,
    required String projectBeforeRevision,
  }) {
    final targetRevision = request.targetMap == null
        ? null
        : mapDocumentRevisionFor(request.targetMap!);
    final identityPayload = <String, Object?>{
      'operation': request.operation.name,
      'projectPath': canonicalProjectPath,
      'projectBeforeRevision': projectBeforeRevision,
      'beforeProject': request.beforeProject.toJson(),
      'afterProject': request.afterProject.toJson(),
      'sourcePath': request.sourcePath,
      'sourceRevision': request.sourceRevision,
      'targetPath': request.targetPath,
      'targetRevision': targetRevision,
    };
    final fingerprint = narrativeEventBytesFingerprint(
      utf8.encode(jsonEncode(identityPayload)),
    ).substring('sha256:'.length);
    return MapLifecycleTransactionRecord._(
      transactionId: 'map_lifecycle_${fingerprint.substring(0, 24)}',
      operation: request.operation,
      status: MapLifecycleTransactionStatus.prepared,
      projectPath: canonicalProjectPath,
      projectBeforeRevision: projectBeforeRevision,
      beforeProject: request.beforeProject,
      afterProject: request.afterProject,
      sourcePath: request.sourcePath,
      sourceRevision: request.sourceRevision,
      targetPath: request.targetPath,
      targetMap: request.targetMap,
      targetRevision: targetRevision,
    );
  }

  factory MapLifecycleTransactionRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException(
        'Unsupported map lifecycle journal schema.',
      );
    }
    final operation = _enumByName(
      MapLifecycleOperation.values,
      json['operation'],
      'operation',
    );
    final status = _enumByName(
      MapLifecycleTransactionStatus.values,
      json['status'],
      'status',
    );
    final beforeProject = ProjectManifest.fromJson(
      _jsonObject(json['beforeProject'], 'beforeProject'),
    );
    final afterProject = ProjectManifest.fromJson(
      _jsonObject(json['afterProject'], 'afterProject'),
    );
    final targetMapJson = json['targetMap'];
    final targetMap = targetMapJson == null
        ? null
        : MapData.fromJson(_jsonObject(targetMapJson, 'targetMap'));
    ProjectValidator.validate(beforeProject);
    ProjectValidator.validate(afterProject);
    if (targetMap != null) MapValidator.validate(targetMap);
    return MapLifecycleTransactionRecord._(
      transactionId: _requiredString(json['transactionId'], 'transactionId'),
      operation: operation,
      status: status,
      projectPath: _requiredString(json['projectPath'], 'projectPath'),
      projectBeforeRevision: _requiredString(
        json['projectBeforeRevision'],
        'projectBeforeRevision',
      ),
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: _optionalString(json['sourcePath'], 'sourcePath'),
      sourceRevision: _optionalString(json['sourceRevision'], 'sourceRevision'),
      targetPath: _optionalString(json['targetPath'], 'targetPath'),
      targetMap: targetMap,
      targetRevision: _optionalString(json['targetRevision'], 'targetRevision'),
    );
  }

  final String transactionId;
  final MapLifecycleOperation operation;
  final MapLifecycleTransactionStatus status;
  final String projectPath;
  final String projectBeforeRevision;
  final ProjectManifest beforeProject;
  final ProjectManifest afterProject;
  final String? sourcePath;
  final String? sourceRevision;
  final String? targetPath;
  final MapData? targetMap;
  final String? targetRevision;

  bool get hasTarget => targetPath != null;

  bool get removesSource =>
      operation == MapLifecycleOperation.rename ||
      operation == MapLifecycleOperation.delete;

  MapLifecycleTransactionRecord copyWith({
    required MapLifecycleTransactionStatus status,
  }) {
    return MapLifecycleTransactionRecord._(
      transactionId: transactionId,
      operation: operation,
      status: status,
      projectPath: projectPath,
      projectBeforeRevision: projectBeforeRevision,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      sourceRevision: sourceRevision,
      targetPath: targetPath,
      targetMap: targetMap,
      targetRevision: targetRevision,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'transactionId': transactionId,
        'operation': operation.name,
        'status': status.name,
        'projectPath': projectPath,
        'projectBeforeRevision': projectBeforeRevision,
        'beforeProject': beforeProject.toJson(),
        'afterProject': afterProject.toJson(),
        'sourcePath': sourcePath,
        'sourceRevision': sourceRevision,
        'targetPath': targetPath,
        'targetMap': targetMap?.toJson(),
        'targetRevision': targetRevision,
      };

  void _validateShape() {
    if (transactionId.trim().isEmpty ||
        projectPath.trim().isEmpty ||
        beforeProject == afterProject) {
      throw const FormatException(
        'Map lifecycle journal identity or project transition is invalid.',
      );
    }
    final hasSource = sourcePath != null && sourceRevision != null;
    final hasCompleteTarget =
        targetPath != null && targetMap != null && targetRevision != null;
    if ((sourcePath == null) != (sourceRevision == null) ||
        (targetPath == null) != (targetMap == null) ||
        (targetPath == null) != (targetRevision == null)) {
      throw const FormatException(
        'Map lifecycle journal contains a partial map precondition.',
      );
    }
    switch (operation) {
      case MapLifecycleOperation.create:
        if (hasSource || !hasCompleteTarget) {
          throw const FormatException(
            'Create requires one complete target and no source.',
          );
        }
      case MapLifecycleOperation.duplicate:
      case MapLifecycleOperation.rename:
        if (!hasSource || !hasCompleteTarget || sourcePath == targetPath) {
          throw const FormatException(
            'Duplicate/rename requires distinct complete source and target.',
          );
        }
      case MapLifecycleOperation.delete:
        if (!hasSource || hasCompleteTarget) {
          throw const FormatException(
            'Delete requires one complete source and no target.',
          );
        }
    }
    if (targetMap != null &&
        mapDocumentRevisionFor(targetMap!) != targetRevision) {
      throw const FormatException(
        'Map lifecycle target payload does not match its revision.',
      );
    }
    _validateLifecycleDelta(
      operation: operation,
      projectPath: projectPath,
      beforeProject: beforeProject,
      afterProject: afterProject,
      sourcePath: sourcePath,
      targetPath: targetPath,
      targetMap: targetMap,
    );
  }
}

final class MapLifecycleTransactionResult {
  const MapLifecycleTransactionResult({
    required this.project,
    this.targetMap,
    this.targetRevision,
  });

  final ProjectManifest project;
  final MapData? targetMap;
  final String? targetRevision;
}

final class MapLifecycleRecoveryResult {
  const MapLifecycleRecoveryResult(this.status);

  final MapLifecycleRecoveryStatus status;
}

/// Infrastructure boundary used by the deterministic application coordinator.
///
/// File implementations must make each journal rewrite and document mutation
/// individually durable. The application coordinator owns ordering and never
/// infers a successful multi-file commit from a phase flag alone.
abstract interface class MapLifecycleTransactionGateway {
  Future<T> synchronized<T>(
    String projectPath,
    Future<T> Function(String canonicalProjectPath) action,
  );

  String journalPath(String canonicalProjectPath);

  Future<MapLifecycleTransactionRecord?> readJournal(
    String canonicalProjectPath,
  );

  Future<void> writeJournal(
    String canonicalProjectPath,
    MapLifecycleTransactionRecord record,
  );

  Future<void> clearJournal(String canonicalProjectPath);

  Future<MapLifecycleProjectSnapshot> readProject(
    String canonicalProjectPath,
  );

  Future<MapLifecycleProjectSnapshot> writeProject(
    String canonicalProjectPath, {
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
    required String expectedRevision,
  });

  Future<RevisionedMapDocument?> readMap(String path);

  Future<RevisionedMapDocument> writeMap(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
  });

  Future<void> deleteMap(
    String path, {
    required String expectedRevision,
  });
}

/// Durable lifecycle orchestration for create, duplicate, rename and delete.
///
/// Once the prepared journal is durable, recovery rolls the stated intent
/// forward. It never guesses across independently changed project/map bytes:
/// such divergence keeps the journal and raises a product-visible block.
final class MapLifecycleTransactionCoordinator {
  const MapLifecycleTransactionCoordinator(
    this.gateway, {
    this.faultInjector,
  });

  final MapLifecycleTransactionGateway gateway;
  final MapLifecycleTransactionFaultInjector? faultInjector;

  Future<MapLifecycleTransactionResult> execute(
    MapLifecycleTransactionRequest request,
  ) {
    return gateway.synchronized(request.projectPath, (canonicalProjectPath) {
      return _executeLocked(request, canonicalProjectPath);
    });
  }

  Future<MapLifecycleRecoveryResult> recover(String projectPath) {
    return gateway.synchronized(projectPath, _recoverLocked);
  }

  /// Holds the lifecycle lock while normal project I/O runs.
  ///
  /// `FileProjectRepository` uses this barrier so opening or generically saving
  /// `project.json` cannot observe a half-finished World Map lifecycle.
  Future<T> runAfterRecovery<T>(
    String projectPath,
    Future<T> Function(String canonicalProjectPath) action,
  ) {
    return gateway.synchronized(projectPath, (canonicalProjectPath) async {
      await _recoverLocked(canonicalProjectPath);
      return action(canonicalProjectPath);
    });
  }

  Future<MapLifecycleTransactionResult> _executeLocked(
    MapLifecycleTransactionRequest request,
    String canonicalProjectPath,
  ) async {
    await _recoverLocked(canonicalProjectPath);
    _requireProjectMapPaths(
      canonicalProjectPath,
      request.sourcePath,
      request.targetPath,
    );
    final current = await gateway.readProject(canonicalProjectPath);
    if (current.project != request.beforeProject) {
      throw const EditorConflictException(
        'Le projet a changé avant le début de la transaction de carte.',
      );
    }
    await _requireSourceRevision(
      sourcePath: request.sourcePath,
      sourceRevision: request.sourceRevision,
      canonicalProjectPath: canonicalProjectPath,
      journalIsDurable: false,
    );
    late final MapLifecycleTransactionRecord record;
    try {
      record = MapLifecycleTransactionRecord.fromRequest(
        request: request,
        canonicalProjectPath: canonicalProjectPath,
        projectBeforeRevision: current.revision,
      );
    } on FormatException catch (error) {
      throw EditorValidationException(
        'La transaction lifecycle demandée est invalide: $error',
      );
    }
    var journalIsDurable = false;
    try {
      await gateway.writeJournal(canonicalProjectPath, record);
      journalIsDurable = true;
      await _checkpoint(
        MapLifecycleTransactionCheckpoint.afterJournalPrepared,
        record,
      );
      return await _rollForwardLocked(record);
    } on MapLifecycleSimulatedCrash {
      rethrow;
    } on ProjectRecoveryBlockedException {
      rethrow;
    } on ProjectRecoveryRequiredException {
      rethrow;
    } on Object catch (error) {
      if (!journalIsDurable) rethrow;
      throw ProjectRecoveryRequiredException(
        'La transaction de carte a été interrompue et sera reprise avant '
        'tout nouvel accès au projet. Cause: $error',
        code: 'mapLifecycleRecoveryRequired',
        path: gateway.journalPath(canonicalProjectPath),
      );
    }
  }

  Future<MapLifecycleRecoveryResult> _recoverLocked(
    String canonicalProjectPath,
  ) async {
    late final MapLifecycleTransactionRecord? record;
    try {
      record = await gateway.readJournal(canonicalProjectPath);
    } on ProjectRecoveryBlockedException {
      rethrow;
    } on Object catch (error) {
      throw ProjectRecoveryBlockedException(
        'Le journal lifecycle World Map est illisible ou invalide: $error',
        code: 'mapLifecycleJournalInvalid',
        path: gateway.journalPath(canonicalProjectPath),
      );
    }
    if (record == null) {
      return const MapLifecycleRecoveryResult(
        MapLifecycleRecoveryStatus.clear,
      );
    }
    if (p.normalize(record.projectPath) != p.normalize(canonicalProjectPath)) {
      _blocked(
        canonicalProjectPath,
        'Le journal appartient à un autre manifeste de projet.',
      );
    }
    _requireProjectMapPaths(
      canonicalProjectPath,
      record.sourcePath,
      record.targetPath,
    );
    try {
      await _rollForwardLocked(record);
      return const MapLifecycleRecoveryResult(
        MapLifecycleRecoveryStatus.recovered,
      );
    } on MapLifecycleSimulatedCrash {
      rethrow;
    } on ProjectRecoveryBlockedException {
      rethrow;
    } on ProjectRecoveryRequiredException {
      rethrow;
    } on Object catch (error) {
      throw ProjectRecoveryRequiredException(
        'La reprise de la transaction World Map doit être retentée. '
        'Cause: $error',
        code: 'mapLifecycleRecoveryRequired',
        path: gateway.journalPath(canonicalProjectPath),
      );
    }
  }

  Future<MapLifecycleTransactionResult> _rollForwardLocked(
    MapLifecycleTransactionRecord initialRecord,
  ) async {
    var record = initialRecord;
    var currentProject = await gateway.readProject(record.projectPath);
    final projectIsBefore = currentProject.project == record.beforeProject;
    final projectIsAfter = currentProject.project == record.afterProject;
    if (!projectIsBefore && !projectIsAfter) {
      _blocked(
        record.projectPath,
        'project.json diverge des deux états attestés par le journal.',
      );
    }

    if (projectIsBefore) {
      if (currentProject.revision != record.projectBeforeRevision) {
        _blocked(
          record.projectPath,
          'La révision exacte de project.json a changé depuis la préparation.',
        );
      }
      await _requireSourceRevision(
        sourcePath: record.sourcePath,
        sourceRevision: record.sourceRevision,
        canonicalProjectPath: record.projectPath,
      );
      if (record.hasTarget) {
        await _ensureTarget(record);
        record = await _advance(
          record,
          MapLifecycleTransactionStatus.targetWritten,
        );
        await _checkpoint(
          MapLifecycleTransactionCheckpoint.afterTargetWritten,
          record,
        );
      }
      currentProject = await gateway.writeProject(
        record.projectPath,
        operationId: record.transactionId,
        before: record.beforeProject,
        after: record.afterProject,
        expectedRevision: record.projectBeforeRevision,
      );
      if (currentProject.project != record.afterProject) {
        _blocked(
          record.projectPath,
          'Le manifeste durable ne correspond pas à la transaction préparée.',
        );
      }
      record = await _advance(
        record,
        MapLifecycleTransactionStatus.projectWritten,
      );
      await _checkpoint(
        MapLifecycleTransactionCheckpoint.afterProjectWritten,
        record,
      );
    } else if (record.hasTarget) {
      // A committed manifest must never be left pointing at a missing target.
      // The journal contains the validated payload needed for an idempotent
      // absence-only repair after a crash or external file removal.
      await _ensureTarget(record);
    }

    if (record.removesSource) {
      await _removeSource(record);
      record = await _advance(
        record,
        MapLifecycleTransactionStatus.sourceRemoved,
      );
      await _checkpoint(
        MapLifecycleTransactionCheckpoint.afterSourceRemoved,
        record,
      );
    }

    record = await _advance(
      record,
      MapLifecycleTransactionStatus.committed,
    );
    await _checkpoint(
      MapLifecycleTransactionCheckpoint.beforeJournalCleared,
      record,
    );
    await gateway.clearJournal(record.projectPath);
    return MapLifecycleTransactionResult(
      project: record.afterProject,
      targetMap: record.targetMap,
      targetRevision: record.targetRevision,
    );
  }

  Future<MapLifecycleTransactionRecord> _advance(
    MapLifecycleTransactionRecord record,
    MapLifecycleTransactionStatus requested,
  ) async {
    final next = requested.index > record.status.index
        ? record.copyWith(status: requested)
        : record;
    if (next.status != record.status) {
      await gateway.writeJournal(record.projectPath, next);
    }
    return next;
  }

  Future<void> _ensureTarget(MapLifecycleTransactionRecord record) async {
    final targetPath = record.targetPath!;
    final expectedRevision = record.targetRevision!;
    final targetMap = record.targetMap!;
    final current = await gateway.readMap(targetPath);
    if (current != null) {
      if (current.revision != expectedRevision || current.map != targetMap) {
        _blocked(
          record.projectPath,
          'La cible "$targetPath" existe avec un contenu indépendant.',
        );
      }
      return;
    }
    final saved = await gateway.writeMap(
      targetMap,
      targetPath,
      precondition: const MapDocumentWritePrecondition.absent(),
    );
    if (saved.revision != expectedRevision || saved.map != targetMap) {
      _blocked(
        record.projectPath,
        'La cible durable ne correspond pas au payload du journal.',
      );
    }
  }

  Future<void> _removeSource(MapLifecycleTransactionRecord record) async {
    final sourcePath = record.sourcePath!;
    final sourceRevision = record.sourceRevision!;
    final current = await gateway.readMap(sourcePath);
    if (current == null) return;
    if (current.revision != sourceRevision) {
      _blocked(
        record.projectPath,
        'La source "$sourcePath" a changé avant sa suppression.',
      );
    }
    await gateway.deleteMap(
      sourcePath,
      expectedRevision: sourceRevision,
    );
    if (await gateway.readMap(sourcePath) != null) {
      _blocked(
        record.projectPath,
        'La suppression durable de "$sourcePath" ne peut pas être attestée.',
      );
    }
  }

  Future<void> _requireSourceRevision({
    required String? sourcePath,
    required String? sourceRevision,
    required String canonicalProjectPath,
    bool journalIsDurable = true,
  }) async {
    if (sourcePath == null) return;
    final current = await gateway.readMap(sourcePath);
    if (current == null || current.revision != sourceRevision) {
      if (!journalIsDurable) {
        throw const EditorConflictException(
          'The source map changed before lifecycle preparation.',
        );
      }
      _blocked(
        canonicalProjectPath,
        'La source "$sourcePath" ne possède plus la révision préparée.',
      );
    }
  }

  Future<void> _checkpoint(
    MapLifecycleTransactionCheckpoint checkpoint,
    MapLifecycleTransactionRecord record,
  ) async {
    await faultInjector?.call(checkpoint, record);
  }

  Never _blocked(String projectPath, String reason) {
    throw ProjectRecoveryBlockedException(
      'La reprise lifecycle World Map refuse de deviner: $reason',
      code: 'mapLifecycleRecoveryBlocked',
      path: gateway.journalPath(projectPath),
    );
  }
}

void _validateLifecycleDelta({
  required MapLifecycleOperation operation,
  required String projectPath,
  required ProjectManifest beforeProject,
  required ProjectManifest afterProject,
  required String? sourcePath,
  required String? targetPath,
  required MapData? targetMap,
}) {
  // Map lifecycle must never become a generic project writer. This equality
  // proves every non-map field is byte-model-equivalent before inspecting the
  // operation-specific maps-list delta.
  if (beforeProject.copyWith(maps: afterProject.maps) != afterProject) {
    throw const FormatException(
      'Map lifecycle may change the manifest maps list only.',
    );
  }
  final sourceRelativePath = sourcePath == null
      ? null
      : _projectRelativeMapPath(projectPath, sourcePath);
  final targetRelativePath = targetPath == null
      ? null
      : _projectRelativeMapPath(projectPath, targetPath);

  switch (operation) {
    case MapLifecycleOperation.create:
    case MapLifecycleOperation.duplicate:
      if (afterProject.maps.length != beforeProject.maps.length + 1 ||
          !_sameEntries(
            beforeProject.maps,
            afterProject.maps.take(beforeProject.maps.length).toList(),
          )) {
        throw const FormatException(
          'Create/duplicate must append exactly one map entry.',
        );
      }
      _requireTargetEntry(
        afterProject.maps.last,
        targetMap: targetMap!,
        targetRelativePath: targetRelativePath!,
      );
      if (operation == MapLifecycleOperation.duplicate) {
        _requireUniqueSourceEntry(
          beforeProject.maps,
          sourceRelativePath!,
        );
      }
      break;
    case MapLifecycleOperation.rename:
      if (afterProject.maps.length != beforeProject.maps.length) {
        throw const FormatException(
          'Rename must preserve the number of map entries.',
        );
      }
      final sourceIndex = _requireUniqueSourceEntry(
        beforeProject.maps,
        sourceRelativePath!,
      );
      for (var index = 0; index < beforeProject.maps.length; index += 1) {
        if (index == sourceIndex) continue;
        if (beforeProject.maps[index] != afterProject.maps[index]) {
          throw const FormatException(
            'Rename changed an unrelated map entry.',
          );
        }
      }
      final expectedRenamedEntry = beforeProject.maps[sourceIndex].copyWith(
        id: targetMap!.id,
        name: targetMap.name,
        relativePath: targetRelativePath!,
      );
      if (afterProject.maps[sourceIndex] != expectedRenamedEntry) {
        throw const FormatException(
          'Rename target entry does not match the journaled map.',
        );
      }
      break;
    case MapLifecycleOperation.delete:
      final sourceIndex = _requireUniqueSourceEntry(
        beforeProject.maps,
        sourceRelativePath!,
      );
      final expectedMaps = <ProjectMapEntry>[
        ...beforeProject.maps.take(sourceIndex),
        ...beforeProject.maps.skip(sourceIndex + 1),
      ];
      if (!_sameEntries(afterProject.maps, expectedMaps)) {
        throw const FormatException(
          'Delete must remove exactly its journaled source entry.',
        );
      }
      break;
  }
}

String _projectRelativeMapPath(String projectPath, String mapPath) {
  final projectRoot = p.dirname(p.normalize(p.absolute(projectPath)));
  final relative = p.relative(
    p.normalize(p.absolute(mapPath)),
    from: projectRoot,
  );
  final posixRelative = p.split(relative).join('/');
  if (posixRelative == '..' || posixRelative.startsWith('../')) {
    throw const FormatException(
      'Map lifecycle path is outside the journaled project.',
    );
  }
  return p.posix.normalize(posixRelative);
}

int _requireUniqueSourceEntry(
  List<ProjectMapEntry> entries,
  String sourceRelativePath,
) {
  final matches = <int>[];
  for (var index = 0; index < entries.length; index += 1) {
    if (p.posix.normalize(entries[index].relativePath) == sourceRelativePath) {
      matches.add(index);
    }
  }
  if (matches.length != 1) {
    throw const FormatException(
      'Lifecycle source path must own exactly one manifest entry.',
    );
  }
  return matches.single;
}

void _requireTargetEntry(
  ProjectMapEntry entry, {
  required MapData targetMap,
  required String targetRelativePath,
}) {
  if (entry.id != targetMap.id ||
      entry.name != targetMap.name ||
      p.posix.normalize(entry.relativePath) != targetRelativePath) {
    throw const FormatException(
      'Lifecycle target entry does not match the journaled map.',
    );
  }
}

bool _sameEntries(
  Iterable<ProjectMapEntry> left,
  Iterable<ProjectMapEntry> right,
) {
  final leftList = left.toList(growable: false);
  final rightList = right.toList(growable: false);
  if (leftList.length != rightList.length) return false;
  for (var index = 0; index < leftList.length; index += 1) {
    if (leftList[index] != rightList[index]) return false;
  }
  return true;
}

void _requireProjectMapPaths(
  String projectPath,
  String? sourcePath,
  String? targetPath,
) {
  final projectRoot = p.normalize(p.dirname(p.absolute(projectPath)));
  final mapsRoot = p.normalize(p.join(projectRoot, 'maps'));
  for (final candidate in <String?>[sourcePath, targetPath]) {
    if (candidate == null) continue;
    final normalized = p.normalize(p.absolute(candidate));
    if (!p.isWithin(mapsRoot, normalized) ||
        p.extension(normalized).toLowerCase() != '.json') {
      throw EditorValidationException(
        'Map lifecycle path must stay inside the project maps directory: '
        '$candidate',
      );
    }
  }
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? source,
  String field,
) {
  if (source is! String) {
    throw FormatException('$field must be a string.');
  }
  for (final value in values) {
    if (value.name == source) return value;
  }
  throw FormatException('Unknown $field "$source".');
}

Map<String, dynamic> _jsonObject(Object? source, String field) {
  if (source is! Map) {
    throw FormatException('$field must be a JSON object.');
  }
  final result = <String, dynamic>{};
  for (final entry in source.entries) {
    if (entry.key is! String) {
      throw FormatException('$field contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _requiredString(Object? source, String field) {
  if (source is! String || source.trim().isEmpty || source != source.trim()) {
    throw FormatException('$field must be a non-empty trimmed string.');
  }
  return source;
}

String? _optionalString(Object? source, String field) {
  if (source == null) return null;
  return _requiredString(source, field);
}
~~~~
### `packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart`

~~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/models/narrative_authoring_transaction.dart';
import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/services/map_lifecycle_transaction_service.dart';
import '../../domain/models/map_document_persistence.dart';
import '../../domain/repositories/repositories.dart';
import 'atomic_project_manifest_persistence.dart';

final _lifecycleWriteQueues = <String, Future<void>>{};

/// Filesystem adapter for the DS-05 recoverable lifecycle protocol.
///
/// The journal is a write-ahead intent under `.pokemap/recovery`. Each rewrite
/// is flushed and renamed on one filesystem. Map and project files still commit
/// separately through their own CAS writers; the journal makes that sequence
/// recoverable and intentionally does not advertise multi-file atomicity.
final class MapLifecycleTransactionFileGateway
    implements MapLifecycleTransactionGateway {
  MapLifecycleTransactionFileGateway({
    required RevisionedMapRepository mapRepository,
    AtomicProjectManifestPersistence? projectPersistence,
  })  : _mapRepository = mapRepository,
        _projectPersistence =
            projectPersistence ?? const AtomicProjectManifestPersistence();

  final RevisionedMapRepository _mapRepository;
  final AtomicProjectManifestPersistence _projectPersistence;

  @override
  Future<T> synchronized<T>(
    String projectPath,
    Future<T> Function(String canonicalProjectPath) action,
  ) async {
    final requestedPath = p.normalize(p.absolute(projectPath));
    final projectFile = File(requestedPath);
    final lockIdentity = p.normalize(
      await projectFile.exists()
          ? await projectFile.resolveSymbolicLinks()
          : requestedPath,
    );
    final previous =
        _lifecycleWriteQueues[lockIdentity] ?? Future<void>.value();
    final turn = Completer<void>();
    final tail = previous.then((_) => turn.future);
    _lifecycleWriteQueues[lockIdentity] = tail;
    await previous;

    RandomAccessFile? handle;
    var locked = false;
    try {
      final lockPath = _lockPath(requestedPath);
      await _requireRegularOrMissing(
        lockPath,
        label: 'Map lifecycle lock',
      );
      final lockFile = File(lockPath);
      await lockFile.parent.create(recursive: true);
      handle = await lockFile.open(mode: FileMode.append);
      await handle.lock(FileLock.exclusive);
      locked = true;
      return await action(requestedPath);
    } finally {
      if (handle != null) {
        if (locked) await handle.unlock();
        await handle.close();
      }
      turn.complete();
      if (identical(_lifecycleWriteQueues[lockIdentity], tail)) {
        _lifecycleWriteQueues.remove(lockIdentity);
      }
    }
  }

  @override
  String journalPath(String canonicalProjectPath) {
    return p.join(
      p.dirname(p.normalize(p.absolute(canonicalProjectPath))),
      '.pokemap',
      'recovery',
      'world-map-lifecycle.json',
    );
  }

  String journalRewritePath(String canonicalProjectPath) {
    return '${journalPath(canonicalProjectPath)}.rewrite.tmp';
  }

  String _lockPath(String canonicalProjectPath) {
    return p.join(
      p.dirname(p.normalize(p.absolute(canonicalProjectPath))),
      '.pokemap',
      'recovery',
      'world-map-lifecycle.lock',
    );
  }

  @override
  Future<MapLifecycleTransactionRecord?> readJournal(
    String canonicalProjectPath,
  ) async {
    final stablePath = journalPath(canonicalProjectPath);
    final rewritePath = journalRewritePath(canonicalProjectPath);
    await _requireRegularOrMissing(
      stablePath,
      label: 'Map lifecycle journal',
    );
    await _requireRegularOrMissing(
      rewritePath,
      label: 'Map lifecycle journal rewrite',
    );
    final stable = File(stablePath);
    final rewrite = File(rewritePath);
    if (!await stable.exists()) {
      // A rewrite without the renamed stable intent never authorized any map
      // or manifest mutation and is safe to discard deterministically.
      if (await rewrite.exists()) await rewrite.delete();
      return null;
    }
    if (await rewrite.exists()) await rewrite.delete();
    final decoded = jsonDecode(await stable.readAsString());
    if (decoded is! Map) {
      throw const FormatException(
        'Map lifecycle journal root must be a JSON object.',
      );
    }
    return MapLifecycleTransactionRecord.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  @override
  Future<void> writeJournal(
    String canonicalProjectPath,
    MapLifecycleTransactionRecord record,
  ) async {
    final stablePath = journalPath(canonicalProjectPath);
    final rewritePath = journalRewritePath(canonicalProjectPath);
    await _requireRegularOrMissing(
      stablePath,
      label: 'Map lifecycle journal',
    );
    await _requireRegularOrMissing(
      rewritePath,
      label: 'Map lifecycle journal rewrite',
    );
    final stable = File(stablePath);
    final rewrite = File(rewritePath);
    await stable.parent.create(recursive: true);
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(record.toJson()),
    );
    await _writeFlushed(rewrite, bytes);
    final rewriteRevision = narrativeEventBytesFingerprint(
      await rewrite.readAsBytes(),
    );
    final expectedRevision = narrativeEventBytesFingerprint(bytes);
    if (rewriteRevision != expectedRevision) {
      throw const EditorPersistenceException(
        'The flushed map lifecycle journal cannot be verified.',
      );
    }
    await rewrite.rename(stable.path);
    final stableRevision = narrativeEventBytesFingerprint(
      await stable.readAsBytes(),
    );
    if (stableRevision != expectedRevision) {
      throw const EditorPersistenceException(
        'The durable map lifecycle journal cannot be verified.',
      );
    }
  }

  @override
  Future<void> clearJournal(String canonicalProjectPath) async {
    final stablePath = journalPath(canonicalProjectPath);
    final rewritePath = journalRewritePath(canonicalProjectPath);
    await _requireRegularOrMissing(
      stablePath,
      label: 'Map lifecycle journal',
    );
    await _requireRegularOrMissing(
      rewritePath,
      label: 'Map lifecycle journal rewrite',
    );
    final stable = File(stablePath);
    final rewrite = File(rewritePath);
    if (await rewrite.exists()) await rewrite.delete();
    if (await stable.exists()) await stable.delete();
  }

  @override
  Future<MapLifecycleProjectSnapshot> readProject(
    String canonicalProjectPath,
  ) async {
    final file = File(canonicalProjectPath);
    if (!await file.exists()) {
      throw const EditorNotFoundException(
        'The project manifest required by map lifecycle recovery is missing.',
      );
    }
    final bytes = await file.readAsBytes();
    return MapLifecycleProjectSnapshot(
      project: decodeValidatedNarrativeEventAuthoringProject(bytes).manifest,
      revision: narrativeEventBytesFingerprint(bytes),
    );
  }

  @override
  Future<MapLifecycleProjectSnapshot> writeProject(
    String canonicalProjectPath, {
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
    required String expectedRevision,
  }) async {
    final result = await _projectPersistence.persistProjectDocument(
      projectPath: canonicalProjectPath,
      operationId: operationId,
      before: before,
      after: after,
      expectedRevision: expectedRevision,
    );
    switch (result.status) {
      case NarrativeAuthoringPersistenceStatus.committed:
        final durable = await readProject(canonicalProjectPath);
        if (durable.project != after) {
          throw const EditorPersistenceException(
            'The durable project does not match the lifecycle transaction.',
          );
        }
        return durable;
      case NarrativeAuthoringPersistenceStatus.persistenceFailed:
        if (_isProjectConflictCode(result.code)) {
          throw EditorConflictException(result.message);
        }
        throw EditorPersistenceException(result.message);
      case NarrativeAuthoringPersistenceStatus.recoveryRequired:
        throw ProjectRecoveryRequiredException(
          result.message,
          code: result.code,
          path: canonicalProjectPath,
        );
    }
  }

  @override
  Future<RevisionedMapDocument?> readMap(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw EditorConflictException(
        'Map lifecycle refuses a non-regular map document: $path',
      );
    }
    return _mapRepository.loadMapDocument(path);
  }

  @override
  Future<RevisionedMapDocument> writeMap(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
  }) {
    return _mapRepository.saveMapDocument(
      map,
      path,
      precondition: precondition,
    );
  }

  @override
  Future<void> deleteMap(
    String path, {
    required String expectedRevision,
  }) {
    return _mapRepository.deleteMapDocument(
      path,
      expectedRevision: expectedRevision,
    );
  }
}

bool _isProjectConflictCode(String code) {
  return code == 'staleProjectRevision' || code == 'projectChangedBeforeCommit';
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

Future<void> _requireRegularOrMissing(
  String path, {
  required String label,
}) async {
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.notFound ||
      type == FileSystemEntityType.file) {
    return;
  }
  throw EditorConflictException('$label is not a regular file: $path');
}
~~~~

### `packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart`

~~~~dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';

void main() {
  group('MapLifecycleTransactionCoordinator', () {
    test('create commits the target and manifest before clearing its journal',
        () async {
      final fixture = _Fixture();
      final request = fixture.createRequest();

      final result = await fixture.coordinator.execute(request);

      expect(result.project, fixture.afterCreate);
      expect(result.targetMap, fixture.target);
      expect(
        result.targetRevision,
        mapDocumentRevisionFor(fixture.target),
      );
      expect(fixture.gateway.project, fixture.afterCreate);
      expect(fixture.gateway.maps[_Fixture.targetPath]!.map, fixture.target);
      expect(fixture.gateway.journal, isNull);
      expect(
        fixture.gateway.writtenStatuses,
        <MapLifecycleTransactionStatus>[
          MapLifecycleTransactionStatus.prepared,
          MapLifecycleTransactionStatus.targetWritten,
          MapLifecycleTransactionStatus.projectWritten,
          MapLifecycleTransactionStatus.committed,
        ],
      );
    });

    test('prepared create rolls forward after a process restart', () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );

      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(fixture.gateway.maps, isEmpty);
      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.journal, isNotNull);

      final recovered =
          await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
        _Fixture.projectPath,
      );

      expect(recovered.status, MapLifecycleRecoveryStatus.recovered);
      expect(fixture.gateway.project, fixture.afterCreate);
      expect(fixture.gateway.maps[_Fixture.targetPath]!.map, fixture.target);
      expect(fixture.gateway.journal, isNull);
      expect(
        (await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ))
            .status,
        MapLifecycleRecoveryStatus.clear,
      );
    });

    test('rename recovery finishes source cleanup after manifest commit',
        () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterProjectWritten,
      )..seedSource();

      await expectLater(
        fixture.coordinator.execute(fixture.renameRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(fixture.gateway.project, fixture.afterRename);
      expect(fixture.gateway.maps, contains(_Fixture.sourcePath));
      expect(fixture.gateway.maps, contains(_Fixture.targetPath));

      await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
        _Fixture.projectPath,
      );

      expect(fixture.gateway.project, fixture.afterRename);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.sourcePath)));
      expect(fixture.gateway.maps[_Fixture.targetPath]!.map, fixture.target);
      expect(fixture.gateway.journal, isNull);
    });

    test('delete recovery removes the exact source after manifest commit',
        () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterProjectWritten,
      )..seedSource();

      await expectLater(
        fixture.coordinator.execute(fixture.deleteRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(fixture.gateway.project, fixture.afterDelete);
      expect(fixture.gateway.maps, contains(_Fixture.sourcePath));

      await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
        _Fixture.projectPath,
      );

      expect(fixture.gateway.project, fixture.afterDelete);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.sourcePath)));
      expect(fixture.gateway.journal, isNull);
    });

    test('recovery blocks and preserves evidence after project divergence',
        () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      fixture.gateway.setProject(
        fixture.before.copyWith(name: 'External project edit'),
      );

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(fixture.gateway.maps, isEmpty);
      expect(fixture.gateway.journal, isNotNull);
    });

    test('recovery blocks when a rename source revision changed', () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      )..seedSource();
      await expectLater(
        fixture.coordinator.execute(fixture.renameRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      fixture.gateway.seedMap(
        _Fixture.sourcePath,
        fixture.source.copyWith(name: 'External map edit'),
      );

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.targetPath)));
      expect(fixture.gateway.journal, isNotNull);
    });

    test('stale source before prepare is a conflict without recovery evidence',
        () async {
      final fixture = _Fixture()..seedSource();
      final request = fixture.renameRequest();
      fixture.gateway.seedMap(
        _Fixture.sourcePath,
        fixture.source.copyWith(name: 'External edit before prepare'),
      );

      await expectLater(
        fixture.coordinator.execute(request),
        throwsA(isA<EditorConflictException>()),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.targetPath)));
      expect(fixture.gateway.journal, isNull);
    });

    test('recovery blocks instead of overwriting a target collision', () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      fixture.gateway.seedMap(_Fixture.targetPath, _map('foreign'));

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(fixture.gateway.maps[_Fixture.targetPath]!.map.id, 'foreign');
      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.journal, isNotNull);
    });

    test('exact project revision is revalidated even for the same model',
        () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      fixture.gateway.projectRevision = _revision('unknown-root-edit');

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, isEmpty);
      expect(fixture.gateway.journal, isNotNull);
    });

    test('committed evidence is idempotently cleared after restart', () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.beforeJournalCleared,
      );

      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(
        fixture.gateway.journal!.status,
        MapLifecycleTransactionStatus.committed,
      );
      expect(fixture.gateway.project, fixture.afterCreate);

      final recovered =
          await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
        _Fixture.projectPath,
      );

      expect(recovered.status, MapLifecycleRecoveryStatus.recovered);
      expect(fixture.gateway.project, fixture.afterCreate);
      expect(fixture.gateway.maps[_Fixture.targetPath]!.map, fixture.target);
      expect(fixture.gateway.journal, isNull);
    });

    test('request cannot smuggle unrelated project changes into create',
        () async {
      final fixture = _Fixture();
      final request = MapLifecycleTransactionRequest.create(
        projectPath: _Fixture.projectPath,
        beforeProject: fixture.before,
        afterProject: fixture.afterCreate.copyWith(name: 'Unrelated edit'),
        targetPath: _Fixture.targetPath,
        targetMap: fixture.target,
      );

      await expectLater(
        fixture.coordinator.execute(request),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, isEmpty);
      expect(fixture.gateway.journal, isNull);
    });

    test('post-journal async failure is reported as recovery required',
        () async {
      final fixture = _Fixture();
      fixture.gateway.writeProjectError = StateError('disk unavailable');

      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(
          isA<ProjectRecoveryRequiredException>().having(
            (error) => error.code,
            'code',
            'mapLifecycleRecoveryRequired',
          ),
        ),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, contains(_Fixture.targetPath));
      expect(fixture.gateway.journal, isNotNull);
    });

    test('journal parser rejects a lifecycle delta that changes other fields',
        () {
      final fixture = _Fixture();
      final record = MapLifecycleTransactionRecord.fromRequest(
        request: fixture.createRequest(),
        canonicalProjectPath: _Fixture.projectPath,
        projectBeforeRevision: fixture.gateway.projectRevision,
      );
      final json = record.toJson()
        ..['afterProject'] =
            fixture.afterCreate.copyWith(name: 'Tampered').toJson();

      expect(
        () => MapLifecycleTransactionRecord.fromJson(json),
        throwsFormatException,
      );
    });
  });
}

final class _Fixture {
  _Fixture({MapLifecycleTransactionCheckpoint? crashAt})
      : gateway = _MemoryGateway(_projectBefore()) {
    coordinator = MapLifecycleTransactionCoordinator(
      gateway,
      faultInjector: crashAt == null
          ? null
          : (checkpoint, _) {
              if (checkpoint == crashAt) {
                throw const MapLifecycleSimulatedCrash();
              }
            },
    );
  }

  static const projectPath = '/project/project.json';
  static const sourcePath = '/project/maps/alpha.json';
  static const targetPath = '/project/maps/beta.json';

  final _MemoryGateway gateway;
  late final MapLifecycleTransactionCoordinator coordinator;

  ProjectManifest get before => _projectBefore();
  ProjectManifest get afterCreate => before.copyWith(
        maps: <ProjectMapEntry>[
          ...before.maps,
          const ProjectMapEntry(
            id: 'beta',
            name: 'beta',
            relativePath: 'maps/beta.json',
          ),
        ],
      );
  ProjectManifest get afterRename => before.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'beta',
            name: 'beta',
            relativePath: 'maps/beta.json',
          ),
        ],
      );
  ProjectManifest get afterDelete => before.copyWith(
        maps: const <ProjectMapEntry>[],
      );
  MapData get source => _map('alpha');
  MapData get target => _map('beta');

  void seedSource() => gateway.seedMap(sourcePath, source);

  MapLifecycleTransactionRequest createRequest() {
    return MapLifecycleTransactionRequest.create(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: afterCreate,
      targetPath: targetPath,
      targetMap: target,
    );
  }

  MapLifecycleTransactionRequest renameRequest() {
    final sourceRevision = gateway.maps[sourcePath]!.revision;
    return MapLifecycleTransactionRequest.rename(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: afterRename,
      sourcePath: sourcePath,
      sourceRevision: sourceRevision,
      targetPath: targetPath,
      targetMap: target,
    );
  }

  MapLifecycleTransactionRequest deleteRequest() {
    final sourceRevision = gateway.maps[sourcePath]!.revision;
    return MapLifecycleTransactionRequest.delete(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: afterDelete,
      sourcePath: sourcePath,
      sourceRevision: sourceRevision,
    );
  }
}

final class _MemoryGateway implements MapLifecycleTransactionGateway {
  _MemoryGateway(this.project)
      : projectRevision = _revision(jsonEncode(project.toJson()));

  ProjectManifest project;
  String projectRevision;
  Object? writeProjectError;
  MapLifecycleTransactionRecord? journal;
  final Map<String, RevisionedMapDocument> maps =
      <String, RevisionedMapDocument>{};
  final List<MapLifecycleTransactionStatus> writtenStatuses =
      <MapLifecycleTransactionStatus>[];

  void setProject(ProjectManifest value) {
    project = value;
    projectRevision = _revision(jsonEncode(value.toJson()));
  }

  void seedMap(String path, MapData map) {
    maps[path] = RevisionedMapDocument(
      map: map,
      revision: mapDocumentRevisionFor(map),
    );
  }

  @override
  Future<T> synchronized<T>(
    String projectPath,
    Future<T> Function(String canonicalProjectPath) action,
  ) {
    return action(projectPath);
  }

  @override
  String journalPath(String canonicalProjectPath) =>
      '$canonicalProjectPath.lifecycle.json';

  @override
  Future<MapLifecycleTransactionRecord?> readJournal(
    String canonicalProjectPath,
  ) async {
    return journal;
  }

  @override
  Future<void> writeJournal(
    String canonicalProjectPath,
    MapLifecycleTransactionRecord record,
  ) async {
    writtenStatuses.add(record.status);
    journal = MapLifecycleTransactionRecord.fromJson(
      jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> clearJournal(String canonicalProjectPath) async {
    journal = null;
  }

  @override
  Future<MapLifecycleProjectSnapshot> readProject(
    String canonicalProjectPath,
  ) async {
    return MapLifecycleProjectSnapshot(
      project: project,
      revision: projectRevision,
    );
  }

  @override
  Future<MapLifecycleProjectSnapshot> writeProject(
    String canonicalProjectPath, {
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
    required String expectedRevision,
  }) async {
    final injectedError = writeProjectError;
    if (injectedError != null) throw injectedError;
    if (projectRevision != expectedRevision || project != before) {
      throw const EditorConflictException('stale project');
    }
    setProject(after);
    return readProject(canonicalProjectPath);
  }

  @override
  Future<RevisionedMapDocument?> readMap(String path) async => maps[path];

  @override
  Future<RevisionedMapDocument> writeMap(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
  }) async {
    final current = maps[path];
    switch (precondition) {
      case MapDocumentMustBeAbsent():
        if (current != null) {
          throw const EditorConflictException('target exists');
        }
      case MapDocumentMustMatchRevision(:final revision):
        if (current?.revision != revision) {
          throw const EditorConflictException('stale map');
        }
    }
    final saved = RevisionedMapDocument(
      map: map,
      revision: mapDocumentRevisionFor(map),
    );
    maps[path] = saved;
    return saved;
  }

  @override
  Future<void> deleteMap(
    String path, {
    required String expectedRevision,
  }) async {
    if (maps[path]?.revision != expectedRevision) {
      throw const EditorConflictException('stale delete');
    }
    maps.remove(path);
  }
}

ProjectManifest _projectBefore() => const ProjectManifest(
      name: 'DS-05',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
    );

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      layers: const <MapLayer>[],
    );

String _revision(String seed) =>
    narrativeEventBytesFingerprint(utf8.encode(seed));
~~~~

### `packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MapLifecycleTransactionFileGateway', () {
    test('commits real files and preserves unknown project root data',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);

      final result = await fixture.coordinator.execute(fixture.createRequest());

      expect(result.project, fixture.after);
      expect(
        (await fixture.mapRepository.loadMapDocument(fixture.targetPath)).map,
        fixture.target,
      );
      expect(
        decodeValidatedNarrativeEventAuthoringProject(
          await fixture.projectFile.readAsBytes(),
        ).manifest,
        fixture.after,
      );
      expect(
        (await fixture.readRoot())['futureRoot'],
        <String, Object?>{'preserved': true},
      );
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('a new gateway instance recovers a crash after target persistence',
        () async {
      final fixture = await _Fixture.create(
        crashAt: MapLifecycleTransactionCheckpoint.afterTargetWritten,
      );
      addTearDown(fixture.dispose);

      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(await File(fixture.targetPath).exists(), isTrue);
      expect(await fixture.readProject(), fixture.before);
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isTrue,
      );

      final restartedGateway = MapLifecycleTransactionFileGateway(
        mapRepository: FileMapRepository(),
      );
      final recovered =
          await MapLifecycleTransactionCoordinator(restartedGateway).recover(
        fixture.projectPath,
      );

      expect(recovered.status, MapLifecycleRecoveryStatus.recovered);
      expect(await fixture.readProject(), fixture.after);
      expect((await FileMapRepository().loadMap(fixture.targetPath)),
          fixture.target);
      expect(
        await File(restartedGateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('project loading recovers a pending map lifecycle first', () async {
      final fixture = await _Fixture.create(
        crashAt: MapLifecycleTransactionCheckpoint.afterTargetWritten,
      );
      addTearDown(fixture.dispose);
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      final recoveryCoordinator = MapLifecycleTransactionCoordinator(
        MapLifecycleTransactionFileGateway(
          mapRepository: FileMapRepository(),
        ),
      );
      final projectRepository = FileProjectRepository(
        mapLifecycleTransactions: recoveryCoordinator,
      );

      final loaded = await projectRepository.loadProject(fixture.projectPath);

      expect(loaded, fixture.after);
      expect(await File(fixture.targetPath).exists(), isTrue);
      expect(
        await File(
          recoveryCoordinator.gateway.journalPath(fixture.projectPath),
        ).exists(),
        isFalse,
      );
    });

    test('generic save queued behind recovery cannot overwrite the map delta',
        () async {
      final fixture = await _Fixture.create(
        crashAt: MapLifecycleTransactionCheckpoint.afterTargetWritten,
      );
      addTearDown(fixture.dispose);
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      final recoveryCoordinator = MapLifecycleTransactionCoordinator(
        MapLifecycleTransactionFileGateway(
          mapRepository: FileMapRepository(),
        ),
      );
      final projectRepository = FileProjectRepository(
        mapLifecycleTransactions: recoveryCoordinator,
      );
      final staleGenericSave = fixture.before.copyWith(name: 'Stale save');

      await expectLater(
        projectRepository.saveProject(staleGenericSave, fixture.projectPath),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await fixture.readProject(), fixture.after);
      expect(await File(fixture.targetPath).exists(), isTrue);
      expect(
        await File(
          recoveryCoordinator.gateway.journalPath(fixture.projectPath),
        ).exists(),
        isFalse,
      );
    });

    test('invalid journal blocks recovery and keeps its evidence', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final journal = File(fixture.gateway.journalPath(fixture.projectPath));
      await journal.parent.create(recursive: true);
      await journal.writeAsString(
        '{"schemaVersion":999,"operation":"create"}',
        flush: true,
      );
      final beforeBytes = await fixture.projectFile.readAsBytes();

      await expectLater(
        fixture.coordinator.recover(fixture.projectPath),
        throwsA(
          isA<ProjectRecoveryBlockedException>().having(
            (error) => error.code,
            'code',
            'mapLifecycleJournalInvalid',
          ),
        ),
      );

      expect(await fixture.projectFile.readAsBytes(), beforeBytes);
      expect(await journal.exists(), isTrue);
      expect(await File(fixture.targetPath).exists(), isFalse);
    });

    test('orphan journal rewrite is discarded without creating an intent',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final rewrite =
          File(fixture.gateway.journalRewritePath(fixture.projectPath));
      await rewrite.parent.create(recursive: true);
      await rewrite.writeAsString('partial', flush: true);

      expect(await fixture.gateway.readJournal(fixture.projectPath), isNull);

      expect(await rewrite.exists(), isFalse);
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('journal paths outside project maps are rejected before durable I/O',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final outsideTarget = p.join(fixture.root.parent.path, 'outside.json');
      final request = MapLifecycleTransactionRequest.create(
        projectPath: fixture.projectPath,
        beforeProject: fixture.before,
        afterProject: fixture.after,
        targetPath: outsideTarget,
        targetMap: fixture.target,
      );

      await expectLater(
        fixture.coordinator.execute(request),
        throwsA(isA<EditorValidationException>()),
      );

      expect(await File(outsideTarget).exists(), isFalse);
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('a symlink journal is blocked instead of following external bytes',
        () async {
      if (Platform.isWindows) return;
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final external = File(p.join(fixture.root.parent.path, 'external.json'));
      await external.writeAsString('external', flush: true);
      addTearDown(() async {
        if (await external.exists()) await external.delete();
      });
      final journalPath = fixture.gateway.journalPath(fixture.projectPath);
      await Directory(p.dirname(journalPath)).create(recursive: true);
      await Link(journalPath).create(external.path);

      await expectLater(
        fixture.coordinator.recover(fixture.projectPath),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(await external.readAsString(), 'external');
      expect(
        await FileSystemEntity.type(journalPath, followLinks: false),
        FileSystemEntityType.link,
      );
    });
  });
}

final class _Fixture {
  _Fixture._({
    required this.root,
    required this.projectFile,
    required this.mapRepository,
    required this.gateway,
    required this.coordinator,
  });

  static Future<_Fixture> create({
    MapLifecycleTransactionCheckpoint? crashAt,
  }) async {
    final root = await Directory.systemTemp.createTemp('pokemap_ds05_');
    final projectFile = File(p.join(root.path, 'project.json'));
    await projectFile.writeAsString(
      const JsonEncoder.withIndent(' ').convert(<String, Object?>{
        ..._before.toJson(),
        'futureRoot': <String, Object?>{'preserved': true},
      }),
      flush: true,
    );
    final mapRepository = FileMapRepository();
    final gateway = MapLifecycleTransactionFileGateway(
      mapRepository: mapRepository,
    );
    final coordinator = MapLifecycleTransactionCoordinator(
      gateway,
      faultInjector: crashAt == null
          ? null
          : (checkpoint, _) {
              if (checkpoint == crashAt) {
                throw const MapLifecycleSimulatedCrash();
              }
            },
    );
    return _Fixture._(
      root: root,
      projectFile: projectFile,
      mapRepository: mapRepository,
      gateway: gateway,
      coordinator: coordinator,
    );
  }

  final Directory root;
  final File projectFile;
  final FileMapRepository mapRepository;
  final MapLifecycleTransactionFileGateway gateway;
  final MapLifecycleTransactionCoordinator coordinator;

  String get projectPath => projectFile.path;
  String get targetPath => p.join(root.path, 'maps', 'beta.json');
  ProjectManifest get before => _before;
  ProjectManifest get after => _after;
  MapData get target => _target;

  MapLifecycleTransactionRequest createRequest() {
    return MapLifecycleTransactionRequest.create(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: after,
      targetPath: targetPath,
      targetMap: target,
    );
  }

  Future<Map<String, dynamic>> readRoot() async {
    return Map<String, dynamic>.from(
      jsonDecode(await projectFile.readAsString()) as Map,
    );
  }

  Future<ProjectManifest> readProject() async {
    return decodeValidatedNarrativeEventAuthoringProject(
      await projectFile.readAsBytes(),
    ).manifest;
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

const _before = ProjectManifest(
  name: 'DS-05',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
);

const _after = ProjectManifest(
  name: 'DS-05',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'beta',
      name: 'Beta',
      relativePath: 'maps/beta.json',
    ),
  ],
  tilesets: <ProjectTilesetEntry>[],
);

const _target = MapData(
  id: 'beta',
  name: 'Beta',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[],
);
~~~~

### `packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/map_dependency_preflight_service.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';
import 'package:path/path.dart' as p;

void main() {
  group('transactional map lifecycle use cases', () {
    test('Create commits map and manifest through the DS-05 coordinator',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.writeProject(_project());

      final created = await CreateMapUseCase(
        fixture.maps,
        fixture.projects,
        lifecycleTransactions: fixture.coordinator,
      ).execute(
        fixture.workspace,
        _project(),
        'harbor',
        3,
        2,
      );

      final durableProject = await fixture.projects.loadProject(
        fixture.workspace.projectManifestPath,
      );
      final durableMap = await fixture.maps.loadMapDocument(
        fixture.workspace.getMapPath('harbor'),
      );
      expect(created.id, 'harbor');
      expect(durableProject.maps.single.id, 'harbor');
      expect(durableMap.map, created);
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('Duplicate journals the exact source revision before writing',
        () async {
      final fixture = await _Fixture.create(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );
      addTearDown(fixture.dispose);
      final project = _project(entries: <ProjectMapEntry>[_entry('alpha')]);
      await fixture.writeProject(project);
      final source = await fixture.seedMap(_map('alpha'));

      await expectLater(
        DuplicateMapUseCase(
          fixture.maps,
          fixture.projects,
          lifecycleTransactions: fixture.coordinator,
        ).execute(fixture.workspace, project, 'alpha'),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );

      final journal = await fixture.gateway.readJournal(fixture.projectPath);
      expect(journal, isNotNull);
      expect(journal!.operation, MapLifecycleOperation.duplicate);
      expect(journal.sourceRevision, source.revision);
      expect(journal.targetMap!.id, 'alpha_copy');
      expect(await File(fixture.workspace.getMapPath('alpha_copy')).exists(),
          isFalse);

      await MapLifecycleTransactionCoordinator(
        MapLifecycleTransactionFileGateway(
          mapRepository: FileMapRepository(),
        ),
      ).recover(fixture.projectPath);
      expect(
        (await fixture.maps.loadMap(fixture.workspace.getMapPath('alpha_copy')))
            .id,
        'alpha_copy',
      );
    });

    test('Rename commits target and manifest before deleting exact source',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final project = _project(entries: <ProjectMapEntry>[_entry('alpha')]);
      await fixture.writeProject(project);
      await fixture.seedMap(_map('alpha'));

      final result = await RenameMapUseCase(
        fixture.maps,
        fixture.projects,
        MapDependencyPreflightService(mapRepository: fixture.maps),
        lifecycleTransactions: fixture.coordinator,
      ).executeRevisioned(
        fixture.workspace,
        project,
        'alpha',
        'beta',
      );

      expect(result.project.maps.single.id, 'beta');
      expect(result.map!.id, 'beta');
      expect(
        result.revision,
        mapDocumentRevisionFor(result.map!),
      );
      expect(await File(fixture.workspace.getMapPath('alpha')).exists(), false);
      expect(await File(fixture.workspace.getMapPath('beta')).exists(), true);
      expect(
        (await fixture.projects.loadProject(fixture.projectPath))
            .maps
            .single
            .id,
        'beta',
      );
    });

    test('Delete commits manifest before deleting the exact source', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final project = _project(entries: <ProjectMapEntry>[_entry('alpha')]);
      await fixture.writeProject(project);
      await fixture.seedMap(_map('alpha'));

      final result = await DeleteMapUseCase(
        fixture.maps,
        fixture.projects,
        MapDependencyPreflightService(mapRepository: fixture.maps),
        lifecycleTransactions: fixture.coordinator,
      ).execute(fixture.workspace, project, 'alpha');

      expect(result.maps, isEmpty);
      expect(await File(fixture.workspace.getMapPath('alpha')).exists(), false);
      expect(
        (await fixture.projects.loadProject(fixture.projectPath)).maps,
        isEmpty,
      );
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        false,
      );
    });
  });
}

final class _Fixture {
  _Fixture._({
    required this.root,
    required this.workspace,
    required this.maps,
    required this.gateway,
    required this.coordinator,
    required this.projects,
  });

  static Future<_Fixture> create({
    MapLifecycleTransactionCheckpoint? crashAt,
  }) async {
    final root = await Directory.systemTemp.createTemp('pokemap_ds05_uc_');
    final workspace = ProjectFileSystem(root.path);
    final maps = FileMapRepository();
    final gateway = MapLifecycleTransactionFileGateway(mapRepository: maps);
    final coordinator = MapLifecycleTransactionCoordinator(
      gateway,
      faultInjector: crashAt == null
          ? null
          : (checkpoint, _) {
              if (checkpoint == crashAt) {
                throw const MapLifecycleSimulatedCrash();
              }
            },
    );
    final projects = FileProjectRepository(
      mapLifecycleTransactions: coordinator,
    );
    return _Fixture._(
      root: root,
      workspace: workspace,
      maps: maps,
      gateway: gateway,
      coordinator: coordinator,
      projects: projects,
    );
  }

  final Directory root;
  final ProjectFileSystem workspace;
  final FileMapRepository maps;
  final MapLifecycleTransactionFileGateway gateway;
  final MapLifecycleTransactionCoordinator coordinator;
  final FileProjectRepository projects;

  String get projectPath => workspace.projectManifestPath;

  Future<void> writeProject(ProjectManifest project) async {
    await File(projectPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
      flush: true,
    );
  }

  Future<RevisionedMapDocument> seedMap(MapData map) {
    return maps.saveMapDocument(
      map,
      p.join(root.path, 'maps', '${map.id}.json'),
      precondition: const MapDocumentWritePrecondition.absent(),
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

ProjectManifest _project({
  List<ProjectMapEntry> entries = const <ProjectMapEntry>[],
}) {
  return ProjectManifest(
    name: 'DS-05',
    maps: entries,
    tilesets: const <ProjectTilesetEntry>[],
  );
}

ProjectMapEntry _entry(String id) => ProjectMapEntry(
      id: id,
      name: id,
      relativePath: 'maps/$id.json',
    );

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      layers: const <MapLayer>[],
    );
~~~~

### `packages/map_editor/test/app/providers/map_lifecycle_provider_wiring_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/editor/map_use_case_providers.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  test('product Create provider injects DS-05 instead of legacy compensation',
      () async {
    final root =
        await Directory.systemTemp.createTemp('pokemap_ds05_provider_');
    addTearDown(() => root.delete(recursive: true));
    final workspace = ProjectFileSystem(root.path);
    const project = ProjectManifest(
      name: 'DS-05 provider',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );
    await File(workspace.projectManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
      flush: true,
    );
    final throwingProjects = _ThrowingProjectRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        mapRepositoryProvider.overrideWithValue(FileMapRepository()),
        projectRepositoryProvider.overrideWithValue(throwingProjects),
      ],
    );
    addTearDown(container.dispose);

    await container.read(createMapUseCaseProvider).execute(
          workspace,
          project,
          'harbor',
          2,
          2,
        );

    expect(throwingProjects.saveCalls, 0);
    expect(
      (await FileProjectRepository().loadProject(
        workspace.projectManifestPath,
      ))
          .maps
          .single
          .id,
      'harbor',
    );
    expect(await File(workspace.getMapPath('harbor')).exists(), isTrue);
  });
}

final class _ThrowingProjectRepository implements ProjectRepository {
  int saveCalls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saveCalls += 1;
    throw StateError('legacy project repository must not be called');
  }
}
~~~~
