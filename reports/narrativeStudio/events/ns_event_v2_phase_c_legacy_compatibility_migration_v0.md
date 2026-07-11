# NS-EVENT-V2 — Phase C — Legacy Compatibility, Claim Closure & Non-Destructive Migration V0

## 1. Résumé exécutif

```text
PHASE C : CLOSED
C0 : PASS
C1 : PASS
C2 : PASS
C3 : PASS
C4 : PASS

Data loss risk : NONE
Real project migrated : NO
Legacy data modified : NO
Phase D : READY au périmètre Phase C
```

La Phase C livre une couche de caractérisation et de compatibilité read-only,
ainsi qu'un planner de migration pur. Elle ne migre aucun projet et ne modifie
aucune donnée legacy. Les MapEvents et les sources Scenario sont caractérisés,
classés et projetés sans inférence silencieuse. Les claims sont vérifiés par
source et provenance. Le plan, les mappings et le receipt restent des valeurs
immuables non écrites.

La suite complète `map_core` passe avec 2 755 tests. Les analyses ciblées et
globales `map_core` passent. Les tests et analyses ciblés editor/runtime
passent, et le build macOS editor passe. L'analyse globale `map_editor` reste
rouge avec 438 diagnostics, dont 81 erreurs dans deux fichiers Pokemon SDK
inchangés par ce lot et identiques à `HEAD`; cette dette préexistante n'est pas
présentée comme verte.

## 2. Baseline Phase B

- Baseline : `fdaf4e5ddfb82981353c104c89377f061b207e2e`.
- Commit : `fdaf4e5d NS-EVENT-V2 PHASE B: Canonical Domain Contracts & Structural Source Index`.
- Phase B : `CLOSED`, B1 à B4 `PASS`.
- Contrats conservés : Event déclenche, Scene orchestre, claim complet,
  registry strict, source index structurel et aucun consumer runtime V2.
- ADR et architecture canonique inchangés.

## 3. Usage MCP Dart

MCP Dart était disponible. Il a été utilisé sur `map_core`, `map_editor` et
`map_runtime` pour inspecter les contrats, les symboles et les diagnostics.
Symboles principaux : `NarrativeEventRecord`, `NarrativeEventRegistry`,
`ValidatedLegacyClaimIndex`, `MapEventDefinition`, `ScenarioAsset`,
`SceneAsset`, `ProjectManifest`, `create/update/delete Scenario`, sources,
claims et opérations structurelles.

Diagnostic MCP final exact :

```text
No errors
```

## 4. Sous-agents et incidents

Passes spécialisées exécutées :

- A — Audit / architecture / C0 : fermeture des réserves Phase B.
- B — Corpus legacy / runtime characterization : inventaire et hash C1.
- C — MapEvent adapter : projection C2 sans write ni position inference.
- D — Scenario compatibility : équivalence Scene et authoring freeze C3.
- E — Planner / claims / receipt : plan déterministe et recovery C4.
- F — Tests / build : gates ciblés, suites cumulées et build macOS.
- G — Scope : contrôle runtime, gameplay, battle, Selbrume et generated.
- H — Evidence : inventaires, hashes, rapports et roadmap.
- R1 — reviewer contradictoire architecture/idempotence.
- R2 — reviewer contradictoire failure modes/receipt.
- Orchestrateur principal — séquencement strict C0 → C1 → C2 → C3 → C4.

Plusieurs appels agents ont rencontré des réponses service `Bad Request` ou
des limites temporaires de threads. Les agents concernés ont été repris ou
fermés; aucun verdict n'a été inventé et aucun résultat n'a été accepté sans
preuve locale. Une dérive temporaire créée par un worker dans `map_gameplay`
a été retirée avant poursuite; le gate final confirme l'absence de diff dans ce
package. Les deux reviewers finaux n'ont modifié aucun fichier.

## 5. Gate 0

```text
$ pwd
/Users/karim/Project/pokemonProject
$ git branch --show-current
main
$ git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock
$ git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)
$ git diff --name-only
packages/map_editor/pubspec.lock
```

Drift préexistant : `packages/map_editor/pubspec.lock`.

```text
hash fichier initial = 2fac1583a9d5864cd3bc13f2aa7a0831274bfe0fde7380782ff68d0820e90ac6
hash diff initial    = 6b33cb8d5361c91b2aa9c8e3fcfebc99a8c3f64c4a822ff8ca55b2097d075511
```

Versions :

```text
Dart SDK 3.12.1 stable, macos_arm64
Flutter 3.46.0-0.3.pre beta
Flutter tool Dart 3.13.0 beta
```

## 6. C0 Phase B Contract Closure

C0 ferme quatre réserves :

1. `ValidatedLegacyClaimIndex` indexe les claims par source et par
   `LegacySourceRef`, y compris les tombstones invalides.
2. Les opérations context-free sont nommées explicitement
   `...StructurallyUnchecked`; aucune API publique ne prétend valider Scene,
   Fact, conflits ou catalogues de Phase E.
3. Le plancher Dart `>=3.4.0` est accepté par les consumers workspace audités.
4. Le pack JCS est reproductible localement, sans réseau.

Gate C0 final :

```text
47 tests passed
DART SDK BASELINE : ACCEPTED
JCS REPRODUCIBILITY : PASS
```

## 7. C0 Reviews

```text
C0 REVIEW R1 : PASS
C0 REVIEW R2 : PASS
```

Les corrections issues des reviews couvrent notamment la stricte fermeture
des opérations, le lookup source/provenance, les surrogates invalides, les
clés dupliquées et la reproductibilité numérique JCS.

## 8. C1 Corpus legacy

Fixture canonique :
`packages/map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.json`.

```text
SHA-256 : 6aa7be80b6819d1b9d2f062172e8bca511cbf82fde98a3863eb3e7f856d5c86c
maps : 2
MapEvents : 13
Scenarios : 11
Scenes : 4
cases : 24
references : 12
```

Classifications :

```text
AUTO_SAFE : 4
ASSISTED : 2
BLOCKED : 13
LEGACY_ONLY : 3
UNSUPPORTED : 2
```

Le corpus caractérise l'ordre first-valid, les pages cachées/désactivées, les
collisions inter-map, sources Scenario, références, saves, World Rules,
conséquences, scripts, cohortes et données inconnues. Il n'est jamais utilisé
comme entrée d'écriture.

## 9. C1 Reviews

```text
C1 REVIEW R1 : PASS
C1 REVIEW R2 : PASS
```

Gate C1 final : `19 tests passed`. La caractérisation runtime ajoute trois
tests Flutter sans modification du runtime de production.

## 10. C2 MapEvent adapter

`projectLegacyMapEventReadOnly` produit une `LegacyMapEventProjection`
immuable : provenance, fingerprint, candidats de source, pages préservées,
références, diagnostics, classification et claim éventuel.

Invariants :

- metadata explicite actor/object/trigger peut confirmer une source;
- une position seule reste `ASSISTED` et ne confirme jamais une source;
- plusieurs footprints restent bloquants;
- MapEvent autonome, source cassée, Scene absente, script/message opaque et
  multi-page non prouvé ne sont pas aplatis;
- l'ordre des pages et le JSON original sont préservés;
- aucun MapEvent, map, Scene ou metadata n'est modifié.

## 11. C2 Reviews

```text
C2 REVIEW R1 : PASS
C2 REVIEW R2 : PASS
```

Gate C2 final : `20 tests passed`.

## 12. C3 Scenario compatibility

Le projecteur Scenario relit le `ScenarioAsset` complet, le node source et la
Scene candidate. Une projection `AUTO_SAFE` exige une Scene unique,
buildable, sans outcomes déclarés et dont la trace observable est équivalente.
Un graphe complexe, plusieurs sources, un binding malformé ou une trace
divergente ne sont jamais aplatis.

Le guard editor s'applique aux create/update/delete Scenario. Quand un claim
valide ou tombstone revendique une provenance ou une source, l'authoring du
Scenario concerné est refusé avec un message humain. Les Scenarios non claimés
gardent le comportement V1.

## 13. C3 Reviews

```text
C3 REVIEW R1 : PASS
C3 REVIEW R2 : PASS
```

Gates finaux :

```text
map_core C3 : 19 tests passed
map_editor guard + régressions : 8 tests passed
runtime characterization : 3 tests passed
```

## 14. C4 Migration planner

`NarrativeEventMigrationPlanner` reçoit uniquement des valeurs explicites :
manifest, maps, projections, corpus, références, saves, snapshots, choix,
registry et receipt éventuels. Il n'accède pas au filesystem.

Le planner produit : status, records/drafts proposés, claims, cohortes,
mappings IDs/pages/références, diagnostics, write preconditions, backup plan,
rollback, point de non-retour et receipt sérialisable.

Durcissements issus des reviews :

- validation exacte manifest/maps/sources/saves/catalogue/corpus;
- Scenes MapEvent et Scenario uniques, buildables et encore équivalentes;
- IDs Scenario/Scene dupliqués bloquants;
- choices Scenario bornés à la projection caractérisée;
- signatures de targets uniques et records préparés désactivés;
- receipt exact, mappings complets et décisions fan-out rejouables;
- idempotence sans nouveaux IDs, y compris mappings distincts et stable keys;
- extension incrémentale bloquée tant qu'un historique de receipts n'existe pas;
- receipt malformé rejeté au decode plutôt que de lever pendant le replay;
- unknown JSON préservé ou bloquant;
- aucun write, backup réel, rename, activation ou migration réelle.

## 15. C4 Reviews

Les reviewers ont d'abord bloqué plusieurs faux positifs d'idempotence et de
receipt. Chaque finding a reçu un test de régression avant nouvelle review.

Verdicts finaux exacts :

```text
C4 REVIEW R1 : PASS
C4 REVIEW R2 : PASS
```

Gate C4 final : `88 tests passed`; `dart analyze` : `No issues found!`.

## 16. Reference graph

Le catalogue distingue cinq domaines : progression, conditions, World Rules,
conséquences et saves. Les kinds sont validés contre leur domaine. Chaque
référence conserve path, legacy ID, map éventuelle et provenances candidates.
Le corpus et le catalogue doivent être exactement égaux sur ces dimensions.

Les mappings finaux exposent IDs, pages, target keys et décisions, sans
modifier le consumer legacy. Les références unqualified ne choisissent jamais
le premier match.

## 17. Collision policy

- Un ID legacy nu avec plusieurs provenances reste `requiresChoice`.
- Décisions admises : tous les targets pour progression/save, sélection
  explicite ou annulation.
- La sélection fan-out avant allocation utilise une stable target key fondée
  sur provenance + signature cible.
- Une sélection inexistante, une clé stale, un mauvais domaine ou un choix
  inutilisé bloque avant allocation d'ID.
- Aucun premier match automatique.

## 18. Claims/cohortes

Les cohortes groupent toutes les provenances partageant la même source V2.
Le `cohortId` et le fingerprint sont canoniques. Un claim valide doit couvrir
exactement ses membres et ses targets. Les partial claims, siblings omis,
claims orphelins, tombstones, doublons de signatures et receipts absents ou
stales restent fail-closed.

Source lookup et provenance lookup résolvent le même claim. Après préparation,
les mappings par provenance sont restaurés depuis le receipt exact; leur union
doit couvrir exactement les targets du claim.

## 19. JCS reproducibility

Commandes finales :

```text
dart run tool/verify_narrative_event_jcs_vectors.dart
Verified 4 canonical vectors 6 official corpus pairs, 24 number vectors,
12 rejection vectors, 2 Phase B hashes, and 2 claim vectors.

dart run tool/verify_narrative_event_jcs_number_oracle.dart
Verified 200000 deterministic IEEE-754 values against Node;
checksum b4294dfb5683285868d038434aaf0d0dfd0fd0cdb7570d79107757f9fd500b57.
```

L'oracle Node est optionnel et local. Les goldens normaux restent vérifiables
par Dart sans réseau.

## 20. Migration classifications

- `AUTO_SAFE` : équivalence et source prouvées; lifecycle explicite requis si
  absent.
- `ASSISTED` : choix humain nécessaire et borné par les preuves disponibles.
- `BLOCKED` : ambiguïté, source/Scene/claim incomplet ou preuve stale.
- `UNSUPPORTED` : donnée opaque non représentable par l'adapter V0.
- `LEGACY_ONLY` : comportement conservé sans proposition V2.

Une classification n'est jamais une activation runtime.

## 21. Receipt/recovery model

Le receipt contient snapshot, hashes avant/après, mappings, target records,
target claims, backup destinations futures, journal et rollback. Il est une
proposition `prepared`, jamais écrit par Phase C. Les target records restent
désactivés. Les mappings de référence doivent être finaux (`mapped` ou
`preservedTombstone`).

Atomicité honnête : staging manifest, rename unitaire, maps legacy inchangées,
journal prepared/committed/recovered. Le rollback n'est garanti qu'avant le
point de non-retour et si revision/hashes concordent. Après la première donnée
V2-only non représentable en legacy, une migration compensatoire est requise.

## 22. Compatibility V1

- Aucun mode runtime V2 n'est activé.
- Aucun handler legacy n'est supprimé.
- Aucun fallback n'est ajouté après un claim valide/tombstone.
- Les Scenarios non claimés et MapEvents legacy restent inchangés.
- Aucun `GameState`, map runtime, gameplay, battle ou projet Selbrume modifié.
- Aucun projet réel migré.

## 23. Tests ciblés

```text
C0 : 47 passed
C1 : 19 passed
C2 : 20 passed
C3 : 19 passed
C4 : 88 passed
map_editor C3 + régressions : 8 passed
map_runtime characterization : 3 passed
```

Les tests couvrent positif, négatif, garde-fous, immutabilité, déterminisme,
idempotence, stale evidence, partial claims, collisions, receipt, rollback,
unknown data et non-régression V1.

## 24. Tests cumulés

```text
cd packages/map_core && dart test --reporter=compact
+2755: All tests passed!
```

## 25. Analyze/build

```text
map_core dart analyze : PASS — No issues found!
MCP Dart final : PASS — No errors
map_editor targeted analyze : PASS — No issues found!
map_runtime targeted analyze : PASS — No issues found!
map_runtime dart analyze : PASS process — 349 info diagnostics historiques
map_editor flutter build macos --debug : PASS
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Analyse globale editor exécutée, résultat honnête :

```text
flutter analyze --no-fatal-infos
438 issues found; exit 1; 81 error diagnostics
```

Les 81 erreurs sont limitées à :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart
```

Ces fichiers n'ont aucun diff et leurs hashes worktree sont identiques à
`HEAD` (`2e6904...` et `5af719...`). Cette dette globale est une réserve
préexistante, pas un succès revendiqué par Phase C.

## 26. Generated files

Deux passes finales :

```text
Built with build_runner in 10s; wrote 0 outputs.
Built with build_runner in 1s; wrote 0 outputs.
```

Aucun generated file n'a changé.

## 27. Scope final

Scope fonctionnel modifié : `map_core`, guard Scenario `map_editor`, tests de
caractérisation runtime, roadmap et rapports. Aucun diff de production dans
`map_runtime`, `map_gameplay`, `map_battle`, `examples`, `assets` ou Selbrume.

Le fichier concurrent non tracké
`selbrume/assets/GENERATED_ASSET_PROMPTS.md` est hors lot, n'existait pas au
Gate 0, et reste intact (`sha256:14368fe6...`). Le lock editor conserve ses
hashes initiaux exacts.

## 28. Risques résiduels

- Le planner reste dry-run : aucun protocole d'écriture Phase E n'est livré.
- L'historique de receipts incrémentaux n'existe pas; le planner bloque ce cas.
- Les cas `ASSISTED` exigent encore un choix humain explicite initial.
- La dette globale analyzer Pokemon SDK de `map_editor` reste ouverte.
- Le runtime V2, dual-read et cutover restent hors scope.

## 29. Entry Gate Phase D

```text
PHASE D — Source Catalogs & Read Models
V2-09 à V2-12
Entry Gate Phase C : ACCEPTED
Status : READY au périmètre Event V2
```

Toutes les preuves Phase C requises sont présentes : Phase B conservée,
lookup claims complet, SDK accepté, JCS/corpus reproductibles, adapters
read-only, authoring freeze, planner pur/déterministe/idempotent, claims et
reference graph complets, aucun write, tests/reviews/build ciblés verts.

Réserve explicite : la dette analyzer globale editor doit rester visible et
être traitée dans son chantier Pokemon SDK; elle n'est pas introduite par
Phase C.

## 30. Auto-review

- Le scope est large, mais chaque jalon a été fermé avant le suivant.
- Les reviewers ont démontré que les premiers receipts étaient trop permissifs;
  les correctifs ont ajouté des invariants et des tests, pas des features.
- Le choix de bloquer l'incrémental V0 est plus petit et plus honnête que
  d'inventer un historique de receipts.
- La duplication du contenu complet des fichiers créés est placée dans
  l'Evidence Pack pour respecter `codex_rule.md`; les sources restent
  l'autorité canonique.
- Aucun résultat global editor n'est maquillé en vert.

## 31. Review contradictoire

Les rounds R1/R2 ont notamment détecté : Scenes non reprosées au replay,
Scenario IDs dupliqués, signatures dupliquées, target activé, domaines de
références incohérents, choices Scenario trop libres, receipts incrémentaux,
mappings par provenance et stable keys perdus, et receipt malformé pouvant
lever. Tous ont reçu une correction bornée et un test.

Verdict contradictoire final : aucun blocker.

## 32. Critique du prompt

Le prompt est utilement strict sur la non-destruction, les claims, JCS,
recovery et reviews. Sa taille et le séquencement C0 à C4 dans un seul lot ont
toutefois augmenté les risques d'incidents agents et le coût de preuve. Les
gates auraient été plus lisibles en cinq lots atomiques.

Deux adaptations ont été nécessaires : `map_runtime` est un package Flutter,
donc le test runtime a été exécuté avec `flutter test` plutôt que `dart test`;
et l'analyse globale editor préexistante rouge a été séparée des analyses
ciblées du lot au lieu d'être maquillée.

## 33. Verdict Phase C

```text
PHASE C : CLOSED
C0 : PASS
C1 / V2-05 : PASS
C2 / V2-06 : PASS
C3 / V2-07 : PASS
C4 / V2-08 : PASS
Data loss risk : NONE
Real project migrated : NO
Legacy data modified : NO
Phase D : READY au périmètre Phase C
Blockers Phase C : aucun
Réserve : analyse globale map_editor préexistante rouge
```
