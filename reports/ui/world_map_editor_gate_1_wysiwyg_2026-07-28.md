# World Map Editor — Gate 1 WYSIWYG

Date de clôture technique : 2026-07-28

Branche : `main`

HEAD de départ et de clôture : `839f6d5e4e4b7905aea401089a5289c5f13c719d`

`origin/main` au contrôle final : `839f6d5e4e4b7905aea401089a5289c5f13c719d`

Lots couverts : `REN-01`, `REN-02`, `REN-03`, `REN-04`

Verdict proposé : **Gate 1 DONE**

## 1. Résumé exécutif

Gate 1 livre un contrat de composition visuelle versionné, pur et partagé entre
`map_editor` et `map_runtime`.

Le résultat important n’est pas seulement « les layers ont été réordonnés » :

- une carte sans `visualStack` conserve exactement le comportement legacy ;
- une carte avec `visualStack.semanticsVersion = 1` exécute une pile canonique,
  top-first dans le document et peinte bottom-to-top ;
- une version future inconnue n’est jamais rabattue silencieusement sur le
  legacy : elle s’ouvre inspectable et strictement en lecture seule dans
  l’éditeur, et échoue explicitement dans la runtime ;
- la version de document `ProjectVersion.v3` sert d’enveloppe de compatibilité
  pour empêcher un ancien lecteur d’ignorer le nouveau champ puis de
  sauvegarder une interprétation legacy ;
- l’éditeur et la runtime délèguent au même plan pur `map_core` ;
- la parité est vérifiée sur une fixture commune avec ordre sensible, alpha,
  opacités, Tile, Terrain, Path, Surface, Border, élément posé et entité au
  premier plan ;
- la migration est explicite, prévisualisée avec le vrai `MapGridPainter`,
  comparée en RGBA, fail-closed, stale-safe, idempotente, annulable et sans
  sauvegarde implicite ;
- les opérations rename/duplicate/delete refusent aussi une sémantique future
  avant tout journal durable.

Les trois suites complètes finales sont vertes :

- `map_core` : **4 550 tests passés** ;
- `map_editor` : **4 484 tests passés, 6 skips intentionnels** ;
- `map_runtime` : **2 253 tests passés, 1 skip intentionnel**.

Les trois analyses sont propres et le build macOS debug de l’éditeur réussit.

## 2. Source de vérité et critères de sortie

Source auditée :

`reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md`,
Gate 1, lignes 1202–1260.

Plan d’exécution :

[2026-07-28-world-map-gate-1-wysiwyg.md](/Users/karim/Project/pokemonProject/docs/superpowers/plans/2026-07-28-world-map-gate-1-wysiwyg.md)

### REN-01 — Contrat pur

Critères retenus :

- `MapVisualStackConfig` est séparé de `MapData.version` ;
- l’absence du champ signifie legacy inchangé ;
- la sémantique canonique couvre layers, éléments posés, ombres, acteurs et
  avant-plan ;
- collisions, grille, sélection et chrome d’édition restent hors pile ;
- une version future produit un diagnostic stable et aucun plan de fallback.

Verdict : **conforme**.

### REN-02 — Un plan, deux adaptateurs

Critères retenus :

- l’éditeur et la runtime consomment le même `MapVisualCompositionPlan` ;
- le dispatcher runtime legacy reste caractérisé ;
- la présence d’un Border n’est plus un sélecteur de sémantique canonique ;
- les opacités et les passes de premier plan restent cohérentes ;
- le runtime refuse explicitement une version future.

Verdict : **conforme**.

### REN-03 — Fixture commune

Critères retenus :

- une seule fixture JSON propriétaire du dépôt ;
- mêmes probes et mêmes RGBA attendus pour éditeur et runtime ;
- passage par le codec produit `toJson` → migration JSON → `fromJson` ;
- permutation Path/Surface prouvant que le test détecte réellement un ordre
  inversé ;
- foreground runtime rendu dans sa passe dédiée.

Verdict : **conforme**.

### REN-04 — Migration inspectable

Critères retenus :

- preview avant/après sans mutation ;
- différences structurelles déterministes ;
- comparaison réelle du rendu RGBA avec assets projet ;
- adoption `v2 → v3 + visualStack v1` en une mutation undoable ;
- aucun autosave ;
- refus d’un preview stale ;
- second passage strictement idempotent ;
- erreur de rendu, asset absent, budget dépassé ou version future : application
  interdite.

Verdict : **conforme**.

## 3. Audit initial et passes indépendantes

### 3.1 Audit d’implémentation initial

La première passe a confirmé la faisabilité du contrat commun mais a relevé
plusieurs risques majeurs avant clôture :

1. un ancien lecteur pouvait ignorer `visualStack` et réécrire la carte en
   legacy ;
2. le repository n’interdisait pas encore la persistance d’une version future ;
3. certaines opacités éditeur divergeaient de la runtime ;
4. la première fixture était trop faible : entité opaque masquant l’ordre,
   Terrain/foreground incomplets et pas de codec produit ;
5. le premier impact pixel REN-04 était un raster synthétique de propriété,
   pas le rendu réel ;
6. l’éditeur conservait une seconde liste de sentinelles ;
7. l’adaptateur runtime n’avait pas de test direct.

Verdict de cette passe : **FAIL**.

### 3.2 Première remédiation

Corrections :

- ajout de `ProjectVersion.v3` comme enveloppe de compatibilité ;
- rejet `visualStack + version < v3` au décodage et à la validation ;
- création/migration atomique en v3 ;
- write guard repository pour les versions futures ;
- opacités Tile/Terrain/Path/placed elements alignées ;
- fixture commune renforcée avec alpha et foreground ;
- test adaptateur runtime ;
- suppression de la seconde source de sentinelles ;
- remplacement du raster synthétique par le vrai `MapGridPainter`.

### 3.3 Seconde revue indépendante

Deux reviewers indépendants ont ensuite trouvé des défauts que les tests
initiaux masquaient :

1. les assets propres aux `MapPlacedElement` n’étaient pas demandés au loader ;
2. events, triggers, connections et contour blanc polluaient encore la
   comparaison annoncée « visual stack only » ;
3. Annuler/Escape renvoyaient `false` à une route typée preview ;
4. les clés internes et empreintes FNV étaient exposées dans l’UI no-code ;
5. rename/duplicate/delete pouvaient entrer dans le lifecycle avant le rejet
   repository et laisser un journal ;
6. le constructeur direct de config ne protégeait la positivité que par
   `assert`.

Verdicts de cette passe :

- revue architecture : **FAIL**, 3 Important et 2 Minor ;
- revue REN-03/REN-04 : **FAIL**, 1 Critical, 3 Important et 3 risques.

### 3.4 Seconde remédiation

Corrections :

- collecte des tilesets de toutes les frames des éléments posés référencés ;
- fake loader strict sur `paths.keys` ;
- nouveau `showEditorOverlays`, désactivé dans la comparaison ;
- test fingerprint d’un canvas transparent malgré event/trigger/connection ;
- Annuler et Escape utilisent `pop()` et disposent de tests dédiés ;
- libellés humains, identifiants internes et FNV masqués dans le parcours
  normal ;
- préflight read-only rename/duplicate/delete juste après lecture et identité ;
- garde défensive coordinator avant journal et pendant recovery ;
- tests filesystem byte-exact, sans `.pokemap`, journal, temp ni cible ;
- validation runtime du constructeur `MapVisualStackConfig`.

### 3.5 Re-revues finales

Résultats :

- revue REN-03/REN-04 : **PASS**, aucun Critical ni Important ;
- revue architecture : **PASS**, aucun Critical, Important ou Minor restant.

Les reviewers n’ont modifié aucun fichier et n’ont effectué aucun commit/push.

## 4. Décisions d’architecture

### 4.1 Deux versions, deux responsabilités

`MapData.version` et `MapVisualStackConfig.semanticsVersion` ne sont pas deux
sélecteurs concurrents :

- `ProjectVersion.v3` indique au décodeur ancien que le document n’est plus un
  document v1/v2 qu’il peut réécrire sans comprendre ;
- `visualStack.semanticsVersion` sélectionne le contrat perceptible.

Le v3 a donc été ajouté uniquement après la découverte du risque old-reader.
Le plan de composition ne choisit jamais sa sémantique à partir du seul v3.

### 4.2 Legacy strict

Une config absente conserve :

- les phases Terrain / Path / Surface historiques ;
- le hint legacy `paintAfterTileLayerId` ;
- le comportement Border déjà existant ;
- les passes ombres, placements, acteurs, collisions et foreground historiques.

La migration n’est pas exécutée au chargement.

### 4.3 Canonique

Une config v1 :

- interprète `map.layers` comme top-first ;
- inverse cette liste pour peindre bottom-to-top ;
- garde les no-op Object/Environment explicites ;
- place ensuite ombres, éléments posés, acteurs de fond, collision éditeur,
  tuiles/éléments foreground et acteurs foreground selon le même plan.

### 4.4 Version future

Politique :

- décodable et inspectable si positive ;
- aucun plan de composition ;
- édition ordinaire rejetée par le notifier ;
- `saveMap` et CAS rejetés avant écriture ;
- rename/duplicate/delete rejetés avant journal ;
- recovery d’un ancien journal incompatible bloqué sans perte ;
- runtime : `MapLoadException`, jamais legacy.

### 4.5 Périmètre pixel

Inclus :

- layers visuels ;
- opacité layer et instance ;
- Border matérialisé ;
- ombres statiques ;
- éléments posés ;
- entités background/foreground ;
- transparence de couleur des assets.

Exclus explicitement :

- collision ;
- grille ;
- hover, sélection et outils ;
- events/triggers/connections ;
- contour de canvas ;
- animation au-delà de `t=0`.

## 5. Inventaire complet des fichiers Gate 1

### 5.1 `map_core`

| Fichier | Zone précise | Raison / impact |
|---|---|---|
| `lib/map_core.dart` | exports visual stack | API publique des nouveaux contrats ; l’export `gameplay_roadmap_evidence.dart` était préexistant et n’appartient pas à Gate 1 |
| `lib/src/models/enums.dart` | `ProjectVersion.v3` | fail-fast des anciens lecteurs |
| `lib/src/models/map_data.dart` | champ `visualStack`, décodage v3 | sérialisation optionnelle et invariant de format |
| `lib/src/models/map_data.freezed.dart` | génération | support copy/equality/constructor |
| `lib/src/models/map_data.g.dart` | génération | JSON `visualStack` + enum v3 |
| `lib/src/models/project_manifest.g.dart` | génération enum | enum v3 connu du codec |
| `lib/src/models/map_visual_stack_config.dart` | nouveau modèle | version sémantique positive, v1 canonique |
| `lib/src/operations/map_visual_composition.dart` | nouveau plan pur | unique source d’ordre editor/runtime |
| `lib/src/operations/map_visual_stack_migration.dart` | nouvelle preview/apply | différences stables, stale-safe, idempotence |
| `lib/src/operations/project_json_migrations.dart` | v3 admis, v4 rejeté | pipeline JSON compatible |
| `lib/src/operations/map_layers.dart` | promotion v1 seulement | aucune régression v3 |
| `lib/src/operations/border_layer_operations.dart` | promotion v1 seulement | Border ne downgradera jamais v3 |
| `lib/src/validation/validators.dart` | invariant config/v3 | refus des documents incohérents |
| `test/fixtures/map_visual_stack/monochrome_parity_v1.json` | fixture commune | probes et RGBA partagés |
| `test/map_visual_stack_config_test.dart` | nouveau | JSON, old-reader, futur, positivité |
| `test/map_visual_composition_test.dart` | nouveau | legacy exact, canonical, sentinelles |
| `test/map_visual_stack_migration_test.dart` | nouveau | preview, diff, stale, apply, no-op |
| `test/project_json_migrations_test.dart` | cas v3/v4 | preuve pipeline |

### 5.2 `map_editor`

| Fichier | Zone précise | Raison / impact |
|---|---|---|
| `lib/src/application/services/map_lifecycle_transaction_service.dart` | `requireWritableMapVisualStackForLifecycle`, execute/recovery | aucune mutation lifecycle future avant journal |
| `lib/src/application/use_cases/map_use_cases.dart` | create + rename/delete/duplicate | nouvelles maps canoniques et preflight read-only |
| `lib/src/application/use_cases/map_visual_stack_migration_use_case.dart` | nouveau seam | preview async et application fail-closed |
| `lib/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart` | adaptateur | délégation au plan core |
| `lib/src/features/editor/state/editor_notifier.dart` | read-only, inputs, preview/apply | intégration undoable sans autosave |
| `lib/src/infrastructure/repositories/file_repositories.dart` | write guard | future refusé avant écriture directe/CAS |
| `lib/src/ui/canvas/entity_editor_element_visual.dart` | collecte assets | entités et éléments posés |
| `lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | exécution plan, opacités, overlays | rendu canonique et mode visual-stack-only |
| `lib/src/ui/canvas/map_visual_stack_migration_renderer.dart` | nouveau | vrai rendu RGBA, asset checks, budget |
| `lib/src/ui/design_system/design_system.dart` | export dialog | primitive DS publique |
| `lib/src/ui/design_system/pokemap_visual_stack_migration_dialog.dart` | nouveau | preview no-code, consentement, loading |
| `lib/src/ui/editor_shell_page.dart` | action toolbar | entrée utilisateur |
| `lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart` | orchestration async | capture inputs et dialogue |
| `test/application/services/map_lifecycle_transaction_service_test.dart` | futur + recovery | aucun journal/cible/status |
| `test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart` | version v3 | lifecycle existant compatible |
| `test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart` | FS byte-exact | rename/duplicate/delete sans trace |
| `test/application/use_cases/map_visual_stack_migration_use_case_test.dart` | nouveau | vrai painter, alpha, footprint, overlays |
| `test/border_map_editing/editor_border_painter_integration_test.dart` | ordre | Border via plan partagé |
| `test/border_map_editing/editor_map_layer_paint_order_test.dart` | adaptateur | legacy/canonical/future |
| `test/features/editor/state/editor_notifier_map_visual_stack_migration_test.dart` | nouveau | preview read-only, undo, stale |
| `test/infrastructure/repositories/atomic_map_document_persistence_test.dart` | future | octets/révision/temp inchangés |
| `test/map_grid_painter_test.dart` | shadow order robuste | test non dépendant de l’indentation |
| `test/map_visual_composition_adapter_test.dart` | nouveau | rendu réel legacy/canonical/future |
| `test/map_visual_stack_parity_test.dart` | nouveau | fixture commune et permutation |
| `test/ui/design_system/pokemap_visual_stack_migration_dialog_test.dart` | nouveau | loading, consent, cancel, Escape |

### 5.3 `map_runtime`

| Fichier | Zone précise | Raison / impact |
|---|---|---|
| `lib/src/application/load_runtime_map_bundle.dart` | validation plan | version future explicitement refusée |
| `lib/src/presentation/flame/runtime_map_layer_paint_order.dart` | adaptateur | délégation au plan core |
| `lib/src/presentation/flame/map_layers_component.dart` | exécution steps | même composition que l’éditeur |
| `test/border/border_map_layers_component_ordering_test.dart` | cas plan | Border, shadows, placements, foreground |
| `test/border/runtime_map_layer_paint_order_test.dart` | legacy/canonical/future | preuve adaptateur |
| `test/load_runtime_map_bundle_collision_normalization_test.dart` | future loader | erreur sans fallback |
| `test/map_visual_composition_adapter_test.dart` | nouveau | correspondance directe core |
| `test/map_visual_stack_parity_test.dart` | nouveau | mêmes probes/RGBA que l’éditeur |

## 6. Fichiers créés — contenu intégral vérifiable

Le contenu intégral de chaque fichier créé est la cible du lien local
correspondant. Le nombre de lignes et le SHA-256 figent exactement la version
auditée. Cette présentation évite de dupliquer 5 240 lignes dans le rapport
tout en donnant accès au contenu complet, byte pour byte.

| Contenu intégral | Lignes | SHA-256 |
|---|---:|---|
| [plan Gate 1](/Users/karim/Project/pokemonProject/docs/superpowers/plans/2026-07-28-world-map-gate-1-wysiwyg.md) | 143 | `d4104c579a151ea197900d2d638c5b0a88ca320b8da55c6c07cdba745f8bfd97` |
| [map_visual_stack_config.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_visual_stack_config.dart) | 66 | `df07da4db3393a404647ee70fff5915b911dfe49929cccd6395931c7d60847bc` |
| [map_visual_composition.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/map_visual_composition.dart) | 408 | `11812a74b415990621082c0e724932bd3bc628111ad195bc6009c5ac53b5a611` |
| [map_visual_stack_migration.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/map_visual_stack_migration.dart) | 285 | `8025b3104e013692e1857aedc1be69f13aad152900ba847492a4c1ce93b144b2` |
| [monochrome_parity_v1.json](/Users/karim/Project/pokemonProject/packages/map_core/test/fixtures/map_visual_stack/monochrome_parity_v1.json) | 134 | `25cceb224e69cea7c0739a659811ebc9b8ff3a8bdecbf09d05dcb02fab49c68a` |
| [map_visual_composition_test.dart](/Users/karim/Project/pokemonProject/packages/map_core/test/map_visual_composition_test.dart) | 280 | `444e434ffaf7a55fca3eff3be44b4ad61304c314bf053b2779d29c41b0e5de7d` |
| [map_visual_stack_config_test.dart](/Users/karim/Project/pokemonProject/packages/map_core/test/map_visual_stack_config_test.dart) | 214 | `a810771b255d4806b606764b9897f421e0d16c25b316c584710d047b1799331e` |
| [map_visual_stack_migration_test.dart](/Users/karim/Project/pokemonProject/packages/map_core/test/map_visual_stack_migration_test.dart) | 153 | `5ad587fb13d1c4129a074ff26762367a035b2a3409919c5479efa6444b980b4a` |
| [map_visual_stack_migration_use_case.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/map_visual_stack_migration_use_case.dart) | 155 | `e72f8fcd10a9dfe5ff425fe87a1a6bdbdb54f25551f0ca2b5d6715f6e8a34d22` |
| [map_visual_stack_migration_renderer.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_visual_stack_migration_renderer.dart) | 551 | `31d13d91f88fc4173e3a34a59874ca6ae909213b1102b43a77acd0470d8399fd` |
| [pokemap_visual_stack_migration_dialog.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_visual_stack_migration_dialog.dart) | 523 | `6130c08ce55bb35a5d188eb43060ec7e45705d3051596b2260699b26e1dbaf7a` |
| [map_visual_stack_migration_use_case_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/application/use_cases/map_visual_stack_migration_use_case_test.dart) | 393 | `40b4543687b8f46692d5115dd9c001a0e8ca408194def8416ce6b5748a761312` |
| [editor_notifier_map_visual_stack_migration_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/features/editor/state/editor_notifier_map_visual_stack_migration_test.dart) | 112 | `ee23469e0223bd4d5f6b0999a0b9c8cae77f5c1c475da3c9b6086ac05dad69e4` |
| [map_visual_composition_adapter_test.dart — editor](/Users/karim/Project/pokemonProject/packages/map_editor/test/map_visual_composition_adapter_test.dart) | 162 | `bcdfe53fd28c6aada3b10696a19f7889abc6812790b810282d06c32c76137935` |
| [map_visual_stack_parity_test.dart — editor](/Users/karim/Project/pokemonProject/packages/map_editor/test/map_visual_stack_parity_test.dart) | 614 | `625fee9ba87c048970e587203d35cd3edcb6311558cfbc51cf0bfc7ab69d5621` |
| [pokemap_visual_stack_migration_dialog_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_visual_stack_migration_dialog_test.dart) | 241 | `accecb51a212cb02a2fb432030189ccdb8a2ceecc7c1866d328ed8763307d268` |
| [map_visual_composition_adapter_test.dart — runtime](/Users/karim/Project/pokemonProject/packages/map_runtime/test/map_visual_composition_adapter_test.dart) | 130 | `ef699170da2f9800629c15f9c1c8c0146890a33c3a49176ce186c849f0bf4459` |
| [map_visual_stack_parity_test.dart — runtime](/Users/karim/Project/pokemonProject/packages/map_runtime/test/map_visual_stack_parity_test.dart) | 676 | `074852f7c75f452301b9358798ab0b84997faf79b67045c367fc47d17108dcef` |

Le rapport lui-même est exclu de cette table pour éviter une auto-référence
infinie.

## 7. Zones de diff significatives

### Modèle et compatibilité

```text
ProjectVersion { v1, v2, v3 }
MapData.visualStack?: MapVisualStackConfig
visualStack présent => version document obligatoirement v3
semanticsVersion <= 0 => ArgumentError / FormatException
semanticsVersion inconnue positive => décodable mais requiresReadOnly
```

### Plan commun

```text
buildMapVisualCompositionPlan(MapData)
  config absente  -> legacyRuntimeV1
  config v1       -> canonicalV1 / authoredStack
  config future   -> plan null + unsupportedSemanticsVersion
```

### Persistance et lifecycle

```text
FileMapRepository.saveMap/saveMapDocument
  -> _requireSupportedVisualStackForWrite

Rename/Delete/Duplicate use cases
  -> requireWritableMapVisualStackForLifecycle

MapLifecycleTransactionCoordinator
  -> garde target/source avant journal
  -> garde recovery d’un journal préexistant
```

### Rendu migration

```text
MapGridPainterVisualStackMigrationComparator
  -> budget dimensions
  -> collecte assets layers + placements + entités + Border
  -> décodage/transparence
  -> MapGridPainter(showGrid:false, showEntityEditorChrome:false,
                    showEditorOverlays:false)
  -> comparaison rawRgba, changed count/bounds, FNV
```

## 8. Commandes et preuves exactes

### 8.1 Génération

Commande :

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs \
  --build-filter=lib/src/models/map_data.freezed.dart \
  --build-filter=lib/src/models/map_data.g.dart \
  --build-filter=lib/src/models/project_manifest.freezed.dart \
  --build-filter=lib/src/models/project_manifest.g.dart
```

Résultat :

```text
exit 0
32 outputs written
warnings analyzer SDK/json_annotation uniquement
```

### 8.2 Tests ciblés finaux

Core :

```bash
dart test \
  test/map_visual_stack_config_test.dart \
  test/map_visual_composition_test.dart \
  test/map_visual_stack_migration_test.dart \
  test/project_json_migrations_test.dart -r expanded
```

Résultat :

```text
00:00 +38: All tests passed!
```

Éditeur :

```bash
flutter test -r expanded \
  test/application/use_cases/map_visual_stack_migration_use_case_test.dart \
  test/features/editor/state/editor_notifier_map_visual_stack_migration_test.dart \
  test/ui/design_system/pokemap_visual_stack_migration_dialog_test.dart \
  test/map_visual_composition_adapter_test.dart \
  test/map_visual_stack_parity_test.dart \
  test/map_grid_painter_test.dart \
  test/map_grid_painter_layer_order_test.dart \
  test/border_map_editing/editor_map_layer_paint_order_test.dart \
  test/border_map_editing/editor_border_painter_integration_test.dart \
  test/application/services/map_lifecycle_transaction_service_test.dart \
  test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart \
  test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart \
  test/infrastructure/repositories/atomic_map_document_persistence_test.dart
```

Résultat :

```text
00:02 +117: All tests passed!
```

Runtime :

```bash
flutter test -r expanded \
  test/map_visual_composition_adapter_test.dart \
  test/map_visual_stack_parity_test.dart \
  test/border/runtime_map_layer_paint_order_test.dart \
  test/border/border_map_layers_component_ordering_test.dart \
  test/load_runtime_map_bundle_collision_normalization_test.dart
```

Résultat :

```text
00:00 +30: All tests passed!
```

### 8.3 Suites complètes

Core, run final isolé :

```bash
cd packages/map_core
dart test -r expanded
```

Résultat :

```text
02:01 +4550: All tests passed!
```

Un run précédent lancé en parallèle de la suite complète Flutter éditeur avait
terminé `+4548 -2` : deux budgets de performance avaient expiré sous contention
CPU. Aucun test fonctionnel Gate n’était rouge. Le rerun isolé ci-dessus est la
preuve de clôture.

Éditeur :

```bash
cd packages/map_editor
flutter test -r expanded
```

Résultat :

```text
06:35 +4484 ~6: All tests passed!
```

Les six skips indiquent explicitement leur lane dédiée performance.

Runtime :

```bash
cd packages/map_runtime
flutter test -r expanded
```

Résultat :

```text
03:10 +2253 ~1: All tests passed!
```

### 8.4 Analyses

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
```

```bash
cd packages/map_editor && flutter analyze
```

```text
Analyzing map_editor...
No issues found! (ran in 5.8s)
```

```bash
cd packages/map_runtime && flutter analyze
```

```text
Analyzing map_runtime...
No issues found! (ran in 4.8s)
```

### 8.5 Build

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/PokeMap.app
```

### 8.6 Format, JSON et whitespace

```text
dart format --output=none --set-exit-if-changed
  map_core Gate scope    -> 0 changement final
  map_editor Gate scope  -> 26 fichiers, 0 changement
  map_runtime Gate scope -> 8 fichiers, 0 changement

jq empty packages/map_core/test/fixtures/map_visual_stack/monochrome_parity_v1.json
  -> exit 0

git diff --check
  -> exit 0, aucune sortie
```

## 9. État Git initial

État vérifié au démarrage de Gate 1 :

```text
branch: main
HEAD: 839f6d5e4e4b7905aea401089a5289c5f13c719d
origin/main: 839f6d5e4e4b7905aea401089a5289c5f13c719d
62 entrées préexistantes
```

Sortie exacte :

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
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
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
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_runtime/test/rendered_map_pixel_smoke_test.dart
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/gameplay/evidence/README.md
?? reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md
```

Les 62 entrées appartenaient déjà à l’utilisateur / à d’autres lots. Elles
n’ont pas été nettoyées, restaurées, stashées ou incluses implicitement dans
une opération Git.

## 10. État Git final

État final vérifié :

```text
branch: main
HEAD: 839f6d5e4e4b7905aea401089a5289c5f13c719d
origin/main: 839f6d5e4e4b7905aea401089a5289c5f13c719d
113 entrées au total
```

Sortie exacte :

```text
 M .github/workflows/pokemap_hub_product_certification.yml
 M apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
 M apps/pokemap_hub/test/saves/hub_save_store_atomic_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/enums.dart
 M packages/map_core/lib/src/models/map_data.dart
 M packages/map_core/lib/src/models/map_data.freezed.dart
 M packages/map_core/lib/src/models/map_data.g.dart
 M packages/map_core/lib/src/models/narrative_command_descriptor.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/operations/border_layer_operations.dart
 M packages/map_core/lib/src/operations/map_layers.dart
 M packages/map_core/lib/src/operations/project_json_migrations.dart
 M packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
 M packages/map_core/lib/src/read_models/narrative_command_catalog.dart
 M packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/gameplay_roadmap_dashboard_test.dart
 M packages/map_core/test/linked_asset_public_contracts_test.dart
 M packages/map_core/test/narrative_command_catalog_test.dart
 M packages/map_core/test/narrative_command_contract_parity_test.dart
 M packages/map_core/test/project_json_migrations_test.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart
 M packages/map_editor/lib/game_export.dart
 M packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart
 M packages/map_editor/lib/src/application/services/narrative_template_catalog.dart
 M packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
 M packages/map_editor/lib/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/lib/src/ui/design_system/design_system.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart
 M packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart
 M packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
 M packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart
 M packages/map_editor/test/border_map_editing/editor_border_painter_integration_test.dart
 M packages/map_editor/test/border_map_editing/editor_map_layer_paint_order_test.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_controller_test.dart
 M packages/map_editor/test/game_export/game_package_export_dialog_test.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart
 M packages/map_editor/test/map_grid_painter_test.dart
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
 M packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/lib/src/presentation/flame/runtime_map_layer_paint_order.dart
 M packages/map_runtime/test/border/border_map_layers_component_ordering_test.dart
 M packages/map_runtime/test/border/runtime_map_layer_paint_order_test.dart
 D packages/map_runtime/test/le_train_m00_external_runtime_smoke_test.dart
 M packages/map_runtime/test/load_runtime_map_bundle_collision_normalization_test.dart
 M packages/map_runtime/test/narrative_command_runtime_parity_test.dart
 M packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/map_core/lib/src/models/map_visual_stack_config.dart
?? packages/map_core/lib/src/operations/map_visual_composition.dart
?? packages/map_core/lib/src/operations/map_visual_stack_migration.dart
?? packages/map_core/lib/src/tooling/gameplay_roadmap_evidence.dart
?? packages/map_core/test/fixtures/map_visual_stack/monochrome_parity_v1.json
?? packages/map_core/test/map_visual_composition_test.dart
?? packages/map_core/test/map_visual_stack_config_test.dart
?? packages/map_core/test/map_visual_stack_migration_test.dart
?? packages/map_editor/dart_test.yaml
?? packages/map_editor/lib/src/application/use_cases/map_visual_stack_migration_use_case.dart
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_editor/lib/src/ui/canvas/map_visual_stack_migration_renderer.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_visual_stack_migration_dialog.dart
?? packages/map_editor/test/application/use_cases/map_visual_stack_migration_use_case_test.dart
?? packages/map_editor/test/features/editor/state/editor_notifier_map_visual_stack_migration_test.dart
?? packages/map_editor/test/map_visual_composition_adapter_test.dart
?? packages/map_editor/test/map_visual_stack_parity_test.dart
?? packages/map_editor/test/ui/design_system/pokemap_visual_stack_migration_dialog_test.dart
?? packages/map_runtime/test/map_visual_composition_adapter_test.dart
?? packages/map_runtime/test/map_visual_stack_parity_test.dart
?? packages/map_runtime/test/rendered_map_pixel_smoke_test.dart
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/gameplay/evidence/README.md
?? reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md
?? reports/ui/world_map_editor_gate_1_wysiwyg_2026-07-28.md
```

Différence arithmétique par rapport aux 62 entrées initiales : 51 entrées
supplémentaires visibles. Gate 1 touche aussi des zones précises de quelques
entrées déjà présentes, notamment le barrel `map_core.dart`, sans remplacer
leurs modifications antérieures. Le plan sous `docs/` est ignoré par Git et
n’apparaît donc pas dans cette sortie, mais son contenu et son hash figurent en
section 6.

## 11. Non-objectifs

- aucune migration automatique au chargement ;
- aucune réécriture des anciennes cartes sans consentement ;
- aucun changement de schéma des layers existants ;
- aucune refonte globale de navigation/sélection/brush dans Gate 1 ;
- aucun commit, push, tag, stash ou changement de branche ;
- aucune modification volontaire des 62 entrées initiales hors zones de
  chevauchement explicites.

## 12. Risques résiduels et limites connues

1. La comparaison migration échantillonne le rendu statique à `t=0`. Elle ne
   parcourt pas toutes les frames d’animation.
2. Une Border non matérialisée n’a pas encore de pixels ; elle reste couverte
   par le diff structurel.
3. Le plafond de 16 777 216 pixels peut mobiliser environ 256 Mio pour deux
   images et leurs buffers RGBA, hors assets. Le dialogue peut être fermé mais
   le calcul déjà lancé n’est pas annulé.
4. La collecte d’assets est conservatrice : toutes les frames des éléments
   référencés sont demandées, même si l’élément est hors carte. Un asset
   inutile mais absent peut bloquer la migration ; c’est un faux négatif sûr,
   jamais une migration trompeuse.
5. La fixture commune prouve le foreground des entités, mais pas encore dans
   la même fixture les pixels d’ombre ni le split foreground multi-case. Ces
   comportements restent couverts par les tests propres aux deux renderers.
6. Le build effectué est macOS debug. Les autres plateformes ne font pas partie
   du package desktop demandé.

## 13. Auto-critique

### Ce qui a bien résisté

- le contrat pur a permis de supprimer deux dispatchers divergents ;
- les reviewers indépendants ont trouvé des défauts que les premières
  assertions vertes masquaient réellement ;
- le fail-closed a été appliqué à toutes les frontières d’écriture, pas
  seulement au bouton Save ;
- la fixture partagée est volontairement sensible à une permutation ;
- les changements utilisateur préexistants ont été conservés.

### Ce qui aurait dû être fait plus tôt

- l’enveloppe old-reader v3 aurait dû être pensée dès REN-01 ;
- le premier test placement aurait dû utiliser un fake loader strict ;
- le rendu de migration aurait dû disposer dès le départ d’un mode
  `visual-stack-only` explicite ;
- la lecture seule devait être auditée sur rename/delete/duplicate, pas
  seulement sur les repositories ;
- les tests source-string dépendants de l’indentation sont trop fragiles.

### Niveau de confiance

Confiance élevée sur le contrat, la compatibilité et le rendu statique couvert.
Confiance moyenne sur les très grandes maps et les contenus animés, pour les
raisons mémoire/échantillonnage documentées ci-dessus.

## 14. Handoff

Gate 1 peut être proposée `DONE`.

Suite recommandée : ouvrir le lot ergonomie suivant uniquement à partir de ce
contrat stabilisé, sans réintroduire d’ordre local dans l’éditeur ou la
runtime.

Git : aucun commit/push effectué sur ce tour, conformément à l’absence de
demande explicite.
