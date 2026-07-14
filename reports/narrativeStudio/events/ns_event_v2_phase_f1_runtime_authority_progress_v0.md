# NS-EVENT-V2 - Phase F1 - Runtime Authority, Lifecycle, Progress & Outcome Outbox V0

## 1. Resume executif

```text
PHASE F1 : BLOCKED

F1-0 : BLOCKED
F1-A / V2-17 : BLOCKED (non commence, stop F1-0)
F1-B1 / V2-18 : BLOCKED (non commence, stop F1-0)
F1-B2 / V2-18 : BLOCKED (non commence, stop F1-0)
F1-B3 / V2-18 : BLOCKED (non commence, stop F1-0)

Authority planner : BLOCKED
Progress save round-trip : BLOCKED
oneShot/reusable : BLOCKED
Save/load busy gate : BLOCKED
Outcome outbox : BLOCKED

Production source bridges added : NO
UI V2 added : NO
Legacy consumedEventIds changed : NO
EventSystemMode changed automatically : NO
Real project data modified : NO

Phase F2 : NOT READY
```

F1-0 a confirme que le repository ne possede pas encore une semantique Fact
canonique partagee par les chemins de production. Une consequence Scene peut
effacer la cle runtime d'un Fact `defaultValue: true`, tandis que les World
Rules continuent a le lire comme vrai. Les conditions Scene canoniques `fact`
ne sont pas executees par le runtime de production, et les conditions legacy
Event Builder lisent l'ID brut sans appliquer `legacyFlagName` ni
`defaultValue`.

La mission impose explicitement : si deux chemins de production evaluent le
meme Fact differemment, arreter F1 et produire un Blocker Report. Ce document
est ce Blocker Report. Aucun choix arbitraire de stockage, d'override ou de
migration n'a ete implemente.

## 2. Baseline E-bis

- Repository : `/Users/karim/Project/pokemonProject`.
- Branche : `main`.
- Baseline exigee et observee :
  `5bf62901d1071d3e17553baef016e4da3b733892`.
- Commit : `feat(event-v2): close NS-EVENT-V2 Phase E-bis`.
- Phase E-bis reste acceptee ; sa reserve de revalidation des maps lors d'un
  undo editor reste hors scope F1.
- La roadmap indiquait F1 `READY`; le gate semantique requis par F1 revele une
  precondition non fermee. La roadmap n'est pas modifiee car F1 n'est pas PASS.

## 3. Usage MCP Dart

Le MCP Dart n'etait pas disponible dans cette session. Aucun appel ou resultat
MCP fictif n'est revendique. La compensation a utilise `rg`, `sed`, `nl`, les
tests Dart/Flutter cibles et les analyses statiques disponibles.

## 4. Sous-agents et incidents

Les huit roles specialises ont ete executes comme audits read-only, avec des
reprises lorsque l'orchestration a signale une limite de threads. Aucun agent
n'a modifie le repository.

| Role | Mission | Verdict |
|---|---|---|
| A - Dispatch Authority | modes, claims, preflight | BLOCKED sans clarification `canStartDualRead`/tombstones |
| B - Candidate Eligibility | Facts, conditions, snapshot, ordre | BLOCKER F1-0 confirme |
| C - Progress Domain | models, codec, legacy mapping | faisable apres F1-A ; non commence |
| D - Lifecycle | lock, Scene, commit atomique | faisable generiquement ; bloque par F1-0 |
| E - Outcome Outbox | FIFO, retries, idempotence | bloque ; contradiction overlap a arbitrer |
| F - Persistence Gate | save/load busy | faisable avec gate partage ; non commence |
| G - Legacy Compatibility | namespaces et production legacy | BLOCKER confirme, legacy intact |
| H - Tests & F2 Readiness | preuves, build, performance | PARTIAL, F2 NOT READY |
| R1 - Runtime Integrity | tenter de refuter le STOP | BLOCKER-CONFIRMED |
| R2 - Product Truthfulness | chercher un faux blocker/faux PASS | BLOCKER-CONFIRMED, formulations corrigees |

Incidents :

1. Le premier lancement parallele a retourne une limite de threads alors que
   plusieurs workers avaient tout de meme ete crees.
2. Les roles B et D ont ete repris avec des agents identifies et leurs verdicts
   ont ete verifies contre le code local.
3. Une tentative de fork a combine `fork_context` et `agent_type`; elle a ete
   relancee immediatement avec une configuration valide.
4. Aucun travail d'un agent interrompu n'a ete accepte comme PASS implicite.

## 5. Gate 0

Sorties exactes avant modification :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock

git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

git diff --name-only
packages/map_editor/pubspec.lock
```

Le log initial commencait par :

```text
5bf62901 feat(event-v2): close NS-EVENT-V2 Phase E-bis
5d920469 feat(event-v2): complete NS-EVENT-V2 Phase E
e932d9a2 feat(event-v2): enhance migration plan with context validation and strict JSON parsing
025bf9bc feat(event-v2): complete NS-EVENT-V2 Phase D
eb1b4998 NS-EVENT-V2 PHASE C: Legacy Compatibility & Non-Destructive Migration
fdaf4e5d NS-EVENT-V2 PHASE B: Canonical Domain Contracts & Structural Source Index
61941c39 NS-EVENT-V2 PHASE A: Canonical Architecture Ratification
```

Drift preexistant exclu :

```text
packages/map_editor/pubspec.lock
SHA-256 initial : a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc
```

Environnement :

```text
Dart map_core/map_gameplay : 3.12.1 stable, macos_arm64
Flutter map_runtime : 3.46.0-0.3.pre beta
Dart Flutter : 3.13.0-167.1.beta
```

`dart pub deps` a passe dans `map_core`. `flutter pub deps` a passe dans
`map_runtime`. `dart pub deps` dans `map_gameplay` a echoue avant toute
modification :

```text
The pubspec.yaml file has changed since the pubspec.lock file was generated,
please run "dart pub get" again.
```

Aucun `pub get` n'a ete lance afin de ne pas modifier un lockfile hors scope.

## 6. Runtime Semantics Gate

Verdict : **F1-0 BLOCKED**.

Invariant de la mission : le planner V2 doit utiliser exactement la semantique
Fact runtime canonique existante et ne doit pas inventer un second stockage.
Condition de stop : si deux chemins de production divergent, produire un
Blocker Report. Les divergences ci-dessous sont reproductibles par lecture des
contrats. Aucun test cross-path existant ne couvre encore la sequence
`defaultValue: true` puis `setFact(false)`.

## 7. Fact Runtime Semantics

### Matrice observee

| Cas | World Rules | Scene setFact | Scene condition production | Event page legacy |
|---|---|---|---|---|
| Definition absente, cle brute absente | faux | echec `unknownFact` | `fact` non supporte | faux |
| default false, aucune cle | faux | n/a | `fact` non supporte | faux |
| default true, aucune cle | vrai | n/a | `fact` non supporte | faux |
| `legacyFlagName`, cle alias presente | vrai | ecrit alias | `fact` non supporte | l'ID Fact brut reste faux |
| default true puis `setFact(false)` | reste vrai | efface la cle et annonce applique | `fact` non supporte | faux |

Preuves :

- `world_rule_projection.dart:84-90` resout la definition, choisit
  `legacyFlagName ?? id`, puis calcule `flag present || defaultValue`.
- `scene_consequence_runtime_writer.dart:63-75` choisit la meme cle, mais
  `setFact(false)` se limite a la retirer.
- `event_builder_contract.dart:199-204` compile les conditions Fact vers un
  `flagIsSet/flagIsUnset(referenceId)` brut.
- `script_condition_evaluator.dart:86-95` consulte uniquement le set de flags
  avec ce nom brut.
- `playable_map_game.dart:5483-5500` supporte `factLikeStoryFlag`, pas
  `SceneConditionSourceKind.fact`, qui atteint `UnsupportedError`.
- ADR-EV2-012 impose pourtant un resolver utilisant la semantique canonique de
  `NarrativeFactDefinition` et la preuve des valeurs par defaut avant F1.

La Phase A avait deja inscrit le risque : `Fact default/override a resoudre
canoniquement | F1/V2-17 avant runtime`.

### Semantique retenue

Aucune. Choisir maintenant entre une valeur effective par defaut, un override
explicite, une cle negative reservee ou l'interdiction des defaults vrais
modifierait un contrat architecturel et potentiellement le modele/persistence.
Le lot interdit ce choix arbitraire.

### Prerequis propose

Un lot de ratification precedant F1 doit :

1. definir comment une valeur `defaultValue: true` peut etre explicitement
   remplacee par `false` ;
2. definir une cle runtime unique et collision-safe pour `legacyFlagName` ;
3. introduire un resolver pur partage et un writer symetrique ;
4. aligner World Rules, conditions Scene canoniques et snapshots V2 ;
5. prouver save/reload et les definitions dupliquees/absentes ;
6. amender explicitement le scope F1 si des chemins actuellement interdits
   doivent etre corriges.

Options a ratifier, sans application :

- override Fact explicite persiste dans `GameState` ;
- convention positive/negative dans le store de flags existant ;
- interdiction/migration des Facts `defaultValue: true`.

## 8. Authority Preflight

Le preflight n'a pas ete implemente. L'audit revele une deuxieme ambiguite :

- ADR-EV2-008 reserve le blocage global de `dualRead` aux collisions globales ;
- une cible locale invalide doit devenir un tombstone fail-closed pour sa source
  tandis que les autres sources continuent ;
- l'implementation actuelle calcule `canStartDualRead` avec
  `globalConflicts.isEmpty && invalidBySource.isEmpty` ;
- le texte F1-0 demande que tout `canStartDualRead == false` bloque l'autorite.

Le resultat actuel confond donc gate de transition stricte et disponibilite de
l'autorite d'un projet deja en `dualRead` avec tombstones locaux. Une
clarification de contrat est necessaire avant le preflight : soit
`canStartDualRead` reste un gate de transition et un second signal runtime est
ajoute, soit sa semantique change explicitement. Les maps
`invalidBySource`/`invalidByProvenance` identifient deja source/provenance par
leurs cles, mais n'exposent pas un resultat tombstone type reconciliant
explicitement le `cohortId`.

## 9. V2-17 Architecture

Non implementee. Le structural source index existe et trie deja les records
`configured && enabled`, mais le planner ne peut pas construire un snapshot
Fact honnête tant que F1-0 est bloque.

## 10. Mode Truth Table

La truth table normative reste acceptee comme cible, mais n'est pas prouvee par
une implementation F1 :

| Mode | Evaluation V2 | Fallback apres noMatch | Claims |
|---|---|---|---|
| legacyOnly | non | autorise | conserves, inertes |
| dualRead | oui | seulement source non claimée | claim/tombstone fail-closed |
| v2Only | oui | interdit | conserves pour audit |

## 11. Claim/Tombstone Truth Table

| Etat claim | ADR | Contrat actuel | Verdict |
|---|---|---|---|
| aucun conflit | autorite possible | `canStartDualRead=true` | coherent |
| collision globale | blocage global | `canStartDualRead=false` | coherent |
| cible locale invalide | tombstone local, autres sources continuent | `canStartDualRead=false` global | contradiction |
| provenance locale invalide | tombstone local | diagnostics texte | contrat type incomplet |

## 12. Candidate Ordering

L'index structurel existant respecte `priority DESC`, `order ASC`, puis
`eventId ASC` stable. Les egalites importees restent presentes. Ce point est
PASS en audit, mais aucune decision planner F1 n'a ete creee.

## 13. Condition Evaluation

`NarrativeEventCondition` est bien une union fermee `fact` /
`narrativeEventConsumed`, avec liste immutable et ordre preserve. Aucun
evaluateur runtime V2 n'existe. L'AND ordonne, le court-circuit et le namespace
`consumedNarrativeEventIds` restent donc non implementes.

## 14. Planner Result Contracts

Les trois resultats ratifies restent `handled`, `claimedButIneligible` et
`noMatch`. Aucun quatrieme resultat n'a ete ajoute. Aucun contrat planner n'a
ete cree parce que ses inputs semantiques ne peuvent pas etre prepares.

## 15. Review V2-17

- Role A : BLOCKED sans clarification claim/preflight.
- Role B : BLOCKER Fact confirme.
- R1/R2 : consolidation dans la review contradictoire finale.
- Verdict V2-17 : **BLOCKED, non commence**.

## 16. Progress Domain

`NarrativeEventProgress` et `NarrativeOutcomeDelivery` n'ont pas ete crees.
L'audit confirme que `GameState` possede encore seulement le namespace legacy
`consumedEventIds` pour les Events.

## 17. Wire Format

Non implemente. Le wire cible du prompt n'a pas ete ajoute a une save. Les
reviewers recommandent un codec manuel strict plutot qu'un codec genere qui
ignorerait des unknown fields ou dedupliquerait silencieusement des sets.

Une tension d'implementation doit etre documentee avant B3 : B1 interdit tout
overlap pending/delivered au decode, tandis que B3 demande une garde defensive
si un etat incoherent est injecte directement en memoire. Ces exigences peuvent
coexister avec un codec strict et une defense du processor ; elles ne forment
pas un blocker ADR autonome.

## 18. GameState/SaveData Compatibility

Aucun champ n'a ete ajoute a `GameState` ou `SaveData`. Les fonctions
`gameStateFromSaveData`, `saveDataFromGameState` et
`normalizeLoadedGameState` restent inchangees. La compatibilite des anciennes
saves V2 n'est pas revendiquee car le namespace V2 n'existe pas encore.

## 19. Legacy Reference Mapping

Non implemente. Aucun ID legacy n'a ete copie, devine ou supprime. Le futur
mapping devra consommer uniquement un mapping explicite de migration et
retourner un resultat bloque pour les collisions.

## 20. Review Progress Domain

Role C conclut que le domaine est faisable apres F1-A, avec collections
defensives, codec strict et IDs centralises. Verdict B1 : **BLOCKED, non
commence**.

## 21. Execution Lifecycle

Non implemente. L'audit confirme qu'un coordinateur generique pourrait composer
`SceneRuntimeExecutor` et `SceneConsequenceRuntimeWriter`, mais ne doit pas
reutiliser `SceneEventRuntimeHook` comme autorite : ce hook est legacy et
MapEvent-specifique.

## 22. Lock & In-flight Semantics

Aucun lock Event V2 ni gate d'activite partage n'existe. Le futur contrat devra
serialiser ou verifier une revision d'etat aussi entre Events differents ; un
lock uniquement par Event autoriserait des commits concurrents perdus.

## 23. Scene Atomic Commit

Non implemente. L'audit Role D identifie un risque herite pour F2 : des
callbacks de production peuvent muter `_gameState` pendant un await, puis le
hook legacy remplace l'etat depuis son snapshot initial. F1 n'a pas modifie ce
chemin interdit. Le coordinateur generique futur devra produire un unique etat
de travail transactionnel avant exposition.

## 24. oneShot/reusable Matrix

| Policy | Succes complet | Echec/annulation | Etat F1 |
|---|---|---|---|
| oneShot | apres succes Scene/consequences ; consommation et enqueue pending dans le meme commit | ne rien consommer | non implemente |
| reusable | ne jamais auto-consommer | ne rien consommer | non implemente |

## 25. Save/Load Busy Gate

Non implemente. Les APIs actuelles ne partagent pas un gate distinguant
`eventExecutionActive` et `outcomeDispatching`. Role F recommande un gate
injecte par lease, avec resultats detailles et wrappers de compatibilite. Une
inspection sans lease serait vulnerable a un TOCTOU.

## 26. Review Lifecycle

Role D : architecture generique faisable, mais BLOCKED par F1-0, F1-A et B1.
La cancellation est actuellement aplatie en echec dans le hook legacy ; le
coordinateur futur devra conserver un statut distinct. Verdict B2 : **BLOCKED,
non commence**.

## 27. Outcome Outbox

Non implementee. Aucun producer Scene/Battle/Scenario n'a ete branche. Aucun
status `running` ou `failed` n'a ete persiste.

## 28. Delivery State Machine

La cible normative `pending -> dispatching memoire -> delivered` reste
acceptee. L'atomicite parent delivered + enfants pending ne peut pas etre
implementee avant B1/B2.

## 29. Retry and Depth Matrix

Non implementee. La cible reste : retry uniquement avant selection, trois
tentatives totales, profondeur `0..8` dispatchable et `>8` terminale. Aucune
mesure ou preuve runtime n'est revendiquee.

## 30. Correlation/Causation

Non implemente. Aucun ID `evx_`, `outd_` ou `corr_` n'a ete genere. La future
API doit reutiliser une seule implementation UUIDv7.

## 31. Save/Reload Evidence

Les regressions legacy de save/reload existantes passent, mais elles ne prouvent
pas la progression V2 absente. Aucune fixture save V2 n'a ete creee.

## 32. Review Outbox

Role E : BLOCKED en cascade ; le traitement defensif de l'overlap doit rester
compatible avec le codec strict. Verdict B3 : **BLOCKED, non commence**.

## 33. Public API finale

Aucune API publique F1 n'a ete ajoutee. Les barrels `map_core`, `map_gameplay`
et `map_runtime` sont inchanges.

## 34. Compatibility V1

Le namespace `consumedEventIds`, `ScriptCondition.eventIsConsumed`,
`SceneConsequence.markEventConsumed`, les World Rules et les bridges legacy
restent inchanges. Cette conservation evite une regression, mais expose aussi
la divergence Fact que F1-0 doit resoudre avant V2.

## 35. Generated Files

Aucun generated file n'a ete modifie et `build_runner` n'a pas ete lance. Le
stop F1-0 precede tout changement de modele.

## 36. Tests cibles

Baselines executees avant le verdict :

```text
map_core:
dart test --reporter=compact test/narrative_event_registry_test.dart
  test/narrative_event_source_index_test.dart
  test/game_state_persistence_test.dart
  test/scene_runtime_executor_test.dart
Resultat : +47, All tests passed!

map_runtime:
flutter test --reporter=compact test/scene_event_runtime_hook_test.dart
  test/scene_consequence_runtime_writer_test.dart
  test/scene_runtime_state_persistence_gate_test.dart
  test/p3_save_load_narrative_state_roundtrip_test.dart
  test/p5_gameplay_save_load_beta_roundtrip_test.dart
Resultat : +40, All tests passed!

map_core complementaire:
dart test --reporter=compact test/event_builder_contract_test.dart
  test/world_rule_projection_test.dart
Resultat : +10, All tests passed!

map_runtime complementaire:
flutter test --reporter=compact test/runtime_story_branching_test.dart
  test/scene_consequence_runtime_writer_test.dart
Resultat : +15, All tests passed!
```

Le fichier demande `script_condition_evaluator_test.dart` n'existe pas ; le
test reel est `script_system_integration_test.dart`. La commande adaptee avec
`game_state_mutations_test.dart` n'a pas pu charger les packages a cause du
package config stale de `map_gameplay` : `uuid` non resolu depuis `map_core` et
erreurs de language-version. Ce probleme etait present avant toute modification.

Aucun test F1-0/A/B1/B2/B3 n'a ete ajoute : le stop immediat interdit de coder
un comportement fonde sur une semantique arbitraire. Cette regle specifique du
lot prime sur l'obligation generique de creer des tests.

## 37. Tests cumules

La passe H a execute les suites completes pour qualifier le baseline, sans les
presenter comme preuve F1 :

```text
packages/map_core:
dart test --reporter=compact
Resultat : +2908, All tests passed!

packages/map_runtime:
flutter test --reporter=compact
Resultat : +1592 ~1 -17, suite en echec
```

La relance `flutter test --no-color --reporter=expanded` rattache les 17 echecs
aux contrats/fixtures Selbrume existants : catalogue des maps, navigation,
assets, golden slice P6, validator et invariants visuels du Port. Aucun code F1
n'existe ; ces echecs sont donc baseline et non des regressions introduites par
ce lot. La liste exacte figure dans l'Evidence Pack.

Smoke host :

```text
flutter test --reporter=compact test/runtime_launch_save_test.dart
  test/phase_a_golden_slice_launch_test.dart
  test/p5_runtime_project_disk_smoke_test.dart
Resultat : +4, All tests passed!
```

## 38. Analyze/build

```text
packages/map_core: dart analyze -> No issues found!
packages/map_gameplay: dart analyze -> No issues found!
packages/map_runtime: flutter analyze --no-fatal-infos
  -> exit 0, 348 infos, 0 warning, 0 erreur
```

Le build produit F1 et un build desktop n'ont pas ete lances : il n'existe
aucun artefact F1 a compiler et le gate ordonne l'arret avant F1-A. Les tests
Flutter cibles/complets et le smoke host ont compile leurs chemins respectifs.

## 39. Performance

Aucun benchmark F1 n'a ete cree ni execute. Mesurer planner, codec, outbox ou
busy gate inexistants produirait des chiffres inventes. Les matrices de
performance restent des criteres du prochain essai F1 apres resolution.

## 40. Scope final

Modifications volontaires : deux fichiers de documentation F1 uniquement.

Non modifies :

- `packages/map_core/**` ;
- `packages/map_gameplay/**` ;
- `packages/map_runtime/**` ;
- `packages/map_editor/**` ;
- `packages/map_battle/**` ;
- `examples/**` ;
- `selbrume/**` ;
- `assets/**` ;
- ADRs et roadmap.

Le drift preexistant `packages/map_editor/pubspec.lock` reste exclu.

Gate Git final :

```text
 M packages/map_editor/pubspec.lock
?? reports/narrativeStudio/events/ns_event_v2_phase_f1_evidence_pack.md
?? reports/narrativeStudio/events/ns_event_v2_phase_f1_runtime_authority_progress_v0.md

git diff --check : empty
HEAD : 5bf62901d1071d3e17553baef016e4da3b733892
```

`git diff --stat` et `git diff --name-only` ne listent que le lockfile suivi,
car les deux rapports sont encore non suivis. L'anti-scope liste ce meme
lockfile preexistant ; son SHA-256 final est identique au hash initial. Aucun
autre chemin interdit n'apparait.

## 41. Risques residuels

1. Valeur false explicite impossible pour un Fact default true.
2. Conditions Scene `fact` non consommees par le runtime de production.
3. IDs bruts legacy divergents des aliases Fact.
4. Definitions Fact dupliquees : World Rules et writer peuvent choisir des
   occurrences differentes.
5. `canStartDualRead` conflue conflit global et tombstone local.
6. Politique overlap pending/delivered a documenter entre codec strict et garde defensive.
7. Atomicite du host de production et cancellation a traiter avant F2.
8. Drift `map_gameplay` pubspec/package config a rafraichir dans un lot autorise.
9. Reserve E-bis editor map undo toujours heritee et hors scope.

Pour la roadmap mecanique, F1 aurait seulement contribue a FG-014
Save/Load Transaction Hardening. FG-014 reste TODO ; aucun statut mecanique ne
change.

## 42. Entry Gate Phase F2

**Phase F2 : NOT READY.** Aucun des contrats F1 n'est disponible. Les bridges
`mapEnter`, `entityInteract`, `triggerEnter` et `outcomeReceived` ne doivent pas
commencer.

## 43. Auto-review

- Le STOP est fonde sur un invariant explicite du prompt et ADR-EV2-012.
- Aucune solution de stockage n'a ete introduite sans ratification.
- Aucun fichier de production, test ou generated n'a ete touche.
- Les baselines vertes ne sont pas presentees comme preuve F1.
- Les echecs `map_gameplay` sont classes comme dette de metadata preexistante,
  pas comme regression.
- Limite : une preuve executable cross-path ne peut pas etre ajoutee sans
  choisir une semantique ; les extraits de production rendent toutefois la
  contradiction deterministe.

## 44. Review contradictoire

R1 a tente de trouver un resolver existant ou une interpretation ADR permettant
de poursuivre sans modifier les chemins interdits. Verdict :
`BLOCKER-CONFIRMED`. Il confirme les deux contre-exemples deterministes
`defaultValue=true sans flag` et `legacyFlagName present sans ID brut`,
l'impossibilite de `setFact(false)` et l'absence de resolver public canonique.

R1 confirme egalement les ambiguities claim/tombstone et overlap outbox. R2
avait pour mandat de trouver une interpretation plus etroite permettant de
poursuivre. Verdict : `BLOCKER-CONFIRMED`. R2 confirme que `handled`, les gates
non commences et la cloture documentaire sont presentes honnetement. Ses six
corrections de formulation ont ete integrees : preuve par inspection plutot que
test cross-path, statut final des agents, overlap comme garde defensive,
precision du Fact absent, timing oneShot et nuance des tombstones.

## 45. Critique du prompt

Le prompt a raison d'imposer F1-0 et le stop-on-divergence ; ce garde-fou a
evite un second moteur Fact. Trois points doivent etre corriges avant relance :

1. resoudre la reserve Fact deja annoncee en Phase A avant de declarer F1
   executable ;
2. distinguer le gate de transition `canStartDualRead` du gate d'autorite
   runtime permettant des tombstones locaux ;
3. documenter la coexistence du codec strict avec la garde defensive B3 pour un
   overlap pending/delivered injecte en memoire.

Le scope F1 est egalement tres large pour un seul lot. Apres le prerequis Fact,
conserver les gates A, B1, B2 et B3 comme commits/reviews independants reduira
le risque.

## 46. Verdict Phase F1

```text
PHASE F1 : BLOCKED
F1-0 — Runtime Semantics Gate : BLOCKED
F1-A / V2-17 : BLOCKED
F1-B1 / V2-18 : BLOCKED
F1-B2 / V2-18 : BLOCKED
F1-B3 / V2-18 : BLOCKED
PHASE F2 : NOT READY
```

Prochain lot recommande, sans l'ajouter a la roadmap : **Canonical Fact Runtime
Semantics & F1 Contract Clarification V0**. Il doit ratifier l'override Fact,
aligner les consumers de production, clarifier claim/tombstone et overlap
outbox, puis rouvrir F1 depuis la meme baseline fonctionnelle.
