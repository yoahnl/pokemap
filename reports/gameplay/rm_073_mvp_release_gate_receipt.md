# RM-073 — MVP Release Gate Receipt

Date : 2026-07-27

Lots : `RM-073`, `FG-185`

Statut proposé du lot : **DONE**

Verdict release : **NO-GO**

Statut FG-185 : **PARTIAL**

## Résultat

Le receipt final de la Phase 7A existe désormais sous
`reports/gameplay/evidence/rm_073_mvp_release_gate_receipt.json`. Il lie le
candidat propre `79b1e87508a2d60ca035faa6cf49e807d0dcdf6a`, les empreintes du
projet source et installé, le scénario de certification, le package exporté,
son inspection, son installation Hub, les 19 critères automatisés, la matrice
monorepo, le build macOS et l'état explicite de la recette humaine.

Le lot documentaire `RM-073` est donc fermé, mais le reçu conclut
volontairement **NO-GO**. `FG-185` reste `PARTIAL` car `RM-071` ne prouve ni
Developer ID, ni notarisation, ni Gatekeeper, ni cold install, et aucun receipt
humain cohérent avec le même commit, arbre projet et package n'existe.

## Audit initial

- Branche : `main`.
- HEAD au début de RM-073 : `e1d92c9a4829458141de58722875b0346f3d35c1`.
- État initial : worktree propre après le commit RM-072.
- Roadmap canonique lue :
  `pokemap_roadmap_mecaniques_fangame.md`, lot `FG-185`.
- Plan de remédiation lu :
  `reports/gameplay/fg_000_remediation_and_personalization_roadmap.md`,
  lots `RM-069` à `RM-073`.
- Règles de rapport lues : `codex_rule.md`.
- Preuves d'entrée inspectées : receipts RM-070, RM-071, dashboard RM-072,
  rapport RM-069 et validateur de walkthrough humain.
- Aucun sub-agent n'a été lancé ; les règles de session interdisaient la
  délégation non demandée. Les verdicts ci-dessous sont des passes locales
  distinctes.

## Décisions et non-objectifs

1. Le test golden installé reste la source d'exécution : son mode normal est
   inchangé et un mode preuve optionnel persiste seulement les métadonnées
   demandées.
2. Le candidat est d'abord committé et propre, puis rejoué. Le commit du
   présent receipt atteste le candidat ; il ne se substitue pas à lui.
3. Les artefacts lourds restent sous `build/phase-7a/`, ignorés par Git. Leurs
   SHA-256 sont conservés dans le receipt.
4. Un standalone Dart CLI essayé en cours de lot a déclenché un crash du
   compilateur dans les build hooks FFI Flutter. Il a été supprimé avant
   commit ; l'écriture de preuve a été intégrée au test Flutter existant, qui
   compile le graphe réel.
5. Aucun contournement de signature, aucune désactivation de library
   validation et aucune promotion artificielle de FG-185 n'ont été ajoutés.
6. Les limitations post-MVP restent hors cutline : objets tenus, nature/IV/EV,
   Struggle, hazards/pickups, templates, complétudes secondaires listées dans
   RM-043/RM-044/RM-046–RM-049/RM-052, gate combat complète RM-053 et tous les
   lots `PH-*`.

## Preuve candidat et package

| Élément | Valeur |
|---|---|
| Commit candidat | `79b1e87508a2d60ca035faa6cf49e807d0dcdf6a` |
| Worktree à la capture | propre, aucun dirty path |
| Arbre projet source | `b62416c314d56e34b3690cebe845270bd7e663dab46f18595ef1cb292977efe4` |
| Scénario | `c52b43a8d8f9b0f5c0f9ee68b6e7cb537044e56d179d6c8de9ff339a9a78c39a` |
| Package | `ac349ee7c5bd0bc2022cfe30addc88109b6f200acf455447c5d97947a071a495` |
| Taille package | 249 654 346 octets |
| Arbre archive inspectée/installée | `7356001303cf13ec32f0cc41b0729e26e4d8279402327dddcbe420ceacfff581` |
| Arbre projet installé | `f3b18f1ab756663d2a70ca0f0d08eeaa970e3a7371897a80b8b352a25b50eaa8` |
| Inspection / validation / load smoke | passed / passed / passed |
| Golden journey | 19/19, aucun raccourci, fin, résultat, crédits, retour Hub |
| Preuve brute locale | SHA-256 `be63f624b77c728d62f3b132a9e8ba657551cb078744459c6f17e25f6f6a7c06` |
| Journal brut local | SHA-256 `a5ab30d73e957707b8f0995838448c2ba641ced574e69d1c8ad189c3c5e413ff` |

Les hash d'arbre source, archive et installation ne décrivent pas la même
représentation et ne sont donc pas censés être identiques. Le receipt vérifie
en revanche l'égalité du SHA package entre export, inspection et installation,
ainsi que l'égalité du tree SHA entre inspection et installation.

## Matrice de décision

| Condition | Preuve | Verdict |
|---|---|---:|
| Candidat propre autorisé | commit et dirty-state capturés | PASS |
| Projet et scénario figés | SHA-256 source, installé et scénario | PASS |
| Package inspecté/installé | SHA package et tree cohérents, load smoke | PASS |
| Golden journey | 19/19, sans raccourci | PASS |
| Tests/analyzes/smokes | RM-070, 20/20 | PASS |
| Build macOS universel | RM-071, build exit 0 | PASS |
| Developer ID / notarisation / Gatekeeper | absents | BLOCKER |
| Cold install et relaunch propre | non prouvés | BLOCKER |
| Walkthrough humain lié au candidat | absent | BLOCKER |
| Builds hors macOS | non approuvés | NON-ÉVALUÉ |

Décision : **NO-GO**. La règle de promotion interdit `FG-185 DONE/GO` tant
que chaque blocker n'est pas fermé par une preuve fraîche et cohérente pour un
même candidat.

## Fichiers et zones modifiés

| Fichier | Type | Zone / impact |
|---|---:|---|
| `examples/playable_runtime_host/test/phase_7a_installed_golden_journey_test.dart` | modifié | variables d'environnement optionnelles, contrôle du worktree propre, empreintes et JSON de preuve |
| `reports/gameplay/evidence/rm_073_mvp_release_gate_receipt.json` | créé | agrégation structurée candidat/projet/package/tests/build/walkthrough/limites/décision |
| `reports/gameplay/rm_073_mvp_release_gate_receipt.md` | créé | présent Evidence Pack |
| `pokemap_roadmap_mecaniques_fangame.md` | modifié | FG-185 reste PARTIAL, RM-073 coché et NO-GO explicite |
| `reports/gameplay/fg_185_mvp_release_gate_v0.md` | modifié | préambule autoritaire aligné sur RM-072/RM-073 |
| `reports/gameplay/fg_180_185_phase_10_playable_game_validation_completion.md` | modifié | matrice courante : receipt présent, blockers RM-071/humain |

Zones de diff essentielles :

```diff
+ POKEMAP_PHASE7A_EVIDENCE_OUTPUT
+ POKEMAP_PHASE7A_PACKAGE_OUTPUT
+ POKEMAP_PHASE7A_SUPPORT_ROOT
+ _requireCleanReleaseCandidate(...)
+ ProjectTreeDigest + SHA-256 package/scénario/entrée installée
```

```diff
- RM-073 et walkthrough humain manquants
+ RM-073 produit avec verdict NO-GO ; RM-071 et walkthrough humain bloquants
```

## Commandes et résultats exacts

### Implémentation et candidat

```text
cd examples/playable_runtime_host
dart format test/phase_7a_installed_golden_journey_test.dart
=> Formatted 1 file (1 changed) in 0.01 seconds.

flutter test test/phase_7a_installed_golden_journey_test.dart
=> 04:48 +1: All tests passed! (exit 0)

flutter analyze
=> No issues found! (ran in 6.7s) (exit 0)

git commit -m "test(release): persist installed package evidence"
=> 79b1e8750, 1 file changed, 159 insertions(+), 4 deletions(-)
```

### Capture sur l'arbre propre

```text
POKEMAP_PHASE7A_EVIDENCE_OUTPUT=.../package-evidence.json \
POKEMAP_PHASE7A_PACKAGE_OUTPUT=.../selbrume.pokemapgame \
POKEMAP_PHASE7A_SUPPORT_ROOT=.../support \
flutter test test/phase_7a_installed_golden_journey_test.dart
=> 05:02 +1: All tests passed! (exit 0)

jq ... package-evidence.json
=> workingTreeClean=true
=> releaseCandidateCommit=79b1e87508a2d60ca035faa6cf49e807d0dcdf6a
=> evaluation.status=succeeded
=> criteriaCount=19, passedCount=19
=> checks.hashesAgree=true
=> checks.installedLaunchResolved=true
=> checks.loadSmokePassed=true

shasum -a 256 package-evidence.json test.log
=> be63f624b77c728d62f3b132a9e8ba657551cb078744459c6f17e25f6f6a7c06  package-evidence.json
=> a5ab30d73e957707b8f0995838448c2ba641ced574e69d1c8ad189c3c5e413ff  test.log
```

### Cohérence finale

```text
jq empty reports/gameplay/evidence/rm_073_mvp_release_gate_receipt.json
git diff --check
=> exit 0, aucune sortie

cd examples/playable_runtime_host
flutter test test/human_walkthrough_receipt_validator_test.dart
=> 00:00 +3: All tests passed! (exit 0)

cd packages/map_core
dart test test/gameplay_roadmap_dashboard_test.dart \
  test/gameplay_roadmap_repository_consistency_test.dart
=> 00:09 +15: All tests passed! (exit 0)

dart run tool/generate_gameplay_roadmap_dashboard.dart --check ../..
=> DONE: 40 · PARTIAL: 12 · BLOCKED: 0 · TODO: 41 · DEFERRED: 21
=> FG-185: PARTIAL
=> exit 0
```

### Diagnostic abandonné

```text
dart run tool/collect_phase_7a_package_evidence.dart --help
=> crash build hooks Flutter/FFI
=> InvalidType is not a subtype of FunctionType
=> exit 252
```

Le fichier CLI était non committé et a été supprimé. Le test Flutter vert
ci-dessus remplace ce chemin sans masquer l'échec.

## Verdict des passes

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — l'agrégation reste dans le host/reports, sans déplacer les règles gameplay |
| Implémentation | PASS — mode normal préservé, preuve optionnelle fail-closed sur arbre propre |
| Tests | PASS — deux golden journeys installés verts, dont une capture candidat |
| Build / Validation | PARTIAL — automatisation verte, distribution et recette humaine incomplètes |
| Critique finale | NO-GO — compile/test ne remplacent ni signature de distribution ni observation humaine |

## Auto-critique et risques

1. La matrice RM-070 et le build RM-071 précèdent le commit candidat RM-073.
   Les changements ultérieurs sont des tests et rapports, pas du code produit,
   mais une gate de release plus stricte relancerait malgré tout les 20
   commandes et le build signé sur le SHA exact final.
2. Le package porte `signatureStatus=notPresent` et le Hub n'est signé
   qu'ad-hoc. Ce n'est pas un artefact distribuable.
3. Les timestamps d'installation `12:00Z` viennent de l'horloge déterministe
   du test ; `capturedAtUtc=08:57:57Z` est l'heure murale de capture.
4. Les artefacts bruts sous `build/` peuvent disparaître. Leurs digests
   conservent l'identité, pas leur disponibilité.
5. Le validateur humain exige actuellement quatre checkpoints de release. Une
   recette réelle doit aussi observer visuel, audio, contrôles, accessibilité,
   sauvegarde après relance et absence de blocage P0/P1.
6. Toute modification ultérieure de code ou contenu crée un nouveau candidat
   et invalide ce receipt.

## État Git

État avant capture : propre sur `79b1e8750`.

État attendu après le commit documentaire RM-073 : propre. Aucun artefact de
`build/phase-7a/` n'est tracké.

## Annexe A — contenu complet du fichier créé

Le présent Evidence Pack n'est pas répliqué récursivement. Le contenu complet
du receipt JSON créé est reproduit ci-dessous sous forme JSON minifiée,
strictement équivalente au fichier indenté.

```json
{"schemaVersion":1,"lot":"RM-073","capturedAtUtc":"2026-07-27T09:00:00Z","status":{"lot":"DONE","fg185":"PARTIAL_NO_GO","releaseDecision":"NO_GO"},"releaseCandidate":{"commit":"79b1e87508a2d60ca035faa6cf49e807d0dcdf6a","workingTreeCleanAtCapture":true,"dirtyPathsAtCapture":[],"attestationModel":"This receipt is committed after the clean candidate and attests that exact candidate; the receipt commit is not substituted for the candidate commit."},"project":{"sourceRelativePath":"selbrume","sourceTreeHashSha256":"b62416c314d56e34b3690cebe845270bd7e663dab46f18595ef1cb292977efe4","installedTreeHashSha256":"f3b18f1ab756663d2a70ca0f0d08eeaa970e3a7371897a80b8b352a25b50eaa8","installedEntryRelativePath":"games/games.pokemap.selbrume/versions/1.0.0/project/project.json","installedEntrySha256":"4a9c2a61a9bc34d8532364538cbc0e27646b4ff03eff3f952cf3af7d4e6e60f8","scenarioRelativePath":"examples/playable_runtime_host/evaluation/scenarios/selbrume/mvp_certification.json","scenarioSha256":"c52b43a8d8f9b0f5c0f9ee68b6e7cb537044e56d179d6c8de9ff339a9a78c39a","scenarioPolicy":"certify"},"package":{"localEvidenceRelativePath":"build/phase-7a/rm-073-79b1e8750/selbrume.pokemapgame","sha256":"ac349ee7c5bd0bc2022cfe30addc88109b6f200acf455447c5d97947a071a495","bytes":249654346,"certified":true,"inspection":{"receiptVersion":1,"securityPolicyVersion":1,"gameId":"games.pokemap.selbrume","gameVersion":"1.0.0","treeSha256":"7356001303cf13ec32f0cc41b0729e26e4d8279402327dddcbe420ceacfff581","manifestSha256":"37dbe8fd5764102db15f36bf988769d2cfbf00a48ffcff774d53f5ff36c90284","packageSha256":"ac349ee7c5bd0bc2022cfe30addc88109b6f200acf455447c5d97947a071a495","archiveBytes":249654346,"payloadBytes":245988723,"fileCount":11242,"signatureStatus":"notPresent"},"installation":{"receiptFormat":1,"securityPolicyVersion":1,"gameId":"games.pokemap.selbrume","gameVersion":"1.0.0","treeSha256":"7356001303cf13ec32f0cc41b0729e26e4d8279402327dddcbe420ceacfff581","manifestSha256":"37dbe8fd5764102db15f36bf988769d2cfbf00a48ffcff774d53f5ff36c90284","packageSha256":"ac349ee7c5bd0bc2022cfe30addc88109b6f200acf455447c5d97947a071a495","validatedAt":"2026-07-27T12:00:00.000Z","installedAt":"2026-07-27T12:00:00.000Z","clockSource":"deterministic test fixture; capturedAtUtc is the wall-clock evidence timestamp","source":"localFile","signatureStatus":"notPresent","validation":{"packageInspection":"passed","projectValidation":"passed","loadSmoke":"passed","compatibility":"accept"},"alreadyInstalled":false,"loadSmokePassed":true,"launchHandle":"games.pokemap.selbrume@1.0.0#7356001303cf13ec32f0cc41b0729e26e4d8279402327dddcbe420ceacfff581"},"hashAgreement":{"exportInspectionInstallationPackageSha256":true,"inspectionInstallationTreeSha256":true}},"automatedEvidence":{"installedGoldenJourney":{"lot":"RM-069","commit":"00e2869996cbe2bc08dcfd28b5274d359cd20982","report":"reports/gameplay/rm_069_golden_journey_19_criteria_gate.md","reportSha256":"d3734f8ea4997545b8d7c975bfff49f8ee6e1b4da5dab3394926262fcc1c434b","freshCandidateCaptureAtUtc":"2026-07-27T08:57:57.350933Z","testSourceSha256":"54ead8d31f50a7ceb836657124e2843611ad8f207bb5382f3b33de0c19feabb3","result":"05:02 +1: All tests passed!","evaluationStatus":"succeeded","evidenceLevel":"releaseEvidence","criteriaPassed":19,"criteriaTotal":19,"shortcutsUsed":[],"endingId":"ending.selbrume-sauvee","completionDestination":"hub"},"monorepoRegression":{"lot":"RM-070","commit":"6053c43e97f3d22fb4b7ed14708f732716ba4680","receipt":"reports/gameplay/evidence/rm_070_regression_gate_receipt.json","receiptSha256":"aa1e02687cf0041a967ece1b5a3c9ae754f66b98776fd2b621475e0e90989953","capturedAtUtc":"2026-07-27T08:26:55Z","executionMode":"sequential-fail-fast","commandsPassed":20,"commandsTotal":20,"allPassed":true,"totalDurationSeconds":1158,"scope":"Nine package test/analyze pairs followed by the runtime battle smoke and host launch smoke."},"platformBuildAndDeviceQa":{"lot":"RM-071","commit":"fe4bf6ea99e8f3ed8f5af1f89170c17cffc86c6e","receipt":"reports/gameplay/evidence/rm_071_macos_build_device_qa_receipt.json","receiptSha256":"a838f25fb6e1e534ad5b0ca81031b68a97f41a97916524590ff9dc89334b5748","capturedAtUtc":"2026-07-27T08:33:41Z","status":"PARTIAL_BLOCKED","buildCommand":"cd apps/pokemap_hub && flutter build macos --release","buildExitCode":0,"buildDurationSeconds":73,"bundleIdentifier":"app.pokemap.hub","bundleArchitectures":["x86_64","arm64"],"bundleBinarySha256":"8bb8fbf4a4ad6f5bbb522f18ffa3f810f01169c529121dea493dfda7f299dcb4","codesignVerify":"valid on disk; satisfies designated requirement","signature":"ad-hoc","developerId":false,"notarized":false,"stapled":false,"gatekeeperAccepted":false,"coldInstallPassed":false,"localLaunchPassed":false,"localLaunchRootCause":"Hardened runtime library validation rejected independently ad-hoc-signed Flutter frameworks."},"roadmapReconciliation":{"lot":"RM-072","commit":"e1d92c9a4829458141de58722875b0346f3d35c1","dashboard":"reports/gameplay/evidence/rm_072_gameplay_roadmap_dashboard.md","dashboardSha256":"9ffc746d6404eca03aaf6f4f29beb006d9299ef58abea318ad7239ea52465fe2","dashboardCounts":{"DONE":40,"PARTIAL":12,"BLOCKED":0,"TODO":41,"DEFERRED":21},"fg185":"PARTIAL"},"candidateCapture":{"rawEvidenceRelativePath":"build/phase-7a/rm-073-79b1e8750/package-evidence.json","rawEvidenceSha256":"be63f624b77c728d62f3b132a9e8ba657551cb078744459c6f17e25f6f6a7c06","rawTestLogRelativePath":"build/phase-7a/rm-073-79b1e8750/test.log","rawTestLogSha256":"a5ab30d73e957707b8f0995838448c2ba641ced574e69d1c8ad189c3c5e413ff","rawArtifactsTracked":false,"note":"Raw package, support directory, evidence, and log remain ignored local build artifacts; their committed digests bind this receipt to the capture."}},"humanWalkthrough":{"present":false,"validated":false,"validator":"examples/playable_runtime_host/lib/src/human_walkthrough_receipt_validator.dart","schemaVersion":1,"requiredReleaseCandidateCommit":"79b1e87508a2d60ca035faa6cf49e807d0dcdf6a","requiredProjectTreeHashSha256":"b62416c314d56e34b3690cebe845270bd7e663dab46f18595ef1cb292977efe4","requiredPackageSha256":"ac349ee7c5bd0bc2022cfe30addc88109b6f200acf455447c5d97947a071a495","requiredCheckpointIds":["new-game","capture","save-reload","ending"],"blockingReason":"No fresh human receipt for the same commit, project tree, and installed package was supplied."},"postMvpCutline":{"acceptedAsLimitations":["RM-024 held items","RM-028 nature, IV and EV","RM-029 Struggle","RM-036 and RM-037 hazards and pickups","RM-038 templates","RM-043, RM-044, RM-046 to RM-049 and RM-052 map, identity, sale, metadata, evolution, TM and display completeness","RM-053 full battle capability gate","all PH-* personalization lots"],"scopeExpansionForbidden":true},"decision":{"release":"NO_GO","fg185":"PARTIAL","rm073":"DONE","passedConditions":["Clean authorized candidate commit captured","Project and scenario fingerprints captured","Package exported, inspected, installed and load-smoked","Installed golden journey passed 19 of 19 without shortcuts","Full monorepo regression matrix passed 20 of 20","macOS universal release bundle compiled","Roadmap and reports reconciled"],"blockingConditions":["Hub bundle lacks a Developer ID signature, notarization, stapled ticket and Gatekeeper acceptance","Cold install and relaunch on a clean macOS device are unproven","Human walkthrough receipt matching the candidate commit, project tree and package is absent","Non-macOS platform builds were not approved and are not release evidence"],"promotionRule":"Do not change FG-185 to DONE/GO until every blocking condition is closed by fresh evidence for one coherent release candidate."},"passes":[{"name":"Audit / Architecture","verdict":"The final receipt aggregates existing lot receipts and a clean installed-package capture without moving gameplay rules across package boundaries."},{"name":"Implementation","verdict":"Evidence mode persists candidate, project, package, installation and 19-criterion data while normal test behavior remains unchanged."},{"name":"Tests","verdict":"Normal mode and clean-candidate evidence mode each passed the full installed golden journey."},{"name":"Build / Validation","verdict":"Automated evidence is green, but RM-071 distribution and human QA remain incomplete."},{"name":"Final Critique","verdict":"The receipt deliberately returns NO_GO; a successful compile and automated scenario cannot substitute for signed distribution or human observation."}],"risks":["The package signature status is notPresent and the Hub bundle is only ad-hoc signed.","Raw evidence artifacts under build/ are local and disposable; committed SHA-256 digests preserve identity but not availability.","Installation validatedAt/installedAt use the deterministic test clock and must not be interpreted as wall-clock capture timestamps.","The human validator contract currently requires four release checkpoints; broader visual, audio, controller and accessibility observations still need an explicit QA checklist.","A later code or content change creates a new candidate and invalidates this receipt until all candidate-bound evidence is regenerated."]}
```
