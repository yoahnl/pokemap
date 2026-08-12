# Audit final de conformité à la cible Item System V1

Date : 2026-08-12

Branche auditée : `codex/item-system-phase-0`

Révision auditée : `59cac1d29d3b20a4691fe4158de52fcce0b4e927`

Roadmap de référence : `documentation/reports/roadmap/gameplay/pokemap_item_system_v1_roadmap.md`

Verdict : **NON, l’implémentation promise n’est pas entièrement terminée**.

## 1. Réponse exécutive

L’Item System V1 n’est pas un faux chantier ni une façade vide. Le socle principal existe réellement : catalogue canonique strict, Bag identifié par `itemId`, transactions atomiques, objets utilisables en overworld et en combat sur le sous-ensemble supporté, capture par Ball sélectionnée, boutiques, pickups, rewards, machines, objets tenus, Item Studio, neuf mutations authoring sur quatre transports, parcours Golden déterministe et infrastructure de certification exécutable.

En revanche, la cible de départ ne promettait pas seulement qu’un parcours Golden choisi avec soin passe. Elle promettait notamment :

- une vérité de capacité indépendante du catalogue authoré ;
- la détection des capacités non exécutables avant le playtest ;
- une rupture stricte de tous les lecteurs de sauvegarde historiques ;
- la protection des key items par défaut ;
- une certification L0-L6 qui prouve le produit, pas uniquement une fixture signée ;
- une clôture appuyée par une matrice de validation honnête.

Ces garanties ne sont pas toutes tenues. Trois contournements ont été reproduits par exécution, et non déduits seulement par lecture statique :

1. un objet combinant `repel` overworld, `restore_pp` battle et un `heldEffectId` inexistant est accepté par l’authoring live et déclaré `ready: true` sans diagnostic ;
2. un `SaveEnvelope` contenant encore `categoryId` dans une entrée de Bag est restauré avec succès par un chemin canonique secondaire ;
3. un key item est retiré du Bag par `GameStateMutations.consumeItem` sans consultation du catalogue ni autorisation explicite.

Le certificat produit généré annonce malgré cela `CERTIFIED` pour L0 à L6. Il est reproductible et lié au commit et à la fixture, mais son périmètre est plus étroit que le verdict produit qu’il affiche.

### Conclusion de décision

- **Le parcours de référence Item V1 est implémenté.**
- **La majorité des briques fonctionnelles promises sont présentes.**
- **La cible produit globale et ses invariants non négociables ne sont pas terminés.**
- **La phase 9 ne peut pas honnêtement être considérée comme une clôture finale.**
- **Le statut global doit rester PARTIAL, mais pour des raisons plus importantes que le seul reload MCP indiqué par la roadmap.**

## 2. Méthode et périmètre

L’audit a été réalisé sans corriger le code afin de ne pas modifier le résultat observé. Il a combiné cinq passes locales indépendantes :

1. **Passe cible et engagements** : reconstitution des contrats non négociables, des phases 0 à 9, des 59 lots et de leurs preuves déclarées.
2. **Passe architecture et code** : inspection des modèles, validators, services gameplay, runtime battle, persistance, authoring, UI, MCP et certification.
3. **Passe hostile** : création de projets et de sauvegardes jetables destinés à tester les frontières négatives que le Golden flow ne couvre pas.
4. **Passe exécutable** : tests ciblés, suites complètes, analyses statiques, transport MCP live, génération du certificat et inspection des receipts.
5. **Passe critique finale** : confrontation entre les preuves réellement exécutées, les formulations de la roadmap et la cible initiale.

Aucun sub-agent n’a été lancé pendant cet audit : l’instruction d’exécution active interdisait la délégation sans demande explicite. Les passes demandées par `codex_rule.md` ont donc été menées localement et séparément.

Le projet utilisateur `le_train_de_17h42` n’a pas été modifié. Deux copies temporaires hostiles ont été déplacées dans la Corbeille après vérification :

- `pokemap-item-audit-live-eBYzoa` ;
- `pokemap-item-audit-capability-kGseP1`.

## 3. Cible contractuelle reconstituée

La cible de départ, telle que figée dans la roadmap, impose au minimum les invariants suivants :

| Axe | Garantie promise | Verdict audit |
|---|---|---|
| Identité | Une pile est identifiée uniquement par `itemId` | Conforme sur le chemin canonique |
| Présentation | Les pockets ne pilotent aucune mécanique | Conforme sur les consommateurs principaux |
| Contextes | Les contextes d’usage sont explicites | Présent, mais la vérité contexte × effet est incomplète |
| Vérité de capacité | `runtimeReady`, `passive` et `unsupported` reflètent le moteur réel | Non conforme |
| Pré-playtest | Toute capacité non exécutable est bloquée ou diagnostiquée avant jeu | Non conforme |
| Transaction | Effet et consommation sont atomiques | Conforme sur `PlayerItemUseService` et le battle bridge |
| Capture | La Ball effectivement choisie est celle consommée | Conforme |
| Key items | Ni vente, ni discard, ni consommation par défaut | Partiel : vente protégée, consommation publique contournable |
| Held items | La définition authorée est validée contre un effet réellement supporté | Partiel : runtime fail-closed, authoring auto-approuvé |
| Catalogue | Schéma exact, aucune tolérance legacy | Conforme pour le codec du catalogue |
| Sauvegarde | Ancien Bag et `categoryId` refusés sur tous les lecteurs | Non conforme sur SaveEnvelope/checkpoints |
| Rupture | Aucun dual reader, fallback ou migration | Non conforme à cause du lecteur secondaire |
| Authoring | Même sémantique sur API, JSONL, Editor et MCP | Conforme pour les neuf mutations testées |
| Certification | Preuves exécutées, liées au commit et à la fixture | Infrastructure conforme ; couverture produit incomplète |
| Repel | Explicitement différé | Différé, mais encore proposé par l’éditeur |

## 4. Findings bloquants et importants

### AUD-ITM-001 — P0 — La capability truth est auto-référentielle et peut certifier une capacité inexistante

**Promesses violées :** ITM-013, ITM-027, ITM-031, ITM-038, ITM-050 à ITM-053, ITM-087 et la règle « unsupported détecté avant playtest ».

Le modèle `ItemCapabilityTruth` sépare :

- l’ensemble global des contextes supportés ;
- l’ensemble global des effets supportés ;
- les identifiants sémantiques supportés ;
- les identifiants held supportés.

Il ne peut pas exprimer la relation indispensable **contexte × type d’effet**. Par exemple, le moteur sait restaurer des PP en overworld, mais le bridge battle ne sait pas appliquer `restore_pp`. Le validator vérifie pourtant séparément que `battle` est un contexte connu et que `restore_pp` est un effet connu, puis accepte leur combinaison.

Plus grave, les adaptateurs authoring et editor construisent la vérité avec :

- tous les contextes de l’enum ;
- tous les effets de l’enum ;
- tous les `semanticActionId` trouvés dans le catalogue en cours de validation ;
- tous les `heldEffectId` trouvés dans ce même catalogue ;
- `supportsCapture: true` et `supportsMoveMachines: true`.

Le catalogue sert donc de preuve de sa propre exécutabilité. C’est l’équivalent logiciel d’un suspect qui signe lui-même son certificat d’alibi, avec un joli tampon vert en prime.

**Code concerné :**

- `packages/map_core/lib/src/read_models/item_capability_truth.dart:15-46` ;
- `packages/map_core/lib/src/validation/project_item_catalog_validator.dart:198-219` ;
- `packages/map_core/lib/src/validation/project_item_catalog_validator.dart:298-309` ;
- `packages/map_core/lib/src/validation/project_item_catalog_validator.dart:479-493` ;
- `packages/map_authoring/lib/src/workspace/project_query_service.dart:1226-1241` ;
- `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart:279-302`.

**Contradictions runtime :**

- le battle bridge ne prend en charge que heal, cure et revive : `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart:311-365` ;
- le moteur overworld refuse `repel` et les actions sémantiques non enregistrées : `packages/map_gameplay/lib/src/player_item_effects.dart:74-108` ;
- le runtime held item peut résoudre un effet comme unsupported et le rejeter au démarrage du combat : `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:400-429`.

**Reproduction exécutable live :**

Un projet jetable a reçu via les mutations MCP officielles une définition contenant simultanément :

- `repel` en overworld ;
- `restore_pp` en battle ;
- `heldEffectId: never_registered_effect`.

Les opérations plan/apply ont réussi. La ressource `itemReadiness` a ensuite répondu :

```json
{
  "ready": true,
  "diagnosticCount": 0,
  "diagnostics": []
}
```

Ce résultat suffit à invalider le statut global CERTIFIED, car trois capacités non exécutables ont traversé exactement la frontière censée les arrêter avant playtest.

**Correction minimale requise :**

- définir un registre de capacités possédé par le moteur, indépendant du catalogue utilisateur ;
- représenter les couples contexte/effet supportés ;
- fournir des registries explicites pour semantic actions et held effects ;
- injecter la même vérité dans core, authoring, editor, runtime et certification ;
- ajouter des tests négatifs sur toutes les combinaisons non supportées.

### AUD-ITM-002 — P0 — La rupture stricte des anciennes sauvegardes n’est pas totale

**Promesses violées :** ITM-023, ITM-062, ITM-088 et les règles « aucun dual reader » et « tout `categoryId` est refusé ».

Le chemin principal est correct :

- `GameStatePersistence` possède le marqueur de schéma Item ;
- `FileGameSaveRepository` l’écrit ;
- `GameSaveCodecExecutor` le valide avant décodage.

Mais le pont canonique `GameStateSaveEnvelopeMapper` crée l’enveloppe avec `GameState.toJson()` et restaure avec `GameState.fromJson()` sans passer par `SaveItemSchemaGuard` ni `validateItemSystemSaveSchema`.

**Code concerné :**

- `packages/map_core/lib/src/save/game_state_save_envelope_mapper.dart:29-42` ;
- `packages/map_core/lib/src/save/game_state_save_envelope_mapper.dart:45-58` ;
- `examples/playable_runtime_host/lib/src/evaluation/runner/evaluation_checkpoint_cache.dart:181-197` ;
- les lecteurs directs analogues du host doivent être inventoriés et supprimés.

Le générateur JSON de `BagEntry` ne lit que `itemId` et `quantity` et ignore les clés supplémentaires. Sans le garde strict placé avant lui, `categoryId` redevient donc silencieusement accepté.

**Reproduction exécutable :**

Un `SaveEnvelope` a été construit avec une entrée :

```json
{
  "itemId": "potion",
  "quantity": 2,
  "categoryId": "medicine"
}
```

`GameStateSaveEnvelopeMapper.restore` l’a accepté et a restauré `potion ×2`. Le probe a produit :

```text
{acceptedLegacyCategoryId: true, restoredItemId: potion, restoredQuantity: 2}
```

Les tests actuels de ce mapper ne vérifient que le round-trip et l’identité ; ils ne testent ni le marqueur Item V1 ni le rejet des clés historiques.

**Correction minimale requise :**

- une seule fonction canonique de sérialisation et de restauration du `GameState` ;
- passage obligatoire par le garde strict dans File repository, SaveEnvelope et checkpoints ;
- suppression de tous les `GameState.fromJson` de persistance directe ;
- tests de contrat partagés injectés dans chaque repository/codec ;
- probe de régression avec marqueur absent, mauvaise version, `categoryId` et clé inconnue.

### AUD-ITM-003 — P1 — La protection des key items est contournable par les mutations publiques

**Promesses violées :** ITM-024, ITM-041, ITM-055 et la règle « un key item n’est pas consommable par défaut ».

`BagOperations.consume` sait protéger un key item si les tags lui sont fournis. `GameStateMutations.sellItem` consulte également le catalogue et bloque correctement la vente.

En revanche, `GameStateMutations.consumeItem` appelle directement `_bagOperations.take` sans catalogue, tags, raison de consommation ni autorisation explicite. Ce chemin est utilisé ou exposé par plusieurs frontières production/playtest, notamment :

- `packages/map_gameplay/lib/src/game_state_mutations.dart:740-753` ;
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:230-258` ;
- `packages/map_gameplay/lib/src/sandbox_player_state.dart:153-161` ;
- `packages/map_authoring/lib/src/application/playtest_player_state_service.dart:41-51`.

**Reproduction exécutable :**

Un état contenant `lab-key ×1` a été transmis à `GameStateMutations.consumeItem`. Le résultat était :

```text
before=1, after=0, catalogConsulted=false
```

Une conséquence narrative peut légitimement retirer une clé, mais cette intention doit être explicite. L’API actuelle ne distingue pas « utiliser un consommable » de « retirer volontairement un objet-clé par scénario ».

**Correction minimale requise :**

- retirer ou restreindre le helper public sans contexte ;
- exiger un `ItemCatalogSnapshot` et une raison typée ;
- rendre l’override key item explicite et false par défaut ;
- donner aux conséquences narratives une commande distincte et auditée si le retrait de clé est voulu.

### AUD-ITM-004 — P1 — Le certificat L0-L6 certifie la fixture signée, pas tout le produit authorable

**Promesses concernées :** ITM-072, ITM-087 à ITM-090 et ITM-105.

La certification n’est plus un simple test de modèle. Le runner exécute réellement des collectors, recalcule les hashes et lie ses receipts à :

- la révision `59cac1d29d3b20a4691fe4158de52fcce0b4e927` ;
- la fixture Golden ;
- les payloads et états observés.

Le bundle frais annonce :

- `overallStatus: CERTIFIED` ;
- L0 à L6 : `CERTIFIED` ;
- aucun evidence gap ;
- hash fixture `087542aa5a9bd3c3b59f5da36ebe0e1d1af53c09162fd25404b5d090886d2048`.

Mais `item_system_schema_evidence_collector.dart` reconstruit lui aussi une vérité de capacité maximiste. Le runner ne lance que la fixture Golden, dont les définitions évitent précisément les combinaisons invalides : Ether est overworld-only, Repel est absent, les held effects sont connus.

Le certificat prouve donc honnêtement :

> « Cette fixture signée et ces opérations choisies ont produit les observations attendues sur cette révision. »

Il ne prouve pas :

> « Toute configuration que l’Item Studio ou le MCP déclare prête est exécutable par le produit. »

Le second énoncé est pourtant celui que suggère `overallStatus: CERTIFIED` et il est contredit par AUD-ITM-001.

**Correction minimale requise :**

- faire dépendre L0/L1 du registre moteur réel ;
- ajouter une matrice négative signée ;
- séparer `GOLDEN_FIXTURE_CERTIFIED` de `PRODUCT_CAPABILITY_CLOSED` ;
- interdire le verdict produit CERTIFIED si une capacité authorable n’a pas de consommateur runtime certifié.

### AUD-ITM-005 — P1 — La matrice finale globale reste rouge

Les tests ciblés Item sont verts, mais plusieurs suites complètes ne le sont pas. Une partie importante des échecs est hors périmètre Item ou dépend d’artefacts externes ; elle ne doit pas être imputée artificiellement à ce chantier. Deux échecs runtime sont toutefois directement révélateurs du cutover : des tests continuent d’attendre le chargement d’anciens JSON alors que la compatibilité devait être supprimée.

Résultats frais :

| Package | Résultat suite complète | Lecture audit |
|---|---:|---|
| `map_core` | 4 147 réussis, 7 échoués, 1 ignoré | plusieurs drifts hors scope ; deux tests de fixtures utilisent aussi des chemins invalides |
| `map_gameplay` | 468/468 | vert |
| `map_battle` | 1 746 réussis, 28 échoués | principalement artefacts PSDK externes absents |
| `map_authoring` | 575/575 | vert |
| `map_runtime` | 2 313 réussis, 3 échoués, 1 ignoré | deux tests legacy save/load encore rouges après cutover ; un golden visuel hors scope |
| `map_player_ui` | 221/221 | vert |
| `playable_runtime_host` | 271 réussis, 16 échoués, 3 ignorés | plusieurs journeys/evaluations Selbrume ou règles de source restent rouges |
| `map_editor` | run interrompu après 16 min sans progression : au moins 5 424 réussis, 108 échoués, 11 ignorés | les tests Item ciblés sont verts ; la suite globale est rouge et finit bloquée |
| `pokemap_product_certification` | 22/22 | vert, mais périmètre insuffisant selon AUD-ITM-004 |

Échecs runtime directement liés à la politique de rupture :

- `narrative_event_progress_save_load_test` attend encore qu’un ancien `GameState` sans progression charge ;
- `narrative_fact_runtime_save_load_test` attend encore le chargement d’un ancien JSON disque.

Ces tests auraient dû être supprimés ou réécrits lors de la suppression explicite de la compatibilité. Leur présence ne prouve pas nécessairement que le chemin principal accepte encore l’ancien format, mais prouve que la bascule n’a pas été nettoyée jusqu’au bout.

### AUD-ITM-006 — P1 — Repel est différé par la roadmap mais encore authorable dans l’Item Studio

ITM-034 et FG-065 sont explicitement différés. Le runtime overworld rejette l’effet `repel`. Pourtant `item_effect_editor.dart` propose encore « Repousse 100 pas » parmi les effets guidés.

Le produit permet donc à un utilisateur no-code de sélectionner une capacité que la roadmap déclare hors périmètre et que le moteur refuse. Cette option doit être masquée/désactivée avec une raison honnête, ou le runtime Repel doit être implémenté et certifié dans un nouveau lot produit.

**Code concerné :** `packages/map_editor/lib/src/features/gameplay/items/item_effect_editor.dart:423-459`.

### AUD-ITM-007 — P2 — Une observation L6 hidden item est attribuée au runner sans traverser le renderer

Le Golden runner vérifie l’état authoré de l’entité cachée et enregistre `hidden_pickup_not_rendered`, mais il ne passe pas lui-même par le renderer Flame pour produire cette observation.

Des tests runtime séparés couvrent réellement le masquage et passent. Le comportement produit est donc prouvé, mais la provenance de l’observation L6 est trop ambitieuse. Le receipt devrait référencer la preuve runtime externe ou renommer l’observation en `hidden_pickup_authored_hidden`.

### AUD-ITM-008 — P2 — La roadmap est déjà obsolète sur ITM-085

La roadmap indique que le MCP global ne publie pas encore les ressources/actions Item. Le contrôle live frais montre désormais :

- les quatre ressources Item attendues ;
- les neuf actions `item.*` ;
- les quatre transports déclarés ;
- les neuf plan/apply/requery exécutés avec succès sur une copie jetable.

ITM-085 peut donc être proposé `DONE` sur l’état live actuel. Cela ne ferme pas l’Item System, car AUD-ITM-001 à AUD-ITM-006 remplacent ce blocker devenu caduc par des écarts plus fondamentaux.

## 5. Ce qui est réellement terminé

Les éléments suivants ont des preuves de code et d’exécution suffisantes dans leur périmètre :

- modèles V1 et codec de catalogue strict ;
- seed MVP canonique ;
- identité de pile uniquement par `itemId` ;
- normalisation, overflow checks et receipts atomiques du Bag ;
- `PlayerItemUseService` pour heal, cure, revive et PP overworld ;
- heal, cure et revive battle via le bridge générique ;
- capture et consommation de la Ball sélectionnée ;
- achats, ventes ordinaires, rewards, New Game et pickups ;
- évolution et TM/HM sur les parcours certifiés ;
- equip/swap/unequip des held items sur les contrôles joueur ajoutés ;
- hidden item authoré et masqué, avec pickup idempotent ;
- Item Studio no-code et mutations authoring canoniques ;
- quatre ressources Item et neuf mutations sur API directe, JSONL, Editor adapter et MCP ;
- fixture Golden autonome et runner déterministe ;
- infrastructure de receipts et de hashes de certification ;
- conversion ciblée de la fixture Selbrume en V6 et test ciblé de boutique dynamique ;
- serveur MCP live courant rechargé avec les contrats Item.

## 6. Matrice auditée des 59 lots

Légende :

- **CONFORME** : résultat du lot présent et preuve proportionnée ;
- **PARTIEL** : implémentation présente mais un critère promis ou une preuve de clôture est invalidé ;
- **DIFFÉRÉ** : décision produit explicite, non implémentée.

| Phase | Lot | Verdict audit | Motif synthétique |
|---:|---|---|---|
| 0 | ITM-001 | CONFORME | inventaire de rupture et caractérisation présents |
| 1 | ITM-010 | CONFORME | modèles V1 canoniques présents |
| 1 | ITM-011 | CONFORME | codec catalogue strict et fail-closed |
| 1 | ITM-012 | CONFORME | seed MVP canonique |
| 1 | ITM-013 | PARTIEL | capability truth non indépendante et sans matrice contexte × effet |
| 1 | ITM-014 | CONFORME | loader partagé et ports canoniques |
| 2 | ITM-020 | CONFORME | stack identity `itemId` et wire Bag V1 |
| 2 | ITM-021 | CONFORME | BagOperations et receipts atomiques |
| 2 | ITM-022 | CONFORME | usage overworld canonique sur capacités réellement supportées |
| 2 | ITM-023 | PARTIEL | garde strict présent, mais contourné par SaveEnvelope/checkpoints |
| 2 | ITM-024 | PARTIEL | give/sell adaptés ; `consumeItem` contourne la policy key item |
| 3 | ITM-025 | CONFORME | classification principale par capacités |
| 3 | ITM-026 | CONFORME | valeurs heal unifiées |
| 3 | ITM-027 | PARTIEL | diagnostic runtime honnête, readiness authoring mensongère |
| 3 | ITM-030 | CONFORME | Bag overworld canonique |
| 3 | ITM-031 | PARTIEL | sous-ensemble battle fonctionne ; restore PP battle est authorable mais inexécutable |
| 3 | ITM-032 | CONFORME | Ball choisie propagée et consommée |
| 3 | ITM-033 | CONFORME | capture minimale exécutée |
| 3 | ITM-034 | DIFFÉRÉ | Repel non implémenté par décision produit |
| 3 | ITM-035 | CONFORME | machines chargées depuis le catalogue |
| 3 | ITM-036 | CONFORME | TM/HM sur parcours certifiés |
| 3 | ITM-037 | CONFORME | opérations held item |
| 3 | ITM-038 | PARTIEL | runtime fail-closed, mais held effect inconnu déclaré ready par authoring |
| 4 | ITM-040 | CONFORME | New Game sur Bag V1 |
| 4 | ITM-041 | PARTIEL | conséquences give/take présentes, retrait key item non explicitement autorisé |
| 4 | ITM-042 | CONFORME | pickups et idempotence |
| 4 | ITM-043 | CONFORME | shops et protection de vente key item |
| 4 | ITM-044 | CONFORME | rewards canoniques |
| 5 | ITM-050 | PARTIEL | ressources présentes, vérité readiness invalide |
| 5 | ITM-051 | PARTIEL | mutations présentes, configurations runtime impossibles acceptées |
| 5 | ITM-052 | PARTIEL | Item Studio complet, mais offre notamment Repel inexécutable |
| 5 | ITM-053 | PARTIEL | pickers basés sur une readiness auto-certifiée |
| 5 | ITM-054 | CONFORME | neuf actions réellement exécutées sur quatre transports |
| 5 | ITM-055 | PARTIEL | frontière playtest bornée, `bag.consume` reste sans policy key item |
| 6 | ITM-060 | CONFORME | anciennes décisions par catégorie retirées des chemins principaux |
| 6 | ITM-061 | PARTIEL | wrappers battle retirés, mais helper medicine/consume parallèle encore public |
| 6 | ITM-062 | PARTIEL | ancien wire retiré du garde principal, lecteur secondaire encore tolérant |
| 7 | ITM-070 | CONFORME | fixture Golden autonome et stricte |
| 7 | ITM-071 | CONFORME | parcours Golden réellement exécuté par API production |
| 7 | ITM-072 | PARTIEL | modèle/runner réels, verdict produit sur-généralisé |
| 7 | ITM-073 | CONFORME | matrice exécutée et résultats rouges documentés |
| 7 | ITM-074 | CONFORME | roadmap mécanique recertifiée avec PARTIAL/DEFERRED explicites |
| 8 | ITM-080 | CONFORME | parité fail-closed |
| 8 | ITM-081 | CONFORME | neuf actions direct API et JSONL |
| 8 | ITM-082 | CONFORME | neuf actions Editor adapter |
| 8 | ITM-083 | CONFORME | neuf actions MCP |
| 8 | ITM-084 | CONFORME | smoke MCP packagé |
| 8 | ITM-085 | CONFORME | smoke live actuel réussi ; roadmap à actualiser |
| 8 | ITM-086 | CONFORME | receipts canoniques liés aux sources |
| 8 | ITM-087 | PARTIEL | collector L0/L1 réutilise la fausse capability truth |
| 8 | ITM-088 | PARTIEL | L2 ignore SaveEnvelope/checkpoints et L3 ne couvre que le Golden valide |
| 8 | ITM-089 | CONFORME | runner reproductible et bundles canoniques |
| 8 | ITM-090 | PARTIEL | statut final CERTIFIED incompatible avec les probes hostiles |
| 9 | ITM-100 | CONFORME | contrôles joueur held item testés |
| 9 | ITM-101 | CONFORME | parcours HM joueur testé |
| 9 | ITM-102 | CONFORME | hidden item réellement couvert par tests runtime ciblés |
| 9 | ITM-103 | CONFORME | fixture Selbrume ciblée convertie en V6 |
| 9 | ITM-104 | CONFORME | boutique dynamique ciblée recertifiée |
| 9 | ITM-105 | PARTIEL | la clôture produit est contredite par les findings P0/P1 |

### Comptage révisé

| Statut audit | Nombre |
|---|---:|
| CONFORME | 39 |
| PARTIEL | 19 |
| DIFFÉRÉ | 1 |
| Total | 59 |

Ce comptage ne signifie pas que 20 lots sont à réécrire entièrement. Plusieurs sont partiels par propagation d’une même cause racine. La correction de la capability truth refermera à elle seule une large partie des lots 013, 027, 031, 038, 050 à 053, 087, 088 et 090.

## 7. Preuves ciblées fraîches

Les suites ciblées Item exécutées pendant l’audit sont vertes :

| Périmètre | Résultat |
|---|---:|
| `map_core` Item/save ciblé | 39 réussis |
| `map_gameplay` Item ciblé | 29 réussis |
| `map_authoring` Item ciblé | 24 réussis |
| `map_runtime` Item/save/render ciblé | 76 réussis |
| `map_player_ui` Item ciblé | 18 réussis |
| `map_editor` Item Studio ciblé | 13 réussis |
| `playable_runtime_host` Golden/Selbrume ciblé | 11 réussis |
| `pokemap_product_certification` | 22 réussis |

Analyses statiques fraîches :

- `map_core` : exit 0, 121 infos de baseline, aucune erreur ;
- `map_gameplay` : exit 0, 1 info de baseline ;
- `map_battle` : aucune issue ;
- `map_authoring` : aucune issue ;
- `map_runtime` ciblé : aucune issue ;
- `map_player_ui` : aucune issue ;
- `map_editor` Item ciblé : aucune issue ;
- `playable_runtime_host` ciblé : aucune issue ;
- `pokemap_product_certification` : aucune issue.

Preuves MCP fraîches :

- `npm run check` : succès ;
- `npm run build` : succès ;
- tests officiels `item_authoring.test.ts` et `live_item_smoke.test.ts` : 2/2 ;
- les neuf actions `item.*` ont chacune exécuté plan, apply, requery et validation structurelle sur un projet jetable ;
- le describe live expose désormais les ressources Item et les neuf mutations avec parité sur quatre transports.

## 8. Commandes globales et résultat

Les commandes ont été exécutées package par package, sans masquer l’analyse derrière un `test && analyze`.

| Commande | Résultat exact utile |
|---|---|
| `cd packages/map_core && dart test` | 4 147 pass, 7 fail, 1 skip |
| `cd packages/map_gameplay && dart test` | 468/468 |
| `cd packages/map_battle && dart test` | 1 746 pass, 28 fail |
| `cd packages/map_authoring && dart test` | 575/575 |
| `cd packages/map_runtime && flutter test` | 2 313 pass, 3 fail, 1 skip |
| `cd packages/map_player_ui && flutter test` | 221/221 |
| `cd examples/playable_runtime_host && flutter test` | 271 pass, 16 fail, 3 skip |
| `cd tools/pokemap_product_certification && flutter test` | 22/22 |
| `cd packages/map_editor && flutter test -r compact` | interrompu par SIGINT après plus de 4 min sans progression ; dernier compteur `+5424 ~11 -108`, exit 130 |
| `cd tools/pokemap_mcp && npm run check` | succès |
| `cd tools/pokemap_mcp && npm run build` | succès |

Les échecs globaux hors Item n’ont pas été corrigés ni attribués artificiellement au chantier. Ils empêchent néanmoins d’utiliser « tout le monorepo est vert » comme argument de clôture.

## 9. Plan minimal restant pour tenir réellement la cible

### Lot R1 — Registre moteur de capability truth

- remplacer les ensembles maximistes par un contrat possédé par le moteur ;
- encoder contexte × effet ;
- enregistrer explicitement semantic actions et held effects ;
- faire consommer cette vérité par validator, resources, pickers, Studio et certification ;
- ajouter une matrice négative.

**Ferme principalement :** AUD-ITM-001 et AUD-ITM-006.

### Lot R2 — Unification stricte de tous les codecs de sauvegarde

- centraliser write/read ;
- brancher SaveEnvelope et checkpoint cache sur le garde strict ;
- supprimer les `GameState.fromJson` de persistance directe ;
- ajouter des contract tests communs à chaque repository.

**Ferme principalement :** AUD-ITM-002 et les tests legacy encore rouges.

### Lot R3 — Autorité explicite de consommation des key items

- supprimer le helper public context-free ;
- introduire une commande de retrait scénaristique explicite ;
- propager catalogue, raison et autorisation ;
- tester playtest, Scene, TM, évolution et usages directs.

**Ferme principalement :** AUD-ITM-003.

### Lot R4 — Certification hostile et statuts honnêtes

- signer les probes négatifs ;
- séparer certification de fixture et fermeture du produit ;
- recoller les observations L6 à leur exécuteur réel ;
- invalider le certificat si une définition authorable est inexécutable.

**Ferme principalement :** AUD-ITM-004 et AUD-ITM-007.

### Lot R5 — Nettoyage de cutover et matrice finale

- supprimer/réécrire les tests qui réclament encore les anciens saves ;
- qualifier les échecs globaux restants par baseline ou régression ;
- rerun complet sérialisé ;
- mettre à jour les roadmaps Item et FG avec les preuves fraîches ;
- ne clôturer ITM-105 qu’après succès des invariants hostiles.

**Ferme principalement :** AUD-ITM-005 et AUD-ITM-008.

## 10. Fichiers et zones les plus significatifs inspectés

### Contrats et validation

- `packages/map_core/lib/src/read_models/item_capability_truth.dart` ;
- `packages/map_core/lib/src/validation/project_item_catalog_validator.dart` ;
- `packages/map_core/lib/src/models/items/` ;
- `packages/map_core/lib/src/operations/game_state_persistence.dart` ;
- `packages/map_core/lib/src/save/game_state_save_envelope_mapper.dart` ;
- `packages/map_core/lib/src/models/save_data.g.dart`.

### Gameplay et runtime

- `packages/map_gameplay/lib/src/items/bag_operations.dart` ;
- `packages/map_gameplay/lib/src/player_item_effects.dart` ;
- `packages/map_gameplay/lib/src/game_state_mutations.dart` ;
- `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart` ;
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart` ;
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart` ;
- `packages/map_runtime/lib/src/infrastructure/game_save_codec_executor.dart` ;
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`.

### Authoring, UI et transports

- `packages/map_authoring/lib/src/workspace/project_query_service.dart` ;
- `packages/map_authoring/lib/src/application/playtest_player_state_service.dart` ;
- `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart` ;
- `packages/map_editor/lib/src/features/gameplay/items/item_effect_editor.dart` ;
- `tools/pokemap_mcp/` et ses tests Item officiels.

### Golden flow et certification

- `examples/playable_runtime_host/golden_item_system/` ;
- `examples/playable_runtime_host/lib/src/golden_item_system_journey.dart` ;
- `examples/playable_runtime_host/lib/src/evaluation/runner/evaluation_checkpoint_cache.dart` ;
- `tools/pokemap_product_certification/lib/src/` ;
- `tools/pokemap_product_certification/test/`.

## 11. État Git et impact de l’audit

État initial du worktree audité : propre.

Révision initiale et auditée : `59cac1d29d3b20a4691fe4158de52fcce0b4e927`.

Le checkout principal possédait déjà quatre modifications Character Studio sans rapport avec l’Item System ; elles n’ont pas été touchées.

Seul ce rapport Markdown est ajouté par l’audit. Aucun fichier de production, test, fixture ou roadmap n’est modifié.

## 12. Auto-critique et limites

- Les probes hostiles démontrent des défauts réels, mais ne constituent pas encore une matrice exhaustive de toutes les combinaisons d’effets et contextes.
- Les suites globales contiennent des échecs préexistants ou dépendants d’artefacts externes. Ils sont rapportés comme risque de clôture, pas comme régressions Item certaines.
- La validation visuelle desktop complète de l’Item Studio n’a pas été rejouée par automatisation UI réelle pendant cet audit ; les widget tests ciblés sont verts.
- Le certificat JSON et les receipts ont été générés dans `/tmp` pour inspection et ne sont pas ajoutés au dépôt.
- Le MCP live a été vérifié sur des copies jetables, pas sur un projet utilisateur.
- Le comptage lot par lot est volontairement conservateur : un lot devient PARTIEL dès qu’un invariant explicitement promis est contredit, même si 90 % de son implémentation est présente.

## 13. Verdict final

**Non : l’Item System V1 n’est pas terminé au sens de la cible initiale.**

Il est suffisamment avancé pour faire fonctionner et certifier un parcours Golden représentatif. Il n’est pas encore suffisamment fermé pour garantir que tout objet déclaré « prêt » par l’authoring est réellement exécutable, que tous les chemins de sauvegarde respectent la rupture stricte, ni que les key items sont protégés par défaut sur toutes les mutations publiques.

La bonne suite n’est pas de refaire tout le système. Elle consiste à fermer cinq lots transversaux précis : vérité moteur, persistance unique, autorité key item, certification hostile et matrice finale. Après ces lots, une nouvelle clôture de phase 9 pourra être défendue sans astérisque de la taille d’un Ronflex.
