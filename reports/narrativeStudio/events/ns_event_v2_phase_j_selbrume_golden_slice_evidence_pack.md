# NS-EVENT-V2 Phase J — Golden Slice Selbrume — Evidence Pack

Date de validation : 2026-07-17
Révision auditée : `2f68328a38bf218c843e497940f8dd24a7a9c194`
Roadmap d'exécution : `MVP Selbrume/road_map_event_builder_v2_execution.md`
Lots : `J1`, `J2`, `J3`, `J4`, `J5`
Phase produit : **Phase 4 — Golden Slice Selbrume**
Verdict final : **DONE technique proposé — J1 à J5 validés**

## 1. Résumé exécutif

La Phase J livre et promeut une Golden Slice Event Builder V2 réelle dans
Selbrume. Trois sources spatiales authorées sur les cartes déclenchent trois
Events project-level :

- interaction avec le PNJ Lysa ;
- entrée dans la zone existante du port ;
- interaction avec l'indice en verre du marais.

La chaîne Lysa testée est :

```text
MapEntity npc_lysa
  -> Event V2
  -> Scene scene_lysa_port
  -> Yarn
  -> Cinematic
  -> Battle
  -> outcome victoire/défaite
  -> Fact
  -> completeStoryStep(step_rival_battle)
  -> World Rule
  -> save/load et one-shot
```

La promotion finale est limitée aux quatre destinations acceptées. Les quatre
hashes du projet réel correspondent exactement aux payloads figés. Un second
passage de l'outil retourne `noOp: promotionAlreadyApplied`.

Les gates finaux sont verts :

- `53/53` tests core ciblés ;
- `14/14` tests de conséquences runtime ;
- `13/13` tests editor J1/J2/J5 ;
- `8/8` tests runtime J3 + smokes Selbrume ;
- `5/5` scénarios host J4/J5 ;
- smoke host historique `1/1` ;
- analyses ciblées core/editor/runtime/host sans diagnostic ;
- builds macOS debug editor et host réussis.

Ce verdict ne signifie pas que toute la roadmap Event Builder ou toute la
golden slice fangame est terminée. `FG-181` et `FG-182` restent `PARTIAL` et
`FG-180` reste `TODO`.

## 2. Confirmation de scope et décisions d'architecture

### Inclus

- deux nouvelles sources physiques : `npc_lysa` et `clue_glass_object` ;
- réutilisation du trigger `zone_port_entry` déjà présent sur la map ;
- trois Events V2 créés avec le use case produit ;
- Scenes construites avec les opérations publiques de `map_core` ;
- conséquence typée `completeStoryStep` consommée par le runtime ;
- fixture autonome et reproductible ;
- exécution depuis les hooks `PlayableMapGame` avec collisions réelles ;
- victoire, défaite, one-shot, réinteraction et save/load ;
- promotion journalée, checkpointée et protégée contre les courses ;
- revalidation sur les vrais octets `selbrume/`.

### Invariants confirmés

- l'Event ne possède aucune position ; la géométrie reste dans `MapEntity` ou
  `MapTrigger` ;
- aucun `PlacedElement` n'est transformé en source Event canonique ;
- le sélecteur de map sert au contexte et au filtrage, pas à « poser » un
  Event sur une carte ;
- le registre Event reste project-level ;
- le Story Step existant `story_main_brume_phare/chapter_1_port/step_rival_battle`
  est réutilisé, sans storyline dupliquée ;
- les quatre seules destinations promues sont celles du manifeste J4 ;
- aucune opération Git d'écriture n'a été exécutée.

### Hors scope conservé

- aucune activation globale V2 par défaut ;
- aucune dépréciation des readers/importeurs V1 ;
- aucune correction des chantiers non liés déjà présents dans le worktree ;
- aucune mise à jour de roadmap, non demandée dans ce lot ;
- aucun starter/capture/PC/shop/badge/field move ajouté à la golden slice
  fangame globale.

## 3. Audit initial

### 3.1 État Git initial

```text
HEAD             2f68328a38bf218c843e497940f8dd24a7a9c194
branche          main
tracked modified 45
untracked        127
staged             0
total            172
```

Le worktree était déjà fortement sale à cause des phases précédentes. Les
changements non attribuables à J ont été préservés.

### 3.2 Contrats et preuves existants

L'audit a lu :

- `AGENTS.md` et `codex_rule.md` ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- `MVP Selbrume/road_map_event_builder_v2_execution.md` ;
- les Evidence Packs G, K et L ;
- les modèles Scene, Storyline, Event Registry et GameState ;
- les bridges runtime de sources spatiales ;
- les repositories editor et le verrou de manifeste partagé ;
- les smokes Selbrume et Phase A existants.

### 3.3 Risques identifiés avant clôture

Les reviews indépendantes ont initialement refusé le lot pour les raisons
suivantes :

1. IDs de dialogue/fact/world rule divergents du plan ;
2. `step_rival_battle` dupliqué dans une nouvelle storyline ;
3. Story Step complété manuellement par le test ;
4. Lysa placée dans la collision pleine d'un bateau ;
5. fixture runtime supprimant les vraies collisions ;
6. Scene finale injectée directement au lieu d'utiliser les opérations
   publiques ;
7. fenêtre TOCTOU classification → rename dans la promotion ;
8. checkpoint partiellement écrit avant journal durable ;
9. réinteraction/inéligibilité J3 incomplètement observées ;
10. reproductibilité byte-for-byte non automatisée ;
11. outil one-shot non journalé laissé dans le dépôt ;
12. tests host chargeant seulement deux maps au lieu du projet promu complet.

Tous ces points ont été corrigés avant le gate final. La limite « vrai restart
de processus host » est documentée en section 13.

## 4. Résultat par lot

| Lot | Résultat | Preuve principale | Statut proposé |
|---|---|---|---|
| J1 | 3 sources, 3 Events, 3 Scenes via opérations produit sur copie | test authoring + original inchangé | `DONE` |
| J2 | fixture autonome, manifestes, recovery et régénération identique | 5 tests persistence/recovery | `DONE` |
| J3 | hooks production, collisions réelles, cibles exactes et one-shot | 8 tests runtime finaux | `DONE` |
| J4 | victoire/défaite, Yarn/Cinematic/Battle, Fact/Step/Rule, save/load | 4 scénarios host fixture + promu | `DONE` |
| J5 | 4 destinations, journal/checkpoint, races, reprise, no-op | 7 tests promotion + projet promu | `DONE` |

## 5. Changements de production

### 5.1 Conséquence narrative typée

`packages/map_core/lib/src/models/scene_consequence.dart`

- ajout de `SceneConsequenceKind.completeStoryStep` ;
- ajout du factory et de `SceneCompleteStoryStepConsequence` ;
- JSON canonique : `kind`, `stepId`, `label`, `notes` ;
- égalité/hash et codec exhaustifs.

`packages/map_core/lib/src/authoring/scene_authoring_operations.dart`

- validation du `stepId` non vide ;
- titre no-code par défaut « Terminer une étape narrative ».

`packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`

- diagnostic `stepId` vide ;
- diagnostic Story Step absent ;
- diagnostic ID global ambigu/dupliqué.

`packages/map_core/lib/src/read_models/event_builder_read_model.dart`
et
`packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart`

- projection, résumé, clé d'impact et identité de la nouvelle conséquence.

`packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`

- résolution globale exacte d'un Story Step ;
- mutation par `GameStateMutations.completeStep` ;
- idempotence ;
- aucune mutation si l'ID est absent ou ambigu.

`packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart`

- résultats explicites `unknownStoryStep` et `ambiguousStoryStep`.

### 5.2 JSON canonique du manifeste

`packages/map_core/lib/src/models/project_manifest.dart` et ses fichiers
générés `project_manifest.freezed.dart` / `project_manifest.g.dart`

- sérialisation profonde explicite des presets path/terrain ;
- stabilisation des fingerprints Event V2 et des fixtures autonomes.

### 5.3 Hook de preuve runtime

`packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

- hook `@visibleForTesting afterNarrativeAuthorityPreparation` ;
- centralisation de `_prepareNarrativeDispatchAuthority` ;
- le hook observe la décision de production sans construire d'occurrence ou
  court-circuiter le dispatcher.

## 6. Contenu Selbrume promu

### 6.1 Contrat d'IDs final

```text
dialogue_lysa_port             count=1
fact_lysa_port_resolved        count=1
world_rule_lysa_port_resolved  count=1
story_main_brume_phare         count=1
chapter_1_port                 count=1
step_rival_battle              count=1
scene_lysa_port                count=1
completeStoryStep(step_rival_battle) count=1
```

Les anciens IDs refusés par les reviews ne sont plus présents :

```text
fact_lysa_rival_defeated                    absent
world_rule_lysa_leaves_after_victory        absent
storyline_lysa_rival                        absent
```

### 6.2 Sources physiques

- `npc_lysa` : `(26,16)`, taille `1x1`, bloquante, face sud ;
- spawn de test : `(26,17)`, face nord ;
- `clue_glass_object` : `(8,32)`, taille `1x1`, non bloquante ;
- `zone_port_entry` : trigger existant réutilisé.

La position initiale `(22,21)` a été rejetée : elle tombait dans la collision
du bateau moyen `(20..27,20..23)`. Les tests finaux conservent les 44
`placedElements` réels du port.

### 6.3 Hashes de promotion finaux

| Destination | SHA-256 final |
|---|---|
| `selbrume/project.json` | `8689d1d9736b543863e40806c1640a76dc8b395a928313f529c0b0384d455167` |
| `selbrume/maps/map_port_brisants.json` | `f4e6a134c9fa720aa4b293dbf71eb65c21f16985b35cabba8370e90cd11e867e` |
| `selbrume/maps/map_marais_salants.json` | `570a406303af98bfb11cd8b1cb164bf254f3b5b24fc35d0d93d78b7d96a76e96` |
| `selbrume/dialogues/lysa_port.yarn` | `cdcda2352f686521a4cabd4cbd9bb4f0429c0beb9fc8997c6448a40fd0f17399` |

Chaque hash est identique au fichier correspondant sous
`promotion_payload/`. Aucune cinquième destination n'a été écrite.

## 7. Promotion et recovery

Le repository créé dans
`packages/map_editor/lib/src/infrastructure/repositories/journaled_file_promotion_repository.dart`
protège :

- allowlist stricte de quatre destinations ;
- refus des chemins hors repo et des symlinks ;
- verrou partagé du manifeste projet pendant promote/restore ;
- hash des sources et reclassification des destinations immédiatement avant
  chaque replace ;
- temp + rename atomique ;
- journal durable et checkpoint préparé de manière récupérable ;
- reprise idempotente après chaque frontière de rename/checkpoint ;
- compensation seulement si l'ownership et tous les fingerprints concordent ;
- conservation du journal dès qu'une divergence empêche une décision sûre.

La première promotion a été effectuée avec le repository journalé. Après
stabilisation du manifeste final, une correction strictement limitée aux mêmes
quatre destinations a été rejouée avec le même repository. L'ancien outil
one-shot de réécriture directe a été supprimé. Le contrôle final donne :

```text
noOp: promotionAlreadyApplied
Tous les fichiers correspondent déjà au manifeste figé.
```

Aucun journal, checkpoint temporaire, `.tmp` ou lock Selbrume ne reste dans le
worktree final.

## 8. Fichiers modifiés attribuables à Phase J

### 8.1 Fichiers existants modifiés

| Fichier | Zone | Raison / impact |
|---|---|---|
| `packages/map_core/lib/src/models/scene_consequence.dart` | enum, factory, classe, codec | conséquence Story Step typée |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | validation/titre conséquence | authoring public no-code |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | validation structure/projet | fail-closed absent/ambigu |
| `packages/map_core/lib/src/read_models/event_builder_read_model.dart` | impact projeté | preview Event Builder |
| `packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart` | résumé/clé/impact | inspector projet V2 |
| `packages/map_core/lib/src/models/project_manifest.dart` | annotations JSON | JSON profond canonique |
| `packages/map_core/lib/src/models/project_manifest.freezed.dart` | génération ciblée | cohérence modèle généré |
| `packages/map_core/lib/src/models/project_manifest.g.dart` | génération ciblée | cohérence codec généré |
| `packages/map_core/test/scene_consequence_model_test.dart` | modèles/JSON/payload | positif + roundtrip |
| `packages/map_core/test/scene_authoring_operations_test.dart` | authoring conséquence | positif + rejet step vide |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart` | codes résultat | erreurs Story Step explicites |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart` | dispatch/mutation | consommation runtime réelle |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | hook autorité | preuve J3 sans bypass |
| `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart` | 3 cas Story Step | connu/inconnu/ambigu/idempotent |
| `selbrume/project.json` | Events/Scenes/assets narratifs | Golden Slice + registre V2 |
| `selbrume/maps/map_port_brisants.json` | entité Lysa | source à `(26,16)` |
| `selbrume/maps/map_marais_salants.json` | entité indice | source à `(8,32)` |

### 8.2 Fichiers source créés

| Fichier | Rôle |
|---|---|
| `docs/superpowers/plans/2026-07-16-event-builder-phase-j-selbrume-golden-slice.md` | plan exécutable J1–J5 |
| `packages/map_core/test/project_manifest_narrative_canonical_json_test.dart` | garde JSON profond |
| `packages/map_editor/lib/src/infrastructure/repositories/journaled_file_promotion_repository.dart` | promotion sûre |
| `packages/map_editor/test/support/selbrume_event_v2_fixture.dart` | authoring/génération/recovery fixture |
| `packages/map_editor/test/selbrume_event_v2_authoring_slice_test.dart` | J1 |
| `packages/map_editor/test/selbrume_event_v2_persistence_migration_test.dart` | J2 |
| `packages/map_editor/test/selbrume_event_v2_promotion_recovery_test.dart` | J5 |
| `packages/map_editor/tool/build_selbrume_event_v2_fixture.dart` | régénération contrôlée |
| `packages/map_editor/tool/promote_selbrume_event_v2_fixture.dart` | promotion manifestée |
| `packages/map_runtime/test/support/selbrume_event_v2_test_fixture.dart` | chargement runtime autonome/réel |
| `packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart` | J3 |
| `examples/playable_runtime_host/test/selbrume_event_v2_lysa_golden_slice_test.dart` | J4 fixture + promu |
| `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart` | J5 octets réels |
| `selbrume/dialogues/lysa_port.yarn` | dialogue réel promu |

Le contenu complet des fichiers source créés est reproduit en annexe B. Les
artefacts générés/autonomes et binaires sont attestés par hashes en annexe A,
conformément à l'exception prévue par les règles du repository.

## 9. Tests et analyses

### 9.1 Matrice finale

| Surface | Commande | Résultat exact |
|---|---|---|
| core modèle/authoring/canonical | `dart test ...` | exit `0`, `+53`, `All tests passed!` |
| runtime conséquence | `flutter test --no-pub test/scene_consequence_runtime_writer_test.dart` | exit `0`, `+14`, `All tests passed!` |
| editor J1/J2/J5 | `flutter test` sur 3 fichiers Phase J | exit `0`, `+13`, `All tests passed!` |
| runtime J3 + P6 | `flutter test --no-pub` sur 3 fichiers | exit `0`, `+8`, `All tests passed!` |
| runtime smokes P6 + Phase A | `flutter test` sur 3 fichiers | exit `0`, `+5`, `All tests passed!` |
| host J4/J5 | `flutter test` sur 2 fichiers | exit `0`, `+5`, `All tests passed!` |
| host Phase A | `flutter test test/phase_a_golden_slice_launch_test.dart` | exit `0`, `+1`, `All tests passed!` |
| analyze core ciblé | `dart analyze` sur 9 items | exit `0`, `No issues found!` |
| analyze editor ciblé | `flutter analyze` sur 7 items | exit `0`, `No issues found!` |
| analyze runtime J3 | `flutter analyze --no-pub` sur 2 items | exit `0`, `No issues found!` |
| analyze runtime conséquence | `flutter analyze --no-pub` sur 3 items | exit `0`, `No issues found!` |
| analyze host J4/J5 | `flutter analyze` sur 2 items | exit `0`, `No issues found!` |

### 9.2 Commandes littérales finales

Core :

```bash
cd packages/map_core
dart test test/scene_consequence_model_test.dart test/scene_authoring_operations_test.dart test/project_manifest_narrative_canonical_json_test.dart --reporter compact
dart analyze lib/src/models/scene_consequence.dart lib/src/authoring/scene_authoring_operations.dart lib/src/diagnostics/scene_diagnostics.dart lib/src/read_models/event_builder_read_model.dart lib/src/read_models/narrative_event_builder_project_read_model.dart lib/src/models/project_manifest.dart test/scene_consequence_model_test.dart test/scene_authoring_operations_test.dart test/project_manifest_narrative_canonical_json_test.dart
```

Editor :

```bash
cd packages/map_editor
flutter test test/selbrume_event_v2_authoring_slice_test.dart test/selbrume_event_v2_persistence_migration_test.dart test/selbrume_event_v2_promotion_recovery_test.dart --reporter compact
flutter analyze lib/src/infrastructure/repositories/journaled_file_promotion_repository.dart test/support/selbrume_event_v2_fixture.dart test/selbrume_event_v2_authoring_slice_test.dart test/selbrume_event_v2_persistence_migration_test.dart test/selbrume_event_v2_promotion_recovery_test.dart tool/build_selbrume_event_v2_fixture.dart tool/promote_selbrume_event_v2_fixture.dart
dart run tool/promote_selbrume_event_v2_fixture.dart
flutter build macos --debug
```

Runtime :

```bash
cd packages/map_runtime
flutter test --no-pub test/selbrume_event_v2_three_source_integration_test.dart test/p6_selbrume_playable_runtime_smoke_test.dart test/p6_selbrume_save_load_golden_slice_test.dart --reporter compact
flutter analyze --no-pub test/support/selbrume_event_v2_test_fixture.dart test/selbrume_event_v2_three_source_integration_test.dart
flutter test --no-pub test/scene_consequence_runtime_writer_test.dart --reporter compact
flutter analyze --no-pub lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart test/scene_consequence_runtime_writer_test.dart
flutter test test/p6_selbrume_playable_runtime_smoke_test.dart test/p6_selbrume_save_load_golden_slice_test.dart test/phase_a_golden_battle_slice_smoke_test.dart --reporter compact
```

Host :

```bash
cd examples/playable_runtime_host
flutter test test/selbrume_event_v2_lysa_golden_slice_test.dart test/selbrume_event_v2_promoted_project_test.dart --reporter compact
flutter analyze test/selbrume_event_v2_lysa_golden_slice_test.dart test/selbrume_event_v2_promoted_project_test.dart
flutter test test/phase_a_golden_slice_launch_test.dart --reporter compact
flutter build macos --debug
```

### 9.3 Exécutions non vertes conservées honnêtement

- une première commande editor a référencé deux noms de fichiers inexistants
  (`selbrume_event_v2_golden_slice_test.dart` et
  `journaled_file_promotion_repository_test.dart`) ; elle a échoué avec deux
  erreurs de chargement. Les vrais fichiers J1/J5 ont ensuite été identifiés et
  la commande correcte a passé `13/13` ;
- un ancien processus `selbrume_event_v2_promotion_recovery_test.dart` était
  resté orphelin et conservait le startup lock Flutter. Il a été arrêté avant
  la relance propre ;
- la première analyse editor a signalé un `prefer_const_constructors`, puis la
  correction intermédiaire un `unnecessary_const`. Le code a été ajusté et la
  relance finale est verte ;
- le premier essai de générateur via Dart CLI a rencontré un crash du compilateur
  FFI. Le même entrypoint exécuté par le toolchain Flutter a réussi et le test
  de reproductibilité byte-for-byte atteste le résultat ;
- une campagne runtime intermédiaire plus large a également fini à `+22`, sans
  échec. Les gates finaux littéraux ci-dessus sont la preuve de clôture retenue.

## 10. Builds

```text
packages/map_editor:
✓ Built build/macos/Build/Products/Debug/map_editor.app

examples/playable_runtime_host:
✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

Les deux commandes ont un code de sortie `0`.

## 11. Verdicts des passes indépendantes

| Passe | Verdict initial | Findings principaux | Verdict après correction |
|---|---|---|---|
| Sub-agent Audit / Architecture | `FAIL strict / PASS partiel` | IDs, step dupliqué, causalité, authoring, TOCTOU | findings corrigés ; architecture conforme |
| Sub-agent Tests | `FAIL strict / PASS partiel` | J3 réinteraction, save/relaunch, IDs, authoring | gates finaux verts ; limite process relaunch documentée |
| Sub-agent Critique | `FAIL` | collision Lysa, checkpoint, courses, reproductibilité, outil one-shot | findings corrigés et artefact supprimé |
| Passe Implémentation parent | `DONE` | TDD core/editor/runtime/host | J1–J5 implémentés |
| Passe Build / Validation parent | `PASS` | tests, analyses, promotion no-op, deux builds | aucune régression ciblée |
| Passe Critique finale parent | `PASS avec limites` | hashes, IDs uniques, anciens IDs absents, aucun artefact | clôture technique proposée |

Les reviews indépendantes n'ont modifié aucun fichier.

## 12. Roadmap mécaniques fangame

| Lot | Statut conservé/proposé | Justification |
|---|---|---|
| `FG-181 — Golden Slice Fangame Fixture V0` | `PARTIAL` | Event/dialogue/battle/story/save couverts, mais starter/capture/PC/shop/soin/badge/field move absents |
| `FG-182 — Golden Slice End-to-End Smoke V0` | `PARTIAL` | slice Lysa E2E couverte, parcours fangame global incomplet |
| `FG-180 — Project Gameplay Readiness Report V0` | `TODO` | ce rapport Phase J ne remplace pas l'audit readiness global |

Aucun statut de roadmap n'a été écrit dans les fichiers, conformément à la
demande actuelle qui portait sur l'implémentation de la phase.

## 13. Limites et risques restants

- Le test J4 sérialise/désérialise l'état de la Golden Slice. Le repository de
  sauvegarde disque réel est couvert séparément par
  `p6_selbrume_save_load_golden_slice_test.dart`, mais aucun test ne tue et ne
  relance un vrai processus GUI macOS au milieu de la slice Lysa.
- L'interaction Lysa via `PlayableMapGame` reste volontairement en vol au
  handoff Yarn dans J3 ; sa consommation/réinteraction complète est testée dans
  le host J4 sur fixture et projet promu. La zone et l'indice sont réexercés
  directement dans J3.
- Les builds sont debug, pas des packages release distribués/signés.
- Le worktree contient de nombreux changements préexistants. Le présent rapport
  attribue seulement les fichiers de la section 8 à Phase J.
- La roadmap Event Builder globale possède encore des gates postérieurs ; la
  réussite de J ne vaut pas readiness produit complète.

Ces limites ne contredisent pas les critères J1–J5, mais elles interdisent de
présenter Phase J comme une certification globale du fangame ou de la release.

## 14. Auto-critique finale

### Solide

- causalité Story Step désormais dans le modèle et le runtime, plus dans le
  callback de test ;
- aucun ID global dupliqué ;
- vraies collisions conservées ;
- fixture régénérable octet pour octet ;
- promotion fail-closed et testée aux frontières durables et concurrentes ;
- tests victoire/défaite sur fixture et octets promus ;
- hashes finaux et no-op vérifiés ;
- aucun artefact de lock/journal conservé.

### Ce qui pourrait être renforcé plus tard

- un smoke GUI piloté de bout en bout avec relance complète du host ;
- une comparaison sémantique générique de projet réutilisable par d'autres
  promotions ;
- une abstraction de promotion moins spécifique à Selbrume si un second lot en
  a réellement besoin ;
- une suite complète editor/runtime sur un worktree stabilisé, distincte du
  scope Phase J ciblé.

Le risque principal évité est un faux positif où le test aurait « terminé » le
Story Step lui-même tout en prétendant que le moteur l'avait fait. La
conséquence `completeStoryStep` ferme explicitement ce trou.

## 15. État Git final

Après création du présent rapport :

```text
HEAD             2f68328a38bf218c843e497940f8dd24a7a9c194
branche          main
staged             0
tracked modified 61
untracked        162
total            223
git diff --check exit 0
selbrume/*.lock  0
journaux/tmp      0
```

Aucune commande `git add`, `commit`, `push`, `checkout`, `switch`, `stash`,
`reset`, `restore`, `merge`, `rebase`, `tag`, `branch` ou `worktree` n'a été
exécutée.

## Annexe A — Artefacts générés et binaires

Les fichiers suivants sont reproduits par hash plutôt qu'en incorporant des
mégaoctets de JSON/PNG dans ce rapport. Leur reproductibilité est couverte par
le test J2 byte-for-byte.

| SHA-256 | Fichier |
|---|---|
| `0087e0f1374bb21f42e1aab2d42168276737cb7d521c6717c6d9a265c353165f` | `assets/tilesets/grant.png` |
| `444251b7dc30250cf610b4166721d10962a5b27c7092f5bf252f34da1c75a617` | `assets/tilesets/port_reference_v3/selbrume_port_ground_v3.png` |
| `688d36095789d2ccbd13ab55807e273d056f4661406c6d452ccc3a724139bcf4` | `assets/tilesets/port_reference_v3/selbrume_port_reference_v3.png` |
| `e914dcf28b6cf85fcbc37c17a622e99cf69dd6e1083703958332bc47f0181b78` | `assets/tilesets/selbrume_marsh_props.png` |
| `6a805f21eaebdb3cba5692acc731b5dccf1e2bdeae9830cf6340237034c06daa` | `assets/tilesets/vova.png` |
| `04ff24730eb823237f24f8554a9492bf2916c1c63d444a4f54434d6cd9f1ac72` | `fixture_manifest.json` |
| `f79026ea9e67f4cc471cfa537b0a7b69b42ae487c5e0d15cda2270cecdaea9aa` | `maps/map_marais_salants.json` |
| `ecd646cb2d732915e6cfd6e81ff358da911d21cf34a2546a9f279b6963c01ab8` | `maps/map_port_brisants.json` |
| `9a1d2aa1fac56baa0f79db319cfdd2eac85834686ebf70836b8d86800225423e` | `project.json` |
| `c58661d01e39146ee0db997cf1c3e3e686379eeda54601c41d7ce72837be6149` | `promotion_checkpoint/checkpoint_manifest.json` |
| `bc0cf7a77344540b109a3ac24dc46022624fc29d169c998589ff14c32f63864b` | `promotion_checkpoint/maps/map_marais_salants.json` |
| `9e378f62dbdd80821c364cf6818a440b942e818f749f7634d28f0a15310842d4` | `promotion_checkpoint/maps/map_port_brisants.json` |
| `e7a799b7dda8a5967323c1548e87c96a27d9f8b70d3c908ee721e6a19dd4f9a8` | `promotion_checkpoint/project.json` |
| `8f24c4c3804fa9b7cafab07efb25fc454cf7857c09f1bbe1f2df98e008cf4dd5` | `promotion_manifest.json` |
| `cdcda2352f686521a4cabd4cbd9bb4f0429c0beb9fc8997c6448a40fd0f17399` | `promotion_payload/dialogues/lysa_port.yarn` |
| `570a406303af98bfb11cd8b1cb164bf254f3b5b24fc35d0d93d78b7d96a76e96` | `promotion_payload/maps/map_marais_salants.json` |
| `f4e6a134c9fa720aa4b293dbf71eb65c21f16985b35cabba8370e90cd11e867e` | `promotion_payload/maps/map_port_brisants.json` |
| `8689d1d9736b543863e40806c1640a76dc8b395a928313f529c0b0384d455167` | `promotion_payload/project.json` |
| `b56a6a1532f7a30fa6bb540159f8be1789faac0dba418a2d96de2bc2a3f8c6dd` | `semantic_diff.json` |

Tous les chemins de cette table sont relatifs à
`examples/playable_runtime_host/event_builder_v2_selbrume_slice/`.

Le dialogue, identique dans la fixture, le payload et Selbrume, est court et
reproduit intégralement :

```yarn
title: LysaPort
---
Lysa: Tu as suivi les éclats de verre jusqu'au port.
Lysa: Montre-moi si tu es prêt à défendre Selbrume.
===
```

## Annexe B — Contenu complet des fichiers source créés

### B.1 `docs/superpowers/plans/2026-07-16-event-builder-phase-j-selbrume-golden-slice.md`

~~~~markdown
# Event Builder V2 Phase J — Selbrume Golden Slice Implementation Plan

Date d'exécution : 2026-07-17
Roadmap : `MVP Selbrume/road_map_event_builder_v2_execution.md`
Lots : J1, J2, J3, J4, J5
Phase produit : 4 — Golden Slice Selbrume

## Objectif

Prouver sur des octets autonomes puis sur le projet Selbrume réel que trois
sources spatiales authorées avec les opérations produit Event V2 déclenchent
les bonnes Scenes, et qu'une Golden Slice Lysa traverse le runtime jusqu'à un
état narratif durable.

La chaîne cible est :

```text
MapEntity Lysa / MapTrigger zone / MapEntity indice
  -> Event V2 project-level
  -> Scene
  -> Yarn
  -> Cinematic
  -> Battle
  -> Outcome qualifié
  -> Fact
  -> Story Step
  -> World Rule
  -> save/load
```

## Autorités et invariants

- Les ADR `ADR-EV2-*` ratifiés restent prioritaires.
- Un Event V2 est project-level et référence exactement une source typée.
- `MapEntity` et `MapTrigger` possèdent la géométrie ; aucun Event ne reçoit de
  position et aucun `PlacedElement` n'est promu en source canonique.
- Les trois Events passent par `NarrativeEventBuilderV2UseCase` et la
  persistance journalée existante ; aucune injection directe de JSON Event.
- Les Scenes sont construites avec les mêmes opérations publiques
  `map_core` que `ScenesWorkspace` consomme.
- Les hooks production `PlayableMapGame` créent les occurrences spatiales ;
  les tests J3 n'appellent pas directement le dispatcher avec une occurrence.
- Le projet `selbrume/` original reste inchangé pendant J1 à J4.
- J5 ne peut écrire que les destinations du manifeste de promotion figé à la
  fin de J4. Toute destination nouvelle bloque le lot avant écriture.
- Aucun write Git : pas de `git add`, commit, push, branche, stash ou reset.

## État d'entrée observé

```text
HEAD    2f68328a38bf218c843e497940f8dd24a7a9c194
branch  main
tracked modified  45
untracked         127
staged              0
```

La Phase 3 possède des preuves techniques vertes I1–I5, mais la roadmap
d'exécution conserve des statuts historiques `NOT STARTED` et l'analyse globale
editor contient 451 constats préexistants. Phase J s'appuie sur les gates
ciblés verts et ne réinterprète pas cette dette comme une régression J.

Lots mécaniques associés :

- `FG-181 — Golden Slice Fangame Fixture V0` : restera `TODO` ou au mieux
  proposition `PARTIAL` sans preuve de tous ses critères propres ;
- `FG-182 — Golden Slice End-to-End Smoke V0` : même politique ;
- `FG-180 — Project Gameplay Readiness Report V0` : reste `TODO`.

## Contrat de contenu figé

| Rôle | Source canonique | Position / origine | Scene |
|---|---|---|---|
| Lysa | `entityInteract + map_port_brisants + npc_lysa` | créer un `MapEntity` `(26,16)` | `scene_lysa_port` |
| Entrée du port | `triggerEnter + map_port_brisants + zone_port_entry` | réutiliser le trigger existant | `scene_port_entry` |
| Indice verre | `entityInteract + map_marais_salants + clue_glass_object` | créer un `MapEntity` `(8,32)` | `scene_clue_glass` |

IDs liés figés : `character_lysa`, `trainer_lysa_port`,
`dialogue_lysa_port`, `cinematic_lysa_port`, `fact_lysa_port_resolved`,
`world_rule_lysa_port_resolved`, `step_rival_battle`.

Correction d'audit J4 : la position initialement envisagée `(22,21)` se trouve
dans la collision pleine du bateau moyen `(20..27,20..23)`. La source Lysa
réutilise donc l'ancre structurelle libre `(26,16)` et doit être testée avec les
`placedElements` réels, sans neutraliser les collisions de la map.

## J0 — Gap d'activation explicite découvert à l'audit

Selbrume ne contient aucun MapEvent legacy, mais conserve une vraie source
Scenario legacy `p6_03_first_interaction` et une ancienne source de test
incomplète. Son registre est absent, donc son mode effectif est `legacyOnly`.
I4 préserve ce mode par contrat et la route produit ne propose encore aucune
activation séparée. J1 serait impossible par la vraie route sans fermer ce
gap.

Créer/étendre :

- `packages/map_editor/lib/src/application/use_cases/narrative_event_v2_mode_activation_use_case.dart` ;
- le port et le repository de migration existants avec une activation CAS
  atomique mono-fichier ;
- `EventBuilderV2MigrationSheet` et la route produit avec un CTA séparé ;
- `packages/map_editor/test/narrative_event_v2_mode_activation_test.dart` ;
- les tests widget de migration.

L'activation choisit `v2Only` seulement si le registre, les claims, les
MapEvents et les sources Scenario legacy sont vides. Sinon elle choisit
`dualRead`, qui conserve le fallback legacy pour les sources non claimées tout
en ouvrant la vraie route V2. Elle est idempotente, revision-gated, fail-closed
derrière le recovery gate et n'est jamais fusionnée avec la prévisualisation
I4.

## J1 — Authoring produit sur copie contrôlée

### Test rouge

Créer :

- `packages/map_editor/test/support/selbrume_event_v2_fixture.dart` ;
- `packages/map_editor/test/selbrume_event_v2_authoring_slice_test.dart`.

Le test doit :

1. hasher le projet Selbrume original ;
2. cloner le projet dans un temp en excluant locks, caches et artefacts ;
3. charger la copie avec `FileProjectRepository` ;
4. créer les deux `MapEntity` avec les services/opérations produit ;
5. construire les trois Scenes avec les opérations consommées par
   `ScenesWorkspace` ;
6. sauvegarder puis créer les trois Events avec
   `NarrativeEventBuilderV2UseCase.create` ;
7. rouvrir et valider sources, Scenes et registre ;
8. prouver que les hashes originaux sont inchangés.

### Critère J1

Trois sources physiques, trois Events configurés et activés sur disque, zéro
mutation du projet original et zéro JSON Event injecté.

## J2 — Fixture autonome, reload et recovery

Créer :

- `packages/map_editor/test/selbrume_event_v2_persistence_migration_test.dart` ;
- `examples/playable_runtime_host/event_builder_v2_selbrume_slice/` ;
- `examples/playable_runtime_host/event_builder_v2_selbrume_slice/promotion_manifest.json`.

La fixture versionnée est produite depuis le résultat J1, puis réduite à sa
fermeture de dépendances explicite. Elle doit contenir ses hashes et un diff
sémantique lisible. Le test couvre reopen identique, panne entre map et registre,
reprise idempotente, conflit de révision, compensation revision-gated et refus
non destructif si ownership/fingerprint divergent.

### Critère J2

Fixture reproductible et autonome ; aucune double écriture ; journal conservé
au moindre doute.

## J3 — Trois sources par les hooks runtime

Créer :

- `packages/map_runtime/test/support/selbrume_event_v2_test_fixture.dart` ;
- `packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart`.

Le test charge uniquement la fixture versionnée et pilote `PlayableMapGame` :
interaction face à Lysa, déplacement dans `zone_port_entry`, interaction face à
l'indice. Il vérifie Scene cible, dispatch, one-shot, inéligibilité et
réinteraction, sans construire une occurrence à la main.

### Critère J3

Les trois traces runtime correspondent exactement aux trois Events du registre
sur disque.

## J4 — Golden Slice Lysa

Créer :

- `examples/playable_runtime_host/event_builder_v2_selbrume_slice/dialogues/lysa_port.yarn` ;
- `examples/playable_runtime_host/test/selbrume_event_v2_lysa_golden_slice_test.dart`.

Le test couvre victoire, défaite, réinteraction et save/load. Il atteste le
handoff Cinematic/Battle, l'outcome qualifié, le Fact, `step_rival_battle`, la
World Rule et la consommation one-shot. Les smokes runtime/host existants
pertinents sont rejoués.

À la fin de J4, recalculer le manifeste de promotion. Le périmètre attendu est :

```text
selbrume/project.json
selbrume/maps/map_port_brisants.json
selbrume/maps/map_marais_salants.json
selbrume/dialogues/lysa_port.yarn
```

Si une cinquième destination est nécessaire, arrêter avant J5 et demander une
nouvelle acceptation de périmètre.

## J5 — Promotion journalée et revalidation

Créer :

- `packages/map_editor/test/selbrume_event_v2_promotion_recovery_test.dart` ;
- `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart`.

Après validation du manifeste exact J4 :

1. capturer hashes/révisions initiaux ;
2. créer un checkpoint autonome pré-promotion ;
3. journaliser ordre, ownership et état de chaque destination ;
4. écrire par temp + rename atomique ;
5. injecter une panne après chaque frontière en test ;
6. reprendre idempotemment ou compenser uniquement si toutes les preuves
   correspondent ;
7. rejouer J1–J4 sur les nouveaux octets Selbrume.

### Critère J5

Selbrume charge et joue la Golden Slice sur ses octets promus, sans état
partiel observable après panne/reprise.

## Ordre TDD et gates

Pour chaque lot : test ciblé rouge, implémentation minimale, test ciblé vert.

Gate Phase J final :

```bash
cd packages/map_editor
flutter test --no-pub \
  test/selbrume_event_v2_authoring_slice_test.dart \
  test/selbrume_event_v2_persistence_migration_test.dart \
  test/selbrume_event_v2_promotion_recovery_test.dart
flutter analyze --no-pub \
  test/support/selbrume_event_v2_fixture.dart \
  test/selbrume_event_v2_authoring_slice_test.dart \
  test/selbrume_event_v2_persistence_migration_test.dart \
  test/selbrume_event_v2_promotion_recovery_test.dart
flutter build macos --debug --no-pub

cd ../map_runtime
flutter test --no-pub \
  test/selbrume_event_v2_three_source_integration_test.dart \
  test/p6_selbrume_playable_runtime_smoke_test.dart \
  test/p6_selbrume_save_load_golden_slice_test.dart
flutter analyze --no-pub \
  test/support/selbrume_event_v2_test_fixture.dart \
  test/selbrume_event_v2_three_source_integration_test.dart

cd ../../examples/playable_runtime_host
flutter test --no-pub \
  test/selbrume_event_v2_lysa_golden_slice_test.dart \
  test/selbrume_event_v2_promoted_project_test.dart \
  test/phase_a_golden_slice_launch_test.dart
flutter analyze --no-pub \
  test/selbrume_event_v2_lysa_golden_slice_test.dart \
  test/selbrume_event_v2_promoted_project_test.dart
flutter build macos --debug --no-pub
```

Produire enfin un Evidence Pack Phase 4 conforme à `codex_rule.md`, avec état
Git initial/final, inventaire, contenu complet des fichiers créés, commandes,
résultats exacts, passes d'audit et auto-critique.
~~~~

### B.2 `packages/map_core/test/project_manifest_narrative_canonical_json_test.dart`

~~~~dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('ProjectManifest path preset output is deep JSON for Event V2 hashes',
      () {
    final manifest = ProjectManifest(
      name: 'Narrative snapshot regression',
      maps: const [],
      tilesets: const [],
      terrainPresets: const <ProjectTerrainPreset>[
        ProjectTerrainPreset(
          id: 'terrain',
          name: 'Terrain',
          terrainType: TerrainType.grass,
          variants: <TerrainPresetVariant>[
            TerrainPresetVariant(
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      pathPresets: const <ProjectPathPreset>[
        ProjectPathPreset(
          id: 'path',
          name: 'Path',
          variants: <PathPresetVariantMapping>[
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cross,
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 2),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      () => canonicalizeNarrativeEventJson(manifest.toJson()),
      returnsNormally,
    );
  });
}
~~~~

### B.3 `packages/map_editor/lib/src/infrastructure/repositories/journaled_file_promotion_repository.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'project_manifest_write_lock.dart';

typedef JournaledPromotionFaultInjector = Future<void> Function(
  int renamedFileCount,
);

typedef JournaledPromotionBeforeReplaceHook = Future<void> Function(
  int fileIndex,
  String sourcePath,
  String destinationPath,
);

typedef JournaledPromotionCheckpointFaultInjector = Future<void> Function(
  int checkpointedFileCount,
);

enum JournaledFilePromotionStatus {
  promoted,
  noOp,
  restored,
  recoveryRequired,
  blocked,
  ioFailure,
}

final class JournaledFilePromotionResult {
  const JournaledFilePromotionResult({
    required this.status,
    required this.code,
    required this.message,
    required this.journalPath,
  });

  final JournaledFilePromotionStatus status;
  final String code;
  final String message;
  final String journalPath;

  bool get succeeded =>
      status == JournaledFilePromotionStatus.promoted ||
      status == JournaledFilePromotionStatus.noOp ||
      status == JournaledFilePromotionStatus.restored;
}

/// Promotes a frozen, hash-pinned list of files with a durable checkpoint.
///
/// The operation is atomic per file. A prepared journal and exact before/after
/// hashes make an interrupted multi-file sequence resumable without guessing.
final class JournaledFilePromotionRepository {
  JournaledFilePromotionRepository({
    required String repositoryRoot,
    required String manifestPath,
    required Set<String> allowedDestinations,
    String? journalPath,
    this.faultInjector,
    this.beforeReplaceHook,
    this.checkpointFaultInjector,
  })  : repositoryRoot = p.normalize(p.absolute(repositoryRoot)),
        manifestPath = p.normalize(p.absolute(manifestPath)),
        allowedDestinations = Set<String>.unmodifiable(
          allowedDestinations.map(_normalizeRelative),
        ),
        journalPath = p.normalize(
          p.absolute(
            journalPath ??
                p.join(
                  repositoryRoot,
                  'selbrume',
                  '.pokemap-event-v2-phase-j-promotion.json',
                ),
          ),
        ),
        projectManifestPath = p.normalize(
          p.absolute(repositoryRoot, 'selbrume', 'project.json'),
        );

  final String repositoryRoot;
  final String manifestPath;
  final Set<String> allowedDestinations;
  final String journalPath;
  final String projectManifestPath;
  final JournaledPromotionFaultInjector? faultInjector;
  final JournaledPromotionBeforeReplaceHook? beforeReplaceHook;
  final JournaledPromotionCheckpointFaultInjector? checkpointFaultInjector;

  String get checkpointDirectoryPath => '$journalPath.checkpoint';

  Future<JournaledFilePromotionResult> promote() async {
    try {
      return await withProjectManifestWriteLock(
        projectManifestPath,
        _promoteLocked,
      );
    } on _PromotionRejected catch (error) {
      return _result(
        JournaledFilePromotionStatus.blocked,
        error.code,
        error.message,
      );
    } on Object catch (error) {
      return _result(
        await File(journalPath).exists()
            ? JournaledFilePromotionStatus.recoveryRequired
            : JournaledFilePromotionStatus.ioFailure,
        await File(journalPath).exists()
            ? 'promotionInterrupted'
            : 'promotionIoFailure',
        'La promotion a été interrompue: $error',
      );
    }
  }

  Future<JournaledFilePromotionResult> _promoteLocked() async {
    final plan = await _loadPlan();
    final journalFile = File(journalPath);
    if (await journalFile.exists()) {
      final journal = await _loadJournal(plan);
      return await _resume(plan, journal);
    }

    final states = await _classifyDestinations(plan);
    if (states.every((state) => state == _DestinationState.after)) {
      return _result(
        JournaledFilePromotionStatus.noOp,
        'promotionAlreadyApplied',
        'Tous les fichiers correspondent déjà au manifeste figé.',
      );
    }
    if (states.asMap().entries.any(
          (state) => !_isBeforeCompatible(plan.entries[state.key], state.value),
        )) {
      throw const _PromotionRejected(
        'destinationRevisionMismatch',
        'Au moins une destination ne correspond ni au checkpoint ni à la cible.',
      );
    }
    if (await Directory(checkpointDirectoryPath).exists()) {
      throw const _PromotionRejected(
        'orphanPromotionCheckpoint',
        'Un checkpoint sans journal existe déjà; aucune écriture n’est autorisée.',
      );
    }
    final journal = _newPreparedJournal(plan);
    await _writeJournal(journal);
    await _prepareCheckpoint(plan);
    await faultInjector?.call(0);
    return await _resume(plan, journal);
  }

  /// Restores the exact pre-promotion checkpoint while all hash guards match.
  Future<JournaledFilePromotionResult> restoreCheckpoint() async {
    try {
      return await withProjectManifestWriteLock(
        projectManifestPath,
        _restoreCheckpointLocked,
      );
    } on _PromotionRejected catch (error) {
      return _result(
        JournaledFilePromotionStatus.blocked,
        error.code,
        error.message,
      );
    } on Object catch (error) {
      return _result(
        JournaledFilePromotionStatus.recoveryRequired,
        'checkpointRestoreInterrupted',
        'La restauration a été interrompue: $error',
      );
    }
  }

  Future<JournaledFilePromotionResult> _restoreCheckpointLocked() async {
    final plan = await _loadPlan();
    if (!await File(journalPath).exists()) {
      throw const _PromotionRejected(
        'promotionJournalMissing',
        'Aucun journal de promotion ne peut être restauré.',
      );
    }
    var journal = await _loadJournal(plan);
    final states = await _classifyDestinations(plan);
    if (states.any((state) => state == _DestinationState.diverged)) {
      throw const _PromotionRejected(
        'promotionOwnershipDiverged',
        'Une destination a divergé; le checkpoint est conservé sans réécriture.',
      );
    }
    await _ensureCheckpoint(plan, states);
    for (var index = plan.entries.length - 1; index >= 0; index--) {
      final entry = plan.entries[index];
      final destination = File(entry.destinationPath(repositoryRoot));
      final state = await _classifyDestination(entry);
      if (state == _DestinationState.before) {
        journal = journal.withFileState(index, 'restored');
        await _writeJournal(journal);
        continue;
      }
      if (entry.beforeExists) {
        final backup = File(_backupPath(entry));
        final backupBytes = await backup.readAsBytes();
        if (_fingerprint(backupBytes) != entry.beforeSha256) {
          throw _PromotionRejected(
            'promotionCheckpointDiverged',
            'Le checkpoint de ${entry.destination} a changé avant restauration.',
          );
        }
        if (await _classifyDestination(entry) != _DestinationState.after) {
          throw _PromotionRejected(
            'promotionDestinationChangedBeforeRestore',
            'La destination ${entry.destination} a changé avant restauration.',
          );
        }
        await _replaceAtomically(destination, backupBytes);
      } else {
        if (await _classifyDestination(entry) != _DestinationState.after) {
          throw _PromotionRejected(
            'promotionDestinationChangedBeforeRestore',
            'La destination ${entry.destination} a changé avant restauration.',
          );
        }
        await destination.delete();
      }
      if (await _classifyDestination(entry) != _DestinationState.before) {
        throw _PromotionRejected(
          'checkpointRestoreHashMismatch',
          'La restauration a échoué pour ${entry.destination}.',
        );
      }
      journal = journal.withFileState(index, 'restored');
      await _writeJournal(journal);
    }
    await _cleanupPromotionArtifacts(plan);
    return _result(
      JournaledFilePromotionStatus.restored,
      'promotionCheckpointRestored',
      'Le checkpoint pré-promotion a été restauré exactement.',
    );
  }

  Future<JournaledFilePromotionResult> _resume(
    _PromotionPlan plan,
    _PromotionJournal initialJournal,
  ) async {
    var journal = initialJournal;
    final initialStates = await _classifyDestinations(plan);
    if (initialStates.any((state) => state == _DestinationState.diverged)) {
      throw const _PromotionRejected(
        'promotionOwnershipDiverged',
        'Une destination a divergé; le journal est conservé sans réécriture.',
      );
    }
    await _ensureCheckpoint(plan, initialStates);
    if (initialStates.every((state) => state == _DestinationState.after)) {
      await _cleanupPromotionArtifacts(plan);
      return _result(
        JournaledFilePromotionStatus.promoted,
        'promotionRecovered',
        'La promotion déjà écrite a été vérifiée et finalisée.',
      );
    }
    for (var index = 0; index < plan.entries.length; index++) {
      final states = await _classifyDestinations(plan);
      if (states.any((state) => state == _DestinationState.diverged)) {
        throw const _PromotionRejected(
          'promotionOwnershipDiverged',
          'Une destination a changé pendant la reprise.',
        );
      }
      final entry = plan.entries[index];
      if (states[index] == _DestinationState.after) {
        journal = journal.withFileState(index, 'promoted');
        await _writeJournal(journal);
        continue;
      }
      final sourcePath = entry.sourcePath(plan.fixtureRoot);
      final source = File(sourcePath);
      final destination = File(entry.destinationPath(repositoryRoot));
      await beforeReplaceHook?.call(index, sourcePath, destination.path);
      final sourceBytes = await source.readAsBytes();
      if (_fingerprint(sourceBytes) != entry.afterSha256) {
        throw _PromotionRejected(
          'promotionSourceChangedBeforeWrite',
          'La source ${entry.source} a changé avant son écriture.',
        );
      }
      if (await _classifyDestination(entry) != _DestinationState.before) {
        throw _PromotionRejected(
          'promotionDestinationChangedBeforeWrite',
          'La destination ${entry.destination} a changé avant son écriture.',
        );
      }
      await _replaceAtomically(destination, sourceBytes);
      if (await _classifyDestination(entry) != _DestinationState.after) {
        throw _PromotionRejected(
          'promotedFileHashMismatch',
          'Le hash promu ne correspond pas pour ${entry.destination}.',
        );
      }
      await faultInjector?.call(index + 1);
      journal = journal.withFileState(index, 'promoted');
      await _writeJournal(journal);
    }
    await _cleanupPromotionArtifacts(plan);
    return _result(
      JournaledFilePromotionStatus.promoted,
      'promotionCommitted',
      'Les quatre fichiers Selbrume ont été promus et vérifiés.',
    );
  }

  _PromotionJournal _newPreparedJournal(_PromotionPlan plan) {
    return _PromotionJournal(
      manifestSha256: plan.manifestSha256,
      ownerFingerprint: plan.ownerFingerprint,
      state: 'prepared',
      files: <_PromotionJournalFile>[
        for (final entry in plan.entries)
          _PromotionJournalFile(
            destination: entry.destination,
            beforeSha256: entry.beforeSha256,
            afterSha256: entry.afterSha256,
            state: 'pending',
          ),
      ],
    );
  }

  Future<void> _prepareCheckpoint(_PromotionPlan plan) async {
    final checkpointDirectory = Directory(checkpointDirectoryPath);
    if (await checkpointDirectory.exists()) {
      await checkpointDirectory.delete(recursive: true);
    }
    await checkpointDirectory.create(recursive: true);
    for (var index = 0; index < plan.entries.length; index++) {
      final entry = plan.entries[index];
      final backup = File(_backupPath(entry));
      if (entry.beforeExists) {
        final destination = File(entry.destinationPath(repositoryRoot));
        final bytes = await destination.readAsBytes();
        if (_fingerprint(bytes) != entry.beforeSha256) {
          throw _PromotionRejected(
            'checkpointSourceChanged',
            'La destination ${entry.destination} a changé avant le checkpoint.',
          );
        }
        await _writeNewFile(backup, bytes);
        if (_fingerprint(await backup.readAsBytes()) != entry.beforeSha256) {
          throw _PromotionRejected(
            'checkpointHashMismatch',
            'Le checkpoint de ${entry.destination} est invalide.',
          );
        }
      }
      await checkpointFaultInjector?.call(index + 1);
    }
    await _validateCheckpoint(plan);
  }

  Future<void> _ensureCheckpoint(
    _PromotionPlan plan,
    List<_DestinationState> states,
  ) async {
    try {
      await _validateCheckpoint(plan);
    } on _PromotionRejected {
      if (states.asMap().entries.any(
            (state) =>
                !_isBeforeCompatible(plan.entries[state.key], state.value),
          )) {
        rethrow;
      }
      await _prepareCheckpoint(plan);
    }
  }

  bool _isBeforeCompatible(
    _PromotionEntry entry,
    _DestinationState state,
  ) {
    return state == _DestinationState.before ||
        (state == _DestinationState.after &&
            entry.beforeExists &&
            entry.beforeSha256 == entry.afterSha256);
  }

  Future<void> _validateCheckpoint(_PromotionPlan plan) async {
    for (final entry in plan.entries.where((entry) => entry.beforeExists)) {
      final backup = File(_backupPath(entry));
      if (!await backup.exists() ||
          _fingerprint(await backup.readAsBytes()) != entry.beforeSha256) {
        throw _PromotionRejected(
          'promotionCheckpointDiverged',
          'Le checkpoint de ${entry.destination} est absent ou divergent.',
        );
      }
    }
  }

  Future<List<_DestinationState>> _classifyDestinations(
    _PromotionPlan plan,
  ) async {
    return Future.wait(plan.entries.map(_classifyDestination));
  }

  Future<_DestinationState> _classifyDestination(
    _PromotionEntry entry,
  ) async {
    final destinationPath = entry.destinationPath(repositoryRoot);
    await _assertSafePath(repositoryRoot, destinationPath);
    final file = File(destinationPath);
    if (!await file.exists()) {
      return entry.beforeExists
          ? _DestinationState.diverged
          : _DestinationState.before;
    }
    final hash = _fingerprint(await file.readAsBytes());
    if (hash == entry.afterSha256) return _DestinationState.after;
    if (entry.beforeExists && hash == entry.beforeSha256) {
      return _DestinationState.before;
    }
    return _DestinationState.diverged;
  }

  Future<_PromotionPlan> _loadPlan() async {
    await _assertSafePath(p.dirname(manifestPath), manifestPath);
    final manifestFile = File(manifestPath);
    final manifestBytes = await manifestFile.readAsBytes();
    final root = _jsonObject(jsonDecode(utf8.decode(manifestBytes)));
    if (root['schemaVersion'] != 1 || root['state'] != 'frozenForJ5') {
      throw const _PromotionRejected(
        'promotionManifestNotFrozen',
        'Le manifeste J4 n’est pas figé pour J5.',
      );
    }
    final rawEntries = _jsonObjects(root['orderedFiles']);
    final entries = <_PromotionEntry>[];
    for (final raw in rawEntries) {
      final order = raw['order'];
      final source = raw['source'];
      final destination = raw['destination'];
      final beforeExists = raw['beforeExists'];
      final beforeSha256 = raw['beforeSha256'];
      final afterSha256 = raw['afterSha256'] ?? raw['sha256'];
      if (order is! int ||
          source is! String ||
          destination is! String ||
          beforeExists is! bool ||
          (beforeSha256 != null && beforeSha256 is! String) ||
          afterSha256 is! String) {
        throw const _PromotionRejected(
          'invalidPromotionManifest',
          'Une entrée du manifeste de promotion est invalide.',
        );
      }
      entries.add(
        _PromotionEntry(
          order: order,
          source: _normalizeRelative(source),
          destination: _normalizeRelative(destination),
          beforeExists: beforeExists,
          beforeSha256: beforeSha256 as String?,
          afterSha256: afterSha256,
        ),
      );
    }
    entries.sort((a, b) => a.order.compareTo(b.order));
    if (entries.length != allowedDestinations.length ||
        entries.asMap().entries.any(
              (entry) => entry.value.order != entry.key + 1,
            ) ||
        entries.map((entry) => entry.destination).toSet().length !=
            entries.length ||
        entries
            .map((entry) => entry.destination)
            .toSet()
            .difference(
              allowedDestinations,
            )
            .isNotEmpty ||
        allowedDestinations
            .difference(
              entries.map((entry) => entry.destination).toSet(),
            )
            .isNotEmpty) {
      throw const _PromotionRejected(
        'promotionScopeMismatch',
        'Le manifeste ne correspond pas exactement aux destinations autorisées.',
      );
    }
    final fixtureRoot = p.dirname(manifestPath);
    for (final entry in entries) {
      final sourcePath = entry.sourcePath(fixtureRoot);
      await _assertSafePath(fixtureRoot, sourcePath);
      if (await FileSystemEntity.type(sourcePath, followLinks: false) !=
          FileSystemEntityType.file) {
        throw _PromotionRejected(
          'promotionSourceNotRegularFile',
          'La source ${entry.source} n’est pas un fichier régulier.',
        );
      }
      if (_fingerprint(await File(sourcePath).readAsBytes()) !=
          entry.afterSha256) {
        throw _PromotionRejected(
          'promotionSourceHashMismatch',
          'La source ${entry.source} ne correspond pas au manifeste.',
        );
      }
      if (entry.beforeExists != (entry.beforeSha256 != null)) {
        throw _PromotionRejected(
          'invalidBeforeRevision',
          'La révision initiale de ${entry.destination} est incohérente.',
        );
      }
    }
    final manifestSha256 = _fingerprint(manifestBytes);
    final ownerFingerprint = _fingerprint(
      utf8.encode(
        jsonEncode(<Object?>[
          manifestSha256,
          for (final entry in entries) entry.toJson(),
        ]),
      ),
    );
    return _PromotionPlan(
      fixtureRoot: fixtureRoot,
      manifestSha256: manifestSha256,
      ownerFingerprint: ownerFingerprint,
      entries: entries,
    );
  }

  Future<_PromotionJournal> _loadJournal(_PromotionPlan plan) async {
    await _assertSafePath(repositoryRoot, journalPath);
    final root = _jsonObject(
      jsonDecode(await File(journalPath).readAsString()),
    );
    final journal = _PromotionJournal.fromJson(root);
    if (journal.manifestSha256 != plan.manifestSha256 ||
        journal.ownerFingerprint != plan.ownerFingerprint ||
        journal.files.length != plan.entries.length ||
        journal.files.asMap().entries.any((entry) {
          final expected = plan.entries[entry.key];
          final actual = entry.value;
          return actual.destination != expected.destination ||
              actual.beforeSha256 != expected.beforeSha256 ||
              actual.afterSha256 != expected.afterSha256;
        })) {
      throw const _PromotionRejected(
        'promotionJournalOwnershipMismatch',
        'Le journal ne possède pas les preuves du manifeste courant.',
      );
    }
    return journal;
  }

  Future<void> _writeJournal(_PromotionJournal journal) async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent(' ').convert(journal.toJson()),
    );
    await _replaceAtomically(File(journalPath), bytes);
  }

  Future<void> _cleanupPromotionArtifacts(_PromotionPlan plan) async {
    for (final entry in plan.entries) {
      final temp = File(_destinationTempPath(entry));
      if (await temp.exists()) await temp.delete();
    }
    final checkpoint = Directory(checkpointDirectoryPath);
    if (await checkpoint.exists()) await checkpoint.delete(recursive: true);
    final journal = File(journalPath);
    if (await journal.exists()) await journal.delete();
    final rewriteTemp = File('$journalPath.rewrite.tmp');
    if (await rewriteTemp.exists()) await rewriteTemp.delete();
  }

  String _backupPath(_PromotionEntry entry) {
    final prefix = entry.order.toString().padLeft(2, '0');
    return p.join(
      checkpointDirectoryPath,
      '$prefix-${p.basename(entry.destination)}.before',
    );
  }

  String _destinationTempPath(_PromotionEntry entry) {
    final destination = entry.destinationPath(repositoryRoot);
    return p.join(
      p.dirname(destination),
      '.${p.basename(destination)}.phase-j-promotion.tmp',
    );
  }

  Future<void> _replaceAtomically(File destination, List<int> bytes) async {
    await destination.parent.create(recursive: true);
    await _assertSafePath(repositoryRoot, destination.path);
    final tempPath = destination.path == journalPath
        ? '$journalPath.rewrite.tmp'
        : p.join(
            destination.parent.path,
            '.${p.basename(destination.path)}.phase-j-promotion.tmp',
          );
    await _assertSafePath(repositoryRoot, tempPath);
    final temp = File(tempPath);
    if (await temp.exists()) await temp.delete();
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(destination.path);
  }

  Future<void> _writeNewFile(File file, List<int> bytes) async {
    await file.parent.create(recursive: true);
    await _assertSafePath(repositoryRoot, file.path);
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw _PromotionRejected(
        'checkpointAlreadyExists',
        'Le checkpoint ${file.path} existe déjà.',
      );
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  JournaledFilePromotionResult _result(
    JournaledFilePromotionStatus status,
    String code,
    String message,
  ) {
    return JournaledFilePromotionResult(
      status: status,
      code: code,
      message: message,
      journalPath: journalPath,
    );
  }
}

enum _DestinationState { before, after, diverged }

final class _PromotionPlan {
  const _PromotionPlan({
    required this.fixtureRoot,
    required this.manifestSha256,
    required this.ownerFingerprint,
    required this.entries,
  });

  final String fixtureRoot;
  final String manifestSha256;
  final String ownerFingerprint;
  final List<_PromotionEntry> entries;
}

final class _PromotionEntry {
  const _PromotionEntry({
    required this.order,
    required this.source,
    required this.destination,
    required this.beforeExists,
    required this.beforeSha256,
    required this.afterSha256,
  });

  final int order;
  final String source;
  final String destination;
  final bool beforeExists;
  final String? beforeSha256;
  final String afterSha256;

  String sourcePath(String fixtureRoot) => p.join(fixtureRoot, source);
  String destinationPath(String repositoryRoot) =>
      p.join(repositoryRoot, destination);

  Map<String, Object?> toJson() => <String, Object?>{
        'order': order,
        'source': source,
        'destination': destination,
        'beforeExists': beforeExists,
        'beforeSha256': beforeSha256,
        'afterSha256': afterSha256,
      };
}

final class _PromotionJournal {
  const _PromotionJournal({
    required this.manifestSha256,
    required this.ownerFingerprint,
    required this.state,
    required this.files,
  });

  final String manifestSha256;
  final String ownerFingerprint;
  final String state;
  final List<_PromotionJournalFile> files;

  factory _PromotionJournal.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1 ||
        json['manifestSha256'] is! String ||
        json['ownerFingerprint'] is! String ||
        json['state'] is! String) {
      throw const _PromotionRejected(
        'invalidPromotionJournal',
        'Le journal de promotion est invalide.',
      );
    }
    return _PromotionJournal(
      manifestSha256: json['manifestSha256']! as String,
      ownerFingerprint: json['ownerFingerprint']! as String,
      state: json['state']! as String,
      files: _jsonObjects(json['files'])
          .map(_PromotionJournalFile.fromJson)
          .toList(growable: false),
    );
  }

  _PromotionJournal withFileState(int index, String nextState) {
    return _PromotionJournal(
      manifestSha256: manifestSha256,
      ownerFingerprint: ownerFingerprint,
      state: state,
      files: <_PromotionJournalFile>[
        for (var candidate = 0; candidate < files.length; candidate++)
          candidate == index
              ? files[candidate].withState(nextState)
              : files[candidate],
      ],
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'manifestSha256': manifestSha256,
        'ownerFingerprint': ownerFingerprint,
        'state': state,
        'files': files.map((entry) => entry.toJson()).toList(growable: false),
      };
}

final class _PromotionJournalFile {
  const _PromotionJournalFile({
    required this.destination,
    required this.beforeSha256,
    required this.afterSha256,
    required this.state,
  });

  final String destination;
  final String? beforeSha256;
  final String afterSha256;
  final String state;

  factory _PromotionJournalFile.fromJson(Map<String, Object?> json) {
    final destination = json['destination'];
    final beforeSha256 = json['beforeSha256'];
    final afterSha256 = json['afterSha256'];
    final state = json['state'];
    if (destination is! String ||
        (beforeSha256 != null && beforeSha256 is! String) ||
        afterSha256 is! String ||
        state is! String) {
      throw const _PromotionRejected(
        'invalidPromotionJournalFile',
        'Une entrée du journal de promotion est invalide.',
      );
    }
    return _PromotionJournalFile(
      destination: destination,
      beforeSha256: beforeSha256 as String?,
      afterSha256: afterSha256,
      state: state,
    );
  }

  _PromotionJournalFile withState(String nextState) => _PromotionJournalFile(
        destination: destination,
        beforeSha256: beforeSha256,
        afterSha256: afterSha256,
        state: nextState,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'destination': destination,
        'beforeSha256': beforeSha256,
        'afterSha256': afterSha256,
        'state': state,
      };
}

final class _PromotionRejected implements Exception {
  const _PromotionRejected(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

String _normalizeRelative(String value) {
  final portable = value.replaceAll('\\', '/');
  final normalized = p.posix.normalize(portable);
  if (p.posix.isAbsolute(normalized) ||
      normalized == '.' ||
      normalized == '..' ||
      normalized.startsWith('../')) {
    throw const _PromotionRejected(
      'unsafePromotionPath',
      'Le manifeste contient un chemin non relatif ou traversant.',
    );
  }
  return normalized;
}

Future<void> _assertSafePath(String root, String candidate) async {
  final normalizedRoot = p.normalize(p.absolute(root));
  final normalizedCandidate = p.normalize(p.absolute(candidate));
  if (normalizedCandidate != normalizedRoot &&
      !p.isWithin(normalizedRoot, normalizedCandidate)) {
    throw const _PromotionRejected(
      'unsafePromotionPath',
      'Un chemin de promotion sort de sa racine autorisée.',
    );
  }
  final relative = p.relative(normalizedCandidate, from: normalizedRoot);
  var cursor = normalizedRoot;
  for (final segment in p.split(relative)) {
    if (segment == '.') continue;
    cursor = p.join(cursor, segment);
    if (await FileSystemEntity.type(cursor, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const _PromotionRejected(
        'promotionSymlinkRefused',
        'Les liens symboliques sont refusés pendant la promotion.',
      );
    }
  }
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) {
    throw const _PromotionRejected(
      'invalidPromotionJson',
      'Un document de promotion n’est pas un objet JSON.',
    );
  }
  return value.cast<String, Object?>();
}

List<Map<String, Object?>> _jsonObjects(Object? value) {
  if (value is! List) {
    throw const _PromotionRejected(
      'invalidPromotionJsonList',
      'Une liste du document de promotion est invalide.',
    );
  }
  return value.map(_jsonObject).toList(growable: false);
}

String _fingerprint(List<int> bytes) => narrativeEventBytesFingerprint(bytes);
~~~~

### B.4 `packages/map_editor/test/support/selbrume_event_v2_fixture.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/entity_editing_coordinator.dart';
import 'package:map_editor/src/application/services/entity_editing_service.dart';
import 'package:map_editor/src/application/use_cases/character_use_cases.dart';
import 'package:map_editor/src/application/use_cases/entity_use_cases.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_v2_mode_activation_use_case.dart';
import 'package:map_editor/src/application/use_cases/trainer_use_cases.dart';
import 'package:map_editor/src/application/models/trainer_field_update.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart';
import 'package:path/path.dart' as p;

const selbrumePortMapId = 'map_port_brisants';
const selbrumeMarshMapId = 'map_marais_salants';
const selbrumeLysaEntityId = 'npc_lysa';
const selbrumePortEntryTriggerId = 'zone_port_entry';
const selbrumeClueEntityId = 'clue_glass_object';
const selbrumeLysaSceneId = 'scene_lysa_port';
const selbrumePortEntrySceneId = 'scene_port_entry';
const selbrumeClueSceneId = 'scene_clue_glass';
const selbrumeLysaCharacterId = 'character_lysa';
const selbrumeLysaTrainerId = 'trainer_lysa_port';
const selbrumeDialogueId = 'dialogue_lysa_port';
const selbrumeDialogueRelativePath = 'dialogues/lysa_port.yarn';
const selbrumeLysaCinematicId = 'cinematic_lysa_port';
const selbrumeLysaFactId = 'fact_lysa_port_resolved';
const selbrumeLysaStorylineId = 'story_main_brume_phare';
const selbrumeLysaChapterId = 'chapter_1_port';
const selbrumeLysaStoryStepId = 'step_rival_battle';
const selbrumeLysaWorldRuleId = 'world_rule_lysa_port_resolved';
const selbrumeLysaVictoryOutcomeId = 'lysa.victory';
const selbrumeLysaDefeatOutcomeId = 'lysa.defeat';

final class SelbrumeEventV2Fixture {
  SelbrumeEventV2Fixture._({
    required this.repoRoot,
    required this.originalRoot,
    required this.promotionBaselineRoot,
    required this.temporaryRoot,
    required this.projectRoot,
    required this.projectPath,
    required this.originalFingerprintBefore,
    required this.copyFingerprintBefore,
    required this.eventIdsByRole,
  });

  final Directory repoRoot;
  final Directory originalRoot;
  final Directory promotionBaselineRoot;
  final Directory temporaryRoot;
  final Directory projectRoot;
  final String projectPath;
  final String originalFingerprintBefore;
  final String copyFingerprintBefore;
  final Map<String, String> eventIdsByRole;

  static Future<SelbrumeEventV2Fixture> create() async {
    final repoRoot = findPokemonProjectRoot();
    final originalRoot = Directory(p.join(repoRoot.path, 'selbrume'));
    final originalFingerprintBefore =
        await selbrumeAuthoringFingerprint(originalRoot);
    final temporaryRoot =
        await Directory.systemTemp.createTemp('pokemap_phase_j_selbrume_');
    final promotionBaselineRoot = Directory(
      p.join(temporaryRoot.path, 'selbrume_promotion_baseline'),
    );
    await _cloneProject(originalRoot, promotionBaselineRoot);
    await _removeLocalArtifacts(promotionBaselineRoot);
    await _restoreVersionedPromotionBaseline(
      repoRoot: repoRoot,
      baselineRoot: promotionBaselineRoot,
    );
    final projectRoot = Directory(p.join(temporaryRoot.path, 'selbrume'));
    await _cloneProject(promotionBaselineRoot, projectRoot);
    final copyFingerprintBefore =
        await selbrumeAuthoringFingerprint(projectRoot);

    final projectPath = p.join(projectRoot.path, 'project.json');
    final events = await _authorSelbrumeSlice(
      projectRoot: projectRoot,
      projectPath: projectPath,
    );
    return SelbrumeEventV2Fixture._(
      repoRoot: repoRoot,
      originalRoot: originalRoot,
      promotionBaselineRoot: promotionBaselineRoot,
      temporaryRoot: temporaryRoot,
      projectRoot: projectRoot,
      projectPath: projectPath,
      originalFingerprintBefore: originalFingerprintBefore,
      copyFingerprintBefore: copyFingerprintBefore,
      eventIdsByRole: Map.unmodifiable(events),
    );
  }

  Future<String> originalFingerprintAfter() {
    return selbrumeAuthoringFingerprint(originalRoot);
  }

  /// Exports the J1 authoring result as a small, standalone Golden Slice.
  ///
  /// Event records are never reconstructed here: the registry bytes come from
  /// the product operations exercised by [_authorSelbrumeSlice]. Only
  /// dependencies unrelated to the selected maps are removed.
  Future<void> exportAutonomousFixture(Directory destination) async {
    if (await destination.exists()) {
      await destination.delete(recursive: true);
    }
    await destination.create(recursive: true);

    final projectRoot = _jsonObject(
      decodeNarrativeEventJsonStrict(await File(projectPath).readAsString()),
    );
    final selectedMapIds = <String>{selbrumePortMapId, selbrumeMarshMapId};
    final selectedMapEntries = _jsonObjects(projectRoot['maps'])
        .where((entry) => selectedMapIds.contains(entry['id']))
        .toList(growable: false);
    final selectedMapRoots = <String, Map<String, Object?>>{};
    final elementIds = <String>{};
    final tilesetIds = <String>{};
    final characterIds = <String>{'vova', selbrumeLysaCharacterId};
    final trainerIds = <String>{selbrumeLysaTrainerId};
    final removedConnections = <Map<String, Object?>>[];
    for (final entry in selectedMapEntries) {
      final mapId = entry['id']! as String;
      final relativePath = entry['relativePath']! as String;
      final mapRoot = _jsonObject(
        decodeNarrativeEventJsonStrict(
          await File(p.join(projectRootDirectory.path, relativePath))
              .readAsString(),
        ),
      );
      for (final connection in _jsonObjects(mapRoot['connections'])) {
        removedConnections.add({
          'mapId': mapId,
          'direction': connection['direction'],
          'targetMapId': connection['targetMapId'],
        });
      }
      mapRoot['connections'] = <Object?>[];
      mapRoot['warps'] = <Object?>[];
      _collectStringValuesForKey(mapRoot, 'elementId', elementIds);
      _collectStringValuesForKey(mapRoot, 'tilesetId', tilesetIds);
      _collectStringValuesForKey(mapRoot, 'characterId', characterIds);
      _collectStringValuesForKey(mapRoot, 'trainerId', trainerIds);
      selectedMapRoots[mapId] = mapRoot;
    }

    final selectedElements = _jsonObjects(projectRoot['elements'])
        .where((entry) => elementIds.contains(entry['id']))
        .toList(growable: false);
    for (final element in selectedElements) {
      _collectStringValuesForKey(element, 'tilesetId', tilesetIds);
    }
    final selectedTrainers = _jsonObjects(projectRoot['trainers'])
        .where((entry) => trainerIds.contains(entry['id']))
        .toList(growable: false);
    for (final trainer in selectedTrainers) {
      _collectStringValuesForKey(trainer, 'characterId', characterIds);
    }
    final selectedCharacters = _jsonObjects(projectRoot['characters'])
        .where((entry) => characterIds.contains(entry['id']))
        .toList(growable: false);
    for (final character in selectedCharacters) {
      _collectStringValuesForKey(character, 'tilesetId', tilesetIds);
    }
    final allTilesets = _jsonObjects(projectRoot['tilesets']);
    final selectedGroupIds = selectedMapEntries
        .map((entry) => entry['groupId'])
        .whereType<String>()
        .toSet();

    projectRoot['maps'] = selectedMapEntries;
    projectRoot['groups'] = _jsonObjects(projectRoot['groups'])
        .where((entry) => selectedGroupIds.contains(entry['id']))
        .toList(growable: false);
    projectRoot['tilesets'] = <Object?>[];
    projectRoot['elements'] = selectedElements;
    projectRoot['characters'] = selectedCharacters;
    projectRoot['trainers'] = selectedTrainers;
    projectRoot['scenes'] = <Object?>[
      for (final entry in _jsonObjects(projectRoot['scenes']))
        if (<String>{
          selbrumeLysaSceneId,
          selbrumePortEntrySceneId,
          selbrumeClueSceneId,
        }.contains(entry['id']))
          entry,
    ];
    projectRoot['dialogues'] = <Object?>[
      <String, Object?>{
        'id': selbrumeDialogueId,
        'name': 'Lysa au port',
        'relativePath': selbrumeDialogueRelativePath,
        'tags': <Object?>['phase-j', 'selbrume'],
        'description': 'Dialogue de la Golden Slice Event V2.',
        'defaultStartNode': 'LysaPort',
        'folderId': null,
        'sortOrder': 0,
      },
    ];
    for (final key in const <String>[
      'encounterTables',
      'scenarios',
      'scripts',
      'dialogueFolders',
      'environmentPresets',
      'pathCategories',
      'pathPatternPresets',
      'pathPresets',
      'terrainCategories',
      'terrainPresets',
    ]) {
      projectRoot[key] = <Object?>[];
    }
    projectRoot['cinematics'] = <Object?>[_goldenLysaCinematic().toJson()];
    projectRoot['facts'] = <Object?>[
      NarrativeFactDefinition(
        id: selbrumeLysaFactId,
        label: 'Lysa vaincue au Port des Brisants',
      ).toJson(),
    ];
    projectRoot['storylines'] = _jsonObjects(projectRoot['storylines'])
        .where((entry) => entry['id'] == selbrumeLysaStorylineId)
        .toList(growable: false);
    projectRoot['worldRules'] = <Object?>[_goldenLysaWorldRule().toJson()];
    projectRoot['surfaceCatalog'] = <String, Object?>{
      'atlases': <Object?>[],
      'animations': <Object?>[],
      'presets': <Object?>[],
    };
    projectRoot['shadowCatalog'] = <String, Object?>{
      'profiles': <Object?>[],
    };
    _collectStringValuesForKey(projectRoot, 'tilesetId', tilesetIds);
    final selectedTilesets = allTilesets
        .where((entry) => tilesetIds.contains(entry['id']))
        .toList(growable: false);
    projectRoot['tilesets'] = selectedTilesets;

    // Parsing the reduced manifest is the export-time schema gate.
    ProjectManifest.fromJson(projectRoot);
    await _writeCanonicalJson(
      File(p.join(destination.path, 'project.json')),
      projectRoot,
    );
    for (final entry in selectedMapEntries) {
      final mapId = entry['id']! as String;
      final relativePath = entry['relativePath']! as String;
      await _writeCanonicalJson(
        File(p.join(destination.path, relativePath)),
        selectedMapRoots[mapId]!,
      );
    }
    final dialogueFile = File(
      p.join(destination.path, selbrumeDialogueRelativePath),
    );
    await dialogueFile.parent.create(recursive: true);
    await dialogueFile.writeAsString(_selbrumeJ2Dialogue, flush: true);
    for (final tileset in selectedTilesets) {
      final relativePath = tileset['relativePath']! as String;
      final source = File(p.join(projectRootDirectory.path, relativePath));
      final target = File(p.join(destination.path, relativePath));
      await target.parent.create(recursive: true);
      await source.copy(target.path);
    }

    final authoredRegistry = NarrativeEventRegistry.fromJson(
      _jsonObject(projectRoot['eventRegistry']),
    );
    final definitions = authoredRegistry.records
        .map((record) => record.definitionOrNull)
        .whereType<NarrativeEventDefinition>()
        .toList(growable: false);
    await _writeCanonicalJson(
      File(p.join(destination.path, 'semantic_diff.json')),
      <String, Object?>{
        'schemaVersion': 1,
        'baseProject': 'selbrume',
        'selectedMaps': selectedMapIds.toList()..sort(),
        'removedExternalConnections': removedConnections,
        'addedCharacters': <String>[selbrumeLysaCharacterId],
        'addedTrainers': <String>[selbrumeLysaTrainerId],
        'addedScenes': <String>[
          selbrumeLysaSceneId,
          selbrumePortEntrySceneId,
          selbrumeClueSceneId,
        ],
        'updatedStorylines': <String>[selbrumeLysaStorylineId],
        'goldenSlice': <String, Object?>{
          'dialogueId': selbrumeDialogueId,
          'cinematicId': selbrumeLysaCinematicId,
          'trainerId': selbrumeLysaTrainerId,
          'factId': selbrumeLysaFactId,
          'storyStepId': selbrumeLysaStoryStepId,
          'worldRuleId': selbrumeLysaWorldRuleId,
          'outcomes': <String>[
            selbrumeLysaVictoryOutcomeId,
            selbrumeLysaDefeatOutcomeId,
          ],
        },
        'events': <Object?>[
          for (final definition in definitions)
            <String, Object?>{
              'id': definition.id,
              'name': definition.name,
              'source': definition.source.toJson(),
              'sceneId': definition.sceneId,
              'reusePolicy': definition.reusePolicy.name,
            },
        ],
      },
    );
    await _writePromotionPayloads(destination);
    await _writeFixtureManifests(
      destination,
      promotionBaselineRoot: promotionBaselineRoot,
    );
  }

  Future<void> _writePromotionPayloads(Directory destination) async {
    final payloadRoot = Directory(
      p.join(destination.path, 'promotion_payload'),
    );
    final baseProject = _jsonObject(
      decodeNarrativeEventJsonStrict(
        await File(p.join(promotionBaselineRoot.path, 'project.json'))
            .readAsString(),
      ),
    );
    final authoredProject = _jsonObject(
      decodeNarrativeEventJsonStrict(await File(projectPath).readAsString()),
    );

    void upsertFromAuthored(String key, Set<String> ids) {
      final additions = _jsonObjects(authoredProject[key])
          .where((entry) => ids.contains(entry['id']))
          .toList(growable: false);
      if (additions.length != ids.length) {
        throw StateError(
          'Promotion payload is missing ${ids.length - additions.length} '
          '$key definition(s).',
        );
      }
      baseProject[key] = _upsertJsonEntriesById(
        _jsonObjects(baseProject[key]),
        additions,
      );
    }

    upsertFromAuthored('characters', const <String>{selbrumeLysaCharacterId});
    upsertFromAuthored('trainers', const <String>{selbrumeLysaTrainerId});
    upsertFromAuthored('scenes', const <String>{
      selbrumeLysaSceneId,
      selbrumePortEntrySceneId,
      selbrumeClueSceneId,
    });
    baseProject['dialogues'] = _upsertJsonEntriesById(
      _jsonObjects(baseProject['dialogues']),
      <Map<String, Object?>>[
        <String, Object?>{
          'id': selbrumeDialogueId,
          'name': 'Lysa au port',
          'relativePath': selbrumeDialogueRelativePath,
          'tags': <Object?>['phase-j', 'selbrume'],
          'description': 'Dialogue de la Golden Slice Event V2.',
          'defaultStartNode': 'LysaPort',
          'folderId': null,
          'sortOrder': 0,
        },
      ],
    );
    baseProject['cinematics'] = _upsertJsonEntriesById(
      _jsonObjects(baseProject['cinematics']),
      <Map<String, Object?>>[_goldenLysaCinematic().toJson()],
    );
    baseProject['facts'] = _upsertJsonEntriesById(
      _jsonObjects(baseProject['facts']),
      <Map<String, Object?>>[
        NarrativeFactDefinition(
          id: selbrumeLysaFactId,
          label: 'Lysa vaincue au Port des Brisants',
        ).toJson(),
      ],
    );
    upsertFromAuthored(
      'storylines',
      const <String>{selbrumeLysaStorylineId},
    );
    baseProject['worldRules'] = _upsertJsonEntriesById(
      _jsonObjects(baseProject['worldRules']),
      <Map<String, Object?>>[_goldenLysaWorldRule().toJson()],
    );
    baseProject['eventRegistry'] = authoredProject['eventRegistry'];

    // This is the destination-ready project, not the reduced runtime fixture:
    // all unrelated Selbrume content must survive promotion.
    ProjectValidator.validate(ProjectManifest.fromJson(baseProject));
    await _writePrettyJson(
      File(p.join(payloadRoot.path, 'project.json')),
      baseProject,
    );

    await _writePromotionMap(
      payloadRoot: payloadRoot,
      mapId: selbrumePortMapId,
      addedEntityId: selbrumeLysaEntityId,
    );
    await _writePromotionMap(
      payloadRoot: payloadRoot,
      mapId: selbrumeMarshMapId,
      addedEntityId: selbrumeClueEntityId,
    );
    final dialogueFile = File(
      p.join(payloadRoot.path, selbrumeDialogueRelativePath),
    );
    await dialogueFile.parent.create(recursive: true);
    await dialogueFile.writeAsString(_selbrumeJ2Dialogue, flush: true);
    await _writePromotionCheckpoint(destination);
  }

  Future<void> _writePromotionCheckpoint(Directory destination) async {
    final checkpointRoot = Directory(
      p.join(destination.path, 'promotion_checkpoint'),
    );
    final entries = <Map<String, Object?>>[];
    for (final relativePath in const <String>[
      'project.json',
      'maps/map_port_brisants.json',
      'maps/map_marais_salants.json',
    ]) {
      final source = File(p.join(promotionBaselineRoot.path, relativePath));
      final bytes = await source.readAsBytes();
      final target = File(p.join(checkpointRoot.path, relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);
      entries.add(<String, Object?>{
        'destination': 'selbrume/$relativePath',
        'checkpoint': 'promotion_checkpoint/$relativePath',
        'beforeExists': true,
        'beforeSha256': narrativeEventBytesFingerprint(bytes),
      });
    }
    entries.add(<String, Object?>{
      'destination': 'selbrume/$selbrumeDialogueRelativePath',
      'checkpoint': null,
      'beforeExists': false,
      'beforeSha256': null,
    });
    await _writeCanonicalJson(
      File(p.join(checkpointRoot.path, 'checkpoint_manifest.json')),
      <String, Object?>{
        'schemaVersion': 1,
        'state': 'prePromotionCheckpoint',
        'orderedFiles': entries,
      },
    );
  }

  Future<void> _writePromotionMap({
    required Directory payloadRoot,
    required String mapId,
    required String addedEntityId,
  }) async {
    final relativePath = 'maps/$mapId.json';
    final baseMap = _jsonObject(
      decodeNarrativeEventJsonStrict(
        await File(p.join(promotionBaselineRoot.path, relativePath))
            .readAsString(),
      ),
    );
    final authoredMap = _jsonObject(
      decodeNarrativeEventJsonStrict(
        await File(p.join(projectRoot.path, relativePath)).readAsString(),
      ),
    );
    final addedEntities = _jsonObjects(authoredMap['entities'])
        .where((entry) => entry['id'] == addedEntityId)
        .toList(growable: false);
    if (addedEntities.length != 1) {
      throw StateError(
        'Promotion payload expected entity $addedEntityId on $mapId.',
      );
    }
    baseMap['entities'] = _upsertJsonEntriesById(
      _jsonObjects(baseMap['entities']),
      addedEntities,
    );
    MapData.fromJson(baseMap);
    await _writePrettyJson(
      File(p.join(payloadRoot.path, relativePath)),
      baseMap,
    );
  }

  Directory get projectRootDirectory => projectRoot;

  Future<void> dispose() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  }
}

const _selbrumeJ2Dialogue = '''title: LysaPort
tags: phase-j selbrume
---
Lysa: La brume se lève sur le Port des Brisants.
Lysa: Si tu veux continuer, montre-moi ce que vaut ton équipe.
===
''';

SceneAsset _authorGoldenLysaSceneWithPublicOperations(
  ProjectManifest project,
  SceneAsset draft,
) {
  var scene = removeSceneEdgeDraft(draft, 'edge_start_end').updatedScene;
  final dialogue = addSceneLinkedAssetNodeDraft(
    scene,
    payload: SceneYarnDialoguePayload(
      dialogueId: selbrumeDialogueId,
      yarnNodeName: 'LysaPort',
      speakerHints: const <String>[selbrumeLysaCharacterId],
    ),
    title: 'Dialogue avec Lysa',
    afterNodeId: 'node_start',
  );
  scene = dialogue.updatedScene;
  final cinematic = addSceneCinematicNodeDraft(
    scene,
    project: project,
    cinematicId: selbrumeLysaCinematicId,
    afterNodeId: dialogue.createdNode.id,
  );
  scene = cinematic.updatedScene;
  final battle = addSceneLinkedAssetNodeDraft(
    scene,
    payload: SceneBattlePayload(
      battleKind: 'trainer',
      trainerId: selbrumeLysaTrainerId,
      npcEntityId: selbrumeLysaEntityId,
      declaredOutcomes: const <String>['victory', 'defeat'],
    ),
    title: 'Combat contre Lysa',
    afterNodeId: cinematic.createdNode.id,
  );
  scene = battle.updatedScene;
  final fact = addSceneConsequenceActionNodeDraft(
    scene,
    consequence: SceneConsequence.setFact(
      factId: selbrumeLysaFactId,
      value: true,
      label: 'Mémoriser la victoire contre Lysa',
    ),
    afterNodeId: battle.createdNode.id,
  );
  scene = fact.updatedScene;
  final completeStep = addSceneConsequenceActionNodeDraft(
    scene,
    consequence: SceneConsequence.completeStoryStep(
      stepId: selbrumeLysaStoryStepId,
      label: 'Terminer l’affrontement contre la rivale',
    ),
    afterNodeId: fact.createdNode.id,
  );
  scene = completeStep.updatedScene;
  final defeatEnd = addSceneNodeDraft(
    scene,
    kind: SceneNodeKind.end,
    title: 'Défaite contre Lysa',
    afterNodeId: battle.createdNode.id,
  );
  scene = defeatEnd.updatedScene;

  for (final link in <({String from, String port, String to})>[
    (from: 'node_start', port: 'completed', to: dialogue.createdNode.id),
    (
      from: dialogue.createdNode.id,
      port: 'completed',
      to: cinematic.createdNode.id,
    ),
    (
      from: cinematic.createdNode.id,
      port: 'completed',
      to: battle.createdNode.id,
    ),
    (
      from: battle.createdNode.id,
      port: 'victory',
      to: fact.createdNode.id,
    ),
    (
      from: fact.createdNode.id,
      port: 'completed',
      to: completeStep.createdNode.id,
    ),
    (
      from: completeStep.createdNode.id,
      port: 'completed',
      to: 'node_end',
    ),
    (
      from: battle.createdNode.id,
      port: 'defeat',
      to: defeatEnd.createdNode.id,
    ),
  ]) {
    scene = addSceneEdgeDraft(
      scene,
      fromNodeId: link.from,
      fromPortId: link.port,
      toNodeId: link.to,
    ).updatedScene;
  }

  return SceneAsset(
    id: scene.id,
    name: 'Rencontre et combat contre Lysa au port',
    description: 'Golden Slice Event V2 de Selbrume.',
    storylineId: selbrumeLysaStorylineId,
    chapterId: selbrumeLysaChapterId,
    tags: const <String>['phase-j', 'selbrume', 'golden-slice'],
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: <SceneNode>[
        for (final node in scene.graph.nodes)
          if (node.id == 'node_end')
            SceneNode(
              id: node.id,
              kind: node.kind,
              title: 'Victoire contre Lysa',
              payload: SceneEndPayload(
                sceneOutcomeId: selbrumeLysaVictoryOutcomeId,
              ),
            )
          else if (node.id == defeatEnd.createdNode.id)
            SceneNode(
              id: node.id,
              kind: node.kind,
              title: node.title,
              payload: SceneEndPayload(
                sceneOutcomeId: selbrumeLysaDefeatOutcomeId,
              ),
            )
          else
            node,
      ],
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(
        id: selbrumeLysaVictoryOutcomeId,
        label: 'Victoire contre Lysa',
      ),
      SceneOutcome(
        id: selbrumeLysaDefeatOutcomeId,
        label: 'Défaite contre Lysa',
      ),
    ],
  );
}

CinematicAsset _goldenLysaCinematic() {
  return CinematicAsset(
    id: selbrumeLysaCinematicId,
    title: 'Lysa se prépare au combat',
    mapId: selbrumePortMapId,
    storylineId: selbrumeLysaStorylineId,
    chapterId: selbrumeLysaChapterId,
    tags: const <String>['phase-j', 'selbrume'],
    timeline: CinematicTimeline(
      steps: <CinematicTimelineStep>[
        CinematicTimelineStep(
          id: 'lysa_battle_beat',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 250,
        ),
      ],
    ),
  );
}

StorylineAsset _goldenLysaStoryline(StorylineAsset original) {
  final chapters = <StorylineChapter>[
    for (final chapter in original.chapters)
      StorylineChapter(
        id: chapter.id,
        title: chapter.title,
        description: chapter.description,
        order: chapter.order,
        steps: <StorylineStep>[
          for (final step in chapter.steps)
            if (step.id == selbrumeLysaStoryStepId)
              StorylineStep(
                id: step.id,
                title: step.title,
                description: step.description,
                order: step.order,
                entryCondition: step.entryCondition,
                completionCondition: step.completionCondition,
                sceneLinkIds: <String>{
                  ...step.sceneLinkIds,
                  selbrumeLysaSceneId,
                }.toList(growable: false),
                expectedOutcomeIds: <String>{
                  ...step.expectedOutcomeIds,
                  selbrumeLysaVictoryOutcomeId,
                }.toList(growable: false),
                status: step.status,
                authorNotes: step.authorNotes,
                metadata: step.metadata,
              )
            else
              step,
        ],
        directSceneLinkIds: chapter.directSceneLinkIds,
        status: chapter.status,
        authorNotes: chapter.authorNotes,
        metadata: chapter.metadata,
      ),
  ];
  final matchingSteps = chapters
      .expand((chapter) => chapter.steps)
      .where((step) => step.id == selbrumeLysaStoryStepId)
      .length;
  if (matchingSteps != 1) {
    throw StateError(
      'Selbrume must expose exactly one $selbrumeLysaStoryStepId.',
    );
  }
  return StorylineAsset(
    id: original.id,
    schemaVersion: original.schemaVersion,
    type: original.type,
    status: original.status,
    title: original.title,
    description: original.description,
    sortOrder: original.sortOrder,
    locale: original.locale,
    chapters: chapters,
    sceneLinks: original.sceneLinks,
    relationships: original.relationships,
    legacySource: original.legacySource,
    authorNotes: original.authorNotes,
    metadata: original.metadata,
  );
}

WorldRuleDefinition _goldenLysaWorldRule() {
  return WorldRuleDefinition(
    id: selbrumeLysaWorldRuleId,
    label: 'Lysa quitte le port après sa défaite',
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: selbrumeLysaFactId,
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: selbrumePortMapId,
      entityId: selbrumeLysaEntityId,
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
    priority: 0,
  );
}

List<Map<String, Object?>> _jsonObjects(Object? value) {
  return (value as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((entry) => entry.cast<String, Object?>())
      .toList(growable: false);
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) {
    throw FormatException('Expected a JSON object, got ${value.runtimeType}.');
  }
  return value.cast<String, Object?>();
}

List<Map<String, Object?>> _upsertJsonEntriesById(
  List<Map<String, Object?>> base,
  List<Map<String, Object?>> additions,
) {
  final additionById = <String, Map<String, Object?>>{
    for (final entry in additions) entry['id']! as String: entry,
  };
  final result = <Map<String, Object?>>[
    for (final entry in base) additionById.remove(entry['id']) ?? entry,
  ];
  result.addAll(additionById.values);
  return result;
}

void _collectStringValuesForKey(
  Object? value,
  String key,
  Set<String> output,
) {
  if (value is Map) {
    final candidate = value[key];
    if (candidate is String && candidate.isNotEmpty) output.add(candidate);
    for (final nested in value.values) {
      _collectStringValuesForKey(nested, key, output);
    }
  } else if (value is List) {
    for (final nested in value) {
      _collectStringValuesForKey(nested, key, output);
    }
  }
}

Future<void> _writeCanonicalJson(File file, Object? value) async {
  await file.parent.create(recursive: true);
  await file.writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(value),
    flush: true,
  );
}

Future<void> _writePrettyJson(File file, Object? value) async {
  // Promotion payloads remain human-reviewable in the real Selbrume diff.
  // Canonicalization still validates the full JSON boundary before writing.
  canonicalizeNarrativeEventJson(value);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
    flush: true,
  );
}

Future<void> _writeFixtureManifests(
  Directory destination, {
  required Directory promotionBaselineRoot,
}) async {
  final payloadFiles = <File>[];
  await for (final entity
      in destination.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relativePath = p.posix.normalize(
      p.relative(entity.path, from: destination.path).replaceAll(r'\', '/'),
    );
    if (relativePath == 'fixture_manifest.json' ||
        relativePath == 'promotion_manifest.json') {
      continue;
    }
    payloadFiles.add(entity);
  }
  payloadFiles.sort((a, b) => a.path.compareTo(b.path));
  final entries = <Map<String, Object?>>[];
  for (final file in payloadFiles) {
    final relativePath = p.posix.normalize(
      p.relative(file.path, from: destination.path).replaceAll(r'\', '/'),
    );
    entries.add(<String, Object?>{
      'path': relativePath,
      'sha256': narrativeEventBytesFingerprint(await file.readAsBytes()),
      'bytes': await file.length(),
    });
  }
  await _writeCanonicalJson(
    File(p.join(destination.path, 'fixture_manifest.json')),
    <String, Object?>{
      'schemaVersion': 1,
      'generator':
          'packages/map_editor/tool/build_selbrume_event_v2_fixture.dart',
      'payloadFiles': entries,
    },
  );
  final entryByPath = <String, Map<String, Object?>>{
    for (final entry in entries) entry['path']! as String: entry,
  };
  final promotions = <({String source, String destination})>[
    (
      source: 'promotion_payload/project.json',
      destination: 'selbrume/project.json',
    ),
    (
      source: 'promotion_payload/maps/map_port_brisants.json',
      destination: 'selbrume/maps/map_port_brisants.json',
    ),
    (
      source: 'promotion_payload/maps/map_marais_salants.json',
      destination: 'selbrume/maps/map_marais_salants.json',
    ),
    (
      source: 'promotion_payload/$selbrumeDialogueRelativePath',
      destination: 'selbrume/$selbrumeDialogueRelativePath',
    ),
  ];
  await _writeCanonicalJson(
    File(p.join(destination.path, 'promotion_manifest.json')),
    <String, Object?>{
      'schemaVersion': 1,
      'state': 'frozenForJ5',
      'orderedFiles': <Object?>[
        for (var index = 0; index < promotions.length; index++)
          <String, Object?>{
            'order': index + 1,
            'source': promotions[index].source,
            'destination': promotions[index].destination,
            'beforeExists': await File(
              p.join(
                promotionBaselineRoot.path,
                promotions[index].destination.replaceFirst('selbrume/', ''),
              ),
            ).exists(),
            'beforeSha256': await _fileFingerprintOrNull(
              File(
                p.join(
                  promotionBaselineRoot.path,
                  promotions[index].destination.replaceFirst('selbrume/', ''),
                ),
              ),
            ),
            'afterSha256': entryByPath[promotions[index].source]!['sha256'],
            'sha256': entryByPath[promotions[index].source]!['sha256'],
          },
      ],
    },
  );
}

Future<String?> _fileFingerprintOrNull(File file) async {
  if (!await file.exists()) return null;
  return narrativeEventBytesFingerprint(await file.readAsBytes());
}

Future<void> _restoreVersionedPromotionBaseline({
  required Directory repoRoot,
  required Directory baselineRoot,
}) async {
  final fixtureRoot = Directory(
    p.join(
      repoRoot.path,
      'examples',
      'playable_runtime_host',
      'event_builder_v2_selbrume_slice',
    ),
  );
  final promotion = _jsonObject(
    decodeNarrativeEventJsonStrict(
      await File(p.join(fixtureRoot.path, 'promotion_manifest.json'))
          .readAsString(),
    ),
  );
  final entries = _jsonObjects(promotion['orderedFiles']);
  if (promotion['state'] != 'frozenForJ5' || entries.length != 4) {
    throw StateError('The versioned J5 promotion baseline is not frozen.');
  }
  for (final entry in entries) {
    final destination = entry['destination']! as String;
    if (!destination.startsWith('selbrume/')) {
      throw StateError('Unexpected promotion destination: $destination');
    }
    final relativePath = destination.substring('selbrume/'.length);
    final target = File(p.join(baselineRoot.path, relativePath));
    if (entry['beforeExists'] == true) {
      final checkpoint = File(
        p.join(fixtureRoot.path, 'promotion_checkpoint', relativePath),
      );
      final bytes = await checkpoint.readAsBytes();
      if (narrativeEventBytesFingerprint(bytes) != entry['beforeSha256']) {
        throw StateError('Checkpoint hash mismatch for $destination.');
      }
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);
    } else if (await target.exists()) {
      await target.delete();
    }
    final restoredHash = await _fileFingerprintOrNull(target);
    if (restoredHash != entry['beforeSha256']) {
      throw StateError('Baseline restore mismatch for $destination.');
    }
  }
}

Future<Map<String, String>> _authorSelbrumeSlice({
  required Directory projectRoot,
  required String projectPath,
}) async {
  final projectRepository = FileProjectRepository();
  final mapRepository = FileMapRepository();
  var project = await projectRepository.loadProject(projectPath);
  await _validateProjectClosure(
    projectRoot: projectRoot,
    project: project,
    mapRepository: mapRepository,
  );
  final existingEvents = await _existingSelbrumeSlice(
    projectRoot: projectRoot,
    project: project,
    mapRepository: mapRepository,
  );
  if (existingEvents != null) return existingEvents;

  final activation = await NarrativeEventV2ModeActivationUseCase(
    gateway: NarrativeEventMigrationPersistenceRepository(),
  ).activate(projectPath);
  if (!activation.succeeded) {
    throw StateError('${activation.code}: ${activation.message}');
  }
  project = await projectRepository.loadProject(projectPath);

  final workspace = ProjectFileSystem(projectRoot.path);
  project = await CreateCharacterUseCase(projectRepository).execute(
    workspace,
    project,
    name: selbrumeLysaCharacterId,
    tilesetId: 'grant',
  );
  project = await UpdateCharacterUseCase(projectRepository).execute(
    workspace,
    project,
    characterId: selbrumeLysaCharacterId,
    name: 'Lysa',
  );
  project = await CreateTrainerUseCase(projectRepository).execute(
    workspace,
    project,
    name: selbrumeLysaTrainerId,
    trainerClass: 'Rivale',
    battleDifficulty: 5,
    characterId: selbrumeLysaCharacterId,
    tags: const <String>['selbrume', 'phase-j'],
  );
  project = await UpdateTrainerUseCase(projectRepository).execute(
    workspace,
    project,
    trainerId: selbrumeLysaTrainerId,
    name: 'Lysa du port',
    characterId: const TrainerFieldUpdate<String>.set(
      selbrumeLysaCharacterId,
    ),
  );
  project = await AddTrainerPokemonUseCase(projectRepository).execute(
    workspace,
    project,
    trainerId: selbrumeLysaTrainerId,
    speciesId: 'bulbasaur',
    level: 7,
    moves: const <String>['tackle', 'growl'],
  );

  final storylineMatches = project.storylines
      .where((storyline) => storyline.id == selbrumeLysaStorylineId)
      .toList(growable: false);
  if (storylineMatches.length != 1) {
    throw StateError(
      'Selbrume must expose exactly one $selbrumeLysaStorylineId.',
    );
  }
  project = project.copyWith(
    dialogues: <ProjectDialogueEntry>[
      ...project.dialogues,
      const ProjectDialogueEntry(
        id: selbrumeDialogueId,
        name: 'Lysa au port',
        relativePath: selbrumeDialogueRelativePath,
        tags: <String>['phase-j', 'selbrume'],
        description: 'Dialogue de la Golden Slice Event V2.',
        defaultStartNode: 'LysaPort',
      ),
    ],
    cinematics: <CinematicAsset>[
      ...project.cinematics,
      _goldenLysaCinematic(),
    ],
    facts: <NarrativeFactDefinition>[
      ...project.facts,
      NarrativeFactDefinition(
        id: selbrumeLysaFactId,
        label: 'Lysa vaincue au Port des Brisants',
      ),
    ],
    storylines: <StorylineAsset>[
      for (final storyline in project.storylines)
        if (storyline.id == selbrumeLysaStorylineId)
          _goldenLysaStoryline(storyline)
        else
          storyline,
    ],
    worldRules: <WorldRuleDefinition>[
      ...project.worldRules,
      _goldenLysaWorldRule(),
    ],
  );

  for (final scene in const <({String seed, String description})>[
    (
      seed: 'lysa_port',
      description: 'Rencontre et combat contre Lysa au port.',
    ),
    (
      seed: 'port_entry',
      description: 'Première entrée dans le Port des Brisants.',
    ),
    (
      seed: 'clue_glass',
      description: 'Découverte de l’indice en verre poli.',
    ),
  ]) {
    final created = createSceneDraftInProject(
      project,
      name: scene.seed,
      description: scene.description,
    );
    if (created.createdScene.id == selbrumeLysaSceneId) {
      final authored = _authorGoldenLysaSceneWithPublicOperations(
        created.updatedProject,
        created.createdScene,
      );
      project = created.updatedProject.copyWith(
        scenes: <SceneAsset>[
          for (final candidate in created.updatedProject.scenes)
            if (candidate.id == authored.id) authored else candidate,
        ],
      );
    } else {
      project = created.updatedProject;
    }
  }
  await projectRepository.saveProject(project, projectPath);

  final entityService = EntityEditingService(
    addEntityToMapUseCase: AddEntityToMapUseCase(),
    updateEntityOnMapUseCase: UpdateEntityOnMapUseCase(),
    deleteEntityFromMapUseCase: DeleteEntityFromMapUseCase(),
    entityEditingCoordinator: const EntityEditingCoordinator(),
  );
  final portEntry = project.maps.singleWhere(
    (entry) => entry.id == selbrumePortMapId,
  );
  final marshEntry = project.maps.singleWhere(
    (entry) => entry.id == selbrumeMarshMapId,
  );
  final portPath = p.join(projectRoot.path, portEntry.relativePath);
  final marshPath = p.join(projectRoot.path, marshEntry.relativePath);

  var portMap = await mapRepository.loadMap(portPath);
  final lysaDraft = entityService.addEntityAt(
    portMap,
    const GridPos(x: 26, y: 16),
    kind: MapEntityKind.npc,
  );
  portMap = entityService.updateEntity(
    lysaDraft.updatedMap,
    entityId: lysaDraft.createdEntity.id,
    id: selbrumeLysaEntityId,
    name: 'Lysa',
    size: const GridSize(width: 1, height: 1),
    blocksMovement: true,
    npc: const MapEntityNpcData(
      displayName: 'Lysa',
      facing: EntityFacing.south,
      visualElementId: 'grant',
      trainerId: selbrumeLysaTrainerId,
      characterId: selbrumeLysaCharacterId,
    ),
    properties: const <String, String>{
      'contractRole': 'phase_j_lysa_source',
    },
  ).updatedMap;
  await mapRepository.saveMap(
    portMap,
    portPath,
    projectDialogueContext: project,
  );

  var marshMap = await mapRepository.loadMap(marshPath);
  final clueDraft = entityService.addEntityAt(
    marshMap,
    const GridPos(x: 8, y: 32),
    kind: MapEntityKind.custom,
  );
  marshMap = entityService.updateEntity(
    clueDraft.updatedMap,
    entityId: clueDraft.createdEntity.id,
    id: selbrumeClueEntityId,
    name: 'Indice en verre poli',
    blocksMovement: false,
    properties: const <String, String>{
      'contractRole': 'phase_j_clue_source',
      'visualOwnerId': 'pe_marais_indice_verre',
    },
  ).updatedMap;
  await mapRepository.saveMap(
    marshMap,
    marshPath,
    projectDialogueContext: project,
  );

  final rawUuids = <String>[
    '019abcde-4000-7000-8000-000000000001',
    '019abcde-4000-7000-8000-000000000002',
    '019abcde-4000-7000-8000-000000000003',
  ];
  var nextUuid = 0;
  var operation = 0;
  final useCase = NarrativeEventBuilderV2UseCase(
    persistenceGateway: projectRepository,
    idGeneratorFactory: () {
      final raw = rawUuids[nextUuid++];
      return NarrativeEventIdGenerator(rawUuidFactory: () => raw);
    },
    operationIdFactory: () => 'phase_j_${++operation}',
  );
  final intents = <({
    String role,
    String name,
    NarrativeEventSourceRef source,
    String sceneId,
  })>[
    (
      role: 'lysa',
      name: 'Rencontre avec Lysa au port',
      source: NarrativeEventSourceRef.entityInteract(
        selbrumePortMapId,
        selbrumeLysaEntityId,
      ),
      sceneId: selbrumeLysaSceneId,
    ),
    (
      role: 'portEntry',
      name: 'Entrée dans le Port des Brisants',
      source: NarrativeEventSourceRef.triggerEnter(
        selbrumePortMapId,
        selbrumePortEntryTriggerId,
      ),
      sceneId: selbrumePortEntrySceneId,
    ),
    (
      role: 'clue',
      name: 'Indice du verre poli',
      source: NarrativeEventSourceRef.entityInteract(
        selbrumeMarshMapId,
        selbrumeClueEntityId,
      ),
      sceneId: selbrumeClueSceneId,
    ),
  ];
  final eventIds = <String, String>{};
  for (final intent in intents) {
    final created = await useCase.create(
      projectPath: projectPath,
      request: NarrativeEventBuilderV2CreationRequest(
        name: intent.name,
        source: intent.source,
        sceneId: intent.sceneId,
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        publish: true,
      ),
      environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
    );
    if (!created.succeeded || created.eventId == null) {
      throw StateError('${created.code}: ${created.message}');
    }
    final activated = await useCase.setEnabled(
      projectPath: projectPath,
      eventId: created.eventId!,
      enabled: true,
      environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
    );
    if (!activated.succeeded) {
      throw StateError('${activated.code}: ${activated.message}');
    }
    eventIds[intent.role] = created.eventId!;
  }
  return eventIds;
}

Future<Map<String, String>?> _existingSelbrumeSlice({
  required Directory projectRoot,
  required ProjectManifest project,
  required FileMapRepository mapRepository,
}) async {
  final registry = project.eventRegistry;
  if (registry == null || registry.mode != EventSystemMode.dualRead) {
    return null;
  }
  final expected = <String, ({NarrativeEventSourceRef source, String sceneId})>{
    'lysa': (
      source: NarrativeEventSourceRef.entityInteract(
        selbrumePortMapId,
        selbrumeLysaEntityId,
      ),
      sceneId: selbrumeLysaSceneId,
    ),
    'portEntry': (
      source: NarrativeEventSourceRef.triggerEnter(
        selbrumePortMapId,
        selbrumePortEntryTriggerId,
      ),
      sceneId: selbrumePortEntrySceneId,
    ),
    'clue': (
      source: NarrativeEventSourceRef.entityInteract(
        selbrumeMarshMapId,
        selbrumeClueEntityId,
      ),
      sceneId: selbrumeClueSceneId,
    ),
  };
  final result = <String, String>{};
  for (final entry in expected.entries) {
    final matches = registry.records.where((record) {
      final definition = record.definitionOrNull;
      return record.enabledOrNull == true &&
          definition?.source == entry.value.source &&
          definition?.sceneId == entry.value.sceneId &&
          definition?.reusePolicy == NarrativeEventReusePolicy.oneShot;
    }).toList(growable: false);
    if (matches.length != 1) return null;
    result[entry.key] = matches.single.id;
  }
  if (!project.characters.any((entry) => entry.id == selbrumeLysaCharacterId) ||
      !project.trainers.any((entry) => entry.id == selbrumeLysaTrainerId) ||
      !<String>{for (final scene in project.scenes) scene.id}.containsAll(
        const <String>{
          selbrumeLysaSceneId,
          selbrumePortEntrySceneId,
          selbrumeClueSceneId,
        },
      )) {
    return null;
  }
  final portEntry = project.maps.singleWhere(
    (entry) => entry.id == selbrumePortMapId,
  );
  final marshEntry = project.maps.singleWhere(
    (entry) => entry.id == selbrumeMarshMapId,
  );
  final port = await mapRepository.loadMap(
    p.join(projectRoot.path, portEntry.relativePath),
  );
  final marsh = await mapRepository.loadMap(
    p.join(projectRoot.path, marshEntry.relativePath),
  );
  if (!port.entities.any((entry) => entry.id == selbrumeLysaEntityId) ||
      !port.triggers.any((entry) => entry.id == selbrumePortEntryTriggerId) ||
      !marsh.entities.any((entry) => entry.id == selbrumeClueEntityId)) {
    return null;
  }
  return result;
}

Future<void> _validateProjectClosure({
  required Directory projectRoot,
  required ProjectManifest project,
  required FileMapRepository mapRepository,
}) async {
  for (final entry in project.maps) {
    await mapRepository.loadMap(p.join(projectRoot.path, entry.relativePath));
  }
  for (final entry in project.dialogues) {
    if (!await File(p.join(projectRoot.path, entry.relativePath)).exists()) {
      throw StateError('Missing dialogue dependency: ${entry.relativePath}');
    }
  }
  for (final entry in project.tilesets) {
    if (!await File(p.join(projectRoot.path, entry.relativePath)).exists()) {
      throw StateError('Missing tileset dependency: ${entry.relativePath}');
    }
  }
}

Future<String> selbrumeAuthoringFingerprint(Directory root) async {
  final files = <File>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.posix.normalize(
      p.relative(entity.path, from: root.path).replaceAll(r'\', '/'),
    );
    if (relative == 'project.json' ||
        relative.startsWith('maps/') ||
        relative.startsWith('dialogues/')) {
      files.add(entity);
    }
  }
  files.sort((a, b) => p
      .relative(a.path, from: root.path)
      .compareTo(p.relative(b.path, from: root.path)));
  final evidence = <String>[];
  for (final file in files) {
    final relative = p.posix.normalize(
      p.relative(file.path, from: root.path).replaceAll(r'\', '/'),
    );
    evidence.add(
      '$relative:${narrativeEventBytesFingerprint(await file.readAsBytes())}',
    );
  }
  return narrativeEventBytesFingerprint(utf8.encode(evidence.join('\n')));
}

Directory findPokemonProjectRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync() &&
        File(p.join(current.path, 'AGENTS.md')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = parent;
  }
}

Future<void> _cloneProject(Directory source, Directory destination) async {
  final result = await Process.run(
    '/bin/cp',
    <String>['-cR', source.path, destination.path],
  );
  if (result.exitCode == 0) return;
  await _copyDirectory(source, destination);
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity
      in source.list(recursive: false, followLinks: false)) {
    final target = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(target));
    } else if (entity is File) {
      await entity.copy(target);
    }
  }
}

Future<void> _removeLocalArtifacts(Directory root) async {
  final removals = <FileSystemEntity>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    final name = p.basename(entity.path);
    if (name == '.DS_Store' ||
        name == '.dart_tool' ||
        name == 'build' ||
        name == '.pokemap' ||
        name.startsWith('.pokemap-project-') ||
        name.endsWith('.lock')) {
      removals.add(entity);
    }
  }
  removals.sort((a, b) => b.path.length.compareTo(a.path.length));
  for (final entity in removals) {
    if (await entity.exists()) {
      await entity.delete(recursive: entity is Directory);
    }
  }
}
~~~~

### B.5 `packages/map_editor/test/selbrume_event_v2_authoring_slice_test.dart`

~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_event_v2_fixture.dart';

void main() {
  test(
    'J1 authors Lysa, port entry and clue sources through product operations',
    () async {
      final fixture = await SelbrumeEventV2Fixture.create();
      addTearDown(fixture.dispose);

      expect(fixture.copyFingerprintBefore, isNotEmpty);
      expect(
        await fixture.originalFingerprintAfter(),
        fixture.originalFingerprintBefore,
        reason: 'J1 must not mutate the original Selbrume project.',
      );

      final session = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final registry = session.manifest.eventRegistry!;
      expect(registry.mode, EventSystemMode.dualRead);
      expect(registry.records, hasLength(3));
      expect(registry.records.every((record) => record.enabledOrNull == true),
          isTrue);
      expect(
        registry.records.map((record) => record.definitionOrNull!.source),
        containsAll(<NarrativeEventSourceRef>[
          NarrativeEventSourceRef.entityInteract(
            selbrumePortMapId,
            selbrumeLysaEntityId,
          ),
          NarrativeEventSourceRef.triggerEnter(
            selbrumePortMapId,
            selbrumePortEntryTriggerId,
          ),
          NarrativeEventSourceRef.entityInteract(
            selbrumeMarshMapId,
            selbrumeClueEntityId,
          ),
        ]),
      );
      expect(
        registry.records.map((record) => record.definitionOrNull!.sceneId),
        containsAll(<String>[
          selbrumeLysaSceneId,
          selbrumePortEntrySceneId,
          selbrumeClueSceneId,
        ]),
      );
      final lysaScene = session.manifest.scenes.singleWhere(
        (scene) => scene.id == selbrumeLysaSceneId,
      );
      expect(
        lysaScene.graph.nodes.map((node) => node.kind),
        containsAll(<SceneNodeKind>[
          SceneNodeKind.yarnDialogue,
          SceneNodeKind.cinematic,
          SceneNodeKind.battle,
          SceneNodeKind.action,
        ]),
      );
      expect(
        lysaScene.graph.nodes
            .where((node) => node.kind == SceneNodeKind.action)
            .map((node) => (node.payload as SceneActionPayload).consequence)
            .whereType<SceneConsequence>()
            .map((consequence) => consequence.kind),
        containsAll(<SceneConsequenceKind>[
          SceneConsequenceKind.setFact,
          SceneConsequenceKind.completeStoryStep,
        ]),
      );
      expect(
        session.manifest.storylines
            .expand((storyline) => storyline.chapters)
            .expand((chapter) => chapter.steps)
            .where((step) => step.id == selbrumeLysaStoryStepId),
        hasLength(1),
      );

      final mapRepository = FileMapRepository();
      final portEntry = session.manifest.maps.singleWhere(
        (entry) => entry.id == selbrumePortMapId,
      );
      final marshEntry = session.manifest.maps.singleWhere(
        (entry) => entry.id == selbrumeMarshMapId,
      );
      final port = await mapRepository.loadMap(
        p.join(fixture.projectRoot.path, portEntry.relativePath),
      );
      final marsh = await mapRepository.loadMap(
        p.join(fixture.projectRoot.path, marshEntry.relativePath),
      );
      final lysa = port.entities.singleWhere(
        (entity) => entity.id == selbrumeLysaEntityId,
      );
      final clue = marsh.entities.singleWhere(
        (entity) => entity.id == selbrumeClueEntityId,
      );
      expect(lysa.pos, const GridPos(x: 26, y: 16));
      expect(lysa.kind, MapEntityKind.npc);
      expect(lysa.npc?.characterId, selbrumeLysaCharacterId);
      expect(lysa.npc?.trainerId, selbrumeLysaTrainerId);
      expect(clue.pos, const GridPos(x: 8, y: 32));
      expect(clue.kind, MapEntityKind.custom);
      expect(
        port.triggers.any(
          (trigger) => trigger.id == selbrumePortEntryTriggerId,
        ),
        isTrue,
      );

      final report = buildNarrativeEventValidationReport(
        registry: registry,
        catalog: session.context.catalog,
      );
      expect(
        report.diagnostics.where(
          (diagnostic) =>
              diagnostic.severity == NarrativeEventValidationSeverity.error,
        ),
        isEmpty,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
~~~~

### B.6 `packages/map_editor/test/selbrume_event_v2_persistence_migration_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_event_v2_fixture.dart';

const _recoveryEntityId = 'phase_j_recovery_probe';

void main() {
  group('J2 autonomous Selbrume Event V2 fixture', () {
    test('reopens identically and attests every payload hash', () async {
      final root = _versionedFixtureRoot();
      final manifest = _jsonObject(
        jsonDecode(
          await File(p.join(root.path, 'fixture_manifest.json')).readAsString(),
        ),
      );
      final payloadFiles = _jsonObjects(manifest['payloadFiles']);
      expect(payloadFiles, isNotEmpty);
      for (final entry in payloadFiles) {
        final file = File(p.join(root.path, entry['path']! as String));
        expect(await file.exists(), isTrue, reason: file.path);
        expect(
          narrativeEventBytesFingerprint(await file.readAsBytes()),
          entry['sha256'],
          reason: entry['path']! as String,
        );
        expect(await file.length(), entry['bytes']);
      }

      final projectPath = p.join(root.path, 'project.json');
      final first = await NarrativeEventAuthoringSession.prepare(projectPath);
      final second = await NarrativeEventAuthoringSession.prepare(projectPath);
      expect(first.manifest.toJson(), second.manifest.toJson());
      expect(first.manifest.maps.map((entry) => entry.id), <String>[
        selbrumePortMapId,
        selbrumeMarshMapId,
      ]);
      expect(first.context.registryOrNull?.records, hasLength(3));
      expect(
        first.context.registryOrNull?.records
            .every((record) => record.enabledOrNull == true),
        isTrue,
      );
      final mapRepository = FileMapRepository();
      for (final entry in first.manifest.maps) {
        final mapPath = p.join(root.path, entry.relativePath);
        final before = await mapRepository.loadMap(mapPath);
        final after = await mapRepository.loadMap(mapPath);
        expect(after.toJson(), before.toJson());
        expect(after.connections, isEmpty);
        expect(after.warps, isEmpty);
      }

      final promotion = _jsonObject(
        jsonDecode(
          await File(p.join(root.path, 'promotion_manifest.json'))
              .readAsString(),
        ),
      );
      expect(promotion['state'], 'frozenForJ5');
      final ordered = _jsonObjects(promotion['orderedFiles']);
      expect(ordered.map((entry) => entry['order']), <Object?>[1, 2, 3, 4]);
      expect(
        ordered.map((entry) => entry['destination']).toSet(),
        hasLength(4),
      );
      for (final entry in ordered) {
        final source = File(p.join(root.path, entry['source']! as String));
        expect(
          narrativeEventBytesFingerprint(await source.readAsBytes()),
          entry['sha256'],
        );
      }
    });

    test('regenerates the versioned fixture byte-for-byte from the checkpoint',
        () async {
      final fixture = await SelbrumeEventV2Fixture.create();
      addTearDown(fixture.dispose);
      final regeneratedRoot = Directory(
        p.join(fixture.temporaryRoot.path, 'regenerated_fixture'),
      );

      await fixture.exportAutonomousFixture(regeneratedRoot);

      expect(
        await _fileTreeFingerprints(regeneratedRoot),
        await _fileTreeFingerprints(_versionedFixtureRoot()),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('retries a map-first crash without rewriting the physical source',
        () async {
      final copy = await _copyVersionedFixture();
      addTearDown(copy.dispose);
      final probe = await _prepareRecoveryProbe(copy);
      final mapFile = File(probe.mapPath);
      final beforeMapHash = narrativeEventBytesFingerprint(
        await mapFile.readAsBytes(),
      );
      final interrupted = await _interruptBetweenMapAndRegistry(
        copy: copy,
        probe: probe,
        operationId: 'phase_j_retry',
      );
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(
        interrupted.journal?.state,
        NarrativeEventSpatialLinkJournalState.mapCommitted,
      );
      final committedMapBytes = await mapFile.readAsBytes();
      expect(
        narrativeEventBytesFingerprint(committedMapBytes),
        isNot(beforeMapHash),
      );

      final restarted = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
        registryGateway: FileProjectRepository(),
      );
      final retried = await restarted.retry(
        projectPath: copy.projectPath,
        expectedEventId: probe.eventId,
        expectedMapId: selbrumePortMapId,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        retried.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(await mapFile.readAsBytes(), committedMapBytes);
      final reopened = await NarrativeEventAuthoringSession.prepare(
        copy.projectPath,
      );
      final record = reopened.manifest.eventRegistry!.records.singleWhere(
        (candidate) => candidate.id == probe.eventId,
      );
      expect(record.draftOrNull?.source, probe.proposal.source);

      final acknowledged = await restarted.acknowledge(
        projectPath: copy.projectPath,
        operationId: retried.journal!.operationId,
        expectedEventId: probe.eventId,
        expectedMapId: selbrumePortMapId,
      );
      expect(
        acknowledged.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(
        (await NarrativeEventSpatialLinkJournalRepository()
                .inspectProject(copy.projectPath))
            .status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    test('rejects a stale project revision before any source write', () async {
      final copy = await _copyVersionedFixture();
      addTearDown(copy.dispose);
      final probe = await _prepareRecoveryProbe(copy);
      final session = await NarrativeEventAuthoringSession.prepare(
        copy.projectPath,
      );
      final record = session.manifest.eventRegistry!.records.singleWhere(
        (candidate) => candidate.id == probe.eventId,
      );
      final mapBytesBefore = await File(probe.mapPath).readAsBytes();
      await File(copy.projectPath).writeAsString(
        '${await File(copy.projectPath).readAsString()}\n',
        flush: true,
      );

      final result =
          await NarrativeEventSpatialLinkJournalRepository().commitMap(
        NarrativeEventSpatialLinkMapCommitRequest(
          projectPath: copy.projectPath,
          projectRevision: session.projectRevision,
          operationId: 'phase_j_stale_revision',
          eventId: probe.eventId,
          eventRecordFingerprintBefore:
              narrativeEventRecordCanonicalFingerprint(record),
          beforeMap: probe.proposal.beforeMap,
          afterMap: probe.proposal.afterMap,
          source: probe.proposal.source,
          sourceOwnerJson: probe.proposal.ownerJson,
          sourceOwnerFingerprint: probe.proposal.ownerFingerprint,
        ),
      );
      expect(result.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(result.code, 'staleProjectRevision');
      expect(await File(probe.mapPath).readAsBytes(), mapBytesBefore);
      expect(result.journal, isNull);
    });

    test('compensates only the exact owner and preserves divergent evidence',
        () async {
      final cleanCopy = await _copyVersionedFixture();
      addTearDown(cleanCopy.dispose);
      final cleanProbe = await _prepareRecoveryProbe(cleanCopy);
      final beforeMap = cleanProbe.proposal.beforeMap;
      final interrupted = await _interruptBetweenMapAndRegistry(
        copy: cleanCopy,
        probe: cleanProbe,
        operationId: 'phase_j_compensation',
      );
      expect(await FileProjectRepository().recover(cleanCopy.projectPath),
          isNotEmpty);
      final cleanup = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
        registryGateway: FileProjectRepository(),
      );
      final cleaned = await cleanup.cleanup(
        projectPath: cleanCopy.projectPath,
        operationId: interrupted.journal!.operationId,
        expectedEventId: cleanProbe.eventId,
        expectedMapId: selbrumePortMapId,
        confirmed: true,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        cleaned.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
        reason: '${cleaned.code}: ${cleaned.message}',
      );
      final restored = await FileMapRepository().loadMap(cleanProbe.mapPath);
      expect(restored.toJson(), beforeMap.toJson());

      final revisionCopy = await _copyVersionedFixture();
      addTearDown(revisionCopy.dispose);
      final revisionProbe = await _prepareRecoveryProbe(revisionCopy);
      final revisionInterrupted = await _interruptBetweenMapAndRegistry(
        copy: revisionCopy,
        probe: revisionProbe,
        operationId: 'phase_j_cleanup_revision',
      );
      expect(
        await FileProjectRepository().recover(revisionCopy.projectPath),
        isNotEmpty,
      );
      final revisionGatedCleanup = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: NarrativeEventSpatialLinkJournalRepository(
          faultInjector: (checkpoint) async {
            if (checkpoint ==
                NarrativeEventSpatialLinkCheckpoint.beforeCleanupRename) {
              await File(revisionCopy.projectPath).writeAsString(
                '${await File(revisionCopy.projectPath).readAsString()}\n',
                flush: true,
              );
            }
          },
        ),
        registryGateway: FileProjectRepository(),
      );
      final revisionRefused = await revisionGatedCleanup.cleanup(
        projectPath: revisionCopy.projectPath,
        operationId: revisionInterrupted.journal!.operationId,
        expectedEventId: revisionProbe.eventId,
        expectedMapId: selbrumePortMapId,
        confirmed: true,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        revisionRefused.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(revisionRefused.code, 'projectChangedDuringCleanup');
      expect(
        (await FileMapRepository().loadMap(revisionProbe.mapPath))
            .entities
            .any((entity) => entity.id == _recoveryEntityId),
        isTrue,
      );
      expect(
        await File(revisionInterrupted.journal!.journalPath).exists(),
        isTrue,
      );

      final divergentCopy = await _copyVersionedFixture();
      addTearDown(divergentCopy.dispose);
      final divergentProbe = await _prepareRecoveryProbe(divergentCopy);
      final divergentInterrupted = await _interruptBetweenMapAndRegistry(
        copy: divergentCopy,
        probe: divergentProbe,
        operationId: 'phase_j_divergent_owner',
      );
      expect(await FileProjectRepository().recover(divergentCopy.projectPath),
          isNotEmpty);
      final mapFile = File(divergentProbe.mapPath);
      final committedMap = await FileMapRepository().loadMap(mapFile.path);
      final tampered = committedMap.copyWith(
        entities: <MapEntity>[
          for (final entity in committedMap.entities)
            if (entity.id == _recoveryEntityId)
              entity.copyWith(name: 'Ownership changed elsewhere')
            else
              entity,
        ],
      );
      await mapFile.writeAsBytes(
        utf8.encode(jsonEncode(tampered.toJson())),
        flush: true,
      );
      final divergentBytes = await mapFile.readAsBytes();
      final refused = await cleanup.cleanup(
        projectPath: divergentCopy.projectPath,
        operationId: divergentInterrupted.journal!.operationId,
        expectedEventId: divergentProbe.eventId,
        expectedMapId: selbrumePortMapId,
        confirmed: true,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        refused.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(refused.code, 'sourceFingerprintMismatch');
      expect(await mapFile.readAsBytes(), divergentBytes);
      expect(
        await File(divergentInterrupted.journal!.journalPath).exists(),
        isTrue,
      );
    });
  });
}

Directory _versionedFixtureRoot() {
  return Directory(
    p.join(
      findPokemonProjectRoot().path,
      'examples',
      'playable_runtime_host',
      'event_builder_v2_selbrume_slice',
    ),
  );
}

Future<Map<String, String>> _fileTreeFingerprints(Directory root) async {
  final files = <File>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is File) files.add(entity);
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return <String, String>{
    for (final file in files)
      p.posix.normalize(
        p.relative(file.path, from: root.path).replaceAll(r'\', '/'),
      ): narrativeEventBytesFingerprint(await file.readAsBytes()),
  };
}

Future<_FixtureCopy> _copyVersionedFixture() async {
  final temporaryRoot =
      await Directory.systemTemp.createTemp('pokemap_phase_j_fixture_');
  final projectRoot = Directory(p.join(temporaryRoot.path, 'slice'));
  final result = await Process.run(
    '/bin/cp',
    <String>['-cR', _versionedFixtureRoot().path, projectRoot.path],
  );
  if (result.exitCode != 0) {
    throw FileSystemException('Fixture clone failed', '${result.stderr}');
  }
  return _FixtureCopy(
    temporaryRoot: temporaryRoot,
    projectRoot: projectRoot,
    projectPath: p.join(projectRoot.path, 'project.json'),
  );
}

Future<_RecoveryProbe> _prepareRecoveryProbe(_FixtureCopy copy) async {
  final builder = NarrativeEventBuilderV2UseCase(
    persistenceGateway: FileProjectRepository(),
    idGeneratorFactory: () => NarrativeEventIdGenerator(
      rawUuidFactory: () => '019abcde-4000-7000-8000-000000000099',
    ),
    operationIdFactory: () => 'phase_j_recovery_draft',
  );
  final draft = await builder.createDraft(
    projectPath: copy.projectPath,
    name: 'J2 recovery probe',
    environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
  );
  if (!draft.succeeded || draft.eventId == null) {
    throw StateError('${draft.code}: ${draft.message}');
  }
  final session = await NarrativeEventAuthoringSession.prepare(
    copy.projectPath,
  );
  final mapEntry = session.manifest.maps.singleWhere(
    (entry) => entry.id == selbrumePortMapId,
  );
  final mapPath = p.join(copy.projectRoot.path, mapEntry.relativePath);
  final beforeMap = await FileMapRepository().loadMap(mapPath);
  const owner = MapEntity(
    id: _recoveryEntityId,
    name: 'J2 recovery probe',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 40, y: 31),
    sign: MapEntitySignData(),
  );
  final proposal = NarrativeEventCreatedSourceProposal(
    physicalKind: NarrativeEventPhysicalSourceKind.sign,
    source: NarrativeEventSourceRef.entityInteract(
      selbrumePortMapId,
      _recoveryEntityId,
    ),
    beforeMap: beforeMap,
    afterMap: beforeMap.copyWith(
      entities: <MapEntity>[...beforeMap.entities, owner],
    ),
    bounds: const MapRect(
      pos: GridPos(x: 40, y: 31),
      size: GridSize(width: 1, height: 1),
    ),
    ownerJson: <String, Object?>{
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': selbrumePortMapId,
      'sourceId': _recoveryEntityId,
      'owner': owner.toJson(),
    },
  );
  return _RecoveryProbe(
    eventId: draft.eventId!,
    mapPath: mapPath,
    proposal: proposal,
  );
}

Future<NarrativeEventExplicitSourceCreationResult>
    _interruptBetweenMapAndRegistry({
  required _FixtureCopy copy,
  required _RecoveryProbe probe,
  required String operationId,
}) {
  final useCase = NarrativeEventExplicitSourceCreationUseCase(
    sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
    registryGateway: FileProjectRepository(
      eventRegistryPersistence: NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated registry crash');
          }
        },
      ),
    ),
    operationIdFactory: () => operationId,
  );
  return useCase.createAndLink(
    projectPath: copy.projectPath,
    eventId: probe.eventId,
    proposal: probe.proposal,
    mapDirty: false,
    projectDirty: false,
    saving: false,
  );
}

Map<String, Object?> _jsonObject(Object? value) {
  return (value as Map).cast<String, Object?>();
}

List<Map<String, Object?>> _jsonObjects(Object? value) {
  return (value as List)
      .map((entry) => _jsonObject(entry))
      .toList(growable: false);
}

final class _FixtureCopy {
  const _FixtureCopy({
    required this.temporaryRoot,
    required this.projectRoot,
    required this.projectPath,
  });

  final Directory temporaryRoot;
  final Directory projectRoot;
  final String projectPath;

  Future<void> dispose() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  }
}

final class _RecoveryProbe {
  const _RecoveryProbe({
    required this.eventId,
    required this.mapPath,
    required this.proposal,
  });

  final String eventId;
  final String mapPath;
  final NarrativeEventCreatedSourceProposal proposal;
}
~~~~

### B.7 `packages/map_editor/test/selbrume_event_v2_promotion_recovery_test.dart`

~~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/journaled_file_promotion_repository.dart';
import 'package:map_editor/src/infrastructure/repositories/project_manifest_write_lock.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_event_v2_fixture.dart';

const _allowedDestinations = <String>{
  'selbrume/project.json',
  'selbrume/maps/map_port_brisants.json',
  'selbrume/maps/map_marais_salants.json',
  'selbrume/dialogues/lysa_port.yarn',
};

void main() {
  group('J5 journaled Selbrume promotion', () {
    test('resumes idempotently after every durable write boundary', () async {
      for (var interruptedBoundary = 0;
          interruptedBoundary <= 4;
          interruptedBoundary++) {
        final sandbox = await _PromotionSandbox.create();
        try {
          final interrupted = await sandbox.repository(
            faultInjector: (renamedFileCount) async {
              if (renamedFileCount == interruptedBoundary) {
                throw StateError('Injected boundary $interruptedBoundary');
              }
            },
          ).promote();
          expect(
            interrupted.status,
            JournaledFilePromotionStatus.recoveryRequired,
            reason: 'boundary $interruptedBoundary: ${interrupted.code}',
          );
          expect(await File(sandbox.journalPath).exists(), isTrue);
          expect(
            await Directory('${sandbox.journalPath}.checkpoint').exists(),
            isTrue,
          );

          final resumed = await sandbox.repository().promote();
          expect(
            resumed.status,
            JournaledFilePromotionStatus.promoted,
            reason: 'boundary $interruptedBoundary: ${resumed.code}',
          );
          await sandbox.expectAfterHashes();
          expect(await File(sandbox.journalPath).exists(), isFalse);
          expect(
            await Directory('${sandbox.journalPath}.checkpoint').exists(),
            isFalse,
          );

          final replayed = await sandbox.repository().promote();
          expect(replayed.status, JournaledFilePromotionStatus.noOp);
          await sandbox.expectAfterHashes();
        } finally {
          await sandbox.dispose();
        }
      }
    });

    test('rebuilds an interrupted checkpoint before any destination write',
        () async {
      for (var interruptedBoundary = 1;
          interruptedBoundary <= 4;
          interruptedBoundary++) {
        final sandbox = await _PromotionSandbox.create();
        try {
          final interrupted = await sandbox.repository(
            checkpointFaultInjector: (checkpointedFileCount) async {
              if (checkpointedFileCount == interruptedBoundary) {
                throw StateError(
                  'Injected checkpoint boundary $interruptedBoundary',
                );
              }
            },
          ).promote();
          expect(
            interrupted.status,
            JournaledFilePromotionStatus.recoveryRequired,
          );
          expect(await File(sandbox.journalPath).exists(), isTrue);
          await sandbox.expectBeforeHashes();

          final resumed = await sandbox.repository().promote();
          expect(resumed.status, JournaledFilePromotionStatus.promoted);
          await sandbox.expectAfterHashes();
        } finally {
          await sandbox.dispose();
        }
      }
    });

    test('restores the autonomous pre-promotion checkpoint exactly', () async {
      final sandbox = await _PromotionSandbox.create();
      addTearDown(sandbox.dispose);
      final interrupted = await sandbox.repository(
        faultInjector: (renamedFileCount) async {
          if (renamedFileCount == 2) throw StateError('restore probe');
        },
      ).promote();
      expect(
        interrupted.status,
        JournaledFilePromotionStatus.recoveryRequired,
      );

      final restored = await sandbox.repository().restoreCheckpoint();
      expect(restored.status, JournaledFilePromotionStatus.restored);
      await sandbox.expectBeforeHashes();
      expect(await File(sandbox.journalPath).exists(), isFalse);
    });

    test('preserves journal and bytes when ownership diverges', () async {
      final sandbox = await _PromotionSandbox.create();
      addTearDown(sandbox.dispose);
      final interrupted = await sandbox.repository(
        faultInjector: (renamedFileCount) async {
          if (renamedFileCount == 1) throw StateError('divergence probe');
        },
      ).promote();
      expect(
        interrupted.status,
        JournaledFilePromotionStatus.recoveryRequired,
      );
      final projectFile = File(
        p.join(sandbox.repositoryRoot.path, 'selbrume', 'project.json'),
      );
      await projectFile.writeAsString(
        '${await projectFile.readAsString()}\nexternal-change',
        flush: true,
      );
      final divergentBytes = await projectFile.readAsBytes();

      final refused = await sandbox.repository().promote();
      expect(refused.status, JournaledFilePromotionStatus.blocked);
      expect(refused.code, 'promotionOwnershipDiverged');
      expect(await projectFile.readAsBytes(), divergentBytes);
      expect(await File(sandbox.journalPath).exists(), isTrue);

      final restoreRefused = await sandbox.repository().restoreCheckpoint();
      expect(restoreRefused.status, JournaledFilePromotionStatus.blocked);
      expect(restoreRefused.code, 'promotionOwnershipDiverged');
      expect(await projectFile.readAsBytes(), divergentBytes);
    });

    test('refuses a fifth destination and destination symlinks', () async {
      final sandbox = await _PromotionSandbox.create();
      addTearDown(sandbox.dispose);
      final manifestRoot = _jsonObject(
        jsonDecode(await File(sandbox.manifestPath).readAsString()),
      );
      final ordered = List<Map<String, Object?>>.of(
        _jsonObjects(manifestRoot['orderedFiles']),
      );
      ordered.add(<String, Object?>{
        ...ordered.last,
        'order': 5,
        'destination': 'selbrume/maps/unreviewed.json',
      });
      manifestRoot['orderedFiles'] = ordered;
      final expandedManifest = File(
        p.join(sandbox.root.path, 'expanded-promotion-manifest.json'),
      );
      await expandedManifest.writeAsString(jsonEncode(manifestRoot));
      final expanded = JournaledFilePromotionRepository(
        repositoryRoot: sandbox.repositoryRoot.path,
        manifestPath: expandedManifest.path,
        allowedDestinations: _allowedDestinations,
        journalPath: sandbox.journalPath,
      );
      final scopeRefused = await expanded.promote();
      expect(scopeRefused.status, JournaledFilePromotionStatus.blocked);
      expect(scopeRefused.code, 'promotionScopeMismatch');

      final portPath = p.join(
        sandbox.repositoryRoot.path,
        'selbrume',
        'maps',
        'map_port_brisants.json',
      );
      await File(portPath).delete();
      await Link(portPath).create(
        p.join(
          sandbox.fixtureRoot.path,
          'promotion_checkpoint',
          'maps',
          'map_port_brisants.json',
        ),
      );
      final symlinkRefused = await sandbox.repository().promote();
      expect(symlinkRefused.status, JournaledFilePromotionStatus.blocked);
      expect(symlinkRefused.code, 'promotionSymlinkRefused');
    });

    test('holds the shared project lock across classification and rename',
        () async {
      final sandbox = await _PromotionSandbox.create();
      addTearDown(sandbox.dispose);
      final beforeReplaceReached = Completer<void>();
      final allowReplace = Completer<void>();
      var hookCalls = 0;
      final promotion = sandbox.repository(
        beforeReplaceHook: (_, __, ___) async {
          hookCalls++;
          if (hookCalls == 1) {
            beforeReplaceReached.complete();
            await allowReplace.future;
          }
        },
      ).promote();
      await beforeReplaceReached.future;

      var competingWriterEntered = false;
      final competingWrite = withProjectManifestWriteLock(
        p.join(sandbox.repositoryRoot.path, 'selbrume', 'project.json'),
        () async => competingWriterEntered = true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(competingWriterEntered, isFalse);

      allowReplace.complete();
      expect((await promotion).status, JournaledFilePromotionStatus.promoted);
      await competingWrite;
      expect(competingWriterEntered, isTrue);
    });

    test('refuses source or destination mutation immediately before rename',
        () async {
      for (final mutateSource in <bool>[true, false]) {
        final sandbox = await _PromotionSandbox.create();
        File? mutatedSourceFile;
        List<int>? originalSourceBytes;
        try {
          List<int>? divergentDestinationBytes;
          var mutated = false;
          final result = await sandbox.repository(
            beforeReplaceHook: (_, sourcePath, destinationPath) async {
              if (mutated) return;
              mutated = true;
              if (mutateSource) {
                final source = File(sourcePath);
                mutatedSourceFile = source;
                originalSourceBytes = await source.readAsBytes();
                await source.writeAsString(
                  '${await source.readAsString()}\nsource-race',
                  flush: true,
                );
              } else {
                final destination = File(destinationPath);
                divergentDestinationBytes = utf8.encode('destination-race');
                await destination.writeAsBytes(
                  divergentDestinationBytes!,
                  flush: true,
                );
              }
            },
          ).promote();

          expect(result.status, JournaledFilePromotionStatus.blocked);
          expect(
            result.code,
            mutateSource
                ? 'promotionSourceChangedBeforeWrite'
                : 'promotionDestinationChangedBeforeWrite',
          );
          expect(await File(sandbox.journalPath).exists(), isTrue);
          if (!mutateSource) {
            final projectFile = File(
              p.join(
                sandbox.repositoryRoot.path,
                'selbrume',
                'project.json',
              ),
            );
            expect(await projectFile.readAsBytes(), divergentDestinationBytes);
          }
        } finally {
          if (mutatedSourceFile != null && originalSourceBytes != null) {
            await mutatedSourceFile!.writeAsBytes(
              originalSourceBytes!,
              flush: true,
            );
          }
          await sandbox.dispose();
        }
      }
    });
  });
}

final class _PromotionSandbox {
  _PromotionSandbox._({
    required this.root,
    required this.repositoryRoot,
    required this.fixtureRoot,
    required this.manifestPath,
    required this.journalPath,
    required this.entries,
  });

  final Directory root;
  final Directory repositoryRoot;
  final Directory fixtureRoot;
  final String manifestPath;
  final String journalPath;
  final List<Map<String, Object?>> entries;

  static Future<_PromotionSandbox> create() async {
    final repoRoot = findPokemonProjectRoot();
    final fixtureRoot = Directory(
      p.join(
        repoRoot.path,
        'examples',
        'playable_runtime_host',
        'event_builder_v2_selbrume_slice',
      ),
    );
    final manifestPath = p.join(
      fixtureRoot.path,
      'promotion_manifest.json',
    );
    final manifest = _jsonObject(
      jsonDecode(await File(manifestPath).readAsString()),
    );
    final entries = _jsonObjects(manifest['orderedFiles']);
    expect(entries.map((entry) => entry['destination']).toSet(),
        _allowedDestinations);

    final root = await Directory.systemTemp.createTemp(
      'pokemap_phase_j_promotion_',
    );
    final repositoryRoot = Directory(p.join(root.path, 'repository'));
    await repositoryRoot.create(recursive: true);
    for (final entry in entries) {
      final destination = File(
        p.join(repositoryRoot.path, entry['destination']! as String),
      );
      if (entry['beforeExists'] == true) {
        final relative =
            (entry['destination']! as String).replaceFirst('selbrume/', '');
        final checkpoint = File(
          p.join(fixtureRoot.path, 'promotion_checkpoint', relative),
        );
        await destination.parent.create(recursive: true);
        await checkpoint.copy(destination.path);
        expect(
          narrativeEventBytesFingerprint(await destination.readAsBytes()),
          entry['beforeSha256'],
        );
      }
    }
    final journalPath = p.join(
      repositoryRoot.path,
      'selbrume',
      '.pokemap-event-v2-phase-j-promotion.json',
    );
    return _PromotionSandbox._(
      root: root,
      repositoryRoot: repositoryRoot,
      fixtureRoot: fixtureRoot,
      manifestPath: manifestPath,
      journalPath: journalPath,
      entries: entries,
    );
  }

  JournaledFilePromotionRepository repository({
    JournaledPromotionFaultInjector? faultInjector,
    JournaledPromotionBeforeReplaceHook? beforeReplaceHook,
    JournaledPromotionCheckpointFaultInjector? checkpointFaultInjector,
  }) {
    return JournaledFilePromotionRepository(
      repositoryRoot: repositoryRoot.path,
      manifestPath: manifestPath,
      allowedDestinations: _allowedDestinations,
      journalPath: journalPath,
      faultInjector: faultInjector,
      beforeReplaceHook: beforeReplaceHook,
      checkpointFaultInjector: checkpointFaultInjector,
    );
  }

  Future<void> expectBeforeHashes() async {
    for (final entry in entries) {
      final destination = File(
        p.join(repositoryRoot.path, entry['destination']! as String),
      );
      if (entry['beforeExists'] == true) {
        expect(await destination.exists(), isTrue);
        expect(
          narrativeEventBytesFingerprint(await destination.readAsBytes()),
          entry['beforeSha256'],
        );
      } else {
        expect(await destination.exists(), isFalse);
      }
    }
  }

  Future<void> expectAfterHashes() async {
    for (final entry in entries) {
      final destination = File(
        p.join(repositoryRoot.path, entry['destination']! as String),
      );
      expect(await destination.exists(), isTrue);
      expect(
        narrativeEventBytesFingerprint(await destination.readAsBytes()),
        entry['afterSha256'],
      );
    }
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Map<String, Object?> _jsonObject(Object? value) =>
    (value! as Map).cast<String, Object?>();

List<Map<String, Object?>> _jsonObjects(Object? value) => (value! as List)
    .map((entry) => (entry! as Map).cast<String, Object?>())
    .toList(growable: false);
~~~~

### B.8 `packages/map_editor/tool/build_selbrume_event_v2_fixture.dart`

~~~~dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../test/support/selbrume_event_v2_fixture.dart';

void main() {
  test('builds the autonomous Selbrume Event V2 fixture', () async {
    final fixture = await SelbrumeEventV2Fixture.create();
    try {
      final destination = Directory(
        p.join(
          fixture.repoRoot.path,
          'examples',
          'playable_runtime_host',
          'event_builder_v2_selbrume_slice',
        ),
      );
      await fixture.exportAutonomousFixture(destination);
      stdout.writeln('Generated ${destination.path}');
    } finally {
      await fixture.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
~~~~

### B.9 `packages/map_editor/tool/promote_selbrume_event_v2_fixture.dart`

~~~~dart
import 'dart:io';

import 'package:map_editor/src/infrastructure/repositories/journaled_file_promotion_repository.dart';
import 'package:path/path.dart' as p;

const _allowedDestinations = <String>{
  'selbrume/project.json',
  'selbrume/maps/map_port_brisants.json',
  'selbrume/maps/map_marais_salants.json',
  'selbrume/dialogues/lysa_port.yarn',
};

Future<void> main() async {
  final repositoryRoot = _findRepositoryRoot();
  final manifestPath = p.join(
    repositoryRoot.path,
    'examples',
    'playable_runtime_host',
    'event_builder_v2_selbrume_slice',
    'promotion_manifest.json',
  );
  final result = await JournaledFilePromotionRepository(
    repositoryRoot: repositoryRoot.path,
    manifestPath: manifestPath,
    allowedDestinations: _allowedDestinations,
  ).promote();
  stdout.writeln('${result.status.name}: ${result.code}');
  stdout.writeln(result.message);
  if (!result.succeeded) {
    stderr.writeln('Journal conservé: ${result.journalPath}');
    exitCode = 1;
  }
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
~~~~

### B.10 `packages/map_runtime/test/support/selbrume_event_v2_test_fixture.dart`

~~~~dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const selbrumePortMapId = 'map_port_brisants';
const selbrumeMarshMapId = 'map_marais_salants';
const selbrumeLysaEntityId = 'npc_lysa';
const selbrumePortEntryTriggerId = 'zone_port_entry';
const selbrumeClueEntityId = 'clue_glass_object';
const selbrumeLysaSceneId = 'scene_lysa_port';
const selbrumePortEntrySceneId = 'scene_port_entry';
const selbrumeClueSceneId = 'scene_clue_glass';
const selbrumeLysaEventId = 'evt_019abcde-4000-7000-8000-000000000001';
const selbrumePortEntryEventId = 'evt_019abcde-4000-7000-8000-000000000002';
const selbrumeClueEventId = 'evt_019abcde-4000-7000-8000-000000000003';

final class SelbrumeEventV2RuntimeFixture {
  SelbrumeEventV2RuntimeFixture._(this.root, this.projectPath, this.label);

  final Directory root;
  final String projectPath;
  final String label;

  static SelbrumeEventV2RuntimeFixture locate() {
    var current = Directory.current.absolute;
    while (true) {
      final candidate = Directory(
        p.join(
          current.path,
          'examples',
          'playable_runtime_host',
          'event_builder_v2_selbrume_slice',
        ),
      );
      if (File(p.join(candidate.path, 'project.json')).existsSync()) {
        return SelbrumeEventV2RuntimeFixture._(
          candidate,
          p.join(candidate.path, 'project.json'),
          'versioned fixture',
        );
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        throw StateError('Selbrume Event V2 fixture not found.');
      }
      current = parent;
    }
  }

  static SelbrumeEventV2RuntimeFixture locatePromoted() {
    var current = Directory.current.absolute;
    while (true) {
      final candidate = Directory(p.join(current.path, 'selbrume'));
      if (File(p.join(candidate.path, 'project.json')).existsSync() &&
          File(p.join(current.path, 'AGENTS.md')).existsSync()) {
        return SelbrumeEventV2RuntimeFixture._(
          candidate,
          p.join(candidate.path, 'project.json'),
          'promoted Selbrume',
        );
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        throw StateError('Promoted Selbrume project not found.');
      }
      current = parent;
    }
  }

  Future<RuntimeMapBundle> loadHarnessBundle({
    required String mapId,
    required GridPos playerPos,
    required EntityFacing facing,
  }) async {
    final source = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: mapId,
    );
    const spawnId = 'phase_j_runtime_test_spawn';
    final map = source.map.copyWith(
      entities: <MapEntity>[
        for (final entity in source.map.entities)
          if (entity.kind != MapEntityKind.spawn) entity,
        MapEntity(
          id: spawnId,
          name: 'Phase J runtime test spawn',
          kind: MapEntityKind.spawn,
          pos: playerPos,
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: facing,
          ),
        ),
      ],
      mapMetadata: source.map.mapMetadata.copyWith(defaultSpawnId: spawnId),
    );
    return RuntimeMapBundle(
      manifest: source.manifest,
      map: map,
      projectRootDirectory: source.projectRootDirectory,
      tilesetAbsolutePathsById: source.tilesetAbsolutePathsById,
    );
  }
}
~~~~

### B.11 `packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart`

~~~~dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('J3 Selbrume sources through PlayableMapGame production hooks', () {
    for (final fixture in <SelbrumeEventV2RuntimeFixture>[
      SelbrumeEventV2RuntimeFixture.locate(),
      SelbrumeEventV2RuntimeFixture.locatePromoted(),
    ]) {
      for (final target in const <_EntityTarget>[
        _EntityTarget(
          label: 'Lysa NPC',
          mapId: selbrumePortMapId,
          entityId: selbrumeLysaEntityId,
          eventId: selbrumeLysaEventId,
          sceneId: selbrumeLysaSceneId,
          playerPos: GridPos(x: 26, y: 17),
          facing: EntityFacing.north,
          completesImmediately: false,
        ),
        _EntityTarget(
          label: 'glass clue object',
          mapId: selbrumeMarshMapId,
          entityId: selbrumeClueEntityId,
          eventId: selbrumeClueEventId,
          sceneId: selbrumeClueSceneId,
          playerPos: GridPos(x: 8, y: 33),
          facing: EntityFacing.north,
          completesImmediately: true,
        ),
      ]) {
        test(
            '${fixture.label}: ${target.label} dispatches its authored Scene once',
            () async {
          final source = NarrativeEventSourceRef.entityInteract(
            target.mapId,
            target.entityId,
          );
          final prepared = <NarrativeEventSourceRef>[];
          final decisions = <NarrativeEventDispatchDecision>[];
          final bundle = await fixture.loadHarnessBundle(
            mapId: target.mapId,
            playerPos: target.playerPos,
            facing: target.facing,
          );
          final authoredRecord =
              bundle.manifest.eventRegistry!.records.singleWhere(
            (record) => record.definitionOrNull?.source == source,
          );
          expect(
            authoredRecord.definitionOrNull?.sceneId,
            target.sceneId,
          );
          late _TestPlayableMapGame game;
          game = _TestPlayableMapGame(
            bundle: bundle,
            projectFilePath: fixture.projectPath,
            beforeNarrativeAuthorityPreparation: (occurrence) async {
              if (occurrence.source == source) prepared.add(occurrence.source);
            },
            afterNarrativeAuthorityPreparation:
                (occurrence, preparation) async {
              if (occurrence.source == source &&
                  preparation is NarrativeEventDispatchAuthorityReady) {
                decisions.add(
                  preparation.plan(gameState: game.gameStateSnapshot),
                );
              }
            },
          );

          await _load(game);
          expect(game.debugPlayerGridPosition, target.playerPos);
          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _pumpUntil(game, () => prepared.isNotEmpty);
          if (target.completesImmediately) {
            await _pumpUntil(
              game,
              () => game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds
                  .contains(target.eventId),
            );
          }

          expect(prepared, <NarrativeEventSourceRef>[source]);
          expect(decisions.single, isA<NarrativeEventDispatchHandled>());
          expect(
            (decisions.single as NarrativeEventDispatchHandled).sceneId,
            target.sceneId,
          );
          if (target.completesImmediately) {
            expect(
              game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds,
              contains(target.eventId),
            );
            expect(
              game.handleRuntimeInputEvent(
                const RuntimeInputEvent.press(RuntimeInputControl.primary),
              ),
              isTrue,
            );
            await _pumpTicks(game, 30);
            expect(
              prepared,
              <NarrativeEventSourceRef>[source, source],
            );
            expect(decisions, hasLength(2));
            final ineligible = decisions.last;
            expect(ineligible, isNot(isA<NarrativeEventDispatchHandled>()));
            expect(
              _reasons(ineligible),
              contains(NarrativeEventDispatchReason.eventConsumed),
              reason: 'A consumed one-shot source must be ineligible.',
            );
          } else {
            expect(
              game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds,
              isNot(contains(target.eventId)),
              reason: 'Lysa remains in-flight until the host closes Yarn.',
            );
            expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
          }
        });
      }

      test('${fixture.label}: port entry dispatches from a real movement front',
          () async {
        final source = NarrativeEventSourceRef.triggerEnter(
          selbrumePortMapId,
          selbrumePortEntryTriggerId,
        );
        final prepared = <NarrativeEventSourceRef>[];
        final decisions = <NarrativeEventDispatchDecision>[];
        final bundle = await fixture.loadHarnessBundle(
          mapId: selbrumePortMapId,
          playerPos: const GridPos(x: 25, y: 1),
          facing: EntityFacing.east,
        );
        final authoredRecord =
            bundle.manifest.eventRegistry!.records.singleWhere(
          (record) => record.definitionOrNull?.source == source,
        );
        expect(
          authoredRecord.definitionOrNull?.sceneId,
          selbrumePortEntrySceneId,
        );
        late _TestPlayableMapGame game;
        game = _TestPlayableMapGame(
          bundle: bundle,
          projectFilePath: fixture.projectPath,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source == source) prepared.add(occurrence.source);
          },
          afterNarrativeAuthorityPreparation: (occurrence, preparation) async {
            if (occurrence.source == source &&
                preparation is NarrativeEventDispatchAuthorityReady) {
              decisions.add(
                preparation.plan(gameState: game.gameStateSnapshot),
              );
            }
          },
        );

        await _load(game);
        expect(prepared, isEmpty,
            reason: 'Spawn outside must not be an entry.');
        await _runSingleMove(game, RuntimeInputControl.right);
        await _pumpUntil(
          game,
          () => game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .contains(selbrumePortEntryEventId),
        );

        expect(game.debugPlayerGridPosition, const GridPos(x: 26, y: 1));
        expect(prepared, <NarrativeEventSourceRef>[source]);
        expect(decisions.single, isA<NarrativeEventDispatchHandled>());
        expect(
          (decisions.single as NarrativeEventDispatchHandled).sceneId,
          selbrumePortEntrySceneId,
        );

        await _runSingleMove(game, RuntimeInputControl.left);
        await _runSingleMove(game, RuntimeInputControl.right);
        await _pumpTicks(game, 30);
        expect(
          prepared,
          <NarrativeEventSourceRef>[source, source],
        );
        expect(decisions, hasLength(2));
        final ineligible = decisions.last;
        expect(ineligible, isNot(isA<NarrativeEventDispatchHandled>()));
        expect(
          _reasons(ineligible),
          contains(NarrativeEventDispatchReason.eventConsumed),
          reason: 'Re-entering a consumed one-shot trigger must be ineligible.',
        );
      });
    }
  });
}

List<NarrativeEventDispatchReason> _reasons(
  NarrativeEventDispatchDecision decision,
) {
  return switch (decision) {
    NarrativeEventDispatchClaimedButIneligible(:final reasons) => reasons,
    NarrativeEventDispatchNoMatch(:final reasons) => reasons,
    NarrativeEventDispatchHandled() => const <NarrativeEventDispatchReason>[],
  };
}

Future<void> _pumpTicks(PlayableMapGame game, int ticks) async {
  for (var index = 0; index < ticks; index++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  for (var index = 0; index < 180; index++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (!game.debugIsPlayerStepping) return;
  }
  fail('Timed out waiting for the Selbrume movement step.');
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 2000,
}) async {
  for (var index = 0; index < maxTicks; index++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Timed out waiting for the Selbrume Event V2 runtime dispatch.');
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.beforeNarrativeAuthorityPreparation,
    super.afterNarrativeAuthorityPreparation,
  });

  @override
  bool get isLoaded => true;
}

final class _EntityTarget {
  const _EntityTarget({
    required this.label,
    required this.mapId,
    required this.entityId,
    required this.eventId,
    required this.sceneId,
    required this.playerPos,
    required this.facing,
    required this.completesImmediately,
  });

  final String label;
  final String mapId;
  final String entityId;
  final String eventId;
  final String sceneId;
  final GridPos playerPos;
  final EntityFacing facing;
  final bool completesImmediately;
}
~~~~

### B.12 `examples/playable_runtime_host/test/selbrume_event_v2_lysa_golden_slice_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

const _portMapId = 'map_port_brisants';
const _marshMapId = 'map_marais_salants';
const _lysaEntityId = 'npc_lysa';
const _lysaEventId = 'evt_019abcde-4000-7000-8000-000000000001';
const _lysaSceneId = 'scene_lysa_port';
const _lysaDialogueId = 'dialogue_lysa_port';
const _lysaCinematicId = 'cinematic_lysa_port';
const _lysaTrainerId = 'trainer_lysa_port';
const _lysaFactId = 'fact_lysa_port_resolved';
const _lysaStepId = 'step_rival_battle';
const _lysaWorldRuleId = 'world_rule_lysa_port_resolved';
const _victoryOutcomeId = 'lysa.victory';
const _defeatOutcomeId = 'lysa.defeat';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('J4 Selbrume Lysa Golden Slice', () {
    for (final promoted in const <bool>[false, true]) {
      for (final battleOutcome in const <String>['victory', 'defeat']) {
        test(
          '${promoted ? 'promoted Selbrume' : 'versioned fixture'} $battleOutcome '
          'crosses Yarn, Cinematic, Battle, outcome and save/load',
          () async {
            final fixture = await _loadFixture(promoted: promoted);
            final dialogueText = await File(
              p.join(fixture.root.path, 'dialogues', 'lysa_port.yarn'),
            ).readAsString();
            expect(dialogueText, contains('title: LysaPort'));
            expect(dialogueText, contains('Port des Brisants'));

            var state = GameState(
              saveId: 'phase_j_lysa_$battleOutcome',
              currentMapId: _portMapId,
              playerPosition: const GridPos(x: 26, y: 17),
            );
            final transactions = NarrativeEventStateTransactions(state);
            final source = NarrativeEventSourceRef.entityInteract(
              _portMapId,
              _lysaEntityId,
            );
            final occurrence = NarrativeEventOccurrence(source: source);
            var dialogueCalls = 0;
            var cinematicCalls = 0;
            var battleCalls = 0;
            var legacyCalls = 0;
            var sequence = 0;
            final bridge = NarrativeSpatialProductionDispatchBridge(
              stateTransactions: transactions,
              currentGameState: () => state,
              onGameStateCommitted: (next) => state = next,
              prepareAuthority: (_, currentOccurrence) async {
                return NarrativeEventDispatchAuthority.prepare(
                  registryResult: fixture.snapshot.registryResult,
                  occurrence: currentOccurrence,
                  factResolver: fixture.snapshot.factResolver,
                  legacyClaimIndex: fixture.snapshot.legacyClaimIndex,
                  projectCatalog: fixture.snapshot.projectCatalog,
                );
              },
              executeScene: (request) async {
                final hostedBattleOutcomes = <NarrativeOutcomeRef>[];
                return executeNarrativeEventScene(
                  request: request,
                  project: fixture.snapshot.project,
                  mapsById: fixture.snapshot.mapsById,
                  currentGameState: () => state,
                  hostedBattleOutcomes: hostedBattleOutcomes,
                  callbacks: SceneRuntimeHostCallbacks(
                    evaluateCondition: (_) =>
                        throw StateError('No condition is expected.'),
                    showDialogue: (intent) {
                      dialogueCalls++;
                      expect(intent.dialogueId, _lysaDialogueId);
                      expect(intent.yarnNodeName, 'LysaPort');
                      return 'completed';
                    },
                    playCinematic: (intent) {
                      cinematicCalls++;
                      expect(intent.cinematicId, _lysaCinematicId);
                      return 'completed';
                    },
                    startBattle: (intent) {
                      battleCalls++;
                      expect(intent.battleKind, 'trainer');
                      expect(intent.trainerId, _lysaTrainerId);
                      hostedBattleOutcomes.add(
                        NarrativeOutcomeRef(
                          producerKind: NarrativeOutcomeProducerKind.battle,
                          producerId: 'trainer:$_lysaTrainerId',
                          outcomeId: battleOutcome,
                        ),
                      );
                      return battleOutcome;
                    },
                  ),
                );
              },
              legacyFallback: (_, __, ___) async => legacyCalls++,
              activityPort: NoopNarrativeEventActivityPort(),
              isCurrentOccurrence: (_) => true,
              executionIdFactory: () => _runtimeId('evx', ++sequence),
              correlationIdFactory: () => _runtimeId('corr', ++sequence),
              deliveryIdFactory: () => _runtimeId('outd', ++sequence),
            );

            final first = await bridge.dispatch(
              occurrenceId: 'phase-j-lysa-$battleOutcome-1',
              occurrence: occurrence,
            );
            expect(
              first,
              isA<NarrativeSpatialProductionDispatchV2Handled>(),
              reason: first is NarrativeSpatialProductionDispatchFailed
                  ? first.failure.toString()
                  : null,
            );
            expect(
              (first as NarrativeSpatialProductionDispatchV2Handled)
                  .execution
                  .eventId,
              _lysaEventId,
            );
            expect(dialogueCalls, 1);
            expect(cinematicCalls, 1);
            expect(battleCalls, 1);
            expect(legacyCalls, 0);
            expect(
              state.narrativeEventProgress.consumedNarrativeEventIds,
              contains(_lysaEventId),
            );

            final pendingOutcomes = state
                .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
                .map((delivery) => delivery.outcome)
                .toSet();
            expect(
              pendingOutcomes,
              contains(
                NarrativeOutcomeRef(
                  producerKind: NarrativeOutcomeProducerKind.battle,
                  producerId: 'trainer:$_lysaTrainerId',
                  outcomeId: battleOutcome,
                ),
              ),
            );
            expect(
              pendingOutcomes,
              contains(
                NarrativeOutcomeRef(
                  producerKind: NarrativeOutcomeProducerKind.scene,
                  producerId: _lysaSceneId,
                  outcomeId: battleOutcome == 'victory'
                      ? _victoryOutcomeId
                      : _defeatOutcomeId,
                ),
              ),
            );

            final factValue =
                state.narrativeFactRuntimeState.overridesByFactId[_lysaFactId];
            final projection = const RuntimeWorldRuleProjectionHook().resolve(
              project: fixture.snapshot.project,
              gameState: state,
              map: fixture.portBundle.map,
            );
            if (battleOutcome == 'victory') {
              expect(factValue, isTrue);
              expect(state.progression.completedStepIds, contains(_lysaStepId));
              expect(projection.hiddenEntityIds, contains(_lysaEntityId));
              expect(
                fixture.snapshot.project.worldRules.map((rule) => rule.id),
                contains(_lysaWorldRuleId),
              );
            } else {
              expect(factValue, isNot(true));
              expect(
                state.progression.completedStepIds,
                isNot(contains(_lysaStepId)),
              );
              expect(
                projection.hiddenEntityIds,
                isNot(contains(_lysaEntityId)),
              );
            }

            final callsBeforeReinteraction =
                dialogueCalls + cinematicCalls + battleCalls;
            final second = await bridge.dispatch(
              occurrenceId: 'phase-j-lysa-$battleOutcome-2',
              occurrence: occurrence,
            );
            expect(
              second,
              isA<NarrativeSpatialProductionDispatchLegacyFallback>(),
              reason: 'dualRead keeps the unrelated historical fallback path.',
            );
            expect(
              dialogueCalls + cinematicCalls + battleCalls,
              callsBeforeReinteraction,
              reason: 'The one-shot Event must not replay its Scene.',
            );
            expect(legacyCalls, 1);

            final encodedSave = jsonDecode(
              jsonEncode(saveDataFromGameState(state).toJson()),
            ) as Map<String, dynamic>;
            final reloaded = gameStateFromSaveData(
              SaveData.fromJson(encodedSave),
            );
            expect(
              reloaded.narrativeEventProgress.consumedNarrativeEventIds,
              contains(_lysaEventId),
            );
            expect(
              reloaded.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
              state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
            );
            expect(
              reloaded.narrativeFactRuntimeState.overridesByFactId[_lysaFactId],
              factValue,
            );
            expect(
              reloaded.progression.completedStepIds,
              state.progression.completedStepIds,
            );
          },
        );
      }
    }
  });
}

String _runtimeId(String prefix, int sequence) {
  final suffix = sequence.toString().padLeft(12, '0');
  return '${prefix}_019abcde-5000-7000-8000-$suffix';
}

Future<_GoldenFixture> _loadFixture({required bool promoted}) async {
  final root = promoted
      ? Directory(p.join(Directory.current.path, '..', '..', 'selbrume'))
      : Directory(
          p.join(
            Directory.current.path,
            'event_builder_v2_selbrume_slice',
          ),
        );
  final projectPath = p.join(root.path, 'project.json');
  final bundles = <String, RuntimeMapBundle>{};
  Future<RuntimeMapBundle> load(String mapId) async {
    return bundles[mapId] ??= await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: mapId,
    );
  }

  final portBundle = await load(_portMapId);
  await load(_marshMapId);
  final snapshot = await NarrativeEventRuntimeSnapshot.build(
    project: portBundle.manifest,
    loadMap: (mapId) async {
      final bundle = await load(mapId);
      return (project: bundle.manifest, map: bundle.map);
    },
  );
  return _GoldenFixture(
    root: root,
    portBundle: portBundle,
    snapshot: snapshot,
  );
}

final class _GoldenFixture {
  const _GoldenFixture({
    required this.root,
    required this.portBundle,
    required this.snapshot,
  });

  final Directory root;
  final RuntimeMapBundle portBundle;
  final NarrativeEventRuntimeSnapshot snapshot;
}
~~~~

### B.13 `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

const _portMapId = 'map_port_brisants';
const _marshMapId = 'map_marais_salants';
const _lysaEntityId = 'npc_lysa';
const _clueEntityId = 'clue_glass_object';
const _portTriggerId = 'zone_port_entry';
const _lysaEventId = 'evt_019abcde-4000-7000-8000-000000000001';
const _lysaFactId = 'fact_lysa_port_resolved';
const _lysaStepId = 'step_rival_battle';
const _lysaTrainerId = 'trainer_lysa_port';
const _lysaWorldRuleId = 'world_rule_lysa_port_resolved';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('J5 promoted Selbrume bytes load and play the Lysa Golden Slice',
      () async {
    final repositoryRoot = _findRepositoryRoot();
    final selbrumeRoot = Directory(p.join(repositoryRoot.path, 'selbrume'));
    final fixtureRoot = Directory(
      p.join(
        repositoryRoot.path,
        'examples',
        'playable_runtime_host',
        'event_builder_v2_selbrume_slice',
      ),
    );
    final promotion = _jsonObject(
      jsonDecode(
        await File(p.join(fixtureRoot.path, 'promotion_manifest.json'))
            .readAsString(),
      ),
    );
    final orderedFiles = _jsonObjects(promotion['orderedFiles']);
    expect(promotion['state'], 'frozenForJ5');
    expect(orderedFiles, hasLength(4));
    for (final entry in orderedFiles) {
      final promoted = File(
        p.join(repositoryRoot.path, entry['destination']! as String),
      );
      expect(await promoted.exists(), isTrue, reason: promoted.path);
      expect(
        narrativeEventBytesFingerprint(await promoted.readAsBytes()),
        entry['afterSha256'],
        reason: 'J5 must run on the promoted bytes, not fixture bytes.',
      );
    }

    final projectPath = p.join(selbrumeRoot.path, 'project.json');
    final bundles = <String, RuntimeMapBundle>{};
    Future<RuntimeMapBundle> load(String mapId) async {
      return bundles[mapId] ??= await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: mapId,
      );
    }

    final portBundle = await load(_portMapId);
    final marshBundle = await load(_marshMapId);
    final project = portBundle.manifest;
    expect(project.maps, hasLength(10));
    expect(project.scenarios.map((entry) => entry.id),
        contains('p6_03_first_interaction'));
    expect(portBundle.map.connections, hasLength(1));
    expect(marshBundle.map.connections, hasLength(2));
    expect(
      portBundle.map.entities.map((entry) => entry.id),
      contains(_lysaEntityId),
    );
    expect(
      marshBundle.map.entities.map((entry) => entry.id),
      contains(_clueEntityId),
    );
    expect(
      portBundle.map.triggers.map((entry) => entry.id),
      contains(_portTriggerId),
    );
    expect(project.eventRegistry?.mode, EventSystemMode.dualRead);
    expect(project.eventRegistry?.records, hasLength(3));
    expect(
      project.worldRules.map((entry) => entry.id),
      contains(_lysaWorldRuleId),
    );
    expect(
      await File(p.join(selbrumeRoot.path, 'dialogues', 'lysa_port.yarn'))
          .readAsString(),
      allOf(contains('title: LysaPort'), contains('Port des Brisants')),
    );

    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: project,
      loadMap: (mapId) async {
        final bundle = await load(mapId);
        return (project: bundle.manifest, map: bundle.map);
      },
    );
    var state = const GameState(
      saveId: 'phase_j_promoted_lysa',
      currentMapId: _portMapId,
      playerPosition: GridPos(x: 26, y: 17),
    );
    final transactions = NarrativeEventStateTransactions(state);
    final source = NarrativeEventSourceRef.entityInteract(
      _portMapId,
      _lysaEntityId,
    );
    var dialogueCalls = 0;
    var cinematicCalls = 0;
    var battleCalls = 0;
    var sequence = 0;
    final bridge = NarrativeSpatialProductionDispatchBridge(
      stateTransactions: transactions,
      currentGameState: () => state,
      onGameStateCommitted: (next) => state = next,
      prepareAuthority: (_, occurrence) async {
        return NarrativeEventDispatchAuthority.prepare(
          registryResult: snapshot.registryResult,
          occurrence: occurrence,
          factResolver: snapshot.factResolver,
          legacyClaimIndex: snapshot.legacyClaimIndex,
          projectCatalog: snapshot.projectCatalog,
        );
      },
      executeScene: (request) async {
        final battleOutcomes = <NarrativeOutcomeRef>[];
        return executeNarrativeEventScene(
          request: request,
          project: snapshot.project,
          mapsById: snapshot.mapsById,
          currentGameState: () => state,
          hostedBattleOutcomes: battleOutcomes,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) =>
                throw StateError('No condition is expected.'),
            showDialogue: (intent) {
              dialogueCalls++;
              expect(intent.dialogueId, 'dialogue_lysa_port');
              expect(intent.yarnNodeName, 'LysaPort');
              return 'completed';
            },
            playCinematic: (intent) {
              cinematicCalls++;
              expect(intent.cinematicId, 'cinematic_lysa_port');
              return 'completed';
            },
            startBattle: (intent) {
              battleCalls++;
              expect(intent.trainerId, _lysaTrainerId);
              battleOutcomes.add(
                NarrativeOutcomeRef(
                  producerKind: NarrativeOutcomeProducerKind.battle,
                  producerId: 'trainer:trainer_lysa_port',
                  outcomeId: 'victory',
                ),
              );
              return 'victory';
            },
          ),
        );
      },
      legacyFallback: (_, __, ___) async {},
      activityPort: NoopNarrativeEventActivityPort(),
      isCurrentOccurrence: (_) => true,
      executionIdFactory: () => _runtimeId('evx', ++sequence),
      correlationIdFactory: () => _runtimeId('corr', ++sequence),
      deliveryIdFactory: () => _runtimeId('outd', ++sequence),
    );

    final dispatched = await bridge.dispatch(
      occurrenceId: 'phase-j-promoted-lysa',
      occurrence: NarrativeEventOccurrence(source: source),
    );
    expect(dispatched, isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(
      (dispatched as NarrativeSpatialProductionDispatchV2Handled)
          .execution
          .eventId,
      _lysaEventId,
    );
    expect((dialogueCalls, cinematicCalls, battleCalls), (1, 1, 1));
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_lysaEventId),
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId[_lysaFactId],
      isTrue,
    );
    expect(state.progression.completedStepIds, contains(_lysaStepId));
    expect(
      const RuntimeWorldRuleProjectionHook()
          .resolve(
            project: project,
            gameState: state,
            map: portBundle.map,
          )
          .hiddenEntityIds,
      contains(_lysaEntityId),
    );

    final reloaded = gameStateFromSaveData(
      SaveData.fromJson(
        jsonDecode(jsonEncode(saveDataFromGameState(state).toJson()))
            as Map<String, dynamic>,
      ),
    );
    expect(
      reloaded.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_lysaEventId),
    );
    expect(
      reloaded.narrativeFactRuntimeState.overridesByFactId[_lysaFactId],
      isTrue,
    );
    expect(reloaded.progression.completedStepIds, contains(_lysaStepId));
  });
}

String _runtimeId(String prefix, int sequence) {
  final suffix = sequence.toString().padLeft(12, '0');
  return '${prefix}_019abcde-6000-7000-8000-$suffix';
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = parent;
  }
}

Map<String, Object?> _jsonObject(Object? value) =>
    (value! as Map).cast<String, Object?>();

List<Map<String, Object?>> _jsonObjects(Object? value) => (value! as List)
    .map((entry) => (entry! as Map).cast<String, Object?>())
    .toList(growable: false);
~~~~
