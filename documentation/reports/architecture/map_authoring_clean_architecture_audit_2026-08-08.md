# Audit `map_authoring` — architecture, fiabilité et optimisation

Date : 8 août 2026
Lot d'audit : `AUDIT-MAP-AUTHORING-2026-08-08`
Périmètre principal : `packages/map_authoring/`
Snapshot audité : branche `main`, commit `4c7d02d1a739b1bb1de574995706ecce90d75bfd` (`perf(authoring): speed up canonical map saves`)
Nature de la passe : audit read-only du code ; seul ce rapport a été ajouté.

> **Décision postérieure à l'audit :** la règle globale de longueur des fichiers Dart, son cliquet, son hook et sa gate CI ont été retirés le 8 août 2026. Les constats de ce rapport sur le seuil de longueur sont conservés comme historique du snapshot et ne sont plus prescriptifs.

## Verdict exécutif

`map_authoring` possède de **bonnes frontières externes**, mais ne peut pas encore être qualifié de clean architecture stricte ni de package totalement « green ».

- Le package est pure Dart, ne dépend en production que de `map_core`, n'importe ni Flutter, ni Flame, ni `map_editor`, ni `map_runtime`, et ne crée aucun cycle d'import au niveau fichier.
- Le cœur transactionnel est substantiel : CAS, idempotence durable, journal, reprise, autorisation, confirmation et audit sont réellement implémentés et bien testés.
- En revanche, le package mélange domaine, application, composition et infrastructure. Son dispatcher canonique inter-domaines vit dans `domains/maps`, les dépendances entre modules sont bidirectionnelles, et le barrel public expose 94,7 % des fichiers internes.
- Plus grave, certaines garanties affichées ne sont pas celles réellement exécutées : le registre présenté comme gate d'admission n'est pas branché au dispatcher canonique ; la « full parity » est largement auto-déclarée ; les inventaires de ressources divergent selon le registre, les mutations, la lecture, `describe()` et PMCP-085.
- Deux candidats de vulnérabilité Medium, à forte confiance par inspection source, ont été identifiés : une recovery peut commencer avec un handle expiré, et le ledger d'idempotence ne protège pas ses fichiers contre les symlinks. Leur exploitabilité n'a pas été reproduite dynamiquement.
- L'analyse statique passe et la suite passe en série, mais la suite concurrente a produit des échecs non déterministes. Le gate de longueur annoncé à 3 000 lignes vérifie actuellement 30 000 lignes.

Verdict : **PARTIAL — architecture viable, corrections P1 requises avant de considérer les garanties de sécurité, de gouvernance et de parité comme fiables.** Aucun P0 n'a été établi. Aucun exploit mutateur n'a été exécuté pendant cet audit read-only.

## 1. Méthode et critères

L'audit a combiné :

1. inventaire reproductible du snapshot Git ;
2. graphe des imports internes et externes ;
3. inspection des ports, contrats, composition roots, registres et barrels ;
4. analyse des chemins de mutation, recovery, idempotence et audit de sécurité ;
5. tests statiques, ciblés, complets, séquentiels et concurrents ;
6. compilation du CLI et validation du serveur MCP ;
7. interrogation live de `pokemap_describe` et de ressources annoncées/non annoncées ;
8. mesure légère du snapshot et rapprochement avec les preuves de performance existantes ;
9. vérification des consommateurs editor, runtime et distribution quand nécessaire pour juger la parité ;
10. passes indépendantes Architecture, Tests/Sécurité et Parité/Performance, suivies d'une critique finale.

La conformité a été jugée sur la direction des dépendances, la séparation des responsabilités, l'honnêteté des contrats exposés, la sécurité des frontières, la preuve par les tests et le coût de maintenance. Le nombre de fichiers ou de lignes de test n'est **pas** traité comme un taux de couverture : aucun rapport LCOV exhaustif n'a été produit.

## 2. Snapshot et inventaire

### État Git initial

```text
?? documentation/reports/editor/plans/wm_conn_01_inter_map_connections_implementation_plan.md
```

Le diff initial de `packages/map_authoring` par rapport à `HEAD` était vide.

### Inventaire reproductible du package

| Mesure | Valeur |
|---|---:|
| Fichiers Dart sous `lib/` | 134 |
| Lignes Dart sous `lib/` | 44 692 |
| Fichiers Dart sous `test/` | 77 |
| Fichiers `*_test.dart` | 75 |
| Lignes Dart sous `test/` | 24 232 |
| Appels statiques `test(...)` | 415 |
| Tests exécutés par la suite complète | 435 |
| Fichiers source dépassant 500 lignes | 29 |
| Fichiers source dépassant 1 000 lignes | 5 |
| Fichiers source dépassant 3 000 lignes | 0 |

La différence entre 415 appels statiques et 435 cas exécutés vient notamment des tests générés ou déclarés dynamiquement ; elle ne constitue pas une anomalie.

### Répartition principale

| Zone | Fichiers | Lignes |
|---|---:|---:|
| `api` | 3 | 943 |
| `contracts` | 16 | 3 268 |
| `domains/assets` | 12 | 4 912 |
| `domains/distribution` | 1 | 354 |
| `domains/gameplay` | 5 | 1 166 |
| `domains/maps` | 25 | 14 992 |
| `domains/narrative` | 16 | 4 087 |
| `history` | 6 | 2 293 |
| `ports` | 7 | 1 529 |
| `registry` | 3 | 629 |
| `security` | 7 | 1 326 |
| `transactions` | 12 | 3 410 |
| `workspace` | 9 | 2 932 |

## 3. Ce qui est réellement conforme

### Frontières de package

- `pubspec.yaml` ne contient qu'une dépendance de production : `map_core`.
- `test/package_boundary_test.dart` interdit les imports Flutter, Flame, editor et runtime et vérifie le manifeste.
- Aucun package consommateur n'importe `package:map_authoring/src/...` ; deux tests internes seulement le font volontairement.
- Le graphe mesuré contient 134 fichiers et 446 imports internes, sans cycle d'import entre fichiers ni cycle de package.
- `MapAuthoringPackageBoundaries` définit correctement les responsabilités possédées par le package et celles laissées aux adaptateurs editor/runtime/MCP.

### Transactions et sécurité

Les mécanismes suivants sont concrets, pas de simples interfaces :

- planification et dry-run ;
- CAS avant promotion ;
- journal durable et checkpoints de fault injection ;
- idempotence durable et concurrence ;
- recovery et compensation ;
- historique/undo ;
- autorisation par acteur et permissions ;
- confirmations liées au plan et one-shot ;
- redaction récursive ;
- audit hash-chain et écritures concurrentes.

Les tests ciblés couvrent notamment les corruptions de stages, revisions conflictuelles, traversals, parents symlinkés pour les ressources transactionnelles, replay et crash recovery.

### Composition et transports

- Le CLI et le worker JSONL utilisent la même API locale et le même dispatcher que l'API Dart.
- `pokemap_describe` publie bien 229 descriptors d'actions, consommables via les outils MCP génériques.
- Les adaptateurs editor, render et playtest existent et évitent une dépendance inverse vers Flutter/Flame.
- Les imports Tiled restent des capacités d'import de données ; Tiled n'est pas une dépendance runtime.

## 4. Findings priorisés

### P1 — Les sources de vérité et la certification PMCP sont incohérentes

Il n'existe pas aujourd'hui une source de vérité unique pour les ressources :

| Inventaire | Nombre / contenu constaté |
|---|---|
| `AuthoringResourceKindRegistry.canonicalMinimal()` | 30 IDs |
| Union des `resourceKind` des mutations | 28 IDs |
| Kinds gérés par `ProjectQueryService` | 20 IDs |
| Kinds publiés par `AuthoringReadApi.describe()` | 12 IDs |
| Matrice PMCP-085 `fullParity` | 62 concepts sémantiques regroupés sous des owners canoniques |

Trois kinds utilisés par les mutations ne sont pas dans le registre : `preset`, `tileLayer`, `tileset`. À l'inverse, plusieurs kinds du registre n'apparaissent pas dans les mutations. Le service de lecture sait interroger huit kinds non publiés par `describe()` : `dialogue`, `script`, `scene`, `eventV2`, `fact`, `worldRule`, `storyline` et `scenario`.

Ces inventaires n'ont pas tous le même niveau d'abstraction : PMCP-085 décrit 62 concepts sémantiques, par exemple `mapLayer → map`, `gamePackage → project` et `shop → campaignContent`, alors que `describe()` et `ProjectQueryService` exposent des kinds de requête. L'inégalité des nombres n'est donc pas une anomalie en soi.

Les incohérences démontrées sont plus précises : huit kinds directement requêtables sont absents de `describe()` ; trois kinds de mutation sont absents du registre ; des owners PMCP tels que `campaignContent` et `pokemonDocument` ne sont pas requêtables ; et les preuves PMCP déclaratives ne démontrent pas l'accès individuel aux sous-ressources.

La vérification live a confirmé que `pokemap_describe` publie 12 kinds et 229 descriptors de mutation, tandis que `fullParity` annonce zéro gap et `catalogComplete: true`. Des requêtes sur `dialogue`, `scene`, `eventV2`, `storyline` et `scenario` réussissent malgré leur absence de `describe()`. À l'inverse, `campaignContent` et `pokemonDocument` sont rejetés avec `query.resource_kind_unsupported`.

La cause structurelle se trouve dans `lib/src/parity/full_authoring_parity.dart:143-160,211-297` : `AuthoringFullParityCatalog.canonical()` affecte mécaniquement `AuthoringTransport.values` aux mutations et construit la plupart des cellules `SUPPORTED` à partir de chaînes d'évidence génériques. Le test `test/parity/full_authoring_parity_test.dart:54-160` vérifie principalement cette déclaration, l'existence de fichiers de test et la relation unidirectionnelle `actions_editor_explicites ⊆ catalogue_canonique`; il n'exécute en direct/JSONL que `map.create` et `presentation.update`.

Impact : un client ne peut pas savoir honnêtement quelles ressources sont interrogeables. Les agents MCP reçoivent une garantie de complétude contredite par le comportement live.

Correction recommandée : créer une définition canonique unique portant identifiant, owner, schéma, capacités de lecture/mutation, transports réellement prouvés et statut, puis générer registre, dispatcher, `describe()`, query routing et matrice depuis cette définition. Séparer explicitement `declared`, `adapter-capable`, `contract-tested` et `end-to-end verified` ; ne produire `SUPPORTED` que depuis une preuve exécutable vérifiée.

### P1 — La gate d'admission des mutations n'est pas branchée

`AuthoringMutationRegistry` est documenté comme une « admission gate preventing partially safe mutation actions from shipping ». Il exige plan, dry-run, stale-CAS, idempotence, recovery, autorisation, receipt et politique undo.

Références : `lib/src/registry/mutation_registry.dart:61-99` et `lib/src/api/local_map_authoring_mutation_api.dart:64-68,83-105`.

Le chemin de production construit pourtant directement `MapMutationDispatcher.canonical()` dans `LocalMapAuthoringMutationApi`, puis publie directement ses descriptors. La recherche du dépôt ne trouve aucun consommateur de production de `AuthoringMutationRegistry` ; son consommateur réel est le test `mutation_gate_test.dart`.

Impact : une nouvelle action peut rejoindre les 229 actions canoniques et être exposée sans passer par la gate présentée comme bloquante. Cela ne prouve pas que les actions actuelles sont dangereuses — le pipeline générique apporte plusieurs garanties — mais la gouvernance annoncée n'est pas effective.

Correction recommandée : fusionner descriptor, factory et preuves d'admission dans l'unique enregistrement canonique, puis refuser la construction du dispatcher si l'admission échoue.

### P1 — Une recovery peut commencer avec un handle expiré

`WorkspaceHandleStore._requireActive()` révoque correctement les handles expirés. En revanche, `LocalMapAuthoringMutationApi._session()` vérifie seulement une map de sessions indépendante. `recover()` autorise ensuite l'opération puis appelle `_recovery.resume()`, qui peut promouvoir les payloads et écrire le journal. Le prochain accès au snapshot, donc la vérification effective du handle, n'arrive qu'après la recovery dans `_receiptResult()`.

Références : `lib/src/workspace/workspace_handle_store.dart:219-234`, `lib/src/api/local_map_authoring_mutation_api.dart:234-243,555-578` et `lib/src/transactions/recovery_service.dart:128-160`.

Prérequis : processus et session encore vivants, handle expiré toujours présent dans `_sessions`, et identifiant d'une transaction pending connu. `history()` présente également un contournement de l'expiration, avec un impact lecture seulement.

Impact candidat : une capability expirée peut encore déclencher une écriture, puis recevoir `workspace.handle_expired` après que le projet a été modifié. La confiance est forte par inspection source, mais l'exploitabilité n'a pas été reproduite dynamiquement.

Correction recommandée : faire valider l'activité du handle au point d'entrée de toute méthode read/mutation/history/recovery et immédiatement avant toute promotion. Ajouter un test avec clock injectée prouvant zéro écriture après expiration.

### P1 — Le ledger d'idempotence suit les symlinks

`FileIdempotencyStore` construit directement `idempotency.jsonl` ainsi que ses fichiers lock, compact et backup. Il crée le parent puis ouvre ces fichiers sans canonicalisation ni contrôle `followLinks: false`. La composition place ce ledger sous `.pokemap/authoring/` dans le projet.

Références : `lib/src/transactions/file_idempotency_store.dart:23-28,135-140,188-228` et `lib/src/api/local_map_authoring_mutation_api.dart:320-327`.

Un projet non fiable peut donc prépositionner le ledger ou un de ses parents sous forme de symlink vers un fichier accessible hors projet. La première réservation y ajoute du JSONL avec les droits du processus. La gateway transactionnelle protège les ressources contre des parents symlinkés, mais cette protection ne s'applique pas au ledger.

Impact candidat : écriture hors racine du projet, limitée aux permissions du processus et au format append JSONL ; sévérité proposée **Medium / CWE-59**. La confiance est forte par inspection source, mais l'exploitabilité n'a pas été reproduite dynamiquement et suppose l'ouverture d'un projet contrôlé par un tiers.

Correction recommandée : réutiliser une primitive de chemin canonique commune pour tous les stores `.pokemap`, refuser chaque composant symlinké et ouvrir les fichiers de façon sûre. Ajouter des tests sur le fichier final, le parent et les fichiers auxiliaires.

### P1 transversal — La gate de 3 000 lignes vérifie 30 000 lignes

`AGENTS.md` et le workflow CI annoncent une limite bloquante de 3 000 lignes. `tools/check_file_length.dart` définit pourtant `_limit = 30000`. La commande réussit donc avec le message « no file over 30000 lines » et ne protégerait pas contre un nouveau fichier de 4 000 lignes.

Référence : `tools/check_file_length.dart:16`.

Le package audité respecte malgré tout la vraie règle : son maximum est 1 450 lignes.

Correction recommandée : remettre le seuil à 3 000, vérifier la sémantique de la baseline et ajouter un test unitaire du checker autour de 2 999/3 000/3 001.

### P2 — La suite concurrente est flaky

Plusieurs résultats ont été observés : `+433 -2` sur une passe complète, `+434 -1` sur une autre, puis `+435` sur une répétition concurrente ; la suite séquentielle passe à `+435`. Les relances isolées ne sont elles-mêmes pas uniformes selon la charge. Cette variance, plutôt qu'un résultat unique, établit la flakiness. Parmi les échecs observés :

- `smart_tiles_rich_authoring_scaling_cli_test.dart: rejects unsupported extents and escaped output` ;
- `cli_golden_test.dart: ... runs the real authoring JSONL session with read API parity`.

Les deux fichiers repassent isolément, et la suite complète en série passe à `+435`. D'autres répétitions ont également montré un timeout du test CLI. Celui-ci impose un délai fixe de 10 secondes au premier retour stdout alors qu'il démarre un processus Dart ; la probe directe a pris environ 6,2 secondes sans forte contention.

Impact : statut CI non déterministe et signal de régression dégradé.

Correction recommandée : précompiler/réutiliser le binaire dans les tests de transport, séparer startup et timeout de protocole, terminer explicitement les processus en échec et donner aux benchmarks process-spawning un timeout cohérent.

### P2 — L'échec de l'audit après commit n'est pas rejouable comme annoncé

Pour les mutations destructives, la confirmation one-shot est consommée pendant l'autorisation, avant la transaction. Si le commit réussit mais l'append de l'audit échoue, le commentaire de `SecureAuthoringMutationExecutor` affirme que le caller peut rejouer avec la même clé d'idempotence. Or le retry repasse d'abord par l'autorisation et peut échouer avec `confirmation.used`; générer une nouvelle confirmation peut également être bloqué par le plan devenu stale.

Référence : `lib/src/security/secure_mutation_executor.dart:59-87,122-140`.

Impact : le projet peut être effectivement modifié alors que le caller reçoit une erreur et que le chemin de récupération annoncé ne fonctionne pas par `apply`.

Correction recommandée : définir un résultat durable « committed / audit pending », rendre sa récupération explicite par operation ID, ou consulter l'idempotence avant une nouvelle consommation de confirmation. Ajouter le scénario exact en test.

### P2 — Les recoveries mutantes ne produisent pas d'événement d'audit

Le modèle prévoit `AuthoringSecurityOperation.recover`, mais `recover()` appelle directement le service de recovery après autorisation. Une reprise peut écrire journal, ressources, historique et idempotence sans passer par `AuthoringAuditLog`.

Correction recommandée : auditer tentative, refus, succès et échec de recovery avec operation ID et receipt, sans exposer de chemins sensibles.

### P2 — La composition inter-domaines est placée dans `domains/maps`

`map_mutation_dispatcher.dart` importe assets, gameplay et narrative puis compose leurs handlers. En sens inverse, ces domaines utilisent plusieurs abstractions et helpers de maps. Aucun cycle fichier n'existe, mais le graphe par modules montre des dépendances bidirectionnelles, notamment domains/workspace, history/transactions, ports/transactions, ports/workspace et transactions/workspace.

Références principales : `lib/src/domains/maps/map_mutation_dispatcher.dart:3-39,60-259` et `lib/src/ports/transaction_file_gateway.dart:1-8`.

Le dossier `ports` contient aussi des implémentations concrètes (`LocalProjectFileReader`, stores mémoire/local), et `transaction_file_gateway.dart` dépend d'un modèle du dossier `transactions`, alors que les transactions dépendent du port.

Correction recommandée : déplacer la composition canonique dans une couche `application` ou `api/composition`, extraire les types partagés vers contracts et réserver `domains/maps` aux règles et use cases de maps.

### P2 — La façade publique est trop large et trop orientée JSON

`map_authoring.dart` exporte 126 des 133 fichiers sous `src/`, soit 94,7 %, incluant stores fichiers, transactions, caches, audit et worker JSONL. Les ports directs retournent des `Map<String, Object?>`, ce qui force l'éditeur à refaire des casts et validations par clés malgré l'existence de contrats typés.

Le package étant interne (`publish_to: none`), ce risque reste de maintenabilité et d'évolution plutôt qu'une rupture publique immédiate.

Correction recommandée : introduire une façade Dart typée, confiner le wire JSON au CLI/MCP, puis réduire progressivement le barrel avec une stratégie de migration.

### P3 — Le package n'est pas portable Web

Huit fichiers de production importent `dart:io`, dont plusieurs implémentations exportées par le barrel. Le package est donc pure Dart au sens « sans Flutter », mais pas portable Web. C'est acceptable si sa cible reste desktop/server ; si le Web devient une cible, les adaptateurs IO devront être isolés derrière des barrels conditionnels ou un package d'infrastructure. Cette contrainte n'est pas classée comme défaut actuel faute d'objectif Web identifié.

### P2 — Schémas et capacités sont nommés mais pas réellement publiés

Les descriptors de mutations transportent des identifiants de schéma, mais `AuthoringSchemaDescriptor` et `AuthoringCapabilityDescriptor` n'ont pas de registre canonique consommé en production. `pokemap_describe` ne publie pas les corps de schéma ; les outils MCP reçoivent un objet de paramètres générique.

Impact : validations tardives, documentation agent incomplète et difficulté à générer des formulaires ou appels sûrs.

Correction recommandée : lier chaque action à un schéma versionné réellement résolu et exposer exemples, champs obligatoires, enums et contraintes dans `describe()`/MCP.

### P3 — Refactorer les hotspots selon la concentration et le churn

| Fichier | Lignes | Signal |
|---|---:|---|
| `environment_actions.dart` | 1 450 | classe 541 lignes, `build()` ~295 lignes |
| `tiled_map_import_actions.dart` | 1 426 | parsing, validation et orchestration concentrés |
| `smart_tile_catalog_actions.dart` | 1 263 | classe ~628 lignes |
| `border_actions.dart` | 1 184 | classe ~686 lignes, `build()` ~480 lignes |
| `region_operations.dart` | 1 118 | classe ~573 lignes |
| `project_query_service.dart` | 994 | routage de 20 kinds et projection |
| `warp_connection_actions.dart` | 987 | orchestration importante |
| `map_lifecycle_adapter.dart` | 985 | adaptation et lifecycle combinés |

Les hotspots les plus modifiés sur les 200 derniers commits incluent toutefois le barrel (43 changements), le dispatcher (24), le registre de ressources (14), la full parity (11), le query service (10) et le snapshot loader (10). Le premier refactoring doit donc viser les sources de vérité et les frontières, pas seulement couper les deux fichiers les plus longs.

Refactorings proposés : extraire validateurs et builders purs, garder les actions publiques comme orchestrateurs courts, caractériser le comportement avant déplacement et éviter une auto-discovery magique qui rendrait le catalogue moins explicite.

## 5. Parité réelle par consommateur

| Consommateur | Verdict | Preuve et limite |
|---|---|---|
| API Dart directe | `PARTIAL` | 229 mutations dispatchées ; façade JSON ; lecture réelle 20 kinds, `describe()` 12. |
| JSONL / CLI | `SUPPORTED` ciblé | Même API/dispatcher ; 33 tests tooling verts ; équivalence concrète non exhaustive. |
| Éditeur | `PARTIAL` | Adaptateurs génériques et 27 tests ciblés verts ; disponibilité UX des 229 actions non démontrée. |
| MCP | `PARTIAL` | Serveur live, 229 actions et 36/36 tests Node ; ressources et preuves de transports incohérentes. |
| Runtime | `PARTIAL` | Tests render/playtest ciblés verts ; chemin playtest MCP distinct du `RuntimePlaytestPort`. |
| `map_authoring` / distribution | `N/A — correctement délégué` | Port abstrait côté authoring ; packaging concret hors package. |
| Chaîne downstream distribution/runtime | `BLOCKED` hors périmètre principal | Deux E2E rouges et six tests de fixtures externes manquantes. |

Le domaine `distribution` minimal de `map_authoring` n'est pas à lui seul un défaut : le packaging concret appartient à `map_distribution` et à ses adaptateurs. De même, les catalogues `BattleActions`, `ProgressionActions` et `SandboxPlayerStateActions` sont des descripteurs réservés, pas une preuve que les mécaniques doivent être implémentées dans `map_authoring`. Leur statut réservé/non exécutable doit simplement être explicite.

## 6. Tests, build et performances

### Résultats frais — `map_authoring`

| Commande | Résultat exact |
|---|---|
| `dart analyze` | exit 0 — `No issues found!` |
| `dart test test/package_boundary_test.dart test/parity/full_authoring_parity_test.dart` | 9/9 passent |
| `dart test` | exit 1 — `+433 -2`; deux échecs intermittents |
| relance isolée des deux fichiers fautifs | 6/6 passent |
| `dart test --concurrency=1` | exit 0 — `+435: All tests passed!` |
| suite ciblée security/transactions/workspace/tooling | `+83`, cinq répétitions vertes |
| `dart run tool/pmcp085_conformance.dart` | 62 ressources, 229 mutations, 0 cellule déclarée bloquée/manquante |
| `dart compile exe bin/pokemap_authoring.dart -o /tmp/pokemap_authoring_audit_4c7d02d1` | exit 0 — binaire généré |

### MCP et consommateurs

| Commande / suite | Résultat |
|---|---|
| `tools/pokemap_mcp`: `npm run check && npm test` | exit 0 — TypeScript vert, 36/36 tests |
| tests editor ciblés | 27/27 passent |
| tests runtime ciblés | 9/9 passent |
| exemples runtime ciblés | 5 passent, 2 échouent |
| `packages/map_distribution`: `dart analyze` | exit 0 |
| `packages/map_distribution`: `dart test` | 75 passent, 6 échouent sur fixtures de rapport absentes |

### Gates de dépôt et rapport

| Commande | Résultat exact |
|---|---|
| `dart tools/check_file_length.dart` | exit 0 — mais message et seuil réels à 30 000, donc preuve invalide pour la règle 3 000 |
| comptage direct des fichiers `map_authoring` | maximum 1 450 lignes ; aucun dépassement de 3 000 |
| `git diff --check -- documentation/reports/architecture/map_authoring_clean_architecture_audit_2026-08-08.md` | exit 0 |
| `bash tools/scripts/check_markdown_hygiene.sh` | exit 1 — deux nouveaux Markdown pour une limite par défaut à zéro : ce rapport demandé et le plan editor non suivi préexistant |

Les deux échecs E2E runtime reproductibles sont distincts de l'architecture interne de `map_authoring` : l'identité package attend `v2` alors que le fixture est `v6`, et le fixture Selbrume reste `v2` alors que le runtime Smart Tile exige `v6`. Ils empêchent néanmoins de qualifier la chaîne consommateur de verte.

### Performance

Une mesure fraîche sur le petit fixture `golden_fangame_slice` a produit 12 runs, quatre ressources, une médiane totale d'environ 3,2 ms et un spread de 701 %. Cette fixture est trop petite et le spread trop élevé pour généraliser un budget de production.

Le rapport historique STN-11 contient une mesure sur 1 024 × 1 024 : plan p50 2,276 s, apply 7,408 s, reopen 1,683 s, recovery 10,318 s, RSS snapshot 860 618 752 octets. Ces valeurs restent des preuves historiques JIT, pas une mesure fraîche du commit audité.

Les receipts sous `packages/map_authoring/build/performance/` sont ignorés par Git, datent du 5 août, mentionnent un autre commit et `treeState: dirty`. Le vérificateur accepte pourtant ces receipts avec et sans timing parce qu'il ne lie pas la preuve au commit, au fingerprint du code, au SDK, à la machine ou à la fraîcheur.

Recommandation : rendre les receipts auto-descriptifs et refuser par défaut une preuve provenant d'un autre commit, tout en conservant un mode explicite de comparaison historique.

## 7. Plan correctif proposé

| Ordre | Lot proposé | Contenu | Done criteria minimaux |
|---:|---|---|---|
| 1 | `MA-AUTH-SEC-01` | Fermer le bypass d'expiration sur recovery/history | tests clock-expiry, aucune écriture/lecture après expiration, suite security verte |
| 2 | `MA-AUTH-SEC-02` | Sécuriser tous les stores `.pokemap` contre les symlinks | tests fichier/parent/auxiliaires, racine canonique commune |
| 3 | `MA-AUTH-REG-01` | Unifier ressources, actions, schémas, query et describe | une source de vérité ; live describe = query = matrice ; gaps explicites |
| 4 | `MA-AUTH-GATE-01` | Brancher la mutation admission gate et corriger le checker 3 000 | action non admise impossible à dispatcher ; tests 2 999/3 000/3 001 |
| 5 | `MA-AUTH-AUDIT-01` | Rendre commit/audit/retry/recovery cohérents | scénario audit-failure high-risk et audit recovery couverts |
| 6 | `MA-AUTH-TEST-01` | Stabiliser les tests process-spawning | 10 suites concurrentes consécutives vertes, aucun child orphelin |
| 7 | `MA-AUTH-ARCH-01` | Déplacer composition et introduire façade typée | dispatcher hors domaine maps, dépendances modules dirigées, migration documentée |
| 8 | `MA-AUTH-PERF-01` | Lier les receipts de performance au snapshot | commit/fingerprint/SDK/fraîcheur contrôlés, benchmark large rerun |
| 9 | `MA-AUTH-HOTSPOTS-01` | Extraire les méthodes concentrées par petits lots | tests de caractérisation, aucune rupture de barrel/transport |

Chaque lot doit rester chirurgical. Les deux lots sécurité et le lot registre ont plus de valeur que le découpage cosmétique immédiat des gros fichiers.

## 8. Roadmap, décisions et non-objectifs

- Aucun statut de la roadmap fangame n'est modifié par cet audit.
- Les lots mécaniques `FG-080` à `FG-093` ainsi que les preuves runtime associées doivent conserver leur statut courant jusqu'à des preuves fraîches ; cet audit ne propose aucun `DONE`.
- Le package `map_authoring` ne doit pas absorber les règles gameplay de `map_gameplay`, le moteur de `map_battle`, le rendu de `map_runtime` ni le packaging concret de `map_distribution`.
- Aucun refactoring, fix sécurité, changement de schéma, changement de roadmap ou opération Git n'a été effectué.

## 9. Fichier créé et zones pertinentes

| Fichier | Zones ajoutées |
|---|---|
| `documentation/reports/architecture/map_authoring_clean_architecture_audit_2026-08-08.md` | verdict, méthode, inventaire, conformité, findings P1/P2/P3, parité, commandes, performance, plan correctif, Git et auto-critique |

Diff de cette passe : ajout d'un rapport consolidé uniquement. Aucun fichier de `packages/map_authoring`, test ou source consommateur n'a été modifié.

## 10. Verdicts des passes indépendantes

| Passe | Verdict |
|---|---|
| Audit / Architecture | `PARTIAL` — frontières package propres ; gate inactive, composition inter-domaines et API publique à corriger |
| Implémentation | `N/A` — audit read-only, aucune correction demandée dans cette passe |
| Tests / Fiabilité | `PARTIAL` — suite série verte, concurrence flaky |
| Sécurité | `CORRECTIONS REQUISES` — deux risques Medium source-backed |
| Build du package | `GREEN` — analyse et compilation vertes |
| Fiabilité | `PARTIAL` — suite concurrente flaky et gate 3 000 invalide |
| Intégration downstream | `BLOCKED/PARTIAL` — E2E et fixtures externes au package |
| Parité / Performance | `PARTIAL` — transports présents, preuve PMCP-085 et receipts performance trop permissifs |
| Critique finale | `PARTIAL crédible après corrections` — séparer concepts PMCP/kinds requêtables et package/downstream ; deux candidats Medium restent à valider dynamiquement |

## 11. Limites et auto-critique

- Aucun fuzzing, test de pénétration dynamique, mutation testing ou profilage mémoire natif n'a été exécuté.
- Les deux candidats sécurité sont établis avec une forte confiance par le chemin source et l'absence de garde, mais aucun exploit n'a été exécuté afin de garder l'audit read-only.
- L'audit ne fournit pas de pourcentage de couverture. Les qualificatifs de robustesse reposent sur les scénarios observés, pas sur le volume de tests.
- Les mesures de performance fraîches utilisent une petite fixture ; les mesures larges sont historiques et doivent être rerun après stabilisation.
- Les checks editor/runtime/distribution ont été ciblés ou transversaux ; ils ne constituent pas une certification complète de ces packages.
- La classification Clean Architecture dépend des frontières attendues. Ici, le package est mieux décrit comme une couche d'application hexagonale pure Dart que comme un domaine métier strict.
- Des modifications concurrentes sont apparues dans `packages/map_editor` pendant l'audit. Elles n'ont pas été inspectées comme faisant partie du snapshot principal et ne doivent pas être attribuées à cette passe.

## 12. Commandes de preuve

Les commandes utiles exécutées incluent :

```text
git status --short --untracked-files=all
git diff --name-status HEAD -- packages/map_authoring
git log -1 --format=...
rg --files packages/map_authoring/lib packages/map_authoring/test
wc -l sur les sources et tests Dart
analyse Tarjan des imports internes et agrégation des dépendances par module
rg des registres, descriptors, schémas, ressources, imports `src/` et action IDs

cd packages/map_authoring && dart analyze
cd packages/map_authoring && dart test
cd packages/map_authoring && dart test --concurrency=1
cd packages/map_authoring && dart test <suites ciblées>
cd packages/map_authoring && dart run tool/pmcp085_conformance.dart
cd packages/map_authoring && dart compile exe bin/pokemap_authoring.dart -o /tmp/pokemap_authoring_audit_4c7d02d1
cd packages/map_authoring && dart run tool/measure_snapshot_cost.dart ...

cd tools/pokemap_mcp && npm run check && npm test
interrogations live pokemap_describe, pokemap_open_workspace, pokemap_query et pokemap_close_workspace
tests ciblés packages/map_editor et packages/map_runtime
tests ciblés examples/playable_runtime_host
cd packages/map_distribution && dart analyze && dart test

dart tools/check_file_length.dart
bash tools/scripts/check_markdown_hygiene.sh
```

Les résultats exacts significatifs sont consignés dans les sections 6 et 10. Les sorties volumineuses n'ont pas été ajoutées au dépôt.

## 13. État Git final

Le diff final de `packages/map_authoring` par rapport à `HEAD` reste vide. L'unique fichier créé par cette passe est le présent rapport.

```text
 M packages/map_editor/lib/src/app/providers/editor/editing_service_providers.dart
 M packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart
 M packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.g.dart
 M packages/map_editor/lib/src/application/services/map_connection_editing_service.dart
 M packages/map_editor/lib/src/application/use_cases/map_connection_use_cases.dart
 M packages/map_editor/lib/src/features/editor/application/world_map_inspector_projector.dart
 M packages/map_editor/lib/src/features/editor/application/world_map_observed_tool_family.dart
 M packages/map_editor/lib/src/features/editor/application/world_map_tool_family.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/adaptive_map_inspector.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_toolbelt.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_workspace_session.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/adaptive_map_inspector_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_toolbelt_test.dart
?? documentation/reports/architecture/map_authoring_clean_architecture_audit_2026-08-08.md
?? documentation/reports/editor/plans/wm_conn_01_inter_map_connections_implementation_plan.md
?? packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_connections_inspector.dart
?? packages/map_editor/lib/src/features/editor/state/editor_notifier_map_connections.dart
?? packages/map_editor/test/application/services/map_connection_editing_service_test.dart
?? packages/map_editor/test/features/editor/presentation/world_map/world_map_connections_inspector_test.dart
```

Tous les changements `packages/map_editor` sont apparus pendant l'audit dans un travail concurrent et n'ont été ni produits ni modifiés par cette passe. Le plan `wm_conn_01...md` était le seul fichier non suivi dans l'état initial. Aucune opération Git d'écriture n'a été effectuée.
