# Fiabilisation de la création et de l’édition de cartes par MCP — plan v2

> **Pour l’agent exécutant :** appliquer `skills/executing-plans/SKILL.md`, ou `skills/subagent-driven-development/SKILL.md` si une exécution déléguée est retenue. Avancer par tâches cochables et lots vérifiés. Ce document décrit du travail à réaliser ; il ne prouve aucune livraison.

**Objectif :** rendre le MCP existant plus simple à découvrir et à utiliser, avec des éditions atomiques, des reprises sûres et des contrôles dont la portée est explicite.

**Architecture :** conserver les API canoniques Dart, les transactions et les outils existants. Ajouter une composition sémantique en mémoire et une façade d’édition ergonomique, sans nouveau moteur transactionnel. Le MCP et JSONL transportent les mêmes contrats ; les règles métier restent dans `map_core` et `map_authoring`.

**Technologies :** Dart, `map_core`, `map_authoring`, worker JSONL, MCP TypeScript, hôte Flutter de rendu 3D.

**Priorité :** chantier 1, à exécuter avant le chantier d’intégration à Studio décrit dans [le second plan](integration_mcp_avelune_studio.md). Ce premier chantier n’attend ni transport réseau ni packaging Studio.

**Date et référence :** 30 octobre 2026. Lecture du dépôt sur `main`, SHA `67b5fd0d6853e7c253d176f3c5f9d524bb3164fe`, avec modifications concurrentes non committées. Revalider les zones touchées avant chaque lot.

---

## 1. Origine, décisions et limites

Ce document reprend le plan de Claude `/Users/karim/Project/plan_fiabilite_creation_cartes_pokemap.md` et la revue contradictoire acceptée dans la conversation. Le fichier original reste intact. La v2 remplace ses prescriptions d’exécution pour ce chantier.

Les nouveautés déjà réalisées par Claude restent acquises : diagnostics Border, requêtes d’intégrité, aperçus avant/après, scans et rendus 3D. Les idées encore proposées restent à implémenter ; ne pas les présenter comme existantes.

Correspondance avec le plan original :

| Plan original | V2 | Évolution principale |
| --- | --- | --- |
| 0 — référence | R0 | Variantes indépendantes, oracles propres aux tâches, baseline LLM comparable |
| D — découverte | R1 | Avancé ; schémas réels, détail à la demande, profil utilisable |
| A.5 — façade/reprises | R2 puis R3 | Identité logique explicite et résultat durable avant les reprises automatiques |
| A — batch/gardes | R3 | Transformations en mémoire, une finalisation, coût instrumenté |
| B — bilan | R4 | Révision, couverture, `pass` / `fail` / `incomplete` |
| C — intentions | R5 | Ambiguïté explicite, vraie résolution Border, création minimale couverte |
| E — banc LLM | R6 | Répétitions, variantes réservées, mêmes modèles avant/après |
| F — skills | R7 | Simplification uniquement après preuve des nouvelles capacités |

Hors périmètre : intégration au démarrage de Studio, nouveau transport réseau, packaging embarqué, refonte générale des sessions ou historiques Studio, reconstruction de Route32, modification de HeartGold, nouvelles mécaniques de jeu, migrations des formats de jeux ou de sauvegardes.

Le périmètre de création couvre une carte dans un projet valide disposant d’un catalogue de ressources utilisables. La création d’assets, l’import automatique de bibliothèques et la génération d’un jeu entier ne font pas partie de ce plan.

## 2. Audit initial : preuves et réutilisation

| Zone existante | Source | Conséquence pour la v2 |
| --- | --- | --- |
| Intégrité et delta | `packages/map_core/lib/src/operations/spatial_map_integrity.dart` | Réutiliser ; filtrer explicitement les `exposed` ; comparer les slots pour l’aggravation des collisions |
| Aperçu des actions | `packages/map_authoring/lib/src/domains/maps/semantic_map_action_support.dart` | Chaque draft actuel encode et inspecte ; ne pas enchaîner ces enveloppes dans le batch |
| Projection de snapshot | `packages/map_authoring/lib/src/workspace/project_snapshot.dart` | `projectMapResources` existe mais exige octets/fingerprints cohérents ; réserver aux projections finales |
| Dispatch | `packages/map_authoring/lib/src/application/map_mutation_dispatcher.dart` | Garder le registre canonique ; partager les transformations avec les actions isolées |
| Matérialisation multiple | `packages/map_authoring/lib/src/domains/maps/border_materialization_batch_actions.dart` | Réutiliser la résolution spatiale et sa limite de features |
| Sélection ciblée | `packages/map_authoring/lib/src/workspace/catalog/catalog_spatial_map_selection.dart` | Dépendances carte + paramètres imbriqués ; chaque sous-action reste à admettre explicitement |
| Fingerprint d’idempotence | `packages/map_authoring/lib/src/support/authoring_fingerprint.dart` | Inclut révision, `dryRun`, extensions ; ne pas modifier ce contrat global pour la nouvelle façade |
| Identité durable | `packages/map_authoring/lib/src/transactions/file_idempotency_store.dart` | Réutiliser les pointeurs par `operationId` et `lookupOperation` |
| Transactions/reçus | `packages/map_authoring/lib/src/transactions/journaled_transaction.dart` | Conserver réservation, journal, préconditions et application atomique |
| Statut et projection | `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart`, `authoring_result_projection.dart` dans le même dossier | Réutiliser `recoveryStatus` et la projection du reçu ; compléter étroitement les métadonnées si nécessaire |
| Catalogue MCP | `tools/pokemap_mcp/src/tools/read_only.ts`, `server.ts` | `describe` sans filtres, toutes les familles enregistrées ; ajouter sans retirer le contrat par défaut |
| Délais MCP | `tools/pokemap_mcp/src/authoring_client.ts`, `config.ts`, `index.ts` | Le client impose ses délais au CLI ; modifier seulement le défaut Dart ne suffit pas |
| Rendu/scan | `tools/pokemap_render_host/lib/src/render_host.dart`, `render_request.dart` | Révision, erreurs et cibles omises existent ; `holeRatio` n’est qu’un détecteur de fond visible enfermé |

Constats fraîchement vérifiés pendant la revue, à dater plutôt qu’à figer dans un test : `describe` vivant répond `ok=true`, 467 actions, 77 ressources, environ 1,06 Mo de données sérialisées. Le serveur issu des sources publie 57 outils pour 138 707 octets de `listTools`. Parmi les 78 actions préfixées `map3d.`, `border_layer.` ou `smart_tile.`, 40 seulement publient un `extensions.inputSchema`.

Les 30 appels de réparation Route32, les durées de 24 à 56 ms d’inspection et les échecs de suites du document original sont des observations historiques, non des mesures recertifiées ici. Ne pas déclarer un échec « préexistant » sans reproduction sur l’état d’entrée du lot.

## 3. Règles communes d’exécution

- Lire `AGENTS.md`, `codex_rule.md`, les règles plus proches et `skills/using-pokemap-mcp/SKILL.md` avant l’exécution. Les consignes utilisateur priment, notamment l’absence de commentaires dans le code sauf demande explicite.
- Aucun Git write sans demande explicite. Si autorisé, ne sélectionner que les chemins et hunks du lot, après inspection des modifications concurrentes ; un chemin explicite contenant du travail étranger ne suffit pas à rendre son ajout sûr.
- Continuer le suivi dans le contexte Notion existant, domaine unique « Systèmes transverses », ticket `409197a7-bfa5-8124-881b-e1cbf0c1a5b2`. Synchroniser les preuves par lot ; `TO REVIEW` en fin de livraison, `DONE` réservé à Yoahn. Ne pas reprendre l’exception Notion du document de Claude comme instruction utilisateur pour Codex.
- Aucun changement de format de projet, package de jeu ou sauvegarde prévu. Si une métadonnée opérationnelle de journal/reçu évolue pour R2, la versionner ou la rendre additive à sa frontière, conserver les lecteurs existants et tester les anciens enregistrements. Ne pas promettre « aucun format persistant modifié » avant cet examen.
- Ne jamais écrire HeartGold pour les essais. Tests sur fixtures classiques et catalogue synthétiques. Une mesure facultative sur projet réel est séparée, en lecture seule, et ne constitue pas une recette d’écriture.
- Artefacts jetables sous `/Users/karim/Library/Caches/AveluneQA/mcp-map-reliability/`, une seule arborescence réutilisée. Avant création, consigner chemins, but, PID et condition de suppression dans le reçu de tâche. Supprimer les environnements et processus possédés en fin de run ; conserver seulement les résultats compacts nécessaires.
- Pour chaque run Flutter, enregistrer PID du runner et descendants pendant l’exécution ; ne terminer que les restes dont commande et filiation sont revérifiées. Aucun kill par nom.
- Ne créer aucun Markdown supplémentaire pendant l’exécution ; résultats en chat, ticket existant et petits reçus JSON si nécessaires. Ce plan et celui d’intégration sont les deux documents explicitement demandés.
- Aucun soak, banc LLM ou nouveau runner macOS coûteux en CI. Les certifications longues sont locales et facultatives.

### Contrat de coût

Pour une édition locale simple : retour visible dans 100 ms et persistance durable dans 500 ms sur projet représentatif documenté, première opération et opérations répétées mesurées séparément, machine et build précisés. Le headless mesure réponse, préparation, application et persistance ; une absence de UI à ce stade n’est pas une certification UI.

Les frontières de stockage sont la carte concernée, ses références réellement nécessaires et les métadonnées transactionnelles ciblées. Aucun parcours des cartes étrangères, rechargement de projet, rejeu complet d’historique ou préparation globale cachée sur le premier edit. La préparation nécessaire à l’admission d’un catalogue reste une opération explicite distincte.

Compter lectures, écritures, décodages, encodages de carte, inspections d’intégrité, résolutions Border et invalidations. Faire varier indépendamment cartes étrangères, historique non pertinent et contenu étranger à la région éditée dans la même carte. Ne pas remplacer ces preuves par le seul nombre d’appels MCP. Si une cible échoue, statut `PARTIAL`, cause et mesure explicites ; ne pas augmenter silencieusement le budget.

## 4. R0 — Fixtures, oracles et mesure avant changement

**Fichiers à créer :**

- `packages/map_authoring/test/support/reliability_map_fixture.dart` : variantes classiques/catalogue, ressources synthétiques et racine QA injectable.
- `packages/map_authoring/test/reliability/reference_tasks_test.dart` : scénarios et assertions indépendantes du futur `mapHealth`.
- `tools/pokemap_mcp/bench/map_reliability_cases.ts` : tâches, variantes et critères ; aucun fournisseur LLM nécessaire pour les tests ordinaires.

**Réutiliser :** `test/support/create_working_catalog_fixture.dart`, `test/workspace/catalog_spatial_map_mutation_test.dart`, `test/domains/maps/border_face_ground_warning_actions_test.dart` et `border_materialization_batch_actions_test.dart` dans `packages/map_authoring`.

La carte canonique reste de 24 × 16 cellules : plateau orthogonal, mer, berge remplaçant le sol, objet et ponton synthétiques. Chaque scénario part d’une variante contenant uniquement les défauts nécessaires à son objectif. Une fixture saine et une fixture cumulant les défauts servent de contrôles séparés.

| Cas | Consigne et résultat indépendant |
| --- | --- |
| T1 | Retirer une berge sans perdre son sol ; feature absente, cellules attendues peintes avec le matériau explicite |
| T2 | Réparer une falaise flottante ; aucun diagnostic crown/base concerné et contour attendu |
| T3 | Ajouter une falaise sur une marche ; feature fraîche, orientation attendue, diagnostics structurels absents |
| T4 | Boucher un trou intérieur ; cellules attendues couvertes, aucune modification hors région |
| T5 | Dégager un ponton ; slots réellement en conflit supprimés/suspendus, autres modules préservés |
| T6 | Peindre avec un nom de matériau ; ID attendu résolu, ambiguïté refusée sur variante dédiée |
| T7 | Partir d’un projet valide sans carte de travail ; créer carte/calques, peindre puis poser un relief avec les ressources existantes |
| T8 | Choix de sol ambigu ; aucune écriture, candidats utiles, correction explicite possible |
| T9 | Réponse perdue après application ; retrouver le même résultat sans nouvelle écriture |
| T10 | Même peinture après undo avec une nouvelle identité ; nouvelle application réelle |

- [ ] Écrire les factories par variante et vérifier leurs préconditions avant le scénario ; stocker aucune donnée réelle de HeartGold.
- [ ] Faire passer T1 à T7 avec les outils actuels quand possible, en explicitant les découvertes et résolutions manuelles nécessaires. Un manque réel est une baseline d’échec documentée, jamais un faux vert ou une dispense d’implémentation.
- [ ] Mesurer séparément appels MCP, appels JSONL internes, octets de découverte, travail et latences. Une référence scriptée ne remplace pas la référence LLM.
- [ ] Réserver trois variantes de T3/T6/T7 à la validation finale ; ne pas adapter les descriptions des outils à leur géométrie ou à leurs noms particuliers.
- [ ] Capturer avant R1/R3 les cinq passages de référence par tâche des mêmes modèles configurables qui seront utilisés en R6, avec les mêmes budgets. Cela évite de devoir restaurer une version ancienne au milieu du worktree partagé ; les essais payants restent des exécutions locales explicitement lancées, pas une dépendance de ce plan documentaire.

**Tests négatifs :** carte saine inchangée, mauvais mapId, ressource inconnue, fixture comportant plusieurs défauts sans les confondre avec un succès global. Chaque scénario vérifie absence de modifications étrangères et réouverture des valeurs persistées.

**Validation prévue :** `cd packages/map_authoring && dart test test/reliability/reference_tasks_test.dart` ; résultat attendu : critères par scénario établis et mesures exportables. L’échec de baseline d’une capacité absente est enregistré séparément des tests de validité de fixture.

## 5. R1 — Découverte ciblée, vrais schémas et profil compact

**Modifier :** `packages/map_authoring/lib/src/registry/action_registry.dart`, `resource_kind_registry.dart`, les descripteurs des actions retenues, `src/api/authoring_read_api.dart`, `src/tooling/jsonl_worker.dart` ; `tools/pokemap_mcp/src/tools/read_only.ts`, `config.ts`, `server.ts`.

**Créer :** `packages/map_authoring/lib/src/api/authoring_capability_discovery.dart`, `packages/map_authoring/test/api/authoring_capability_discovery_test.dart`, `tools/pokemap_mcp/test/capability_discovery.test.ts`, `tools/pokemap_mcp/test/map_builder_profile.test.ts`.

Contrat additif : `pokemap_describe({domain?, view?, actionIds?})`, avec les valeurs par défaut historiques équivalentes à `{domain:"all", view:"full"}`. Domaines : `map3d`, `map2d`, `narrative`, `assets`, `battle`, `all`. La classification est explicite et inclut les actions transversales nécessaires ; pas de filtre silencieux par seul préfixe.

Le mode compact expose une liste courte : identifiant, version, résumé, contraintes importantes, disponibilité du schéma et moyen de demander le détail. `actionIds` retourne les vrais schémas d’entrée des actions demandées, les limites, effets, exigences de confirmation et un exemple valide. Un `inputSchemaId` seul n’est pas un schéma. La couverture commence par les actions des scénarios et toute la liste blanche de R3 ; aucune action non couverte n’est annoncée utilisable dans le profil simplifié.

- [ ] Écrire les tests de filtrage, d’inclusion des capacités Smart Tile/Border et de préservation exacte du défaut historique.
- [ ] Compléter les schémas manquants au niveau des descripteurs propriétaires ; faire valider chaque exemple par le même schéma et par le parseur réel.
- [ ] Exposer cette découverte par API Dart puis JSONL ; le MCP ne maintient pas une seconde vérité des paramètres.
- [ ] Ajouter `--profile map-builder`, sans modifier le profil complet par défaut.
- [ ] Dans le profil compact initial, conserver `describe`, `workspace`, `query`, `workshop`, `plan`, `apply`, `history`, `artifact`, les outils 3D et `recovery_status`. Ajouter ensuite `map_edit`/`map_check` sans retirer la voie canonique de création et de diagnostic.
- [ ] Réduire les descriptions et exemples redondants, mesurer le schéma réellement envoyé. Cibles de volume : liste d’outils ≤ 25 Ko et index compact du domaine ≤ 40 Ko. Ne pas retirer récupération ou création pour atteindre un chiffre.

**Acceptation :** un client neuf découvre sans lire le catalogue complet les contrats nécessaires à T1–T7. Domaines, versions, schémas et exemples correspondent au parseur. Les outils historiques restent accessibles dans le profil complet. Un profil compact sans R3 reste utilisable via plan/apply.

**Validation prévue :** `dart test test/api/authoring_capability_discovery_test.dart test/registry` dans `packages/map_authoring` ; `node --import tsx --test test/capability_discovery.test.ts test/map_builder_profile.test.ts test/config.test.ts` dans `tools/pokemap_mcp`.

## 6. R2 — Identité logique, déterminisme et reprise du résultat

**Modifier :** `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart`, `authoring_result_projection.dart`, `src/transactions/journaled_transaction.dart`, `file_idempotency_store.dart`, `src/workspace/catalog/catalog_authoring_session.dart` uniquement aux frontières nécessaires ; `src/tooling/jsonl_worker.dart` pour exposer le même contrat.

**Créer :** `packages/map_authoring/lib/src/api/map_edit_execution.dart`, `packages/map_authoring/lib/src/contracts/map_edit_operation.dart`, `packages/map_authoring/test/api/map_edit_operation_test.dart`, `packages/map_authoring/test/tooling/jsonl_map_edit_operation_test.dart`.

**Étendre :** `test/transactions/idempotency_contract_test.dart` et les tests catalogue ciblés. Ne pas modifier les fingerprints des anciennes actions.

### 6.1 Contrat public

La façade canonique d’édition prend un `operationId` explicite pour une application durable. Le client crée cette identité avant l’appel et la conserve jusqu’au résultat certain. Une nouvelle intention, même identique après undo, utilise une autre identité. `dryRun` ne réserve aucune application et peut utiliser la même identité pour reproduire la projection.

```json
{
  "projectHandle": "<opaque>",
  "operationId": "edit-7f61",
  "mapId": "field",
  "seed": 42,
  "operations": [
    {"actionId": "border_layer.feature_delete", "actionVersion": 1,
     "parameters": {"layerId": "shore-layer", "featureId": "shore"}}
  ],
  "guards": {},
  "dryRun": true
}
```

Le schéma rejette les propriétés inconnues et normalise les défauts avant le fingerprint sémantique. Celui-ci inclut version de contrat, carte, opérations ordonnées, guards effectifs et seed ; il exclut handles temporaires, numéro de tentative, révision relue et `dryRun`. Une même identité avec contenu métier différent est refusée avant écriture. La seed est explicite ou vaut un défaut stable documenté ; les IDs générés dérivent de l’identité logique et de l’index, pas d’un `planId` aléatoire.

Le déterminisme porte sur état projeté, IDs métier et diagnostics ordonnés, à état/dépendances/résolveur/seed identiques. Reçus et dates transactionnelles de deux nouvelles intentions peuvent différer. Un rejeu d’une intention déjà appliquée retrouve son reçu historique.

### 6.2 Orchestration canonique

```text
normaliser et valider la demande
consulter l’identité durable (acteur, projet, operationId)
  terminée + même fingerprint -> reprojeter le reçu existant
  identité liée à un autre fingerprint -> conflit sans écriture
  réservée/journal en cours -> statut précis, pas de nouvelle application
  absente -> lecture ciblée, planification, application canonique
si refus stale/conflit avant toute réservation durable
  relire les dépendances puis replanifier avec une clé de tentative distincte
si statut durable ou réponse d’application incertaine
  inspecter le statut ; ne pas recommencer aveuglément
```

Réutiliser les index `lookupOperation`, `recoveryStatus`, les journaux et la reprojection existants. Les extensions arbitraires d’une requête ne sont pas automatiquement conservées dans le reçu : persister un binding sémantique calculé côté serveur dans les métadonnées canoniques de la nouvelle opération. Le binding doit survivre au redémarrage et être atomiquement lié au journal/reçu ; aucun mapping MCP seulement en mémoire et aucun second ledger généraliste.

La recherche doit aussi reconnaître une tentative déjà réservée. Le stockage actuel impose une portée durable par `operationId` : une nouvelle clé de tentative n’est permise qu’avant réservation/journal durable confirmé absent. Préserver les préconditions et confirmations du plan ; ne jamais auto-confirmer une nouvelle opération nécessitant une approbation liée au diff.

Définir et publier la durée effective de rétention/rejeu et sa relation avec la maintenance d’historique. Ne pas promettre un reçu éternel : un identifiant reconnu mais dont la preuve a expiré doit produire un statut explicite, pas être silencieusement réappliqué. Si les index actuels ne permettent pas cette distinction, ajouter le tombstone minimal à cette frontière et ses tests de maintenance.

- [ ] Écrire le test rouge « réponse perdue après commit, réouverture et rejeu avec même identité : zéro nouvelle écriture, même reçu ».
- [ ] Tester nouvelle intention identique après undo : nouvel ID, nouvel effet durable ; même ID avec contenu différent : refus.
- [ ] Tester deux appels concurrents avec même identité, crash avant/après réservation et après écriture visible, plans expirés, historique maintenu et rétention dépassée.
- [ ] Implémenter le binding durable et la consultation du résultat avant replanification, pour classique et catalogue, par les frontières existantes.
- [ ] Tester deux projections avec seed identique : mêmes octets métier et diagnostics ; les métadonnées transactionnelles sont comparées séparément.
- [ ] Exposer l’état `applied`, `unchanged`, `busy`, `recovery_required`, `confirmation_required` ou une erreur métier structurée ; jamais de succès durable avant persistance.
- [ ] Conserver aussi le binding et le résultat `unchanged` de façon durable sans écriture fictive de carte. Tester une réponse perdue de ce no-op, une modification externe, puis le rejeu : même résultat initial, aucune nouvelle application. Une nouvelle intention utilise un autre operationId.
- [ ] Borner les reprises pré-réservation : trois tentatives au maximum, délais de 100 puis 250 ms, deadline totale explicite. Une indisponibilité persistante renvoie `busy` avec statut consultable. Cette tolérance ne remplace pas la cible de latence nominale.
- [ ] Harmoniser les délais réels du client MCP, du worker et du CLI ; couvrir `--authoring-timeout-ms` et la propagation d’annulation. Aucun délai augmenté silencieusement pour masquer un parcours global.

**Validation prévue :** tests API/JSONL cités plus `dart test test/transactions/idempotency_contract_test.dart test/transactions/scoped_idempotency_store_test.dart test/transactions/incremental_idempotency_store_test.dart` dans `packages/map_authoring`. Les tests de crash utilisent les checkpoints existants et ne touchent aucun projet utilisateur.

## 7. R3 — Batch atomique, rematérialisation et garde-fous

**Créer :** `packages/map_authoring/lib/src/domains/maps/map3d_edit_batch_actions.dart`, `map3d_edit_projection.dart` dans le même dossier, `packages/map_authoring/test/domains/maps/map3d_edit_batch_actions_test.dart`, `tools/pokemap_mcp/src/tools/map_edit.ts`, `tools/pokemap_mcp/test/map_edit.test.ts`, `tools/pokemap_mcp/test/map_edit_stdio.test.ts`.

**Modifier :** dispatcher, descripteurs/registre, `semantic_map_action_support.dart`, actions propriétaires admises, sélection catalogue ciblée, `tools/pokemap_mcp/src/server.ts`, tests de parité et `test/workspace/catalog_spatial_map_mutation_test.dart`.

### 7.1 Frontière de composition

Action canonique `map3d.edit_batch`, version 1, 1 à 64 sous-opérations. Chaque opération porte `actionId`, `actionVersion`, `parameters`. Injecter le mapId commun ou refuser toute divergence. Aucune récursion de batch, écriture de catalogue partagé ou autre carte.

Extraire uniquement les transformations des actions admises dans un contexte commun de carte en mémoire. Chaque action isolée continue d’utiliser cette transformation puis son enveloppe historique. Les préconditions structurelles nécessaires restent vérifiées ; les états transitoires autorisés dans le batch sont explicités, par exemple suppression de Border puis restauration du sol avant contrôle final.

Ne pas appeler un builder de draft par sous-opération, encoder/décoder un JSON intermédiaire, ou appeler `projectMapResources` à chaque étape. Finaliser une seule carte, une seule unité d’undo et un seul changement transactionnel. Traiter une sous-opération sans effet comme `unchanged` ; définir un batch entièrement inchangé sans reçu d’écriture fictif.

Liste d’admission à couvrir en transformations partagées et tests :

```text
smart_tile.cell.paint, smart_tile.cell.paint_batch, smart_tile.cell.erase
map3d.terrain.surface.upsert_batch, map3d.terrain.surface.delete_batch
map3d.instance.upsert_batch, map3d.instance.delete_batch
border_layer.feature_create, border_layer.feature_update, border_layer.feature_delete
border_layer.feature_move, border_layer.stroke_add, border_layer.stroke_update
border_layer.stroke_delete, border_layer.stroke_erase
border_layer.region_fill, border_layer.region_clear
border_layer.feature_set_replacement, border_layer.feature_set_suppressed
border_layer.feature_clear_slot_override, border_layer.feature_set_keep_out
border_layer.relink_apply, border_layer.feature_set_blueprint
border_layer.materialize_batch_apply
```

Une sous-action qui nécessite d’autres documents à écrire est refusée avec `foreign_resource`. Une action non encore admise au parcours ciblé ne doit pas provoquer un repli vers chargement global. `map3d.instance.delete_batch` demande notamment une admission ciblée explicite. La liste publiée ne contient que les opérations réellement livrées ; toute réduction par rapport à cette liste laisse R3 partiel jusqu’à décision de périmètre.

### 7.2 Contrôles finaux

```json
{
  "groundGaps": "refuse",
  "borderObjectOverlaps": "refuse",
  "staleBorders": "rematerialize",
  "newBorderErrors": "refuse",
  "newBorderWarnings": "report"
}
```

Les champs de contrôle acceptent `refuse` ou `report` ; `staleBorders` accepte `rematerialize`, `refuse`, `report`. La politique de bilan R4 peut être plus exigeante que l’acceptation d’une édition sans régression.

- [ ] Collecter les features touchées par IDs, dépendances de terrain et mutations de matérialisation ; matérialiser les features touchées `missing`/`stale` au plus une fois en fin de batch.
- [ ] Calculer l’intégrité avant/après une fois au niveau du batch, partager ces rapports avec le preview final pour éviter un recalcul caché.
- [ ] Refuser les nouveaux `exposed` et les passages `unproven` vers `exposed`. Rapporter les nouveaux `unproven` sans les refuser.
- [ ] Étendre les collisions à des identités de slots pour refuser nouvelles collisions et aggravations d’une paire existante ; un module remplacé ou déplacé en conflit ne doit pas échapper à la comparaison.
- [ ] Comparer les nouveaux diagnostics Border par feature, slot, code et faits pertinents ; ne pas ignorer une aggravation du même diagnostic sur le même slot.
- [ ] Refuser les erreurs nouvelles et features touchées encore invalides selon la politique. Les défauts étrangers préexistants restent rapportés ; ne pas imposer leur réparation à chaque edit local.
- [ ] Ajouter les erreurs indexées `operation_failed` avec cause d’origine et les refus de garde-fou, tous sans écriture.
- [ ] Produire preview compact : opérations et effets, `unchanged`, features rematérialisées, problèmes introduits/aggravés, état final résumé et références de détail paginées.

### 7.3 Façade MCP et coût

`pokemap_map_edit` transporte le contrat R2, appelle l’orchestrateur canonique et expose `dryRun`. Le serveur peut cacher la chorégraphie à l’agent, mais ni sa sécurité ni son coût. Les résultats durables incluent operationId, reçu, révision et résumé métier ; un résultat inconclusif conserve un identifiant consultable.

- [ ] Couvrir T1/T4/T5 par un appel d’édition après découverte, éventuellement suivi d’un check. T6 reste un critère de R5.
- [ ] Tester atomisme : opération 3 refusée après deux projections valides, aucune écriture ; changement multi-carte refusé ; 0/65 opérations refusées ; opérations sans effet et suppressions déjà satisfaites selon contrat.
- [ ] Comparer classique/catalogue, API directe/JSONL/MCP et chemin éditeur existant lorsqu’il partage les transformations. Aucun nouveau bouton Studio demandé ; justifier précisément les cas UI N/A.
- [ ] Mesurer 1, 3 et 64 sous-opérations : un encodage final de la carte et deux inspections d’intégrité au maximum pour le batch, indépendamment du nombre de sous-opérations. Les contrôles sémantiques locaux et résolutions nécessaires sont comptés séparément.
- [ ] Faire varier 0/90 cartes étrangères et deux profondeurs d’historique, vérifier l’absence de lecture/décodage de contenu étranger et expliquer les pages d’index réellement nécessaires. Ne pas copier arbitrairement une tolérance de 16 pages sans justification du stockage courant.
- [ ] Garder la région éditée fixe et faire croître séparément taille, objets et Borders non pertinents dans la même carte. Deux inspections complètes ne prouvent pas à elles seules la proportionnalité : caractériser la fermeture de dépendances nécessaire, notamment connectivité du vide et masques Border. Si le détecteur actuel impose un travail disproportionné par edit, corriger sa frontière propriétaire avec une inspection incrémentale équivalente, ou laisser ce critère `PARTIAL` ; ne pas masquer le coût dans un cache chaud.
- [ ] Mesurer première opération et répétitions jusqu’à durabilité, rouvrir et vérifier le contenu. Une simple mesure `dryRun` ne ferme pas le lot.

**Validation prévue :** tests de batch/API R2, `dart test test/workspace/catalog_spatial_map_mutation_test.dart test/domains/maps/border_materialization_batch_actions_test.dart` ; côté MCP `node --import tsx --test test/map_edit.test.ts test/map_edit_stdio.test.ts`.

## 8. R4 — Bilan unique avec portée de preuve explicite

**Créer :** `packages/map_authoring/lib/src/api/map_health_query.dart`, `packages/map_authoring/test/api/map_health_query_test.dart`, `tools/pokemap_mcp/src/tools/map_check.ts`, `tools/pokemap_mcp/test/map_check.test.ts`.

**Modifier :** registres de ressources, routage API/query/JSONL, table de parité, `tools/pokemap_mcp/src/server.ts`, `tools/pokemap_render_host/lib/src/render_host.dart` et ses tests seulement pour la couverture/cohérence nécessaires.

`mapHealth` s’interroge via `get ids:[mapId]` ou `list filters.mapId`, avec lecture ciblée. Le bilan comprend révision, version de politique, contrôles exécutés, problèmes, inconnues et couverture. Il ne certifie ni fidélité à une référence ni jouabilité complète.

```json
{
  "mapId": "field",
  "revision": "<révision ciblée>",
  "policyVersion": 1,
  "verdict": "incomplete",
  "checks": {
    "structure": {"status": "pass"},
    "borders": {"status": "pass", "unexplainedWarnings": []},
    "visual": {"status": "incomplete", "reason": "targets_skipped"}
  },
  "coverage": {"requested": "full", "skippedTargetCount": 2},
  "issues": [],
  "suggestedOperations": []
}
```

- [ ] Définir la politique par code : erreurs, `missing`/`stale`, trous `exposed` et défauts crown/base pertinents bloquent le bilan. Les `unproven` restent inconnues/candidats visuels. Les chevauchements non expliqués nécessitent un examen ; `holeRatio=0` ne les acquitte pas.
- [ ] Ne pas fabriquer une liste vide d’avertissements inexpliqués sans avoir réellement évalué ceux présents. Sans mécanisme d’acceptation persistante, renvoyer les avertissements et justifications manquantes ; ne pas ajouter une mutation de format de carte pour ce seul lot.
- [ ] Ajouter `pokemap_map_check({projectHandle,mapId,visual:"none"|"targets"|"full"})`, défaut `full`. `none` peut réussir les seuls contrôles structurels demandés, avec visuel `not_run` explicitement affiché ; jamais une réussite visuelle implicite.
- [ ] Exiger une même révision entre rapport et scan ; en cas de modification concurrente, résultat `incomplete` ou nouvelle tentative bornée avec mêmes règles.
- [ ] Prendre en compte erreurs de rendu, absence de capacité native, vues/cibles omises, couverture terrain non peinte et avertissements non évaluables. Un défaut prouvé donne `fail` même si un autre contrôle est incomplet ; sinon une preuve manquante donne `incomplete`.
- [ ] Publier ce que mesure `holeRatio` ; un ratio positif est un signal à examiner dans son contexte, une valeur nulle n’est pas une preuve universelle. Stabiliser heure, caméra et animations pertinentes pour les tests de reproductibilité.
- [ ] Sortie courte limitée à 20 problèmes avec total et détail paginé, images des défauts et des cas ambigus utiles, sans masquer les éléments non affichés. Préserver l’accès manuel au rendu complet.
- [ ] Tester carte saine, crown/base warning, erreur Border, nouveau `unproven`, défaut occulté, vide relié au cadre, cibles omises, erreur de rendu et révisions différentes. Assertions indépendantes du seul verdict.

**Validation prévue :** `dart test test/api/map_health_query_test.dart test/registry test/parity` dans `packages/map_authoring` ; `node --import tsx --test test/map_check.test.ts test/native_render_host.test.ts` dans `tools/pokemap_mcp` ; tests `render_host_test.dart` dans `tools/pokemap_render_host` avec suivi des processus.

## 9. R5 — Intentions limitées et parcours minimal de création

**Créer :** `packages/map_core/lib/src/operations/spatial_map_edit_intents.dart`, `packages/map_core/test/operations/spatial_map_edit_intents_test.dart`, `packages/map_authoring/test/domains/maps/map3d_edit_intents_test.dart`, `tools/pokemap_mcp/test/map_creation_reliability_stdio.test.ts`.

**Modifier :** projection du batch, requêtes de ressources/découverte nécessaires, sélection catalogue, schémas et barrels publics des packages concernés. La résolution de noms est canonique ; elle ne dépend pas d’une recherche limitée au manifeste déjà fermé sur les références actuelles.

| Intention | Contrat de résolution |
| --- | --- |
| `intent.ground.fill` | Cellules/région, matériau/calque explicites facultatifs ; résultat `resolved`, `ambiguous` ou `no_source`. Départage stable, calques visibles pertinents, groupes par matériau/calque, pas de propagation arbitraire d’un vide |
| `intent.border.remove_keeping_ground` | Déterminer les contributions réelles de la Border et le sol à remplacer ; ne pas utiliser uniquement les trous intérieurs du détecteur, qui ignore le vide relié à la marge. Demander un choix lorsque la source de sol n’est pas certaine |
| `intent.border.trace_step` | Marches orthogonales de plateaux, hauteurs effectives, région et profil explicites ; contours orientés terre à droite, boucle/traits ordonnés, validation par le vrai resolver |
| `intent.border.clear_over_object` | Slots réellement en collision avec l’instance ; aperçu des modules affectés ; avertir si leur suppression retire aussi du sol |
| `material:{name:"mer"}` | Recherche ciblée dans les ressources autorisées, nom normalisé et preset ; zéro/plusieurs candidats refusés avec IDs et labels utilisables |

- [ ] Écrire les tests purs pour égalité de votes, plusieurs trous adjacents, mer/terre, absence de voisin, plusieurs matériaux, rampes/surfaces, plusieurs boucles et région tronquant un contour.
- [ ] Résoudre les intentions en opérations concrètes affichées dans l’aperçu, puis appliquer les mêmes gardes du batch. Les suggestions ne deviennent jamais des mutations implicites non montrées.
- [ ] Pour `trace_step`, refuser selon les capacités et diagnostics du profil ; aucun refus universel de décrochement d’une case. Erreurs avec cellules et alternatives utiles. Rampes non prises en charge explicitement refusées avec cause précise.
- [ ] Tester suggestions devenues périmées avant reprise et noms ambigus sur ressources hors fermeture initiale de carte ; aucune lecture globale des assets pour chercher un label.
- [ ] Faire réussir T2/T3/T6 en un appel d’édition après découverte, sans exiger leur livraison au lot R3.
- [ ] Couvrir T7 par une séquence bornée d’actions existantes `map.create`, création des calques Smart Tile/Border selon les contrats publiés, terrain, peinture puis batch de relief. Les actions de création hors portée « une carte existante » restent des transactions distinctes ; ne pas forcer leur entrée dans le batch monodocument.
- [ ] Conserver ces actions dans le profil compact via la voie canonique plan/apply. Retourner les identités générées sans les faire deviner au client ; vérifier réouverture, édition native et absence d’effacement des ressources déjà présentes.

**Acceptation :** les cas explicitement résolus réussissent ; les ambiguïtés produisent un choix exploitable sans écriture. T7 prouve la création d’une carte avec ressources existantes, distinctement de la réparation. La parité visuelle et l’usage natif terrain/paths/Borders sont vérifiés séparément.

**Validation prévue :** `dart test test/operations/spatial_map_edit_intents_test.dart` dans `packages/map_core` ; tests d’intentions dans `packages/map_authoring` ; test stdio de création dans `tools/pokemap_mcp`.

## 10. R6 — Banc local de décision, petit et grand modèle

**Créer :** `tools/pokemap_mcp/bench/map_reliability_bench.ts` et `tools/pokemap_mcp/test/map_reliability_bench.test.ts`. Réutiliser les cas R0 et les connecteurs de modèles configurés, sans coder de fournisseur obligatoire dans les outils métier.

- [ ] Exécuter 5 passages × 10 tâches pour chaque modèle et chaque version avant/après, avec les trois variantes réservées. Conserver modèles/versions, paramètres de génération, prompts, budget d’appels/tokens/temps et version du serveur identiques hors changement testé.
- [ ] Le test ordinaire du harnais utilise un faux modèle déterministe et ne consomme aucun crédit. Le vrai banc est local, explicitement lancé, sans CI automatique.
- [ ] Réinitialiser une fixture isolée par tâche. Critère = oracle propre au cas, non-régression et résultat des contrôles demandés ; le seul `map_check` ne note pas son propre examen.
- [ ] Compter succès/échecs/incomplets, appels MCP, requêtes internes, octets/tokens, durée, refus de garde-fou, ambiguïtés, erreurs de schéma et reprises. Classer un refus sûr comme tel, distinct d’une corruption.
- [ ] Rapporter taux et nombres bruts par tâche/modèle, médiane des appels et dispersion. Objectifs de décision : ≥ 80 % pour le petit modèle, ≥ 95 % pour le grand et médiane d’appels divisée par 3 sur les tâches comparables. Ce sont des cibles empiriques de ce banc, pas des garanties universelles.
- [ ] Comparer aussi les timings et le travail ; aucune baisse d’appels qui masque une hausse disproportionnée du travail n’est acceptée. Catalogue, contention et durabilité ont leurs preuves dédiées R2/R3 ; le banc classique ne les certifie pas.
- [ ] Placer les résultats JSON compacts sous la racine QA canonique pendant le run, verser les preuves utiles au ticket existant puis supprimer les copies jetables. Ne pas optimiser les consignes par modèle ou par tâche pour obtenir du vert.

**Validation prévue :** `node --import tsx --test test/map_reliability_bench.test.ts` dans `tools/pokemap_mcp`, puis commande du harnais avec noms exacts des modèles retenus et budgets consignés dans le reçu de run. Sans fournisseur/version configuré, le banc réel reste non exécuté ; ne pas inventer des taux.

## 11. R7 — Skills, contrats et validation de sortie

**Modifier seulement après livraison correspondante :** `skills/using-pokemap-mcp/SKILL.md`, `skills/authoring-pokemap-3d-reliefs/SKILL.md`, `skills/README.md`, documentation canonique de contrats si sa génération est requise. `AGENTS.md` seulement si une règle réelle devient inexacte, sans suppression des garanties générales.

- [ ] Appliquer `skills/writing-skills/SKILL.md` aux changements de skills, avec essai avant/après par agent et preuve du comportement.
- [ ] Enseigner : découverte ciblée → observation/révision → édition avec identité logique → contrôle de portée connue → résolution explicite des ambiguïtés. Un `incomplete` ne se transforme pas en succès par répétition.
- [ ] Garder terre à droite, contour sur la marche, pas de compensation arbitraire d’offset, provenance du sol, native editability et limites des scans.
- [ ] Réduire la chorégraphie manuelle uniquement pour les actions où R2/R3 la prennent réellement en charge ; préserver la voie avancée et les commandes de récupération.
- [ ] Faire une critique indépendante : contrats trompeurs, coûts cachés, ambiguïtés automatisées, mélange avec intégration Studio, régression des nouveautés de Claude, modifications concurrentes embarquées.

## 12. Vérification technique et preuves par lot

Les commandes ci-dessous sont prévues, non exécutées par la rédaction de ce plan. Exécuter d’abord les tests ciblés du lot, puis élargir selon les frontières touchées. Ne pas lancer mécaniquement toutes les suites pour une modification de schéma de découverte.

```bash
cd packages/map_core
dart analyze
dart test test/border

cd ../map_authoring
dart analyze lib
dart test test/api test/domains/maps test/workspace/catalog_spatial_map_mutation_test.dart test/registry test/parity test/tooling/jsonl_worker_test.dart
dart run tool/pmcp085_conformance.dart
dart test test/parity/full_authoring_parity_test.dart

cd ../../tools/pokemap_mcp
npm run check
npm run build
node --import tsx --test --test-concurrency=1 test/config.test.ts test/native_render_host.test.ts test/protocol_compatibility.test.ts test/runtime_server.test.ts
```

Si le rendu est modifié : `flutter analyze` et `flutter test test/render_host_test.dart` depuis `tools/pokemap_render_host`, avec suivi et nettoyage des descendants. Les vérifications natives et du build représentatif restent locales. Consulter les docs Flame configurées avant de modifier leur intégration.

Reconstruire/recharger le serveur puis contrôler le catalogue vivant : outils, schémas, profils, ouverture d’une fixture autorisée, requête, `dryRun`, application sûre, rejeu, contrôle, fermeture. Ne pas conclure que le serveur vivant reflète les sources sur le seul succès des tests.

Chaque lot se termine par un reçu en chat/ticket contenant :

1. Scope exact, statut des critères et capacités existantes préservées.
2. Git d’entrée/sortie et inventaire des seuls fichiers/hunks du lot.
3. Commandes exactes, lignes de résultats, échecs et raisons des checks non exécutés.
4. Preuves API/JSONL/MCP et éditeur, ou justification N/A précise ; mesures première/répétées et compteurs.
5. Limites visuelles, de plateforme, de compatibilité, de rétention et de benchmark.
6. Critique finale indépendante, nettoyage des artefacts/processus, statut Notion `TO REVIEW` si prêt.

Le contrôle Markdown de l’exécution garde son budget normal de zéro nouveau document ; le budget de deux est réservé à la création initiale des deux plans demandés. Aucun commit, push, release ou écriture HeartGold n’est autorisé par ce document.

## 13. État d’exécution au 30 octobre 2026

La mise en œuvre fonctionnelle a été réalisée sur le dépôt partagé. Les cases précédentes restent la liste détaillée des critères ; le tableau suivant distingue les capacités vérifiées des critères de recette qui restent ouverts. Le plan 2 n’a pas été exécuté. Yoahn a autorisé le commit final et a explicitement choisi « livrer le harnais ; différer les essais LLM réels ».

| Lot | Résultat vérifié | Statut de recette |
| --- | --- | --- |
| R0 | Fixtures classiques/catalogue, oracles indépendants et tâches de référence ; vraie contribution de sol Border sur T1 | Référence déterministe livrée ; référence LLM différée |
| R1 | Découverte filtrée/paginée, schémas et exemples passés au JSON Schema et aux vrais parseurs, profil compact avec rendu et récupération | Fonctionnel vérifié ; `listTools` réel à 24 938 octets, pages compactes ≤ 40 Ko |
| R2 | Identité sémantique durable, seed stable, no-op durable, rejeu après réouverture, concurrence, nouvelle intention après undo, compensation/expiration, annulation avant réservation et continuation confirmée | Fonctionnel vérifié sur fixtures et frontières transactionnelles ; rétention annoncée de 30 jours |
| R3 | 24 actions composées sans drafts intermédiaires ; un encodage et deux inspections finales pour 1/3/64 opérations ; rematérialisation, refus atomiques et aggravation des contacts | `PARTIAL` pour coût local et certaines admissions de dépendances, voir limites ci-dessous |
| R4 | `mapHealth`, pagination liée à la révision et `map_check` ; défaut prouvé prioritaire sur inconnue ; même révision exigée ; scan sur toute l’étendue, heure et temps d’animation fixés | Contrats vérifiés ; le scan reste un détecteur de fond enfermé, pas une certification visuelle universelle |
| R5 | Quatre intentions, noms normalisés et ambiguïtés refusées ; géométrie de feature mise à jour sans changement d’identité ; T7 créé jusqu’au relief natif puis rouvert par MCP réel | Fonctionnel vérifié sur cas pris en charge ; coût de recherche de noms et dépendances non universellement admises restent `PARTIAL` |
| R6 | Harnais injectable local, budgets, contexte public, arrêt/drain avant oracle indépendant, mesures et médianes/dispersion ; faux modèle sans crédits | Harnais livré ; pilotes et essais réels petit/grand modèle différés, aucun taux 80/95 % ni gain ×3 revendiqué |
| R7 | Skills mis à jour après essai documentaire rouge/vert : boucle façade, identité après réponse perdue, ambiguïtés, couverture et décrochements dépendants du profil | Parcours documentaires vérifiés, workflow avancé et invariants natifs préservés |

### Preuves techniques de l’exécution

- `packages/map_authoring` : groupe API santé/édition, intentions, exemples, batch, ciblage et JSONL — **95 tests réussis** ; concurrence et même peinture après undo — **4 tests supplémentaires réussis**. Groupe référence/découverte/matérialisation/lecture native — **62 tests réussis**. Les suites générales du monorepo ne sont pas déclarées vertes.
- `packages/map_core` : intentions pures, intégrité et delta — **18 tests réussis** au passage groupé ; analyse ciblée sans problème. La région exacte d’un plateau conserve ses quatre côtés ; les versions inconnues d’intention sont refusées.
- `tools/pokemap_mcp` : `npm run check` et `npm run build` réussis ; groupe configuration/découverte/profil/bilan/façade/harnais/rendu/runtime — **31 tests réussis** ; groupe découverte/protocole/stdio édition et création — **11 tests réussis**. Les quatre parcours stdio métier couvrent les deux stockages.
- `tools/pokemap_render_host` : `flutter analyze` sans problème ; **22 tests réussis**, descendants du runner observés et aucun harnais restant ; `flutter build macos --debug` réussi. Aucun processus DTD actif à recharger.
- Smoke natif sur fixture synthétique : deux scans réels, même révision, quatre vues couvrant 24 × 16, aucune cible omise, mêmes ratios et mêmes empreintes PNG. Les contrôles structurels passent mais deux plages de fond enfermé produisent bien `fail` visuel sur les deux passages. Ce résultat n’est pas renommé « carte saine visuellement ».
- PMCP-085 : catalogue déclaré complet et zéro cellule déclarée manquante, mais certification globale des transports incomplète, sortie **1**. Les tests globaux inventaire/parité révèlent aussi des écarts hors des contrats livrés, notamment les kinds `mapAtmosphere`, `mapEditor` et `cinematicMediaAsset`. L’ajout de `mapHealth` est inclus dans les attentes du lot ; aucun assouplissement des autres assertions.

### Critères restant ouverts

Les deux inspections finales parcourent encore la carte sélectionnée. `clear_over_object` ajoute une inspection d’intention comptée séparément. La fermeture incrémentale dans une grande carte n’est donc pas certifiée. Les mesures sont headless, JIT, sur fixture 24 × 16, MacBookPro18,3 arm64 ; un échantillon catalogue a mesuré **588 ms** pour le premier durable et **316 ms** ensuite. Des répétitions plus rapides ne ferment pas la cible de 500 ms. Aucune preuve UI 100/500 ms ni certification sur projet représentatif n’est revendiquée.

La suppression ciblée d’instances catalogue refuse les projets dont les documents narratifs exigent un index entrant qui n’est pas disponible. Elle ne se replie pas vers un chargement global. La résolution de noms catalogue parcourt des summaries de matériaux/presets avant de charger les définitions retenues ; elle évite les assets étrangers, mais son coût dépend encore de cet index.

L’éditeur réutilise les transformations propriétaires conservées ; aucun bouton de batch ni intégration MCP au cycle de vie de Studio n’a été ajouté. Les preuves d’édition et de persistance de ce lot sont API/JSONL/MCP, pas une recette UI. Aucun export de jeu, sauvegarde protégée ou projet HeartGold n’a été modifié.

Les commits intermédiaires du dépôt partagé incluent déjà des morceaux du chantier, enregistrés par Yoahn pendant l’exécution. Le commit final doit compléter uniquement les chemins et hunks possédés ; sa référence et l’état Git final sont consignés dans le ticket existant et la réponse finale. Les fixtures et processus QA sont supprimés après la recette ; seuls les tests maintenus, les deux plans demandés et les preuves compactes du ticket restent.
