# NS-GS-04-bis — Mechanics-First Roadmap Alignment

---

## 1. Résumé exécutif

Ce lot formalise un changement de cap majeur sur la roadmap Narrative Studio / Golden Slice :

- **Selbrume reste un banc d'essai**, un scénario de référence, un cas de validation concret.
- **L'objectif n'est pas de créer le jeu Selbrume** dans le repo. L'objectif est de rendre PokeMap capable de faire Selbrume.
- **Les fixtures finales Selbrume seront créées par l'utilisateur** lui-même dans l'éditeur de jeu.
- **Les lots suivants deviennent des lots de mécanique générique** / authoring readiness / runtime readiness.
- **`MVP Selbrume/road_map.md` devient la source de vérité vivante** à mettre à jour à chaque lot.
- **NS-GS-03 et NS-GS-04 restent utiles** comme inventaire de référence et stratégie de preuve, mais leurs mentions de fixtures Selbrume doivent être lues comme support de validation, pas comme contenu à produire par les agents.

Ce lot ne crée aucun code, aucune fixture, aucun test. Il produit un rapport documentaire de réalignement et met à jour `road_map.md`.

Après review, le prochain lot est **NS-GS-05 — New Game Minimal Runtime** (mécanique générique, pas hardcodée Selbrume).

---

## 2. Sources et méthode

### Documents lus

| Document | Chemin |
|---|---|
| Roadmap courante | [road_map.md](file:///Users/karim/Project/pokemonProject/MVP%20Selbrume/road_map.md) |
| NS-GS-01 | [ns_gs_01_golden_slice_exact_specification.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_01_golden_slice_exact_specification.md) |
| NS-GS-02 | [ns_gs_02_starter_initial_party_decision.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_02_starter_initial_party_decision.md) |
| NS-GS-03 | [ns_gs_03_content_inventory_fixture_plan.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_03_content_inventory_fixture_plan.md) |
| NS-GS-04 | [ns_gs_04_runtime_smoke_strategy.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_04_runtime_smoke_strategy.md) |

### Méthode

Lecture de `road_map.md` (615 lignes). Le fichier contient déjà la roadmap mechanics-first complète, les principes de gouvernance, les 6 phases et les lots NS-GS-05 à NS-GS-18. Ce lot formalise cette roadmap comme source de vérité, ajoute la règle de maintenance permanente et produit le rapport documentaire.

---

## 3. Décision utilisateur à intégrer

> [!IMPORTANT]
> **Décision utilisateur canonique :**
>
> Les agents ne créent pas les fixtures Selbrume finales.
> L'utilisateur les créera lui-même plus tard dans l'éditeur de jeu.
> Les agents doivent ajouter les mécaniques manquantes qui rendent ce travail possible.

### Ce que Selbrume est désormais

```text
un scénario de référence
un banc d'essai pour prioriser les mécaniques manquantes
une cible de validation ("est-ce que PokeMap peut faire ça ?")
un exemple concret pour les tests et l'API
```

### Ce que Selbrume n'est pas

```text
un projet de contenu créé par Codex
un project.json final généré par agent
un pack de maps / NPCs / dialogues / battles créés en dur dans le repo
une démonstration produit livrée clé en main
```

---

## 4. Changement de lecture de la roadmap

| Avant | Après |
|---|---|
| NS-GS-08 = Bourg Selbrume / Maël Content | NS-GS-08 = NPC Interaction → Scene Authoring Readiness |
| NS-GS-09 = Port Brisants / Lysa Content | NS-GS-09 = Yarn Outcome → Scene Branch Readiness |
| NS-GS-10 = Storyline Chapter 1 Wiring | NS-GS-10 = World Rules / Conditional Presence Readiness |
| NS-GS-11 = Battle Lysa Authoring Fixture | NS-GS-11 = Trainer Battle Authoring Readiness |
| NS-GS-12 = Golden Slice Smoke Test | NS-GS-12 = Editor-authored Golden Slice Validation |
| Agents créent les fixtures Selbrume | Agents créent les mécaniques génériques |
| Fixtures = contenu final | Fixtures = support technique de test uniquement |

---

## 5. Règle permanente de mise à jour de road_map.md

À chaque lot NS-GS / NS-SB / Narrative Studio lié à ce chantier, l'agent doit :

1. **Lire** `MVP Selbrume/road_map.md` avant toute modification.
2. **Respecter** la roadmap canonique courante.
3. **Mettre à jour le statut** du lot exécuté (TODO → en cours → fait).
4. **Ajouter un résumé court** du résultat dans la section du lot.
5. **Mettre à jour** la section « Prochain lot recommandé ».
6. **Signaler** les décisions utilisateur nouvelles.
7. **Signaler** les changements de périmètre.
8. **Ne jamais transformer** un lot de mécanique générique en création de contenu Selbrume.
9. **Ne jamais créer** de fixtures Selbrume finales sauf demande explicite de l'utilisateur.
10. **Conserver** un Evidence Pack dans le rapport du lot.

---

## 6. Ce que les agents peuvent faire

```text
✅ Créer des mécaniques génériques (GivePokemon, NewGame, StepCompletion, etc.)
✅ Créer des actions runtime réutilisables (kScenarioActionGivePokemon, etc.)
✅ Créer des opérations pures dans map_gameplay (mutations, predicates)
✅ Créer des validators génériques (narrative validator, project validator)
✅ Créer des hooks de progression génériques (step completion, world rules)
✅ Créer des tests unitaires dans les packages concernés
✅ Créer des tests runtime dans map_runtime
✅ Créer de petites fixtures techniques de test strictement nécessaires
✅ Créer des objets in-memory dans les tests (fake GameState, fake ScenarioAsset)
✅ Créer un faux ScenarioAsset minimal dans un test
✅ Créer un faux GameState minimal dans un test
✅ Améliorer l'authoring dans l'éditeur si nécessaire
✅ Fournir des checklists de validation pour un projet authoré
✅ Fournir des diagnostics runtime si un projet est cassé
```

---

## 7. Ce que les agents ne doivent pas faire

```text
❌ Créer map_bourg_selbrume finale
❌ Créer map_port_brisants finale
❌ Créer npc_mael final (entity, dialogues, scène)
❌ Créer npc_lysa final (entity, dialogues, scène, trainer)
❌ Créer npc_soline final
❌ Écrire les dialogues finaux de Maël / Lysa / Soline
❌ Créer les ScenarioAssets finaux de Selbrume (scene_mael_intro, scene_rival_meet)
❌ Créer les RuntimeCutsceneAssets finaux de Selbrume
❌ Créer trainer_lysa_port final
❌ Créer battle_rival_port final
❌ Créer project.json Selbrume complet
❌ Créer les fixtures de save Selbrume finales (selbrume_initial_save.json, etc.)
❌ Remplir les Yarn dialogues de Selbrume avec du texte final
❌ Présenter du contenu de test comme contenu final Selbrume
```

---

## 8. Exception : fixtures techniques de test

### Autorisé

```text
Objet in-memory pour tester GivePokemon :
  final state = GameState.empty();
  final result = GameStateMutations.givePokemon(state, speciesId: 'test_species', level: 5);
  expect(result.party.members.length, 1);

Mini ScenarioAsset de test :
  final testScenario = ScenarioAsset(id: 'test_scene', nodes: [...]);

Fake map minimale pour tester une world rule :
  final testMap = MapData(id: 'test_map', entities: [...]);
```

### Interdit

```text
❌ map_bourg_selbrume.json copié dans les fixtures de test
❌ yarn_mael_intro_before_gift.yarn avec du vrai dialogue
❌ trainer_lysa_port.json avec la vraie team Lysa
❌ project_selbrume.json complet dans examples/
```

### Règle de distinction

```text
Si la fixture est nécessaire pour prouver qu'une mécanique générique fonctionne → autorisée.
Si la fixture reproduit le contenu final Selbrume → interdite.
Si la fixture contient des ids Selbrume réels (map_bourg_selbrume, npc_mael, etc.) → interdite,
  sauf si c'est strictement nécessaire pour un test technique et clairement documenté comme placeholder.
```

---

## 9. Roadmap corrigée complète

```text
PHASE 1 — Alignement (documentaire)
  ✅ NS-GS-01    — Golden Slice Exact Specification
  ✅ NS-GS-01-bis — Roadmap & Evidence Alignment Fix
  ✅ NS-GS-02    — Starter / Initial Party Decision
  ✅ NS-GS-02-bis — Starter Decision Alignment Fix
  ✅ NS-GS-03    — Content Inventory & Fixture Plan
  ✅ NS-GS-03-bis — Rival Outcome & World Rule Alignment Fix
  ✅ NS-GS-04    — Runtime Smoke Strategy
  ✅ NS-GS-04-bis — Mechanics-First Roadmap Alignment    ← CE LOT

PHASE 2 — Socle runtime générique (code)
  🔜 NS-GS-05   — New Game Minimal Runtime
     NS-GS-06   — GivePokemon Minimal
     NS-GS-07   — Step Completion / Progression Hooks V0

PHASE 3 — Authoring / runtime bridge générique (code + readiness)
     NS-GS-08   — NPC Interaction → Scene Authoring Readiness
     NS-GS-09   — Yarn Outcome → Scene Branch Readiness
     NS-GS-10   — World Rules / Conditional Presence Readiness
     NS-GS-11   — Trainer Battle Authoring Readiness

PHASE 4 — Validation depuis l'éditeur
     NS-GS-12   — Editor-authored Golden Slice Validation

PHASE 5 — Sécurité no-code
     NS-GS-13   — Narrative Validator Minimal V0

PHASE 6 — Extension gameplay
     NS-GS-14   — Item Pickup / GiveItem Authoring Readiness
     NS-GS-15   — Key Item / Door Gate Readiness
     NS-GS-16   — Side Quest / Optional Storyline Readiness
     NS-GS-17   — Static Encounter / Boss Battle Readiness
     NS-GS-18   — Reward / Money / XP Bridge Audit
```

---

## 10. Nouveau sens des lots NS-GS-05 à NS-GS-13

### NS-GS-05 — New Game Minimal Runtime

| Champ | Détail |
|---|---|
| Type | Code runtime générique |
| Objectif | Permettre de démarrer une nouvelle partie proprement |
| Doit permettre | Un projet authoré dans l'éditeur définit sa map de départ, position, état initial |
| Ne doit pas | Hardcoder map_bourg_selbrume, entity_mael_bourg, sproutle, Lysa |
| Package probable | map_runtime + peut-être playable_runtime_host |
| Tests | Obligatoires |
| Résultat | PokeMap sait lancer une nouvelle partie générique |

### NS-GS-06 — GivePokemon Minimal

| Champ | Détail |
|---|---|
| Type | Code gameplay/runtime générique |
| Objectif | Ajouter un Pokémon à la party via une action narrative |
| Doit permettre | Un PNJ authoré dans l'éditeur donne un Pokémon configuré |
| Ne doit pas | Créer Sproutle dans un projet Selbrume, créer UI choix starter, créer PC |
| Package probable | map_gameplay + map_runtime + map_core si besoin |
| Tests | Obligatoires |

### NS-GS-07 — Step Completion / Progression Hooks V0

| Champ | Détail |
|---|---|
| Type | Code runtime générique ou audit + code conditionnel |
| Objectif | Permettre de compléter une étape d'histoire depuis une action/fact/outcome |
| Doit permettre | CompleteStep action, step completed when fact set, persist save/load |
| Ne doit pas | Câbler les steps Selbrume finaux |
| Tests | Obligatoires |

### NS-GS-08 — NPC Interaction → Scene Authoring Readiness

| Champ | Détail |
|---|---|
| Type | Runtime/editor readiness |
| Objectif | Permettre à l'éditeur d'authorer un PNJ qui déclenche une scène |
| Cas de référence | « Maël donne un starter » — mais implémente « un PNJ peut donner un Pokémon et poser une mission » |
| Ne doit pas | Créer Maël final |

### NS-GS-09 — Yarn Outcome → Scene Branch Readiness

| Champ | Détail |
|---|---|
| Type | Runtime/editor readiness |
| Objectif | Permettre à l'éditeur d'authorer un dialogue Yarn avec outcomes qui branchent une scène |
| Cas de référence | confident / hesitant / aggressive → cinematic_rival_smiles / cinematic_rival_teases |
| Ne doit pas | Écrire yarn_rival_intro final |

### NS-GS-10 — World Rules / Conditional Presence Readiness

| Champ | Détail |
|---|---|
| Type | Runtime/editor readiness |
| Objectif | Permettre de modifier le monde selon facts/steps |
| Cas de référence | Lysa accessible seulement si fact_starter_received AND fact_mission_started |
| Ne doit pas | Créer Lysa finale |

### NS-GS-11 — Trainer Battle Authoring Readiness

| Champ | Détail |
|---|---|
| Type | Runtime/editor readiness |
| Objectif | Permettre à l'éditeur d'authorer un combat trainer lancé depuis une scène |
| Cas de référence | Combat rival |
| Ne doit pas | Créer trainer_lysa_port final |

### NS-GS-12 — Editor-authored Golden Slice Validation

| Champ | Détail |
|---|---|
| Type | Validation / smoke test |
| Objectif | Valider un mini-projet créé dans l'éditeur par l'utilisateur |
| Doit fournir | Checklist de validation, smoke harness générique, diagnostics |
| Ne doit pas | Créer les fixtures Selbrume à la place de l'utilisateur |

### NS-GS-13 — Narrative Validator Minimal V0

| Champ | Détail |
|---|---|
| Type | Validator générique |
| Objectif | Détecter les erreurs narrativo-runtime critiques dans un projet authoré |
| Détections | Scene absente, Yarn absent, outcome non géré, trainer absent, fact jamais produit, world rule cible absente, step impossible |

---

## 11. Extension post-Golden Slice NS-GS-14 à NS-GS-18

| Lot | Objectif | Cas de référence | Mécanique générique |
|---|---|---|---|
| NS-GS-14 | Item Pickup / GiveItem Authoring Readiness | Objet ramassable | Objet → Bag, fact, empêche double, save/load |
| NS-GS-15 | Key Item / Door Gate Readiness | Cabane du phare | Condition HasItem/HasFact → porte ouverte/fermée |
| NS-GS-16 | Side Quest / Optional Storyline Readiness | Cristaux de sel / Goélise | Quête annexe optionnelle, steps, récompense |
| NS-GS-17 | Static Encounter / Boss Battle Readiness | Pokémon du phare | Combat static one-shot, victory/capture/defeat |
| NS-GS-18 | Reward / Money / XP Bridge Audit | Post-battle rewards | XP, money, level-up, give item after battle |

---

## 12. Impact sur les rapports NS-GS-03 et NS-GS-04

### NS-GS-03 — Content Inventory & Fixture Plan

```text
Reste utile comme inventaire de référence.
Les ids, entities, facts, world rules listés sont la cible de validation.
Mais les mentions de fixtures (selbrume_initial_save.json, etc.) doivent être lues comme
"support de validation pour NS-GS-12", pas comme "contenu à créer par les agents".
```

### NS-GS-04 — Runtime Smoke Strategy

```text
Reste utile comme stratégie de preuve.
Les 13 tests (GS-T01 à GS-T13) et les 8 gates (A à H) sont toujours valides.
Mais les tests doivent utiliser des fixtures techniques de test,
pas des fixtures Selbrume finales.
```

### Interprétation correcte

```text
NS-GS-03 = "voici ce que le projet Selbrume doit contenir pour fonctionner"
NS-GS-04 = "voici comment prouver que les mécaniques permettent à ce projet de fonctionner"
Ni l'un ni l'autre ne doit être lu comme "les agents créent ce contenu".
```

---

## 13. Impact sur les prochains prompts

Bloc réutilisable à inclure dans tous les futurs prompts liés au chantier :

```md
## Obligation roadmap

Avant toute modification, lire :

`MVP Selbrume/road_map.md`

À la fin du lot, mettre à jour ce fichier avec :

- statut du lot ;
- résumé du résultat ;
- décisions prises ;
- prochaine étape recommandée ;
- éventuelles déviations ;
- confirmation que le lot respecte l'approche mechanics-first.

Ne pas créer de contenu Selbrume final sauf demande explicite de l'utilisateur.
```

---

## 14. Prochain lot recommandé

```text
NS-GS-05 — New Game Minimal Runtime
```

Périmètre :

```text
Mécanique générique de nouvelle partie.
Pas hardcodée Selbrume.
Pas de fixtures Selbrume finales.
Compatible projet authoré dans l'éditeur.
ProjectManifest.startMapId / startSpawnId.
Initial party vide si le projet le demande.
Tests unitaires obligatoires.
Mettre à jour MVP Selbrume/road_map.md.
```

---

## 15. Evidence Pack

### Git status initial

```bash
$ git status --short --untracked-files=all
(working tree propre)
```

### Documents lus

```text
MVP Selbrume/road_map.md (615 lignes)
reports/gameplay/ns_gs_03_content_inventory_fixture_plan.md (sections §1, §25, §27)
reports/gameplay/ns_gs_04_runtime_smoke_strategy.md (sections §1, §22, §24)
reports/gameplay/ns_gs_02_starter_initial_party_decision.md (décision Option A)
reports/gameplay/ns_gs_01_golden_slice_exact_specification.md (pipeline spec)
```

### Fichiers créés/modifiés

```text
CRÉÉ  : reports/gameplay/ns_gs_04_bis_mechanics_first_roadmap_alignment.md
MODIFIÉ : MVP Selbrume/road_map.md
```

### Git status/diff final

```bash
$ git diff --check
(sortie vide — pas de whitespace errors)
EXIT:0

$ git diff --stat
 MVP Selbrume/road_map.md | 116 ++++++++++++++++++++++++++---------------------
 1 file changed, 64 insertions(+), 52 deletions(-)

$ git diff --name-only
MVP Selbrume/road_map.md

$ git status --short --untracked-files=all
 M "MVP Selbrume/road_map.md"
?? reports/gameplay/ns_gs_04_bis_mechanics_first_roadmap_alignment.md
```

### Confirmations

```text
Aucun code modifié.
Aucune fixture finale créée.
Aucun test modifié.
Aucun build_runner lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 16. Auto-review

| Question | Réponse |
|---|---|
| La décision utilisateur est-elle intégrée ? | ✅ §3 — agents ne créent pas les fixtures Selbrume finales |
| La roadmap est-elle mechanics-first ? | ✅ §9 — roadmap complète de NS-GS-05 à NS-GS-18 |
| road_map.md est-il mis à jour ? | ✅ Section NS-GS-04-bis ajoutée + règle permanente |
| La règle de mise à jour permanente est-elle claire ? | ✅ §5 — 10 points |
| Les agents sont-ils empêchés de créer Selbrume ? | ✅ §7 — liste d'interdictions explicite |
| Le prochain lot NS-GS-05 est-il bien cadré ? | ✅ §14 — mécanique générique, pas hardcodée |
| NS-GS-03/04 restent-ils utiles ? | ✅ §12 — utiles comme référence, pas comme commande de création |
| Y a-t-il une dette restante ? | ⚠️ Les prochains prompts doivent inclure le bloc §13 |

---

*Fin du document NS-GS-04-bis.*
