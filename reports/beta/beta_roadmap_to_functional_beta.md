# PokeMap Roadmap To Functional Beta

## 1. Roadmap principles

Objectif: atteindre une beta fonctionnelle PokeMap centree sur Selbrume, avec
preuve end-to-end et sans chercher la parite Pokemon complete.

Ordre directeur:

1. Rendre vrai le lancement d'un projet cree par PokeMap.
2. Fermer New Game et etat initial.
3. Fermer la boucle party/bag/heal minimale.
4. Fermer wild encounter, battle, capture, trainer, rewards et XP minimale.
5. Durcir narrative/save/load/validator.
6. Ajouter audio minimal.
7. Assembler Selbrume seulement quand les briques beta sont testables.

Lots existants de la roadmap mecanique concernes:

```text
FG-011 New Game Runtime Flow V0
FG-012 Starter Selection Model V0
FG-013 Starter Selection Runtime Flow V0
FG-014 Save/Load Transaction Hardening V0
FG-016 Golden Runtime Boot Smoke V0
FG-021 PlayerPokemon Persistence Expansion V0
FG-022 PC Box Model V0
FG-024 Capture Destination: Party or Box V0
FG-025 Capture To Box When Party Full V0
FG-026 Runtime Party Menu Read-only V0
FG-040 Battle Persistence Contract V0
FG-041 PP Write-back V0
FG-042 Major Status Write-back V0
FG-043 Battle Reward Model V0
FG-044 XP Distribution V0
FG-045 Level-up Apply V0
FG-048 Post-battle Reward Presentation V0
FG-049 Capture Formula V0
FG-051 Trainer Rewards / Money / Badges V0
FG-060 Item Use Effect Registry V0
FG-061 Overworld Bag Menu V0
FG-062 Medicine Outside Battle V0
FG-063 Status Cure / Revive V0
FG-067 Item Pickup Event V0
FG-071 Heal Center Flow V0
FG-100 Encounter Runtime Audit V0
FG-108 Encounter Authoring Validation V0
FG-140 Trainer Defeated Policy V0
FG-141 Post-battle Dialogue Hook V0
FG-146 Story Progression Validator V0
FG-163 Runtime Save Menu V0
FG-181 Golden Slice Fangame Fixture V0
FG-182 Golden Slice End-to-End Smoke V0
```

Roadmap proposee: 26 lots, dont environ 18 bloquants beta. Les lots audio n'ont
pas de FG evident trouve dans la roadmap actuelle; ils sont ajoutes car la
checklist beta les demande.

## 2. Phase 0 - Truth alignment / audit closure

### BETA-00 - Reconcile roadmap statuses

- Objectif: aligner les statuts roadmap avec le code reel.
- Pourquoi: l'audit a trouve des briques avancees mais non beta-ready; certains
  anciens rapports peuvent donner une impression trop optimiste.
- Scope exact: relire FG-011 a FG-182 utiles, noter `DONE/PARTIAL/TODO/BLOCKED`
  avec preuves fraiches.
- Non-objectifs: modifier le code ou fermer des lots.
- Packages/fichiers: `pokemap_roadmap_mecaniques_fangame.md`, `reports/roadmap`.
- Criteres d'acceptation: rapport court listant chaque FG pertinent, preuve,
  statut propose et contradiction eventuelle.
- Tests attendus: aucun test code; `git diff --check` sur le rapport.
- Risques: passer du temps a corriger l'histoire plutot que la beta.
- Dependances: audit present.
- Statut de blocage: bloquant organisationnel avant gros travaux.

### BETA-01 - Define beta acceptance smoke

- Objectif: transformer la checklist en test plan executable.
- Pourquoi: aucun test ne prouve le flux complet editeur -> disque -> runtime.
- Scope exact: definir fixtures minimales, commandes et assertions pour le
  parcours beta.
- Non-objectifs: creer Selbrume final.
- Packages/fichiers: `reports/beta`, futurs tests dans `examples/playable_runtime_host`.
- Criteres d'acceptation: chaque bloc checklist a au moins une preuve attendue
  ou une decision de non-scope.
- Tests attendus: aucun au lot lui-meme; plan de tests produit.
- Risques: sur-specifier avant les decisions produit.
- Dependances: BETA-00.
- Statut de blocage: bloquant pour eviter les regressions d'audit.

## 3. Phase 1 - Runtime project disk loading + New Game

### BETA-02 - Editor-created project disk smoke

- Objectif: prouver qu'un projet cree/sauve par l'editeur peut etre charge par
  le runtime.
- Pourquoi: `loadRuntimeMapBundle` marche sur fixtures, pas sur un flux editeur
  prouve.
- Scope exact: creer une fixture de projet editeur minimal, sauver disque,
  charger via runtime host/test, verifier manifest/map/tilesets/dialogues de base.
- Non-objectifs: combat, Selbrume final, audio.
- Packages/fichiers probables: `packages/map_editor`, `packages/map_runtime`,
  `examples/playable_runtime_host/test`.
- Criteres d'acceptation: test e2e editeur repository -> `project.json` ->
  `loadRuntimeMapBundle` vert.
- Tests attendus: nouveau smoke host ou runtime fixture test.
- Risques: chemins relatifs et assets existants peuvent exposer dette ancienne.
- Dependances: BETA-01.
- Statut de blocage: oui.

### BETA-03 - Playable start map and spawn contract

- Objectif: rendre start map/spawn explicites, valides et non-fallback.
- Pourquoi: le runtime peut fallback `(0,0)` et la beta doit echouer clairement
  si le projet n'est pas jouable.
- Scope exact: contrat manifest ou convention start map, spawn obligatoire,
  diagnostics actionnables.
- Non-objectifs: choix multiple de region ou profiles avances.
- Packages/fichiers probables: `map_core`, `map_gameplay`, `map_runtime`,
  `map_editor`.
- Criteres d'acceptation: projet sans spawn/start valide donne diagnostic;
  projet valide demarre a la bonne position.
- Tests attendus: validator tests, runtime boot tests.
- Risques: migration manifest si nouveau champ.
- Dependances: BETA-02.
- Statut de blocage: oui.

### BETA-04 - Runtime New Game flow V0

- Objectif: lancer une partie neuve depuis un projet disque sans launch save
  preexistante.
- Pourquoi: beta impossible si l'utilisateur doit fournir une save manuelle.
- Scope exact: bouton/flow minimal, creation `GameState`, saveId, map, position,
  facing, metadata.
- Non-objectifs: UI riche, slots multiples, intro cinematics.
- Packages/fichiers probables: `packages/map_gameplay`,
  `packages/map_runtime`, `examples/playable_runtime_host`.
- Criteres d'acceptation: test host New Game cree un GameState coherent et
  l'affiche.
- Tests attendus: `flutter test` host/runtime New Game smoke.
- Risques: conflit avec launch save existante.
- Dependances: BETA-03.
- Statut de blocage: oui.

### BETA-05 - Starter and initial inventory V0

- Objectif: donner un starter et initialiser bag/argent/flags/steps.
- Pourquoi: `createNewGameState` cree un etat vide; la checklist beta demande
  starter et etat initial.
- Scope exact: config minimale manifest ou scenario New Game, starter unique ou
  choix simple, bag initial, argent initial, flags/steps.
- Non-objectifs: choix starter anime, rival dynamic starter, balance fine.
- Packages/fichiers probables: `map_core`, `map_gameplay`, `map_runtime`,
  `map_editor`.
- Criteres d'acceptation: New Game produit party non vide, bag initial attendu,
  progression initiale testee.
- Tests attendus: `map_gameplay` mutation tests, runtime New Game smoke,
  save/load roundtrip.
- Risques: schema migration et UX editor.
- Dependances: BETA-04.
- Statut de blocage: oui.

## 4. Phase 2 - Party / Bag / HealParty

### BETA-06 - PlayerPokemon beta persistence contract

- Objectif: figer les champs Pokemon necessaires a la beta.
- Pourquoi: HP existe, mais max HP, PP, XP et status write-back sont incomplets.
- Scope exact: document/implementer le minimum: level, current/max HP, status,
  moves, PP si retenu, XP si retenu.
- Non-objectifs: EV/IV complet, friendship, met data, formes complexes.
- Packages/fichiers probables: `map_core`, `map_runtime`, `map_battle`.
- Criteres d'acceptation: sauvegarde/reload preserve les champs beta.
- Tests attendus: `game_state_persistence_test.dart`,
  `file_game_save_repository_test.dart`, battle write-back tests.
- Risques: migration de saves.
- Dependances: BETA-05.
- Statut de blocage: oui.

### BETA-07 - Party menu beta read-only plus KO clarity

- Objectif: rendre l'equipe lisible en runtime: PV, niveau, statut, KO.
- Pourquoi: party existe mais le joueur doit comprendre son etat.
- Scope exact: affichage minimal, navigation, pas de reorder sauf besoin lead.
- Non-objectifs: move details, held item management, PC.
- Packages/fichiers probables: `map_runtime`, `examples/playable_runtime_host`.
- Criteres d'acceptation: test widget/menu verifie affichage party avec KO.
- Tests attendus: host/menu widget tests.
- Risques: dette UI si menu actuel est trop demo.
- Dependances: BETA-06.
- Statut de blocage: oui.

### BETA-08 - Bag menu and medicine outside battle V0

- Objectif: utiliser potion depuis l'overworld.
- Pourquoi: potions existent en combat; la checklist demande bag runtime minimal
  et potion.
- Scope exact: menu bag minimal, item effect registry V0, potion HP restore,
  decrement quantity.
- Non-objectifs: shops, sorting, key items, TMs.
- Packages/fichiers probables: `map_core`, `map_gameplay`, `map_runtime`,
  `map_editor`.
- Criteres d'acceptation: utiliser potion modifie HP/bag et persiste apres save.
- Tests attendus: pure mutation tests, runtime menu tests, save/load test.
- Risques: besoin de max HP.
- Dependances: BETA-06, BETA-07.
- Statut de blocage: oui.

### BETA-09 - HealParty and heal point V0

- Objectif: fournir centre/point de soin beta.
- Pourquoi: bloc 7 entier est manquant.
- Scope exact: `healParty`, clear status, revive KO, restore HP, PP seulement
  si PP est dans le contrat, script action/dialogue hook, feedback simple.
- Non-objectifs: animation/audio riche, infirmiere complete.
- Packages/fichiers probables: `map_gameplay`, `map_runtime`, `map_editor`,
  `map_core`.
- Criteres d'acceptation: interaction point de soin soigne party et save/reload
  preserve l'etat soigne.
- Tests attendus: mutation tests, scenario runtime test, host smoke.
- Risques: status/PP contract pas encore fige.
- Dependances: BETA-06.
- Statut de blocage: oui.

## 5. Phase 3 - Wild encounters + capture

### BETA-10 - Encounter runtime audit closure

- Objectif: fermer la rencontre sauvage beta minimale.
- Pourquoi: zones/tables/runtime existent mais les conditions sont partielles.
- Scope exact: hautes herbes ou zone simple, table valide, roll deterministic en
  test, no encounter diagnostics.
- Non-objectifs: fishing, headbutt, repel, weather/time conditions.
- Packages/fichiers probables: `map_core`, `map_gameplay`, `map_runtime`,
  `map_editor`.
- Criteres d'acceptation: marcher dans une zone lance wild battle en test.
- Tests attendus: gameplay encounter tests, runtime smoke.
- Risques: hasard/flakiness.
- Dependances: BETA-03.
- Statut de blocage: oui.

### BETA-11 - Encounter authoring validation V0

- Objectif: empecher des encounter tables injouables.
- Pourquoi: species/moves/items ne sont pas valides de facon holistique.
- Scope exact: species existant, niveaux valides, moves optionnels valides,
  table referencee par zone, table non vide.
- Non-objectifs: balance, raretes avancees.
- Packages/fichiers probables: `map_core`, `map_editor`.
- Criteres d'acceptation: diagnostics editeur et core pour table invalide.
- Tests attendus: validator tests, editor use case tests.
- Risques: catalog Pokemon incomplet dans certains projets.
- Dependances: BETA-10.
- Statut de blocage: oui.

### BETA-12 - Capture party-or-fallback V0

- Objectif: rendre la capture beta acceptable.
- Pourquoi: capture marche seulement avec party non pleine; no PC/box.
- Scope exact: soit PC Box V0, soit fallback explicite si party pleine avec
  message clair; ball consumption correct; capture persistence.
- Non-objectifs: formule complete multi-ball, box UI avancee.
- Packages/fichiers probables: `map_core`, `map_runtime`, `map_battle`.
- Criteres d'acceptation: capture party libre, party pleine et save/load testes.
- Tests attendus: `wild_battle_end_to_end_flow_test.dart`,
  `runtime_battle_outcome_apply_test.dart`, save repository tests.
- Risques: choix produit PC vs fallback.
- Dependances: BETA-06, BETA-10.
- Statut de blocage: oui.

### BETA-13 - Capture formula V0

- Objectif: remplacer auto-success par une formule beta simple.
- Pourquoi: auto-success est testable mais pas tres Pokemon-like.
- Scope exact: catch rate minimal, ball multiplier minimal, deterministic RNG
  injectable en tests.
- Non-objectifs: shakes exacts, status modifiers complexes, critical capture.
- Packages/fichiers probables: `map_battle`, `map_runtime`, `map_core`.
- Criteres d'acceptation: tests success/fail deterministes, feedback minimal.
- Tests attendus: battle session capture tests, runtime capture tests.
- Risques: peut etre repousse si beta accepte capture simplifiee documentee.
- Dependances: BETA-12.
- Statut de blocage: moyen, selon definition beta.

## 6. Phase 4 - Trainer battle + rewards + XP minimal

### BETA-14 - Trainer on map end-to-end V0

- Objectif: creer, placer et combattre un dresseur depuis l'editeur.
- Pourquoi: pieces existent mais pas de smoke no-code complet.
- Scope exact: trainer library -> NPC/trainer entity -> runtime trigger ->
  victory/defeat -> defeated flag -> post-battle dialogue.
- Non-objectifs: vision cones avances, rematch, AI avancee.
- Packages/fichiers probables: `map_editor`, `map_core`, `map_runtime`,
  `map_gameplay`.
- Criteres d'acceptation: test fixture editeur ou disque prouve le trajet.
- Tests attendus: editor use case tests, runtime trainer smoke.
- Risques: raw IDs dans UI trainer/entity.
- Dependances: BETA-02, BETA-03.
- Statut de blocage: oui.

### BETA-15 - Battle persistence contract V0

- Objectif: formaliser ce que le combat ecrit dans GameState.
- Pourquoi: HP oui; PP/status/held item/XP/rewards non.
- Scope exact: mapping party slots, HP, status, PP si beta, item consumption,
  capture, trainer defeated.
- Non-objectifs: evolution, switch history complete.
- Packages/fichiers probables: `map_battle`, `map_runtime`, `map_core`.
- Criteres d'acceptation: tests couvrent chaque champ contractuel.
- Tests attendus: runtime battle outcome tests.
- Risques: data model insuffisant.
- Dependances: BETA-06.
- Statut de blocage: oui.

### BETA-16 - Battle rewards and money/items V0

- Objectif: ajouter un reward contract apres wild/trainer battle.
- Pourquoi: bloc rewards est manquant.
- Scope exact: `BattleReward` ou equivalent runtime, money trainer minimal,
  item reward scenario-compatible, feedback text.
- Non-objectifs: loot tables avancees, badges sauf si slice le demande.
- Packages/fichiers probables: `map_core`, `map_battle`, `map_runtime`,
  `map_editor`.
- Criteres d'acceptation: trainer victory ajoute argent/item et save/reload le
  preserve.
- Tests attendus: battle outcome tests, scenario continuation tests, file save.
- Risques: source de verite reward entre battle/trainer/scenario.
- Dependances: BETA-14, BETA-15.
- Statut de blocage: oui.

### BETA-17 - XP and level-up minimal V0

- Objectif: gagner XP et level-up minimal apres combat.
- Pourquoi: `PlayerPokemon.level` existe mais pas XP.
- Scope exact: champ XP, XP awarded, threshold simple, level increment,
  feedback minimal.
- Non-objectifs: stats exactes, learn move, evolution.
- Packages/fichiers probables: `map_core`, `map_battle`, `map_runtime`.
- Criteres d'acceptation: combat donne XP, level-up possible, save/reload garde
  niveau et XP.
- Tests attendus: battle reward/XP tests, save persistence tests.
- Risques: schema migration et balance.
- Dependances: BETA-06, BETA-15.
- Statut de blocage: oui.

### BETA-18 - Post-battle presentation V0

- Objectif: expliquer au joueur victoire, defaite, reward, XP, capture.
- Pourquoi: beta jouable demande feedback, meme simple.
- Scope exact: message/result panel minimal, money/item/XP/level/capture lines.
- Non-objectifs: animations riches, audio.
- Packages/fichiers probables: `map_runtime`, `examples/playable_runtime_host`.
- Criteres d'acceptation: tests verifient que le feedback est affiche pour
  victoire, defaite et capture.
- Tests attendus: runtime widget/component tests.
- Risques: overlay battle deja complexe.
- Dependances: BETA-16, BETA-17.
- Statut de blocage: oui.

## 7. Phase 5 - Narrative end-to-end hardening

### BETA-19 - Narrative beta subset freeze

- Objectif: declarer le sous-ensemble narrative supporte pour beta.
- Pourquoi: le modele est riche; certains nodes restent non supportes.
- Scope exact: event/source types, actions autorisees, predicates, outcomes,
  battle continuation, give item/Pokemon, heal, complete step.
- Non-objectifs: tous les nodes studio, choice graph avance.
- Packages/fichiers probables: `map_core`, `map_runtime`, `map_editor`,
  `reports/beta`.
- Criteres d'acceptation: doc + validator refuse les actions hors beta.
- Tests attendus: narrative validator tests.
- Risques: frustrer authoring temporairement.
- Dependances: BETA-09, BETA-14.
- Statut de blocage: oui.

### BETA-20 - Conditional dialogue and world rules smoke

- Objectif: prouver dialogue different et world rule apres progression.
- Pourquoi: P3 fixtures le prouvent techniquement, pas sur un parcours beta.
- Scope exact: NPC avant/apres step, fact/world rule runtime visible,
  persistence consumed/progression.
- Non-objectifs: UI narrative polish.
- Packages/fichiers probables: `map_runtime`, `map_core`,
  `examples/playable_runtime_host`.
- Criteres d'acceptation: test e2e dialogue -> outcome -> step -> dialogue
  change -> save/reload.
- Tests attendus: runtime scenario smoke.
- Risques: event consumption semantics inegales.
- Dependances: BETA-19.
- Statut de blocage: oui.

### BETA-21 - Consumed events/scenes persistence hardening

- Objectif: garantir que one-shot events et scenes ne rejouent pas apres reload.
- Pourquoi: champs existent mais pas partout beta-proven.
- Scope exact: consumed event ids, completed cutscene ids, script variables,
  compatibility GameState JSON.
- Non-objectifs: migration ancienne exhaustive hors beta.
- Packages/fichiers probables: `map_core`, `map_runtime`, `map_gameplay`.
- Criteres d'acceptation: test one-shot event -> save -> reload -> no replay.
- Tests attendus: runtime/file repository tests.
- Risques: distinction `SaveData` legacy vs GameState JSON.
- Dependances: BETA-20.
- Statut de blocage: oui.

## 8. Phase 6 - Save/load beta hardening

### BETA-22 - Save/load transaction hardening

- Objectif: rendre `saveGame`/`loadGame` robustes et testables.
- Pourquoi: `PlayableMapGame.loadGame` est documente non transactionnel.
- Scope exact: rollback ou prevalidation, map/position truth, invalid save
  diagnostics, no partial destructive load.
- Non-objectifs: cloud save, multiple profiles riches.
- Packages/fichiers probables: `map_runtime`, `examples/playable_runtime_host`,
  `map_core`.
- Criteres d'acceptation: tests invalid load no-corrupt-current-state, valid
  load restores map/position/party/bag/progression.
- Tests attendus: runtime save/load tests, host menu tests.
- Risques: Flame lifecycle complexity.
- Dependances: BETA-04, BETA-21.
- Statut de blocage: oui.

### BETA-23 - Full beta save/reload smoke

- Objectif: sauvegarder et recharger apres exploration, narrative, battle,
  reward, capture et heal.
- Pourquoi: tests existent par morceaux, pas en chaine.
- Scope exact: fixture technique beta avant Selbrume final, asserts sur chaque
  etat important.
- Non-objectifs: 10-20 minutes de contenu.
- Packages/fichiers probables: `packages/map_runtime/test/fixtures`,
  `examples/playable_runtime_host/test`.
- Criteres d'acceptation: un test prouve le roundtrip complet.
- Tests attendus: nouveau smoke runtime/host.
- Risques: peut devenir fragile si trop long.
- Dependances: BETA-09, BETA-12, BETA-18, BETA-22.
- Statut de blocage: oui.

## 9. Phase 7 - Audio minimal

### BETA-24 - Audio catalog and validation V0

- Objectif: creer un modele audio beta et valider les fichiers.
- Pourquoi: audio est absent sauf metadata raw.
- Scope exact: catalogue BGM/SFX, refs map/battle/menu/dialogue/capture/heal,
  diagnostics missing file, editor picker minimal.
- Non-objectifs: importer tout le SDK audio, mixage avance.
- Packages/fichiers probables: `map_core`, `map_editor`, `map_runtime`.
- Criteres d'acceptation: projet avec audio manquant echoue validator; projet
  valide reference des assets existants.
- Tests attendus: core validator tests, editor picker/use case tests.
- Risques: asset licensing/provenance.
- Dependances: BETA-03.
- Statut de blocage: oui si audio reste dans checklist beta.

### BETA-25 - Runtime BGM/SFX and volume V0

- Objectif: jouer musique de map/combat et SFX beta.
- Pourquoi: aucune dependency/service audio n'existe.
- Scope exact: service audio, loop map BGM, switch battle BGM, SFX menu/dialogue
  /battle/capture/heal, volume music/effects/mute.
- Non-objectifs: crossfade parfait, spatial audio.
- Packages/fichiers probables: `map_runtime`, `examples/playable_runtime_host`,
  `map_core`.
- Criteres d'acceptation: tests avec fake audio service prouvent appels; smoke
  runtime charge assets.
- Tests attendus: runtime unit tests with fake audio, validator tests.
- Risques: Flutter desktop audio dependency, asset bundle config.
- Dependances: BETA-24.
- Statut de blocage: oui si audio reste dans checklist beta.

## 10. Phase 8 - Validator beta readiness

### BETA-26 - PlayableProjectValidator V0

- Objectif: agreger les validations necessaires a un projet jouable.
- Pourquoi: validateurs disperses ne suffisent pas.
- Scope exact: start map/spawn, warps, NPC refs, dialogues/scenes/outcomes,
  trainers/battles, species/moves/items, assets, audio, save compatibility.
- Non-objectifs: balance, style guide, lint cosmetique.
- Packages/fichiers probables: `map_core`, `map_runtime`, `map_editor`.
- Criteres d'acceptation: un projet invalide produit diagnostics actionnables;
  une fixture beta technique passe.
- Tests attendus: core validator tests with fixtures.
- Risques: faux positifs sur projets incomplets.
- Dependances: BETA-03, BETA-11, BETA-19, BETA-24.
- Statut de blocage: oui.

### BETA-27 - Editor validation surface V0

- Objectif: exposer le validator dans l'editeur.
- Pourquoi: beta no-code doit prevenir avant runtime.
- Scope exact: bouton/panel "Validate playability", diagnostics group by area,
  navigation vers item si possible.
- Non-objectifs: auto-fix massif, wizard complet.
- Packages/fichiers probables: `packages/map_editor`.
- Criteres d'acceptation: test UI ou notifier prouve affichage diagnostics.
- Tests attendus: editor widget tests.
- Risques: bruit diagnostique.
- Dependances: BETA-26.
- Statut de blocage: oui.

## 11. Phase 9 - Golden Slice Selbrume assembly

### BETA-28 - Selbrume content skeleton project

- Objectif: creer le vrai projet Selbrume minimal.
- Pourquoi: actuellement Selbrume est concept/roadmap, pas projet jouable.
- Scope exact: project dir, Bourg/Port maps, spawns, warps, Mael, Lysa, rival
  trainer, encounter table simple, items, heal point, audio refs.
- Non-objectifs: contenu 10-20 min complet, polish tileset final.
- Packages/fichiers probables: `examples/playable_runtime_host` ou future
  `examples/selbrume`, fixtures projet.
- Criteres d'acceptation: project loads, validator beta donne diagnostics connus
  seulement pour contenu non encore rempli.
- Tests attendus: runtime project load smoke.
- Risques: commencer trop tot avant validator/rewards.
- Dependances: BETA-23, BETA-26.
- Statut de blocage: oui, mais doit attendre les fondations.

### BETA-29 - Selbrume playable route V0

- Objectif: rendre Bourg -> Port jouable avec progression minimale.
- Pourquoi: la beta doit demontrer une boucle RPG concrete.
- Scope exact: start, starter, dialogue Mael, step/fact/world rule, exploration,
  wild encounter/capture, rival battle, Lysa dialogue, heal, save/reload.
- Non-objectifs: 10-20 minutes finales, side quests, shops.
- Packages/fichiers probables: projet Selbrume, `examples/playable_runtime_host/test`.
- Criteres d'acceptation: smoke e2e traverse la route et verifie GameState.
- Tests attendus: Selbrume route smoke.
- Risques: content design peut exposer gaps mechanics.
- Dependances: BETA-28.
- Statut de blocage: oui.

### BETA-30 - Selbrume 10-20 minute beta slice

- Objectif: etendre V0 en slice beta jouable.
- Pourquoi: checklist demande un projet exemple jouable 10-20 minutes.
- Scope exact: contenu final minimal, dialogues, encounters, trainer, rewards,
  audio minimal, save/reload final, validator green.
- Non-objectifs: monde complet, post-beta polish.
- Packages/fichiers probables: projet Selbrume, reports/beta, host tests.
- Criteres d'acceptation: validator green; smoke final vert; parcours manuel
  checklist vert.
- Tests attendus: Selbrume final smoke, validator test, save/reload test.
- Risques: lot trop gros si BETA-29 n'est pas strictement minimal.
- Dependances: BETA-29.
- Statut de blocage: oui.

## 12. Phase 10 - Beta release checklist

### BETA-31 - Beta release candidate gate

- Objectif: decider objectivement si la beta est releaseable.
- Pourquoi: eviter de confondre "tests passent" et "beta fonctionnelle".
- Scope exact: checklist finale, tests obligatoires, known limits, manual smoke,
  git status, package commands.
- Non-objectifs: nouvelles features.
- Packages/fichiers probables: `reports/beta`, CI/local scripts si existants.
- Criteres d'acceptation: rapport RC listant beta-ready oui/non, failures,
  commands exactes et final git status.
- Tests attendus: tous les tests cibles beta plus package analyze cible.
- Risques: decouverte tardive d'un blocker.
- Dependances: BETA-30.
- Statut de blocage: oui.

### BETA-32 - Post-beta backlog split

- Objectif: separer ce qui attend apres beta.
- Pourquoi: la beta ne doit pas absorber toute la parite RPG.
- Scope exact: classer polish, parity battle, advanced encounters, shops, PC UI,
  evolution, move learning, field moves, audio polish.
- Non-objectifs: implementation.
- Packages/fichiers probables: `reports/beta`, roadmap mecanique.
- Criteres d'acceptation: backlog post-beta clair avec priorites.
- Tests attendus: aucun.
- Risques: peu technique mais important pour focus.
- Dependances: BETA-31.
- Statut de blocage: non pour release, utile pour suite.

## 13. Shortest healthy path

Chemin le plus court mais sain vers beta:

1. BETA-00 a BETA-05 pour alignement, project disk, New Game, starter.
2. BETA-06 a BETA-09 pour party/bag/heal.
3. BETA-10 a BETA-12 pour encounters/capture avec fallback.
4. BETA-14 a BETA-18 pour trainer battle, rewards, XP, feedback.
5. BETA-19 a BETA-23 pour narrative/save/load.
6. BETA-24 a BETA-27 pour audio et validator.
7. BETA-28 a BETA-31 pour Selbrume et RC.

Lots pouvant etre repousses si la beta accepte une definition plus stricte et
documentee:

- BETA-13 capture formula, si capture deterministic/simple est acceptee.
- Une partie de BETA-25 SFX, si audio minimal se limite a BGM + deux SFX.
- BETA-32, qui est post-release hygiene.

Nombre approximatif de lots avant beta fonctionnelle: 28 a 31 selon le niveau
audio/capture exige. Nombre minimal recommande: 26 lots bloquants ou quasi
bloquants avant de declarer Selbrume beta-ready.

## 14. Proposed status update for relevant FG lots

Sans modifier la roadmap, l'audit propose:

| FG | Statut propose | Raison |
|---|---|---|
| FG-011 | TODO/BLOCKED | New Game runtime absent. |
| FG-012 | TODO | Starter model/manifest absent. |
| FG-013 | TODO | Starter runtime flow absent. |
| FG-014 | PARTIAL | Save/load existe, transaction hardening manque. |
| FG-016 | PARTIAL | Golden boot technique existe, pas beta Selbrume. |
| FG-021 | PARTIAL | PlayerPokemon persiste mais XP/PP/maxHP incomplets. |
| FG-022 | TODO | No PC box model trouve. |
| FG-024 | PARTIAL/TODO | Capture party ok, box/fallback beta absent. |
| FG-025 | TODO | Party full capture non routable vers box. |
| FG-026 | PARTIAL | Menu party minimal existe, pas beta complet. |
| FG-040 | TODO | Battle persistence contract incomplet. |
| FG-041 | TODO | PP write-back absent. |
| FG-042 | TODO | Status write-back incomplet. |
| FG-043 | TODO | Reward model absent. |
| FG-044 | TODO | XP absent. |
| FG-045 | TODO | Level-up apply absent. |
| FG-048 | TODO | Reward presentation absente. |
| FG-049 | TODO/PARTIAL | Capture auto-success, no formula. |
| FG-051 | TODO | Money/badges trainer absent. |
| FG-060 | TODO | Item effect registry beta absent. |
| FG-061 | TODO/PARTIAL | Bag runtime minimal seulement. |
| FG-062 | TODO | Medicine outside battle absent. |
| FG-063 | TODO | Status cure/revive absent. |
| FG-067 | PARTIAL | `giveItem` existe; pickup e2e beta manque. |
| FG-071 | TODO | Heal center absent. |
| FG-100 | PARTIAL | Encounters runtime existent, audit closure manque. |
| FG-108 | PARTIAL | Encounter authoring existe, validation beta manque. |
| FG-140 | PARTIAL | Trainer defeated flag existe, policy typed manque. |
| FG-141 | PARTIAL | Dialogue hook possible, pas beta-proven. |
| FG-146 | TODO/PARTIAL | Narrative validator existe, story progression validator beta manque. |
| FG-163 | PARTIAL | Save menu existe, hardening/transaction manque. |
| FG-181 | TODO | Selbrume project absent. |
| FG-182 | TODO | Selbrume e2e smoke absent. |
