# BETA-PERF-000 / BETA-PERF-001 — baseline Map Editor

Date : 2026-08-12

Branche : `codex/perf-000a-hermetic-harness`

HEAD demandé au début de la correction : `7036dd80853825b11966cda10519f7ecef859848`

Base après rebase : `baff15fcc420b864201fa367e99ae44e488de365` (`origin/main`)

SHA de code mesuré : `a59e6127e0fdd36d960515beaefa75f48b351761`

Statut proposé des deux tickets : `TO REVIEW`

## Verdict

- BETA-PERF-000 : `PASS technique local`. Les trois drivers recalculent les statistiques et budgets depuis les échantillons bruts, refusent une provenance incomplète, et distinguent maintenant pré-dispatch, mutation/publication, enregistrement canvas et FrameTiming.
- BETA-PERF-001 : `PASS technique local`. Le vrai widget de masque fin est borné pendant le geste, réversible, compatible avec la projection `cells`, et respecte les budgets 1024².
- Verdict de clôture : `PARTIAL / CI pending` tant qu'un run GitHub Actions du SHA final n'a pas produit et publié ses reçus. Aucun ticket ne doit passer en `DONE` avant review humaine.

Les trois reçus locaux canoniques ont été produits séquentiellement, en profile macOS, avec un arbre propre et le même SHA. Ils résident sous `packages/map_editor/build/performance/` et restent des artefacts de build non versionnés.

## Audit initial et anomalies reproduites

Le worktree dédié pointait bien sur `7036dd80853825b11966cda10519f7ecef859848`, mais contenait déjà le travail PERF-000 en cours. Il n'a pas été masqué, restauré ou nettoyé ; il a été audité puis intégré aux commits bornés de la branche.

Les manques ont été reproduits avant correction :

- la sauvegarde d'un masque de collision fin vide recréait des `cells` grossières depuis le padding ; le test attendait `[]` et recevait toute la grille 4 × 4 ;
- les contrats fine-mask acceptaient des P95 de 8 000 µs et 16 700 µs sans les rejeter ;
- le widget ne permettait pas de reproduire puis protéger une lecture alpha asynchrone devenue obsolète ;
- les anciens noms `pointer_to_dispatch` et `canvas.build` donnaient une portée plus large que le travail réellement mesuré ;
- le driver générique acceptait des reçus sans échantillons, aux percentiles falsifiés ou à provenance `unavailable` ;
- le premier journey profile corrigé tentait de sauvegarder la fixture grossière 1024² et échouait avec `authorization.request_too_large`. La matrice 128/256/512/1024 reste mesurée, tandis que le scénario persistant open/undo/save utilise une fixture visuelle 64² compatible avec la limite authoring.

## Choix d'architecture

### Masques fins

Le geste suit la frontière suivante :

```text
pointerMove -> mutation Uint8List locale -> chunks sales -> repaint
pointerUp / changement de mode / Save -> encodage -> projection cells -> publication parent
pointerCancel -> restauration du buffer et du cache de paint
```

Il n'y a ni callback parent, ni filesystem, ni JSON, ni base64 dans `pointerMove`. La sauvegarde recalcule toujours `cells` depuis `collisionMask` lorsqu'un masque fin existe, y compris lorsque la projection est vide. Un jeton de génération empêche une ancienne lecture alpha asynchrone de remplacer une source, un profil ou des dimensions plus récents.

`FineMaskStroke` copie encore le layer complet à l'ouverture du geste. Cela représente environ 1 MiB pour un layer 1024². Cette allocation O(surface) est volontairement conservée comme réserve non bloquante ; une refonte delta-undo serait un autre ticket.

### Instrumentation

- `pointer.pre_dispatch` couvre la validation et la conversion avant mutation ; il n'est pas utilisé comme budget interactif.
- `pointer.to_state_publish` couvre la mutation réelle jusqu'à la publication d'état.
- `canvas.prepare` et `canvas.future_builder_body` nomment précisément leurs portées respectives.
- `canvas.paint_recording` mesure l'enregistrement UI dans un `PictureRecorder`, sans layout, composition ni raster GPU.
- `flutter.frame_total` expose les vrais `FrameTiming` séparément et reste observationnel.
- les compteurs filesystem, JSON et base64 couvrent uniquement les frontières editor/authoring instrumentées. Ils ne prétendent pas observer tout le processus macOS.
- sans recording active, la télémétrie ne conserve aucun sample ou compteur et n'effectue aucun travail proportionnel à la carte.

## Baseline profile macOS

Machine de calibration : macOS 27.0 build 26A5388g, arm64.

Dart : 3.13.0-167.1.beta.

Flutter : 3.46.0-0.3.pre, beta, révision `677d472756f83c14371dd8cc624387065f3d32a7`.

Flame : 1.38.0.

### Journey projet

| Mesure | Samples | P50 | P95 | P99 | Max | Budget/politique | Verdict |
|---|---:|---:|---:|---:|---:|---|---|
| Placement local | 90 | 379 µs | 555 µs | 2 869 µs | 2 869 µs | P95 < 16 000 µs | PASS |
| `pointer.to_state_publish` | 90 | 564 µs | 667 µs | 715 µs | 715 µs | P95 < 8 000 µs | PASS |
| `canvas.paint_recording` | 78 | 58 µs | 132 µs | 155 µs | 155 µs | enregistrement UI | PASS |
| `flutter.frame_total` | 163 | 5 860 µs | 9 643 µs | 25 505 µs | 32 509 µs | observation | OBSERVATION |

Deux frames sur 163 dépassent 16,67 ms ; aucune ne dépasse 33,3 ms. Ce résultat n'est pas substitué au budget du paint et n'est pas maquillé en gate.

La matrice grossière utilise des cellules distinctes. Elle expose honnêtement le coût proportionnel à la surface :

| Extent | Trait | P50 mutation | P95 | P99 | Max | FS/JSON/base64 pendant mutation |
|---:|---:|---:|---:|---:|---:|---:|
| 128² | 1 | 90 µs | 90 µs | 90 µs | 90 µs | 0 |
| 128² | 10 | 161 µs | 233 µs | 233 µs | 233 µs | 0 |
| 128² | 100 | 157 µs | 201 µs | 2 735 µs | 3 445 µs | 0 |
| 128² | 1 000 | 187 µs | 250 µs | 1 234 µs | 3 466 µs | 0 |
| 256² | 1 | 357 µs | 357 µs | 357 µs | 357 µs | 0 |
| 256² | 10 | 689 µs | 762 µs | 762 µs | 762 µs | 0 |
| 256² | 100 | 683 µs | 1 098 µs | 1 391 µs | 1 924 µs | 0 |
| 256² | 1 000 | 738 µs | 1 208 µs | 1 658 µs | 3 146 µs | 0 |
| 512² | 1 | 1 274 µs | 1 274 µs | 1 274 µs | 1 274 µs | 0 |
| 512² | 10 | 2 679 µs | 2 834 µs | 2 834 µs | 2 834 µs | 0 |
| 512² | 100 | 2 731 µs | 4 678 µs | 6 996 µs | 7 643 µs | 0 |
| 512² | 1 000 | 2 755 µs | 4 446 µs | 6 448 µs | 7 731 µs | 0 |
| 1024² | 1 | 5 283 µs | 5 283 µs | 5 283 µs | 5 283 µs | 0 |
| 1024² | 10 | 10 705 µs | 16 446 µs | 16 446 µs | 16 446 µs | 0 |
| 1024² | 100 | 10 783 µs | 13 323 µs | 17 309 µs | 20 002 µs | 0 |
| 1024² | 1 000 | 10 816 µs | 12 603 µs | 19 270 µs | 32 436 µs | 0 |

Cette matrice est une preuve de mesure PERF-000, pas une déclaration que l'ancien chemin grossier 1024² satisfait un budget de 8 ms. Les masques fins corrigés sont mesurés séparément ci-dessous.

### Journey du vrai éditeur de masque fin

| Extent | Pointer P50 | P95 | P99 | Max | Paint P50 | P95 | P99 | Max |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 64² | 11 µs | 24 µs | 39 µs | 39 µs | 264 µs | 324 µs | 326 µs | 326 µs |
| 256² | 88 µs | 105 µs | 144 µs | 144 µs | 706 µs | 812 µs | 905 µs | 905 µs |
| 512² | 304 µs | 343 µs | 373 µs | 373 µs | 1 477 µs | 1 582 µs | 1 584 µs | 1 584 µs |
| 1024² | 1 061 µs | 1 217 µs | 1 219 µs | 1 219 µs | 4 210 µs | 4 650 µs | 7 886 µs | 7 886 µs |

Les gates recalculées par le driver sont : pointer 1024² P95 < 8 000 µs et paint 1024² P95 < 16 700 µs. Les `FrameTiming` restent observationnels ; à 1024², P50/P95/P99/max valent 10 641/20 051/24 299/24 299 µs.

### Projection canvas

| Mode 1024² | P50 | P95 | P99 | Max |
|---|---:|---:|---:|---:|
| Standard | 119 µs | 150 µs | 1 222 µs | 1 222 µs |
| Smart Tiles | 827 µs | 1 028 µs | 1 133 µs | 1 133 µs |
| Ombres | 59 µs | 108 µs | 2 955 µs | 2 955 µs |
| Combiné | 1 061 µs | 1 246 µs | 1 299 µs | 1 299 µs |

Le ratio P95 combiné 1024/128 vaut 1,039 pour un budget de 1,5. À extent 1024, les P95 avec 100, 1 000 et 10 000 éléments placés valent respectivement 100, 72 et 178 µs.

### Mémoire et allocations

| Journey | Octets alloués | Allocations | Heap avant GC | Heap après GC | RSS |
|---|---:|---:|---:|---:|---:|
| Projet interactif | 152 866 176 | 587 020 | 170 777 200 | 116 018 080 | 452 968 448 |
| Masque fin | 32 419 232 | 284 694 | 27 013 520 | 7 552 928 | 225 689 600 |
| Projection canvas | 35 648 480 | 449 991 | 31 560 768 | 5 501 728 | 197 672 960 |
| Soak masque fin, 3 ouvertures | 22 724 640 | 260 691 | 17 318 880 | 7 560 736 | non exposé |

Le GC a été forcé et attesté par le VM service pour chaque mesure. Le soak reste dans son budget de croissance de 32 MiB. Le RSS inclut le heap Dart, Flutter, les buffers graphiques, les bibliothèques et les allocations natives ; il ne représente pas uniquement les données de collision.

## Contrats exécutables

Les drivers refusent désormais :

- un reçu sans `samplesUs`, vide ou avec `sampleCount` incohérent ;
- des P50/P95/P99/max différents des valeurs recalculées ;
- une matrice absente, incomplète ou dupliquée ;
- un booléen `performanceGates=true` contredit par les échantillons ;
- un mode autre que `flutter-profile`, un arbre non propre, un SHA non hexadécimal de 40 caractères, une architecture inconnue ou une toolchain incomplète ;
- une portée de mesure ou de compteurs plus large que la couverture réellement instrumentée.

La fixture projet inclut un PNG déterministe réel, vérifie son existence et son décodage en 128 × 48, et désactive l'auto-restore ainsi que l'update host pendant le journey.

## Fichiers modifiés

### Gouvernance et CI

- `.github/workflows/pokemap_hub_product_certification.yml` : manifestes canoniques, matrice complète et collecte des journeys.
- `AGENTS.md` : fin de ticket en `TO REVIEW`, commit puis rebase, traçabilité Notion.
- `apps/pokemap_hub/test/release/performance_observation_workflow_test.dart` : contrat des chemins du workflow.
- `documentation/reports/editor/perf_000c_map_editor_baseline_2026-08-12.md` : baseline unique et limites.

### `map_authoring`

- `lib/map_authoring_local.dart` : export du hook d'observation.
- `lib/src/api/local_map_authoring_mutation_api.dart`, `lib/src/application/map_mutation_dispatcher.dart` : spans snapshot/plan/apply.
- `lib/src/domains/maps/collision_actions.dart`, `lib/src/domains/maps/map_lifecycle_adapter.dart` : observation codec et cycle de vie.
- `lib/src/support/authoring_performance_observer.dart` : observer opt-in.
- `lib/src/transactions/file_idempotency_store.dart`, `lib/src/transactions/local_transaction_file_gateway.dart` : compteurs filesystem/JSON.
- `test/domains/maps/effective_collision_test.dart`, `test/domains/maps/map_lifecycle_contract_test.dart`, `test/domains/maps/map_lifecycle_transaction_test.dart`, `test/transactions/idempotency_contract_test.dart` : couverture des frontières instrumentées.

### `map_editor` production

- `lib/main.dart`, `lib/src/ui/editor_shell_page.dart`, `test/editor_shell_page_smoke_test.dart`, `test/shell_chrome_test_harness.dart` : journeys hermétiques sans auto-restore/update host.
- `lib/src/application/services/editor_performance_telemetry.dart`, `fine_mask_performance_telemetry.dart` : spans, échantillons, compteurs, garde LIFO et chemin inactif.
- `lib/src/application/authoring_api/authoring_mutation_adapter.dart`, `lib/src/features/editor/state/editor_notifier.dart` : publication, save et authoring observables.
- `lib/src/application/collision_generation/placed_element_auto_collision_generator.dart`, `lib/src/infrastructure/authoring_api/editor_project_file_reader.dart`, `lib/src/ui/assets/editor_image_cache.dart` : frontières codec, filesystem et cache instrumentées.
- `lib/src/ui/canvas/map_canvas.dart`, `lib/src/ui/canvas/map_canvas/map_grid_painter.dart` : portée pointer/build/paint honnête.
- `lib/src/ui/panels/element_collision_editor_sheet.dart` : commit actif et cohérence `collisionMask`/`cells`.
- `lib/src/ui/widgets/element_collision_triple_mask_editor.dart` : draft local, chunks sales, rollback et rejet de readback obsolète.
- `pubspec.yaml`, `pubspec.lock` : dépendance de développement VM service.

### `map_editor` preuves

- `integration_test/editor_project_journey_test.dart`, `editor_canvas_projection_journey_test.dart`, `editor_fine_mask_journey_test.dart`, `integration_test/support/vm_memory_probe.dart` : matrices réelles et mémoire après GC.
- `test/application/services/editor_performance_telemetry_test.dart`, `test/editor_image_cache_test.dart`, `test/map_canvas_pointer_navigation_test.dart` : instrumentation de production et coût désactivé.
- `test/element_collision_editor_sheet_fine_mask_test.dart`, `test/ui/widgets/element_collision_triple_mask_editor_performance_test.dart` : save, cancel, mode, readback et hot path.
- `test/fine_mask_performance_contract_test.dart`, `test/performance_driver_contract_test.dart`, `test/integration_support/vm_memory_probe_test.dart` : contrats adversariaux et VM service.
- `test_driver/fine_mask_performance_driver.dart`, `test_driver/performance_driver.dart`, `test_driver/support/fine_mask_performance_contract.dart` : recalcul fail-closed, budgets et provenance.

## Commandes et résultats frais

- `cd packages/map_authoring && dart test test/transactions/idempotency_contract_test.dart` : 11/11, `All tests passed!`.
- `cd packages/map_authoring && dart analyze lib/src/api/local_map_authoring_mutation_api.dart lib/src/transactions/file_idempotency_store.dart test/transactions/idempotency_contract_test.dart` : `No issues found!`.
- huit fichiers de tests ciblés `map_editor` couvrant télémétrie, masque, sheet, drivers, canvas et cache : 106/106, `All tests passed!`.
- analyse ciblée des vingt fichiers touchés `map_editor` : `No issues found! (5.5s)`.
- `flutter drive --profile` fine-mask : PASS, reçu `editor_fine_mask_journey.json` au SHA `a59e6127e0fdd36d960515beaefa75f48b351761`.
- `flutter drive --profile` project journey : PASS, reçu `editor_project_journey.json` au même SHA.
- `flutter drive --profile` canvas journey : PASS, reçu `editor_canvas_projection_journey.json` au même SHA.

Les suites profile ont été exécutées séquentiellement. Aucune suite globale de collisions fines ni aucun profile concurrent n'a été lancé.

## Auto-critique et risques résiduels

- Aucun blocker de code local n'est identifié.
- Le chemin de collision grossière reste proportionnel à la surface et dépasse 8 ms en 1024² ; la baseline l'expose au lieu de le cacher. PERF-001 porte sur l'éditeur de masque fin corrigé.
- Le premier frame/readback et certains maxima restent bruités ; les gates utilisent les échantillons bruts et le P95, tandis que les vrais FrameTiming sont observationnels.
- Le RSS du journey projet atteint 452 968 448 octets, mais le heap après GC vaut 116 018 080 octets et le soak masque fin est stable. Cela ne prouve pas une fuite native.
- Le buffer rollback d'un trait fin reste O(surface), environ 1 MiB à 1024².
- Les compteurs ne sont pas system-wide ; seuls les appels traversant les frontières editor/authoring instrumentées sont garantis.
- Les artefacts locaux sous `build/` ne remplacent pas un artefact GitHub Actions attaché au SHA final.

## Verdict des passes

- Audit/Architecture : PASS, anciens findings reclassifiés sur le code actuel et portées rendues explicites.
- Implémentation : PASS, hot paths fins locaux et projection legacy cohérente.
- Tests : PASS, contrats positifs et adversariaux verts.
- Build/Validation : PASS local, trois builds profile macOS et reçus au même SHA propre.
- Critique : PASS avec réserves documentées ; CI distante encore requise.
