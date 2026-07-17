# Event Builder V2 — Phase 3 Validator & Migration Evidence Pack

Date de clôture technique : 2026-07-17
Lot exact : **Phase 3 — Validation et migration, sous-lots I1 à I5**
Plan d’exécution : `docs/superpowers/plans/2026-07-16-event-builder-phase-i-validator-migration.md`
Roadmap de référence : `MVP Selbrume/road_map_event_builder_v2_execution.md`
Lot mécanique associé : `FG-180 — Project Gameplay Readiness Report V0` (`TODO`, non fermé par ce lot)

## 1. Résumé exécutif

La Phase 3 livre les cinq capacités prévues :

1. un rapport d’intégrité Event V2 typé, stable et déterministe dans `map_core` ;
2. un rapport d’atteignabilité qui compose l’index de sources et l’autorité de dispatch ;
3. des diagnostics cliquables et revalidés au clic vers Event, Map, Scene ou migration ;
4. une prévisualisation V1→V2 sans écriture, puis une persistance journalée, récupérable et compensable en mode fail-closed ;
5. une validation incrémentale réellement branchée à la route produit, mesurée sur 500 Events.

Les preuves ciblées finales sont vertes : `map_core` 5/5 et analyse propre,
gate editor 24/24, régressions Phase 2 224/224, navigation/design system
28/28, analyse ciblée 23 éléments propre et build macOS debug réussi. Le p95
final est de **16 099 µs** pour un budget figé de **36 000 µs**.

La commande `flutter analyze --no-pub` globale reste rouge avec exactement
**451 constats préexistants** dans le package. Aucun ne vise les 23 éléments
Phase 3 analysés séparément. En conséquence, les lots I1–I5 sont proposés
`DONE` techniquement, mais la Phase 3 ne doit pas être marquée `DONE` dans la
roadmap sans acceptation explicite de cette baseline globale. La roadmap n’a
pas été modifiée dans ce lot.

## 2. Confirmation du scope

### Inclus

- contrats publics de validation et d’atteignabilité dans `map_core` ;
- coordinator, cache, navigation et affichage no-code dans `map_editor` ;
- migration preview/commit/recovery/compensation ;
- interlock avec le recovery gate canonique du registre ;
- tests négatifs de corruption et de destination obsolète ;
- protocole et budget de performance I5 ;
- Evidence Pack présent.

### Exclus et préservé

- aucune activation automatique du mode runtime V2 ;
- aucune promotion de données dans le projet Selbrume ;
- aucun changement des hooks runtime ou gameplay ;
- aucun nettoyage des changements préexistants du checkout ;
- aucune écriture Git, branche, worktree, commit ou push ;
- aucune mise à jour de statut de la roadmap, non demandée par l’utilisateur.

## 3. Audit initial et droit de remise en cause

L’audit initial a identifié :

- `buildNarrativeEventProjectCatalog` comme source existante des diagnostics de projet ;
- `NarrativeEventSourceIndex` comme vérité d’ordre et de conflits ;
- `NarrativeEventDispatchAuthority` comme vérité d’éligibilité runtime ;
- le planner et les receipts de migration déjà disponibles dans `map_core` ;
- `NarrativeEventRegistryPersistence` comme autorité de journal/recovery Event ;
- `ScenesWorkspace` avec une sélection locale nécessitant un focus typé partagé ;
- `PokeMapDiagnosticCallout` et les side sheets comme primitives design system.

La consigne du plan demandant littéralement de composer
`FileProjectRepository.saveProject` a été remise en cause après inspection :
cette méthode préserve volontairement le registre courant et refuse donc la
transition de registre nécessaire à une migration. L’alternative minimale
retenue est un gateway migration spécialisé qui :

- partage le verrou canonique de `project.json` ;
- consulte sous ce verrou le recovery gate de `NarrativeEventRegistryPersistence` ;
- contrôle la révision attendue ;
- préserve les clés root inconnues ;
- écrit backup, receipt et journal atomiquement fichier par fichier ;
- ne revendique aucune atomicité multi-fichier ;
- compense uniquement lorsque toutes les preuves concordent.

Cette déviation est intentionnelle et plus petite qu’une extension transverse
du repository de projet. Elle reste une dette architecturale documentée : une
future primitive commune d’écriture de manifest éviterait deux implémentations
de renommage atomique.

Risques initiaux principaux : collision des clés de diagnostic, navigation sur
snapshot stale, cache benchmark-only, migration inaccessible en `legacyOnly`,
recovery destructif, CTA trompeur et artefacts de golden accidentels. Tous ont
été corrigés ou explicitement bornés dans les limites finales.

## 4. État Git initial

État observé au début de Phase 3 :

- HEAD : `2f68328a38bf218c843e497940f8dd24a7a9c194` ;
- branche : `main` ;
- 42 fichiers suivis modifiés ;
- 107 fichiers non suivis ;
- 149 entrées sales au total.

Ces changements appartenaient aux phases précédentes et à d’autres chantiers.
Ils ont été préservés. Les 36 images de diff générées par un run golden
historique pendant Phase 3 ont été supprimées ; les 4 images antérieures du
16 juillet ont été conservées.

## 5. Inventaire complet des fichiers Phase 3

| Fichier | Zones modifiées/créées | Raison et impact |
|---|---|---|
| `docs/superpowers/plans/2026-07-16-event-builder-phase-i-validator-migration.md` | plan I1–I5 et gates | Fige scope, architecture, protocole et budget avant validation. |
| `packages/map_core/lib/map_core.dart` | exports validation/reachability | Rend les contrats I1/I2 publics. |
| `packages/map_core/lib/src/operations/narrative_event_registry_codec.dart` | `ValidatedLegacyClaimIndex.inspectSourceStructure` | Vérifie la structure des claims sans fabriquer de preuve runtime. |
| `packages/map_core/lib/src/read_models/narrative_event_validation_read_model.dart` | diagnostics, destinations, stable keys | Contrat typé et déterministe I1. |
| `packages/map_core/lib/src/operations/build_narrative_event_validation_report.dart` | full/subset/normalisation | Compose le catalogue et produit les réparations Event/Source/Scene/Claim. |
| `packages/map_core/lib/src/read_models/narrative_event_reachability_report.dart` | runtime snapshot et report | Contrat public I2. |
| `packages/map_core/lib/src/operations/build_narrative_event_reachability_report.dart` | ordre, conflits, runtime connu/inconnu | Compose index et dispatch authority sans second moteur. |
| `packages/map_core/test/narrative_event_v2_integrity_validation_test.dart` | déterminisme, destinations, non-collision | Preuves I1 positives/négatives. |
| `packages/map_core/test/narrative_event_reachability_report_test.dart` | ordre, conflits, claims, runtime | Preuves I2 et permutation d’entrée. |
| `packages/map_editor/lib/src/app/providers/core/repository_providers.dart` | provider gateway migration | Composition production I4. |
| `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart` | loader validation et cache scoped projet | Branche I5 dans la route produit. |
| `packages/map_editor/lib/src/features/narrative/state/narrative_event_validation_state.dart` | snapshot/items UI | Projection sans recalcul des règles core. |
| `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart` | cache incrémental et commandes navigation | I3/I5, invalidations et résolution stale. |
| `packages/map_editor/lib/src/features/narrative/state/narrative_scene_focus_provider.dart` | requête `{sceneId, nonce}` | Focus Scene exact sans écraser une sélection valide. |
| `packages/map_editor/lib/src/application/models/narrative_event_migration_persistence_models.dart` | preview/status/journal/checkpoints | Contrats applicatifs I4. |
| `packages/map_editor/lib/src/application/ports/narrative_event_migration_persistence_gateway.dart` | port inspect/commit/recover/compensate | Frontière testable I4. |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart` | session, projections, planner, receipt | Preview byte-identique et mode inchangé. |
| `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart` | lock, gate, journal, recovery, compensation | Persistance fail-closed et vérifications anti-tamper. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_migration_sheet.dart` | preview/commit/recovery no-code | UX I4 sans JSON brut. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | fail-closed, globals, clics, legacy migration, adoption | Intégration produit I3/I4 et compatibilité V1. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart` | diagnostics/callbacks inspecteur | Transporte l’état sans valider dans le widget. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | section validation et actions | Diagnostics no-code, clés uniques. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | enveloppe route V2 + child V1 | Rend la migration accessible en `legacyOnly`. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | `requestedSceneId` | Applique un focus valide, ignore un ID supprimé. |
| `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart` | snapshot validation déterministe | I/O seam stable pour les tests widget. |
| `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart` | fail-closed, clic frais, compatibilité V1 | Prouve le vrai picker Source depuis un diagnostic. |
| `packages/map_editor/test/narrative_event_validation_coordinator_test.dart` | Event/Map/Scene/Claim/stale/cache | Tests I3. |
| `packages/map_editor/test/ui/canvas/event_builder_v2_validation_navigation_test.dart` | focus Scene valide et stale | Non-régression navigation I3. |
| `packages/map_editor/test/narrative_event_migration_preview_use_case_test.dart` | preview, commit, crash, tamper, recovery | Matrice disque I4. |
| `packages/map_editor/test/ui/canvas/event_builder_v2_migration_sheet_test.dart` | cancel, commit, recovery bloquée | Matrice UI I4. |
| `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart` | équivalence et budget | Corpus/protocole I5. |
| `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart` | sortie environnement/perf | Contexte reproductible des mesures. |
| `reports/narrativeStudio/events/ns_event_v2_phase_3_validator_migration_evidence_pack.md` | présent document + annexes | Preuve de clôture technique. |

## 6. Diffs et zones précises

### map_core

- `map_core.dart` : quatre exports ajoutés pour les read models et opérations I1/I2.
- `narrative_event_registry_codec.dart` : ajout d’une inspection structurelle de claim qui ne transforme pas une structure valide en preuve runtime.
- `build_narrative_event_validation_report.dart` : traduction des diagnostics catalogue, diagnostic global de registre, claims structurels, subset incrémental et tri canonique.
- `narrative_event_validation_read_model.dart` : `eventScene` distingue une réparation de Scene absente d’une Scene ouvrable ; `stableKey` inclut action et message.
- `build_narrative_event_reachability_report.dart` : diagnostics par Event conflictuel, destinations `mapSource` réelles pour les sources spatiales, runtime inconnu en warning.

### map_editor — validation et navigation

- le provider conserve le dernier cache par projet et invalide sur changement de racine ;
- suppression/ajout de record force un full fallback ; Fact, Scene, source, mode et diagnostics globaux ont des fingerprints explicites ;
- la route ferme l’éditeur si la validation charge ou échoue ;
- un clic recharge un snapshot attesté avant résolution ;
- Source/Scene ouvrent leurs vrais pickers, Map réutilise le bridge, Claim/Registry ouvrent la migration ;
- les diagnostics globaux sont visibles et actionnables ;
- un projet V1 non enregistré conserve son workspace historique, tandis qu’un projet enregistré expose le CTA de migration.

### map_editor — migration

- commit refuse une révision devenue stale ;
- le gate registry canonique est inspecté sous le même verrou ;
- recovery vérifie ownership, receipt, backup, `beforeRevision`, fingerprints sémantiques et `receiptId` sûr ;
- compensation conserve le projet et le journal au moindre écart ;
- une altération coordonnée backup + `backupHash` reste bloquée grâce au recroisement avec `beforeRevision` ;
- après recovery finalisé, la route recharge le manifest disque et adopte le registre par CAS.

## 7. Tests créés ou renforcés

### I1/I2

- diagnostics source/Scene/claim/registre ;
- Event valide sans diagnostic ;
- messages distincts non fusionnés ;
- priorité descendante, ordre ascendant et tie-break ID ;
- conflit pour chaque Event ;
- one-shot consommé, disabled, claim, référence absente et runtime inconnu ;
- permutation d’entrée strictement déterministe.

### I3

- regroupement sans recalcul UI ;
- commandes Event, Map, Scene, Claim et destination stale ;
- cache du loader produit réutilisé ;
- focus Scene exact et ID supprimé ignoré ;
- clic produit : deuxième chargement de validation puis ouverture du vrai picker Source ;
- échec du validator présenté fail-closed.

### I4

- preview et cancel byte-identiques ;
- commit/reload et compensation exacte ;
- stale revision avant commit ;
- crash après journal préparé et après renommage du projet ;
- recovery rollback et finalisation ;
- receipt préparé altéré ;
- receipt, backup, ownership et fingerprint divergents ;
- altération coordonnée backup + hash journal ;
- `receiptId` de traversal dans le journal ;
- interlock avec un journal registry à récupérer ;
- états UI commit réussi et recovery bloquée.

### I5

- équivalence stricte incremental/full ;
- mutation Event + dépendants exacts ;
- suppression source, Scene et Fact ;
- changement mode/global ;
- suppression de record et full fallback des 499 restants ;
- protocole 500/100/50/100, 10 warmups, 50 mesures.

## 8. Performance I5

Environnement final imprimé par le test :

```text
os=macos
os_version=Version_27.0_(Build_26A5378j)
dart=3.13.0-167.1.beta
processors=10
host=Yoahns-MBP.localdomain
mode=jit
execution=sequential
```

Corpus : 500 records, 100 sources, 50 Scenes, 100 facts.
Protocole : 10 warmups puis 50 itérations séquentielles.
Baseline initiale sans gate : p50 `14 016 µs`, p95 `17 900 µs`.
Politique figée avant le run final : `max(25 ms, ceil(2 × 17,9 ms)) = 36 ms`.
Budget source : Event muté + dépendants exacts, soit 3 Events.
Run final : p50 `14 601 µs`, p95 `16 099 µs`, recalcul `3`, budget `36 000 µs`, **PASS**.

Le budget n’a pas été modifié après observation des runs finaux.

## 9. Commandes et résultats exacts

### Gate map_core

```bash
cd packages/map_core
dart test test/narrative_event_v2_integrity_validation_test.dart test/narrative_event_reachability_report_test.dart
dart analyze
```

Résultat : `+5 All tests passed!` puis `No issues found!`.

### Gate map_editor exact

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact \
  test/narrative_event_validation_coordinator_test.dart \
  test/narrative_event_migration_preview_use_case_test.dart \
  test/ui/canvas/event_builder_v2_migration_sheet_test.dart \
  test/narrative_event_validation_incremental_performance_test.dart \
  test/narrative_event_authoring_snapshot_performance_test.dart
```

Résultat final : `+24 All tests passed!`; p95 I5 `16 099 µs / 36 000 µs`.

### Analyse ciblée Phase 3

```bash
flutter analyze --no-pub [23 éléments Phase 3]
```

Résultat : `Analyzing 23 items... No issues found! (ran in 4.5s)`.

### Régressions Phase 2

```bash
flutter test --no-pub --reporter=compact \
  test/narrative_event_builder_v2_use_case_test.dart \
  test/narrative_event_builder_v2_state_test.dart \
  test/narrative_event_builder_v2_session_snapshot_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/event_builder_v2_project_list_test.dart \
  test/ui/canvas/event_builder_v2_creation_flow_test.dart \
  test/ui/canvas/event_builder_v2_workspace_test.dart \
  test/ui/canvas/event_builder_v2_accessibility_test.dart \
  test/ui/canvas/event_builder_v2_flow_fidelity_test.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_map_focus_return_flow_test.dart
```

Premier run : échec en cascade de 60 tests V1 car la route exigeait un chemin
disque avant d’afficher le child legacy. Test suspect isolé puis correctif : le
workspace V1 reste disponible sans chemin, seule la migration exige un projet
enregistré. Run final : `+224 All tests passed!`.

### Navigation et design system

```bash
flutter test --no-pub --reporter=compact \
  test/ui/canvas/event_builder_v2_validation_navigation_test.dart \
  test/event_map_navigation_controller_test.dart \
  test/map_canvas_narrative_event_focus_test.dart \
  test/ui/design_system/pokemap_diagnostic_callout_test.dart
```

Résultat : `+28 All tests passed!`.

### Analyse globale

```bash
flutter analyze --no-pub
```

Résultat : exit 1, `451 issues found. (ran in 6.0s)`. Le passif comprend
notamment une désynchronisation du convertisseur Pokémon SDK avec les contrats
`PokemonMove*`, ainsi que des lints `const` dans des tests étrangers au lot.
Les 23 éléments Phase 3 sont propres dans l’analyse ciblée ci-dessus.

### Build

```bash
flutter build macos --no-pub
flutter build macos --debug --no-pub
```

Le build release échoue avant compilation applicative dans Flutter 3.38.4 :
`lipo -archs` confirme `x86_64 arm64`, mais la commande utilisée par Flutter,
`lipo <binary> -verify_arch arm64 x86_64`, retourne
`-verify_arch requires exactly one input file` sous macOS 27.0. Deux runs ont
reproduit l'incompatibilité d'outillage. Le build debug mono-architecture
réussit ensuite : `✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## 10. Verdict des passes obligatoires

| Passe | Verdict final | Synthèse |
|---|---|---|
| Audit / Architecture | PASS après correction | Cache produit, stable keys, legacy route, gate registry et anti-tamper recontrôlés. L’altération coordonnée backup/hash et le traversal `receiptId` ont été trouvés puis fermés. |
| Implémentation | PASS fonctionnel / réserves documentées | Vraies destinations Map, réparation Scene, snapshot frais, globals, claim/registry, recovery UI et cache produit confirmés. |
| Tests | PASS | Matrice corrective I1–I5 et gates ciblés verts ; absence de test widget distinct pour chaque variante Map/Scene/stale considérée résiduelle non bloquante car coordinator/navigation sont testés séparément. |
| Build / Validation | PASS ciblé, FAIL release environnement et global baseline | 24 tests, analyse ciblée et build debug verts ; release bloquée par Flutter/lipo, analyse globale à 451. |
| Critique finale | PASS avec risques | Aucun contrôle mort I5, aucune couleur ad hoc, aucun write Git, artefacts golden du lot retirés. Limites corpus et autorité manifest documentées. |

Verdicts indépendants finaux, tous rendus en lecture seule :

- passe Architecture / anti-tamper (`phase2_h3_audit`) : **PASS technique I1–I5, aucun blocker dans le périmètre** ; elle a relancé la matrice I4 à `14/14` ;
- passe conformité plan / couverture (`phase2_h4_audit`) : **PASS I1–I5**, avec I4 limité au corpus caractérisé et Phase 3 formellement bloquée par la baseline globale non acceptée ;
- passe Evidence Pack (`phase2_h5_audit`) : **READY** après contrôle de l'état Git final et suppression du marqueur de génération.

## 11. Statut proposé

| Lot | Proposition | Justification |
|---|---|---|
| I1 | `DONE` technique | Rapport stable, destinations typées et non-collision prouvés. |
| I2 | `DONE` technique | Ordre/conflits/runtime/claims déterministes et composés. |
| I3 | `DONE` technique | Clic frais et destinations de correction réellement consommées. |
| I4 | `DONE` pour le corpus caractérisé | Preview/commit/recovery/compensation et anti-tamper prouvés. |
| I5 | `DONE` technique | Cache produit cohérent et budget figé respecté. |
| Phase 3 | `CANDIDATE DONE` | Clôture formelle conditionnée à l’acceptation de la baseline analyze globale. |
| FG-180 | `TODO` | Le readiness gameplay global dépasse cette phase Event Builder. |

## 12. Limites et risques restants

1. Le preview I4 caractérise manifest, maps et scénarios chargés. Le catalogue de références, les snapshots de sauvegarde et les données legacy inconnues restent vides faute de producteur canonique editor ; étendre ce corpus exige un lot explicite et ne doit pas être inventé ici.
2. Le gateway migration partage verrou et recovery gate, mais conserve sa propre primitive `_writeAtomic`; une abstraction manifest commune réduirait cette duplication.
3. Les fingerprints Event sont reconstruits à chaque passe avant de limiter les validations core ; le résultat est incrémental, une part de scan reste globale.
4. L’analyse globale du package n’est pas propre : 451 constats hors scope.
5. Le build release macOS est bloqué par l'incompatibilité Flutter 3.38.4 / `lipo` de macOS 27.0 ; le build debug est vert et `lipo -archs` prouve que le framework universel contient bien les deux architectures demandées.
6. Les quatre images de failure Scene du 16 juillet restent présentes car antérieures à ce lot.

## 13. Auto-critique finale

- Le premier raccord `legacyOnly` a cassé les fixtures V1 sans chemin disque ; la régression large a détecté l’erreur et le run final 224/224 confirme la correction.
- Le premier recovery vérifiait `backupHash` mais pas son égalité avec `beforeRevision`; la passe Architecture a trouvé le contournement coordonné et un test dédié le ferme.
- Le premier click-through sélectionnait l’Event sans consommer `command.section`; Source et Scene ouvrent désormais les vrais pickers.
- Le protocole I5 mesure le travail total du coordinator, mais le compteur de recalcul ne reflète pas le coût de construction des fingerprints. Cette nuance est explicitement conservée.
- La migration n’atteste pas encore un inventaire générique de toutes les sauvegardes/références externes. Le rapport ne prétend donc pas une migration universelle hors corpus caractérisé.

## 14. Prochaines étapes proposées, non implémentées

1. faire accepter la baseline globale ou ouvrir un lot dédié de remise à zéro de `flutter analyze` ;
2. ajouter un producteur canonique de catalogue références/saves/unknown legacy pour élargir I4 ;
3. extraire une primitive commune de mutation CAS du manifest ;
4. poursuivre la roadmap avec J1 seulement après décision formelle sur Phase 3 ;
5. conserver FG-180 `TODO` jusqu’au readiness gameplay complet.

## 15. État Git final

Commandes de contrôle :

```bash
git rev-parse HEAD
git branch --show-current
git status --short --untracked-files=all
git diff --name-only
git diff --cached --name-only
git diff --stat
```

État final exact :

- HEAD : `2f68328a38bf218c843e497940f8dd24a7a9c194` ;
- branche : `main` ;
- 45 fichiers suivis modifiés, tous non indexés ;
- 127 fichiers non suivis ;
- 172 entrées sales au total ;
- 0 fichier indexé et 0 diff cached ;
- diff suivi global : `45 files changed, 5935 insertions(+), 604 deletions(-)`.

L'écart brut avec l'état initial est de +3 fichiers suivis modifiés et +20
fichiers non suivis. Plusieurs fichiers Phase 3 étaient déjà sales au début :
ces deltas ne constituent donc pas un inventaire du lot ; l'inventaire exact du
scope est donné en section 5. Aucun `git add`, commit, reset, checkout, stash ou
autre écriture Git n'a été exécuté. Les changements étrangers restent visibles
et intacts.

---

## Annexe A — Contenu complet des fichiers créés

Les sous-sections suivantes reproduisent intégralement les fichiers créés par
la Phase 3, conformément à `codex_rule.md`. Le présent Evidence Pack est exclu
de sa propre annexe afin d'éviter une récursion sans fin.

### A.1 — `docs/superpowers/plans/2026-07-16-event-builder-phase-i-validator-migration.md`

````markdown
# Event Builder V2 Phase I — Validator & Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `subagent-driven-development` (recommended when explicitly authorized) or
> `executing-plans` to implement this plan task-by-task. Steps use checkbox
> (`- [ ]`) syntax for tracking.

**Goal:** livrer la Phase 3 de la roadmap d’exécution Event Builder V2, soit
I1 à I5 : diagnostics d’intégrité déterministes, atteignabilité, destinations
UI exactes, migration V1→V2 sûre et validation incrémentale mesurée.

**Architecture:** `map_core` reste l’unique propriétaire des diagnostics et de
l’ordre structurel. `map_editor` ne fait que coordonner, mettre en cache les
résultats attestés, naviguer vers Event/Map/Scene et persister la migration via
une frontière applicative testable. Le planner, les receipts, le catalogue V2,
l’index de sources et l’autorité de dispatch existants sont composés; aucun
second validator ou moteur de migration n’est créé.

**Tech Stack:** Dart, Flutter desktop, Riverpod, Freezed existant,
`package:test`, `flutter_test`, persistance fichier journalée et design system
PokeMap.

---

## Contraintes de ce checkout

- Exécution dans le checkout courant, sans worktree, conformément au choix de
  l’utilisateur.
- Aucun `git add`, commit, push, branche, stash ou reset : le dépôt interdit les
  écritures Git sans autorisation explicite. Les étapes « commit » habituelles
  du skill sont remplacées par un inventaire Git en lecture seule.
- Les 149 entrées sales observées au départ appartiennent à plusieurs lots;
  aucune modification étrangère à Phase I ne doit être nettoyée ou réécrite.
- I1–I5 restent des candidates techniques tant que S0/H1–H5 ne sont pas
  formellement `DONE` dans la roadmap d’exécution.
- Lot mécanique associé : `FG-180 — Project Gameplay Readiness Report V0`,
  actuellement `TODO`. Phase I ne suffit pas à fermer FG-180, qui couvre le
  readiness global du fangame.

## Audit et décisions verrouillées

1. `buildNarrativeEventProjectCatalog` produit déjà des codes de diagnostic
   V2 pour source, Scene, dépendance et claim, mais son diagnostic ne porte ni
   action ni destination typée.
2. `narrative_validator.dart` reste le validator Scenario historique. Phase I
   ne doit pas y cacher les diagnostics de registre V2.
3. `NarrativeEventSourceIndex` fournit l’ordre structurel et les ties;
   `NarrativeEventDispatchAuthority` fournit les causes d’inéligibilité runtime.
4. Le planner Phase C et les receipts stricts existent dans `map_core`; aucun
   use case editor ne les prévisualise ou ne les persiste encore.
5. `FileProjectRepository` protège déjà `project.json` par verrou, contrôle de
   révision et écriture atomique. La migration doit le composer et ajouter un
   petit journal/backup de receipt, pas contourner cette autorité.
6. `ScenesWorkspace` possède une sélection locale. Une destination Scene exacte
   exige un focus typé partagé, pas un simple `selectScenesWorkspace()`.
7. Le design system fournit `PokeMapDiagnosticCallout` et les side sheets;
   aucune couleur ad hoc n’est autorisée.

## Task 1 — I1 : rapport d’intégrité V2 déterministe

**Files:**

- Create: `packages/map_core/lib/src/read_models/narrative_event_validation_read_model.dart`
- Create: `packages/map_core/lib/src/operations/build_narrative_event_validation_report.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Test: `packages/map_core/test/narrative_event_v2_integrity_validation_test.dart`

- [ ] **Step 1: écrire le test RED du modèle public**

  Le test construit le même projet dans deux ordres de fichiers et attend le
  même snapshot `toDebugJson()`. Il couvre au minimum : source absente, source
  d’un type non résoluble, Scene absente, claim invalide et record valide sans
  diagnostic.

  API attendue :

  ```dart
  NarrativeEventValidationReport buildNarrativeEventValidationReport({
    required NarrativeEventRegistry registry,
    required NarrativeEventProjectCatalog catalog,
  });
  ```

  Chaque diagnostic expose : `code`, `severity`, `eventId`, `path`, `message`,
  `action`, `destination` et un `stableKey` déterministe.

- [ ] **Step 2: vérifier le RED**

  Run:

  ```bash
  cd packages/map_core
  dart test test/narrative_event_v2_integrity_validation_test.dart
  ```

  Expected: compilation failure because the report API does not exist.

- [ ] **Step 3: implémenter le minimum en composant le catalogue**

  Traduire les diagnostics du catalogue et les invariants du registre vers des
  destinations typées : `event`, `source`, `scene`, `claim`, `registry` ou
  `unavailable`. Conserver les codes existants lorsqu’ils existent. Trier par
  sévérité, `eventId`, chemin, code et clé de destination.

- [ ] **Step 4: exporter uniquement les deux nouvelles APIs publiques**

  Ne pas modifier le validator Scenario et ne pas dupliquer les règles de
  résolution du catalogue.

- [ ] **Step 5: vérifier le GREEN et les tests voisins**

  ```bash
  cd packages/map_core
  dart test test/narrative_event_v2_integrity_validation_test.dart \
    test/narrative_event_project_catalog_test.dart \
    test/narrative_event_configuration_validation_test.dart
  dart analyze lib/src/read_models/narrative_event_validation_read_model.dart \
    lib/src/operations/build_narrative_event_validation_report.dart \
    test/narrative_event_v2_integrity_validation_test.dart
  ```

## Task 2 — I2 : conflits et atteignabilité

**Files:**

- Create: `packages/map_core/lib/src/read_models/narrative_event_reachability_report.dart`
- Create: `packages/map_core/lib/src/operations/build_narrative_event_reachability_report.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Test: `packages/map_core/test/narrative_event_reachability_report_test.dart`

- [ ] **Step 1: écrire le test RED de vérité structurelle**

  Couvrir : priorité décroissante, ordre croissant, tie-break stable par ID,
  conflit exact, one-shot consommé, claim V2, Event désactivé, référence runtime
  absente et condition dont la valeur est inconnue.

  API attendue :

  ```dart
  NarrativeEventReachabilityReport buildNarrativeEventReachabilityReport({
    required NarrativeEventRegistry registry,
    required NarrativeEventProjectCatalog catalog,
    NarrativeEventReachabilityRuntimeSnapshot runtime =
        const NarrativeEventReachabilityRuntimeSnapshot.unknown(),
  });
  ```

  Une valeur runtime inconnue produit `warning/runtimeUnknown`, jamais une
  erreur d’intégrité inventée.

- [ ] **Step 2: vérifier le RED**

  ```bash
  cd packages/map_core
  dart test test/narrative_event_reachability_report_test.dart
  ```

- [ ] **Step 3: implémenter par composition**

  Utiliser `buildNarrativeEventSourceIndex` pour l’ordre et les conflicts. Pour
  un snapshot runtime complet, réutiliser l’autorité de dispatch; pour un
  snapshot incomplet, conserver l’ordre structurel et marquer l’inconnu. Chaque
  cause actionnable reçoit une destination Event/source/claim.

- [ ] **Step 4: vérifier déterminisme et absence de régression**

  ```bash
  cd packages/map_core
  dart test test/narrative_event_reachability_report_test.dart \
    test/narrative_event_source_index_test.dart \
    test/narrative_event_dispatch_authority_test.dart
  dart analyze lib/src/read_models/narrative_event_reachability_report.dart \
    lib/src/operations/build_narrative_event_reachability_report.dart \
    test/narrative_event_reachability_report_test.dart
  ```

## Task 3 — I3 : coordinator et destinations UI exactes

**Files:**

- Create: `packages/map_editor/lib/src/features/narrative/state/narrative_event_validation_state.dart`
- Create: `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart`
- Create: `packages/map_editor/lib/src/features/narrative/state/narrative_scene_focus_provider.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- Test: `packages/map_editor/test/narrative_event_validation_coordinator_test.dart`
- Test: `packages/map_editor/test/ui/canvas/event_builder_v2_validation_navigation_test.dart`

- [ ] **Step 1: écrire les tests RED du coordinator**

  Attendre une projection pure qui regroupe les diagnostics core par Event et
  produit une commande typée : sélectionner l’Event, ouvrir/focaliser sa source
  Map, ou ouvrir/focaliser sa Scene. Une destination supprimée entre le calcul
  et le clic doit retourner `staleDestination`, sans throw.

- [ ] **Step 2: écrire le test widget RED du click-through**

  Depuis un diagnostic :

  - Event → sélectionne `v2:<eventId>` et la section concernée;
  - Map → réutilise le bridge Phase G et son focus exact;
  - Scene → pousse `sceneId` dans le provider de focus, ouvre Scenes et
    `ScenesWorkspace` sélectionne cette Scene;
  - destination obsolète → affiche un diagnostic explicite et conserve le draft.

- [ ] **Step 3: implémenter le coordinator sans recalcul UI**

  Le coordinator reçoit le rapport core déjà construit. Les widgets reçoivent
  seulement des view models et callbacks. Aucun widget ne valide le registre.

- [ ] **Step 4: implémenter le focus Scene ciblé**

  Ajouter un provider Riverpod de requête de focus `{sceneId, nonce}`.
  `NarrativeWorkspaceCanvas` le lit et passe `requestedSceneId` à
  `ScenesWorkspace`. `didUpdateWidget` applique uniquement une nouvelle requête
  valide; un ID absent ne remplace pas la sélection courante.

- [ ] **Step 5: afficher les diagnostics dans l’inspecteur**

  Réutiliser les composants design system. Un bouton n’est rendu que si sa
  destination est encore actionnable. Les libellés sont no-code et les IDs
  techniques restent réservés aux détails debug.

- [ ] **Step 6: vérifier GREEN, focus et retour**

  ```bash
  cd packages/map_editor
  flutter test --no-pub \
    test/narrative_event_validation_coordinator_test.dart \
    test/ui/canvas/event_builder_v2_validation_navigation_test.dart \
    test/event_builder_map_focus_return_flow_test.dart \
    test/scenes_workspace_test.dart
  ```

## Task 4 — I4 : preview, migration, recovery et compensation

**Files:**

- Create: `packages/map_editor/lib/src/application/models/narrative_event_migration_persistence_models.dart`
- Create: `packages/map_editor/lib/src/application/ports/narrative_event_migration_persistence_gateway.dart`
- Create: `packages/map_editor/lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart`
- Create: `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart`
- Create: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_migration_sheet.dart`
- Modify: `packages/map_editor/lib/src/app/providers/core/repository_providers.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`
- Test: `packages/map_editor/test/narrative_event_migration_preview_use_case_test.dart`
- Test: `packages/map_editor/test/ui/canvas/event_builder_v2_migration_sheet_test.dart`

- [ ] **Step 1: écrire les tests RED de preview sans write**

  La preview charge le projet/corpus attesté, appelle
  `NarrativeEventMigrationPlanner.plan`, retourne compteurs, choix, diagnostics,
  impact de mode et receipt proposé, et ne modifie aucun octet.

- [ ] **Step 2: écrire les tests RED de persistance**

  Couvrir : cancel byte-identique, commit/reload reproductible, crash après
  journal préparé, recovery, compensation sûre et compensation bloquée par une
  révision/hash/receipt/ownership/fingerprint divergente.

- [ ] **Step 3: implémenter la frontière de persistance**

  Composer `FileProjectRepository.saveProject` pour `project.json`. Le gateway
  migration possède seulement les opérations `inspect`, `commit`, `recover` et
  `compensate`; il écrit backup, receipt et journal sous un dossier dédié, avec
  flush et renommage atomique fichier par fichier. Il ne revendique jamais une
  atomicité multi-fichier.

- [ ] **Step 4: implémenter la compensation fail-closed**

  Restaurer les octets du backup seulement si toutes les préconditions du
  receipt correspondent encore. Sinon : aucun write, journal conservé, statut
  `blocked` et cause stable.

- [ ] **Step 5: implémenter la sheet de migration**

  Accessible en `legacyOnly` et `dualRead`, elle montre preview, blockers et
  changements avant activation du CTA. Cancel ferme sans write. Commit et
  recovery affichent leur état; aucun JSON brut n’est demandé.

- [ ] **Step 6: vérifier GREEN**

  ```bash
  cd packages/map_editor
  flutter test --no-pub \
    test/narrative_event_migration_preview_use_case_test.dart \
    test/ui/canvas/event_builder_v2_migration_sheet_test.dart
  ```

## Task 5 — I5 : invalidation incrémentale et performance

**Files:**

- Modify: `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart`
- Create: `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart`
- Modify: `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart`
- Create: `reports/narrativeStudio/events/ns_event_v2_phase_3_validator_migration_evidence_pack.md`

- [ ] **Step 1: figer le protocole avant mesure**

  Corpus : 500 records V2 distribués sur 100 sources, 50 Scenes et 100 facts;
  mutation d’un seul Event; 10 warmups; 50 itérations mesurées; exécution
  séquentielle; machine/OS/Dart/Flutter consignés dans l’Evidence Pack.

- [ ] **Step 2: écrire le test de cohérence RED**

  Le cache est indexé par fingerprint global et clés de dépendance par Event.
  Après mutation, seul l’Event et ses dépendants sont recalculés. Le résultat
  incrémental doit être strictement égal au full rebuild, y compris après
  suppression de source ou Scene.

- [ ] **Step 3: mesurer la baseline sans gate**

  Le premier run imprime p50/p95 et compteurs de recalcul sans assertion de
  temps. Reporter les nombres exacts dans l’Evidence Pack.

- [ ] **Step 4: geler les budgets numériques avant le run final**

  Politique ratifiée par ce plan : budget p95 final = valeur entière la plus
  grande entre 25 ms et 2 × la baseline p95 observée; budget de recalcul =
  Event muté + dépendants exacts, sans refresh global. Inscrire les valeurs
  numériques dans le test et l’Evidence Pack avant la validation finale; ne
  plus les modifier après un échec.

- [ ] **Step 5: exécuter le run final**

  ```bash
  cd packages/map_editor
  flutter test --no-pub \
    test/narrative_event_validation_incremental_performance_test.dart \
    test/narrative_event_authoring_snapshot_performance_test.dart
  ```

## Task 6 — Gate Phase 3, critique et Evidence Pack

**Files:**

- Create: `reports/narrativeStudio/events/ns_event_v2_phase_3_validator_migration_evidence_pack.md`
- Do not modify: `MVP Selbrume/road_map_event_builder_v2_execution.md` unless
  the user explicitly requests a roadmap status update.

- [ ] **Step 1: exécuter le gate map_core exact**

  ```bash
  cd packages/map_core
  dart test \
    test/narrative_event_v2_integrity_validation_test.dart \
    test/narrative_event_reachability_report_test.dart
  dart analyze
  ```

- [ ] **Step 2: exécuter le gate map_editor exact**

  ```bash
  cd packages/map_editor
  flutter test --no-pub \
    test/narrative_event_validation_coordinator_test.dart \
    test/narrative_event_migration_preview_use_case_test.dart \
    test/ui/canvas/event_builder_v2_migration_sheet_test.dart \
    test/narrative_event_validation_incremental_performance_test.dart \
    test/narrative_event_authoring_snapshot_performance_test.dart
  flutter analyze --no-pub
  flutter build macos --debug --no-pub
  ```

- [ ] **Step 3: exécuter les régressions Phase 2 et les tests navigation**

  Rejouer le gate H, le retour Map, la sélection Scene et les tests design
  system touchés.

- [ ] **Step 4: effectuer les passes finales séquentielles**

  Audit/Architecture, Implémentation, Tests, Build/Validation et Critique
  finale. La critique recherche scope creep, contrôle mort, cache stale,
  diagnostic mensonger, rollback destructif et fichiers accidentels.

- [ ] **Step 5: écrire l’Evidence Pack conformément à `codex_rule.md`**

  Inclure état Git initial/final, inventaire, zones modifiées, contenu complet
  des fichiers créés, commandes et résultats exacts, baseline/budgets, limites,
  risques et statut proposé de I1–I5 et FG-180.

## Self-review du plan

- Le plan couvre bien les cinq lots I1–I5, pas seulement trois sous-lots.
- Toutes les APIs nouvelles ont un propriétaire unique et un test RED dédié.
- Les règles core ne sont jamais recalculées dans les widgets.
- La migration ne promet pas d’atomicité multi-fichier et sa compensation est
  fail-closed.
- Le focus Scene exact est explicitement prévu, contrairement au simple switch
  de workspace de Phase 2.
- La performance suit le protocole « baseline puis budgets figés » demandé par
  la roadmap.
- Aucun commit ni worktree n’est demandé en contradiction avec les règles du
  dépôt et le choix utilisateur.
- Aucun placeholder `TODO`, pseudo-code `...` ou futur type non défini n’est
  utilisé comme étape d’implémentation.

````


### A.2 — `packages/map_core/lib/src/read_models/narrative_event_validation_read_model.dart`

````dart
import 'package:meta/meta.dart' show immutable;

enum NarrativeEventValidationSeverity { info, warning, error }

enum NarrativeEventValidationAction {
  none,
  openEvent,
  chooseSource,
  openMapSource,
  chooseScene,
  reviewClaim,
  reviewRegistry,
}

enum NarrativeEventValidationDestinationKind {
  unavailable,
  registry,
  event,
  eventSource,
  eventScene,
  mapSource,
  scene,
  claim,
}

@immutable
final class NarrativeEventValidationDestination {
  NarrativeEventValidationDestination({
    required this.kind,
    this.eventId,
    this.mapId,
    this.sourceOwnerId,
    this.sceneId,
    this.claimId,
  }) {
    if (kind == NarrativeEventValidationDestinationKind.event &&
        eventId == null) {
      throw ArgumentError('An Event destination requires eventId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.eventSource &&
        eventId == null) {
      throw ArgumentError('An Event source destination requires eventId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.eventScene &&
        eventId == null) {
      throw ArgumentError('An Event Scene destination requires eventId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.mapSource &&
        mapId == null) {
      throw ArgumentError('A map source destination requires mapId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.scene &&
        sceneId == null) {
      throw ArgumentError('A Scene destination requires sceneId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.claim &&
        claimId == null) {
      throw ArgumentError('A claim destination requires claimId.');
    }
  }

  final NarrativeEventValidationDestinationKind kind;
  final String? eventId;
  final String? mapId;
  final String? sourceOwnerId;
  final String? sceneId;
  final String? claimId;

  String get stableKey => <String?>[
        kind.name,
        eventId,
        mapId,
        sourceOwnerId,
        sceneId,
        claimId,
      ].map((value) => value ?? '').join('\u001f');

  Map<String, Object?> toDebugJson() => {
        'kind': kind.name,
        if (eventId != null) 'eventId': eventId,
        if (mapId != null) 'mapId': mapId,
        if (sourceOwnerId != null) 'sourceOwnerId': sourceOwnerId,
        if (sceneId != null) 'sceneId': sceneId,
        if (claimId != null) 'claimId': claimId,
      };
}

@immutable
final class NarrativeEventValidationDiagnostic {
  NarrativeEventValidationDiagnostic({
    required String code,
    required this.severity,
    required String path,
    required String message,
    required this.action,
    required this.destination,
    this.eventId,
  })  : code = _identity(code, 'code'),
        path = _identity(path, 'path'),
        message = _identity(message, 'message');

  final String code;
  final NarrativeEventValidationSeverity severity;
  final String? eventId;
  final String path;
  final String message;
  final NarrativeEventValidationAction action;
  final NarrativeEventValidationDestination destination;

  String get stableKey => <String?>[
        severity.name,
        eventId,
        path,
        code,
        action.name,
        message,
        destination.stableKey,
      ].map((value) => value ?? '').join('\u001e');

  Map<String, Object?> toDebugJson() => {
        'stableKey': stableKey,
        'code': code,
        'severity': severity.name,
        if (eventId != null) 'eventId': eventId,
        'path': path,
        'message': message,
        'action': action.name,
        'destination': destination.toDebugJson(),
      };
}

@immutable
final class NarrativeEventValidationReport {
  NarrativeEventValidationReport({
    required List<NarrativeEventValidationDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final List<NarrativeEventValidationDiagnostic> diagnostics;

  int get errorCount => diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity == NarrativeEventValidationSeverity.error,
      )
      .length;

  int get warningCount => diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity == NarrativeEventValidationSeverity.warning,
      )
      .length;

  bool get hasBlockingDiagnostics => errorCount != 0;

  Map<String, Object?> toDebugJson() => {
        'errorCount': errorCount,
        'warningCount': warningCount,
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}
````


### A.3 — `packages/map_core/lib/src/operations/build_narrative_event_validation_report.dart`

````dart
import '../catalogs/narrative_event_project_catalog.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../read_models/narrative_event_validation_read_model.dart';
import 'narrative_event_canonical_json.dart';
import 'narrative_event_registry_codec.dart';

NarrativeEventValidationReport buildNarrativeEventValidationReport({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
}) {
  return _buildNarrativeEventValidationReport(
    registry: registry,
    catalog: catalog,
  );
}

/// Reuses the canonical validation rules for a bounded Event subset.
///
/// This is intended for application-layer incremental caches. Passing an
/// empty [eventIds] set with [includeGlobalDiagnostics] enabled rebuilds only
/// registry-wide diagnostics.
NarrativeEventValidationReport buildNarrativeEventValidationReportSubset({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
  required Set<String> eventIds,
  bool includeGlobalDiagnostics = false,
}) {
  return _buildNarrativeEventValidationReport(
    registry: registry,
    catalog: catalog,
    eventIds: eventIds,
    includeGlobalDiagnostics: includeGlobalDiagnostics,
  );
}

/// Applies the canonical deduplication and ordering to cached diagnostics.
NarrativeEventValidationReport normalizeNarrativeEventValidationReport(
  Iterable<NarrativeEventValidationDiagnostic> diagnostics,
) {
  final uniqueByKey = <String, NarrativeEventValidationDiagnostic>{};
  for (final diagnostic in diagnostics) {
    uniqueByKey.putIfAbsent(diagnostic.stableKey, () => diagnostic);
  }
  final sorted = uniqueByKey.values.toList()..sort(_compareDiagnostics);
  return NarrativeEventValidationReport(diagnostics: sorted);
}

NarrativeEventValidationReport _buildNarrativeEventValidationReport({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
  Set<String>? eventIds,
  bool includeGlobalDiagnostics = true,
}) {
  final recordsById = {
    for (final record in registry.records) record.id: record,
  };
  final diagnostics = <NarrativeEventValidationDiagnostic>[];

  for (final diagnostic in catalog.diagnostics) {
    final eventId = _eventIdFromPath(diagnostic.path);
    if (!_includesDiagnostic(
      eventId,
      eventIds: eventIds,
      includeGlobalDiagnostics: includeGlobalDiagnostics,
    )) {
      continue;
    }
    diagnostics.add(
      _fromProjectDiagnostic(
        diagnostic,
        recordsById: recordsById,
      ),
    );
  }

  for (final record in registry.records) {
    if (eventIds != null && !eventIds.contains(record.id)) continue;
    final draft = record.draftOrNull;
    if (draft != null && draft.source == null) {
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'narrativeEventSourceMissing',
          severity: NarrativeEventValidationSeverity.error,
          eventId: record.id,
          path: 'eventRegistry.records.${record.id}.source',
          message: 'Cet Event ne possède pas encore de déclencheur.',
          action: NarrativeEventValidationAction.chooseSource,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.eventSource,
            eventId: record.id,
          ),
        ),
      );
    }
  }

  final claimDiagnostics = <NarrativeEventValidationDiagnostic>[];
  _appendClaimDiagnostics(registry, claimDiagnostics);
  diagnostics.addAll(
    claimDiagnostics.where(
      (diagnostic) => _includesDiagnostic(
        diagnostic.eventId,
        eventIds: eventIds,
        includeGlobalDiagnostics: includeGlobalDiagnostics,
      ),
    ),
  );

  return normalizeNarrativeEventValidationReport(diagnostics);
}

bool _includesDiagnostic(
  String? eventId, {
  required Set<String>? eventIds,
  required bool includeGlobalDiagnostics,
}) {
  if (eventId == null) return includeGlobalDiagnostics;
  return eventIds == null || eventIds.contains(eventId);
}

NarrativeEventValidationDiagnostic _fromProjectDiagnostic(
  NarrativeEventProjectDiagnostic diagnostic, {
  required Map<String, NarrativeEventRecord> recordsById,
}) {
  final eventId = _eventIdFromPath(diagnostic.path);
  final record = eventId == null ? null : recordsById[eventId];
  final severity = switch (diagnostic.severity) {
    NarrativeEventProjectDiagnosticSeverity.info =>
      NarrativeEventValidationSeverity.info,
    NarrativeEventProjectDiagnosticSeverity.warning =>
      NarrativeEventValidationSeverity.warning,
    NarrativeEventProjectDiagnosticSeverity.error =>
      NarrativeEventValidationSeverity.error,
  };

  if (eventId != null && diagnostic.path.endsWith('.source')) {
    final source = _recordSource(record);
    final sourceIdentity = _sourceIdentity(source);
    return NarrativeEventValidationDiagnostic(
      code: diagnostic.code,
      severity: severity,
      eventId: eventId,
      path: diagnostic.path,
      message: diagnostic.message,
      action: NarrativeEventValidationAction.chooseSource,
      destination: NarrativeEventValidationDestination(
        kind: NarrativeEventValidationDestinationKind.eventSource,
        eventId: eventId,
        mapId: sourceIdentity?.mapId,
        sourceOwnerId: sourceIdentity?.ownerId,
      ),
    );
  }

  if (eventId != null && diagnostic.path.endsWith('.sceneId')) {
    final sceneId = _recordSceneId(record);
    return NarrativeEventValidationDiagnostic(
      code: diagnostic.code,
      severity: severity,
      eventId: eventId,
      path: diagnostic.path,
      message: diagnostic.message,
      action: NarrativeEventValidationAction.chooseScene,
      destination:
          sceneId == null || diagnostic.code == 'narrativeEventSceneMissing'
              ? NarrativeEventValidationDestination(
                  kind: NarrativeEventValidationDestinationKind.eventScene,
                  eventId: eventId,
                )
              : NarrativeEventValidationDestination(
                  kind: NarrativeEventValidationDestinationKind.scene,
                  eventId: eventId,
                  sceneId: sceneId,
                ),
    );
  }

  if (eventId != null) {
    return NarrativeEventValidationDiagnostic(
      code: diagnostic.code,
      severity: severity,
      eventId: eventId,
      path: diagnostic.path,
      message: diagnostic.message,
      action: NarrativeEventValidationAction.openEvent,
      destination: NarrativeEventValidationDestination(
        kind: NarrativeEventValidationDestinationKind.event,
        eventId: eventId,
      ),
    );
  }

  return NarrativeEventValidationDiagnostic(
    code: diagnostic.code,
    severity: severity,
    path: diagnostic.path,
    message: diagnostic.message,
    action: NarrativeEventValidationAction.reviewRegistry,
    destination: NarrativeEventValidationDestination(
      kind: NarrativeEventValidationDestinationKind.registry,
    ),
  );
}

void _appendClaimDiagnostics(
  NarrativeEventRegistry registry,
  List<NarrativeEventValidationDiagnostic> diagnostics,
) {
  if (registry.legacyClaims.isEmpty) return;
  final claimIndex = buildValidatedLegacyClaimIndex(registry);

  if (claimIndex.globalConflicts.isNotEmpty) {
    for (var index = 0; index < claimIndex.globalConflicts.length; index++) {
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'legacyClaimGlobalConflict',
          severity: NarrativeEventValidationSeverity.error,
          path: 'eventRegistry.legacyClaims',
          message: claimIndex.globalConflicts[index],
          action: NarrativeEventValidationAction.reviewRegistry,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.registry,
          ),
        ),
      );
    }
    return;
  }

  for (final claim in registry.legacyClaims) {
    final resolution = claimIndex.inspectSourceStructure(claim.source);
    for (final issue in resolution.diagnostics) {
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'legacyClaim${_upperFirst(issue.code.code)}',
          severity: NarrativeEventValidationSeverity.error,
          eventId: issue.targetEventId,
          path: 'eventRegistry.legacyClaims.${claim.cohortId}',
          message: issue.message,
          action: NarrativeEventValidationAction.reviewClaim,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.claim,
            eventId: issue.targetEventId,
            claimId: claim.cohortId,
          ),
        ),
      );
    }
  }
}

String? _eventIdFromPath(String path) {
  const prefix = 'eventRegistry.records.';
  if (!path.startsWith(prefix)) return null;
  final remainder = path.substring(prefix.length);
  final separator = remainder.indexOf('.');
  return separator < 0 ? remainder : remainder.substring(0, separator);
}

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord? record) {
  return record?.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
}

String? _recordSceneId(NarrativeEventRecord? record) {
  return record?.when(
    draft: (draft) => draft.sceneId,
    configured: (definition, _) => definition.sceneId,
  );
}

({String? mapId, String? ownerId})? _sourceIdentity(
  NarrativeEventSourceRef? source,
) {
  return source?.when(
    entityInteract: (mapId, entityId) => (mapId: mapId, ownerId: entityId),
    triggerEnter: (mapId, triggerId) => (mapId: mapId, ownerId: triggerId),
    mapEnter: (mapId) => (mapId: mapId, ownerId: null),
    outcomeReceived: (_) => (mapId: null, ownerId: null),
  );
}

int _compareDiagnostics(
  NarrativeEventValidationDiagnostic left,
  NarrativeEventValidationDiagnostic right,
) {
  final severity = right.severity.index.compareTo(left.severity.index);
  if (severity != 0) return severity;
  for (final pair in <(String, String)>[
    (left.eventId ?? '', right.eventId ?? ''),
    (left.path, right.path),
    (left.code, right.code),
    (left.action.name, right.action.name),
    (left.message, right.message),
    (left.destination.stableKey, right.destination.stableKey),
  ]) {
    final comparison = compareNarrativeEventUtf16(pair.$1, pair.$2);
    if (comparison != 0) return comparison;
  }
  return 0;
}

String _upperFirst(String value) =>
    '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
````


### A.4 — `packages/map_core/lib/src/read_models/narrative_event_reachability_report.dart`

````dart
import 'package:meta/meta.dart' show immutable;

import '../models/game_state.dart';
import '../models/narrative_event_source_ref.dart';
import '../operations/narrative_event_registry_codec.dart';
import '../operations/narrative_fact_runtime.dart';
import 'narrative_event_validation_read_model.dart';

enum NarrativeEventReachabilityStatus {
  reachable,
  unreachable,
  runtimeUnknown,
  blocked,
}

@immutable
final class NarrativeEventReachabilityRuntimeSnapshot {
  const NarrativeEventReachabilityRuntimeSnapshot.unknown()
      : isComplete = false,
        gameState = null,
        factResolver = null,
        claimIndex = null,
        inFlightNarrativeEventIds = const <String>{};

  NarrativeEventReachabilityRuntimeSnapshot.complete({
    required this.gameState,
    required this.factResolver,
    this.claimIndex,
    Set<String> inFlightNarrativeEventIds = const <String>{},
  })  : isComplete = true,
        inFlightNarrativeEventIds = Set.unmodifiable(inFlightNarrativeEventIds);

  final bool isComplete;
  final GameState? gameState;
  final NarrativeFactRuntimeResolver? factResolver;
  final ValidatedLegacyClaimIndex? claimIndex;
  final Set<String> inFlightNarrativeEventIds;
}

@immutable
final class NarrativeEventSourceReachability {
  NarrativeEventSourceReachability({
    required this.source,
    required List<String> orderedEventIds,
    required List<String> disabledEventIds,
    required List<String> draftEventIds,
    required List<String> claimedTargetEventIds,
    required this.hasOrderingConflict,
    required this.status,
    required List<String> reasons,
    this.selectedEventId,
  })  : orderedEventIds = List.unmodifiable(orderedEventIds),
        disabledEventIds = List.unmodifiable(disabledEventIds),
        draftEventIds = List.unmodifiable(draftEventIds),
        claimedTargetEventIds = List.unmodifiable(claimedTargetEventIds),
        reasons = List.unmodifiable(reasons);

  final NarrativeEventSourceRef source;
  final List<String> orderedEventIds;
  final List<String> disabledEventIds;
  final List<String> draftEventIds;
  final List<String> claimedTargetEventIds;
  final bool hasOrderingConflict;
  final NarrativeEventReachabilityStatus status;
  final List<String> reasons;
  final String? selectedEventId;

  Map<String, Object?> toDebugJson() => {
        'source': source.toJson(),
        'orderedEventIds': orderedEventIds,
        'disabledEventIds': disabledEventIds,
        'draftEventIds': draftEventIds,
        'claimedTargetEventIds': claimedTargetEventIds,
        'hasOrderingConflict': hasOrderingConflict,
        'status': status.name,
        'reasons': reasons,
        if (selectedEventId != null) 'selectedEventId': selectedEventId,
      };
}

@immutable
final class NarrativeEventReachabilityReport {
  NarrativeEventReachabilityReport({
    required List<NarrativeEventSourceReachability> sources,
    required List<NarrativeEventValidationDiagnostic> diagnostics,
  })  : sources = List.unmodifiable(sources),
        diagnostics = List.unmodifiable(diagnostics);

  final List<NarrativeEventSourceReachability> sources;
  final List<NarrativeEventValidationDiagnostic> diagnostics;

  Map<String, Object?> toDebugJson() => {
        'sources': [for (final source in sources) source.toDebugJson()],
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };
}
````


### A.5 — `packages/map_core/lib/src/operations/build_narrative_event_reachability_report.dart`

````dart
import '../catalogs/narrative_event_project_catalog.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_occurrence.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../read_models/narrative_event_reachability_report.dart';
import '../read_models/narrative_event_source_index.dart';
import '../read_models/narrative_event_validation_read_model.dart';
import 'narrative_event_canonical_json.dart';
import 'narrative_event_dispatch_authority.dart';
import 'narrative_event_registry_codec.dart';

NarrativeEventReachabilityReport buildNarrativeEventReachabilityReport({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
  NarrativeEventReachabilityRuntimeSnapshot runtime =
      const NarrativeEventReachabilityRuntimeSnapshot.unknown(),
}) {
  final sourceIndexResult = buildNarrativeEventSourceIndex(registry.records);
  final claimIndex = buildValidatedLegacyClaimIndex(registry);
  final sourcesByKey = <String, NarrativeEventSourceRef>{};
  for (final record in registry.records) {
    final source = _recordSource(record);
    if (source != null) sourcesByKey[_sourceKey(source)] = source;
  }
  for (final claim in registry.legacyClaims) {
    sourcesByKey[_sourceKey(claim.source)] = claim.source;
  }

  final diagnostics = <NarrativeEventValidationDiagnostic>[];
  final reports = <NarrativeEventSourceReachability>[];
  final sortedSources = sourcesByKey.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (final entry in sortedSources) {
    final source = entry.value;
    final orderedRecords = sourceIndexResult.index.recordsFor(source);
    final allRecords = registry.records
        .where((record) => _recordSource(record) == source)
        .toList()
      ..sort((left, right) => compareNarrativeEventUtf16(left.id, right.id));
    final disabledIds = <String>[
      for (final record in allRecords)
        if (record.definitionOrNull != null && record.enabledOrNull != true)
          record.id,
    ];
    final draftIds = <String>[
      for (final record in allRecords)
        if (record.draftOrNull != null) record.id,
    ];
    final sourceConflicts = sourceIndexResult.conflicts
        .where((conflict) => conflict.source == source)
        .toList();
    final claimResolution = claimIndex.inspectSourceStructure(source);
    final claims = claimResolution is LegacyClaimSourceValid
        ? <LegacySourceClaim>[claimResolution.claim]
        : <LegacySourceClaim>[];
    final claimedTargetIds = <String>{
      for (final claim in claims) ...claim.targetEventIds,
    }.toList()
      ..sort(compareNarrativeEventUtf16);

    for (final conflict in sourceConflicts) {
      for (final record in conflict.records) {
        diagnostics.add(
          NarrativeEventValidationDiagnostic(
            code: 'sourceOrderingConflict',
            severity: NarrativeEventValidationSeverity.error,
            eventId: record.id,
            path: 'eventRegistry.sources.${entry.key}',
            message: conflict.diagnostic,
            action: _sourceAction(source),
            destination: _sourceDestination(source, record.id),
          ),
        );
      }
    }
    for (final claim in claims) {
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'sourceClaimedByV2',
          severity: NarrativeEventValidationSeverity.info,
          eventId: claim.targetEventIds.first,
          path: 'eventRegistry.legacyClaims.${claim.cohortId}',
          message: 'Cette source legacy est revendiquée par Event V2.',
          action: NarrativeEventValidationAction.reviewClaim,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.claim,
            claimId: claim.cohortId,
            eventId: claim.targetEventIds.first,
          ),
        ),
      );
    }

    if (!runtime.isComplete) {
      final hasEnabledCandidates = orderedRecords.isNotEmpty;
      if (hasEnabledCandidates) {
        final eventId = orderedRecords.first.id;
        diagnostics.add(
          NarrativeEventValidationDiagnostic(
            code: 'runtimeUnknown',
            severity: NarrativeEventValidationSeverity.warning,
            eventId: eventId,
            path: 'eventRegistry.sources.${entry.key}.runtime',
            message:
                'L’état runtime est inconnu; l’atteignabilité finale ne peut pas être affirmée.',
            action: _sourceAction(source),
            destination: _sourceDestination(source, eventId),
          ),
        );
      }
      reports.add(
        NarrativeEventSourceReachability(
          source: source,
          orderedEventIds: [for (final record in orderedRecords) record.id],
          disabledEventIds: disabledIds,
          draftEventIds: draftIds,
          claimedTargetEventIds: claimedTargetIds,
          hasOrderingConflict: sourceConflicts.isNotEmpty,
          status: hasEnabledCandidates
              ? NarrativeEventReachabilityStatus.runtimeUnknown
              : NarrativeEventReachabilityStatus.unreachable,
          reasons: hasEnabledCandidates
              ? const ['runtimeUnknown']
              : [
                  if (disabledIds.isNotEmpty) 'disabled',
                  if (draftIds.isNotEmpty) 'draft',
                  'noEligibleCandidate',
                ],
        ),
      );
      continue;
    }

    final preparation = NarrativeEventDispatchAuthority.prepare(
      registryResult: EventRegistryDecodeResult.decoded(registry),
      occurrence: NarrativeEventOccurrence(source: source),
      factResolver: runtime.factResolver!,
      legacyClaimIndex: runtime.claimIndex,
      projectCatalog: catalog,
    );
    if (preparation is NarrativeEventDispatchAuthorityBlocked) {
      final reasons = <String>[
        'authorityBlocked:${preparation.reason.name}',
        ...preparation.diagnostics,
      ];
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'dispatchAuthorityBlocked',
          severity: NarrativeEventValidationSeverity.warning,
          eventId: allRecords.isEmpty ? null : allRecords.first.id,
          path: 'eventRegistry.sources.${entry.key}.runtime',
          message: reasons.join(' '),
          action: allRecords.isEmpty
              ? NarrativeEventValidationAction.reviewRegistry
              : _sourceAction(source),
          destination: allRecords.isEmpty
              ? NarrativeEventValidationDestination(
                  kind: NarrativeEventValidationDestinationKind.registry,
                )
              : _sourceDestination(source, allRecords.first.id),
        ),
      );
      reports.add(
        NarrativeEventSourceReachability(
          source: source,
          orderedEventIds: [for (final record in orderedRecords) record.id],
          disabledEventIds: disabledIds,
          draftEventIds: draftIds,
          claimedTargetEventIds: claimedTargetIds,
          hasOrderingConflict: sourceConflicts.isNotEmpty,
          status: NarrativeEventReachabilityStatus.blocked,
          reasons: reasons,
        ),
      );
      continue;
    }

    final decision = (preparation as NarrativeEventDispatchAuthorityReady).plan(
      gameState: runtime.gameState!,
      inFlightNarrativeEventIds: runtime.inFlightNarrativeEventIds,
    );
    final handled = decision is NarrativeEventDispatchHandled;
    final reasons = [for (final reason in decision.reasons) reason.name];
    reports.add(
      NarrativeEventSourceReachability(
        source: source,
        orderedEventIds: [for (final record in orderedRecords) record.id],
        disabledEventIds: disabledIds,
        draftEventIds: draftIds,
        claimedTargetEventIds: claimedTargetIds,
        hasOrderingConflict: sourceConflicts.isNotEmpty,
        status: handled
            ? NarrativeEventReachabilityStatus.reachable
            : NarrativeEventReachabilityStatus.unreachable,
        reasons: reasons,
        selectedEventId: handled ? decision.eventId : null,
      ),
    );
  }

  diagnostics.sort((left, right) {
    final severity = right.severity.index.compareTo(left.severity.index);
    if (severity != 0) return severity;
    return left.stableKey.compareTo(right.stableKey);
  });
  return NarrativeEventReachabilityReport(
    sources: reports,
    diagnostics: diagnostics,
  );
}

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
}

String _sourceKey(NarrativeEventSourceRef source) =>
    canonicalizeNarrativeEventJson(source.toJson());

String? _mapId(NarrativeEventSourceRef source) => source.when(
      entityInteract: (mapId, _) => mapId,
      triggerEnter: (mapId, _) => mapId,
      mapEnter: (mapId) => mapId,
      outcomeReceived: (_) => null,
    );

String? _ownerId(NarrativeEventSourceRef source) => source.when(
      entityInteract: (_, entityId) => entityId,
      triggerEnter: (_, triggerId) => triggerId,
      mapEnter: (_) => null,
      outcomeReceived: (_) => null,
    );

NarrativeEventValidationAction _sourceAction(NarrativeEventSourceRef source) {
  return source.kind == NarrativeEventSourceKind.outcomeReceived
      ? NarrativeEventValidationAction.openEvent
      : NarrativeEventValidationAction.openMapSource;
}

NarrativeEventValidationDestination _sourceDestination(
  NarrativeEventSourceRef source,
  String eventId,
) {
  if (source.kind == NarrativeEventSourceKind.outcomeReceived) {
    return NarrativeEventValidationDestination(
      kind: NarrativeEventValidationDestinationKind.eventSource,
      eventId: eventId,
    );
  }
  return NarrativeEventValidationDestination(
    kind: NarrativeEventValidationDestinationKind.mapSource,
    eventId: eventId,
    mapId: _mapId(source),
    sourceOwnerId: _ownerId(source),
  );
}
````


### A.6 — `packages/map_core/test/narrative_event_v2_integrity_validation_test.dart`

````dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

const _validId = 'evt_019abcde-0000-7000-8000-000000000005';

void main() {
  group('I1 Event V2 integrity validation', () {
    test('is deterministic and exposes typed repair destinations', () {
      final records = <NarrativeEventRecord>[
        draftRecord(id: eventIdA),
        configuredRecord(
          id: eventIdB,
          source: NarrativeEventSourceRef.triggerEnter('map_a', 'zone_bad'),
        ),
        configuredRecord(id: eventIdC, sceneId: 'scene_missing'),
        configuredRecord(id: _validId),
      ];
      final registry = registryWithRecords(
        records,
        claims: [
          authoringClaim(targetEventIds: [eventIdD])
        ],
      );
      final catalogDiagnostics = <NarrativeEventProjectDiagnostic>[
        NarrativeEventProjectDiagnostic(
          code: 'narrativeEventSourceUnavailable',
          severity: NarrativeEventProjectDiagnosticSeverity.error,
          message: 'La source ne correspond plus à un déclencheur utilisable.',
          path: 'eventRegistry.records.$eventIdB.source',
        ),
        NarrativeEventProjectDiagnostic(
          code: 'narrativeEventSceneMissing',
          severity: NarrativeEventProjectDiagnosticSeverity.error,
          message: 'La Scene sélectionnée est absente.',
          path: 'eventRegistry.records.$eventIdC.sceneId',
        ),
      ];

      NarrativeEventValidationReport build({required bool reversed}) {
        final orderedRecords = reversed ? records.reversed.toList() : records;
        final orderedDiagnostics = reversed
            ? catalogDiagnostics.reversed.toList()
            : catalogDiagnostics;
        final orderedRegistry = registryWithRecords(
          orderedRecords,
          claims: registry.legacyClaims,
        );
        return buildNarrativeEventValidationReport(
          registry: orderedRegistry,
          catalog: authoringCatalogForRegistry(
            orderedRegistry,
            diagnostics: orderedDiagnostics,
            invalidEventIds: {eventIdB, eventIdC},
          ),
        );
      }

      final report = build(reversed: false);
      expect(build(reversed: true).toDebugJson(), report.toDebugJson());
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'narrativeEventSourceMissing',
          'narrativeEventSourceUnavailable',
          'narrativeEventSceneMissing',
          'legacyClaimTargetEventAbsent',
        ]),
      );

      final sourceMissing = report.diagnostics.singleWhere(
        (diagnostic) =>
            diagnostic.code == 'narrativeEventSourceMissing' &&
            diagnostic.eventId == eventIdA,
      );
      expect(sourceMissing.severity, NarrativeEventValidationSeverity.error);
      expect(sourceMissing.action, NarrativeEventValidationAction.chooseSource);
      expect(
        sourceMissing.destination.kind,
        NarrativeEventValidationDestinationKind.eventSource,
      );
      expect(sourceMissing.destination.eventId, eventIdA);

      final sceneMissing = report.diagnostics.singleWhere(
        (diagnostic) => diagnostic.code == 'narrativeEventSceneMissing',
      );
      expect(sceneMissing.action, NarrativeEventValidationAction.chooseScene);
      expect(
        sceneMissing.destination.kind,
        NarrativeEventValidationDestinationKind.eventScene,
      );
      expect(sceneMissing.destination.eventId, eventIdC);

      final invalidClaim = report.diagnostics.singleWhere(
        (diagnostic) => diagnostic.code == 'legacyClaimTargetEventAbsent',
      );
      expect(invalidClaim.eventId, eventIdD);
      expect(invalidClaim.action, NarrativeEventValidationAction.reviewClaim);
      expect(
        invalidClaim.destination.kind,
        NarrativeEventValidationDestinationKind.claim,
      );
      expect(invalidClaim.destination.claimId,
          registry.legacyClaims.single.cohortId);

      expect(
        report.diagnostics.where(
          (diagnostic) => diagnostic.eventId == _validId,
        ),
        isEmpty,
      );
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.stableKey).toSet(),
        hasLength(report.diagnostics.length),
      );
    });

    test('keeps project diagnostics without an Event as registry destinations',
        () {
      final registry = registryWithRecords(const []);
      final report = buildNarrativeEventValidationReport(
        registry: registry,
        catalog: authoringCatalog(
          diagnostics: [
            NarrativeEventProjectDiagnostic(
              code: 'duplicateManifestMapId',
              severity: NarrativeEventProjectDiagnosticSeverity.warning,
              message: 'Deux maps partagent le même identifiant.',
              path: 'maps.map_a',
            ),
          ],
        ),
      );

      expect(report.errorCount, 0);
      expect(report.warningCount, 1);
      expect(
        report.diagnostics.single.destination.kind,
        NarrativeEventValidationDestinationKind.registry,
      );
      expect(report.diagnostics.single.eventId, isNull);
    });

    test('normalization keeps distinct conflict messages', () {
      NarrativeEventValidationDiagnostic conflict(String message) {
        return NarrativeEventValidationDiagnostic(
          code: 'legacyClaimGlobalConflict',
          severity: NarrativeEventValidationSeverity.error,
          path: 'eventRegistry.legacyClaims',
          message: message,
          action: NarrativeEventValidationAction.reviewRegistry,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.registry,
          ),
        );
      }

      final report = normalizeNarrativeEventValidationReport([
        conflict('Conflit A.'),
        conflict('Conflit B.'),
      ]);

      expect(report.diagnostics, hasLength(2));
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.message),
        ['Conflit A.', 'Conflit B.'],
      );
    });
  });
}
````


### A.7 — `packages/map_core/test/narrative_event_reachability_report_test.dart`

````dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

const _eventE = 'evt_019abcde-0000-7000-8000-000000000005';
const _eventF = 'evt_019abcde-0000-7000-8000-000000000006';

void main() {
  group('I2 Event V2 reachability report', () {
    test('keeps structural order, exact conflicts, claims and unknown runtime',
        () {
      final conflictSource = NarrativeEventSourceRef.mapEnter('map_a');
      final disabledSource = NarrativeEventSourceRef.mapEnter('map_disabled');
      final conditionSource =
          NarrativeEventSourceRef.outcomeReceived(outcomeRef);
      final records = <NarrativeEventRecord>[
        configuredRecord(
          id: eventIdC,
          source: conflictSource,
          priority: 20,
          order: 99,
          enabled: true,
        ),
        configuredRecord(
          id: eventIdB,
          source: conflictSource,
          priority: 10,
          order: 2,
          enabled: true,
        ),
        configuredRecord(
          id: eventIdA,
          source: conflictSource,
          priority: 10,
          order: 2,
          enabled: true,
        ),
        configuredRecord(
          id: eventIdD,
          source: disabledSource,
          priority: 99,
          enabled: false,
        ),
        configuredRecord(
          id: _eventF,
          source: conditionSource,
          conditions: [NarrativeEventCondition.fact('fact_a', true)],
          enabled: true,
        ),
      ];
      final claim = authoringClaim(
        source: conflictSource,
        targetEventIds: [eventIdA],
      );
      final registry = registryWithRecords(
        records,
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );

      final report = buildNarrativeEventReachabilityReport(
        registry: registry,
        catalog: _catalog(registry),
      );
      final conflict = report.sources.singleWhere(
        (source) => source.source == conflictSource,
      );
      expect(conflict.orderedEventIds, [eventIdC, eventIdA, eventIdB]);
      expect(conflict.hasOrderingConflict, isTrue);
      expect(conflict.claimedTargetEventIds, [eventIdA]);
      expect(conflict.status, NarrativeEventReachabilityStatus.runtimeUnknown);

      final disabled = report.sources.singleWhere(
        (source) => source.source == disabledSource,
      );
      expect(disabled.disabledEventIds, [eventIdD]);
      expect(disabled.status, NarrativeEventReachabilityStatus.unreachable);
      expect(disabled.reasons, contains('disabled'));

      final condition = report.sources.singleWhere(
        (source) => source.source == conditionSource,
      );
      expect(condition.status, NarrativeEventReachabilityStatus.runtimeUnknown);
      final unknown = report.diagnostics.where(
        (diagnostic) => diagnostic.code == 'runtimeUnknown',
      );
      expect(unknown, isNotEmpty);
      expect(
        unknown.every(
          (diagnostic) =>
              diagnostic.severity == NarrativeEventValidationSeverity.warning,
        ),
        isTrue,
      );
      expect(
        report.diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'runtimeUnknown' &&
              diagnostic.severity == NarrativeEventValidationSeverity.error,
        ),
        isEmpty,
      );
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(['sourceOrderingConflict', 'sourceClaimedByV2']),
      );
      expect(
        report.diagnostics
            .where((diagnostic) => diagnostic.code == 'sourceOrderingConflict')
            .map((diagnostic) => diagnostic.eventId),
        containsAll([eventIdA, eventIdB]),
      );
      expect(
        report.diagnostics
            .where((diagnostic) => diagnostic.code == 'runtimeUnknown')
            .first
            .destination
            .kind,
        NarrativeEventValidationDestinationKind.mapSource,
      );

      final permutedRegistry = registryWithRecords(
        records.reversed.toList(),
        mode: EventSystemMode.dualRead,
        claims: [claim],
      );
      final permuted = buildNarrativeEventReachabilityReport(
        registry: permutedRegistry,
        catalog: _catalog(permutedRegistry),
      );
      expect(permuted.toDebugJson(), report.toDebugJson());
    });

    test(
        'reuses dispatch authority for consumed and missing runtime references',
        () {
      final consumedSource = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'npc_a',
      );
      final missingReferenceSource =
          NarrativeEventSourceRef.triggerEnter('map_a', 'zone_a');
      final records = <NarrativeEventRecord>[
        configuredRecord(
          id: eventIdC,
          source: consumedSource,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          enabled: true,
        ),
        configuredRecord(
          id: _eventE,
          source: missingReferenceSource,
          sceneId: 'scene_missing',
          enabled: true,
        ),
      ];
      final registry = registryWithRecords(
        records,
        mode: EventSystemMode.v2Only,
      );
      final report = buildNarrativeEventReachabilityReport(
        registry: registry,
        catalog: _catalog(registry),
        runtime: NarrativeEventReachabilityRuntimeSnapshot.complete(
          gameState: GameState(
            saveId: 'reachability',
            narrativeEventProgress: NarrativeEventProgress(
              consumedNarrativeEventIds: [eventIdC],
            ),
          ),
          factResolver: NarrativeFactRuntimeResolver.fromFacts(
            [factEntry().fact],
          ),
        ),
      );

      final consumed = report.sources.singleWhere(
        (source) => source.source == consumedSource,
      );
      expect(consumed.status, NarrativeEventReachabilityStatus.unreachable);
      expect(consumed.reasons, contains('eventConsumed'));

      final missing = report.sources.singleWhere(
        (source) => source.source == missingReferenceSource,
      );
      expect(missing.status, NarrativeEventReachabilityStatus.unreachable);
      expect(missing.reasons, contains('runtimeReferenceUnavailable'));
    });
  });
}

NarrativeEventProjectCatalog _catalog(NarrativeEventRegistry registry) {
  return authoringCatalog(
    spatialOptions: [
      spatialOption(NarrativeEventSourceRef.mapEnter('map_a')),
      spatialOption(NarrativeEventSourceRef.mapEnter('map_disabled')),
      spatialOption(entitySource),
      spatialOption(triggerSource),
    ],
    scenes: [sceneEntry()],
    facts: [factEntry()],
    events: [
      for (final record in registry.records)
        NarrativeEventProjectEventEntry(
          record: record,
          proposed: false,
          inDependencyCycle: false,
          contextuallyValid: true,
        ),
    ],
  );
}
````


### A.8 — `packages/map_editor/lib/src/features/narrative/state/narrative_event_validation_state.dart`

````dart
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

@immutable
final class NarrativeEventValidationItem {
  const NarrativeEventValidationItem(this.diagnostic);

  final NarrativeEventValidationDiagnostic diagnostic;

  bool get actionable =>
      diagnostic.action != NarrativeEventValidationAction.none &&
      diagnostic.destination.kind !=
          NarrativeEventValidationDestinationKind.unavailable;
}

@immutable
final class NarrativeEventValidationState {
  NarrativeEventValidationState._({
    required Map<String, List<NarrativeEventValidationItem>> byEventId,
    required List<NarrativeEventValidationItem> global,
  })  : _byEventId =
            Map<String, List<NarrativeEventValidationItem>>.unmodifiable({
          for (final entry in byEventId.entries)
            entry.key:
                List<NarrativeEventValidationItem>.unmodifiable(entry.value),
        }),
        global = List<NarrativeEventValidationItem>.unmodifiable(global);

  factory NarrativeEventValidationState.fromReport(
    NarrativeEventValidationReport report,
  ) {
    final byEventId = <String, List<NarrativeEventValidationItem>>{};
    final global = <NarrativeEventValidationItem>[];
    for (final diagnostic in report.diagnostics) {
      final item = NarrativeEventValidationItem(diagnostic);
      final eventId = diagnostic.eventId;
      if (eventId == null) {
        global.add(item);
      } else {
        byEventId.putIfAbsent(eventId, () => []).add(item);
      }
    }
    return NarrativeEventValidationState._(
      byEventId: byEventId,
      global: global,
    );
  }

  final Map<String, List<NarrativeEventValidationItem>> _byEventId;
  final List<NarrativeEventValidationItem> global;

  List<NarrativeEventValidationItem> forEvent(String? eventId) {
    if (eventId == null) return const [];
    return _byEventId[eventId] ?? const [];
  }
}

@immutable
final class NarrativeEventValidationSnapshot {
  const NarrativeEventValidationSnapshot({
    required this.registry,
    required this.catalog,
    required this.report,
    required this.state,
    this.recalculatedEventIds = const {},
  });

  final NarrativeEventRegistry registry;
  final NarrativeEventProjectCatalog catalog;
  final NarrativeEventValidationReport report;
  final NarrativeEventValidationState state;
  final Set<String> recalculatedEventIds;
}
````


### A.9 — `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart`

````dart
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

enum NarrativeEventValidationNavigationStatus {
  ready,
  staleDestination,
  unavailable,
}

enum NarrativeEventValidationNavigationKind {
  selectEvent,
  openMapSource,
  openScene,
  reviewClaim,
  reviewRegistry,
}

enum NarrativeEventValidationSection { overview, source, scene, claim }

@immutable
final class NarrativeEventIncrementalValidationCache {
  NarrativeEventIncrementalValidationCache({
    required Map<String, String> eventFingerprints,
    required Map<String, List<NarrativeEventValidationDiagnostic>>
        diagnosticsByEvent,
    required List<NarrativeEventValidationDiagnostic> globalDiagnostics,
    required Map<String, Set<String>> dependenciesByEvent,
    required this.globalFingerprint,
  })  : eventFingerprints = Map<String, String>.unmodifiable(eventFingerprints),
        diagnosticsByEvent =
            Map<String, List<NarrativeEventValidationDiagnostic>>.unmodifiable({
          for (final entry in diagnosticsByEvent.entries)
            entry.key: List<NarrativeEventValidationDiagnostic>.unmodifiable(
              entry.value,
            ),
        }),
        globalDiagnostics =
            List<NarrativeEventValidationDiagnostic>.unmodifiable(
          globalDiagnostics,
        ),
        dependenciesByEvent = Map<String, Set<String>>.unmodifiable({
          for (final entry in dependenciesByEvent.entries)
            entry.key: Set<String>.unmodifiable(entry.value),
        });

  final Map<String, String> eventFingerprints;
  final Map<String, List<NarrativeEventValidationDiagnostic>>
      diagnosticsByEvent;
  final List<NarrativeEventValidationDiagnostic> globalDiagnostics;
  final Map<String, Set<String>> dependenciesByEvent;
  final String globalFingerprint;
}

@immutable
final class NarrativeEventIncrementalValidationResult {
  NarrativeEventIncrementalValidationResult({
    required this.report,
    required this.cache,
    required Set<String> recalculatedEventIds,
  }) : recalculatedEventIds = Set<String>.unmodifiable(recalculatedEventIds);

  final NarrativeEventValidationReport report;
  final NarrativeEventIncrementalValidationCache cache;
  final Set<String> recalculatedEventIds;
}

@immutable
final class NarrativeEventValidationNavigationCommand {
  const NarrativeEventValidationNavigationCommand({
    required this.kind,
    required this.section,
    this.eventId,
    this.mapId,
    this.sourceOwnerId,
    this.sceneId,
    this.claimId,
  });

  final NarrativeEventValidationNavigationKind kind;
  final NarrativeEventValidationSection section;
  final String? eventId;
  final String? mapId;
  final String? sourceOwnerId;
  final String? sceneId;
  final String? claimId;

  String? get selectedStableKey => eventId == null ? null : 'v2:$eventId';
}

@immutable
final class NarrativeEventValidationNavigationResult {
  const NarrativeEventValidationNavigationResult._({
    required this.status,
    required this.message,
    this.command,
  });

  const NarrativeEventValidationNavigationResult.ready(
    NarrativeEventValidationNavigationCommand command,
  ) : this._(
          status: NarrativeEventValidationNavigationStatus.ready,
          message: '',
          command: command,
        );

  const NarrativeEventValidationNavigationResult.stale(String message)
      : this._(
          status: NarrativeEventValidationNavigationStatus.staleDestination,
          message: message,
        );

  const NarrativeEventValidationNavigationResult.unavailable(String message)
      : this._(
          status: NarrativeEventValidationNavigationStatus.unavailable,
          message: message,
        );

  final NarrativeEventValidationNavigationStatus status;
  final String message;
  final NarrativeEventValidationNavigationCommand? command;
}

final class NarrativeEventValidationCoordinator {
  const NarrativeEventValidationCoordinator();

  /// Reuses core-produced diagnostics for Events whose attested inputs did not
  /// change, while always invalidating transitive Event dependents.
  ///
  /// The coordinator owns cache policy only: scoped and merged reports still
  /// pass through map_core so the editor cannot introduce a second validator
  /// or a competing diagnostic order.
  NarrativeEventIncrementalValidationResult rebuildIncrementally({
    required NarrativeEventRegistry registry,
    required NarrativeEventProjectCatalog catalog,
    NarrativeEventIncrementalValidationCache? previous,
  }) {
    final recordsById = {
      for (final record in registry.records) record.id: record,
    };
    final currentFingerprints = {
      for (final record in registry.records)
        record.id: _eventValidationFingerprint(
          record,
          registry: registry,
          catalog: catalog,
        ),
    };
    final currentDependencies = {
      for (final record in registry.records)
        record.id: _recordEventDependencies(record),
    };
    final globalFingerprint = _globalValidationFingerprint(
      registry: registry,
      catalog: catalog,
    );

    if (previous == null) {
      final report = buildNarrativeEventValidationReport(
        registry: registry,
        catalog: catalog,
      );
      final partition = _partitionDiagnostics(
        report.diagnostics,
        eventIds: recordsById.keys.toSet(),
      );
      return NarrativeEventIncrementalValidationResult(
        report: report,
        cache: NarrativeEventIncrementalValidationCache(
          eventFingerprints: currentFingerprints,
          diagnosticsByEvent: partition.byEvent,
          globalDiagnostics: partition.global,
          dependenciesByEvent: currentDependencies,
          globalFingerprint: globalFingerprint,
        ),
        recalculatedEventIds: recordsById.keys.toSet(),
      );
    }

    if (!_sameStringSet(
      previous.eventFingerprints.keys,
      currentFingerprints.keys,
    )) {
      return rebuildIncrementally(registry: registry, catalog: catalog);
    }

    final directlyChanged = <String>{};
    for (final eventId in {
      ...previous.eventFingerprints.keys,
      ...currentFingerprints.keys,
    }) {
      if (previous.eventFingerprints[eventId] != currentFingerprints[eventId]) {
        directlyChanged.add(eventId);
      }
    }
    final invalidated = _withTransitiveDependents(
      directlyChanged,
      currentDependencies: currentDependencies,
      previousDependencies: previous.dependenciesByEvent,
    );
    final recalculatedEventIds =
        invalidated.intersection(recordsById.keys.toSet());

    final recalculatedReport = buildNarrativeEventValidationReportSubset(
      registry: registry,
      catalog: catalog,
      eventIds: recalculatedEventIds,
    );
    final recalculatedPartition = _partitionDiagnostics(
      recalculatedReport.diagnostics,
      eventIds: recalculatedEventIds,
    );
    final diagnosticsByEvent =
        <String, List<NarrativeEventValidationDiagnostic>>{
      for (final eventId in recordsById.keys)
        eventId: recalculatedEventIds.contains(eventId)
            ? recalculatedPartition.byEvent[eventId] ?? const []
            : previous.diagnosticsByEvent[eventId] ?? const [],
    };

    final globalDiagnostics = globalFingerprint == previous.globalFingerprint
        ? previous.globalDiagnostics
        : buildNarrativeEventValidationReportSubset(
            registry: registry,
            catalog: catalog,
            eventIds: const {},
            includeGlobalDiagnostics: true,
          ).diagnostics;
    final report = normalizeNarrativeEventValidationReport([
      ...globalDiagnostics,
      for (final diagnostics in diagnosticsByEvent.values) ...diagnostics,
    ]);

    return NarrativeEventIncrementalValidationResult(
      report: report,
      cache: NarrativeEventIncrementalValidationCache(
        eventFingerprints: currentFingerprints,
        diagnosticsByEvent: diagnosticsByEvent,
        globalDiagnostics: globalDiagnostics,
        dependenciesByEvent: currentDependencies,
        globalFingerprint: globalFingerprint,
      ),
      recalculatedEventIds: recalculatedEventIds,
    );
  }

  NarrativeEventValidationNavigationResult resolve({
    required NarrativeEventValidationDiagnostic diagnostic,
    required NarrativeEventRegistry registry,
    required NarrativeEventProjectCatalog catalog,
  }) {
    final destination = diagnostic.destination;
    final eventId = destination.eventId ?? diagnostic.eventId;
    final record = eventId == null
        ? null
        : registry.records.where((record) => record.id == eventId).firstOrNull;

    switch (destination.kind) {
      case NarrativeEventValidationDestinationKind.unavailable:
        return const NarrativeEventValidationNavigationResult.unavailable(
          'Ce diagnostic ne possède pas de destination ouvrable.',
        );
      case NarrativeEventValidationDestinationKind.registry:
        return const NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.reviewRegistry,
            section: NarrativeEventValidationSection.overview,
          ),
        );
      case NarrativeEventValidationDestinationKind.event:
      case NarrativeEventValidationDestinationKind.eventSource:
      case NarrativeEventValidationDestinationKind.eventScene:
        if (record == null) return _staleEvent();
        return NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.selectEvent,
            section: switch (destination.kind) {
              NarrativeEventValidationDestinationKind.eventSource =>
                NarrativeEventValidationSection.source,
              NarrativeEventValidationDestinationKind.eventScene =>
                NarrativeEventValidationSection.scene,
              _ => NarrativeEventValidationSection.overview,
            },
            eventId: eventId,
          ),
        );
      case NarrativeEventValidationDestinationKind.mapSource:
        if (record == null) return _staleEvent();
        final source = _recordSource(record);
        if (source == null ||
            catalog.resolveSource(source).status !=
                NarrativeEventProjectResolutionStatus.found ||
            !_matchesSpatialDestination(source, destination)) {
          return const NarrativeEventValidationNavigationResult.stale(
            'L’élément de map ciblé n’existe plus dans le projet courant.',
          );
        }
        return NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.openMapSource,
            section: NarrativeEventValidationSection.source,
            eventId: eventId,
            mapId: destination.mapId,
            sourceOwnerId: destination.sourceOwnerId,
          ),
        );
      case NarrativeEventValidationDestinationKind.scene:
        final sceneId = destination.sceneId;
        if (sceneId == null ||
            catalog.resolveScene(sceneId).status !=
                NarrativeEventProjectResolutionStatus.found) {
          return const NarrativeEventValidationNavigationResult.stale(
            'La Scene ciblée n’existe plus dans le projet courant.',
          );
        }
        if (eventId != null && record == null) return _staleEvent();
        return NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.openScene,
            section: NarrativeEventValidationSection.scene,
            eventId: eventId,
            sceneId: sceneId,
          ),
        );
      case NarrativeEventValidationDestinationKind.claim:
        final claimId = destination.claimId;
        final exists = claimId != null &&
            registry.legacyClaims.any((claim) => claim.cohortId == claimId);
        if (!exists) {
          return const NarrativeEventValidationNavigationResult.stale(
            'Le lien de migration ciblé n’existe plus.',
          );
        }
        return NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.reviewClaim,
            section: NarrativeEventValidationSection.claim,
            eventId: eventId,
            claimId: claimId,
          ),
        );
    }
  }
}

({
  Map<String, List<NarrativeEventValidationDiagnostic>> byEvent,
  List<NarrativeEventValidationDiagnostic> global,
}) _partitionDiagnostics(
  Iterable<NarrativeEventValidationDiagnostic> diagnostics, {
  required Set<String> eventIds,
}) {
  final byEvent = {
    for (final eventId in eventIds)
      eventId: <NarrativeEventValidationDiagnostic>[],
  };
  final global = <NarrativeEventValidationDiagnostic>[];
  for (final diagnostic in diagnostics) {
    final eventId = diagnostic.eventId;
    if (eventId == null || !byEvent.containsKey(eventId)) {
      global.add(diagnostic);
    } else {
      byEvent[eventId]!.add(diagnostic);
    }
  }
  return (byEvent: byEvent, global: global);
}

String _eventValidationFingerprint(
  NarrativeEventRecord record, {
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
}) {
  final catalogDiagnostics = [
    for (final diagnostic in catalog.diagnostics)
      if (_eventIdFromDiagnosticPath(diagnostic.path) == record.id)
        diagnostic.toDebugJson(),
  ]..sort(
      (left, right) => compareNarrativeEventUtf16(
        canonicalizeNarrativeEventJson(left),
        canonicalizeNarrativeEventJson(right),
      ),
    );
  final eventEntries = [
    for (final entry in catalog.events)
      if (entry.record.id == record.id) entry.toDebugJson(),
  ];
  final claims = [
    for (final claim in registry.legacyClaims)
      if (claim.targetEventIds.contains(record.id)) claim.toJson(),
  ];
  return narrativeEventCanonicalSha256({
    'record': record.toJson(),
    'catalogDiagnostics': catalogDiagnostics,
    'eventEntries': eventEntries,
    'claims': claims,
    if (claims.isNotEmpty)
      'claimUniverse': [
        for (final claim in registry.legacyClaims) claim.toJson(),
      ],
  });
}

String _globalValidationFingerprint({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
}) {
  return narrativeEventCanonicalSha256({
    'schemaVersion': registry.schemaVersion,
    'mode': registry.mode.name,
    'legacyClaims': [
      for (final claim in registry.legacyClaims) claim.toJson(),
    ],
    'catalogDiagnostics': [
      for (final diagnostic in catalog.diagnostics)
        if (_eventIdFromDiagnosticPath(diagnostic.path) == null)
          diagnostic.toDebugJson(),
    ],
  });
}

Set<String> _recordEventDependencies(NarrativeEventRecord record) {
  final conditions = record.when(
    draft: (draft) => draft.conditions,
    configured: (definition, _) => definition.conditions,
  );
  return {
    for (final condition in conditions)
      ...condition.when(
        fact: (_, __) => const <String>{},
        narrativeEventConsumed: (eventId, _) => {eventId},
      ),
  };
}

Set<String> _withTransitiveDependents(
  Set<String> directlyChanged, {
  required Map<String, Set<String>> currentDependencies,
  required Map<String, Set<String>> previousDependencies,
}) {
  final dependentsByEvent = <String, Set<String>>{};
  for (final dependencies in [currentDependencies, previousDependencies]) {
    for (final entry in dependencies.entries) {
      for (final dependencyId in entry.value) {
        dependentsByEvent
            .putIfAbsent(dependencyId, () => <String>{})
            .add(entry.key);
      }
    }
  }
  final invalidated = {...directlyChanged};
  final pending = [...directlyChanged];
  while (pending.isNotEmpty) {
    final eventId = pending.removeLast();
    for (final dependentId in dependentsByEvent[eventId] ?? const <String>{}) {
      if (invalidated.add(dependentId)) pending.add(dependentId);
    }
  }
  return invalidated;
}

String? _eventIdFromDiagnosticPath(String path) {
  const prefix = 'eventRegistry.records.';
  if (!path.startsWith(prefix)) return null;
  final remainder = path.substring(prefix.length);
  final separator = remainder.indexOf('.');
  return separator < 0 ? remainder : remainder.substring(0, separator);
}

bool _sameStringSet(Iterable<String> left, Iterable<String> right) {
  final leftSet = left.toSet();
  final rightSet = right.toSet();
  return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
}

NarrativeEventValidationNavigationResult _staleEvent() {
  return const NarrativeEventValidationNavigationResult.stale(
    'L’événement ciblé n’existe plus dans le projet courant.',
  );
}

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
}

bool _matchesSpatialDestination(
  NarrativeEventSourceRef source,
  NarrativeEventValidationDestination destination,
) {
  return source.when(
    entityInteract: (mapId, entityId) =>
        destination.mapId == mapId && destination.sourceOwnerId == entityId,
    triggerEnter: (mapId, triggerId) =>
        destination.mapId == mapId && destination.sourceOwnerId == triggerId,
    mapEnter: (mapId) =>
        destination.mapId == mapId && destination.sourceOwnerId == null,
    outcomeReceived: (_) => false,
  );
}
````


### A.10 — `packages/map_editor/lib/src/features/narrative/state/narrative_scene_focus_provider.dart`

````dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
final class NarrativeSceneFocusRequest {
  const NarrativeSceneFocusRequest({
    required this.sceneId,
    required this.nonce,
  });

  final String sceneId;
  final int nonce;
}

final class NarrativeSceneFocusController
    extends StateNotifier<NarrativeSceneFocusRequest?> {
  NarrativeSceneFocusController() : super(null);

  int _nonce = 0;

  void focus(String sceneId) {
    final normalized = sceneId.trim();
    if (normalized.isEmpty) return;
    state = NarrativeSceneFocusRequest(
      sceneId: normalized,
      nonce: ++_nonce,
    );
  }
}

final narrativeSceneFocusProvider = StateNotifierProvider<
    NarrativeSceneFocusController, NarrativeSceneFocusRequest?>((ref) {
  return NarrativeSceneFocusController();
});
````


### A.11 — `packages/map_editor/lib/src/application/models/narrative_event_migration_persistence_models.dart`

````dart
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

@immutable
final class NarrativeEventMigrationPreview {
  const NarrativeEventMigrationPreview({
    required this.projectPath,
    required this.projectRevision,
    required this.project,
    required this.plan,
  });

  final String projectPath;
  final String projectRevision;
  final ProjectManifest project;
  final NarrativeEventMigrationPlan plan;

  bool get canCommit => plan.canApply && receipt != null;
  NarrativeEventMigrationReceipt? get receipt => plan.receiptProposal;
  int get legacyItemCount => plan.items.length;
  int get proposedEventCount => plan.recordsProposed.length;
  int get proposedClaimCount => plan.claimsProposed.length;
  int get choiceCount => receipt?.sourceChoices.length ?? 0;
  EventSystemMode get modeBefore =>
      project.eventRegistry?.mode ?? EventSystemMode.legacyOnly;
  EventSystemMode get modeAfter => modeBefore;

  NarrativeEventRegistry get registryAfter {
    if (!canCommit) {
      throw StateError('Only a ready migration preview has a next registry.');
    }
    final before = project.eventRegistry;
    return NarrativeEventRegistry(
      schemaVersion: 1,
      mode: before?.mode ?? EventSystemMode.legacyOnly,
      records: [
        ...?before?.records,
        ...plan.recordsProposed,
      ],
      legacyClaims: [
        ...?before?.legacyClaims,
        ...plan.claimsProposed,
      ],
    );
  }
}

enum NarrativeEventMigrationPersistenceStatus {
  clear,
  committed,
  recovered,
  compensated,
  noOp,
  blocked,
  rejected,
  staleRevision,
  recoveryRequired,
  ioFailure,
}

enum NarrativeEventMigrationInspectionStatus {
  clear,
  recoveryRequired,
  committed,
  blocked,
}

enum NarrativeEventMigrationJournalState {
  prepared,
  committed,
  recovered,
  compensated,
}

enum NarrativeEventMigrationWriteCheckpoint {
  afterBackupWritten,
  afterReceiptWritten,
  afterJournalPrepared,
  afterProjectRenamed,
  afterJournalCommitted,
}

typedef NarrativeEventMigrationFaultInjector = Future<void> Function(
  NarrativeEventMigrationWriteCheckpoint checkpoint,
);

@immutable
final class NarrativeEventMigrationCommitRequest {
  NarrativeEventMigrationCommitRequest({required this.preview}) {
    if (!preview.canCommit) {
      throw ArgumentError.value(preview.plan.status, 'preview');
    }
  }

  final NarrativeEventMigrationPreview preview;
}

@immutable
final class NarrativeEventMigrationCompensationRequest {
  const NarrativeEventMigrationCompensationRequest({
    required this.projectPath,
    required this.receiptId,
  });

  final String projectPath;
  final String receiptId;
}

@immutable
final class NarrativeEventMigrationPersistenceResult {
  const NarrativeEventMigrationPersistenceResult({
    required this.status,
    required this.code,
    required this.message,
    this.journalPath,
    this.receiptPath,
  });

  final NarrativeEventMigrationPersistenceStatus status;
  final String code;
  final String message;
  final String? journalPath;
  final String? receiptPath;

  bool get succeeded =>
      status == NarrativeEventMigrationPersistenceStatus.committed ||
      status == NarrativeEventMigrationPersistenceStatus.recovered ||
      status == NarrativeEventMigrationPersistenceStatus.compensated ||
      status == NarrativeEventMigrationPersistenceStatus.noOp;
}

@immutable
final class NarrativeEventMigrationInspection {
  const NarrativeEventMigrationInspection({
    required this.status,
    required this.code,
    required this.message,
    this.journalPath,
  });

  final NarrativeEventMigrationInspectionStatus status;
  final String code;
  final String message;
  final String? journalPath;
}
````


### A.12 — `packages/map_editor/lib/src/application/ports/narrative_event_migration_persistence_gateway.dart`

````dart
import '../models/narrative_event_migration_persistence_models.dart';

abstract interface class NarrativeEventMigrationPersistenceGateway {
  Future<NarrativeEventMigrationInspection> inspect(String projectPath);

  Future<NarrativeEventMigrationPersistenceResult> commit(
    NarrativeEventMigrationCommitRequest request,
  );

  Future<NarrativeEventMigrationPersistenceResult> recover(
    String projectPath,
  );

  Future<NarrativeEventMigrationPersistenceResult> compensate(
    NarrativeEventMigrationCompensationRequest request,
  );
}
````


### A.13 — `packages/map_editor/lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart`

````dart
import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_migration_persistence_models.dart';

/// Builds an attested migration plan without writing project bytes.
///
/// Auto-safe single-page legacy map Events can be proposed here, but the plan
/// deliberately preserves the current runtime mode. Activation remains a
/// separate, explicit product action after review and persistence.
final class NarrativeEventMigrationPreviewUseCase {
  NarrativeEventMigrationPreviewUseCase({
    NarrativeEventMigrationIdSource? ids,
    NarrativeEventMigrationClock? clock,
  })  : _ids = ids ?? _EditorMigrationIds(),
        _clock = clock ?? DateTime.now;

  final NarrativeEventMigrationIdSource _ids;
  final NarrativeEventMigrationClock _clock;

  Future<NarrativeEventMigrationPreview> preview(
    String projectPath, {
    NarrativeEventMigrationSnapshot? expectedSnapshot,
    List<int>? existingReceiptJsonBytes,
  }) async {
    final session = await NarrativeEventAuthoringSession.prepare(projectPath);
    final project = session.manifest;
    final registry = project.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        );
    final claimIndex = buildValidatedLegacyClaimIndex(registry);
    final mapProjections = <LegacyMapEventProjection>[];
    final sourceChoices = <NarrativeEventMigrationSourceChoice>[];
    for (final map in session.maps) {
      for (final event in map.events) {
        final projection = projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: map,
          event: event,
          claimIndex: claimIndex,
          rawEventJson: Map<String, Object?>.from(event.toJson()),
        );
        mapProjections.add(projection);
        final source = projection.confirmedSource;
        if (projection.classification ==
                LegacyMigrationClassification.autoSafe &&
            source != null &&
            projection.pages.length == 1 &&
            projection.pages.single.sceneId != null) {
          sourceChoices.add(
            NarrativeEventMigrationSourceChoice.confirmCandidate(
              provenance: projection.provenance,
              source: source,
              targets: [
                NarrativeEventMigrationTargetProposal(
                  name: event.title.trim().isEmpty ? event.id : event.title,
                  legacyPageIndex: projection.pages.single.pageIndex,
                  conditions: const [],
                  sceneId: projection.pages.single.sceneId,
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: projection.pages.single.pageIndex,
                ),
              ],
            ),
          );
        }
      }
    }
    final scenarioProjections = <LegacyScenarioSourceProjection>[
      for (final scenario in project.scenarios)
        for (final node in scenario.nodes)
          if (isLegacyScenarioSourceNode(node))
            projectLegacyScenarioSourceReadOnly(
              scenario: scenario,
              node: node,
              scenes: project.scenes,
              claimIndex: claimIndex,
            ),
    ];
    final referencedOutcomes = <NarrativeOutcomeRef>[
      for (final projection in scenarioProjections)
        if (projection.source != null)
          ...projection.source!.when(
            entityInteract: (_, __) => const <NarrativeOutcomeRef>[],
            triggerEnter: (_, __) => const <NarrativeOutcomeRef>[],
            mapEnter: (_) => const <NarrativeOutcomeRef>[],
            outcomeReceived: (outcome) => [outcome],
          ),
    ];
    final catalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: session.maps,
      legacyProjections: mapProjections,
      referencedOutcomes: referencedOutcomes,
    );
    final references = NarrativeEventReferenceCatalog.empty();
    final characterizedCorpus = <String, Object?>{
      'version': 'NS-EVENT-V2-I4-v0',
    };
    final snapshot = NarrativeEventMigrationSnapshot(
      projectRevisionToken: session.projectRevision,
      manifestHash: catalog.manifestHash,
      corpusHash: narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(characterizedCorpus),
      ),
      referenceCatalogHash: narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(references.toJson()),
      ),
      mapHashes: catalog.mapHashes,
      legacySourceHashes: {
        for (final projection in mapProjections)
          legacyMigrationSourceSnapshotKey(projection.provenance):
              projection.sourceFingerprint,
        for (final projection in scenarioProjections)
          legacyMigrationSourceSnapshotKey(projection.provenance):
              projection.sourceFingerprint,
      },
      saveHashes: const {},
    );
    final plan = NarrativeEventMigrationPlanner(
      ids: _ids,
      clock: _clock,
    ).plan(
      NarrativeEventMigrationPlannerInput(
        project: project,
        maps: session.maps,
        mapEventProjections: mapProjections,
        scenarioProjections: scenarioProjections,
        references: references,
        currentSnapshot: snapshot,
        expectedSnapshot: expectedSnapshot,
        choices: NarrativeEventMigrationChoices(
          sourceChoices: sourceChoices,
        ),
        characterizedCorpus: characterizedCorpus,
        saveSnapshots: const [],
        unknownLegacyData: const [],
        backupPlan: NarrativeEventMigrationBackupPlan(
          futureDestinations: const {
            'manifest': '.pokemap/event-migration/project.before.json',
            'receipt': '.pokemap/event-migration/receipt.json',
          },
        ),
        existingReceiptJsonBytes: existingReceiptJsonBytes,
        validationCatalog: catalog,
      ),
    );
    return NarrativeEventMigrationPreview(
      projectPath: session.projectPath,
      projectRevision: session.projectRevision,
      project: project,
      plan: plan,
    );
  }
}

final class _EditorMigrationIds implements NarrativeEventMigrationIdSource {
  final NarrativeEventIdGenerator _generator = NarrativeEventIdGenerator();

  @override
  String nextEventId() => _generator.generate(existingRecords: const []);

  @override
  String nextReceiptId() {
    final eventId = _generator.generate(existingRecords: const []);
    return 'evmr_${eventId.substring(4)}';
  }
}
````


### A.14 — `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart`

````dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_event_migration_persistence_models.dart';
import '../../application/models/narrative_event_registry_persistence_models.dart';
import '../../application/ports/narrative_event_migration_persistence_gateway.dart';
import 'narrative_event_registry_persistence.dart';
import 'project_manifest_write_lock.dart';

/// Persists one reviewed migration with byte backup and a durable journal.
///
/// Each file is written atomically, but the multi-file sequence is not claimed
/// to be transactional. Recovery inspects the prepared journal, and
/// compensation restores the backup only while every revision, receipt,
/// ownership and semantic fingerprint guard still matches.
final class NarrativeEventMigrationPersistenceRepository
    implements NarrativeEventMigrationPersistenceGateway {
  NarrativeEventMigrationPersistenceRepository({
    this.faultInjector,
    NarrativeEventRegistryPersistence? registryPersistence,
  }) : _registryPersistence =
            registryPersistence ?? NarrativeEventRegistryPersistence();

  final NarrativeEventMigrationFaultInjector? faultInjector;
  final NarrativeEventRegistryPersistence _registryPersistence;

  @override
  Future<NarrativeEventMigrationInspection> inspect(String projectPath) async {
    return withProjectManifestWriteLock(
      projectPath,
      () => _inspectLocked(projectPath),
    );
  }

  @override
  Future<NarrativeEventMigrationPersistenceResult> commit(
    NarrativeEventMigrationCommitRequest request,
  ) async {
    final preview = request.preview;
    try {
      return await withProjectManifestWriteLock(preview.projectPath, () async {
        final inspection = await _inspectLocked(preview.projectPath);
        if (inspection.status !=
            NarrativeEventMigrationInspectionStatus.clear) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.blocked,
            'migrationRecoveryGate',
            inspection.message,
            journalPath: inspection.journalPath,
          );
        }
        final projectFile = File(preview.projectPath);
        final beforeBytes = await projectFile.readAsBytes();
        final beforeRevision = narrativeEventBytesFingerprint(beforeBytes);
        final receipt = preview.receipt!;
        if (beforeRevision != preview.projectRevision ||
            beforeRevision != receipt.snapshot.projectRevisionToken) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.staleRevision,
            'staleProjectRevision',
            'Le projet a changé depuis la prévisualisation.',
          );
        }
        final nextRegistry = preview.registryAfter;
        final nextProject = preview.project.copyWith(
          eventRegistry: nextRegistry,
        );
        ProjectValidator.validate(nextProject);
        final expectedManifestHash = _semanticHash(nextProject.toJson());
        final expectedRegistryHash = _semanticHash(nextRegistry.toJson());
        if (expectedManifestHash != receipt.expectedManifestHashAfter ||
            expectedRegistryHash != receipt.expectedRegistryHashAfter) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.rejected,
            'receiptTargetMismatch',
            'Le résultat proposé ne correspond plus au receipt attesté.',
          );
        }

        final currentRoot = _jsonObject(
          decodeNarrativeEventJsonStrict(utf8.decode(beforeBytes)),
        );
        final nextRoot = Map<String, Object?>.from(currentRoot)
          ..['eventRegistry'] = nextRegistry.toJson();
        canonicalizeNarrativeEventJson(nextRoot);
        final nextBytes = utf8.encode(
          const JsonEncoder.withIndent('  ').convert(nextRoot),
        );
        final paths = _paths(preview.projectPath, receipt.receiptId);
        await Directory(paths.directory).create(recursive: true);
        await _writeAtomic(paths.backup, beforeBytes);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterBackupWritten,
        );
        final receiptBytes = utf8.encode(
          const JsonEncoder.withIndent('  ').convert(receipt.toJson()),
        );
        await _writeAtomic(paths.receipt, receiptBytes);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterReceiptWritten,
        );
        final journal = _MigrationJournal(
          receiptId: receipt.receiptId,
          projectPath: p.normalize(preview.projectPath),
          state: NarrativeEventMigrationJournalState.prepared,
          beforeRevision: beforeRevision,
          afterRevision: narrativeEventBytesFingerprint(nextBytes),
          backupHash: narrativeEventBytesFingerprint(beforeBytes),
          receiptHash: narrativeEventBytesFingerprint(receiptBytes),
          expectedManifestHashAfter: receipt.expectedManifestHashAfter,
          expectedRegistryHashAfter: receipt.expectedRegistryHashAfter,
          ownerFingerprint: _ownerFingerprint(
            receiptId: receipt.receiptId,
            projectPath: p.normalize(preview.projectPath),
            beforeRevision: beforeRevision,
            expectedManifestHashAfter: receipt.expectedManifestHashAfter,
          ),
        );
        await _writeJournal(paths.journal, journal);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterJournalPrepared,
        );
        if (narrativeEventBytesFingerprint(await projectFile.readAsBytes()) !=
            beforeRevision) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.recoveryRequired,
            'projectChangedAfterJournal',
            'Le projet a changé après la préparation du journal.',
            journalPath: paths.journal,
            receiptPath: paths.receipt,
          );
        }
        await _writeAtomic(preview.projectPath, nextBytes);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterProjectRenamed,
        );
        final committed = journal.withState(
          NarrativeEventMigrationJournalState.committed,
        );
        await _writeJournal(paths.journal, committed);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterJournalCommitted,
        );
        return _result(
          NarrativeEventMigrationPersistenceStatus.committed,
          'migrationCommitted',
          'Les événements V2 et leurs liens sont enregistrés; le mode runtime reste inchangé.',
          journalPath: paths.journal,
          receiptPath: paths.receipt,
        );
      });
    } on Object catch (error) {
      final receiptId = preview.receipt?.receiptId;
      final paths =
          receiptId == null ? null : _paths(preview.projectPath, receiptId);
      final prepared = paths != null && await File(paths.journal).exists();
      return _result(
        prepared
            ? NarrativeEventMigrationPersistenceStatus.recoveryRequired
            : NarrativeEventMigrationPersistenceStatus.ioFailure,
        prepared ? 'preparedMigrationInterrupted' : 'migrationIoFailure',
        'La migration a été interrompue: $error',
        journalPath: paths?.journal,
        receiptPath: paths?.receipt,
      );
    }
  }

  @override
  Future<NarrativeEventMigrationPersistenceResult> recover(
    String projectPath,
  ) async {
    try {
      return await withProjectManifestWriteLock(projectPath, () async {
        final registryGate = await _registryRecoveryGate(projectPath);
        if (registryGate != null) return registryGate;
        final journalEntry = await _singleJournal(projectPath);
        if (journalEntry == null) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.noOp,
            'noMigrationRecovery',
            'Aucune migration interrompue n’est présente.',
          );
        }
        final (journalPath, journal) = journalEntry;
        if (journal.state != NarrativeEventMigrationJournalState.prepared) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.noOp,
            'migrationAlreadyTerminal',
            'Le journal de migration est déjà dans un état terminal.',
            journalPath: journalPath,
          );
        }
        if (!_safeReceiptId(journal.receiptId)) {
          return _blocked('invalidReceiptId', journalPath);
        }
        final paths = _paths(projectPath, journal.receiptId);
        final evidenceFailure = await _migrationEvidenceFailure(
          journal: journal,
          paths: paths,
          projectPath: projectPath,
        );
        if (evidenceFailure != null) {
          return _blocked(evidenceFailure, journalPath);
        }
        final currentRevision = narrativeEventBytesFingerprint(
          await File(projectPath).readAsBytes(),
        );
        if (currentRevision == journal.beforeRevision) {
          await _writeJournal(
            journalPath,
            journal.withState(NarrativeEventMigrationJournalState.recovered),
          );
          return _result(
            NarrativeEventMigrationPersistenceStatus.recovered,
            'preparedMigrationRolledBack',
            'La migration interrompue a été refermée sans modifier le projet.',
            journalPath: journalPath,
            receiptPath: paths.receipt,
          );
        }
        if (currentRevision == journal.afterRevision) {
          final currentProject = ProjectManifest.fromJson(
            Map<String, dynamic>.from(
              _jsonObject(
                decodeNarrativeEventJsonStrict(
                  await File(projectPath).readAsString(),
                ),
              ),
            ),
          );
          if (_semanticHash(currentProject.toJson()) !=
                  journal.expectedManifestHashAfter ||
              _semanticHash(currentProject.eventRegistry?.toJson()) !=
                  journal.expectedRegistryHashAfter) {
            return _blocked('migrationFingerprintMismatch', journalPath);
          }
          await _writeJournal(
            journalPath,
            journal.withState(NarrativeEventMigrationJournalState.committed),
          );
          return _result(
            NarrativeEventMigrationPersistenceStatus.recovered,
            'preparedMigrationFinalized',
            'La migration appliquée a été finalisée.',
            journalPath: journalPath,
            receiptPath: paths.receipt,
          );
        }
        return _blocked('projectRevisionDiverged', journalPath);
      });
    } on Object catch (error) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.ioFailure,
        'migrationRecoveryFailure',
        'La récupération a échoué: $error',
      );
    }
  }

  @override
  Future<NarrativeEventMigrationPersistenceResult> compensate(
    NarrativeEventMigrationCompensationRequest request,
  ) async {
    if (!_safeReceiptId(request.receiptId)) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.blocked,
        'invalidReceiptId',
        'Le receipt demandé est invalide.',
      );
    }
    try {
      return await withProjectManifestWriteLock(request.projectPath, () async {
        final registryGate = await _registryRecoveryGate(request.projectPath);
        if (registryGate != null) return registryGate;
        final paths = _paths(request.projectPath, request.receiptId);
        if (!await File(paths.journal).exists()) {
          return _blocked('migrationJournalMissing', paths.journal);
        }
        final journal = await _readJournal(paths.journal);
        if (journal.state != NarrativeEventMigrationJournalState.committed) {
          return _blocked('migrationNotCommitted', paths.journal);
        }
        if (journal.receiptId != request.receiptId) {
          return _blocked('migrationReceiptMismatch', paths.journal);
        }
        final evidenceFailure = await _migrationEvidenceFailure(
          journal: journal,
          paths: paths,
          projectPath: request.projectPath,
        );
        if (evidenceFailure != null) {
          return _blocked(evidenceFailure, paths.journal);
        }
        final backupBytes = await File(paths.backup).readAsBytes();
        final currentBytes = await File(request.projectPath).readAsBytes();
        if (narrativeEventBytesFingerprint(currentBytes) !=
            journal.afterRevision) {
          return _blocked('projectRevisionDiverged', paths.journal);
        }
        final currentProject = ProjectManifest.fromJson(
          Map<String, dynamic>.from(
            _jsonObject(
              decodeNarrativeEventJsonStrict(utf8.decode(currentBytes)),
            ),
          ),
        );
        if (_semanticHash(currentProject.toJson()) !=
                journal.expectedManifestHashAfter ||
            _semanticHash(currentProject.eventRegistry?.toJson()) !=
                journal.expectedRegistryHashAfter) {
          return _blocked('migrationFingerprintMismatch', paths.journal);
        }
        await _writeAtomic(request.projectPath, backupBytes);
        await _writeJournal(
          paths.journal,
          journal.withState(
            NarrativeEventMigrationJournalState.compensated,
          ),
        );
        return _result(
          NarrativeEventMigrationPersistenceStatus.compensated,
          'migrationCompensated',
          'Le projet a été restauré à ses octets antérieurs.',
          journalPath: paths.journal,
          receiptPath: paths.receipt,
        );
      });
    } on Object catch (error) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.blocked,
        'compensationPrerequisiteMissing',
        'La compensation est bloquée: $error',
      );
    }
  }

  Future<NarrativeEventMigrationInspection> _inspectLocked(
    String projectPath,
  ) async {
    try {
      final registryInspection =
          await _registryPersistence.inspectProjectAlreadyLocked(projectPath);
      if (registryInspection.status !=
          NarrativeEventRegistryRecoveryGateStatus.clear) {
        return NarrativeEventMigrationInspection(
          status: NarrativeEventMigrationInspectionStatus.blocked,
          code: 'eventRegistryRecoveryGate',
          message: registryInspection.issues.isEmpty
              ? 'Une écriture Event doit être récupérée avant la migration.'
              : registryInspection.issues.first.message,
          journalPath: registryInspection.issues
              .map((issue) => issue.path)
              .whereType<String>()
              .firstOrNull,
        );
      }
      final entries = await _journalFiles(projectPath);
      if (entries.isEmpty) {
        return const NarrativeEventMigrationInspection(
          status: NarrativeEventMigrationInspectionStatus.clear,
          code: 'clear',
          message: 'Aucun journal de migration en attente.',
        );
      }
      if (entries.length != 1) {
        return NarrativeEventMigrationInspection(
          status: NarrativeEventMigrationInspectionStatus.blocked,
          code: 'multipleMigrationJournals',
          message: 'Plusieurs journaux de migration exigent une inspection.',
          journalPath: entries.first,
        );
      }
      final journal = await _readJournal(entries.single);
      final status = switch (journal.state) {
        NarrativeEventMigrationJournalState.prepared =>
          NarrativeEventMigrationInspectionStatus.recoveryRequired,
        NarrativeEventMigrationJournalState.committed =>
          NarrativeEventMigrationInspectionStatus.committed,
        NarrativeEventMigrationJournalState.recovered ||
        NarrativeEventMigrationJournalState.compensated =>
          NarrativeEventMigrationInspectionStatus.clear,
      };
      return NarrativeEventMigrationInspection(
        status: status,
        code: journal.state.name,
        message:
            status == NarrativeEventMigrationInspectionStatus.recoveryRequired
                ? 'Une migration préparée doit être récupérée.'
                : 'Le journal de migration est ${journal.state.name}.',
        journalPath: entries.single,
      );
    } on Object catch (error) {
      return NarrativeEventMigrationInspection(
        status: NarrativeEventMigrationInspectionStatus.blocked,
        code: 'invalidMigrationJournal',
        message: 'Le journal de migration est illisible: $error',
      );
    }
  }

  Future<(String, _MigrationJournal)?> _singleJournal(
    String projectPath,
  ) async {
    final files = await _journalFiles(projectPath);
    if (files.length != 1) return null;
    return (files.single, await _readJournal(files.single));
  }

  Future<List<String>> _journalFiles(String projectPath) async {
    final root = Directory(
      p.join(p.dirname(projectPath), '.pokemap', 'event-migration'),
    );
    if (!await root.exists()) return const [];
    final result = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && p.basename(entity.path) == 'journal.json') {
        result.add(p.normalize(entity.path));
      }
    }
    result.sort(compareNarrativeEventUtf16);
    return result;
  }

  Future<void> _fault(NarrativeEventMigrationWriteCheckpoint checkpoint) async {
    await faultInjector?.call(checkpoint);
  }

  Future<NarrativeEventMigrationPersistenceResult?> _registryRecoveryGate(
    String projectPath,
  ) async {
    final inspection =
        await _registryPersistence.inspectProjectAlreadyLocked(projectPath);
    if (inspection.status == NarrativeEventRegistryRecoveryGateStatus.clear) {
      return null;
    }
    return _result(
      NarrativeEventMigrationPersistenceStatus.blocked,
      'eventRegistryRecoveryGate',
      inspection.issues.isEmpty
          ? 'Une écriture Event doit être récupérée avant cette opération.'
          : inspection.issues.first.message,
      journalPath: inspection.issues
          .map((issue) => issue.path)
          .whereType<String>()
          .firstOrNull,
    );
  }
}

Future<String?> _migrationEvidenceFailure({
  required _MigrationJournal journal,
  required _MigrationPaths paths,
  required String projectPath,
}) async {
  if (journal.projectPath != p.normalize(projectPath) ||
      journal.ownerFingerprint !=
          _ownerFingerprint(
            receiptId: journal.receiptId,
            projectPath: journal.projectPath,
            beforeRevision: journal.beforeRevision,
            expectedManifestHashAfter: journal.expectedManifestHashAfter,
          )) {
    return 'migrationOwnershipMismatch';
  }
  final receiptBytes = await File(paths.receipt).readAsBytes();
  final receipt =
      decodeNarrativeEventMigrationReceiptStrict(receiptBytes).receiptOrNull;
  if (receipt == null ||
      receipt.receiptId != journal.receiptId ||
      narrativeEventBytesFingerprint(receiptBytes) != journal.receiptHash) {
    return 'migrationReceiptMismatch';
  }
  if (receipt.snapshot.projectRevisionToken != journal.beforeRevision ||
      receipt.expectedManifestHashAfter != journal.expectedManifestHashAfter ||
      receipt.expectedRegistryHashAfter != journal.expectedRegistryHashAfter) {
    return 'migrationReceiptMismatch';
  }
  final backupBytes = await File(paths.backup).readAsBytes();
  final backupRevision = narrativeEventBytesFingerprint(backupBytes);
  if (backupRevision != journal.backupHash ||
      backupRevision != journal.beforeRevision) {
    return 'backupHashMismatch';
  }
  return null;
}

final class _MigrationPaths {
  const _MigrationPaths({
    required this.directory,
    required this.journal,
    required this.receipt,
    required this.backup,
  });

  final String directory;
  final String journal;
  final String receipt;
  final String backup;
}

_MigrationPaths _paths(String projectPath, String receiptId) {
  final directory = p.join(
    p.dirname(projectPath),
    '.pokemap',
    'event-migration',
    receiptId,
  );
  return _MigrationPaths(
    directory: directory,
    journal: p.join(directory, 'journal.json'),
    receipt: p.join(directory, 'receipt.json'),
    backup: p.join(directory, 'project.before.json'),
  );
}

final class _MigrationJournal {
  const _MigrationJournal({
    required this.receiptId,
    required this.projectPath,
    required this.state,
    required this.beforeRevision,
    required this.afterRevision,
    required this.backupHash,
    required this.receiptHash,
    required this.expectedManifestHashAfter,
    required this.expectedRegistryHashAfter,
    required this.ownerFingerprint,
  });

  factory _MigrationJournal.fromJson(Map<String, Object?> json) {
    String value(String key) {
      final result = json[key];
      if (result is! String || result.isEmpty) {
        throw FormatException('Invalid journal field $key.');
      }
      return result;
    }

    return _MigrationJournal(
      receiptId: value('receiptId'),
      projectPath: value('projectPath'),
      state: NarrativeEventMigrationJournalState.values.byName(value('state')),
      beforeRevision: value('beforeRevision'),
      afterRevision: value('afterRevision'),
      backupHash: value('backupHash'),
      receiptHash: value('receiptHash'),
      expectedManifestHashAfter: value('expectedManifestHashAfter'),
      expectedRegistryHashAfter: value('expectedRegistryHashAfter'),
      ownerFingerprint: value('ownerFingerprint'),
    );
  }

  final String receiptId;
  final String projectPath;
  final NarrativeEventMigrationJournalState state;
  final String beforeRevision;
  final String afterRevision;
  final String backupHash;
  final String receiptHash;
  final String expectedManifestHashAfter;
  final String expectedRegistryHashAfter;
  final String ownerFingerprint;

  _MigrationJournal withState(NarrativeEventMigrationJournalState value) {
    return _MigrationJournal(
      receiptId: receiptId,
      projectPath: projectPath,
      state: value,
      beforeRevision: beforeRevision,
      afterRevision: afterRevision,
      backupHash: backupHash,
      receiptHash: receiptHash,
      expectedManifestHashAfter: expectedManifestHashAfter,
      expectedRegistryHashAfter: expectedRegistryHashAfter,
      ownerFingerprint: ownerFingerprint,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'receiptId': receiptId,
        'projectPath': projectPath,
        'state': state.name,
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'backupHash': backupHash,
        'receiptHash': receiptHash,
        'expectedManifestHashAfter': expectedManifestHashAfter,
        'expectedRegistryHashAfter': expectedRegistryHashAfter,
        'ownerFingerprint': ownerFingerprint,
      };
}

Future<_MigrationJournal> _readJournal(String path) async {
  return _MigrationJournal.fromJson(
    _jsonObject(
      decodeNarrativeEventJsonStrict(await File(path).readAsString()),
    ),
  );
}

Future<void> _writeJournal(String path, _MigrationJournal journal) {
  return _writeAtomic(
    path,
    utf8.encode(const JsonEncoder.withIndent('  ').convert(journal.toJson())),
  );
}

Future<void> _writeAtomic(String path, List<int> bytes) async {
  final target = File(path);
  await target.parent.create(recursive: true);
  final temp = File('$path.rewrite.tmp');
  if (await temp.exists()) await temp.delete();
  await temp.writeAsBytes(bytes, flush: true);
  await temp.rename(path);
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  return <String, Object?>{
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

String _semanticHash(Object? value) =>
    'sha256:${narrativeEventCanonicalSha256(value)}';

String _ownerFingerprint({
  required String receiptId,
  required String projectPath,
  required String beforeRevision,
  required String expectedManifestHashAfter,
}) =>
    _semanticHash({
      'receiptId': receiptId,
      'projectPath': projectPath,
      'beforeRevision': beforeRevision,
      'expectedManifestHashAfter': expectedManifestHashAfter,
    });

bool _safeReceiptId(String value) =>
    RegExp(r'^evmr_[0-9a-f-]+$').hasMatch(value) && p.basename(value) == value;

NarrativeEventMigrationPersistenceResult _blocked(
  String code,
  String journalPath,
) {
  return _result(
    NarrativeEventMigrationPersistenceStatus.blocked,
    code,
    'La précondition de compensation « $code » n’est plus satisfaite.',
    journalPath: journalPath,
  );
}

NarrativeEventMigrationPersistenceResult _result(
  NarrativeEventMigrationPersistenceStatus status,
  String code,
  String message, {
  String? journalPath,
  String? receiptPath,
}) {
  return NarrativeEventMigrationPersistenceResult(
    status: status,
    code: code,
    message: message,
    journalPath: journalPath,
    receiptPath: receiptPath,
  );
}
````


### A.15 — `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_migration_sheet.dart`

````dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/narrative_event_migration_persistence_models.dart';
import '../../design_system/design_system.dart';

class EventBuilderV2MigrationSheet extends StatefulWidget {
  const EventBuilderV2MigrationSheet({
    super.key,
    required this.preview,
    required this.onCancel,
    required this.onCommit,
    this.onRecover,
  });

  final NarrativeEventMigrationPreview preview;
  final VoidCallback onCancel;
  final Future<NarrativeEventMigrationPersistenceResult> Function() onCommit;
  final Future<NarrativeEventMigrationPersistenceResult> Function()? onRecover;

  @override
  State<EventBuilderV2MigrationSheet> createState() =>
      _EventBuilderV2MigrationSheetState();
}

class _EventBuilderV2MigrationSheetState
    extends State<EventBuilderV2MigrationSheet> {
  bool _working = false;
  NarrativeEventMigrationPersistenceResult? _result;

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final blockers = preview.plan.diagnostics.where(
      (diagnostic) =>
          diagnostic.severity == LegacyMigrationDiagnosticSeverity.error,
    );
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-v2-migration-sheet'),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Préparer les événements V2',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'PokeMap convertit les événements historiques à partir des '
            'éléments déjà présents dans vos maps. Aucun JSON n’est demandé.',
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          PokeMapCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MigrationCount(
                  icon: CupertinoIcons.bolt_circle,
                  label: _countLabel(
                    preview.proposedEventCount,
                    singular: 'événement à créer',
                    plural: 'événements à créer',
                  ),
                ),
                const SizedBox(height: 8),
                _MigrationCount(
                  icon: CupertinoIcons.link,
                  label: _countLabel(
                    preview.proposedClaimCount,
                    singular: 'lien de compatibilité',
                    plural: 'liens de compatibilité',
                  ),
                ),
                const SizedBox(height: 8),
                _MigrationCount(
                  icon: CupertinoIcons.checkmark_shield,
                  label: _countLabel(
                    preview.choiceCount,
                    singular: 'correspondance confirmée',
                    plural: 'correspondances confirmées',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            title: 'Activation séparée',
            message: 'Après cette préparation, le mode de jeu reste inchangé. '
                'Les nouveaux événements restent désactivés jusqu’à leur '
                'validation explicite.',
          ),
          if (blockers.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final blocker in blockers) ...[
              PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.error,
                title: 'Conversion bloquée',
                message: blocker.message,
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (_result != null) ...[
            const SizedBox(height: 12),
            PokeMapDiagnosticCallout(
              key: const ValueKey('event-migration-result'),
              severity: _result!.succeeded
                  ? PokeMapDiagnosticSeverity.info
                  : PokeMapDiagnosticSeverity.warning,
              title:
                  _result!.succeeded ? 'Opération terminée' : 'Action requise',
              message: _result!.message,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey('event-migration-cancel'),
                  onPressed: _working ? null : widget.onCancel,
                  variant: PokeMapButtonVariant.ghost,
                  child: const Text('Annuler'),
                ),
              ),
              if (widget.onRecover != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('event-migration-recover'),
                    onPressed: _working ? null : _recover,
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Récupérer'),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey('event-migration-commit'),
                  onPressed: !_working && preview.canCommit ? _commit : null,
                  variant: PokeMapButtonVariant.primary,
                  leading: _working
                      ? const CupertinoActivityIndicator()
                      : const Icon(CupertinoIcons.arrow_right_circle_fill),
                  child: const Text('Préparer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _commit() async {
    setState(() => _working = true);
    final result = await widget.onCommit();
    if (!mounted) return;
    setState(() {
      _working = false;
      _result = result;
    });
  }

  Future<void> _recover() async {
    setState(() => _working = true);
    final result = await widget.onRecover!();
    if (!mounted) return;
    setState(() {
      _working = false;
      _result = result;
    });
  }
}

class _MigrationCount extends StatelessWidget {
  const _MigrationCount({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _countLabel(
  int count, {
  required String singular,
  required String plural,
}) =>
    '$count ${count == 1 ? singular : plural}';
````


### A.16 — `packages/map_editor/test/narrative_event_validation_coordinator_test.dart`

````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_event_validation_coordinator.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_validation_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../map_core/test/support/narrative_event_authoring_fixtures.dart';
import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('I3 narrative Event validation coordinator', () {
    test('groups the core report without recomputing diagnostics', () {
      final eventDiagnostic = _diagnostic(
        eventId: eventIdA,
        kind: NarrativeEventValidationDestinationKind.event,
      );
      final globalDiagnostic = NarrativeEventValidationDiagnostic(
        code: 'registryIssue',
        severity: NarrativeEventValidationSeverity.warning,
        path: 'eventRegistry',
        message: 'Registre à vérifier.',
        action: NarrativeEventValidationAction.reviewRegistry,
        destination: NarrativeEventValidationDestination(
          kind: NarrativeEventValidationDestinationKind.registry,
        ),
      );
      final state = NarrativeEventValidationState.fromReport(
        NarrativeEventValidationReport(
          diagnostics: [globalDiagnostic, eventDiagnostic],
        ),
      );

      expect(state.forEvent(eventIdA).single.diagnostic, same(eventDiagnostic));
      expect(state.global.single.diagnostic, same(globalDiagnostic));
    });

    test('resolves exact Event, Map, Scene and claim destinations', () {
      final record = configuredRecord(id: eventIdA, enabled: true);
      final claim = authoringClaim(targetEventIds: [eventIdA]);
      final registry = registryWithRecords(
        [record],
        claims: [claim],
      );
      final catalog = authoringCatalogForRegistry(
        registry,
        scenes: [sceneEntry()],
      );
      const coordinator = NarrativeEventValidationCoordinator();

      final event = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.eventSource,
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(event.status, NarrativeEventValidationNavigationStatus.ready);
      expect(event.command!.kind,
          NarrativeEventValidationNavigationKind.selectEvent);
      expect(event.command!.selectedStableKey, 'v2:$eventIdA');
      expect(event.command!.section, NarrativeEventValidationSection.source);

      final eventScene = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.eventScene,
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(eventScene.command!.kind,
          NarrativeEventValidationNavigationKind.selectEvent);
      expect(
        eventScene.command!.section,
        NarrativeEventValidationSection.scene,
      );

      final map = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.mapSource,
          mapId: 'map_a',
          sourceOwnerId: 'npc_a',
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(map.command!.kind,
          NarrativeEventValidationNavigationKind.openMapSource);
      expect(map.command!.mapId, 'map_a');
      expect(map.command!.sourceOwnerId, 'npc_a');

      final scene = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.scene,
          sceneId: 'scene_a',
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(scene.command!.kind,
          NarrativeEventValidationNavigationKind.openScene);
      expect(scene.command!.sceneId, 'scene_a');

      final claimResult = coordinator.resolve(
        diagnostic: NarrativeEventValidationDiagnostic(
          code: 'claimIssue',
          severity: NarrativeEventValidationSeverity.error,
          eventId: eventIdA,
          path: 'eventRegistry.legacyClaims.${claim.cohortId}',
          message: 'Claim invalide.',
          action: NarrativeEventValidationAction.reviewClaim,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.claim,
            claimId: claim.cohortId,
            eventId: eventIdA,
          ),
        ),
        registry: registry,
        catalog: catalog,
      );
      expect(claimResult.command!.kind,
          NarrativeEventValidationNavigationKind.reviewClaim);
    });

    test('returns staleDestination without throwing after deletion', () {
      final registry = registryWithRecords([configuredRecord(id: eventIdA)]);
      const coordinator = NarrativeEventValidationCoordinator();
      final result = coordinator.resolve(
        diagnostic: _diagnostic(
          eventId: eventIdA,
          kind: NarrativeEventValidationDestinationKind.scene,
          sceneId: 'scene_deleted',
        ),
        registry: registry,
        catalog: authoringCatalogForRegistry(registry),
      );

      expect(
        result.status,
        NarrativeEventValidationNavigationStatus.staleDestination,
      );
      expect(result.command, isNull);
      expect(result.message, contains('n’existe plus'));
    });

    test('production snapshot loader reuses its latest project cache',
        () async {
      final fixture = await createPersistenceFixture(
        registry: persistenceRegistry(mode: EventSystemMode.v2Only),
      );
      addTearDown(fixture.dispose);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
        projectRootPath: fixture.root.path,
        project: fixture.session.manifest,
      );
      final loader = container.read(
        narrativeEventValidationSnapshotLoaderProvider,
      );

      final initial = await loader(request);
      final unchanged = await loader(request);

      expect(initial.recalculatedEventIds, {persistenceEventA});
      expect(unchanged.recalculatedEventIds, isEmpty);
      expect(unchanged.report.toDebugJson(), initial.report.toDebugJson());
    });
  });
}

NarrativeEventValidationDiagnostic _diagnostic({
  required String eventId,
  required NarrativeEventValidationDestinationKind kind,
  String? mapId,
  String? sourceOwnerId,
  String? sceneId,
}) {
  return NarrativeEventValidationDiagnostic(
    code: 'testIssue',
    severity: NarrativeEventValidationSeverity.error,
    eventId: eventId,
    path: 'eventRegistry.records.$eventId',
    message: 'Diagnostic de test.',
    action: NarrativeEventValidationAction.openEvent,
    destination: NarrativeEventValidationDestination(
      kind: kind,
      eventId: eventId,
      mapId: mapId,
      sourceOwnerId: sourceOwnerId,
      sceneId: sceneId,
    ),
  );
}
````


### A.17 — `packages/map_editor/test/ui/canvas/event_builder_v2_validation_navigation_test.dart`

````dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_scene_focus_provider.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';

void main() {
  testWidgets('Scene validation destination focuses the exact Scene safely',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = ProjectManifest(
      name: 'Validation navigation',
      maps: const [],
      tilesets: const [],
      scenes: [_scene('scene_a'), _scene('scene_b')],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(editorNotifierProvider, (_, __) {});
    addTearDown(subscription.close);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.scenes,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          darkTheme: PokeMapTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: SizedBox(
              width: 1440,
              height: 900,
              child: NarrativeWorkspaceCanvas(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scenes-selected-summary-scene_a')),
      findsOneWidget,
    );

    container.read(narrativeSceneFocusProvider.notifier).focus('scene_b');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scenes-selected-summary-scene_b')),
      findsOneWidget,
    );

    container.read(narrativeSceneFocusProvider.notifier).focus('scene_deleted');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scenes-selected-summary-scene_b')),
      findsOneWidget,
    );
    expect(container.read(editorNotifierProvider).project, same(project));
  });
}

SceneAsset _scene(String id) {
  return SceneAsset(
    id: id,
    name: 'Scene $id',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}
````


### A.18 — `packages/map_editor/test/narrative_event_migration_preview_use_case_test.dart`

````dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_migration_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_migration_preview_use_case.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:path/path.dart' as p;

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('I4 migration preview and persistence', () {
    test('preview is byte-identical and exposes a complete planner summary',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();
      final preview = await _useCase().preview(fixture.projectPath);

      expect(await fixture.readBytes(), before);
      expect(preview.plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(preview.canCommit, isTrue);
      expect(preview.legacyItemCount, 1);
      expect(preview.proposedEventCount, 1);
      expect(preview.proposedClaimCount, 1);
      expect(preview.choiceCount, 1);
      expect(preview.receipt, isNotNull);
      expect(preview.modeBefore, EventSystemMode.legacyOnly);
      expect(preview.modeAfter, EventSystemMode.legacyOnly);
    });

    test('commit reloads reproducibly and compensation restores exact bytes',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();
      final preview = await _useCase().preview(fixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository();

      final committed = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );
      expect(
        committed.status,
        NarrativeEventMigrationPersistenceStatus.committed,
        reason: '${committed.code}: ${committed.message}',
      );
      final reloaded = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(reloaded.manifest.eventRegistry?.mode, EventSystemMode.legacyOnly);
      expect(reloaded.manifest.eventRegistry?.records, hasLength(1));
      expect(reloaded.manifest.eventRegistry?.legacyClaims, hasLength(1));

      final compensated = await repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: fixture.projectPath,
          receiptId: preview.receipt!.receiptId,
        ),
      );
      expect(
        compensated.status,
        NarrativeEventMigrationPersistenceStatus.compensated,
      );
      expect(await fixture.readBytes(), before);
    });

    test('recovers a prepared journal and blocks divergent compensation',
        () async {
      final recoveryFixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(recoveryFixture.dispose);
      final recoveryBefore = await recoveryFixture.readBytes();
      final recoveryPreview =
          await _useCase().preview(recoveryFixture.projectPath);
      final crashing = NarrativeEventMigrationPersistenceRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventMigrationWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated crash');
          }
        },
      );

      final interrupted = await crashing.commit(
        NarrativeEventMigrationCommitRequest(preview: recoveryPreview),
      );
      expect(
        interrupted.status,
        NarrativeEventMigrationPersistenceStatus.recoveryRequired,
        reason: '${interrupted.code}: ${interrupted.message}',
      );
      expect((await crashing.inspect(recoveryFixture.projectPath)).status,
          NarrativeEventMigrationInspectionStatus.recoveryRequired);
      final recovered = await crashing.recover(recoveryFixture.projectPath);
      expect(
          recovered.status, NarrativeEventMigrationPersistenceStatus.recovered);
      expect(await recoveryFixture.readBytes(), recoveryBefore);

      final divergentFixture =
          await createPersistenceFixture(map: _legacyMap());
      addTearDown(divergentFixture.dispose);
      final divergentPreview =
          await _useCase().preview(divergentFixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository();
      final committed = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: divergentPreview),
      );
      expect(committed.succeeded, isTrue);
      final file = File(divergentFixture.projectPath);
      await file.writeAsString(
        '${await file.readAsString()}\n',
        flush: true,
      );
      final divergentBytes = await file.readAsBytes();

      final blocked = await repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: divergentFixture.projectPath,
          receiptId: divergentPreview.receipt!.receiptId,
        ),
      );
      expect(blocked.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(blocked.code, 'projectRevisionDiverged');
      expect(await file.readAsBytes(), divergentBytes);
      expect(await File(committed.journalPath!).exists(), isTrue);
    });

    test('rejects a commit when project bytes changed after preview', () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final preview = await _useCase().preview(fixture.projectPath);
      final projectFile = File(fixture.projectPath);
      await projectFile.writeAsString(
        '${await projectFile.readAsString()}\n',
        flush: true,
      );
      final changedBytes = await projectFile.readAsBytes();

      final result = await NarrativeEventMigrationPersistenceRepository()
          .commit(NarrativeEventMigrationCommitRequest(preview: preview));

      expect(
        result.status,
        NarrativeEventMigrationPersistenceStatus.staleRevision,
      );
      expect(result.code, 'staleProjectRevision');
      expect(await projectFile.readAsBytes(), changedBytes);
    });

    test('finalizes an applied project after a crash before journal commit',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final preview = await _useCase().preview(fixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventMigrationWriteCheckpoint.afterProjectRenamed) {
            throw const FileSystemException('simulated applied crash');
          }
        },
      );

      final interrupted = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );
      expect(
        interrupted.status,
        NarrativeEventMigrationPersistenceStatus.recoveryRequired,
      );
      final recovered = await repository.recover(fixture.projectPath);
      expect(
        recovered.status,
        NarrativeEventMigrationPersistenceStatus.recovered,
      );
      expect(recovered.code, 'preparedMigrationFinalized');
      final reloaded = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      expect(reloaded.manifest.eventRegistry?.records, hasLength(1));
    });

    test('blocks recovery when prepared receipt evidence was altered',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();
      final preview = await _useCase().preview(fixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventMigrationWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated prepared crash');
          }
        },
      );
      final interrupted = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );
      final receiptFile = File(interrupted.receiptPath!);
      await receiptFile.writeAsString(
        '${await receiptFile.readAsString()}\n',
        flush: true,
      );

      final recovered = await repository.recover(fixture.projectPath);

      expect(
        recovered.status,
        NarrativeEventMigrationPersistenceStatus.blocked,
      );
      expect(recovered.code, 'migrationReceiptMismatch');
      expect(await fixture.readBytes(), before);
    });

    test('blocks an unsafe receipt path stored in a prepared journal',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final before = await fixture.readBytes();
      final preview = await _useCase().preview(fixture.projectPath);
      final repository = NarrativeEventMigrationPersistenceRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventMigrationWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated prepared crash');
          }
        },
      );
      final interrupted = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );
      await _mutateJson(interrupted.journalPath!, (json) {
        json['receiptId'] = '../outside';
      });

      final recovered = await repository.recover(fixture.projectPath);

      expect(
        recovered.status,
        NarrativeEventMigrationPersistenceStatus.blocked,
      );
      expect(recovered.code, 'invalidReceiptId');
      expect(await fixture.readBytes(), before);
    });

    test('blocks compensation when receipt evidence was altered', () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      final receiptFile = File(committed.result.receiptPath!);
      await receiptFile.writeAsString(
        '${await receiptFile.readAsString()}\n',
        flush: true,
      );

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'migrationReceiptMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('blocks compensation when backup evidence was altered', () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      final backupFile = File(
        p.join(
          p.dirname(committed.result.journalPath!),
          'project.before.json',
        ),
      );
      await backupFile.writeAsString(
        '${await backupFile.readAsString()}\n',
        flush: true,
      );

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'backupHashMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('blocks coordinated backup and journal hash tampering', () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      final backupFile = File(
        p.join(
          p.dirname(committed.result.journalPath!),
          'project.before.json',
        ),
      );
      await backupFile.writeAsString(
        '{"name":"backup falsifié"}',
        flush: true,
      );
      final forgedHash = narrativeEventBytesFingerprint(
        await backupFile.readAsBytes(),
      );
      await _mutateJson(committed.result.journalPath!, (json) {
        json['backupHash'] = forgedHash;
      });

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'backupHashMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('anchors coordinated journal revisions in the immutable receipt',
        () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      final backupFile = File(
        p.join(
          p.dirname(committed.result.journalPath!),
          'project.before.json',
        ),
      );
      await backupFile.writeAsString(
        '{"name":"backup entièrement falsifié"}',
        flush: true,
      );
      final forgedRevision = narrativeEventBytesFingerprint(
        await backupFile.readAsBytes(),
      );
      await _mutateJson(committed.result.journalPath!, (json) {
        json['backupHash'] = forgedRevision;
        json['beforeRevision'] = forgedRevision;
        json['ownerFingerprint'] = 'sha256:${narrativeEventCanonicalSha256({
              'receiptId': json['receiptId'],
              'projectPath': json['projectPath'],
              'beforeRevision': forgedRevision,
              'expectedManifestHashAfter': json['expectedManifestHashAfter'],
            })}';
      });

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'migrationReceiptMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('blocks compensation when journal ownership was altered', () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectBytes = await committed.fixture.readBytes();
      await _mutateJson(committed.result.journalPath!, (json) {
        json['ownerFingerprint'] =
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      });

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'migrationOwnershipMismatch');
      expect(await committed.fixture.readBytes(), projectBytes);
    });

    test('blocks compensation on semantic drift even with matching bytes hash',
        () async {
      final committed = await _committedFixture();
      addTearDown(committed.fixture.dispose);
      final projectFile = File(committed.fixture.projectPath);
      await _mutateJson(projectFile.path, (json) {
        json['name'] = 'Projet modifié après migration';
      });
      final changedBytes = await projectFile.readAsBytes();
      await _mutateJson(committed.result.journalPath!, (json) {
        json['afterRevision'] = narrativeEventBytesFingerprint(changedBytes);
      });

      final result = await committed.repository.compensate(
        NarrativeEventMigrationCompensationRequest(
          projectPath: committed.fixture.projectPath,
          receiptId: committed.preview.receipt!.receiptId,
        ),
      );

      expect(result.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(result.code, 'migrationFingerprintMismatch');
      expect(await projectFile.readAsBytes(), changedBytes);
    });

    test('blocks migration while the canonical registry gate needs recovery',
        () async {
      final fixture = await createPersistenceFixture(map: _legacyMap());
      addTearDown(fixture.dispose);
      final preview = await _useCase().preview(fixture.projectPath);
      final interruptedRegistry = await NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated registry crash');
          }
        },
      ).write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'i4_registry_recovery_gate',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      expect(
        interruptedRegistry.status,
        NarrativeEventRegistryPersistenceStatus.ioFailure,
      );
      final repository = NarrativeEventMigrationPersistenceRepository();

      final inspection = await repository.inspect(fixture.projectPath);
      final commit = await repository.commit(
        NarrativeEventMigrationCommitRequest(preview: preview),
      );

      expect(
        inspection.status,
        NarrativeEventMigrationInspectionStatus.blocked,
      );
      expect(inspection.code, 'eventRegistryRecoveryGate');
      expect(commit.status, NarrativeEventMigrationPersistenceStatus.blocked);
      expect(commit.code, 'migrationRecoveryGate');
    });
  });
}

Future<
    ({
      EventRegistryPersistenceFixture fixture,
      NarrativeEventMigrationPreview preview,
      NarrativeEventMigrationPersistenceRepository repository,
      NarrativeEventMigrationPersistenceResult result,
    })> _committedFixture() async {
  final fixture = await createPersistenceFixture(map: _legacyMap());
  final preview = await _useCase().preview(fixture.projectPath);
  final repository = NarrativeEventMigrationPersistenceRepository();
  final result = await repository.commit(
    NarrativeEventMigrationCommitRequest(preview: preview),
  );
  expect(result.status, NarrativeEventMigrationPersistenceStatus.committed);
  return (
    fixture: fixture,
    preview: preview,
    repository: repository,
    result: result,
  );
}

Future<void> _mutateJson(
  String path,
  void Function(Map<String, Object?> json) mutate,
) async {
  final file = File(path);
  final decoded = jsonDecode(await file.readAsString());
  final json = Map<String, Object?>.from(decoded as Map);
  mutate(json);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(json),
    flush: true,
  );
}

NarrativeEventMigrationPreviewUseCase _useCase() {
  return NarrativeEventMigrationPreviewUseCase(
    ids: _Ids(),
    clock: () => DateTime.utc(2026, 7, 17, 10),
  );
}

MapData _legacyMap() {
  return const MapData(
    id: 'map_a',
    name: 'Map A',
    size: GridSize(width: 8, height: 6),
    layers: [MapLayer.object(id: 'events', name: 'Events')],
    entities: [
      MapEntity(
        id: 'npc_a',
        name: 'NPC A',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'legacy_a',
        title: 'Rencontre legacy',
        position: EventPosition(layerId: 'events', x: 1, y: 1),
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'npc_a',
        },
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
          ),
        ],
      ),
    ],
  );
}

final class _Ids implements NarrativeEventMigrationIdSource {
  var _event = 0;
  var _receipt = 0;

  @override
  String nextEventId() {
    _event++;
    return 'evt_019abcde-0000-7000-8000-${_event.toString().padLeft(12, '0')}';
  }

  @override
  String nextReceiptId() {
    _receipt++;
    return 'evmr_019abcde-0000-7000-8000-${_receipt.toString().padLeft(12, '0')}';
  }
}
````


### A.19 — `packages/map_editor/test/ui/canvas/event_builder_v2_migration_sheet_test.dart`

````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_migration_persistence_models.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_migration_preview_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_migration_sheet.dart';

import '../../support/event_registry_persistence_fixtures.dart';

void main() {
  testWidgets('shows a no-code preview and cancel performs no write',
      (tester) async {
    late EventRegistryPersistenceFixture fixture;
    late List<int> before;
    late NarrativeEventMigrationPreview preview;
    await tester.runAsync(() async {
      fixture = await createPersistenceFixture(map: _legacyMap());
      before = await fixture.readBytes();
      preview = await NarrativeEventMigrationPreviewUseCase(
        ids: _Ids(),
        clock: () => DateTime.utc(2026, 7, 17, 10),
      ).preview(fixture.projectPath);
    });
    addTearDown(fixture.dispose);
    var cancelled = false;
    var commitCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: EventBuilderV2MigrationSheet(
            preview: preview,
            onCancel: () => cancelled = true,
            onCommit: () async {
              commitCalls++;
              return const NarrativeEventMigrationPersistenceResult(
                status: NarrativeEventMigrationPersistenceStatus.committed,
                code: 'committed',
                message: 'Migration enregistrée.',
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Préparer les événements V2'), findsOneWidget);
    expect(find.text('1 événement à créer'), findsOneWidget);
    expect(find.text('1 lien de compatibilité'), findsOneWidget);
    expect(find.textContaining('mode de jeu reste inchangé'), findsOneWidget);
    expect(find.textContaining('evmr_'), findsNothing);
    expect(
      tester.widget(find.byKey(const ValueKey('event-migration-commit'))),
      isA<Widget>(),
    );

    await tester.tap(find.byKey(const ValueKey('event-migration-cancel')));
    await tester.pump();
    expect(cancelled, isTrue);
    expect(commitCalls, 0);
    final after = await tester.runAsync(fixture.readBytes);
    expect(after, before);
  });

  testWidgets('commit reports a successful persisted migration',
      (tester) async {
    final prepared = await _preparePreview(tester);
    addTearDown(prepared.fixture.dispose);
    var commitCalls = 0;
    await _pumpSheet(
      tester,
      preview: prepared.preview,
      onCommit: () async {
        commitCalls++;
        return const NarrativeEventMigrationPersistenceResult(
          status: NarrativeEventMigrationPersistenceStatus.committed,
          code: 'migrationCommitted',
          message: 'Migration enregistrée.',
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('event-migration-commit')));
    await tester.pump();

    expect(commitCalls, 1);
    expect(
      find.byKey(const ValueKey('event-migration-result')),
      findsOneWidget,
    );
    expect(find.text('Opération terminée'), findsOneWidget);
    expect(find.text('Migration enregistrée.'), findsOneWidget);
  });

  testWidgets('recovery reports a fail-closed state without invoking commit',
      (tester) async {
    final prepared = await _preparePreview(tester);
    addTearDown(prepared.fixture.dispose);
    var commitCalls = 0;
    var recoveryCalls = 0;
    await _pumpSheet(
      tester,
      preview: prepared.preview,
      onCommit: () async {
        commitCalls++;
        return const NarrativeEventMigrationPersistenceResult(
          status: NarrativeEventMigrationPersistenceStatus.committed,
          code: 'unexpected',
          message: 'Ne doit pas être appelé.',
        );
      },
      onRecover: () async {
        recoveryCalls++;
        return const NarrativeEventMigrationPersistenceResult(
          status: NarrativeEventMigrationPersistenceStatus.blocked,
          code: 'backupHashMismatch',
          message: 'La récupération est bloquée.',
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('event-migration-recover')));
    await tester.pump();

    expect(recoveryCalls, 1);
    expect(commitCalls, 0);
    expect(find.text('Action requise'), findsOneWidget);
    expect(find.text('La récupération est bloquée.'), findsOneWidget);
  });
}

Future<
    ({
      EventRegistryPersistenceFixture fixture,
      NarrativeEventMigrationPreview preview,
    })> _preparePreview(WidgetTester tester) async {
  late EventRegistryPersistenceFixture fixture;
  late NarrativeEventMigrationPreview preview;
  await tester.runAsync(() async {
    fixture = await createPersistenceFixture(map: _legacyMap());
    preview = await NarrativeEventMigrationPreviewUseCase(
      ids: _Ids(),
      clock: () => DateTime.utc(2026, 7, 17, 10),
    ).preview(fixture.projectPath);
  });
  return (fixture: fixture, preview: preview);
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required NarrativeEventMigrationPreview preview,
  required Future<NarrativeEventMigrationPersistenceResult> Function() onCommit,
  Future<NarrativeEventMigrationPersistenceResult> Function()? onRecover,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: EventBuilderV2MigrationSheet(
          preview: preview,
          onCancel: () {},
          onCommit: onCommit,
          onRecover: onRecover,
        ),
      ),
    ),
  );
  await tester.pump();
}

MapData _legacyMap() {
  return const MapData(
    id: 'map_a',
    name: 'Map A',
    size: GridSize(width: 8, height: 6),
    layers: [MapLayer.object(id: 'events', name: 'Events')],
    entities: [
      MapEntity(
        id: 'npc_a',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'legacy_a',
        title: 'Rencontre legacy',
        position: EventPosition(layerId: 'events', x: 1, y: 1),
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'npc_a',
        },
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
          ),
        ],
      ),
    ],
  );
}

final class _Ids implements NarrativeEventMigrationIdSource {
  var event = 0;
  var receipt = 0;

  @override
  String nextEventId() =>
      'evt_019abcde-0000-7000-8000-${(++event).toString().padLeft(12, '0')}';

  @override
  String nextReceiptId() =>
      'evmr_019abcde-0000-7000-8000-${(++receipt).toString().padLeft(12, '0')}';
}
````


### A.20 — `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart`

````dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_event_validation_coordinator.dart';

const _recordCount = 500;
const _sourceCount = 100;
const _sceneCount = 50;
const _factCount = 100;
const _warmupIterations = 10;
const _measuredIterations = 50;
const _p95BudgetMicroseconds = 36000;

void main() {
  test(
    'incremental validation equals a full rebuild for Event, source, and '
    'Scene invalidation',
    () {
      const coordinator = NarrativeEventValidationCoordinator();
      final fixture = _ValidationFixture.create();
      final initial = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: fixture.catalog(),
      );

      final mutatedRegistry = fixture.registryWithRenamedEvent(0);
      final eventMutation = coordinator.rebuildIncrementally(
        registry: mutatedRegistry,
        catalog: fixture.catalog(registry: mutatedRegistry),
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        eventMutation,
        registry: mutatedRegistry,
        catalog: fixture.catalog(registry: mutatedRegistry),
      );
      expect(
        eventMutation.recalculatedEventIds,
        {_eventId(0), _eventId(1), _eventId(2)},
      );

      final sourceCatalog = fixture.catalog(removedSourceIndex: 0);
      final sourceDeletion = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: sourceCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        sourceDeletion,
        registry: fixture.registry,
        catalog: sourceCatalog,
      );
      expect(
        sourceDeletion.recalculatedEventIds,
        _withDependents({for (var index = 0; index < 500; index += 100) index}),
      );

      final sceneCatalog = fixture.catalog(removedSceneIndex: 0);
      final sceneDeletion = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: sceneCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        sceneDeletion,
        registry: fixture.registry,
        catalog: sceneCatalog,
      );
      expect(
        sceneDeletion.recalculatedEventIds,
        _withDependents({for (var index = 0; index < 500; index += 50) index}),
      );

      final factCatalog = fixture.catalog(removedFactIndex: 0);
      final factDeletion = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: factCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        factDeletion,
        registry: fixture.registry,
        catalog: factCatalog,
      );
      expect(
        factDeletion.recalculatedEventIds,
        _withDependents({for (var index = 0; index < 500; index += 100) index}),
      );

      final globalCatalog = fixture.catalog(includeGlobalDiagnostic: true);
      final globalChange = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: globalCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        globalChange,
        registry: fixture.registry,
        catalog: globalCatalog,
      );
      expect(globalChange.recalculatedEventIds, isEmpty);

      final modeRegistry = fixture.registryWithMode(EventSystemMode.v2Only);
      final modeCatalog = fixture.catalog(registry: modeRegistry);
      final modeChange = coordinator.rebuildIncrementally(
        registry: modeRegistry,
        catalog: modeCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        modeChange,
        registry: modeRegistry,
        catalog: modeCatalog,
      );
      expect(modeChange.recalculatedEventIds, isEmpty);

      final removedRegistry = fixture.registryWithoutLastEvent();
      final removedCatalog = fixture.catalog(registry: removedRegistry);
      final recordSetChange = coordinator.rebuildIncrementally(
        registry: removedRegistry,
        catalog: removedCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        recordSetChange,
        registry: removedRegistry,
        catalog: removedCatalog,
      );
      expect(
        recordSetChange.recalculatedEventIds,
        {
          for (var index = 0; index < _recordCount - 1; index++) _eventId(index)
        },
      );
    },
  );

  test('incremental validation keeps the frozen Phase 3 p95 budget', () {
    const coordinator = NarrativeEventValidationCoordinator();
    final fixture = _ValidationFixture.create();
    final initial = coordinator.rebuildIncrementally(
      registry: fixture.registry,
      catalog: fixture.catalog(),
    );
    final mutatedRegistry = fixture.registryWithRenamedEvent(0);
    final mutatedCatalog = fixture.catalog(registry: mutatedRegistry);

    NarrativeEventIncrementalValidationResult run() {
      return coordinator.rebuildIncrementally(
        registry: mutatedRegistry,
        catalog: mutatedCatalog,
        previous: initial.cache,
      );
    }

    for (var index = 0; index < _warmupIterations; index++) {
      run();
    }
    final samples = <int>[];
    NarrativeEventIncrementalValidationResult? last;
    for (var index = 0; index < _measuredIterations; index++) {
      final stopwatch = Stopwatch()..start();
      last = run();
      stopwatch.stop();
      samples.add(stopwatch.elapsedMicroseconds);
    }

    final sorted = [...samples]..sort();
    final p50 = sorted[(sorted.length * 0.50).ceil() - 1];
    final p95 = sorted[(sorted.length * 0.95).ceil() - 1];
    stdout.writeln(
      'NS_EVENT_V2_PHASE_3_INCREMENTAL_BASELINE '
      'os=${Platform.operatingSystem} '
      'os_version=${_singleLine(Platform.operatingSystemVersion)} '
      'dart=${Platform.version.split(' ').first} '
      'processors=${Platform.numberOfProcessors} '
      'records=$_recordCount sources=$_sourceCount scenes=$_sceneCount '
      'facts=$_factCount warmups=$_warmupIterations '
      'iterations=$_measuredIterations execution=sequential '
      'p50_us=$p50 p95_us=$p95 '
      'recalculated=${last!.recalculatedEventIds.length} '
      'budget_p95_us=$_p95BudgetMicroseconds threshold=frozen',
    );

    expect(
      last.recalculatedEventIds,
      {_eventId(0), _eventId(1), _eventId(2)},
    );
    expect(
      last.report.toDebugJson(),
      buildNarrativeEventValidationReport(
        registry: mutatedRegistry,
        catalog: mutatedCatalog,
      ).toDebugJson(),
    );
    expect(
      p95,
      lessThanOrEqualTo(_p95BudgetMicroseconds),
      reason: 'The Phase 3 p95 budget was frozen after the baseline run.',
    );
  });
}

void _expectEquivalentToFullBuild(
  NarrativeEventIncrementalValidationResult result, {
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
}) {
  expect(
    result.report.toDebugJson(),
    buildNarrativeEventValidationReport(
      registry: registry,
      catalog: catalog,
    ).toDebugJson(),
  );
}

Set<String> _withDependents(Set<int> directlyChanged) {
  final result = {...directlyChanged};
  if (result.contains(0)) {
    result
      ..add(1)
      ..add(2);
  } else if (result.contains(1)) {
    result.add(2);
  }
  return {for (final index in result) _eventId(index)};
}

String _eventId(int index) {
  return 'evt_019abcde-0000-7000-8000-'
      '${index.toRadixString(16).padLeft(12, '0')}';
}

String _singleLine(String value) => value.replaceAll(RegExp(r'\s+'), '_');

final class _ValidationFixture {
  _ValidationFixture._({required this.registry});

  factory _ValidationFixture.create() {
    return _ValidationFixture._(
      registry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: [
          for (var index = 0; index < _recordCount; index++) _record(index)
        ],
        legacyClaims: const [],
      ),
    );
  }

  final NarrativeEventRegistry registry;

  NarrativeEventRegistry registryWithRenamedEvent(int renamedIndex) {
    return NarrativeEventRegistry(
      schemaVersion: registry.schemaVersion,
      mode: registry.mode,
      records: [
        for (var index = 0; index < _recordCount; index++)
          _record(
            index,
            name: index == renamedIndex ? 'Event $index renamed' : null,
          ),
      ],
      legacyClaims: registry.legacyClaims,
    );
  }

  NarrativeEventRegistry registryWithoutLastEvent() {
    return NarrativeEventRegistry(
      schemaVersion: registry.schemaVersion,
      mode: registry.mode,
      records: registry.records.take(_recordCount - 1).toList(),
      legacyClaims: registry.legacyClaims,
    );
  }

  NarrativeEventRegistry registryWithMode(EventSystemMode mode) {
    return NarrativeEventRegistry(
      schemaVersion: registry.schemaVersion,
      mode: mode,
      records: registry.records,
      legacyClaims: registry.legacyClaims,
    );
  }

  NarrativeEventProjectCatalog catalog({
    NarrativeEventRegistry? registry,
    int? removedSourceIndex,
    int? removedSceneIndex,
    int? removedFactIndex,
    bool includeGlobalDiagnostic = false,
  }) {
    final effectiveRegistry = registry ?? this.registry;
    final availableSourceIndexes = {
      for (var index = 0; index < _sourceCount; index++)
        if (index != removedSourceIndex) index,
    };
    final availableSceneIndexes = {
      for (var index = 0; index < _sceneCount; index++)
        if (index != removedSceneIndex) index,
    };
    final availableFactIndexes = {
      for (var index = 0; index < _factCount; index++)
        if (index != removedFactIndex) index,
    };
    final diagnostics = <NarrativeEventProjectDiagnostic>[];
    if (includeGlobalDiagnostic) {
      diagnostics.add(
        NarrativeEventProjectDiagnostic(
          code: 'fixtureGlobalDiagnostic',
          severity: NarrativeEventProjectDiagnosticSeverity.warning,
          message: 'Le registre de test doit être vérifié.',
          path: 'eventRegistry',
        ),
      );
    }
    final invalidEventIds = <String>{};
    for (var index = 0; index < effectiveRegistry.records.length; index++) {
      final eventId = _eventId(index);
      if (!availableSourceIndexes.contains(index % _sourceCount)) {
        invalidEventIds.add(eventId);
        diagnostics.add(
          NarrativeEventProjectDiagnostic(
            code: 'narrativeEventSourceMissing',
            severity: NarrativeEventProjectDiagnosticSeverity.error,
            message:
                'La source de cet Event ne résout pas une option utilisable.',
            path: 'eventRegistry.records.$eventId.source',
          ),
        );
      }
      if (!availableSceneIndexes.contains(index % _sceneCount)) {
        invalidEventIds.add(eventId);
        diagnostics.add(
          NarrativeEventProjectDiagnostic(
            code: 'narrativeEventSceneMissing',
            severity: NarrativeEventProjectDiagnosticSeverity.error,
            message: 'La Scene de cet Event doit être unique et exécutable.',
            path: 'eventRegistry.records.$eventId.sceneId',
          ),
        );
      }
      if (index != 1 &&
          index != 2 &&
          !availableFactIndexes.contains(index % _factCount)) {
        invalidEventIds.add(eventId);
        diagnostics.add(
          NarrativeEventProjectDiagnostic(
            code: 'narrativeEventFactMissing',
            severity: NarrativeEventProjectDiagnosticSeverity.error,
            message: 'Le Fact référencé doit exister exactement une fois.',
            path: 'eventRegistry.records.$eventId.conditions.0.factId',
          ),
        );
      }
    }
    diagnostics.sort((left, right) {
      final path = compareNarrativeEventUtf16(left.path, right.path);
      return path != 0
          ? path
          : compareNarrativeEventUtf16(left.code, right.code);
    });

    return NarrativeEventProjectCatalog(
      manifestHash:
          'manifest-${availableSourceIndexes.length}-${availableSceneIndexes.length}',
      mapHashes: {
        for (final index in availableSourceIndexes)
          'map_${index.toString().padLeft(3, '0')}': 'hash-$index',
      },
      spatialSources: NarrativeSpatialEventSourceCatalog(
        options: [
          for (final index in availableSourceIndexes) _sourceOption(index),
        ],
        diagnostics: const [],
      ),
      outcomeSources: NarrativeOutcomeEventSourceCatalog(
        options: const [],
        diagnostics: const [],
      ),
      scenes: [
        for (final index in availableSceneIndexes) _sceneEntry(index),
      ],
      facts: [for (final index in availableFactIndexes) _factEntry(index)],
      events: [
        for (final record in effectiveRegistry.records)
          NarrativeEventProjectEventEntry(
            record: record,
            proposed: false,
            inDependencyCycle: false,
            contextuallyValid: !invalidEventIds.contains(record.id),
          ),
      ],
      diagnostics: diagnostics,
    );
  }
}

NarrativeEventRecord _record(int index, {String? name}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId(index),
      name: name ?? 'Event $index',
      source: NarrativeEventSourceRef.mapEnter(
        'map_${(index % _sourceCount).toString().padLeft(3, '0')}',
      ),
      conditions: [
        if (index == 1)
          NarrativeEventCondition.narrativeEventConsumed(_eventId(0), true)
        else if (index == 2)
          NarrativeEventCondition.narrativeEventConsumed(_eventId(1), true)
        else
          NarrativeEventCondition.fact(
            'fact_${(index % _factCount).toString().padLeft(3, '0')}',
            true,
          ),
      ],
      sceneId: 'scene_${(index % _sceneCount).toString().padLeft(3, '0')}',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: index,
    ),
    enabled: true,
  );
}

NarrativeSpatialEventSourceOption _sourceOption(int index) {
  final mapId = 'map_${index.toString().padLeft(3, '0')}';
  return NarrativeSpatialEventSourceOption(
    source: NarrativeEventSourceRef.mapEnter(mapId),
    humanLabel: 'Entrée sur Map $index',
    humanDescription: 'Quand le joueur entre sur Map $index',
    mapId: mapId,
    mapLabel: 'Map $index',
    sourceTypeLabel: 'Entrée sur une map',
    availability: NarrativeSpatialEventSourceAvailability.selectable,
    origin: NarrativeSpatialEventSourceOrigin.canonical,
    debugTechnicalLabel: 'mapEnter:$mapId',
    geometry: const NarrativeSpatialSourceGeometrySummary.mapWide(),
    ownerKind: NarrativeSpatialEventSourceOwnerKind.map,
  );
}

NarrativeEventProjectSceneEntry _sceneEntry(int index) {
  final sceneId = 'scene_${index.toString().padLeft(3, '0')}';
  return NarrativeEventProjectSceneEntry(
    scene: SceneAsset.fromJson({
      'id': sceneId,
      'name': 'Scene $index',
      'graph': const {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {'id': 'end', 'kind': 'end'},
        ],
        'edges': [
          {
            'id': 'edge_end',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'end',
            'kind': 'default',
          },
        ],
      },
    }),
    buildable: true,
  );
}

NarrativeEventProjectFactEntry _factEntry(int index) {
  final factId = 'fact_${index.toString().padLeft(3, '0')}';
  return NarrativeEventProjectFactEntry(
    NarrativeFactDefinition(id: factId, label: 'Fact $index'),
  );
}
````
