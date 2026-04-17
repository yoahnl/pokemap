# Phase A — Vérité produit battleable

## 1. Résumé exécutif honnête

Verdict :

- la Phase A est livrée ;
- le repo versionne maintenant un **golden battle-ready slice** réel et lançable ;
- le host d'exemple sait charger ce slice via un vrai `project.json` et une vraie save de lancement adjacente ;
- le bootstrap moves embarqué a été réaligné pour cesser de prétendre supporter des seams encore mensongers ;
- un rapport automatique de couverture existe et mesure le vrai bootstrap et le vrai golden slice ;
- un smoke path local existe, à la fois côté runtime battle et côté host de lancement ;
- aucun chantier de fondation Showdown-like n'a été ouvert ;
- aucune nouvelle grosse mécanique battle n'a été ajoutée.

Résultat produit réel :

- le golden slice versionné démarre aujourd'hui un combat sauvage réel ;
- le golden slice versionné démarre aujourd'hui un combat trainer réel ;
- le rapport de couverture généré localement mesure :
  - bootstrap moves bridgeables : `13 / 21`
  - golden slice moves bridgeables : `3 / 3`
  - seeds joueur bridgeables : `2 / 2`
  - seeds trainer bridgeables : `1 / 1`
  - seeds wild bridgeables : `1 / 1`
  - combats wild authored démarrables : `1 / 1`
  - combats trainer authored démarrables : `1 / 1`

Limites maintenues volontairement :

- pas d'ouverture de `selfSwitch`, `forceSwitch`, hazards, terrains riches, abilities, items ou doubles ;
- pas d'élargissement opportuniste de `RuntimeBattleMoveBridge` ;
- pas de refonte request / `Side` / event engine / queue ;
- pas de mensonge sur `solar_beam`, qui reste `catalogOnly` malgré un sous-ensemble BE8 local réel, car sa vérité canonique Showdown est encore trop large pour être déclarée honnêtement supportée dans le bootstrap.

## 2. Pré-gates exécutés + résultats

Pré-gates git read-only au début :

- `git status --short`
  - worktree déjà sale avant le lot à cause de `?? reports/lot0-real-battle-coverage-and-showdown-plan.md`
- `git diff --stat`
  - vide au départ
- `git ls-files --others --exclude-standard`
  - bruit préexistant confirmé : `AGENTS.md` et `reports/lot0-real-battle-coverage-and-showdown-plan.md`

Pré-gates/audit technique utiles avant modifications :

- lecture ciblée de la chaîne `map_editor -> map_runtime -> example host`
- relecture des seams battle/runtime déjà ouverts par BE8/BE9/BE10/BE10A
- vérification du chemin réel de lancement produit dans `examples/playable_runtime_host`
- vérification du bootstrap moves embarqué dans `packages/map_editor`

État initial réellement constaté :

- le moteur et le runtime savaient déjà faire démarrer honnêtement un sous-ensemble singles 1v1 ;
- le repo ne versionnait toujours pas de slice produit battle-ready assumé ;
- le host d'exemple retombait surtout sur un seed de démo ;
- le bootstrap embarqué contenait encore plusieurs moves marqués trop favorablement ;
- un test du host était déjà rouge avant ce lot :
  - `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
  - cause : attente obsolète sur le nombre de moves dérivés pour Squirtle.

## 3. Méthode réelle utilisée

Méthode suivie :

1. audit du repo réel avant toute modification ;
2. choix explicite de l'emplacement du golden slice, du smoke path et de la mesure de couverture ;
3. implémentation minimale et strictement locale à la Phase A ;
4. génération d'une mesure reproductible ;
5. smoke tests réels ;
6. review séparée ;
7. intégration des remarques valides ;
8. rerun des validations utiles après corrections de review.

Ce qui a été confirmé par lecture de code :

- le host d'exemple était la meilleure surface produit existante pour porter un slice lançable ;
- le bootstrap moves embarqué vivait bien dans `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart` ;
- le bridge runtime restait la source de vérité de bridgeabilité ;
- le seed builder runtime était déjà capable de filtrer les moves non bridgeables sans inventer de remplacement ;
- les tests existants prouvaient bien le sous-ensemble moteur, mais pas une vérité produit versionnée.

Ce qui a été confirmé par exécution locale :

- le golden slice démarre un combat sauvage réel ;
- le golden slice démarre un combat trainer réel ;
- le host charge effectivement une vraie save versionnée adjacente au `project.json` ;
- le rapport de couverture se génère bien depuis le vrai bootstrap embarqué et le vrai golden slice ;
- les validations ciblées `flutter analyze` / `flutter test` sur les surfaces touchées sont vertes.

Ce qui reste une inférence raisonnable :

- un seul map slice suffit pour la Phase A ;
- la présence de `evolutionsDir` et `mediaDir` pointant vers des dossiers non versionnés dans le golden slice n'empêche pas la vérité produit Phase A tant qu'aucun chemin runtime utilisé ici n'en dépend.

Ce qui reste incertain :

- quel sera le vrai taux de battleability sur un projet plus riche qu'un slice minimal ;
- si un deuxième lot de coverage lift borné restera rentable après la mesure de ce slice, ou si les blockers dominants deviendront déjà structurels.

## 4. Audit initial réel

### 4.1. Où pouvait vivre honnêtement le golden slice

Options réellement auditées :

- `packages/map_editor`
  - rejeté comme emplacement principal du golden slice ;
  - bon endroit pour le bootstrap/scaffold ;
  - mauvais endroit pour une vérité produit directement lançable.
- `packages/map_runtime`
  - bon endroit pour smoke tests et mesure runtime ;
  - mauvais endroit pour une référence produit que quelqu'un peut ouvrir visuellement.
- `examples/playable_runtime_host`
  - retenu ;
  - déjà pensé pour charger un `project.json` réel ;
  - surface produit la plus honnête du repo pour une démonstration locale lançable.

Décision :

- golden slice versionné sous `examples/playable_runtime_host/golden_battle_slice/`
- smoke runtime sous `packages/map_runtime/test/`
- smoke host sous `examples/playable_runtime_host/test/`
- rapport de couverture généré sous `reports/`
- tooling de mesure réparti entre :
  - `packages/map_editor/tool/` pour exporter la vérité bootstrap embarquée ;
  - `packages/map_runtime/tool/` pour mesurer le golden slice ;
  - `scripts/` pour fournir une commande repo-root simple et reproductible.

### 4.2. Où le projet “mentait” encore avant le lot

Constats confirmés :

- le repo n'avait pas de slice battle-ready assumé et versionné ;
- le host d'exemple s'appuyait surtout sur un seed de démo historique ;
- les fixtures de tests donnaient une image plus favorable que le produit réel ;
- plusieurs moves du bootstrap embarqué donnaient encore l'illusion d'une couverture supportable alors qu'ils dépendaient de seams explicitement hors phase ;
- aucune mesure locale simple ne répondait noir sur blanc à :
  - quels moves du bootstrap passent vraiment le bridge ;
  - quels seeds du slice passent ;
  - quels combats authored démarrent ;
  - pourquoi un blocage survient.

## 5. Critique explicite du prompt

Le prompt était globalement bon, mais certains points méritaient d'être recadrés :

- `packages/map_editor` était autorisé “si nécessaire” ; j'ai considéré qu'il était effectivement nécessaire pour le réalignement honnête du bootstrap, mais pas comme lieu principal du golden slice.
- “1 ou 2 maps” : j'ai volontairement pris **1 map**. C'est suffisant pour la Phase A, plus lisible, et plus honnête qu'un mini monde artificiellement gonflé.
- “smoke test local” : je l'ai interprété comme :
  - un test runtime automatisé sur le vrai slice versionné ;
  - un test host qui prouve que le seam de lancement produit charge bien la vraie save adjacente ;
  - plus une documentation manuelle simple dans le README.
- le prompt n'explicitait pas assez la contrainte de vérité sur le seam host ; la review a confirmé qu'un smoke purement runtime ne suffisait pas à prouver la vérité produit du launch path.
- le prompt laissait ouverte l'idée d'ajouter des moves “déjà vraiment supportés”. C'est précisément là que `solar_beam` était piégeux : le sous-ensemble BE8 existe localement, mais le mouvement canonique reste trop large pour être présenté honnêtement comme bootstrap supporté.

## 6. Décisions retenues / rejetées

### Décisions retenues

- retenir `examples/playable_runtime_host/golden_battle_slice/` comme emplacement produit ;
- ajouter un seam explicite de save adjacente au `project.json` dans le host ;
- garder le seed de démo historique seulement comme fallback quand aucune vraie save versionnée n'existe ;
- générer la mesure de couverture depuis :
  - le vrai seed bootstrap embarqué ;
  - le vrai `project.json` du golden slice ;
  - la vraie save versionnée du golden slice ;
- réaligner le bootstrap par **reclassement honnête**, pas par élargissement du bridge.

### Décisions rejetées

- porter le golden slice comme seed interne `map_editor`
  - rejeté : trop proche d'une fixture applicative, pas assez produit-oriented.
- élargir massivement `RuntimeBattleMoveBridge`
  - rejeté : hors scope et risqué.
- laisser `absorb`, `double_slap`, `u_turn`, `whirlwind` dans une zone ambiguë du bootstrap
  - rejeté : le bootstrap devait cesser de mentir.
- promouvoir `solar_beam` en support bootstrap honnête
  - rejeté après review : trop flatteur au regard de la sémantique canonique.
- se contenter d'un smoke purement manuel
  - rejeté : pas assez reproductible en l'absence de CI.

## 7. Périmètre inclus / exclu

### Inclus

- `packages/map_editor`
  - uniquement pour réaligner le bootstrap et exporter sa vérité ;
- `packages/map_runtime`
  - uniquement pour mesurer la couverture et ajouter le smoke du vrai slice ;
- `examples/playable_runtime_host`
  - pour porter le golden slice et le seam de lancement produit ;
- `scripts/`
  - pour la commande de couverture reproductible ;
- `reports/`
  - pour le rapport de couverture généré et ce report final.

### Exclu

- toute ouverture de nouvelle grosse mécanique battle ;
- toute refonte request / `Side` / event engine / queue ;
- tout changement de `packages/map_battle` ;
- `packages/map_core` ;
- toute extension mensongère du bridge ;
- toute écriture Git interdite.

## 8. Plan local retenu

Plan exécuté :

1. créer un slice produit minimal, versionné, ouvrable via le host ;
2. ajouter une vraie save de lancement adjacente au `project.json` ;
3. documenter ce chemin dans le README du host ;
4. réaligner le bootstrap embarqué en reclassant honnêtement les moves hors scope ;
5. ajouter un exporter simple de ce bootstrap ;
6. ajouter un auditeur runtime du golden slice ;
7. ajouter un wrapper repo-root pour générer le rapport de couverture ;
8. ajouter un smoke runtime sur le vrai slice ;
9. ajouter un test host sur le vrai seam de lancement ;
10. passer en review ;
11. corriger les findings valides ;
12. rerun les validations.

## 9. Golden slice créé

Golden slice versionné :

- emplacement :
  - `examples/playable_runtime_host/golden_battle_slice/`
- contenu :
  - `project.json`
  - `runtime_host_launch_save.json`
  - `maps/golden_field.json`
  - deux espèces minimales :
    - `sproutle`
    - `sparkitten`
  - deux learnsets minimaux
  - un catalogue moves minimal limité aux moves réellement consommés
  - un README dédié

Choix de conception :

- le slice n'est pas un projet “magique” caché en test ;
- le slice n'utilise que les données strictement nécessaires pour prouver la battleability ;
- la save de lancement versionnée est adjacente au `project.json` pour que le host puisse la résoudre sans convention cachée ;
- la map est volontairement minuscule pour rester lisible.

Contenu produit réel du slice :

- une map `golden_field`
- une zone d'herbe avec rencontre sauvage `sparkitten`
- un NPC trainer `npc_trainer_rookie` lié à `trainer_rookie`
- une party joueur versionnée avec :
  - `sproutle` niveau 7
  - `sparkitten` niveau 6

## 10. Alignement bootstrap/scaffold

Moves explicitement reclassés pour cesser de mentir :

- `absorb`
  - reste dans le seed ;
  - passe en `catalogOnly` ;
  - raison : `unsupported_effect_kind:drain`
- `double_slap`
  - passe en `catalogOnly`
  - raison : `unsupported_effect_kind:multi_hit`
- `u_turn`
  - passe en `catalogOnly`
  - raison : `unsupported_effect_kind:self_switch`
- `whirlwind`
  - passe en `catalogOnly`
  - raison : `unsupported_effect_kind:force_switch`
- `trick_room`
  - reste `structuredPartial`
  - cohérent avec le sous-ensemble BE9 réellement bridgeable via exception locale
- `solar_beam`
  - garde son effet `chargeThenStrike` au niveau data ;
  - mais reste `catalogOnly` ;
  - raisons :
    - `showdown_callback:onBasePower`
    - `showdown_callback:onTryMove`
    - `unsupported_mechanic:weather_charge_shortcuts`

Principe retenu :

- le bootstrap peut contenir des moves non bridgeables ;
- il ne doit pas les présenter comme honnêtement supportés ;
- la vérité du bootstrap est désormais plus sévère, donc plus utile.

### Justification fichier par fichier

- `examples/playable_runtime_host/README.md`
  - documente le chemin manuel le plus simple vers la vérité produit Phase A.
- `examples/playable_runtime_host/lib/main.dart`
  - branche le host sur une vraie save versionnée adjacente au `project.json`.
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
  - centralise le seam de lancement produit et ses garde-fous.
- `examples/playable_runtime_host/test/runtime_launch_save_test.dart`
  - verrouille le chargement de la save versionnée adjacente.
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
  - prouve que le golden slice versionné expose bien une vraie save de lancement.
- `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
  - remet au vrai le test de fallback historique du host, déjà adjacent au seam touché.
- `examples/playable_runtime_host/golden_battle_slice/**`
  - porte la vérité produit minimale, versionnée et lançable.
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
  - réaligne honnêtement les claims du bootstrap.
- `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`
  - verrouille les reclassements les plus sensibles du bootstrap.
- `packages/map_editor/tool/export_embedded_pokemon_moves_bootstrap.dart`
  - exporte la vraie source bootstrap sans dépendre de JSON généré.
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
  - prouve qu'un combat wild et un combat trainer démarrent sur le slice réel.
- `packages/map_runtime/tool/phase_a_battle_coverage.dart`
  - mesure le bootstrap et le golden slice avec les vrais loaders runtime.
- `scripts/generate_phase_a_battle_coverage.sh`
  - donne une commande repo-root simple et reproductible sans CI.
- `reports/phase-a-battle-coverage.md`
  - capture la mesure réelle générée.
- `reports/phase-a-golden-battle-slice-report.md`
  - consigne l'audit, les décisions, les validations et l'annexe exhaustive.

## 11. Rapport de couverture réel

Commande repo-root retenue :

- `./scripts/generate_phase_a_battle_coverage.sh`

Source de vérité de cette commande :

- export du vrai bootstrap embarqué via `packages/map_editor/tool/export_embedded_pokemon_moves_bootstrap.dart`
- audit du vrai golden slice via `packages/map_runtime/tool/phase_a_battle_coverage.dart`

Résultat réellement généré :

- fichier :
  - `reports/phase-a-battle-coverage.md`
- chiffres :
  - bootstrap moves bridgeables : `13 / 21`
  - golden slice moves bridgeables : `3 / 3`
  - seeds joueur bridgeables : `2 / 2`
  - seeds trainer bridgeables : `1 / 1`
  - seeds wild bridgeables : `1 / 1`
  - combats wild démarrables : `1 / 1`
  - combats trainer démarrables : `1 / 1`

Gardes-fous importants :

- le tool runtime refuse un save path qui ne vit pas à côté du `project.json` ;
- la mesure n'utilise pas une fixture de `/tmp` ;
- la vérité joueur vient de la vraie save versionnée du slice.

## 12. Smoke test local réel

Smoke paths livrés :

- smoke runtime :
  - `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
  - prouve qu'un combat sauvage et un combat trainer démarrent réellement depuis le slice versionné
- smoke host :
  - `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
  - prouve que le host voit et charge la save versionnée adjacente

Smoke manuel documenté :

1. `cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host`
2. `/opt/homebrew/bin/flutter run -d macos`
3. sélectionner `golden_battle_slice/project.json`
4. charger `golden_field`

## 13. Commandes réellement exécutées

Git read-only :

- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

Audit local :

- lectures ciblées via `rg`, `sed`, `find`, `wc -l`
- relecture des seams runtime/host/bootstrap et des fichiers du golden slice

Validation map_editor :

- `cd packages/map_editor && /opt/homebrew/bin/flutter test test/pokemon_moves_bootstrap_seed_test.dart`
- `cd packages/map_editor && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart test/pokemon_moves_bootstrap_seed_test.dart tool/export_embedded_pokemon_moves_bootstrap.dart`

Validation example host :

- `cd examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/runtime_launch_save_test.dart test/runtime_demo_party_seed_test.dart test/project_loader_page_test.dart test/phase_a_golden_slice_launch_test.dart`
- `cd examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/phase_a_golden_slice_launch_test.dart`
- `cd examples/playable_runtime_host && /opt/homebrew/bin/flutter analyze --no-pub lib/main.dart lib/src/runtime_launch_save.dart lib/src/runtime_demo_party_seed.dart test/runtime_launch_save_test.dart test/runtime_demo_party_seed_test.dart test/project_loader_page_test.dart test/phase_a_golden_slice_launch_test.dart`

Validation runtime :

- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/phase_a_golden_battle_slice_smoke_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub tool/phase_a_battle_coverage.dart test/phase_a_golden_battle_slice_smoke_test.dart`

Couverture :

- `./scripts/generate_phase_a_battle_coverage.sh`

## 14. Résultats réels analyze / tests / smoke / scripts

### map_editor

- `flutter test test/pokemon_moves_bootstrap_seed_test.dart`
  - vert
- `flutter analyze --no-pub ...`
  - vert

### example host

- `flutter test test/runtime_launch_save_test.dart test/runtime_demo_party_seed_test.dart test/project_loader_page_test.dart test/phase_a_golden_slice_launch_test.dart`
  - vert
- `flutter test test/phase_a_golden_slice_launch_test.dart`
  - vert
- `flutter analyze --no-pub ...`
  - vert

### map_runtime

- `flutter test test/phase_a_golden_battle_slice_smoke_test.dart`
  - vert
- `flutter analyze --no-pub ...`
  - vert

### couverture

- `./scripts/generate_phase_a_battle_coverage.sh`
  - vert
  - `reports/phase-a-battle-coverage.md` régénéré

Note finale de validation :

- après ces validations vertes, seul `reports/phase-a-golden-battle-slice-report.md` a encore été créé/modifié ;
- aucune surface code exécutable n'a changé après ces reruns ;
- il n'y avait donc pas de justification honnête pour relancer davantage de tests/analyze.

## 15. Incidents rencontrés

1. **Worktree déjà sale avant le lot**
   - `reports/lot0-real-battle-coverage-and-showdown-plan.md` était déjà présent comme bruit non tracké.

2. **Test host déjà rouge avant Phase A**
   - `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
   - l'attente Squirtle ne correspondait plus à la dérivation réelle des moves ;
   - correction locale et justifiée car ce test protège directement le seam de fallback que la Phase A touche.

3. **Sur-optimisme initial sur `solar_beam`**
   - première itération trop flatteuse ;
   - review a correctement pointé que le bootstrap n'avait pas à annoncer une vérité plus large que la réalité canonique supportée ;
   - correction appliquée.

4. **Smoke initial trop centré runtime**
   - première version ne prouvait pas assez le seam host/launch ;
   - review a demandé un test host réel ;
   - correction appliquée.

5. **Agent secondaire sans retour utile**
   - `Ptolemy` a fini shutdown sans payload exploitable ;
   - aucun finding retenu de cet agent.

## 16. État git utile final

Note importante :

- le worktree n'était pas propre au départ ;
- le bruit préexistant a été distingué explicitement ;
- aucune écriture Git interdite n'a été faite.

État final attendu après ce lot :

- fichiers modifiés suivis :
  - `examples/playable_runtime_host/README.md`
  - `examples/playable_runtime_host/lib/main.dart`
  - `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
  - `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- fichiers créés :
  - `examples/playable_runtime_host/golden_battle_slice/README.md`
  - `examples/playable_runtime_host/golden_battle_slice/project.json`
  - `examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json`
  - `examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json`
  - `examples/playable_runtime_host/golden_battle_slice/data/pokemon/species/001-sproutle.json`
  - `examples/playable_runtime_host/golden_battle_slice/data/pokemon/species/004-sparkitten.json`
  - `examples/playable_runtime_host/golden_battle_slice/data/pokemon/learnsets/sproutle.json`
  - `examples/playable_runtime_host/golden_battle_slice/data/pokemon/learnsets/sparkitten.json`
  - `examples/playable_runtime_host/golden_battle_slice/data/pokemon/catalogs/moves.json`
  - `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
  - `examples/playable_runtime_host/test/runtime_launch_save_test.dart`
  - `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
  - `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`
  - `packages/map_editor/tool/export_embedded_pokemon_moves_bootstrap.dart`
  - `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
  - `packages/map_runtime/tool/phase_a_battle_coverage.dart`
  - `scripts/generate_phase_a_battle_coverage.sh`
  - `reports/phase-a-battle-coverage.md`
  - `reports/phase-a-golden-battle-slice-report.md`
- bruit préexistant conservé :
  - `reports/lot0-real-battle-coverage-and-showdown-plan.md`

Sortie réelle du `git status --short` final :

```text
 M examples/playable_runtime_host/README.md
 M examples/playable_runtime_host/lib/main.dart
 M examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
 M packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
?? examples/playable_runtime_host/golden_battle_slice/
?? examples/playable_runtime_host/lib/src/runtime_launch_save.dart
?? examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
?? examples/playable_runtime_host/test/runtime_launch_save_test.dart
?? packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart
?? packages/map_editor/tool/
?? packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
?? packages/map_runtime/tool/
?? reports/lot0-real-battle-coverage-and-showdown-plan.md
?? reports/phase-a-battle-coverage.md
?? reports/phase-a-golden-battle-slice-report.md
?? scripts/
```

Sortie réelle du `git diff --stat` final :

```text
 examples/playable_runtime_host/README.md           | 37 ++++++++++++-----
 examples/playable_runtime_host/lib/main.dart       | 46 +++++++++++++---------
 .../test/runtime_demo_party_seed_test.dart         |  2 +-
 .../seeds/pokemon_moves_bootstrap_seed.dart        | 24 ++++++++++-
 4 files changed, 77 insertions(+), 32 deletions(-)
```

Sortie réelle du `git ls-files --others --exclude-standard` final :

```text
examples/playable_runtime_host/golden_battle_slice/README.md
examples/playable_runtime_host/golden_battle_slice/data/pokemon/catalogs/moves.json
examples/playable_runtime_host/golden_battle_slice/data/pokemon/learnsets/sparkitten.json
examples/playable_runtime_host/golden_battle_slice/data/pokemon/learnsets/sproutle.json
examples/playable_runtime_host/golden_battle_slice/data/pokemon/species/001-sproutle.json
examples/playable_runtime_host/golden_battle_slice/data/pokemon/species/004-sparkitten.json
examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json
examples/playable_runtime_host/golden_battle_slice/project.json
examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
examples/playable_runtime_host/lib/src/runtime_launch_save.dart
examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
examples/playable_runtime_host/test/runtime_launch_save_test.dart
packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart
packages/map_editor/tool/export_embedded_pokemon_moves_bootstrap.dart
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
packages/map_runtime/tool/phase_a_battle_coverage.dart
reports/lot0-real-battle-coverage-and-showdown-plan.md
reports/phase-a-battle-coverage.md
reports/phase-a-golden-battle-slice-report.md
scripts/generate_phase_a_battle_coverage.sh
```

## 17. Checklist finale

- [x] ai-je audité le repo réel avant de modifier ?
- [x] ai-je choisi explicitement un emplacement pertinent pour le golden slice ?
- [x] ai-je créé un golden slice réellement versionné et produit-oriented ?
- [x] le golden slice est-il vraiment lançable localement ?
- [x] ai-je évité de prendre les fixtures de tests pour la vérité produit ?
- [x] ai-je réaligné le bootstrap/scaffold sans mentir sur la couverture ?
- [x] ai-je ajouté des moves seulement s'ils sont réellement supportés ?
- [x] ai-je retiré / reclassé les moves mensongers ?
- [x] ai-je produit une mesure réelle de couverture ?
- [x] ai-je produit un smoke test local reproductible ?
- [x] ai-je évité toute nouvelle grosse mécanique battle ?
- [x] ai-je évité toute refonte de fondation prématurée ?
- [x] ai-je évité tout git write interdit ?
- [x] ai-je relancé analyze/tests/validations utiles localement ?
- [x] ai-je utilisé un sub-agent d'audit/design ?
- [x] ai-je utilisé un reviewer séparé ?
- [x] ai-je intégré les remarques valides du reviewer ?
- [x] mon rapport final est-il vraiment exhaustif ?
- [x] ai-je inclus le contenu complet de tous les fichiers touchés ?
- [x] ai-je explicitement signalé ce qui reste incertain ?

## 18. Retour du sub-agent

Sub-agent d'audit/design utilisé :

- `Hume`

Ce qu'il a proposé :

- golden slice plus proche des seeds `map_editor`
- smoke côté host
- coverage mesurée explicitement

Ce que j'ai retenu :

- l'idée qu'il fallait distinguer clairement :
  - lieu du golden slice
  - lieu du smoke
  - lieu du tooling de mesure
- la nécessité d'un smoke réellement produit-facing

Ce que j'ai rejeté :

- porter le golden slice sous forme de seed `map_editor`
  - rejeté car trop orienté bootstrap interne, pas assez produit.

## 19. Retour du reviewer séparé

Reviewer séparé utilisé :

- `Chandrasekhar`

Findings utiles remontés :

1. `solar_beam` était présenté trop favorablement
   - retenu
2. le smoke devait aussi prouver le seam host de lancement
   - retenu
3. le tool de couverture devait refuser des chemins save/project non adjacents
   - retenu

Remarque signalée mais non traduite en changement bloquant :

- absence de certains sous-répertoires non consommés (`media`, `evolutions`) dans le slice
  - documentée comme limite acceptable de Phase A ;
  - non retenue comme blocker.

## 20. Corrections appliquées après review

- `solar_beam` rebasculé en `catalogOnly`
- test bootstrap mis à jour pour refléter cette vérité
- ajout du test host `phase_a_golden_slice_launch_test.dart`
- durcissement du tool de couverture pour imposer l'adjacence `project.json` / `runtime_host_launch_save.json`

## 21. Autocritique finale

Ce lot est bon et honnête, mais il ne faut pas le sur-vendre.

Ce que le lot prouve vraiment :

- qu'on sait maintenant versionner et lancer un slice produit battleable ;
- qu'on sait mesurer localement la vérité du bootstrap et du slice ;
- qu'on a cessé quelques mensonges de bootstrap.

Ce qu'il ne prouve pas :

- que le repo entier devient “battleable” au sens large ;
- que la couverture data réelle hors golden slice est bonne ;
- qu'un coverage lift Phase B sera forcément encore rentable ;
- qu'on peut rester longtemps sans fondations plus riches.

Risque restant :

- un golden slice trop petit peut donner une fausse sensation de confort si on oublie qu'il sert de **slice de vérité**, pas d'échantillon représentatif complet du futur contenu produit.

## 22. Contenu complet de tous les fichiers modifiés / créés / supprimés

Note :

- le contenu complet du présent report n'est pas recopié ici pour éviter la récursion infinie ;
- tous les autres fichiers touchés par le lot sont recopiés intégralement ci-dessous ;
- il n'y a eu aucune suppression de fichier dans ce lot.

### `examples/playable_runtime_host/README.md`

```md
# playable_runtime_host

Host Flutter desktop minimal pour charger un `project.json` PokeMap et lancer
le runtime Flame localement.

## Phase A golden slice

Le repo versionne maintenant un slice produit de référence ici :

- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/project.json`

Ce slice contient :
- une map `golden_field`
- une zone de rencontre sauvage
- un dresseur
- un petit catalogue Pokémon minimal mais réellement battleable
- une vraie save de lancement `runtime_host_launch_save.json`

### Lancer le golden slice

1. `cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host`
2. `/opt/homebrew/bin/flutter run -d macos`
3. Sélectionner le `project.json` du dossier `golden_battle_slice`
4. Charger la map `golden_field`

Le host charge automatiquement `runtime_host_launch_save.json` s’il existe à
côté du `project.json`. Sinon, il retombe sur le seed de démo historique.

## Validation locale utile

- smoke test runtime :
  `cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/phase_a_golden_battle_slice_smoke_test.dart`
- tests host liés au lancement :
  `cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/project_loader_page_test.dart test/runtime_launch_save_test.dart test/runtime_demo_party_seed_test.dart test/phase_a_golden_slice_launch_test.dart`
```

### `examples/playable_runtime_host/golden_battle_slice/README.md`

```md
# Phase A Golden Battle Slice

Ce dossier versionne le **slice produit de référence** pour la Phase A de la
roadmap battle.

Objectif :
- fournir un vrai `project.json` lançable localement ;
- fournir une vraie save de lancement versionnée ;
- prouver qu'un combat sauvage et un combat dresseur démarrent honnêtement ;
- servir de base stable aux smoke tests et au rapport de couverture.

Contenu minimal assumé :
- 1 map : `golden_field`
- 1 zone de rencontre sauvage
- 1 NPC dresseur
- 2 espèces locales minimalement jouables
- 1 catalogue moves strictement limité aux moves utilisés par le slice
- 1 save de lancement : `runtime_host_launch_save.json`

Lancement manuel via le host :
1. `cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host`
2. `/opt/homebrew/bin/flutter run -d macos`
3. Sélectionner :
   `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/project.json`
4. Charger la map `golden_field`

Le host détecte automatiquement `runtime_host_launch_save.json` à côté du
`project.json` et démarre avec cette vraie party versionnée.
```

### `examples/playable_runtime_host/golden_battle_slice/project.json`

```json
{
  "name": "Phase A Golden Battle Slice",
  "version": "v1",
  "maps": [
    {
      "id": "golden_field",
      "name": "Golden Field",
      "relativePath": "maps/golden_field.json",
      "role": "exterior",
      "sortOrder": 0
    }
  ],
  "tilesets": [],
  "encounterTables": [
    {
      "id": "golden_grass",
      "name": "Golden Grass",
      "encounterKind": "walk",
      "entries": [
        {
          "speciesId": "sparkitten",
          "minLevel": 6,
          "maxLevel": 6,
          "weight": 1
        }
      ]
    }
  ],
  "trainers": [
    {
      "id": "trainer_rookie",
      "name": "Mira",
      "trainerClass": "Rookie",
      "team": [
        {
          "speciesId": "sparkitten",
          "level": 6,
          "moves": [
            "tackle",
            "growl"
          ]
        }
      ]
    }
  ],
  "pokemon": {
    "enabled": true,
    "dataRoot": "data/pokemon",
    "speciesDir": "data/pokemon/species",
    "learnsetsDir": "data/pokemon/learnsets",
    "evolutionsDir": "data/pokemon/evolutions",
    "mediaDir": "data/pokemon/media",
    "catalogFiles": {
      "moves": "data/pokemon/catalogs/moves.json"
    }
  }
}
```

### `examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json`

```json
{
  "saveId": "phase-a-golden-slice",
  "currentMapId": "golden_field",
  "playerPosition": {
    "x": 1,
    "y": 1
  },
  "playerFacing": "east",
  "party": {
    "members": [
      {
        "speciesId": "sproutle",
        "natureId": "bold",
        "abilityId": "overgrow",
        "level": 7,
        "knownMoveIds": [
          "tackle",
          "growl",
          "vine_whip"
        ],
        "currentHp": 25
      },
      {
        "speciesId": "sparkitten",
        "natureId": "hardy",
        "abilityId": "blaze",
        "level": 6,
        "knownMoveIds": [
          "tackle",
          "growl"
        ],
        "currentHp": 22
      }
    ]
  },
  "trainerProfile": {
    "name": "Phase A Hero"
  },
  "bag": {
    "entries": [
      {
        "itemId": "poke-ball",
        "categoryId": "items",
        "quantity": 2
      }
    ]
  }
}
```

### `examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json`

```json
{
  "id": "golden_field",
  "name": "Golden Field",
  "size": {
    "width": 4,
    "height": 3
  },
  "version": "v1",
  "entities": [
    {
      "id": "spawn_start",
      "name": "Spawn Start",
      "kind": "spawn",
      "pos": {
        "x": 1,
        "y": 1
      },
      "blocksMovement": false,
      "spawn": {
        "role": "player_start",
        "facing": "east"
      }
    },
    {
      "id": "npc_trainer_rookie",
      "name": "Rookie Mira",
      "kind": "npc",
      "pos": {
        "x": 2,
        "y": 1
      },
      "npc": {
        "displayName": "Mira",
        "trainerId": "trainer_rookie",
        "facing": "west"
      }
    }
  ],
  "gameplayZones": [
    {
      "id": "golden_grass_zone",
      "name": "Golden Grass",
      "kind": "encounter",
      "area": {
        "pos": {
          "x": 1,
          "y": 0
        },
        "size": {
          "width": 1,
          "height": 1
        }
      },
      "encounter": {
        "encounterTableId": "golden_grass",
        "encounterKind": "walk"
      }
    }
  ],
  "mapMetadata": {
    "defaultSpawnId": "spawn_start"
  }
}
```

### `examples/playable_runtime_host/golden_battle_slice/data/pokemon/species/001-sproutle.json`

```json
{
  "id": "sproutle",
  "slug": "sproutle",
  "nationalDex": 1,
  "names": {
    "en": "Sproutle"
  },
  "speciesName": {
    "en": "Seedling"
  },
  "genIntroduced": 1,
  "typing": {
    "types": [
      "grass"
    ]
  },
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45,
    "bst": 318
  },
  "abilities": {
    "primary": "overgrow"
  },
  "breeding": {
    "genderRatio": {
      "male": 0.875,
      "female": 0.125
    },
    "eggGroups": [
      "monster",
      "grass"
    ],
    "hatchCycles": 20
  },
  "progression": {
    "growthRateId": "medium_slow",
    "baseExp": 64,
    "catchRate": 45,
    "baseFriendship": 50
  },
  "refs": {
    "learnset": "sproutle",
    "evolution": "sproutle",
    "media": "sproutle"
  },
  "dexContent": {
    "heightM": 0.7,
    "weightKg": 6.9
  },
  "classification": {
    "isEnabledInProject": true
  },
  "gameplayFlags": {
    "starterEligible": true
  },
  "sourceMeta": {
    "seededBy": "phase_a_golden_slice",
    "seedVersion": 1
  }
}
```

### `examples/playable_runtime_host/golden_battle_slice/data/pokemon/species/004-sparkitten.json`

```json
{
  "id": "sparkitten",
  "slug": "sparkitten",
  "nationalDex": 4,
  "names": {
    "en": "Sparkitten"
  },
  "speciesName": {
    "en": "Ember Cat"
  },
  "genIntroduced": 1,
  "typing": {
    "types": [
      "fire"
    ]
  },
  "baseStats": {
    "hp": 35,
    "atk": 52,
    "def": 43,
    "spa": 60,
    "spd": 50,
    "spe": 65,
    "bst": 305
  },
  "abilities": {
    "primary": "blaze"
  },
  "breeding": {
    "genderRatio": {
      "male": 0.875,
      "female": 0.125
    },
    "eggGroups": [
      "field"
    ],
    "hatchCycles": 20
  },
  "progression": {
    "growthRateId": "medium_slow",
    "baseExp": 62,
    "catchRate": 45,
    "baseFriendship": 50
  },
  "refs": {
    "learnset": "sparkitten",
    "evolution": "sparkitten",
    "media": "sparkitten"
  },
  "dexContent": {
    "heightM": 0.6,
    "weightKg": 8.5
  },
  "classification": {
    "isEnabledInProject": true
  },
  "sourceMeta": {
    "seededBy": "phase_a_golden_slice",
    "seedVersion": 1
  }
}
```

### `examples/playable_runtime_host/golden_battle_slice/data/pokemon/learnsets/sproutle.json`

```json
{
  "speciesId": "sproutle",
  "startingMoves": [
    "tackle"
  ],
  "relearnMoves": [
    "growl"
  ],
  "levelUp": [
    {
      "moveId": "vine_whip",
      "level": 5,
      "source": "level_up",
      "versionGroup": "phase_a"
    }
  ]
}
```

### `examples/playable_runtime_host/golden_battle_slice/data/pokemon/learnsets/sparkitten.json`

```json
{
  "speciesId": "sparkitten",
  "startingMoves": [
    "tackle"
  ],
  "relearnMoves": [
    "growl"
  ],
  "levelUp": []
}
```

### `examples/playable_runtime_host/golden_battle_slice/data/pokemon/catalogs/moves.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "moves",
  "meta": {
    "description": "Phase A golden slice move catalog",
    "notes": [
      "Only the exact moves consumed by the golden slice are versioned here.",
      "This file is intentionally tiny so the slice stays readable and measurable."
    ]
  },
  "entries": [
    {
      "id": "tackle",
      "name": "Tackle",
      "names": {
        "en": "Tackle"
      },
      "generation": 1,
      "source": "phase_a_golden_slice",
      "type": "normal",
      "category": "physical",
      "target": "normal",
      "basePower": 40,
      "accuracy": {
        "kind": "percent",
        "value": 100
      },
      "pp": 35,
      "engineSupportLevel": "structured_supported"
    },
    {
      "id": "growl",
      "name": "Growl",
      "names": {
        "en": "Growl"
      },
      "generation": 1,
      "source": "phase_a_golden_slice",
      "type": "normal",
      "category": "status",
      "target": "allAdjacentFoes",
      "basePower": 0,
      "accuracy": {
        "kind": "percent",
        "value": 100
      },
      "pp": 40,
      "effects": [
        {
          "kind": "modify_stats",
          "targetScope": "target",
          "stageChanges": [
            {
              "stat": "attack",
              "stages": -1
            }
          ]
        }
      ],
      "engineSupportLevel": "structured_supported"
    },
    {
      "id": "vine_whip",
      "name": "Vine Whip",
      "names": {
        "en": "Vine Whip"
      },
      "generation": 1,
      "source": "phase_a_golden_slice",
      "type": "grass",
      "category": "physical",
      "target": "normal",
      "basePower": 45,
      "accuracy": {
        "kind": "percent",
        "value": 100
      },
      "pp": 25,
      "engineSupportLevel": "structured_supported"
    }
  ]
}
```

### `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

/// Nom fixe du fichier de save versionné qu'un projet peut exposer pour le
/// host runtime.
///
/// Phase A veut une vérité produit réellement lançable :
/// - un simple `project.json` sélectionnable dans le host ;
/// - éventuellement une vraie save de lancement adjacente ;
/// - et aucune dépendance à une fixture temporaire ou à un seed "magique".
///
/// Si ce fichier est présent à côté du `project.json`, le host le traite comme
/// la meilleure source de vérité pour l'état joueur initial.
const kRuntimeHostLaunchSaveFileName = 'runtime_host_launch_save.json';

/// Charge la save versionnée de lancement d'un projet runtime, si elle existe.
///
/// Politique volontairement stricte :
/// - absence du fichier => `null`, le host peut alors retomber sur son seed
///   de démo historique ;
/// - fichier présent mais invalide => erreur explicite ;
/// - aucune fallback silencieuse vers une autre save si ce seam produit est
///   cassé, parce qu'on veut que le golden slice reste honnête.
Future<SaveData?> loadRuntimeHostLaunchSaveData({
  required String projectFilePath,
}) async {
  final projectFile = File(projectFilePath);
  final launchSaveFile = File.fromUri(
    projectFile.parent.uri.resolve(kRuntimeHostLaunchSaveFileName),
  );
  if (!await launchSaveFile.exists()) {
    return null;
  }

  final decoded = jsonDecode(await launchSaveFile.readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw StateError(
      'Le fichier $kRuntimeHostLaunchSaveFileName doit contenir un objet JSON.',
    );
  }

  try {
    return SaveData.fromJson(decoded).normalized();
  } catch (error) {
    throw StateError(
      'Le fichier $kRuntimeHostLaunchSaveFileName est invalide: $error',
    );
  }
}
```

### `examples/playable_runtime_host/lib/main.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'src/in_game_menu.dart';
import 'src/runtime_demo_party_seed.dart';
import 'src/runtime_launch_save.dart';
import 'src/runtime_launch_options.dart';
import 'src/runtime_pokedex_loader.dart';

// Point d'entrée minimal du host runtime.
// On garde un MaterialApp très simple, puis toute la navigation se fait
// depuis la page de chargement et le menu in-game.
void main() {
  runApp(const MaterialApp(
    title: 'Playable Runtime Host',
    home: _ProjectLoaderPage(),
  ));
}

// Cette page joue deux rôles très ciblés :
// 1. charger un projet et une map runtime ;
// 2. exposer les surfaces minimales de debug/save/menu utiles aux phases 9-10.
class _ProjectLoaderPage extends StatefulWidget {
  const _ProjectLoaderPage();

  @override
  State<_ProjectLoaderPage> createState() => _ProjectLoaderPageState();
}

class _ProjectLoaderPageState extends State<_ProjectLoaderPage> {
  String _projectFilePath = '';
  List<ProjectMapEntry> _availableMaps = const [];
  String? _selectedMapId;
  PlayableMapGame? _game;
  String? _error;
  bool _loading = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showFpsOverlay = false;
  bool _surfingEnabled = false;
  bool _seedDemoPokemon = true;
  bool _saveLoadBusy = false;
  String? _saveLoadStatus;
  String? _saveLoadError;
  Timer? _runtimeInfoTicker;

  static const _prefsFileName = '.playable_runtime_host_prefs.json';

  @override
  void initState() {
    super.initState();
    _restoreLastSession();
  }

  @override
  void dispose() {
    // Le ticker d'overlay est strictement local au host et doit toujours être
    // arrêté quand la page sort, pour éviter toute fuite de rafraîchissement.
    _runtimeInfoTicker?.cancel();
    super.dispose();
  }

  // Les préférences locales du host ne font pas partie de la save gameplay.
  // Elles servent seulement à rouvrir rapidement le dernier projet dans l'outil
  // d'hébergement runtime.
  String _prefsFilePath() {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return _prefsFileName;
    }
    return '$home/$_prefsFileName';
  }

  // La restauration des préférences est volontairement best-effort :
  // on veut retrouver vite le dernier projet, sans jamais bloquer le chargement
  // si le fichier local est absent ou invalide.
  Future<void> _restoreLastSession() async {
    try {
      final file = File(_prefsFilePath());
      if (!await file.exists()) {
        return;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final savedProjectPath = (decoded['projectFilePath'] as String?)?.trim();
      final savedMapId = (decoded['mapId'] as String?)?.trim();
      if (savedProjectPath == null || savedProjectPath.isEmpty) {
        return;
      }
      if (!await File(savedProjectPath).exists()) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _projectFilePath = savedProjectPath;
        _selectedMapId = savedMapId != null && savedMapId.isNotEmpty
            ? savedMapId
            : _selectedMapId;
      });
      await _loadProjectMapsFromManifest(
        savedProjectPath,
        preferredMapId: savedMapId,
      );
    } catch (_) {
      // Restauration best-effort: on ignore silencieusement les prefs invalides.
    }
  }

  // On persiste seulement le chemin du projet et la map choisie, pas l'état
  // gameplay. La vraie sauvegarde gameplay reste dans le pipeline phase 9.
  Future<void> _persistLastSession() async {
    try {
      final file = File(_prefsFilePath());
      final payload = <String, dynamic>{
        'projectFilePath': _projectFilePath,
        'mapId': _selectedMapId,
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Persistance best-effort: ne bloque jamais le flux utilisateur.
    }
  }

  // Cette lecture du manifest sert uniquement à alimenter le host :
  // on récupère la liste des maps disponibles sans toucher au save system.
  Future<void> _loadProjectMapsFromManifest(
    String projectFilePath, {
    String? preferredMapId,
  }) async {
    try {
      final raw = await File(projectFilePath).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          _availableMaps = const [];
        });
        return;
      }
      final manifest = ProjectManifest.fromJson(decoded);
      final maps = List<ProjectMapEntry>.of(manifest.maps)
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          if (byOrder != 0) return byOrder;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      String? nextSelected = _selectedMapId;
      final preferred = preferredMapId?.trim();
      if (preferred != null &&
          preferred.isNotEmpty &&
          maps.any((m) => m.id == preferred)) {
        nextSelected = preferred;
      } else if (nextSelected == null ||
          nextSelected.isEmpty ||
          !maps.any((m) => m.id == nextSelected)) {
        nextSelected = maps.isEmpty ? null : maps.first.id;
      }
      if (!mounted) return;
      setState(() {
        _availableMaps = maps;
        _selectedMapId = nextSelected;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableMaps = const [];
      });
    }
  }

  // Le ticker force un refresh léger de l'overlay runtime pour afficher
  // les informations de debug et de save qui évoluent pendant la session.
  void _startRuntimeInfoTicker() {
    _runtimeInfoTicker?.cancel();
    _runtimeInfoTicker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (!mounted || _game == null) {
          return;
        }
        setState(() {});
      },
    );
  }

  void _stopRuntimeInfoTicker() {
    _runtimeInfoTicker?.cancel();
    _runtimeInfoTicker = null;
  }

  // Le host laisse l'utilisateur choisir explicitement un project.json.
  // Cela reste séparé de toute logique de menu in-game ou de save gameplay.
  Future<void> _pickProjectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      dialogTitle: 'Sélectionner project.json',
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _projectFilePath = path;
      _error = null;
    });
    await _loadProjectMapsFromManifest(path);
    await _persistLastSession();
  }

  // Ce chargement construit uniquement le bundle runtime et l'instance de jeu.
  // Il ne modifie pas la structure métier des saves.
  Future<void> _load() async {
    final projectFilePath = _projectFilePath;
    final mapId = (_selectedMapId ?? '').trim();

    if (projectFilePath.isEmpty) {
      setState(() => _error = 'Sélectionnez un fichier project.json.');
      return;
    }
    if (mapId.isEmpty) {
      setState(() => _error = 'Saisissez un identifiant de map.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _game = null;
    });

    try {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      // Phase A privilégie un vrai état joueur versionné quand le projet en
      // fournit un. Le seed de démo historique reste un fallback pratique pour
      // les projets génériques qui n'ont pas encore de save de lancement.
      final launchSaveData = await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFilePath,
      );
      final launchDemoSeed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: launchSaveData == null && _seedDemoPokemon,
        projectFilePath: projectFilePath,
      );
      if (!mounted) return;
      final nextGame = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: launchSaveData ??
            (launchDemoSeed == null
                ? null
                : SaveData(
                    saveId: kRuntimeDemoSeedSaveId,
                    currentMapId: mapId,
                    party: PlayerParty(
                      members: <PlayerPokemon>[
                        PlayerPokemon(
                          speciesId: launchDemoSeed.speciesId,
                          natureId: 'hardy',
                          abilityId: launchDemoSeed.abilityId,
                          level: launchDemoSeed.level,
                          knownMoveIds: launchDemoSeed.knownMoveIds,
                          currentHp: launchDemoSeed.currentHp,
                        ),
                      ],
                    ),
                    trainerProfile: const TrainerProfile(name: 'Demo'),
                  )),
      );
      setState(() {
        _game = nextGame;
        _saveLoadStatus = null;
        _saveLoadError = null;
      });
      nextGame.setCollisionOverlayVisible(_showCollisionOverlay);
      nextGame
          .setNpcCollisionDebugOverlayVisible(_showNpcCollisionDebugOverlay);
      nextGame.setFpsOverlayVisible(_showFpsOverlay);
      nextGame.setSurfingEnabled(_surfingEnabled);
      _startRuntimeInfoTicker();
      await _persistLastSession();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Retour au chargeur de projet.
  // On ne détruit pas de données persistées, on ferme juste la session runtime.
  void _reset() => setState(() {
        _stopRuntimeInfoTicker();
        _game = null;
        _error = null;
        _saveLoadStatus = null;
        _saveLoadError = null;
      });

  // Les boutons historiques du host réutilisent désormais le même flux que
  // l'écran "Sauvegarde" du menu in-game, pour garder une seule source de
  // vérité côté runtime.
  Future<void> _saveGame() async {
    await _performSaveRequest();
  }

  Future<void> _loadGame() async {
    await _performLoadRequest();
  }

  // Ce helper centralise la sauvegarde gameplay existante.
  // Il renvoie un résultat structuré pour que le menu in-game et l'overlay
  // historique affichent exactement le même statut utilisateur.
  Future<InGameMenuActionResult> _performSaveRequest() async {
    final game = _game;
    if (game == null || _saveLoadBusy) {
      return const InGameMenuActionResult(
        error: 'Sauvegarde indisponible',
      );
    }
    setState(() {
      _saveLoadBusy = true;
      _saveLoadError = null;
      _saveLoadStatus = null;
    });
    try {
      final saved = await game.saveGame();
      if (!mounted) {
        return const InGameMenuActionResult();
      }
      final info = game.saveLoadInfo;
      final status = saved
          ? 'Sauvegarde OK · ${info.mapId} (${info.playerX}, ${info.playerY})'
          : 'Sauvegarde impossible';
      setState(() {
        _saveLoadStatus = status;
      });
      return InGameMenuActionResult(status: status);
    } catch (e) {
      if (!mounted) {
        return const InGameMenuActionResult();
      }
      final error = 'Erreur sauvegarde: $e';
      setState(() {
        _saveLoadError = error;
      });
      return InGameMenuActionResult(error: error);
    } finally {
      if (mounted) {
        setState(() => _saveLoadBusy = false);
      }
    }
  }

  // Même principe pour le chargement :
  // on garde un seul chemin d'exécution pour l'overlay runtime et le menu.
  Future<InGameMenuActionResult> _performLoadRequest() async {
    final game = _game;
    if (game == null || _saveLoadBusy) {
      return const InGameMenuActionResult(
        error: 'Chargement indisponible',
      );
    }
    setState(() {
      _saveLoadBusy = true;
      _saveLoadError = null;
      _saveLoadStatus = null;
    });
    try {
      final loaded = await game.loadGame();
      if (!mounted) return const InGameMenuActionResult();
      if (!loaded) {
        const error = 'Aucune sauvegarde trouvée ou chargement impossible';
        setState(() {
          _saveLoadError = error;
        });
        return const InGameMenuActionResult(error: error);
      }
      final info = game.saveLoadInfo;
      final status =
          'Chargement OK · ${info.mapId} (${info.playerX}, ${info.playerY})';
      setState(() {
        _surfingEnabled = info.movementMode == MovementMode.surf.name;
        _saveLoadStatus = status;
      });
      return InGameMenuActionResult(status: status);
    } catch (e) {
      if (!mounted) return const InGameMenuActionResult();
      final error = 'Erreur chargement: $e';
      setState(() {
        _saveLoadError = error;
      });
      return InGameMenuActionResult(error: error);
    } finally {
      if (mounted) {
        setState(() => _saveLoadBusy = false);
      }
    }
  }

  // Le menu phase 10 vit dans le host runtime existant, sans nouveau framework.
  // On pousse simplement une route Flutter classique au-dessus du GameWidget.
  Future<void> _openInGameMenu() async {
    final game = _game;
    if (game == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return InGameMenuPage(
            gameStateSnapshotBuilder: () => game.gameStateSnapshot,
            pokedexLoader: () => loadRuntimePokedexEntries(
              projectFilePath: _projectFilePath,
            ),
            onSaveRequested: _performSaveRequest,
            onLoadRequested: _performLoadRequest,
            onCloseRequested: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Deux états d'interface seulement :
    // 1. soit une session runtime est active et on affiche le jeu ;
    // 2. soit on reste sur le chargeur de projet.
    final game = _game;
    if (game != null) {
      final info = game.saveLoadInfo;
      return Scaffold(
        appBar: AppBar(
          title: Text((_selectedMapId ?? '').trim()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _reset,
          ),
          actions: [
            // Le menu in-game est volontairement minimal :
            // un seul bouton ouvre les écrans lecture seule de la phase 10.
            IconButton(
              key: const Key('runtime-menu-button'),
              icon: const Icon(Icons.menu),
              onPressed: _openInGameMenu,
            ),
          ],
        ),
        body: Stack(
          children: [
            GameWidget(game: game),
            Positioned(
              top: 12,
              right: 12,
              child: Card(
                color: Colors.black.withValues(alpha: 0.55),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Collisions',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showCollisionOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _showCollisionOverlay = v);
                                    game.setCollisionOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'FPS',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showFpsOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _showFpsOverlay = v);
                                    game.setFpsOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Surf',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _surfingEnabled,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _surfingEnabled = v);
                                    game.setSurfingEnabled(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'NPC hitbox',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showNpcCollisionDebugOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(
                                      () => _showNpcCollisionDebugOverlay = v,
                                    );
                                    game.setNpcCollisionDebugOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Map: ${info.mapId}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Pos: (${info.playerX}, ${info.playerY})  Face: ${info.facing}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Mode: ${info.movementMode}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'FPS: ${game.currentFps.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.lightGreenAccent),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonal(
                            onPressed: _saveLoadBusy ? null : _saveGame,
                            child: const Text('Sauvegarder'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _saveLoadBusy ? null : _loadGame,
                            child: const Text('Charger'),
                          ),
                        ],
                      ),
                      if (_saveLoadStatus != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _saveLoadStatus!,
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ],
                      if (_saveLoadError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _saveLoadError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Playable Runtime Host')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Projet', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _ProjectFileField(
              path: _projectFilePath,
              onPick: _loading ? null : _pickProjectFile,
            ),
            const SizedBox(height: 20),
            if (_availableMaps.isEmpty)
              const TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Map',
                  hintText:
                      'Chargez un project.json valide pour lister les maps',
                  border: OutlineInputBorder(),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedMapId,
                decoration: const InputDecoration(
                  labelText: 'Map',
                  border: OutlineInputBorder(),
                ),
                items: _availableMaps
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.id,
                        child: Text('${entry.name} (${entry.id})'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedMapId = value);
                        _persistLastSession();
                      },
              ),
            const SizedBox(height: 16),
            RuntimeDemoSeedToggle(
              value: _seedDemoPokemon,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _seedDemoPokemon = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _load,
              child: Text(_loading ? 'Chargement…' : 'Lancer'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectFileField extends StatelessWidget {
  const _ProjectFileField({required this.path, required this.onPick});

  final String path;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                path.isEmpty ? 'Aucun fichier sélectionné' : path,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: path.isEmpty ? Theme.of(context).hintColor : null,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: onPick,
              child: const Text('Parcourir…'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
```

### `examples/playable_runtime_host/test/runtime_launch_save_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loadRuntimeHostLaunchSaveData', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('runtime_launch_save_');
      await File('${root.path}/project.json').writeAsString(
        jsonEncode(<String, dynamic>{
          'name': 'Phase A Host Test',
          'maps': const <Map<String, dynamic>>[],
          'tilesets': const <Map<String, dynamic>>[],
        }),
      );
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('returns null when no versioned launch save is present', () async {
      final save = await loadRuntimeHostLaunchSaveData(
        projectFilePath: '${root.path}/project.json',
      );

      expect(save, isNull);
    });

    test('loads a versioned launch save adjacent to project.json', () async {
      await File('${root.path}/$kRuntimeHostLaunchSaveFileName').writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'saveId': 'phase-a-save',
          'currentMapId': 'golden_field',
          'playerPosition': <String, int>{'x': 1, 'y': 1},
          'playerFacing': 'east',
          'party': <String, dynamic>{
            'members': <Map<String, dynamic>>[
              <String, dynamic>{
                'speciesId': 'sproutle',
                'natureId': 'bold',
                'abilityId': 'overgrow',
                'level': 7,
                'knownMoveIds': <String>['tackle', 'growl', 'vine_whip'],
                'currentHp': 23,
              },
            ],
          },
          'trainerProfile': <String, dynamic>{'name': 'Phase A Tester'},
        }),
      );

      final save = await loadRuntimeHostLaunchSaveData(
        projectFilePath: '${root.path}/project.json',
      );

      expect(save, isNotNull);
      expect(save!.saveId, equals('phase-a-save'));
      expect(save.currentMapId, equals('golden_field'));
      expect(save.playerPosition.x, equals(1));
      expect(save.playerPosition.y, equals(1));
      expect(save.party.members.single.speciesId, equals('sproutle'));
      expect(
        save.party.members.single.knownMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });
  });
}
```

### `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the versioned Phase A golden slice exposes a real launch save',
      () async {
    final projectFilePath =
        '${Directory.current.path}${Platform.pathSeparator}golden_battle_slice${Platform.pathSeparator}project.json';

    final save = await loadRuntimeHostLaunchSaveData(
      projectFilePath: projectFilePath,
    );

    expect(save, isNotNull);
    expect(save!.currentMapId, equals('golden_field'));
    expect(save.party.members, hasLength(2));
    expect(save.party.members.first.speciesId, equals('sproutle'));
  });
}
```

### `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_demo_party_seed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildRuntimeHostLaunchDemoPartySeed', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('runtime_host_seed_');
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('returns null when demo seed is disabled', () async {
      await _writeProjectFixture(root);

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: false,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNull);
    });

    test('builds a seeded save with one usable pokemon when enabled', () async {
      await _writeProjectFixture(root);

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      expect(seed!.speciesId, equals('bulbasaur'));
      expect(seed.level, equals(kRuntimeDemoSeedLevel));
      expect(seed.currentHp, equals(kRuntimeDemoSeedCurrentHp));
      expect(seed.abilityId, equals('overgrow'));
      expect(
        seed.knownMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });

    test('prefers Squirtle over Abra when both are available', () async {
      await _writeProjectFixture(
        root,
        includeAbra: true,
        includeSquirtle: true,
      );

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      expect(seed!.speciesId, equals('squirtle'));
      expect(seed.abilityId, equals('torrent'));
      expect(
        seed.knownMoveIds,
        equals(<String>['tackle', 'tail_whip', 'bubble', 'water_gun']),
      );
    });
  });
}

Future<void> _writeProjectFixture(
  Directory root, {
  bool includeAbra = false,
  bool includeSquirtle = false,
}) async {
  await File('${root.path}/project.json').writeAsString(
    jsonEncode(<String, dynamic>{
      'name': 'Runtime Host Seed Test',
      'maps': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'lab',
          'name': 'Lab',
          'relativePath': 'maps/lab.json',
        },
      ],
      'tilesets': const <Map<String, dynamic>>[],
      'pokemon': <String, dynamic>{
        'enabled': true,
        'speciesDir': 'data/pokemon/species',
        'learnsetsDir': 'data/pokemon/learnsets',
      },
    }),
  );

  await _writeJson(
    root,
    'data/pokemon/species/0001-bulbasaur.json',
    <String, dynamic>{
      'id': 'bulbasaur',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Bulbasaur'},
      'typing': <String, Object>{
        'types': <String>['grass', 'poison'],
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'refs': <String, String>{
        'learnset': 'bulbasaur',
        'evolution': 'bulbasaur',
        'media': 'bulbasaur',
      },
      'classification': <String, bool>{'isEnabledInProject': true},
    },
  );

  await _writeJson(
    root,
    'data/pokemon/learnsets/bulbasaur.json',
    <String, dynamic>{
      'speciesId': 'bulbasaur',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 5,
          'source': 'level_up',
          'versionGroup': 'demo',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'demo',
        },
      ],
    },
  );

  if (includeAbra) {
    await _writeJson(
      root,
      'data/pokemon/species/0063-abra.json',
      <String, dynamic>{
        'id': 'abra',
        'nationalDex': 63,
        'names': <String, String>{'en': 'Abra'},
        'typing': <String, Object>{
          'types': <String>['psychic'],
        },
        'abilities': <String, String>{'primary': 'synchronize'},
        'refs': <String, String>{
          'learnset': 'abra',
          'evolution': 'abra',
          'media': 'abra',
        },
        'classification': <String, bool>{'isEnabledInProject': true},
      },
    );

    await _writeJson(
      root,
      'data/pokemon/learnsets/abra.json',
      <String, dynamic>{
        'speciesId': 'abra',
        'startingMoves': <String>['teleport'],
        'relearnMoves': <String>['kinesis'],
        'levelUp': const <Map<String, Object>>[],
      },
    );
  }

  if (includeSquirtle) {
    await _writeJson(
      root,
      'data/pokemon/species/0007-squirtle.json',
      <String, dynamic>{
        'id': 'squirtle',
        'nationalDex': 7,
        'names': <String, String>{'en': 'Squirtle'},
        'typing': <String, Object>{
          'types': <String>['water'],
        },
        'abilities': <String, String>{'primary': 'torrent'},
        'refs': <String, String>{
          'learnset': 'squirtle',
          'evolution': 'squirtle',
          'media': 'squirtle',
        },
        'classification': <String, bool>{'isEnabledInProject': true},
      },
    );

    await _writeJson(
      root,
      'data/pokemon/learnsets/squirtle.json',
      <String, dynamic>{
        'speciesId': 'squirtle',
        'startingMoves': <String>['tackle'],
        'relearnMoves': <String>['tail_whip'],
        'levelUp': <Map<String, Object>>[
          <String, Object>{
            'moveId': 'bubble',
            'level': 4,
            'source': 'level_up',
            'versionGroup': 'demo',
          },
          <String, Object>{
            'moveId': 'water_gun',
            'level': 7,
            'source': 'level_up',
            'versionGroup': 'demo',
          },
        ],
      },
    );
  }
}

Future<void> _writeJson(
  Directory root,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File.fromUri(root.uri.resolve(relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}
```

### `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/seeds/pokemon_moves_bootstrap_seed.dart';

void main() {
  group('buildEmbeddedPokemonMovesBootstrapSeed', () {
    late Map<String, PokemonMove> movesById;

    setUp(() {
      final catalog = buildEmbeddedPokemonMovesBootstrapSeed();
      movesById = <String, PokemonMove>{
        for (final entry in catalog.entries)
          PokemonMove.fromJson(entry).id: PokemonMove.fromJson(entry),
      };
    });

    test(
        'keeps obviously unsupported switch and multi-hit seams out of supported bootstrap claims',
        () {
      expect(
        movesById['absorb']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['double_slap']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['u_turn']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['whirlwind']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
    });

    test('reflects the real BE8 and BE9 support that now exists locally', () {
      expect(
        movesById['solar_beam']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['trick_room']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredPartial),
      );
    });
  });
}
```

### `packages/map_editor/tool/export_embedded_pokemon_moves_bootstrap.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_editor/src/application/seeds/pokemon_moves_bootstrap_seed.dart';

/// Exporte le seed moves bootstrap embarqué vers stdout en JSON canonique.
///
/// Phase A a besoin d'une mesure reproductible de la vérité bootstrap :
/// - ce tooling ne lit aucun fichier généré ;
/// - il réutilise la vraie source embarquée de `map_editor` ;
/// - il laisse ensuite `map_runtime` auditer ce payload sans dépendre
///   directement du package editor.
void main() {
  const encoder = JsonEncoder.withIndent('  ');
  stdout.write(
    encoder.convert(
      buildEmbeddedPokemonMovesBootstrapSeed().toJson(),
    ),
  );
}
```

### `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`

```dart
import 'package:map_core/map_core.dart';

import '../models/pokemon_project_data_models.dart';

/// Version logique du seed embarqué des moves bootstrap.
///
/// On ne crée pas ici un nouveau schéma JSON ni un framework de seed générique.
/// La "version" utile pour ce lot est simplement :
/// - un entier local, facile à relire dans le code ;
/// - reporté aussi dans les notes du catalogue seedé ;
/// - assez simple pour tracer les évolutions sans rouvrir `PokemonDataMeta`.
const int embeddedPokemonMovesSeedVersion = 1;

/// Construit le catalogue `moves` embarqué pour le bootstrap projet.
///
/// Choix d'architecture volontaire :
/// - le seed est codé en Dart, pas en asset Flutter ;
/// - le bootstrap n'a donc ni dépendance `rootBundle`, ni dépendance réseau ;
/// - le seed passe par les vrais modèles canoniques `PokemonMove`, puis
///   sérialise `toJson()` ;
/// - la copie dans le projet reste un simple write JSON, sans génération live.
///
/// Pourquoi pas un asset JSON pour M4 :
/// - `map_editor` ne versionne pas déjà ce type de seed via `flutter/assets` ;
/// - le use case d'initialisation est aujourd'hui un seam applicatif simple,
///   testable sans plomberie Flutter ;
/// - ajouter une lecture d'asset ici ouvrirait une couche de packaging plus
///   large que nécessaire pour ce seul lot.
///
/// Pourquoi pas le catalogue Showdown complet :
/// - cela demanderait soit du tooling de génération versionné, soit un gros
///   artefact généré hors scope M4 ;
/// - M4 doit fixer le seam bootstrap, pas ouvrir un chantier "catalog dump".
///
/// Le seed reste donc volontairement :
/// - canonique ;
/// - offline ;
/// - substantiel ;
/// - mais encore curaté.
PokemonCatalogFile buildEmbeddedPokemonMovesBootstrapSeed() {
  return PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: const PokemonDataMeta(
      description: 'Move catalog for the local Pokemon project database.',
      sourcePriority: <String>['internal'],
      notes: <String>[
        'Embedded canonical move seed shipped with map_editor for offline bootstrap.',
        'Curated from Showdown-backed move data and versioned in the repository.',
        'bootstrap_seed_version:$embeddedPokemonMovesSeedVersion',
      ],
    ),
    entries: _embeddedPokemonMovesSeedEntries
        .map((move) => move.toJson())
        .toList(growable: false),
  );
}

/// Le seed n'essaie pas d'être tout Showdown.
///
/// On prend un sous-ensemble volontairement utile pour un projet frais :
/// - attaques simples courantes ;
/// - quelques statuts et boosts ;
/// - quelques moves plus "structurels" pour garder des entrées qui montrent
///   honnêtement les limites actuelles (`catalog_only` quand nécessaire).
final List<PokemonMove> _embeddedPokemonMovesSeedEntries = <PokemonMove>[
  ..._structuredSupportedSeedMoves,
  ..._catalogOnlySeedMoves,
];

/// Moves dont la structure utile est déjà correctement portée par le modèle.
///
/// Même si `map_battle` ne consomme pas encore tout cela, le modèle canonique
/// est capable de les décrire sans mensonge métier majeur.
final List<PokemonMove> _structuredSupportedSeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'absorb',
    showdownMoveId: 'absorb',
    name: 'Absorb',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 20,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.drain(numerator: 1, denominator: 2),
    ],
    shortDescription: 'User recovers 50% of the damage dealt.',
    description:
        'The user recovers 1/2 the HP lost by the target, rounded half up. '
        'If Big Root is held by the user, the HP recovered is 1.3x normal, '
        'rounded half down.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:drain',
    ],
  ),
  _showdownSeedMove(
    id: 'double_slap',
    showdownMoveId: 'doubleslap',
    name: 'Double Slap',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 15,
    accuracy: const PokemonMoveAccuracy.percent(value: 85),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.multiHit(minHits: 2, maxHits: 5),
    ],
    shortDescription: 'Hits 2-5 times in one turn.',
    description:
        'Hits two to five times. Has a 35% chance to hit two or three times '
        'and a 15% chance to hit four or five times. If one of the hits '
        'breaks the target\'s substitute, it will take damage for the '
        'remaining hits. If the user has the Skill Link Ability, this move '
        'will always hit five times.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:multi_hit',
    ],
  ),
  _showdownSeedMove(
    id: 'feint',
    showdownMoveId: 'feint',
    name: 'Feint',
    generation: 4,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 30,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    priority: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.breakProtect(),
    ],
    shortDescription: 'Nullifies Detect, Protect, and Quick/Wide Guard.',
    description: 'If this move is successful, it breaks through the target\'s '
        'Baneful Bunker, Detect, King\'s Shield, Protect, or Spiky Shield for '
        'this turn, allowing other Pokemon to attack the target normally. '
        'If the target\'s side is protected by Crafty Shield, Mat Block, '
        'Quick Guard, or Wide Guard, that protection is also broken for this '
        'turn and other Pokemon may attack the target\'s side normally.',
  ),
  _showdownSeedMove(
    id: 'growl',
    showdownMoveId: 'growl',
    name: 'Growl',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 40,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.sound,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Attack by 1.',
    description: 'Lowers the target\'s Attack by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'hyper_beam',
    showdownMoveId: 'hyperbeam',
    name: 'Hyper Beam',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    basePower: 150,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.recharge,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.requireRecharge(),
    ],
    shortDescription: 'User cannot move next turn.',
    description:
        'If this move is successful, the user must recharge on the following '
        'turn and cannot select a move.',
  ),
  _showdownSeedMove(
    id: 'leer',
    showdownMoveId: 'leer',
    name: 'Leer',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.defense,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Defense by 1.',
    description: 'Lowers the target\'s Defense by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'rain_dance',
    showdownMoveId: 'raindance',
    name: 'Rain Dance',
    generation: 2,
    type: 'water',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setWeather(weatherId: 'raindance'),
    ],
    shortDescription: 'For 5 turns, heavy rain powers Water moves.',
    description: 'For 5 turns, the weather becomes Rain Dance. The damage of '
        'Water-type attacks is multiplied by 1.5 and the damage of Fire-type '
        'attacks is multiplied by 0.5 during the effect. Lasts for 8 turns if '
        'the user is holding Damp Rock. Fails if the current weather is Rain '
        'Dance.',
  ),
  _showdownSeedMove(
    id: 'razor_leaf',
    showdownMoveId: 'razorleaf',
    name: 'Razor Leaf',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 55,
    accuracy: const PokemonMoveAccuracy.percent(value: 95),
    pp: 25,
    critRatio: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.slicing,
    ],
    shortDescription: 'High critical hit ratio. Hits adjacent foes.',
    description: 'Has a higher chance for a critical hit.',
  ),
  _showdownSeedMove(
    id: 'swords_dance',
    showdownMoveId: 'swordsdance',
    name: 'Swords Dance',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.dance,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        targetScope: PokemonMoveEffectTargetScope.self,
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: 2,
          ),
        ],
      ),
    ],
    shortDescription: 'Raises the user\'s Attack by 2.',
    description: 'Raises the user\'s Attack by 2 stages.',
  ),
  _showdownSeedMove(
    id: 'swift',
    showdownMoveId: 'swift',
    name: 'Swift',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 60,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'This move does not check accuracy. Hits foes.',
    description: 'This move does not check accuracy.',
  ),
  _showdownSeedMove(
    id: 'tackle',
    showdownMoveId: 'tackle',
    name: 'Tackle',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'thunder_wave',
    showdownMoveId: 'thunderwave',
    name: 'Thunder Wave',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(statusId: 'par'),
    ],
    shortDescription: 'Paralyzes the target.',
    description:
        'Paralyzes the target. This move does not ignore type immunity.',
  ),
  _showdownSeedMove(
    id: 'thunderbolt',
    showdownMoveId: 'thunderbolt',
    name: 'Thunderbolt',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.special,
    basePower: 90,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 15,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(chance: 10, statusId: 'par'),
    ],
    shortDescription: '10% chance to paralyze the target.',
    description: 'Has a 10% chance to paralyze the target.',
  ),
  _showdownSeedMove(
    id: 'u_turn',
    showdownMoveId: 'uturn',
    name: 'U-turn',
    generation: 4,
    type: 'bug',
    category: PokemonMoveCategory.physical,
    basePower: 70,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.selfSwitch(),
    ],
    shortDescription: 'User switches out after damaging the target.',
    description:
        'If this move is successful and the user has not fainted, the user '
        'switches out even if it is trapped and is replaced immediately by a '
        'selected party member. The user does not switch out if there are no '
        'unfainted party members, or if the target switched out using an '
        'Eject Button or through the effect of the Emergency Exit or Wimp Out '
        'Abilities.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:self_switch',
    ],
  ),
  _showdownSeedMove(
    id: 'vine_whip',
    showdownMoveId: 'vinewhip',
    name: 'Vine Whip',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    basePower: 45,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'whirlwind',
    showdownMoveId: 'whirlwind',
    name: 'Whirlwind',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    priority: -6,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.allyAnim,
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.wind,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.forceSwitch(),
    ],
    shortDescription: 'Forces the target to switch to a random ally.',
    description:
        'The target is forced to switch out and be replaced with a random '
        'unfainted ally. Fails if the target is the last unfainted Pokemon in '
        'its party, or if the target used Ingrain previously or has the '
        'Suction Cups Ability.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:force_switch',
    ],
  ),
];

/// Moves volontairement gardés dans le seed malgré un support encore limité.
///
/// On les garde parce qu'ils rendent le seed plus utile qu'une simple liste
/// d'attaques triviales, tout en exposant honnêtement les limites structurelles
/// actuelles via `catalog_only` et `unsupportedReasons`.
final List<PokemonMove> _catalogOnlySeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'stealth_rock',
    showdownMoveId: 'stealthrock',
    name: 'Stealth Rock',
    generation: 4,
    type: 'rock',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.foeSide,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mustPressure,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSideCondition(conditionId: 'stealthrock'),
    ],
    shortDescription: 'Hurts foes on switch-in. Factors Rock weakness.',
    description:
        'Sets up a hazard on the opposing side of the field, damaging each '
        'opposing Pokemon that switches in. Fails if the effect is already '
        'active on the opposing side. Foes lose 1/32, 1/16, 1/8, 1/4, or 1/2 '
        'of their maximum HP, rounded down, based on their weakness to the '
        'Rock type; 0.25x, 0.5x, neutral, 2x, or 4x, respectively. Can be '
        'removed from the opposing side if any Pokemon uses Tidy Up, or if '
        'any opposing Pokemon uses Mortal Spin, Rapid Spin, or Defog '
        'successfully, or is hit by Defog.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.onSideStart',
      'showdown_callback:condition.onSwitchIn',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.onSideStart',
      'condition.onSwitchIn',
    ],
  ),
  _showdownSeedMove(
    id: 'electric_terrain',
    showdownMoveId: 'electricterrain',
    name: 'Electric Terrain',
    generation: 6,
    type: 'electric',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.nonSky,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setTerrain(terrainId: 'electricterrain'),
    ],
    shortDescription: '5 turns. Grounded: +Electric power, can\'t sleep.',
    description:
        'For 5 turns, the terrain becomes Electric Terrain. During the '
        'effect, the power of Electric-type attacks made by grounded Pokemon '
        'is multiplied by 1.3 and grounded Pokemon cannot fall asleep; Pokemon '
        'already asleep do not wake up. Grounded Pokemon cannot become '
        'affected by Yawn or fall asleep from its effect. Camouflage '
        'transforms the user into an Electric type, Nature Power becomes '
        'Thunderbolt, and Secret Power has a 30% chance to cause paralysis. '
        'Fails if the current terrain is Electric Terrain.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onBasePower',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldStart',
      'showdown_callback:condition.onSetStatus',
      'showdown_callback:condition.onTryAddVolatile',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onBasePower',
      'condition.onFieldEnd',
      'condition.onFieldStart',
      'condition.onSetStatus',
      'condition.onTryAddVolatile',
    ],
  ),
  _showdownSeedMove(
    id: 'healing_wish',
    showdownMoveId: 'healingwish',
    name: 'Healing Wish',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSlotCondition(conditionId: 'healingwish'),
    ],
    shortDescription: 'User faints. Next hurt Pokemon is fully healed.',
    description:
        'The user faints, and if the Pokemon brought out to replace it does '
        'not have full HP or has a non-volatile status condition, its HP is '
        'fully restored along with having any non-volatile status condition '
        'cured. The replacement is sent out at the end of the turn, and the '
        'healing happens before hazards take effect. This effect continues '
        'until a Pokemon that meets either of these conditions switches in at '
        'the user\'s position or gets swapped into the position with Ally '
        'Switch. Fails if the user is the last unfainted Pokemon in its party.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.onSwap',
      'showdown_callback:condition.onSwitchIn',
      'showdown_callback:onTryHit',
      'unsupported_mechanic:condition',
      'unsupported_mechanic:selfdestruct',
    ],
    showdownHooksPresent: <String>[
      'condition.onSwap',
      'condition.onSwitchIn',
      'onTryHit',
    ],
  ),
  _showdownSeedMove(
    id: 'solar_beam',
    showdownMoveId: 'solarbeam',
    name: 'Solar Beam',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 120,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.charge,
      PokemonMoveFlag.failInstruct,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noSleepTalk,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.chargeThenStrike(chargeStateId: 'solar_charge'),
    ],
    shortDescription: 'Charges turn 1. Hits turn 2. No charge in sunlight.',
    description:
        'This attack charges on the first turn and executes on the second. '
        'Power is halved if the weather is Primordial Sea, Rain Dance, '
        'Sandstorm, or Snow and the user is not holding Utility Umbrella. If '
        'the user is holding a Power Herb or the weather is Desolate Land or '
        'Sunny Day, the move completes in one turn. If the user is holding '
        'Utility Umbrella and the weather is Desolate Land or Sunny Day, the '
        'move still requires a turn to charge.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:onBasePower',
      'showdown_callback:onTryMove',
      'unsupported_mechanic:weather_charge_shortcuts',
    ],
    showdownHooksPresent: <String>[
      'onBasePower',
      'onTryMove',
    ],
  ),
  _showdownSeedMove(
    id: 'trick_room',
    showdownMoveId: 'trickroom',
    name: 'Trick Room',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    priority: -7,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: 'trickroom'),
    ],
    shortDescription: 'Goes last. For 5 turns, turn order is reversed.',
    description:
        'For 5 turns, the Speed of every Pokemon is recalculated for the '
        'purposes of determining turn order. During the effect, each '
        'Pokemon\'s Speed is considered to be (10000 - its normal Speed), and '
        'if this value is greater than 8191, 8192 is subtracted from it. If '
        'this move is used during the effect, the effect ends.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
    unsupportedReasons: <String>[
      'unsupported_mechanic:turn_order_inversion',
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldRestart',
      'showdown_callback:condition.onFieldStart',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onFieldEnd',
      'condition.onFieldRestart',
      'condition.onFieldStart',
    ],
  ),
];

/// Helper unique pour garder le seed compact sans créer de framework.
///
/// `source` vaut volontairement `showdown` :
/// - il décrit l'origine du contenu métier ;
/// - pas le mode de chargement ;
/// - le bootstrap reste local/offline car ce seed est déjà versionné ici.
PokemonMove _showdownSeedMove({
  required String id,
  required String showdownMoveId,
  required String name,
  required int generation,
  required String type,
  required PokemonMoveCategory category,
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int basePower = 0,
  required PokemonMoveAccuracy accuracy,
  int pp = 0,
  bool noPpBoosts = false,
  int priority = 0,
  int critRatio = 1,
  List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[],
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  String shortDescription = '',
  String description = '',
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
  List<String> showdownHooksPresent = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: generation,
    source: 'showdown',
    type: type,
    category: category,
    target: target,
    basePower: basePower,
    accuracy: accuracy,
    pp: pp,
    noPpBoosts: noPpBoosts,
    priority: priority,
    critRatio: critRatio,
    flags: flags,
    effects: effects,
    shortDescription: shortDescription,
    description: description,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
    sourceRefs: PokemonMoveSourceRefs(
      showdownMoveId: showdownMoveId,
      showdownHooksPresent: showdownHooksPresent,
    ),
  ).normalized();
}
```

### `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/trainer_battle_request.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase A golden battle-ready slice smoke', () {
    const mapper = RuntimeBattleSetupMapper();

    test('the versioned golden slice starts a real wild battle', () async {
      final projectFilePath = _goldenProjectFilePath();
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'golden_field',
      );
      final save = await _loadGoldenSave(projectFilePath);
      final gameState = gameStateFromSaveData(save);

      final world = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: gameState.playerPosition,
        playerFacing: Direction.east,
        project: bundle.manifest,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.north),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: bundle.manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter;

      expect(encounter, isNotNull);
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter!,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: gameState,
        request: request,
      );
      final session = createBattleSession(setup);

      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, equals('sproutle'));
      expect(session.state.enemy.speciesId, equals('sparkitten'));
    });

    test('the versioned golden slice starts a real trainer battle', () async {
      final projectFilePath = _goldenProjectFilePath();
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'golden_field',
      );
      final save = await _loadGoldenSave(projectFilePath);
      final gameState = gameStateFromSaveData(save);

      final world = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: gameState.playerPosition,
        playerFacing: Direction.east,
        project: bundle.manifest,
      );
      final trainer = bundle.map.entities.firstWhere(
        (entity) => entity.id == 'npc_trainer_rookie',
      );
      final request = buildTrainerBattleRequestFromNpc(
        entity: trainer,
        manifest: bundle.manifest,
        world: world,
        createdAtEpochMs: 1,
      );

      expect(request, isNotNull);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: gameState,
        request: request!,
      );
      expect(setup.isTrainerBattle, isTrue);
      final session = createBattleSession(setup);

      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, equals('sproutle'));
      expect(session.state.enemy.speciesId, equals('sparkitten'));
    });
  });
}

String _goldenProjectFilePath() {
  // Le smoke doit consommer le vrai slice versionné du repo, pas une fixture
  // temporaire en /tmp. On résout donc explicitement le chemin vers l'example
  // host battleready pour que le test protège cette vérité produit.
  return p.normalize(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'examples',
      'playable_runtime_host',
      'golden_battle_slice',
      'project.json',
    ),
  );
}

Future<SaveData> _loadGoldenSave(String projectFilePath) async {
  final saveFile = File(
    p.join(
      File(projectFilePath).parent.path,
      'runtime_host_launch_save.json',
    ),
  );
  final decoded = jsonDecode(await saveFile.readAsString());
  return SaveData.fromJson(decoded as Map<String, dynamic>).normalized();
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  var _doubleIndex = 0;
  var _intIndex = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() {
    final value = nextDoubleValues[_doubleIndex % nextDoubleValues.length];
    _doubleIndex++;
    return value;
  }

  @override
  int nextInt(int max) {
    final value = nextIntValues[_intIndex % nextIntValues.length];
    _intIndex++;
    return max == 0 ? 0 : value % max;
  }
}
```

### `packages/map_runtime/tool/phase_a_battle_coverage.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/application/runtime_pokemon_learnset_loader.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final config = _CliConfig.fromArgs(args);
  const renderer = _PhaseACoverageRenderer(
    bridge: RuntimeBattleMoveBridge(),
    mapper: RuntimeBattleSetupMapper(),
    moveCatalogLoader: RuntimeMoveCatalogLoader(),
    combatantSeedBuilder: RuntimeBattleCombatantSeedBuilder(),
    speciesLoader: RuntimePokemonSpeciesLoader(),
    learnsetLoader: RuntimePokemonLearnsetLoader(),
  );

  final report = await renderer.render(
    bootstrapJsonPath: config.bootstrapJsonPath,
    projectFilePath: config.projectFilePath,
    launchSavePath: config.launchSavePath,
  );

  final outputFile = File(config.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(report);
  stdout.writeln('Phase A battle coverage written to ${outputFile.path}');
}

class _CliConfig {
  const _CliConfig({
    required this.bootstrapJsonPath,
    required this.projectFilePath,
    required this.launchSavePath,
    required this.outputPath,
  });

  final String bootstrapJsonPath;
  final String projectFilePath;
  final String launchSavePath;
  final String outputPath;

  static _CliConfig fromArgs(List<String> args) {
    String readFlag(String name) {
      final index = args.indexOf(name);
      if (index == -1 || index + 1 >= args.length) {
        throw ArgumentError('Missing required flag $name');
      }
      return args[index + 1];
    }

    return _CliConfig(
      bootstrapJsonPath: readFlag('--bootstrap-json'),
      projectFilePath: readFlag('--project'),
      launchSavePath: readFlag('--save'),
      outputPath: readFlag('--output'),
    );
  }
}

class _PhaseACoverageRenderer {
  const _PhaseACoverageRenderer({
    required this.bridge,
    required this.mapper,
    required this.moveCatalogLoader,
    required this.combatantSeedBuilder,
    required this.speciesLoader,
    required this.learnsetLoader,
  });

  final RuntimeBattleMoveBridge bridge;
  final RuntimeBattleSetupMapper mapper;
  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimeBattleCombatantSeedBuilder combatantSeedBuilder;
  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;

  Future<String> render({
    required String bootstrapJsonPath,
    required String projectFilePath,
    required String launchSavePath,
  }) async {
    final projectFile = File(projectFilePath);
    final projectRootDirectory = projectFile.parent.path;
    final normalizedProjectRoot = p.normalize(projectRootDirectory);
    final normalizedLaunchSaveParent =
        p.normalize(File(launchSavePath).parent.path);
    if (normalizedLaunchSaveParent != normalizedProjectRoot) {
      throw StateError(
        'Phase A coverage requires the launch save to live next to project.json.',
      );
    }
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    );
    final launchSave = SaveData.fromJson(
      jsonDecode(await File(launchSavePath).readAsString())
          as Map<String, dynamic>,
    ).normalized();
    final gameState = gameStateFromSaveData(launchSave);
    final bootstrapCatalogJson =
        jsonDecode(await File(bootstrapJsonPath).readAsString())
            as Map<String, dynamic>;
    final bootstrapEntries =
        (bootstrapCatalogJson['entries'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .toList(growable: false);
    final runtimeMovesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: manifest.pokemon,
    );

    final authoredMaps = await _loadProjectMaps(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
    );
    final bootstrapMoves = bootstrapEntries
        .map(PokemonMove.fromJson)
        .toList(growable: false)
      ..sort((left, right) => left.id.compareTo(right.id));

    final bootstrapMoveRows = bootstrapMoves
        .map(
          (move) => _classifyMoveBridgeability(
            move: move,
            sourceLabel: 'bootstrap',
            occurrenceCount: 1,
            sources: const <String>['bootstrap'],
          ),
        )
        .toList(growable: false);

    final sliceMoveUsages = await _collectGoldenSliceMoveUsages(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      launchSave: launchSave,
      authoredMaps: authoredMaps,
    );
    final sliceMoveRows = sliceMoveUsages.values
        .map(
          (usage) => _classifyMoveBridgeability(
            move: usage.move,
            sourceLabel: 'golden_slice',
            occurrenceCount: usage.occurrenceCount,
            sources: usage.sources,
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.moveId.compareTo(right.moveId));

    final playerSelection = mapper.selectPlayerBattleLineup(gameState.party);
    final playerSeedRows = await _buildPlayerSeedRows(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      runtimeMovesCatalog: runtimeMovesCatalog,
      gameState: gameState,
      playerSelection: playerSelection,
    );
    final trainerSeedRows = await _buildTrainerSeedRows(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      runtimeMovesCatalog: runtimeMovesCatalog,
    );
    final wildSeedRows = await _buildWildSeedRows(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      runtimeMovesCatalog: runtimeMovesCatalog,
      authoredMaps: authoredMaps,
    );

    final battleRows = await _buildBattleRows(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      gameState: gameState,
      authoredMaps: authoredMaps,
    );

    final bootstrapBridgeableCount =
        bootstrapMoveRows.where((row) => row.bridgeable).length;
    final sliceBridgeableCount =
        sliceMoveRows.where((row) => row.bridgeable).length;
    final playerBridgeableCount =
        playerSeedRows.where((row) => row.status == 'bridgeable').length;
    final trainerBridgeableCount =
        trainerSeedRows.where((row) => row.status == 'bridgeable').length;
    final wildBridgeableCount =
        wildSeedRows.where((row) => row.status == 'bridgeable').length;
    final wildBattleStartableCount =
        battleRows.where((row) => row.kind == 'wild' && row.startable).length;
    final trainerBattleStartableCount = battleRows
        .where((row) => row.kind == 'trainer' && row.startable)
        .length;

    return <String>[
      '# Phase A Battle Coverage',
      '',
      '## Executive Summary',
      '',
      '- Bootstrap moves bridgeables: '
          '$bootstrapBridgeableCount / ${bootstrapMoveRows.length}',
      '- Golden slice moves bridgeables: '
          '$sliceBridgeableCount / ${sliceMoveRows.length}',
      '- Player seeds bridgeables: '
          '$playerBridgeableCount / ${playerSeedRows.length}',
      '- Trainer seeds bridgeables: '
          '$trainerBridgeableCount / ${trainerSeedRows.length}',
      '- Wild seeds bridgeables: '
          '$wildBridgeableCount / ${wildSeedRows.length}',
      '- Wild battles startable: '
          '$wildBattleStartableCount / ${battleRows.where((row) => row.kind == 'wild').length}',
      '- Trainer battles startable: '
          '$trainerBattleStartableCount / ${battleRows.where((row) => row.kind == 'trainer').length}',
      '',
      '## Bootstrap Move Coverage',
      '',
      _markdownTable(
        const <String>[
          'moveId',
          'engineSupportLevel',
          'bridgeable',
          'bridgeLimit',
          'unsupportedReasons',
        ],
        bootstrapMoveRows
            .map(
              (row) => <String>[
                row.moveId,
                row.engineSupportLevel,
                row.bridgeable ? 'yes' : 'no',
                row.bridgeLimit,
                row.unsupportedReasons,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Golden Slice Move Coverage',
      '',
      _markdownTable(
        const <String>[
          'moveId',
          'occurrences',
          'sources',
          'engineSupportLevel',
          'bridgeable',
          'bridgeLimit',
          'unsupportedReasons',
        ],
        sliceMoveRows
            .map(
              (row) => <String>[
                row.moveId,
                row.occurrenceCount.toString(),
                row.sources.join(', '),
                row.engineSupportLevel,
                row.bridgeable ? 'yes' : 'no',
                row.bridgeLimit,
                row.unsupportedReasons,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Player Seed Coverage',
      '',
      _markdownTable(
        const <String>[
          'label',
          'candidateMoveIds',
          'builtMoveIds',
          'status',
          'failure',
        ],
        playerSeedRows
            .map(
              (row) => <String>[
                row.label,
                row.candidateMoveIds.join(', '),
                row.builtMoveIds.join(', '),
                row.status,
                row.failure,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Trainer Seed Coverage',
      '',
      _markdownTable(
        const <String>[
          'label',
          'candidateMoveIds',
          'builtMoveIds',
          'status',
          'failure',
        ],
        trainerSeedRows
            .map(
              (row) => <String>[
                row.label,
                row.candidateMoveIds.join(', '),
                row.builtMoveIds.join(', '),
                row.status,
                row.failure,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Wild Seed Coverage',
      '',
      _markdownTable(
        const <String>[
          'label',
          'candidateMoveIds',
          'builtMoveIds',
          'status',
          'failure',
        ],
        wildSeedRows
            .map(
              (row) => <String>[
                row.label,
                row.candidateMoveIds.join(', '),
                row.builtMoveIds.join(', '),
                row.status,
                row.failure,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Authored Battle Startability',
      '',
      _markdownTable(
        const <String>[
          'kind',
          'label',
          'startable',
          'reason',
        ],
        battleRows
            .map(
              (row) => <String>[
                row.kind,
                row.label,
                row.startable ? 'yes' : 'no',
                row.reason,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Notes',
      '',
      '- Wild battle opportunities are measured at the authored '
          '`zone -> table entry` level.',
      '- Trainer battles are measured at the authored NPC trainer hook level.',
      '- Player truth comes from the versioned launch save, not from test-only '
          'fixtures.',
      '- This report is generated locally from the real golden slice and the '
          'real embedded bootstrap seed.',
      '',
    ].join('\n');
  }

  Future<Map<String, MapData>> _loadProjectMaps({
    required String projectRootDirectory,
    required ProjectManifest manifest,
  }) async {
    final maps = <String, MapData>{};
    for (final entry in manifest.maps) {
      final file = File(p.join(projectRootDirectory, entry.relativePath));
      maps[entry.id] = MapData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    }
    return maps;
  }

  _MoveCoverageRow _classifyMoveBridgeability({
    required PokemonMove move,
    required String sourceLabel,
    required int occurrenceCount,
    required List<String> sources,
  }) {
    try {
      bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Audit $sourceLabel',
      );
      return _MoveCoverageRow(
        moveId: move.id,
        occurrenceCount: occurrenceCount,
        sources: sources,
        engineSupportLevel: move.engineSupportLevel.name,
        bridgeable: true,
        bridgeLimit: '',
        unsupportedReasons: move.unsupportedReasons.join(', '),
      );
    } on RuntimeBattleSetupException catch (error) {
      return _MoveCoverageRow(
        moveId: move.id,
        occurrenceCount: occurrenceCount,
        sources: sources,
        engineSupportLevel: move.engineSupportLevel.name,
        bridgeable: false,
        bridgeLimit: _extractBridgeLimit(error.debugDetails),
        unsupportedReasons: move.unsupportedReasons.join(', '),
      );
    }
  }

  Future<Map<String, _SliceMoveUsage>> _collectGoldenSliceMoveUsages({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required SaveData launchSave,
    required Map<String, MapData> authoredMaps,
  }) async {
    final moveCatalog = await moveCatalogLoader.load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: manifest.pokemon,
    );
    final usages = <String, _SliceMoveUsage>{};

    void addUsage({
      required String moveId,
      required String source,
    }) {
      final move = moveCatalog.lookup(moveId);
      if (move == null) {
        return;
      }
      final current = usages[moveId];
      usages[moveId] = current == null
          ? _SliceMoveUsage(
              move: move,
              occurrenceCount: 1,
              sources: <String>[source],
            )
          : current.addSource(source);
    }

    for (var i = 0; i < launchSave.party.members.length; i++) {
      final member = launchSave.party.members[i];
      final candidateMoveIds = await _derivePlayerCandidateMoveIds(
        projectRootDirectory: projectRootDirectory,
        manifest: manifest,
        playerPokemon: member,
      );
      for (final moveId in candidateMoveIds) {
        addUsage(
          moveId: moveId,
          source: 'player_party[$i]',
        );
      }
    }

    for (final trainer in manifest.trainers) {
      for (var i = 0; i < trainer.team.length; i++) {
        final teamMember = trainer.team[i];
        final candidateMoveIds = await _deriveTrainerCandidateMoveIds(
          projectRootDirectory: projectRootDirectory,
          manifest: manifest,
          teamMember: teamMember,
        );
        for (final moveId in candidateMoveIds) {
          addUsage(
            moveId: moveId,
            source: 'trainer:${trainer.id}[$i]',
          );
        }
      }
    }

    for (final mapEntry in authoredMaps.entries) {
      final map = mapEntry.value;
      for (final zone in _authoredEncounterZones(map)) {
        final tableId = (zone.encounter?.encounterTableId ?? '').trim();
        final table = manifest.encounterTables.firstWhere(
          (candidate) => candidate.id == tableId,
        );
        for (var i = 0; i < table.entries.length; i++) {
          final entry = table.entries[i];
          final candidateMoveIds = await _deriveWildCandidateMoveIds(
            projectRootDirectory: projectRootDirectory,
            manifest: manifest,
            speciesId: entry.speciesId,
            level: entry.minLevel,
          );
          for (final moveId in candidateMoveIds) {
            addUsage(
              moveId: moveId,
              source: 'wild:${map.id}:${zone.id}[$i]',
            );
          }
        }
      }
    }

    return usages;
  }

  Future<List<_SeedCoverageRow>> _buildPlayerSeedRows({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required RuntimeMoveCatalog runtimeMovesCatalog,
    required GameState gameState,
    required RuntimePlayerBattleLineupSelection playerSelection,
  }) async {
    final rows = <_SeedCoverageRow>[];
    for (var i = 0; i < gameState.party.members.length; i++) {
      final playerPokemon = gameState.party.members[i];
      final candidateMoveIds = await _derivePlayerCandidateMoveIds(
        projectRootDirectory: projectRootDirectory,
        manifest: manifest,
        playerPokemon: playerPokemon,
      );
      final label = i == playerSelection.activeIndex
          ? 'player_party[$i]:active:${playerPokemon.speciesId}'
          : playerSelection.reserveIndices.contains(i)
              ? 'player_party[$i]:reserve:${playerPokemon.speciesId}'
              : 'player_party[$i]:inactive:${playerPokemon.speciesId}';

      try {
        final seed = await combatantSeedBuilder.buildPlayerCombatantSeed(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: manifest.pokemon,
          movesCatalog: runtimeMovesCatalog,
          playerPokemon: playerPokemon,
          combatantLabel: label,
        );
        rows.add(
          _SeedCoverageRow(
            label: label,
            candidateMoveIds: candidateMoveIds,
            builtMoveIds:
                seed.moves.map((move) => move.id).toList(growable: false),
            status: 'bridgeable',
            failure: '',
          ),
        );
      } on RuntimeBattleSetupException catch (error) {
        rows.add(
          _SeedCoverageRow(
            label: label,
            candidateMoveIds: candidateMoveIds,
            builtMoveIds: const <String>[],
            status: 'blocked',
            failure: _formatFailure(error),
          ),
        );
      }
    }
    return rows;
  }

  Future<List<_SeedCoverageRow>> _buildTrainerSeedRows({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required RuntimeMoveCatalog runtimeMovesCatalog,
  }) async {
    final rows = <_SeedCoverageRow>[];
    for (final trainer in manifest.trainers) {
      for (var i = 0; i < trainer.team.length; i++) {
        final teamMember = trainer.team[i];
        final candidateMoveIds = await _deriveTrainerCandidateMoveIds(
          projectRootDirectory: projectRootDirectory,
          manifest: manifest,
          teamMember: teamMember,
        );
        final label = 'trainer:${trainer.id}[$i]:${teamMember.speciesId}';
        try {
          final seed = await combatantSeedBuilder.buildTrainerCombatantSeed(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: manifest.pokemon,
            movesCatalog: runtimeMovesCatalog,
            teamMember: teamMember,
            trainerName: trainer.name,
          );
          rows.add(
            _SeedCoverageRow(
              label: label,
              candidateMoveIds: candidateMoveIds,
              builtMoveIds:
                  seed.moves.map((move) => move.id).toList(growable: false),
              status: 'bridgeable',
              failure: '',
            ),
          );
        } on RuntimeBattleSetupException catch (error) {
          rows.add(
            _SeedCoverageRow(
              label: label,
              candidateMoveIds: candidateMoveIds,
              builtMoveIds: const <String>[],
              status: 'blocked',
              failure: _formatFailure(error),
            ),
          );
        }
      }
    }
    return rows;
  }

  Future<List<_SeedCoverageRow>> _buildWildSeedRows({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required RuntimeMoveCatalog runtimeMovesCatalog,
    required Map<String, MapData> authoredMaps,
  }) async {
    final rows = <_SeedCoverageRow>[];
    for (final mapEntry in authoredMaps.entries) {
      final map = mapEntry.value;
      for (final zone in _authoredEncounterZones(map)) {
        final table = manifest.encounterTables.firstWhere(
          (candidate) =>
              candidate.id == (zone.encounter?.encounterTableId ?? '').trim(),
        );
        for (var i = 0; i < table.entries.length; i++) {
          final entry = table.entries[i];
          final candidateMoveIds = await _deriveWildCandidateMoveIds(
            projectRootDirectory: projectRootDirectory,
            manifest: manifest,
            speciesId: entry.speciesId,
            level: entry.minLevel,
          );
          final label =
              'wild:${map.id}:${zone.id}[$i]:${entry.speciesId}@${entry.minLevel}-${entry.maxLevel}';
          try {
            final seed = await combatantSeedBuilder.buildWildCombatantSeed(
              projectRootDirectory: projectRootDirectory,
              pokemonConfig: manifest.pokemon,
              movesCatalog: runtimeMovesCatalog,
              request: WildBattleStartRequest(
                requestId: 'audit-wild-$i',
                createdAtEpochMs: 1,
                returnContext: OverworldReturnContext(
                  mapId: map.id,
                  playerPos: zone.area.pos,
                  playerFacing: Direction.south,
                ),
                mapId: map.id,
                zoneId: zone.id,
                tableId: table.id,
                encounterKind: zone.encounter!.encounterKind,
                speciesId: entry.speciesId,
                level: entry.minLevel,
                minLevel: entry.minLevel,
                maxLevel: entry.maxLevel,
                weight: entry.weight,
                playerPos: zone.area.pos,
              ),
            );
            rows.add(
              _SeedCoverageRow(
                label: label,
                candidateMoveIds: candidateMoveIds,
                builtMoveIds:
                    seed.moves.map((move) => move.id).toList(growable: false),
                status: 'bridgeable',
                failure: '',
              ),
            );
          } on RuntimeBattleSetupException catch (error) {
            rows.add(
              _SeedCoverageRow(
                label: label,
                candidateMoveIds: candidateMoveIds,
                builtMoveIds: const <String>[],
                status: 'blocked',
                failure: _formatFailure(error),
              ),
            );
          }
        }
      }
    }
    return rows;
  }

  Future<List<_BattleCoverageRow>> _buildBattleRows({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required GameState gameState,
    required Map<String, MapData> authoredMaps,
  }) async {
    final rows = <_BattleCoverageRow>[];
    for (final mapEntry in authoredMaps.entries) {
      final map = mapEntry.value;
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(projectRootDirectory, 'project.json'),
        mapId: map.id,
      );

      for (final zone in _authoredEncounterZones(map)) {
        final table = manifest.encounterTables.firstWhere(
          (candidate) =>
              candidate.id == (zone.encounter?.encounterTableId ?? '').trim(),
        );
        for (var i = 0; i < table.entries.length; i++) {
          final entry = table.entries[i];
          final label =
              'wild:${map.id}:${zone.id}[$i]:${entry.speciesId}@${entry.minLevel}-${entry.maxLevel}';
          try {
            await mapper.map(
              bundle: bundle,
              gameState: gameState,
              request: WildBattleStartRequest(
                requestId: 'audit-wild-start-$i',
                createdAtEpochMs: 1,
                returnContext: OverworldReturnContext(
                  mapId: map.id,
                  playerPos: zone.area.pos,
                  playerFacing: Direction.south,
                ),
                mapId: map.id,
                zoneId: zone.id,
                tableId: table.id,
                encounterKind: zone.encounter!.encounterKind,
                speciesId: entry.speciesId,
                level: entry.minLevel,
                minLevel: entry.minLevel,
                maxLevel: entry.maxLevel,
                weight: entry.weight,
                playerPos: zone.area.pos,
              ),
            );
            rows.add(
              const _BattleCoverageRow(
                kind: 'wild',
                label: '',
                startable: true,
                reason: '',
              ).copyWith(label: label),
            );
          } on RuntimeBattleSetupException catch (error) {
            rows.add(
              _BattleCoverageRow(
                kind: 'wild',
                label: label,
                startable: false,
                reason: _formatFailure(error),
              ),
            );
          }
        }
      }

      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
      );
      for (final entity in map.entities.where(
        (entity) => entity.kind == MapEntityKind.npc,
      )) {
        final trainerId = entity.npc?.trainerId?.trim();
        if (trainerId == null || trainerId.isEmpty) {
          continue;
        }
        final label = 'trainer:${map.id}:${entity.id}:$trainerId';
        try {
          await mapper.map(
            bundle: bundle,
            gameState: gameState,
            request: TrainerBattleStartRequest(
              requestId: 'audit-trainer-$trainerId',
              createdAtEpochMs: 1,
              returnContext: OverworldReturnContext(
                mapId: map.id,
                playerPos: world.player.pos,
                playerFacing: world.player.facing,
              ),
              trainerId: trainerId,
              npcEntityId: entity.id,
              mapId: map.id,
              playerPos: world.player.pos,
            ),
          );
          rows.add(
            _BattleCoverageRow(
              kind: 'trainer',
              label: label,
              startable: true,
              reason: '',
            ),
          );
        } on RuntimeBattleSetupException catch (error) {
          rows.add(
            _BattleCoverageRow(
              kind: 'trainer',
              label: label,
              startable: false,
              reason: _formatFailure(error),
            ),
          );
        }
      }
    }
    return rows;
  }

  Future<List<String>> _derivePlayerCandidateMoveIds({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required PlayerPokemon playerPokemon,
  }) async {
    if (playerPokemon.knownMoveIds.isNotEmpty) {
      return _normalizeUniqueIdsPreserveOrder(playerPokemon.knownMoveIds)
          .take(4)
          .toList(growable: false);
    }
    return _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      speciesId: playerPokemon.speciesId,
      level: playerPokemon.level,
    );
  }

  Future<List<String>> _deriveTrainerCandidateMoveIds({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required ProjectTrainerPokemonEntry teamMember,
  }) async {
    if (teamMember.moves.isNotEmpty) {
      return _normalizeUniqueIdsPreserveOrder(teamMember.moves)
          .take(4)
          .toList(growable: false);
    }
    return _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      speciesId: teamMember.speciesId,
      level: teamMember.level,
    );
  }

  Future<List<String>> _deriveWildCandidateMoveIds({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required String speciesId,
    required int level,
  }) {
    return _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      speciesId: speciesId,
      level: level,
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required String speciesId,
    required int level,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: manifest.pokemon,
      speciesId: speciesId,
    );
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: manifest.pokemon,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );
    final ordered = <String>[
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp
          .where((entry) => entry.level <= level)
          .map((entry) => entry.moveId),
    ];
    final unique = _normalizeUniqueIdsPreserveOrder(ordered);
    if (unique.length <= 4) {
      return unique;
    }
    return unique.sublist(unique.length - 4);
  }

  List<String> _normalizeUniqueIdsPreserveOrder(List<String> rawIds) {
    final out = <String>[];
    final seen = <String>{};
    for (final rawId in rawIds) {
      final normalizedId = rawId.trim();
      if (normalizedId.isEmpty || !seen.add(normalizedId)) {
        continue;
      }
      out.add(normalizedId);
    }
    return List<String>.unmodifiable(out);
  }

  String _extractBridgeLimit(String? debugDetails) {
    if (debugDetails == null || debugDetails.isEmpty) {
      return '';
    }
    final match = RegExp(r'bridgeLimit=([^,]+)').firstMatch(debugDetails);
    return match == null ? '' : match.group(1)!;
  }

  String _formatFailure(RuntimeBattleSetupException error) {
    if (error.debugDetails == null || error.debugDetails!.trim().isEmpty) {
      return error.message;
    }
    return '${error.message} (${error.debugDetails})';
  }

  String _markdownTable(List<String> headers, List<List<String>> rows) {
    String escape(String value) {
      return value.replaceAll('|', '\\|').replaceAll('\n', '<br>');
    }

    final buffer = StringBuffer()
      ..writeln('| ${headers.map(escape).join(' | ')} |')
      ..writeln('| ${headers.map((_) => '---').join(' | ')} |');
    for (final row in rows) {
      buffer.writeln('| ${row.map(escape).join(' | ')} |');
    }
    return buffer.toString().trimRight();
  }

  Iterable<MapGameplayZone> _authoredEncounterZones(MapData map) sync* {
    for (final zone in map.gameplayZones) {
      final tableId = (zone.encounter?.encounterTableId ?? '').trim();
      if (zone.kind != GameplayZoneKind.encounter || tableId.isEmpty) {
        continue;
      }
      yield zone;
    }
  }
}

class _SliceMoveUsage {
  const _SliceMoveUsage({
    required this.move,
    required this.occurrenceCount,
    required this.sources,
  });

  final PokemonMove move;
  final int occurrenceCount;
  final List<String> sources;

  _SliceMoveUsage addSource(String source) {
    final nextSources = List<String>.from(sources);
    if (!nextSources.contains(source)) {
      nextSources.add(source);
    }
    return _SliceMoveUsage(
      move: move,
      occurrenceCount: occurrenceCount + 1,
      sources: List<String>.unmodifiable(nextSources),
    );
  }
}

class _MoveCoverageRow {
  const _MoveCoverageRow({
    required this.moveId,
    required this.occurrenceCount,
    required this.sources,
    required this.engineSupportLevel,
    required this.bridgeable,
    required this.bridgeLimit,
    required this.unsupportedReasons,
  });

  final String moveId;
  final int occurrenceCount;
  final List<String> sources;
  final String engineSupportLevel;
  final bool bridgeable;
  final String bridgeLimit;
  final String unsupportedReasons;
}

class _SeedCoverageRow {
  const _SeedCoverageRow({
    required this.label,
    required this.candidateMoveIds,
    required this.builtMoveIds,
    required this.status,
    required this.failure,
  });

  final String label;
  final List<String> candidateMoveIds;
  final List<String> builtMoveIds;
  final String status;
  final String failure;
}

class _BattleCoverageRow {
  const _BattleCoverageRow({
    required this.kind,
    required this.label,
    required this.startable,
    required this.reason,
  });

  final String kind;
  final String label;
  final bool startable;
  final String reason;

  _BattleCoverageRow copyWith({
    String? kind,
    String? label,
    bool? startable,
    String? reason,
  }) {
    return _BattleCoverageRow(
      kind: kind ?? this.kind,
      label: label ?? this.label,
      startable: startable ?? this.startable,
      reason: reason ?? this.reason,
    );
  }
}
```

### `scripts/generate_phase_a_battle_coverage.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Wrapper Phase A volontairement simple :
# - exporte d'abord la vraie vérité bootstrap depuis map_editor ;
# - puis demande à map_runtime de mesurer le vrai golden slice versionné ;
# - écrit enfin le report markdown sous reports/.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_JSON="$(mktemp)"
trap 'rm -f "$BOOTSTRAP_JSON"' EXIT

(
  cd "$REPO_ROOT/packages/map_editor"
  /opt/homebrew/bin/flutter pub run tool/export_embedded_pokemon_moves_bootstrap.dart > "$BOOTSTRAP_JSON"
)

(
  cd "$REPO_ROOT/packages/map_runtime"
  /opt/homebrew/bin/flutter pub run tool/phase_a_battle_coverage.dart \
    --bootstrap-json "$BOOTSTRAP_JSON" \
    --project "$REPO_ROOT/examples/playable_runtime_host/golden_battle_slice/project.json" \
    --save "$REPO_ROOT/examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json" \
    --output "$REPO_ROOT/reports/phase-a-battle-coverage.md"
)

echo "Coverage report written to $REPO_ROOT/reports/phase-a-battle-coverage.md"
```

### `reports/phase-a-battle-coverage.md`

```md
# Phase A Battle Coverage

## Executive Summary

- Bootstrap moves bridgeables: 13 / 21
- Golden slice moves bridgeables: 3 / 3
- Player seeds bridgeables: 2 / 2
- Trainer seeds bridgeables: 1 / 1
- Wild seeds bridgeables: 1 / 1
- Wild battles startable: 1 / 1
- Trainer battles startable: 1 / 1

## Bootstrap Move Coverage

| moveId | engineSupportLevel | bridgeable | bridgeLimit | unsupportedReasons |
| --- | --- | --- | --- | --- |
| absorb | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:drain |
| double_slap | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:multi_hit |
| electric_terrain | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.durationCallback, showdown_callback:condition.onBasePower, showdown_callback:condition.onFieldEnd, showdown_callback:condition.onFieldStart, showdown_callback:condition.onSetStatus, showdown_callback:condition.onTryAddVolatile, unsupported_mechanic:condition |
| feint | structuredSupported | yes |  |  |
| growl | structuredSupported | yes |  |  |
| healing_wish | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.onSwap, showdown_callback:condition.onSwitchIn, showdown_callback:onTryHit, unsupported_mechanic:condition, unsupported_mechanic:selfdestruct |
| hyper_beam | structuredSupported | yes |  |  |
| leer | structuredSupported | yes |  |  |
| rain_dance | structuredSupported | yes |  |  |
| razor_leaf | structuredSupported | yes |  |  |
| solar_beam | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:onBasePower, showdown_callback:onTryMove, unsupported_mechanic:weather_charge_shortcuts |
| stealth_rock | catalogOnly | no | engine_support_level_not_bridgeable | showdown_callback:condition.onSideStart, showdown_callback:condition.onSwitchIn, unsupported_mechanic:condition |
| swift | structuredSupported | yes |  |  |
| swords_dance | structuredSupported | yes |  |  |
| tackle | structuredSupported | yes |  |  |
| thunder_wave | structuredSupported | yes |  |  |
| thunderbolt | structuredSupported | yes |  |  |
| trick_room | structuredPartial | yes |  | unsupported_mechanic:turn_order_inversion, showdown_callback:condition.durationCallback, showdown_callback:condition.onFieldEnd, showdown_callback:condition.onFieldRestart, showdown_callback:condition.onFieldStart, unsupported_mechanic:condition |
| u_turn | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:self_switch |
| vine_whip | structuredSupported | yes |  |  |
| whirlwind | catalogOnly | no | engine_support_level_not_bridgeable | unsupported_effect_kind:force_switch |

## Golden Slice Move Coverage

| moveId | occurrences | sources | engineSupportLevel | bridgeable | bridgeLimit | unsupportedReasons |
| --- | --- | --- | --- | --- | --- | --- |
| growl | 4 | player_party[0], player_party[1], trainer:trainer_rookie[0], wild:golden_field:golden_grass_zone[0] | structuredSupported | yes |  |  |
| tackle | 4 | player_party[0], player_party[1], trainer:trainer_rookie[0], wild:golden_field:golden_grass_zone[0] | structuredSupported | yes |  |  |
| vine_whip | 1 | player_party[0] | structuredSupported | yes |  |  |

## Player Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| player_party[0]:active:sproutle | tackle, growl, vine_whip | tackle, growl, vine_whip | bridgeable |  |
| player_party[1]:reserve:sparkitten | tackle, growl | tackle, growl | bridgeable |  |

## Trainer Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| trainer:trainer_rookie[0]:sparkitten | tackle, growl | tackle, growl | bridgeable |  |

## Wild Seed Coverage

| label | candidateMoveIds | builtMoveIds | status | failure |
| --- | --- | --- | --- | --- |
| wild:golden_field:golden_grass_zone[0]:sparkitten@6-6 | tackle, growl | tackle, growl | bridgeable |  |

## Authored Battle Startability

| kind | label | startable | reason |
| --- | --- | --- | --- |
| wild | wild:golden_field:golden_grass_zone[0]:sparkitten@6-6 | yes |  |
| trainer | trainer:golden_field:npc_trainer_rookie:trainer_rookie | yes |  |

## Notes

- Wild battle opportunities are measured at the authored `zone -> table entry` level.
- Trainer battles are measured at the authored NPC trainer hook level.
- Player truth comes from the versioned launch save, not from test-only fixtures.
- This report is generated locally from the real golden slice and the real embedded bootstrap seed.
```
