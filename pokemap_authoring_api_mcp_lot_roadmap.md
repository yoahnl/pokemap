# PokeMap Authoring API & MCP Lot Roadmap

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `subagent-driven-development` (recommended) or `executing-plans` to implement
> an approved lot task-by-task. Each lot requires its own detailed
> implementation plan before code changes.

**Goal:** Deliver a canonical, safe and testable PokeMap Authoring API, migrate
the editor onto it, then expose it through a thin MCP server without duplicating
PokeMap rules.

**Architecture:** A new pure-Dart `map_authoring` package sits above the existing
pure domain packages and below `map_editor`, the CLI, runtime adapters and MCP.
Every mutation follows `plan → preview → validate → apply → receipt`, with
explicit revisions, durable idempotence and honest recovery guarantees. The MCP
is implemented last as a transport adapter over the same public contracts.

**Tech Stack:** Dart 3, Flutter where existing editor/runtime adapters require
it, `map_core`, `map_gameplay`, `map_battle`, `map_distribution`, JSON Schema,
JSONL for the CLI worker boundary, Flutter Test, Dart Test, and an official MCP
SDK selected by a dedicated compatibility gate.

---

## 1. Nature de ce document

Le catalogue approuvé est :

```text
pokemap_authoring_api_mcp_action_catalog.md
```

Ce document le découpe en lots indépendants et ordonnés. Il s’agit d’une
roadmap maîtresse, pas d’un plan de codage monolithique. Avant chaque lot, un
plan d’implémentation dédié devra fournir :

- les signatures exactes ;
- les changements fichier par fichier ;
- les tests rouges puis verts ;
- les commandes précises ;
- les résultats attendus ;
- les étapes de migration ;
- les limites explicitement conservées.

Cette décomposition évite un plan unique de plusieurs milliers d’étapes qui
serait impossible à relire, réviser ou exécuter de manière sûre.

## 2. Décisions figées

1. Le MCP ne contient aucune règle métier PokeMap.
2. `map_authoring` est un package Dart pur, sans Flutter ni Flame.
3. `map_authoring` peut dépendre de `map_core`, `map_gameplay`, `map_battle` et
   `map_distribution`; aucun de ces packages ne dépend de `map_authoring`.
4. `map_editor` consomme progressivement `map_authoring`.
5. Le runtime reste propriétaire du rendu et du playtest de production via des
   ports implémentés hors de `map_authoring`.
6. Les IDs, revisions, plans, jobs, artefacts et curseurs sont opaques.
7. Aucune écriture arbitraire de fichier ou patch JSON brut n’est une commande
   publique normale.
8. Une mutation n’est pas exposée au MCP avant de disposer de dry-run, diff,
   validation, idempotence, permissions et receipt.
9. Une opération multi-fichiers est annoncée comme récupérable, pas atomique,
   tant que le stockage ne garantit pas l’atomicité globale.
10. L’absence de consommateur runtime maintient la capacité en `MISSING` ou
    `BLOCKED`, même si son modèle d’authoring existe.
11. Aucun lot ne modifie la roadmap mécanique sans demande explicite.
12. Aucun lot n’est `DONE` sans preuves fraîches conformes aux règles du dépôt.

## 3. Structure cible

### 3.1 Nouveau package canonique

```text
packages/map_authoring/
├── pubspec.yaml
├── lib/
│   ├── map_authoring.dart
│   └── src/
│       ├── contracts/
│       ├── registry/
│       ├── workspace/
│       ├── transactions/
│       ├── history/
│       ├── security/
│       ├── references/
│       ├── domains/
│       │   ├── project/
│       │   ├── maps/
│       │   ├── assets/
│       │   ├── narrative/
│       │   ├── pokemon/
│       │   ├── gameplay/
│       │   └── distribution/
│       ├── ports/
│       └── tooling/
├── bin/
│   └── pokemap_authoring.dart
└── test/
    ├── contracts/
    ├── registry/
    ├── workspace/
    ├── transactions/
    ├── domains/
    └── contract_kit/
```

### 3.2 Adaptateurs existants

```text
packages/map_editor/lib/src/application/authoring_api/
packages/map_editor/lib/src/infrastructure/authoring_api/
packages/map_runtime/lib/src/application/authoring_preview/
examples/playable_runtime_host/lib/src/evaluation/
```

### 3.3 Adaptateur MCP

Emplacement cible :

```text
tools/pokemap_mcp/
├── package.json
├── tsconfig.json
├── src/
│   ├── server.ts
│   ├── authoring_client.ts
│   ├── tools/
│   ├── resources/
│   └── schemas/
└── test/
```

Le lot de compatibilité MCP confirmera l’SDK et le protocole avant la création
de cette arborescence. Le choix TypeScript est la valeur par défaut parce que
l’SDK officiel est disponible; le lot peut retenir un autre SDK officiel
uniquement si ses tests de conformité et de distribution sont meilleurs sur les
plateformes PokeMap.

## 4. Statuts et tailles

Tous les lots de ce document commencent au statut :

```text
PLANNED
```

Tailles relatives :

| Taille | Interprétation |
|---|---|
| `S` | Contrat ou adaptation bornée dans un package |
| `M` | Tranche verticale avec plusieurs contrats et tests |
| `L` | Domaine complet ou migration multi-package |
| `XL` | Gate de convergence nécessitant plusieurs lots préalables |

Les tailles ne constituent pas une estimation calendaire.

## 5. Graphe de dépendances

```text
PMCP-000
   ↓
PMCP-001 → PMCP-002 → PMCP-003
                         ↓
                PMCP-010 → 011 → 012 → 013
                                      ↓
                PMCP-020 → 021 → 022 → 023 → 024
                                      ↓
             ┌────────────┼────────────┐
             ↓            ↓            ↓
        Maps 030–035  Assets 040–042  Narrative 050–053
             └────────────┼────────────┘
                          ↓
                    Gameplay 060–063
                          ↓
                    Playtest 070–072
                          ↓
                    Editor 080–081
                          ↓
                    MCP 082–085
```

Les domaines Assets et Narrative peuvent avancer en parallèle après
`PMCP-024`. Gameplay attend les contrats de référence et de transaction, mais
ses sous-domaines indépendants pourront être planifiés séparément.

## 6. Jalons produit

| Jalon | Lots inclus | Résultat démontrable |
|---|---|---|
| `M0 — Registry` | `PMCP-000` à `003` | Catalogue généré, contrats versionnés et test kit |
| `M1 — Read API` | `PMCP-010` à `013` | Inspection fiable d’un projet réel par API et CLI |
| `M2 — Safe Write Kernel` | `PMCP-020` à `024` | Mutations planifiées, revisionnées, récupérables et annulables |
| `M3 — Map Authoring` | `PMCP-030` à `035` | Création et transformation d’une carte sans Flutter |
| `M4 — Content Authoring` | `PMCP-040` à `063` | Assets, narration et gameplay manipulables par la même API |
| `M5 — Runtime Proof` | `PMCP-070` à `072` | Playtest sandboxé, readiness et package prouvés |
| `M6 — Product Parity` | `PMCP-080` à `081` | L’éditeur utilise l’API canonique |
| `M7 — MCP Production` | `PMCP-082` à `085` | MCP conforme, sûr et sans contournement |

Le premier résultat utile pour un agent est `M1`. Le premier résultat capable
de modifier réellement des cartes est `M3`.

## 7. Definition of Done commune

Chaque lot doit satisfaire tous les points applicables :

- contrat public documenté et exporté par le barrel du package ;
- test positif ;
- test négatif ;
- test de garde-fou ;
- test de non-régression ;
- JSON round-trip lorsque le lot ajoute un contrat sérialisé ;
- dry-run sans écriture pour toute mutation ;
- apply nominal avec diff et receipt ;
- retry idempotent ;
- conflit de révision refusé ;
- permissions refusées testées ;
- impact de références documenté ;
- recovery testé pour toute mutation multi-fichiers ;
- undo testé ou non-applicabilité justifiée ;
- aucun accès Flutter/Flame depuis un package pur ;
- analyse et tests ciblés du package ;
- suite complète du package lorsque le coût reste proportionné ;
- build ou meilleure validation alternative documentée ;
- état git initial et final ;
- aucun fichier préexistant étranger modifié ;
- rapport de lot avec limites et risques ;
- statut de roadmap seulement proposé, jamais changé sans demande.

Commandes de base du nouveau package :

```bash
cd packages/map_authoring && dart test
cd packages/map_authoring && dart analyze
```

Les lots multi-packages ajoutent les commandes prévues dans `AGENTS.md`.

## 8. Phase A — Contrats et registre

### PMCP-000 — Baseline et matrice de couverture

**Statut :** `PLANNED`  
**Taille :** `S`  
**Dépendances :** aucune

**Objectif :** transformer le catalogue approuvé en inventaire vérifiable des
ressources, actions, consommateurs et preuves.

**Périmètre :**

- définir la matrice `SUPPORTED / NOT_APPLICABLE / BLOCKED / MISSING` ;
- inventorier les use cases publics de `map_editor` ;
- inventorier les opérations pures de `map_core` ;
- inventorier les commandes runtime et PokeMap Eval ;
- associer chaque action à son package propriétaire ;
- associer les lots `FG-*` pertinents sans modifier leur statut ;
- détecter les chemins de mutation UI sans équivalent canonique.

**Fichiers principaux :**

- créer `packages/map_core/lib/src/tooling/authoring_capability_inventory.dart`;
- créer `packages/map_core/tool/generate_authoring_capability_inventory.dart`;
- créer `packages/map_core/test/authoring_capability_inventory_test.dart`;
- créer `reports/analysis/pmcp_000_authoring_capability_baseline.md`;
- lire `pokemap_authoring_api_mcp_action_catalog.md`.

**Preuves de fin :**

- inventaire déterministe généré deux fois à l’identique ;
- chaque type de `ProjectManifest` et `MapData` possède une ligne ;
- chaque commande PokeMap Eval possède une ligne ;
- chaque ligne contient owner, statut, référence et consommateur runtime ;
- aucune capacité `SUPPORTED` sans fichier et test associés.

### PMCP-001 — Package `map_authoring` et frontières

**Statut :** `PLANNED`  
**Taille :** `S`  
**Dépendances :** `PMCP-000`

**Objectif :** créer le package Dart pur qui portera l’API canonique.

**Périmètre :**

- créer le pubspec et le barrel public ;
- fixer les dépendances autorisées ;
- ajouter un guardrail interdisant Flutter et Flame ;
- définir les namespaces de dossiers ;
- ajouter une API vide mais compilable ;
- documenter l’ownership des contrats et adaptateurs.

**Fichiers principaux :**

- créer `packages/map_authoring/pubspec.yaml`;
- créer `packages/map_authoring/lib/map_authoring.dart`;
- créer `packages/map_authoring/lib/src/architecture/package_boundaries.dart`;
- créer `packages/map_authoring/test/package_boundary_test.dart`;
- modifier uniquement les pubspecs des consommateurs lorsque les imports sont
  réellement introduits dans un lot ultérieur.

**Preuves de fin :**

- `dart test` et `dart analyze` verts dans `map_authoring` ;
- test d’architecture refusant `package:flutter` et `package:flame` ;
- aucun changement de comportement dans les packages existants.

### PMCP-002 — Contrats, références et registre d’actions

**Statut :** `PLANNED`  
**Taille :** `M`  
**Dépendances :** `PMCP-001`

**Objectif :** fournir les types publics versionnés décrivant ressources,
actions, schémas et capacités.

**Périmètre :**

- `AuthoringResourceRef` typé ;
- `AuthoringActionDescriptor` ;
- `AuthoringCapabilityDescriptor` ;
- `AuthoringSchemaDescriptor` ;
- niveaux de risque, permissions et garanties ;
- registre déterministe et recherche par ID ;
- détection des doublons et versions incompatibles ;
- représentation JSON sans dépendance MCP.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/contracts/resource_ref.dart`;
- créer `packages/map_authoring/lib/src/contracts/action_descriptor.dart`;
- créer `packages/map_authoring/lib/src/contracts/capability_descriptor.dart`;
- créer `packages/map_authoring/lib/src/contracts/schema_descriptor.dart`;
- créer `packages/map_authoring/lib/src/registry/action_registry.dart`;
- créer `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`;
- créer `packages/map_authoring/test/registry/action_registry_test.dart`;
- créer `packages/map_authoring/test/contracts/descriptor_json_test.dart`.

**Preuves de fin :**

- ordre stable indépendamment de l’ordre d’enregistrement ;
- doublons d’ID et de version refusés ;
- unknown future fields préservés ou refusés selon le contrat documenté ;
- catalogue minimal `project`, `map`, `layer`, `region` enregistré.

### PMCP-003 — Enveloppes, erreurs et kit de tests de contrat

**Statut :** `PLANNED`  
**Taille :** `M`  
**Dépendances :** `PMCP-002`

**Objectif :** standardiser requêtes, résultats, diagnostics et preuves de
parité pour tous les lots suivants.

**Périmètre :**

- enveloppe `AuthoringRequest` ;
- enveloppe `AuthoringResult` ;
- erreurs structurées ;
- diff et ressources affectées ;
- receipts et artefact refs ;
- sérialisation canonique ;
- fake repository et contract test kit ;
- générateur de documentation du registre.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/contracts/authoring_request.dart`;
- créer `packages/map_authoring/lib/src/contracts/authoring_result.dart`;
- créer `packages/map_authoring/lib/src/contracts/authoring_error.dart`;
- créer `packages/map_authoring/lib/src/contracts/authoring_diff.dart`;
- créer `packages/map_authoring/lib/src/contracts/authoring_receipt.dart`;
- créer `packages/map_authoring/lib/src/tooling/registry_documentation.dart`;
- créer `packages/map_authoring/test/contract_kit/authoring_action_contract.dart`;
- créer `packages/map_authoring/test/contracts/envelope_json_test.dart`.

**Preuves de fin :**

- round-trip de toutes les enveloppes ;
- erreurs sans stack trace ni chemin machine ;
- résultat compact avec lien d’artefact ;
- documentation générée déterministe.

## 9. Phase B — API de lecture

### PMCP-010 — Workspace sûr et handles explicites

**Statut :** `PLANNED`  
**Taille :** `M`  
**Dépendances :** `PMCP-003`

**Objectif :** ouvrir un projet sans état implicite ni accès hors des racines
autorisées.

**Périmètre :**

- configuration des racines ;
- canonicalisation et résolution de symlinks ;
- handles opaques de workspace et projet ;
- expiration et libération des handles ;
- mode lecture seule ;
- fingerprint initial ;
- refus des traversées de chemin.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/workspace/workspace_policy.dart`;
- créer `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart`;
- créer `packages/map_authoring/lib/src/workspace/project_open_service.dart`;
- créer `packages/map_authoring/lib/src/ports/project_file_reader.dart`;
- créer `packages/map_authoring/test/workspace/project_open_service_test.dart`;
- créer `packages/map_authoring/test/workspace/workspace_path_security_test.dart`.

**Preuves de fin :**

- ouverture d’un fixture réel ;
- refus d’un chemin extérieur et d’un symlink sortant ;
- handles inconnus et expirés refusés ;
- aucune écriture en lecture seule.

### PMCP-011 — Snapshot projet, queries et pagination

**Statut :** `PLANNED`  
**Taille :** `M`  
**Dépendances :** `PMCP-010`

**Objectif :** lire de grands projets par snapshots cohérents et projections
compactes.

**Périmètre :**

- snapshot du manifest et des maps ;
- révision globale dérivée des ressources ;
- `list/get/batch_get/search/summary` ;
- field masks ;
- filtres et tris déterministes ;
- pagination à curseur liée à la révision ;
- lecture de régions de map sans renvoyer la map entière.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/workspace/project_snapshot.dart`;
- créer `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`;
- créer `packages/map_authoring/lib/src/contracts/query_request.dart`;
- créer `packages/map_authoring/lib/src/contracts/query_page.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/map_region_query.dart`;
- créer `packages/map_authoring/test/workspace/project_snapshot_test.dart`;
- créer `packages/map_authoring/test/contracts/query_pagination_test.dart`.

**Preuves de fin :**

- pagination stable sur snapshot figé ;
- curseur refusé avec une requête ou révision différente ;
- projection summary sensiblement plus petite que detail sans perte d’identité ;
- région hors limites refusée proprement.

### PMCP-012 — Références, diagnostics et capability truth

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-011`

**Objectif :** unifier dépendances, références cassées et vérité de support.

**Périmètre :**

- index de références typées ;
- dépendances et dependents ;
- graphe borné ;
- impact de suppression/renommage ;
- références cassées ;
- adaptation des read models narratifs existants ;
- adaptation de `project_capability_truth.dart` ;
- diagnostics codés et navigables.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/references/project_reference_index.dart`;
- créer `packages/map_authoring/lib/src/references/reference_impact.dart`;
- créer `packages/map_authoring/lib/src/references/reference_queries.dart`;
- créer `packages/map_authoring/lib/src/domains/project/capability_truth_adapter.dart`;
- réutiliser
  `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`;
- réutiliser
  `packages/map_core/lib/src/read_models/project_capability_truth.dart`;
- créer `packages/map_authoring/test/references/project_reference_index_test.dart`.

**Preuves de fin :**

- références inter-domaines couvertes ;
- cycles terminent sans récursion infinie ;
- graphe paginé ou borné ;
- aucune capacité promue par simple présence de modèle.

### PMCP-013 — CLI JSONL en lecture seule

**Statut :** `PLANNED`  
**Taille :** `M`  
**Dépendances :** `PMCP-012`

**Objectif :** prouver l’API indépendamment de Flutter et du futur SDK MCP.

**Périmètre :**

- executable `pokemap_authoring` ;
- commandes describe/open/query/validate/close ;
- protocole JSONL strict ;
- stdout réservé aux enveloppes ;
- stderr réservé aux diagnostics opérateur ;
- codes de sortie documentés ;
- limites d’entrée et timeouts ;
- golden transcripts.

**Fichiers principaux :**

- créer `packages/map_authoring/bin/pokemap_authoring.dart`;
- créer `packages/map_authoring/lib/src/tooling/jsonl_worker.dart`;
- créer `packages/map_authoring/lib/src/tooling/cli_exit_codes.dart`;
- créer `packages/map_authoring/test/tooling/jsonl_worker_test.dart`;
- créer `packages/map_authoring/test/tooling/cli_golden_test.dart`;
- modifier `packages/map_authoring/pubspec.yaml` pour déclarer l’executable.

**Preuves de fin :**

- un projet réel est ouvert, interrogé et validé en JSONL ;
- entrée malformée ne termine pas le worker de manière ambiguë ;
- aucune sortie non JSON sur stdout ;
- résultat direct API et résultat CLI identiques.

## 10. Phase C — Noyau de mutation sûre

### PMCP-020 — Plan, dry-run et diff structuré

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-013`

**Objectif :** fournir le pipeline commun de toute mutation.

**Périmètre :**

- plan opaque et expirant ;
- IDs et seed fixés au plan ;
- mutation pure en mémoire ;
- normalisation et validation ;
- ressources touchées ;
- diff structuré ;
- impact de références ;
- preview artifact refs ;
- apply refusé si plan périmé.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/transactions/action_planner.dart`;
- créer `packages/map_authoring/lib/src/transactions/authoring_plan.dart`;
- créer `packages/map_authoring/lib/src/transactions/plan_store.dart`;
- créer `packages/map_authoring/lib/src/transactions/change_set.dart`;
- créer `packages/map_authoring/test/transactions/action_planner_test.dart`;
- créer `packages/map_authoring/test/transactions/stale_plan_test.dart`.

**Preuves de fin :**

- dry-run sans modification de fichier ;
- même plan donne mêmes IDs, seed et diff ;
- changement externe invalide le plan ;
- plan expiré produit une remédiation exploitable.

### PMCP-021 — CAS et ledger d’idempotence durable

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-020`

**Objectif :** rendre les retries sûrs et refuser les lost updates.

**Périmètre :**

- expected revisions par ressource ;
- calcul de fingerprints canoniques ;
- ledger durable d’idempotence ;
- même clé + même payload retourne le même receipt ;
- même clé + payload différent est refusé ;
- scope acteur/projet/action/version ;
- rétention et nettoyage bornés.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/transactions/revision_set.dart`;
- créer `packages/map_authoring/lib/src/transactions/idempotency_ledger.dart`;
- créer `packages/map_authoring/lib/src/ports/idempotency_store.dart`;
- adapter
  `packages/map_editor/lib/src/infrastructure/repositories/atomic_map_document_persistence.dart`;
- adapter
  `packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart`;
- créer `packages/map_authoring/test/transactions/idempotency_contract_test.dart`;
- créer `packages/map_authoring/test/transactions/revision_conflict_test.dart`.

**Preuves de fin :**

- retry après perte de réponse ne réapplique pas l’action ;
- collision de clé refusée ;
- mutation concurrente refusée ;
- ledger récupérable après redémarrage.

### PMCP-022 — Transaction multi-fichiers et recovery

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-021`

**Objectif :** généraliser le journal récupérable du lifecycle map.

**Périmètre :**

- journal avant/après ;
- écritures temporaires vérifiées ;
- promotion ordonnée ;
- reprise idempotente ;
- compensation revision-gated ;
- inspection et plan de recovery ;
- crash simulé à chaque frontière ;
- receipts honnêtes sur l’atomicité.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/transactions/journaled_transaction.dart`;
- créer `packages/map_authoring/lib/src/transactions/recovery_service.dart`;
- créer `packages/map_authoring/lib/src/ports/transaction_file_gateway.dart`;
- réutiliser
  `packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart`;
- réutiliser
  `packages/map_editor/lib/src/infrastructure/repositories/journaled_file_promotion_repository.dart`;
- créer `packages/map_authoring/test/transactions/crash_boundary_test.dart`;
- créer `packages/map_authoring/test/transactions/recovery_idempotence_test.dart`.

**Preuves de fin :**

- chaque crash simulé laisse un état ancien ou récupérable ;
- reprise répétée est idempotente ;
- compensation refuse une révision divergente ;
- aucun message ne prétend à une atomicité non garantie.

### PMCP-023 — Permissions, confirmations et audit

**Statut :** `PLANNED`  
**Taille :** `M`  
**Dépendances :** `PMCP-022`

**Objectif :** appliquer une politique uniforme avant toute exposition agent.

**Périmètre :**

- scopes du catalogue ;
- lecture seule par défaut ;
- réseau désactivé par défaut ;
- niveaux de risque ;
- confirmation token ;
- redaction de secrets et chemins ;
- rate/size limits ;
- audit append-only.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/security/authoring_permission.dart`;
- créer `packages/map_authoring/lib/src/security/authorization_policy.dart`;
- créer `packages/map_authoring/lib/src/security/confirmation_token.dart`;
- créer `packages/map_authoring/lib/src/security/audit_record.dart`;
- créer `packages/map_authoring/test/security/authorization_policy_test.dart`;
- créer `packages/map_authoring/test/security/output_redaction_test.dart`.

**Preuves de fin :**

- action destructive refusée sans scope et confirmation ;
- lecture seule empêche toute écriture indirecte ;
- aucun secret ou chemin absolu dans les erreurs ;
- audit relie request, plan, receipt et acteur.

### PMCP-024 — History, undo/redo et gate de mutation

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-023`

**Objectif :** rendre les mutations durables et fermer le contrat commun.

**Périmètre :**

- history paginée ;
- undo comme nouvelle transaction CAS ;
- redo comme nouvelle transaction CAS ;
- revert d’une révision ;
- rétention des blobs adressés par contenu ;
- batch d’actions ;
- contract suite obligatoire pour enregistrer une mutation.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/history/authoring_history.dart`;
- créer `packages/map_authoring/lib/src/history/undo_service.dart`;
- créer `packages/map_authoring/lib/src/history/revision_revert_service.dart`;
- créer `packages/map_authoring/lib/src/transactions/batch_executor.dart`;
- créer `packages/map_authoring/test/history/undo_redo_contract_test.dart`;
- créer `packages/map_authoring/test/contract_kit/mutation_gate_test.dart`.

**Preuves de fin :**

- undo refuse d’écraser une modification ultérieure ;
- redo fonctionne après undo et est invalidé par une branche divergente ;
- action non undoable expose une raison et une durée de rétention ;
- aucune mutation ne rejoint le registre sans contract suite.

## 11. Phase D — Tranche verticale Maps

### PMCP-030 — Lifecycle map canonique

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-024`

**Objectif :** migrer create/load/save/rename/duplicate/delete/resize derrière
`map_authoring`.

**Périmètre :**

- adapter les opérations existantes ;
- conserver les validations et comportements legacy ;
- plan d’impact avant rename/delete/resize ;
- transaction manifest + fichier map ;
- receipts et undo ;
- commandes CLI correspondantes.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/maps/map_lifecycle_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart`;
- réutiliser
  `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`;
- réutiliser
  `packages/map_core/lib/src/operations/map_resize.dart`;
- créer `packages/map_authoring/test/domains/maps/map_lifecycle_contract_test.dart`;
- créer un test d’adaptation dans `packages/map_editor/test/`.

**Preuves de fin :**

- lifecycle complet via API et CLI ;
- crash recovery manifest + map ;
- rename/delete protègent les dépendances ;
- comportement historique de l’éditeur préservé.

### PMCP-031 — Layers, régions et `map.apply_operations`

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-030`

**Objectif :** permettre la construction efficace d’une carte sans appels
cellule par cellule.

**Périmètre :**

- lifecycle de tous les types de layer ;
- paint/erase/stamp/fill/flood/replace ;
- line/polyline/rect/polygon ;
- copy/cut/paste/move/rotate/flip ;
- validation bounds et tailles de layer ;
- batch compact `map.apply_operations` ;
- un seul receipt et undo par batch.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/maps/layer_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/region_operations.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/map_operations_batch.dart`;
- réutiliser
  `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`;
- créer `packages/map_authoring/test/domains/maps/region_operations_test.dart`;
- créer `packages/map_authoring/test/domains/maps/map_operations_batch_test.dart`.

**Preuves de fin :**

- une fixture map complète créée par un batch borné ;
- batch invalide n’applique aucune opération ;
- rotation/flip préservent dimensions et références ;
- receipt décrit les cellules et ressources touchées sans payload démesuré.

### PMCP-032 — Terrain, path, surface et autotile

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-031`

**Objectif :** exposer les opérations sémantiques plutôt que les tuiles brutes.

**Périmètre :**

- terrain paint/erase/fill/replace ;
- path paint/erase/fill et propriétés ;
- surface paint/erase/clear ;
- autotile resolve/preview/apply/rebuild ;
- presets et variants référencés par ID typé ;
- seed déterministe pour variants pondérés.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/maps/terrain_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/path_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/surface_actions.dart`;
- adapter
  `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart`;
- adapter les opérations surface existantes de `map_core`;
- créer `packages/map_authoring/test/domains/maps/semantic_painting_test.dart`;
- créer `packages/map_authoring/test/domains/maps/autotile_determinism_test.dart`.

**Preuves de fin :**

- même seed produit le même résultat ;
- preview et apply produisent le même change set ;
- preset manquant produit un diagnostic réparable ;
- aucun tileset brut requis pour l’usage normal.

### PMCP-033 — Environment et border

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-032`

**Objectif :** regrouper les workflows aujourd’hui dispersés dans des actions
planifiables.

**Périmètre :**

- environment areas, masks, seed et génération ;
- placements générés et overrides manuels ;
- border strokes, features et blueprints ;
- relink, materialization et resize ;
- diagnostics et publication readiness ;
- preview artifact.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/maps/environment_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/border_actions.dart`;
- réutiliser les opérations `packages/map_core/lib/src/operations/border_*`;
- adapter les use cases `environment_*` de `map_editor`;
- créer `packages/map_authoring/test/domains/maps/environment_actions_test.dart`;
- créer `packages/map_authoring/test/domains/maps/border_actions_test.dart`.

**Preuves de fin :**

- génération déterministe ;
- local edit ne régénère pas hors de son halo documenté ;
- blueprint non publiable refusé ;
- preview lié à la révision et au seed.

### PMCP-034 — Objets spatiaux et collision effective

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-031`

**Objectif :** unifier placed elements, entities, NPC, triggers, zones et
collisions.

**Périmètre :**

- CRUD et batch move ;
- payloads typés ;
- NPC visibility/dialogues/movement/waypoints ;
- triggers et gameplay zones ;
- profils collision d’élément ;
- collision layer ;
- query de collision effective avec provenance ;
- walkability et reachability.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/maps/placed_element_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/entity_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/trigger_zone_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/collision_actions.dart`;
- adapter
  `packages/map_editor/lib/src/application/use_cases/entity_use_cases.dart`;
- adapter
  `packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart`;
- créer `packages/map_authoring/test/domains/maps/spatial_object_contract_test.dart`;
- créer `packages/map_authoring/test/domains/maps/effective_collision_test.dart`.

**Preuves de fin :**

- payload incompatible avec le kind refusé ;
- déplacement hors bounds refusé atomiquement ;
- collision expliquée par couche/élément/entité ;
- reachability détecte une sortie isolée.

### PMCP-035 — Warps, connexions, world graph et rendu map

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-034`

**Objectif :** fermer les relations inter-maps et produire une preuve visuelle.

**Périmètre :**

- warp CRUD et paires réciproques ;
- connection CRUD et opérations bidirectionnelles ;
- transaction sur les deux maps ;
- world graph connecté/déconnecté et pathfinding ;
- preview d’alignement ;
- render map/region/layer/overlays via port ;
- absence explicite de `worldLayout` global.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/maps/warp_connection_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/maps/world_graph_queries.dart`;
- créer `packages/map_authoring/lib/src/ports/map_render_port.dart`;
- adapter
  `packages/map_editor/lib/src/application/use_cases/map_connection_use_cases.dart`;
- adapter
  `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart`;
- créer un adaptateur de rendu sous
  `packages/map_runtime/lib/src/application/authoring_preview/`;
- créer `packages/map_authoring/test/domains/maps/warp_connection_transaction_test.dart`.

**Preuves de fin :**

- paire source/cible modifiée ou récupérable ensemble ;
- référence cible invalide refusée ;
- world graph déterministe ;
- overlays collision/zones/warps/entities générés.

## 12. Phase E — Assets et bibliothèques visuelles

### PMCP-040 — Asset store et imports sûrs

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-024`

**Objectif :** créer un registre d’assets unifié et adressé par contenu.

**Périmètre :**

- list/get/search/inspect/preview ;
- import/replace/move/delete planifiés ;
- digests et MIME réel ;
- artefact handles ;
- usages, unused et dedupe ;
- sécurité path/symlink/taille ;
- rollback des blobs.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/assets/asset_store.dart`;
- créer `packages/map_authoring/lib/src/domains/assets/asset_actions.dart`;
- créer `packages/map_authoring/lib/src/contracts/artifact_ref.dart`;
- créer `packages/map_authoring/lib/src/ports/artifact_store.dart`;
- créer `packages/map_authoring/test/domains/assets/asset_security_test.dart`;
- créer `packages/map_authoring/test/domains/assets/content_addressing_test.dart`.

**Preuves de fin :**

- symlink sortant refusé ;
- contenu identique détecté ;
- suppression référencée bloquée ;
- undo restaure le blob exact.

### PMCP-041 — Tilesets, palettes, éléments et presets

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-040`, `PMCP-032`

**Objectif :** exposer la chaîne visuelle utilisée par l’éditeur de maps.

**Périmètre :**

- tileset folders et tilesets ;
- grille, transparent color et tile properties ;
- palette entries et frames ;
- element categories/groups/elements ;
- collisions, animations et tags ;
- terrain/path/surface/environment presets ;
- shadows et projected building shadows ;
- dependency preflight.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/assets/tileset_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/assets/palette_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/assets/element_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/assets/preset_actions.dart`;
- adapter les use cases `project_tileset*`, `project_element*` et
  `terrain_preset_use_cases.dart`;
- créer `packages/map_authoring/test/domains/assets/visual_library_contract_test.dart`.

**Preuves de fin :**

- suppression d’élément scanne toutes les maps ;
- source rect hors atlas refusé ;
- regrid fournit un impact avant apply ;
- presets restent utilisables par les actions de map.

### PMCP-042 — Presentation, vidéo, audio et fontes

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-040`

**Objectif :** couvrir les assets non-map et le profil de présentation.

**Périmètre :**

- branding et title music ;
- intro video, poster et captions ;
- typography roles, licence et glyph coverage ;
- semantic theme ;
- inspection et validation média ;
- transcode/normalize via ports asynchrones ;
- preview.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/assets/presentation_actions.dart`;
- créer `packages/map_authoring/lib/src/ports/media_processing_port.dart`;
- adapter
  `packages/map_core/lib/src/models/project_presentation_profile.dart`;
- adapter les services de Personalization Studio de `map_editor`;
- créer `packages/map_authoring/test/domains/assets/presentation_actions_test.dart`;
- créer un test d’adaptateur dans `packages/map_editor/test/`.

**Preuves de fin :**

- contrastes, licences et glyph coverage validés ;
- média hors limites refusé avant copie ;
- traitement long retourne un job/artefact ;
- fallback de présentation préservé.

## 13. Phase F — Narration

### PMCP-050 — Dialogues Yarn et scripts legacy

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-024`

**Objectif :** couvrir lifecycle, source, compile, outcomes et migration.

**Périmètre :**

- dialogue folders et dialogues ;
- source Yarn ;
- nodes/lines/choices/jumps/outcomes ;
- tags et start node ;
- compile/validate/simulate ;
- scripts legacy et conditions ;
- migration planifiée vers Scene.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/narrative/dialogue_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/narrative/yarn_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/narrative/script_actions.dart`;
- adapter les use cases `project_dialogue_use_cases.dart`;
- réutiliser les compilateurs dialogue de `map_core`;
- créer `packages/map_authoring/test/domains/narrative/dialogue_contract_test.dart`;
- créer `packages/map_authoring/test/domains/narrative/script_migration_test.dart`.

**Preuves de fin :**

- source et metadata persistent ensemble ou sont récupérables ;
- outcome utilisé ne peut être supprimé sans remplacement ;
- commande Yarn inconnue reste honnêtement diagnostiquée ;
- migration legacy conserve les effets supportés.

### PMCP-051 — Scenes, Event V2, Facts et World Rules

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-050`, `PMCP-012`

**Objectif :** exposer le cœur narratif moderne à travers les opérations pures
existantes.

**Périmètre :**

- Scene lifecycle, nodes, edges, layout et outcomes ;
- les 22 commandes canoniques ;
- Event V2 sources, conditions, priorité et publication ;
- Facts typés ;
- World Rules ;
- dependency impact ;
- simulate/reachability.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/narrative/event_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/narrative/fact_rule_actions.dart`;
- adapter `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`;
- adapter les opérations Event V2 et World Rule de `map_core/src/authoring`;
- adapter
  `packages/map_editor/lib/src/application/use_cases/execute_narrative_authoring_transaction.dart`;
- créer `packages/map_authoring/test/domains/narrative/scene_event_contract_test.dart`.

**Preuves de fin :**

- API ne duplique pas les règles d’opérations pures ;
- source/condition invalide refusée ;
- publication et activation revision-gated ;
- commande sans consommateur runtime non promue.

### PMCP-052 — Storylines et migration Scenarios

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-051`

**Objectif :** couvrir chapitres, étapes, relations et migration legacy.

**Périmètre :**

- storyline lifecycle ;
- chapters et steps ;
- scene links, relationships, effects et anchors ;
- progression graph ;
- availability et completion preview ;
- Scenario read/validate/simulate ;
- migration planifiée vers Storyline/Scene/Event V2.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/narrative/storyline_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/narrative/scenario_actions.dart`;
- adapter les opérations Storyline existantes de `map_core/src/authoring`;
- créer `packages/map_authoring/test/domains/narrative/storyline_progression_test.dart`;
- créer `packages/map_authoring/test/domains/narrative/scenario_migration_test.dart`.

**Preuves de fin :**

- cycles et étapes inatteignables diagnostiqués ;
- reorder conserve les identités ;
- migration fournit diff et références impactées ;
- legacy reste lisible après migration.

### PMCP-053 — Cinématiques et gate narrative

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-052`, `PMCP-035`, `PMCP-042`

**Objectif :** couvrir timeline, média, preflight et fermer la parité narrative.

**Périmètre :**

- stage, actors, appearances et placements ;
- targets, stage points et paths ;
- douze kinds de timeline ;
- copy/paste/reorder ;
- preflight et preview ;
- limitations runtime explicites ;
- diagnostic suppression planifiée ;
- matrice narrative editor/API/runtime.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/narrative/cinematic_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/narrative/narrative_parity_gate.dart`;
- adapter les opérations Cinematic de `map_core/src/authoring`;
- réutiliser le preflight runtime de `map_core`;
- créer un preview adapter dans `map_runtime`;
- créer `packages/map_authoring/test/domains/narrative/cinematic_contract_test.dart`;
- créer `packages/map_authoring/test/domains/narrative/narrative_parity_gate_test.dart`.

**Preuves de fin :**

- chaque timeline kind est authorable ou explicitement bloqué ;
- target runtime-unsafe refusé au preflight ;
- preview lié à la révision ;
- aucune mutation narrative UI hors matrice.

## 14. Phase G — Données et mécanique de jeu

### PMCP-060 — Base Pokémon, espèces et catalogues

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-024`, `PMCP-040`

**Objectif :** déplacer les contrats authoring dispersés vers une façade pure.

**Périmètre :**

- catalogues génériques ;
- species/forms ;
- stats, types, abilities et metadata ;
- learnsets et evolutions ;
- media ;
- imports et sync externes derrière permission réseau ;
- batch et validation.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/pokemon/catalog_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/pokemon/species_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/pokemon/import_actions.dart`;
- adapter les ports Pokémon de `map_editor/lib/src/application/ports/`;
- adapter
  `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`;
- créer `packages/map_authoring/test/domains/pokemon/species_contract_test.dart`;
- créer `packages/map_authoring/test/domains/pokemon/import_security_test.dart`.

**Preuves de fin :**

- import preview sans réseau implicite ;
- references learnset/evolution/media validées ;
- batch partiellement invalide ne produit pas d’état ambigu ;
- round-trip des données existantes sans perte.

### PMCP-061 — Moves, abilities, items et contenu de campagne

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-060`, `PMCP-051`

**Objectif :** couvrir les définitions gameplay authorables et les catalogues
de campagne.

**Périmètre :**

- moves/effects/engine support ;
- abilities/effects ;
- items overworld/battle/held/capture/TM-HM ;
- trainers et teams ;
- characters et animations ;
- encounter tables et conditions ;
- shops et badges ;
- New Game et starters.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/pokemon/move_ability_item_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/gameplay/trainer_encounter_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/gameplay/shop_badge_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/gameplay/new_game_actions.dart`;
- adapter les use cases trainer/encounter existants de `map_editor`;
- créer `packages/map_authoring/test/domains/gameplay/campaign_content_contract_test.dart`.

**Preuves de fin :**

- définition non consommée marquée partielle ;
- trainer battle setup valide ;
- encounter distribution déterministe avec seed ;
- New Game produit un état initial validé.

### PMCP-062 — Save, party, PC, bag et services

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-061`

**Objectif :** fournir les opérations d’état joueur nécessaires au playtest et
aux templates narratifs.

**Périmètre :**

- save inspect/validate/migrate/diff ;
- party et summary ;
- PC/boxes ;
- bag, money et items ;
- shop/heal/PC services ;
- mutations sur copie sandbox uniquement ;
- probes explicitement séparées.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/gameplay/save_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/gameplay/player_state_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/gameplay/service_actions.dart`;
- adapter les services de `map_gameplay`;
- adapter les repositories de save de `map_runtime`;
- créer `packages/map_authoring/test/domains/gameplay/player_state_contract_test.dart`;
- créer `packages/map_authoring/test/domains/gameplay/production_save_isolation_test.dart`.

**Preuves de fin :**

- aucune action authoring ne modifie une save de production ;
- guards last usable Pokémon et box pleine testés ;
- shop transaction conserve argent/stock/bag ;
- save future inconnue reste non modifiable.

### PMCP-063 — Battle, progression et preuve de consommation

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-062`

**Objectif :** exposer simulation battle et write-back sans déplacer les règles
hors de `map_battle` et `map_gameplay`.

**Périmètre :**

- setup wild/trainer/static ;
- commandes battle ;
- seed et trace ;
- outcome et write-back ;
- XP, level, move learning et evolution ;
- rewards et capture destination ;
- simulation et receipt ;
- capability truth basée sur le vrai consommateur runtime.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/gameplay/battle_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/gameplay/progression_actions.dart`;
- adapter les façades de `map_battle`;
- adapter `packages/map_gameplay/lib/src/battle_progression_service.dart`;
- adapter le write-back de `map_runtime`;
- créer `packages/map_authoring/test/domains/gameplay/battle_simulation_contract_test.dart`;
- créer un smoke test dans `packages/map_runtime/test/`.

**Preuves de fin :**

- simulation même seed/mêmes décisions identique ;
- write-back complet prouvé ;
- décision move/evolution explicite ;
- unsupported effect n’est pas annoncé supporté.

## 15. Phase H — Playtest, readiness et distribution

### PMCP-070 — Ports de playtest et session sandboxée

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-063`, `PMCP-035`

**Objectif :** extraire le framework PokeMap Eval derrière des contrats
réutilisables par l’API.

**Périmètre :**

- playtest port dans `map_authoring` ;
- adapter PokeMap Eval ;
- project revision figée ;
- save/checkpoint éphémère ;
- start/pause/resume/stop ;
- commands/events/snapshots/diffs ;
- screenshot et receipt ;
- cleanup garanti.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/ports/playtest_port.dart`;
- créer `packages/map_authoring/lib/src/contracts/playtest_contracts.dart`;
- adapter
  `examples/playable_runtime_host/lib/src/evaluation/driver/evaluation_driver.dart`;
- adapter le runner et les workers existants ;
- créer `packages/map_authoring/test/contracts/playtest_contract_test.dart`;
- créer un test d’intégration dans `examples/playable_runtime_host/test/evaluation/`.

**Preuves de fin :**

- session pilotée depuis l’API ;
- arrêt libère ressources et fichiers temporaires ;
- projet et save de production inchangés ;
- receipt lie révision, seed, scénario et artefacts.

### PMCP-071 — Commandes manquantes, jobs et artefacts

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-070`

**Objectif :** fermer les gaps du catalogue PokeMap Eval et uniformiser les
travaux longs.

**Périmètre :**

- party/bag/PC complets ;
- shop sell ;
- battle switch/target/learning/evolution ;
- trainer/static battle starts ;
- pause/options/Pokédex/save slots ;
- assertions Scene/outcome/visuelles ;
- jobs get/events/cancel/retry ;
- artefacts image/log/receipt.

**Fichiers principaux :**

- modifier
  `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart`;
- adapter `evaluation_scenario_runner.dart`;
- adapter `evaluation_worker_pool.dart`;
- créer `packages/map_authoring/lib/src/contracts/job_contracts.dart`;
- créer `packages/map_authoring/lib/src/contracts/artifact_contracts.dart`;
- créer des tests ciblés dans `examples/playable_runtime_host/test/evaluation/`;
- créer `packages/map_authoring/test/contracts/job_contract_test.dart`.

**Preuves de fin :**

- toutes les commandes du catalogue d’actions applicables ont un chemin réel ;
- cancellation bornée ;
- ordre des événements stable ;
- aucune commande opaque ne remplace une séquence utilisateur essentielle.

### PMCP-072 — Readiness, Golden Slice et package identique

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-071`, `PMCP-053`, `PMCP-041`

**Objectif :** prouver le chemin authoring → validation → playtest → package.

**Périmètre :**

- project readiness orchestrée ;
- fixes uniquement planifiés ;
- Golden Slice créé par l’API publique ;
- regression matrix ;
- package build/inspect/verify ;
- digest identique entre export et installation ;
- release receipt ;
- mapping vers `FG-180` à `FG-185` sans changement automatique.

**Fichiers principaux :**

- créer `packages/map_authoring/lib/src/domains/project/readiness_actions.dart`;
- créer `packages/map_authoring/lib/src/domains/distribution/package_actions.dart`;
- adapter les validators de `map_core`;
- adapter `packages/map_distribution/lib/src/game_package_builder.dart`;
- adapter les release gates existants de PokeMap Eval ;
- créer un fixture sous `examples/playable_runtime_host/`;
- créer des tests dans `packages/map_authoring/test/domains/distribution/`.

**Preuves de fin :**

- fixture créée sans écriture JSON directe ;
- mêmes octets vérifiés par digest ;
- Golden Slice atteint son résultat via runtime de production ;
- chaque diagnostic de release cite sa preuve.

## 16. Phase I — Parité éditeur et MCP

### PMCP-080 — Migration lecture de `map_editor`

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-072`

**Objectif :** faire lire le projet à l’éditeur via les snapshots et queries
canoniques.

**Périmètre :**

- bootstrap projet ;
- listes/maps/catalogues ;
- diagnostics ;
- références ;
- projections adaptées à l’UI ;
- aucune mutation modifiée dans ce lot ;
- mesures de non-régression sur grands projets.

**Fichiers principaux :**

- créer `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart`;
- créer `packages/map_editor/lib/src/infrastructure/authoring_api/editor_project_file_reader.dart`;
- modifier les state/notifiers par tranches bornées ;
- ajouter la dépendance `map_authoring` au pubspec éditeur ;
- créer `packages/map_editor/test/authoring_api/editor_read_parity_test.dart`;
- adapter les tests large-project existants.

**Preuves de fin :**

- affichage identique sur fixtures de référence ;
- aucun second parsing concurrent du projet ;
- pagination et recherche gardent l’ordre UI ;
- performances ne régressent pas au-delà du budget existant.

### PMCP-081 — Migration mutations de `map_editor`

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-080`

**Objectif :** supprimer les chemins de mutation produit qui contournent
`map_authoring`.

**Périmètre :**

- maps et layers ;
- assets et presets ;
- objets spatiaux ;
- narration ;
- données gameplay ;
- save/dirty/history de l’éditeur ;
- receipts reliés au feedback UI ;
- suppression progressive des orchestrations dupliquées.

**Fichiers principaux :**

- créer `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart`;
- créer `packages/map_editor/lib/src/application/authoring_api/editor_receipt_presenter.dart`;
- modifier les use cases et notifiers concernés par lots internes ;
- conserver les widgets du design system ;
- créer `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`;
- créer un guardrail détectant les writes projet hors adaptateurs autorisés.

**Preuves de fin :**

- API directe et geste UI produisent le même receipt ;
- undo/redo UI passe par l’historique canonique ;
- conflit externe visible et non écrasé ;
- aucun contrôleur Flutter appelé par `map_authoring`.

### PMCP-082 — Gate SDK et protocole MCP

**Statut :** `PLANNED`  
**Taille :** `S`  
**Dépendances :** `PMCP-013`, `PMCP-071`

**Objectif :** figer l’SDK, la version de protocole et le mode de distribution
du serveur MCP par preuves, pas par préférence.

**Périmètre :**

- tester l’SDK TypeScript officiel ;
- tester stdio local ;
- tester Streamable HTTP stateless si requis ;
- vérifier outils, resources, structured content et Tasks ;
- vérifier compatibilité client réelle ;
- définir fallback protocol version ;
- produire un decision record.

**Fichiers principaux :**

- créer `reports/analysis/pmcp_082_mcp_sdk_compatibility_decision.md`;
- créer un spike temporaire uniquement dans le plan dédié puis conserver
  seulement les tests et fichiers retenus ;
- préparer `tools/pokemap_mcp/` si l’option TypeScript est validée.

**Critère de décision :**

- retenir TypeScript officiel si la version testée passe conformance, stdio,
  resources, structured content et gestion de jobs nécessaire ;
- sinon retenir le SDK officiel le mieux classé qui passe la même matrice ;
- supporter `2026-07-28` lorsque client et SDK le permettent ;
- négocier une version antérieure documentée sans changer les contrats
  `map_authoring`.

**Preuves de fin :**

- matrice SDK/version/client reproductible ;
- aucune dépendance protocolaire dans `map_authoring` ;
- stratégie d’upgrade et de fallback documentée.

Sources officielles à revalider pendant le lot :

- [MCP SDK tiers](https://modelcontextprotocol.io/community/sdk-tiers)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [MCP specification](https://modelcontextprotocol.io/specification/draft/server/tools)

### PMCP-083 — MCP lecture seule et resources

**Statut :** `PLANNED`  
**Taille :** `L`  
**Dépendances :** `PMCP-082`, `PMCP-080`

**Objectif :** livrer le premier MCP utile sans autoriser de mutation.

**Périmètre :**

- `pokemap_describe` ;
- `pokemap_workspace` en lecture ;
- `pokemap_query` ;
- `pokemap_validate` en lecture ;
- `pokemap_artifact` en lecture ;
- resources project/map/catalog/diagnostics ;
- pagination et structured content ;
- handles explicites ;
- sandbox de chemins.

**Fichiers principaux :**

- créer l’arborescence `tools/pokemap_mcp/` validée par `PMCP-082`;
- créer `src/authoring_client.ts`;
- créer les tools read-only ;
- créer les resource templates ;
- créer les tests protocolaires et golden transcripts ;
- ajouter la documentation de connexion locale.

**Preuves de fin :**

- client MCP inspecte un projet réel ;
- tools list stable et schémas valides ;
- resource URI invalide refusée ;
- aucune écriture possible par cette version du serveur.

### PMCP-084 — MCP mutation, rendu, playtest et historique

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** `PMCP-083`, `PMCP-081`

**Objectif :** exposer toute la puissance de l’API sans élargir la surface MCP.

**Périmètre :**

- `pokemap_plan` ;
- `pokemap_apply` ;
- `pokemap_render` ;
- `pokemap_playtest` ;
- `pokemap_job` ou Tasks ;
- `pokemap_history` ;
- `pokemap_recovery` ;
- confirmations ;
- liens d’artefacts ;
- erreurs réparables par le modèle.

**Fichiers principaux :**

- compléter `tools/pokemap_mcp/src/tools/`;
- compléter `tools/pokemap_mcp/src/resources/`;
- compléter `authoring_client.ts`;
- créer tests plan/apply/retry/conflict/permission ;
- créer tests render/playtest/job/cancel ;
- créer test de parité API/CLI/MCP.

**Preuves de fin :**

- un agent crée une map par batch, preview, validate et apply ;
- retry ne double pas la mutation ;
- conflit est retourné sans interprétation silencieuse ;
- playtest sandboxé retourne un receipt et des artefacts ;
- recovery exige permission et confirmation.

### PMCP-085 — Conformance, sécurité et gate « 100 % »

**Statut :** `PLANNED`  
**Taille :** `XL`  
**Dépendances :** tous les lots précédents

**Objectif :** autoriser la revendication de couverture complète uniquement sur
preuve.

**Périmètre :**

- matrice ressource × capacité ;
- comparaison automatique avec use cases éditeur ;
- comparaison avec commandes runtime ;
- tests de contrat de toutes les mutations ;
- conformance MCP ;
- threat model et tests path/permission/rate/size ;
- fuzz des enveloppes et schémas ;
- golden journey API directe/éditeur/CLI/MCP ;
- documentation utilisateur et développeur ;
- release gate.

**Fichiers principaux :**

- créer `packages/map_authoring/test/parity/full_authoring_parity_test.dart`;
- créer `packages/map_editor/test/authoring_api/no_bypass_guardrail_test.dart`;
- créer tests de conformance dans `tools/pokemap_mcp/test/`;
- créer `reports/analysis/pmcp_085_full_parity_evidence_pack.md`;
- mettre à jour le catalogue uniquement avec preuves fraîches ;
- proposer les statuts roadmap sans les modifier automatiquement.

**Preuves de fin :**

- chaque cellule applicable est `SUPPORTED` ;
- chaque `NOT_APPLICABLE` est justifié ;
- aucun `BLOCKED` ou `MISSING` caché par un outil générique ;
- même scénario produit des receipts équivalents via API, CLI et MCP ;
- éditeur sans chemin de mutation hors API ;
- conformance et sécurité vertes sur les commandes exactes du rapport.

## 17. Ordre de lancement recommandé

Commencer par :

```text
PMCP-000 → PMCP-001 → PMCP-002 → PMCP-003
```

Puis fermer le premier jalon réellement utilisable :

```text
PMCP-010 → PMCP-011 → PMCP-012 → PMCP-013
```

Ne pas commencer `tools/pokemap_mcp` avant `PMCP-082`. Un prototype MCP
antérieur peut servir à apprendre, mais ne doit pas devenir une architecture
de production ni porter des règles PokeMap.

La première tranche de mutation recommandée est :

```text
PMCP-020 → PMCP-024 → PMCP-030 → PMCP-031
```

Elle donne rapidement une API capable de créer et modifier des maps par batch,
ce qui répond au besoin initial de réduire le tâtonnement lors de la création
de contenu.

## 18. Parallélisation sûre

Après `PMCP-024`, ces branches sont indépendantes au niveau fonctionnel :

```text
Branche Maps       : PMCP-030 → 035
Branche Assets     : PMCP-040 → 042
Branche Narrative  : PMCP-050 → 053
Branche Pokémon    : PMCP-060
```

Contraintes :

- une seule branche modifie un contrat transversal à la fois ;
- toute extension du registre passe par review de compatibilité ;
- les branches n’ajoutent pas leur propre transaction, erreur ou receipt ;
- les migrations `map_editor` attendent les domaines stabilisés ;
- les lots MCP attendent la parité éditeur et runtime requise.

## 19. Lots explicitement hors de cette roadmap

Cette roadmap ne crée pas :

- un nouvel éditeur de cartes mondial sans modèle `worldLayout` approuvé ;
- une dépendance runtime à Tiled, RMXP ou un SDK Pokémon externe ;
- un moteur LLM à l’intérieur de PokeMap ;
- une API de clics/pixels comme contrat métier ;
- une capacité gameplay absente de la roadmap mécanique ;
- une synchronisation cloud ou multi-utilisateur temps réel ;
- une publication publique automatique sans release gate ;
- un shell arbitraire exposé à l’agent.

Ces sujets exigent des specs et plans séparés.

## 20. Roadmap mécanique

Les lots PMCP exposent et prouvent les mécaniques, mais ne remplacent pas leurs
lots `FG-*`.

| Domaine PMCP | Lots FG principalement concernés |
|---|---|
| New Game, save, party, PC | `FG-010` à `FG-030` |
| Battle et progression | `FG-040` à `FG-053` |
| Bag, shops et soins | `FG-060` à `FG-073` |
| Commands et Event authoring | `FG-080` à `FG-094` |
| Encounters | `FG-100` à `FG-108` |
| Field moves | `FG-120` à `FG-129` |
| Trainer et progression narrative | `FG-140` à `FG-147` |
| Menus runtime | `FG-160` à `FG-165` |
| Readiness et Golden Slice | `FG-180` à `FG-185` |

À la fin de chaque lot, le rapport indique seulement si les lots FG pertinents
restent `TODO`, `PARTIAL`, `BLOCKED` ou peuvent être proposés `DONE` avec
preuves fraîches.

## 21. Self-review de la décomposition

### Couverture du catalogue

- contrats et registre : `PMCP-000` à `003` ;
- workspace, query et références : `PMCP-010` à `013` ;
- dry-run, CAS, recovery, permissions et undo : `PMCP-020` à `024` ;
- maps et rendu : `PMCP-030` à `035` ;
- assets et présentation : `PMCP-040` à `042` ;
- narration : `PMCP-050` à `053` ;
- Pokémon et gameplay : `PMCP-060` à `063` ;
- playtest, readiness et package : `PMCP-070` à `072` ;
- éditeur et MCP : `PMCP-080` à `085`.

### Cohérence

- aucune dépendance inverse depuis un package métier vers `map_authoring` ;
- aucune règle métier dans l’adaptateur MCP ;
- aucun lot MCP avant le gate SDK ;
- aucun lot de mutation avant le noyau de transaction ;
- aucune revendication `100 %` avant la parité éditeur/runtime/MCP.

### Limites

- les signatures détaillées sont volontairement laissées aux plans dédiés de
  chaque lot ;
- les commandes Git proposées par le skill ne sont pas exécutées sans
  autorisation explicite ;
- cette roadmap ne modifie aucun statut existant.

## 22. Handoff

Le prochain document à produire est le plan d’implémentation détaillé de
`PMCP-000`, puis `PMCP-001`. L’exécution recommandée suit le mode
subagent-driven avec review de conformité puis review de qualité entre les
lots. Une exécution inline reste possible avec checkpoints après chaque lot.
