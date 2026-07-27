# PokeMap — Roadmap mécanique fangame Pokémon-like

**Version :** 2026-07-23
**Portée :** mécaniques de jeu uniquement. Pas de polish visuel, pas d’ombres, pas de Surface/Path/Environment Studio sauf quand une mécanique en dépend directement.  
**Objectif produit :** permettre de créer un fangame Pokémon-like court, jouable sans code, avec exploration, rencontres, combats, capture, progression, inventaire, événements et sauvegarde fiable.

---

## 0. Mode d’emploi pour agents IA

Ce fichier sert de **source de suivi**. Un agent peut s’en servir pour répondre à deux questions :

```text
Est-ce que cette mécanique est finie ?
Si non, quel lot faut-il exécuter ensuite ?
```

### 0.1 Légende des statuts

| Statut | Signification | Qui peut le poser ? |
|---|---|---|
| `✅ DONE` | Implémenté, testé, documenté, preuves fournies | Agent reviewer ou utilisateur |
| `🟡 PARTIAL` | Base existante mais limitée, non intégrée ou incomplète | Agent reviewer |
| `⬜ TODO` | Non démarré ou non prouvé | Par défaut |
| `🔴 BLOCKED` | Bloqué par dépendance technique ou décision produit | Agent reviewer + justification |
| `⏸ DEFERRED` | Hors MVP ou volontairement repoussé | Utilisateur ou roadmap |
| `🧪 AUDIT` | Lot d’audit sans modification de code | Agent exécutant |

### 0.2 Règle dure : ne jamais marquer `DONE` sans preuve

Un lot ne passe en `✅ DONE` que si le rapport final contient au minimum :

```text
- statut final clair ;
- fichiers créés / modifiés / supprimés ;
- inventaire complet des fichiers, y compris untracked ;
- commandes exécutées ;
- résultats exacts des tests/analyzes ;
- limites connues ;
- risques restants ;
- git status --short --untracked-files=all final ;
- justification que le périmètre du lot est respecté.
```

Pour les lots mécaniques, le rapport recommandé est :

```text
reports/gameplay/fg_<id>_<slug>.md
```

Exemple :

```text
reports/gameplay/fg_024_capture_destination_party_or_box.md
```

### 0.3 Règles d’architecture à respecter

Le repo est un monorepo Dart/Flutter. Les responsabilités doivent rester séparées :

| Package | Rôle | Règle |
|---|---|---|
| `packages/map_core` | modèles, contrats, JSON, validations | pur Dart, pas Flutter/Flame |
| `packages/map_gameplay` | logique overworld pure | pur Dart, dépend de `map_core` |
| `packages/map_battle` | moteur de combat | pur Dart, indépendant de Flutter |
| `packages/map_runtime` | intégration runtime Flutter/Flame | handoff battle, save/load, UI runtime, overlays |
| `packages/map_editor` | outil auteur desktop | no-code authoring, ne pas coupler au rendu runtime |
| `examples/playable_runtime_host` | host de smoke tests runtime | golden slice jouable |

Règle importante : **les règles gameplay ne doivent pas être cachées dans Flame**. Les règles vont dans `map_gameplay` ou `map_core`. Flame consomme des décisions déjà calculées.

### 0.4 Commandes de vérification recommandées

À adapter selon les fichiers touchés.

```bash
cd packages/map_core && dart test
cd packages/map_core && dart analyze

cd packages/map_gameplay && dart test
cd packages/map_gameplay && dart analyze

cd packages/map_battle && dart test
cd packages/map_battle && dart analyze

cd packages/map_runtime && flutter test
cd packages/map_runtime && flutter analyze

cd packages/map_editor && flutter test
cd packages/map_editor && flutter analyze

cd examples/playable_runtime_host && flutter test
cd examples/playable_runtime_host && flutter analyze
```

Smoke tests runtime à privilégier dès qu’un lot touche la boucle joueur ou battle :

```bash
cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
```

### 0.5 Format de mise à jour de statut

Quand un lot est terminé, mettre à jour la table correspondante ainsi :

```md
| FG-024 | Capture Destination: Party or Box | ✅ DONE | reports/gameplay/fg_024_capture_destination_party_or_box.md | 2026-05-22 | Capture vers party ou box prouvée par tests runtime + map_core. |
```

Ne pas écrire `DONE` si le rapport dit seulement “ça devrait marcher”. PokeMap n’a pas besoin de voyants verts imaginaires, il a besoin de preuves.

### 0.6 Cadence de mise à jour

À partir du 2026-07-23, cette roadmap doit être mise à jour à chaque clôture de
lot ou de phase :

```text
1. mettre à jour la ligne FG concernée avec statut, preuve et commit ;
2. cocher uniquement les critères de DoD fraîchement prouvés ;
3. recalculer le statut de la phase synthétique sans masquer les lots restants ;
4. conserver les limites, régressions historiques et gates encore ouvertes ;
5. inclure la modification de roadmap dans le commit du lot quand celui-ci est
   encore ouvert, sinon produire une modification documentaire distincte.
```

Dernère mise à jour : **2026-07-23** — phase MVP 3, services joueur.
`FG-026`, `FG-027`, `FG-028`, `FG-061`, `FG-062` et `FG-070` sont fermés par
les UI Party/Bag/shop et leur transaction runtime + sauvegarde. `FG-029` reste
partiel faute d'accès Summary depuis le PC ; `FG-071` reste partiel jusqu'à la
commande Scene `HealParty`. Les commits de preuve sont `12a8af78`, `f44ab359`
et celui du lot 3.5 créé avec cette mise à jour.

---

## 1. Diagnostic actuel résumé

### 1.1 Ce qui existe déjà

| Bloc | État actuel | Statut roadmap |
|---|---|---|
| Architecture multi-packages | `map_core`, `map_gameplay`, `map_battle`, `map_runtime`, `map_editor` sont séparés | `✅ DONE` fondation |
| Données projet | `ProjectManifest` porte déjà beaucoup de données : maps, tilesets, terrains, paths, encounters, dialogues, scripts, scenarios, trainers, Pokémon config, etc. | `🟡 PARTIAL` car pas encore gameplay complet |
| Save/GameState | `GameState` contient déjà map courante, position/facing, mode de déplacement, party, trainer profile, bag, progression, variables, story flags, événements consommés | `🟡 PARTIAL` |
| Gameplay zones | Zones de rencontres, contraintes de déplacement, hazards, zones spéciales/custom | `🟡 PARTIAL` |
| Rencontres wild walk/surf | Le runtime sait déclencher des rencontres aléatoires walk/surf vers battle request | `🟡 PARTIAL` |
| Surf | Évaluation pure déjà bonne : cible eau, déjà en surf, Pokémon utilisable, capacité débloquée | `🟡 PARTIAL` car Surf existe, mais les autres field moves restent à faire |
| Battle engine | Moteur avec décisions, timeline, statuts, météo/terrain, hazards, switch, AI, items/actions, registres moves/items/abilities | `🟡 PARTIAL` car parité incomplète |
| Runtime battle handoff | Mapping save/projet vers `BattleSetup`, création session, overlay, seen/caught partiel | `🟡 PARTIAL` |
| Post-battle write-back | HP, PP, statut, XP, niveaux, moves, évolution, récompenses trainer et destination de capture sont appliqués transactionnellement | `✅ DONE` pour le périmètre FG-040 à FG-049 / FG-051 ; PC plein traité en Phase 3 du plan MVP |
| Trainer editor | Roster, détails, équipes, espèces/moves/items via catalogues | `🟡 PARTIAL` côté authoring |
| Narrative studios | Dialogue/Step/Global Story/Cutscene existent comme squelette auteur | `🟡 PARTIAL` car actions gameplay manquantes |

### 1.2 Ce qui manque pour fermer la boucle RPG

La boucle cible est :

```text
nouvelle partie
→ choix starter / état initial
→ exploration
→ dialogue / événement
→ rencontre ou trainer battle
→ combat
→ capture / récompense / XP
→ level-up / moves / évolution
→ inventaire / équipe / soin / PC
→ progression histoire
→ sauvegarde / chargement fiable
```

Aujourd’hui, plusieurs segments existent, mais la chaîne complète n’est pas fermée. Les gros trous sont :

```text
- PC/Boxes ;
- menu party runtime ;
- progression XP / level-up / moves / évolutions ;
- récompenses combat : argent, badges, items, post-battle dialogue ;
- bag runtime complet ;
- shops / centre Pokémon / item pickups ;
- catalogue d’actions événementielles no-code ;
- field moves hors Surf ;
- rencontres statiques, gifts, pêche, headbutt ;
- validation “ce projet est réellement jouable”.
```

---

## 2. MVP cible : Golden Slice Fangame

### 2.1 Définition

Le MVP n’est pas “toutes les mécaniques Pokémon modernes”. Le MVP est :

```text
Un fangame court de 30 à 60 minutes, jouable sans code.
```

### 2.2 Checklist produit MVP

Le MVP est atteint quand un créateur peut faire ceci dans PokeMap :

```md
- [ ] Créer une nouvelle partie.
- [ ] Choisir un starter.
- [ ] Explorer 2–3 maps connectées.
- [ ] Parler à des PNJ.
- [ ] Avoir des dialogues conditionnels.
- [ ] Déclencher des cutscenes simples.
- [ ] Faire des rencontres sauvages en herbe.
- [ ] Capturer des Pokémon.
- [ ] Envoyer automatiquement au PC si la party est pleine.
- [ ] Combattre des trainers.
- [ ] Gagner XP + argent.
- [ ] Level-up.
- [ ] Apprendre une attaque.
- [ ] Obtenir un badge ou flag.
- [ ] Débloquer Surf ou Cut.
- [ ] Utiliser un shop.
- [ ] Se soigner dans un centre Pokémon.
- [ ] Sauvegarder / charger proprement.
- [ ] Finir une mini-histoire.
```

### 2.3 Non-objectifs MVP

À ne pas prioriser maintenant :

```text
- ombres ;
- surface polish ;
- animation eau avancée ;
- tilesets artistiques ;
- battle FX ;
- caméra cinématique ;
- UI très jolie ;
- rendu avancé runtime ;
- doubles/triples battles ;
- contests ;
- daycare/breeding ;
- online trades/battles ;
- battle frontier ;
- casino/minigames ;
- Mega / Tera / Z-Moves / Dynamax ;
- IV/EV/natures avancés si non nécessaires au MVP.
```

---

## 3. Priorités mécaniques

| Priorité | Bloc | Pourquoi c’est bloquant | Statut |
|---:|---|---|---|
| 1 | Party + PC + Bag runtime | La boucle collection/soin/capture reste cassée sans ça | `🟡 PARTIAL` — parcours jouables ; Summary depuis le PC reste absent |
| 2 | XP + level-up + évolution | Les combats ne font pas progresser les Pokémon | `✅ DONE` |
| 3 | Rewards combat + argent + badges | Les trainers ne structurent pas encore l’aventure | `✅ DONE` pour le contrat et l’application post-combat MVP |
| 4 | Event command catalog | Sans actions no-code, l’éditeur reste trop technique | `⬜ TODO` |
| 5 | Field moves hors Surf | Sans gates environnementaux, la progression map est plate | `⬜ TODO` |
| 6 | Shops / heal center / pickups | Sans économie et recovery, le jeu ne vit pas | `🟡 PARTIAL` — shop et soin menu fermés ; pickups et commande Scene heal restent ouverts |
| 7 | Battle write-back complet | PP/status/held items doivent survivre au combat | `🟡 PARTIAL` : HP/PP/status/progression fermés ; mutation held item non ouverte |
| 8 | Encounter types élargis | Statics, gifts, fishing, headbutt donnent la vraie saveur Pokémon | `⬜ TODO` |
| 9 | Runtime menus | Pause, party, bag, Pokédex, options sont indispensables | `🟡 PARTIAL` — pause, Party, Bag, Pokédex, options, shop, PC et soin prouvés |
| 10 | Validation jeu jouable | Le créateur doit savoir si son projet est cassé avant le runtime | `⬜ TODO` |

---

## 4. Roadmap synthétique

| Phase | Lots | Objectif | Dépendance | Statut |
|---|---:|---|---|---|
| Phase 0 | FG-000 → FG-009 | Audit et contrats de suivi | Aucun | `⬜ TODO` |
| Phase 1 | FG-010 → FG-019 | New Game, starter, save/load, pause shell | Phase 0 | `⬜ TODO` |
| Phase 2 | FG-020 → FG-039 | Party, PC, capture crédible | Phase 1 | `🟡 PARTIAL` — 10/11 lots fermés, FG-029 partiel |
| Phase 3 | FG-040 → FG-059 | Battle persistence, rewards, XP, level-up, évolutions | Phase 2 | `🟡 PARTIAL` — FG-040 à FG-049 et FG-051 fermés |
| Phase 4 | FG-060 → FG-079 | Bag, items, shops, centre Pokémon | Phase 2 | `🟡 PARTIAL` — FG-060/061/062/063/069/070 fermés ; FG-071 partiel |
| Phase 5 | FG-080 → FG-099 | Event commands no-code | Phases 1–4 selon commandes | `⬜ TODO` |
| Phase 6 | FG-100 → FG-119 | Encounters élargis | Phases 2, 5 | `⬜ TODO` |
| Phase 7 | FG-120 → FG-139 | Field moves / environmental gates | Phases 2, 5 | `⬜ TODO` |
| Phase 8 | FG-140 → FG-159 | Trainers, badges, gyms, templates histoire | Phases 3, 5 | `⬜ TODO` |
| Phase 9 | FG-160 → FG-179 | Menus runtime et UX joueur | Phases 1–4 | `⬜ TODO` |
| Phase 10 | FG-180 → FG-199 | Validator + Golden Slice complet | Toutes phases MVP | `⬜ TODO` |
| Phase 11 | FG-200+ | Post-MVP / parité avancée | MVP validé | `⏸ DEFERRED` |

---

# Phase 0 — Audit et contrat de roadmap

## FG-000 — Fangame Mechanics Readiness Audit V0

**Statut :** `⬜ TODO`  
**Type :** audit sans code  
**But :** établir l’état exact avant de modifier quoi que ce soit.

### Scope

Inspecter :

```text
packages/map_core
packages/map_gameplay
packages/map_battle
packages/map_runtime
packages/map_editor
examples/playable_runtime_host
reports/
docs/combat/
```

### Livrable

```text
reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
```

### DoD

```md
- [ ] Inventaire des mécaniques présentes.
- [ ] Inventaire des mécaniques absentes.
- [ ] Statut par package : modèle / gameplay / battle / runtime / editor.
- [ ] Liste des tests existants utiles.
- [ ] Liste des fixtures golden utiles.
- [ ] Proposition de statut initial pour chaque lot de cette roadmap.
- [ ] Aucune modification de code.
```

### Vérification

```bash
git status --short --untracked-files=all
```

---

## FG-001 — Roadmap Tracker Repo Integration V0

**Statut :** `⬜ TODO`  
**But :** copier cette roadmap dans le repo, dans un emplacement canonique.

### Chemin recommandé

```text
docs/gameplay/fangame_mechanics_roadmap.md
```

Si `docs/` est gitignored sauf exceptions, utiliser :

```text
reports/gameplay/fangame_mechanics_roadmap.md
```

### DoD

```md
- [ ] Le fichier est ajouté au repo.
- [ ] Le chemin est mentionné dans `AGENTS.md` ou dans un rapport de reprise si besoin.
- [ ] Le statut de chaque lot peut être mis à jour sans toucher au code.
- [ ] Aucun fichier généré ou cache n’est ajouté.
```

---

# Phase 1 — Runtime Player Loop

Objectif : le joueur peut démarrer une partie, recevoir un état initial, choisir un starter, sauvegarder/charger et ouvrir une première interface de pause.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-010 | Initial GameState Builder V0 | `⬜ TODO` | — |
| FG-011 | New Game Runtime Flow V0 | `⬜ TODO` | — |
| FG-012 | Starter Selection Model V0 | `⬜ TODO` | — |
| FG-013 | Starter Selection Runtime Flow V0 | `⬜ TODO` | — |
| FG-014 | Save/Load Transaction Hardening V0 | `✅ DONE` | `playable_map_game_save_load_transaction_test.dart` + Golden Slice Selbrume rollback/retry |
| FG-015 | Runtime Pause Menu Shell V0 | `⬜ TODO` | — |
| FG-016 | Golden Runtime Boot Smoke V0 | `⬜ TODO` | — |

## FG-010 — Initial GameState Builder V0

**Packages probables :** `map_core`, éventuellement `map_runtime` pour consommation.  
**But :** créer une API pure qui construit un `GameState` initial valide depuis un projet.

### À produire

```text
- modèle ou opération pure de construction d’état initial ;
- validation des champs nécessaires : saveId, mapId, position, facing, party vide ou starter pending, trainer profile, bag initial, progression initiale ;
- erreurs explicites si start map / spawn / config manquent.
```

### DoD

```md
- [ ] Builder pur dans `map_core` ou opération dédiée.
- [ ] Tests succès : état initial minimal valide.
- [ ] Tests erreurs : map absente, spawn absent, config incohérente.
- [ ] Pas de Flutter/Flame dans `map_core`.
- [ ] Aucun lancement runtime caché dans le builder.
```

## FG-011 — New Game Runtime Flow V0

**Packages probables :** `map_runtime`, `examples/playable_runtime_host`.  
**But :** brancher le builder à un flux runtime “Nouvelle partie”.

### DoD

```md
- [ ] Le runtime peut créer une save neuve sans fixture manuelle fragile.
- [ ] Le joueur arrive sur la bonne map, à la bonne position.
- [ ] Le flux ne contourne pas la validation du `GameState`.
- [ ] Smoke test runtime : lancement nouvelle partie.
```

## FG-012 — Starter Selection Model V0

**Packages probables :** `map_core`, `map_editor`.  
**But :** représenter les options de starter dans les données projet.

### DoD

```md
- [ ] Modèle de configuration des starters.
- [ ] Chaque starter référence une espèce existante.
- [ ] Moves initiaux validables.
- [ ] Item tenu optionnel validable.
- [ ] Level initial validé.
- [ ] Tests JSON/validation si modèle persistant.
```

## FG-013 — Starter Selection Runtime Flow V0

**Packages probables :** `map_runtime`, `map_gameplay`.  
**But :** permettre au joueur de choisir un starter et l’ajouter à sa party.

### DoD

```md
- [ ] UI/runtime flow minimal.
- [ ] Ajout exact du starter choisi à la party.
- [ ] Flag ou événement consommé empêchant de reprendre plusieurs starters.
- [ ] Test runtime ou widget selon architecture.
- [ ] Aucun starter hardcodé hors fixture/demo.
```

## FG-014 — Save/Load Transaction Hardening V0

**Packages probables :** `map_runtime`, `map_core`.  
**But :** éviter un runtime partiellement modifié après un échec de chargement.

### DoD

```md
- [x] Audit du flux load actuel.
- [x] Chargement préparé avant mutation destructive.
- [x] Échec de load = état runtime précédent conservé ou erreur propre.
- [x] Tests d'échec : map absente, layer invalide, save corrompue.
- [x] Rapport indiquant les limites restantes dans la roadmap de clôture MVP.
```

**Preuve (2026-07-23) :** `playable_map_game_save_load_transaction_test.dart`
(`+5`), `file_game_save_repository_test.dart` (`+15`) et
`p6_selbrume_save_load_golden_slice_test.dart` (`+2`) prouvent préparation,
rollback complet, sauvegarde intacte, input/save encore utilisables et retry
réussi sur les vraies maps Selbrume. Analyse Runtime propre. Limite externe au
lot : quatre tests Battle de l'ancienne fixture checkpoint restent rouges car
son catalogue de moves sous `/tmp/checkpoint_load_safety` est absent.

## FG-015 — Runtime Pause Menu Shell V0

**Packages probables :** `map_runtime`.  
**But :** ouvrir un menu pause minimal sans encore tout implémenter.

### DoD

```md
- [ ] Entrée clavier/manette/souris selon convention existante.
- [ ] Options visibles : Party, Bag, Save, Options, Close.
- [ ] Options non prêtes désactivées ou route vers placeholder explicite.
- [ ] Le jeu se met en état input-safe pendant le menu.
```

## FG-016 — Golden Runtime Boot Smoke V0

**Packages probables :** `examples/playable_runtime_host`, `map_runtime`.  
**But :** fixture de smoke test pour la boucle boot/new game.

### DoD

```md
- [ ] Test lance le host.
- [ ] Test crée ou charge une partie neuve.
- [ ] Test vérifie map, position, party initiale ou starter pending.
- [ ] Test documenté comme gate de régression.
```

---

# Phase 2 — Party, PC, capture

Objectif : capturer reste utile même quand la party contient déjà 6 Pokémon.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-020 | PlayerPokemon Runtime Persistence Audit | `✅ DONE` | [Contrat et audit champ par champ](reports/gameplay/fg_040_battle_persistence_contract_v0.md), `caf97a2e1` |
| FG-021 | PlayerPokemon Persistence Expansion V0 | `✅ DONE` | XP/PP compatibles legacy, hydratation catalogues et round-trip, `caf97a2e1` |
| FG-022 | PC Box Model V0 | `✅ DONE` | 8 boxes stables de 30 slots, migration legacy et round-trip ; lot 3.1, Core 4381/4381 |
| FG-023 | PC Storage Operations V0 | `✅ DONE` | Opérations atomiques et erreurs typées ; lot 3.2, Gameplay 380/380 |
| FG-024 | Capture Destination: Party or Box V0 | `✅ DONE` | Destination party/première box et saturation typée ; lot 3.2 |
| FG-025 | Capture To Box When Party Full V0 | `✅ DONE` | Write-back runtime, destination lisible et refus avant débit si PC plein ; lot 3.2 |
| FG-026 | Runtime Party Menu Read-only V0 | `✅ DONE` | Menu pause, 1–6 Pokémon et état vide testés ; lot 3.3, `12a8af78` |
| FG-027 | Pokémon Summary Runtime V0 | `✅ DONE` | XP/PV/statut/nature/talent/objet et moves+PP visibles ; lot 3.3, `12a8af78` |
| FG-028 | Party Reorder / Lead Selection V0 | `✅ DONE` | Swap/lead purs, UI et transaction runtime testés ; lots 3.2–3.5 |
| FG-029 | Runtime PC Screen V0 | `🟡 PARTIAL` | Dépôt/retrait/swap et garde last usable testés ; accès Summary depuis le PC absent |
| FG-030 | Party/Box Validation V0 | `✅ DONE` | Diagnostics typés party/box/catalogues et messages lisibles ; lot 3.1 |

## FG-020 — PlayerPokemon Runtime Persistence Audit

**Type :** audit sans code.  
**But :** déterminer exactement quels champs Pokémon sont persistés, perdus ou inventés.

### À inspecter

```text
- PlayerPokemon ;
- PlayerParty ;
- GameState persistence ;
- battle setup mapper ;
- battle outcome apply ;
- capture builder ;
- normalization loaded game state.
```

### DoD

```md
- [x] Tableau champ par champ : species, level, hp, pp, status, moves, ability, nature, held item, form, shiny, exp, friendship, etc.
- [x] Statut : persistant / partiel / absent / inventé au fallback.
- [x] Recommandation de modèle minimal MVP.
- [x] Audit isolé dans le rapport avant l’extension de modèle FG-021.
```

## FG-021 — PlayerPokemon Persistence Expansion V0

**But :** ajouter les champs manquants nécessaires au MVP, sans ouvrir IV/EV complets si non requis.

### Champs MVP recommandés

```text
- level ;
- experience ou expIntoLevel ;
- currentHp ;
- maxHp si non dérivable simplement ;
- majorStatus ;
- known moves avec currentPp/maxPp ;
- heldItemId optionnel ;
- formId optionnel ;
- met metadata minimale optionnelle.
```

### DoD

```md
- [x] Modèle compatible anciennes saves.
- [x] JSON/migration si nécessaire.
- [x] Tests de normalisation.
- [x] Aucun calcul battle complexe caché dans le modèle.
```

## FG-022 — PC Box Model V0

**But :** créer le stockage PC/Boxes côté save.

### DoD

```md
- [x] Modèle `PokemonStorage` ou équivalent.
- [x] Liste de boxes nommées avec IDs stables.
- [x] Slots bornés à 30 par box par défaut.
- [x] Capacité configurable par box et constante par défaut documentée.
- [x] Sérialisation/normalisation avec migration de `storedPokemon`.
- [x] Tests : box vide, contenu, ordre, round-trip et limites.
```

## FG-023 — PC Storage Operations V0

**But :** opérations pures pour manipuler party/PC.

### Opérations minimales

```text
- deposit party -> box ;
- withdraw box -> party ;
- move within box ;
- move box -> box ;
- swap party/box ;
- find first available slot ;
- validate not removing last usable Pokémon si règle activée.
```

### DoD

```md
- [x] Opérations pures testées.
- [x] Erreurs explicites : slot invalide, party pleine, box pleine.
- [x] Pas de UI.
- [x] Pas de repo disque.
```

## FG-024 — Capture Destination: Party or Box V0

**But :** remplacer la logique “party pleine = erreur” par une décision explicite.

### Décision attendue

```text
si party.size < 6 → destination party
sinon si PC a une place → destination première box libre
sinon → capture impossible / storage full
```

### DoD

```md
- [x] Fonction pure de décision.
- [x] Tests party disponible.
- [x] Tests party pleine + box disponible.
- [x] Tests storage full.
- [x] Le résultat contient la destination et le runtime produit son message.
```

## FG-025 — Capture To Box When Party Full V0

**But :** intégrer la destination de capture dans le write-back runtime.

### DoD

```md
- [x] Capture ajoute à la party si place.
- [x] Capture ajoute au PC si party pleine.
- [x] Poké Ball consommée exactement une fois.
- [x] Seen/caught normalisé.
- [x] Message runtime indique la destination.
- [x] Tests outcome apply : party, box, storage full avant tentative.
```

## FG-026 — Runtime Party Menu Read-only V0

**But :** voir son équipe en runtime.

### DoD

```md
- [x] Menu accessible depuis pause.
- [x] Affiche 1 à 6 Pokémon.
- [x] Affiche nom/espèce, niveau, PV, statut, moves résumés.
- [x] Le changement d’ordre est fourni par FG-028, sans état intermédiaire invalide.
- [x] Cas party vide géré proprement.
```

## FG-027 — Pokémon Summary Runtime V0

**But :** écran détail Pokémon.

### DoD

```md
- [x] Stats persistées utiles (XP/PV/niveau/statut) visibles.
- [x] Moves + PP visibles.
- [x] Nature/ability/held item visibles si modèle disponible.
- [x] Pas d’édition runtime non prévue.
```

## FG-028 — Party Reorder / Lead Selection V0

**But :** changer le lead et réordonner l’équipe.

### DoD

```md
- [x] Swap deux slots party.
- [x] Le changement de lead place explicitement la cible en tête.
- [x] Impossible de créer un état invalide.
- [x] Tests opérations pures + runtime smoke.
```

## FG-029 — Runtime PC Screen V0

**But :** ouvrir le PC et gérer party/boxes.

### DoD

```md
- [x] Écran PC minimal accessible depuis le menu pause runtime.
- [x] Withdraw/deposit/move fonctionnels.
- [ ] Summary accessible.
- [x] Validation last usable Pokémon si règle retenue.
```

## FG-030 — Party/Box Validation V0

**But :** le validator signale les états de party/storage cassés.

### DoD

```md
- [x] Diagnostic party > 6.
- [x] Diagnostic box overflow.
- [x] Diagnostic Pokémon sans espèce valide.
- [x] Diagnostic move inconnu si catalogues chargés.
- [x] Rapport typé avec chemin et message lisible pour agent et utilisateur.
```

---

# Phase 3 — Battle persistence, rewards, XP, progression

Objectif : les combats changent réellement la progression joueur/Pokémon.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-040 | Battle Persistence Contract V0 | `✅ DONE` | [Contrat de persistance](reports/gameplay/fg_040_battle_persistence_contract_v0.md), `caf97a2e1` |
| FG-041 | PP Write-back V0 | `✅ DONE` | Seed et write-back multi-combattants, `475789b25` |
| FG-042 | Major Status Write-back V0 | `✅ DONE` | Bridge des statuts majeurs et cohérence HP/K.O., `475789b25` |
| FG-043 | Battle Reward Model V0 | `✅ DONE` | Contrats typés wild/trainer, argent/items/flags/badge, `f07362f0b` |
| FG-044 | XP Distribution V0 | `✅ DONE` | Participants exacts, multi-adversaires et catalogues stricts, `2bbba3ed8` |
| FG-045 | Level-up Apply V0 | `✅ DONE` | Level cap, multi-level, recalcul stats/HP, `2bbba3ed8` |
| FG-046 | Learn Move on Level-up V0 | `✅ DONE` | Ajout, remplacement et refus, `9b988c78e` |
| FG-047 | Evolution Check V0 | `✅ DONE` | Évolution niveau, acceptation/refus et préservation d’état, `ce8812bdb` |
| FG-048 | Post-battle Reward Presentation V0 | `✅ DONE` | Queue ordonnée et overlay décisionnel transactionnel, `c410ac59c` |
| FG-049 | Capture Formula V0 | `✅ DONE` | Formule HP/ball/status à RNG injecté, `ae187f67b` |
| FG-050 | Generic Battle Item Handling V0 | `⬜ TODO` | — |
| FG-051 | Trainer Rewards / Money / Badges V0 | `✅ DONE` | Récompenses différées, idempotence trainer et messages, `f07362f0b` + `c410ac59c` |
| FG-052 | Switch/Faint Replacement UX Hardening | `⬜ TODO` | — |
| FG-053 | Battle Parity Target Document | `⬜ TODO` | — |

## FG-040 — Battle Persistence Contract V0

**Type :** audit/design.  
**But :** définir ce qui doit revenir du combat vers `GameState`.

### DoD

```md
- [x] Contrat listant HP, PP, status, held item, exp, level, moves, evolution triggers.
- [x] Mapping battle lineup -> party slots documenté.
- [x] Non-objectifs clairement listés.
- [x] Contrat gelé avant les commits moteur suivants.
```

## FG-041 — PP Write-back V0

**But :** persister les PP courants après combat.

### DoD

```md
- [x] Battle final state expose les PP restants par combatant/move.
- [x] Runtime write-back les réécrit sur le bon slot party.
- [x] Tests switch + plusieurs membres engagés.
- [x] Tests anciens setups compatibles.
```

## FG-042 — Major Status Write-back V0

**But :** persister poison/paralysie/brûlure/sommeil/gel si le MVP les utilise.

### DoD

```md
- [x] Status battle -> status overworld défini.
- [x] Faint/currentHp cohérent.
- [x] Guérison hors combat disponible via les opérations party/bag existantes.
- [x] Tests pour burn/poison/paralysis/sleep et les autres statuts majeurs supportés.
```

## FG-043 — Battle Reward Model V0

**But :** modéliser les récompenses sans les appliquer encore.

### DoD

```md
- [x] `BattleReward` ou équivalent : money, exp chunks, items, badges/flags optionnels.
- [x] Distinction wild/trainer.
- [x] Pas d’UI dans le lot de modèle.
- [x] Tests de construction/validation.
```

## FG-044 — XP Distribution V0

**But :** donner de l’XP aux Pokémon éligibles.

### DoD

```md
- [x] Règle MVP documentée : participants réels, sans Exp Share implicite.
- [x] XP calculée depuis base exp / level adversaire via catalogues stricts.
- [x] XP ajoutée aux bons slots.
- [x] Tests wild/trainer, switch et participant K.O.
```

## FG-045 — Level-up Apply V0

**But :** appliquer les niveaux gagnés et recalculer les stats.

### DoD

```md
- [x] Level cap documenté.
- [x] Recalcul stats minimal honnête.
- [x] PV après level-up cohérents.
- [x] Tests multi-level.
```

## FG-046 — Learn Move on Level-up V0

**But :** apprendre une attaque lors du level-up.

### DoD

```md
- [x] Learnset consulté.
- [x] Si moins de 4 moves : ajout automatique.
- [x] Si 4 moves : décision réelle de remplacement ou refus.
- [x] Tests move appris / move ignoré / remplacement.
```

## FG-047 — Evolution Check V0

**But :** déclencher les évolutions simples.

### Scope MVP recommandé

```text
- évolution par niveau ;
- évolution par item si Phase 4 prête ;
- pas de breeding/trade/time complexe au début.
```

### DoD

```md
- [x] Évolution par niveau fonctionnelle.
- [x] Évolution peut être acceptée ou refusée dans l’overlay post-combat.
- [x] Form/species/moves/stats mis à jour proprement.
- [x] Tests évolue / n’évolue pas / franchissement multi-level.
```

## FG-048 — Post-battle Reward Presentation V0

**But :** présenter XP, level-up, moves, argent, capture destination.

### DoD

```md
- [x] Timeline ou queue de messages post-battle.
- [x] Messages ordonnés : victoire, XP, level-up, move, évolution, argent/items.
- [x] Aucun reward silencieux critique.
```

## FG-049 — Capture Formula V0

**But :** remplacer la capture immédiate par une formule MVP.

### DoD

```md
- [x] Formule documentée.
- [x] Prend en compte HP cible, ball rate et statut.
- [x] RNG injecté/testable.
- [x] Tests déterministes avec RNG seed/fake.
```

## FG-050 — Generic Battle Item Handling V0

**But :** utiliser des objets de battle via registry plutôt que cas isolés.

### DoD

```md
- [ ] Registry d’effets battle item.
- [ ] Potion, status cure, revive si supportés.
- [ ] Poké Ball reste cohérente avec capture formula.
- [ ] Consommation item unique et testée.
```

## FG-051 — Trainer Rewards / Money / Badges V0

**But :** appliquer argent, badges et flags à la victoire trainer.

### DoD

```md
- [x] Money reward depuis le trainer authored.
- [x] Badge grant optionnel dans le contrat de récompense.
- [x] Field ability unlock optionnel via badge/flag.
- [x] Trainer defeated reste idempotent.
- [x] Tests victoire / défaite / fuite-capture et non-réapplication des récompenses.
```

## FG-052 — Switch/Faint Replacement UX Hardening

**But :** rendre les remplacements après K.O. jouables.

### DoD

```md
- [ ] Quand le Pokémon actif est K.O., le joueur choisit un remplaçant si possible.
- [ ] Si aucun Pokémon utilisable : défaite propre.
- [ ] Mapping party slots reste honnête.
- [ ] Tests battle + runtime overlay.
```

## FG-053 — Battle Parity Target Document

**Type :** décision produit.  
**But :** arrêter de viser “tout Pokémon” sans cible.

### DoD

```md
- [ ] Génération cible MVP choisie ou profil “modern sans gimmicks”.
- [ ] Moves/abilities/items indispensables listés.
- [ ] Gimmicks exclus listés.
- [ ] Coverage gate définie.
- [ ] Prochain lot battle coverage proposé.
```

---

# Phase 4 — Bag, items, économie, soins

Objectif : rendre l’inventaire utile hors combat.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-060 | Item Use Effect Registry V0 | `✅ DONE` | Registry pur HP/statut/revive/PP/key item/Ball et erreurs typées ; lot 3.2 |
| FG-061 | Overworld Bag Menu V0 | `✅ DONE` | Catégories, quantités, utilisabilité et action joueur testées ; lot 3.3 |
| FG-062 | Medicine Outside Battle V0 | `✅ DONE` | Picker item/cible, consommation exacte et transaction sauvegardée ; lots 3.2–3.5 |
| FG-063 | Status Cure / Revive V0 | `✅ DONE` | Antidote, réveil, anti-para, burn/ice/full heal et revive testés ; lot 3.2 |
| FG-064 | Key Item Gates V0 | `⬜ TODO` | — |
| FG-065 | Repel V0 | `⏸ DEFERRED` | Hors MVP signé le 2026-07-22. |
| FG-066 | Poké Ball Families V0 | `⏸ DEFERRED` | Familles complètes hors MVP ; une Poké Ball minimale reste requise. |
| FG-067 | Item Pickup Event V0 | `⬜ TODO` | — |
| FG-068 | Hidden Item Event V0 | `⬜ TODO` | — |
| FG-069 | Shop Model V0 | `✅ DONE` | Shops persistants, prix/stock et validation catalogue ; lot 3.1, Core 4381/4381 |
| FG-070 | Shop Runtime V0 | `✅ DONE` | Prix/stock/argent/quantité, UI et transaction sauvegardée ; lots 3.2–3.5 |
| FG-071 | Heal Center Flow V0 | `🟡 PARTIAL` | Soin complet menu + sauvegarde livré ; commande Scene `HealParty` encore absente |
| FG-072 | Held Item Operations V0 | `⬜ TODO` | — |
| FG-073 | TM/HM Item Support V0 | `⬜ TODO` | — |
| FG-074 | Shop State Model & Compatibility V0 | `✅ DONE` | Modèle versionné, compatibilité catalogue statique et round-trip JSON ; `22797f4b0` |
| FG-075 | Shop State Resolver & Stock V0 | `✅ DONE` | Résolution prioritaire pure, contexte de progression et stock isolé par état ; `c46dfcf4d` |
| FG-076 | Dynamic Shop Runtime V0 | `✅ DONE` | Ouverture sur profil résolu, revalidation transactionnelle et fermeture authored ; `f59770e8f` |
| FG-077 | Dynamic Shop No-Code Builder V0 | `✅ DONE` | Builder quatre zones, catalogue, conditions guidées et inspecteur ; `4a766eb97` |
| FG-078 | Shop State Validator & Simulator V0 | `✅ DONE` | Diagnostics, simulation d'états et prévention des configurations ambiguës ; `c81d8d04c` |
| FG-079 | Selbrume Dynamic Shop Golden Slice V0 | `✅ DONE` | Quatre profils Selbrume, achats exacts, fermeture, save/load, vérificateur MVP-16 et QA visuelle ; rapport FG-079 |

## FG-060 — Item Use Effect Registry V0

**But :** centraliser les effets d’objets.

### DoD

```md
- [x] Registry pur testable.
- [x] Effets : heal HP, cure status, revive, key item no-op/trigger, ball metadata.
- [x] Erreurs : item inconnu, mauvaise cible, quantité insuffisante.
- [x] Pas d’UI.
```

## FG-061 — Overworld Bag Menu V0

**But :** ouvrir le sac depuis le menu pause.

### DoD

```md
- [x] Catégories affichées.
- [x] Quantités affichées.
- [x] Action utiliser disponible ; jeter n'est pas retenu dans le MVP.
- [x] Items non utilisables indiqués clairement.
```

## FG-062 — Medicine Outside Battle V0

**But :** utiliser Potion/Super Potion/etc. hors combat.

### DoD

```md
- [x] Sélection item -> sélection Pokémon -> application.
- [x] Ne consomme pas si aucun effet.
- [x] Consomme exactement si effet appliqué.
- [x] Tests full HP, fainted, normal heal.
```

## FG-063 — Status Cure / Revive V0

**But :** antidote, réveil, anti-para, full heal, revive.

### DoD

```md
- [x] Cure status cible correcte.
- [x] Revive uniquement K.O.
- [x] Full heal retenu et testé.
- [x] Tests par status.
```

## FG-064 — Key Item Gates V0

**But :** gérer les objets clés qui débloquent des actions.

### DoD

```md
- [ ] Key items représentés dans bag.
- [ ] Conditions scripts peuvent vérifier présence.
- [ ] Pas de consommation par défaut.
```

## FG-065 — Repel V0

**But :** réduire/bloquer rencontres pendant N pas.

### DoD

```md
- [ ] État repel dans GameState/progression.
- [ ] Décrément au déplacement.
- [ ] Encounter evaluator respecte Repel.
- [ ] Message fin de Repel.
```

## FG-066 — Poké Ball Families V0

**But :** gérer plusieurs balls avec rates différents.

### DoD

```md
- [ ] Ball metadata utilisée par capture formula.
- [ ] Poké Ball, Great Ball, Ultra Ball minimum.
- [ ] Tests consommation et rates.
```

## FG-067 — Item Pickup Event V0

**But :** ramasser un objet visible.

### DoD

```md
- [ ] Commande ajoute item au bag.
- [ ] Event consommé après pickup.
- [ ] Objet disparaît ou devient inactif.
- [ ] Tests save/reload : pas de duplication.
```

## FG-068 — Hidden Item Event V0

**But :** ramasser un objet invisible/inspectable.

### DoD

```md
- [ ] Déclenchement via action/interact.
- [ ] Message dédié.
- [ ] Event consommé.
- [ ] Option future Itemfinder non requise.
```

## FG-069 — Shop Model V0

**But :** modéliser une boutique.

### DoD

```md
- [x] Shop id/name/items.
- [x] Prix authored et stock optionnel validés.
- [x] Validation item exists quand le catalogue est fourni.
- [x] Pas d’UI.
```

## FG-070 — Shop Runtime V0

**But :** acheter/vendre.

### DoD

```md
- [x] Hook shop accessible depuis le menu pause runtime.
- [x] Buy vérifie argent et stock.
- [x] Sell non autorisé par le modèle MVP ; aucun faux parcours exposé.
- [x] Money mutations testées.
```

## FG-071 — Heal Center Flow V0

**But :** soigner la party.

### DoD

```md
- [ ] Commande `HealParty`.
- [x] Restaure HP, PP, status selon règle.
- [ ] Dialogue simple possible.
- [ ] Option définir respawn/heal location si retenue.
```

## FG-072 — Held Item Operations V0

**But :** donner/reprendre des objets tenus.

### DoD

```md
- [ ] Give/take held item depuis party summary ou bag.
- [ ] Bag quantity mise à jour.
- [ ] Held item persiste save/load.
```

## FG-073 — TM/HM Item Support V0

**But :** apprendre moves via objets techniques.

### DoD

```md
- [ ] Vérifie compatibilité Pokémon/move.
- [ ] Gère 4 moves max.
- [ ] HM/key move policy documentée.
- [ ] FieldAbility unlock ne dépend pas naïvement du simple move si badge requis.
```

## FG-074 à FG-079 — Dynamic Shop State Builder V0

**But :** permettre à une boutique de changer intégralement selon l'état du
jeu, sans code ni identifiants de progression parallèles.

### DoD

```md
- [x] Les catalogues statiques historiques restent lisibles et jouables.
- [x] Des profils conditionnels priorisés peuvent changer ouverture, textes,
      catalogue, prix et stock.
- [x] Le runtime résout et revalide le profil actif à chaque transaction.
- [x] Le stock reste isolé par profil et persiste après sauvegarde/chargement.
- [x] Le Narrative Studio fournit un builder no-code, des diagnostics et un
      simulateur de progression.
- [x] Selbrume prouve les états default, after-lysa, lighthouse-alert et
      story-finished dans le parcours joueur.
- [x] La preuve inclut achats, argent, inventaire, stock, fermeture authored,
      save/load et capture réelle du Shop Builder.
```

**Limite de clôture :** les échecs globaux historiques du validateur narratif
Selbrume et les doublons de source Lysa restent suivis séparément ; ils ne sont
pas introduits par le modèle ou le runtime de boutique dynamique.

---

# Phase 5 — Event Command Catalog no-code

Objectif : permettre aux créateurs de faire les événements Pokémon classiques sans script brut.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-080 | Event Command Model V0 | `⬜ TODO` | — |
| FG-081 | Condition Builder No-code V0 | `⬜ TODO` | — |
| FG-082 | Runtime Command Executor V0 | `🟡 PARTIAL` | Parité exhaustive des 18 commandes publiables prouvée ; promotion bloquée par la suite Runtime globale déjà rouge sur fixtures progression |
| FG-083 | Give/Take Item Commands V0 | `🟡 PARTIAL` | `giveItem(poke-ball, 5)` authoré dans Selbrume, idempotent après save/reload et relié au flux de capture ; promotion globale différée jusqu'à la gate Phase 5 |
| FG-084 | Give Pokémon Command V0 | `⬜ TODO` | — |
| FG-085 | Heal Party Command V0 | `🟡 PARTIAL` | Modèle, JSON, caps runtime, preview, writer idempotent et authoring guidé prouvés ; poste de soins physique authoré dans Selbrume, parcours joueur réel différé à FG-182 |
| FG-086 | Start Trainer Battle Command V0 | `⬜ TODO` | — |
| FG-087 | Start Static Encounter Command V0 | `⬜ TODO` | — |
| FG-088 | Set Flag / Variable Commands V0 | `⬜ TODO` | — |
| FG-089 | Unlock Field Ability / Badge Commands V0 | `🟡 PARTIAL` | AwardBadge/UnlockFieldAbility persistants et authorables ; Badge des Brisants + Surf placés après la victoire contre Lysa, parcours réel différé à FG-182 |
| FG-090 | Warp Command V0 | `🟡 PARTIAL` | Pipeline réel et parité handler/port prouvés ; navette Selbrume authorée vers un warp d'arrivée valide sans remplacer les connexions physiques |
| FG-091 | Open Shop / Open PC Commands V0 | `🟡 PARTIAL` | Controller, routes host et ports prouvés ; comptoir Potion/Antidote et terminal PC possèdent maintenant des sources physiques réutilisables dans Selbrume |
| FG-092 | NPC Move / Presence Commands V0 | `⬜ TODO` | — |
| FG-093 | Action Builder UI V0 | `🟡 PARTIAL` | Catalogue/pickers runtime-aware, références supprimées bloquantes, round-trip et bijection catalogue/runtime testés ; 2 preuves Selbrume globales restent périmées |
| FG-094 | Event Templates V0 | `⬜ TODO` | — |

## FG-080 — Event Command Model V0

**But :** créer un vocabulaire d’actions typées.

### DoD

```md
- [ ] Modèle action typée ou union de commands.
- [ ] JSON/validation si persistant.
- [ ] Aucun interpréteur runtime encore si scope séparé.
- [ ] Commands non supportées explicitement rejetées.
```

## FG-081 — Condition Builder No-code V0

**But :** conditions sans écrire de script brut.

### Conditions MVP

```text
- flag set/unset ;
- variable compare ;
- has item ;
- has Pokémon species ;
- trainer defeated ;
- badge owned ;
- field ability unlocked ;
- story step complete.
```

### DoD

```md
- [ ] Modèle condition réutilise/étend l’existant.
- [ ] UI guidée dans editor.
- [ ] Tests evaluator.
```

## FG-082 — Runtime Command Executor V0

**But :** appliquer les commands au `GameState` et au runtime.

### DoD

```md
- [ ] Executor pur quand possible.
- [ ] Séparation commands state-only vs commands runtime interactive.
- [ ] Erreurs explicites pour command impossible.
- [ ] Tests ordre d’exécution.
```

## FG-083 à FG-092 — Commands spécialisées

### DoD commun

```md
- [ ] Command modèle.
- [ ] Validation editor/projet.
- [ ] Exécution runtime.
- [ ] Tests état avant/après.
- [ ] Message utilisateur si command visible.
- [ ] Idempotence si event consommé.
```

Commands à couvrir :

```text
FG-083 Give/Take Item
FG-084 Give Pokémon
FG-085 Heal Party
FG-086 Start Trainer Battle
FG-087 Start Static Encounter
FG-088 Set Flag / Variable
FG-089 Unlock Field Ability / Badge
FG-090 Warp
FG-091 Open Shop / Open PC
FG-092 NPC Move / Presence
```

## FG-093 — Action Builder UI V0

**But :** créer les commands dans l’éditeur sans JSON.

### DoD

```md
- [ ] Choix du type de command.
- [ ] Formulaire guidé.
- [ ] Pickers pour item/species/trainer/shop/map/flag.
- [ ] Validation inline.
- [ ] Aucun ID manuel obligatoire si picker possible.
```

## FG-094 — Event Templates V0

**But :** presets d’événements classiques.

### Templates MVP

```text
- PNJ dialogue simple ;
- PNJ conditionnel ;
- item ball ;
- hidden item ;
- door/warp ;
- trainer battle ;
- shop clerk ;
- heal center nurse ;
- starter choice ;
- badge reward.
```

### DoD

```md
- [ ] Templates créent des events valides.
- [ ] Le créateur peut les modifier ensuite.
- [ ] Tests snapshot ou validation projet.
```

---

# Phase 6 — Encounters élargis

Objectif : dépasser walk/surf et couvrir les cas Pokémon classiques.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-100 | Encounter Runtime Audit V0 | `⬜ TODO` | — |
| FG-101 | Encounter Conditions V0 | `⬜ TODO` | — |
| FG-102 | Static Encounter Flow V0 | `⬜ TODO` | — |
| FG-103 | Gift Pokémon Flow V0 | `⬜ TODO` | — |
| FG-104 | Fishing Attempt Flow V0 | `⏸ DEFERRED` | Hors MVP signé le 2026-07-22. |
| FG-105 | Headbutt Encounter Flow V0 | `⏸ DEFERRED` | Hors MVP signé le 2026-07-22. |
| FG-106 | Surf Encounter Conditions Hardening V0 | `⬜ TODO` | — |
| FG-107 | Consumed Encounter Write-back V0 | `⬜ TODO` | — |
| FG-108 | Encounter Authoring Validation V0 | `⬜ TODO` | — |

## FG-100 — Encounter Runtime Audit V0

**Type :** audit.  
**But :** cartographier les encounter kinds déjà modélisés vs réellement exécutables.

### DoD

```md
- [ ] Tableau `EncounterKind` : modèle / editor / runtime / tests.
- [ ] Gaps exacts walk/surf/headbutt/rod/gift/special.
- [ ] Aucun code modifié.
```

## FG-101 — Encounter Conditions V0

**But :** conditionner une table ou entrée.

### Conditions possibles MVP

```text
- flag/story step ;
- time/weather si déjà disponible, sinon deferred ;
- repel ;
- required field ability ;
- map/chapter.
```

### DoD

```md
- [ ] Conditions évaluées purement.
- [ ] Tests priorité/poids.
- [ ] Editor validation.
```

## FG-102 — Static Encounter Flow V0

**But :** interaction avec un Pokémon fixe/légendaire/scripté.

### DoD

```md
- [ ] Command démarre wild battle avec espèce/level définis.
- [ ] Event consumed si battu/capturé selon règle.
- [ ] Save/reload ne redonne pas l’encounter.
```

## FG-103 — Gift Pokémon Flow V0

**But :** donner un Pokémon via NPC/event.

### DoD

```md
- [ ] Si party place : ajoute party.
- [ ] Sinon PC si disponible.
- [ ] Sinon refuse ou demande libérer place selon règle.
- [ ] Message destination.
```

## FG-104 — Fishing Attempt Flow V0

**But :** utiliser une canne pour déclencher une rencontre.

### DoD

```md
- [ ] Vérifie cible eau.
- [ ] Vérifie item/canne.
- [ ] Sélectionne table old/good/super rod.
- [ ] RNG testable.
- [ ] Feedback “pas de touche” possible.
```

## FG-105 — Headbutt Encounter Flow V0

**But :** arbre + rencontre.

### DoD

```md
- [ ] Cible arbre/headbutt marker.
- [ ] Vérifie move/ability/unlock si requis.
- [ ] Table headbutt.
- [ ] Feedback sans rencontre.
```

## FG-106 — Surf Encounter Conditions Hardening V0

**But :** renforcer les rencontres en surf avec conditions et repel.

### DoD

```md
- [ ] Mode `MovementMode.surf` pris en compte.
- [ ] Repel respecté.
- [ ] Tables conditionnelles supportées.
- [ ] Tests no encounter hors eau.
```

## FG-107 — Consumed Encounter Write-back V0

**But :** persister les encounters consommés.

### DoD

```md
- [ ] Identifiant stable encounter/event.
- [ ] Mark consumed après capture/battle selon policy.
- [ ] Save/load prouvé.
```

## FG-108 — Encounter Authoring Validation V0

**But :** éviter les tables cassées.

### DoD

```md
- [ ] Espèce existe.
- [ ] Levels valides.
- [ ] Poids valides.
- [ ] Table référencée par zone existe.
- [ ] Conditions référencent flags/vars valides si possible.
```

---

# Phase 7 — Field moves / environmental gates

Objectif : rendre la progression map réellement Pokémon-like.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-120 | Field Move Action Base V0 | `🟡 PARTIAL` | Zone `movement/surf` authorée dans le Passage des Dames ; preuve de traversée `PlayableMapGame` différée à FG-182 |
| FG-121 | Cut Obstacle V0 | `⏸ DEFERRED` | Hors MVP ; Surf est le seul field gate signé. |
| FG-122 | Strength Boulder V0 | `⏸ DEFERRED` | Hors MVP ; Surf est le seul field gate signé. |
| FG-123 | Rock Smash V0 | `⏸ DEFERRED` | Hors MVP ; Surf est le seul field gate signé. |
| FG-124 | Flash / Dark Zone V0 | `⏸ DEFERRED` | Hors MVP ; Surf est le seul field gate signé. |
| FG-125 | Fly / Fast Travel V0 | `⏸ DEFERRED` | Hors MVP ; Surf est le seul field gate signé. |
| FG-126 | Waterfall V0 | `⏸ DEFERRED` | Hors MVP ; Surf est le seul field gate signé. |
| FG-127 | Dive V0 | `⏸ DEFERRED` | Hors MVP ; Surf est le seul field gate signé. |
| FG-128 | Field Move Editor Templates V0 | `⏸ DEFERRED` | Hors MVP ; templates avancés différés. |
| FG-129 | Badge/Unlock Gate Integration V0 | `🟡 PARTIAL` | Badge des Brisants lié à Surf et attribué après Lysa ; refus avant unlock et traversée réelle différés à FG-182 |

## FG-120 — Field Move Action Base V0

**But :** généraliser le pattern Surf : évaluation pure → prompt runtime → mutation/action.

### DoD

```md
- [ ] Interface ou modèle d’évaluation field move.
- [ ] Résultats typés : canUse, missingMove, locked, invalidTarget, alreadyActive, etc.
- [ ] Tests purs.
- [ ] Surf peut rester existant mais pattern documenté.
```

## FG-121 — Cut Obstacle V0

### DoD

```md
- [ ] Obstacle Cut authorable.
- [ ] Vérifie move/unlock.
- [ ] Prompt runtime.
- [ ] Obstacle consommé ou état changé.
- [ ] Save/reload garde l’arbre coupé si policy le demande.
```

## FG-122 — Strength Boulder V0

### DoD

```md
- [ ] Boulder entity/obstacle.
- [ ] Vérifie Strength/unlock.
- [ ] Poussée sur grille.
- [ ] Collision mise à jour.
- [ ] Reset policy map reload documentée.
```

## FG-123 — Rock Smash V0

### DoD

```md
- [ ] Rocher destructible.
- [ ] Vérifie Rock Smash/unlock.
- [ ] Peut déclencher encounter optionnel.
- [ ] Consumed/reset policy documentée.
```

## FG-124 — Flash / Dark Zone V0

### DoD

```md
- [ ] Zone sombre marquée gameplay.
- [ ] Flash change état de visibilité ou flag.
- [ ] Pas de focus sur rendu avancé.
- [ ] Mécanique validée même avec rendu minimal.
```

## FG-125 — Fly / Fast Travel V0

### DoD

```md
- [ ] Destinations débloquées.
- [ ] Vérifie badge/field ability.
- [ ] Warp vers map/spawn.
- [ ] Pas utilisable en intérieur si règle retenue.
```

## FG-126 — Waterfall V0

### DoD

```md
- [ ] Cible waterfall authorable.
- [ ] Vérifie move/unlock + mode surf si requis.
- [ ] Change position/map selon target.
```

## FG-127 — Dive V0

### DoD

```md
- [ ] Dive spots authorables.
- [ ] Warp couche/map sous-marine.
- [ ] Return path défini.
```

## FG-128 — Field Move Editor Templates V0

### DoD

```md
- [ ] Templates Cut tree, Strength boulder, Rock Smash rock, Fly destination, etc.
- [ ] Validation inline.
- [ ] Aucun JSON manuel requis.
```

## FG-129 — Badge/Unlock Gate Integration V0

### DoD

```md
- [ ] Field abilities peuvent être débloquées par badge ou flag.
- [ ] Conditions script peuvent vérifier unlock.
- [ ] UI indique pourquoi l’action est bloquée.
```

---

# Phase 8 — Trainers, badges, gyms, histoire jouable

Objectif : faire des trainers et badges de vrais jalons de progression.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-140 | Trainer Defeated Policy V0 | `⬜ TODO` | — |
| FG-141 | Post-battle Dialogue Hook V0 | `⬜ TODO` | — |
| FG-142 | Trainer Rematch Policy V0 | `⏸ DEFERRED` | Hors MVP ; rematch désactivé par défaut. |
| FG-143 | Badge Grant Flow V0 | `⬜ TODO` | — |
| FG-144 | Gym Flow Template V0 | `⬜ TODO` | — |
| FG-145 | Rival / Follow-up Event Template V0 | `⬜ TODO` | — |
| FG-146 | Story Progression Validator V0 | `⬜ TODO` | — |
| FG-147 | Scenario Completion Report V0 | `⬜ TODO` | — |

## FG-140 — Trainer Defeated Policy V0

### DoD

```md
- [ ] Trainer defeated flag idempotent.
- [ ] Trainer ne relance pas battle si battu, sauf rematch.
- [ ] Editor expose policy.
```

## FG-141 — Post-battle Dialogue Hook V0

### DoD

```md
- [ ] Dialogue avant combat.
- [ ] Dialogue après victoire joueur.
- [ ] Dialogue si déjà battu.
- [ ] Option dialogue défaite joueur si utile.
```

## FG-142 — Trainer Rematch Policy V0

### DoD

```md
- [ ] Rematch disabled par défaut.
- [ ] Rematch conditionnel possible par flag/chapter.
- [ ] Rewards rematch configurables ou bloquées.
```

## FG-143 — Badge Grant Flow V0

### DoD

```md
- [ ] Badge ajouté au trainer profile.
- [ ] Badge peut débloquer field ability.
- [ ] Message runtime.
- [ ] Tests double grant idempotent.
```

## FG-144 — Gym Flow Template V0

### DoD

```md
- [ ] Template leader battle + badge + post dialogue.
- [ ] Validation trainer/badge/ability.
- [ ] Peut être utilisé sans script brut.
```

## FG-145 — Rival / Follow-up Event Template V0

### DoD

```md
- [ ] Template trainer battle scénarisé.
- [ ] Flags/story steps mis à jour.
- [ ] Warp/cutscene optionnel.
```

## FG-146 — Story Progression Validator V0

### DoD

```md
- [ ] Détecte steps impossibles.
- [ ] Détecte flags jamais posés mais requis.
- [ ] Détecte dialogues/actions référencés absents.
```

## FG-147 — Scenario Completion Report V0

### DoD

```md
- [ ] Rapport lisible : début, milestones, fin.
- [ ] Liste blockers.
- [ ] Compatible avec Golden Slice Validator.
```

---

# Phase 9 — Menus runtime et UX joueur

Objectif : rendre les mécaniques accessibles au joueur.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-160 | Pause Menu Complete V0 | `⬜ TODO` | — |
| FG-161 | Runtime Pokédex Read-only V0 | `⬜ TODO` | — |
| FG-162 | Runtime Options V0 | `⬜ TODO` | — |
| FG-163 | Runtime Save Menu V0 | `⬜ TODO` | — |
| FG-164 | Runtime Map / Fast Travel UI V0 | `⬜ TODO` | — |
| FG-165 | Runtime Input Lock Conventions V0 | `✅ DONE` | `reports/gameplay/fg_165_runtime_input_lock_conventions_v0_revalidation_2026-07-26.md` |

## FG-160 — Pause Menu Complete V0

### DoD

```md
- [ ] Party, Bag, Pokédex, Save, Options, Quit/Close reliés aux vrais flows.
- [ ] Navigation clavier/souris propre.
- [ ] Pas de corruption input overworld.
```

## FG-161 — Runtime Pokédex Read-only V0

### DoD

```md
- [ ] Seen/caught affichés.
- [ ] Species details minimal.
- [ ] Mise à jour après rencontre/capture.
```

## FG-162 — Runtime Options V0

### DoD

```md
- [ ] Options minimales : texte speed, volume si dispo, controls si dispo.
- [ ] Persistance options.
```

## FG-163 — Runtime Save Menu V0

### DoD

```md
- [ ] Save depuis pause.
- [ ] Confirmation.
- [ ] Erreur disque affichée proprement.
- [ ] Test ou smoke selon architecture.
```

## FG-164 — Runtime Map / Fast Travel UI V0

### DoD

```md
- [ ] Affiche destinations connues.
- [ ] Utilisé par Fly si disponible.
- [ ] Ne dépend pas du polish visuel.
```

## FG-165 — Runtime Input Lock Conventions V0

### DoD

```md
- [x] Convention unique pour dialogue/menu/battle/overworld.
- [x] Pas de double input pendant transition.
- [x] Tests ou doc runtime.
```

---

# Phase 10 — Validation “jeu jouable” et Golden Slice

Objectif : prouver qu’un vrai mini-fangame peut être créé et terminé.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Project Gameplay Readiness Report V0 | `✅ DONE` | `reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md` |
| FG-181 | Golden Slice Fangame Fixture V0 | `✅ DONE` | `reports/gameplay/fg_181_golden_slice_fangame_fixture_v0.md` |
| FG-182 | Golden Slice End-to-End Smoke V0 | `✅ DONE` | `reports/gameplay/fg_182_golden_slice_end_to_end_smoke_v0.md` |
| FG-183 | Regression Matrix V0 | `✅ DONE` | `reports/gameplay/fg_183_regression_matrix_v0.md` |
| FG-184 | Roadmap Status Dashboard Generator V0 | `✅ DONE` | `reports/gameplay/fg_184_roadmap_status_dashboard_generator_v0.md` |
| FG-185 | MVP Release Gate V0 | `🟡 PARTIAL` | `reports/gameplay/fg_185_mvp_release_gate_v0.md` — RM-069/RM-070/RM-072 verts ; RM-073 produit avec verdict NO-GO ; RM-071 et walkthrough humain bloquants |

## FG-180 — Project Gameplay Readiness Report V0

**But :** générer un rapport “ton projet est jouable / cassé / incomplet”.

### Diagnostics MVP

```text
- start state absent ;
- starter config absente ;
- no playable party path ;
- encounter table cassée ;
- trainer référence move/species invalide ;
- shop item invalide ;
- event command invalide ;
- required flag jamais posé ;
- field ability unlock impossible ;
- story end unreachable ;
- battle bridge coverage insuffisante.
```

### DoD

```md
- [x] Rapport lisible par créateur.
- [x] Rapport détaillé par agent.
- [x] Sévérités : error/warning/info.
- [x] Tests sur fixture saine et fixture cassée.
```

## FG-181 — Golden Slice Fangame Fixture V0

**But :** construire une mini-aventure de référence.

### Contenu minimal

```text
- 2–3 maps ;
- starter selection ;
- wild grass encounter ;
- capture ;
- PC si party pleine ou scénario test dédié ;
- trainer battle ;
- XP/level-up ;
- shop ;
- heal center ;
- badge/flag ;
- Surf ou Cut unlock ;
- mini-fin histoire.
```

### DoD

```md
- [x] Fixture versionnée.
- [x] Assets minimaux seulement.
- [x] Toutes les données validées.
- [x] Rapport de walkthrough attendu.
```

## FG-182 — Golden Slice End-to-End Smoke V0

**But :** test automatisé ou semi-automatisé du mini-fangame.

### DoD

```md
- [x] Lancement nouvelle partie.
- [x] Starter choisi.
- [x] Rencontre déclenchée.
- [x] Combat terminé.
- [x] Capture effectuée.
- [x] Trainer battu.
- [x] XP/level-up prouvé.
- [x] Shop/heal utilisé.
- [x] Badge/field unlock acquis.
- [x] Save/reload au moins une fois.
- [x] Fin atteinte.
```

## FG-183 — Regression Matrix V0

### DoD

```md
- [x] Liste des tests par package.
- [x] Mapping lots -> tests à relancer.
- [x] Commandes rapides et commandes complètes.
```

## FG-184 — Roadmap Status Dashboard Generator V0

**But :** optionnel mais utile : générer un résumé des statuts depuis ce fichier/rapports.

### DoD

```md
- [x] Script lit les rapports gameplay.
- [x] Produit tableau DONE/PARTIAL/TODO.
- [x] Ne modifie pas le code.
```

## FG-185 — MVP Release Gate V0

**But :** décider objectivement “PokeMap est un outil fangame MVP”.

**État vérifié le 2026-07-27 : `PARTIAL / NO-GO`.** Le golden journey installé,
la matrice monorepo et la réconciliation sont verts (`RM-069`, `RM-070`,
`RM-072`). Le receipt final `RM-073` lie un candidat propre, le projet, le
package inspecté/installé et ces preuves, puis conclut honnêtement `NO-GO` :
Developer ID/notarisation/cold install et walkthrough humain ne sont pas
prouvés (`RM-071`).
Voir `reports/gameplay/fg_185_mvp_release_gate_v0.md`.

### DoD

```md
- [x] Golden Slice passe.
- [x] Project Gameplay Readiness Report sans error.
- [x] Tests package critiques verts.
- [x] Limitations post-MVP listées.
- [x] Utilisateur valide le périmètre.
- [x] Receipt `RM-073` produit avec commit candidat, dirty-state, fingerprint projet, package installé, tests/analyzes/builds et état du walkthrough humain cohérents ; verdict `NO-GO` tant que RM-071 et la recette humaine restent incomplets.
```

---

# Phase 11 — Post-MVP / Deferred

Ces sujets sont importants, mais ne doivent pas bloquer le MVP.

| ID | Sujet | Statut | Déclencheur |
|---|---|---|---|
| FG-200 | Double battles | `⏸ DEFERRED` | Après MVP singles stable |
| FG-201 | Mega/Tera/Z/Dynamax | `⏸ DEFERRED` | Après choix génération cible avancée |
| FG-202 | Daycare/Breeding | `⏸ DEFERRED` | Après PC/party/progression solides |
| FG-203 | Online trade/battle | `⏸ DEFERRED` | Après runtime local complet |
| FG-204 | Contests/minigames | `⏸ DEFERRED` | Après core adventure complète |
| FG-205 | Battle Frontier | `⏸ DEFERRED` | Après battle parity avancée |
| FG-206 | IV/EV/nature advanced UX | `⏸ DEFERRED` | Si le projet vise du compétitif |
| FG-207 | Full Pokédex modern parity | `⏸ DEFERRED` | Après MVP + génération cible claire |

---

## 12. Ordre recommandé des 15 prochains lots

Pour fermer rapidement la boucle joueur, exécuter dans cet ordre :

```text
1.  FG-000 — Fangame Mechanics Readiness Audit V0
2.  FG-010 — Initial GameState Builder V0
3.  FG-011 — New Game Runtime Flow V0
4.  FG-012 — Starter Selection Model V0
5.  FG-013 — Starter Selection Runtime Flow V0
6.  FG-020 — PlayerPokemon Runtime Persistence Audit
7.  FG-022 — PC Box Model V0
8.  FG-023 — PC Storage Operations V0
9.  FG-024 — Capture Destination: Party or Box V0
10. FG-025 — Capture To Box When Party Full V0
11. FG-026 — Runtime Party Menu Read-only V0
12. FG-040 — Battle Persistence Contract V0
13. FG-043 — Battle Reward Model V0
14. FG-044 — XP Distribution V0
15. FG-045 — Level-up Apply V0
```

Pourquoi cet ordre : il commence par rendre la partie lançable, puis ferme la capture/collection, puis seulement ensuite nourrit la progression battle. Faire XP avant PC/capture serait possible, mais moins rentable pour un fangame de collection.

---

## 13. Template de prompt pour exécuter un lot

À copier-coller aux agents IA.

```md
# Mission

Tu travailles dans le repo local :

`/Users/karim/Project/pokemonProject`

Tu dois exécuter uniquement le lot :

`FG-XXX — <Nom du lot>`

# Contexte

Consulte d’abord :

- `AGENTS.md` à la racine ;
- les éventuels `AGENTS.md` plus profonds ;
- `docs/gameplay/fangame_mechanics_roadmap.md` ou `reports/gameplay/fangame_mechanics_roadmap.md` ;
- le rapport du lot précédent si disponible.

# Périmètre

Tu dois respecter strictement le scope du lot.

Interdits :

- refactor large hors scope ;
- changement visuel non demandé ;
- modification Surface/Shadow/Environment hors besoin mécanique explicite ;
- modification de fichiers générés sans nécessité ;
- ajout de cache/build/.dart_tool ;
- affirmation de réussite sans test.

# Livrables

- Code minimal si le lot est un lot d’implémentation.
- Tests ciblés.
- Rapport : `reports/gameplay/fg_xxx_<slug>.md`.
- Mise à jour du statut de la roadmap si demandé explicitement.

# Vérification attendue

Exécute au minimum :

```bash
git status --short --untracked-files=all
```

Puis les tests/analyzes adaptés aux packages touchés.

# Rapport final obligatoire

Inclure :

- résumé ;
- fichiers créés/modifiés/supprimés ;
- inventaire complet incluant untracked ;
- commandes exécutées ;
- résultats exacts ;
- limites ;
- risques ;
- prochain lot recommandé ;
- git status final.
```

---

## 14. Critères de victoire globaux

Les **19 critères produit de §2.2 sont la vérité MVP**. La fermeture exige les
lots exacts et le test d'acceptation reliés ci-dessous ; elle n'autorise jamais
une promotion en bloc. Chaque lot conserve son DoD et son Evidence Pack propre.

| # | Critère produit | Lots exacts requis | Test d'acceptation de fermeture |
|---:|---|---|---|
| MVP-01 | Créer une nouvelle partie | FG-010, FG-011, FG-016, FG-180, FG-182 | `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart` |
| MVP-02 | Choisir un starter | FG-012, FG-013, FG-180, FG-182 | `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart` |
| MVP-03 | Explorer 2–3 maps connectées | FG-180, FG-181, FG-182 | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` |
| MVP-04 | Parler à des PNJ | FG-080, FG-082, FG-092, FG-093, FG-180, FG-182 | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` |
| MVP-05 | Avoir des dialogues conditionnels | FG-081, FG-082, FG-088, FG-093, FG-180, FG-182 | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` |
| MVP-06 | Déclencher des cutscenes simples | FG-082, FG-092, FG-093, FG-180, FG-182 | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` |
| MVP-07 | Faire des rencontres sauvages en herbe | FG-180, FG-182 | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` |
| MVP-08 | Capturer des Pokémon | FG-049, FG-083, FG-180, FG-182 | `packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart` |
| MVP-09 | Envoyer automatiquement au PC si la party est pleine | FG-022, FG-023, FG-024, FG-025, FG-029, FG-030, FG-180, FG-182 | `packages/map_gameplay/test/player_storage_operations_test.dart` (planifié Phase 3) |
| MVP-10 | Combattre des trainers | FG-086, FG-140, FG-141, FG-180, FG-182 | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` |
| MVP-11 | Gagner XP + argent | FG-020, FG-021, FG-040, FG-043, FG-044, FG-048, FG-051, FG-180, FG-182 | `packages/map_gameplay/test/battle_progression_service_test.dart` (planifié Phase 2) |
| MVP-12 | Level-up | FG-020, FG-021, FG-040, FG-044, FG-045, FG-047, FG-048, FG-180, FG-182 | `packages/map_gameplay/test/battle_progression_service_test.dart` (planifié Phase 2) |
| MVP-13 | Apprendre une attaque | FG-020, FG-021, FG-040, FG-041, FG-046, FG-048, FG-180, FG-182 | `packages/map_gameplay/test/battle_move_learning_test.dart` (planifié Phase 2) |
| MVP-14 | Obtenir un badge ou flag | FG-051, FG-089, FG-143, FG-180, FG-182 | `packages/map_core/test/badge_definition_test.dart` (planifié Phase 3) |
| MVP-15 | Débloquer Surf ou Cut | FG-089, FG-120, FG-129, FG-180, FG-182 | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` à étendre en Phase 5 : refus avant unlock puis traversée Surf |
| MVP-16 | Utiliser un shop | FG-060, FG-069, FG-070, FG-082, FG-091, FG-093, FG-180, FG-182 | `examples/playable_runtime_host/test/in_game_shop_page_test.dart` (planifié Phase 3) |
| MVP-17 | Se soigner dans un centre Pokémon | FG-060, FG-062, FG-063, FG-071, FG-085, FG-093, FG-180, FG-182 | `examples/playable_runtime_host/test/in_game_heal_flow_test.dart` (planifié Phase 3) |
| MVP-18 | Sauvegarder / charger proprement | FG-014, FG-163, FG-180, FG-182, FG-183, FG-185 | `packages/map_runtime/test/playable_map_game_save_load_transaction_test.dart` |
| MVP-19 | Finir une mini-histoire | FG-080, FG-081, FG-082, FG-088, FG-092, FG-093, FG-140, FG-141, FG-146, FG-147, FG-180, FG-181, FG-182, FG-183, FG-185 | `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` |

Exclusions signées : FG-065, FG-066, FG-104, FG-105, FG-121, FG-122,
FG-123, FG-124, FG-125, FG-126, FG-127, FG-128 et FG-142 restent
`⏸ DEFERRED`, jamais `DONE` pour fermer le MVP. FG-066 n'exclut pas la Poké
Ball minimale requise par MVP-08. Surf est le seul field gate requis par MVP-15.

Le GO final exige aussi la gate Phase 6 : même `releaseCandidateCommit`, même
tree hash projet, même package, receipt automatisé et walkthrough humain.

---

## 15. Notes de prudence

- Ne pas confondre “modèle présent” et “mécanique jouable”.
- Ne pas confondre “éditeur sait créer la donnée” et “runtime sait l’exécuter”.
- Ne pas confondre “battle engine sait résoudre un cas” et “GameState persiste correctement le résultat”.
- Ne pas viser toutes les générations Pokémon avant d’avoir une aventure de 30 minutes terminable.
- Ne pas cacher la logique de progression dans l’UI ou dans Flame.
- Ne pas laisser les agents écrire “validé” sans commandes exactes.

Le cap est simple : **un joueur doit pouvoir commencer, progresser, capturer, se soigner, gagner, sauvegarder, recharger et terminer une petite histoire**. Tout le reste est du bonus tant que cette phrase n’est pas vraie.
