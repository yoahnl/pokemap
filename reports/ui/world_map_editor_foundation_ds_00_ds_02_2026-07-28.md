# WM-FOUNDATION-DS-00-DS-02 — Evidence Pack et recommandation

Date : 28 juillet 2026
Périmètre : `packages/map_editor`
Source d’audit : [world_map_editor_ultra_complete_audit.md](world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md)
Plan exécuté : [2026-07-28-world-map-foundation-ds-00-ds-02.md](../../docs/superpowers/plans/2026-07-28-world-map-foundation-ds-00-ds-02.md)

## 1. Verdict et conseil

Verdict du lot :

| Sous-lot | Statut | Verdict |
|---|---:|---|
| DS-00 — caractérisation lifecycle | **PARTIAL** | Couverture forte des IDs, chemins, activations dirty, concurrence et plusieurs pannes, mais pas encore de matrice exhaustive de chaque checkpoint I/O, des changements externes et de toutes les références. |
| DS-01 — IDs et chemins confinés | **PASS** | Contrat canonique, conflits case-insensitifs, intégrité globale du manifeste, chemin autoritatif, confinement lexical/réel et symlinks couverts. |
| DS-02 — activation centralisée | **PASS** | Gateway unique, Save/Abandonner/Annuler, activations map/projet, single-flight, baselines anti-stale, leases et Border couverts. |
| Gate 0 globale | **PARTIAL** | DS-03, DS-04 et DS-05 restent nécessaires avant toute déclaration « data-safe » ou « prête à livrer ». |

**Conseil : ne pas lancer une refonte UI big-bang maintenant.** Le bon prochain lot est
**DS-03 — Document Store atomique, révisionné et protégé par CAS**. Il faut ensuite
fermer DS-04 (références entrantes) et DS-05 (transactions lifecycle). À ce moment-là,
les lots ergonomiques peuvent être livrés par tranches, dans cet ordre :

1. pile de rendu canonique et parité éditeur/runtime (le problème d’ordre des layers) ;
2. machine d’interaction exclusive et navigation desktop/Magic Mouse ;
3. gomme indépendante du dernier brush ;
4. sélection, hit-test et déplacement transactionnel ;
5. catalogue d’assets filtré et mémoire de tileset par layer ;
6. recomposition canvas-first du shell et de l’inspecteur.

On peut prototyper les interactions dès maintenant, mais il est déconseillé de faire
migrer ou réécrire massivement les données avant DS-03/04/05. Le présent patch est
**prêt pour review sur son périmètre DS-01/02**, pas pour déclarer la fondation complète
ni l’éditeur ergonomiquement refondu.

## 2. Audit initial conservé

L’audit initial a rendu : **FAIL produit / PARTIAL technique / refonte profonde
justifiée**. Les symptômes utilisateur ont tous été reliés à des causes structurelles :

- la pile de layers affichée n’est pas la pile effectivement peinte ;
- la gomme réutilise l’empreinte du dernier brush ;
- la sélection ne permet pas de déplacer normalement un élément placé ;
- la palette mélange terrains, paths, characters et autres assets sans contexte ;
- le tileset actif est mémorisé globalement au lieu de l’être par layer ;
- le routeur de gestes arbitre mal navigation, scroll et peinture ;
- l’architecture d’information expose l’historique des features plutôt que les tâches.

L’audit a également préservé les contrats utiles déjà présents : frontières
`map_core`/`map_editor`/`map_runtime`, modèles sérialisables, design system PokeMap,
use cases/Riverpod, undo/redo par stroke, previews, rejet des mélanges de source,
toasts centralisés et contrôleurs Border/Environment. Cinematic Studio fournit déjà
la référence interne pour `PointerPanZoom`, pinch trackpad, pan non-mutant, zoom,
sélection/déplacement, snap et annulation clavier. Ces acquis doivent être réutilisés,
pas réécrits.

Les 22 findings, captures, preuves et gates de refonte sont conservés dans l’artefact
d’audit séparé. Ce fichier provient de la tâche d’audit précédente et n’est pas
reproduit ici ; le présent rapport reproduit intégralement tous les nouveaux fichiers
du lot DS-00→DS-02.

## 3. Objectif, décisions et non-objectifs

Objectif : empêcher que la future refonte ergonomique amplifie des corruptions ou des
pertes de travail. Le lot introduit donc un contrat d’identité/path strict et un
gateway d’activation commun avant de toucher au shell visuel.

Décisions :

- les IDs nouvellement authorés sont des identifiants ASCII minuscules bornés ;
- les anciens IDs invalides restent diagnostiqués et protégés, sans migration silencieuse ;
- le `relativePath` du manifeste est autoritatif ;
- l’intégrité du manifeste est globale avant les frontières d’écriture durables ;
- une activation dirty demande explicitement Save, Abandonner ou Annuler ;
- une décision est liée à la cible, au projet, à la map active et au source path ;
- la baseline est revalidée synchroniquement avant lease et après chaque await pertinent ;
- les écritures directes connues passent par les mêmes leases/interlocks ;
- les dialogues utilisent le design system PokeMap.

Non-objectifs assumés :

- pas d’écriture finale atomique, de révision, de CAS ou de détection de modification externe ;
- pas d’index exhaustif de références entrantes ;
- pas de transaction crash-safe pour create/duplicate/rename/delete ;
- pas de resize impact plan ;
- pas de correction de rendu, gomme, déplacement, palette ou shell dans ce lot ;
- aucune opération Git d’écriture.

## 4. Ce qui a été implémenté

### DS-01

- Grammaire : minuscules ASCII, chiffres, `_`/`-`, extrémités alphanumériques,
  maximum 64 caractères ; noms de périphériques Windows rejetés.
- Détection de conflits et génération de copies case-insensitives.
- Diagnostic des IDs legacy et chemin de renommage explicite vers un ID canonique.
- Vérification globale : IDs uniques, chemins uniques, paths sûrs, un propriétaire par
  fichier, et exception étroite pour la source legacy d’une migration explicite.
- Rejet avant I/O des traversals, chemins absolus POSIX/Windows, backslashes,
  extensions/répertoires non conformes, symlink du dossier maps et alias internes.
- Create/Rename/Delete/Duplicate préflightés ; `relativePath` autoritatif ; cohérence
  entre entrée de manifeste et `MapData.id` persisté.
- Warp source/cible et écriture réciproque validés.
- Mode protégé explicite si l’état legacy/manifeste n’est pas sûr.
- Cache de diagnostic côté authoring pour éviter un scan filesystem par sample de paint,
  avec revalidation aux frontières durables.

### DS-02

- Coordinateur pur `Save / Discard / Cancel`.
- Gateway canonique map et projet, y compris création/ouverture de projet.
- Décisions liées à la cible, au projet, à la map active, au source path et à la baseline.
- Revalidation synchrone immédiatement avant la lease, plus revalidation après les awaits.
- Single-flight : une seconde activation map/projet renvoie busy pendant le chargement.
- Chargement temporaire et adoption seulement après validation de la cible et de son ID.
- Même map sans décision : no-op sans I/O.
- Border preview : lifecycle, cleanup/reload, Event writer, tileset assignment et warp
  réciproque sont bloqués ; les callbacks capturés revalident au moment de l’appel.
- Les routes interactives connues utilisent le guard partagé.
- Le bridge Event revalide session/epoch après activation, réussite comme échec.

## 5. Inventaire exact du lot

### Fichiers créés

| Fichier | Lignes | SHA-256 |
|---|---:|---|
| `docs/superpowers/plans/2026-07-28-world-map-foundation-ds-00-ds-02.md` | 526 | `9f99b9d9b400091e555fa71a3d39225e58bcc8a2e7c1e623f7e47633e5be484d` |
| `packages/map_editor/lib/src/application/services/project_map_id_policy.dart` | 137 | `7f108a281d0c2c1a2bccdea0b4efccbff694b3936137532126a425c88182feb7` |
| `packages/map_editor/lib/src/application/services/project_map_manifest_integrity_policy.dart` | 90 | `60cab3d6019797a228a9c29de50057c6117cefaa2b8d0fa1dc99ff768285d0be` |
| `packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart` | 49 | `8a65f7b787653703ee6c4803d9a252f9e763fe27f1e79c26e9a26b9a21b97a3b` |
| `packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart` | 184 | `285d1606a499a19d596395cb08d99deb12f6cb7eb29ea285c69d815c931a7dcf` |
| `packages/map_editor/test/application/services/project_map_id_policy_test.dart` | 143 | `45f035fbbdd06ddddbe69f5ca7c847024cecdc0f22f9be469c161f489c7eb80b` |
| `packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart` | 165 | `917d4e816cf68e5651d3df76fae90e405a7b486bd64b8be27ad787c25dca80d1` |
| `packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart` | 1058 | `d33cc9efac9d7dddd6794972eec9971768d9b5ca063ead6728c7edd6df3a3dfb` |
| `packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart` | 66 | `6ad6a2667d23a6fdbcebd8344f8df53bc5f55bf15d50ffbd408b0311931efc5e` |
| `packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart` | 1237 | `341f0a6cc9445663678c891cd01851f6b4d8c36db8a1b07418d7ceeb5ca91ee2` |
| `packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart` | 207 | `fdd97adc4edafa660109ec4f7a189433c3a560cdc0e440042a8838afdebf0894` |

Le rapport courant est également créé par ce lot mais n’est évidemment pas reproduit
à l’intérieur de lui-même.

### Fichiers suivis modifiés et zones

| Fichier | Modification | Hunks Git exacts |
|---|---|---|
| `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart` | préflight global du manifeste, IDs/chemins autoritatifs, lifecycle create/rename/delete/duplicate, compensations best-effort | `@@ -1,0 +2 @@ import 'package:map_core/map_core.dart'; @@ -5,0 +7,2 @@ import '../ports/project_workspace.dart'; @@ -7,0 +11,4 @@ import 'project_use_case_support.dart'; @@ -17,0 +25 @@ class SaveMapUseCase { @@ -35,5 +43,10 @@ class CreateMapUseCase { @@ -43,2 +56,2 @@ class CreateMapUseCase { @@ -71 +84 @@ class CreateMapUseCase { @@ -72,0 +86,5 @@ class CreateMapUseCase { @@ -80,2 +98,2 @@ class CreateMapUseCase { @@ -88 +106,11 @@ class CreateMapUseCase { @@ -168,2 +196,19 @@ class RenameMapUseCase { @@ -171 +216,5 @@ class RenameMapUseCase { @@ -173 +222,11 @@ class RenameMapUseCase { @@ -175 +234,2 @@ class RenameMapUseCase { @@ -178,4 +237,0 @@ class RenameMapUseCase { @@ -183 +239,5 @@ class RenameMapUseCase { @@ -186,0 +247,12 @@ class RenameMapUseCase { @@ -188,9 +259,0 @@ class RenameMapUseCase { @@ -198,3 +261,5 @@ class RenameMapUseCase { @@ -202,4 +266,0 @@ class RenameMapUseCase { @@ -207,0 +269,4 @@ class RenameMapUseCase { @@ -219,2 +284,6 @@ class DeleteMapUseCase { @@ -225,0 +295 @@ class DeleteMapUseCase { @@ -239,6 +309,11 @@ class DuplicateMapUseCase { @@ -246,2 +321 @@ class DuplicateMapUseCase { @@ -248,0 +323,6 @@ class DuplicateMapUseCase { @@ -250,0 +331 @@ class DuplicateMapUseCase { @@ -254,2 +334,0 @@ class DuplicateMapUseCase { @@ -266 +345,10 @@ class DuplicateMapUseCase { @@ -270,0 +359,42 @@ class DuplicateMapUseCase {` |
| `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart` | validation source/cible et cohérence ID persisté avant écriture réciproque | `@@ -5,0 +6 @@ import '../ports/project_workspace.dart'; @@ -96,0 +98,2 @@ class CreateReciprocalWarpUseCase { @@ -105,4 +108,5 @@ class CreateReciprocalWarpUseCase { @@ -119,0 +124,7 @@ class CreateReciprocalWarpUseCase {` |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | gateway canonique d’activation map/projet, handshake dirty, leases, baselines anti-stale, mode protégé et interlocks Border | `@@ -50,0 +51,2 @@ import '../../../application/services/placed_element_instance_indexer.dart'; @@ -57,0 +60 @@ import '../application/editor_workspace_controller.dart'; @@ -99,0 +103,25 @@ typedef _MapDiskMutationLease = ({ @@ -121,0 +150,21 @@ BorderPreviewContext? _borderPreviewContext(EditorState state) { @@ -123,0 +173,6 @@ class EditorNotifier extends _$EditorNotifier { @@ -128,0 +184,5 @@ class EditorNotifier extends _$EditorNotifier { @@ -344,0 +405,27 @@ class EditorNotifier extends _$EditorNotifier { @@ -345,0 +433,2 @@ class EditorNotifier extends _$EditorNotifier { @@ -348,0 +438,3 @@ class EditorNotifier extends _$EditorNotifier { @@ -363,0 +456 @@ class EditorNotifier extends _$EditorNotifier { @@ -367,0 +461,3 @@ class EditorNotifier extends _$EditorNotifier { @@ -375,0 +472,24 @@ class EditorNotifier extends _$EditorNotifier { @@ -377,0 +498,18 @@ class EditorNotifier extends _$EditorNotifier { @@ -381 +519 @@ class EditorNotifier extends _$EditorNotifier { @@ -386 +524 @@ class EditorNotifier extends _$EditorNotifier { @@ -389 +527 @@ class EditorNotifier extends _$EditorNotifier { @@ -401 +539,3 @@ class EditorNotifier extends _$EditorNotifier { @@ -402,0 +543,14 @@ class EditorNotifier extends _$EditorNotifier { @@ -410 +564 @@ class EditorNotifier extends _$EditorNotifier { @@ -420,0 +575 @@ class EditorNotifier extends _$EditorNotifier { @@ -425 +580 @@ class EditorNotifier extends _$EditorNotifier { @@ -440,0 +596 @@ class EditorNotifier extends _$EditorNotifier { @@ -966,0 +1123,2 @@ class EditorNotifier extends _$EditorNotifier { @@ -970,0 +1129,225 @@ class EditorNotifier extends _$EditorNotifier { @@ -1333,0 +1717,3 @@ class EditorNotifier extends _$EditorNotifier { @@ -1447,0 +1834,8 @@ class EditorNotifier extends _$EditorNotifier { @@ -1501,0 +1896,4 @@ class EditorNotifier extends _$EditorNotifier { @@ -1504,0 +1903,20 @@ class EditorNotifier extends _$EditorNotifier { @@ -1507 +1925,116 @@ class EditorNotifier extends _$EditorNotifier { @@ -1514 +2047,5 @@ class EditorNotifier extends _$EditorNotifier { @@ -1519 +2056 @@ class EditorNotifier extends _$EditorNotifier { @@ -1522 +2059 @@ class EditorNotifier extends _$EditorNotifier { @@ -1525 +2062 @@ class EditorNotifier extends _$EditorNotifier { @@ -1532 +2069,9 @@ class EditorNotifier extends _$EditorNotifier { @@ -1560 +2105 @@ class EditorNotifier extends _$EditorNotifier { @@ -1569 +2114 @@ class EditorNotifier extends _$EditorNotifier { @@ -1573,0 +2119 @@ class EditorNotifier extends _$EditorNotifier { @@ -1578 +2124 @@ class EditorNotifier extends _$EditorNotifier { @@ -1581,0 +2128 @@ class EditorNotifier extends _$EditorNotifier { @@ -1748,0 +2296,7 @@ class EditorNotifier extends _$EditorNotifier { @@ -1918,0 +2473,6 @@ class EditorNotifier extends _$EditorNotifier { @@ -2005,0 +2566,6 @@ class EditorNotifier extends _$EditorNotifier { @@ -2566,0 +3133,8 @@ class EditorNotifier extends _$EditorNotifier { @@ -2610,0 +3185,8 @@ class EditorNotifier extends _$EditorNotifier { @@ -2651,0 +3234 @@ class EditorNotifier extends _$EditorNotifier { @@ -3097,0 +3681,6 @@ class EditorNotifier extends _$EditorNotifier { @@ -6168,0 +6758,7 @@ class EditorNotifier extends _$EditorNotifier { @@ -6173,0 +6770,11 @@ class EditorNotifier extends _$EditorNotifier { @@ -6336,0 +6944,7 @@ class EditorNotifier extends _$EditorNotifier { @@ -6343 +6957 @@ class EditorNotifier extends _$EditorNotifier { @@ -6346 +6959,0 @@ class EditorNotifier extends _$EditorNotifier { @@ -6351 +6964,4 @@ class EditorNotifier extends _$EditorNotifier { @@ -6355,0 +6972 @@ class EditorNotifier extends _$EditorNotifier { @@ -6478 +7095,2 @@ class EditorNotifier extends _$EditorNotifier { @@ -11857 +12475,2 @@ class EditorNotifier extends _$EditorNotifier {` |
| `packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart` | revalidation de session/epoch après activation asynchrone | `@@ -0,0 +1,2 @@ @@ -22 +24,3 @@ typedef LoadNarrativeEventMapSnapshot = Future<MapData?> Function(String mapId); @@ -357,5 +361,20 @@ final class NarrativeEventMapBridgeController @@ -453,5 +472,17 @@ final class NarrativeEventMapBridgeController` |
| `packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart` | confinement lexical/réel de maps/*.json et rejet des alias symlink | `@@ -4,0 +5 @@ import 'package:path/path.dart' as p; @@ -5,0 +7 @@ import '../../application/ports/project_workspace.dart'; @@ -7,0 +10,2 @@ class ProjectFileSystem implements ProjectWorkspace { @@ -22 +26,71 @@ class ProjectFileSystem implements ProjectWorkspace { @@ -27 +101 @@ class ProjectFileSystem implements ProjectWorkspace { @@ -32 +106,2 @@ class ProjectFileSystem implements ProjectWorkspace { @@ -205,0 +281,41 @@ class ProjectFileSystem implements ProjectWorkspace {` |
| `packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart` | retour de navigation via le guard partagé | `@@ -6,0 +7,2 @@ import '../../../application/models/narrative_event_map_bridge_models.dart'; @@ -38,0 +41,23 @@ class NarrativeEventMapReturnPanel extends ConsumerWidget { @@ -54 +79 @@ class NarrativeEventMapReturnPanel extends ConsumerWidget { @@ -56 +81,5 @@ class NarrativeEventMapReturnPanel extends ConsumerWidget { @@ -85 +114 @@ class NarrativeEventMapReturnPanel extends ConsumerWidget { @@ -87 +116,5 @@ class NarrativeEventMapReturnPanel extends ConsumerWidget {` |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | activation Event V2 protégée et révalidation après await | `@@ -14,0 +15,3 @@ import '../../../app/providers/core/repository_providers.dart'; @@ -906,0 +910,23 @@ class _EventBuilderV2ProductRouteState @@ -925 +951,4 @@ class _EventBuilderV2ProductRouteState @@ -927 +956,5 @@ class _EventBuilderV2ProductRouteState @@ -961 +994 @@ class _EventBuilderV2ProductRouteState @@ -963 +996,5 @@ class _EventBuilderV2ProductRouteState @@ -1177 +1214,6 @@ class _EventBuilderV2ProductRouteState @@ -1181 +1223,2 @@ class _EventBuilderV2ProductRouteState @@ -1252,0 +1296,8 @@ class _EventBuilderV2ProductRouteState @@ -1297,0 +1349,13 @@ class _EventBuilderV2ProductRouteState @@ -1969,0 +2034,14 @@ Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>` |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart` | reload/cleanup protégés par lease et Border, callback revalidé | `@@ -13,0 +14 @@ import '../../../application/use_cases/narrative_event_spatial_source_link_use_c @@ -54,0 +56,2 @@ class NarrativeEventMapBanner extends ConsumerWidget { @@ -56,0 +60 @@ class NarrativeEventMapBanner extends ConsumerWidget { @@ -238,0 +243 @@ class NarrativeEventMapBanner extends ConsumerWidget { @@ -257 +262,4 @@ class NarrativeEventMapBanner extends ConsumerWidget {` |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | ouverture de map via le guard commun | `@@ -11,0 +12,2 @@ import '../../domain/repositories/repositories.dart'; @@ -142 +143,0 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget { @@ -153,2 +154,17 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget { @@ -394 +410,5 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget { @@ -417 +437,5 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget { @@ -1552,0 +1577,2 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget { @@ -1567,0 +1594,2 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget { @@ -1672 +1700,8 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget { @@ -3790,0 +3826,14 @@ Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>` |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | activation projet centralisée et interlocks lifecycle | `@@ -30,0 +31,2 @@ import '../features/border_map_editing/presentation/pending_border_save_dialog.d @@ -344,0 +347 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> { @@ -346,2 +349,9 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> { @@ -349 +359 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> { @@ -354,4 +364,6 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {` |
| `packages/map_editor/lib/src/ui/panels/map_connections_panel.dart` | navigation vers connexion via le guard commun | `@@ -5,0 +6 @@ import 'package:map_core/map_core.dart'; @@ -103 +104,2 @@ class _MapConnectionsPanelState extends ConsumerState<MapConnectionsPanel> { @@ -125 +127,5 @@ class _MapConnectionsPanelState extends ConsumerState<MapConnectionsPanel> { @@ -153 +159,2 @@ class _MapConnectionsPanelState extends ConsumerState<MapConnectionsPanel> { @@ -414,2 +421 @@ class _DirectionConnectionCard extends StatelessWidget { @@ -438 +444,2 @@ class _DirectionConnectionCard extends StatelessWidget { @@ -462 +469,3 @@ class _DirectionConnectionCard extends StatelessWidget {` |
| `packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart` | écritures directes Event soumises aux gardes/leases | `@@ -7,0 +8 @@ import '../../application/use_cases/narrative_event_spatial_source_link_use_case @@ -19,0 +21,2 @@ class NarrativeEventMapBridgePanel extends ConsumerWidget { @@ -118 +121,2 @@ class NarrativeEventMapBridgePanel extends ConsumerWidget { @@ -124 +128,2 @@ class NarrativeEventMapBridgePanel extends ConsumerWidget { @@ -132,0 +138,3 @@ class NarrativeEventMapBridgePanel extends ConsumerWidget {` |
| `packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart` | activation depuis l’arbre via le guard commun | `@@ -4,0 +5 @@ import 'package:map_core/map_core.dart'; @@ -144 +145,2 @@ class GroupNode extends StatelessWidget { @@ -187 +189,5 @@ class MapNode extends StatelessWidget {` |
| `packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart` | activation depuis l’état vide via le guard commun | `@@ -6,0 +7 @@ import '../design_system/design_system.dart'; @@ -29 +30 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -36 +37,2 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -72 +74,2 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -77 +80,2 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -96,96 +100,114 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -193,8 +215,2 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -202,23 +218,12 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -225,0 +231 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -229 +234,0 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -231,0 +237,4 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -249 +258,2 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -253 +263 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -259,2 +269,6 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -271 +285 @@ class MapWorkspaceEmptyState extends ConsumerWidget { @@ -289 +303 @@ class _IsometricLayersPainter extends CustomPainter { @@ -292 +306 @@ class _IsometricLayersPainter extends CustomPainter { @@ -306 +320,2 @@ class _IsometricLayersPainter extends CustomPainter { @@ -312,4 +327,6 @@ class _IsometricLayersPainter extends CustomPainter { @@ -318 +335,8 @@ class _IsometricLayersPainter extends CustomPainter { @@ -321 +345,8 @@ class _IsometricLayersPainter extends CustomPainter { @@ -326,5 +357,5 @@ class _IsometricLayersPainter extends CustomPainter { @@ -332,4 +363,6 @@ class _IsometricLayersPainter extends CustomPainter { @@ -338 +371,2 @@ class _IsometricLayersPainter extends CustomPainter { @@ -345 +379 @@ class _IsometricLayersPainter extends CustomPainter { @@ -347 +381 @@ class _IsometricLayersPainter extends CustomPainter { @@ -350,7 +384,11 @@ class _IsometricLayersPainter extends CustomPainter { @@ -368 +406 @@ class _IsometricLayersPainter extends CustomPainter { @@ -372 +410 @@ class _IsometricLayersPainter extends CustomPainter { @@ -382 +420 @@ class _IsometricLayersPainter extends CustomPainter { @@ -392 +430 @@ class _IsometricLayersPainter extends CustomPainter { @@ -398 +436 @@ class _IsometricLayersPainter extends CustomPainter { @@ -400,3 +438,5 @@ class _IsometricLayersPainter extends CustomPainter { @@ -408,2 +448,3 @@ class _IsometricLayersPainter extends CustomPainter { @@ -411,3 +452,5 @@ class _IsometricLayersPainter extends CustomPainter { @@ -417 +460,2 @@ class _IsometricLayersPainter extends CustomPainter { @@ -419,4 +463,4 @@ class _IsometricLayersPainter extends CustomPainter { @@ -424,3 +468,12 @@ class _IsometricLayersPainter extends CustomPainter {` |
| `packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart` | création/ouverture projet via le gateway partagé | `@@ -12,0 +13 @@ import 'package:path_provider/path_provider.dart'; @@ -37,0 +39 @@ Future<void> showTopToolbarNewProjectDialog( @@ -40 +42,6 @@ Future<void> showTopToolbarNewProjectDialog( @@ -60 +67,5 @@ Future<void> showTopToolbarOpenProjectDialog(` |
| `packages/map_editor/test/event_map_navigation_controller_test.dart` | non-régression navigation, mêmes maps et résultats périmés | `@@ -643,0 +644,110 @@ void main() {` |
| `packages/map_editor/test/ui/canvas/narrative_event_map_banner_test.dart` | interlocks Border, cleanup/reload et callback capturé | `@@ -9,0 +10,2 @@ import 'package:map_core/map_core.dart'; @@ -21,0 +24,3 @@ import 'package:map_editor/src/domain/repositories/repositories.dart'; @@ -608 +613 @@ void main() { @@ -610 +615 @@ void main() { @@ -614,3 +619 @@ void main() { @@ -627 +630,4 @@ void main() { @@ -656,2 +662,2 @@ void main() { @@ -788,0 +795,50 @@ void main() { @@ -795,3 +851 @@ void main() { @@ -825 +879 @@ void main() { @@ -830 +884 @@ void main() { @@ -2344 +2398,2 @@ ProviderContainer _container({ @@ -2475,0 +2531,34 @@ MapData _map() => const MapData( @@ -2731,0 +2821,10 @@ final class _SuspendingMapRepository implements MapRepository { @@ -2737,0 +2837 @@ final class _SuspendingProjectRepository implements ProjectRepository { @@ -2740,0 +2841 @@ final class _SuspendingProjectRepository implements ProjectRepository {` |

Stat du diff suivi limité au lot :

```text
 .../src/application/use_cases/map_use_cases.dart   | 230 +++++--
 .../src/application/use_cases/warp_use_cases.dart  |  19 +-
 .../src/features/editor/state/editor_notifier.dart | 659 ++++++++++++++++++++-
 .../state/narrative_event_map_bridge_state.dart    |  53 +-
 .../filesystem/project_filesystem.dart             | 122 +++-
 .../events/narrative_event_map_return_panel.dart   |  41 +-
 .../events_v2/event_builder_v2_product_route.dart  |  90 ++-
 .../map_canvas/narrative_event_map_banner.dart     |  10 +-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  61 +-
 .../map_editor/lib/src/ui/editor_shell_page.dart   |  26 +-
 .../lib/src/ui/panels/map_connections_panel.dart   |  23 +-
 .../panels/narrative_event_map_bridge_panel.dart   |  12 +-
 .../widgets/tree/world_tree_nodes.dart             |  10 +-
 .../src/ui/shared/map_workspace_empty_state.dart   | 425 +++++++------
 .../top_toolbar/dialogs/top_toolbar_dialogs.dart   |  15 +-
 .../test/event_map_navigation_controller_test.dart | 110 ++++
 .../ui/canvas/narrative_event_map_banner_test.dart | 129 +++-
 17 files changed, 1710 insertions(+), 325 deletions(-)
```

Les autres fichiers dirty du dépôt ne sont pas attribués à ce lot. En particulier,
les changements Narrative Studio, personnalisation, lockfile de certification,
xcuserdata et autres travaux concurrents ont été conservés sans nettoyage.

## 6. Preuves RED/GREEN et vérification finale

La démarche a commencé par des tests RED ciblés : politiques inexistantes,
traversal accepté, activation dirty remplaçant la source, stale callbacks, writers
directs et Border non interlockés. Chaque famille a ensuite été rendue GREEN. Les
échecs intermédiaires utiles ont notamment révélé :

- un test widget FakeAsync bloqué sur un `Completer` ;
- un retour same-map qui faisait une activation inutile ;
- un fixture Border resté en ProjectVersion.v1 ;
- une fenêtre d’autorisation projet testée au mauvais ordre de microtask ;
- un callback de banner capturé qui devait revalider sa lease.

### Pack final principal

Commande fraîche :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact \
  test/application/services/project_map_id_policy_test.dart \
  test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/features/editor/application/map_activation_coordinator_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/features/editor/presentation/map_activation_guard_test.dart \
  test/event_map_navigation_controller_test.dart \
  test/top_toolbar_test.dart \
  test/ui/panels/narrative_event_map_bridge_panel_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/event_builder_workspace_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart \
  test/ui/canvas/narrative_event_map_banner_test.dart
```

Résultat exact : **exit 0 — `00:27 +428: All tests passed!`**.

### Analyse

```bash
cd packages/map_editor
flutter analyze --no-pub
```

Résultat exact : **exit 0 — `No issues found! (ran in 5.7s)`**.

### Format et whitespace

La commande `dart format --output=none --set-exit-if-changed` a été appliquée aux
27 sources/tests explicites du lot.

Résultat exact : **exit 0 — `Formatted 27 files (0 changed) in 0.22 seconds.`**.

`git diff --check` ciblé sur les 17 fichiers suivis du lot : **exit 0, clean**.
La passe Build a également relancé `git diff --check` global après le build :
**exit 0, aucune sortie**.

### Build macOS release

```bash
cd packages/map_editor
flutter build macos --release --no-pub
```

Résultat indépendant final : **exit 0 — `PokeMap.app (44.6MB)`**.

Avertissements uniquement tiers : `audioplayers_darwin` (actor isolation / weak
capture) et `video_player_avfoundation` (dépréciation/optionnalité).

Snapshot de preuve :

- digest SHA-256 de tous les Dart `lib/` + `test/` :
  `4402bc51f2e8d46368346f95ac6d9d4916f351957e97bb82a874d45a103bc2bc`,
  identique avant et après build ;
- source la plus récente : `16:12:05` ;
- exécutable : `16:15:32` ;
- App.framework : `16:15:31` ;
- SHA-256 exécutable :
  `5bcef6656a56ce22e18bf428edb2fa7e9aaec2886ec3946007e251ec1e9e6028`.

### Limite de preuve sur la suite totale

Une tentative de suite package complète a été interrompue volontairement pendant que
les sources changeaient encore. Elle n’est **pas** présentée comme verte. La preuve
finale est le pack produit/fondation de 428 tests, complété par trois matrices
indépendantes et l’analyse package complète.

Commande interrompue :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact
```

Résultat exact conservé : **interruption manuelle par SIGINT avant résultat terminal** ;
aucun total final exploitable n’a été produit et aucun code de sortie fiable n’a été
consigné. Le run a donc été exclu des preuves vertes au lieu d’être requalifié.

## 7. Verdicts des passes indépendantes

| Passe | Résultat frais | Verdict |
|---|---|---|
| Audit / Architecture | Audit initial read-only, 22 findings et programme Gate 0→6 | **FAIL produit / PARTIAL technique** ; refonte profonde justifiée, fondation data-safe prioritaire. |
| Implémentation | Pack final principal 428/428, analyse package et contrôles ciblés | **PASS DS-01/DS-02** ; périmètre livré sans prétendre fermer DS-00/Gate 0. |
| Tests — Foundation tests | 87/87 PASS + analyse ciblée sans problème | **PASS DS-01/DS-02**, aucun blocker ; DS-00/Gate 0 PARTIAL pour DS-03/04/05. |
| Build / Validation — Policy/build freeze | 248/248 PASS + analyse package + build release | **PASS sur le périmètre** ; digest source stable avant/après build. |
| Critique finale — Implementation readiness | 239/239 PASS + analyse + format + diff check, puis relecture du rapport | **PASS après corrections du rapport** ; aucun contournement produit normal trouvé. |

Ces matrices se recouvrent et ne sont pas additionnées.

Points signalés par la contre-revue :

- `loadMap(forceReload: true)` et `activateNarrativeEventMapSnapshot` restent des
  footguns recovery/legacy à réduire ;
- le store final écrit sans atomicité/CAS ;
- les compensations lifecycle restent best-effort ;
- l’index de références n’est pas exhaustif.

## 8. État Git

### État initial de l’audit qui précède le lot

Branche : `main`
HEAD : `a3d741818`

```text
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
```

### Baseline du lot fondation à la sortie de l’audit

Dernier snapshot exact conservé avant l’implémentation :

```text
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/01-empty-world-map-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/02-port-open-overview-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/03-inspector-scroll-layer-context-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/04-layers-expanded-truncated-actions-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md
```

### État observé avant création du présent rapport

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
?? packages/map_runtime/tool/qc03_m01_env01_runtime_capture_test.dart
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/gameplay/evidence/README.md
?? reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/01-empty-world-map-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/02-port-open-overview-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/03-inspector-scroll-layer-context-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/evidence/04-layers-expanded-truncated-actions-800x600.png
?? reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md
```

### État final après création et critique du rapport

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

Aucune commande Git d’écriture n’a été exécutée. Le worktree partagé est fortement
dirty à cause de travaux préexistants et concurrents ; aucun de ces changements n’a
été masqué, restauré, stashed ou nettoyé.

## 9. Auto-critique et risques

### Ce que la preuve établit fortement

- Les nouvelles opérations d’authoring ne peuvent plus injecter un ID/path arbitraire.
- Les chemins maps sont confinés lexicalement et physiquement, y compris avec symlinks.
- Une activation interactive dirty ne remplace plus silencieusement le document actif.
- Les décisions périmées, doubles activations et principaux writers directs sont gardés.
- Le package est analysable et le build macOS release passe sur un snapshot stable.

### Ce que la preuve n’établit pas

- Résistance aux crashs entre toutes les étapes d’un lifecycle.
- Écriture atomique et compare-and-swap contre une modification externe.
- Exhaustivité de toutes les références à une map avant rename/delete.
- Absence absolue de bypass via les API recovery/legacy.
- Suite `flutter test` package totale verte sur le snapshot final.
- Amélioration de l’ergonomie : aucun des symptômes visuels/gestuels n’est encore réparé.

### Risques de sur- et sous-correction

Sur-correction : durcir trop tôt la migration legacy pourrait bloquer des projets
existants. Le lot évite cela en diagnostiquant et en exigeant une migration explicite.

Sous-correction : commencer le shell UI maintenant pourrait déplacer les mêmes bugs
dans une nouvelle interface. Le risque principal restant est la persistance non
atomique ; il doit être fermé avant les migrations ou transformations massives.

### Verdict de critique

Le changement est cohérent, ciblé et suffisamment prouvé pour **DS-01/DS-02**.
La formulation « lot de fondation terminé » serait néanmoins trompeuse : **DS-00 et
Gate 0 restent PARTIAL**. La prochaine décision d’architecture doit être DS-03, puis
DS-04/DS-05, avant de considérer la base data-safe.

## 10. Recommandation de séquençage

| Ordre | Lot | Pourquoi |
|---:|---|---|
| 1 | DS-03 — Store atomique/révisionné/CAS | Ferme le plus gros risque de perte/corruption encore ouvert. |
| 2 | DS-04 — Index/préflight des références | Rend rename/delete compréhensibles et non destructifs. |
| 3 | DS-05 — Transaction lifecycle | Ferme les fenêtres de crash et compensations best-effort. |
| 4 | REN-01→03 | Rend l’ordre des layers canonique et testable éditeur/runtime. |
| 5 | INT-01→03 | Répare navigation, arbitrage souris/Magic Mouse et gomme. |
| 6 | SEL/MOV | Donne enfin sélection et déplacement directs. |
| 7 | AST-01→03 | Filtre les assets et mémorise le contexte par layer. |
| 8 | UI-01→03 | Recompose le shell autour d’un canvas déjà fiable. |

## 11. Contenu complet des fichiers créés

### `docs/superpowers/plans/2026-07-28-world-map-foundation-ds-00-ds-02.md`

````markdown
# World Map Foundation DS-00 to DS-02 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make World Map lifecycle operations safe before the visual refactor:
new map identifiers cannot escape the map directory, and a dirty map cannot be
replaced without an explicit Save, Discard, or Cancel decision.

**Architecture:** Keep persisted `MapData.id` backward compatible, but introduce
an authoring-only identifier policy for newly created or renamed maps. Harden the
real filesystem adapter independently so every map path is lexically confined
to `<project>/maps`. Put dirty-map activation policy in a pure coordinator,
enforce it inside `EditorNotifier`, and reuse one design-system prompt from all
interactive map-opening entry points.

**Tech Stack:** Dart 3, Flutter desktop, Riverpod, `package:path`,
`flutter_test`, PokeMap design system.

**Repository constraints:** Work in the existing tree because `AGENTS.md`
forbids creating a worktree or branch without explicit Git authorization. Do
not commit, stage, stash, switch branches, or modify unrelated dirty files.

---

## Scope

Included:

- DS-00 lifecycle characterization;
- DS-01 safe authoring IDs and map-path confinement before I/O;
- DS-02 centralized dirty-map activation;
- Save / Discard / Cancel presentation using PokeMap design-system widgets;
- targeted tests, package tests, analysis, macOS build, and evidence report.

Excluded:

- DS-03 atomic map persistence and revisions;
- dependency-aware delete/rename preflight beyond existing narrative guards;
- map resize planning;
- canonical render stack;
- navigation, eraser, selection, palette, or broad UI redesign;
- automatic or bulk migration of legacy map IDs (legacy maps are diagnosed
  and kept read-only until an explicit canonical rename path is available).

## Files

Create:

- `packages/map_editor/lib/src/application/services/project_map_id_policy.dart`
- `packages/map_editor/lib/src/application/services/project_map_manifest_integrity_policy.dart`
- `packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart`
- `packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart`
- `packages/map_editor/test/application/services/project_map_id_policy_test.dart`
- `packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart`
- `packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart`
- `packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart`
- `packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart`
- `packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart`
- `reports/ui/world_map_editor_foundation_ds_00_ds_02_2026-07-28.md`

Modify:

- `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart`
- `packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart`
- `packages/map_editor/lib/src/ui/panels/map_connections_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart`
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`
- `packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart`
- `packages/map_editor/test/event_map_navigation_controller_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_event_map_banner_test.dart`

No generated model or provider file is expected to change.

---

### Task 1: Characterize the authoring identifier contract

**Files:**

- Create:
  `packages/map_editor/test/application/services/project_map_id_policy_test.dart`
- Create:
  `packages/map_editor/lib/src/application/services/project_map_id_policy.dart`

- [x] **Step 1: Write the failing tests**

Cover:

```dart
group('ProjectMapIdPolicy', () {
  test('accepts canonical lowercase IDs used by current projects', () {});
  test('rejects empty, surrounding whitespace, separators and traversal', () {});
  test('rejects absolute paths, extensions, uppercase and reserved names', () {});
  test('detects conflicts case-insensitively', () {});
  test('creates a bounded canonical copy ID', () {});
});
```

The accepted grammar is lowercase ASCII with digits, `_` and `-`, starts and
ends with an alphanumeric character, and has a maximum length of 64. Windows
device names (`con`, `prn`, `aux`, `nul`, `com1`…`com9`, `lpt1`…`lpt9`) are
rejected case-insensitively.

- [x] **Step 2: Run RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/application/services/project_map_id_policy_test.dart
```

Expected: compilation failure because `ProjectMapIdPolicy` does not exist.

- [x] **Step 3: Implement the minimum policy**

Expose:

```dart
final class ProjectMapIdPolicy {
  static const int maxLength = 64;

  const ProjectMapIdPolicy();

  String requireValid(String rawId);

  void requireAvailable(
    String mapId,
    Iterable<String> existingIds, {
    String? excludingId,
  });

  String nextCopyId(String sourceId, Iterable<String> existingIds);
}
```

Throw `EditorValidationException` for malformed IDs and
`EditorConflictException` for a case-insensitive collision.

- [x] **Step 4: Run GREEN**

Run the Task 1 command. Expected: all Task 1 tests pass.

---

### Task 2: Confine real map paths to the project map directory

**Files:**

- Create:
  `packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart`
- Modify:
  `packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart`

- [x] **Step 1: Write the failing tests**

Use a temporary project directory and cover:

```dart
test('resolves maps/town.json inside the canonical maps directory', () {});
test('rejects parent traversal before touching the filesystem', () {});
test('rejects POSIX and Windows absolute paths', () {});
test('rejects backslash separators and non-map directories', () {});
test('getMapPath rejects an unsafe authoring ID', () {});
test('rejects a maps directory symlink that resolves outside the project', () {});
test('rejects a nested symlink whose target leaves the maps directory', () {});
```

- [x] **Step 2: Run RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart
```

Expected: unsafe paths currently resolve outside `<project>/maps`.

- [x] **Step 3: Implement lexical confinement**

`ProjectFileSystem.resolveMapPath` must:

1. reject blank or absolute input for both POSIX and Windows syntax;
2. reject backslashes;
3. normalize with `p.posix`;
4. require `maps/<file>.json`;
5. construct an absolute candidate;
6. resolve every existing ancestor/symlink synchronously;
7. require the resolved candidate to remain within the real
   `<project>/maps` directory;
8. throw `EditorValidationException` before repository read/write/delete I/O.

`getMapRelativePath` must call `ProjectMapIdPolicy.requireValid`, and
`getMapPath` must resolve that safe relative path.

The real adapter may use synchronous metadata/path resolution because the
existing `ProjectWorkspace` path contract is synchronous. It must not create,
write, rename, or delete anything during validation.

- [x] **Step 4: Run GREEN**

Run the Task 2 command. Expected: all Task 2 tests pass.

---

### Task 3: Apply the policy before every lifecycle I/O

**Files:**

- Create:
  `packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart`
- Modify:
  `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`

- [x] **Step 1: Write RED tests with recording fakes**

Cover:

```dart
test('Create rejects traversal before workspace or repository calls', () {});
test('Create rejects a case-insensitive duplicate without I/O', () {});
test('Rename validates the target before loading the source', () {});
test('Rename resolves the source from its manifest relativePath', () {});
test('Rename blocks a case-equivalent legacy target before I/O', () {});
test('Delete refuses an unknown map before delete I/O', () {});
test('Delete uses the manifest relativePath instead of deriving from ID', () {});
test('Duplicate refuses an unsafe legacy source before repository I/O', () {});
test('Duplicate chooses a bounded available copy ID', () {});
```

- [x] **Step 2: Run RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/application/use_cases/map_lifecycle_use_cases_test.dart
```

Expected: the unsafe create/rename cases reach workspace/repository calls.

- [x] **Step 3: Implement minimal lifecycle changes**

- validate create and rename targets at method entry;
- compare conflicts case-insensitively;
- locate source entries in `ProjectManifest.maps`;
- resolve existing source/delete paths from `entry.relativePath`;
- generate duplicate IDs through `ProjectMapIdPolicy`;
- block case-equivalent legacy renames until an explicit migration exists;
- keep DS-03 transactions out of scope.

- [x] **Step 4: Run GREEN**

Run the Task 3 command. Expected: all lifecycle tests pass.

---

### Task 4: Define and enforce the dirty activation policy

**Files:**

- Create:
  `packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart`
- Create:
  `packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart`
- Create:
  `packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart`
- Modify:
  `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

- [x] **Step 1: Write RED tests for the pure coordinator**

Required API:

```dart
enum DirtyMapActivationDecision { save, discard, cancel }

enum MapActivationPlan { activate, saveThenActivate, stay }

enum MapActivationOutcome {
  activated,
  requiresDecision,
  cancelled,
  saveBlocked,
  busy,
  failed,
}

final class MapActivationCoordinator {
  const MapActivationCoordinator();

  MapActivationPlan plan({
    required bool isDirty,
    DirtyMapActivationDecision? decision,
  });
}
```

Cover clean activation, missing decision on dirty state, Save, Discard, and
Cancel.

- [x] **Step 2: Run coordinator RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/features/editor/application/map_activation_coordinator_test.dart
```

Expected: compilation failure because the coordinator does not exist.

- [x] **Step 3: Implement the pure coordinator**

The coordinator returns:

- clean -> `activate`;
- dirty + null -> caller must return `requiresDecision`;
- dirty + save -> `saveThenActivate`;
- dirty + discard -> `activate`;
- dirty + cancel -> `stay`.

- [x] **Step 4: Write notifier RED tests**

Cover:

```dart
test('dirty activation without a decision performs no map read', () {});
test('same-map activation is a no-op even when the document is dirty', () {});
test('Cancel preserves map identity, history, viewport and dirty state', () {});
test('Discard replaces the map only after target load succeeds', () {});
test('Discard preserves the dirty source when target load fails', () {});
test('Save persists the source before reading and adopting the target', () {});
test('failed save blocks target reads and preserves the source', () {});
test('a second activation is rejected as busy while the first load owns the lease', () {});
```

- [x] **Step 5: Run notifier RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/features/editor/state/editor_notifier_map_activation_test.dart
```

Expected: the current `loadMap` reads and replaces a dirty document.

- [x] **Step 6: Implement notifier enforcement**

Add `activateMap(...) -> Future<MapActivationOutcome>` as the canonical command.
Keep `loadMap(...) -> Future<void>` as a compatibility wrapper that delegates to
`activateMap`.

Rules:

- evaluate dirty policy before acquiring a load lease or reading the target;
- same-map user activation is a no-op; internal recovery may opt into an
  explicit `forceReload`;
- internal calls that already own `mapWriteLeaseToken` retain their existing
  recovery contract;
- Save must return without loading unless `saveActiveMap` returns `saved`;
- Discard does not clear the source before target load succeeds;
- Cancel and missing decision are byte-preserving;
- the existing mutation lease remains the stale-result guard and defines the
  minimal concurrency contract for this lot: a second activation is rejected
  as busy rather than silently racing the first.

- [x] **Step 7: Run GREEN**

Run coordinator and notifier tests together. Expected: all pass.

---

### Task 5: Reuse one Save / Discard / Cancel prompt

**Files:**

- Create:
  `packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart`
- Create:
  `packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart`
- Modify all direct interactive map activation callers listed in the file
  inventory.

- [x] **Step 1: Write RED widget tests**

Cover:

```dart
testWidgets('clean activation opens immediately without a dialog', (_) async {});
testWidgets('Cancel leaves the activation command untouched', (_) async {});
testWidgets('Discard retries activation with an explicit discard decision', (_) async {});
testWidgets('Save uses the existing guarded map save before activation', (_) async {});
testWidgets('a blocked save never activates the target', (_) async {});
```

- [x] **Step 2: Run RED**

Run:

```bash
cd packages/map_editor
flutter test --no-pub \
  test/features/editor/presentation/map_activation_guard_test.dart
```

Expected: compilation failure because the shared guard does not exist.

- [x] **Step 3: Implement with the design system**

Use `showPokeMapConfirmationDialog`, `PokeMapDialogAction`, and
`PokeMapButtonVariant`; do not introduce local colors or ad-hoc buttons.

The shared guard first calls activation without a decision. Only
`requiresDecision` opens the dialog. Save delegates to
`requestActiveMapSaveWithBorderPreviewGuard`; activation resumes only after
`ActiveMapSaveOutcome.saved`.

- [x] **Step 4: Route all direct interactive activation calls**

Replace direct `loadMap` or `openConnectedMap` callbacks in:

- project tree;
- empty map workspace;
- map connections;
- narrative workspace;
- narrative map banner.

Programmatic snapshot reads remain unchanged.

- [x] **Step 5: Run GREEN**

Run the Task 5 test plus the affected existing shell/narrative widget tests.

---

### Task 6: Verification and closure evidence

**Files:**

- Create:
  `reports/ui/world_map_editor_foundation_ds_00_ds_02_2026-07-28.md`

- [x] **Step 1: Run focused tests**

Run all new tests plus:

```bash
flutter test --no-pub --reporter expanded \
  test/editor_project_session_controller_test.dart \
  test/editor_notifier_map_snapshot_test.dart \
  test/editor_notifier_project_dirty_state_test.dart \
  test/event_map_navigation_controller_test.dart \
  test/ui/shell/pokemap_workspace_empty_state_test.dart
```

- [x] **Step 2: Run the expanded foundation/product regression pack**

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact \
  test/application/services/project_map_id_policy_test.dart \
  test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart \
  test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/features/editor/application/map_activation_coordinator_test.dart \
  test/features/editor/state/editor_notifier_map_activation_test.dart \
  test/features/editor/presentation/map_activation_guard_test.dart \
  test/event_map_navigation_controller_test.dart \
  test/top_toolbar_test.dart \
  test/ui/panels/narrative_event_map_bridge_panel_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/event_builder_workspace_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart \
  test/ui/canvas/narrative_event_map_banner_test.dart
```

Fresh result: `00:27 +428: All tests passed!` (exit 0).

A prior full-package attempt was deliberately interrupted while the source was
still changing. It is not reported as a green full-suite result.

- [x] **Step 3: Run analysis**

```bash
cd packages/map_editor
flutter analyze --no-pub
```

- [x] **Step 4: Build macOS**

```bash
cd packages/map_editor
flutter build macos --release --no-pub
```

- [x] **Step 5: Review and report**

Run separate Audit/Architecture, Implementation, Tests, Build/Validation, and
Final Critique passes. Record:

- initial and final Git status;
- exact changed files and zones;
- every command and exact result;
- full contents of created text files;
- preserved limits and remaining DS-03 risks;
- no claim of green if the full suite is red.
````

### `packages/map_editor/lib/src/application/services/project_map_id_policy.dart`

````dart
import '../errors/application_errors.dart';

/// Validates IDs created by authoring workflows without rewriting legacy data.
///
/// A canonical ID is safe to embed in a map filename: it contains only
/// lowercase ASCII letters, digits, `_`, and `-`, with an alphanumeric first
/// and last character. Existing persisted IDs remain a separate migration
/// concern and must not be silently normalized by this policy.
final class ProjectMapIdPolicy {
  static const int maxLength = 64;

  static final RegExp _canonicalPattern = RegExp(
    r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$',
  );

  static const Set<String> _windowsReservedNames = <String>{
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
  };

  const ProjectMapIdPolicy();

  String requireValid(String rawId) {
    if (rawId.isEmpty) {
      throw const EditorValidationException('Map ID cannot be empty');
    }
    if (rawId.length > maxLength) {
      throw const EditorValidationException(
        'Map ID cannot exceed 64 characters',
      );
    }
    if (!_canonicalPattern.hasMatch(rawId)) {
      throw EditorValidationException(
        'Map ID "$rawId" must use lowercase ASCII letters, digits, "_" or '
        '"-", and start and end with a letter or digit',
      );
    }

    // Keep this platform-neutral: projects authored on macOS must remain
    // writable when moved to Windows.
    if (_windowsReservedNames.contains(rawId.toLowerCase())) {
      throw EditorValidationException(
        'Map ID "$rawId" is reserved by Windows',
      );
    }

    return rawId;
  }

  /// Lists persisted IDs that cannot participate in normal map authoring.
  ///
  /// The values are returned byte-for-byte so callers can diagnose legacy
  /// data without silently normalizing or migrating the project.
  List<String> nonCanonicalIds(Iterable<String> persistedIds) {
    final invalidIds = <String>[];
    for (final persistedId in persistedIds) {
      try {
        requireValid(persistedId);
      } on EditorValidationException {
        invalidIds.add(persistedId);
      }
    }
    return List<String>.unmodifiable(invalidIds);
  }

  void requireAvailable(
    String mapId,
    Iterable<String> existingIds, {
    String? excludingId,
  }) {
    final canonicalId = requireValid(mapId);
    final comparisonId = canonicalId.toLowerCase();

    for (final existingId in existingIds) {
      final existingComparisonId = existingId.toLowerCase();
      // Exclude only the identified source entry. A second entry that differs
      // only by case is still a real collision and must not be hidden.
      if (existingId == excludingId) {
        continue;
      }
      if (existingComparisonId == comparisonId) {
        throw EditorConflictException(
          'A map with the ID "$canonicalId" already exists',
        );
      }
    }
  }

  String nextCopyId(String sourceId, Iterable<String> existingIds) {
    final canonicalSourceId = requireValid(sourceId);
    final occupiedIds =
        existingIds.map((existingId) => existingId.toLowerCase()).toSet();

    var copyNumber = 0;
    while (true) {
      final suffix = copyNumber == 0 ? '_copy' : '_copy_$copyNumber';
      final sourceLength = maxLength - suffix.length;
      if (sourceLength < 1) {
        throw const EditorConflictException(
          'Unable to generate an available map copy ID',
        );
      }

      // Reserve the suffix before truncating so every generated candidate
      // remains canonical and never exceeds the persisted ID limit.
      final boundedSource = canonicalSourceId.length <= sourceLength
          ? canonicalSourceId
          : canonicalSourceId.substring(0, sourceLength);
      final candidate = '$boundedSource$suffix';
      if (!occupiedIds.contains(candidate.toLowerCase())) {
        return candidate;
      }

      copyNumber += 1;
    }
  }
}
````

### `packages/map_editor/lib/src/application/services/project_map_manifest_integrity_policy.dart`

````dart
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import 'project_map_id_policy.dart';

/// Validates that every manifest map path has one safe, unambiguous owner.
///
/// The workspace resolver remains authoritative for confinement and symlink
/// rejection. This policy adds the project-wide ownership check required
/// before a lifecycle or direct map write can safely start.
final class ProjectMapManifestIntegrityPolicy {
  const ProjectMapManifestIntegrityPolicy();

  static const ProjectMapIdPolicy _idPolicy = ProjectMapIdPolicy();

  List<String> diagnostics(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    String? allowedLegacyId,
  }) {
    final issues = <String>[];
    final ownersByResolvedPath = <String, ProjectMapEntry>{};
    final ownersById = <String, ProjectMapEntry>{};

    for (final entry in project.maps) {
      final idOwnershipKey = entry.id.toLowerCase();
      final previousIdOwner = ownersById[idOwnershipKey];
      if (previousIdOwner != null) {
        issues.add(
          'Les entrées « ${previousIdOwner.id} » et « ${entry.id} » '
          'utilisent le même identifiant de map.',
        );
      } else {
        ownersById[idOwnershipKey] = entry;
      }
      if (entry.id != allowedLegacyId) {
        try {
          _idPolicy.requireValid(entry.id);
        } on EditorValidationException catch (error) {
          issues.add(
            'La carte « ${entry.id} » utilise un identifiant legacy : $error',
          );
        }
      }

      late final String resolvedPath;
      try {
        resolvedPath = workspace.resolveMapPath(entry.relativePath);
      } on Object catch (error) {
        issues.add(
          'La carte « ${entry.id} » utilise un chemin non sûr '
          '« ${entry.relativePath} » : $error',
        );
        continue;
      }

      final ownershipKey = p.normalize(resolvedPath).toLowerCase();
      final previousOwner = ownersByResolvedPath[ownershipKey];
      if (previousOwner != null) {
        issues.add(
          'Les cartes « ${previousOwner.id} » et « ${entry.id} » '
          'référencent le même fichier de map.',
        );
        continue;
      }
      ownersByResolvedPath[ownershipKey] = entry;
    }

    return List<String>.unmodifiable(issues);
  }

  void requireValid(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    String? allowedLegacyId,
  }) {
    final issues = diagnostics(
      workspace,
      project,
      allowedLegacyId: allowedLegacyId,
    );
    if (issues.isEmpty) return;
    throw EditorValidationException(
      'Le manifeste des maps est non conforme et reste en lecture seule. '
      '${issues.first}',
    );
  }
}
````

### `packages/map_editor/lib/src/features/editor/application/map_activation_coordinator.dart`

````dart
/// Explicit choice made before leaving a map with unsaved authoring changes.
enum DirtyMapActivationDecision {
  save,
  discard,
  cancel,
}

/// Side-effect-free plan used by every active-map navigation entry point.
enum MapActivationPlan {
  activate,
  saveThenActivate,
  requiresDecision,
  stay,
}

/// Observable result of an active-map navigation request.
enum MapActivationOutcome {
  activated,
  requiresDecision,
  cancelled,
  saveBlocked,
  busy,
  failed,
  unavailable,
}

/// Centralizes the dirty-document decision matrix.
///
/// Keeping this policy pure prevents individual tree, canvas, or connection
/// entry points from inventing different rules for unsaved work.
final class MapActivationCoordinator {
  const MapActivationCoordinator();

  MapActivationPlan plan({
    required bool isDirty,
    bool hasPendingPreview = false,
    DirtyMapActivationDecision? decision,
  }) {
    if (!isDirty && !hasPendingPreview) {
      return MapActivationPlan.activate;
    }
    return switch (decision) {
      null => MapActivationPlan.requiresDecision,
      DirtyMapActivationDecision.save => MapActivationPlan.saveThenActivate,
      DirtyMapActivationDecision.discard => MapActivationPlan.activate,
      DirtyMapActivationDecision.cancel => MapActivationPlan.stay,
    };
  }
}
````

### `packages/map_editor/lib/src/features/editor/presentation/map_activation_guard.dart`

````dart
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../../border_map_editing/application/pending_border_save_guard.dart';
import '../../border_map_editing/presentation/pending_border_save_dialog.dart';
import '../application/map_activation_coordinator.dart';
import '../state/editor_notifier.dart';

typedef MapActivationCommand = Future<MapActivationOutcome> Function(
  DirtyMapActivationDecision? decision,
);

/// Runs the shared Save / Discard / Cancel interaction for map navigation.
///
/// The command is injectable so the decision workflow remains widget-testable
/// without constructing an entire editor session.
Future<MapActivationOutcome> requestGuardedMapActivation({
  required BuildContext context,
  required MapActivationCommand activate,
  required Future<ActiveMapSaveOutcome> Function() save,
}) async {
  final initialOutcome = await activate(null);
  if (initialOutcome != MapActivationOutcome.requiresDecision) {
    return initialOutcome;
  }
  if (!context.mounted) {
    await activate(DirtyMapActivationDecision.cancel);
    return MapActivationOutcome.cancelled;
  }

  final decision =
      await showPokeMapConfirmationDialog<DirtyMapActivationDecision>(
    context: context,
    title: 'Modifications non enregistrées',
    message: 'La carte active contient des modifications. '
        'Enregistrez-les avant d’ouvrir une autre carte, ignorez-les '
        'explicitement, ou restez ici.',
    actions: const <PokeMapDialogAction<DirtyMapActivationDecision>>[
      PokeMapDialogAction<DirtyMapActivationDecision>(
        label: 'Rester ici',
        value: DirtyMapActivationDecision.cancel,
      ),
      PokeMapDialogAction<DirtyMapActivationDecision>(
        label: 'Ignorer les modifications',
        value: DirtyMapActivationDecision.discard,
        variant: PokeMapButtonVariant.danger,
      ),
      PokeMapDialogAction<DirtyMapActivationDecision>(
        label: 'Enregistrer et ouvrir',
        value: DirtyMapActivationDecision.save,
        variant: PokeMapButtonVariant.success,
      ),
    ],
  );

  switch (decision ?? DirtyMapActivationDecision.cancel) {
    case DirtyMapActivationDecision.cancel:
      return activate(DirtyMapActivationDecision.cancel);
    case DirtyMapActivationDecision.discard:
      return activate(DirtyMapActivationDecision.discard);
    case DirtyMapActivationDecision.save:
      final saveOutcome = await save();
      if (saveOutcome == ActiveMapSaveOutcome.cancelled) {
        await activate(DirtyMapActivationDecision.cancel);
        return MapActivationOutcome.cancelled;
      }
      if (saveOutcome != ActiveMapSaveOutcome.saved) {
        await activate(DirtyMapActivationDecision.cancel);
        return MapActivationOutcome.saveBlocked;
      }
      if (!context.mounted) {
        await activate(DirtyMapActivationDecision.cancel);
        return MapActivationOutcome.cancelled;
      }
      // The save decision is also the acknowledgement token for this exact
      // handshake. The coordinator sees a clean document and does not save a
      // second time, while stale Discard answers remain strictly rejected.
      return activate(DirtyMapActivationDecision.save);
  }
}

/// Product-facing adapter used by every World Maps navigation surface.
Future<MapActivationOutcome> requestEditorMapActivation({
  required BuildContext context,
  required EditorNotifier notifier,
  required String relativePath,
}) async {
  final outcome = await requestGuardedMapActivation(
    context: context,
    activate: (decision) => notifier.activateMap(
      relativePath,
      dirtyDecision: decision,
    ),
    save: () => requestActiveMapSaveWithBorderPreviewGuard(
      context: context,
      notifier: notifier,
    ),
  );
  if (outcome == MapActivationOutcome.activated) {
    notifier.selectMapWorkspace();
  }
  return outcome;
}

Future<MapActivationOutcome> requestEditorConnectedMapActivation({
  required BuildContext context,
  required EditorNotifier notifier,
  required MapConnectionDirection direction,
}) async {
  final outcome = await requestGuardedMapActivation(
    context: context,
    activate: (decision) => notifier.activateConnectedMap(
      direction,
      dirtyDecision: decision,
    ),
    save: () => requestActiveMapSaveWithBorderPreviewGuard(
      context: context,
      notifier: notifier,
    ),
  );
  if (outcome == MapActivationOutcome.activated) {
    notifier.selectMapWorkspace();
  }
  return outcome;
}

Future<MapActivationOutcome> requestEditorProjectActivation({
  required BuildContext context,
  required EditorNotifier notifier,
  required String manifestPath,
}) {
  return requestGuardedMapActivation(
    context: context,
    activate: (decision) => notifier.activateProject(
      manifestPath,
      dirtyDecision: decision,
    ),
    save: () => _saveEditorBeforeProjectReplacement(
      context: context,
      notifier: notifier,
    ),
  );
}

Future<MapActivationOutcome> requestEditorProjectCreation({
  required BuildContext context,
  required EditorNotifier notifier,
  required String name,
  required String directory,
}) {
  return requestGuardedMapActivation(
    context: context,
    activate: (decision) => notifier.createAndActivateProject(
      name,
      directory,
      dirtyDecision: decision,
    ),
    save: () => _saveEditorBeforeProjectReplacement(
      context: context,
      notifier: notifier,
    ),
  );
}

Future<ActiveMapSaveOutcome> _saveEditorBeforeProjectReplacement({
  required BuildContext context,
  required EditorNotifier notifier,
}) async {
  final editor = notifier.currentState;
  if (editor.activeMap != null &&
      (editor.isDirty || notifier.hasPendingBorderPreview)) {
    final mapOutcome = await requestActiveMapSaveWithBorderPreviewGuard(
      context: context,
      notifier: notifier,
    );
    if (mapOutcome != ActiveMapSaveOutcome.saved) return mapOutcome;
  }
  if (notifier.currentState.isProjectDirty &&
      !await notifier.saveProjectManifest()) {
    return ActiveMapSaveOutcome.failed;
  }
  return ActiveMapSaveOutcome.saved;
}
````

### `packages/map_editor/test/application/services/project_map_id_policy_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/project_map_id_policy.dart';

void main() {
  const policy = ProjectMapIdPolicy();

  group('ProjectMapIdPolicy', () {
    test('accepts canonical lowercase IDs used by current projects', () {
      for (final mapId in <String>[
        'town',
        'route_01',
        'route-2',
        'a' * ProjectMapIdPolicy.maxLength,
      ]) {
        expect(policy.requireValid(mapId), mapId);
      }
    });

    test(
      'rejects empty, surrounding whitespace, separators and traversal',
      () {
        for (final mapId in <String>[
          '',
          ' town',
          'town ',
          'town square',
          'town/route',
          r'town\route',
          '.',
          '..',
          '../town',
          'town/../route',
          '_town',
          'town_',
          '-town',
          'town-',
          'a' * (ProjectMapIdPolicy.maxLength + 1),
        ]) {
          expect(
            () => policy.requireValid(mapId),
            throwsA(isA<EditorValidationException>()),
            reason: '"$mapId" must not be accepted as an authoring map ID',
          );
        }
      },
    );

    test(
      'rejects absolute paths, extensions, uppercase and reserved names',
      () {
        for (final mapId in <String>[
          '/town',
          r'C:\town',
          'C:/town',
          'town.json',
          'Town',
          'con',
          'prn',
          'aux',
          'nul',
          'com1',
          'com9',
          'lpt1',
          'lpt9',
        ]) {
          expect(
            () => policy.requireValid(mapId),
            throwsA(isA<EditorValidationException>()),
            reason: '"$mapId" must not be accepted as an authoring map ID',
          );
        }
      },
    );

    test('detects conflicts case-insensitively', () {
      expect(
        () => policy.requireAvailable('town', const <String>['Town']),
        throwsA(isA<EditorConflictException>()),
      );

      expect(
        () => policy.requireAvailable(
          'town',
          const <String>['Town', 'route_01'],
          excludingId: 'Town',
        ),
        returnsNormally,
      );
      expect(
        () => policy.requireAvailable(
          'town',
          const <String>['Town', 'town'],
          excludingId: 'Town',
        ),
        throwsA(isA<EditorConflictException>()),
      );
      expect(
        () => policy.requireAvailable(
          'harbor',
          const <String>['Town', 'route_01'],
        ),
        returnsNormally,
      );
      expect(
        () => policy.requireAvailable('../harbor', const <String>[]),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('creates a bounded canonical copy ID', () {
      expect(
        policy.nextCopyId('town', const <String>['route_01']),
        'town_copy',
      );
      expect(
        policy.nextCopyId('town', const <String>['TOWN_COPY']),
        'town_copy_1',
      );

      final sourceId = 'a' * ProjectMapIdPolicy.maxLength;
      final firstCandidate = '${'a' * 59}_copy';
      final candidate = policy.nextCopyId(
        sourceId,
        <String>[firstCandidate.toUpperCase()],
      );

      expect(candidate, '${'a' * 57}_copy_1');
      expect(candidate, hasLength(ProjectMapIdPolicy.maxLength));
      expect(policy.requireValid(candidate), candidate);
    });

    test('identifies legacy IDs without rewriting persisted values', () {
      final ids = <String>['town', 'Town', '../legacy', 'route-1'];

      expect(
        policy.nonCanonicalIds(ids),
        <String>['Town', '../legacy'],
      );
      expect(ids, <String>['town', 'Town', '../legacy', 'route-1']);
    });
  });
}
````

### `packages/map_editor/test/infrastructure/filesystem/project_filesystem_map_path_confinement_test.dart`

````dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ProjectFileSystem map path confinement', () {
    late Directory projectRoot;
    late ProjectFileSystem workspace;
    final extraRoots = <Directory>[];

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'pokemap_map_path_confinement_',
      );
      workspace = ProjectFileSystem(projectRoot.path);
    });

    tearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
      for (final root in extraRoots) {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
      extraRoots.clear();
    });

    test('resolves direct and nested JSON maps inside the map directory', () {
      expect(
        workspace.resolveMapPath('maps/town.json'),
        p.normalize(p.join(projectRoot.path, 'maps', 'town.json')),
      );
      expect(
        workspace.resolveMapPath('maps/regions/route_1.json'),
        p.normalize(
          p.join(projectRoot.path, 'maps', 'regions', 'route_1.json'),
        ),
      );
    });

    test('rejects traversal before any target file can be created', () {
      for (final relativePath in <String>[
        '../project.json',
        'maps/../project.json',
        'maps/sub/../../project.json',
      ]) {
        expect(
          () => workspace.resolveMapPath(relativePath),
          throwsA(isA<EditorValidationException>()),
          reason: relativePath,
        );
      }

      expect(
        File(p.join(projectRoot.path, 'project.json')).existsSync(),
        isFalse,
      );
    });

    test('rejects internal dot-segment and duplicate-separator aliases', () {
      for (final alias in <String>[
        'maps/./town.json',
        'maps/nested/../town.json',
        'maps//town.json',
      ]) {
        expect(
          () => workspace.resolveMapPath(alias),
          throwsA(isA<EditorValidationException>()),
          reason: alias,
        );
      }
    });

    test('rejects POSIX, drive-letter and UNC absolute paths', () {
      for (final path in <String>[
        '/tmp/evil.json',
        'C:/evil.json',
        r'C:\evil.json',
        r'\\server\share\evil.json',
      ]) {
        expect(
          () => workspace.resolveMapPath(path),
          throwsA(isA<EditorValidationException>()),
          reason: path,
        );
      }
    });

    test('rejects backslashes, non-map directories and non-JSON targets', () {
      for (final path in <String>[
        r'maps\town.json',
        'maps_evil/town.json',
        'assets/town.json',
        'maps/town.txt',
        'maps/',
      ]) {
        expect(
          () => workspace.resolveMapPath(path),
          throwsA(isA<EditorValidationException>()),
          reason: path,
        );
      }
    });

    test('getMapPath rejects an unsafe authoring identifier', () {
      expect(
        () => workspace.getMapPath('../project'),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => workspace.getMapRelativePath('Town'),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('rejects a maps directory symlink that leaves the project', () async {
      final outside = await Directory.systemTemp.createTemp(
        'pokemap_map_path_outside_',
      );
      extraRoots.add(outside);
      await Link(p.join(projectRoot.path, 'maps')).create(outside.path);

      expect(
        () => workspace.resolveMapPath('maps/town.json'),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('rejects a nested symlink whose target leaves maps', () async {
      final maps = Directory(p.join(projectRoot.path, 'maps'));
      await maps.create();
      final outside = await Directory.systemTemp.createTemp(
        'pokemap_nested_map_path_outside_',
      );
      extraRoots.add(outside);
      await Link(p.join(maps.path, 'linked')).create(outside.path);

      expect(
        () => workspace.resolveMapPath('maps/linked/town.json'),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('rejects an internal symlink alias even when it stays inside maps',
        () async {
      final maps = Directory(p.join(projectRoot.path, 'maps'));
      await maps.create();
      await Link(p.join(maps.path, 'alias')).create(maps.path);

      expect(
        () => workspace.resolveMapPath('maps/alias/town.json'),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        workspace.resolveMapPath('maps/town.json'),
        p.join(maps.path, 'town.json'),
      );
    });
  });
}
````

### `packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/application/use_cases/warp_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('CreateMapUseCase foundation guard', () {
    test('rejects traversal before any workspace or repository call', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(),
          '../project',
          8,
          8,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects a case-insensitive duplicate before I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('Town', 'maps/Town.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorConflictException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects a manifest path alias before workspace or repository I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('harbor', 'maps/town.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorConflictException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects an orphan target file before repository write I/O', () async {
      final fixture = _LifecycleFixture(
        existingFiles: const <String>{'/project/maps/town.json'},
      );

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('rejects an unsafe third-party manifest path before writer I/O',
        () async {
      final fixture = _LifecycleFixture(
        rejectedMapPaths: const <String>{'maps/alias/town.json'},
      );

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('legacy', 'maps/alias/town.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('rejects duplicate manifest path ownership before writer I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/shared.json'),
            _entry('beta', 'maps/SHARED.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('rejects an unrelated legacy manifest ID before writer I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('LegacyMap', 'maps/legacy.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('persists the canonical map and manifest entry', () async {
      final fixture = _LifecycleFixture();

      final created = await fixture.create.execute(
        fixture.workspace,
        fixture.project(),
        'harbor',
        6,
        5,
        groupId: 'coast',
        role: MapRole.interior,
      );

      expect(created.id, 'harbor');
      expect(created.size, const GridSize(width: 6, height: 5));
      expect(created.layers.map((layer) => layer.id), <String>[
        'l_base',
        'l_terrain',
        'l_collisions',
      ]);
      expect(
          fixture.mapRepository.saved.single.path, '/project/maps/harbor.json');
      final savedProject = fixture.projectRepository.savedProjects.single;
      expect(savedProject.maps.single.id, 'harbor');
      expect(savedProject.maps.single.relativePath, 'maps/harbor.json');
      expect(savedProject.maps.single.groupId, 'coast');
      expect(savedProject.maps.single.role, MapRole.interior);
    });

    test('removes the new map when manifest persistence fails', () async {
      final fixture = _LifecycleFixture(
        projectSaveError: StateError('manifest save failed'),
      );

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(),
          'harbor',
          6,
          5,
        ),
        throwsStateError,
      );

      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/harbor.json'],
      );
    });
  });

  group('RenameMapUseCase foundation guard', () {
    test('rejects duplicate case-insensitive manifest IDs before writer I/O',
        () async {
      final fixture = _LifecycleFixture();
      final project = fixture.project(entries: <ProjectMapEntry>[
        _entry('alpha', 'maps/alpha.json'),
        _entry('Alpha', 'maps/other.json'),
      ]);

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          project,
          'alpha',
          'gamma',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('validates the target before resolving or loading the source',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('town', 'maps/custom/town-source.json'),
          ]),
          'town',
          '../project',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('loads an existing map from its authoritative manifest path',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository
          .mapsByPath['/project/maps/custom/town-source.json'] = _map('town');

      final updated = await fixture.rename.execute(
        fixture.workspace,
        fixture.project(entries: <ProjectMapEntry>[
          _entry(
            'town',
            'maps/custom/town-source.json',
            groupId: 'coast',
            sortOrder: 7,
          ),
          _entry('route', 'maps/route.json'),
        ]),
        'town',
        'harbor',
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/custom/town-source.json'],
      );
      expect(
          fixture.mapRepository.saved.single.path, '/project/maps/harbor.json');
      expect(fixture.mapRepository.deletedPaths,
          <String>['/project/maps/custom/town-source.json']);
      final renamed = updated.maps.first;
      expect(renamed.id, 'harbor');
      expect(renamed.relativePath, 'maps/harbor.json');
      expect(renamed.groupId, 'coast');
      expect(renamed.sortOrder, 7);
      expect(updated.maps.last, _entry('route', 'maps/route.json'));
    });

    test('explicitly migrates one safe legacy ID to a canonical ID', () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/legacy-map.json'] =
          _map('LegacyMap');

      final updated = await fixture.rename.execute(
        fixture.workspace,
        fixture.project(entries: <ProjectMapEntry>[
          _entry('LegacyMap', 'maps/legacy-map.json'),
          _entry('route', 'maps/route.json'),
        ]),
        'LegacyMap',
        'legacy_map',
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/legacy-map.json'],
      );
      expect(fixture.mapRepository.saved.single.map.id, 'legacy_map');
      expect(
        fixture.mapRepository.saved.single.path,
        '/project/maps/legacy_map.json',
      );
      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/legacy-map.json'],
      );
      expect(updated.maps.first.id, 'legacy_map');
      expect(updated.maps.first.relativePath, 'maps/legacy_map.json');
      expect(updated.maps.last, _entry('route', 'maps/route.json'));
    });

    test('blocks a case-equivalent legacy rename before any I/O', () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/Town.json'] =
          _map('Town');

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('Town', 'maps/Town.json'),
          ]),
          'Town',
          'town',
        ),
        throwsA(isA<EditorInvalidOperationException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects a target path already owned by another manifest entry',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
            _entry('harbor', 'maps/town.json'),
          ]),
          'alpha',
          'town',
        ),
        throwsA(isA<EditorConflictException>()),
      );

      fixture.expectNoIo();
    });

    test('manifest failure removes only the newly written rename target',
        () async {
      final fixture = _LifecycleFixture(
        projectSaveError: StateError('manifest save failed'),
      );
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('alpha');

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
          'beta',
        ),
        throwsStateError,
      );

      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/beta.json'],
      );
    });

    test('refuses a source whose persisted ID mismatches the manifest',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('beta');

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
          'harbor',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/alpha.json'],
      );
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });
  });

  group('DeleteMapUseCase foundation guard', () {
    test('rejects duplicate exact manifest IDs before writer I/O', () async {
      final fixture = _LifecycleFixture();
      final project = fixture.project(entries: <ProjectMapEntry>[
        _entry('alpha', 'maps/alpha.json'),
        _entry('alpha', 'maps/other.json'),
      ]);

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          project,
          'alpha',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('refuses an unknown map before delete I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          fixture.project(),
          'missing',
        ),
        throwsA(isA<EditorNotFoundException>()),
      );

      fixture.expectNoIo();
    });

    test('deletes the authoritative manifest path and preserves other entries',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository
          .mapsByPath['/project/maps/custom/town-source.json'] = _map('town');

      final updated = await fixture.delete.execute(
        fixture.workspace,
        fixture.project(entries: <ProjectMapEntry>[
          _entry('town', 'maps/custom/town-source.json'),
          _entry('route', 'maps/route.json'),
        ]),
        'town',
      );

      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/custom/town-source.json'],
      );
      expect(updated.maps, <ProjectMapEntry>[
        _entry('route', 'maps/route.json'),
      ]);
      expect(fixture.projectRepository.savedProjects.single, updated);
    });

    test('keeps an unsafe legacy map read-only before delete I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('../legacy', 'maps/legacy.json'),
          ]),
          '../legacy',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('manifest failure never deletes the source map', () async {
      final fixture = _LifecycleFixture(
        projectSaveError: StateError('manifest save failed'),
      );
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('alpha');

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
        ),
        throwsStateError,
      );

      expect(fixture.mapRepository.deletedPaths, isEmpty);
    });

    test('refuses deletion when persisted ID mismatches the manifest',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('../legacy');

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/alpha.json'],
      );
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });
  });

  group('DuplicateMapUseCase foundation guard', () {
    test('refuses an unsafe legacy source before repository I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.duplicate.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('../project', 'maps/legacy.json'),
          ]),
          '../project',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('uses the manifest source path and a bounded available copy ID',
        () async {
      final fixture = _LifecycleFixture();
      final sourceId = 'a' * 64;
      final firstCopyId = '${'a' * 59}_copy';
      fixture.mapRepository.mapsByPath['/project/maps/custom/source.json'] =
          _map(sourceId);

      final updated = await fixture.duplicate.execute(
        fixture.workspace,
        fixture.project(entries: <ProjectMapEntry>[
          _entry(
            sourceId,
            'maps/custom/source.json',
            groupId: 'coast',
            sortOrder: 4,
          ),
          _entry(firstCopyId, 'maps/$firstCopyId.json'),
        ]),
        sourceId,
      );

      const expectedId =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa_copy_1';
      expect(expectedId, hasLength(64));
      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/custom/source.json'],
      );
      expect(fixture.mapRepository.saved.single.map.id, expectedId);
      expect(fixture.mapRepository.saved.single.path,
          '/project/maps/$expectedId.json');
      final duplicate = updated.maps.last;
      expect(duplicate.id, expectedId);
      expect(duplicate.relativePath, 'maps/$expectedId.json');
      expect(duplicate.groupId, 'coast');
      expect(duplicate.role, MapRole.exterior);
    });

    test('rejects a generated copy path owned by another manifest entry',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.duplicate.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
            _entry('harbor', 'maps/alpha_copy.json'),
          ]),
          'alpha',
        ),
        throwsA(isA<EditorConflictException>()),
      );

      fixture.expectNoIo();
    });

    test('removes the generated copy when manifest persistence fails',
        () async {
      final fixture = _LifecycleFixture(
        projectSaveError: StateError('manifest save failed'),
      );
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('alpha');

      await expectLater(
        fixture.duplicate.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
        ),
        throwsStateError,
      );

      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/alpha_copy.json'],
      );
    });

    test('refuses a source whose persisted ID mismatches the manifest',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('beta');

      await expectLater(
        fixture.duplicate.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/alpha.json'],
      );
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });
  });

  group('SaveMapUseCase legacy read-only guard', () {
    test('rejects a non-canonical persisted map ID before repository I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.save.execute(
          _map('../legacy'),
          '/project/maps/legacy.json',
          projectDialogueContext: fixture.project(
            entries: <ProjectMapEntry>[
              _entry('../legacy', 'maps/legacy.json'),
            ],
          ),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });
  });

  group('CreateReciprocalWarpUseCase legacy read-only guard', () {
    test('rejects a canonical source targeting a legacy map before I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.reciprocalWarp.execute(
          fixture.workspace,
          fixture.project(
            entries: <ProjectMapEntry>[
              _entry('alpha', 'maps/alpha.json'),
              _entry('../legacy', 'maps/legacy.json'),
            ],
          ),
          sourceMap: _mapWithWarp(
            id: 'alpha',
            targetMapId: '../legacy',
          ),
          sourceWarp: _warp('../legacy'),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects a legacy source targeting a canonical map before I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.reciprocalWarp.execute(
          fixture.workspace,
          fixture.project(
            entries: <ProjectMapEntry>[
              _entry('../legacy', 'maps/legacy.json'),
              _entry('beta', 'maps/beta.json'),
            ],
          ),
          sourceMap: _mapWithWarp(
            id: '../legacy',
            targetMapId: 'beta',
          ),
          sourceWarp: _warp('beta'),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('canonical cross-map reciprocal warp still persists the target',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/beta.json'] =
          _map('beta');

      final result = await fixture.reciprocalWarp.execute(
        fixture.workspace,
        fixture.project(
          entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
            _entry('beta', 'maps/beta.json'),
          ],
        ),
        sourceMap: _mapWithWarp(id: 'alpha', targetMapId: 'beta'),
        sourceWarp: _warp('beta'),
      );

      expect(result.updatedTargetMap.id, 'beta');
      expect(result.reciprocalWarp.targetMapId, 'alpha');
      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/beta.json'],
      );
      expect(fixture.mapRepository.saved, hasLength(1));
      expect(
          fixture.mapRepository.saved.single.path, '/project/maps/beta.json');
    });

    test('rejects a loaded legacy target after one read and before write',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/beta.json'] =
          _map('../legacy');

      await expectLater(
        fixture.reciprocalWarp.execute(
          fixture.workspace,
          fixture.project(
            entries: <ProjectMapEntry>[
              _entry('alpha', 'maps/alpha.json'),
              _entry('beta', 'maps/beta.json'),
            ],
          ),
          sourceMap: _mapWithWarp(id: 'alpha', targetMapId: 'beta'),
          sourceWarp: _warp('beta'),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/beta.json'],
      );
      expect(fixture.mapRepository.saved, isEmpty);
    });

    test('rejects a loaded target whose ID mismatches its manifest entry',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/beta.json'] =
          _map('gamma');

      await expectLater(
        fixture.reciprocalWarp.execute(
          fixture.workspace,
          fixture.project(
            entries: <ProjectMapEntry>[
              _entry('alpha', 'maps/alpha.json'),
              _entry('beta', 'maps/beta.json'),
            ],
          ),
          sourceMap: _mapWithWarp(id: 'alpha', targetMapId: 'beta'),
          sourceWarp: _warp('beta'),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/beta.json'],
      );
      expect(fixture.mapRepository.saved, isEmpty);
    });
  });
}

ProjectMapEntry _entry(
  String id,
  String relativePath, {
  String? groupId,
  int sortOrder = 0,
}) {
  return ProjectMapEntry(
    id: id,
    name: id,
    relativePath: relativePath,
    groupId: groupId,
    sortOrder: sortOrder,
  );
}

MapData _map(String id) {
  return MapData(
    id: id,
    name: id,
    size: const GridSize(width: 2, height: 2),
    layers: const <MapLayer>[],
  );
}

MapWarp _warp(String targetMapId) => MapWarp(
      id: 'exit',
      pos: const GridPos(x: 0, y: 0),
      targetMapId: targetMapId,
      targetPos: const GridPos(x: 1, y: 1),
    );

MapData _mapWithWarp({
  required String id,
  required String targetMapId,
}) =>
    _map(id).copyWith(warps: <MapWarp>[_warp(targetMapId)]);

final class _LifecycleFixture {
  _LifecycleFixture({
    Object? projectSaveError,
    Set<String> existingFiles = const <String>{},
    Set<String> rejectedMapPaths = const <String>{},
  })  : workspace = _RecordingWorkspace(
          existingFiles: existingFiles,
          rejectedMapPaths: rejectedMapPaths,
        ),
        mapRepository = _RecordingMapRepository(),
        projectRepository = _RecordingProjectRepository(projectSaveError) {
    create = CreateMapUseCase(mapRepository, projectRepository);
    rename = RenameMapUseCase(mapRepository, projectRepository);
    delete = DeleteMapUseCase(mapRepository, projectRepository);
    duplicate = DuplicateMapUseCase(mapRepository, projectRepository);
    save = SaveMapUseCase(mapRepository);
    reciprocalWarp = CreateReciprocalWarpUseCase(mapRepository);
  }

  final _RecordingWorkspace workspace;
  final _RecordingMapRepository mapRepository;
  final _RecordingProjectRepository projectRepository;
  late final CreateMapUseCase create;
  late final RenameMapUseCase rename;
  late final DeleteMapUseCase delete;
  late final DuplicateMapUseCase duplicate;
  late final SaveMapUseCase save;
  late final CreateReciprocalWarpUseCase reciprocalWarp;

  ProjectManifest project({List<ProjectMapEntry> entries = const []}) {
    return ProjectManifest(
      name: 'Demo',
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      maps: entries,
      groups: const <ProjectMapGroup>[
        ProjectMapGroup(
          id: 'coast',
          name: 'Coast',
          type: MapGroupType.route,
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
    );
  }

  void expectNoIo() {
    expect(workspace.calls, isEmpty);
    expect(mapRepository.loadedPaths, isEmpty);
    expect(mapRepository.saved, isEmpty);
    expect(mapRepository.deletedPaths, isEmpty);
    expect(projectRepository.savedProjects, isEmpty);
  }
}

final class _RecordingWorkspace implements ProjectWorkspace {
  _RecordingWorkspace({
    required this.existingFiles,
    required this.rejectedMapPaths,
  });

  final Set<String> existingFiles;
  final Set<String> rejectedMapPaths;
  final List<String> calls = <String>[];

  @override
  String get projectRoot => '/project';

  @override
  String get projectManifestPath => '/project/project.json';

  @override
  String resolveMapPath(String relativePath) {
    calls.add('resolveMapPath:$relativePath');
    if (rejectedMapPaths.contains(relativePath)) {
      throw EditorValidationException('Unsafe map path: $relativePath');
    }
    return '/project/$relativePath';
  }

  @override
  String getMapPath(String mapId) {
    calls.add('getMapPath:$mapId');
    return '/project/maps/$mapId.json';
  }

  @override
  String getMapRelativePath(String mapId) {
    calls.add('getMapRelativePath:$mapId');
    return 'maps/$mapId.json';
  }

  @override
  Future<void> ensureDirectoryExists(String path) async {
    calls.add('ensureDirectoryExists:$path');
  }

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<bool> fileExists(String path) async {
    calls.add('fileExists:$path');
    return existingFiles.contains(path);
  }

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/project/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/project/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

final class _RecordingMapRepository implements MapRepository {
  final Map<String, MapData> mapsByPath = <String, MapData>{};
  final List<String> loadedPaths = <String>[];
  final List<({MapData map, String path})> saved =
      <({MapData map, String path})>[];
  final List<String> deletedPaths = <String>[];

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    final map = mapsByPath[path];
    if (map == null) throw StateError('Missing fake map: $path');
    return map;
  }

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    saved.add((map: map, path: path));
  }

  @override
  Future<void> deleteMap(String path) async {
    deletedPaths.add(path);
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}
}

final class _RecordingProjectRepository implements ProjectRepository {
  _RecordingProjectRepository(this.saveError);

  final Object? saveError;
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) async =>
      throw UnimplementedError();

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    if (saveError != null) throw saveError!;
    savedProjects.add(project);
  }
}
````

### `packages/map_editor/test/features/editor/application/map_activation_coordinator_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';

void main() {
  group('MapActivationCoordinator', () {
    const coordinator = MapActivationCoordinator();

    test('activates a clean document immediately', () {
      expect(
        coordinator.plan(isDirty: false),
        MapActivationPlan.activate,
      );
    });

    test('treats a transient Border preview as unsaved authoring state', () {
      expect(
        coordinator.plan(
          isDirty: false,
          hasPendingPreview: true,
        ),
        MapActivationPlan.requiresDecision,
      );
    });

    test('requires an explicit decision for a dirty document', () {
      expect(
        coordinator.plan(isDirty: true),
        MapActivationPlan.requiresDecision,
      );
    });

    test('maps save, discard, and cancel to distinct plans', () {
      expect(
        coordinator.plan(
          isDirty: true,
          decision: DirtyMapActivationDecision.save,
        ),
        MapActivationPlan.saveThenActivate,
      );
      expect(
        coordinator.plan(
          isDirty: true,
          decision: DirtyMapActivationDecision.discard,
        ),
        MapActivationPlan.activate,
      );
      expect(
        coordinator.plan(
          isDirty: true,
          decision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationPlan.stay,
      );
    });

    test('ignores stale decisions when the document is already clean', () {
      expect(
        coordinator.plan(
          isDirty: false,
          decision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationPlan.activate,
      );
    });
  });
}
````

### `packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart`

````dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier.activateMap', () {
    test('same-map activation is a strict no-op, even while dirty', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      final outcome = await notifier.activateMap('maps/alpha.json');

      expect(outcome, MapActivationOutcome.activated);
      expect(notifier.state, before);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('explicit recovery reload bypasses the dirty prompt', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      final outcome = await notifier.activateMap(
        'maps/alpha.json',
        forceReload: true,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_alphaSaved));
      expect(notifier.state.isDirty, isFalse);
      expect(
        fixture.repository.loadedPaths,
        <String>['/project/maps/alpha.json'],
      );
    });

    test('dirty activation requires a decision before any I/O', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      final outcome = await notifier.activateMap('maps/beta.json');

      expect(outcome, MapActivationOutcome.requiresDecision);
      expect(notifier.state.activeMap!.id, 'alpha');
      expect(notifier.state.isDirty, isTrue);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('clean map with a pending Border preview requires a decision',
        () async {
      final fixture = _ActivationFixture();
      final map = _alphaWithBorder();
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(
          activeMap: map,
          savedMapSnapshot: map,
        );
      fixture.preview.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: createEditorBorderPreviewContext(
          projectRootPath: '/project',
          activeMapPath: '/project/maps/alpha.json',
          project: _project,
          map: map,
        ),
      );

      final outcome = await notifier.activateMap('maps/beta.json');

      expect(outcome, MapActivationOutcome.requiresDecision);
      expect(notifier.state.activeMap, same(map));
      expect(fixture.preview.current.hasPendingPreview, isTrue);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('cancel keeps the complete source editing session intact', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.cancel,
      );

      expect(outcome, MapActivationOutcome.cancelled);
      expect(notifier.state, before);
      expect(fixture.repository.loadedPaths, isEmpty);
    });

    test('a stale decision after cancel is rejected without I/O', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      expect(
        await notifier.activateMap(
          'maps/beta.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );

      final staleOutcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(staleOutcome, MapActivationOutcome.unavailable);
      expect(notifier.state, before);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('Discard is rejected if the source snapshot changed while prompting',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final replacement = notifier.state.copyWith(
        activeMap: notifier.state.activeMap!.copyWith(name: 'Async result'),
      );
      notifier.state = replacement;

      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(outcome, MapActivationOutcome.unavailable);
      expect(notifier.state, replacement);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('a stale decision cannot hide behind a same-map no-op', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      expect(
        await notifier.activateMap(
          'maps/beta.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );
      final replacementProject = _project.copyWith(name: 'Replacement');
      final replacementState = _cleanSourceState().copyWith(
        project: replacementProject,
        activeMap: _beta,
        activeMapPath: '/project/maps/beta.json',
        savedMapSnapshot: _beta,
      );
      notifier.state = replacementState;

      final staleOutcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(staleOutcome, MapActivationOutcome.unavailable);
      expect(notifier.state, replacementState);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('discard loads the target and opens a clean document', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_beta));
      expect(notifier.state.activeMapPath, '/project/maps/beta.json');
      expect(notifier.state.savedMapSnapshot, same(_beta));
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(fixture.repository.loadedPaths, ['/project/maps/beta.json']);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('save persists the source before loading the target', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.save,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(fixture.repository.callOrder, <String>[
        'save:/project/maps/alpha.json',
        'load:/project/maps/beta.json',
      ]);
      expect(fixture.repository.savedMaps.single, same(_alphaEdited));
      expect(notifier.state.activeMap, same(_beta));
      expect(notifier.state.isDirty, isFalse);
    });

    test('successful external save may advance map identity before activation',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final savedReplacement =
          notifier.state.activeMap!.copyWith(name: 'Saved async result');
      notifier.state = notifier.state.copyWith(
        activeMap: savedReplacement,
        savedMapSnapshot: savedReplacement,
        isDirty: false,
      );

      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.save,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_beta));
      expect(fixture.repository.savedPaths, isEmpty);
      expect(
        fixture.repository.loadedPaths,
        <String>['/project/maps/beta.json'],
      );
    });

    test('failed save blocks navigation and preserves the source', () async {
      final fixture = _ActivationFixture(saveError: StateError('disk full'));
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.save,
      );

      expect(outcome, MapActivationOutcome.saveBlocked);
      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.activeMapPath, '/project/maps/alpha.json');
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.mapUndoStack, isNotEmpty);
      expect(fixture.repository.loadedPaths, isEmpty);
    });

    test('missing target is rejected before saving a dirty source', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      final outcome = await notifier.activateMap('maps/missing.json');

      expect(outcome, MapActivationOutcome.failed);
      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.activeMapPath, '/project/maps/alpha.json');
      expect(notifier.state.isDirty, isTrue);
      expect(fixture.repository.savedPaths, isEmpty);
      expect(fixture.repository.loadedPaths, isEmpty);
    });

    test('failed target load never replaces or cleans the source', () async {
      final fixture = _ActivationFixture();
      fixture.repository.mapsByPath.remove('/project/maps/beta.json');
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(outcome, MapActivationOutcome.failed);
      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.activeMapPath, '/project/maps/alpha.json');
      expect(notifier.state.savedMapSnapshot, same(_alphaSaved));
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.mapUndoStack, isNotEmpty);
    });

    test('rejects a target whose persisted ID disagrees with the manifest',
        () async {
      final fixture = _ActivationFixture();
      fixture.repository.mapsByPath['/project/maps/beta.json'] =
          _beta.copyWith(id: 'wrong');
      final notifier = fixture.notifier..state = _cleanSourceState();

      final outcome = await notifier.activateMap('maps/beta.json');

      expect(outcome, MapActivationOutcome.failed);
      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.activeMapPath, '/project/maps/alpha.json');
      expect(notifier.state.isDirty, isFalse);
    });

    test('rejects a second concurrent activation as busy', () async {
      final loadStarted = Completer<void>();
      final releaseLoad = Completer<MapData>();
      final fixture = _ActivationFixture(
        loadHandler: (path) {
          if (path == '/project/maps/beta.json') {
            if (!loadStarted.isCompleted) loadStarted.complete();
            return releaseLoad.future;
          }
          return Future<MapData>.value(_gamma);
        },
      );
      final notifier = fixture.notifier..state = _cleanSourceState();

      final first = notifier.activateMap('maps/beta.json');
      await loadStarted.future;
      final second = await notifier.activateMap('maps/gamma.json');

      expect(second, MapActivationOutcome.busy);
      releaseLoad.complete(_beta);
      expect(await first, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_beta));
    });

    test('a dirty Discard load owns the gateway until adoption completes',
        () async {
      final loadStarted = Completer<void>();
      final releaseLoad = Completer<MapData>();
      final fixture = _ActivationFixture(
        loadHandler: (path) {
          if (path == '/project/maps/beta.json') {
            if (!loadStarted.isCompleted) loadStarted.complete();
            return releaseLoad.future;
          }
          return Future<MapData>.value(_gamma);
        },
      );
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final first = notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );
      await loadStarted.future;

      expect(
        await notifier.activateMap('maps/gamma.json'),
        MapActivationOutcome.busy,
      );
      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.busy,
      );

      releaseLoad.complete(_beta);
      expect(await first, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_beta));
      expect(fixture.projectRepository.loadedPaths, isEmpty);
    });

    test('only one dirty activation decision can be pending', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      final first = await notifier.activateMap('maps/beta.json');
      final second = await notifier.activateMap('maps/gamma.json');

      expect(first, MapActivationOutcome.requiresDecision);
      expect(second, MapActivationOutcome.busy);
      expect(
        await notifier.activateMap(
          'maps/beta.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );
      expect(
        await notifier.activateMap('maps/gamma.json'),
        MapActivationOutcome.requiresDecision,
      );
    });

    test('connected-map check and cancel preserve an in-progress stroke',
        () async {
      final fixture = _ActivationFixture();
      const strokeStart = MapHistorySnapshot(map: _alphaSaved);
      final connectedAlpha = _alphaEdited.copyWith(
        connections: const <MapConnection>[
          MapConnection(
            direction: MapConnectionDirection.north,
            targetMapId: 'beta',
            offset: 0,
          ),
        ],
      );
      final before = _dirtySourceState().copyWith(
        activeMap: connectedAlpha,
        mapStrokeStart: strokeStart,
      );
      final notifier = fixture.notifier..state = before;

      final check = await notifier.activateConnectedMap(
        MapConnectionDirection.north,
      );
      expect(check, MapActivationOutcome.requiresDecision);
      expect(notifier.state, before);

      final cancelled = await notifier.activateConnectedMap(
        MapConnectionDirection.north,
        dirtyDecision: DirtyMapActivationDecision.cancel,
      );
      expect(cancelled, MapActivationOutcome.cancelled);
      expect(notifier.state, before);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });
  });

  group('project session replacement interlock', () {
    test('clean project activation owns the lease before repository I/O',
        () async {
      final loadStarted = Completer<void>();
      final releaseLoad = Completer<ProjectManifest>();
      final fixture = _ActivationFixture(
        projectLoadHandler: (path) {
          if (!loadStarted.isCompleted) loadStarted.complete();
          return releaseLoad.future;
        },
      );
      final notifier = fixture.notifier..state = _cleanSourceState();

      final activation = notifier.activateProject(
        '/other/project.json',
        rememberAsRecent: false,
      );
      await loadStarted.future;

      expect(notifier.state.isSaving, isTrue);
      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.busy,
      );
      releaseLoad.complete(_project);
      expect(await activation, MapActivationOutcome.activated);
      expect(notifier.state.isSaving, isFalse);
    });

    test('clean project authorization rejects a microtask document change',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _cleanSourceState();

      scheduleMicrotask(() {
        notifier.state = notifier.state.copyWith(
          activeMap: notifier.state.activeMap!.copyWith(name: 'Async result'),
          isDirty: true,
        );
      });
      final activation = notifier.activateProject(
        '/other/project.json',
        rememberAsRecent: false,
      );

      expect(await activation, MapActivationOutcome.unavailable);
      expect(fixture.projectRepository.loadedPaths, isEmpty);
      expect(notifier.state.activeMap!.name, 'Async result');
      expect(notifier.state.isDirty, isTrue);
    });

    test('dirty project load requires a handshake and Cancel preserves source',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      expect(fixture.projectRepository.loadedPaths, isEmpty);

      expect(
        await notifier.activateProject(
          '/other/project.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
          rememberAsRecent: false,
        ),
        MapActivationOutcome.cancelled,
      );
      expect(notifier.state, before);
      fixture.expectNoLifecycleIo();
    });

    test('Discard loads the project only after the exact handshake', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateProject(
        '/other/project.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
        rememberAsRecent: false,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(
        fixture.projectRepository.loadedPaths,
        <String>['/other/project.json'],
      );
      expect(notifier.state.activeMap, isNull);
      expect(notifier.state.activeMapPath, isNull);
      expect(notifier.state.isDirty, isFalse);
    });

    test(
        'project Discard is rejected if the active map changed while prompting',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      final replacement = notifier.state.copyWith(
        activeMap: notifier.state.activeMap!.copyWith(name: 'Async result'),
      );
      notifier.state = replacement;

      final outcome = await notifier.activateProject(
        '/other/project.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
        rememberAsRecent: false,
      );

      expect(outcome, MapActivationOutcome.unavailable);
      expect(notifier.state, replacement);
      fixture.expectNoLifecycleIo();
    });

    test('low-level project wrappers cannot silently replace a dirty map',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      await notifier.loadProject(
        '/other/project.json',
        rememberAsRecent: false,
      );
      await notifier.createProject('Other', '/other');

      expect(notifier.state, before);
      fixture.expectNoLifecycleIo();
      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
        reason: 'Compatibility wrappers must release their pending handshake.',
      );
      expect(
        await notifier.activateMap(
          'maps/beta.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );
    });

    test('pending Border preview protects project open and creation', () async {
      final fixture = _ActivationFixture();
      final map = _beginPendingAlphaBorderPreview(fixture);
      final notifier = fixture.notifier;

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      expect(
        await notifier.activateProject(
          '/other/project.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
          rememberAsRecent: false,
        ),
        MapActivationOutcome.cancelled,
      );
      expect(
        await notifier.createAndActivateProject('Other', '/other'),
        MapActivationOutcome.requiresDecision,
      );
      expect(
        await notifier.createAndActivateProject(
          'Other',
          '/other',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );

      expect(notifier.state.activeMap, same(map));
      expect(fixture.preview.current.hasPendingPreview, isTrue);
      fixture.expectNoLifecycleIo();
    });

    test('project-dirty state also requires an explicit replacement decision',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(isProjectDirty: true);

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      expect(fixture.projectRepository.loadedPaths, isEmpty);
      expect(
        await notifier.activateProject(
          '/other/project.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
          rememberAsRecent: false,
        ),
        MapActivationOutcome.cancelled,
      );
      expect(notifier.state.isProjectDirty, isTrue);
      fixture.expectNoLifecycleIo();
    });
  });

  group('dirty active-map lifecycle interlock', () {
    test('create cannot replace a dirty active map', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      await notifier.createMap('delta', 8, 8);

      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.isDirty, isTrue);
      fixture.expectNoLifecycleIo();
    });

    test('rename cannot mutate the dirty active map on disk', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      await notifier.renameMap('alpha', 'delta');

      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.isDirty, isTrue);
      fixture.expectNoLifecycleIo();
    });

    test('delete cannot remove the dirty active map from disk', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      await notifier.deleteMap('alpha');

      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.isDirty, isTrue);
      fixture.expectNoLifecycleIo();
    });

    test('legacy active map stays read-only before a stroke can begin', () {
      final fixture = _ActivationFixture();
      final legacy = _alphaEdited.copyWith(id: '../legacy');
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(
          activeMap: legacy,
          savedMapSnapshot: legacy,
        );

      notifier.beginMapStroke();

      expect(notifier.state.mapStrokeStart, isNull);
      expect(notifier.state.errorMessage, contains('lecture seule'));
      fixture.expectNoLifecycleIo();
    });

    test('pending Border preview blocks every map lifecycle replacement',
        () async {
      final fixture = _ActivationFixture();
      final map = _beginPendingAlphaBorderPreview(fixture);
      final notifier = fixture.notifier;

      await notifier.createMap('delta', 8, 8);
      await notifier.renameMap('beta', 'delta');
      await notifier.deleteMap('beta');
      await notifier.duplicateMap('beta');

      expect(notifier.state.activeMap, same(map));
      expect(fixture.preview.current.hasPendingPreview, isTrue);
      expect(notifier.state.errorMessage, contains('aperçu de bordure'));
      fixture.expectNoLifecycleIo();
    });

    test('pending Border preview blocks direct map writers', () async {
      final fixture = _ActivationFixture();
      final map = _beginPendingAlphaBorderPreview(fixture);
      final notifier = fixture.notifier;

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 0, y: 0),
        kind: NarrativeEventPhysicalSourceKind.npc,
      );
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      await notifier.assignTilesetToActiveLayer('secondary');
      await notifier.createReciprocalWarpForSelectedWarp();

      expect(proposal, isNull);
      expect(writeLease, isNull);
      expect(notifier.state.activeMap, same(map));
      expect(fixture.preview.current.hasPendingPreview, isTrue);
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, contains('aperçu de bordure'));
      fixture.expectNoLifecycleIo();
    });

    test('legacy active map blocks every direct map writer', () async {
      final fixture = _ActivationFixture();
      final legacy = _alphaWithBorder().copyWith(id: '../legacy');
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(
          project: _projectWithTilesets,
          activeMap: legacy,
          activeMapPath: '/project/maps/legacy.json',
          savedMapSnapshot: legacy,
          activeLayerId: 'ground',
          selectedWarpId: 'north_exit',
        );

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 0, y: 0),
        kind: NarrativeEventPhysicalSourceKind.npc,
      );
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      await notifier.assignTilesetToActiveLayer('secondary');
      await notifier.createReciprocalWarpForSelectedWarp();

      expect(proposal, isNull);
      expect(writeLease, isNull);
      expect(notifier.state.activeMap, same(legacy));
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, contains('lecture seule'));
      fixture.expectNoLifecycleIo();
    });

    test('ambiguous manifest path ownership makes direct writers read-only',
        () async {
      final fixture = _ActivationFixture();
      final ambiguousProject = _project.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/shared.json',
          ),
          ProjectMapEntry(
            id: 'beta',
            name: 'Beta',
            relativePath: 'maps/SHARED.json',
          ),
        ],
      );
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(project: ambiguousProject);

      expect(
        await notifier.saveActiveMap(),
        ActiveMapSaveOutcome.unavailable,
      );
      expect(notifier.beginNarrativeEventSourceMapWriteLease(), isNull);

      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, contains('lecture seule'));
      fixture.expectNoLifecycleIo();
    });

    test('canonical map cannot write a reciprocal warp into a legacy target',
        () async {
      final fixture = _ActivationFixture();
      final source = _alphaWithBorder().copyWith(
        warps: const <MapWarp>[
          MapWarp(
            id: 'legacy_exit',
            pos: GridPos(x: 0, y: 0),
            targetMapId: '../legacy',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final project = _projectWithTilesets.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
          ProjectMapEntry(
            id: '../legacy',
            name: 'Legacy',
            relativePath: 'maps/legacy.json',
          ),
        ],
      );
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(
          project: project,
          activeMap: source,
          savedMapSnapshot: source,
          activeLayerId: 'ground',
          selectedWarpId: 'legacy_exit',
        );

      await notifier.createReciprocalWarpForSelectedWarp();

      expect(notifier.state.activeMap, same(source));
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, contains('lecture seule'));
      fixture.expectNoLifecycleIo();
    });
  });
}

const _alphaSaved = MapData(
  id: 'alpha',
  name: 'Alpha saved',
  size: GridSize(width: 2, height: 2),
);
const _alphaEdited = MapData(
  id: 'alpha',
  name: 'Alpha edited',
  size: GridSize(width: 2, height: 2),
);
const _beta = MapData(
  id: 'beta',
  name: 'Beta',
  size: GridSize(width: 2, height: 2),
);
const _gamma = MapData(
  id: 'gamma',
  name: 'Gamma',
  size: GridSize(width: 2, height: 2),
);

const _project = ProjectManifest(
  name: 'Demo',
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
  tilesets: <ProjectTilesetEntry>[],
  maps: <ProjectMapEntry>[
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
    ProjectMapEntry(
      id: 'gamma',
      name: 'Gamma',
      relativePath: 'maps/gamma.json',
    ),
  ],
);

final _projectWithTilesets = _project.copyWith(
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'primary',
      name: 'Primary',
      relativePath: 'tilesets/primary.png',
    ),
    ProjectTilesetEntry(
      id: 'secondary',
      name: 'Secondary',
      relativePath: 'tilesets/secondary.png',
    ),
  ],
);

EditorState _dirtySourceState() => const EditorState(
      projectRootPath: '/project',
      project: _project,
      activeMap: _alphaEdited,
      activeMapPath: '/project/maps/alpha.json',
      savedMapSnapshot: _alphaSaved,
      activeLayerId: 'decor',
      zoom: 1.75,
      panOffset: Offset(13, -8),
      mapUndoStack: <MapHistorySnapshot>[
        MapHistorySnapshot(map: _alphaSaved),
      ],
      canUndoMap: true,
      isDirty: true,
    );

EditorState _cleanSourceState() => _dirtySourceState().copyWith(
      savedMapSnapshot: _alphaEdited,
      mapUndoStack: const <MapHistorySnapshot>[],
      canUndoMap: false,
      isDirty: false,
    );

MapData _alphaWithBorder() => MapData(
      id: 'alpha',
      name: 'Alpha with Border preview',
      size: const GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        const TileLayer(
          id: 'ground',
          name: 'Sol',
          tilesetId: 'primary',
          tiles: <int>[0, 0, 0, 0],
        ),
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'coast',
                name: 'Côte',
                blueprintId: 'coast-blueprint',
                seed: BorderSignedInt64.fromInt(7),
                geometry: BorderRegionGeometry(
                  width: 2,
                  height: 2,
                  cells: const <bool>[true, false, false, false],
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
      ],
      warps: const <MapWarp>[
        MapWarp(
          id: 'north_exit',
          pos: GridPos(x: 0, y: 0),
          targetMapId: 'beta',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
    );

MapData _beginPendingAlphaBorderPreview(_ActivationFixture fixture) {
  final map = _alphaWithBorder();
  fixture.notifier.state = _cleanSourceState().copyWith(
    project: _projectWithTilesets,
    activeMap: map,
    savedMapSnapshot: map,
    activeLayerId: 'ground',
    selectedWarpId: 'north_exit',
  );
  fixture.preview.begin(
    map: map,
    layerId: 'borders',
    featureId: 'coast',
    context: createEditorBorderPreviewContext(
      projectRootPath: '/project',
      activeMapPath: '/project/maps/alpha.json',
      project: _projectWithTilesets,
      map: map,
    ),
  );
  return map;
}

final class _ActivationFixture {
  _ActivationFixture({
    Object? saveError,
    Future<MapData> Function(String path)? loadHandler,
    Future<ProjectManifest> Function(String path)? projectLoadHandler,
  })  : preview = BorderPreviewController(),
        repository = _ActivationMapRepository(
          saveError: saveError,
          loadHandler: loadHandler,
        ),
        projectRepository = _ActivationProjectRepository(
          loadHandler: projectLoadHandler,
        ) {
    container = ProviderContainer(
      overrides: <Override>[
        mapRepositoryProvider.overrideWith((ref) => repository),
        projectRepositoryProvider.overrideWith((ref) => projectRepository),
        projectWorkspaceFactoryProvider.overrideWith(
          (ref) => const _ActivationWorkspaceFactory(),
        ),
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    addTearDown(container.dispose);
  }

  final _ActivationMapRepository repository;
  final _ActivationProjectRepository projectRepository;
  final BorderPreviewController preview;
  late final ProviderContainer container;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  void expectNoLifecycleIo() {
    expect(repository.loadedPaths, isEmpty);
    expect(repository.savedPaths, isEmpty);
    expect(repository.deletedPaths, isEmpty);
    expect(projectRepository.savedProjects, isEmpty);
  }
}

final class _ActivationWorkspaceFactory implements ProjectWorkspaceFactory {
  const _ActivationWorkspaceFactory();

  @override
  ProjectWorkspace create(String projectRoot) =>
      _ActivationWorkspace(projectRoot);
}

final class _ActivationWorkspace implements ProjectWorkspace {
  const _ActivationWorkspace(this.projectRoot);

  @override
  final String projectRoot;

  @override
  String get projectManifestPath => '$projectRoot/project.json';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '$projectRoot/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      '$projectRoot/tilesets/imported.png';

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

final class _ActivationMapRepository implements MapRepository {
  _ActivationMapRepository({
    this.saveError,
    this.loadHandler,
  });

  final Object? saveError;
  final Future<MapData> Function(String path)? loadHandler;
  final Map<String, MapData> mapsByPath = <String, MapData>{
    '/project/maps/alpha.json': _alphaSaved,
    '/project/maps/beta.json': _beta,
    '/project/maps/gamma.json': _gamma,
  };
  final List<String> loadedPaths = <String>[];
  final List<String> savedPaths = <String>[];
  final List<String> deletedPaths = <String>[];
  final List<MapData> savedMaps = <MapData>[];
  final List<String> callOrder = <String>[];

  @override
  Future<void> deleteMap(String path) async {
    deletedPaths.add(path);
  }

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    callOrder.add('load:$path');
    final customHandler = loadHandler;
    if (customHandler != null) return customHandler(path);
    final map = mapsByPath[path];
    if (map == null) throw StateError('Missing map: $path');
    return map;
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    savedPaths.add(path);
    savedMaps.add(map);
    callOrder.add('save:$path');
    final failure = saveError;
    if (failure != null) throw failure;
  }
}

final class _ActivationProjectRepository implements ProjectRepository {
  _ActivationProjectRepository({this.loadHandler});

  final Future<ProjectManifest> Function(String path)? loadHandler;
  final List<String> loadedPaths = <String>[];
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) async {
    loadedPaths.add(path);
    final customHandler = loadHandler;
    if (customHandler != null) return customHandler(path);
    return _project;
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedProjects.add(project);
  }
}
````

### `packages/map_editor/test/features/editor/presentation/map_activation_guard_test.dart`

````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/presentation/map_activation_guard.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('clean activation does not open a decision dialog',
      (tester) async {
    final decisions = <DirtyMapActivationDecision?>[];
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (decision) async {
          decisions.add(decision);
          return MapActivationOutcome.activated;
        },
        save: () async => ActiveMapSaveOutcome.saved,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(result, MapActivationOutcome.activated);
    expect(decisions, <DirtyMapActivationDecision?>[null]);
    expect(find.byKey(pokeMapConfirmationDialogKey), findsNothing);
  });

  testWidgets('dirty activation offers cancel, discard, and save',
      (tester) async {
    await tester.pumpWidget(
      _GuardHarness(
        activate: (_) async => MapActivationOutcome.requiresDecision,
        save: () async => ActiveMapSaveOutcome.saved,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapConfirmationDialogKey), findsOneWidget);
    expect(find.text('Modifications non enregistrées'), findsOneWidget);
    expect(find.text('Rester ici'), findsOneWidget);
    expect(find.text('Ignorer les modifications'), findsOneWidget);
    expect(find.text('Enregistrer et ouvrir'), findsOneWidget);
  });

  testWidgets('discard forwards the explicit discard decision', (tester) async {
    final decisions = <DirtyMapActivationDecision?>[];
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (decision) async {
          decisions.add(decision);
          return decision == null
              ? MapActivationOutcome.requiresDecision
              : MapActivationOutcome.activated;
        },
        save: () async => ActiveMapSaveOutcome.saved,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ignorer les modifications'));
    await tester.pumpAndSettle();

    expect(decisions, <DirtyMapActivationDecision?>[
      null,
      DirtyMapActivationDecision.discard,
    ]);
    expect(result, MapActivationOutcome.activated);
  });

  testWidgets('cancel keeps navigation on the current document',
      (tester) async {
    final decisions = <DirtyMapActivationDecision?>[];
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (decision) async {
          decisions.add(decision);
          return decision == null
              ? MapActivationOutcome.requiresDecision
              : MapActivationOutcome.cancelled;
        },
        save: () async => ActiveMapSaveOutcome.saved,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rester ici'));
    await tester.pumpAndSettle();

    expect(decisions, <DirtyMapActivationDecision?>[
      null,
      DirtyMapActivationDecision.cancel,
    ]);
    expect(result, MapActivationOutcome.cancelled);
  });

  testWidgets('save persists first, then activates without a second prompt',
      (tester) async {
    final calls = <String>[];
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (decision) async {
          calls.add('activate:${decision?.name ?? 'check'}');
          return decision == null
              ? MapActivationOutcome.requiresDecision
              : MapActivationOutcome.activated;
        },
        save: () async {
          calls.add('save');
          return ActiveMapSaveOutcome.saved;
        },
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer et ouvrir'));
    await tester.pumpAndSettle();

    expect(calls, <String>[
      'activate:check',
      'save',
      'activate:save',
    ]);
    expect(result, MapActivationOutcome.activated);
  });

  testWidgets('failed save keeps navigation blocked', (tester) async {
    var activationCount = 0;
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (_) async {
          activationCount += 1;
          return MapActivationOutcome.requiresDecision;
        },
        save: () async => ActiveMapSaveOutcome.failed,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer et ouvrir'));
    await tester.pumpAndSettle();

    expect(activationCount, 2);
    expect(result, MapActivationOutcome.saveBlocked);
  });
}

typedef _Activate = Future<MapActivationOutcome> Function(
  DirtyMapActivationDecision? decision,
);

final class _GuardHarness extends StatelessWidget {
  const _GuardHarness({
    required this.activate,
    required this.save,
    this.onResult,
  });

  final _Activate activate;
  final Future<ActiveMapSaveOutcome> Function() save;
  final ValueChanged<MapActivationOutcome>? onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Builder(
        builder: (context) => Center(
          child: PokeMapButton(
            onPressed: () async {
              final result = await requestGuardedMapActivation(
                context: context,
                activate: activate,
                save: save,
              );
              onResult?.call(result);
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
  }
}
````
