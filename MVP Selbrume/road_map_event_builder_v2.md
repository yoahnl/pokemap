# Event Builder V2 — Canonical Source-First Roadmap

## Statut du document

```text
Roadmap vivante : V0
Lot fondateur : NS-EVENT-RESET-00
Mode d'execution : missions par phase, anciens lots conserves comme jalons
Macro-phases : 12 (A a L)
Missions executables : 13 (A, B, C, D, E, F1, F2, G, H, I, J, K, L)
Jalons traces : 44 au total, RESET-00 + V2-01 a V2-43
Architecture : hybride projet + ancres de map
Phase A : CLOSED / ACCEPTED le 2026-07-10
Phase D : CLOSED / ACCEPTED le 2026-07-13
Prochaine mission : PHASE E - Authoring Operations
```

Cette roadmap remplace la progression incrémentale du seul Event Builder
map-local. Elle ne supprime aucun projet existant et ne change pas le statut des
lots gameplay `FG-*` sans preuves fraîches.

Le registre normatif des décisions est :

```text
MVP Selbrume/event_builder_v2_architecture_decisions.md
```

L'audit RESET-00 reste une preuve historique. En cas d'écart, le ledger
`ADR-EV2-*` ratifié en Phase A est prioritaire.

## Modèle d'exécution par phases

```text
1 phase = 1 mission principale Ultra
1 ancien lot = 1 jalon interne de phase
1 jalon = code borné + tests ciblés + review locale
1 phase = 1 rapport principal + 1 Evidence Pack
```

Chaque mission suit :

```text
Gate 0
-> audit de fraîcheur
-> jalon N
-> tests ciblés puis cumulés
-> review locale
-> jalon suivant
-> vérifications complètes
-> reviews contradictoires
-> Evidence Pack
-> rapport et verdict de phase
```

Les jalons V2-01 à V2-43 ne sont plus des prompts indépendants. Ils restent les
checklists, dépendances, scopes et preuves internes de leur mission parente.

## Modèle de statut

| Objet | Valeurs autorisées |
|---|---|
| Mission | `PLANNED`, `READY`, `IN_PROGRESS`, `CLOSED`, `BLOCKED`, `ROLLED_BACK` |
| Gate | `PENDING`, `ACCEPTED`, `REJECTED` |
| Jalon | `PLANNED`, `IN_PROGRESS`, `PASS`, `BLOCKED`, `WAIVED` |

Un jalon `WAIVED` exige un ADR accepté et ne peut pas supprimer une capacité du
Gate de sortie.

## Evidence Pack et stop-on-blocker

Chaque Evidence Pack contient : baseline Git/SHA et drifts, inventaire des
fichiers/symboles, ledger des jalons, commandes et résultats exacts, tests de
compatibilité/rollback, reviews, risques résiduels et état Git final.

Si un jalon invalide un ADR de Phase A, rencontre une migration ambiguë, échoue
une vérification obligatoire ou perd sa preuve de rollback :

1. arrêter immédiatement la mission ;
2. marquer jalon et mission `BLOCKED` ;
3. préserver l'état et ne pas improviser un nouveau contrat ;
4. produire un Blocker Report avec preuves ;
5. obtenir un nouvel ADR et repasser le Gate d'entrée avant reprise.

## Décisions fondatrices ratifiées

1. `NarrativeEventDefinition` est l’Event configuré canonique, fin et
   project-level.
2. `NarrativeEventRecord` sépare `draft` incomplet de `configured` valide ;
   `enabled` appartient au variant configured et seuls `configured + enabled`
   entrent dans le runtime.
3. Un Event configuré possède exactement une source typée V0 ; une source peut
   être référencée par plusieurs Events.
4. L’Event ne possède pas de position. `MapEntity`, `MapTrigger` ou la map
   possèdent la géométrie.
5. Les IDs Event sont uniques au niveau projet et immuables dès la création du draft.
6. `MapEventDefinition` devient legacy read/adapter/migration input ; aucun write
   V2 normal ne le cible.
7. Les sources de `ScenarioAsset` deviennent un bridge legacy ; le V2 ne les
   étend pas comme modèle Event.
8. L’Event configuré cible exactement une `SceneAsset`. Outcomes, branches et conséquences restent
   Scene-owned et read-only dans l’Event Builder.
9. V0 couvre `entityInteract`, `triggerEnter`, `mapEnter` et
   `outcomeReceived`.
10. Résolution V0 : candidats éligibles, priorité explicite, ordre explicite,
    `eventId` comme dernier tie-breaker, un seul candidat sélectionné pour le
    snapshot runtime.
   L'UI expose la priorité lorsqu'une source a plusieurs Events actifs ; l'ordre
   stable et le tie-break technique restent internes mais sont expliqués par le
   diagnostic de conflit.
11. `oneShot` est consommé après réussite complète de la Scene ; `reusable` ne
    l’est pas ; save/load est refusé pendant une Scene active non checkpointable.
12. Migration : dual-read temporaire, single-write V2, preview non destructive,
    opt-in et rollback.
13. La north star 1672 × 941 est la cible visuelle, avec écarts volontaires pour
    protéger Event ≠ Scene.
14. `outcomeReceived` stocke une référence qualifiée
    `(producerKind, producerId, outcomeId)` avec producteurs V0 `scene`,
    `battle`, `legacyScenario`. Yarn est qualifié par sa Scene.
15. `NarrativeEventRegistry` porte son propre `schemaVersion`, le mode
    `legacyOnly | dualRead | v2Only` et des `LegacySourceClaim`. Il ne modifie pas
    l'enum `ProjectVersion` partagé avec les maps.
16. Un coordinateur de dispatch unique consulte mode et claims. Un Event V2
    revendiqué mais inéligible bloque le fallback legacy.
17. La progression V2 stocke des IDs Event globaux et une outbox d'outcomes dans
    un namespace séparé du legacy `consumedEventIds`.
18. Les conditions V0 sont un AND ordonné de `fact` et
    `narrativeEventConsumed`; Story Step reste exclu tant que son identité n'est
    pas globalement qualifiée.
19. Les IDs Event suivent `evt_<uuid-v7>` et sont immuables dès la création du
    draft.
20. Aucun feature flag indépendant ne concurrence `EventSystemMode`.

## Règles communes aux jalons

- Toute donnée legacy est lue avant d’être migrée.
- Aucun lot ne combine modèle, migration, runtime et UI dans un seul diff.
- Les generated files sont régénérés seulement dans le package modifié.
- Les Visual Gates utilisent la référence hashée de NS-EVENT-RESET-00.
- Tout changement de schema possède fixture avant/après et rollback.
- Tout lot runtime possède preuve positive, négative, réentrance et save/load si
  pertinent.
- Toute UI normale masque les termes techniques de stockage.

## Chemins existants vérifiés par RESET-00

Les roots et contrats existants cités dans cette roadmap ont été vérifiés :

```text
packages/map_core
packages/map_editor
packages/map_gameplay
packages/map_runtime
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
```

Les noms de fichiers introduits par `nouveau` ou décrits sans chemin complet
sont des destinations proposées. Une mission peut choisir un autre chemin dans
le même package si elle documente ce choix sans changer le contrat ratifié.

---

# Phase A — Canonical Architecture Decisions — CLOSED / ACCEPTED

```text
Mission : NS-EVENT-V2 - PHASE A
Lifecycle : CLOSED
Gate de sortie : ACCEPTED
Date : 2026-07-10
```

## Objectif

Arrêter l’architecture produit, domaine, runtime, migration et visuelle avant
toute implémentation.

## Entry criteria

- Event Builder V1 livré jusqu’à NS-EVENT-41-bis.
- Deux pipelines concurrents identifiés.
- Sources produit Selbrume disponibles.
- Image north star disponible.

## Exit criteria

- ADR-EV2-001 à ADR-EV2-020 acceptés ;
- architecture D, contrats publics, ownership et runtime semantics ratifiés ;
- ledger et rapport de clôture créés ;
- roadmap convertie en missions par phases ;
- Phase F scindée en F1/F2 ;
- reviewers architecture et produit sans blocker ;
- Entry Gate de Phase B accepté.

## Jalons internes

### NS-EVENT-RESET-00 — Canonical Event Sources & Event Builder V2 Ultra Roadmap

- **Type :** audit.
- **Objectif :** produire la décision canonique et la roadmap exécutable.
- **Problème traité :** création abstraite par position et coexistence de trois vocabulaires Event.
- **Dépendances :** NS-EVENT-41-bis ; sources produit Selbrume.
- **Packages concernés :** lecture de `map_core`, `map_editor`, `map_runtime`, `map_gameplay` ; aucune modification.
- **Fichiers probables :** trois documents de ce lot.
- **Contrats créés/modifiés :** aucun code ; contrat conceptuel seulement.
- **Non-objectifs :** production, migration, prototype, build.
- **Risques :** décision trop abstraite ou non reliée au repo.
- **Compatibilité :** aucun changement de données.
- **Tests ciblés :** non applicables.
- **Régressions :** anti-scope Git.
- **Analyse/build :** non requis.
- **Visual Gate :** analyse de la référence, pas de capture implémentation.
- **Critères d’acceptation :** trois documents complets, prochain lot exact.
- **Evidence Pack :** Gate 0/final, MCP Dart, inventaire, sous-agents.
- **Rollback :** supprimer uniquement les trois documents avant commit.
- **Impact suivant :** débloque la ratification détaillée de Phase A.
- **Taille :** L.
- **Bloquant :** oui.

## Clôture de mission

La mission Phase A a produit :

```text
MVP Selbrume/event_builder_v2_architecture_decisions.md
reports/narrativeStudio/events/ns_event_v2_phase_a_architecture_ratification_closure_v0.md
MVP Selbrume/road_map_event_builder_v2.md
```

RESET-00 est confirmé comme baseline fraîche. Ses décisions ouvertes sont
surclassées par les ADRs ratifiés ; aucune erreur factuelle importante n'exige
d'addendum à l'audit et la spécification visuelle reste compatible.

## Risques

- divergence entre recommandations historiques ;
- confusion `ScenarioAsset` / Event / Scene ;
- copie visuelle aveugle.

## Gate de validation

`ACCEPTED` : reviews architecture + UX contradictoires sans blocker après
corrections, 20 ADRs présents, validations documentaires et anti-scope verts.

## Livrable final

Ledger normatif, rapport de clôture, roadmap phase-based et Entry Gate B.

---

# Phase B — Domain Contracts — CLOSED / ACCEPTED

```text
Mission : NS-EVENT-V2 - PHASE B
Lifecycle : CLOSED
Gate d'entrée : ACCEPTED par Phase A
Gate de sortie : ACCEPTED
Date : 2026-07-10
Jalons : V2-01 à V2-04
```

## Objectif

Créer les contrats purs et sérialisables de l’Event V2 sans consumer runtime ou
UI.

## Entry criteria

- Phase A `CLOSED / ACCEPTED` et aucun nouvel ADR supersédant le ledger.
- `NarrativeEventSourceRef` avec quatre variants exacts.
- `NarrativeOutcomeRef` et producers `scene`, `battle`, `legacyScenario`.
- IDs `evt_<uuid-v7>` globaux et immuables.
- `NarrativeEventCondition` limité à Fact et Event V2 consommé, AND ordonné.
- champs exacts draft/definition/record et publication désactivée par défaut.
- `eventRegistry` nullable, schema `1`, JSON strict/fail-closed.
- modes et truth table d'autorité ratifiés.
- claims qualifiés avec cohortes, empreintes et receipt.
- absence de position et politique Event -> exactement une Scene.
- lifecycle, progression/outbox et compatibilité JSON ratifiés.
- Gate 0 Phase B confirme un worktree sans drift de production non attribué.

## Exit criteria

- source union typée ;
- Event fin et records draft/configured ;
- registry manifest versionné indépendamment ;
- index structurel déterministe, sans `GameState`.

## Jalons internes

### NS-EVENT-V2-01 — Canonical Narrative Event Source Ref Contract V0 — PASS

- **Type :** core.
- **Objectif :** introduire l’union typée des quatre sources V0.
- **Problème traité :** chaînes magiques et couples source/trigger invalides.
- **Dépendances :** RESET-00.
- **Packages concernés :** `packages/map_core`.
- **Fichiers probables :** nouveau `lib/src/models/narrative_event_source_ref.dart`, barrel, tests.
- **Contrats créés/modifiés :** `NarrativeEventSourceRef` avec `outcomeReceived(outcome: NarrativeOutcomeRef)`, `NarrativeOutcomeRef`, `NarrativeOutcomeProducerKind(scene, battle, legacyScenario)`, kind et clé structurelle.
- **Non-objectifs :** Event complet, manifest, runtime, UI.
- **Risques :** duplication des enums Scenario existantes.
- **Compatibilité :** adapter de conversion conceptuel seulement ; aucune donnée V1 écrite.
- **Tests ciblés :** factories, equality, JSON, malformed, clés déterministes, mêmes outcomeId sous producteurs distincts.
- **Régressions :** tests `NarrativeEventSourcePickerOption` et Scenario source.
- **Analyse/build :** `dart test`, `dart analyze`, build_runner map_core.
- **Visual Gate :** non.
- **Critères d’acceptation :** quatre variantes exactes, provenance outcome obligatoire, aucune position, aucun label stocké.
- **Evidence Pack :** JSON goldens, API publique, diff generated borné.
- **Rollback :** retirer modèle/barrel/generated sans migration de données.
- **Impact suivant :** débloque V2-02, V2-09, V2-17.
- **Taille :** S.
- **Bloquant :** oui.

### NS-EVENT-V2-02 — Canonical Narrative Event Definition & Record Contract V0 — PASS

- **Type :** core.
- **Objectif :** créer l’Event fin et séparer record draft/configured.
- **Problème traité :** `MapEventDefinition` mélange géométrie/pages/présentation et un modèle toujours valide ne peut pas persister `Décider plus tard`.
- **Dépendances :** V2-01.
- **Packages concernés :** `packages/map_core`.
- **Fichiers probables :** nouveau `narrative_event_definition.dart`, tests, barrel.
- **Contrats créés/modifiés :** `NarrativeEventDefinition(id,name,source,conditions,sceneId,reusePolicy,priority,order)`, `NarrativeEventDraft`, `NarrativeEventRecord.draft/configured`, `enabled` sur configured.
- **Non-objectifs :** stockage manifest, migration, exécution.
- **Risques :** réintroduire des actions Scene-owned.
- **Compatibilité :** modèle opt-in non consommé.
- **Tests ciblés :** ID `evt_<uuid-v7>`, invariants source/Scene, draft incomplet round-trip, publication configured disabled, activation, oneShot/reusable, conditions V0 et JSON.
- **Régressions :** SceneAsset, EventBuilder V1 et WorldRule serialization.
- **Analyse/build :** `dart test`, `dart analyze`, build_runner map_core.
- **Visual Gate :** non.
- **Critères d’acceptation :** configured = une source/une Scene/zéro position ; draft incomplet jamais publiable ni indexable ; zéro outcome-owned.
- **Evidence Pack :** matrice champs/ownership, JSON golden.
- **Rollback :** retrait du modèle avant intégration manifest.
- **Impact suivant :** débloque V2-03 et authoring.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-03 — Project Manifest Event Registry, Mode & Claims Schema V0 — PASS

- **Type :** core.
- **Objectif :** stocker records, mode d'autorité et claims legacy avec version indépendante.
- **Problème traité :** absence de registry global, IDs inter-map ambigus et aucun propriétaire de dispatch dual-read.
- **Dépendances :** V2-02.
- **Packages concernés :** `packages/map_core`.
- **Fichiers probables :** `project_manifest.dart`, nouveau registry/claims codec, generated, tests.
- **Contrats créés/modifiés :** `ProjectManifest.eventRegistry?`, registry schema `1`, `EventSystemMode`, `LegacySourceRef`, `LegacySourceClaimMember`, `LegacySourceClaim(cohortId,source,members,cohortFingerprint,targetEventIds,migrationReceiptId)` ; aucun nouveau `ProjectVersion`.
- **Non-objectifs :** migrer un projet réel, modifier les maps.
- **Risques :** perte de clés JSON inconnues lors du save.
- **Compatibilité :** registry absent = `legacyOnly`; encode registry seulement sur opt-in.
- **Tests ciblés :** registry absent/null/present, ordre de listes préservé, draft/configured, trois modes, JSON canonique des unions, membres/targets triés, matrice invalid/unsupported/contextual claims, duplicate cohort/source/member, target absent ou de source différente, préimages RFC 8785 avec digests goldens connus, future registry version et champs inconnus fail-closed sans réécriture/runtime.
- **Régressions :** manifest scenes/scenarios/facts/worldRules.
- **Analyse/build :** map_core tests/analyze/build_runner.
- **Visual Gate :** non.
- **Critères d’acceptation :** round-trip sémantique ; mode/claims persistés ; aucune modification du schema de map ni de `ProjectVersion`.
- **Evidence Pack :** fixtures V1/V2, diff JSON.
- **Rollback :** mode `legacyOnly` et lecteur V1 conservé ; aucun projet migré.
- **Impact suivant :** débloque registry, repositories et migration.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-04 — Structural Event Source Index Contract — PASS

- **Type :** core.
- **Objectif :** compiler un index structurel pur source → records configurés.
- **Problème traité :** scans O(scénarios×nodes) et mélange index/éligibilité stateful.
- **Dépendances :** V2-03.
- **Packages concernés :** `packages/map_core` uniquement.
- **Fichiers probables :** nouveau index structurel, tests.
- **Contrats créés/modifiés :** source key qualifiée, record refs ordonnées, duplicate report.
- **Non-objectifs :** `GameState`, conditions, consumed, effets runtime, Scene execution.
- **Risques :** priorité incompatible avec données legacy.
- **Compatibilité :** tie-break documenté ; adapters alimenteront le même index.
- **Tests ciblés :** zéro/un/plusieurs records, draft/disabled exclus, source qualifiée, priorité/order/ID structurels, deux enabled en conflit tous deux indexés et triés par eventId avec diagnostic.
- **Régressions :** serialization Event et ordre Scenario existant ; aucun import `map_gameplay`.
- **Analyse/build :** tests/analyze des packages touchés.
- **Visual Gate :** non.
- **Critères d’acceptation :** lookup déterministe et complexité mesurée ; conflit importé reste indexé défensivement ; aucune décision d'éligibilité stateful.
- **Evidence Pack :** matrices et micro-benchmark baseline.
- **Rollback :** garder le scan legacy disponible tant que `dualRead` est supporté.
- **Impact suivant :** débloque runtime et diagnostics de conflits.
- **Taille :** M.
- **Bloquant :** oui.

## Clôture de mission

La Phase B livre les quatre contrats purs dans `packages/map_core` : sources et
outcomes qualifiés, records draft/configured avec UUIDv7, registry schema `1`
et preflight fail-closed, claims JCS/SHA-256, puis index structurel immuable.

Preuves de sortie :

- B1, B2, B3 et B4 : `PASS` après reviews R1/R2 ;
- suite complète `map_core` : `2652` tests passés ;
- `dart analyze` : aucune issue ;
- deux runs `build_runner` successifs : `0 outputs` ;
- aucun consumer runtime/editor et aucune donnée projet migrée ;
- baseline de performance B4 documentée dans l’Evidence Pack.

Le check global Dart 3.12 signale 67 fichiers historiques hors Phase B qui
seraient reformatés. Les 19 fichiers manuscrits du lot passent le même check
ciblé sans changement ; aucun churn historique n’est inclus.

## Risques

- modèle trop large ;
- generated churn ;
- version V2 écrite trop tôt ;
- duplication du runtime Scenario.

## Gate de validation

Tous tests map_core verts, analyse propre, goldens JSON approuvés, aucune donnée
fixture existante réécrite involontairement.

## Livrable final

Contrat Event V2 pur, versionné, indexable et encore sans consumer.

---

# Phase C — Legacy Compatibility & Migration

```text
Mission status : CLOSED / ACCEPTED le 2026-07-11
Gate d'entrée : ACCEPTED par Phase B le 2026-07-10
Gate de sortie : ACCEPTED — C0 à C4 PASS, aucun write legacy
Jalons : V2-05 à V2-08
```

## Objectif

Lire, diagnostiquer, prévisualiser et migrer sans destruction les Events de map
et les sources Scenario existantes.

## Entry criteria

- Phase B `CLOSED / ACCEPTED`.
- corpus legacy figé.
- politique collisions IDs et unknown JSON décidée.

## Exit criteria

- dual-read fiable ;
- preview classé AUTO_SAFE/ASSISTED/BLOCKED ;
- mappings du graphe de références et claims produits ;
- protocole de commit/récupération défini sans write réel.

## Jalons internes

### NS-EVENT-V2-05 — Legacy Event Corpus & Characterization Gate

- **Statut :** PASS — corpus figé et hashé le 2026-07-11.
- **Type :** migration.
- **Objectif :** figer comportements, données et graphe de références legacy avant conversion.
- **Problème traité :** absence de corpus exhaustif, références dispersées et migrations no-op.
- **Dépendances :** V2-03.
- **Packages concernés :** `map_core`, fixtures tests.
- **Fichiers probables :** fixtures actor/object/trigger/pages/scripts/metadata, conditions, World Rules, commandes, conséquences, saves, tests.
- **Contrats créés/modifiés :** aucun production ; catalogue de cas.
- **Non-objectifs :** conversion ou écriture.
- **Risques :** corpus non représentatif.
- **Compatibilité :** hash byte-for-byte de chaque entrée.
- **Tests ciblés :** decode et comportement actuel de chaque fixture, ordre first-valid multi-page, consommation explicite, collisions inter-map, préimages/digests goldens MapEvent et ScenarioAsset complets, calcul des cohortes complètes et détection de membre manquant/stale.
- **Régressions :** Event Builder V1, repositories.
- **Analyse/build :** tests/analyze map_core.
- **Visual Gate :** non.
- **Critères d’acceptation :** tous les cas du prompt couverts, dont pages multiples et références de consommation.
- **Evidence Pack :** inventaire, hashes, graphe mapId/eventId → consumers, expected diagnostics.
- **Rollback :** suppression fixtures seulement.
- **Impact suivant :** base de V2-06 à V2-08.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-06 — MapEventDefinition Read-Only Compatibility Adapter V0

- **Statut :** PASS — adapter read-only validé le 2026-07-11.
- **Type :** migration.
- **Objectif :** projeter un MapEvent legacy vers un candidat Event V2 sans write.
- **Problème traité :** map-local, position et pages incompatibles avec le canon.
- **Dépendances :** V2-02, V2-05.
- **Packages concernés :** `packages/map_core`.
- **Fichiers probables :** nouveau adapter/diagnostics/tests.
- **Contrats créés/modifiés :** `LegacyMapEventProjection`, confidence/classification.
- **Non-objectifs :** deviner une entité par collision de coordonnées ou matérialiser une source.
- **Risques :** multi-page et scripts non convertibles.
- **Compatibilité :** lecture seule ; JSON original intact.
- **Tests ciblés :** single page, multi-page first-valid, page sans Scene, script/message, missing layer, out-of-bounds, duplicate pos.
- **Régressions :** map event operations et Scene link diagnostics.
- **Analyse/build :** map_core tests/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** aucune conversion silencieuse ; l'adapter préserve l'ordre first-valid ; MapEvent autonome reste legacy/BLOCKED jusqu'à source explicite ; toute scission est seulement une proposition avec groupe de progression explicite.
- **Evidence Pack :** mapping champ par champ et pertes nulles/explicites.
- **Rollback :** supprimer adapter.
- **Impact suivant :** alimente read models et migration preview.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-07 — Scenario Source Compatibility & Authoring Freeze V0

- **Statut :** PASS — projection et authoring freeze validés le 2026-07-11.
- **Type :** migration.
- **Objectif :** lire les nodes source Scenario et verrouiller ceux revendiqués par V2 sans promouvoir ScenarioAsset en Event.
- **Problème traité :** second pipeline actif et encore modifiable après claim V2.
- **Dépendances :** V2-01, V2-05.
- **Packages concernés :** `map_core`, `map_editor`, tests runtime de caractérisation.
- **Fichiers probables :** adapter source-node, guard des use cases Scenario, diagnostics, fixtures P3.
- **Contrats créés/modifiés :** `LegacyScenarioSourceProjection`, authoring lock reason fondé sur `LegacySourceClaim`.
- **Non-objectifs :** aplatir conditions internes ou actions en Event.
- **Risques :** double dispatch après import.
- **Compatibilité :** source non claimée reste active ; source claimée devient read-only et non dispatchable par fallback.
- **Tests ciblés :** quatre source kinds, multiple source nodes, malformed bindings, claimed edit blocked, unclaimed edit preserved.
- **Régressions :** P3 source bridge et Scenario executor.
- **Analyse/build :** map_core/runtime tests ciblés, analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** projection fidèle, authoring claimé verrouillé avec raison humaine, aucune suppression du Scenario.
- **Evidence Pack :** fixtures P3, liste des semantics non converties.
- **Rollback :** retirer adapter sans donnée écrite.
- **Impact suivant :** V2-08 et suppression future du dual pipeline.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-08 — Migration Plan, Reference Mapping & Recovery Receipt V0

- **Statut :** PASS dry-run Phase C — applicabilité `ready/canApply` fermée
  par Phase D D0 le 2026-07-13.
- **Type :** migration.
- **Objectif :** produire un plan de migration pur, complet et réversible sans écrire.
- **Problème traité :** références dispersées, claims absents et promesse impossible de transaction multi-fichiers atomique.
- **Dépendances :** V2-06, V2-07.
- **Packages concernés :** `map_core`, tests de contrats editor-neutral.
- **Fichiers probables :** planner, report/receipt model, reference mapping, recovery protocol, tests.
- **Contrats créés/modifiés :** migration receipt, mapping IDs/pages/groupes de consommation, backup/hash.
- **Non-objectifs :** write filesystem, UI complète ou migration Selbrume réelle.
- **Risques :** collision d’IDs consommés irréversible.
- **Compatibilité :** dry-run uniquement ; BLOCKED sur ambiguïté ; original intact.
- **Tests ciblés :** plan déterministe/idempotent, split multi-page accepté/refusé, mappings progression/références, claim/receipt/cohort exacts, membre/page stale ou partiel, unknown keys et préconditions recovery.
- **Régressions :** serializers manifest/map et diagnostics legacy.
- **Analyse/build :** tests/analyze map_core.
- **Visual Gate :** non.
- **Critères d’acceptation :** zéro write ; receipt contient records, claims, progression/ref mappings, préconditions et plan de récupération ; downgrade V2-only explicitement impossible.
- **Evidence Pack :** fixtures, plan JSON golden, hashes attendus, matrice références.
- **Rollback :** supprimer le plan en mémoire ; aucun fichier n'a changé.
- **Impact suivant :** débloque authoring V2 et Golden Slice migration.
- **Taille :** M.
- **Bloquant :** oui.

## Risques

- ambiguïtés multi-page ;
- scripts/messages opaques ;
- collisions de consumed IDs ;
- double exécution legacy/V2 ;
- équivalence multi-page et graphe de références incomplets.

## Gate de validation

Corpus intégral classé, dry-run idempotent, claims et mappings complets, aucun
octet source modifié.

## Livrable final

Couche de compatibilité et plan de migration sûr, encore sans write utilisateur.

---

# Phase D — Source Catalogs & Read Models

```text
Mission status : CLOSED / ACCEPTED le 2026-07-13
Gate d'entrée : ACCEPTED par Phase C le 2026-07-11
Gate de sortie : ACCEPTED — D0 global et V2-09 à V2-12 PASS
Jalons : V2-09 à V2-12
```

## Objectif

Construire les catalogues projet, libellés humains, diagnostics et projections
nécessaires à l’authoring source-first.

## Entry criteria

- Phases B et C validées.
- conventions IDs immuables définies.
- toutes les maps chargeables en lecture.

## Exit criteria

- catalogues spatiaux et outcomes complets ;
- liste Events projet unifiée ;
- navigation et diagnostics sans vocabulaire technique.

## Jalons internes

## D0 — Migration Integrity Closure

```text
D0-A — Receipt & Choice Closure : PASS
D0-B — Contextual Integrity : PASS
D0 global : PASS
```

Le receipt est closed-world, les clés dupliquées sont rejetées et les choix
`confirmCandidate` / `explicitReassignment` restent distincts. Un plan
`ready/canApply` exige désormais un catalogue lié au snapshot exact et des
références source, Scene, Fact, Event et outcome contextuellement valides.

### NS-EVENT-V2-09 — Spatial Event Source Catalog V0

- **Statut :** PASS — catalogue spatial validé le 2026-07-13.
- **Type :** core.
- **Objectif :** cataloguer maps, `MapEntity` interactables et `MapTrigger`.
- **Problème traité :** Event Builder limité à la map active.
- **Dépendances :** V2-01, V2-03.
- **Packages concernés :** `map_core`.
- **Fichiers probables :** nouveau source catalog/read model, tests.
- **Contrats créés/modifiés :** source option humaine, map/entity/trigger status.
- **Non-objectifs :** outcomes et UI.
- **Risques :** coût de chargement de toutes les maps.
- **Compatibilité :** inclure projections legacy avec badge compatibilité.
- **Tests ciblés :** NPC/sign/item/custom, spawn disabled, trigger event/custom, trigger system disabled, MapPlacedElement disabled, 1×1/multi-cell, missing map.
- **Régressions :** narrative reference picker catalogs.
- **Analyse/build :** map_core test/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** matrice d'éligibilité explicite, labels humains, IDs stables, aucune position copiée ni MapPlacedElement présenté comme entity.
- **Evidence Pack :** catalog snapshot et perf baseline.
- **Rollback :** garder picker Scenario existant.
- **Impact suivant :** création et navigation map.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-10 — Outcome Event Source Catalog V0

- **Statut :** PASS — catalogue outcomes qualifiés validé le 2026-07-13.
- **Type :** core.
- **Objectif :** cataloguer outcomes Scene/Battle et Scenario legacy qualifiés ; Yarn est exposé par l'outcome Scene qui l'orchestre.
- **Problème traité :** sources non spatiales sans registre unifié.
- **Dépendances :** V2-01, contrats outcomes existants.
- **Packages concernés :** `map_core`.
- **Fichiers probables :** outcome catalog/read model/tests.
- **Contrats créés/modifiés :** `NarrativeOutcomeRef(producerKind, producerId, outcomeId)`, label, reachability status, adapter legacy unqualified.
- **Non-objectifs :** créer de nouveaux outcomes depuis Event Builder.
- **Risques :** provenance perdue lors d'une émission runtime legacy.
- **Compatibilité :** outcomes Scenario non qualifiés conservés sous provenance legacy explicite.
- **Tests ciblés :** Scene declared/emitted, battle public ref, Yarn normalisé par Scene, même ID cross-producer distinct, source legacy unqualified, missing producer, battle sans ref stable exclue.
- **Régressions :** Scene outcome diagnostics et projections.
- **Analyse/build :** map_core test/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** source outcome sélectionnable sans map active, sous réserve du snapshot projet requis pour vérifier toute référence map-backed ; provenance persistée ; mêmes IDs locaux restent distincts ; aucun `putIfAbsent` global silencieux.
- **Evidence Pack :** registry snapshot, collisions.
- **Rollback :** retirer catalogue sans donnée.
- **Impact suivant :** outcome authoring/runtime.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-11 — Unified Event Builder Project Read Model V0

- **Statut :** PASS — read model projet unifié validé le 2026-07-13.
- **Type :** core.
- **Objectif :** projeter V2 + legacy dans une liste projet déterministe.
- **Problème traité :** workspace map-local et double pipeline invisible.
- **Dépendances :** V2-06, V2-07, V2-09, V2-10.
- **Packages concernés :** `map_core`.
- **Fichiers probables :** nouveau V2 read model/tests.
- **Contrats créés/modifiés :** summaries, groups, status, source sentence, projections.
- **Non-objectifs :** mutations et widgets.
- **Risques :** faux statut prêt ou duplications.
- **Compatibilité :** origin V2/MapEvent/Scenario explicite mais technique cachée UI.
- **Tests ciblés :** grouping map/outcome/unconfigured, sorting, diagnostics dedup.
- **Régressions :** EventBuilderReadModel V1 et World Rule projections.
- **Analyse/build :** map_core test/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** vue globale, truthful status, stabilité snapshots.
- **Evidence Pack :** snapshot Selbrume synthétique.
- **Rollback :** conserver le read model V1 tant que `dualRead` est supporté.
- **Impact suivant :** UI V2.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-12 — Event Source Navigation & Diagnostic Destinations V0

- **Statut :** PASS — intents editor-neutral validés le 2026-07-13.
- **Type :** core.
- **Objectif :** calculer destinations éditeur et actions recommandées.
- **Problème traité :** `Voir sur la carte` non fonctionnel et diagnostics sans chemin.
- **Dépendances :** V2-09, V2-10, V2-11.
- **Packages concernés :** `map_core`, contrats editor-neutral.
- **Fichiers probables :** navigation intent/diagnostic destination/tests.
- **Contrats créés/modifiés :** `EditorDestination`, focus target, source geometry summary.
- **Non-objectifs :** exécuter la navigation Flutter.
- **Risques :** couplage map_core → UI.
- **Compatibilité :** intents purs, aucun type Widget.
- **Tests ciblés :** entity/trigger/map/outcome/missing/nonspatial.
- **Régressions :** source picker diagnostics.
- **Analyse/build :** map_core tests/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** chaque diagnostic connaît une destination ou explique son absence.
- **Evidence Pack :** matrice source/action/destination.
- **Rollback :** supprimer intents purs.
- **Impact suivant :** Map Editor integration et inspector.
- **Taille :** S.
- **Bloquant :** non.

## Risques

- lecture de toutes les maps trop lente ;
- labels incomplets ;
- outcomes non normalisés ;
- fuite de détails techniques.

## Gate de validation

`ACCEPTED` : snapshots déterministes, baseline performance établie, aucune
présentation prête sur référence invalide, compatibilité V1/runtime vérifiée et
aucune donnée utilisateur migrée.

## Livrable final

Catalogue source-first et read model projet consommables par l’éditeur.

---

# Phase E — Authoring Operations

```text
Mission status : READY
Gate d'entrée : ACCEPTED par Phase D le 2026-07-13
Jalons : V2-13 à V2-16
```

## Objectif

Fournir des opérations pures, no-code et réversibles pour créer/configurer un
Event V2 sans UI.

## Entry criteria

- Phase D validée.
- registry schema et plan de migration disponibles.
- stratégie révision/undo décidée.

## Exit criteria

- création de brouillon possible sans map ;
- source remplaçable sans perte ;
- conditions, Scene et behavior authorables ;
- single-write V2 persistant et undoable.

## Jalons internes

### NS-EVENT-V2-13 — Event Draft Creation Operations V0

- **Type :** core.
- **Objectif :** créer un Event brouillon avec ou sans source initiale.
- **Problème traité :** création V1 exige map, layer et position.
- **Dépendances :** V2-02, V2-03.
- **Packages concernés :** `map_core`.
- **Fichiers probables :** authoring operations/draft result/tests.
- **Contrats créés/modifiés :** opérations sur `NarrativeEventRecord.draft`, stable ID generator input, revision.
- **Non-objectifs :** widgets, source map creation.
- **Risques :** IDs non déterministes ou brouillons publiés.
- **Compatibilité :** aucun write legacy ; source/Scene null autorisées seulement dans la variante draft.
- **Tests ciblés :** create global/spatial/unconfigured, duplicate ID, immutable input.
- **Régressions :** Event Builder V1 draft tests.
- **Analyse/build :** map_core tests/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** brouillon sauvegardable mais absent de l'index et publication bloquée.
- **Evidence Pack :** before/after contracts.
- **Rollback :** retirer opérations sans donnée migrée.
- **Impact suivant :** V2-14 et UI création.
- **Taille :** S.
- **Bloquant :** oui.

### NS-EVENT-V2-14 — Event Source Select, Replace & Remove Operations V0

- **Type :** core.
- **Objectif :** choisir/changer/retirer une source en préservant le reste.
- **Problème traité :** source confondue avec position et Event identity.
- **Dépendances :** V2-09, V2-10, V2-13.
- **Packages concernés :** `map_core`.
- **Fichiers probables :** source authoring ops/tests.
- **Contrats créés/modifiés :** validation option, revision conflict, impact preview.
- **Non-objectifs :** supprimer ou renommer la source physique.
- **Risques :** retarget silencieux d’une référence cassée.
- **Compatibilité :** source manquante conservée jusqu’à choix explicite.
- **Tests ciblés :** replace each kind, remove, stale option, same source no-op, outcome provenance preserved.
- **Régressions :** narrative source authoring operations.
- **Analyse/build :** map_core tests/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** ID Event, conditions, Scene et `reusePolicy` inchangés ; detach explicite produit un draft sans source.
- **Evidence Pack :** property preservation matrix.
- **Rollback :** undo via previous immutable definition.
- **Impact suivant :** source-first UI.
- **Taille :** S.
- **Bloquant :** oui.

### NS-EVENT-V2-15 — Event Conditions, Scene & Behavior Authoring V0

- **Type :** core.
- **Objectif :** authorer le subset V0 et compiler un Event publiable.
- **Problème traité :** adapters V1 partiels et lifecycle metadata-only.
- **Dépendances :** V2-13, V2-14.
- **Packages concernés :** `map_core`.
- **Fichiers probables :** authoring ops, validator, tests.
- **Contrats créés/modifiés :** `NarrativeEventCondition.fact` et `.narrativeEventConsumed`, AND (vide=true, ordre stable), Scene ref, `NarrativeEventReusePolicy`, priority/order, publication draft→configured disabled.
- **Non-objectifs :** outcome/reaction/consequence authoring.
- **Risques :** promettre oneShot avant runtime.
- **Compatibilité :** legacy conditions opaques restent verrouillées via adapter.
- **Tests ciblés :** Fact true/false, Event consumed/not, Story Step/OR/raw flag refusés, AND/vide/ordre, set Scene, reusePolicy, conflit priority/order qui autorise publication disabled mais refuse activation, désactivation, invalid refs, immutable.
- **Régressions :** ScriptCondition et opérations Event Builder V1 restent inchangés.
- **Analyse/build :** map_core tests/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** aucun champ Scene-owned ; priorité explicable ; ordre/tie-break déterministes ; diagnostics truthful.
- **Evidence Pack :** authoring capability table.
- **Rollback :** conserver Event V2 précédent par undo/revision.
- **Impact suivant :** runtime et UI central.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-16 — Journaled Event Registry Single-Write & Undo V0

- **Type :** editor.
- **Objectif :** persister uniquement le registry/claims du manifest avec journal de récupération, révision et undo.
- **Problème traité :** mutations dupliquées, save direct et fausse promesse d'atomicité multi-fichiers.
- **Dépendances :** V2-08, V2-15.
- **Packages concernés :** `map_editor`, `map_core` repositories.
- **Fichiers probables :** repository/use case/notifier tests.
- **Contrats créés/modifiés :** save result, revision token, recovery journal `prepared/committed/recovered`, undo entry.
- **Non-objectifs :** UI V2 complète ou migration automatique.
- **Risques :** overwrite concurrent, journal stale et unknown JSON.
- **Compatibilité :** single-write registry V2 ; maps/Scenarios legacy inchangés ; claims les rendent read-only sans réécriture.
- **Tests ciblés :** stage/rename success, crash avant/après rename, recovery, stale revision, undo, unknown fields, claim persistence.
- **Régressions :** file repositories et editor notifier persistence.
- **Analyse/build :** editor tests/analyze, macOS debug.
- **Visual Gate :** non.
- **Critères d’acceptation :** remplacement unitaire du manifest crash-recoverable ; aucune map modifiée ; aucun état « committed » sans hash vérifié.
- **Evidence Pack :** journal, temp file/rename trace, hashes avant/après/recovery.
- **Rollback :** restauration précédente seulement si revision inchangée ; sinon migration compensatoire ou blocage, jamais overwrite d'authoring V2 ultérieur.
- **Impact suivant :** UI V2 peut écrire de façon sûre.
- **Taille :** M.
- **Bloquant :** oui.

## Risques

- faux brouillon publiable ;
- révision perdue ;
- write V1 accidentel ;
- ownership Scene violé.

## Gate de validation

Opérations pures, tests de préservation, repository journalé, récupération et
undo verts ; aucun widget encore requis.

## Livrable final

API d’authoring V2 complète, journalée et gardée par la validation du registry.

---

# Phase F1 — Runtime Authority & Progress

```text
Mission status : PLANNED
Jalons : V2-17 à V2-18
```

## Objectif

Créer l'autorité pure de dispatch, la progression V2 et les semantics de
lifecycle/persistance avant de brancher une source production.

## Entry criteria

- Phases B, C et E `CLOSED`.
- index structurel V2-04 disponible.
- conditions et authoring V2-15 stables.
- truth table mode/claims et ADR-EV2-013/014 inchangés.

## Exit criteria

- planner `handled/claimedButIneligible/noMatch` pur et déterministe ;
- claims et ordre multi-Events entièrement testés ;
- progression/outbox save round-trip ;
- oneShot/reusable et refus de save pendant Scene active prouvés ;
- aucun bridge source production encore requis.

## Jalons internes

### NS-EVENT-V2-17 — Unified Event Dispatch Authority & Eligibility Planner V0

- **Type :** runtime.
- **Objectif :** transformer une occurrence, le registry mode/claims, l'index et une vue de progression en décision unique sans effet.
- **Problème traité :** matching dispersé, fallback concurrent et first-manifest implicite.
- **Dépendances :** V2-03, V2-04, V2-15.
- **Packages concernés :** `map_gameplay`, `map_core`.
- **Fichiers probables :** dispatch planner/result/tests.
- **Contrats créés/modifiés :** `EventOccurrence`, `EventProgressView`, décision `handled/claimedButIneligible/noMatch`, rejection reasons, legacy authority.
- **Non-objectifs :** Flame, Scene execution, mutation GameState.
- **Risques :** claim ignoré ou fallback réactivé après oneShot consommé.
- **Compatibilité :** MapEvent/Scenario passent par cette autorité ; aucun hook ne choisit seul son fallback.
- **Tests ciblés :** trois modes, `ValidatedLegacyClaimIndex` globalConflict qui bloque dualRead, tombstone per-source `claimedButIneligible` sans bloquer les autres sources, claim valide avec target eligible/ineligible, target ineligible mais Event non-target de même source eligible, aucun candidat de source eligible, unclaimed noMatch, registry invalid qui n'atteint pas le planner, conditions AND, priority, inactive, draft, errors.
- **Régressions :** ScriptConditionEvaluator.
- **Analyse/build :** dart test/analyze core/gameplay.
- **Visual Gate :** non.
- **Critères d’acceptation :** décision pure/déterministe ; claim persistant bloque fallback même sans candidat ; aucun wildcard vide.
- **Evidence Pack :** truth table et perf p95.
- **Rollback :** mode registry `legacyOnly` avant toute donnée V2-only.
- **Impact suivant :** V2-18 à V2-22.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-18 — Event Progress Namespace, Lifecycle & Save/Load V0

- **Type :** runtime.
- **Objectif :** introduire la progression V2 globale, oneShot/reusable et les points de persistance avant les bridges production.
- **Problème traité :** IDs legacy nus, références dispersées et lifecycle metadata-only.
- **Dépendances :** V2-02, V2-03, V2-05, V2-08, V2-15.
- **Packages concernés :** `map_core`, `map_gameplay`, `map_runtime` persistence.
- **Fichiers probables :** GameState event V2 progress, codecs, mutations, reference adapters, tests.
- **Contrats créés/modifiés :** `NarrativeEventProgress`, namespace `consumedNarrativeEventIds`, delivery outbox avec correlation/depth/attempts, progress view, stable save busy gate.
- **Non-objectifs :** hooks source, reset calendar/weather ou fan-out.
- **Risques :** consommation prématurée, référence legacy oubliée et save pendant flow.
- **Compatibilité :** `consumedEventIds` reste legacy ; mappings qualifiés bloquent sur collisions ambiguës.
- **Tests ciblés :** success/fail/cancel, oneShot/reusable, save refusé pendant Scene active/dispatching, migration refs, new game, save/reload, pending/delivered, noMatch/ineligible terminaux, retry infrastructure x3, consumer failure terminal, profondeur 8/9.
- **Régressions :** GameState codec, Scene consequence markEventConsumed, World Rules et save persistence.
- **Analyse/build :** all touched package tests/analyze, runtime host smoke.
- **Visual Gate :** non.
- **Critères d’acceptation :** namespace séparé ; consume seulement après Scene success ; aucun faux checkpoint running ; outbox idempotente ; graphe de références couvert.
- **Evidence Pack :** lifecycle matrix, mapping references, save busy proof et outbox round-trip.
- **Rollback :** progression V2 ignorée seulement avant publication V2-only.
- **Impact suivant :** débloque les quatre bridges production.
- **Taille :** L.
- **Bloquant :** oui.

## Risques

- fallback réactivé malgré claim ;
- consommation prématurée ;
- save accepté pendant une Scene non checkpointable ;
- outbox outcome non idempotente ;
- référence legacy évaluée dans le namespace V2.

## Gate de validation

Truth table des trois modes, ordre multi-Events, lifecycle complet, codec de
progression et save/outbox entièrement verts. Rollback `legacyOnly` prouvé avant
la première donnée V2 non représentable en legacy.

## Livrable final

Autorité et progression V2 prêtes pour les bridges, sans hook production.

---

# Phase F2 — Runtime Source Bridges

```text
Mission status : PLANNED
Jalons : V2-19 à V2-22
```

## Objectif

Brancher `mapEnter`, `entityInteract`, `triggerEnter` et `outcomeReceived` sur
l'autorité F1, puis exécuter la Scene sans double dispatch legacy.

## Entry criteria

- Phase F1 `CLOSED`.
- catalogs D stables, dont outcomes qualifiées V2-10.
- source fingerprints/claims C valides.
- aucune source production ne contourne le coordinateur.

## Exit criteria

- quatre hooks production V2 ;
- raisons map activation et outbox outcome qualifiées ;
- aucune occurrence perdue ou doublée ;
- claim inéligible sans fallback ;
- traces de rollback legacy positives.

## Jalons internes

### NS-EVENT-V2-19 — Map Enter Production Dispatch Bridge V0

- **Type :** runtime.
- **Objectif :** émettre exactement une occurrence après activation map réussie.
- **Problème traité :** loadGame omet mapEnter et les semantics varient boot/warp/connection.
- **Dépendances :** V2-17, V2-18.
- **Packages concernés :** `map_runtime`.
- **Fichiers probables :** `playable_map_game.dart`, bridge tests/fixtures.
- **Contrats créés/modifiés :** raison d'activation map et occurrence unique.
- **Non-objectifs :** autres sources.
- **Risques :** double émission au boot/warp/load.
- **Compatibilité :** Scenario legacy arbitré par mode/claim ; un seul chemin gagne.
- **Tests ciblés :** boot, warp, connection, load, failure, same-map whiteout, claimed ineligible.
- **Régressions :** P3 mapEnter smoke.
- **Analyse/build :** runtime tests/analyze, host smoke.
- **Visual Gate :** non.
- **Critères d’acceptation :** une occurrence par activation terminée, autorité tracée, aucun fallback claimé.
- **Evidence Pack :** event trace par chemin.
- **Rollback :** mode `legacyOnly`.
- **Impact suivant :** Golden Slice map enter.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-20 — Entity Interaction Production Dispatch Bridge V0

- **Type :** runtime.
- **Objectif :** router l'interaction `MapEntity` via l'autorité unique avant fallback gameplay.
- **Problème traité :** bridge Scenario, MapEvent et dialogue fallback concurrents.
- **Dépendances :** V2-17, V2-18.
- **Packages concernés :** `map_gameplay`, `map_runtime`.
- **Fichiers probables :** gameplay interaction, playable game, tests.
- **Contrats créés/modifiés :** occurrence entity qualifiée et feedback de décision.
- **Non-objectifs :** `MapPlacedElement`, `MapEntity.spawn` et source raw tile.
- **Risques :** bloquer le fallback sur erreur silencieuse ou doubler item/sign behavior.
- **Compatibilité :** fallback legacy/dialogue uniquement sur `noMatch` non claimé.
- **Tests ciblés :** npc/sign/item/custom, spawn excluded, placed element excluded, claimed ineligible, noMatch, multiple Events, missing Scene.
- **Régressions :** NPC interaction readiness, placed-element gameplay et NS-EVENT-34.
- **Analyse/build :** gameplay/runtime tests/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** feedback joueur sur erreur, un seul lancement, matrice entity respectée.
- **Evidence Pack :** dispatch traces par kind.
- **Rollback :** mode `legacyOnly`.
- **Impact suivant :** Golden Lysa et objet.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-21 — Trigger Enter Production Dispatch Bridge V0

- **Type :** runtime.
- **Objectif :** router les fronts extérieur→intérieur des `MapTrigger` éligibles.
- **Problème traité :** `MapEventType.triggerZone` faux et entrées superposées perdues.
- **Dépendances :** V2-17, V2-18.
- **Packages concernés :** `map_runtime`, `map_gameplay` si l'occupation devient pure.
- **Fichiers probables :** trigger occupancy/queue, tests.
- **Contrats créés/modifiés :** trigger occurrence queue, kind eligibility et rearm-on-exit.
- **Non-objectifs :** MapGameplayZone, raw tile et trigger système non éligible.
- **Risques :** warp, overlap et dialogue busy.
- **Compatibilité :** legacy triggerZone reste adapter ; fallback seulement non claimé.
- **Tests ciblés :** event/custom, system kinds excluded, moved, warp, overlap, dialogue busy, spawn inside, exit/reenter.
- **Régressions :** P3 trigger bridge et NS-EVENT-35 negative gate.
- **Analyse/build :** runtime tests/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** aucune entrée perdue, kinds éligibles explicites, ordre déterministe, aucun fallback claimé.
- **Evidence Pack :** occupancy timelines et dispatch authority traces.
- **Rollback :** mode `legacyOnly`.
- **Impact suivant :** Golden Event B.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-22 — Qualified Outcome Received Dispatch & Reentrancy V0

- **Type :** runtime.
- **Objectif :** router chaque émission Scene/Battle qualifiée et chaque bridge Scenario legacy vers l'autorité V2 ; Yarn réémet par la Scene.
- **Problème traité :** outcome ID local, récursion Scenario et confusion flag durable/livraison.
- **Dépendances :** V2-10, V2-17, V2-18.
- **Packages concernés :** `map_runtime`, ponts Scene/Battle/Scenario, `map_core` occurrence.
- **Fichiers probables :** qualified outcome bus/adapter, correlation queue, tests.
- **Contrats créés/modifiés :** occurrence outcome qualifiée, correlation/depth, outbox pending/delivered obligatoire.
- **Non-objectifs :** producteur Yarn autonome, replay d'une delivery déjà delivered ou fan-out multi-Events.
- **Risques :** boucle outcome→Event→Scene→outcome et provenance perdue dans adapter legacy.
- **Compatibilité :** flag/outcome legacy conservé sous provenance `legacyScenario`; livraison V2 non rejouée.
- **Tests ciblés :** Scene/Battle mêmes IDs distincts, battle autonome après write-back, battle hébergée avec write-back seulement dans le state de travail puis commit parent, parent Scene fail qui abandonne state Battle et outcome global, ordre FIFO Battle puis Scene, Yarn normalisé par Scene, legacy unqualified, mismatch, recursion bound, duplicate emission, pending replay et delivered no replay après save/load.
- **Régressions :** P3 outcome continuation, Scene outcomes et battle handoff.
- **Analyse/build :** runtime/core tests/analyze, runtime host smoke.
- **Visual Gate :** non.
- **Critères d’acceptation :** une occurrence qualifiée par émission, boucle bornée, aucune collision cross-producer, aucun replay au load.
- **Evidence Pack :** correlation/provenance traces, outbox et save round-trip.
- **Rollback :** mode `legacyOnly` avant publication V2-only.
- **Impact suivant :** Golden Lysa branches.
- **Taille :** L.
- **Bloquant :** oui.

## Risques

- double dispatch ;
- occurrence perdue ;
- boucle outcome ;
- outbox perdue ou rejouée ;
- performance sans index.

## Gate de validation

Matrice quatre sources, raisons map activation, reentrance et outbox save/load
entièrement vertes ; aucun bridge legacy ne double le V2 et aucun claim ne
fallback.

## Livrable final

Quatre bridges production derrière l'autorité persistée `EventSystemMode`.

---

# Phase G — Map Editor Integration

```text
Mission status : PLANNED
Jalons : V2-23 à V2-25
```

## Objectif

Faire de la vraie source physique le point d’entrée spatial de l’Event.

## Entry criteria

- Phases D, E et F2 validées.
- navigation intents disponibles.
- source IDs immuables ou migration de rename définie.

## Exit criteria

- création depuis sélection ;
- focus/retour carte réel ;
- création explicite d’une source manquante sans Event abstrait.

## Jalons internes

### NS-EVENT-V2-23 — Map Selection to Event Creation Bridge V0

- **Type :** editor.
- **Objectif :** créer/lier un Event depuis MapEntity, MapTrigger ou map.
- **Problème traité :** clic de case abstrait et couche Événements obligatoire.
- **Dépendances :** V2-13, V2-14, V2-16.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** map inspector/context actions/notifier/tests.
- **Contrats créés/modifiés :** source-prefilled creation intent.
- **Non-objectifs :** UI Event Builder complète.
- **Risques :** double création et documents non sauvegardés.
- **Compatibilité :** action legacy séparée et marquée.
- **Tests ciblés :** entity, trigger, map, cancel, existing link, dirty document.
- **Régressions :** map selection and draft creation tests.
- **Analyse/build :** editor test/analyze/macos.
- **Visual Gate :** oui, context menu/inspector map.
- **Critères d’acceptation :** aucun layerId/coordonnée demandé.
- **Evidence Pack :** widget flow + capture.
- **Rollback :** masquer actions V2.
- **Impact suivant :** UX source-first complet.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-24 — See/Choose on Map Focus & Return Flow V0

- **Type :** editor.
- **Objectif :** ouvrir, sélectionner, centrer et revenir sans perdre le draft.
- **Problème traité :** callback actuel revient au workspace Events sans focus.
- **Dépendances :** V2-12, V2-23.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** editor state, map canvas focus command, navigation tests.
- **Contrats créés/modifiés :** map focus request, return token, highlight lifetime.
- **Non-objectifs :** mini-map ou nouveau canvas.
- **Risques :** perte de sélection et documents dirty.
- **Compatibilité :** sources non spatiales sans CTA carte.
- **Tests ciblés :** entity/trigger/map/missing/nonspatial, back/cancel.
- **Régressions :** workspace navigation and map camera tests.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** oui, bandeau sélection et highlight.
- **Critères d’acceptation :** vraie source centrée, retour exact au même Event.
- **Evidence Pack :** screenshots + state traces.
- **Rollback :** désactiver focus, garder picker liste.
- **Impact suivant :** inspector V2.
- **Taille :** M.
- **Bloquant :** non.

### NS-EVENT-V2-25 — Explicit Spatial Source Creation V0

- **Type :** editor.
- **Objectif :** créer une vraie entité/zone avant de lier un Event.
- **Problème traité :** panneau/tile/point invisible sans source stable.
- **Dépendances :** V2-23, V2-24.
- **Packages concernés :** `map_editor`, `map_core` ops existantes.
- **Fichiers probables :** source creation flow/tests.
- **Contrats créés/modifiés :** MapEntity custom/sign/item ou MapTrigger 1×1 proposal.
- **Non-objectifs :** raw tile source, warpAttempt V1.
- **Risques :** source orpheline si Event save échoue.
- **Compatibilité :** workflow journalé en deux commits : source map durable, puis Event registry ; échec du second affiche `Réessayer` / `Supprimer la source`.
- **Tests ciblés :** invisible interactable, enter point, cancel avant write, crash entre commits, retry, cleanup source inchangée.
- **Régressions :** entity/trigger creation and map save.
- **Analyse/build :** editor/core tests/analyze/macos.
- **Visual Gate :** oui.
- **Critères d’acceptation :** aucune EventPosition V2 créée.
- **Evidence Pack :** journal, before/after map + manifest hashes, recovery traces.
- **Rollback :** suppression proposée seulement si la source n'a pas changé et après confirmation ; aucun rollback multi-fichiers prétendument atomique.
- **Impact suivant :** couvre cas physiques sans modèle dédié.
- **Taille :** L.
- **Bloquant :** non.

## Risques

- crash entre commit map et commit manifest ;
- focus canvas incomplet ;
- source orpheline ;
- IDs éditables.

## Gate de validation

Flows réels Map Editor, annulation et récupération en deux étapes prouvés ;
aucun Event abstrait sur case.

## Livrable final

Pont bidirectionnel Map Editor ↔ Event Builder V2.

---

# Phase H — Event Builder V2 UI

```text
Mission status : PLANNED
Jalons : V2-26 à V2-30
North star : 1672 x 941, SHA-256 2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885
```

## Objectif

Livrer le workflow source-first dans la composition cinq panneaux de la north
star, sans authoring Scene-owned trompeur.

## Entry criteria

- Phases D, E et G validées.
- runtime V2 contrôlé par `EventSystemMode`.
- design system tokens disponibles.

## Exit criteria

- liste projet, bibliothèque, éditeur et inspecteur complets ;
- création sans mini-map ;
- états vides/erreur/read-only ;
- navigation carte fonctionnelle.

## Jalons internes

### NS-EVENT-V2-26 — V2 Shell, Project Event List & Filters V0

- **Type :** editor.
- **Objectif :** monter le shell cinq panneaux et la liste projet unifiée.
- **Problème traité :** liste limitée à la map active.
- **Dépendances :** V2-11, référence UI.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** V2 workspace/list widgets/tests.
- **Contrats créés/modifiés :** aucun core ; consumption read model V2.
- **Non-objectifs :** éditeur central complet.
- **Risques :** densité et performance des listes.
- **Compatibilité :** badge ancien format et filtre origine sans terme technique ; en `v2Only`, workspace V1 read-only et aucun CTA de création legacy.
- **Tests ciblés :** groups map/outcome/unconfigured, search, filters, selection, three registry modes, no legacy create in v2Only.
- **Régressions :** Narrative shell et workspace Event Builder V1 en mode `legacyOnly`.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** oui, 1672×941 liste.
- **Critères d’acceptation :** Events globaux visibles sans map active.
- **Evidence Pack :** widget tests, capture, perf list.
- **Rollback :** repasser workspace V1.
- **Impact suivant :** base V2-27 à V2-30.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-27 — Source-First Event Creation UX V0

- **Type :** editor.
- **Objectif :** implémenter Nom → type → map → source → Scene → `reusePolicy`.
- **Problème traité :** position/layer obligatoires.
- **Dépendances :** V2-13, V2-14, V2-16, V2-26.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** creation panel/dialog/step tests.
- **Contrats créés/modifiés :** aucun core.
- **Non-objectifs :** drag/drop ou création source inline complexe.
- **Risques :** wizard long et état brouillon perdu.
- **Compatibilité :** `Décider plus tard` crée un brouillon non publiable.
- **Tests ciblés :** quatre kinds avec matrice picker, source missing/deleted, publier vers configured disabled, activer/désactiver, conflit existant qui bloque seulement activation, cancel/resume, save/close/reopen.
- **Régressions :** placement NS-EVENT-36/38 dans le workspace V1 `legacyOnly`.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** oui, empty/create/error.
- **Critères d’acceptation :** aucun mini-damier ; source réelle obligatoire pour publier ; référence typée identique après réouverture ; conflit multi-Events expliqué avant validation.
- **Evidence Pack :** flow screenshots and state matrix.
- **Rollback :** disable V2 creation, preserve drafts read-only.
- **Impact suivant :** central trigger/inspector.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-28 — Trigger Block & Source Inspector V0

- **Type :** editor.
- **Objectif :** afficher/modifier `Comment cela commence`, l'élément choisi et le lieu depuis la vraie source.
- **Problème traité :** faux acteur/objet/zone dérivé de MapEventType.
- **Dépendances :** V2-12, V2-14, V2-24, V2-27.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** central trigger block/inspector/tests.
- **Contrats créés/modifiés :** aucun core.
- **Non-objectifs :** raw IDs, coordinates, metadata.
- **Risques :** source stale et CTA carte invalide.
- **Compatibilité :** résumé ancien format read-only avec action `Voir le diagnostic de conversion`; aucune mutation avant V2-33.
- **Tests ciblés :** source non choisie persistée avec publication bloquée et aucun CTA map ; entity/trigger/map/outcome ; source cassée distincte ; change, see map, diagnostic conversion sans write.
- **Régressions :** Event Builder inspector tests.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** oui.
- **Critères d’acceptation :** phrase humaine cohérente centre/inspecteur.
- **Evidence Pack :** source matrix captures.
- **Rollback :** revenir au V2 read-only summary.
- **Impact suivant :** V2-29.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-29 — Conditions, Scene, Behavior & Read-Only Projections UI V0

- **Type :** editor.
- **Objectif :** authorer l’Event et projeter honnêtement la Scene.
- **Problème traité :** cockpit trompeur ou simplification sans détails.
- **Dépendances :** V2-15, V2-22, V2-28.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** central flow/library/projection widgets/tests.
- **Contrats créés/modifiés :** aucun core.
- **Non-objectifs :** authoring outcomes/reactions/consequences/World Rules.
- **Risques :** copier les contrôles décoratifs de la north star.
- **Compatibilité :** legacy conditions locked, scripts/messages warning.
- **Tests ciblés :** add/remove condition, choose/create/open Scene, lifecycle, catégories `Configurer l'événement` / `Dans la Scene liée`, absence grips/drop, read-only guards.
- **Régressions :** NS-EVENT-41-bis truthfulness and Scene projections.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** oui, full flow.
- **Critères d’acceptation :** Event≠Scene visible ; oneShot runtime-backed ; aucune ligne Scene-owned ne paraît ajoutable ; aucun drop target sans drag/drop fonctionnel.
- **Evidence Pack :** ownership assertion pack.
- **Rollback :** workspace V1 conservé en `legacyOnly` tant que `dualRead` est supporté.
- **Impact suivant :** V2-30 and visual closure.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-30 — V2 Empty, Missing, Conflict & Accessibility States

- **Type :** editor.
- **Objectif :** fermer les états secondaires et l’accessibilité.
- **Problème traité :** références cassées, conflits et états vides non actionnables.
- **Dépendances :** V2-26 à V2-29.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** state widgets/tests/goldens.
- **Contrats créés/modifiés :** aucun core.
- **Non-objectifs :** nouveau design system global.
- **Risques :** état couleur-only ou texte technique.
- **Compatibilité :** legacy/missing distincts.
- **Tests ciblés :** empty/filter empty/unselected/missing/stale revision/error/warning/info, multi-Events source conflict, premier candidat selon snapshot, candidat suivant quand le premier est inéligible, priority action, keyboard.
- **Régressions :** shell and navigation tests.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** oui, matrice états.
- **Critères d’acceptation :** text+icon+semantics, aucune fuite technique, conflit source résolvable sans exposer `order` ou tie-break ID.
- **Evidence Pack :** accessibility report and screenshots.
- **Rollback :** conserver états fonctionnels minimaux de V2-29.
- **Impact suivant :** validator and pixel closure.
- **Taille :** M.
- **Bloquant :** non.

## Risques

- retour prématuré au cockpit ;
- bibliothèque mensongère ;
- régression densité ;
- focus et scroll incohérents.

## Gate de validation

Workflows widget complets, anti-authoring guards, Visual Gates de tous les états,
aucun overflow aux dimensions desktop supportées.

## Livrable final

Event Builder V2 fonctionnel sous l'autorité `EventSystemMode`, avant validation/polish final.

---

# Phase I — Validator & Diagnostics

```text
Mission status : PLANNED
Jalons : V2-31 à V2-33
```

## Objectif

Diagnostiquer source, références, lifecycle, conflits, migration et atteignabilité
avec des codes stables et des destinations éditeur.

## Entry criteria

- Phase H fonctionnelle.
- diagnostic contract de RESET-00 accepté.
- index projet et source catalogs disponibles.

## Exit criteria

- erreurs bloquantes exhaustives ;
- warnings allowlistables ;
- navigation vers correction ;
- validation incrémentale budgétée.

## Jalons internes

### NS-EVENT-V2-31 — Source & Reference Integrity Validator V0

- **Type :** validation.
- **Objectif :** couvrir records, IDs, mode/claims, source, map, entity, trigger, outcome qualifié et Scene.
- **Problème traité :** validateurs asymétriques et références cassées tardives.
- **Dépendances :** V2-03, V2-09, V2-10, V2-12.
- **Packages concernés :** `map_core`.
- **Fichiers probables :** Event V2 validator/diagnostic registry/tests.
- **Contrats créés/modifiés :** codes `EV2-ID`, `EV2-RECORD`, `EV2-SOURCE`, `EV2-CLAIM`, `EV2-SCENE`.
- **Non-objectifs :** reachability globale et migration.
- **Risques :** diagnostics dupliqués ou paths instables.
- **Compatibilité :** diagnostics legacy info/warning, jamais crash decode.
- **Tests ciblés :** draft non publiable, claim conflict/missing, entity/trigger kind eligibility, placed element excluded, outcome producer missing, chaque severity, dedup, sort, destination.
- **Régressions :** narrative validator and Scene diagnostics.
- **Analyse/build :** map_core test/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** code/path/ref/action/destination pour chaque cas.
- **Evidence Pack :** diagnostic registry snapshot.
- **Rollback :** garder validators V1 en parallèle.
- **Impact suivant :** V2-32/V2-33 et release gates.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-32 — Event Reachability, Conflict & Runtime Support Validator

- **Type :** validation.
- **Objectif :** détecter conflits, source inactive, outcome qualifié jamais émis et Event inatteignable.
- **Problème traité :** premier match implicite et sources runtime partielles.
- **Dépendances :** V2-04, V2-17, V2-31.
- **Packages concernés :** `map_core`, éventuellement `map_gameplay` tests.
- **Fichiers probables :** reachability graph, conflict validator, tests.
- **Contrats créés/modifiés :** conflict/reachability diagnostics.
- **Non-objectifs :** exécuter la Scene.
- **Risques :** faux positifs sur conditions dynamiques.
- **Compatibilité :** unknown = warning explicite, pas erreur arbitraire.
- **Tests ciblés :** competing events, hidden entity, ineligible trigger kind, unproduced producer-qualified outcome, claimed fallback blocked.
- **Régressions :** narrative validator reachability.
- **Analyse/build :** tests/analyze packages touchés.
- **Visual Gate :** non.
- **Critères d’acceptation :** conflits déterministes et explication utilisateur.
- **Evidence Pack :** graph traces.
- **Rollback :** désactiver diagnostics avancés.
- **Impact suivant :** Golden Slice readiness.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-33 — Migration UX, Editor Destination & Incremental Validation Gate

- **Type :** validation.
- **Objectif :** unir diagnostics migration/authoring/runtime, livrer la preview de conversion et mesurer l’incrémental.
- **Problème traité :** erreurs sans action, migration opaque et validation globale coûteuse.
- **Dépendances :** V2-08, V2-12, V2-16, V2-30, V2-31, V2-32.
- **Packages concernés :** `map_core`, `map_editor` integration.
- **Fichiers probables :** validation coordinator, migration preview/confirmation UI, destination bridge, tests.
- **Contrats créés/modifiés :** blocking scopes, allowlist, incremental cache ; aucun core migration nouveau.
- **Non-objectifs :** migration silencieuse, conversion sans preview, nouveau format de backup.
- **Risques :** cache stale, navigation incorrecte et confirmation ambiguë.
- **Compatibilité :** full validation fallback.
- **Tests ciblés :** invalidation, stale cache, click diagnostic, preview diff, confirmation via repository V2-16, cancel sans write, backup failure, crash recovery, rollback revision unchanged/changed, migration blocked.
- **Régressions :** project validator and editor diagnostics.
- **Analyse/build :** core/editor tests/analyze/macos.
- **Visual Gate :** oui, diagnostics inspector/list et preview de conversion.
- **Critères d’acceptation :** destination exacte ; preview compréhensible ; confirmation explicite ; journal/recovery et rollback revision-gated prouvés ; performance mesurée sans seuil inventé.
- **Evidence Pack :** p50/p95 observés, click-through tests, captures preview, hashes avant/après/rollback.
- **Rollback :** disable cache, keep full validator et conserver l'ancien format inchangé.
- **Impact suivant :** Golden and final gates.
- **Taille :** M.
- **Bloquant :** oui.

## Risques

- faux positif ;
- code diagnostic recyclé ;
- cache stale ;
- warning noyé.

## Gate de validation

Registry stable, matrice diagnostics exhaustive, navigation actionnable, budget
performance archivé.

## Livrable final

Validator Event V2 central prêt pour Selbrume.

---

# Phase J — Selbrume Golden Slice

```text
Mission status : PLANNED
Jalons : V2-34 à V2-37
```

## Objectif

Prouver authoring, disque, reload, runtime, Scene, lifecycle, diagnostics et
navigation sur trois vraies sources, puis sur le flux Lysa complet.

## Entry criteria

- Phases F à I validées.
- copie de travail Selbrume hashée.
- références Lysa, zone_port_entry et clue_glass_object disponibles/créables.

## Exit criteria

- Events A/B/C authorés depuis UI ;
- persistence/reload sans perte ;
- runtime source-first ;
- Golden Lysa end-to-end et save/load verts.

## Jalons internes

### NS-EVENT-V2-34 — Selbrume Three-Source Authoring Slice

- **Type :** editor.
- **Objectif :** authorer PNJ, zone et objet depuis l’UI V2.
- **Problème traité :** aucune preuve de contenu réel source-first.
- **Dépendances :** V2-23, V2-27 à V2-30, V2-31.
- **Packages concernés :** `map_editor`, fixtures Selbrume en copie contrôlée.
- **Fichiers probables :** tests integration/fixtures, pas le projet final au départ.
- **Contrats créés/modifiés :** aucun nouveau.
- **Non-objectifs :** flow Lysa complet ou pixel closure.
- **Risques :** fixtures divergent du projet.
- **Compatibilité :** aucun legacy supprimé.
- **Tests ciblés :** Event A `npc_lysa`, B `zone_port_entry`, C `clue_glass_object`.
- **Régressions :** UI creation and Map bridge.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** oui, trois sélections.
- **Critères d’acceptation :** source réelle, aucun EventPosition.
- **Evidence Pack :** UI traces and JSON diff.
- **Rollback :** supprimer copie fixture V2.
- **Impact suivant :** V2-35/V2-36.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-35 — Selbrume Persistence, Reload & Migration Proof

- **Type :** migration.
- **Objectif :** prouver disque/reload/recovery et rollback revision-gated des trois Events.
- **Problème traité :** commit registry/claims et legacy corpus non prouvés.
- **Dépendances :** V2-08, V2-16, V2-34.
- **Packages concernés :** `map_core`, `map_editor` tests.
- **Fichiers probables :** integration fixtures/tests/report.
- **Contrats créés/modifiés :** migration receipt utilisé.
- **Non-objectifs :** runtime complet.
- **Risques :** fixture mutée en place.
- **Compatibilité :** maps/Scenarios originaux inchangés ; backup manifest hashé.
- **Tests ciblés :** save/reload, idempotence, import legacy, crash recovery, rollback avant edit, rollback bloqué après edit.
- **Régressions :** repository and codec tests.
- **Analyse/build :** core/editor tests/analyze.
- **Visual Gate :** non.
- **Critères d’acceptation :** zéro perte, relecture sémantique identique et claims toujours autoritaires après reload.
- **Evidence Pack :** hashes/diffs/receipt/journal.
- **Rollback :** restaurer le manifest fixture seulement si revision inchangée.
- **Impact suivant :** V2-36/V2-37.
- **Taille :** M.
- **Bloquant :** oui.

### NS-EVENT-V2-36 — Selbrume Three-Source Runtime Proof

- **Type :** runtime.
- **Objectif :** déclencher A/B/C via vrais hooks production.
- **Problème traité :** P3 injecte des occurrences sans prouver tous les hooks.
- **Dépendances :** V2-18 à V2-22, V2-35.
- **Packages concernés :** `map_runtime`, host smoke.
- **Fichiers probables :** integration tests/fixtures/reports.
- **Contrats créés/modifiés :** aucun nouveau.
- **Non-objectifs :** toute la storyline Lysa.
- **Risques :** flakiness Flame et ordre sources.
- **Compatibilité :** vérifier absence double dispatch legacy.
- **Tests ciblés :** interact, enter zone, object interact, oneShot/reusable, save/reload.
- **Régressions :** P3/P6 runtime tests.
- **Analyse/build :** runtime tests/analyze, host smoke/macos.
- **Visual Gate :** capture runtime ciblée si UI visible.
- **Critères d’acceptation :** chaque Event lance la bonne Scene une fois selon policy.
- **Evidence Pack :** runtime logs and state snapshots.
- **Rollback :** recovery receipt et mode `legacyOnly` seulement avant le point de non-retour.
- **Impact suivant :** V2-37.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-37 — Lysa End-to-End Golden Narrative Slice

- **Type :** validation.
- **Objectif :** prouver Event→Scene→Yarn→Cinematic→Battle→Outcome→Fact→Step→Rule.
- **Problème traité :** aucune preuve transversale complète.
- **Dépendances :** V2-34 à V2-36, systems Scene/Yarn/Cinematic/Battle.
- **Packages concernés :** tous packages concernés par le slice et host.
- **Fichiers probables :** Selbrume golden fixture/tests/report.
- **Contrats créés/modifiés :** aucun Event-owned outcome.
- **Non-objectifs :** toute l’histoire Selbrume.
- **Risques :** dépendances externes et fixture trop large.
- **Compatibilité :** legacy project ouvre toujours avant opt-in migration.
- **Tests ciblés :** conditions, branches ton, victory/defeat, oneShot, reinteraction, save/reload.
- **Régressions :** existing P6 Selbrume beta/interaction/save tests.
- **Analyse/build :** suites ciblées tous packages, analyzes, host build.
- **Visual Gate :** oui, authoring + runtime + validator.
- **Critères d’acceptation :** zéro erreur, warnings allowlistés, outcome/Fact/Step/Rule prouvés.
- **Evidence Pack :** full trace, screenshots, save snapshots.
- **Rollback :** restaurer fixture et désactiver V2.
- **Impact suivant :** autorise Phase K/L.
- **Taille :** L.
- **Bloquant :** oui.

## Risques

- fixture non représentative ;
- test trop monolithique ;
- état persistent pollué ;
- faux PASS visuel sans runtime.

## Gate de validation

Golden Slice Lysa complet, trois sources réelles, reinteraction et save/reload.

## Livrable final

Preuve Selbrume source-first end-to-end.

---

# Phase K — Pixel-Perfect Visual Closure

```text
Mission status : PLANNED
Jalons : V2-38 à V2-40
North star : 1672 x 941, référence hashée de Phase A
```

## Objectif

Atteindre la composition, densité et hiérarchie de la north star 1672 × 941
après stabilisation fonctionnelle.

## Entry criteria

- Phase J validée.
- données de capture figées.
- tokens design system disponibles.

## Exit criteria

- overlay et côte-à-côte approuvés ;
- états secondaires couverts ;
- desktop responsive sans overflow ;
- écarts métier documentés.

## Jalons internes

### NS-EVENT-V2-38 — Reference Grid & Five-Panel Pixel Alignment

- **Type :** visual.
- **Objectif :** aligner shell, colonnes, gaps, paddings et typographie à 1672×941.
- **Problème traité :** écart structurel avec la north star définitive.
- **Dépendances :** V2-26 à V2-30, V2-37.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** workspace widgets/tests/goldens/report.
- **Contrats créés/modifiés :** aucun métier.
- **Non-objectifs :** nouvelles capacités ou refonte EditorChrome globale non nécessaire.
- **Risques :** hardcodes et casse sous le seuil cinq panneaux de 1480 px.
- **Compatibilité :** design tokens seuls.
- **Tests ciblés :** dimensions, columns, no overflow, glyphs.
- **Régressions :** Event Builder and Narrative shell.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** obligatoire référence/capture/overlay/côte-à-côte.
- **Critères d’acceptation :** tolérances de la spec visuelle.
- **Evidence Pack :** matrix zone by zone.
- **Rollback :** revert styles du lot uniquement.
- **Impact suivant :** V2-39/V2-40.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-39 — Editor Flow, Connectors & Inspector Fidelity

- **Type :** visual.
- **Objectif :** polir cartes métier, rails, branches, library et inspector.
- **Problème traité :** détails visuels encore loin de la référence.
- **Dépendances :** V2-38.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** flow/library/inspector widgets/tests/goldens.
- **Contrats créés/modifiés :** aucun métier.
- **Non-objectifs :** rendre authorables les projections Scene.
- **Risques :** connecteurs fragiles sur contenu dynamique.
- **Compatibilité :** source-first labels et read-only badges conservés.
- **Tests ciblés :** dynamic heights, long labels, branches 0/1/2/3+, hover/focus, absence de grip/drop sans moteur fonctionnel.
- **Régressions :** ownership/forbidden authoring tests.
- **Analyse/build :** editor tests/analyze/macos.
- **Visual Gate :** obligatoire.
- **Critères d’acceptation :** flow reconnaissable et interactif sans mensonge.
- **Evidence Pack :** overlays focused regions.
- **Rollback :** fallback connectors simples.
- **Impact suivant :** V2-40.
- **Taille :** M.
- **Bloquant :** non.

### NS-EVENT-V2-40 — Desktop Responsive & Visual State Closure

- **Type :** visual.
- **Objectif :** fermer 1280/1440/1480/1672/wide, text scale et tous états.
- **Problème traité :** pixel match unique sans robustesse réelle.
- **Dépendances :** V2-39.
- **Packages concernés :** `map_editor`.
- **Fichiers probables :** responsive layout/tests/goldens/report.
- **Contrats créés/modifiés :** aucun métier.
- **Non-objectifs :** mobile/tablet.
- **Risques :** panneaux cachés sans contrôle.
- **Compatibilité :** bibliothèque en side sheet modale explicite sous 1480, avec fond inerte, focus trap, focus retour et `Escape`.
- **Tests ciblés :** empty/error/legacy/long IDs/dense lists/text scale/keyboard, budget largeur, scroll/catégorie conservés, Tab/Shift+Tab contenus, fond inerte, Escape et focus restauré.
- **Régressions :** all Event Builder widget groups.
- **Analyse/build :** full editor tests/analyze/macos.
- **Visual Gate :** obligatoire multi-viewport.
- **Critères d’acceptation :** aucun overflow et accès à chaque zone.
- **Evidence Pack :** viewport matrix and accessibility audit.
- **Rollback :** revenir au dernier layout style-only prouvé sans toucher aux contrats.
- **Impact suivant :** readiness final.
- **Taille :** M.
- **Bloquant :** oui.

## Risques

- optimisation du raster au détriment du produit ;
- hardcodes ;
- interactions non testées ;
- accessibilité sacrifiée.

## Gate de validation

Overlay 50 %, côte-à-côte, matrice zones, multi-viewport, accessibility et
justification de chaque écart majeur.

## Livrable final

Event Builder V2 visuellement clos et robuste sur desktop.

---

# Phase L — Final Readiness Gate

```text
Mission status : PLANNED
Jalons : V2-41 à V2-43
```

## Objectif

Prouver compatibilité, performance, rollback et readiness release sans feature
flag obligatoire.

## Entry criteria

- Phases B à K validées.
- corpus legacy et Selbrume stables.
- aucun blocker ouvert.

## Exit criteria

- performance dans budgets ;
- migration/rollback exercés ;
- suites et builds verts ;
- décision release explicite.

## Jalons internes

### NS-EVENT-V2-41 — Legacy Corpus, Migration & Performance Readiness Gate

- **Type :** validation.
- **Objectif :** exécuter corpus V1/V2, migration et budgets.
- **Problème traité :** preuves locales sans garantie projet réel.
- **Dépendances :** V2-08, V2-33, V2-37, V2-40.
- **Packages concernés :** core/editor/runtime test surfaces.
- **Fichiers probables :** readiness tests/report, aucun modèle nouveau.
- **Contrats créés/modifiés :** aucun.
- **Non-objectifs :** correction opportuniste hors blockers.
- **Risques :** baseline non reproductible.
- **Compatibilité :** ouverture V1 sans write ; rollback seulement revision inchangée ; migration compensatoire sinon.
- **Tests ciblés :** corpus all fixtures, perf p50/p95, claims authority, no fallback after consumed, migration/recovery/rollback.
- **Régressions :** all Event V1/V2 targeted suites.
- **Analyse/build :** all affected package analyzes/builds.
- **Visual Gate :** captures état legacy/migration.
- **Critères d’acceptation :** budgets et zéro perte.
- **Evidence Pack :** hashes, metrics, allowlist warnings.
- **Rollback :** release blocked ; backup restauré seulement sous précondition de révision.
- **Impact suivant :** V2-42.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-42 — Full Package Regression & Release Candidate Gate

- **Type :** validation.
- **Objectif :** lancer tests/analyzes/builds complets et candidate release.
- **Problème traité :** risques transversaux non couverts par tests ciblés.
- **Dépendances :** V2-41.
- **Packages concernés :** `map_core`, `map_gameplay`, `map_runtime`, `map_editor`, host.
- **Fichiers probables :** rapport uniquement sauf blockers séparés.
- **Contrats créés/modifiés :** aucun.
- **Non-objectifs :** corriger plusieurs domaines dans ce gate.
- **Risques :** suite longue ou flaky.
- **Compatibilité :** V1 and V2 fixtures in same run.
- **Tests ciblés :** toutes suites package + host smoke.
- **Régressions :** intégralité repo pertinente.
- **Analyse/build :** tous analyses, macOS debug, host build.
- **Visual Gate :** re-run baselines V2.
- **Critères d’acceptation :** zéro failure, zéro diff généré inattendu.
- **Evidence Pack :** commands exactes and outputs.
- **Rollback :** no release ; mode courant et readers legacy conservés.
- **Impact suivant :** V2-43.
- **Taille :** L.
- **Bloquant :** oui.

### NS-EVENT-V2-43 — Event Builder V2 Final Go/No-Go & V1 Deprecation Gate

- **Type :** validation.
- **Objectif :** décider activation par défaut, mode `v2Only` et calendrier V1.
- **Problème traité :** coexistence indéfinie de deux pipelines.
- **Dépendances :** V2-42.
- **Packages concernés :** documentaire ; mode/config si GO dans un jalon séparé ou très borné.
- **Fichiers probables :** final readiness report/deprecation notice.
- **Contrats créés/modifiés :** décision de support, pas de modèle.
- **Non-objectifs :** suppression immédiate des lecteurs/importeurs legacy.
- **Risques :** GO avec rollback non prouvé ou données V2-only non downgradeables.
- **Compatibilité :** lecteur/importeur legacy conservé ; authoring source Scenario/MapEvent et dispatch legacy désactivés pour tout projet passé en `v2Only`.
- **Tests ciblés :** reprise Evidence Packs, mode v2Only no fallback, aucun write legacy depuis les entrypoints editor, projet legacyOnly toujours lisible.
- **Régressions :** aucune commande nouvelle si V2-42 frais.
- **Analyse/build :** référencer V2-42 ; relancer si diff.
- **Visual Gate :** référence finale.
- **Critères d’acceptation :** décision explicite, blockers zéro, mode/claims prouvés, aucun nouvel authoring legacy en V2, rollback documenté sans promesse après point de non-retour.
- **Evidence Pack :** index de toutes preuves.
- **Rollback :** V2 non activé ou restauration par receipt si aucune donnée V2-only non représentable n'a été publiée.
- **Impact suivant :** lots de dépréciation V1 futurs.
- **Taille :** M.
- **Bloquant :** oui.

## Risques

- dette de dual-read ;
- rollback impossible après publication V2-only ;
- suite flaky ;
- décision release politique non prise.

## Gate de validation

Go/No-Go signé avec Evidence Pack complet, `EventSystemMode` et fenêtre de support.

## Livrable final

Event Builder V2 prêt ou explicitement refusé avec blockers nommés.

---

# Chemins critiques

## Trajectoire minimale Golden Slice

```text
RESET-00
→ V2-01 → V2-02 → V2-03 → V2-04
→ V2-05 → V2-06 → V2-07 → V2-08
→ V2-09 → V2-10 → V2-11 → V2-12
→ V2-13 → V2-14 → V2-15 → V2-16
→ V2-17 → V2-18 → V2-19 → V2-20 → V2-21 → V2-22
→ V2-23 → V2-24 → V2-25
→ V2-26 → V2-27 → V2-28 → V2-29 → V2-30
→ V2-31 → V2-32 → V2-33
→ V2-34 → V2-35 → V2-36 → V2-37
```

V2-25 prouve la capacité de matérialisation explicite même si les trois sources
Golden existent déjà ; le jalon ne peut pas être omis silencieusement. V2-33
ferme la migration UX avant contenu réel. Cette trajectoire ne supprime aucun
legacy et reporte le pixel polish ; elle ne peut pas être release finale.

## Trajectoire complète Event Builder V2

```text
Phase A → B → C
B + C → D
C + D → E
B + C + E → F1
D + F1 → F2
D + E + F2 → G
D + E + F2 + G → H
F1 + H → I
F2 + G + H + I → J
J → K
B..K → L
```

## Jalons internes parallélisables

- V2-09 spatial et V2-10 outcome après V2-01/03 ;
- V2-18 progression peut avancer avec V2-17 après contrats/mappings ;
- V2-19, 20, 21 et 22 après V2-17 + V2-18 ;
- V2-31 et premiers travaux V2-26 après read model stable ;
- Visual QA tooling peut être préparé avant Phase K, sans modifier l’UI.

## Points de non-retour

1. première progression ou référence V2 persistée qui ne peut pas être
   représentée exactement en legacy ;
2. résolution manuelle irréversible d'une collision `consumedEventIds` ;
3. passage d'un projet réel en `v2Only` ;
4. désactivation du dispatch Scenario/MapEvent legacy ;
5. suppression d’un lecteur/importer legacy.

La première écriture d'un registry vide ou d'un draft reste réversible tant que
le backup, les revisions et le receipt sont inchangés.

## Décisions ratifiées et règle de contestation

Les décisions utilisateur A-01 à A-20 sont ratifiées dans
`MVP Selbrume/event_builder_v2_architecture_decisions.md`. Une mission future ne
les confirme pas de nouveau. Elle les applique ou s'arrête avec un Blocker
Report et demande un ADR de remplacement.

# Synthèse des missions et jalons

| Mission | Jalons | Nombre | Gate principal |
|---|---|---:|---|
| A `CLOSED` | RESET-00 | 1 | 20 ADRs + Entry Gate B |
| B `CLOSED` | V2-01 à V2-04 | 4 | contrats/JSON/index |
| C `CLOSED` | V2-05 à V2-08 | 4 | adapters/plan/claims |
| D `CLOSED` | V2-09 à V2-12 | 4 | catalogs/read models |
| E `READY` | V2-13 à V2-16 | 4 | authoring/single-write |
| F1 | V2-17 à V2-18 | 2 | autorité/progression/outbox |
| F2 | V2-19 à V2-22 | 4 | quatre source bridges |
| G | V2-23 à V2-25 | 3 | Map Editor bridge |
| H | V2-26 à V2-30 | 5 | UI V2 |
| I | V2-31 à V2-33 | 3 | validator |
| J | V2-34 à V2-37 | 4 | Golden Selbrume |
| K | V2-38 à V2-40 | 3 | pixel closure |
| L | V2-41 à V2-43 | 3 | readiness |
| **Total** | **RESET-00 + V2-01…43** | **44** | **Go/No-Go** |

# Prochaine mission exécutable

```text
PHASE E — Authoring Operations
Jalons internes : V2-13 à V2-16
Gate d'entrée : ACCEPTED par Phase D
```

Phase E doit exécuter ses quatre jalons dans une seule mission avec tests
cumulés, reviews locales, Evidence Pack et rapport de phase. Elle doit conserver
les catalogues et intentions Phase D comme contrats immuables et ne doit encore
ajouter ni runtime V2, ni migration réelle de projet, ni UI Flutter.
