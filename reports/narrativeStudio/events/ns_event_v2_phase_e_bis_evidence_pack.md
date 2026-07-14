# NS-EVENT-V2 - Phase E-bis - Evidence Pack

## 1. Identite du lot

```text
Lot : NS-EVENT-V2 - PHASE E-bis
Objet : Authoring Snapshot Attestation & Pending Recovery Gate Closure V0
Repository : /Users/karim/Project/pokemonProject
Branche : main
HEAD : 5d9204693085326e57aefc73bbf2a6a54082451b
Baseline pre-Phase-E : e932d9a2
Phase E : 5d920469
Verdict : CLOSED / PASS
Phase suivante : F1 READY
```

## 2. Gate 0 et drift initial

Commandes executees avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/pubspec.lock
packages/map_editor/pubspec.lock
5d920469 feat(event-v2): complete NS-EVENT-V2 Phase E
e932d9a2 feat(event-v2): enhance migration plan with context validation and strict JSON parsing
```

Drift preexistant :

```text
Fichier : packages/map_editor/pubspec.lock
SHA-256 initial : a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc
Action E-bis : aucune
```

## 3. Baselines et environnement

| Element | Valeur |
|---|---|
| Dart autonome | 3.12.1 stable, macos_arm64 |
| Flutter | 3.46.0-0.3.pre beta |
| Dart Flutter | 3.13.0-167.1.beta |
| DevTools | 2.59.0 |
| OS performance | macOS 27.0 build 26A5378j |
| CPU logique | 10 |

Baseline de tests avant implementation :

```text
map_core, deux tests cibles : +11 All tests passed
map_core analyze : No issues found
editor repository + journal + recovery + undo : +39 All tests passed
```

## 4. Regles et fichiers lus

Instructions lues :

- `AGENTS.md` fourni pour le repository ;
- `skills/README.md` ;
- `codex_rule.md` ;
- skill `subagent-driven-development` ;
- skill `test-driven-development` ;
- skill `systematic-debugging` ;
- skill `verification-before-completion`.

Documents normatifs principaux :

- prompt Phase E-bis attache ;
- `MVP Selbrume/road_map_event_builder_v2.md` ;
- `MVP Selbrume/event_builder_v2_architecture_decisions.md` ;
- rapports et Evidence Packs Phases B, C, D et E ;
- contrats Phase D de catalogue/index et operations Phase E.

Zones code inspectees :

- models/errors/use cases d'application `map_editor` ;
- repositories fichier et persistance registry ;
- verrou de manifest ;
- tests repository, journal, recovery, undo et performance ;
- fixtures de persistence ;
- decodeurs et builders `map_core` utilises par les snapshots.

## 5. MCP Dart

Le MCP Dart n'etait pas disponible. Aucun symbole MCP n'a donc ete invoque.
Compensation : recherches `rg`, lectures `sed`, tests Flutter/Dart, analyse
statique ciblee, build macOS et execution isolee par `git archive`.

## 6. Sous-agents et incidents

| ID | Role | Resultat |
|---|---|---|
| `019f6073-9cb0-7591-a40d-611a9e5fa67f` | A - Snapshot Attestation | PASS |
| `019f6088-cbb1-7693-9c49-dd9c4c1a995a` | B - Map Revalidation | PASS |
| `019f6090-42ae-7ff1-a719-d63dc04649a2` | C - Recovery Gate | PASS apres re-review |
| `019f609f-a24d-7e91-9441-842ea00a11f4` | D - Persistence Architecture | PASS apres re-review |
| `019f609d-adf8-79d1-9a5a-d8d683f458d7` | E - Baseline Regression | PASS |
| `019f60aa-8c24-7590-bccc-978666ff1c83` | F - Tests & Readiness | PASS, F1 READY |

Incidents :

1. Le premier lancement A a combine `fork_context` et `agent_type`; relance
   immediate avec une configuration valide.
2. Le premier lancement E a rencontre la meme combinaison invalide; relance.
3. La passe E s'est d'abord presentee comme D et a donne un verdict incompatible
   avec ses preuves; clarification envoyee, verdict final PASS.
4. C a trouve trois blockers reels, tous transformes en tests rouges puis fixes.
5. D a trouve l'ambiguite `recovered journal + unexpected undo`, reproduite en
   rouge puis fermee.
6. R1 a trouve un undo orphelin, un alias map non revalide et une preuve
   baseline insuffisamment reproductible ; corrections puis re-review PASS.
7. R2 a trouve la perte de cause/path recovery et l'absence d'inspection au
   gateway ; corrections puis re-review PASS.
8. Aucun agent n'a edite de fichier.

## 7. Inventaire des fichiers E-bis

### Production

Crees :

- `packages/map_editor/lib/src/application/models/narrative_event_authoring_session.dart`
  - 313 lignes ;
  - session, attestation, decodeurs stricts partages.

Modifies :

- `packages/map_editor/lib/src/application/errors/application_errors.dart` ;
- `packages/map_editor/lib/src/application/models/narrative_event_registry_persistence_models.dart` ;
- `packages/map_editor/lib/src/application/ports/narrative_event_registry_persistence_gateway.dart` ;
- `packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart` ;
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart` ;
- `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_registry_persistence.dart` ;
- `packages/map_editor/lib/src/infrastructure/repositories/project_manifest_write_lock.dart`.

### Tests

Crees :

- `packages/map_editor/test/narrative_event_authoring_session_test.dart` (327 lignes) ;
- `packages/map_editor/test/narrative_event_authoring_map_revalidation_test.dart` (377 lignes) ;
- `packages/map_editor/test/event_registry_recovery_gate_test.dart` (773 lignes) ;
- `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart` (257 lignes).

Modifies :

- `packages/map_editor/test/event_registry_repository_test.dart` ;
- `packages/map_editor/test/event_registry_recovery_test.dart` ;
- `packages/map_editor/test/event_registry_undo_test.dart` ;
- `packages/map_editor/test/event_registry_persistence_performance_test.dart` ;
- `packages/map_editor/test/support/event_registry_persistence_fixtures.dart`.

### Documentation

Crees :

- `reports/narrativeStudio/events/ns_event_v2_phase_e_bis_snapshot_recovery_closure_v0.md` ;
- `reports/narrativeStudio/events/ns_event_v2_phase_e_bis_evidence_pack.md`.

Modifie apres PASS :

- `MVP Selbrume/road_map_event_builder_v2.md`.

Exclu et non revendique : `packages/map_editor/pubspec.lock`, drift preexistant.

## 8. API session et attestation

API canonique :

```dart
NarrativeEventAuthoringSession.prepare(projectPath)
NarrativeEventRegistryWriteRequest.fromAuthoringSession(
  session: session,
  result: result,
)
```

L'ancienne construction depuis un contexte caller arbitraire a ete retiree. La
session conserve de maniere immuable :

- path projet/manifest canonique ;
- bytes manifest exacts ;
- SHA-256 manifest exact ;
- hash semantique manifest ;
- projet decode et normalise ;
- path declare, cible canonique, bytes et SHA-256 de chaque map ;
- empreinte registry ;
- empreinte catalogue ;
- empreinte structural source index ;
- volume total atteste.

Decodeurs stricts partages :

```text
decodeValidatedNarrativeEventAuthoringProject
decodeValidatedNarrativeEventAuthoringMap
normalizeLoadedProjectManifest
```

## 9. Fixture manifest/maps

La fixture editor a ete rendue structurellement valide : manifest reel,
fichiers maps reels, layers et objets sources minimaux, Scene optionnelle et
preparation explicite d'une session. Elle ne pointe vers aucun projet utilisateur
et chaque test opere dans un repertoire temporaire.

## 10. Attestation golden et contexte forge

Matrice A :

| Cas | Attendu | Resultat |
|---|---|---|
| Registry absent | Snapshot valide et deterministe | PASS |
| Registry present | Empreintes exactes, collections immuables | PASS |
| Map manquante | Session refusee | PASS |
| Map JSON invalide | Session refusee | PASS |
| IDs map dupliques | Session refusee | PASS |
| Manifest invalide | Session refusee | PASS |
| Registry non supporte | Session refusee | PASS |
| Request sans session | API indisponible | PASS |
| Catalogue forge | Fresh replay refuse | PASS |
| Source index forge | Fresh replay refuse | PASS |
| Session devenue stale | Refus sans artefact | PASS |
| Collection de paths declares modifiee | Mutation refusee | PASS |

## 11. Fresh replay

Sous le verrou canonique du projet :

```text
inspect recovery
-> prepare fresh disk session
-> compare exact attestation
-> replay authoring operation with fresh catalog/index
-> compare replayed result
-> prepare journal
-> revalidate maps
-> rename manifest
```

Un ecart avant preparation renvoie `staleAuthoringSnapshot` sans creer de
journal, temp, backup ou undo. Une map qui diverge plus tard renvoie
`staleMapRevision` et restaure/nettoie l'etat journalise de facon sure.

## 12. Map change et race matrix

| Preuve | Etat |
|---|---|
| Entite supprimee avant replay | PASS, aucun artefact |
| Trigger supprime avant replay | PASS, aucun artefact |
| Outcome map-backed stale | PASS, aucun artefact |
| Map changee apres fresh replay | PASS, aucun rename |
| Map changee apres journal prepared | PASS, recovery sure |
| Map changee au dernier checkpoint | PASS, aucun rename |
| Cible canonique transformee en symlink | PASS, resultat stale stable |
| Alias manifest A retargete vers B avec octets identiques | PASS, aucun rename |

Les paths de verrou, projet et maps sont canoniques afin que deux alias symlink
ne contournent pas la revision ou ne creent pas deux verrous logiques.

## 13. Pending recovery matrix

| Etat disque | Event write | Generic save | Load/open | Recovery explicite |
|---|---|---|---|---|
| Aucun journal | Autorise | Autorise | Autorise | No-op |
| `prepared` valide | Bloque | Bloque | Bloque | Restaure/finalise |
| `committed` coherent | Autorise | Autorise | Autorise | Non requise |
| `recovered` coherent | Autorise | Autorise | Autorise | Non requise |
| Journal illisible | Bloque | Bloque | Bloque | Bloque fail-closed |
| Plusieurs `prepared` | Bloque | Bloque | Bloque | Bloque ambigu |
| Path unsafe | Bloque | Bloque | Bloque | Bloque |
| Backup absente/corrompue | Bloque | Bloque | Bloque | Bloque avant mutation |
| Revision projet inconnue | Bloque | Bloque | Bloque | Bloque avant mutation |
| Temp after-state corrompu | Bloque | Bloque | Bloque | Bloque avant mutation |
| Rewrite temp orphelin | Bloque | Bloque | Bloque | Bloque |
| Undo inattendu/corrompu | Bloque | Bloque | Bloque | Bloque |
| Undo sans journal | Bloque `orphanUndo` | Bloque | Bloque | Bloque |
| Artefact sous forme de symlink | Bloque `unsafeArtifactLink` | Bloque | Bloque | Bloque |
| Artefact autre projet | Ignore | Ignore | Ignore | Non concerne |

## 14. Generic save, load et no-hidden-recovery

`FileProjectRepository.saveProject`, la persistance registry, l'undo et le load
utilisent le meme verrou projet et la meme inspection. `inspectRecovery` est
expose par le gateway et `InspectNarrativeEventRegistryRecoveryUseCase`. Le
load partage les decodeurs stricts mais n'appelle jamais la recovery. Les
resultats conservent l'inspection complete ; les exceptions exposent `code` et
`path`. Les tests verifient qu'un `prepared` bloque les trois chemins et que
seul l'appel explicite de recovery debloque ensuite les acces.

Preuve d'absence d'autre writer manifest : les recherches des usages
`saveProject`, `writeAs*`, `rename` et `project.json` montrent que les writers
production passent par `_saveProjectLocked` ou la transition registry. Les
autres ecritures ciblees sont maps/assets/tilesets.

## 15. Malformed journal et fail-closed

L'inspection est read-only. Avant toute mutation, elle decode et valide le
journal, ses paths, revisions, hashes et prerequis. Une anomalie bloque
l'ensemble du projet et la boucle de recovery ne continue pas sur d'autres
journaux. Cette politique evite une recovery partielle impossible a expliquer.

Les artefacts associes a une recovery valide sont supprimes ensemble, y compris
le rewrite undo. La recovery via un path projet symlink utilise le meme path
canonique et retrouve les memes artefacts.

Un `.undo.json` sans journal correspondant est `orphanUndo` et ne peut pas
atteindre la transition d'undo. Un artefact de persistance represente par un
lien symbolique est `unsafeArtifactLink` et bloque avant lecture ou mutation.

## 16. Baseline archive des deux tests editor

Methode read-only reproductible, executee depuis la racine du repository :

```bash
mktemp -d /tmp/pokemap-e-bis-baseline.XXXXXX
git archive e932d9a2 | tar -x -C /tmp/pokemap-e-bis-baseline.Nqrgwz
cd /tmp/pokemap-e-bis-baseline.Nqrgwz/packages/map_editor
flutter pub get
flutter test --reporter=compact \
  test/selbrume_editor_repository_roundtrip_test.dart \
  --name 'real EditorNotifier sessions retain all 722 placements after an edit'
flutter test --reporter=compact \
  test/editor_notifier_project_dirty_state_test.dart \
  --name 'applyElementAutoShadowSuggestions applique et sauvegarde'
```

```bash
mktemp -d /tmp/pokemap-e-bis-phase-e.XXXXXX
git archive 5d920469 | tar -x -C /tmp/pokemap-e-bis-phase-e.s6rs5D
cd /tmp/pokemap-e-bis-phase-e.s6rs5D/packages/map_editor
flutter pub get
flutter test --reporter=compact \
  test/selbrume_editor_repository_roundtrip_test.dart \
  --name 'real EditorNotifier sessions retain all 722 placements after an edit'
flutter test --reporter=compact \
  test/editor_notifier_project_dirty_state_test.dart \
  --name 'applyElementAutoShadowSuggestions applique et sauvegarde'
```

Etat final : les deux memes commandes ont ete executees depuis
`/Users/karim/Project/pokemonProject/packages/map_editor`.

| Etat | Placement source template | Auto-shadow inference |
|---|---|---|
| `e932d9a2` | FAIL, attendu 306, obtenu 94, ligne 196 | FAIL, attendu non-null, obtenu null, ligne 194 |
| `5d920469` | Meme echec | Meme echec |
| E-bis final | Meme echec | Meme echec |

Sorties decisives exactes dans les six executions :

```text
placements, exit 1
Expected: an object with length of <306>
Actual: has length of <94>
test/selbrume_editor_repository_roundtrip_test.dart 196:11
Some tests failed.

auto-shadow, exit 1
Expected: not null
Actual: <null>
test/editor_notifier_project_dirty_state_test.dart 194:7
Some tests failed.
```

Hashes des fichiers de test, identiques sur baseline, Phase E et final :

```text
selbrume_editor_repository_roundtrip_test.dart
7a98a3cba20b06771417c6c08d13747a61b96fbfa3a246e70effa61b8ac3e487

editor_notifier_project_dirty_state_test.dart
d812c33bbdf53908d0f3ec9d0d7ce10a8dd1f073094d26458ca2efa611fbcd52
```

Les repertoires `/tmp/pokemap-e-bis-baseline.Nqrgwz` et
`/tmp/pokemap-e-bis-phase-e.s6rs5D` ont ete supprimes ; `test ! -e` confirme
`archives temporaires absentes`.

Verdict D : les deux echecs sont preexistants prouves. Ils ne sont ni corriges
hors scope, ni caches, ni annonces comme verts.

## 17. TDD et corrections issues des reviews

Sequences rouge/vert observees :

1. Session A : erreur de compilation avant API, puis vert.
2. Source index forge : test rouge, puis rejet vert.
3. Races map B : tests rouges, puis checkpoints verts.
4. Retarget symlink : code stable rouge, puis vert.
5. Outcome map-backed : fixture/layer rouge, puis vert.
6. Prerequis prepared invalides : rouge, puis fail-closed vert.
7. Rewrite undo recovery : rouge, puis nettoyage vert.
8. Recovery par symlink : rouge, puis path canonique vert.
9. `recovered + unexpected undo` : deux cas rouges, puis blocage vert.
10. Alias map A vers B avec memes octets : commit rouge, puis stale vert.
11. Undo orphelin : mutation possible rouge, puis `orphanUndo` vert.
12. Artefact symlink : ignore rouge, puis `unsafeArtifactLink` vert.
13. Cause/path recovery : API absente rouge, puis propagation gateway verte.

Aucun critere n'a ete reduit pour faire passer les tests.

## 18. Tests cibles et cumules

Commandes principales :

```bash
cd packages/map_editor
flutter test --reporter=compact test/narrative_event_authoring_session_test.dart
flutter test --reporter=compact test/narrative_event_authoring_map_revalidation_test.dart
flutter test --reporter=compact test/event_registry_recovery_gate_test.dart
flutter test --reporter=compact test/event_registry_repository_test.dart test/event_registry_journal_test.dart test/event_registry_recovery_test.dart test/event_registry_undo_test.dart
flutter test --reporter=compact test/event_registry_repository_test.dart test/event_registry_journal_test.dart test/event_registry_recovery_test.dart test/event_registry_undo_test.dart test/event_registry_persistence_performance_test.dart test/narrative_event_authoring_session_test.dart test/narrative_event_authoring_map_revalidation_test.dart test/event_registry_recovery_gate_test.dart test/narrative_event_authoring_snapshot_performance_test.dart
```

Resultats obtenus :

```text
Phase C standalone apres corrections : +11 All tests passed
Recovery/repository/journal/undo final : +52 All tests passed
Phase B standalone final : +7 All tests passed
E4 + E-bis cumule avant dernier cas undo : +69 All tests passed
E4 + E-bis cumule apres review D : +71 All tests passed
E4 + E-bis cumule final apres R1/R2 : +74 All tests passed
Regressions editor pertinentes finales : +194 All tests passed
map_core complet : +2908 All tests passed
```

## 19. Analyses

```text
packages/map_core: dart analyze
No issues found

packages/map_editor: flutter analyze --no-fatal-infos <18 fichiers E-bis>
Analyzing 18 items...
No issues found! (ran in 3.0s)

packages/map_editor: flutter analyze --no-fatal-infos
451 issues found

archive 5d920469: flutter analyze --no-fatal-infos
451 issues found
```

La comparaison archive/final classe l'analyse globale comme dette preexistante.
Le repertoire temporaire d'analyse `/tmp/pokemap-e-bis-analyze.gMkH2B` a ete
supprime et son absence verifiee.

## 20. Build

```bash
cd packages/map_editor
flutter build macos --debug
```

```text
Built build/macos/Build/Products/Debug/map_editor.app
Resultat : PASS
```

## 21. Performance

Protocole : JIT, 1 warmup, 5 iterations, aucune attente stricte et aucun cache
global mutable.

| Operation | N | Mean us | Median us | Bytes |
|---|---:|---:|---:|---:|
| Session prepare | 10 maps | 13,559.4 | 12,497.0 | 9,692 |
| Session prepare | 100 maps | 72,116.2 | 69,704.0 | 71,702 |
| Session prepare | 500 maps | 307,242.8 | 306,607.0 | 347,302 |
| Final map revalidation | 10 maps | 5,865.8 | 5,857.0 | 5,120 |
| Final map revalidation | 100 maps | 40,414.8 | 41,485.0 | 51,200 |
| Final map revalidation | 500 maps | 152,027.8 | 144,436.0 | 256,000 |
| Recovery scan | 0 | 1,408.4 | 1,287.0 | 0 |
| Recovery scan | 1 | 2,661.8 | 2,386.0 | 2,369 |
| Recovery scan | 100 | 101,029.6 | 100,633.0 | 276,615 |

Hashing et rebuild catalogue/index sont inclus dans `Session prepare`. Le
hashing est inclus et le rebuild exclu de `Final map revalidation`.

## 22. Reviews R1/R2

### R1 - Integrity

Verdict initial : FAIL. Blockers : undo orphelin, retarget de l'alias manifest
non revalide, baseline insuffisamment reproductible. Reserve : artefacts `Link`
ignores.

Corrections : inventaire `undoPaths` et `linkPaths`, blocages `orphanUndo` et
`unsafeArtifactLink`, conservation du path declare avec double resolution avant
rename, tests A vers B avec memes octets, commandes/hashes/sorties baseline
consignes ci-dessus.

Re-review : PASS, aucun blocker code restant. Reserve non bloquante : une
mutation filesystem externe apres la derniere resolution mais avant rename
reste theorique ; les writers cooperatifs sont serialises par le verrou.

### R2 - Product Truthfulness

Verdict initial : FAIL. Blockers : cause/path recovery perdus et inspection non
exposee au gateway ; documents CLOSED avant insertion des reviews/gate final.

Corrections : `inspectRecovery`, use case dedie, `recoveryInspection` dans le
resultat, exceptions avec `code`/`path` et messages detailles, assertions
`preparedJournal`/`invalidJournal`, documents finalises apres les gates.

Re-review : PASS, aucun blocker produit restant. Reserves non bloquantes :
`multiplePreparedJournals` n'a pas de path unique et le message prepared repete
partiellement son resume.

## 23. Gate final

Le cumul final E4 + E-bis termine avec `+74 All tests passed`. Les commandes
Git finales sont executees apres les reviews R1/R2 et leurs sorties sont
ajoutees ici avant cloture.

Commandes imposees :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
git diff --name-only -- \
  packages/map_runtime \
  packages/map_gameplay \
  packages/map_battle \
  packages/map_editor/lib/src/ui \
  examples \
  assets \
  selbrume \
  "MVP Selbrume/selbrume.md" \
  "MVP Selbrume/narrative_studio.md"
```

Attendu anti-scope : `<empty>`.

Sorties finales :

```text
git status --short --untracked-files=all
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M packages/map_editor/lib/src/application/errors/application_errors.dart
 M packages/map_editor/lib/src/application/models/narrative_event_registry_persistence_models.dart
 M packages/map_editor/lib/src/application/ports/narrative_event_registry_persistence_gateway.dart
 M packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/lib/src/infrastructure/repositories/narrative_event_registry_persistence.dart
 M packages/map_editor/lib/src/infrastructure/repositories/project_manifest_write_lock.dart
 M packages/map_editor/pubspec.lock
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/event_registry_recovery_test.dart
 M packages/map_editor/test/event_registry_repository_test.dart
 M packages/map_editor/test/event_registry_undo_test.dart
 M packages/map_editor/test/support/event_registry_persistence_fixtures.dart
?? packages/map_editor/lib/src/application/models/narrative_event_authoring_session.dart
?? packages/map_editor/test/event_registry_recovery_gate_test.dart
?? packages/map_editor/test/narrative_event_authoring_map_revalidation_test.dart
?? packages/map_editor/test/narrative_event_authoring_session_test.dart
?? packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
?? reports/narrativeStudio/events/ns_event_v2_phase_e_bis_evidence_pack.md
?? reports/narrativeStudio/events/ns_event_v2_phase_e_bis_snapshot_recovery_closure_v0.md

git diff --stat
14 files changed, 912 insertions(+), 253 deletions(-)

git diff --check
<empty>

anti-scope
<empty>

git diff --name-only -- packages/map_core
<empty>
```

Le stat Git exclut les sept fichiers non suivis, listes par le status et
inventories en section 7. Le controle explicite de whitespace sur ces fichiers
est vide. Les recherches sur les additions code/tests pour
`//`, `/*`, `TODO`, `FIXME`, `HACK`, `TEMP` sont vides.

```text
SHA-256 pubspec.lock final
a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc
SHA-256 pubspec.lock initial
a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc
```

Le lockfile reste un drift preexistant byte-identique. Aucun commit Git n'a ete
cree.

## 24. Entry Gate F1

```text
Authoring operations immutable : PASS
Publication configured-disabled : PASS (Phase E)
Activation separee : PASS (Phase E)
Fresh authoring snapshot : PASS
Exact project/map revisions : PASS
Journaled registry persistence : PASS
Mandatory recovery gate : PASS
Stale-safe undo : PASS
Real source bridge : NOT ADDED
Runtime V2 : NOT ADDED
UI V2 : NOT ADDED

PHASE F1 : READY
```

Blocker restant pour F1 : aucun dans le scope E-bis.
