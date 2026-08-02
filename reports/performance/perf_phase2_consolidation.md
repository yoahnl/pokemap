# Evidence Pack — Consolidation de la phase 2 performance

Date d’exécution : 2 août 2026 (Europe/Paris)
Branche / base : `main` à `1f5f4da3d62019ba84cbcc7fd63edf77133c7973`
Lots : `PERF-RM-05`, `PERF-RM-08`, `PERF-RM-09A`, `PERF-RM-09B`
Verdict : **phase 2 consolidée ; quatre lots proposés `DONE`**.

## Synthèse de sortie

| Lot | Verdict proposé | Preuve décisive |
|---|---|---|
| `PERF-RM-05` | `DONE` | Une racine active, au plus un candidat explicite, anciennes racines rejetées, trois runs AOT sous 10 Mio de croissance RSS. |
| `PERF-RM-08` | `DONE` | Trois journeys macOS profile, 100 éléments/10 sources/8 demandeurs/10 erreurs/10 cycles, chaque croissance stabilisée sous 10 % et 50 Mio. |
| `PERF-RM-09A` | `DONE` | Selbrume p50 <400 ms sur chaque run, p95 <1 s, pic RSS moyen réduit de 42,39 %, checksum identique. |
| `PERF-RM-09B` | `DONE` | Trois saves éditeur 10 Mio profile ≤250 ms et heartbeat ≤16,667 ms, bytes identiques, runtime déjà sous budget. |

Aucun statut de roadmap n’a été écrit : la demande porte sur la consolidation et
ses preuves. Les quatre changements de statut ci-dessus sont donc des
propositions fondées sur les résultats frais.

## Audit initial et verdict des passes indépendantes

La première revue indépendante a refusé une clôture prématurée et relevé quatre
familles de bloqueurs P1 :

1. une session d’une ancienne racine pouvait être rouverte après un switch ;
2. le snapshot lançait une seconde observation non bornée et décodait les gros
   modèles sur l’isolate appelant ;
3. plusieurs consommateurs d’images ne transmettaient pas la racine/cache
   projet, les crops ne partageaient pas leur source et certains leases
   survivaient à un changement de sélection ;
4. le benchmark 10 Mio n’exerçait pas l’invalidation Authoring du câblage
   production, tandis qu’une estimation de sortie rescannait le gros payload
   sur l’isolate UI.

Verdicts des passes d’audit avant remédiation :

| Passe | Verdict initial |
|---|---|
| assets éditeur | `PASS_WITH_CHANGES`, RM-08 maintenu `PARTIAL` sans trois receipts profile |
| snapshot/codec | RM-09A `PARTIAL`, moyenne 436 805 µs et réduction du pic RSS non prouvée |
| session/save | RM-09B RED, save mesuré 362 503 µs et benchmark hors lifecycle production |
| validation roadmap | aucun P0 ; P1 sur admission stale, offload decode, scope cache et preuve production |

Verdict initial : **aucun P0, mais les quatre lots ne pouvaient pas être
consolidés sans changements**. Les remédiations ont été implémentées puis
couvertes par tests et profils. La checklist de sortie reprend explicitement
chacun de ces constats dans la section « Revue finale » ci-dessous.

## Décisions et zones précises modifiées

### RM-05 — admission et retraite des sessions

- `EditorAuthoringSessionLifecycle.prepareCandidate`, `activate`,
  `discard` et `closeAll` sérialisent désormais l’admission
  `activeRoot + candidateRoot`.
- `AuthoringQueryAdapter` et `AuthoringMutationAdapter` contrôlent la racine
  avant et après toute ouverture ; une racine retirée échoue avec
  `editor.authoring_session_stale`.
- `EditorNotifier` prépare explicitement le candidat avant chargement/création
  et rend une erreur de cleanup visible.
- Réactiver ou repréparer la racine active retire tout candidat restant.
- Le benchmark lifecycle prépare lui aussi chaque candidat et exige
  `candidateRoot == null` à la fin.

### RM-08 — cache d’images réellement projet-scoped

- `EditorImageCache.loadCrop` sépare `variantKey` du
  `sourceVariantKey` : plusieurs crops partagent une seule image source sans
  confondre leurs variantes finales.
- `EnvironmentElementThumbnail.didUpdateWidget` recharge si le manifest,
  l’élément, le resolver, la racine ou le cache change, y compris au même path.
- `EnvironmentStudioWorkspace` propage la racine projet jusqu’aux formulaires,
  détails, palettes et thumbnails.
- `TilesetEditorCanvas` et `PathStudioPanel` invalident les complétions
  tardives et libèrent leurs leases sur changement/null/dispose.
- Le journey utilise 100 éléments logiques découpés dans 10 tilesets sources,
  deux projets A/B distincts et de vrais widgets rendus.

### RM-09A — snapshot cohérent, borné et offloadé

- `ProjectWorkspaceAccess.matchesResourceBytes` réalise la seconde observation
  byte-exacte sans créer un second conteneur possédé.
- `ProjectSnapshotLoader._matchSecondObservations` utilise un pool borné
  (`maxConcurrentSecondObservations=8`) en conservant l’ordre et les erreurs.
- `ProjectSnapshotDecodeExecutor` décode UTF-8/JSON/modèles ≥1 Mio via
  `Isolate.run`; autorisation, lectures et double observation restent locales.
- Les fingerprints, révisions, ordre, bytes exposés et erreurs de mutation/
  disparition restent identiques.

### RM-09B — codec hors UI et lifecycle production

- `decodeNarrativeEventJsonStrict` valide doublons/surrogates sans construire
  une canonicalisation complète inutilisée.
- `EditorPersistenceCodecExecutor.prepareExistingProjectUpdate` produit
  directement les bytes finaux ; les comparaisons CAS byte-exactes passent au
  worker pour les gros payloads.
- L’estimation JSON est plafonnée au seuil et court-circuitée lorsque les bytes
  courants dépassent déjà 1 Mio, supprimant le scan UI des 10 Mio.
- `FileProjectRepository` conserve recovery, locks, double contrôle avant/live
  et écriture ; le journey ouvre puis invalide un vrai snapshot Authoring.

## Mesures finales

### RM-05 — trois processus AOT, dix racines

| Run | Durée | Croissance RSS | État final |
|---:|---:|---:|---|
| 1 | 55 902 µs | 9 551 872 octets | lecture=1, mutation=1, candidat=null |
| 2 | 50 352 µs | 9 584 640 octets | lecture=1, mutation=1, candidat=null |
| 3 | 54 567 µs | 9 584 640 octets | lecture=1, mutation=1, candidat=null |

Chaque participant rapporte `opening=0`, `retiring=0`,
`activeOperations=0`, `closeCount=9`; le coordinator possède deux
participants.

Artifacts :
`packages/map_editor/build/performance/phase2-consolidation-final-rm05/results/run_{1,2,3}.json`.

### RM-08 — trois processus macOS profile

| Run | Croissance RSS stabilisée | Ratio | Pic RSS | Frame span p95 |
|---:|---:|---:|---:|---:|
| 1 | 6 848 512 octets | 3,519 % | 220 135 424 | 121 986 µs |
| 2 | 7 077 888 octets | 3,635 % | 220 364 800 | 119 575 µs |
| 3 | 1 048 576 octets | 0,523 % | 219 152 384 | 119 613 µs |

La croissance stabilisée est
`median(cycles 8–10) - median(cycles 1–3)`. Les trois runs respectent
séparément les deux bornes de 50 Mio et 10 %. Fixture et arbre mesuré sont
identiques dans les trois receipts :
`fixtureFingerprint=ad05eb87429059c175636d58ccdfc0c8e102945c1ecea8ed543a9b32f6e53235`,
`treeFingerprint=11768eb3d6fb94df18ee9c631f58b27cbeb687ac52510ff77285fa5c62b4e85f`.

Les frame timings sont **observation uniquement**, conformément au seuil annoncé
avant mesure. La mémoire native image exacte est `null` avec justification ;
`width × height × 4` reste explicitement une estimation logique, pas une
allocation CPU/GPU mesurée.

Artifacts :
`packages/map_editor/build/performance/phase2-consolidation-final-rm08/run_{1,2,3}.json`.

### RM-09A — vrai Selbrume, trois processus AOT

| Run | p50 actuel | p95 actuel | Pic RSS actuel | p50 baseline | Pic RSS baseline |
|---:|---:|---:|---:|---:|---:|
| 1 | 369 086 µs | 373 549 µs | 181 534 720 | 604 484 µs | 360 955 904 |
| 2 | 374 674 µs | 386 457 µs | 206 209 024 | 603 583 µs | 332 939 264 |
| 3 | 372 845 µs | 376 809 µs | 203 554 816 | 602 720 µs | 332 480 512 |

Moyenne des 24 samples : 373 302,83 µs contre 604 221,63 µs (−38,22 %).
Pic RSS externe moyen : 197 099 520 contre 342 125 227 octets (−42,39 %).
Chaque p50 est sous 400 ms et chaque p95 sous 1 s. Les deux côtés utilisent le
même dataset `2ab648cc9fa4f5b8` et le même checksum
`82e410fe61aba903`.

La baseline provient de `git archive HEAD`, même SDK/commande/dataset, avec
une seule adaptation du harness : le nom `selbrume` de HEAD pointait encore
vers une mini-fixture de 2 maps ; il a été redirigé vers le vrai
`/selbrume`. Une première baseline sur la mini-fixture a été explicitement
rejetée et n’entre dans aucun calcul.

Artifacts actuels :
`packages/map_authoring/build/performance/phase2-consolidation-final-rm09a/results/run_{1,2,3}.{json,time.txt}`.

Artifacts baseline :
`packages/map_authoring/build/performance/phase2-consolidation-paired-baseline-rm09a-canonical/results/run_{1,2,3}.{json,time.txt}`.

### RM-09B — trois processus macOS profile, sauvegarde 10 Mio

| Run | Save production | Gap heartbeat max | Workers | Échecs worker |
|---:|---:|---:|---:|---:|
| 1 | 219 343 µs | 3 695 µs | 4 | 0 |
| 2 | 235 213 µs | 5 995 µs | 4 | 0 |
| 3 | 235 493 µs | 7 073 µs | 4 | 0 |

Chaque run respecte `save ≤250 000 µs` et
`heartbeat ≤16 667 µs`, invalide le snapshot Authoring et conserve
`sha256:776c57eafc5031a19ff1cd5578fdb566c56bce00993617c5556dd0d324d165c9`.
Les trois receipts partagent le même tree fingerprint RM-09B.

Les `FrameTiming.max` élevés (431 359 / 372 747 / 373 662 µs) sont conservés
sans sélection ni suppression, mais marqués observation-only : ils proviennent
du couplage raster/test-driver et coexistent avec un timer main-isolate qui
répond toutes les 3,7–7,1 ms. Le critère annoncé de sortie RM-09B est ce
heartbeat 60 Hz, pas un seuil frame ajouté après mesure.

Artifacts :
`packages/map_editor/build/performance/phase2-consolidation-final-rm09b-profile/run_{1,2,3}.json`.

Le volet runtime n’a pas été modifié après sa validation : trois runs 10 Mio
restent sous 45 ms au save, sous 26 ms au load et sous 33,3 ms de gap.

## Vérifications exactes

```text
cd packages/map_core
dart test --reporter compact && dart analyze
=> exit 0 ; +4679 ; All tests passed! ; No issues found!

cd packages/map_authoring
dart test --reporter compact && dart analyze
=> exit 0 ; +314 ; All tests passed! ; No issues found!

cd packages/map_runtime
flutter test --reporter compact && flutter analyze
=> exit 0 ; +2320 ~1 ; tous les tests non ignorés passent ; No issues found!

cd packages/map_editor
flutter test <14 fichiers ciblés Phase 2>
=> exit 0 ; +165 ; All tests passed!

flutter analyze
=> exit 0 ; No issues found! (6,5 s)

flutter build macos --debug
=> exit 0 ; PokeMap.app construit ; avertissements AVFoundation tiers uniquement

flutter test -d macos integration_test/editor_asset_cache_journey_test.dart
flutter test -d macos integration_test/editor_codec_offload_journey_test.dart
=> exit 0 ; +1 chacun ; All tests passed!

flutter drive --profile -d macos ... editor_asset_cache_journey_test.dart
=> 3 processus ; exit 0 chacun

flutter drive --profile -d macos ... editor_codec_offload_journey_test.dart
=> 3 processus ; exit 0 chacun

dart format --output=none --set-exit-if-changed <fichiers Dart de phase>
=> exit 0 ; 57 files ; 0 changed

git diff --check
=> exit 0 ; aucune erreur
```

Deux dettes préexistantes ont été isolées plutôt que masquées :

- `editor_notifier_map_activation_test.dart` : `+37 -1`, échec
  « save persists the source… », attendu `activated`, obtenu `saveBlocked`
  faute d’attestation de révision disque ;
- `pending_border_save_notifier_test.dart` : `+6 -4`, trois attestations
  disque absentes et une fausse racine qui n’est pas un projet PokeMap réel.

Tous les tests « project session replacement interlock » touchés par RM-05
passent dans le premier fichier ; ces cinq échecs sont donc documentés comme
dette hors phase, pas comptés comme verts.

## Parité PokeMap MCP

```text
cd packages/map_authoring
dart run tool/pmcp085_conformance.dart
=> exit 0 ; resources=62 ; mutationActions=227 ;
   blockedOrMissing=0 ; catalogComplete=true

cd tools/pokemap_mcp
npm run check && npm test
=> exit 0 ; 23/23 tests ; 0 failure

pokemap_describe (serveur live)
=> ok=true ; resources=62 ; mutationActions=227 ;
   blockedOrMissing=0 ; catalogComplete=true
```

La phase ne crée aucun nouveau contrat sémantique persistant : elle conserve
l’API canonique et prouve que direct API, CLI/JSONL, éditeur et MCP restent
alignés.

## Inventaire Git avant le commit demandé

État initial avant la phase 2 : cinq fichiers world-map suivis déjà modifiés et
un `__pycache__` non suivi. Ils ont été préservés sans édition attribuable à
cette phase. Aucune commande Git d’écriture n’avait été exécutée au moment de
la clôture technique.

| État | Fichier | Attribution |
|---|---|---|
| `M` | `ackages/map_authoring/benchmark/authoring_snapshot_open.dart` | phase 2 |
| `M` | `packages/map_authoring/lib/src/ports/project_file_reader.dart` | phase 2 |
| `M` | `packages/map_authoring/lib/src/workspace/project_snapshot.dart` | phase 2 |
| `M` | `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart` | phase 2 |
| `M` | `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart` | phase 2 |
| `M` | `packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart` | phase 2 |
| `M` | `packages/map_authoring/test/workspace/project_open_service_test.dart` | phase 2 |
| `M` | `packages/map_authoring/test/workspace/project_snapshot_test.dart` | phase 2 |
| `M` | `packages/map_core/lib/src/operations/narrative_event_canonical_json.dart` | phase 2 |
| `M` | `packages/map_core/test/narrative_event_claim_fingerprints_test.dart` | phase 2 |
| `M` | `packages/map_editor/integration_test/editor_project_journey_test.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/app/providers/core/repository_providers.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart` | hors phase — préservé |
| `M` | `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart` | hors phase — préservé |
| `M` | `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/path_studio/path_pattern_tileset_image_info_loader.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/ui/assets/editor_image_cache.dart` | phase 2 |
| `M` | `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart` | phase 2 |
| `M` | `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/authoring_api/editor_read_parity_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/editor_image_cache_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/features/editor/application/world_map_paint_layer_routing_test.dart` | hors phase — préservé |
| `M` | `packages/map_editor/test/features/editor/application/world_map_tool_activation_test.dart` | hors phase — préservé |
| `M` | `packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart` | hors phase — préservé |
| `M` | `packages/map_editor/test/features/editor/state/editor_notifier_map_activation_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/path_pattern/path_pattern_asset_diagnostics_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/path_pattern/path_studio_panel_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart` | phase 2 |
| `M` | `packages/map_editor/test/tileset_library_visual_labels_test.dart` | phase 2 |
| `M` | `packages/map_editor/test_driver/performance_driver.dart` | phase 2 |
| `M` | `packages/map_runtime/lib/map_runtime.dart` | phase 2 |
| `M` | `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart` | phase 2 |
| `??` | `packages/map_authoring/test/workspace/project_snapshot_concurrency_test.dart` | phase 2 |
| `??` | `packages/map_editor/benchmark/authoring_session_lifecycle.dart` | phase 2 |
| `??` | `packages/map_editor/benchmark/editor_asset_cache_profile_test.dart` | phase 2 |
| `??` | `packages/map_editor/benchmark/editor_codec_offload_profile_test.dart` | phase 2 |
| `??` | `packages/map_editor/integration_test/editor_asset_cache_journey_test.dart` | phase 2 |
| `??` | `packages/map_editor/integration_test/editor_codec_offload_journey_test.dart` | phase 2 |
| `??` | `packages/map_editor/lib/src/application/authoring_api/authoring_session_lifecycle.dart` | phase 2 |
| `??` | `packages/map_editor/lib/src/infrastructure/repositories/editor_persistence_codec_executor.dart` | phase 2 |
| `??` | `packages/map_editor/test/authoring_api/authoring_session_lifecycle_test.dart` | phase 2 |
| `??` | `packages/map_editor/test/environment_studio/environment_element_thumbnail_async_test.dart` | phase 2 |
| `??` | `packages/map_editor/test/infrastructure/editor_persistence_codec_executor_test.dart` | phase 2 |
| `??` | `packages/map_runtime/benchmark/game_save_codec_offload_profile_test.dart` | phase 2 |
| `??` | `packages/map_runtime/lib/src/infrastructure/game_save_codec_executor.dart` | phase 2 |
| `??` | `packages/map_runtime/test/game_save_codec_executor_test.dart` | phase 2 |
| `??` | `reports/performance/perf_rm_05_authoring_session_lifecycle.md` | phase 2 |
| `??` | `reports/performance/perf_rm_08_editor_asset_pipeline.md` | phase 2 |
| `??` | `reports/performance/perf_rm_09a_authoring_snapshot.md` | phase 2 |
| `??` | `reports/performance/perf_rm_09b_application_codec_offload.md` | phase 2 |
| `??` | `reports/performance/plans/2026-08-01-pokemap-perf-rm-05-authoring-session-lifecycle.md` | phase 2 |
| `??` | `reports/performance/plans/2026-08-01-pokemap-perf-rm-08-editor-asset-pipeline.md` | phase 2 |
| `??` | `reports/performance/plans/2026-08-01-pokemap-perf-rm-09a-authoring-snapshot.md` | phase 2 |
| `??` | `reports/performance/plans/2026-08-01-pokemap-perf-rm-09b-application-codec-offload.md` | phase 2 |
| `??` | `reports/performance/plans/2026-08-02-pokemap-perf-phase2-consolidation.md` | phase 2 |
| `??` | `skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc` | hors phase — préservé |
| `??` | `packages/map_core/tool/diagnose_m01_validation.dart` | hors phase — apparu après la consolidation, préservé |
| `??` | `reports/performance/perf_phase2_consolidation.md` | phase 2 — présent rapport |

Avant le commit demandé : 48 fichiers suivis modifiés, dont 43 attribués à la
phase et 5 hors phase ; 26 fichiers non suivis, dont 24 attribués à la phase et
2 hors phase. Le commit doit inclure exclusivement les 67 fichiers de phase et
laisser les cinq fichiers world-map, le `__pycache__` et
`packages/map_core/tool/diagnose_m01_validation.dart` dans le worktree.

## Décisions, non-objectifs et risques résiduels

Décisions : garder les deux observations snapshot ; garder I/O, locks, recovery
et CAS sur l’isolate propriétaire ; utiliser des workers seulement pour le
travail pur ; conserver un cache par projet ; ne jamais présenter une estimation
RGBA comme mémoire native.

Non-objectifs respectés : aucun changement de schema, format JSON, protocole
MCP, frontière workspace ou package ; aucun cache global runtime ; aucune
suppression d’une fenêtre de cohérence ; aucune écriture Git.

Auto-critique :

- RSS reste une mesure process-wide bruitée ; les trois processus et le critère
  par-run limitent ce biais sans le supprimer.
- La baseline RM-09A exigeait une adaptation de chemin du harness HEAD ; le
  checksum/dataset identiques et la commande documentée rendent la comparaison
  contrôlable, mais ce n’est pas un checkout propre exécutable tel quel.
- Les frame timings des journeys macOS incluent le coût du harness et ne
  démontrent pas à eux seuls la fluidité visuelle ; RM-08 les traite
  observation-only et RM-09B ajoute un heartbeat main-isolate préannoncé.
- Le pire run RM-09B (235,493 ms) ne garde qu’environ 14,5 ms de marge sous le
  seuil de 250 ms ; le gate doit rester exécuté sur une lane macOS stable pour
  détecter une régression ou une variance machine future.
- La mémoire native des images n’est pas attribuable avec une API Flutter profile
  stable ; elle reste honnêtement `N/A`.
- Les deux groupes de tests préexistants en échec empêchent de présenter la suite
  éditeur globale comme entièrement verte, malgré les 165 tests de phase verts.

## Revue finale

La passe de clôture a rejoué la checklist issue des trois audits indépendants :

| Constat indépendant | Preuve finale | Verdict |
|---|---|---|
| Sessions stale/racine retenue non imposée | admission candidat, double garde avant/après ouverture, tests de réactivation et mutation stale | levé |
| Seconde observation non bornée et copies RSS | pool de 8, comparaison booléenne byte-exacte, baseline canonique −42,39 % RSS | levé |
| Profil assets non représentatif | trois vrais journeys macOS profile, widgets rendus, A/B, source partagée, cache détruit | levé |
| Benchmark save hors lifecycle production | snapshot Authoring ouvert puis invalidé dans les trois receipts profile | levé |
| Decode des gros projets sur l’isolate appelant | executor ≥1 Mio et test worker forcé sur quatre ressources structurées | levé |

Verdict de clôture : **0 P0, 0 P1 restant**. Les points P2 sont les limites de
mesure déjà déclarées (RSS process-wide, mémoire native image indisponible,
FrameTiming observationnel et cinq tests éditeur préexistants en échec). Ils ne
contredisent aucun critère de sortie des quatre lots. Conclusion :

- `PERF-RM-05` : `DONE` proposé ;
- `PERF-RM-08` : `DONE` proposé ;
- `PERF-RM-09A` : `DONE` proposé ;
- `PERF-RM-09B` : `DONE` proposé.

## Annexes — contenu complet des fichiers créés pendant la consolidation


### `reports/performance/plans/2026-08-02-pokemap-perf-phase2-consolidation.md`

````markdown
# Plan d’exécution — Consolidation de la phase 2 performance

Date : 2 août 2026
Lots : `PERF-RM-05`, `PERF-RM-08`, `PERF-RM-09A`, `PERF-RM-09B`

## Objectif

Fermer les preuves encore partielles de la phase 2 sans affaiblir les
frontières workspace, les contrôles de concurrence, l’ownership des images ou
la parité PokeMap MCP.

## Critères de sortie

- `RM-09A` : Selbrume moyen/p50 sous 400 ms, p95 au plus 1 s, pic RSS réduit
  d’au moins 30 % contre la baseline canonique, checksum et double observation
  inchangés.
- `RM-09B` : sauvegarde éditeur 10 Mio au plus 250 ms sur le chemin lifecycle
  de production, heartbeat UI au plus 16,667 ms, bytes et fingerprint stables,
  conflits avant/après préparation toujours rejetés.
- `RM-08` : trois processus `flutter drive --profile -d macos`, 100 assets,
  huit demandeurs concurrents, dix erreurs, dix cycles A/B, cache précédent
  détruit, diagnostics/frame timings/RSS complets et mémoire native déclarée
  indisponible plutôt qu’inventée.
- `RM-05` : aucune régression du lifecycle de session constatée par les tests
  ciblés et les validations larges.

## Étapes

1. Capturer les mesures fraîches et attribuer les coûts dominants.
2. Poser les portes RED de `RM-09B`, optimiser la validation JSON et remplacer
   les SHA de contrôle redondants par une comparaison byte-exacte off-isolate.
3. Réutiliser sous lock le snapshot lifecycle déjà vérifié et mesurer trois
   sauvegardes 10 Mio sur le câblage production.
4. Ajouter une seconde observation `RM-09A` qui compare les bytes sans créer un
   deuxième conteneur possédé, puis mesurer trois processus AOT Selbrume avec
   `/usr/bin/time -l`.
5. Créer le journey macOS profile `RM-08`, rendre le driver multi-cible et
   produire trois receipts isolés avec le même fingerprint source/fixture.
6. Rejouer les tests ciblés, suites de packages, analyses, build macOS et
   preuves de parité API/JSONL/éditeur/MCP.
7. Faire une revue indépendante, consolider les Evidence Packs et proposer les
   statuts finaux sans effectuer d’écriture Git.

## Non-objectifs

- aucune modification des cinq fichiers world-map préexistants ;
- aucune suppression d’une fenêtre de cohérence ou de récupération ;
- aucun seuil frame arbitraire ajouté après mesure ;
- aucune estimation RGBA présentée comme mémoire native réelle ;
- aucun `git add`, commit, push, stash, reset ou changement de branche.
````

### `packages/map_editor/integration_test/editor_asset_cache_journey_test.dart`

````dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/widgets/environment_element_thumbnail.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _target = 'integration_test/editor_asset_cache_journey_test.dart';
const _assetCount = 100;
const _sourceImageCount = 10;
const _tilesPerSource = _assetCount ~/ _sourceImageCount;
const _cycleCount = 10;
const _duplicateCallers = 8;
const _cacheBudgetBytes = 512 * 1024;
const _memoryGrowthBudgetBytes = 50 * 1024 * 1024;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'profiles the project-scoped asset cache on macOS',
    (tester) async {
      final fixture = await _AssetCachePerformanceFixture.create();
      addTearDown(fixture.dispose);
      final timings = <FrameTiming>[];
      void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);
      var timingsCallbackRegistered = false;

      await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));
      for (var index = 0; index < 3; index++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      SchedulerBinding.instance.addTimingsCallback(captureTimings);
      timingsCallbackRegistered = true;
      addTearDown(
        () {
          if (!timingsCallbackRegistered) return;
          SchedulerBinding.instance.removeTimingsCallback(captureTimings);
          timingsCallbackRegistered = false;
        },
      );

      final rssBeforeJourney = ProcessInfo.currentRss;
      final cycles = <Map<String, Object?>>[];
      var peakEstimatedDecodedBytes = 0;
      for (var cycle = 0; cycle < _cycleCount; cycle++) {
        final projectIndex = cycle % fixture.projectCount;
        final project = fixture.project(projectIndex);
        final cache = EditorImageCache(
          sessionKey: project.sessionKey,
          maximumDecodedBytes: _cacheBudgetBytes,
        );
        final rssBeforeCycle = ProcessInfo.currentRss;
        final stopwatch = Stopwatch()..start();

        Map<String, Object?>? duplicateEvidence;
        if (cycle == 0) {
          final duplicateResults = await Future.wait([
            for (var caller = 0; caller < _duplicateCallers; caller++)
              cache.load(project.assetPaths.first),
          ]);
          expect(
            duplicateResults.every((result) => result.image != null),
            isTrue,
          );
          for (final result in duplicateResults) {
            result.dispose();
          }
          final diagnostics = cache.diagnostics;
          duplicateEvidence = <String, Object?>{
            'callers': _duplicateCallers,
            'hits': diagnostics.hits,
            'misses': diagnostics.misses,
            'inFlightLoads': diagnostics.inFlightLoads,
          };
          expect(diagnostics.misses, 1);
          expect(diagnostics.hits, _duplicateCallers - 1);
          expect(diagnostics.inFlightLoads, 0);
        }

        await tester.pumpWidget(
          _AssetThumbnailJourney(
            cycle: cycle,
            project: project,
            cache: cache,
          ),
        );
        await _pumpUntilLoaded(
          tester,
          cache: cache,
          cycle: cycle,
        );

        expect(find.byType(RawImage), findsNWidgets(_assetCount));
        expect(find.byKey(ValueKey('missing-$cycle')), findsOneWidget);
        final firstPixel = await _firstPixelRgba(
          cache,
          project.assetPaths.first,
        );
        expect(firstPixel, project.firstPixelRgba);

        final loadedDiagnostics = cache.diagnostics;
        peakEstimatedDecodedBytes =
            peakEstimatedDecodedBytes < loadedDiagnostics.peakDecodedBytes
                ? loadedDiagnostics.peakDecodedBytes
                : peakEstimatedDecodedBytes;
        expect(loadedDiagnostics.inFlightLoads, 0);
        expect(
          loadedDiagnostics.residentDecodedBytes,
          lessThanOrEqualTo(_cacheBudgetBytes),
        );
        expect(loadedDiagnostics.evictions, greaterThan(0));
        expect(loadedDiagnostics.missingFiles, 1);
        final rssLoaded = ProcessInfo.currentRss;

        await tester.pumpWidget(
          const CupertinoApp(home: SizedBox.shrink()),
        );
        await tester.pump(const Duration(milliseconds: 16));
        cache.dispose();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        stopwatch.stop();

        final disposedDiagnostics = cache.diagnostics;
        expect(disposedDiagnostics.isDisposed, isTrue);
        expect(disposedDiagnostics.entries, 0);
        expect(disposedDiagnostics.residentDecodedBytes, 0);
        expect(disposedDiagnostics.inFlightLoads, 0);
        cycles.add(<String, Object?>{
          'cycle': cycle + 1,
          'project': project.label,
          'durationUs': stopwatch.elapsedMicroseconds,
          'rssBeforeBytes': rssBeforeCycle,
          'rssLoadedBytes': rssLoaded,
          'rssAfterReleaseBytes': ProcessInfo.currentRss,
          'maxRssBytes': ProcessInfo.maxRss,
          'firstPixelRgba': firstPixel,
          'expectedFirstPixelRgba': project.firstPixelRgba,
          'duplicateEvidence': duplicateEvidence,
          'loadedCache': _diagnosticsJson(loadedDiagnostics),
          'disposedCache': _diagnosticsJson(disposedDiagnostics),
        });
      }

      await tester.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      SchedulerBinding.instance.removeTimingsCallback(captureTimings);
      timingsCallbackRegistered = false;
      final frameMetrics = _frameMetrics(timings);
      expect(frameMetrics['frameCount'], greaterThan(0));
      expect(tester.takeException(), isNull);

      final stabilization = _memoryStabilization(cycles);
      expect(
        stabilization['withinBudget'],
        isTrue,
        reason: 'Released-cycle RSS must stabilize within 50 MiB or 10%.',
      );
      binding.reportData = <String, dynamic>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'editor_asset_cache_journey',
        'target': _target,
        'requestedOutputPath': _requestedOutputPath,
        'executionMode': const bool.fromEnvironment('dart.vm.profile')
            ? 'flutter-profile'
            : 'flutter-debug',
        'fixture': 'synthetic-elements-two-projects-shared-tilesets-64x64',
        'fixtureFingerprint': fixture.fingerprint,
        'warmups': 3,
        'sampleCount': timings.length,
        'iterations': <String, Object?>{
          'assets': _assetCount,
          'sourceImages': _sourceImageCount,
          'duplicateCallers': _duplicateCallers,
          'missingFiles': _cycleCount,
          'cycles': _cycleCount,
          'projectSwitches': _cycleCount - 1,
        },
        'measurementScope': <String, Object?>{
          'flutterFrames': true,
          'renderedEnvironmentElementThumbnails': true,
          'projectScopedCaches': true,
          'buildAndRasterCombined': false,
          'forcedGarbageCollection': false,
        },
        'memory': <String, Object?>{
          'rssBeforeBytes': rssBeforeJourney,
          'rssAfterBytes': ProcessInfo.currentRss,
          'maxRssBytes': ProcessInfo.maxRss,
          'nativeImageBytes': null,
          'nativeImageAvailability':
              'No stable Flutter profile API attributes native CPU/GPU image '
                  'allocations to EditorImageCache.',
          'estimatedResidentDecodedBytes': peakEstimatedDecodedBytes,
          'estimatedResidentDecodedBytesMethod':
              'EditorImageCache sum(width * height * 4); logical estimate, '
                  'not native allocation.',
        },
        'results': cycles,
        'memoryStabilization': stabilization,
        'frameMetrics': frameMetrics,
        'thresholdPolicy': <String, Object?>{
          'frameTimingsObservationOnly': true,
          'memoryGateBytes': _memoryGrowthBudgetBytes,
          'memoryGateRatio': 0.10,
          'memoryGateRequiresEachProcess': true,
        },
      };
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Future<void> _pumpUntilLoaded(
  WidgetTester tester, {
  required EditorImageCache cache,
  required int cycle,
}) async {
  for (var frame = 0; frame < 300; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (cache.diagnostics.inFlightLoads == 0 &&
        find.byType(RawImage).evaluate().length == _assetCount &&
        find.byKey(ValueKey('missing-$cycle')).evaluate().length == 1) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw StateError(
    'Asset cache cycle ${cycle + 1} did not settle within 300 frames: '
    '${_diagnosticsJson(cache.diagnostics)}',
  );
}

Future<List<int>> _firstPixelRgba(
  EditorImageCache cache,
  String path,
) async {
  final result = await cache.load(path);
  final image = result.image;
  if (image == null) {
    throw StateError(
        'Unable to decode the project-switch probe: ${result.failure}');
  }
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null || data.lengthInBytes < 4) {
      throw StateError('The project-switch probe returned no RGBA bytes.');
    }
    return data.buffer.asUint8List(data.offsetInBytes, 4).toList();
  } finally {
    result.dispose();
  }
}

Map<String, Object?> _diagnosticsJson(
  EditorImageCacheDiagnostics diagnostics,
) =>
    <String, Object?>{
      'entries': diagnostics.entries,
      'hits': diagnostics.hits,
      'misses': diagnostics.misses,
      'invalidations': diagnostics.invalidations,
      'missingFiles': diagnostics.missingFiles,
      'readFailures': diagnostics.readFailures,
      'decodeFailures': diagnostics.decodeFailures,
      'disposedImages': diagnostics.disposedImages,
      'maximumDecodedBytes': diagnostics.maximumDecodedBytes,
      'residentDecodedBytes': diagnostics.residentDecodedBytes,
      'peakDecodedBytes': diagnostics.peakDecodedBytes,
      'evictions': diagnostics.evictions,
      'inFlightLoads': diagnostics.inFlightLoads,
      'isDisposed': diagnostics.isDisposed,
    };

Map<String, Object?> _memoryStabilization(
  List<Map<String, Object?>> cycles,
) {
  final released = cycles
      .map((cycle) => cycle['rssAfterReleaseBytes']! as int)
      .toList(growable: false);
  final earlyMedian = _median(released.take(3).toList());
  final lateMedian = _median(released.skip(released.length - 3).toList());
  final growth = lateMedian - earlyMedian;
  final growthRatio = earlyMedian == 0 ? 0.0 : growth / earlyMedian;
  return <String, Object?>{
    'earlyCycles': const <int>[1, 2, 3],
    'lateCycles': const <int>[8, 9, 10],
    'earlyMedianRssBytes': earlyMedian,
    'lateMedianRssBytes': lateMedian,
    'growthBytes': growth,
    'growthRatio': growthRatio,
    'withinByteBudget': growth <= _memoryGrowthBudgetBytes,
    'withinRatioBudget': growthRatio <= 0.10,
    'withinBudget': growth <= _memoryGrowthBudgetBytes || growthRatio <= 0.10,
  };
}

int _median(List<int> values) {
  final sorted = List<int>.of(values)..sort();
  return sorted[sorted.length ~/ 2];
}

Map<String, Object?> _frameMetrics(List<FrameTiming> timings) {
  final build = timings
      .map((timing) => timing.buildDuration.inMicroseconds)
      .toList(growable: false);
  final raster = timings
      .map((timing) => timing.rasterDuration.inMicroseconds)
      .toList(growable: false);
  final spans = timings
      .map((timing) => timing.totalSpan.inMicroseconds)
      .toList(growable: false);
  final sortedBuild = List<int>.of(build)..sort();
  final sortedRaster = List<int>.of(raster)..sort();
  final sortedSpans = List<int>.of(spans)..sort();
  final over16 = spans.where((value) => value > 16670).length;
  final over33 = spans.where((value) => value > 33300).length;
  return <String, Object?>{
    'frameCount': timings.length,
    'buildSamplesMicroseconds': build,
    'rasterSamplesMicroseconds': raster,
    'frameSpanSamplesMicroseconds': spans,
    'buildP50Us': _percentile(sortedBuild, 0.50),
    'buildP95Us': _percentile(sortedBuild, 0.95),
    'buildP99Us': _percentile(sortedBuild, 0.99),
    'rasterP50Us': _percentile(sortedRaster, 0.50),
    'rasterP95Us': _percentile(sortedRaster, 0.95),
    'rasterP99Us': _percentile(sortedRaster, 0.99),
    'frameSpanP50Us': _percentile(sortedSpans, 0.50),
    'frameSpanP95Us': _percentile(sortedSpans, 0.95),
    'frameSpanP99Us': _percentile(sortedSpans, 0.99),
    'framesOver16Point67Milliseconds': over16,
    'framesOver16Point67Rate': timings.isEmpty ? 0 : over16 / timings.length,
    'framesOver33Point3Milliseconds': over33,
    'framesOver33Point3Rate': timings.isEmpty ? 0 : over33 / timings.length,
  };
}

int _percentile(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

final class _AssetThumbnailJourney extends StatelessWidget {
  const _AssetThumbnailJourney({
    required this.cycle,
    required this.project,
    required this.cache,
  });

  final int cycle;
  final _AssetProjectFixture project;
  final EditorImageCache cache;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: SingleChildScrollView(
          child: Wrap(
            children: <Widget>[
              for (var index = 0; index < _assetCount; index++)
                EnvironmentElementThumbnail(
                  manifest: project.manifest,
                  element: project.elements[index],
                  elementId: project.elements[index].id,
                  resolveTilesetPathById: project.resolveTilesetPath,
                  projectRootPath: project.sessionKey,
                  imageCache: cache,
                  size: 32,
                  previewKey: ValueKey('preview-$cycle-$index'),
                  fallbackKey: ValueKey('unexpected-fallback-$cycle-$index'),
                ),
              EnvironmentElementThumbnail(
                manifest: project.manifest,
                element: project.missingElement,
                elementId: project.missingElement.id,
                resolveTilesetPathById: project.resolveTilesetPath,
                projectRootPath: project.sessionKey,
                imageCache: cache,
                size: 32,
                previewKey: ValueKey('unexpected-missing-preview-$cycle'),
                fallbackKey: ValueKey('missing-$cycle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _AssetCachePerformanceFixture {
  const _AssetCachePerformanceFixture({
    required this.root,
    required this.projects,
    required this.fingerprint,
  });

  final Directory root;
  final List<_AssetProjectFixture> projects;
  final String fingerprint;

  int get projectCount => projects.length;

  _AssetProjectFixture project(int index) => projects[index];

  static Future<_AssetCachePerformanceFixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap-rm08-assets-',
    );
    final projects = <_AssetProjectFixture>[];
    final fixtureHashes = <String>[];
    for (var projectIndex = 0; projectIndex < 2; projectIndex++) {
      final directory = await Directory(
        '${root.path}/project_${projectIndex == 0 ? 'a' : 'b'}',
      ).create();
      final assetPaths = <String>[];
      final elements = <ProjectElementEntry>[];
      final pathByTilesetId = <String, String>{};
      for (var sourceIndex = 0;
          sourceIndex < _sourceImageCount;
          sourceIndex++) {
        final tilesetId = 'tileset-$sourceIndex';
        final bytes = _tilesetPng(projectIndex, sourceIndex);
        final path = '${directory.path}/$tilesetId.png';
        await File(path).writeAsBytes(bytes, flush: true);
        assetPaths.add(path);
        pathByTilesetId[tilesetId] = path;
        fixtureHashes.add(sha256.convert(bytes).toString());
        for (var tileIndex = 0; tileIndex < _tilesPerSource; tileIndex++) {
          final assetIndex = sourceIndex * _tilesPerSource + tileIndex;
          elements.add(
            ProjectElementEntry(
              id: 'element-$assetIndex',
              name: 'Element $assetIndex',
              tilesetId: tilesetId,
              categoryId: 'profile',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  tilesetId: tilesetId,
                  source: TilesetSourceRect(x: tileIndex, y: 0),
                ),
              ],
            ),
          );
        }
      }
      const missingTilesetId = 'missing';
      pathByTilesetId[missingTilesetId] = '${directory.path}/missing.png';
      const missingElement = ProjectElementEntry(
        id: 'missing-element',
        name: 'Missing element',
        tilesetId: missingTilesetId,
        categoryId: 'profile',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            tilesetId: missingTilesetId,
            source: TilesetSourceRect(x: 0, y: 0),
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'RM-08 project ${projectIndex == 0 ? 'A' : 'B'}',
        settings: const ProjectSettings(tileWidth: 64, tileHeight: 64),
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        elements: elements,
      );
      projects.add(
        _AssetProjectFixture(
          label: projectIndex == 0 ? 'A' : 'B',
          sessionKey: directory.path,
          manifest: manifest,
          elements: elements,
          missingElement: missingElement,
          assetPaths: assetPaths,
          pathByTilesetId: pathByTilesetId,
          firstPixelRgba: _pixel(projectIndex, 0),
        ),
      );
    }
    return _AssetCachePerformanceFixture(
      root: root,
      projects: projects,
      fingerprint:
          sha256.convert(utf8.encode(jsonEncode(fixtureHashes))).toString(),
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _AssetProjectFixture {
  const _AssetProjectFixture({
    required this.label,
    required this.sessionKey,
    required this.manifest,
    required this.elements,
    required this.missingElement,
    required this.assetPaths,
    required this.pathByTilesetId,
    required this.firstPixelRgba,
  });

  final String label;
  final String sessionKey;
  final ProjectManifest manifest;
  final List<ProjectElementEntry> elements;
  final ProjectElementEntry missingElement;
  final List<String> assetPaths;
  final Map<String, String> pathByTilesetId;
  final List<int> firstPixelRgba;

  String? resolveTilesetPath(String tilesetId) => pathByTilesetId[tilesetId];
}

Uint8List _tilesetPng(int projectIndex, int sourceIndex) {
  final image = img.Image(width: 64 * _tilesPerSource, height: 64);
  for (var tileIndex = 0; tileIndex < _tilesPerSource; tileIndex++) {
    final assetIndex = sourceIndex * _tilesPerSource + tileIndex;
    final rgba = _pixel(projectIndex, assetIndex);
    for (var y = 0; y < 64; y++) {
      for (var x = tileIndex * 64; x < (tileIndex + 1) * 64; x++) {
        image.setPixelRgba(x, y, rgba[0], rgba[1], rgba[2], rgba[3]);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

List<int> _pixel(int projectIndex, int assetIndex) => <int>[
      projectIndex == 0 ? (17 + assetIndex) % 255 : (211 + assetIndex) % 255,
      projectIndex == 0
          ? (101 + assetIndex * 3) % 255
          : (47 + assetIndex * 3) % 255,
      projectIndex == 0
          ? (203 + assetIndex * 7) % 255
          : (89 + assetIndex * 7) % 255,
      255,
    ];
````

### `packages/map_editor/integration_test/editor_codec_offload_journey_test.dart`

````dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/editor_persistence_codec_executor.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _target = 'integration_test/editor_codec_offload_journey_test.dart';
const _requestedPayloadBytes = 10 * 1024 * 1024;
const _saveBudgetUs = 250000;
const _heartbeatBudgetUs = 16667;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'profiles a production-wired 10 MiB editor save on macOS',
    (tester) async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap-rm09b-profile-',
      );
      addTearDown(() async {
        if (await sandbox.exists()) await sandbox.delete(recursive: true);
      });
      final project = ProjectManifest(
        name: 'RM-09B profile project',
        maps: const [],
        tilesets: const [],
        globalProperties: <String, Object?>{
          'payload': 'x' * _requestedPayloadBytes,
        },
      );
      final codec = EditorPersistenceCodecExecutor();
      final projectFile = File('${sandbox.path}/project.json');
      final beforeBytes = await codec.encodeNewProject(project);
      await projectFile.writeAsBytes(beforeBytes, flush: true);

      const projectFiles = EditorProjectFileReader();
      final authoringQueries = AuthoringQueryAdapter(fileReader: projectFiles);
      final authoringLifecycle = EditorAuthoringSessionLifecycle(
        fileReader: projectFiles,
      )..attach(authoringQueries);
      addTearDown(authoringLifecycle.closeAll);
      await authoringLifecycle.activate(sandbox.path);
      await authoringQueries.open(sandbox.path);
      expect(authoringQueries.diagnostics.liveSessions, 1);

      final repository = FileProjectRepository(
        codecExecutor: codec,
        authoringQueries: authoringQueries,
        mapLifecycleTransactions: MapLifecycleTransactionCoordinator(
          MapLifecycleTransactionFileGateway(
            mapRepository: FileMapRepository(),
          ),
        ),
      );
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          ),
        ),
      );
      for (var index = 0; index < 3; index++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final timings = <FrameTiming>[];
      void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);
      var callbackRegistered = true;
      SchedulerBinding.instance.addTimingsCallback(captureTimings);
      addTearDown(() {
        if (!callbackRegistered) return;
        SchedulerBinding.instance.removeTimingsCallback(captureTimings);
        callbackRegistered = false;
      });

      var saveCompleted = false;
      final stopwatch = Stopwatch()..start();
      var previousHeartbeatUs = 0;
      var maxHeartbeatGapUs = 0;
      var heartbeatCount = 0;
      final heartbeat = Timer.periodic(const Duration(milliseconds: 1), (_) {
        final now = stopwatch.elapsedMicroseconds;
        final gap = now - previousHeartbeatUs;
        if (gap > maxHeartbeatGapUs) maxHeartbeatGapUs = gap;
        previousHeartbeatUs = now;
        heartbeatCount++;
      });
      addTearDown(heartbeat.cancel);
      final saving = repository
          .saveProject(project, projectFile.path)
          .whenComplete(() => saveCompleted = true);
      var heartbeatPumps = 0;
      while (!saveCompleted && heartbeatPumps < 600) {
        await tester.pump(const Duration(milliseconds: 8));
        await Future<void>.delayed(const Duration(milliseconds: 1));
        heartbeatPumps++;
      }
      await saving;
      final finalHeartbeatGapUs =
          stopwatch.elapsedMicroseconds - previousHeartbeatUs;
      if (finalHeartbeatGapUs > maxHeartbeatGapUs) {
        maxHeartbeatGapUs = finalHeartbeatGapUs;
      }
      heartbeat.cancel();
      stopwatch.stop();
      expect(saveCompleted, isTrue);
      expect(authoringQueries.diagnostics.liveSessions, 0);

      for (var index = 0; index < 3; index++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      SchedulerBinding.instance.removeTimingsCallback(captureTimings);
      callbackRegistered = false;

      final frameMetrics = _frameMetrics(timings);
      const isProfile = bool.fromEnvironment('dart.vm.profile');
      final afterBytes = await projectFile.readAsBytes();
      final beforeFingerprint = narrativeEventBytesFingerprint(beforeBytes);
      final afterFingerprint = narrativeEventBytesFingerprint(afterBytes);
      expect(afterFingerprint, beforeFingerprint);
      if (isProfile) {
        expect(stopwatch.elapsedMicroseconds, lessThanOrEqualTo(_saveBudgetUs));
        expect(maxHeartbeatGapUs, lessThanOrEqualTo(_heartbeatBudgetUs));
      }
      expect(timings, isNotEmpty);
      expect(tester.takeException(), isNull);

      binding.reportData = <String, dynamic>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'editor_codec_offload_journey',
        'target': _target,
        'requestedOutputPath': _requestedOutputPath,
        'executionMode': isProfile ? 'flutter-profile' : 'flutter-debug',
        'repositoryMode':
            'production-lifecycle-with-authoring-snapshot-invalidation',
        'requestedPayloadBytes': _requestedPayloadBytes,
        'encodedBytes': afterBytes.length,
        'elapsedUs': stopwatch.elapsedMicroseconds,
        'heartbeatPumps': heartbeatPumps,
        'heartbeatMetrics': <String, Object?>{
          'timerCount': heartbeatCount,
          'maxGapUs': maxHeartbeatGapUs,
        },
        'fingerprint': afterFingerprint,
        'authoringSnapshotInvalidated':
            authoringQueries.diagnostics.liveSessions == 0,
        'codecDiagnostics': <String, Object?>{
          'localOperations': codec.diagnostics.localOperations,
          'workerOperations': codec.diagnostics.workerOperations,
          'workerFailures': codec.diagnostics.workerFailures,
        },
        'frameMetrics': frameMetrics.toJson(),
        'frameMetricsAcceptance': 'observation-only',
        'performanceGates': <String, Object?>{
          'saveMaxUs': _saveBudgetUs,
          'heartbeatMaxGapUs': _heartbeatBudgetUs,
          'requiresEveryProcess': true,
          'enforced': isProfile,
        },
      };
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

_FrameMetrics _frameMetrics(List<FrameTiming> timings) {
  final spans = timings
      .map((timing) => timing.totalSpan.inMicroseconds)
      .toList(growable: false);
  final sorted = List<int>.of(spans)..sort();
  return _FrameMetrics(
    samplesUs: spans,
    p50Us: _percentile(sorted, 0.50),
    p95Us: _percentile(sorted, 0.95),
    p99Us: _percentile(sorted, 0.99),
    maxSpanUs: sorted.isEmpty ? 0 : sorted.last,
  );
}

int _percentile(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

final class _FrameMetrics {
  const _FrameMetrics({
    required this.samplesUs,
    required this.p50Us,
    required this.p95Us,
    required this.p99Us,
    required this.maxSpanUs,
  });

  final List<int> samplesUs;
  final int p50Us;
  final int p95Us;
  final int p99Us;
  final int maxSpanUs;

  Map<String, Object?> toJson() => <String, Object?>{
        'frameCount': samplesUs.length,
        'samplesUs': samplesUs,
        'p50Us': p50Us,
        'p95Us': p95Us,
        'p99Us': p99Us,
        'maxUs': maxSpanUs,
      };
}
````


## Annexes complémentaires — contenu final des fichiers créés puis modifiés pendant la consolidation

### `packages/map_authoring/test/workspace/project_snapshot_concurrency_test.dart`

````dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSnapshotLoader concurrent observations', () {
    test(
      'rejects a map changed between its first and second observation',
      () async {
        final fixture = _CanonicalSnapshotFixture.create();
        final harness = await _SnapshotHarness.open(fixture);
        harness.reader.onRead = (relativePath, observation, canonicalBytes) {
          if (relativePath == 'maps/zeta.json' && observation == 2) {
            // The second payload remains valid map JSON. This proves rejection
            // comes from coherence checking rather than from decode failure.
            return _mapBytes('zeta', name: 'Zeta changed concurrently');
          }
          return canonicalBytes;
        };

        await expectLater(
          () => harness.loader.load(harness.opened.projectHandle),
          throwsA(
            isA<ProjectSnapshotException>().having(
              (error) => error.code,
              'code',
              'project.changed_during_snapshot',
            ),
          ),
        );

        expect(harness.reader.readCount('maps/zeta.json'), 2);
      },
    );

    test('fails closed when a map disappears before its second observation',
        () async {
      final fixture = _CanonicalSnapshotFixture.create();
      final harness = await _SnapshotHarness.open(fixture);
      harness.reader.onRead = (relativePath, observation, canonicalBytes) {
        if (relativePath == 'maps/zeta.json' && observation == 2) {
          throw const WorkspaceAccessException(
            'workspace.file_unavailable',
            'The requested project resource is unavailable.',
          );
        }
        return canonicalBytes;
      };

      await expectLater(
        () => harness.loader.load(harness.opened.projectHandle),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.file_unavailable',
          ),
        ),
      );

      expect(harness.reader.readCount('maps/zeta.json'), 2);
    });

    test(
      'preserves canonical bytes, fingerprints, order, and two reads',
      () async {
        final fixture = _CanonicalSnapshotFixture.create();
        final harness = await _SnapshotHarness.open(fixture);

        final snapshot =
            await harness.loader.load(harness.opened.projectHandle);

        final canonicalResources = fixture.resourcesByIdentity.entries
            .map(
              (entry) => NarrativeProjectFingerprintEntry(
                relativePath: entry.value.relativePath,
                bytes: entry.value.bytes,
              ),
            )
            .toList(growable: false);
        expect(
          snapshot.revision,
          computeNarrativeProjectFingerprint(canonicalResources),
        );
        for (final entry in fixture.resourcesByIdentity.entries) {
          final identity = entry.key;
          final resource = entry.value;
          expect(
            snapshot.resourceFingerprints[identity],
            computeNarrativeProjectFingerprint([
              NarrativeProjectFingerprintEntry(
                relativePath: resource.relativePath,
                bytes: resource.bytes,
              ),
            ]),
            reason: 'fingerprint for $identity must use its canonical bytes',
          );
          expect(
            snapshot.resourceBytes(identity),
            resource.bytes,
            reason: 'pre-image for $identity must be byte-identical',
          );
          expect(
            snapshot.resourceStorageKeys[identity],
            resource.relativePath,
          );
        }

        // Manifest order is deliberately zeta then alpha. Public projections
        // remain deterministic independently of that authoring order.
        expect(snapshot.maps.map((map) => map.id), ['alpha', 'zeta']);
        expect(
          snapshot.resourceFingerprints.keys,
          [
            assetCatalogResourceIdentity,
            dialogueSourceResourceIdentity('intro'),
            'map:alpha',
            'map:zeta',
            'project',
          ],
        );
        expect(
          snapshot.resourceStorageKeys.keys,
          snapshot.resourceFingerprints.keys,
        );

        // The successful loader contract is exactly two observations of each
        // returned resource. Opening the handle happened before counters were
        // reset, so its independent manifest read is intentionally excluded.
        expect(harness.reader.readLog, hasLength(10));
        for (final resource in fixture.resourcesByIdentity.values) {
          expect(
            harness.reader.readCount(resource.relativePath),
            2,
            reason: '${resource.relativePath} must be observed exactly twice',
          );
        }
      },
    );

    test('performs the second observation concurrently', () async {
      final fixture = _CanonicalSnapshotFixture.create();
      final harness = await _SnapshotHarness.open(fixture);
      var activeSecondReads = 0;
      var maximumConcurrentSecondReads = 0;
      harness.reader.onRead = (
        relativePath,
        observation,
        canonicalBytes,
      ) async {
        if (observation == 2) {
          activeSecondReads++;
          if (activeSecondReads > maximumConcurrentSecondReads) {
            maximumConcurrentSecondReads = activeSecondReads;
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
          activeSecondReads--;
        }
        return canonicalBytes;
      };

      await harness.loader.load(harness.opened.projectHandle);

      expect(maximumConcurrentSecondReads, greaterThan(1));
    });

    test('bounds second-observation concurrency for large catalogs', () async {
      final fixture = _CanonicalSnapshotFixture.withMapCount(20);
      final harness = await _SnapshotHarness.open(
        fixture,
        maxConcurrentSecondObservations: 4,
      );
      var activeSecondReads = 0;
      var maximumConcurrentSecondReads = 0;
      harness.reader.onRead = (
        relativePath,
        observation,
        canonicalBytes,
      ) async {
        if (observation == 2) {
          activeSecondReads++;
          if (activeSecondReads > maximumConcurrentSecondReads) {
            maximumConcurrentSecondReads = activeSecondReads;
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
          activeSecondReads--;
        }
        return canonicalBytes;
      };

      await harness.loader.load(harness.opened.projectHandle);

      expect(maximumConcurrentSecondReads, greaterThan(1));
      expect(maximumConcurrentSecondReads, lessThanOrEqualTo(4));
    });

    test('offloads large structured resource decoding through the executor',
        () async {
      final worker = _CountingDecodeWorker();
      final harness = await _SnapshotHarness.open(
        _CanonicalSnapshotFixture.create(),
        decodeExecutor: ProjectSnapshotDecodeExecutor(
          offloadThresholdBytes: 0,
          workerRunner: worker.run,
        ),
      );

      final snapshot = await harness.loader.load(harness.opened.projectHandle);

      expect(snapshot.maps, hasLength(2));
      expect(worker.calls, 4);
    });
  });
}

final class _CountingDecodeWorker {
  var calls = 0;

  Future<T> run<T>(T Function() operation) async {
    calls++;
    return operation();
  }
}

typedef _ReadInterceptor = FutureOr<List<int>> Function(
  String relativePath,
  int observation,
  List<int> canonicalBytes,
);

final class _SnapshotHarness {
  const _SnapshotHarness({
    required this.reader,
    required this.loader,
    required this.opened,
  });

  static Future<_SnapshotHarness> open(
    _CanonicalSnapshotFixture fixture, {
    int maxConcurrentSecondObservations = 8,
    ProjectSnapshotDecodeExecutor? decodeExecutor,
  }) async {
    final reader = _MemoryProjectFileReader(
      allowedRoot: fixture.allowedRoot,
      projectRoot: fixture.projectRoot,
      resources: fixture.resourcesByPath,
    );
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [fixture.allowedRoot],
      fileReader: reader,
    );
    var token = 0;
    final handles = WorkspaceHandleStore(
      clock: () => DateTime.utc(2026, 8, 2, 12),
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    final openService = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await openService.openProject(fixture.projectRoot);

    // Snapshot read counts must not accidentally include ProjectOpenService's
    // own manifest validation read.
    reader.resetObservations();
    return _SnapshotHarness(
      reader: reader,
      loader: ProjectSnapshotLoader(
        handles: handles,
        maxConcurrentSecondObservations: maxConcurrentSecondObservations,
        decodeExecutor: decodeExecutor,
      ),
      opened: opened,
    );
  }

  final _MemoryProjectFileReader reader;
  final ProjectSnapshotLoader loader;
  final OpenedProject opened;
}

/// Complete in-memory implementation of the filesystem port used by the real
/// workspace policy, open service, handle store, and snapshot loader.
///
/// The fake only controls what each disk observation returns; assertions stay
/// focused on the production snapshot contract rather than fake interactions.
final class _MemoryProjectFileReader implements ProjectFileReader {
  _MemoryProjectFileReader({
    required this.allowedRoot,
    required this.projectRoot,
    required Map<String, List<int>> resources,
  }) : _resources = {
          for (final entry in resources.entries)
            entry.key: List<int>.unmodifiable(entry.value),
        };

  final String allowedRoot;
  final String projectRoot;
  final Map<String, List<int>> _resources;
  final List<String> readLog = [];
  final Map<String, int> _readCounts = {};
  _ReadInterceptor? onRead;

  @override
  Future<String> canonicalizeDirectory(String path) async {
    if (path == allowedRoot || path == projectRoot) return path;
    throw const WorkspaceAccessException(
      'workspace.directory_unavailable',
      'The requested workspace root is unavailable.',
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (projectRoot != this.projectRoot) {
      throw const WorkspaceAccessException(
        'workspace.path_outside_project',
        'The requested project resource resolves outside the project.',
      );
    }
    final bytes = _resources[relativePath];
    if (bytes == null) {
      throw const WorkspaceAccessException(
        'workspace.file_unavailable',
        'The requested project resource is unavailable.',
      );
    }
    final observation = (_readCounts[relativePath] ?? 0) + 1;
    _readCounts[relativePath] = observation;
    readLog.add(relativePath);
    final observed =
        await (onRead?.call(relativePath, observation, bytes) ?? bytes);
    return List<int>.unmodifiable(observed);
  }

  int readCount(String relativePath) => _readCounts[relativePath] ?? 0;

  void resetObservations() {
    readLog.clear();
    _readCounts.clear();
  }
}

final class _CanonicalSnapshotFixture {
  const _CanonicalSnapshotFixture({
    required this.allowedRoot,
    required this.projectRoot,
    required this.resourcesByIdentity,
  });

  factory _CanonicalSnapshotFixture.create() {
    final allowedRoot = '${Platform.pathSeparator}workspace';
    final manifestBytes = utf8.encode(
      jsonEncode({
        'name': 'Snapshot Concurrency Characterization',
        'version': 'v1',
        'maps': [
          _mapEntry('zeta', 'maps/zeta.json'),
          _mapEntry('alpha', 'maps/alpha.json'),
        ],
        'tilesets': <Object?>[],
        'dialogues': const [
          {
            'id': 'intro',
            'name': 'Intro',
            'relativePath': 'dialogues/intro.yarn',
          },
        ],
      }),
    );
    return _CanonicalSnapshotFixture(
      allowedRoot: allowedRoot,
      projectRoot: '$allowedRoot${Platform.pathSeparator}project',
      resourcesByIdentity: {
        'project': _CanonicalResource('project.json', manifestBytes),
        'map:zeta': _CanonicalResource(
          'maps/zeta.json',
          _mapBytes('zeta'),
        ),
        'map:alpha': _CanonicalResource(
          'maps/alpha.json',
          _mapBytes('alpha'),
        ),
        dialogueSourceResourceIdentity('intro'): _CanonicalResource(
          'dialogues/intro.yarn',
          utf8.encode('title: Start\n---\nBonjour\n===\n'),
        ),
        assetCatalogResourceIdentity: _CanonicalResource(
          assetCatalogStorageKey,
          utf8.encode(jsonEncode({'schemaVersion': 1, 'records': []})),
        ),
      },
    );
  }

  factory _CanonicalSnapshotFixture.withMapCount(int mapCount) {
    final allowedRoot = '${Platform.pathSeparator}workspace';
    final mapEntries = <Map<String, Object?>>[];
    final resources = <String, _CanonicalResource>{};
    for (var index = 0; index < mapCount; index++) {
      final id = 'map_$index';
      final relativePath = 'maps/$id.json';
      mapEntries.add(_mapEntry(id, relativePath));
      resources['map:$id'] = _CanonicalResource(
        relativePath,
        _mapBytes(id),
      );
    }
    final manifestBytes = utf8.encode(
      jsonEncode({
        'name': 'Bounded Snapshot Concurrency',
        'version': 'v1',
        'maps': mapEntries,
        'tilesets': <Object?>[],
      }),
    );
    return _CanonicalSnapshotFixture(
      allowedRoot: allowedRoot,
      projectRoot: '$allowedRoot${Platform.pathSeparator}project',
      resourcesByIdentity: <String, _CanonicalResource>{
        'project': _CanonicalResource('project.json', manifestBytes),
        ...resources,
        assetCatalogResourceIdentity: _CanonicalResource(
          assetCatalogStorageKey,
          utf8.encode(jsonEncode({'schemaVersion': 1, 'records': []})),
        ),
      },
    );
  }

  final String allowedRoot;
  final String projectRoot;
  final Map<String, _CanonicalResource> resourcesByIdentity;

  Map<String, List<int>> get resourcesByPath => {
        for (final resource in resourcesByIdentity.values)
          resource.relativePath: resource.bytes,
      };
}

final class _CanonicalResource {
  const _CanonicalResource(this.relativePath, this.bytes);

  final String relativePath;
  final List<int> bytes;
}

Map<String, Object?> _mapEntry(String id, String relativePath) => {
      'id': id,
      'name': id,
      'relativePath': relativePath,
      'role': 'exterior',
      'sortOrder': 0,
    };

List<int> _mapBytes(String id, {String? name}) => utf8.encode(
      jsonEncode({
        'id': id,
        'name': name ?? id,
        'size': {'width': 2, 'height': 2},
        'version': 'v1',
        'layers': <Object?>[],
      }),
    );
````

### `packages/map_editor/benchmark/authoring_session_lifecycle.dart`

````dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

import '../../../tool/performance/benchmark_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const {'roots', 'output'},
    );
    final rootCount = cli.positiveInt('roots', fallback: 10);
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_editor');
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_authoring_lifecycle_',
    );
    try {
      final roots = await Future.wait([
        for (var index = 0; index < rootCount; index += 1)
          _writeFixture(sandbox, index),
      ]);
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
        ..attach(queries)
        ..attach(mutations);
      final rssBefore = ProcessInfo.currentRss;
      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < roots.length; index += 1) {
        final root = roots[index];
        await lifecycle.prepareCandidate(root.path);
        await queries.open(root.path);
        await mutations.plan(
          root.path,
          actionId: 'map.save',
          parameters: {
            'map': _map.copyWith(name: 'Candidate $index').toJson(),
          },
          idempotencyKey: 'lifecycle_$index',
        );
        await lifecycle.activate(root.path);
        _requireBounded(queries.diagnostics, label: 'query');
        _requireBounded(mutations.diagnostics, label: 'mutation');
      }
      stopwatch.stop();
      final rssAfter = ProcessInfo.currentRss;
      final queryDiagnostics = queries.diagnostics;
      final mutationDiagnostics = mutations.diagnostics;
      final result = <String, Object?>{
        'rootCount': rootCount,
        'elapsedUs': stopwatch.elapsedMicroseconds,
        'rssBeforeBytes': rssBefore,
        'rssAfterBytes': rssAfter,
        'rssGrowthBytes': rssAfter - rssBefore,
        'activeRoot': lifecycle.activeRoot,
        'participantCount': lifecycle.participantCount,
        'query': _diagnosticsJson(queryDiagnostics),
        'mutation': _diagnosticsJson(mutationDiagnostics),
      };
      final receipt = await performanceReceipt(
        benchmark: 'authoring_session_lifecycle',
        warmups: 0,
        sampleCount: 1,
        arguments: [
          'benchmark/authoring_session_lifecycle.dart',
          ...arguments,
        ],
        metadata: {'rootCount': rootCount, 'gcMode': 'not available in AOT'},
        results: [result],
      );
      await writePerformanceReceipt(
        outputPath: outputPath,
        packageName: 'map_editor',
        receipt: receipt,
      );
      await lifecycle.closeAll();
    } finally {
      await sandbox.delete(recursive: true);
    }
  } on FormatException catch (error) {
    stderr.writeln('authoring_session_lifecycle: ${error.message}');
    exitCode = 64;
  }
}

Future<Directory> _writeFixture(Directory sandbox, int index) async {
  final root = await Directory(p.join(sandbox.path, 'project_$index')).create();
  final maps = await Directory(p.join(root.path, 'maps')).create();
  await File(p.join(root.path, 'project.json')).writeAsString(
    jsonEncode(_project.copyWith(name: 'Lifecycle project $index').toJson()),
  );
  await File(p.join(maps.path, 'alpha.json'))
      .writeAsString(jsonEncode(_map.toJson()));
  return root;
}

void _requireBounded(
  EditorAuthoringSessionDiagnostics diagnostics, {
  required String label,
}) {
  if (diagnostics.liveSessions != 1 ||
      diagnostics.candidateRoot != null ||
      diagnostics.openingSessions != 0 ||
      diagnostics.retiringSessions != 0 ||
      diagnostics.activeOperations != 0) {
    throw StateError('$label sessions escaped the mono-project bound.');
  }
}

Map<String, Object?> _diagnosticsJson(
  EditorAuthoringSessionDiagnostics diagnostics,
) =>
    {
      'retainedRoot': diagnostics.retainedRoot,
      'candidateRoot': diagnostics.candidateRoot,
      'liveSessions': diagnostics.liveSessions,
      'openingSessions': diagnostics.openingSessions,
      'retiringSessions': diagnostics.retiringSessions,
      'activeOperations': diagnostics.activeOperations,
      'closeCount': diagnostics.closeCount,
    };

const _project = ProjectManifest(
  name: 'Lifecycle project',
  maps: [
    ProjectMapEntry(
      id: 'alpha',
      name: 'Alpha',
      relativePath: 'maps/alpha.json',
    ),
  ],
  tilesets: [],
);

const _map = MapData(
  id: 'alpha',
  name: 'Alpha',
  size: GridSize(width: 2, height: 2),
  version: ProjectVersion.v3,
  visualStack: MapVisualStackConfig.canonicalV1,
  layers: [
    MapLayer.tile(id: 'l_base', name: 'Base', tiles: [0, 0, 0, 0]),
    MapLayer.terrain(
      id: 'l_terrain',
      name: 'Terrain',
      terrains: [
        TerrainType.none,
        TerrainType.none,
        TerrainType.none,
        TerrainType.none,
      ],
    ),
    MapLayer.collision(
      id: 'l_collisions',
      name: 'Collisions',
      collisions: [false, false, false, false],
    ),
  ],
);
````

### `packages/map_editor/benchmark/editor_codec_offload_profile_test.dart`

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/editor_persistence_codec_executor.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profiles editor codec phases and UI-isolate heartbeat', () async {
    final enforcePerformanceGates =
        Platform.environment['POKEMAP_ENFORCE_PERFORMANCE_GATES'] == '1';
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_editor_codec_profile_',
    );
    try {
      final rows = <Map<String, Object?>>[];
      for (final requestedBytes in const [1024, 102400, 2420033, 10485760]) {
        final project = ProjectManifest(
          name: 'Codec $requestedBytes',
          maps: const [],
          tilesets: const [],
          globalProperties: {'payload': 'x' * requestedBytes},
        );
        final local = EditorPersistenceCodecExecutor(
          offloadThresholdBytes: 1 << 30,
        );
        final thresholded = EditorPersistenceCodecExecutor();

        final localEncode = await _measure(
          () => local.encodeNewProject(project),
        );
        final workerEncode = await _measure(
          () => thresholded.encodeNewProject(project),
        );
        expect(workerEncode.value, localEncode.value);

        final projectDirectory = await Directory(
          '${sandbox.path}/project_$requestedBytes',
        ).create();
        final file = File('${projectDirectory.path}/project.json');
        final writeWatch = Stopwatch()..start();
        await file.writeAsBytes(workerEncode.value, flush: true);
        writeWatch.stop();
        final readWatch = Stopwatch()..start();
        final bytes = await file.readAsBytes();
        readWatch.stop();

        final decodeWatch = Stopwatch()..start();
        final raw = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        decodeWatch.stop();
        final modelWatch = Stopwatch()..start();
        final modeled = ProjectManifest.fromJson(raw);
        modelWatch.stop();
        final validateWatch = Stopwatch()..start();
        ProjectValidator.validate(modeled);
        validateWatch.stop();

        final localDecode = await _measure(
          () => local.decodeValidatedProject(bytes),
        );
        final workerDecode = await _measure(
          () => thresholded.decodeValidatedProject(bytes),
        );
        expect(workerDecode.value, localDecode.value);
        expect(workerDecode.value, project);
        final localSavePrepare = await _measure(
          () => local.prepareExistingProjectUpdate(
            currentBytes: bytes,
            project: project,
          ),
        );
        final workerSavePrepare = await _measure(
          () => thresholded.prepareExistingProjectUpdate(
            currentBytes: bytes,
            project: project,
          ),
        );
        expect(workerSavePrepare.value.bytes, localSavePrepare.value.bytes);
        final localFingerprint = await _measure(
          () => local.fingerprintProjectBytes(bytes),
        );
        final workerFingerprint = await _measure(
          () => thresholded.fingerprintProjectBytes(bytes),
        );
        expect(workerFingerprint.value, localFingerprint.value);
        expect(workerSavePrepare.value.bytes, bytes);
        const projectFiles = EditorProjectFileReader();
        final authoringQueries = AuthoringQueryAdapter(
          fileReader: projectFiles,
        );
        final authoringLifecycle = EditorAuthoringSessionLifecycle(
          fileReader: projectFiles,
        )..attach(authoringQueries);
        await authoringLifecycle.activate(projectDirectory.path);
        await authoringQueries.open(projectDirectory.path);
        expect(authoringQueries.diagnostics.liveSessions, 1);
        late final _HeartbeatMeasurement<void> repositorySave;
        try {
          final repository = FileProjectRepository(
            codecExecutor: EditorPersistenceCodecExecutor(),
            authoringQueries: authoringQueries,
            mapLifecycleTransactions: MapLifecycleTransactionCoordinator(
              MapLifecycleTransactionFileGateway(
                mapRepository: FileMapRepository(),
              ),
            ),
          );
          repositorySave = await _measure(
            () => repository.saveProject(project, file.path),
          );
        } finally {
          expect(authoringQueries.diagnostics.liveSessions, 0);
          await authoringLifecycle.closeAll();
        }
        expect(
          narrativeEventBytesFingerprint(await file.readAsBytes()),
          narrativeEventBytesFingerprint(bytes),
        );
        if (enforcePerformanceGates && requestedBytes == 10485760) {
          expect(
            repositorySave.elapsedUs,
            lessThanOrEqualTo(250000),
            reason: '10 MiB editor save must remain within the RM-09B gate.',
          );
          expect(
            repositorySave.maxHeartbeatGapUs,
            lessThanOrEqualTo(16667),
            reason: '10 MiB editor save must not miss a 60 Hz UI heartbeat.',
          );
        }
        rows.add({
          'requestedPayloadBytes': requestedBytes,
          'encodedBytes': bytes.length,
          'fingerprint': narrativeEventBytesFingerprint(bytes),
          'readUs': readWatch.elapsedMicroseconds,
          'decodeJsonUs': decodeWatch.elapsedMicroseconds,
          'modelUs': modelWatch.elapsedMicroseconds,
          'validateUs': validateWatch.elapsedMicroseconds,
          'writeUs': writeWatch.elapsedMicroseconds,
          'localEncode': localEncode.toJson(),
          'thresholdedEncode': workerEncode.toJson(),
          'localDecode': localDecode.toJson(),
          'thresholdedDecode': workerDecode.toJson(),
          'localSavePrepare': localSavePrepare.toJson(),
          'thresholdedSavePrepare': workerSavePrepare.toJson(),
          'localFingerprint': localFingerprint.toJson(),
          'thresholdedFingerprint': workerFingerprint.toJson(),
          'repositorySave': repositorySave.toJson(),
          'authoringSnapshotInvalidated':
              authoringQueries.diagnostics.liveSessions == 0,
          'codecDiagnostics': {
            'localOperations': thresholded.diagnostics.localOperations,
            'workerOperations': thresholded.diagnostics.workerOperations,
            'workerFailures': thresholded.diagnostics.workerFailures,
          },
        });
      }
      final receipt = <String, Object?>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'editor_codec_offload',
        'executionMode': 'flutter-test-debug',
        'repositoryMode':
            'production-lifecycle-with-authoring-snapshot-invalidation',
        'thresholdBytes':
            EditorPersistenceCodecExecutor.defaultOffloadThresholdBytes,
        'performanceGates': <String, Object?>{
          'editorSave10MiBMaxUs': 250000,
          'uiHeartbeatMaxGapUs': 16667,
          'enforced': enforcePerformanceGates,
        },
        'results': rows,
      };
      await _writeReceiptIfRequested(receipt);
      // ignore: avoid_print
      print(jsonEncode(receipt));
    } finally {
      await sandbox.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> _writeReceiptIfRequested(Map<String, Object?> receipt) async {
  final requested = Platform.environment['POKEMAP_PERF_OUTPUT']?.trim() ?? '';
  if (requested.isEmpty) return;
  final packageRoot = Directory.current.resolveSymbolicLinksSync();
  if (p.isAbsolute(requested)) {
    throw const FormatException(
      'POKEMAP_PERF_OUTPUT must stay inside packages/map_editor.',
    );
  }
  final output = File(p.normalize(p.join(packageRoot, requested))).absolute;
  if (!p.isWithin(packageRoot, output.path)) {
    throw const FormatException(
      'POKEMAP_PERF_OUTPUT must stay inside packages/map_editor.',
    );
  }
  await output.parent.create(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
    flush: true,
  );
}

Future<_HeartbeatMeasurement<T>> _measure<T>(
    Future<T> Function() operation) async {
  final stopwatch = Stopwatch()..start();
  var previousTickUs = 0;
  var maxHeartbeatGapUs = 0;
  var heartbeatCount = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
    final now = stopwatch.elapsedMicroseconds;
    final gap = now - previousTickUs;
    if (gap > maxHeartbeatGapUs) maxHeartbeatGapUs = gap;
    previousTickUs = now;
    heartbeatCount++;
  });
  try {
    final value = await operation();
    final finalGap = stopwatch.elapsedMicroseconds - previousTickUs;
    if (finalGap > maxHeartbeatGapUs) maxHeartbeatGapUs = finalGap;
    return _HeartbeatMeasurement(
      value: value,
      elapsedUs: stopwatch.elapsedMicroseconds,
      heartbeatCount: heartbeatCount,
      maxHeartbeatGapUs: maxHeartbeatGapUs,
    );
  } finally {
    timer.cancel();
    stopwatch.stop();
  }
}

final class _HeartbeatMeasurement<T> {
  const _HeartbeatMeasurement({
    required this.value,
    required this.elapsedUs,
    required this.heartbeatCount,
    required this.maxHeartbeatGapUs,
  });

  final T value;
  final int elapsedUs;
  final int heartbeatCount;
  final int maxHeartbeatGapUs;

  Map<String, Object?> toJson() => {
        'elapsedUs': elapsedUs,
        'heartbeatCount': heartbeatCount,
        'maxHeartbeatGapUs': maxHeartbeatGapUs,
      };
}
````

### `packages/map_editor/lib/src/application/authoring_api/authoring_session_lifecycle.dart`

````dart
import 'package:map_authoring/map_authoring.dart';

/// One editor-private owner of Authoring sessions keyed by canonical root.
abstract interface class EditorAuthoringLifecycleParticipant {
  /// Temporarily authorizes one project candidate during an editor switch.
  Future<void> allowCandidate(String canonicalRoot);

  /// Closes every session except [canonicalRoot].
  Future<void> retainOnly(String canonicalRoot);

  /// Closes the session for [canonicalRoot] when it exists.
  Future<void> closeProject(String canonicalRoot);

  /// Closes every owned session.
  Future<void> closeAll();
}

final class EditorAuthoringStaleSessionException implements Exception {
  const EditorAuthoringStaleSessionException();

  String get code => 'editor.authoring_session_stale';
  String get message =>
      'The project session is no longer active or an authorized candidate.';

  @override
  String toString() => 'EditorAuthoringStaleSessionException: $message';
}

final class EditorAuthoringSessionDiagnostics {
  const EditorAuthoringSessionDiagnostics({
    required this.retainedRoot,
    required this.candidateRoot,
    required this.liveSessions,
    required this.openingSessions,
    required this.retiringSessions,
    required this.activeOperations,
    required this.closeCount,
  });

  final String? retainedRoot;
  final String? candidateRoot;
  final int liveSessions;
  final int openingSessions;
  final int retiringSessions;
  final int activeOperations;
  final int closeCount;
}

/// Coordinates the editor's mono-project Authoring session lifecycle.
///
/// This coordinator is intentionally editor-private. The canonical Authoring
/// API, JSONL transport, and MCP server remain multi-workspace and keep their
/// explicit open/close semantics.
final class EditorAuthoringSessionLifecycle {
  EditorAuthoringSessionLifecycle({required ProjectFileReader fileReader})
      : _fileReader = fileReader;

  final ProjectFileReader _fileReader;
  final List<EditorAuthoringLifecycleParticipant> _participants = [];
  Future<void> _transition = Future<void>.value();
  String? _activeRoot;
  String? _candidateRoot;

  String? get activeRoot => _activeRoot;
  String? get candidateRoot => _candidateRoot;
  int get participantCount => _participants.length;

  void attach(EditorAuthoringLifecycleParticipant participant) {
    if (_participants.any((current) => identical(current, participant))) {
      return;
    }
    _participants.add(participant);
  }

  Future<void> activate(String projectRootPath) => _serialize(() async {
        final canonicalRoot =
            await _fileReader.canonicalizeDirectory(projectRootPath);
        if (_activeRoot == canonicalRoot && _candidateRoot == null) return;
        try {
          await _allSettled(
            _participants.map(
              (participant) => participant.retainOnly(canonicalRoot),
            ),
          );
        } finally {
          // Concrete participants switch their admission boundary before
          // waiting for retired leases to drain. Commit the same fail-closed
          // root even when one close reports an error, so the editor cannot
          // silently reopen the previous project.
          _activeRoot = canonicalRoot;
          _candidateRoot = null;
        }
      });

  Future<void> prepareCandidate(String projectRootPath) => _serialize(() async {
        final canonicalRoot =
            await _fileReader.canonicalizeDirectory(projectRootPath);
        if (_activeRoot == canonicalRoot) {
          if (_candidateRoot == null) return;
          try {
            await _allSettled(
              _participants.map(
                (participant) => participant.retainOnly(canonicalRoot),
              ),
            );
          } finally {
            _candidateRoot = null;
          }
          return;
        }
        if (_candidateRoot == canonicalRoot) return;
        final previous = _candidateRoot;
        if (previous != null) {
          await _allSettled(
            _participants.map(
              (participant) => participant.closeProject(previous),
            ),
          );
        }
        await _allSettled(
          _participants.map(
            (participant) => participant.allowCandidate(canonicalRoot),
          ),
        );
        _candidateRoot = canonicalRoot;
      });

  Future<void> discard(String projectRootPath) => _serialize(() async {
        final canonicalRoot =
            await _fileReader.canonicalizeDirectory(projectRootPath);
        if (_activeRoot == canonicalRoot) return;
        try {
          await _allSettled(
            _participants.map(
              (participant) => participant.closeProject(canonicalRoot),
            ),
          );
        } finally {
          if (_candidateRoot == canonicalRoot) _candidateRoot = null;
        }
      });

  Future<void> closeAll() => _serialize(() async {
        await _allSettled(
          _participants.map((participant) => participant.closeAll()),
        );
        _activeRoot = null;
        _candidateRoot = null;
      });

  Future<void> _serialize(Future<void> Function() operation) {
    final current = _transition.then((_) => operation());
    _transition = current.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return current;
  }
}

Future<void> _allSettled(Iterable<Future<void>> operations) async {
  Object? firstError;
  StackTrace? firstStackTrace;
  await Future.wait<void>(
    operations.map((operation) async {
      try {
        await operation;
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }),
  );
  if (firstError != null) {
    Error.throwWithStackTrace(firstError!, firstStackTrace!);
  }
}
````

### `packages/map_editor/lib/src/infrastructure/repositories/editor_persistence_codec_executor.dart`

````dart
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import '../../application/models/narrative_event_authoring_session.dart';

typedef EditorPersistenceWorkerRunner = Future<T> Function<T>(
  T Function() operation,
);

enum EditorPersistenceCodecFailureKind {
  currentProjectInvalid,
  eventRegistryReadOnly,
  eventRegistryConflict,
  updatedProjectInvalid,
}

final class EditorPersistenceCodecException implements Exception {
  const EditorPersistenceCodecException({
    required this.kind,
    required this.message,
  });

  final EditorPersistenceCodecFailureKind kind;
  final String message;

  @override
  String toString() => 'EditorPersistenceCodecException(${kind.name}): '
      '$message';
}

final class EditorPersistenceCodecDiagnostics {
  const EditorPersistenceCodecDiagnostics({
    required this.localOperations,
    required this.workerOperations,
    required this.workerFailures,
  });

  final int localOperations;
  final int workerOperations;
  final int workerFailures;
}

final class EditorPreparedProjectUpdate {
  const EditorPreparedProjectUpdate({
    required this.bytes,
  });

  final List<int> bytes;
}

/// Executes pure project JSON/model work outside the UI isolate for large
/// payloads. File ownership, locks, recovery gates, revision checks and writes
/// deliberately remain in [FileProjectRepository].
final class EditorPersistenceCodecExecutor {
  EditorPersistenceCodecExecutor({
    this.offloadThresholdBytes = defaultOffloadThresholdBytes,
    EditorPersistenceWorkerRunner? workerRunner,
  }) : _workerRunner = workerRunner ?? _runEditorPersistenceWorker {
    if (offloadThresholdBytes < 0) {
      throw ArgumentError.value(
        offloadThresholdBytes,
        'offloadThresholdBytes',
        'must not be negative',
      );
    }
  }

  /// Phase 0 measurements show JSON costs becoming visible around 1–2 MiB.
  static const int defaultOffloadThresholdBytes = 1024 * 1024;

  final int offloadThresholdBytes;
  final EditorPersistenceWorkerRunner _workerRunner;

  var _localOperations = 0;
  var _workerOperations = 0;
  var _workerFailures = 0;

  EditorPersistenceCodecDiagnostics get diagnostics =>
      EditorPersistenceCodecDiagnostics(
        localOperations: _localOperations,
        workerOperations: _workerOperations,
        workerFailures: _workerFailures,
      );

  Future<Map<String, Object?>> decodeProjectRoot(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => _decodeStrictProjectRoot(ownedBytes),
    );
  }

  Future<ProjectManifest> decodeValidatedProject(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => decodeValidatedNarrativeEventAuthoringProject(ownedBytes).manifest,
    );
  }

  Future<List<int>> encodeNewProject(ProjectManifest project) {
    final projectJson = project.toJson();
    final estimatedBytes = _estimateJsonBytesUpTo(
      projectJson,
      offloadThresholdBytes,
    );
    return _execute(
      estimatedBytes,
      () => utf8.encode(
        const JsonEncoder.withIndent('  ').convert(projectJson),
      ),
    );
  }

  Future<List<int>> mergeAndEncodeProject({
    required Map<String, Object?> currentRoot,
    required ProjectManifest project,
    required int inputByteLength,
  }) {
    final ownedRoot = Map<String, Object?>.from(currentRoot);
    return _execute(
      inputByteLength,
      () => _mergeAndEncodeProject(ownedRoot, project),
    );
  }

  /// Decodes, checks and merges an existing project in one worker transfer.
  ///
  /// The caller still owns the recovery gate, lock, before/live revision
  /// checks and final write. Only pure JSON/model work happens here.
  Future<EditorPreparedProjectUpdate> prepareExistingProjectUpdate({
    required List<int> currentBytes,
    required ProjectManifest project,
  }) {
    final ownedBytes = _ownedBytes(currentBytes);
    final estimatedOutputBytes = ownedBytes.length >= offloadThresholdBytes
        ? ownedBytes.length
        : _estimateJsonBytesUpTo(project.toJson(), offloadThresholdBytes);
    return _execute(
      ownedBytes.length > estimatedOutputBytes
          ? ownedBytes.length
          : estimatedOutputBytes,
      () => _prepareExistingProjectUpdate(ownedBytes, project),
    );
  }

  Future<String> fingerprintProjectBytes(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => narrativeEventBytesFingerprint(ownedBytes),
    );
  }

  Future<bool> projectBytesMatch(List<int> expected, List<int> actual) {
    final ownedExpected = _ownedBytes(expected);
    final ownedActual = _ownedBytes(actual);
    return _execute(
      ownedExpected.length > ownedActual.length
          ? ownedExpected.length
          : ownedActual.length,
      () => _projectBytesMatch(ownedExpected, ownedActual),
    );
  }

  Future<T> _execute<T>(int inputByteLength, T Function() operation) async {
    if (inputByteLength < offloadThresholdBytes) {
      _localOperations++;
      return operation();
    }
    _workerOperations++;
    try {
      return await _workerRunner(operation);
    } on Object {
      _workerFailures++;
      rethrow;
    }
  }
}

Future<T> _runEditorPersistenceWorker<T>(T Function() operation) {
  return Isolate.run(operation);
}

bool _projectBytesMatch(List<int> expected, List<int> actual) {
  if (expected.length != actual.length) return false;
  for (var index = 0; index < expected.length; index++) {
    if (expected[index] != actual[index]) return false;
  }
  return true;
}

Map<String, Object?> _decodeStrictProjectRoot(List<int> bytes) {
  return _strictJsonObject(
    decodeNarrativeEventJsonStrict(utf8.decode(bytes)),
  );
}

List<int> _mergeAndEncodeProject(
  Map<String, Object?> currentRoot,
  ProjectManifest project,
) {
  final serializedProject = _strictJsonObject(project.toJson());
  final nextRoot = Map<String, Object?>.from(currentRoot)
    ..addAll(serializedProject);
  if (currentRoot.containsKey('eventRegistry')) {
    nextRoot['eventRegistry'] = currentRoot['eventRegistry'];
  } else {
    nextRoot.remove('eventRegistry');
  }
  canonicalizeNarrativeEventJson(nextRoot);
  return utf8.encode(
    const JsonEncoder.withIndent('  ').convert(nextRoot),
  );
}

EditorPreparedProjectUpdate _prepareExistingProjectUpdate(
  List<int> currentBytes,
  ProjectManifest project,
) {
  late final Map<String, Object?> currentRoot;
  try {
    currentRoot = _decodeStrictProjectRoot(currentBytes);
  } on Object catch (error) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.currentProjectInvalid,
      message: '$error',
    );
  }

  final currentRegistry = decodeNarrativeEventRegistry(
    currentRoot['eventRegistry'],
  );
  if (!currentRegistry.writable) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.eventRegistryReadOnly,
      message: currentRegistry.diagnostics.join(' '),
    );
  }
  if (!_sameEventRegistry(
    currentRegistry.registryOrNull,
    project.eventRegistry,
  )) {
    throw const EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.eventRegistryConflict,
      message: 'The Event registry changed outside the generic project save.',
    );
  }
  try {
    return EditorPreparedProjectUpdate(
      bytes: _mergeAndEncodeProject(currentRoot, project),
    );
  } on Object catch (error) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.updatedProjectInvalid,
      message: '$error',
    );
  }
}

bool _sameEventRegistry(
  NarrativeEventRegistry? left,
  NarrativeEventRegistry? right,
) {
  return canonicalizeNarrativeEventJson(left?.toJson()) ==
      canonicalizeNarrativeEventJson(right?.toJson());
}

Map<String, Object?> _strictJsonObject(Object? value) {
  if (value is! Map) {
    throw const FormatException('Project root must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Project keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

int _estimateJsonBytesUpTo(Object? value, int limit) {
  if (limit <= 0) return limit;
  if (value == null) return _capToLimit(4, limit);
  if (value is String) return _jsonStringEncodedBytesUpTo(value, limit);
  if (value is num || value is bool) {
    return _capToLimit(value.toString().length, limit);
  }
  if (value is List) {
    var total = _capToLimit(2, limit);
    for (final item in value) {
      if (total >= limit) return limit;
      total += _estimateJsonBytesUpTo(item, limit - total);
      if (total >= limit) return limit;
      total++;
    }
    return _capToLimit(total, limit);
  }
  if (value is Map) {
    var total = _capToLimit(2, limit);
    for (final entry in value.entries) {
      if (total >= limit) return limit;
      total += _jsonStringEncodedBytesUpTo(
        entry.key.toString(),
        limit - total,
      );
      if (total >= limit) return limit;
      total = _capToLimit(total + 2, limit);
      if (total >= limit) return limit;
      total += _estimateJsonBytesUpTo(entry.value, limit - total);
      if (total >= limit) return limit;
      total++;
    }
    return _capToLimit(total, limit);
  }
  return _capToLimit(value.toString().length, limit);
}

int _jsonStringEncodedBytesUpTo(String value, int limit) {
  if (limit <= 0) return limit;
  var total = 2;
  final units = value.codeUnits;
  for (var index = 0; index < units.length; index++) {
    final unit = units[index];
    if (unit == 0x22 || unit == 0x5c) {
      total += 2;
    } else if (unit <= 0x1f) {
      total += switch (unit) {
        0x08 || 0x09 || 0x0a || 0x0c || 0x0d => 2,
        _ => 6,
      };
    } else if (unit <= 0x7f) {
      total += 1;
    } else if (unit <= 0x7ff) {
      total += 2;
    } else if (unit >= 0xd800 &&
        unit <= 0xdbff &&
        index + 1 < units.length &&
        units[index + 1] >= 0xdc00 &&
        units[index + 1] <= 0xdfff) {
      total += 4;
      index++;
    } else {
      total += 3;
    }
    if (total >= limit) return limit;
  }
  return _capToLimit(total, limit);
}

int _capToLimit(int value, int limit) => value < limit ? value : limit;

Uint8List _ownedBytes(List<int> bytes) {
  return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
````

### `packages/map_editor/test/authoring_api/authoring_session_lifecycle_test.dart`

````dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  group('EditorAuthoringSessionLifecycle', () {
    test('switching A to B retains B in every attached participant', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final reads = _FakeLifecycleParticipant()..open('/canonical/a');
      final mutations = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, reads, mutations);

      await lifecycle.activate('/alias/a');
      reads.open('/canonical/b');
      mutations.open('/canonical/b');
      await lifecycle.activate('/alias/b');

      expect(lifecycle.activeRoot, '/canonical/b');
      expect(reads.liveRoots, equals(<String>{'/canonical/b'}));
      expect(mutations.liveRoots, equals(<String>{'/canonical/b'}));
      expect(
        reads.retainOnlyCalls,
        equals(<String>['/canonical/a', '/canonical/b']),
      );
      expect(
        mutations.retainOnlyCalls,
        equals(<String>['/canonical/a', '/canonical/b']),
      );
    });

    test('ten sequential roots leave only the last root alive', () async {
      final aliases = <String, String>{
        for (var index = 1; index <= 10; index += 1)
          '/alias/$index': '/canonical/$index',
      };
      final reader = _CanonicalReader(aliases);
      final reads = _FakeLifecycleParticipant();
      final mutations = _FakeLifecycleParticipant();
      final lifecycle = _lifecycle(reader, reads, mutations);

      for (var index = 1; index <= 10; index += 1) {
        reads.open('/canonical/$index');
        mutations.open('/canonical/$index');
        await lifecycle.activate('/alias/$index');
      }

      expect(lifecycle.activeRoot, '/canonical/10');
      expect(reads.liveRoots, equals(<String>{'/canonical/10'}));
      expect(mutations.liveRoots, equals(<String>{'/canonical/10'}));
      expect(reads.retainOnlyCalls, hasLength(10));
      expect(mutations.retainOnlyCalls, hasLength(10));
    });

    test('activation canonicalizes the requested project root', () async {
      final reader = _CanonicalReader({
        '/selected/project': '/real/project',
      });
      final participant = _FakeLifecycleParticipant()..open('/real/project');
      final lifecycle = _lifecycle(reader, participant);

      await lifecycle.activate('/selected/project');

      expect(reader.canonicalizeCalls, equals(['/selected/project']));
      expect(lifecycle.activeRoot, '/real/project');
      expect(participant.retainOnlyCalls, equals(['/real/project']));
    });

    test('activating the same canonical root twice is idempotent', () async {
      final reader = _CanonicalReader({
        '/alias/one': '/canonical/project',
        '/alias/two': '/canonical/project',
      });
      final participant = _FakeLifecycleParticipant()
        ..open('/canonical/project');
      final lifecycle = _lifecycle(reader, participant);

      await lifecycle.activate('/alias/one');
      await lifecycle.activate('/alias/two');

      expect(lifecycle.activeRoot, '/canonical/project');
      expect(participant.retainOnlyCalls, equals(['/canonical/project']));
    });

    test('closing the lifecycle repeatedly remains safe and empty', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
      });
      final reads = _FakeLifecycleParticipant()..open('/canonical/a');
      final mutations = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, reads, mutations);
      await lifecycle.activate('/alias/a');

      await lifecycle.closeAll();
      await lifecycle.closeAll();

      expect(lifecycle.activeRoot, isNull);
      expect(reads.liveRoots, isEmpty);
      expect(mutations.liveRoots, isEmpty);
    });

    test('discarding a candidate never closes the active root', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');

      await lifecycle.discard('/alias/a');
      participant.open('/canonical/b');
      await lifecycle.discard('/alias/b');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(participant.liveRoots, equals(<String>{'/canonical/a'}));
      expect(participant.closeProjectCalls, equals(['/canonical/b']));
    });

    test('preparing a candidate authorizes only one non-active root', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
        '/alias/c': '/canonical/c',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');

      await lifecycle.prepareCandidate('/alias/b');
      await lifecycle.prepareCandidate('/alias/c');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(lifecycle.candidateRoot, '/canonical/c');
      expect(
        participant.allowCandidateCalls,
        equals(['/canonical/b', '/canonical/c']),
      );
      expect(participant.closeProjectCalls, contains('/canonical/b'));
    });

    test('reactivating the active root retires an outstanding candidate',
        () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');
      await lifecycle.prepareCandidate('/alias/b');
      participant.open('/canonical/b');

      await lifecycle.activate('/alias/a');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(lifecycle.candidateRoot, isNull);
      expect(participant.liveRoots, equals(<String>{'/canonical/a'}));
      expect(
          participant.retainOnlyCalls,
          equals([
            '/canonical/a',
            '/canonical/a',
          ]));
    });

    test('preparing the active root retires an outstanding candidate',
        () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');
      await lifecycle.prepareCandidate('/alias/b');
      participant.open('/canonical/b');

      await lifecycle.prepareCandidate('/alias/a');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(lifecycle.candidateRoot, isNull);
      expect(participant.liveRoots, equals(<String>{'/canonical/a'}));
    });

    test('one participant failure does not skip cleanup of the others',
        () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final failing = _FakeLifecycleParticipant()..open('/canonical/a');
      final healthy = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, failing, healthy);
      await lifecycle.activate('/alias/a');
      failing
        ..open('/canonical/b')
        ..retainOnlyError = StateError('cannot close A');
      healthy.open('/canonical/b');

      await expectLater(
        lifecycle.activate('/alias/b'),
        throwsA(isA<StateError>()),
      );

      // Admission switches fail closed to B even when one retirement reports
      // an error, so stale work cannot reopen A behind the editor state.
      expect(lifecycle.activeRoot, '/canonical/b');
      expect(failing.retainOnlyCalls.last, '/canonical/b');
      expect(healthy.retainOnlyCalls.last, '/canonical/b');
      expect(healthy.liveRoots, equals(<String>{'/canonical/b'}));
    });

    test('an occupied participant delays completion of activation', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final busy = _FakeLifecycleParticipant()..open('/canonical/a');
      final other = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, busy, other);
      await lifecycle.activate('/alias/a');
      busy.open('/canonical/b');
      other.open('/canonical/b');
      final releaseBusyParticipant = Completer<void>();
      busy.retainOnlyBlocker = releaseBusyParticipant;
      var completed = false;

      final switching = lifecycle.activate('/alias/b').whenComplete(() {
        completed = true;
      });
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(lifecycle.activeRoot, '/canonical/a');

      releaseBusyParticipant.complete();
      await switching;

      expect(completed, isTrue);
      expect(lifecycle.activeRoot, '/canonical/b');
      expect(busy.liveRoots, equals(<String>{'/canonical/b'}));
      expect(other.liveRoots, equals(<String>{'/canonical/b'}));
    });

    test('a discarded late opening closes and returns a typed stale failure',
        () async {
      final active = Directory(
        '${Directory.current.parent.parent.path}/examples/'
        'playable_runtime_host/golden_fangame_slice',
      );
      final candidate = Directory(
        '${Directory.current.parent.parent.path}/selbrume',
      );
      final candidateRoot = await candidate.resolveSymbolicLinks();
      final reader = _GatedProjectReader(candidateRoot);
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
        ..attach(queries);
      addTearDown(lifecycle.closeAll);
      await lifecycle.activate(active.path);

      await lifecycle.prepareCandidate(candidate.path);
      final opening = queries.open(candidate.path);
      await reader.started.future;
      final discarding = lifecycle.discard(candidate.path);
      await Future<void>.delayed(Duration.zero);
      reader.release.complete();

      await expectLater(
        opening,
        throwsA(isA<EditorAuthoringStaleSessionException>()),
      );
      await discarding;
      expect(lifecycle.activeRoot, await active.resolveSymbolicLinks());
      expect(queries.diagnostics.liveSessions, 0);
      expect(queries.diagnostics.openingSessions, 0);
      expect(queries.diagnostics.retiringSessions, 0);
      expect(queries.diagnostics.closeCount, 1);
    });

    test('repository providers attach both editor-private adapters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authoringMutationAdapterProvider);
      final lifecycle = container.read(
        editorAuthoringSessionLifecycleProvider,
      );

      expect(lifecycle.participantCount, 2);
    });
  });
}

EditorAuthoringSessionLifecycle _lifecycle(
  ProjectFileReader reader,
  _FakeLifecycleParticipant first, [
  _FakeLifecycleParticipant? second,
]) {
  final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
    ..attach(first);
  if (second != null) lifecycle.attach(second);
  return lifecycle;
}

final class _CanonicalReader implements ProjectFileReader {
  _CanonicalReader(this.canonicalRoots);

  final Map<String, String> canonicalRoots;
  final List<String> canonicalizeCalls = <String>[];

  @override
  Future<String> canonicalizeDirectory(String path) async {
    canonicalizeCalls.add(path);
    return canonicalRoots[path] ?? path;
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    throw UnsupportedError('Lifecycle tests never read project bytes.');
  }
}

final class _GatedProjectReader implements ProjectFileReader {
  _GatedProjectReader(this.gatedRoot);

  final String gatedRoot;
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  static const _delegate = EditorProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (projectRoot == gatedRoot && !started.isCompleted) {
      started.complete();
      await release.future;
    }
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

final class _FakeLifecycleParticipant
    implements EditorAuthoringLifecycleParticipant {
  final Set<String> liveRoots = <String>{};
  final List<String> retainOnlyCalls = <String>[];
  final List<String> closeProjectCalls = <String>[];
  final List<String> allowCandidateCalls = <String>[];
  int closeAllCalls = 0;
  Object? retainOnlyError;
  Completer<void>? retainOnlyBlocker;

  void open(String canonicalRoot) {
    liveRoots.add(canonicalRoot);
  }

  @override
  Future<void> allowCandidate(String canonicalRoot) async {
    allowCandidateCalls.add(canonicalRoot);
  }

  @override
  Future<void> retainOnly(String canonicalRoot) async {
    retainOnlyCalls.add(canonicalRoot);
    final blocker = retainOnlyBlocker;
    if (blocker != null) await blocker.future;
    final error = retainOnlyError;
    if (error != null) throw error;
    liveRoots.removeWhere((root) => root != canonicalRoot);
  }

  @override
  Future<void> closeProject(String canonicalRoot) async {
    closeProjectCalls.add(canonicalRoot);
    liveRoots.remove(canonicalRoot);
  }

  @override
  Future<void> closeAll() async {
    closeAllCalls += 1;
    liveRoots.clear();
  }
}
````

### `packages/map_editor/test/environment_studio/environment_element_thumbnail_async_test.dart`

````dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/widgets/environment_element_thumbnail.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows loading and ignores a stale A to B completion',
      (tester) async {
    final firstImage = await tester.runAsync(() => _image(1, 1));
    final secondImage = await tester.runAsync(() => _image(2, 1));
    addTearDown(firstImage!.dispose);
    addTearDown(secondImage!.dispose);
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);

    await tester.pumpWidget(
      _app(
        cache: cache,
        path: '/project/a.png',
        widgetKey: const Key('thumbnail'),
      ),
    );
    expect(
      find.byKey(const Key('environment-element-thumbnail-loading')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _app(
        cache: cache,
        path: '/project/b.png',
        widgetKey: const Key('thumbnail'),
      ),
    );
    final current = EditorImageLoadResult.success(secondImage.clone());
    cache.complete('/project/b.png', current);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('preview')), findsOneWidget);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 2);

    final stale = EditorImageLoadResult.success(firstImage.clone());
    cache.complete('/project/a.png', stale);
    await tester.pump();
    await tester.pump();

    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 2);
    expect(stale.image!.debugDisposed, isTrue);
  });

  testWidgets('renders the fallback after a typed missing-file result',
      (tester) async {
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);
    const path = '/project/missing.png';

    await tester.pumpWidget(_app(cache: cache, path: path));
    cache.complete(
      path,
      const EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.missingFile,
          path: path,
          message: 'missing',
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('fallback')), findsOneWidget);
    expect(find.byKey(const Key('preview')), findsNothing);
  });

  testWidgets('reloads the same path when the project manifest is replaced',
      (tester) async {
    final firstImage = await tester.runAsync(() => _image(1, 1));
    final secondImage = await tester.runAsync(() => _image(2, 1));
    addTearDown(firstImage!.dispose);
    addTearDown(secondImage!.dispose);
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);
    const path = '/project/revisioned.png';

    await tester.pumpWidget(_app(cache: cache, path: path));
    cache.complete(path, EditorImageLoadResult.success(firstImage.clone()));
    await tester.pump();
    expect(cache.requestCount(path), 1);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 1);

    await tester.pumpWidget(
      _app(
        cache: cache,
        path: path,
        manifest: _manifestRevision2,
      ),
    );

    expect(cache.requestCount(path), 2);
    cache.complete(path, EditorImageLoadResult.success(secondImage.clone()));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 2);
  });
}

Widget _app({
  required _QueuedImageCache cache,
  required String path,
  Key? widgetKey,
  ProjectManifest manifest = _manifest,
}) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      child: EnvironmentElementThumbnail(
        key: widgetKey,
        manifest: manifest,
        element: _element,
        elementId: _element.id,
        resolveTilesetPathById: (_) => path,
        imageCache: cache,
        previewKey: const Key('preview'),
        fallbackKey: const Key('fallback'),
      ),
    ),
  );
}

Future<ui.Image> _image(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xff55aa55),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

final class _QueuedImageCache extends EditorImageCache {
  _QueuedImageCache()
      : super(
          sessionKey: 'environment-thumbnail-test',
          retirementScheduler: (disposeImage) => disposeImage(),
        );

  final Map<String, List<Completer<EditorImageLoadResult>>> _requests = {};

  @override
  Future<EditorImageLoadResult> loadCrop(
    String? path, {
    required ui.Rect sourceRect,
    String variantKey = 'original',
    String sourceVariantKey = 'original',
    EditorImageBytesTransform? transformBytes,
  }) {
    final request = Completer<EditorImageLoadResult>();
    (_requests[path!] ??= <Completer<EditorImageLoadResult>>[]).add(request);
    return request.future;
  }

  void complete(String path, EditorImageLoadResult result) {
    final requests = _requests[path]!;
    requests.firstWhere((request) => !request.isCompleted).complete(result);
  }

  int requestCount(String path) => _requests[path]?.length ?? 0;
}

const _manifest = ProjectManifest(
  name: 'Environment thumbnail',
  settings: ProjectSettings(tileWidth: 1, tileHeight: 1),
  maps: [],
  tilesets: [
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'tiles.png',
    ),
  ],
);

const _manifestRevision2 = ProjectManifest(
  name: 'Environment thumbnail revision 2',
  settings: ProjectSettings(tileWidth: 1, tileHeight: 1),
  maps: [],
  tilesets: [
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'tiles.png',
    ),
  ],
);

const _element = ProjectElementEntry(
  id: 'grass',
  name: 'Grass',
  tilesetId: 'tiles',
  categoryId: 'nature',
  frames: [
    TilesetVisualFrame(
      tilesetId: 'tiles',
      source: TilesetSourceRect(x: 0, y: 0),
    ),
  ],
);
````

### `packages/map_editor/test/infrastructure/editor_persistence_codec_executor_test.dart`

````dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/repositories/editor_persistence_codec_executor.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: const [],
    legacyClaims: const [],
  );
  final before = ProjectManifest(
    name: 'Avant',
    maps: const [],
    tilesets: const [],
    eventRegistry: registry,
  );
  final after = ProjectManifest(
    name: 'Après',
    maps: const [],
    tilesets: const [],
    eventRegistry: registry,
  );

  test('forced local and worker paths produce byte-identical project JSON',
      () async {
    final source = <String, Object?>{
      ...before.toJson(),
      'futureField': <String, Object?>{'kept': true},
    };
    final sourceBytes = utf8.encode(jsonEncode(source));
    final localRunner = _RecordingWorkerRunner();
    final workerRunner = _RecordingWorkerRunner();
    final local = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 1 << 30,
      workerRunner: localRunner.call,
    );
    final worker = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 0,
      workerRunner: workerRunner.call,
    );

    final localUpdate = await local.prepareExistingProjectUpdate(
      currentBytes: sourceBytes,
      project: after,
    );
    final workerUpdate = await worker.prepareExistingProjectUpdate(
      currentBytes: sourceBytes,
      project: after,
    );

    expect(workerUpdate.bytes, localUpdate.bytes);
    final merged =
        jsonDecode(utf8.decode(workerUpdate.bytes)) as Map<String, dynamic>;
    expect(merged['name'], 'Après');
    expect(merged['futureField'], {'kept': true});
    expect(merged['eventRegistry'], registry.toJson());
    expect(localRunner.calls, 0);
    expect(workerRunner.calls, 1);
  });

  test('default worker can decode and validate a project off-isolate',
      () async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(after.toJson()),
    );
    final executor = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 0,
    );

    final decoded = await executor.decodeValidatedProject(bytes);

    expect(decoded, after);
    expect(executor.diagnostics.workerOperations, 1);
    expect(executor.diagnostics.localOperations, 0);
  });

  test('offloads when a small existing project grows beyond the threshold',
      () async {
    final sourceBytes = utf8.encode(jsonEncode(before.toJson()));
    final expanded = ProjectManifest(
      name: 'Expanded',
      maps: const [],
      tilesets: const [],
      eventRegistry: registry,
      globalProperties: <String, Object?>{
        'payload': 'x' * (2 * 1024 * 1024),
      },
    );
    final workerRunner = _RecordingWorkerRunner();
    final executor = EditorPersistenceCodecExecutor(
      workerRunner: workerRunner.call,
    );

    final update = await executor.prepareExistingProjectUpdate(
      currentBytes: sourceBytes,
      project: expanded,
    );

    expect(update.bytes.length, greaterThan(2 * 1024 * 1024));
    expect(workerRunner.calls, 1);
    expect(executor.diagnostics.workerOperations, 1);
  });

  test('forced local and worker paths compare project bytes exactly', () async {
    final expected = List<int>.filled(2 * 1024 * 1024, 7);
    final changed = List<int>.of(expected)..[expected.length - 1] = 8;
    final local = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 1 << 30,
    );
    final workerRunner = _RecordingWorkerRunner();
    final worker = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 0,
      workerRunner: workerRunner.call,
    );

    expect(
        await local.projectBytesMatch(expected, List<int>.of(expected)), true);
    expect(await worker.projectBytesMatch(expected, changed), false);
    expect(await worker.projectBytesMatch(expected, [...expected, 7]), false);
    expect(workerRunner.calls, 2);
  });

  test('worker failure is surfaced without a local retry', () async {
    final executor = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 0,
      workerRunner: <T>(T Function() operation) async {
        throw StateError('worker failed');
      },
    );

    await expectLater(
      executor.encodeNewProject(after),
      throwsA(isA<StateError>()),
    );
    expect(executor.diagnostics.workerFailures, 1);
  });

  test('repository leaves existing bytes untouched when its worker fails',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'pokemap_editor_codec_failure_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/project.json');
    final beforeBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(before.toJson()),
    );
    await file.writeAsBytes(beforeBytes, flush: true);
    final repository = FileProjectRepository(
      codecExecutor: EditorPersistenceCodecExecutor(
        offloadThresholdBytes: 0,
        workerRunner: <T>(T Function() operation) async {
          throw StateError('worker failed');
        },
      ),
    );

    await expectLater(
      repository.saveProject(after, file.path),
      throwsA(isA<EditorPersistenceException>()),
    );

    expect(await file.readAsBytes(), beforeBytes);
  });
}

final class _RecordingWorkerRunner {
  var calls = 0;

  Future<T> call<T>(T Function() operation) async {
    calls++;
    return operation();
  }
}
````
