# NS-EVENT-V2 — PHASE E — Evidence Pack

## 1. Baseline et Gate 0

| Élément | Preuve |
|---|---|
| Baseline | `e932d9a26bc942711f01b8c0cfe077cd50438d29` |
| Phase D initiale | `025bf9bc3bbc521cc2187d43fde4ad1d78a75f2f` |
| Branche | `main` |
| Worktree initial | propre |
| Diff initial | vide |
| Repo | `/Users/karim/Project/pokemonProject` |

Le `git log --oneline -n 20` exact est reproduit dans le rapport principal.

## 2. Drift indépendant

`packages/map_editor/pubspec.lock` était identique au HEAD au Gate 0, puis a été
réécrit par l'outillage Flutter pendant une lecture de dépendances.

```text
HEAD blob    16e4b367ae1ac074a2ce3b59309b3c34618a860f
worktree     51980c1eff6de9c04d44f6f236d647850e185ced
SHA-256      a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc
ownership    hors Phase E
commit       exclu
```

Les images `packages/map_editor/test/failures/*.png` étaient des sorties non
suivies créées par la suite golden complète. `git ls-files` était vide pour ce
dossier; ces seules sorties de test ont été supprimées avant le gate final.

## 3. Fichiers normatifs lus

- `MVP Selbrume/event_builder_v2_architecture_decisions.md`
- `MVP Selbrume/road_map_event_builder_v2.md`
- rapports Phase A, B, C et D sous `reports/narrativeStudio/events/`
- contrats/catalogues/index/read models/codecs Event V2 dans `map_core`
- repositories et ports de persistance existants dans `map_editor`
- tests Event V2, repository et compatibilité V1 pertinents
- `AGENTS.md`, `codex_rule.md`, `skills/README.md` et skills de workflow

## 4. MCP et agents

MCP Dart indisponible. Fallback: recherche locale, tests, analyse, génération et
build. Passes A-H exécutées; reviews contradictoires R1/R2 finales: PASS. Incident
initial: combinaison de paramètres agent invalide, puis limite de threads;
réutilisation des agents existants.

## 5. Inventaire des fichiers

### Créés — production map_core

- `packages/map_core/lib/src/authoring/narrative_event_activation_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_event_authoring_contract.dart`
- `packages/map_core/lib/src/authoring/narrative_event_authoring_support.dart`
- `packages/map_core/lib/src/authoring/narrative_event_authoring_verification.dart`
- `packages/map_core/lib/src/authoring/narrative_event_configuration_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_event_configuration_validation.dart`
- `packages/map_core/lib/src/authoring/narrative_event_draft_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_event_publication_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_event_source_operations_v2.dart`

### Créés — tests map_core

- `packages/map_core/test/support/narrative_event_authoring_fixtures.dart`
- `packages/map_core/test/narrative_event_activation_test.dart`
- `packages/map_core/test/narrative_event_authoring_performance_test.dart`
- `packages/map_core/test/narrative_event_authoring_verification_test.dart`
- `packages/map_core/test/narrative_event_bytes_fingerprint_test.dart`
- `packages/map_core/test/narrative_event_configuration_authoring_test.dart`
- `packages/map_core/test/narrative_event_draft_authoring_test.dart`
- `packages/map_core/test/narrative_event_id_generator_test.dart`
- `packages/map_core/test/narrative_event_publication_test.dart`
- `packages/map_core/test/narrative_event_source_authoring_v2_test.dart`

### Créés — production map_editor

- `packages/map_editor/lib/src/application/models/narrative_event_registry_persistence_models.dart`
- `packages/map_editor/lib/src/application/ports/narrative_event_registry_persistence_gateway.dart`
- `packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/narrative_event_registry_persistence.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/project_manifest_write_lock.dart`

### Créés — tests map_editor

- `packages/map_editor/test/support/event_registry_persistence_fixtures.dart`
- `packages/map_editor/test/event_registry_journal_test.dart`
- `packages/map_editor/test/event_registry_persistence_performance_test.dart`
- `packages/map_editor/test/event_registry_recovery_test.dart`
- `packages/map_editor/test/event_registry_repository_test.dart`
- `packages/map_editor/test/event_registry_undo_test.dart`

### Modifiés

| Fichier | Zone précise | Raison |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | exports authoring Event V2 | API publique E1-E3 |
| `packages/map_core/lib/src/operations/narrative_event_canonical_json.dart` | `narrativeEventBytesFingerprint` | revision SHA-256 des octets manifest |
| `packages/map_editor/lib/src/application/use_cases/use_cases.dart` | export persistence use cases | API application E4 |
| `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart` | `FileProjectRepository`, save générique verrouillé | gateway E4 et coexistence safe avec saves historiques |
| `MVP Selbrume/road_map_event_builder_v2.md` | Phase E, synthèse, prochaine mission | fermeture E et readiness F1 |

### Rapports créés

- `reports/narrativeStudio/events/ns_event_v2_phase_e_authoring_operations_v0.md`
- `reports/narrativeStudio/events/ns_event_v2_phase_e_evidence_pack.md`

Le prompt Phase E interdit de recopier des milliers de lignes de code dans cet
Evidence Pack. Les chemins, lignes, hashes et extraits ciblés ci-dessous sont la
preuve canonique; le contenu complet reste disponible dans chaque fichier cité.

### Empreintes des fichiers créés

Format: `chemin | lignes | SHA-256`.

```text
packages/map_core/lib/src/authoring/narrative_event_activation_operations.dart | 225 | e7f9773604701a11918bd71a319027bcee4b0f1d770bbd300076dae762ed2ef9
packages/map_core/lib/src/authoring/narrative_event_authoring_contract.dart | 440 | c022319d7ae7b559da3c3bc4e0d089317fb68c6a92d05ae705ae1c4958637654
packages/map_core/lib/src/authoring/narrative_event_authoring_support.dart | 32 | 3766bf9e42588cc8d5da2ce7952b36c45d0595775a4ff96639fc927e537b6608
packages/map_core/lib/src/authoring/narrative_event_authoring_verification.dart | 210 | c92d39af04834dd454776cdb9aa0c0547f4a50e1653cfecbfde4a0847a025d5c
packages/map_core/lib/src/authoring/narrative_event_configuration_operations.dart | 508 | c5effe6d4631b4bc78fee15f0d4ed2ec4b6d0a95bf01a2e0fbd9ee65e0f03a98
packages/map_core/lib/src/authoring/narrative_event_configuration_validation.dart | 499 | 22452382ff1b6ebed3d6a2fcba3fce7d015d0dabc0cf3e3339d8aad2c5940cfd
packages/map_core/lib/src/authoring/narrative_event_draft_operations.dart | 204 | c267e1e7599c1508d2227647ed6d0d61976b926acbea95175add883cf5a83d79
packages/map_core/lib/src/authoring/narrative_event_publication_operations.dart | 184 | 90b14a9ac7415a41f4ecd1919719fc9c758749b1164984cc1cc91563839dabfe
packages/map_core/lib/src/authoring/narrative_event_source_operations_v2.dart | 572 | 13f2cca8d5510a7f08c143915ebafc77ce076c458dc117e57aeff8d28fced537
packages/map_core/test/support/narrative_event_authoring_fixtures.dart | 343 | 1c22ace9c189214d258bec7bcc2354febe643ac1d9eaabb48f924b2933697119
packages/map_core/test/narrative_event_activation_test.dart | 199 | 84187e325eea743cb8f3d9d635544282e7854502d2a64b357f567815121ee488
packages/map_core/test/narrative_event_authoring_performance_test.dart | 216 | 10a45b3b819c906b607c8af2f598f64206372e6d4ef44c54653716c0b9bc31c2
packages/map_core/test/narrative_event_authoring_verification_test.dart | 82 | 8bc91768101cedf4947dbc51bd6d4e0640e9527916ac52a0bff766062d95a6da
packages/map_core/test/narrative_event_bytes_fingerprint_test.dart | 11 | 94125d395bd4dd858ce13de54e4f03388c7f8e199de668d9665acedc0659332a
packages/map_core/test/narrative_event_configuration_authoring_test.dart | 746 | 5a37a3e12175930cad97a94234566a6b64db338afd7ff986f17424e25bacf090
packages/map_core/test/narrative_event_draft_authoring_test.dart | 357 | 9730c7a87cba94b3bb28b8f34da230720de2daa28e7a8e821168dc2178e8c0ae
packages/map_core/test/narrative_event_id_generator_test.dart | 32 | ae5f8dde680bacf2c21ddb5738e256e5ab1550642288c96a700c7c3fb94e9d41
packages/map_core/test/narrative_event_publication_test.dart | 209 | d17fda131a1a86308efcf5b2d13c2c95486dc7dacbd0d48334e5c440a83753f0
packages/map_core/test/narrative_event_source_authoring_v2_test.dart | 538 | 512b97c8faccbb5e25c8d3833a5f1f86f386ed77f533907a964ec46ba83c5130
packages/map_editor/lib/src/application/models/narrative_event_registry_persistence_models.dart | 621 | f5227b0d621f7162aab9edd0a472e6da2ff2844a344f56df49666b1e75de2cc0
packages/map_editor/lib/src/application/ports/narrative_event_registry_persistence_gateway.dart | 13 | 61a7c43fcfd57379c333c39f85119a7676706729158cddae2b3089d42d5b0320
packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart | 36 | 3d038a748e8482b7f8c6888b4a44e29aab967128aabdc4529351806ae1d2ae45
packages/map_editor/lib/src/infrastructure/repositories/narrative_event_registry_persistence.dart | 1075 | db89baf5a83107408937b583008524b58cef0f9a0d18646f7074b4a37a789468
packages/map_editor/lib/src/infrastructure/repositories/project_manifest_write_lock.dart | 45 | 15498e106217f40dda4f90848e3da70c5d2b6cd24838679fc002a6a69625c46e
packages/map_editor/test/support/event_registry_persistence_fixtures.dart | 350 | a251777dcebe46885f5c32421ca1580a32505e9abacef38bfd30b6341e149c13
packages/map_editor/test/event_registry_journal_test.dart | 339 | 20bd9d45bef81eec356b8362742d2fd8b06a87c4125cb67492fd5d5779a72bd7
packages/map_editor/test/event_registry_persistence_performance_test.dart | 101 | b1c4d919b0732636b92677aec7c3a59321853f876cb0b54b36e135f04ac1cec0
packages/map_editor/test/event_registry_recovery_test.dart | 391 | 3ee2b2d18e1100a966840f94ffbf91109f11220e4728727d49c90c43115f5063
packages/map_editor/test/event_registry_repository_test.dart | 599 | b7109b66a3d071e27ca8aa909f0b02d3c88ff68d42b98687093fb24fe983c5b7
packages/map_editor/test/event_registry_undo_test.dart | 356 | 4888b28beb51e90e02e6d6c2d380155d3629b114873982a5f8f95849bbd7a4ea
```

## 6. API publique

```text
NarrativeEventAuthoringContext
NarrativeEventAuthoringResult
NarrativeEventAuthoringStatus
NarrativeEventAuthoringMutation
NarrativeEventAuthoringDiagnostic
NarrativeEventSourceImpactPreview

createNarrativeEventDraft
selectNarrativeEventSource
replaceNarrativeEventSource
removeNarrativeEventSource
renameNarrativeEvent
setNarrativeEventConditions
setNarrativeEventScene
removeNarrativeEventScene
setNarrativeEventReusePolicy
setNarrativeEventPriority
setNarrativeEventOrder
publishNarrativeEvent
activateNarrativeEvent
deactivateNarrativeEvent
verifyNarrativeEventAuthoringResult

NarrativeEventRegistryWriteRequest.fromAuthoringResult
NarrativeEventRegistryPersistence
PersistNarrativeEventRegistryUseCase
RecoverNarrativeEventRegistryWritesUseCase
UndoNarrativeEventRegistryWriteUseCase
```

## 7. Authoring result matrix

| Statut | Diagnostic | nextRegistry | conceptual revision | undoable | Persistable |
|---|---:|---:|---:|---:|---:|
| applied | optionnel | oui | oui | oui | oui après replay |
| noOp | optionnel | non | non | non | non |
| rejected | requis | non | non | non | non |
| staleRevision | requis | non | non | non | non |
| unsupportedRegistry | requis | non | non | non | non |
| invalidRegistry | requis | non | non | non | non |

Le replay E4 compare mutation, record, registry précédent et registry suivant;
il bloque un faux résultat et toute mutation multi-record.

## 8. Draft fixtures

Les fixtures couvrent registry absent, registry legacyOnly/dualRead, claims non
vides, chaque source spatiale et outcome qualifiée, source manquante/ambigüe,
catalogue stale, source index stale, collision et épuisement de générateur.

```text
input: registry absent + source null + injected ID evt-new
output: legacyOnly registry, one draft, enabled index unchanged
write: none until E4
```

## 9. Property preservation

| Propriété | select | replace | remove | persist |
|---|---:|---:|---:|---:|
| Event ID | = | = | = | = |
| name | = | = | = | = |
| conditions/order | = | = | = | = |
| Scene | = | = | = | = |
| reuse/priority/order | = | = | = | = |
| registry schema/mode | = | = | = | = |
| claims | = | = | = | = |
| unknown root JSON | n/a | n/a | n/a | = |
| maps/Scenarios | untouched | untouched | untouched | untouched |

## 10. Condition graph fixtures

Tests: Fact missing/ambiguous, Event missing/draft/invalid, duplicate conditions,
self reference, cycles 2/3 nodes, cycle de 10 000 Events sans récursion, réparation
d'une cascade canonique, détachement avec blocker indépendant et plusieurs cycles
indépendants.

## 11. Publication diagnostics

| Code stable | Cause |
|---|---|
| `sourceRequired` | draft sans source |
| `sceneRequired` | draft sans Scene |
| `reusePolicyRequired` | behavior absent |
| `eventNotDraft` | publication d'un configured |
| source/Scene/Fact diagnostics | référence invalide ou ambiguë |
| `runtimeSupportPending` | publication réussie, runtime V2 absent |

Sortie réussie: `NarrativeEventRecord.configured(... enabled: false)`.

## 12. Activation conflict matrix

| Source | Priority | Order | Enabled conflict | Verdict |
|---|---:|---:|---:|---|
| différente | * | * | n/a | PASS |
| identique | différente | même | oui | PASS |
| identique | même | différent | oui | PASS |
| identique | même | même | oui | BLOCK `exactSourceConflict` |

## 13. Raw JSON before/after golden

```json
{
  "unknownRoot": {"kept": [1, 2, 3]},
  "eventRegistry": {"schemaVersion": 1, "mode": "legacyOnly", "claims": []},
  "maps": [{"unknownMapField": true}],
  "scenarios": [{"unknownScenarioField": "kept"}]
}
```

Après write, seules les données de `eventRegistry` changent. `unknownRoot`, maps,
scenarios et leurs sous-arbres restent sémantiquement identiques. Le preflight
rejette duplicate keys, séquences Unicode non I-JSON et registry
unsupported/invalid.

## 14. Journal JSON golden ciblé

```json
{
  "schemaVersion": 1,
  "operationId": "phase-e-write-001",
  "projectPath": "<absolute-project-path>",
  "journalPath": "<same-directory-journal>",
  "beforeHash": "sha256:<64 hex>",
  "expectedAfterHash": "sha256:<64 hex>",
  "tempPath": "<same-directory-temp>",
  "backupPath": "<same-directory-backup>",
  "state": "prepared|committed|recovered",
  "preparedAt": "<UTC>",
  "eventIds": ["evt-new"],
  "mutation": "createDraft",
  "previousRegistryHash": "sha256:<64 hex>",
  "nextRegistryHash": "sha256:<64 hex>",
  "previousRegistry": null,
  "nextRegistry": {"schemaVersion": 1, "mode": "legacyOnly"}
}
```

Le décodeur exige les champs exacts, les hashes concordants, les Event IDs
uniques triés et un lifecycle timestamp cohérent.

## 15. Crash injection et recovery

| Injection | Projet visible | Artefacts | Recovery |
|---|---|---|---|
| beforeBackup | before | aucun/partiel | no-op/cleanup |
| afterBackup | before | backup | backup orphan vérifié retiré |
| afterJournalPrepared | before | backup+journal | rollback recovered |
| afterTempFlush | before | backup+journal+temp | temp retiré, rollback |
| beforeRename | before | prepared | rollback |
| afterRename | after | prepared | finalisation recovered |
| afterHashVerify | after | prepared | finalisation recovered |
| beforeCommitted | after | prepared | finalisation recovered |
| afterCommittedBeforeCleanup | after | committed | cleanup idempotent |

Hash projet différent de before et after, backup absent/corrompu, plusieurs
journaux prepared ou journal/undo incohérents: `blocked`, sans overwrite.

## 16. Undo outputs

```text
normal undo       committed, project revision returns to prior semantic registry
unrelated change staleUndo, no byte overwritten
later Event write staleUndo, no byte overwritten
crash pre-rename  recovery then deterministic retry succeeds
crash post-rename recovery finalizes visible undo
corrupt metadata  rejected/blocked
```

## 17. Revision/hash evidence

- Registry fingerprint: SHA-256 du JSON canonique Event V2.
- Project revision: `sha256:` + SHA-256 des octets exacts du manifest.
- Hash revalidé sous verrou avant écriture.
- Hash relu immédiatement avant rename.
- Hash after vérifié après rename avant `committed`.
- Undo exige exactement l'afterRevision précédente.

## 18. No legacy write evidence

```text
git diff --name-only -- packages/map_runtime/lib packages/map_gameplay \
  packages/map_battle examples assets selbrume \
  "MVP Selbrume/selbrume.md" "MVP Selbrume/narrative_studio.md"
<empty>

git diff --name-only -- packages/map_editor/lib/src/ui/canvas/events \
  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
<empty>
```

Les fixtures hashent les maps/Scenarios avant/après et vérifient leur absence de
mutation. Aucun plan de migration n'est appliqué.

## 19. Tests et résultats exacts

```text
map_core Phase E ciblé + performance       +66  All tests passed!
map_core complet                           +2908 All tests passed!
map_editor E4 repository/journal/recovery  +39  All tests passed!
map_editor E4 + performance                +40  All tests passed!
map_editor régressions pertinentes         +245 All tests passed!
map_runtime legacy characterization        +3   All tests passed!
```

Suite editor complète: exit 1 sur 3105 résultats `testDone`: `2968 success`,
`6 failure`, `131 error`; le flux machine contient 137 événements de type
`error`. Les erreurs couvrent surtout UI/shadow editor, goldens,
Storylines/Scenes et scripts Selbrume, plus quelques chargements Pokemon SDK.
Les six `failure` sont listés dans le rapport principal. Aucun résultat non vert
ne cible les suites ou fichiers Phase E.

## 20. Analyses, génération et build

```text
cd packages/map_core && dart analyze
No issues found!

cd packages/map_editor && flutter analyze --no-fatal-infos <12 fichiers E4>
No issues found!

cd packages/map_editor && flutter analyze
exit 1 — 451 issues found; 0 diagnostic dans les fichiers Phase E

cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
0 outputs (deux passes)

cd packages/map_editor && flutter build macos --debug
Built build/macos/Build/Products/Debug/map_editor.app
```

## 21. Performance

Machine: Apple M1 Pro / 32 GiB / Darwin ARM64 27.0.0. Dart 3.12.1, Flutter
3.46.0-0.3.pre. JIT, warmup 1, catalogues exclus, hashing inclus, AOT non mesuré.

| Mesure | Volume | Mean µs | Median µs |
|---|---:|---:|---:|
| draft | 10 / 1k / 10k | 1360.3 / 27994.9 / 238589 | 1084 / 28710 / 235308 |
| source | 10 / 1k / 10k | 695.2 / 24231.4 / 241821.3 | 641 / 23252 / 241483 |
| graph | 10 / 1k / 10k | 308.6 / 20130.7 / 186790 | 274 / 19376 / 187365 |
| publication | 10 / 1k / 10k | 489.4 / 24330.3 / 284058.7 | 381 / 24464 / 275385 |
| activation | 10 / 1k / 10k | 439.3 / 26908.7 / 301777.7 | 405 / 27013 / 313129 |
| JSON patch | 10 / 1k / 10k | 126.9 / 9284.7 / 94430 | 98 / 8475 / 96223 |
| journal write | 1 | 24221.9 | 16265 |
| recovery scan | 1 | 8209.8 | 5978 |
| recovery scan | 100 | 157851.6 | 157443 |

## 22. Review evidence

R1 initial: BLOCKED sur lock/CAS, requête forgeable, undo retry et journal temp.
R2 initial: BLOCKED sur save générique, lock, backup/journal malformé, truthful
metadata et preuves. Tous les blockers ont un test de non-régression.

```text
E1 REVIEW R1 : PASS
E1 REVIEW R2 : PASS
E2 REVIEW R1 : PASS
E2 REVIEW R2 : PASS
E3 REVIEW R1 : PASS
E3 REVIEW R2 : PASS
E4 REVIEW R1 : PASS
E4 REVIEW R2 : PASS
```

## 23. Risques et F1 gate

Risques restants: advisory lock, absence de directory fsync, dette globale
editor, performance AOT non mesurée, API sans UI et runtime V2 absent.

F1 est READY sur les contrats purs et persistés. F1 doit ajouter uniquement
l'autorité/progression V2, sans réécrire les sources legacy, sans confondre
`enabled` et support runtime, et sans contourner le journal/revision.

## 24. Gate final

```text
staged Phase E files                         37
git diff --cached --check                   <empty>
forbidden runtime/gameplay/battle scope     <empty>
Event Builder UI scope                      <empty>
unstaged                                    packages/map_editor/pubspec.lock
R1                                          PASS
R2                                          PASS
```

Le commit sélectif exclut `packages/map_editor/pubspec.lock` et tout fichier
d'une autre conversation. Aucun push n'est demandé.
