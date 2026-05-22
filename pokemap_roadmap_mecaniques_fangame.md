# PokeMap — Roadmap mécanique fangame Pokémon-like

**Version :** 2026-05-22  
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
| Post-battle write-back | PV des Pokémon engagés, trainer defeated, capture minimale, consommation Poké Ball, ajout à party | `🟡 PARTIAL` |
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
| 1 | Party + PC + Bag runtime | La boucle collection/soin/capture reste cassée sans ça | `⬜ TODO` |
| 2 | XP + level-up + évolution | Les combats ne font pas progresser les Pokémon | `⬜ TODO` |
| 3 | Rewards combat + argent + badges | Les trainers ne structurent pas encore l’aventure | `⬜ TODO` |
| 4 | Event command catalog | Sans actions no-code, l’éditeur reste trop technique | `⬜ TODO` |
| 5 | Field moves hors Surf | Sans gates environnementaux, la progression map est plate | `⬜ TODO` |
| 6 | Shops / heal center / pickups | Sans économie et recovery, le jeu ne vit pas | `⬜ TODO` |
| 7 | Battle write-back complet | PP/status/held items doivent survivre au combat | `⬜ TODO` |
| 8 | Encounter types élargis | Statics, gifts, fishing, headbutt donnent la vraie saveur Pokémon | `⬜ TODO` |
| 9 | Runtime menus | Pause, party, bag, Pokédex, options sont indispensables | `⬜ TODO` |
| 10 | Validation jeu jouable | Le créateur doit savoir si son projet est cassé avant le runtime | `⬜ TODO` |

---

## 4. Roadmap synthétique

| Phase | Lots | Objectif | Dépendance | Statut |
|---|---:|---|---|---|
| Phase 0 | FG-000 → FG-009 | Audit et contrats de suivi | Aucun | `⬜ TODO` |
| Phase 1 | FG-010 → FG-019 | New Game, starter, save/load, pause shell | Phase 0 | `⬜ TODO` |
| Phase 2 | FG-020 → FG-039 | Party, PC, capture crédible | Phase 1 | `⬜ TODO` |
| Phase 3 | FG-040 → FG-059 | Battle persistence, rewards, XP, level-up, évolutions | Phase 2 | `⬜ TODO` |
| Phase 4 | FG-060 → FG-079 | Bag, items, shops, centre Pokémon | Phase 2 | `⬜ TODO` |
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
| FG-014 | Save/Load Transaction Hardening V0 | `⬜ TODO` | — |
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
- [ ] Audit du flux load actuel.
- [ ] Chargement préparé avant mutation destructive.
- [ ] Échec de load = état runtime précédent conservé ou erreur propre.
- [ ] Tests d’échec : map absente, layer invalide, save corrompue.
- [ ] Rapport indiquant les limites restantes.
```

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
| FG-020 | PlayerPokemon Runtime Persistence Audit | `⬜ TODO` | — |
| FG-021 | PlayerPokemon Persistence Expansion V0 | `⬜ TODO` | — |
| FG-022 | PC Box Model V0 | `⬜ TODO` | — |
| FG-023 | PC Storage Operations V0 | `⬜ TODO` | — |
| FG-024 | Capture Destination: Party or Box V0 | `⬜ TODO` | — |
| FG-025 | Capture To Box When Party Full V0 | `⬜ TODO` | — |
| FG-026 | Runtime Party Menu Read-only V0 | `⬜ TODO` | — |
| FG-027 | Pokémon Summary Runtime V0 | `⬜ TODO` | — |
| FG-028 | Party Reorder / Lead Selection V0 | `⬜ TODO` | — |
| FG-029 | Runtime PC Screen V0 | `⬜ TODO` | — |
| FG-030 | Party/Box Validation V0 | `⬜ TODO` | — |

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
- [ ] Tableau champ par champ : species, level, hp, pp, status, moves, ability, nature, held item, form, shiny, exp, friendship, etc.
- [ ] Statut : persistant / partiel / absent / inventé au fallback.
- [ ] Recommandation de modèle minimal MVP.
- [ ] Aucune modification de code.
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
- [ ] Modèle compatible anciennes saves.
- [ ] JSON/migration si nécessaire.
- [ ] Tests de normalisation.
- [ ] Aucun calcul battle complexe caché dans le modèle.
```

## FG-022 — PC Box Model V0

**But :** créer le stockage PC/Boxes côté save.

### DoD

```md
- [ ] Modèle `PokemonStorage` ou équivalent.
- [ ] Liste de boxes nommées.
- [ ] Slots bornés, par exemple 30 par box.
- [ ] Capacité configurable ou constante documentée.
- [ ] Sérialisation/normalisation.
- [ ] Tests : box vide, ajout, déplacement, limites.
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
- [ ] Opérations pures testées.
- [ ] Erreurs explicites : slot invalide, party pleine, box pleine.
- [ ] Pas de UI.
- [ ] Pas de repo disque.
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
- [ ] Fonction pure de décision.
- [ ] Tests party disponible.
- [ ] Tests party pleine + box disponible.
- [ ] Tests storage full.
- [ ] Le résultat contient destination + message possible.
```

## FG-025 — Capture To Box When Party Full V0

**But :** intégrer la destination de capture dans le write-back runtime.

### DoD

```md
- [ ] Capture ajoute à la party si place.
- [ ] Capture ajoute au PC si party pleine.
- [ ] Poké Ball consommée exactement une fois.
- [ ] Seen/caught normalisé.
- [ ] Message runtime indique la destination.
- [ ] Tests outcome apply : party, box, storage full.
```

## FG-026 — Runtime Party Menu Read-only V0

**But :** voir son équipe en runtime.

### DoD

```md
- [ ] Menu accessible depuis pause.
- [ ] Affiche 1 à 6 Pokémon.
- [ ] Affiche nom/espèce, niveau, PV, statut, moves résumés.
- [ ] Aucun changement d’ordre encore si FG-028 non fait.
- [ ] Cas party vide géré proprement.
```

## FG-027 — Pokémon Summary Runtime V0

**But :** écran détail Pokémon.

### DoD

```md
- [ ] Stats visibles.
- [ ] Moves + PP visibles.
- [ ] Nature/ability/held item visibles si modèle disponible.
- [ ] Pas d’édition runtime non prévue.
```

## FG-028 — Party Reorder / Lead Selection V0

**But :** changer le lead et réordonner l’équipe.

### DoD

```md
- [ ] Swap deux slots party.
- [ ] Le premier Pokémon utilisable devient lead battle par défaut.
- [ ] Impossible de créer un état invalide.
- [ ] Tests opérations pures + runtime smoke.
```

## FG-029 — Runtime PC Screen V0

**But :** ouvrir le PC et gérer party/boxes.

### DoD

```md
- [ ] Écran PC minimal accessible via commande/event ou debug hook.
- [ ] Withdraw/deposit/move fonctionnels.
- [ ] Summary accessible.
- [ ] Validation last usable Pokémon si règle retenue.
```

## FG-030 — Party/Box Validation V0

**But :** le validator signale les états de party/storage cassés.

### DoD

```md
- [ ] Diagnostic party > 6.
- [ ] Diagnostic box overflow.
- [ ] Diagnostic Pokémon sans espèce valide.
- [ ] Diagnostic move inconnu si catalogues chargés.
- [ ] Rapport lisible pour agent et utilisateur.
```

---

# Phase 3 — Battle persistence, rewards, XP, progression

Objectif : les combats changent réellement la progression joueur/Pokémon.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-040 | Battle Persistence Contract V0 | `⬜ TODO` | — |
| FG-041 | PP Write-back V0 | `⬜ TODO` | — |
| FG-042 | Major Status Write-back V0 | `⬜ TODO` | — |
| FG-043 | Battle Reward Model V0 | `⬜ TODO` | — |
| FG-044 | XP Distribution V0 | `⬜ TODO` | — |
| FG-045 | Level-up Apply V0 | `⬜ TODO` | — |
| FG-046 | Learn Move on Level-up V0 | `⬜ TODO` | — |
| FG-047 | Evolution Check V0 | `⬜ TODO` | — |
| FG-048 | Post-battle Reward Presentation V0 | `⬜ TODO` | — |
| FG-049 | Capture Formula V0 | `⬜ TODO` | — |
| FG-050 | Generic Battle Item Handling V0 | `⬜ TODO` | — |
| FG-051 | Trainer Rewards / Money / Badges V0 | `⬜ TODO` | — |
| FG-052 | Switch/Faint Replacement UX Hardening | `⬜ TODO` | — |
| FG-053 | Battle Parity Target Document | `⬜ TODO` | — |

## FG-040 — Battle Persistence Contract V0

**Type :** audit/design.  
**But :** définir ce qui doit revenir du combat vers `GameState`.

### DoD

```md
- [ ] Contrat listant HP, PP, status, held item, exp, level, moves, evolution triggers.
- [ ] Mapping battle lineup -> party slots documenté.
- [ ] Non-objectifs clairement listés.
- [ ] Pas de modification moteur avant contrat.
```

## FG-041 — PP Write-back V0

**But :** persister les PP courants après combat.

### DoD

```md
- [ ] Battle final state expose les PP restants par combatant/move.
- [ ] Runtime write-back les réécrit sur le bon slot party.
- [ ] Tests switch + plusieurs membres engagés.
- [ ] Tests anciens setups compatibles.
```

## FG-042 — Major Status Write-back V0

**But :** persister poison/paralysie/brûlure/sommeil/gel si le MVP les utilise.

### DoD

```md
- [ ] Status battle -> status overworld défini.
- [ ] Faint/currentHp cohérent.
- [ ] Guérison hors combat possible via Phase 4.
- [ ] Tests pour au moins burn/poison/paralysis/sleep si supportés.
```

## FG-043 — Battle Reward Model V0

**But :** modéliser les récompenses sans les appliquer encore.

### DoD

```md
- [ ] `BattleReward` ou équivalent : money, exp chunks, items, badges/flags optionnels.
- [ ] Distinction wild/trainer.
- [ ] Pas d’UI.
- [ ] Tests de construction/validation.
```

## FG-044 — XP Distribution V0

**But :** donner de l’XP aux Pokémon éligibles.

### DoD

```md
- [ ] Règle MVP documentée : actif seul, participants, ou exp share.
- [ ] XP calculée depuis base exp / level adversaire si catalogues disponibles.
- [ ] XP ajoutée aux bons slots.
- [ ] Tests wild/trainer, switch, fainted participant.
```

## FG-045 — Level-up Apply V0

**But :** appliquer les niveaux gagnés et recalculer les stats.

### DoD

```md
- [ ] Level cap documenté.
- [ ] Recalcul stats minimal honnête.
- [ ] PV après level-up cohérents.
- [ ] Tests multi-level.
```

## FG-046 — Learn Move on Level-up V0

**But :** apprendre une attaque lors du level-up.

### DoD

```md
- [ ] Learnset consulté.
- [ ] Si moins de 4 moves : ajout automatique.
- [ ] Si 4 moves : prompt ou stratégie fallback documentée.
- [ ] Test move appris / move ignoré / remplacement.
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
- [ ] Évolution par niveau fonctionnelle.
- [ ] Évolution peut être refusée/annulée si UX prévue, sinon auto avec décision documentée.
- [ ] Form/species/moves/stats mis à jour proprement.
- [ ] Tests évolue / n’évolue pas / chaîne simple.
```

## FG-048 — Post-battle Reward Presentation V0

**But :** présenter XP, level-up, moves, argent, capture destination.

### DoD

```md
- [ ] Timeline ou queue de messages post-battle.
- [ ] Messages ordonnés : victoire, XP, level-up, move, évolution, argent/items.
- [ ] Aucun reward silencieux critique.
```

## FG-049 — Capture Formula V0

**But :** remplacer la capture immédiate par une formule MVP.

### DoD

```md
- [ ] Formule documentée.
- [ ] Prend en compte HP cible, ball rate, status si disponible.
- [ ] RNG injecté/testable.
- [ ] Tests déterministes avec RNG seed/fake.
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
- [ ] Money reward depuis trainer ou formule.
- [ ] Badge grant optionnel.
- [ ] Field ability unlock optionnel via badge/flag.
- [ ] Trainer defeated reste idempotent.
- [ ] Tests victoire / défaite / rematch policy.
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
| FG-060 | Item Use Effect Registry V0 | `⬜ TODO` | — |
| FG-061 | Overworld Bag Menu V0 | `⬜ TODO` | — |
| FG-062 | Medicine Outside Battle V0 | `⬜ TODO` | — |
| FG-063 | Status Cure / Revive V0 | `⬜ TODO` | — |
| FG-064 | Key Item Gates V0 | `⬜ TODO` | — |
| FG-065 | Repel V0 | `⬜ TODO` | — |
| FG-066 | Poké Ball Families V0 | `⬜ TODO` | — |
| FG-067 | Item Pickup Event V0 | `⬜ TODO` | — |
| FG-068 | Hidden Item Event V0 | `⬜ TODO` | — |
| FG-069 | Shop Model V0 | `⬜ TODO` | — |
| FG-070 | Shop Runtime V0 | `⬜ TODO` | — |
| FG-071 | Heal Center Flow V0 | `⬜ TODO` | — |
| FG-072 | Held Item Operations V0 | `⬜ TODO` | — |
| FG-073 | TM/HM Item Support V0 | `⬜ TODO` | — |

## FG-060 — Item Use Effect Registry V0

**But :** centraliser les effets d’objets.

### DoD

```md
- [ ] Registry pur testable.
- [ ] Effets : heal HP, cure status, revive, key item no-op/trigger, ball metadata.
- [ ] Erreurs : item inconnu, mauvaise cible, quantité insuffisante.
- [ ] Pas d’UI.
```

## FG-061 — Overworld Bag Menu V0

**But :** ouvrir le sac depuis le menu pause.

### DoD

```md
- [ ] Catégories affichées.
- [ ] Quantités affichées.
- [ ] Action utiliser/jeter si retenue.
- [ ] Items non utilisables indiqués clairement.
```

## FG-062 — Medicine Outside Battle V0

**But :** utiliser Potion/Super Potion/etc. hors combat.

### DoD

```md
- [ ] Sélection item -> sélection Pokémon -> application.
- [ ] Ne consomme pas si aucun effet.
- [ ] Consomme exactement si effet appliqué.
- [ ] Tests full HP, fainted, normal heal.
```

## FG-063 — Status Cure / Revive V0

**But :** antidote, réveil, anti-para, full heal, revive.

### DoD

```md
- [ ] Cure status cible correcte.
- [ ] Revive uniquement K.O.
- [ ] Full heal si retenu.
- [ ] Tests par status.
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
- [ ] Shop id/name/items.
- [ ] Prix depuis item catalog ou override.
- [ ] Validation item exists.
- [ ] Pas d’UI.
```

## FG-070 — Shop Runtime V0

**But :** acheter/vendre.

### DoD

```md
- [ ] Open shop command ou hook runtime.
- [ ] Buy vérifie argent et stock.
- [ ] Sell si autorisé.
- [ ] Money mutations testées.
```

## FG-071 — Heal Center Flow V0

**But :** soigner la party.

### DoD

```md
- [ ] Commande `HealParty`.
- [ ] Restaure HP, PP, status selon règle.
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

---

# Phase 5 — Event Command Catalog no-code

Objectif : permettre aux créateurs de faire les événements Pokémon classiques sans script brut.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-080 | Event Command Model V0 | `⬜ TODO` | — |
| FG-081 | Condition Builder No-code V0 | `⬜ TODO` | — |
| FG-082 | Runtime Command Executor V0 | `⬜ TODO` | — |
| FG-083 | Give/Take Item Commands V0 | `⬜ TODO` | — |
| FG-084 | Give Pokémon Command V0 | `⬜ TODO` | — |
| FG-085 | Heal Party Command V0 | `⬜ TODO` | — |
| FG-086 | Start Trainer Battle Command V0 | `⬜ TODO` | — |
| FG-087 | Start Static Encounter Command V0 | `⬜ TODO` | — |
| FG-088 | Set Flag / Variable Commands V0 | `⬜ TODO` | — |
| FG-089 | Unlock Field Ability / Badge Commands V0 | `⬜ TODO` | — |
| FG-090 | Warp Command V0 | `⬜ TODO` | — |
| FG-091 | Open Shop / Open PC Commands V0 | `⬜ TODO` | — |
| FG-092 | NPC Move / Presence Commands V0 | `⬜ TODO` | — |
| FG-093 | Action Builder UI V0 | `⬜ TODO` | — |
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
| FG-104 | Fishing Attempt Flow V0 | `⬜ TODO` | — |
| FG-105 | Headbutt Encounter Flow V0 | `⬜ TODO` | — |
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
| FG-120 | Field Move Action Base V0 | `⬜ TODO` | — |
| FG-121 | Cut Obstacle V0 | `⬜ TODO` | — |
| FG-122 | Strength Boulder V0 | `⬜ TODO` | — |
| FG-123 | Rock Smash V0 | `⬜ TODO` | — |
| FG-124 | Flash / Dark Zone V0 | `⬜ TODO` | — |
| FG-125 | Fly / Fast Travel V0 | `⬜ TODO` | — |
| FG-126 | Waterfall V0 | `⬜ TODO` | — |
| FG-127 | Dive V0 | `⬜ TODO` | — |
| FG-128 | Field Move Editor Templates V0 | `⬜ TODO` | — |
| FG-129 | Badge/Unlock Gate Integration V0 | `⬜ TODO` | — |

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
| FG-142 | Trainer Rematch Policy V0 | `⬜ TODO` | — |
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
| FG-165 | Runtime Input Lock Conventions V0 | `⬜ TODO` | — |

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
- [ ] Convention unique pour dialogue/menu/battle/overworld.
- [ ] Pas de double input pendant transition.
- [ ] Tests ou doc runtime.
```

---

# Phase 10 — Validation “jeu jouable” et Golden Slice

Objectif : prouver qu’un vrai mini-fangame peut être créé et terminé.

| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Project Gameplay Readiness Report V0 | `⬜ TODO` | — |
| FG-181 | Golden Slice Fangame Fixture V0 | `⬜ TODO` | — |
| FG-182 | Golden Slice End-to-End Smoke V0 | `⬜ TODO` | — |
| FG-183 | Regression Matrix V0 | `⬜ TODO` | — |
| FG-184 | Roadmap Status Dashboard Generator V0 | `⬜ TODO` | — |
| FG-185 | MVP Release Gate V0 | `⬜ TODO` | — |

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
- [ ] Rapport lisible par créateur.
- [ ] Rapport détaillé par agent.
- [ ] Sévérités : error/warning/info.
- [ ] Tests sur fixture saine et fixture cassée.
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
- [ ] Fixture versionnée.
- [ ] Assets minimaux seulement.
- [ ] Toutes les données validées.
- [ ] Rapport de walkthrough attendu.
```

## FG-182 — Golden Slice End-to-End Smoke V0

**But :** test automatisé ou semi-automatisé du mini-fangame.

### DoD

```md
- [ ] Lancement nouvelle partie.
- [ ] Starter choisi.
- [ ] Rencontre déclenchée.
- [ ] Combat terminé.
- [ ] Capture effectuée.
- [ ] Trainer battu.
- [ ] XP/level-up prouvé.
- [ ] Shop/heal utilisé.
- [ ] Badge/field unlock acquis.
- [ ] Save/reload au moins une fois.
- [ ] Fin atteinte.
```

## FG-183 — Regression Matrix V0

### DoD

```md
- [ ] Liste des tests par package.
- [ ] Mapping lots -> tests à relancer.
- [ ] Commandes rapides et commandes complètes.
```

## FG-184 — Roadmap Status Dashboard Generator V0

**But :** optionnel mais utile : générer un résumé des statuts depuis ce fichier/rapports.

### DoD

```md
- [ ] Script lit les rapports gameplay.
- [ ] Produit tableau DONE/PARTIAL/TODO.
- [ ] Ne modifie pas le code.
```

## FG-185 — MVP Release Gate V0

**But :** décider objectivement “PokeMap est un outil fangame MVP”.

### DoD

```md
- [ ] Golden Slice passe.
- [ ] Project Gameplay Readiness Report sans error.
- [ ] Tests package critiques verts.
- [ ] Limitations post-MVP listées.
- [ ] Utilisateur valide le périmètre.
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

PokeMap pourra être considéré comme **vrai outil de fangame Pokémon-like MVP** quand :

```md
- [ ] FG-010 à FG-016 sont DONE.
- [ ] FG-020 à FG-030 sont DONE.
- [ ] FG-040 à FG-049 sont DONE au minimum pour HP/PP/status/XP/level-up/capture formula.
- [ ] FG-060 à FG-071 sont DONE pour bag/shop/heal.
- [ ] FG-080 à FG-094 sont DONE pour events no-code essentiels.
- [ ] FG-100 à FG-108 sont DONE pour encounters essentiels.
- [ ] FG-120, FG-121 et FG-129 sont DONE au minimum pour un field gate type Cut ou Surf unlock.
- [ ] FG-140, FG-141, FG-143 et FG-144 sont DONE pour trainers/badges.
- [ ] FG-160 et FG-163 sont DONE pour pause/save.
- [ ] FG-180 à FG-185 sont DONE.
- [ ] Golden Slice jouable de bout en bout.
```

---

## 15. Notes de prudence

- Ne pas confondre “modèle présent” et “mécanique jouable”.
- Ne pas confondre “éditeur sait créer la donnée” et “runtime sait l’exécuter”.
- Ne pas confondre “battle engine sait résoudre un cas” et “GameState persiste correctement le résultat”.
- Ne pas viser toutes les générations Pokémon avant d’avoir une aventure de 30 minutes terminable.
- Ne pas cacher la logique de progression dans l’UI ou dans Flame.
- Ne pas laisser les agents écrire “validé” sans commandes exactes.

Le cap est simple : **un joueur doit pouvoir commencer, progresser, capturer, se soigner, gagner, sauvegarder, recharger et terminer une petite histoire**. Tout le reste est du bonus tant que cette phrase n’est pas vraie.
