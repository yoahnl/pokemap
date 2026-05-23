# NS-GS-02 — Starter / Initial Party Decision

---

## 1. Résumé exécutif

Le Golden Slice Selbrume V0 nécessite que le joueur possède au moins un Pokémon avant le combat contre Lysa au port. Trois options ont été étudiées : (A) Maël donne réellement le starter en jeu via une mutation `givePokemon`, (B) le GameState initial contient déjà un Pokémon pré-chargé, (C) hybride combinant A et B.

**Décision canonique GS V0 : Option A** — Maël donne réellement le starter (`sproutle`) au joueur pendant `scene_mael_intro`. L'option du starter pré-chargé (B) est techniquement plus simple, mais elle est rejetée parce qu'elle ne prouve pas la boucle RPG attendue : le joueur doit vivre le don du starter pour que le Golden Slice soit fidèle au scénario Selbrume.

**Décision GS V1 : Option A enrichie** — Maël donne le starter avec une UX plus complète si nécessaire (meilleur dialogue, choix starter éventuel, diagnostics).

**Impact sur NS-GS-06** : **obligatoire avant NS-GS-12**. La mutation `givePokemon` / `addPartyMember` doit être implémentée dans NS-GS-06.

**Starter recommandé** : `sproutle` (Sproutle, Grass, BST 318, ability overgrow) — donné par Maël via GivePokemon. Species custom du projet, déjà validé dans le golden_battle_slice existant, avec learnset et moves bridgeables confirmés.

> [!IMPORTANT]
> L'Option B (starter pré-chargé) reste une preuve technique utile que la party peut être persistée,
> mais elle **ne suffit pas** pour le Golden Slice produit car elle contourne le don du starter.
> L'Option C est rejetée car elle ajoute une complexité inutile pour V0.

---

## 2. Sources et contexte

### Documents lus

| Document | Chemin | Rôle |
|---|---|---|
| NS-GS-01 | [ns_gs_01_golden_slice_exact_specification.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_01_golden_slice_exact_specification.md) | Spécification exacte du Golden Slice |
| SEL-A1 | [sel_a1_narrative_glossary.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_a1_narrative_glossary.md) | Glossaire narratif |
| SEL-A2 | [sel_a2_event_scene_outcome_fact_contract.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_a2_event_scene_outcome_fact_contract.md) | Contrat Event → Scene → Outcome → Fact |
| SEL-B2 | [sel_b2_battle_from_scene.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_b2_battle_from_scene.md) | Battle from Scene |
| SEL-B1 | [sel_b1_fix_give_item_to_bag.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_b1_fix_give_item_to_bag.md) | Fix giveItem → Bag |
| Roadmap | [road_map.md](file:///Users/karim/Project/pokemonProject/MVP%20Selbrume/road_map.md) | Roadmap canonique |
| Scénario | [selbrume.md](file:///Users/karim/Project/pokemonProject/MVP%20Selbrume/selbrume.md) | Scénario canonique Selbrume |
| Vision | [narrative_studio.md](file:///Users/karim/Project/pokemonProject/MVP%20Selbrume/narrative_studio.md) | Vision Narrative Studio |

### Code source inspecté (lecture seule)

| Fichier | Rôle |
|---|---|
| [game_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/game_state.dart) | GameState avec `PlayerParty party` |
| [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart) | PlayerPokemon, PlayerParty, SaveData |
| [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart) | 10 mutations, pas de givePokemon |
| [runtime_demo_party_seed.dart](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart) | Fixture party demo avec sproutle/sparkitten |
| [runtime_host_launch_save.json](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json) | Save fixture avec party pré-chargée |

---

## 3. Problème à résoudre

```text
Pour combattre Lysa au port, le joueur doit avoir au moins un Pokémon dans sa party.
Le Golden Slice V0 doit prouver la boucle RPG complète, y compris le don du starter.
givePokemon est absent du code actuel et devra être implémenté (NS-GS-06).

La roadmap canonique interdit de coder avant NS-GS-05/06/07.
NS-GS-02 est documentaire uniquement.
```

Le problème central est donc : **comment s'assurer que le joueur reçoit son premier Pokémon de Maël en jeu, de manière fiable et prouvable ?**

---

## 4. Contraintes du Golden Slice

```text
1. Le Golden Slice doit prouver le battle handoff Lysa (SEL-B2).
2. Le joueur doit avoir une party non vide avant battle_rival_port.
3. Le Golden Slice V0 doit éviter les systèmes non indispensables.
4. La roadmap interdit de coder avant NS-GS-05/06/07.
5. NS-GS-02 est documentaire uniquement.
6. Le pipeline complet est : spawn → Maël → port → Lysa → combat → outcome → fact → step → world rule → save/load.
7. Le starter doit survivre un cycle save/load.
8. Le combat doit être jouable avec le starter à un niveau cohérent (~5).
```

---

## 5. État technique pertinent du repo

| Élément | Statut | Preuve fichier / symbole | Impact |
|---|---|---|---|
| GameState contient une party | ✅ | `@Default(PlayerParty()) PlayerParty party` dans `game_state.dart` | La party est un champ natif du GameState |
| SaveData persiste la party | ✅ | `PlayerParty party` dans `SaveData`, serialisé JSON | Save/load de la party fonctionne |
| PlayerPokemon modèle complet | ✅ | `save_data.dart:L98-115` — speciesId, natureId, abilityId, gender, level, IVs, EVs, moves, HP, status, shiny, heldItem | Suffisant pour le GS |
| Mutation givePokemon | ❌ absent | `rg "givePokemon\|addPartyMember\|addPokemon" game_state_mutations.dart` → vide | **À implémenter dans NS-GS-06** (obligatoire pour GS V0) |
| Mutation addPartyMember | ❌ absent | idem | Pas de mécanisme pour ajouter un Pokémon en jeu |
| New Game flow | ❌ absent | `rg "newGame\|NewGame\|new_game\|initialState" map_runtime/lib` → vide | Le runtime n'a pas de flow New Game |
| Species ids custom (golden_battle_slice) | ✅ 2 espèces | `sproutle` (Grass, BST 318), `sparkitten` (Fire, BST 305) | Species prêtes pour le GS |
| Species ids importés (pokedex pack 10) | ✅ 10 espèces | bulbasaur, charmander, squirtle, pikachu, eevee, etc. | Disponibles mais hors golden_battle_slice |
| Fixture party existante | ✅ | `runtime_host_launch_save.json` : sproutle L7 + sparkitten L6 | Preuve que la sérialisation party fonctionne (utile pour save/load après don du starter) |
| `buildRuntimeHostLaunchDemoSaveData` | ✅ | `runtime_demo_party_seed.dart:L93-118` | Pattern existant pour construire un SaveData avec party |
| `_preferredRuntimeDemoSpeciesIds` | ✅ | `['squirtle', 'carapuce', 'mew', 'dratini']` | Le host préfère squirtle/carapuce mais utilise sproutle/sparkitten en pratique |

---

## 6. Options étudiées

### Option A — Maël donne réellement le starter en jeu

#### Description

Le joueur commence sans Pokémon (party vide). Il interagit avec Maël dans `scene_mael_intro`. Pendant le dialogue, Maël donne un Pokémon au joueur. Le Pokémon est ajouté à la party du joueur via une mutation `givePokemon` ou `addPartyMember` déclenchée par un nœud ScenarioAsset de type action.

#### Ce que cela implique côté joueur

Le joueur vit l'expérience complète : il reçoit son starter, puis part en mission. Le Pokémon est un cadeau narratif, pas un prérequis technique invisible.

#### Ce que cela implique côté Maël

Maël dit quelque chose comme : « Tiens, prends ce Pokémon pour te protéger » ou « Ce Sproutle t'accompagnera — il est courageux, comme toi. »

#### Ce que cela implique côté runtime

Il faut :
- une mutation `givePokemon(state, speciesId, level, ...)` dans `GameStateMutations` ;
- un nouveau kind d'action dans `ScenarioRuntimeExecutor` (ex: `kScenarioActionGivePokemon`) ;
- ou bien un nœud `runScript` avec un script qui appelle `givePokemon`.

#### Ce que cela implique côté save/load

Si le joueur sauvegarde entre le début et le moment où Maël donne le starter, la party sera vide au reload. Il faut que le graphe scénario ne soit pas reproductible (il ne rejoue pas le don de starter) ou que le starter soit persisté via un flag + party.

#### Avantages

- Fidélité narrative maximale.
- Le joueur vit une expérience de RPG canonique (recevoir son premier Pokémon).
- Prouve la capacité du runtime à modifier le GameState depuis un graphe scénario.

#### Inconvénients

- Nécessite d'implémenter `givePokemon` (mutation + action kind + tests) — **accepté : c'est le lot NS-GS-06**.
- Complexifie `scene_mael_intro` avec un nœud supplémentaire.
- Risque de régression save/load si la mutation est mal implémentée — **mitigé par NS-GS-04/12**.

#### Risques

- Dérive de scope : on commence à implémenter des mécaniques gameplay trop tôt.
- Le coût M de `givePokemon` peut retarder NS-GS-12.
- Si le runtime Pokémon species n'est pas bien câblé, le starter donné peut crasher le combat.

#### Lots impactés

| Lot | Impact |
|---|---|
| NS-GS-05 | Le New Game doit initialiser une party vide |
| NS-GS-06 | **Obligatoire** avant NS-GS-08 |
| NS-GS-08 | `scene_mael_intro` doit contenir un nœud `givePokemon` |
| NS-GS-12 | Le smoke test doit vérifier que le starter est dans la party après Maël |

---

### Option B — Le GameState initial contient déjà un Pokémon

#### Description

Le joueur commence le Golden Slice avec un Pokémon déjà présent dans sa party. Le `GameState` initial (fixture ou New Game flow minimal) inclut un `PlayerPokemon` avec un species id, un niveau, et des moves. Maël ne donne pas le starter ; il reconnaît que le joueur a déjà un compagnon.

#### Ce que cela implique côté joueur

Le joueur commence avec un Pokémon. Il ne vit pas la scène du don de starter, mais il peut immédiatement explorer et combattre.

#### Ce que cela implique côté Maël

Maël dit quelque chose comme : « Tu as déjà un compagnon avec toi ? Parfait. Alors tu peux m'aider. Va au port, quelque chose d'étrange se passe. »

#### Ce que cela implique côté runtime

Il faut seulement :
- un `SaveData` ou `GameState` initial avec une party non vide ;
- un mécanisme de chargement (fixture JSON ou New Game minimal).

Le pattern est **déjà implémenté** dans `runtime_host_launch_save.json` + `buildRuntimeHostLaunchDemoSaveData`.

#### Ce que cela implique côté save/load

Aucun risque supplémentaire. Le starter est dans la party dès le début. Save/load de la party fonctionne déjà (vérifié SEL-B1).

#### Avantages

- Zéro code gameplay supplémentaire pour le GS V0.
- Pattern déjà validé dans le projet (golden_battle_slice fixture).
- Respecte la gouvernance : pas de code prématuré.
- Simplifie `scene_mael_intro` (pas de branche givePokemon).
- Réduit le chemin critique : NS-GS-06 reporté.

#### Inconvénients

- Le joueur ne vit pas l'expérience du don de starter.
- Le scénario Selbrume canonique mentionne que Maël donne le starter — cette étape est contournée.
- Si le GameState initial est mal construit, le starter pourrait avoir des moves non bridgeables.

#### Risques

- Le dialogue de Maël doit être cohérent (il ne doit pas dire qu'il donne un Pokémon).
- Si le species id du starter n'est pas dans les données du projet ouvert, le combat crashera.

#### Lots impactés

| Lot | Impact |
|---|---|
| NS-GS-05 | Doit charger un GameState initial avec party non vide |
| NS-GS-06 | **Reporté** après NS-GS-12 |
| NS-GS-08 | `scene_mael_intro` simplifiée (pas de givePokemon) |
| NS-GS-12 | Le smoke test vérifie que le starter est présent au départ |

---

### Option C — Hybride

#### Description

Le GameState initial contient un starter (comme Option B). Mais si la party est vide (corruption, reset, edge case), Maël peut donner un Pokémon (comme Option A). Cela combine les deux mécanismes.

#### Ce que cela implique côté joueur

Identique à Option B dans le cas normal. En cas de party vide, Maël offre un starter de secours.

#### Ce que cela implique côté Maël

Maël a deux variantes de dialogue : une si le joueur a déjà un Pokémon, une si la party est vide.

#### Ce que cela implique côté runtime

Il faut les deux mécanismes : GameState initial avec party + mutation givePokemon + condition dans le graphe scénario. Plus complexe que A ou B séparément.

#### Ce que cela implique côté save/load

Comme Option B si la party est non vide. Comme Option A si la party est vide (risques save/load de givePokemon).

#### Avantages

- Robuste : le joueur a toujours un Pokémon.
- Gère les cas limites.

#### Inconvénients

- Nécessite les deux implémentations (coût A + B).
- Sur-ingénierie pour le GS V0.
- Complexifie le graphe scénario avec une branche conditionnelle supplémentaire.
- Viole la gouvernance (nécessite givePokemon avant le cadrage complet).

#### Risques

- Le coût est le plus élevé des trois options.
- La branche de fallback (Maël donne le starter) peut ne jamais être testée si la party est toujours non vide.
- Risque de confusion sur quel chemin est le "vrai" chemin.

#### Lots impactés

| Lot | Impact |
|---|---|
| NS-GS-05 | Doit charger un GameState initial avec party non vide |
| NS-GS-06 | **Obligatoire** pour le fallback |
| NS-GS-08 | `scene_mael_intro` complexe (branche partyEmpty) |
| NS-GS-12 | Deux chemins à tester |

---

## 7. Comparaison structurée

| Critère | Option A — Maël donne | Option B — Party initiale | Option C — Hybride |
|---|---|---|---|
| Fidélité narrative | ✅ Maximale | ⚠️ Contournée | ✅ Maximale |
| Prouve la boucle RPG | ✅ Oui | ❌ Non — contourne le don | ⚠️ Partiellement |
| Simplicité GS V0 | ⚠️ Nécessite NS-GS-06 | ✅ Aucun code supplémentaire | ❌ Nécessite les deux |
| Code requis avant NS-GS-12 | M (mutation + action + tests) | XS (fixture JSON) | M+ (mutation + action + condition) |
| Risque de dérive | ⚠️ Cadré par NS-GS-06 minimal | ✅ Minimal | ❌ Sur-ingénierie |
| Testabilité | ✅ Prouve le pipeline complet | ✅ Trivial | ❌ Deux chemins à tester |
| Respect gouvernance | ✅ Code prévu en Phase 2 (NS-GS-06) | ✅ Documentaire + fixture | ❌ Code non cadré |
| Impact sur NS-GS-05 | S (party vide + New Game) | XS (party pré-chargée) | S+ (les deux) |
| Impact sur NS-GS-06 | **Obligatoire** | Reporté | Obligatoire |
| Impact sur NS-GS-12 | Prouve le don + combat | Simple (vérifier présence) | Double (deux chemins) |
| **Recommandation** | **✅ GS V0 (décision canonique)** | **Rejetée pour GS V0** | **Déconseillée** |

---

## 8. Recommandation pour GS V0

**Pour le Golden Slice V0, la décision canonique est : Option A — Maël donne réellement le starter en jeu.**

Justification :

1. **Le Golden Slice doit prouver la boucle RPG complète** : le joueur doit commencer sans Pokémon, le recevoir de Maël, puis l'utiliser pour combattre Lysa. Contourner le don du starter (Option B) ne prouve pas cette boucle.

2. **Le scénario canonique Selbrume l'exige** : `selbrume.md` (§4.1, Configuration A) prévoit que le joueur commence sans Pokémon et reçoit un starter au début. Le Golden Slice doit être fidèle au scénario.

3. **NS-GS-06 est un investissement minimal et réutilisable** : une mutation `givePokemon` sera utile au-delà du GS V0 (échanges, récompenses, quêtes). Le coût M est amorti.

4. **Le pipeline prouvé est plus complet** : `spawn → Maël → givePokemon → mission → port → Lysa → combat → outcome → fact → step → world rule → save/load`. Chaque maillon est prouvé.

> [!WARNING]
> L'Option B est un raccourci technique qui reste une preuve utile que la party peut être persistée.
> Mais elle ne suffit pas pour le Golden Slice produit, car elle contourne le don du starter
> au lieu de le prouver.

---

## 9. Recommandation pour GS V1

**Pour le Golden Slice V1, la recommandation reste Option A, enrichie :**

```text
- Meilleur dialogue de Maël (plus narratif, plus émouvant).
- Éventuel choix de starter plus tard (V1+ / post-GS).
- Meilleure UX (animation de don, notification in-game).
- Meilleurs diagnostics (vérification learnset, bridge moves).
```

L'Option A du GS V0 est volontairement minimale. Le GS V1 l'enrichira sans la remplacer.

---

## 10. Décision sur NS-GS-06 GivePokemon Minimal

```text
NS-GS-06 est : obligatoire avant NS-GS-12.

Raison :
- L'Option A (décision canonique) nécessite givePokemon.
- Le joueur commence sans Pokémon.
- Maël donne réellement sproutle pendant scene_mael_intro.
- Sans givePokemon, le joueur ne peut pas combattre Lysa.
```

NS-GS-06 devra fournir le minimum nécessaire pour :

```text
1. Ajouter un PlayerPokemon dans GameState.party (mutation addPartyMember ou givePokemon).
2. Être déclenchable depuis un ScenarioAsset (action kind) ou un script runtime.
3. Éviter les doublons de starter (condition: si party vide, ou si fact_starter_received non posé).
4. Persister correctement via SaveData (la party est déjà sérialisée, mais le flag doit l'être aussi).
5. Être testable sans UI complète (test unitaire sur la mutation + test d'intégration scénario).
```

> [!IMPORTANT]
> NS-GS-06 doit rester **minimal** :
> - Pas de système complet de cadeau Pokémon.
> - Pas de choix starter.
> - Pas d'UI riche.
> - Un seul Pokémon donné (sproutle), un seul donneur (Maël).

---

## 11. Starter recommandé

| Usage | Species id | Nom affiché | Statut | Pourquoi |
|---|---|---|---|---|
| **Starter V0 joueur** | `sproutle` | Sproutle | ✅ Existe dans golden_battle_slice, enabled, learnset validé | Pokémon custom du projet, BST 318 (starter-tier), Grass, ability `overgrow`, moves confirmés (`tackle`, `growl`, `vine_whip` au L7). Déjà utilisé dans la fixture party existante. |
| **Pokémon Lysa V0** | `sparkitten` | Sparkitten | ✅ Existe dans golden_battle_slice, enabled | Pokémon custom Fire, BST 305, ability `blaze`, moves confirmés (`tackle`, `growl` au L6). Crée un matchup Grass vs Fire cohérent. |
| **Alternatif joueur** | `squirtle` | Carapuce | ⚠️ Existe dans fixtures editor, mais pas dans golden_battle_slice/data | Pourrait être utilisé si le projet cible a ces species importées. Nécessite vérification du learnset/bridge. |
| **Idéal narratif** | species custom Selbrume | à créer | ❌ N'existe pas | Un Pokémon lié au lore Selbrume (brume, marais, sel) serait plus immersif, mais n'est pas nécessaire pour le GS V0. |

### Recommandation starter

```text
Pour le GS V0, sproutle (species id = "sproutle") est donné par Maël via GivePokemon.
Pour le GS V0, sparkitten (species id = "sparkitten") est le Pokémon de Lysa.
sproutle n'est plus préchargé — il est donné en jeu.
Pour le GS V1+, envisager un species custom lié au lore Selbrume.
```

### Paramètres recommandés pour le starter V0

```text
speciesId  : sproutle
natureId   : hardy (neutre)
abilityId  : overgrow
gender     : null (déterminé par le seed)
level      : 5
knownMoveIds : [tackle, growl]
currentHp  : 22 (plein au L5)
```

### Paramètres recommandés pour Lysa V0

```text
speciesId  : sparkitten
natureId   : hardy
abilityId  : blaze
gender     : null
level      : 5
knownMoveIds : [tackle, growl]
currentHp  : 20 (plein au L5)
```

> [!NOTE]
> Les niveaux et HP exacts seront affinés dans NS-GS-11 (Battle Lysa Authoring Fixture).
> Les valeurs ci-dessus sont des recommandations de départ, pas des fixtures finales.

---

## 12. Impact sur Maël

### GS V0 — Maël donne réellement le starter (Option A)

Maël **doit** donner le starter pendant `scene_mael_intro`.

Formulation recommandée :

```text
✅ « Ce Sproutle m'a été confié par un ami. Il a besoin de quelqu'un de courageux. »
✅ « Prends-le, il sera ton premier compagnon. »
✅ [Le joueur reçoit Sproutle !]
✅ « La brume autour du phare inquiète les pêcheurs. Va au port des Brisants, regarde ce qui s'y passe. »
```

Maël ne doit **pas** dire :

```text
❌ « Tu as déjà un compagnon avec toi ? Parfait. » (formulation Option B, rejetée)
```

### GS V1 — Maël enrichi

```text
Dialogue plus long, contexte sur l'ami qui a confié Sproutle,
éventuel choix starter, animation de don améliorée.
```

---

## 13. Impact sur scene_mael_intro

### GS V0 — Option A retenue

Le graphe conceptuel de `scene_mael_intro` inclut le don du starter :

```text
[start]
  ↓
[node_dialogue_intro] (kind: openDialogue → yarn_mael_intro_before_gift)
  ↓
[node_give_starter] (kind: givePokemon → sproutle, L5, tackle+growl)
  ↓
[node_set_flag] (kind: setFlag → fact_starter_received)
  ↓
[node_dialogue_mission] (kind: openDialogue → yarn_mael_mission)
  ↓
[node_set_flag] (kind: setFlag → fact_mission_started)
  ↓
[node_emit_outcome] (kind: emitOutcome → mission_started)
  ↓
[end]
```

Le graphe doit poser `fact_starter_received` après le don pour :
- empêcher un redon si le joueur re-parle à Maël ;
- permettre à NS-GS-12 de vérifier la réception.

### GS V1 — Enrichi

```text
Ajout possible :
- condition partyEmpty pour gérer les edge cases ;
- branche fallback si le starter a déjà été reçu ;
- animation / notification in-game.
```

---

## 14. Impact sur yarn_mael_intro

### Dialogue V0 (Maël donne le starter — Option A)

```text
yarn_mael_intro_before_gift :
Maël : Ah, tu es là. J'ai quelque chose pour toi.
       Ce Sproutle m'a été confié par un vieil ami. Il a besoin de quelqu'un de courageux.
       Prends-le. Il sera ton premier compagnon.

[→ givePokemon sproutle L5 exécuté ici]

yarn_mael_mission :
Maël : Maintenant, écoute.
       Tu vois le phare, là-bas ? La brume ne se dissipe plus depuis trois jours.
       Les pêcheurs sont inquiets. Les Pokémon aussi.
       Va au port des Brisants. Regarde ce qui s'y passe.
       Et sois prudent.

[Choix joueur]
→ J'y vais tout de suite. (outcome: accept_mission)
→ Tu peux m'en dire plus ? (outcome: ask_more → puis accept_mission)
```

### Dialogue après don (si le joueur re-parle à Maël)

```text
yarn_mael_encouragement :
Maël : Tu as Sproutle avec toi. Tu es prêt(e).
       Va au port des Brisants. Fais attention à toi.
```

### Dialogue fallback (party vide, fact_starter_received non posé — edge case)

```text
Ne devrait pas se produire si le graphe est bien câblé.
Si la party est vide et le flag n'est pas posé, Maël relance le don.
Si le flag est posé mais la party est vide (corruption), situation d'erreur.
NS-GS-04 doit couvrir ce cas.
```

---

## 15. Impact sur NS-GS-03 Content Inventory & Fixture Plan

NS-GS-03 devra inventorier les éléments suivants à cause de la décision Option A :

```text
- Fixture GameState initial :
  - party : vide (aucun starter pré-chargé)
  - bag : vide ou [5 poké-balls]
  - storyFlags : vide
  - completedSteps : vide
  - currentMapId : map_bourg_selbrume
  - playerPosition : devant Maël
  - trainerProfile : { name: "Joueur" }

- Species data sproutle :
  - fichier species JSON : déjà existant dans golden_battle_slice
  - learnset JSON : à vérifier / copier vers le projet Selbrume
  - moves catalog : à vérifier pour les moves au L5

- Action GivePokemon attendue :
  - mutation addPartyMember dans GameStateMutations
  - action kind givePokemon dans ScenarioRuntimeExecutor
  - ou script runtime équivalent

- Fact / flag attendu :
  - fact_starter_received (posé après don réussi)
  - condition empêchant le redon (step ou flag check)

- Yarn Maël V0 :
  - yarn_mael_intro_before_gift : dialogue avant le don
  - yarn_mael_mission : dialogue de mission après le don
  - yarn_mael_encouragement : dialogue si re-parle après don

- ScenarioAsset scene_mael_intro V0 :
  - graphe avec nœud givePokemon
  - flag fact_starter_received
  - nœud dialogue mission
```

---

## 16. Impact sur NS-GS-04 Runtime Smoke Strategy

NS-GS-04 devra définir les tests suivants à cause de la décision Option A :

```text
Tests à prouver :
1. La party est vide au départ (avant Maël).
2. Après scene_mael_intro, le starter (sproutle) est dans la party.
3. Le starter a au moins 1 move bridgeable (tackle).
4. Le flag fact_starter_received est posé après le don.
5. Le starter reçu survit un cycle save/load (save → reload → party identique).
6. Le combat Lysa peut démarrer avec le starter reçu.
7. givePokemon fonctionne (mutation testée unitairement + intégration scénario).

Tests à NE PAS prouver en V0 :
- Choix starter (un seul starter fixe : sproutle)
- New Game overlay complet
- Animation de don riche
```

---

## 17. Impact sur NS-GS-05 New Game Minimal Runtime

Avec Option A, NS-GS-05 devra :

```text
1. Initialiser un GameState / SaveData minimal avec :
   - party : vide (aucun starter pré-chargé)
   - bag : vide ou [5 poké-balls]
   - currentMapId : map_bourg_selbrume
   - playerPosition : devant ou près de Maël
   - storyFlags : vide
   - completedSteps : vide

2. Le joueur doit pouvoir parler à Maël immédiatement.

3. Le joueur ne doit PAS pouvoir combattre avant d'avoir reçu le starter.

4. NS-GS-05 ne doit PAS :
   - pré-charger sproutle dans la party ;
   - proposer un choix de starter ;
   - implémenter givePokemon (c'est NS-GS-06).

Le pattern buildRuntimeHostLaunchDemoSaveData() dans runtime_demo_party_seed.dart
montre comment construire un SaveData. NS-GS-05 doit l'adapter avec party vide.
```

---

## 18. Impact sur NS-GS-12 Golden Slice Smoke Test

Avec Option A, le smoke test final doit vérifier :

```text
Au départ :
✓ La party est vide.
✓ Aucun starter n'a été reçu (fact_starter_received absent).
✓ Le joueur est à Bourg Selbrume, devant Maël.

Après Maël :
✓ Maël a donné sproutle au joueur.
✓ La party contient exactement 1 Pokémon (sproutle, L5, tackle+growl).
✓ Le Pokémon reçu a speciesId, level, moves, currentHp cohérents.
✓ Le flag fact_starter_received est posé.
✓ Le flag fact_mission_started est posé.
✓ Save/load conserve le Pokémon reçu (save → reload → party identique).

Après combat Lysa :
✓ Le combat démarre correctement avec sproutle (reçu) vs sparkitten.
✓ Le combat se termine avec un BattleOutcome.
✓ Les flags battle:battle_rival_port:<outcome> sont posés.
✓ Le Pokémon reçu est bien celui utilisé pour le combat.

Après save/load final :
✓ Le starter est présent dans la party au reload.
✓ Le HP du starter est celui d'après le combat (pas reset).
✓ Tous les flags et steps sont persistés.
```

---

## 19. Risques et garde-fous

| Risque | Impact | Garde-fou |
|---|---|---|
| GivePokemon trop large | Fort — sur-ingénierie | NS-GS-06 doit rester minimal : un seul Pokémon, un seul donneur, pas de choix starter, pas d'UI riche |
| Double don du starter | Fort — Pokémon dupliqué | Flag `fact_starter_received` ou condition step/party |
| Save/load après don du starter | Moyen — perte du Pokémon | Test obligatoire dans NS-GS-04 et NS-GS-12 |
| Battle Lysa sans starter | Fort — crash | World rule / event condition / smoke test vérifie party non vide |
| Species id `sproutle` absent dans le projet ouvert | Moyen | NS-GS-05 doit s'assurer que le projet Selbrume contient sproutle |
| Starter trop fort (écrase Lysa) | Faible | Les deux sont au L5 avec tackle+growl |
| Starter trop faible (perd systématiquement) | Faible | Le matchup Grass vs Fire favorise Lysa, mais la défaite est un outcome valide |
| Dialogue Maël incohérent | Moyen | NS-GS-08 doit rédiger un dialogue cohérent avec Option A |
| Option C complexifie le GS V0 | Fort — sur-ingénierie | Option C est explicitement déconseillée |

---

## 20. Décision finale

```text
Décision NS-GS-02 (corrigée NS-GS-02-bis) :

- GS V0 : Option A — Maël donne réellement sproutle (L5) au joueur en jeu.
  Le joueur commence sans Pokémon. givePokemon est obligatoire.

- GS V1 : Option A enrichie — meilleur dialogue, UX améliorée, choix starter éventuel.

- Option B : rejetée pour GS V0 (contourne le don au lieu de le prouver).

- Option C : rejetée (sur-ingénierie inutile).

- NS-GS-06 : obligatoire avant NS-GS-12.

- NS-GS-05 devra :
  - initialiser le joueur sans starter (party vide) ;
  - spawn à Bourg Selbrume, Maël accessible.

- NS-GS-06 devra :
  - implémenter addPartyMember / givePokemon minimal ;
  - être utilisable par ScenarioAsset ou script runtime ;
  - éviter les doublons (condition fact_starter_received).

- NS-GS-03 devra inventorier :
  - fixture GameState initial (party vide, bag, map, position) ;
  - species data sproutle (vérifier learnset, moves bridgeables) ;
  - action GivePokemon attendue ;
  - fact_starter_received ;
  - Yarn Maël V0 (formulation Option A : don du starter) ;
  - ScenarioAsset scene_mael_intro V0 (graphe avec givePokemon).

- NS-GS-04 devra prouver :
  - party vide au départ ;
  - starter reçu après Maël ;
  - starter survit save/load ;
  - combat Lysa démarrable après réception ;
  - givePokemon fonctionne.

- NS-GS-08 devra :
  - Maël donne réellement sproutle ;
  - scene_mael_intro utilise GivePokemon ;
  - yarn_mael_intro raconte le don.

- NS-GS-12 devra vérifier :
  - starter reçu en jeu, persisté et utilisé contre Lysa.
```

---

## 20bis. Roadmap impactée par la décision Option A

| Lot | Impact de la décision Option A |
|---|---|
| **NS-GS-03** | Inventorier sproutle comme starter donné par Maël ; action GivePokemon ; fact_starter_received ; conditions anti-redon |
| **NS-GS-04** | Tester party vide → starter reçu → save/load → combat Lysa ; tester givePokemon |
| **NS-GS-05** | Initialiser le joueur sans starter ; party vide ; Maël accessible |
| **NS-GS-06** | **Obligatoire** ; ajouter un Pokémon à la party ; utilisable par le pipeline narratif ; testé avant NS-GS-08/12 |
| **NS-GS-08** | Maël donne réellement sproutle ; scene_mael_intro utilise GivePokemon ; yarn raconte le don |
| **NS-GS-12** | Vérifie que le starter est reçu en jeu, persisté et utilisé |

---

## 21. Evidence Pack — NS-GS-02 + NS-GS-02-bis

### Git status initial (avant NS-GS-02-bis)

```bash
$ git status --short --untracked-files=all
?? reports/gameplay/ns_gs_02_starter_initial_party_decision.md
```

### Fichier modifié par NS-GS-02-bis

```text
reports/gameplay/ns_gs_02_starter_initial_party_decision.md
```

### Documents lus (NS-GS-02 initial)

```text
reports/gameplay/ns_gs_01_golden_slice_exact_specification.md
reports/gameplay/sel_a1_narrative_glossary.md
reports/gameplay/sel_a2_event_scene_outcome_fact_contract.md
reports/gameplay/sel_b2_battle_from_scene.md
reports/gameplay/sel_b1_fix_give_item_to_bag.md
MVP Selbrume/road_map.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
```

### Résumé des corrections NS-GS-02-bis

1. **Décision GS V0 corrigée** : Option B → Option A (Maël donne réellement le starter).
2. **Décision GS V1 corrigée** : Option A → Option A enrichie.
3. **NS-GS-06 corrigé** : reporté → obligatoire avant NS-GS-12.
4. **Impact Maël corrigé** : dialogue Option B → dialogue Option A (don du starter).
5. **Impact scene_mael_intro corrigé** : graphe simplifié → graphe avec givePokemon.
6. **Impact yarn_mael_intro corrigé** : formulation Option B → formulation don starter.
7. **Impacts NS-GS-03/04/05/12 corrigés** : party pré-chargée → party vide + givePokemon.
8. **Risques corrigés** : ajout risques GivePokemon trop large, double don, save/load après don.
9. **Section 20bis ajoutée** : Roadmap impactée par la décision Option A.
10. **Auto-review corrigée** : toutes les réponses reflètent Option A.

### Git status/diff final

```bash
$ git diff --check
(sortie vide — pas de whitespace errors)
EXIT:0

$ git diff --stat
(sortie vide — le fichier est untracked, pas staged)

$ git diff --name-only
(sortie vide — pas de fichier tracked modifié)

$ git status --short --untracked-files=all
?? reports/gameplay/ns_gs_02_starter_initial_party_decision.md
```

### Confirmations

```text
Un seul fichier modifié : reports/gameplay/ns_gs_02_starter_initial_party_decision.md
Aucun code modifié.
Aucune fixture modifiée.
Aucun test modifié.
Aucun build_runner lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 22. Auto-review

| Question | Réponse |
|---|---|
| La décision est-elle claire ? | ✅ Oui — GS V0 = Option A (Maël donne le starter). |
| La roadmap canonique est-elle respectée ? | ✅ Oui — aucun code, aucune fixture créée. |
| Le lot reste-t-il documentaire ? | ✅ Oui — un seul fichier MD modifié. |
| NS-GS-06 est-il clairement obligatoire ? | ✅ Oui — obligatoire avant NS-GS-12. |
| NS-GS-03 sait-il quoi inventorier ? | ✅ Oui — §15 + §20bis détaillent les éléments. |
| NS-GS-04 sait-il quoi prouver ? | ✅ Oui — §16 détaille les tests Option A. |
| NS-GS-05 sait-il initialiser sans starter ? | ✅ Oui — §17 dit party vide. |
| NS-GS-08 sait-il que Maël donne le starter ? | ✅ Oui — §12 + §20bis. |
| Le starter recommandé est-il fondé sur des données réelles ? | ✅ Oui — sproutle existe, enabled, learnset validé. |
| Y a-t-il une dette restante ? | ⚠️ Les paramètres exacts du starter (HP, nature) seront affinés dans NS-GS-11. |

---

*Fin du document NS-GS-02 (corrigé NS-GS-02-bis).*
