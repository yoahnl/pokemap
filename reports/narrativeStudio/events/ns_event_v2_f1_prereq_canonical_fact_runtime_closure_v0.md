# NS-EVENT-V2 — F1-PREREQ — Canonical Fact Runtime Semantics, Dual-Read Readiness & Outbox Contract Closure V0

## 1. Résumé exécutif

```text
F1-PREREQ : CLOSED

PR-0 : PASS
PR-A : PASS
PR-B : PASS
PR-C : PASS
PR-D : PASS

default true -> explicit false : PASS
World Rules canonical Fact : PASS
Scene condition canonical Fact : PASS
Fact save/reload : PASS
canEnterDualRead : PASS
canRunDualRead : PASS
typed tombstones : PASS
outbox contract : PASS

F1 implementation added : NO
Production source bridge added : NO
Real project data modified by this lot : NO

Phase F1 : READY
Phase F2 : NOT READY
```

Le lot ajoute un état runtime Fact explicite et persistant, un resolver et un
writer partagés, l'alignement des quatre familles de consommateurs canoniques,
et une readiness dual-read qui distingue les conflits globaux des tombstones
locaux. Il ratifie aussi le contrat outbox strict-wire/defensive-memory sans
implémenter l'outbox.

La suite runtime complète n'est pas verte dans le worktree partagé : 45 tests
Selbrume échouent parce qu'une autre conversation a changé
`selbrume/project.json` vers `ProjectSchemaVersion.v2`, alors que ce runtime
courant ne décode que `v1`. Le fichier était propre au Gate 0 et n'a pas été
touché par ce lot. Les 112 fichiers de test sans référence textuelle à Selbrume
passent avec 1102 tests, les 39 tests runtime ciblés passent, et le host macOS
build. Cette réserve concurrente est conservée honnêtement sans élargir le
scope interdit.

## 2. Baseline et Blocker F1

- HEAD de départ : `a2ee6bbdb67389336452c5431e523f179a481335`.
- Commit : `docs(event-v2): report NS-EVENT-V2 Phase F1 blocker`.
- Dernière baseline production : `5bf62901d1071d3e17553baef016e4da3b733892`.
- Cause du STOP F1-0 : sémantique Fact divergente, readiness claims sans preuve
  corpus et contradiction overlap outbox non ratifiée.
- Les deux rapports historiques F1 ont été conservés sans réécriture.

## 3. Usage MCP Dart

Le MCP Dart n'était pas disponible dans les outils de cette session. Aucun
usage MCP n'est revendiqué. La compensation a utilisé `rg`, lectures ciblées,
tests Dart/Flutter, analyses, build_runner, build macOS et reviews indépendantes.

## 4. Sous-agents et incidents

| Rôle | Mission | Verdict |
|---|---|---|
| A | Fact Domain & Save Codec | PASS |
| B | Fact Resolver & Writer | PASS |
| C | Production Consumers | PASS après fermeture du faux fallback raw |
| D | Dual-Read Contract | PASS après fermeture de la preuve corpus |
| E | Outbox Contract | PASS après correction des frontières de crash |
| F | Save/Load & Compatibility | PASS |
| G | Tests, Docs & F1 Reopening | PASS après reprise orchestrateur |
| R1 | Runtime Integrity | PASS PR-A/B/C/D |
| R2 | Compatibility Truthfulness | PASS PR-A/B/C/D |
| Orchestrateur | intégration, arbitrage et preuves finales | PASS avec réserve runtime concurrente |

Incident G : le rôle, pourtant assigné en lecture seule, a créé le benchmark et
modifié le codec/tests PR-C. Il a été interrompu. L'orchestrateur a audité les
quatre fichiers, repris ou corrigé chaque changement, puis relancé les tests. Le
benchmark utile a été adopté. Aucun incident n'a réduit les critères.

Incident PR-B : R2 a identifié qu'un contexte Fact global requalifiait aussi
les pages legacy non marquées. La correction rend le contexte page-scoped via
`EventPageResolver.contextForPage` et l'active seulement pour une provenance
Event Builder reconnue. Le schema courant et le legacy `reusePolicy` valide
sont acceptés ; un schema futur, malformed ou absent sans marqueur reste raw.
Les deux reviewers ont ensuite rendu PASS sans blocker.

Incident tooling : une commande de test a d'abord nommé un fichier inexistant,
puis le bon test gameplay a passé. Une invocation Flutter via le SDK FVM stable,
incompatible avec le package config beta du repo, a aussi été arrêtée ; toutes
les validations Flutter finales utilisent `/opt/homebrew/share/flutter/bin`.

Incident PR-D : une première review a demandé des champs d'enveloppe étrangers
au modèle canonique exact. Ce finding a été rejeté avec preuve de la spec F1.
Les remarques pertinentes ont conduit à définir `deliveryId` comme identité
stable, puis à corriger une vraie ambiguïté entre pending durable et création
jamais sauvegardée. Les reviews finales concluent PASS.

## 5. Gate 0

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

Le lock editor préexistant avait et conserve le SHA-256
`a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc`.

`dart pub deps` dans `map_gameplay` a signalé le lock/package config stale.
Le `dart pub get` explicitement autorisé a ajouté uniquement les transitives
`uuid 4.5.3` et `fixnum 1.1.1`, nécessaires au `map_core` courant. Hash lock :
`83b13b3f...` -> `ef1601ab...`. Les deux fichiers `.dart_tool` déjà suivis ont
été rafraîchis en cohérence avec ce lock.

Baselines avant code : `map_core` 42 tests PASS + analyze PASS ;
`map_gameplay` 25 tests PASS + analyze PASS ; `map_runtime` 16 tests PASS.

## 6. PR-0 Contract Ratification

Trois addenda `Accepted` ont été ajoutés sans réécrire les ADR historiques :

- `ADR-EV2-012-A — Canonical Fact Runtime Overrides & Resolution` ;
- `ADR-EV2-008-A — Dual-Read Entry Gate vs Runtime Readiness` ;
- `ADR-EV2-014-A — Strict Outbox Wire Invariant & Defensive Runtime Guard`.

Les matrices Facts, dual-read et outbox sont explicites. Les passes architecture
et compatibilité ont conclu PASS avant PR-A.

## 7. Fact Semantic Decision

La valeur canonique suit exactement : override explicite par `fact.id`, puis
runtime key legacy active, puis `defaultValue`. Une valeur false explicite ne
disparaît jamais quand elle égale le default courant.

## 8. Fact Runtime State

`NarrativeFactRuntimeState` expose une map immuable
`overridesByFactId: Map<String, bool>`. Il valide les IDs non vides et
trim-exacts, copie défensivement les entrées et possède equality/hash stable.

## 9. Wire Format

```json
{
  "overridesByFactId": {
    "fact_gate_open": false,
    "fact_rival_defeated": true
  }
}
```

Les clés sont triées lexicalement. Les valeurs non booléennes, sous-arbres
invalides, IDs vides ou non trim-exacts sont rejetés sans normalisation.

## 10. Old Save Compatibility

L'absence du sous-arbre dans `GameState` ou `SaveData` produit l'état vide. Les
story flags ne sont pas transformés en overrides au load. Les overrides
orphelins sont conservés et jamais rapprochés par label/alias.

## 11. Runtime Key Collision Policy

Le catalogue détecte : duplicate Fact ID, duplicate alias, alias égal à l'ID
d'un autre Fact et duplicate runtime key. Une ambiguïté retourne un résultat
typé et bloque les consommateurs canoniques ; aucun premier gagnant.

## 12. Canonical Resolver

`NarrativeFactRuntimeResolver` construit un index immuable en O(n), puis résout
en lookup O(1). Les résultats sont typés : valeur résolue et source,
`unknownFact`, `ambiguousFact` ou `invalidRuntimeKey`.

## 13. Canonical Writer

`writeNarrativeFactRuntimeValue` écrit toujours l'override, synchronise le
runtime key legacy dans `StoryFlags`, conserve les autres champs et ne touche
jamais `consumedEventIds`. Un rejet retourne l'état original et une raison
stable.

## 14. World Rules Alignment

`projectWorldRuleEffects` et les diagnostics utilisent le resolver partagé.
Le cas `default true + override false` projette false. Les catalogues ambigus
restent fail-closed et diagnostiqués.

## 15. Scene Consequence Alignment

`SceneConsequenceRuntimeWriter` délègue `setFact` au writer partagé. Le commit
multi-conséquences reste atomique : une écriture Fact rejetée annule le lot.

## 16. Scene Condition Alignment

`SceneConditionSourceKind.fact` est résolu par le helper partagé avec les
opérateurs `isTrue`, `isFalse` et `equals bool`. `factLikeStoryFlag` reste un
flag brut legacy.

## 17. ScriptCondition Compatibility

`ScriptEvaluationContext` accepte un contexte Fact canonique optionnel.
`flagIsSet/flagIsUnset` ciblant un Fact utilisent le resolver ; sans contexte,
le comportement raw historique est inchangé. `EventPageResolver` accepte un
`contextForPage` afin de décider cette qualification pour chaque page.

`PlayableMapGame` fournit le contexte canonique uniquement si
`hasEventBuilderPageProvenance(page)` reconnaît le schema Event Builder courant
ou, pour les anciennes pages sans schema, un `reusePolicy` historique valide.
La présence d'un schema futur ou malformed interdit expressément le fallback
legacy. Une page non marquée qui utilise par hasard le même nom qu'un Fact reste
donc un flag brut, ce qui ferme le faux correctif détecté par R2.

## 18. Cross-Consumer Matrix

| Cas | Resolver | World Rule | Scene Fact | Script contextuel |
|---|---:|---:|---:|---:|
| default false, rien | false | false | false | false |
| default true, rien | true | true | true | true |
| alias actif | true | true | true | true |
| override false | false | false | false | false |
| alias + override false | false | false | false | false |
| override true | true | true | true | true |

Les tests de frontière page-scoped prouvent en plus : provenance schema
courante canonicalisée, provenance legacy `reusePolicy` canonicalisée, page
non marquée conservée raw, et schema futur conservé raw même avec un
`reusePolicy` par ailleurs valide.

## 19. Save/Reload Evidence

Le chemin `default true -> setFact(false) -> save -> reload` reste false. Le
round-trip disque conserve true, false et override orphelin. Une ancienne save
sans champ charge un état vide. `consumedEventIds` et story flags simples restent
inchangés au load.

## 20. PR-A Review

R1 et R2 : PASS. Gate final PR-A : 48 tests core PASS, 6 tests runtime PASS,
analyze core PASS, format PASS et build_runner PASS.

## 21. PR-B Review

R1 et R2 : PASS. Gate final PR-B : 21 tests core PASS, 23 tests gameplay PASS,
27 tests runtime PASS. La clôture de compatibilité ajoute 13 tests core de
provenance et 1 test editor historique ; analyses sans erreur.

## 22. Dual-Read Entry Gate

`canStartDualRead` reste l'alias strict de `canEnterDualRead`. Avec claims, le
builder registry-only sans evidence runtime reste fail-closed. L'entrée exige
absence de conflit global, absence de tombstone local et preuve corpus validée.

## 23. Runtime Readiness

`canRunDualRead` exige absence de conflit global et evidence runtime validée.
Les tombstones locaux n'arrêtent pas les autres sources. Une collision globale
de cohorte/source/provenance bloque toute résolution runtime.

## 24. Typed Source Tombstones

`resolveSource` retourne une union fermée `absent`, `valid` ou `tombstone`.
Le tombstone conserve source, claim/cohort quand disponibles et diagnostics
stables/immuables. Aucun null ambigu.

## 25. Typed Provenance Tombstones

`resolveProvenance` expose les mêmes variantes pour `LegacySourceRef`. Une
source et sa provenance valides doivent pointer la même cohorte ; la divergence
échoue pendant la préparation.

## 26. Claim Compatibility

Le codec registry, le JSON claims, fingerprints, receipts, plans et règles de
création de claims sont inchangés. La preuve corpus est fournie séparément via
`LegacyClaimRuntimeEvidence`. Les claims sans preuve ne sont pas déclarés
runtime-ready.

## 27. PR-C Review

Le premier R2 a bloqué la validation registry-only, qui pouvait présenter un
fingerprint stale comme valide. La correction a ajouté le builder corpus-aware,
les diagnostics typed tombstones et les gates fail-closed. Reviews finales R1
et R2 : PASS. Gate PR-C : 113 tests PASS, analyze PASS.

## 28. Outbox Contract Closure

`deliveryId` est l'identité stable d'une commande logique et sa clé
d'idempotence ; aucun `dispatchId` secondaire n'est inventé. Wire et
constructeurs futurs rejetteront overlap pending/delivered et duplicate pending.
Une incohérence mémoire overlap est terminalisée sans dispatch, sans tentative
ni enfant, avec `dataInconsistency` ; le decode ne la répare jamais.

Les frontières de crash distinguent : création jamais sauvegardée (delivery et
effets producteur absents après reload), pending déjà durable (même ID restauré)
et terminal delivered durable (aucun replay). L'exactly-once d'un effet externe
hors commit `GameState` reste hors garantie V0 et exige un protocole idempotent.

## 29. PR-D Review

Après deux boucles contradictoires, R1, R2 et le rôle E concluent PASS. La
matrice wire/mémoire et 17 tests futurs sont ratifiés. Aucun modèle, codec ou
processor outbox n'est présent dans ce lot.

## 30. Public API

Exports ajoutés : `NarrativeFactRuntimeState`, resolver/catalog/results/writer
Fact, et helper Scene condition via le barrel runtime. Les types de résolution
claims sont publics ; leurs constructeurs restent contrôlés par l'index.

## 31. Generated Files

Les generated `GameState` et `SaveData` ont été régénérés. Aucun autre modèle
généré n'a dérivé. Second passage build_runner : succès, `0 outputs` écrits ;
warning non bloquant analyzer language `3.9` vs SDK `3.12`.

## 32. Tests ciblés

```text
PR-A core       : 48 PASS
PR-A runtime    : 6 PASS
PR-B core       : 21 PASS
PR-B gameplay   : 23 PASS
PR-B runtime    : 27 PASS
Provenance core : 13 PASS
Editor legacy   : 1 PASS
PR-C core       : 113 PASS
Runtime cumulé  : 39 PASS
Host smoke      : 4 PASS
Performance     : 1 PASS
```

## 33. Tests cumulés

```text
map_core complet       : 2955 PASS
map_gameplay complet   : 245 PASS
map_runtime ciblé      : 39 PASS
map_runtime complet    : 1559 PASS, 1 SKIP, 45 FAIL
runtime non-Selbrume   : 112 files, 1102 PASS
host smoke             : 4 PASS
```

Les 45 erreurs complètes ont toutes la même cause racine :
`Invalid argument(s): v2 is not one of the supported values: v1` en lisant le
`selbrume/project.json` concurrent. La liste exacte est dans l'Evidence Pack.

## 34. Analyze/build

```text
map_core dart analyze                  : No issues found
map_gameplay dart analyze              : No issues found
map_runtime analyze ciblé final, 2 items: No issues found
map_runtime flutter analyze            : 348 infos, exit 1 avec fatal-infos
map_runtime --no-fatal-infos            : exit 0, aucune warning/error
map_core build_runner, second passage  : success, 0 outputs
host flutter build macos --debug       : PASS
  build/macos/Build/Products/Debug/playable_runtime_host.app
```

Les 348 infos runtime sont une dette de lint existante, sans warning/error et
hors scope. Aucun build map_editor n'était demandé ni pertinent.

## 35. Performance

Machine : MacBook Pro `MacBookPro18,3`, Apple M1 Pro 10 cœurs, 32 Go, macOS
27.0 build 26A5378j. Dart 3.12.1 stable macOS arm64, JIT ; AOT non mesuré.

| Opération | Volume | moyenne µs | médiane µs | p95 µs |
|---|---:|---:|---:|---:|
| resolver override | 1 | 0.214 | 0.183 | 0.526 |
| resolver override | 100 | 0.051 | 0.048 | 0.072 |
| resolver override | 1 000 | 0.068 | 0.067 | 0.076 |
| resolver override | 10 000 | 0.083 | 0.079 | 0.117 |
| resolver alias | 10 000 | 0.085 | 0.083 | 0.095 |
| resolver default | 10 000 | 0.087 | 0.085 | 0.092 |
| resolver absent | 10 000 | 0.024 | 0.024 | 0.025 |
| codec round-trip | 0 | 0.999 | 0.790 | 1.780 |
| codec round-trip | 100 | 40.135 | 35.000 | 52.400 |
| codec round-trip | 10 000 | 4022.000 | 3769.000 | 5751.000 |
| claim valide | 0 | 2.532 | 2.150 | 4.900 |
| claim valide | 100 | 541.600 | 500.500 | 946.000 |
| claim valide | 10 000 | 20842.857 | 21139.000 | 25317.000 |
| tombstone local | 10 000 | 28249.857 | 23859.000 | 49924.000 |
| collision globale | 10 000 | 30634.000 | 29800.000 | 33662.000 |

Resolver : index O(n), lookup O(1). Codec : O(k log k) pour le tri stable.
Claim index : O(records + claims + targets), avec tri supplémentaire des
conflits. 30 itérations x batch 1000 pour resolver ; codec 30/20/7 ; claims
20/20/7. Aucun seuil flaky ni cache global mutable.

## 36. Scope final

```text
 M "MVP Selbrume/event_builder_v2_architecture_decisions.md"
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/event_builder_contract.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
 M packages/map_core/lib/src/models/game_state.dart
 M packages/map_core/lib/src/models/game_state.freezed.dart
 M packages/map_core/lib/src/models/game_state.g.dart
 M packages/map_core/lib/src/models/save_data.dart
 M packages/map_core/lib/src/models/save_data.freezed.dart
 M packages/map_core/lib/src/models/save_data.g.dart
 M packages/map_core/lib/src/operations/game_state_persistence.dart
 M packages/map_core/lib/src/operations/narrative_event_registry_codec.dart
 M packages/map_core/lib/src/projection/world_rule_projection.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/event_builder_authoring_operations_test.dart
 M packages/map_core/test/game_state_persistence_test.dart
 M packages/map_core/test/narrative_event_registry_test.dart
 M packages/map_core/test/save_data_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_core/test/world_rule_projection_test.dart
 M packages/map_editor/pubspec.lock
 M packages/map_gameplay/.dart_tool/package_config.json
 M packages/map_gameplay/.dart_tool/package_graph.json
 M packages/map_gameplay/lib/src/event_page_resolver.dart
 M packages/map_gameplay/lib/src/new_game_state_builder.dart
 M packages/map_gameplay/lib/src/script_condition_evaluator.dart
 M packages/map_gameplay/pubspec.lock
 M packages/map_gameplay/test/new_game_state_builder_test.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
 M packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
 M selbrume/project.json
?? packages/map_core/lib/src/models/narrative_fact_runtime_state.dart
?? packages/map_core/lib/src/operations/narrative_fact_runtime.dart
?? packages/map_core/test/narrative_fact_runtime_performance_test.dart
?? packages/map_core/test/narrative_fact_runtime_resolver_test.dart
?? packages/map_core/test/narrative_fact_runtime_state_test.dart
?? packages/map_core/test/narrative_fact_runtime_writer_test.dart
?? packages/map_core/test/project_validator_test.dart
?? packages/map_core/test/validated_legacy_claim_index_runtime_readiness_test.dart
?? packages/map_gameplay/test/narrative_fact_script_condition_test.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart
?? packages/map_runtime/test/narrative_fact_runtime_cross_consumer_test.dart
?? packages/map_runtime/test/narrative_fact_runtime_save_load_test.dart
?? reports/narrativeStudio/events/ns_event_v2_f1_prereq_canonical_fact_runtime_closure_v0.md
?? reports/narrativeStudio/events/ns_event_v2_f1_prereq_evidence_pack.md
?? selbrume/assets/borders/snapshots/b9a77cfa1bf35d89d0854b7c180f974b1400474cc27e05db0d9ee93f82b5b38a/frame_0000.png
?? selbrume/assets/borders/snapshots/d12d89c830a4e1f88038afc8e868282ca24d8a1dfc42505b7e3593cc97ea95c0/frame_0000.png
?? selbrume/assets/borders/snapshots/f7dff67260a8197d15f892ecca9b8099cadb1f4c24176b4c64246c48e719e3c9/frame_0000.png
?? selbrume/assets/borders/snapshots/ff1052a8600830f40d9e04e5dce67d879962e567481f832e26249e4706d4d779/frame_0000.png
```

`git diff --check` : vide. Anti-scope :

```text
packages/map_editor/pubspec.lock
selbrume/project.json
```

Le premier est le drift préexistant hashé au Gate 0 ; le second et les quatre
snapshots Selbrume sont des changements concurrents apparus pendant le lot.


Fichiers du lot : deux docs normatifs, `map_core`, `map_gameplay`, `map_runtime`,
tests et deux rapports. Aucun `map_editor`, `map_battle`, asset, source host,
bridge, UI, migration ou donnée projet n'a été modifié par ce lot.

Le worktree partagé contient néanmoins le lock editor préexistant et des
changements Selbrume apparus pendant l'exécution. Leurs hashes et leur statut
sont isolés dans l'Evidence Pack ; ils ne sont ni revendiqués ni nettoyés.

## 37. Risques résiduels

1. La suite runtime complète doit être relancée après convergence du chantier
   concurrent `ProjectSchemaVersion.v2`.
2. Les pages legacy sans marqueur Event Builder restent volontairement raw ;
   toute future extension de provenance devra conserver le refus des schemas
   inconnus et être accompagnée d'une preuve de compatibilité.
3. F1 doit réellement implémenter et tester les 17 cas outbox ; ce lot ne fait
   que ratifier leur contrat.
4. La garantie exactly-once externe reste volontairement hors V0.

## 38. F1 Reopening Gate

Tous les critères fonctionnels propres au prérequis sont prouvés : false
explicite persistant, consumers alignés, collision-safe, claims corpus-aware,
tombstones locaux, global conflicts bloquants et contrat outbox accepté. Aucun
planner prématuré n'existe. F1 est READY pour V2-17/V2-18 ; F1 n'est pas CLOSED.
F2 reste PLANNED / NOT READY.

## 39. Auto-review

Le changement est large parce qu'il ferme trois blockers transverses, mais les
frontières restent celles du prompt. Les principales vigilances ont été la
propagation de l'état Fact dans tous les codecs, l'absence de second resolver,
la preuve corpus obligatoire et la séparation contract/implementation outbox.

Le choix registry-only fail-closed avec claims est plus strict que le
comportement historique, mais il empêche précisément un runtime de confondre
structure plausible et readiness prouvée. Les projections structurelles restent
disponibles ; les résolutions runtime refusent l'absence d'evidence.

La première intégration PR-B était trop large : disposer d'un registry Fact ne
suffit pas à prouver qu'une condition de page legacy vise ce Fact. Le contexte
par page et la provenance stricte restaurent le comportement raw historique
sans réduire la sémantique canonique des pages réellement issues du builder.

## 40. Review contradictoire

R1 a cherché les pertes d'override, divergences de readers, writes legacy-only,
double dispatch et confusion conflit/tombstone. R2 a cherché migration eager,
drop orphelin, mutation consumed IDs, raw flags requalifiés, roadmap mensongère
et save/load regressé. R2 a effectivement trouvé la requalification trop large
des pages non marquées ; après `contextForPage`, détection de provenance stricte
et matrices current/legacy/absent/future, R1 et R2 ont rendu PASS sans blocker
sur l'arbre final.

## 41. Critique du prompt

Le prompt est précis et a correctement séparé prérequis et F1. Deux tensions ont
été arbitrées : `codex_rule.md` demande un maximum de commentaires, tandis que
le prompt interdit tout nouveau commentaire de code ; l'instruction directe,
plus prioritaire, a été respectée. Les seuls commentaires ajoutés visibles dans
le diff sont des ignores générés automatiquement par Freezed.

La formule PR-C littérale ne mentionnait pas la preuve corpus découverte par la
review. Déclarer `canRunDualRead` depuis le registry seul aurait menti. L'API a
donc été étendue avec `LegacyClaimRuntimeEvidence`, conformément à l'objectif
runtime readiness, sans modifier le wire claims.

Enfin, exiger une suite complète verte tout en interdisant Selbrume devient
impossible quand une autre conversation change ce fichier pendant le lot. La
réponse la plus sûre a été de ne pas le restaurer et de produire une isolation
reproductible des 45 erreurs plus une suite non-Selbrume verte.

## 42. Verdict

```text
F1-PREREQ : CLOSED
PR-0 — Contract Ratification : PASS
PR-A — Fact Runtime Domain & Persistence : PASS
PR-B — Canonical Production Alignment : PASS
PR-C — Dual-Read Runtime Readiness : PASS
PR-D — Outbox Contract Closure : PASS
PHASE F1 : READY
PHASE F2 : NOT READY
```

Réserve : le worktree partagé ne permet pas d'affirmer que la suite runtime
globale est verte tant que le projet Selbrume v2 concurrent n'est pas pris en
charge. Cette réserve n'est pas une régression du lot F1-PREREQ et ne justifie
aucune modification hors scope.
