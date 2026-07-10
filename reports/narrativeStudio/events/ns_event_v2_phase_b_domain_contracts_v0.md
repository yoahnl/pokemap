# NS-EVENT-V2 — Phase B — Canonical Domain Contracts & Structural Source Index

## 1. Résumé exécutif

```text
PHASE B : CLOSED
B1 : PASS
B2 : PASS
B3 : PASS
B4 : PASS
Dependency Gate : ACCEPTED
map_core tests : PASS — 2652 tests
dart analyze : PASS — No issues found!
build_runner stability : PASS — deux runs finaux, 0 outputs
Blockers : aucun
Prochaine phase : PHASE C — READY
```

La Phase B introduit dans `map_core` un Event V2 pur, sérialisable, strictement
validé et indexable, sans consumer runtime, UI, migration de projet ni mutation
gameplay. Les contrats Phase A sont respectés : quatre sources fermées, une
Scene par Event configuré, aucun champ spatial, claims complets, codec
fail-closed et index sans `GameState`.

## 2. Baseline Phase A

- Commit normatif : `61941c3955ca103eb8650ddbf8db06f33d563854`.
- Ledger inchangé : `MVP Selbrume/event_builder_v2_architecture_decisions.md`.
- Roadmap utilisée : `MVP Selbrume/road_map_event_builder_v2.md`.
- Autorité appliquée : ADR-EV2-001 à ADR-EV2-020, rapport Phase A, roadmap,
  RESET-00, puis historique V1.

## 3. Usage MCP Dart

MCP Dart était disponible et a été utilisé avec les roots `map_core`,
`map_runtime`, `map_editor` et `map_gameplay`. Les recherches LSP ont couvert
`ProjectManifest`, `ProjectVersion`, `MapEventDefinition`, `MapEventPage`,
`EventPosition`, `MapEventType`, `ScenarioAsset`, `SceneAsset`, Facts,
World Rules, drafts Scenario, picker Event V1, `GameState`, `ScriptCondition`,
les barrels et les consumers de `ProjectManifest.fromJson`.

Après B1, B2, B3 et B4, `mcp__dart__analyze_files` a retourné exactement :

```text
No errors
```

## 4. Sous-agents

Les passes spécialisées obligatoires ont été exécutées :

- A — Source & Outcome Contracts : contrat B1, identité structurelle, absence
  de géométrie ; verdict GO.
- B — Event Definition & Record : champs exacts, publication, activation et
  UUIDv7 ; aucun blocker de contrat.
- C — Registry & Preflight Codec : closed-world JSON, raw subtree et
  capabilities fail-closed.
- D — Claims, JCS & Fingerprints : préimages ADR, RFC 8785, SHA-256,
  cohortes et conflits.
- E — Structural Index : filtrage, tri, conflits et complexité.
- F — Backward Compatibility & Public API : manifests V1, generated et
  consumers directs.
- G — Tests & Dependency Gate : dépendances, vectors et gates cumulés.
- R1 — Architecture & Wire Format : review contradictoire après chaque jalon.
- R2 — Compatibility & Failure Modes : review contradictoire après chaque
  jalon.
- Orchestrateur principal : arbitrage séquentiel B1 → B2 → B3 → B4.

Deux workers B2 ont été arrêtés après absence de progression ; leur squelette
de test a été repris et vérifié localement. Aucun résultat agent n’a été accepté
sans test, analyse et review contradictoire.

## 5. Dependency Gate

```text
DEPENDENCY GATE : ACCEPTED
```

- `uuid ^4.5.3`, licence MIT : génération UUIDv7 éprouvée.
- `crypto ^3.0.7`, licence BSD-3-Clause : SHA-256 éprouvé.
- SDK `map_core` : `>=3.4.0 <4.0.0`, requis par `crypto 3.0.7`.
- Aucune dépendance JCS : implémentation locale bornée et prouvée.
- Aucune dépendance deep-equality : égalité structurelle locale explicite.

La stratégie JCS locale a été acceptée après comparaison de 200 000 patterns
IEEE-754 déterministes avec `JSON.stringify` Node et comparaison des six corpus
officiels JCS (`arrays`, `french`, `structures`, `unicode`, `values`, `weird`).

## 6. Gate 0

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

Le drift `packages/map_editor/pubspec.lock` était préexistant. Hash fichier
initial : `2fac1583a9d5864cd3bc13f2aa7a0831274bfe0fde7380782ff68d0820e90ac6`.
Hash diff initial :
`6b33cb8d5361c91b2aa9c8e3fcfebc99a8c3f64c4a822ff8ca55b2097d075511`.

```text
Dart SDK version: 3.12.1 (stable) on "macos_arm64"
Baseline HEAD: 61941c39 NS-EVENT-V2 PHASE A: Canonical Architecture Ratification
```

## 7. Jalon B1 / V2-01

Création de `NarrativeEventSourceRef`, `NarrativeEventSourceKind`,
`NarrativeOutcomeRef` et `NarrativeOutcomeProducerKind`. Les quatre variants
exacts sont `entityInteract`, `triggerEnter`, `mapEnter` et
`outcomeReceived`. Les trois producers sont `scene`, `battle` et
`legacyScenario`. Les IDs sont opaques, case-sensitive, non vides et déjà
trimmed. L’objet typé sert directement de clé de Map.

## 8. Review B1

```text
B1 REVIEW R1: PASS
B1 REVIEW R2: PASS
```

Une première review a détecté la confusion entre champ futur et champ connu
incompatible. Le helper strict distingue maintenant unknown → `unsupported`
et payload cross-variant connu → `invalid`.

## 9. Jalon B2 / V2-02

Création de `NarrativeEventCondition`, `NarrativeEventReusePolicy`,
`NarrativeEventDefinition`, `NarrativeEventDraft`, `NarrativeEventRecord`,
des opérations pures publish/activate/deactivate et de
`NarrativeEventIdGenerator`. La publication est atomique et désactivée par
défaut. L’ID suit exactement `evt_<uuid-v7 lowercase canonical>` avec seize
retries supplémentaires et erreur à la dix-septième collision.

## 10. Review B2

```text
B2 REVIEW R1: PASS
B2 REVIEW R2: PASS
```

R2 a d’abord signalé `crypto` et le lock éditeur. Après preuve du Dependency
Gate Phase B et des hashes identiques du drift initial, le verdict a été
révisé en PASS.

## 11. Jalon B3 / V2-03

Création du registry schema `1`, des trois modes, des provenances et claims,
du codec strict, de `ValidatedLegacyClaimIndex`, du preflight sur bytes JSON,
de JCS/SHA-256 et des fonctions de fingerprint. `ProjectManifest` reçoit un
`NarrativeEventRegistry? eventRegistry` omis quand absent.

Le preflight conserve les bytes originaux, le sous-arbre raw en cas de failure,
et expose `writable`, `runtimeAllowed`, `migrationAllowed` et
`playtestAllowed`. `unsupported` et `invalid` sont fail-closed.

## 12. Review B3

```text
B3 REVIEW R1: PASS
B3 REVIEW R2: PASS avec réserve Phase C
```

R1 a trouvé puis fait corriger deux défauts : arrondi possible des entiers hors
plage I-JSON et perte des clés JSON dupliquées par `jsonDecode`. Les entiers
hors ±9 007 199 254 740 991 sont rejetés et un scanner lexical détecte les
duplicates sous `eventRegistry` avant decode. La réserve R2 concerne le
branchement du preflight dans le repository éditeur, explicitement interdit en
Phase B et transféré au Gate Phase C.

## 13. Jalon B4 / V2-04

Création de `NarrativeEventSourceIndex`,
`NarrativeEventSourceIndexBuildResult` et `NarrativeEventSourceConflict`.
L’index exclut drafts et configured disabled, groupe par source, trie par
priority DESC, order ASC, Event ID ASC et conserve tous les records d’un tie.
Il n’évalue ni condition, ni lifecycle, ni catalogue, et ne désigne aucun
winner.

## 14. Review B4

```text
B4 REVIEW R1: PASS
B4 REVIEW R2: PASS
```

R2 a demandé des preuves supplémentaires : lookup par instance structurellement
égale, plusieurs groupes de conflits, immutabilité profonde et conditions non
évaluées. Les quatre tests ont été ajoutés avant le PASS.

## 15. Public API finale

API principale exportée par `map_core.dart` :

```text
NarrativeEventSourceKind
NarrativeEventSourceRef
NarrativeOutcomeProducerKind
NarrativeOutcomeRef
NarrativeEventCondition
NarrativeEventReusePolicy
NarrativeEventDefinition
NarrativeEventDraft
NarrativeEventRecord
NarrativeEventIdGenerator
NarrativeEventRegistry
EventSystemMode
LegacySourceRef
LegacySourceClaimMember
LegacySourceClaim
EventRegistryDecodeResult
ValidatedLegacyClaimIndex
NarrativeEventSourceIndex
NarrativeEventSourceIndexBuildResult
NarrativeEventSourceConflict
```

Sont aussi exportés les opérations pures de publication, activation, JCS,
fingerprinting, preflight, validation des claims et build de l’index.

## 16. Wire format final

- Sources : discriminant `kind`, payload exact par variant.
- Conditions : `fact` ou `narrativeEventConsumed`.
- Record : discriminant `state`, payload exclusif `draft` ou
  `definition + enabled`.
- Registry : `schemaVersion`, `mode`, `records`, `legacyClaims`.
- Unknown field/kind/schema : `unsupported`.
- Required manquant/null/type/invariant : `invalid`.
- Claims : members et targets non vides, uniques, canoniquement ordonnés,
  hashes lowercase stricts et receipt non vide.

## 17. Compatibility V1

Un manifest sans `eventRegistry`, ou avec `null`, reste effectif
`legacyOnly`; le champ n’est pas ajouté au round-trip. `ProjectVersion` reste
inchangé. Les tests Scene, Scenario, Facts, World Rules et Event Builder V1
passent. Aucun consumer runtime/editor n’est modifié.

## 18. Generated files

Seuls les fichiers generated liés à `ProjectManifest` ont changé :

```text
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
```

Deux runs finaux `build_runner` ont écrit `0 outputs`. Aucun generated d’un
autre package n’a changé.

## 19. Tests ciblés

Les six suites Phase B passent : sources, definition, registry, codec,
fingerprints et index. Le dernier gate ciblé retourne `57` tests passés.

## 20. Tests cumulés

```text
$ dart test --reporter=compact
00:06 +2652: All tests passed!
exit=0
```

Les régressions ciblées ProjectManifest/Scene/Scenario/Facts/World Rules/Event
Builder V1 ont également passé (`108` tests lors du gate B3 cumulatif).

## 21. Analyse

```text
$ dart analyze
Analyzing map_core...
No issues found!
exit=0
```

Le check global `dart format --output=none --set-exit-if-changed lib test`
retourne `exit=1` car Dart 3.12 identifierait 67 fichiers historiques hors
lot. Le check ciblé des 19 fichiers manuscrits Phase B retourne :

```text
Formatted 19 files (0 changed) in 0.05 seconds.
exit=0
```

## 22. Performance baseline

Mesure informative JIT, Dart 3.12.1, macOS arm64, 20 001 records et 1 001
sources :

```text
Build: 10 iterations in 258643 us; mean 25864.3 us
Lookup absent: 1000000 in 23295 us; 23.295 ns/op
Lookup single: 1000000 in 28329 us; 28.329 ns/op
Lookup multiple: 1000000 in 24894 us; 24.894 ns/op
Checksum: 21000000
```

Aucun seuil arbitraire n’est utilisé ; complexité documentée :
`O(R + sum(k log k))`, lookup Map attendu `O(1)`.

## 23. Scope final

Modifications de production limitées à `packages/map_core`, aux deux rapports
et à la roadmap autorisée. Aucun fichier `map_runtime`, `map_gameplay`,
`map_battle`, `map_editor`, `examples`, `assets` ou `selbrume` n’est revendiqué.
Le lock éditeur reste un drift préexistant identique.

## 24. Risques résiduels

- Le repository éditeur appelle encore directement `ProjectManifest.fromJson` ;
  Phase C doit adopter le preflight pour offrir le mode read-only au lieu d’un
  simple échec de load.
- Phase C doit confronter claims et fingerprints au corpus legacy réel.
- L’index est structurel uniquement ; l’éligibilité stateful reste F1.
- Le baseline global de format Dart 3.12 reste à traiter dans un lot hygiene
  séparé, sans polluer Phase B.

## 25. Entry Gate Phase C

```text
PHASE C : READY
```

Preuves : quatre sources, records stables, registry schema `1`, codec strict,
claims/JCS/SHA-256 prouvés, index stable, anciens manifests lisibles, suite
complète et analyse vertes, build_runner stable. Aucun runtime consumer, aucun
projet migré et aucune UI dépendante n’existent encore.

## 26. Auto-review

La surface publique reste petite et sans modèle universel opaque. Les points
les plus risqués ont reçu des tests négatifs : unknown/invalid, duplicate keys,
safe integers, collision UUID, claims cross-conflict et ties d’index. Le choix
manuel des codecs évite de masquer les future fields mais augmente le coût de
maintenance ; tout nouveau champ devra rouvrir une décision de schema.

## 27. Review contradictoire

Les reviewers ont effectivement bloqué B1, B3 et B4 avant correction. Aucun
verdict n’a été forcé : les objections dépendance/drift et consumer éditeur ont
été arbitrées avec preuves et frontières explicites, puis re-reviewées.

## 28. Critique du prompt

Le prompt est précis sur les contracts, les gates et les non-objectifs. Deux
points méritent ajustement : `dart format lib test` provoque un churn historique
avec le SDK actuel et devrait être remplacé par un check ciblé + un lot hygiene ;
la distinction entre livraison du preflight en Phase B et intégration dans les
repositories en Phase C devrait être rappelée dans les critères de
compatibilité. La quantité imposée de sous-agents est coûteuse mais a détecté
de vrais défauts JCS et de tests.

## 29. Verdict Phase B

```text
PHASE B : CLOSED / ACCEPTED
B1 / V2-01 : PASS
B2 / V2-02 : PASS
B3 / V2-03 : PASS
B4 / V2-04 : PASS
PHASE C : READY
```
