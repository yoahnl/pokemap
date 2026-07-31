# PMCP-084 — MCP mutation, rendu, playtest et historique

Date : 2026-07-31
Lot : `PMCP-084` — exposer toute la puissance de l’API sans élargir la surface MCP
Verdict proposé : **DONE**

## Résumé exécutif

Le serveur MCP PokeMap expose maintenant les sept capacités prévues par le lot : `pokemap_plan`, `pokemap_apply`, `pokemap_render`, `pokemap_playtest`, `pokemap_job`, `pokemap_history` et `pokemap_recovery`. Elles complètent les cinq tools de lecture de PMCP-083 sans dupliquer les règles métier : mutations et historique traversent le worker JSONL Dart canonique, le rendu traverse `RuntimeAuthoringMapRenderAdapter`, et les playtests traversent le runner PokeMap Eval existant.

Le scénario réel `selbrume.healing-service` a été exécuté de bout en bout via le MCP produit : état `succeeded`, reçu présent, deux artefacts enregistrés et aucun chemin absolu exposé. La suite MCP contient 18 tests verts. La suite complète `map_authoring` contient 293 tests verts. Le lot peut être proposé `DONE`; la phase 7 entière peut donc être proposée `DONE` sous réserve de la gate de conformance globale PMCP-085, qui reste volontairement hors scope.

## Confirmation du scope

Périmètre réalisé conformément à la roadmap :

- plan, preview, validation, apply et retry idempotent ;
- confirmation plan-bound pour les actions destructives ;
- rendu map/région révisionné et artefact PNG opaque ;
- playtest sandboxé, polling, événements, annulation et retry ;
- historique paginé et undo ;
- recovery derrière permission canonique et phrase exacte ;
- liens `artifact://` seulement ;
- erreurs structurées, retryabilité et remédiation préservées.

Non-périmètre conservé : transport HTTP, authentification distante, persistance des jobs après redémarrage, scénarios runtime libres, rendu asset-accurate et revendication de couverture « 100 % » avant PMCP-085.

## Audit initial

- Base de départ : commit `6476680c` (`PMCP-083`).
- Rapports lus : `pmcp_080_editor_read_migration_evidence.md`, `pmcp_081_editor_mutation_migration_evidence.md`, `pmcp_082_mcp_sdk_compatibility_decision.md` et `pmcp_083_mcp_read_only_evidence.md`.
- Le contrat `AuthoringMutationApiPort` possédait déjà plan/confirm/apply/undo/recover, mais aucune lecture paginée de l’historique.
- `JsonlWorker` exposait les mutations canoniques, mais pas `history`.
- `RuntimeAuthoringMapRenderAdapter`, `RuntimePlaytestPort`, `EvaluationPlaytestDriver` et `EvaluationAuthoringJobService` existaient déjà depuis PMCP-070 à PMCP-072.
- Le CLI PokeMap Eval savait exécuter les scénarios enregistrés et produire un reçu plus des artefacts, mais aucun adaptateur MCP ne gérait son process, sa sandbox, ses jobs ou son registre d’artefacts.
- Le registre MCP PMCP-083 ne contenait que les cinq tools de lecture.
- Risques identifiés : fuite de chemins, réimplémentation TypeScript des règles Dart, mutation sans plan, retry duplicatif, conflit masqué, recovery sans double barrière, process runtime orphelin, scénario appliqué au mauvais projet et artefact sortant de la racine.
- Limite de scope : réutiliser les ports et runners existants ; aucun changement des règles de gameplay, de l’éditeur ou des chantiers Smart Tiles concurrents.

## Architecture retenue

```text
Client MCP
  ├─ lecture/query/validate ───────────────┐
  ├─ plan/apply/history/recovery ─────────┼─ LocalAuthoringClient
  │                                       │  -> worker JSONL map_authoring
  ├─ render -> root binding serveur       │  -> pokemap_render.dart
  │                                       │  -> RuntimeAuthoringMapRenderAdapter
  └─ playtest/job -> root binding serveur ┘  -> PokeMap Eval headless/interactive
                                               -> receipt + artifact://
```

Les racines restent des bindings privés du process MCP. Le modèle ne reçoit que `projectHandle`, `workspaceHandle`, `jobId`, révisions, reçus nettoyés et URIs opaques. Les sorties stderr des enfants sont drainées et ne traversent jamais le protocole.

## Passes de contrôle et verdicts

La contrainte active de session interdisait de lancer des sub-agents sans demande explicite de l’utilisateur. Les cinq rôles obligatoires de `codex_rule.md` ont donc été exécutés comme passes locales séparées.

1. **Audit / Architecture — PASS** : les règles restent dans `map_authoring` et `map_runtime`; le runtime ne dépend plus du dossier de handlers MCP après extraction de `tool_error.ts`.
2. **Implémentation — PASS** : les sept tools sont composés dans le serveur produit ; historique JSONL, bindings de racines, rendu, jobs et artefacts sont opérationnels.
3. **Tests — PASS** : positif, négatif, garde-fous, non-régression, retry, conflit, permission, mismatch projet, annulation et exécution réelle couverts.
4. **Build / Validation — PASS** : build TypeScript, analyses Dart/Flutter et suites ciblées/complètes concernées sont verts.
5. **Critique finale — PASS avec limites documentées** : aucune modification Smart Tiles indexée, aucun chemin absolu dans les résultats MCP, aucun parseur métier TypeScript. Les jobs restent process-local et le catalogue de playtest reste explicitement borné.

## Inventaire complet des fichiers du lot

### Fichiers créés

- `packages/map_runtime/bin/pokemap_render.dart` — worker de rendu one-shot, borné à une racine autorisée, réponse JSON path-free et PNG encodé uniquement pour le registre interne.
- `tools/pokemap_mcp/src/runtime_gateway.ts` — orchestration render/playtest/job, process groups bornés, collecte d’artefacts et nettoyage des reçus.
- `tools/pokemap_mcp/src/tool_error.ts` — erreur partagée et sûre hors worker Dart.
- `tools/pokemap_mcp/src/tools/mutations.ts` — plan/apply/history/recovery et confirmations.
- `tools/pokemap_mcp/src/tools/result.ts` — enveloppe structurée commune et normalisation des erreurs.
- `tools/pokemap_mcp/src/tools/runtime.ts` — render/playtest/job et schémas stricts.
- `tools/pokemap_mcp/test/mutation_server.test.ts` — batch, parity CLI/MCP, retry, conflit et recovery.
- `tools/pokemap_mcp/test/runtime_server.test.ts` — rendu réel, artefacts, jobs, événements, cancel, retry et mismatch projet.
- `reports/analysis/pmcp_084_mcp_mutation_runtime_evidence.md` — présent Evidence Pack.
- `reports/analysis/pmcp_084_mcp_mutation_runtime_evidence_appendix.md` — contenu intégral des huit fichiers source/test créés.

### Fichiers modifiés

- `packages/map_authoring/lib/src/api/authoring_mutation_api.dart` — ajoute `history(projectHandle, limit, cursor)` au port.
- `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart` — conserve le store d’historique par session et sérialise une page stable.
- `packages/map_authoring/lib/src/tooling/jsonl_worker.dart` — ajoute la commande stricte `history`.
- `packages/map_authoring/test/tooling/jsonl_mutation_worker_test.dart` — couvre history et la parité directe API/JSONL.
- `tools/pokemap_mcp/README.md` — documente le workflow complet et les options runtime.
- `tools/pokemap_mcp/src/authoring_client.ts` — conserve côté serveur les bindings handle→racine et les invalide à la fermeture.
- `tools/pokemap_mcp/src/config.ts` — découvre/valide repo, package runtime et host Eval.
- `tools/pokemap_mcp/src/index.ts` — compose et ferme le runtime gateway.
- `tools/pokemap_mcp/src/server.ts` — enregistre mutations et runtime, met à jour les instructions produit.
- `tools/pokemap_mcp/src/tools/read_only.ts` — réutilise l’enveloppe et la normalisation communes.
- `tools/pokemap_mcp/test/protocol_compatibility.test.ts` — fixe la liste produit à douze tools.
- `tools/pokemap_mcp/test/read_only_server.test.ts` — conserve les preuves read-only tout en reconnaissant les tools de mutation.

L’appendice reproduit intégralement les huit fichiers source/test créés. Les deux rapports ne sont pas reproduits récursivement.

## Diffs et zones précises modifiées

### Contrat canonique Dart

- `AuthoringMutationApiPort` : nouvelle méthode `history`.
- `LocalMapAuthoringMutationApi.describeMutations` : commande `history` annoncée.
- `_LocalMapAuthoringSession.open` : injection du `AuthoringHistoryStore` déjà créé pour les commits/undo.
- `_LocalMapAuthoringSession.history` : validation cursor par `AuthoringHistoryCursor`, limite `1..100` déléguée au store, entries et `nextCursor` gelés.
- `JsonlWorker._dispatch` : clés exactes `{projectHandle, limit, cursor}`, type entier obligatoire et délégation directe.

### MCP mutation

- `pokemap_plan` accepte le contrat d’action complet, garde `dryRun` explicite et ne modifie rien.
- `pokemap_apply` sépare `confirm` et `apply`; l’operation id reste explicite et le token n’est jamais reconstruit.
- `pokemap_history` sépare pagination et undo.
- `pokemap_recovery` exige exactement `RECOVER <operationId>` avant d’atteindre le worker, qui applique ensuite sa permission `project.recovery`.
- Les erreurs Dart conservent `code`, `domainCode`, `retryable`, `remediation` et `details`.

### MCP runtime

- `LocalAuthoringClient` mémorise la racine uniquement après un `open` canonique réussi et supprime le binding lors de `close`.
- `pokemap_render.dart` recharge un snapshot strict, appelle l’adaptateur runtime, calcule un handle content-addressed et ne renvoie aucun chemin.
- `LocalRuntimeGateway` maintient états et événements ordonnés, nouvelle identité sur retry, signal d’annulation, `SIGTERM` puis `SIGKILL` borné pour le groupe de process POSIX.
- Le scénario Eval est résolu par ID dans le catalogue fixe puis comparé à la racine réelle du `projectHandle`.
- Le reçu public retire `receiptPath`/`relativeReceiptPath` et remplace les chemins d’artefacts par des références `artifact://sha256/...`.
- La collecte refuse `..`, suit les liens uniquement pour vérifier que leur cible reste dans le repository, et limite stdout enfant à 32 MiB.

### Composition et documentation

- Le binaire stdio instancie un registre d’artefacts partagé, le runtime gateway et le worker Authoring, puis les ferme ensemble.
- La configuration accepte les overrides explicites sans rendre les chemins accessibles aux tools.
- Le README remplace l’ancien workflow PMCP-083 read-only par le workflow plan→apply→render/playtest/history/recovery.

## Tests créés ou modifiés

### Positifs

- création de map, preview, apply, retry identique, query et validation ;
- batch atomique `map.apply_operations` après création ;
- historique ordonné ;
- rendu réel `golden_town`, dimensions et signature PNG ;
- playtest job réussi avec receipt, artefact et événements ;
- retry d’un job échoué vers un nouvel attempt ;
- scénario réel Selbrume via le serveur MCP produit.

### Négatifs et garde-fous

- conflit de révision renvoyé sans replan silencieux et sans fichier créé ;
- recovery bloqué avant le worker si la phrase diffère ;
- permission canonique refusée préservée après confirmation ;
- scénario Selbrume refusé sur un autre projet ;
- sortie de racine et handles d’artefacts inconnus conservés des tests PMCP-083 ;
- annulation d’un job bloqué ;
- protocole non supporté et configuration sans racine toujours refusés.

### Non-régression

- protocole MCP moderne et fallback ;
- cinq tools de lecture et quatre resources ;
- suite complète `map_authoring` ;
- rendu runtime existant ;
- ports playtest/job du host ;
- analyses de trois packages.

## TDD et incidents utiles

- Après enregistrement des mutations, les deux tests de liste PMCP-083 ont échoué parce qu’ils attendaient encore cinq tools. Les attentes ont été étendues et vérifient désormais séparément les annotations read-only et mutation.
- Le premier lancement du render worker a échoué à la compilation sur `MapSize`; le modèle canonique utilise `GridSize`. Le type a été corrigé avant toute preuve positive.
- Le premier lancement avec une racine relative contenant `..` a été refusé par `WorkspacePolicy`, comme prévu. Les adaptateurs de production transmettent des racines absolues déjà autorisées.
- `exactOptionalPropertyTypes` a refusé les propriétés optionnelles explicitement `undefined`; les handlers reconstruisent maintenant les objets en omettant réellement ces clés.
- La critique architecture a détecté un import runtime→handler pour l’erreur commune ; `PokeMapToolError` a été remontée dans `src/tool_error.ts`.
- La critique confidentialité a détecté les chemins relatifs présents dans le reçu Eval privé ; le reçu MCP les remplace maintenant par les références opaques enregistrées.

## Commandes et résultats exacts

### MCP TypeScript

```text
cd tools/pokemap_mcp
npm run check
Résultat exact : tsc -p tsconfig.json --noEmit — exit 0

npm test
Résultat exact : tests 18, pass 18, fail 0, cancelled 0, skipped 0, todo 0
Le script exécute npm run build avant les tests ; build TypeScript exit 0.
```

### API / worker Dart

```text
cd packages/map_authoring
dart test test/tooling/jsonl_mutation_worker_test.dart --reporter compact
Résultat exact : +1, All tests passed!

dart test --reporter compact
Résultat exact : +293, All tests passed!

dart analyze
Résultat exact : No issues found!
```

### Runtime render

```text
cd packages/map_runtime
flutter test test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart
Résultat exact : +2, All tests passed!

flutter analyze
Résultat exact : No issues found! (ran in 4.9s)

printf <render-json> | dart run bin/pokemap_render.dart --root <absolute-golden-root>
Résultat exact : status=success, image/png, 6x5, byteLength=89, handle artifact://sha256/...
```

### Runtime playtest / jobs

```text
cd examples/playable_runtime_host
flutter test test/evaluation/evaluation_authoring_job_service_test.dart test/evaluation/evaluation_playtest_adapter_test.dart
Résultat exact : +6, All tests passed!

flutter analyze
Résultat exact : No issues found! (ran in 6.2s)

dart run tool/pokemap_eval.dart run selbrume.healing-service --json --target headless
Résultat exact : status=succeeded, exitCode=0, passedSteps=5, totalSteps=5

node --input-type=module -e <MCP production playtest probe>
Résultat exact : {"state":"succeeded","scenarioId":"selbrume.healing-service","receipt":true,"artifactCount":2,"pathsExposed":false}
```

## État Git

État initial : `6476680c`, avec modifications externes non liées dans `packages/map_editor`, `examples/playable_runtime_host/pubspec.lock` et `.superpowers/brainstorm/...`.

Pendant le lot, d’autres modifications externes Smart Tiles sont apparues dans `packages/map_core` et `packages/map_editor`. Elles n’ont été ni éditées intentionnellement, ni restaurées, ni indexées par ce lot. Le lockfile du host, déjà sale, a pu être rafraîchi par Flutter et reste explicitement hors commit.

État final avant commit : uniquement les vingt fichiers d’implémentation/test listés ci-dessus et les deux rapports PMCP-084 doivent être indexés. `dist/`, `node_modules/`, build Eval et tous les chantiers externes restent hors commit.

## Critères de fin PMCP-084

- Agent crée/configure une map par batch, preview, validate et apply : **oui**.
- Retry ne double pas la mutation : **oui**, résultat appliqué strictement identique.
- Conflit retourné sans interprétation silencieuse : **oui**, `revision_conflict`, retryable, aucun fichier conflictuel.
- Playtest sandboxé retourne reçu et artefacts : **oui**, fake contrôlé permanent et scénario Selbrume réel via MCP.
- Recovery exige permission et confirmation : **oui**, les deux barrières sont testées séparément.
- Render retourne un artefact opaque réel : **oui**, PNG produit par `map_runtime` et relu par `pokemap_artifact`.
- Jobs get/events/cancel/retry : **oui**, états et séquences testés.
- Parité API/CLI/MCP : **oui**, API↔JSONL comparée dans Dart, MCP↔CLI exécutée par `LocalAuthoringClient`, mêmes reçus canoniques sans transformation métier.

## Limites explicitement conservées

- Les jobs et bytes d’artefacts vivent en mémoire du process MCP ; un redémarrage invalide leurs handles.
- Les playtests de production n’acceptent que les scénarios déclarés par PokeMap Eval et liés exactement au projet ouvert. Le catalogue actuel de production est Selbrume ; aucun script arbitraire n’est accepté.
- Le rendu est le preview déterministe sémantique de `map_runtime`, pas une capture asset-accurate du jeu.
- Le mode job reste `pokemap_job`, car l’API Tasks TypeScript stable n’était pas disponible lors de PMCP-082.
- L’annulation tue un groupe de process sur POSIX ; sur Windows, Node ne fournit ici qu’un signal au process enfant direct.
- Le transport reste stdio local. HTTP/auth distante restent hors scope.
- La roadmap n’est pas modifiée par ce lot ; le présent rapport propose les statuts.

## Auto-critique finale

Le lot est volumineux mais respecte la dépendance essentielle : TypeScript orchestre, Dart décide. `runtime_gateway.ts` concentre encore jobs, process et collecte d’artefacts ; une extraction future en trois modules améliorerait la lisibilité, sans bénéfice fonctionnel immédiat. Le démarrage Dart/Flutter reste visible dans les tests et dans le premier appel render/playtest. Une worker pool persistante pourrait réduire ce coût, mais elle appartient à une optimisation ultérieure et demanderait une nouvelle analyse de cycle de vie.

Le principal risque restant est la volatilité des jobs/artefacts, pas leur exactitude. Aucune capacité distante n’a été ouverte, aucun chemin absolu n’est renvoyé, et le scénario réel prouve la consommation par le moteur. Le verdict `DONE` est donc justifié pour PMCP-084 sans anticiper PMCP-085.

## Suite proposée

- Proposer `PMCP-080`, `PMCP-081`, `PMCP-082`, `PMCP-083` et `PMCP-084` comme `DONE`, donc phase 7 `DONE`.
- Passer à `PMCP-085` pour la conformance, la sécurité et la gate finale « 100 % ».
- Ne pas ajouter de transport réseau avant d’avoir défini authentification, quotas, persistance et modèle de menace.
