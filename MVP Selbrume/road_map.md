Oui. Et avec ton recadrage, la roadmap doit être **corrigée en profondeur**.

Le bon cap n’est plus :

```text
Créer les contenus Selbrume dans le repo.
```

Le bon cap est :

```text
Ajouter les mécaniques génériques manquantes
pour que toi, ensuite, tu puisses créer Selbrume dans l’éditeur.
```

Selbrume reste notre **scénario de référence / banc d’essai**, parce qu’il force PokeMap à relier map, PNJ, dialogues, scènes, combats, facts, world rules, sauvegarde et validation. Mais on ne cherche pas à produire tout le jeu Selbrume maintenant.

Le vrai problème identifié reste exactement celui-ci : PokeMap a déjà beaucoup de pièces, mais il faut les câbler en **boucle jouable**.

# Roadmap complète corrigée

## État actuel

| Lot                                        |                         Statut | Commentaire                                                                     |
| ------------------------------------------ | -----------------------------: | ------------------------------------------------------------------------------- |
| NS-GS-00A — Product Model                  |                         ✅ fait | Vision Narrative Studio                                                         |
| NS-GS-00B — Readiness Audit corrigé        |                         ✅ fait | Selbrume comme référence                                                        |
| NS-GS-00C — Glossaire                      |                         ✅ fait | vocabulaire Event / Scene / Fact / Step                                         |
| NS-GS-00D — Event → Scene → Outcome → Fact |                         ✅ fait | contrat runtime minimal                                                         |
| NS-GS-00E — Battle from Scene              |                         ✅ fait | combat depuis ScenarioAsset                                                     |
| NS-GS-00F — giveItem → Bag                 |                         ✅ fait | inventaire corrigé                                                              |
| NS-GS-01 / 01-bis                          |                         ✅ fait | spec Golden Slice + roadmap corrigée                                            |
| NS-GS-02 / 02-bis                          |                         ✅ fait | décision : Maël donne réellement le starter                                     |
| NS-GS-03 / 03-bis                          | ✅ fait mais à recontextualiser | inventaire utile, mais ne doit pas devenir “fixtures créées par agent”          |
| NS-GS-04                                   |      ✅ fait (recontextualisé) | stratégie de preuve utile ; à lire comme preuves de mécaniques, pas comme fixtures à créer |
| NS-GS-04-bis                               |                        ✅ fait | roadmap realignée mechanics-first, règle permanente inscrite, rapport livré     |

---

# Principe de gouvernance corrigé

## Ce que les agents doivent faire

```text
ajouter des mécaniques génériques
ajouter des actions runtime réutilisables
ajouter les contrats nécessaires
ajouter les validations nécessaires
améliorer l’authoring dans l’éditeur si nécessaire
créer des tests unitaires / intégration minimaux
créer éventuellement des objets de test in-memory
```

## Ce que les agents ne doivent pas faire

```text
créer les maps Selbrume finales
créer les PNJ Selbrume finaux
écrire les dialogues finaux
créer les ScenarioAssets finaux de Selbrume
créer les trainers/battles finaux de Selbrume
créer les fixtures projet Selbrume à ta place
remplir un project.json Selbrume complet
```

## Exception acceptable

Les agents peuvent créer des **fixtures de test techniques minimales** si elles sont nécessaires à un test automatisé, mais pas du contenu Selbrume auteur. Autrement dit :

```text
✅ Objet de test in-memory pour vérifier GivePokemon
✅ Mini ScenarioAsset de test dans un fichier de test
✅ Fake map minimal pour tester une world rule

❌ map_bourg_selbrume finale
❌ yarn_mael_intro final
❌ trainer_lysa_port final
❌ project Selbrume complet préfabriqué
```

---

# Phase 1 — Alignement avant code

## NS-GS-04-bis — Mechanics-First Roadmap Alignment

| Champ                     | Détail                                                                                        |
| ------------------------- | --------------------------------------------------------------------------------------------- |
| Type                      | Documentaire correctif                                                                        |
| Objectif                  | Corriger NS-GS-03/04 pour dire que les fixtures Selbrume seront créées par toi dans l’éditeur |
| Code                      | ❌ non                                                                                         |
| Pourquoi                  | Éviter que Codex parte créer Selbrume dans le repo                                            |
| Sortie                    | rapport ou patch documentaire court                                                           |
| Prochain après validation | NS-GS-05                                                                                      |

À corriger dans les docs :

```text
NS-GS-08/09/10/11 ne sont plus “créer contenu Selbrume”
mais “rendre authorable / exécutable ce type de contenu”.
```

---

# Phase 2 — Socle runtime générique

## NS-GS-05 — New Game Minimal Runtime

| Champ             | Détail                                               |
| ----------------- | ---------------------------------------------------- |
| Type              | Code runtime générique                               |
| Objectif          | Permettre de démarrer une nouvelle partie proprement |
| Ne doit pas faire | créer Selbrume                                       |
| Package probable  | map_runtime + peut-être playable_runtime_host        |
| Tests             | oui                                                  |

But générique :

```text
créer un GameState initial propre
définir une map de départ depuis le projet
définir une position de départ depuis le projet
démarrer avec party vide si le projet le demande
charger ensuite le projet créé dans l’éditeur
```

Ce lot ne doit pas hardcoder :

```text
map_bourg_selbrume
entity_mael_bourg
sproutle
Lysa
```

Il doit plutôt permettre :

```text
ProjectManifest.startMapId
ProjectManifest.startSpawnId ou équivalent
initial party policy
initial bag policy
initial flags vides
```

Résultat attendu :

```text
PokeMap sait lancer une nouvelle partie générique.
```

---

## NS-GS-06 — GivePokemon Minimal

| Champ             | Détail                                                 |
| ----------------- | ------------------------------------------------------ |
| Type              | Code gameplay/runtime générique                        |
| Objectif          | Ajouter un Pokémon à la party via une action narrative |
| Ne doit pas faire | créer Sproutle dans un projet Selbrume                 |
| Package probable  | map_gameplay + map_runtime + map_core si besoin        |
| Tests             | obligatoires                                           |

Mécanique générique :

```text
Action narrative GivePokemon
→ crée ou reçoit un PlayerPokemon
→ ajoute à GameState.party
→ empêche doublons si demandé
→ compatible save/load
```

Non-objectifs :

```text
pas de choix de starter
pas d’UI starter complète
pas de PC
pas de système complet de cadeaux Pokémon
pas de modèle “tous les jeux commencent par starter”
```

Ce lot est devenu obligatoire, parce que tu veux que le joueur reçoive réellement le Pokémon en jeu, pas qu’il soit préchargé magiquement.

---

## NS-GS-07 — Step Completion / Progression Hooks V0

| Champ             | Détail                                                                     |
| ----------------- | -------------------------------------------------------------------------- |
| Type              | Code runtime générique ou audit+code conditionnel                          |
| Objectif          | Permettre de compléter une étape d’histoire depuis une action/fact/outcome |
| Ne doit pas faire | câbler les steps Selbrume finaux                                           |
| Tests             | oui                                                                        |

À vérifier / ajouter :

```text
CompleteStep action
Step completed when fact set
Step completed when scene outcome emitted
Step completed after cutscene end
Step progression persisted in save/load
```

Pourquoi c’est important : Selbrume demande de passer de “starter reçu” à “mission reçue”, puis “rival battu”, etc. Le document de stratégie rappelle que la progression doit être vérifiée par steps/facts/world rules et que `whenCutsceneEnds` peut ne pas suffire.

---

# Phase 3 — Authoring / runtime bridge générique

Cette phase remplace les anciens lots “Bourg Selbrume / Port Brisants Content”.

## NS-GS-08 — NPC Interaction → Scene Authoring Readiness

| Champ             | Détail                                                          |
| ----------------- | --------------------------------------------------------------- |
| Type              | Runtime/editor readiness                                        |
| Ancien sens       | Bourg Selbrume / Maël Content                                   |
| Nouveau sens      | Permettre à l’éditeur d’authorer un PNJ qui déclenche une scène |
| Ne doit pas faire | créer Maël                                                      |

À prouver :

```text
un NPC créé dans l’éditeur peut référencer une scène
une interaction joueur → PNJ lance cette scène
la scène peut déclencher des actions gameplay
la scène peut poser des facts
la scène peut émettre des outcomes
la scène peut être rejouée ou bloquée selon condition
```

Cas de référence :

```text
“Maël donne un starter”
```

Mais l’agent doit implémenter :

```text
“un PNJ peut donner un Pokémon et poser une mission”
```

Pas :

```text
“créer npc_mael dans le repo”
```

---

## NS-GS-09 — Yarn Outcome → Scene Branch Readiness

| Champ             | Détail                                                                                  |
| ----------------- | --------------------------------------------------------------------------------------- |
| Type              | Runtime/editor readiness                                                                |
| Ancien sens       | Port Brisants / Lysa Content                                                            |
| Nouveau sens      | Permettre à l’éditeur d’authorer un dialogue Yarn avec outcomes qui branchent une scène |
| Ne doit pas faire | écrire yarn_rival_intro final                                                           |

À prouver :

```text
Yarn expose des outcomes déclarés
Scene peut lire ces outcomes
Scene peut brancher selon outcome
Scene peut jouer une cinematic placeholder
Scene peut continuer vers une action suivante
```

Cas de référence :

```text
confident / hesitant / aggressive
→ cinematic_rival_smiles / cinematic_rival_teases
```

L’audit mécanique insiste justement sur le besoin d’un vrai Yarn Bridge : Yarn Node → outcomes déclarés → Scene Branch → Scene Outcome → Event/Facts si nécessaire.

---

## NS-GS-10 — World Rules / Conditional Presence Readiness

| Champ             | Détail                                           |
| ----------------- | ------------------------------------------------ |
| Type              | Runtime/editor readiness                         |
| Ancien sens       | Storyline Chapter 1 Wiring                       |
| Nouveau sens      | Permettre de modifier le monde selon facts/steps |
| Ne doit pas faire | câbler Lysa finale                               |

À prouver :

```text
un élément / PNJ peut être visible selon Fact
un élément / PNJ peut être interactable selon Fact
un dialogue peut changer selon Fact
les world rules se recalculent après event
les world rules se recalculent après save/load
```

Cas de référence :

```text
Lysa accessible seulement si :
fact_starter_received
AND fact_mission_started
AND NOT fact_rival_battle_done
```

C’est un vrai bloc manquant identifié : sans World Rules, les scènes peuvent se déclencher, mais le monde ne change pas vraiment.

---

## NS-GS-11 — Trainer Battle Authoring Readiness

| Champ             | Détail                                                                    |
| ----------------- | ------------------------------------------------------------------------- |
| Type              | Runtime/editor readiness                                                  |
| Ancien sens       | Battle Lysa Authoring Fixture                                             |
| Nouveau sens      | Permettre à l’éditeur d’authorer un combat trainer lancé depuis une scène |
| Ne doit pas faire | créer trainer_lysa_port final                                             |

À prouver :

```text
un trainer créé dans le manifest/editor est résolvable
un NPC peut référencer ce trainer
une scène peut lancer startTrainerBattle
battleId/trainerId/npcEntityId sont cohérents
victory/defeat posent les bons flags
la scène reprend après combat
les branches victory/defeat peuvent poser des facts
```

Le rapport NS-GS-04 liste déjà `start_trainer_battle_from_scene`, `battle_victory_sets_flags_and_continues` et `battle_defeat_sets_flags_and_continues` comme tests clés.

---

# Phase 4 — Validation globale par projet créé dans l’éditeur

## NS-GS-12 — Editor-authored Golden Slice Validation

| Champ             | Détail                                |
| ----------------- | ------------------------------------- |
| Type              | Validation / smoke test               |
| Ancien sens       | Créer fixtures + smoke test           |
| Nouveau sens      | Valider un projet créé dans l’éditeur |
| Ne doit pas faire | créer le projet à ta place            |

Principe :

```text
Tu crées dans l’éditeur :
- une map de départ
- un PNJ mentor
- une scène qui donne un Pokémon
- une map port
- une rivale
- un combat
- des world rules
- une save / lancement

L’agent fournit :
- check-list de validation
- smoke harness générique si nécessaire
- tests sur le runtime générique
- diagnostics si le projet créé est cassé
```

À prouver :

```text
nouvelle partie
party vide
PNJ donne Pokémon
save/load conserve le Pokémon
world rule débloque PNJ rival
dialogue outcome branche
combat trainer démarre
victory branch fonctionne
defeat branch fonctionne
facts/steps/world rules persistent
```

Donc NS-GS-12 ne doit plus être :

```text
“voici les fixtures Selbrume générées par Codex”
```

mais :

```text
“voici comment valider un Golden Slice créé dans l’éditeur”
```

---

# Phase 5 — Validator minimal

Je mettrais cette phase juste après ou en parallèle de NS-GS-12, car c’est une mécanique clé pour un outil no-code.

## NS-GS-13 — Narrative Validator Minimal V0

| Champ             | Détail                                                        |
| ----------------- | ------------------------------------------------------------- |
| Type              | Validator générique                                           |
| Objectif          | Détecter les erreurs qui rendent un projet narratif injouable |
| Ne doit pas faire | validator complet de tout PokeMap                             |

À détecter :

```text
scene référencée absente
dialogue Yarn absent
outcome Yarn non géré
trainer absent
battleId absent
fact utilisé mais jamais produit
fact produit mais jamais lu
world rule cible absente
step impossible à compléter
NPC référence une scene inexistante
```

Pourquoi c’est important : l’audit souligne que sans validator, un outil no-code devient vite une machine à fabriquer des projets cassés.

---

# Phase 6 — Extension mécanique après Golden Slice

Une fois la chaîne PNJ → scène → GivePokemon → Yarn outcomes → battle → facts/world rules → save/load validée, on peut ouvrir les autres mécaniques.

## NS-GS-14 — Item Pickup / GiveItem Authoring Readiness

Objectif :

```text
permettre à l’éditeur de créer un objet ramassable
poser fact picked_up
mettre item dans Bag
empêcher double ramassage
persist save/load
```

SEL-B1 a déjà corrigé `giveItem → Bag`, donc ce sera probablement plus court.

---

## NS-GS-15 — Key Item / Door Gate Readiness

Objectif :

```text
condition HasItem / HasFact
porte ouverte/fermée
message si bloqué
world rule persistante
```

Cas de référence :

```text
cabane du phare
```

Mais mécanique générique :

```text
clé → porte
```

---

## NS-GS-16 — Side Quest / Optional Storyline Readiness

Objectif :

```text
quête annexe disponible sous condition
steps optionnels
récompense
dialogue final
world rules liées
```

Cas de référence :

```text
cristaux de sel
Goélise
cabane
```

Mais mécanique générique :

```text
optional storyline
```

---

## NS-GS-17 — Static Encounter / Boss Battle Readiness

Objectif :

```text
interactable / zone trigger lance combat static
victory/capture/defeat outcomes
post-battle facts
one-shot
save/load
```

Cas de référence :

```text
Pokémon du phare
```

---

## NS-GS-18 — Reward / Money / XP Bridge Audit

Objectif :

```text
auditer puis planifier XP
money rewards
post-battle rewards
give item after battle
```

L'audit mécanique signale clairement que XP, level-up, moves, récompenses, bag runtime complet, shops et centre Pokémon restent de gros trous pour une boucle RPG complète.

---

# Roadmap synthétique finale

```text
PHASE 1 — Alignement (documentaire)
✅ NS-GS-01    — Golden Slice Exact Specification
✅ NS-GS-01-bis — Roadmap & Evidence Alignment Fix
✅ NS-GS-02    — Starter / Initial Party Decision
✅ NS-GS-02-bis — Starter Decision Alignment Fix
✅ NS-GS-03    — Content Inventory & Fixture Plan
✅ NS-GS-03-bis — Rival Outcome & World Rule Alignment Fix
✅ NS-GS-04    — Runtime Smoke Strategy
✅ NS-GS-04-bis — Mechanics-First Roadmap Alignment

PHASE 2 — Socle runtime générique (code)
✅ NS-GS-05   — New Game Minimal Runtime
✅ NS-GS-06   — GivePokemon Minimal
✅ NS-GS-07   — Step Completion / Progression Hooks V0

PHASE 3 — Authoring / runtime bridge (code + readiness)
✅ NS-GS-08   — NPC Interaction → Scene Authoring Readiness
✅ NS-GS-09   — Yarn Outcome → Scene Branch Readiness
✅ NS-GS-10   — World Rules / Conditional Presence Readiness
✅ NS-GS-11   — Trainer Battle Authoring Readiness

PHASE 4 — Validation depuis l'éditeur
✅ NS-GS-12   — Editor-authored Golden Slice Validation (Level 2 Application — 14 tests)

PHASE 5 — Sécurité no-code
✅ NS-GS-13   — Narrative Validator Minimal V0

PHASE 6 — Extension gameplay
🔜 NS-GS-14   — Item Pickup / GiveItem Authoring Readiness
   NS-GS-15   — Key Item / Door Gate Readiness
   NS-GS-16   — Side Quest / Optional Storyline Readiness
   NS-GS-17   — Static Encounter / Boss Battle Readiness
   NS-GS-18   — Reward / Money / XP Bridge Audit
```

# Prochain lot exact

```text
🔜 NS-GS-14 — Item Pickup / GiveItem Authoring Readiness
```

Périmètre :

```text
Caractériser ou ajouter le flux générique Item Pickup / GiveItem :
ramassage d'objet, ajout inventaire, idempotence si nécessaire,
authoring readiness et preuves runtime/application.
Pas de fixtures Selbrume finales.
Tests obligatoires.
Mettre à jour MVP Selbrume/road_map.md.
```

---

# Règle permanente de maintenance de la roadmap

À chaque lot NS-GS / NS-SB / Narrative Studio lié à ce chantier, l'agent doit :

1. **Lire** ce fichier (`MVP Selbrume/road_map.md`) avant toute modification.
2. **Respecter** la roadmap canonique courante.
3. **Mettre à jour le statut** du lot exécuté.
4. **Ajouter un résumé court** du résultat.
5. **Mettre à jour** la section « Prochain lot recommandé ».
6. **Signaler** les décisions utilisateur nouvelles.
7. **Signaler** les changements de périmètre.
8. **Ne jamais transformer** un lot de mécanique générique en création de contenu Selbrume.
9. **Ne jamais créer** de fixtures Selbrume finales sauf demande explicite de l'utilisateur.
10. **Conserver** un Evidence Pack dans le rapport du lot.

---

# Mise à jour NS-GS-04-bis — 2026-05-23

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-04-bis — Mechanics-First Roadmap Alignment |
| Résultat | Roadmap realignée mechanics-first. Règle permanente inscrite. Rapport livré. |
| Décision intégrée | Les agents ne créent pas les fixtures Selbrume finales. L'utilisateur les crée dans l'éditeur. |
| NS-GS-03/04 | Restent utiles comme référence, pas comme commande de création. |
| Prochain lot | NS-GS-05 — New Game Minimal Runtime (mécanique générique) |
| Rapport | `reports/gameplay/ns_gs_04_bis_mechanics_first_roadmap_alignment.md` |

---

# Mise à jour NS-GS-05 — 2026-05-23

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-05 — New Game Minimal Runtime |
| Résultat | `createNewGameState` ajouté dans map_gameplay. 33 tests passent. Analyze clean (0 nouveau). |
| Fichiers | `new_game_state_builder.dart` (lib + test), `map_gameplay.dart` (+1 export) |
| Décision | Pas de modification ProjectManifest (évite build_runner). startMapId fourni par l'appelant. |
| Limites | Pas de startMapId persisté dans le manifest. Pas de spawn resolution intégrée. |
| Mechanics-first | ✅ Aucun id Selbrume. Aucune fixture finale. Party vide. |
| Prochain lot | NS-GS-06 — GivePokemon Minimal |
| Rapport | `reports/gameplay/ns_gs_05_new_game_minimal_runtime.md` |

---

# Mise à jour NS-GS-06 — 2026-05-23

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-06 — GivePokemon Minimal |
| Résultat | Mutation `givePokemon` + action `kScenarioActionGivePokemon`. 20 tests passent (16 gameplay + 4 runtime). Analyze clean (0 nouveau). |
| Fichiers | `game_state_mutations.dart` (+42 lignes), `scenario_runtime_executor.dart` (+68 lignes), `map_runtime.dart` (+1 export), 2 fichiers test |
| Décision | Option A retenue : action native ScenarioRuntimeExecutor. Params via payload.params. |
| Limites | Limite party 6 non modélisée. currentHp=1 arbitraire. Pas de calcul stats/learnset. |
| Mechanics-first | ✅ Aucun id Selbrume. Aucune fixture finale. createNewGameState inchangé. |
| Prochain lot | NS-GS-07 — Step Completion / Progression Hooks V0 |
| Rapport | `reports/gameplay/ns_gs_06_give_pokemon_minimal.md` |

---

# Mise à jour NS-GS-06-bis — 2026-05-23

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-06-bis — GivePokemon Runtime Payload Hardening |
| Résultat | `knownMoveIds` (comma-sep) et `currentHp` (fallback=level) ajoutés au payload runtime. 9 tests runtime passent. 16 gameplay repassent. Analyze clean. |
| Fichiers | `scenario_runtime_executor.dart` (+31 -2), `scenario_give_pokemon_test.dart` (+292), rapport |
| Décision | `currentHp` fallback = level (pas de base stats). `knownMoveIds` = comma-separated string. |
| Limites | Limite party 6 non modélisée. Pas de résolution learnset/stats. |
| Mechanics-first | ✅ Aucun id Selbrume. Aucune fixture finale. Mutation pure inchangée. |
| Prochain lot | NS-GS-07 — Step Completion / Progression Hooks V0 |
| Rapport | `reports/gameplay/ns_gs_06_bis_give_pokemon_runtime_payload_hardening.md` |

---

# Mise à jour NS-GS-07 — 2026-05-23

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-07 — Step Completion / Progression Hooks V0 |
| Résultat | Mutation `completeStep` + action `kScenarioActionCompleteStep`. 22 tests passent (14 gameplay + 8 runtime). Predicates `stepCompleted`/`stepNotCompleted` vérifiés. Analyze clean. |
| Fichiers | `game_state_mutations.dart` (+27), `scenario_runtime_executor.dart` (+46), `map_runtime.dart` (+1 export), 2 fichiers test |
| Décision | `stepId` via `payload.params`. Idempotent. No-op sur blank. Predicates déjà câblés. |
| Limites | Pas de validation stepId dans un registre. Pas de validator narratif. whenCutsceneEnds conservé. |
| Mechanics-first | ✅ Aucun id Selbrume. Aucune fixture finale. createNewGameState inchangé. |
| Prochain lot | NS-GS-08 — NPC Interaction → Scene Authoring Readiness |
| Rapport | `reports/gameplay/ns_gs_07_step_completion_progression_hooks.md` |

---

# Mise à jour NS-GS-07-bis — 2026-05-23

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-07-bis — Analyzer Cleanup for Step Completion Tests |
| Résultat | 2 imports relatifs remplacés par `package:`. 0 diagnostic analyzer sur le fichier. 8 tests passent. |
| Fichiers | `scenario_complete_step_test.dart` (2 lignes modifiées), rapport |
| Décision | Import `package:map_runtime/src/...` au lieu de `../lib/src/...`. |
| Limites | `map_entity_runtime_predicate_evaluator_test.dart` pré-existant utilise aussi des imports relatifs (hors scope). |
| Mechanics-first | ✅ Aucun code de prod modifié. Aucune fixture Selbrume. |
| Prochain lot | NS-GS-08 — NPC Interaction → Scene Authoring Readiness |
| Rapport | `reports/gameplay/ns_gs_07_bis_analyzer_cleanup_step_completion_tests.md` |

---

# Mise à jour NS-GS-08 — 2026-05-23

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-08 — NPC Interaction → Scene Authoring Readiness |
| Résultat | Cas A : pont PNJ → scène déjà complet. 7 tests de caractérisation ajoutés. Aucun code de prod modifié. Analyze clean. |
| Fichiers | `npc_interaction_scene_readiness_test.dart` (7 tests), rapport |
| Décision | Le pont existe : PlayableMapGame → ScenarioRuntimeExecutor via entityInteract. Fallback dialogue NPC si aucun scénario ne matche. |
| Limites | Tests au niveau executor, pas au niveau Flame complet. Yarn outcome et world rules hors scope. |
| Mechanics-first | ✅ Aucun code de prod modifié. Aucune fixture Selbrume. |
| Prochain lot | NS-GS-09 — Yarn Outcome → Scene Branch Readiness |
| Rapport | `reports/gameplay/ns_gs_08_npc_interaction_scene_authoring_readiness.md` |

---

# Mise à jour NS-GS-09 — 2026-05-23

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-09 — Yarn Outcome → Scene Branch Readiness |
| Résultat | Cas A : flux outcome → branch déjà complet. 9 tests de caractérisation ajoutés. Aucun code de prod modifié. Analyze clean. |
| Fichiers | `outcome_scene_branch_readiness_test.dart` (9 tests), rapport |
| Décision | Le pont existe : emitOutcome → flag scenario.outcome.* → condition flagIsSet → trueBranch/falseBranch. |
| Frontière Event/Scene | ✅ Event non transformé en Scene. Scene reste le lieu du branching narratif. |
| Garde-fou faux positif | Cas 2 : outcome technique équivalent. Gap honnête : Yarn parser → emitOutcome pas testé au niveau Flame. |
| Limites | Tests au niveau executor, pas au niveau Dialogue/Yarn complet. World rules hors scope. |
| Mechanics-first | ✅ Aucun code de prod modifié. Aucune fixture Selbrume. |
| Prochain lot | NS-GS-10 — World Rules / Conditional Presence Readiness |
| Rapport | `reports/gameplay/ns_gs_09_yarn_outcome_scene_branch_readiness.md` |

---

# Mise à jour NS-GS-10 — 2026-05-24

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-10 — World Rules / Conditional Presence Readiness |
| Résultat | Cas A : flux GameState → World Rule → monde déjà complet. 31 tests de caractérisation ajoutés. Aucun code de prod modifié. Analyze clean. |
| Fichiers | `world_rules_conditional_presence_readiness_test.dart` (31 tests), rapport |
| Décision | Le pont existe : MapEntityRuntimePredicateEvaluator → isNpcPresentOnMap → resolveNpcDialogue. 8 predicate kinds couverts. |
| Frontière Event/Scene/World Rule | ✅ Event non transformé en World Rule. World Rule non transformée en Scene. Trois concepts séparés. |
| Garde-fou faux positif | Cas 2 : predicate + resolver utilisé en production. Gap honnête : refresh Flame complet non testé (NS-GS-12). |
| Limites | Tests au niveau evaluator, pas au niveau Flame complet. Refresh PlayableMapGame hors scope. |
| Mechanics-first | ✅ Aucun code de prod modifié. Aucune fixture Selbrume. |
| Prochain lot | NS-GS-11 — Trainer Battle Authoring Readiness |
| Rapport | `reports/gameplay/ns_gs_10_world_rules_conditional_presence_readiness.md` |

---

# Mise à jour NS-GS-11 — 2026-05-24

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-11 — Trainer Battle Authoring Readiness |
| Résultat | Cas A : flux Scene → Trainer Battle → Outcome → Continuation déjà complet. 13 tests de caractérisation ajoutés. Aucun code de prod modifié. Analyze clean. |
| Fichiers | `trainer_battle_authoring_readiness_test.dart` (13 tests), rapport |
| Décision | Le pont existe : startTrainerBattle → ScenarioRuntimeEffectType.battle → _handleScenarioBattleEffect → _onBattleFinished → scenarioBattleOutcomeFlagName → dispatchContinuation → branch victory/defeat. |
| Frontière Scene/Battle/World Rule | ✅ Battle non transformé en Scene. Scene reste responsable de la progression post-combat. Outcome battle revient à la Scene. |
| Garde-fou faux positif | Cas 1 : flux complet dispatch → battle effect → outcome → continuation → branch testé. Gap honnête : Flame-level _handleScenarioBattleEffect et _onBattleFinished non testés au niveau widget test (NS-GS-12). |
| Limites | Tests au niveau ScenarioRuntimeExecutor, pas au niveau Flame complet. buildTrainerBattleRequestFromNpc et applyRuntimeBattleOutcomeToGameState testés séparément dans leurs fichiers respectifs. |
| Mechanics-first | ✅ Aucun code de prod modifié. Aucune fixture Selbrume. Ids génériques test_*. |
| Prochain lot | NS-GS-12 — Editor-authored Golden Slice Validation |
| Rapport | `reports/gameplay/ns_gs_11_trainer_battle_authoring_readiness.md` |
| Fermeture documentaire | NS-GS-11-bis — Evidence Pack Fix Only. Rapport : `reports/gameplay/ns_gs_11_bis_evidence_pack_fix.md` |

---

# Mise à jour NS-GS-12 — 2026-05-24

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-12 — Editor-authored Golden Slice Validation |
| Résultat | Golden Slice intégré prouvé au niveau Application (Level 2). 14 tests composent NS-GS-05..11 en chaîne end-to-end. Aucun code de prod modifié. Analyze clean (0 diagnostic). |
| Fichiers | `ns_gs_12_golden_slice_validation_test.dart` (14 tests), rapport |
| Décision | Level 2 (Application) est le plus haut niveau prouvable sans construire un projet fixture Selbrume complet ou un harness headless PlayableMapGame. |
| Frontière Event/Scene/Battle/World Rule | ✅ Les 3 scénarios (mentor, dialogue, battle) composent via dispatch + dispatchContinuation + emitOutcome + sourceOutcome. World Rule projette le state résultant. |
| Garde-fou faux positif | Cas 1 : flux intégré prouvé (pas briques isolées). Gap honnête : Flame-level PlayableMapGame non testé. Battle outcome simulé (flag posé manuellement). openDialogue stubé. |
| Limites | Tests au niveau ScenarioRuntimeExecutor + MapEntityRuntimePredicateEvaluator, pas au niveau Flame complet. Pas de PC/Box, bag/items, XP/money testés. |
| Mechanics-first | ✅ Aucun code de prod modifié. Aucune fixture Selbrume. Ids génériques test_*. |
| Prochain lot | NS-GS-13 — Narrative Validator Minimal V0 |
| Rapport | `reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md` |
| Fermeture documentaire | NS-GS-12-bis — Evidence Pack & Level Label Fix Only. Rapport : `reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md` |

---

# Mise à jour NS-GS-13 — 2026-05-24

| Champ | Détail |
|---|---|
| Lot exécuté | NS-GS-13 — Narrative Validator Minimal V0 |
| Résultat | Narrative Validator minimal ajouté dans `map_core` avec rapport multi-diagnostics déterministe. 16 tests ciblés couvrent les erreurs/warnings V0 principaux. |
| Décision | Cas B : `ProjectValidator` existait déjà mais lève une seule `ValidationException`; il ne fournit pas un rapport narratif no-code multi-diagnostics. Ajout d'une brique pure Dart dans `packages/map_core/lib/src/operations/narrative_validator.dart`. |
| Fichiers | `packages/map_core/lib/src/operations/narrative_validator.dart`, `packages/map_core/test/narrative_validator_test.dart`, `packages/map_core/lib/map_core.dart`, rapport NS-GS-13 |
| Diagnostics V0 | Unknown node refs, unreachable node, missing source, unknown dialogue, unknown trainer, missing trainerId/npcEntityId, blank battleId explicite, source entityInteract unknown map/entity, outcome emitted/consumed mismatch, conditional dialogue unknown, flag/step read-write mismatch warnings. |
| Tests exécutés | `cd packages/map_core && dart test test/narrative_validator_test.dart` ; `cd packages/map_core && dart test --reporter compact` |
| Analyzer | `cd packages/map_core && dart analyze` → No issues found. |
| git diff --check | À reporter dans `reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md` Evidence Pack final. |
| Limites | Validator V0 mémoire uniquement ; pas de chargement disque ; `entityInteract` valide l'entité seulement quand les `MapData` sont fournis ; pas de correction automatique ; pas de validator complet de tout PokeMap. |
| Mechanics-first | ✅ Brique générique pure Dart. Aucun code runtime/editor modifié. Aucun contenu Selbrume final. Aucun `project.json` généré. |
| Prochain lot | NS-GS-14 — Item Pickup / GiveItem Authoring Readiness |
| Rapport | `reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md` |
| Fermeture documentaire | NS-GS-13-bis — Evidence Pack Closure Only. Rapport : `reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md` |
