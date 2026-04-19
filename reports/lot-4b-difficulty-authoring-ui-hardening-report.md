# Lot 4b — Difficulty Validation Hardening + Trainer Studio Authoring + Modern Battle UI + Background Image Picker

## 1. Resume Executif Honnete

`Lot 4b` est reussi au sens du perimetre demande.

Le lot ferme quatre besoins produit reelles ensemble, sans ouvrir le lot 5 :
- la preuve du lot 4 est reellement durcie par un helper runtime pur qui represente le vrai routing `trainer -> difficulty -> BattleOpponentPolicy`, puis par un smoke test qui consomme ce helper dans le vrai flow runtime ;
- le Trainer Studio authorise maintenant une vraie difficulte trainer `1..10` via un slider explicite, persistante dans `ProjectTrainerEntry.battleDifficulty` ;
- le Trainer Studio authorise maintenant un vrai fond de combat explicite par trainer, stocke comme chemin relatif projet dans `ProjectTrainerEntry.battleBackgroundRelativePath`, avec indication claire et clear propre ;
- l'UI combat runtime est nettement plus proche du rythme et de la hierarchie du gif de reference : HUDs plus battle-like, command box plus lisible, scene moins panneau debug, tout en restant adosse aux seules verites `BattleDecisionRequest` et `BattleTurnResult.timeline`.

Decisions structurantes retenues :
- j'ai garde toute la logique battle et IA hors de `battle_session.dart` ;
- je n'ai pas ouvert de lot 5 ;
- je n'ai pas cree de framework global de theming ni de media library ;
- j'ai choisi un indicateur authoring lisible pour l'image de fond dans le Trainer Studio plutot qu'un thumbnail runtime-decode fragile ;
- j'ai garde la priorite runtime suivante : `background explicite trainer resoluble > fond contextuel du lot 2 > fallback stable`.

## 2. Pre-gates Reellement Executes + Resultats

Commandes executees au tout debut :

```text
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Resultats au debut du lot :
- `git status --short --untracked-files=all` : aucune sortie
- `git diff --stat` : aucune sortie
- `git ls-files --others --exclude-standard` : aucune sortie

Conclusion honnête :
- le repo etait propre au debut du lot 4b ;
- il n'y avait pas de bruit git pre-existant a lisser ;
- la dirtiness finale du worktree vient donc bien de ce lot 4b et du report lui-meme.

## 3. Methode Reellement Suivie

Methode reelle :
1. relecture des docs/reports battle et du code reel sur `map_battle`, `map_runtime`, `map_core` et `map_editor` ;
2. recherche repo-reelle des fichiers du Trainer Studio et des patterns de picker existants ;
3. verification de la reference visuelle disponible : les chemins `/mnt/data/...` mentionnes dans le prompt n'etaient pas presents, le gif reellement disponible et exploitable etait `/Users/karim/Desktop/OPEyTO4.gif` ;
4. fermeture du trou de preuve lot 4 par extraction d'un helper runtime pur et par renforcement des smokes ;
5. authoring trainer dans l'editor : modele, validation, use cases, notifier, surface UI ;
6. runtime explicite trainer background > contextuel > fallback ;
7. modernisation visuelle runtime de la battle scene en restant honnête sur les commandes reelles ;
8. relance progressive des tests cibles, correction des vrais regressions, puis rerun complet des validations demandees ;
9. tentative de review separee via sub-agents ;
10. redaction du report final avec appendice complet des fichiers touches.

## 4. Perimetre Inclus / Exclu

Inclus :
- durcissement de preuve lot 4 ;
- validation `battleDifficulty` et `battleBackgroundRelativePath` dans `map_core` ;
- authoring Trainer Studio pour difficulte et background ;
- runtime explicit trainer background override ;
- modernisation de l'UI combat runtime ;
- tests cibles `map_core`, `map_editor`, `map_runtime`, `map_battle`, host.

Exclu volontairement :
- scripts trainer/boss ;
- switch intelligent ;
- replacement intelligent ;
- targeting riche ;
- nouvelles mecaniques battle ;
- refactor large battle-core ;
- framework global de theming/media ;
- faux `Bag` ou faux menu `Pokemon` dans l'UI combat ;
- modification de `battle_session.dart` ;
- modification de `battle_opponent_policy.dart` au-dela du lot 4 deja acquis.

## 5. Classification Initiale Des Sujets Du Lot 4b

- `hardening de preuve lot 4` : `required_now`
- `slider difficulte Trainer Studio` : `required_now`
- `stockage du background explicite trainer` : `required_now`
- `picker d'image de background` : `required_now`
- `preview/clear de l'image selectionnee` : `fix_now_small`
- `override runtime background explicite > fond contextuel` : `required_now`
- `modernisation UI combat inspiree du gif` : `required_now`
- `eventuelle navigation locale type command families` : `defer_not_lot4b`
- `eventuel test seam/runtime helper` : `required_now`
- `eventuelle modification de battle_opponent_policy.dart` : `document_now_only`
- `eventuelle modification de battle_session.dart` : `defer_not_lot4b`
- `eventuelle modification de playable_map_game.dart` : `required_now`
- `eventuelle modification de battle_overlay_component.dart` : `required_now`
- `eventuelle modification de battle_scene_backdrop_component.dart` : `required_now`
- `eventuelle modification de project_trainer.dart` : `required_now`
- `eventuels fichiers Trainer Studio a modifier` : `required_now`
- `scripts trainer/boss` : `defer_not_lot4b`
- `switch intelligent` : `defer_not_lot4b`
- `replacement intelligent` : `defer_not_lot4b`
- `thumbnail image editor decode-time reel` : `defer_not_lot4b`

## 6. Fichiers Lus

Docs / reports relus :
- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/combat-ui-ai-audit-and-roadmap.md`
- `reports/combat-ui-ai-implementation-roadmap.md`
- `reports/lot-1-battle-scene-ui-pass-report.md`
- `reports/lot-2-contextual-backgrounds-report.md`
- `reports/lot-3-battle-opponent-policy-seam-report.md`
- `reports/lot-4-difficulty-routing-report.md`
- `reports/r2-scheduler-consolidation-report.md`
- `reports/r3-condition-lifecycle-consolidation-report.md`

Battle-core relu :
- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_opponent_policy.dart`
- `packages/map_battle/lib/src/battle_session.dart`

Runtime / combat UI relu :
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_debug_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart`

Runtime / application relu :
- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`

Trainer data / editor relu :
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart`
- `packages/map_editor/test/trainer_library_panel_test.dart`
- `packages/map_editor/test/trainer_use_cases_test.dart`

Donnees / host relues :
- `examples/playable_runtime_host/golden_battle_slice/project.json`

Recherche repo-reelle executee :
- recherche des vrais fichiers Trainer Studio
- recherche des occurrences `battleDifficulty`, `ProjectTrainerEntry`, `battleThemeId`, `portraitElementId`
- recherche des patterns existants de picker / file picker / import d'image
- recherche des composants runtime battle deja poses

## 7. Validations Reellement Relancees

### Battle

```text
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test
```

### Map core

```text
cd /Users/karim/Project/pokemonProject/packages/map_core && dart analyze lib/src/models/project_trainer.dart lib/src/validation/validators.dart test/project_trainer_validation_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_core && dart run build_runner build --delete-conflicting-outputs
cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/project_trainer_validation_test.dart
```

### Map editor

```text
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub \
  lib/src/application/use_cases/trainer_use_cases.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/panels/trainer_library_panel.dart \
  lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart \
  lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart \
  test/trainer_use_cases_test.dart \
  test/trainer_library_panel_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test \
  test/trainer_use_cases_test.dart \
  test/trainer_library_panel_test.dart
```

### Runtime

```text
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-pub \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/presentation/flame/battle_scene_backdrop_component.dart \
  lib/src/presentation/flame/battle_command_panel_component.dart \
  lib/src/presentation/flame/battle_scene_hud_component.dart \
  lib/src/presentation/flame/battle_scene_combatant_component.dart \
  lib/src/presentation/flame/battle_background_resolver.dart \
  lib/src/presentation/flame/runtime_trainer_battle_overrides.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/battle_overlay_component_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/battle_overlay_component_test.dart
```

### Host

```text
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

## 8. Resultats Reellement Obtenus

Tout est vert au moment de clore ce lot.

Resultats notables :
- `map_battle`: analyse verte, suite complete verte
- `map_core`: analyse verte, build_runner passe, test de validation verte
- `map_editor`: analyse ciblee verte, tests cibles verts
- `map_runtime`: analyse ciblee verte, tests cibles verts
- `examples/playable_runtime_host`: tests verts

Incidents reels pendant les validations :
- le premier PNG 1x1 encode dans les tests etait techniquement decodable par Pillow mais pas par `ui.instantiateImageCodec` en environnement Flutter test ; j'ai remplace ce fixture par un PNG 2x2 valide et le probleme a disparu ;
- un test widget editor tentait au debut un flow trop ambitieux avec thumbnail/picker, et le retour n'etait pas proportionne au lot ; j'ai resserre la preuve editor vers un authoring UI lisible + persistance use case + consommation runtime reelle.

## 9. Decisions Retenues / Rejetees Sujet Par Sujet

### A. Hardening reel du lot 4

Retenu :
- extraire `resolveRuntimeTrainerOpponentPolicy(...)` et `findTrainerEntryForBattleRequest(...)` dans `packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart`
- faire consommer ce helper par `PlayableMapGame`
- faire consommer ce helper aussi par le smoke runtime `phase_a_golden_battle_slice_smoke_test.dart`

Pourquoi :
- le trou du lot 4 venait du fait qu'un test utilisait directement `battleOpponentPolicyForDifficulty(...)`, ce qui prouvait le mapping battle-local mais pas le vrai routing runtime ;
- ce helper ferme exactement ce trou, sans retomber dans une plomberie plus large.

Rejete :
- remettre la logique de difficulty routing dans `battle_session.dart`
- ouvrir un registry de policies
- ouvrir du routing wild difficulty

### B. Slider de difficulte Trainer Studio

Retenu :
- slider `1..10` explicite dans l'editeur trainer
- badge `AI X` visible dans le roster quand une difficulte est authorée
- message clair quand aucun override n'est authoré et que le fallback historique reste en place

Pourquoi :
- c'est la meilleure expression produit du lot 4 routée proprement jusque dans l'authoring ;
- un champ texte aurait ete plus laid, moins robuste et moins fidele au besoin.

Rejete :
- champ texte brut
- selecteur technique ou obscure

### C. Stockage du background explicite trainer

Retenu :
- `ProjectTrainerEntry.battleBackgroundRelativePath`
- chemin relatif projet

Pourquoi :
- c'est la forme la plus petite et la plus honnête pour authorer un fond explicite sans creer de media system global ;
- c'est compatible avec le runtime qui connait deja le `projectRootDirectory`.

Rejete :
- identifiant global d'asset abstrait sans pipeline existante
- grand catalogue d'images trainer
- stockage absolu machine-local

### D. Picker d'image

Retenu :
- picker simple base sur `FilePicker`
- acceptation uniquement de chemins project-local ; sinon message d'erreur explicite
- clear propre

Pourquoi :
- plus petit picker honnête et repo-reel ;
- respecte le besoin produit sans framework d'asset browsing.

Rejete :
- media browser complet
- library de backgrounds
- picker multi-source / tagging / folders virtuels

### E. Preview / indication

Retenu :
- indication authoring lisible avec etat `linked / missing / none`
- pas de thumbnail decode-time dans le Trainer Studio

Pourquoi :
- le prompt autorisait "preview ou au moins une indication lisible" ;
- le thumbnail reel apportait du decode d'image fragile dans le widget test/editor pour un gain produit limité a ce stade ;
- le runtime, lui, charge bien la vraie image en combat.

Rejete :
- thumbnail editor plus ambitieux mais fragile

### F. Runtime explicite > contextuel > fallback

Retenu :
- `BattleBackgroundResolver.resolve()` commence par resoudre la famille contextuelle du lot 2
- s'il trouve un `battleBackgroundRelativePath` trainer, il retourne une `BattleBackgroundSpec.explicitImage(...)` avec le `fallbackKey` contextuel
- `BattleSceneBackdropComponent` tente de charger l'image explicite ; si le chargement echoue, il peint le fallback contextuel sans mentir

Pourquoi :
- on garde le lot 2 intact tout en ajoutant une surcouche trainer explicite honnête ;
- on n'introduit rien dans `map_battle`.

### G. Modernisation UI combat inspiree du gif

Retenu :
- command box en deux zones : narration/prompt a gauche, commandes a droite
- commandes rendues en grille 2x2 quand c'est honnête, sinon en liste
- aucune commande fictive `Bag` / `Pokemon`
- HUDs plus compacts et plus battle-like
- silhouettes / plateformes de combattants plus lisibles

Pourquoi :
- c'est le meilleur rapprochement avec le rythme du gif sans mensonge produit ;
- l'overlay reste strictement derive de `BattleDecisionRequest` et `timeline`.

Rejete :
- copie pixel-perfect du gif
- fausse barre de commandes a quatre familles fixes si le moteur ne les expose pas
- faux `Bag`
- faux menu `Pokemon`

## 10. Justification Des Fichiers Modifies

- `packages/map_core/lib/src/models/project_trainer.dart` : ajout des donnees produit authorables reelles
- `packages/map_core/lib/src/validation/validators.dart` : validation honnête `1..10` et chemin relatif projet
- `packages/map_core/lib/src/models/project_trainer.freezed.dart` / `.g.dart` : regeneration necessaire apres modification du modele
- `packages/map_core/test/project_trainer_validation_test.dart` : verrouille la validation authoring
- `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart` : persistance create/update/clear pour difficulte et background
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` : relie l'UI aux use cases sans logique parallele
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart` : logique locale du slider, du picker et du clear
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart` : rendu authoring slider/background
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart` : badges et lecture lisible dans le Studio
- `packages/map_editor/test/trainer_use_cases_test.dart` : persistence/correction editor
- `packages/map_editor/test/trainer_library_panel_test.dart` : presence et lisibilite des controles authoring
- `packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart` : helper pur pour fermer le trou de preuve lot 4
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` : consomme le vrai helper runtime
- `packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart` : route background explicite trainer
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart` : charge et peint l'image explicite, sinon fallback honnête
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` : entree presentative plus riche, layout plus proche du gif, sans faux flows
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart` : nouvelle battle box moderne, sans commandes mensongeres
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart` : HUDs modernises
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart` : meilleure presence de scene sans sprites prod
- `packages/map_runtime/test/battle_overlay_component_test.dart` : preuve de chargement d'image explicite
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart` : preuve runtime directe trainer difficulty + trainer explicit background
- `examples/playable_runtime_host/golden_battle_slice/project.json` : authoring reel de l'exemple golden slice
- `examples/playable_runtime_host/golden_battle_slice/assets/battle_backgrounds/trainer_rookie.png` : fixture image minimale necessaire pour un vrai fond explicite resolvable en smoke/host

## 11. Justification Des Fichiers Volontairement Non Touches

- `packages/map_battle/lib/src/battle_session.dart` : volontairement non touche pour garder la logique difficulty hors de la session
- `packages/map_battle/lib/src/battle_queue.dart` : hors lot
- `packages/map_battle/lib/src/battle_resolution.dart` : hors lot
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` : pas necessaire pour authorer ni router le fond explicite/difficulte trainer
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart` : hors lot
- host source hors tests : aucune raison stricte de le toucher
- docs canoniques battle : ce lot est un lot produit/authoring/UI, pas une phase canonique roadmap battle structurelle

## 12. Comment Le Lot 4 A Ete Reellement Durci Ou Corrige

Le vrai durcissement est le suivant :
- avant : le smoke runtime du lot 4 passait par `battleOpponentPolicyForDifficulty(...)` directement, donc la consommation de la difficulte authorée dans le vrai wiring runtime restait indirecte ;
- apres : `PlayableMapGame` et le smoke runtime passent par `resolveRuntimeTrainerOpponentPolicy(...)`, qui lit `trainerId` dans la vraie `BattleStartRequest`, retrouve le `ProjectTrainerEntry` dans le vrai `ProjectManifest`, lit `battleDifficulty`, puis choisit la bonne policy battle-local ;
- en plus : le smoke verifie explicitement que `trainerEntry.battleDifficulty == 4` et que la vraie entree golden slice authorée est bien utilisee.

Autrement dit :
- la preuve ne s'arrete plus au mapping battle-local ;
- elle couvre maintenant le routing runtime reel.

## 13. Description Precise Du Slider Trainer Studio

Implementation retenue :
- controle : `CupertinoSlider`
- plage : `1..10`
- stockage : `ProjectTrainerEntry.battleDifficulty`
- mode vide : autorise ; le bouton "Use fallback" retire la valeur authorée et laisse le fallback historique
- lecture : badge `AI X` dans la liste quand present ; label de detail dans la surface d'edition

UX retenue :
- pas de champ texte
- pas de saisie libre
- message explicite quand aucune difficulte n'est encore authorée
- message explicite indiquant qu'une vraie valeur `1..10` sera plus tard routée vers peu de profils internes

## 14. Description Precise Du Picker Background

Implementation retenue :
- un vrai bouton `Choose image`
- `FilePicker` cote editor
- restriction a des fichiers image usuels (`png`, `jpg`, `jpeg`, `webp`, `bmp`, `gif`)
- verification que le fichier choisi reste dans le projet
- stockage en chemin relatif projet
- bouton `Clear`
- etat authoring lisible : aucun fond, fond lie, fichier manquant

Comportement si le fichier n'existe plus :
- le Studio l'indique comme `Linked file missing`
- le runtime ignore l'image explicite manquante et revient au fond contextuel du lot 2

## 15. Description Precise De La Priorite Runtime Explicite > Contextuel > Fallback

Priorite appliquee :
1. trainer explicit background si `battleBackgroundRelativePath` est present
2. sinon fond contextuel du lot 2 (`indoor`, `trainerOutdoor`, `wildOutdoor`...)
3. sinon fallback stable deja present

Details d'implementation :
- `BattleBackgroundResolver.resolve()` calcule d'abord la cle contextuelle ;
- si le trainer authoré un background explicite, il retourne `BattleBackgroundSpec.explicitImage(fallbackKey: contextualKey, absolutePath: ...)` ;
- `BattleSceneBackdropComponent` tente le decode ;
- si ce decode echoue, il peint le fallbackKey contextuel sans casser la scene.

## 16. Description Precise De La Nouvelle UI Combat

Ameliorations reelles :
- command box restructuree en deux panneaux : prompt/narration a gauche, commandes a droite ;
- commandes rendues en cartes modernes, en grille 2x2 quand il y a peu d'options, sinon en liste ;
- les cartes sont colorees selon la vraie famille de choix supportee (attaque physique, speciale, support, switch, neutre) ;
- HUD ennemi et joueur re-dessines dans un style plus proche d'un battle HUD Pokemon-like : nom, niveau, HP bar, statut, lecture plus compacte ;
- silhouettes de combattants plus centrales, avec plateforme sable, ombre et aura, plutot qu'un simple bloc debug ;
- le debug panel reste optionnel et separe.

Ce que je n'ai pas fait pour rester honnête :
- pas de bouton `Bag` si le moteur ne l'expose pas ;
- pas de faux menu `Pokemon` ;
- pas de sous-menu de familles de commandes qui ne correspondrait pas a `BattleDecisionRequest`.

Inspiration reellement retenue du gif :
- hiérarchie top enemy / bottom player
- battle box basse tres lisible
- rythme visuel plus console-JRPG / Pokemon-like
- HUDs plus compacts et distincts

## 17. Ce Qui Reste Volontairement Pour Le Lot 5

- scripts trainer/boss
- policies trainer plus riches
- switch intelligent
- replacement intelligent
- targeting plus riche
- comportement contextuel multi-criteres
- pipeline de vrais sprites battle ou backgrounds artistiques prod

## 18. Incidents Rencontres

- le premier fixture PNG etait trop fragile pour `instantiateImageCodec` en test Flutter ;
- un premier essai de test widget editor plus ambitieux s'est revele trop fragile par rapport au gain ; j'ai resserre la preuve editor ;
- les chemins `/mnt/data/...` annonces par le prompt n'etaient pas presents localement ; la vraie reference exploitable etait `/Users/karim/Desktop/OPEyTO4.gif` ;
- aucune ecriture Git interdite n'a ete effectuee.

## 19. Retour Des Sub-agents

### Battle/runtime truth

Retour utile :
- le trou de preuve lot 4 etait reel ;
- la bonne fermeture etait un helper runtime pur, pas un faux framework ni un simple test battle-core.

Decision prise :
- suivi.

### Trainer Studio / authoring UX

Retour utile :
- besoin d'un authoring visible et simple ;
- un systeme plus abstrait de references media aurait ete disproportionne.

Decision prise :
- suivi sur le principe ;
- stockage direct `battleBackgroundRelativePath` retenu au lieu d'une abstraction plus large.

### Battle UI / visual structure

Retour utile :
- rapprocher la composition du gif sans reproduire ses commandes non supportees ;
- privilegier layout, rythme, hierarchie et lisibilite.

Decision prise :
- suivi.

## 20. Retour Du Reviewer Separe

Deux reviews separees ont ete tentees via sub-agents distincts.

Resultat honnête :
- aucun reviewer n'a rendu un retour exploitable avant timeout ;
- je ne fabrique donc pas de findings fictifs ;
- je classe cela comme "review separee tentee mais non obtenue".

Risques residuels que j'assume explicitement en l'absence de reviewer rendu :
- l'UI combat modernisee n'a pas ete revue visuellement par un second regard humain ;
- le compromis "indication lisible au lieu de thumbnail editor" peut etre discute produit, meme s'il reste honnête et dans le perimetre ;
- l'appendice est volumineux a cause des fichiers generes et du besoin d'inclure tout le contenu.

## 21. Critique Explicite Du Prompt Lui-meme

Parties utiles :
- l'insistance sur les seams (`BattleDecisionRequest`, `timeline`, priorite background explicite > contextuel > fallback) ;
- l'interdiction des faux supports UI ;
- la demande de relier authoring, runtime et preuve de validation.

Parties discutables :
- imposer une preview image editor n'est pas toujours le meilleur choix ; ici, une indication lisible et robuste etait plus juste que d'introduire un decode thumbnail fragile ;
- les chemins `/mnt/data/...` donnes comme reference n'etaient pas disponibles dans l'environnement reel ; il fallait donc retomber sur la ressource locale vraiment presente.

Parties trop rigides :
- "inclure le contenu complet de tous les fichiers modifies/crees/supprimes" devient tres lourd des qu'il y a du code genere et un binaire ; c'est faisable, mais c'est plus une contrainte d'audit documentaire qu'une aide a la qualite technique ;
- exiger implicitement une review separee meme quand les reviewers ne repondent pas peut pousser a inventer des retours. Je ne l'ai pas fait.

Parties volontairement resserrees par moi :
- j'ai resserre la notion de "preview" vers une indication editor claire plutot qu'un vrai thumbnail ;
- j'ai resserre la preuve editor vers `UI visible + use case persistence + runtime consumption`, au lieu de m'acharner sur un test widget OS-dependent du picker ;
- j'ai resserre la modernisation combat vers une meilleure battle box, HUD et scene, plutot que vers une copie pixel-perfect du gif.

## 22. Autocritique Finale

Ce que je defend bien :
- le lot reste disciplinaire et n'ouvre pas le lot 5 ;
- la preuve du lot 4 est nettement meilleure qu'avant ;
- le Trainer Studio authorise vraiment les nouvelles donnees ;
- le runtime les consomme honnêtement ;
- l'UI combat est sensiblement moins debug-panel et plus battle-like.

Ce que j'aurais pu pousser plus loin si le lot avait ete plus large :
- un vrai thumbnail editor robuste ;
- des assets battle plus riches ;
- une verification visuelle runtime par capture automatisee.

## 23. Etat Git Final Utile

L'etat git final a ete releve apres creation de ce report ; il inclut donc logiquement ce report comme nouveau fichier.

```text
 M examples/playable_runtime_host/golden_battle_slice/project.json
 M packages/map_core/lib/src/models/project_trainer.dart
 M packages/map_core/lib/src/models/project_trainer.freezed.dart
 M packages/map_core/lib/src/models/project_trainer.g.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart
 M packages/map_editor/test/trainer_library_panel_test.dart
 M packages/map_editor/test/trainer_use_cases_test.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
?? examples/playable_runtime_host/golden_battle_slice/assets/battle_backgrounds/trainer_rookie.png
?? packages/map_core/test/project_trainer_validation_test.dart
?? packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart
?? reports/lot-4b-difficulty-authoring-ui-hardening-report.md
```

```text
 .../golden_battle_slice/project.json               |   1 +
 .../map_core/lib/src/models/project_trainer.dart   |  12 +
 .../lib/src/models/project_trainer.freezed.dart    |  60 +++-
 .../map_core/lib/src/models/project_trainer.g.dart |   3 +
 .../map_core/lib/src/validation/validators.dart    |  16 +
 .../application/use_cases/trainer_use_cases.dart   |  29 ++
 .../src/features/editor/state/editor_notifier.dart |   8 +
 .../lib/src/ui/panels/trainer_library_panel.dart   | 186 +++++++++++
 .../trainer_library_panel_trainer_widgets.dart     | 280 +++++++++++++++-
 .../trainer_library_panel_workspace_widgets.dart   |  31 ++
 .../test/trainer_library_panel_test.dart           |  78 ++++-
 .../map_editor/test/trainer_use_cases_test.dart    |  49 +++
 .../flame/battle_background_resolver.dart          |  75 ++++-
 .../flame/battle_command_panel_component.dart      | 355 +++++++++++++++------
 .../flame/battle_overlay_component.dart            |  92 ++++--
 .../flame/battle_scene_backdrop_component.dart     |  99 ++++++
 .../flame/battle_scene_combatant_component.dart    | 157 +++++----
 .../flame/battle_scene_hud_component.dart          | 149 ++++++---
 .../src/presentation/flame/playable_map_game.dart  |  32 +-
 .../test/battle_overlay_component_test.dart        |  32 ++
 .../phase_a_golden_battle_slice_smoke_test.dart    |  24 +-
 21 files changed, 1480 insertions(+), 288 deletions(-)
```

```text
examples/playable_runtime_host/golden_battle_slice/assets/battle_backgrounds/trainer_rookie.png
packages/map_core/test/project_trainer_validation_test.dart
packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart
reports/lot-4b-difficulty-authoring-ui-hardening-report.md
```

## 24. Checklist Finale

- [x] ai-je garde le perimetre du lot 4b sans deriver vers le lot 5 ?
- [x] ai-je reellement durci la preuve du lot 4 ?
- [x] ai-je ajoute un vrai slider de difficulte dans le Trainer Studio ?
- [x] ai-je ajoute un vrai picker d'image de background ?
- [x] ai-je relie honnêtement ce picker au runtime ?
- [x] ai-je garde la priorite explicite > contextuel > fallback ?
- [x] ai-je modernise l'UI combat vers l'esprit du gif sans mentir ?
- [x] ai-je garde les commandes adossees a `BattleDecisionRequest` ?
- [x] ai-je evite les commandes mensongeres non supportees ?
- [x] ai-je relance les validations utiles ?
- [x] ai-je utilise des sub-agents ?
- [~] ai-je fait une review separee ?
  Review separee tentee deux fois, sans retour exploitable avant timeout.
- [x] ai-je inclus le contenu complet de tous les fichiers touches ?
  Oui pour tous les fichiers touches hors le report lui-meme, qu'il est impossible d'inclure recursivement dans son propre corps.
- [x] ai-je evite toute ecriture Git interdite ?

## 25. Decision Finale Nette

- `lot 4b reussi ou non` : **oui**
- `preuve lot 4 reellement durcie ou non` : **oui**
- `trainer authoring reellement meilleur ou non` : **oui**
- `UI combat reellement modernisee vers la reference ou non` : **oui, sans copie mensongere**
- `preparation saine du lot 5 ou non` : **oui**

Le point le plus important a retenir est le suivant :
- ce lot relie maintenant une verite produit authorable (`battleDifficulty`, `battleBackgroundRelativePath`) a une consommation runtime honnête, puis a une presentation battle nettement plus lisible, sans retransformer le projet en tunnel de plomberie battle-core.

## Appendice A — Contenu Complet Des Fichiers Touches

Note honnête :
- cet appendice inclut le contenu complet de tous les fichiers modifies ou crees par le lot 4b ;
- il n'inclut pas recursivement ce report lui-meme, ce qui serait impossible ;
- pour le PNG binaire, le contenu est fourni en Base64 complet.

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
      "battleDifficulty": 4,
      "battleBackgroundRelativePath": "assets/battle_backgrounds/trainer_rookie.png",
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

### `packages/map_core/lib/src/models/project_trainer.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_trainer.freezed.dart';
part 'project_trainer.g.dart';

/// Entrée Pokémon dans l'équipe d'un [ProjectTrainerEntry].
@freezed
class ProjectTrainerPokemonEntry with _$ProjectTrainerPokemonEntry {
  const factory ProjectTrainerPokemonEntry({
    required String speciesId,
    required int level,

    /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
    @Default([]) List<String> moves,
    String? heldItemId,
    String? formId,

    /// Genre libre : "male", "female", "any", ou null = non spécifié.
    String? gender,
    @Default(false) bool shiny,
  }) = _ProjectTrainerPokemonEntry;

  factory ProjectTrainerPokemonEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTrainerPokemonEntryFromJson(json);
}

/// Fiche projet d'un dresseur, référencé depuis [MapEntityNpcData.trainerId].
@freezed
class ProjectTrainerEntry with _$ProjectTrainerEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTrainerEntry({
    required String id,
    required String name,

    /// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
    required String trainerClass,

    /// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
    ///
    /// Ce champ reste volontairement optionnel pour deux raisons :
    /// - préserver les anciens trainers du dépôt sans migration forcée ;
    /// - laisser le runtime retomber sur le comportement historique quand
    ///   aucune difficulté explicite n'a encore été authored.
    ///
    /// Interprétation de périmètre :
    /// - cette valeur ne décrit que la sélection d'action adverse en combat ;
    /// - elle n'ouvre ni scripts trainer, ni phases boss, ni switch/replacement
    ///   intelligents ;
    /// - le routing réel vers quelques profils battle-local reste fait côté
    ///   runtime + `map_battle`, pas dans ce modèle data.
    int? battleDifficulty,

    /// Image de fond de combat explicitement authored pour ce trainer.
    ///
    /// Ce champ reste volontairement petit et purement data :
    /// - il stocke un chemin relatif au projet, pas un asset handle global ;
    /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
    ///   métier battle ;
    /// - il permet simplement au runtime de prioriser un fond explicite
    ///   trainer avant le fond contextuel du lot 2 ;
    /// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
    ///   sa chaîne `explicite > contextuel > fallback`.
    String? battleBackgroundRelativePath,

    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    @Default([]) List<ProjectTrainerPokemonEntry> team,
    @Default([]) List<String> tags,
  }) = _ProjectTrainerEntry;

  factory ProjectTrainerEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTrainerEntryFromJson(json);
}

```

### `packages/map_core/lib/src/models/project_trainer.freezed.dart`

```dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_trainer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProjectTrainerPokemonEntry _$ProjectTrainerPokemonEntryFromJson(
    Map<String, dynamic> json) {
  return _ProjectTrainerPokemonEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectTrainerPokemonEntry {
  String get speciesId => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;

  /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
  List<String> get moves => throw _privateConstructorUsedError;
  String? get heldItemId => throw _privateConstructorUsedError;
  String? get formId => throw _privateConstructorUsedError;

  /// Genre libre : "male", "female", "any", ou null = non spécifié.
  String? get gender => throw _privateConstructorUsedError;
  bool get shiny => throw _privateConstructorUsedError;

  /// Serializes this ProjectTrainerPokemonEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTrainerPokemonEntryCopyWith<ProjectTrainerPokemonEntry>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTrainerPokemonEntryCopyWith<$Res> {
  factory $ProjectTrainerPokemonEntryCopyWith(ProjectTrainerPokemonEntry value,
          $Res Function(ProjectTrainerPokemonEntry) then) =
      _$ProjectTrainerPokemonEntryCopyWithImpl<$Res,
          ProjectTrainerPokemonEntry>;
  @useResult
  $Res call(
      {String speciesId,
      int level,
      List<String> moves,
      String? heldItemId,
      String? formId,
      String? gender,
      bool shiny});
}

/// @nodoc
class _$ProjectTrainerPokemonEntryCopyWithImpl<$Res,
        $Val extends ProjectTrainerPokemonEntry>
    implements $ProjectTrainerPokemonEntryCopyWith<$Res> {
  _$ProjectTrainerPokemonEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? level = null,
    Object? moves = null,
    Object? heldItemId = freezed,
    Object? formId = freezed,
    Object? gender = freezed,
    Object? shiny = null,
  }) {
    return _then(_value.copyWith(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      moves: null == moves
          ? _value.moves
          : moves // ignore: cast_nullable_to_non_nullable
              as List<String>,
      heldItemId: freezed == heldItemId
          ? _value.heldItemId
          : heldItemId // ignore: cast_nullable_to_non_nullable
              as String?,
      formId: freezed == formId
          ? _value.formId
          : formId // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      shiny: null == shiny
          ? _value.shiny
          : shiny // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTrainerPokemonEntryImplCopyWith<$Res>
    implements $ProjectTrainerPokemonEntryCopyWith<$Res> {
  factory _$$ProjectTrainerPokemonEntryImplCopyWith(
          _$ProjectTrainerPokemonEntryImpl value,
          $Res Function(_$ProjectTrainerPokemonEntryImpl) then) =
      __$$ProjectTrainerPokemonEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String speciesId,
      int level,
      List<String> moves,
      String? heldItemId,
      String? formId,
      String? gender,
      bool shiny});
}

/// @nodoc
class __$$ProjectTrainerPokemonEntryImplCopyWithImpl<$Res>
    extends _$ProjectTrainerPokemonEntryCopyWithImpl<$Res,
        _$ProjectTrainerPokemonEntryImpl>
    implements _$$ProjectTrainerPokemonEntryImplCopyWith<$Res> {
  __$$ProjectTrainerPokemonEntryImplCopyWithImpl(
      _$ProjectTrainerPokemonEntryImpl _value,
      $Res Function(_$ProjectTrainerPokemonEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? level = null,
    Object? moves = null,
    Object? heldItemId = freezed,
    Object? formId = freezed,
    Object? gender = freezed,
    Object? shiny = null,
  }) {
    return _then(_$ProjectTrainerPokemonEntryImpl(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      moves: null == moves
          ? _value._moves
          : moves // ignore: cast_nullable_to_non_nullable
              as List<String>,
      heldItemId: freezed == heldItemId
          ? _value.heldItemId
          : heldItemId // ignore: cast_nullable_to_non_nullable
              as String?,
      formId: freezed == formId
          ? _value.formId
          : formId // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      shiny: null == shiny
          ? _value.shiny
          : shiny // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTrainerPokemonEntryImpl implements _ProjectTrainerPokemonEntry {
  const _$ProjectTrainerPokemonEntryImpl(
      {required this.speciesId,
      required this.level,
      final List<String> moves = const [],
      this.heldItemId,
      this.formId,
      this.gender,
      this.shiny = false})
      : _moves = moves;

  factory _$ProjectTrainerPokemonEntryImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectTrainerPokemonEntryImplFromJson(json);

  @override
  final String speciesId;
  @override
  final int level;

  /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
  final List<String> _moves;

  /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
  @override
  @JsonKey()
  List<String> get moves {
    if (_moves is EqualUnmodifiableListView) return _moves;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_moves);
  }

  @override
  final String? heldItemId;
  @override
  final String? formId;

  /// Genre libre : "male", "female", "any", ou null = non spécifié.
  @override
  final String? gender;
  @override
  @JsonKey()
  final bool shiny;

  @override
  String toString() {
    return 'ProjectTrainerPokemonEntry(speciesId: $speciesId, level: $level, moves: $moves, heldItemId: $heldItemId, formId: $formId, gender: $gender, shiny: $shiny)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTrainerPokemonEntryImpl &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(other._moves, _moves) &&
            (identical(other.heldItemId, heldItemId) ||
                other.heldItemId == heldItemId) &&
            (identical(other.formId, formId) || other.formId == formId) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.shiny, shiny) || other.shiny == shiny));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      speciesId,
      level,
      const DeepCollectionEquality().hash(_moves),
      heldItemId,
      formId,
      gender,
      shiny);

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTrainerPokemonEntryImplCopyWith<_$ProjectTrainerPokemonEntryImpl>
      get copyWith => __$$ProjectTrainerPokemonEntryImplCopyWithImpl<
          _$ProjectTrainerPokemonEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTrainerPokemonEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectTrainerPokemonEntry
    implements ProjectTrainerPokemonEntry {
  const factory _ProjectTrainerPokemonEntry(
      {required final String speciesId,
      required final int level,
      final List<String> moves,
      final String? heldItemId,
      final String? formId,
      final String? gender,
      final bool shiny}) = _$ProjectTrainerPokemonEntryImpl;

  factory _ProjectTrainerPokemonEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectTrainerPokemonEntryImpl.fromJson;

  @override
  String get speciesId;
  @override
  int get level;

  /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
  @override
  List<String> get moves;
  @override
  String? get heldItemId;
  @override
  String? get formId;

  /// Genre libre : "male", "female", "any", ou null = non spécifié.
  @override
  String? get gender;
  @override
  bool get shiny;

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTrainerPokemonEntryImplCopyWith<_$ProjectTrainerPokemonEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectTrainerEntry _$ProjectTrainerEntryFromJson(Map<String, dynamic> json) {
  return _ProjectTrainerEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectTrainerEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
  String get trainerClass => throw _privateConstructorUsedError;

  /// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
  ///
  /// Ce champ reste volontairement optionnel pour deux raisons :
  /// - préserver les anciens trainers du dépôt sans migration forcée ;
  /// - laisser le runtime retomber sur le comportement historique quand
  ///   aucune difficulté explicite n'a encore été authored.
  ///
  /// Interprétation de périmètre :
  /// - cette valeur ne décrit que la sélection d'action adverse en combat ;
  /// - elle n'ouvre ni scripts trainer, ni phases boss, ni switch/replacement
  ///   intelligents ;
  /// - le routing réel vers quelques profils battle-local reste fait côté
  ///   runtime + `map_battle`, pas dans ce modèle data.
  int? get battleDifficulty => throw _privateConstructorUsedError;

  /// Image de fond de combat explicitement authored pour ce trainer.
  ///
  /// Ce champ reste volontairement petit et purement data :
  /// - il stocke un chemin relatif au projet, pas un asset handle global ;
  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
  ///   métier battle ;
  /// - il permet simplement au runtime de prioriser un fond explicite
  ///   trainer avant le fond contextuel du lot 2 ;
  /// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
  ///   sa chaîne `explicite > contextuel > fallback`.
  String? get battleBackgroundRelativePath =>
      throw _privateConstructorUsedError;
  String? get characterId => throw _privateConstructorUsedError;
  String? get portraitElementId => throw _privateConstructorUsedError;
  String? get battleThemeId => throw _privateConstructorUsedError;
  String? get victoryThemeId => throw _privateConstructorUsedError;
  List<ProjectTrainerPokemonEntry> get team =>
      throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this ProjectTrainerEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTrainerEntryCopyWith<ProjectTrainerEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTrainerEntryCopyWith<$Res> {
  factory $ProjectTrainerEntryCopyWith(
          ProjectTrainerEntry value, $Res Function(ProjectTrainerEntry) then) =
      _$ProjectTrainerEntryCopyWithImpl<$Res, ProjectTrainerEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String trainerClass,
      int? battleDifficulty,
      String? battleBackgroundRelativePath,
      String? characterId,
      String? portraitElementId,
      String? battleThemeId,
      String? victoryThemeId,
      List<ProjectTrainerPokemonEntry> team,
      List<String> tags});
}

/// @nodoc
class _$ProjectTrainerEntryCopyWithImpl<$Res, $Val extends ProjectTrainerEntry>
    implements $ProjectTrainerEntryCopyWith<$Res> {
  _$ProjectTrainerEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? trainerClass = null,
    Object? battleDifficulty = freezed,
    Object? battleBackgroundRelativePath = freezed,
    Object? characterId = freezed,
    Object? portraitElementId = freezed,
    Object? battleThemeId = freezed,
    Object? victoryThemeId = freezed,
    Object? team = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      trainerClass: null == trainerClass
          ? _value.trainerClass
          : trainerClass // ignore: cast_nullable_to_non_nullable
              as String,
      battleDifficulty: freezed == battleDifficulty
          ? _value.battleDifficulty
          : battleDifficulty // ignore: cast_nullable_to_non_nullable
              as int?,
      battleBackgroundRelativePath: freezed == battleBackgroundRelativePath
          ? _value.battleBackgroundRelativePath
          : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
              as String?,
      characterId: freezed == characterId
          ? _value.characterId
          : characterId // ignore: cast_nullable_to_non_nullable
              as String?,
      portraitElementId: freezed == portraitElementId
          ? _value.portraitElementId
          : portraitElementId // ignore: cast_nullable_to_non_nullable
              as String?,
      battleThemeId: freezed == battleThemeId
          ? _value.battleThemeId
          : battleThemeId // ignore: cast_nullable_to_non_nullable
              as String?,
      victoryThemeId: freezed == victoryThemeId
          ? _value.victoryThemeId
          : victoryThemeId // ignore: cast_nullable_to_non_nullable
              as String?,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerPokemonEntry>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTrainerEntryImplCopyWith<$Res>
    implements $ProjectTrainerEntryCopyWith<$Res> {
  factory _$$ProjectTrainerEntryImplCopyWith(_$ProjectTrainerEntryImpl value,
          $Res Function(_$ProjectTrainerEntryImpl) then) =
      __$$ProjectTrainerEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String trainerClass,
      int? battleDifficulty,
      String? battleBackgroundRelativePath,
      String? characterId,
      String? portraitElementId,
      String? battleThemeId,
      String? victoryThemeId,
      List<ProjectTrainerPokemonEntry> team,
      List<String> tags});
}

/// @nodoc
class __$$ProjectTrainerEntryImplCopyWithImpl<$Res>
    extends _$ProjectTrainerEntryCopyWithImpl<$Res, _$ProjectTrainerEntryImpl>
    implements _$$ProjectTrainerEntryImplCopyWith<$Res> {
  __$$ProjectTrainerEntryImplCopyWithImpl(_$ProjectTrainerEntryImpl _value,
      $Res Function(_$ProjectTrainerEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? trainerClass = null,
    Object? battleDifficulty = freezed,
    Object? battleBackgroundRelativePath = freezed,
    Object? characterId = freezed,
    Object? portraitElementId = freezed,
    Object? battleThemeId = freezed,
    Object? victoryThemeId = freezed,
    Object? team = null,
    Object? tags = null,
  }) {
    return _then(_$ProjectTrainerEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      trainerClass: null == trainerClass
          ? _value.trainerClass
          : trainerClass // ignore: cast_nullable_to_non_nullable
              as String,
      battleDifficulty: freezed == battleDifficulty
          ? _value.battleDifficulty
          : battleDifficulty // ignore: cast_nullable_to_non_nullable
              as int?,
      battleBackgroundRelativePath: freezed == battleBackgroundRelativePath
          ? _value.battleBackgroundRelativePath
          : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
              as String?,
      characterId: freezed == characterId
          ? _value.characterId
          : characterId // ignore: cast_nullable_to_non_nullable
              as String?,
      portraitElementId: freezed == portraitElementId
          ? _value.portraitElementId
          : portraitElementId // ignore: cast_nullable_to_non_nullable
              as String?,
      battleThemeId: freezed == battleThemeId
          ? _value.battleThemeId
          : battleThemeId // ignore: cast_nullable_to_non_nullable
              as String?,
      victoryThemeId: freezed == victoryThemeId
          ? _value.victoryThemeId
          : victoryThemeId // ignore: cast_nullable_to_non_nullable
              as String?,
      team: null == team
          ? _value._team
          : team // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerPokemonEntry>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectTrainerEntryImpl implements _ProjectTrainerEntry {
  const _$ProjectTrainerEntryImpl(
      {required this.id,
      required this.name,
      required this.trainerClass,
      this.battleDifficulty,
      this.battleBackgroundRelativePath,
      this.characterId,
      this.portraitElementId,
      this.battleThemeId,
      this.victoryThemeId,
      final List<ProjectTrainerPokemonEntry> team = const [],
      final List<String> tags = const []})
      : _team = team,
        _tags = tags;

  factory _$ProjectTrainerEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTrainerEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  /// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
  @override
  final String trainerClass;

  /// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
  ///
  /// Ce champ reste volontairement optionnel pour deux raisons :
  /// - préserver les anciens trainers du dépôt sans migration forcée ;
  /// - laisser le runtime retomber sur le comportement historique quand
  ///   aucune difficulté explicite n'a encore été authored.
  ///
  /// Interprétation de périmètre :
  /// - cette valeur ne décrit que la sélection d'action adverse en combat ;
  /// - elle n'ouvre ni scripts trainer, ni phases boss, ni switch/replacement
  ///   intelligents ;
  /// - le routing réel vers quelques profils battle-local reste fait côté
  ///   runtime + `map_battle`, pas dans ce modèle data.
  @override
  final int? battleDifficulty;

  /// Image de fond de combat explicitement authored pour ce trainer.
  ///
  /// Ce champ reste volontairement petit et purement data :
  /// - il stocke un chemin relatif au projet, pas un asset handle global ;
  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
  ///   métier battle ;
  /// - il permet simplement au runtime de prioriser un fond explicite
  ///   trainer avant le fond contextuel du lot 2 ;
  /// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
  ///   sa chaîne `explicite > contextuel > fallback`.
  @override
  final String? battleBackgroundRelativePath;
  @override
  final String? characterId;
  @override
  final String? portraitElementId;
  @override
  final String? battleThemeId;
  @override
  final String? victoryThemeId;
  final List<ProjectTrainerPokemonEntry> _team;
  @override
  @JsonKey()
  List<ProjectTrainerPokemonEntry> get team {
    if (_team is EqualUnmodifiableListView) return _team;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_team);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'ProjectTrainerEntry(id: $id, name: $name, trainerClass: $trainerClass, battleDifficulty: $battleDifficulty, battleBackgroundRelativePath: $battleBackgroundRelativePath, characterId: $characterId, portraitElementId: $portraitElementId, battleThemeId: $battleThemeId, victoryThemeId: $victoryThemeId, team: $team, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTrainerEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.trainerClass, trainerClass) ||
                other.trainerClass == trainerClass) &&
            (identical(other.battleDifficulty, battleDifficulty) ||
                other.battleDifficulty == battleDifficulty) &&
            (identical(other.battleBackgroundRelativePath,
                    battleBackgroundRelativePath) ||
                other.battleBackgroundRelativePath ==
                    battleBackgroundRelativePath) &&
            (identical(other.characterId, characterId) ||
                other.characterId == characterId) &&
            (identical(other.portraitElementId, portraitElementId) ||
                other.portraitElementId == portraitElementId) &&
            (identical(other.battleThemeId, battleThemeId) ||
                other.battleThemeId == battleThemeId) &&
            (identical(other.victoryThemeId, victoryThemeId) ||
                other.victoryThemeId == victoryThemeId) &&
            const DeepCollectionEquality().equals(other._team, _team) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      trainerClass,
      battleDifficulty,
      battleBackgroundRelativePath,
      characterId,
      portraitElementId,
      battleThemeId,
      victoryThemeId,
      const DeepCollectionEquality().hash(_team),
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTrainerEntryImplCopyWith<_$ProjectTrainerEntryImpl> get copyWith =>
      __$$ProjectTrainerEntryImplCopyWithImpl<_$ProjectTrainerEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTrainerEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectTrainerEntry implements ProjectTrainerEntry {
  const factory _ProjectTrainerEntry(
      {required final String id,
      required final String name,
      required final String trainerClass,
      final int? battleDifficulty,
      final String? battleBackgroundRelativePath,
      final String? characterId,
      final String? portraitElementId,
      final String? battleThemeId,
      final String? victoryThemeId,
      final List<ProjectTrainerPokemonEntry> team,
      final List<String> tags}) = _$ProjectTrainerEntryImpl;

  factory _ProjectTrainerEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectTrainerEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
  @override
  String get trainerClass;

  /// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
  ///
  /// Ce champ reste volontairement optionnel pour deux raisons :
  /// - préserver les anciens trainers du dépôt sans migration forcée ;
  /// - laisser le runtime retomber sur le comportement historique quand
  ///   aucune difficulté explicite n'a encore été authored.
  ///
  /// Interprétation de périmètre :
  /// - cette valeur ne décrit que la sélection d'action adverse en combat ;
  /// - elle n'ouvre ni scripts trainer, ni phases boss, ni switch/replacement
  ///   intelligents ;
  /// - le routing réel vers quelques profils battle-local reste fait côté
  ///   runtime + `map_battle`, pas dans ce modèle data.
  @override
  int? get battleDifficulty;

  /// Image de fond de combat explicitement authored pour ce trainer.
  ///
  /// Ce champ reste volontairement petit et purement data :
  /// - il stocke un chemin relatif au projet, pas un asset handle global ;
  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
  ///   métier battle ;
  /// - il permet simplement au runtime de prioriser un fond explicite
  ///   trainer avant le fond contextuel du lot 2 ;
  /// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
  ///   sa chaîne `explicite > contextuel > fallback`.
  @override
  String? get battleBackgroundRelativePath;
  @override
  String? get characterId;
  @override
  String? get portraitElementId;
  @override
  String? get battleThemeId;
  @override
  String? get victoryThemeId;
  @override
  List<ProjectTrainerPokemonEntry> get team;
  @override
  List<String> get tags;

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTrainerEntryImplCopyWith<_$ProjectTrainerEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

```

### `packages/map_core/lib/src/models/project_trainer.g.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_trainer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectTrainerPokemonEntryImpl _$$ProjectTrainerPokemonEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTrainerPokemonEntryImpl(
      speciesId: json['speciesId'] as String,
      level: (json['level'] as num).toInt(),
      moves:
          (json['moves'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      heldItemId: json['heldItemId'] as String?,
      formId: json['formId'] as String?,
      gender: json['gender'] as String?,
      shiny: json['shiny'] as bool? ?? false,
    );

Map<String, dynamic> _$$ProjectTrainerPokemonEntryImplToJson(
        _$ProjectTrainerPokemonEntryImpl instance) =>
    <String, dynamic>{
      'speciesId': instance.speciesId,
      'level': instance.level,
      'moves': instance.moves,
      'heldItemId': instance.heldItemId,
      'formId': instance.formId,
      'gender': instance.gender,
      'shiny': instance.shiny,
    };

_$ProjectTrainerEntryImpl _$$ProjectTrainerEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTrainerEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      trainerClass: json['trainerClass'] as String,
      battleDifficulty: (json['battleDifficulty'] as num?)?.toInt(),
      battleBackgroundRelativePath:
          json['battleBackgroundRelativePath'] as String?,
      characterId: json['characterId'] as String?,
      portraitElementId: json['portraitElementId'] as String?,
      battleThemeId: json['battleThemeId'] as String?,
      victoryThemeId: json['victoryThemeId'] as String?,
      team: (json['team'] as List<dynamic>?)
              ?.map((e) => ProjectTrainerPokemonEntry.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$ProjectTrainerEntryImplToJson(
        _$ProjectTrainerEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'trainerClass': instance.trainerClass,
      'battleDifficulty': instance.battleDifficulty,
      'battleBackgroundRelativePath': instance.battleBackgroundRelativePath,
      'characterId': instance.characterId,
      'portraitElementId': instance.portraitElementId,
      'battleThemeId': instance.battleThemeId,
      'victoryThemeId': instance.victoryThemeId,
      'team': instance.team.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
    };

```

### `packages/map_core/lib/src/validation/validators.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/script_conditions.dart';
import '../operations/map_entities.dart';
import 'dialogue_validation.dart';
import 'entity_editor_visual_validation.dart';

class ProjectValidator {
  // Scenario action/source kinds partagés avec l'éditeur/runtime.
  // On garde ces chaînes localisées ici pour valider de manière
  // déterministe sans dépendre d'un package runtime.
  static const Set<String> _scenarioWorldSourceKinds = <String>{
    'sourceMapEnter',
    'sourceTriggerEnter',
    'sourceEntityInteract',
  };
  static const String _scenarioOutcomeSourceKind = 'sourceOutcome';
  static const String _scenarioEmitOutcomeKind = 'emitOutcome';

  /// Rectangles sources valides, [durationMs] > 0 si présent, au moins une frame,
  /// tailles identiques si plusieurs frames (préparation animation).
  static void _validateVisualFrames(
    List<TilesetVisualFrame> frames, {
    required String context,
    required Set<String> knownTilesetIds,
  }) {
    if (frames.isEmpty) {
      throw ValidationException('$context must have at least one visual frame');
    }
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final src = frame.source;
      if (src.x < 0 || src.y < 0) {
        throw ValidationException(
          '$context frame $i has invalid source coordinates',
        );
      }
      if (src.width <= 0 || src.height <= 0) {
        throw ValidationException('$context frame $i has invalid source size');
      }
      final overrideId = frame.tilesetId.trim();
      if (overrideId.isNotEmpty && !knownTilesetIds.contains(overrideId)) {
        throw ValidationException(
          '$context frame $i references missing tileset: $overrideId',
        );
      }
      final d = frame.durationMs;
      if (d != null && d <= 0) {
        throw ValidationException(
          '$context frame $i durationMs must be positive when set',
        );
      }
    }
    if (frames.length > 1) {
      final w = frames.first.source.width;
      final h = frames.first.source.height;
      for (var i = 1; i < frames.length; i++) {
        final s = frames[i].source;
        if (s.width != w || s.height != h) {
          throw ValidationException(
            '$context animation frames must share the same width and height',
          );
        }
      }
    }
  }

  static void validate(ProjectManifest manifest) {
    _validateUniqueness(manifest);
    _validateHierarchy(manifest);
    _validateEncounterTables(manifest.encounterTables);
    _validateProjectDialogues(manifest);
    _validateTrainers(manifest);
    _validateCharacters(manifest);
    _validateSettings(manifest.settings);
  }

  static void _validateUniqueness(ProjectManifest manifest) {
    _validateUniqueIds(
      manifest.maps,
      (map) => map.id,
      duplicateMessagePrefix: 'Duplicate map ID',
    );
    _validateUniqueIds(
      manifest.groups,
      (group) => group.id,
      duplicateMessagePrefix: 'Duplicate group ID',
    );
    _validateUniqueIds(
      manifest.tilesets,
      (tileset) => tileset.id,
      duplicateMessagePrefix: 'Duplicate tileset ID',
    );
    _validateUniqueIds(
      manifest.tilesetFolders,
      (folder) => folder.id,
      duplicateMessagePrefix: 'Duplicate tileset folder ID',
    );
    _validateUniqueIds(
      manifest.elementCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate element category ID',
    );
    _validateUniqueIds(
      manifest.elements,
      (element) => element.id,
      duplicateMessagePrefix: 'Duplicate element ID',
    );
    _validateUniqueIds(
      manifest.terrainCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate terrain category ID',
    );
    _validateUniqueIds(
      manifest.pathCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate path category ID',
    );
    _validateUniqueIds(
      manifest.terrainPresets,
      (preset) => preset.id,
      duplicateMessagePrefix: 'Duplicate terrain preset ID',
    );
    _validateUniqueIds(
      manifest.pathPresets,
      (preset) => preset.id,
      duplicateMessagePrefix: 'Duplicate path preset ID',
    );
    _validateUniqueIds(
      manifest.encounterTables,
      (table) => table.id,
      duplicateMessagePrefix: 'Duplicate encounter table ID',
    );
    _validateUniqueIds(
      manifest.dialogueFolders,
      (f) => f.id,
      duplicateMessagePrefix: 'Duplicate dialogue folder ID',
    );
    _validateUniqueIds(
      manifest.dialogues,
      (d) => d.id,
      duplicateMessagePrefix: 'Duplicate dialogue ID',
    );
    _validateUniqueIds(
      manifest.scenarios,
      (s) => s.id,
      duplicateMessagePrefix: 'Duplicate scenario ID',
    );
    _validateUniqueIds(
      manifest.trainers,
      (t) => t.id,
      duplicateMessagePrefix: 'Duplicate trainer ID',
    );
    _validateUniqueIds(
      manifest.characters,
      (c) => c.id,
      duplicateMessagePrefix: 'Duplicate character ID',
    );
  }

  static void _validateProjectDialogues(ProjectManifest manifest) {
    final dialogueFolderIds = manifest.dialogueFolders.map((f) => f.id).toSet();
    final dialogueRelativePaths = <String>{};
    for (final d in manifest.dialogues) {
      final id = d.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Dialogue entry has an empty id');
      }
      if (d.name.trim().isEmpty) {
        throw ValidationException('Dialogue $id has an empty name');
      }
      assertValidProjectDialogueRelativePath(d.relativePath, dialogueId: id);
      final rpNorm = d.relativePath.replaceAll(r'\', '/');
      if (!dialogueRelativePaths.add(rpNorm)) {
        throw ValidationException(
          'Duplicate dialogue relativePath in manifest: $rpNorm',
        );
      }
      assertValidDialogueStartNode(
        d.defaultStartNode,
        contextLabel: 'Dialogue $id defaultStartNode',
      );
      final df = d.folderId?.trim();
      if (df != null && df.isNotEmpty && !dialogueFolderIds.contains(df)) {
        throw ValidationException(
          'Dialogue $id references unknown dialogue folder: $df',
        );
      }
    }
  }

  static void _validateHierarchy(ProjectManifest manifest) {
    final groupIds = manifest.groups.map((g) => g.id).toSet();

    for (final group in manifest.groups) {
      if (group.parentGroupId != null &&
          !groupIds.contains(group.parentGroupId)) {
        throw ValidationException(
          'Group ${group.id} references non-existent parent: ${group.parentGroupId}',
        );
      }
      if (group.parentGroupId == group.id) {
        throw ValidationException('Group ${group.id} cannot be its own parent');
      }

      var current = group;
      final visited = {group.id};
      while (current.parentGroupId != null) {
        if (!groupIds.contains(current.parentGroupId)) {
          break;
        }
        if (!visited.add(current.parentGroupId!)) {
          throw ValidationException(
            'Cycle detected in group hierarchy at ${group.id}',
          );
        }
        current = manifest.groups
            .firstWhere((candidate) => candidate.id == current.parentGroupId);
      }
    }

    for (final map in manifest.maps) {
      if (map.groupId != null && !groupIds.contains(map.groupId)) {
        throw ValidationException(
          'Map ${map.id} references non-existent group: ${map.groupId}',
        );
      }
      _validateRelativePath(map.relativePath, 'Map ${map.id}');
    }

    _validateTilesetFolders(manifest);
    _validateDialogueFolders(manifest);
    _validateTilesets(manifest, groupIds);
    _validateElementCategories(manifest);
    _validateElements(manifest, groupIds);
    _validatePresetCategories(
      manifest.terrainCategories,
      label: 'terrain category',
    );
    _validatePresetCategories(
      manifest.pathCategories,
      label: 'path category',
    );
    _validateTerrainPresets(manifest);
    _validatePathPresets(manifest);
    _validateScenarios(manifest);
  }

  static void _validateTilesetFolders(ProjectManifest manifest) {
    final folderById = <String, ProjectTilesetFolder>{};
    for (final folder in manifest.tilesetFolders) {
      if (folder.id.trim().isEmpty) {
        throw const ValidationException('Tileset folder ID cannot be empty');
      }
      if (folder.name.trim().isEmpty) {
        throw ValidationException(
          'Tileset folder "${folder.id}" has an empty name',
        );
      }
      folderById[folder.id] = folder;
    }

    for (final folder in manifest.tilesetFolders) {
      final parentId = folder.parentFolderId;
      if (parentId == null) continue;
      if (!folderById.containsKey(parentId)) {
        throw ValidationException(
          'Tileset folder ${folder.id} references missing parent: $parentId',
        );
      }
      if (parentId == folder.id) {
        throw ValidationException(
          'Tileset folder ${folder.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final chain = <String>{};
      while (cursor != null) {
        if (!chain.add(cursor)) {
          throw ValidationException(
            'Cycle detected in tileset folder hierarchy at ${folder.id}',
          );
        }
        cursor = folderById[cursor]?.parentFolderId;
      }
    }

    final folderIds = folderById.keys.toSet();
    for (final tileset in manifest.tilesets) {
      final fid = tileset.folderId?.trim();
      if (fid == null || fid.isEmpty) continue;
      if (!folderIds.contains(fid)) {
        throw ValidationException(
          'Tileset ${tileset.id} references unknown tileset folder: $fid',
        );
      }
    }
  }

  static void _validateDialogueFolders(ProjectManifest manifest) {
    final folderById = <String, ProjectDialogueFolder>{};
    for (final folder in manifest.dialogueFolders) {
      if (folder.id.trim().isEmpty) {
        throw const ValidationException('Dialogue folder ID cannot be empty');
      }
      if (folder.name.trim().isEmpty) {
        throw ValidationException(
          'Dialogue folder "${folder.id}" has an empty name',
        );
      }
      folderById[folder.id] = folder;
    }

    for (final folder in manifest.dialogueFolders) {
      final parentId = folder.parentFolderId;
      if (parentId == null) continue;
      if (!folderById.containsKey(parentId)) {
        throw ValidationException(
          'Dialogue folder ${folder.id} references missing parent: $parentId',
        );
      }
      if (parentId == folder.id) {
        throw ValidationException(
          'Dialogue folder ${folder.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final chain = <String>{};
      while (cursor != null) {
        if (!chain.add(cursor)) {
          throw ValidationException(
            'Cycle detected in dialogue folder hierarchy at ${folder.id}',
          );
        }
        cursor = folderById[cursor]?.parentFolderId;
      }
    }
  }

  static void _validateTilesets(
      ProjectManifest manifest, Set<String> groupIds) {
    var worldTilesetCount = 0;
    final tilesetElementGroupIdsByTileset = <String, Set<String>>{};
    final allTilesetIds = manifest.tilesets.map((t) => t.id).toSet();

    for (final tileset in manifest.tilesets) {
      _validateRelativePath(tileset.relativePath, 'Tileset ${tileset.id}');

      if (tileset.scope == TilesetScope.global) {
        if (tileset.groupId != null) {
          throw ValidationException(
            'Global tileset ${tileset.id} cannot have groupId',
          );
        }
      } else {
        final groupId = tileset.groupId;
        if (groupId == null || !groupIds.contains(groupId)) {
          throw ValidationException(
            'Group-scoped tileset ${tileset.id} must reference an existing group',
          );
        }
      }

      if (tileset.isWorldTileset) {
        worldTilesetCount++;
        if (tileset.scope != TilesetScope.global) {
          throw ValidationException(
              'World tileset ${tileset.id} must be global');
        }
      }

      final elementGroupById = <String, TilesetElementGroup>{};
      for (final group in tileset.elementGroups) {
        if (group.id.trim().isEmpty) {
          throw ValidationException(
            'Tileset ${tileset.id} has an internal group with empty ID',
          );
        }
        if (group.name.trim().isEmpty) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} has an empty name',
          );
        }
        if (elementGroupById.containsKey(group.id)) {
          throw ValidationException(
            'Duplicate internal group ID in tileset ${tileset.id}: ${group.id}',
          );
        }
        elementGroupById[group.id] = group;
      }

      for (final group in tileset.elementGroups) {
        final parentId = group.parentGroupId;
        if (parentId == null) continue;
        if (!elementGroupById.containsKey(parentId)) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} references missing parent: $parentId',
          );
        }
        if (parentId == group.id) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} cannot be its own parent',
          );
        }
        String? cursor = parentId;
        final visited = <String>{group.id};
        while (cursor != null) {
          if (!visited.add(cursor)) {
            throw ValidationException(
              'Cycle detected in tileset ${tileset.id} internal groups at ${group.id}',
            );
          }
          cursor = elementGroupById[cursor]?.parentGroupId;
        }
      }

      tilesetElementGroupIdsByTileset[tileset.id] =
          elementGroupById.keys.toSet();

      final paletteIds = <String>{};
      for (final entry in tileset.paletteEntries) {
        if (entry.id.trim().isEmpty) {
          throw ValidationException(
            'Palette entry in tileset ${tileset.id} has an empty ID',
          );
        }
        if (!paletteIds.add(entry.id)) {
          throw ValidationException(
            'Duplicate palette entry ID in tileset ${tileset.id}: ${entry.id}',
          );
        }
        _validateVisualFrames(
          entry.frames,
          context: 'Palette entry ${entry.id} in tileset ${tileset.id}',
          knownTilesetIds: allTilesetIds,
        );
      }
    }

    if (worldTilesetCount > 1) {
      throw const ValidationException('Only one world tileset can be defined');
    }
  }

  static void _validateElementCategories(ProjectManifest manifest) {
    final categoryById = <String, ProjectElementCategory>{};
    for (final category in manifest.elementCategories) {
      if (category.id.trim().isEmpty) {
        throw const ValidationException('Element category ID cannot be empty');
      }
      if (category.name.trim().isEmpty) {
        throw ValidationException(
          'Element category ${category.id} has an empty name',
        );
      }
      categoryById[category.id] = category;
    }

    for (final category in manifest.elementCategories) {
      final parentId = category.parentCategoryId;
      if (parentId == null) continue;
      if (!categoryById.containsKey(parentId)) {
        throw ValidationException(
          'Element category ${category.id} references missing parent: $parentId',
        );
      }
      if (parentId == category.id) {
        throw ValidationException(
          'Element category ${category.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final visited = <String>{category.id};
      while (cursor != null) {
        if (!visited.add(cursor)) {
          throw ValidationException(
            'Cycle detected in element categories at ${category.id}',
          );
        }
        cursor = categoryById[cursor]?.parentCategoryId;
      }
    }
  }

  static void _validateElements(
      ProjectManifest manifest, Set<String> groupIds) {
    final tilesetIds = manifest.tilesets.map((t) => t.id).toSet();
    final tilesetElementGroupIdsByTileset = <String, Set<String>>{
      for (final tileset in manifest.tilesets)
        tileset.id: tileset.elementGroups.map((group) => group.id).toSet(),
    };
    final categoryIds = manifest.elementCategories.map((e) => e.id).toSet();

    for (final element in manifest.elements) {
      if (element.id.trim().isEmpty) {
        throw const ValidationException('Element ID cannot be empty');
      }
      if (element.name.trim().isEmpty) {
        throw ValidationException('Element ${element.id} has an empty name');
      }
      if (!tilesetIds.contains(element.tilesetId)) {
        throw ValidationException(
          'Element ${element.id} references missing tileset: ${element.tilesetId}',
        );
      }
      if (!categoryIds.contains(element.categoryId)) {
        throw ValidationException(
          'Element ${element.id} references missing category: ${element.categoryId}',
        );
      }
      if (element.groupId != null && !groupIds.contains(element.groupId)) {
        throw ValidationException(
          'Element ${element.id} references missing group: ${element.groupId}',
        );
      }
      if (element.tilesetGroupId != null &&
          element.tilesetGroupId!.trim().isEmpty) {
        throw ValidationException(
          'Element ${element.id} has an empty tilesetGroupId',
        );
      }
      if (element.tilesetGroupId != null) {
        final tilesetGroups =
            tilesetElementGroupIdsByTileset[element.tilesetId] ?? const {};
        if (!tilesetGroups.contains(element.tilesetGroupId)) {
          throw ValidationException(
            'Element ${element.id} references missing tileset group ${element.tilesetGroupId} in tileset ${element.tilesetId}',
          );
        }
      }
      _validateVisualFrames(
        element.frames,
        context: 'Element ${element.id}',
        knownTilesetIds: tilesetIds,
      );
      _validateElementCollisionProfile(element);
    }
  }

  static void _validateElementCollisionProfile(ProjectElementEntry element) {
    final profile = element.collisionProfile;
    if (profile == null) {
      return;
    }
    final padding = profile.padding;
    if (padding.top < 0 ||
        padding.right < 0 ||
        padding.bottom < 0 ||
        padding.left < 0) {
      throw ValidationException(
        'Element ${element.id} collision profile contains negative padding values',
      );
    }
    final source = element.frames.primarySource;
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.shapeCells,
      label: 'shape',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.cells,
      label: 'final',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.manualAddedCells,
      label: 'manualAdded',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.manualRemovedCells,
      label: 'manualRemoved',
    );
  }

  static void _validateCollisionCellsList({
    required String elementId,
    required TilesetSourceRect source,
    required List<GridPos> cells,
    required String label,
  }) {
    final seen = <String>{};
    for (final cell in cells) {
      if (cell.x < 0 || cell.y < 0) {
        throw ValidationException(
          'Element $elementId collision profile contains negative $label cell coordinates',
        );
      }
      if (cell.x >= source.width || cell.y >= source.height) {
        throw ValidationException(
          'Element $elementId $label collision cell (${cell.x}, ${cell.y}) is outside source bounds ${source.width}x${source.height}',
        );
      }
      final key = '${cell.x}:${cell.y}';
      if (!seen.add(key)) {
        throw ValidationException(
          'Element $elementId collision profile contains duplicate $label cell ($key)',
        );
      }
    }
  }

  static void _validatePresetCategories(
    List<ProjectPresetCategory> categories, {
    required String label,
  }) {
    final byId = <String, ProjectPresetCategory>{};
    for (final category in categories) {
      if (category.id.trim().isEmpty) {
        throw ValidationException('${_capitalize(label)} ID cannot be empty');
      }
      if (category.name.trim().isEmpty) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} has an empty name',
        );
      }
      byId[category.id] = category;
    }

    for (final category in categories) {
      final parentId = category.parentCategoryId;
      if (parentId == null) continue;
      if (!byId.containsKey(parentId)) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} references missing parent: $parentId',
        );
      }
      if (parentId == category.id) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final visited = <String>{category.id};
      while (cursor != null) {
        if (!visited.add(cursor)) {
          throw ValidationException(
            'Cycle detected in ${label}s at ${category.id}',
          );
        }
        cursor = byId[cursor]?.parentCategoryId;
      }
    }
  }

  static void _validateTerrainPresets(ProjectManifest manifest) {
    final tilesetIds = manifest.tilesets.map((tileset) => tileset.id).toSet();
    final categoryIds =
        manifest.terrainCategories.map((category) => category.id).toSet();

    for (final preset in manifest.terrainPresets) {
      if (preset.id.trim().isEmpty) {
        throw const ValidationException('Terrain preset ID cannot be empty');
      }
      if (preset.name.trim().isEmpty) {
        throw ValidationException(
          'Terrain preset ${preset.id} has an empty name',
        );
      }
      if (preset.terrainType == TerrainType.none) {
        throw ValidationException(
          'Terrain preset ${preset.id} cannot target terrain type "none"',
        );
      }
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && !tilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Terrain preset ${preset.id} references missing tileset: $tilesetId',
        );
      }
      final categoryId = preset.categoryId?.trim();
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          !categoryIds.contains(categoryId)) {
        throw ValidationException(
          'Terrain preset ${preset.id} references missing terrain category: $categoryId',
        );
      }
      for (var vi = 0; vi < preset.variants.length; vi++) {
        final variant = preset.variants[vi];
        if (variant.weight <= 0) {
          throw ValidationException(
            'Terrain preset ${preset.id} has an invalid variant weight',
          );
        }
        _validateVisualFrames(
          variant.frames,
          context: 'Terrain preset ${preset.id} variant index $vi',
          knownTilesetIds: tilesetIds,
        );
      }
    }
  }

  static void _validatePathPresets(ProjectManifest manifest) {
    final tilesetIds = manifest.tilesets.map((tileset) => tileset.id).toSet();
    final categoryIds =
        manifest.pathCategories.map((category) => category.id).toSet();

    for (final preset in manifest.pathPresets) {
      if (preset.id.trim().isEmpty) {
        throw const ValidationException('Path preset ID cannot be empty');
      }
      if (preset.name.trim().isEmpty) {
        throw ValidationException('Path preset ${preset.id} has an empty name');
      }
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && !tilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Path preset ${preset.id} references missing tileset: $tilesetId',
        );
      }
      final categoryId = preset.categoryId?.trim();
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          !categoryIds.contains(categoryId)) {
        throw ValidationException(
          'Path preset ${preset.id} references missing path category: $categoryId',
        );
      }
      final variants = <TerrainPathVariant>{};
      for (final mapping in preset.variants) {
        if (!variants.add(mapping.variant)) {
          throw ValidationException(
            'Path preset ${preset.id} has duplicate variant mapping: ${mapping.variant.name}',
          );
        }
        _validateVisualFrames(
          mapping.frames,
          context: 'Path preset ${preset.id} variant ${mapping.variant.name}',
          knownTilesetIds: tilesetIds,
        );
      }
    }

    final terrainTilesetIds = manifest.terrainPresets
        .map((preset) => preset.tilesetId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final preset in manifest.pathPresets) {
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && terrainTilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Tileset $tilesetId cannot be shared between terrain and path presets',
        );
      }
    }
  }

  static void _validateScenarios(ProjectManifest manifest) {
    final knownScriptIds = manifest.scripts.map((script) => script.id).toSet();
    final knownDialogueIds =
        manifest.dialogues.map((dialogue) => dialogue.id).toSet();
    final knownMapIds = manifest.maps.map((map) => map.id).toSet();
    final knownTrainerIds =
        manifest.trainers.map((trainer) => trainer.id).toSet();

    for (final scenario in manifest.scenarios) {
      final scenarioId = _requireProjectNonBlank(
        scenario.id,
        'Scenario ID cannot be empty',
      );
      _requireProjectNonBlank(
          scenario.name, 'Scenario $scenarioId has an empty name');

      // Outcomes déclarés: non vides et sans doublons.
      final declaredOutcomeIds = <String>{};
      for (final rawOutcomeId in scenario.declaredOutcomes) {
        final outcomeId = _requireProjectNonBlank(
          rawOutcomeId,
          'Scenario $scenarioId has an empty declared outcome',
        );
        if (!declaredOutcomeIds.add(outcomeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate declared outcome: $outcomeId',
          );
        }
      }

      // Condition d'activation scénario (gating global/local).
      if (scenario.activationCondition != null) {
        _validateScriptCondition(
          scenario.activationCondition!,
          contextLabel: 'Scenario $scenarioId activationCondition',
        );
      }

      if (scenario.nodes.isEmpty) {
        throw ValidationException('Scenario $scenarioId must contain nodes');
      }
      final nodeIds = <String>{};
      var startNodesCount = 0;
      for (final node in scenario.nodes) {
        final nodeId = _requireProjectNonBlank(
          node.id,
          'Scenario $scenarioId has a node with empty id',
        );
        if (!nodeIds.add(nodeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate node id: $nodeId',
          );
        }
        if (node.type == ScenarioNodeType.start) {
          startNodesCount++;
        }

        final actionKind = node.payload.actionKind?.trim() ?? '';
        final outcomeId = node.binding.outcomeId?.trim() ?? '';

        if (actionKind == _scenarioEmitOutcomeKind ||
            actionKind == _scenarioOutcomeSourceKind) {
          if (outcomeId.isEmpty) {
            throw ValidationException(
              'Scenario $scenarioId node $nodeId kind "$actionKind" requires outcomeId',
            );
          }
        }
        if (scenario.scope == ScenarioScope.globalStory &&
            _scenarioWorldSourceKinds.contains(actionKind)) {
          throw ValidationException(
            'Scenario $scenarioId is globalStory and cannot use world source kind: $actionKind',
          );
        }
        if (scenario.scope == ScenarioScope.localEventFlow &&
            actionKind == _scenarioOutcomeSourceKind) {
          throw ValidationException(
            'Scenario $scenarioId is localEventFlow and cannot use sourceOutcome',
          );
        }

        final binding = node.binding;
        final scriptId = binding.scriptId?.trim();
        if (scriptId != null &&
            scriptId.isNotEmpty &&
            !knownScriptIds.contains(scriptId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown script: $scriptId',
          );
        }
        final dialogueId = binding.dialogueId?.trim();
        if (dialogueId != null &&
            dialogueId.isNotEmpty &&
            !knownDialogueIds.contains(dialogueId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown dialogue: $dialogueId',
          );
        }
        final mapId = binding.mapId?.trim();
        if (mapId != null && mapId.isNotEmpty && !knownMapIds.contains(mapId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown map: $mapId',
          );
        }
        final trainerId = binding.trainerId?.trim();
        if (trainerId != null &&
            trainerId.isNotEmpty &&
            !knownTrainerIds.contains(trainerId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown trainer: $trainerId',
          );
        }
        final eventId = binding.eventId?.trim();
        if (eventId != null &&
            eventId.isNotEmpty &&
            (mapId == null || mapId.isEmpty)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId cannot define eventId without mapId',
          );
        }
        final condition = node.payload.condition;
        if (condition != null) {
          _validateScriptCondition(
            condition,
            contextLabel: 'Scenario $scenarioId node $nodeId condition',
          );
        }
      }
      if (startNodesCount != 1) {
        throw ValidationException(
          'Scenario $scenarioId must contain exactly one start node',
        );
      }
      final entryNodeId = _requireProjectNonBlank(
        scenario.entryNodeId,
        'Scenario $scenarioId has an empty entryNodeId',
      );
      if (!nodeIds.contains(entryNodeId)) {
        throw ValidationException(
          'Scenario $scenarioId entryNodeId references missing node: $entryNodeId',
        );
      }

      final edgeIds = <String>{};
      final outgoingByNode = <String, int>{};
      for (final edge in scenario.edges) {
        final edgeId = _requireProjectNonBlank(
          edge.id,
          'Scenario $scenarioId has an edge with empty id',
        );
        if (!edgeIds.add(edgeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate edge id: $edgeId',
          );
        }
        final fromNodeId = _requireProjectNonBlank(
          edge.fromNodeId,
          'Scenario $scenarioId edge $edgeId has empty fromNodeId',
        );
        final toNodeId = _requireProjectNonBlank(
          edge.toNodeId,
          'Scenario $scenarioId edge $edgeId has empty toNodeId',
        );
        if (!nodeIds.contains(fromNodeId)) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId references missing fromNodeId: $fromNodeId',
          );
        }
        if (!nodeIds.contains(toNodeId)) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId references missing toNodeId: $toNodeId',
          );
        }
        if (fromNodeId == toNodeId) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId cannot target the same node',
          );
        }
        outgoingByNode[fromNodeId] = (outgoingByNode[fromNodeId] ?? 0) + 1;
      }

      final nodeById = <String, ScenarioNode>{
        for (final node in scenario.nodes) node.id: node,
      };
      for (final entry in nodeById.entries) {
        final node = entry.value;
        final outgoing = outgoingByNode[node.id] ?? 0;
        if (node.type == ScenarioNodeType.choice && outgoing < 2) {
          throw ValidationException(
            'Scenario $scenarioId choice node ${node.id} must have at least two outgoing edges',
          );
        }
        if (node.type == ScenarioNodeType.condition && outgoing < 2) {
          throw ValidationException(
            'Scenario $scenarioId condition node ${node.id} must have at least two outgoing edges',
          );
        }
        if (node.type == ScenarioNodeType.end && outgoing > 0) {
          throw ValidationException(
            'Scenario $scenarioId end node ${node.id} cannot have outgoing edges',
          );
        }
      }
    }
  }

  static void _validateScriptCondition(
    ScriptCondition condition, {
    required String contextLabel,
  }) {
    for (final key in condition.params.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException('$contextLabel has an empty param key');
      }
    }
    switch (condition.type) {
      case ScriptConditionType.allOf:
      case ScriptConditionType.anyOf:
        if (condition.children.isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires at least one child',
          );
        }
        for (var i = 0; i < condition.children.length; i++) {
          _validateScriptCondition(
            condition.children[i],
            contextLabel: '$contextLabel.children[$i]',
          );
        }
        return;
      case ScriptConditionType.not:
        if (condition.children.length != 1) {
          throw ValidationException(
            '$contextLabel not requires exactly one child',
          );
        }
        _validateScriptCondition(
          condition.children.first,
          contextLabel: '$contextLabel.children[0]',
        );
        return;
      case ScriptConditionType.flagIsSet:
      case ScriptConditionType.flagIsUnset:
        final flagName = condition.params[ScriptConditionParams.flagName];
        if (flagName == null || flagName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty flagName',
          );
        }
        return;
      case ScriptConditionType.eventIsConsumed:
        final eventId = condition.params[ScriptConditionParams.eventId];
        if (eventId == null || eventId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel eventIsConsumed requires a non-empty eventId',
          );
        }
        return;
      case ScriptConditionType.playerOnMap:
        final mapId = condition.params[ScriptConditionParams.mapId];
        if (mapId == null || mapId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel playerOnMap requires a non-empty mapId',
          );
        }
        return;
      case ScriptConditionType.variableEquals:
      case ScriptConditionType.variableGreaterThan:
      case ScriptConditionType.variableLessThan:
        final variableName =
            condition.params[ScriptConditionParams.variableName];
        final value = condition.params[ScriptConditionParams.value];
        if (variableName == null || variableName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty variableName',
          );
        }
        if (value == null || value.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty value',
          );
        }
        return;
      case ScriptConditionType.fieldAbilityUnlocked:
        final ability = condition.params[ScriptConditionParams.ability];
        if (ability == null || ability.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel fieldAbilityUnlocked requires a non-empty ability',
          );
        }
        return;
      case ScriptConditionType.partyHasMove:
      case ScriptConditionType.partyHasUsableMove:
        final moveId = condition.params[ScriptConditionParams.moveId];
        if (moveId == null || moveId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty moveId',
          );
        }
        return;
    }
  }

  static String _requireProjectNonBlank(String value, String message) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ValidationException(message);
    }
    return trimmed;
  }

  static void _validateRelativePath(String path, String label) {
    final value = path.trim();
    if (value.isEmpty) {
      throw ValidationException('$label has an empty relativePath');
    }
    if (value.startsWith('/') || value.startsWith('\\')) {
      throw ValidationException('$label relativePath must be relative');
    }
    if (value.contains(':\\') || value.contains(':/')) {
      throw ValidationException('$label relativePath must not be absolute');
    }
    if (value.contains('..')) {
      throw ValidationException('$label relativePath must not escape project');
    }
  }

  static void _validateEncounterTables(List<ProjectEncounterTable> tables) {
    for (final table in tables) {
      final id = table.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Encounter table ID cannot be empty');
      }
      if (table.name.trim().isEmpty) {
        throw ValidationException('Encounter table $id name cannot be empty');
      }
      for (var i = 0; i < table.entries.length; i++) {
        final entry = table.entries[i];
        if (entry.speciesId.trim().isEmpty) {
          throw ValidationException(
            'Encounter table $id entry $i has empty speciesId',
          );
        }
        if (entry.minLevel <= 0 || entry.maxLevel <= 0) {
          throw ValidationException(
            'Encounter table $id entry $i levels must be positive',
          );
        }
        if (entry.minLevel > entry.maxLevel) {
          throw ValidationException(
            'Encounter table $id entry $i minLevel (${entry.minLevel}) > maxLevel (${entry.maxLevel})',
          );
        }
        if (entry.weight <= 0) {
          throw ValidationException(
            'Encounter table $id entry $i weight must be positive (got ${entry.weight})',
          );
        }
      }
    }
  }

  static void _validateTrainers(ProjectManifest manifest) {
    final elementIds = manifest.elements.map((e) => e.id).toSet();
    final characterIds = manifest.characters.map((c) => c.id).toSet();
    for (final trainer in manifest.trainers) {
      final id = trainer.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Trainer ID cannot be empty');
      }
      if (trainer.name.trim().isEmpty) {
        throw ValidationException('Trainer $id has an empty name');
      }
      if (trainer.trainerClass.trim().isEmpty) {
        throw ValidationException('Trainer $id has an empty trainerClass');
      }
      final battleDifficulty = trainer.battleDifficulty;
      if (battleDifficulty != null &&
          (battleDifficulty < 1 || battleDifficulty > 10)) {
        throw ValidationException(
          'Trainer $id battleDifficulty must stay within 1..10 (got $battleDifficulty)',
        );
      }
      final battleBackgroundRelativePath =
          trainer.battleBackgroundRelativePath?.trim();
      if (battleBackgroundRelativePath != null &&
          battleBackgroundRelativePath.isNotEmpty) {
        _validateRelativePath(
          battleBackgroundRelativePath,
          'Trainer $id battleBackgroundRelativePath',
        );
      }
      final characterId = trainer.characterId?.trim();
      if (characterId != null &&
          characterId.isNotEmpty &&
          !characterIds.contains(characterId)) {
        throw ValidationException(
          'Trainer $id characterId "$characterId" does not exist in project characters',
        );
      }
      final portraitId = trainer.portraitElementId?.trim();
      if (portraitId != null &&
          portraitId.isNotEmpty &&
          !elementIds.contains(portraitId)) {
        throw ValidationException(
          'Trainer $id portraitElementId "$portraitId" does not exist in project elements',
        );
      }
      for (var i = 0; i < trainer.team.length; i++) {
        final pokemon = trainer.team[i];
        if (pokemon.speciesId.trim().isEmpty) {
          throw ValidationException(
            'Trainer $id team[$i] has empty speciesId',
          );
        }
        if (pokemon.level <= 0) {
          throw ValidationException(
            'Trainer $id team[$i] level must be positive (got ${pokemon.level})',
          );
        }
      }
    }
  }

  static void _validateCharacters(ProjectManifest manifest) {
    final knownTilesetIds = manifest.tilesets.map((t) => t.id).toSet();
    for (final char in manifest.characters) {
      final id = char.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Character entry has an empty id');
      }
      if (char.name.trim().isEmpty) {
        throw ValidationException('Character $id has an empty name');
      }
      final tid = char.tilesetId.trim();
      if (tid.isEmpty) {
        throw ValidationException('Character $id has an empty tilesetId');
      }
      if (!knownTilesetIds.contains(tid)) {
        throw ValidationException(
          'Character $id references unknown tileset: $tid',
        );
      }
      if (char.frameWidth <= 0 || char.frameHeight <= 0) {
        throw ValidationException(
          'Character $id has invalid frame dimensions',
        );
      }
      for (var i = 0; i < char.animations.length; i++) {
        final anim = char.animations[i];
        for (var j = 0; j < anim.frames.length; j++) {
          final frame = anim.frames[j];
          final src = frame.source;
          if (src.x < 0 || src.y < 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j has invalid source coordinates',
            );
          }
          if (src.width <= 0 || src.height <= 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j has invalid source size',
            );
          }
          if (frame.durationMs <= 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j durationMs must be positive',
            );
          }
        }
      }
    }
    final playerCharId = manifest.settings.defaultPlayerCharacterId?.trim();
    if (playerCharId != null && playerCharId.isNotEmpty) {
      final charIds = manifest.characters.map((c) => c.id).toSet();
      if (!charIds.contains(playerCharId)) {
        throw ValidationException(
          'Settings defaultPlayerCharacterId "$playerCharId" references unknown character',
        );
      }
    }
  }

  static void _validateSettings(ProjectSettings settings) {
    if (settings.tileWidth <= 0 || settings.tileHeight <= 0) {
      throw const ValidationException('Tile size must be positive');
    }
    if (settings.displayScale <= 0) {
      throw const ValidationException('Display scale must be positive');
    }
    if (settings.defaultMapWidth <= 0 || settings.defaultMapHeight <= 0) {
      throw const ValidationException('Default map size must be positive');
    }
  }

  static void _validateUniqueIds<T>(
    List<T> items,
    String Function(T item) idSelector, {
    required String duplicateMessagePrefix,
  }) {
    final ids = <String>{};
    for (final item in items) {
      final id = idSelector(item).trim();
      if (id.isEmpty) continue;
      if (!ids.add(id)) {
        throw ValidationException('$duplicateMessagePrefix: $id');
      }
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class MapValidator {
  /// [projectDialogueContext] : si fourni, les [DialogueRef] sans chemin legacy doivent pointer vers [ProjectManifest.dialogues].
  static void validate(
    MapData map, {
    ProjectManifest? projectDialogueContext,
  }) {
    final mapId = _requireNonBlank(map.id, 'Map ID cannot be empty');
    _requireNonBlank(map.name, 'Map name cannot be empty');
    if (map.size.width <= 0 || map.size.height <= 0) {
      throw ValidationException(
        'Map $mapId has invalid size: ${map.size.width}x${map.size.height}',
      );
    }

    final expectedCellCount = map.size.width * map.size.height;
    for (final layer in map.layers) {
      _validateLayer(layer, expectedCellCount);
    }

    _validateUniqueIds(
      map.layers,
      (layer) => layer.id,
      duplicateMessagePrefix: 'Duplicate layer ID',
    );

    for (final entity in map.entities) {
      final entityId = _requireNonBlank(entity.id, 'Entity ID cannot be empty');
      _requireNonBlank(entity.kind.name, 'Entity $entityId has invalid kind');
      if (entity.size.width <= 0 || entity.size.height <= 0) {
        throw ValidationException(
          'Entity $entityId has invalid size: (${entity.size.width}x${entity.size.height})',
        );
      }
      _validatePositionInBounds(
        entity.pos,
        map.size,
        errorLabel: 'Entity $entityId origin',
      );
      final entityRight = entity.pos.x + entity.size.width;
      final entityBottom = entity.pos.y + entity.size.height;
      if (entityRight > map.size.width || entityBottom > map.size.height) {
        throw ValidationException(
          'Entity $entityId has an invalid area extending outside map bounds',
        );
      }
      for (final key in entity.properties.keys) {
        if (key.trim().isEmpty) {
          throw ValidationException(
            'Entity $entityId has an empty property key',
          );
        }
      }
      assertValidMapEntityTypedPayloads(entity);
      if (projectDialogueContext != null) {
        assertEntityDialogueRefsAgainstProject(entity, projectDialogueContext);
        assertEntityTrainerRefsAgainstProject(entity, projectDialogueContext);
        assertEntityCharacterRefsAgainstProject(entity, projectDialogueContext);
        assertEntityEditorVisualAgainstProject(entity, projectDialogueContext);
      }
    }
    _validateUniqueIds(
      map.entities,
      (entity) => entity.id,
      duplicateMessagePrefix: 'Duplicate entity ID',
    );

    final layerById = <String, MapLayer>{
      for (final layer in map.layers) layer.id: layer,
    };
    final elementById = projectDialogueContext == null
        ? const <String, ProjectElementEntry>{}
        : {
            for (final element in projectDialogueContext.elements)
              element.id: element,
          };

    for (final instance in map.placedElements) {
      final instanceId = _requireNonBlank(
        instance.id,
        'Placed element instance ID cannot be empty',
      );
      final layerId = _requireNonBlank(
        instance.layerId,
        'Placed element instance $instanceId has empty layerId',
      );
      final elementId = _requireNonBlank(
        instance.elementId,
        'Placed element instance $instanceId has empty elementId',
      );
      final layer = layerById[layerId];
      if (layer == null) {
        throw ValidationException(
          'Placed element instance $instanceId references unknown layer: $layerId',
        );
      }
      if (layer is! TileLayer) {
        throw ValidationException(
          'Placed element instance $instanceId must reference a tile layer: $layerId',
        );
      }
      _validatePositionInBounds(
        instance.pos,
        map.size,
        errorLabel: 'Placed element instance $instanceId origin',
      );
      for (final key in instance.properties.keys) {
        if (key.trim().isEmpty) {
          throw ValidationException(
            'Placed element instance $instanceId has an empty property key',
          );
        }
      }
      final animation = instance.animation;
      if (animation != null) {
        if (animation.speed <= 0) {
          throw ValidationException(
            'Placed element instance $instanceId has invalid animation speed: ${animation.speed}',
          );
        }
        final startOffsetMs = animation.startOffsetMs;
        if (startOffsetMs != null && startOffsetMs < 0) {
          throw ValidationException(
            'Placed element instance $instanceId has negative animation startOffsetMs: $startOffsetMs',
          );
        }
      }
      for (var behaviorIndex = 0;
          behaviorIndex < instance.behaviors.length;
          behaviorIndex++) {
        final behavior = instance.behaviors[behaviorIndex];
        final behaviorId = behavior.id.trim();
        const maxBehaviorCooldownMs = 600000;
        if (behaviorId.isEmpty) {
          throw ValidationException(
            'Placed element instance $instanceId behavior[$behaviorIndex] has empty id',
          );
        }
        for (var i = behaviorIndex + 1; i < instance.behaviors.length; i++) {
          if (instance.behaviors[i].id.trim() == behaviorId) {
            throw ValidationException(
              'Placed element instance $instanceId has duplicate behavior id "$behaviorId"',
            );
          }
        }
        final trigger = behavior.trigger;
        final triggerScope = behavior.triggerScope;
        switch (triggerScope) {
          case MapPlacedElementTriggerScope.defaultScope:
            break;
          case MapPlacedElementTriggerScope.oncePerEnter:
            if (trigger != MapPlacedElementTriggerType.onEnter) {
              throw ValidationException(
                'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope oncePerEnter requires trigger onEnter',
              );
            }
            break;
          case MapPlacedElementTriggerScope.whileInsideSingleShot:
            if (trigger != MapPlacedElementTriggerType.onEnter &&
                trigger != MapPlacedElementTriggerType.onNear) {
              throw ValidationException(
                'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope whileInsideSingleShot requires trigger onEnter or onNear',
              );
            }
            break;
          case MapPlacedElementTriggerScope.facingOnly:
            if (trigger != MapPlacedElementTriggerType.onAction &&
                trigger != MapPlacedElementTriggerType.onNear) {
              throw ValidationException(
                'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope facingOnly requires trigger onAction or onNear',
              );
            }
            break;
          case MapPlacedElementTriggerScope.nearCardinalOnly:
            if (trigger != MapPlacedElementTriggerType.onNear) {
              throw ValidationException(
                'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope nearCardinalOnly requires trigger onNear',
              );
            }
            break;
        }
        final cooldownMs = behavior.cooldownMs;
        if (cooldownMs != null) {
          if (cooldownMs < 0) {
            throw ValidationException(
              'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] has negative cooldownMs: $cooldownMs',
            );
          }
          if (cooldownMs > maxBehaviorCooldownMs) {
            throw ValidationException(
              'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] has excessive cooldownMs: $cooldownMs (max $maxBehaviorCooldownMs)',
            );
          }
        }
        final effect = behavior.effect;
        final behaviorLabel =
            'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId]';
        switch (effect.type) {
          case MapPlacedElementEffectType.showMessage:
            final message = effect.message?.trim() ?? '';
            if (message.isEmpty) {
              throw ValidationException(
                '$behaviorLabel showMessage requires a non-empty message',
              );
            }
            break;
          case MapPlacedElementEffectType.openDialogue:
            final dialogue = effect.dialogue;
            if (dialogue == null) {
              throw ValidationException(
                '$behaviorLabel openDialogue requires a dialogue reference',
              );
            }
            final dialogueId = dialogue.dialogueId.trim();
            if (dialogueId.isEmpty) {
              throw ValidationException(
                '$behaviorLabel openDialogue requires a non-empty dialogueId',
              );
            }
            final scriptPath = dialogue.scriptPathRelative.trim();
            if (scriptPath.startsWith('/') || scriptPath.startsWith(r'\')) {
              throw ValidationException(
                '$behaviorLabel dialogue scriptPathRelative must be relative',
              );
            }
            if (scriptPath.contains('..')) {
              throw ValidationException(
                '$behaviorLabel dialogue scriptPathRelative must not contain ..',
              );
            }
            assertValidDialogueStartNode(
              dialogue.startNode,
              contextLabel: '$behaviorLabel dialogue',
            );
            if (projectDialogueContext != null && scriptPath.isEmpty) {
              final exists = projectDialogueContext.dialogues
                  .any((entry) => entry.id == dialogueId);
              if (!exists) {
                throw ValidationException(
                  '$behaviorLabel references unknown dialogue id "$dialogueId"',
                );
              }
            }
            break;
          case MapPlacedElementEffectType.setAnimationEnabled:
            if (effect.animationEnabled == null) {
              throw ValidationException(
                '$behaviorLabel setAnimationEnabled requires animationEnabled',
              );
            }
            break;
          case MapPlacedElementEffectType.playAnimationOnce:
            break;
        }
      }
      if (projectDialogueContext != null) {
        final element = elementById[elementId];
        if (element == null) {
          throw ValidationException(
            'Placed element instance $instanceId references unknown element: $elementId',
          );
        }
        final layerTilesetId = (layer.tilesetId ?? map.tilesetId).trim();
        final elementTilesetId = _resolveElementPrimaryTilesetId(element);
        if (layerTilesetId.isNotEmpty &&
            elementTilesetId.isNotEmpty &&
            layerTilesetId != elementTilesetId) {
          throw ValidationException(
            'Placed element instance $instanceId references element $elementId from tileset $elementTilesetId, but layer $layerId uses tileset $layerTilesetId',
          );
        }
        final source = element.frames.primarySource;
        final width = source.width <= 0 ? 1 : source.width;
        final height = source.height <= 0 ? 1 : source.height;
        final right = instance.pos.x + width;
        final bottom = instance.pos.y + height;
        if (right > map.size.width || bottom > map.size.height) {
          throw ValidationException(
            'Placed element instance $instanceId footprint ${width}x$height exceeds map bounds from origin (${instance.pos.x}, ${instance.pos.y})',
          );
        }
        if (animation != null && animation.enabled && element.frames.isEmpty) {
          throw ValidationException(
            'Placed element instance $instanceId enables animation but source element $elementId has no frames',
          );
        }
      }
    }
    _validateUniqueIds(
      map.placedElements,
      (instance) => instance.id,
      duplicateMessagePrefix: 'Duplicate placed element instance ID',
    );

    final seenConnectionDirections = <MapConnectionDirection>{};
    for (final connection in map.connections) {
      final targetMapId = _requireNonBlank(
        connection.targetMapId,
        'Map connection ${connection.direction.name} has empty targetMapId',
      );
      if (targetMapId == mapId) {
        throw ValidationException(
          'Map connection ${connection.direction.name} cannot target its own map',
        );
      }
      if (!seenConnectionDirections.add(connection.direction)) {
        throw ValidationException(
          'Duplicate map connection direction: ${connection.direction.name}',
        );
      }
    }

    final scriptIds = projectDialogueContext == null
        ? null
        : {
            for (final script in projectDialogueContext.scripts) script.id,
          };
    final layerIds = <String>{for (final layer in map.layers) layer.id};
    for (final event in map.events) {
      _validateMapEvent(
        map,
        event,
        layerIds: layerIds,
        knownScriptIds: scriptIds,
      );
    }
    _validateUniqueIds(
      map.events,
      (event) => event.id,
      duplicateMessagePrefix: 'Duplicate map event ID',
    );

    for (final warp in map.warps) {
      final warpId = _requireNonBlank(warp.id, 'Warp ID cannot be empty');
      _requireNonBlank(warp.targetMapId, 'Warp $warpId has empty targetMapId');
      _validatePositionInBounds(
        warp.pos,
        map.size,
        errorLabel: 'Warp $warpId',
      );
      if (warp.targetPos.x < 0 || warp.targetPos.y < 0) {
        throw ValidationException(
          'Warp $warpId has invalid target position: (${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      if (warp.triggerPadding.top < 0 ||
          warp.triggerPadding.right < 0 ||
          warp.triggerPadding.bottom < 0 ||
          warp.triggerPadding.left < 0) {
        throw ValidationException(
          'Warp $warpId has invalid negative trigger padding',
        );
      }
      final seenApproach = <EntityFacing>{};
      for (final facing in warp.allowedApproachFacings) {
        if (!seenApproach.add(facing)) {
          throw ValidationException(
            'Warp $warpId has duplicate allowed approach facing: ${facing.name}',
          );
        }
      }
    }
    _validateUniqueIds(
      map.warps,
      (warp) => warp.id,
      duplicateMessagePrefix: 'Duplicate warp ID',
    );

    for (final trigger in map.triggers) {
      final triggerId =
          _requireNonBlank(trigger.id, 'Trigger ID cannot be empty');
      _requireNonBlank(
          trigger.type.name, 'Trigger $triggerId has invalid type');
      for (final key in trigger.properties.keys) {
        if (key.trim().isEmpty) {
          throw ValidationException(
              'Trigger $triggerId has an empty property key');
        }
      }
      _validatePositionInBounds(
        trigger.area.pos,
        map.size,
        errorLabel: 'Trigger $triggerId area origin',
      );
      if (trigger.area.size.width <= 0 || trigger.area.size.height <= 0) {
        throw ValidationException(
          'Trigger $triggerId has invalid area size: (${trigger.area.size.width}x${trigger.area.size.height})',
        );
      }

      final zoneRight = trigger.area.pos.x + trigger.area.size.width;
      final zoneBottom = trigger.area.pos.y + trigger.area.size.height;
      if (zoneRight > map.size.width || zoneBottom > map.size.height) {
        throw ValidationException(
          'Trigger $triggerId has an invalid area extending outside map bounds',
        );
      }
    }
    _validateUniqueIds(
      map.triggers,
      (trigger) => trigger.id,
      duplicateMessagePrefix: 'Duplicate trigger ID',
    );

    for (final zone in map.gameplayZones) {
      final zoneId =
          _requireNonBlank(zone.id, 'Gameplay zone ID cannot be empty');
      _requireNonBlank(
          zone.kind.name, 'Gameplay zone $zoneId has invalid kind');
      final specialProps = zone.special?.properties;
      if (specialProps != null) {
        for (final key in specialProps.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
              'Gameplay zone $zoneId has an empty special property key',
            );
          }
        }
      }
      _validatePositionInBounds(
        zone.area.pos,
        map.size,
        errorLabel: 'Gameplay zone $zoneId area origin',
      );
      if (zone.area.size.width <= 0 || zone.area.size.height <= 0) {
        throw ValidationException(
          'Gameplay zone $zoneId has invalid area size: '
          '(${zone.area.size.width}x${zone.area.size.height})',
        );
      }
      final zoneRight = zone.area.pos.x + zone.area.size.width;
      final zoneBottom = zone.area.pos.y + zone.area.size.height;
      if (zoneRight > map.size.width || zoneBottom > map.size.height) {
        throw ValidationException(
          'Gameplay zone $zoneId area extends outside map bounds',
        );
      }
    }
    _validateUniqueIds(
      map.gameplayZones,
      (zone) => zone.id,
      duplicateMessagePrefix: 'Duplicate gameplay zone ID',
    );

    _validateMapMetadata(map);
  }

  static void _validateMapMetadata(MapData map) {
    final md = map.mapMetadata;
    if (md.musicId != null && md.musicId!.trim().isEmpty) {
      throw ValidationException(
        'Map metadata musicId must be null or a non-blank string',
      );
    }
    if (md.defaultSpawnId != null && md.defaultSpawnId!.trim().isEmpty) {
      throw ValidationException(
        'Map metadata defaultSpawnId must be null or a non-blank string',
      );
    }
    final seenTags = <String>{};
    for (final tag in md.tags) {
      final t = tag.trim();
      if (t.isEmpty) {
        throw ValidationException(
          'Map metadata tags must not contain empty or whitespace-only entries',
        );
      }
      if (tag != t) {
        throw ValidationException(
          'Map metadata tags must be stored without leading or trailing whitespace',
        );
      }
      if (!seenTags.add(t)) {
        throw ValidationException(
          'Map metadata tags must be unique (duplicate: "$t")',
        );
      }
    }
    final spawnId = md.defaultSpawnId?.trim();
    if (spawnId != null && spawnId.isNotEmpty) {
      final keys = <String>{};
      final entityIds = <String>{};
      for (final e in map.entities) {
        if (e.kind == MapEntityKind.spawn) {
          entityIds.add(e.id);
          final k = e.spawn?.spawnKey.trim() ?? '';
          if (k.isNotEmpty) keys.add(k);
        }
      }
      if (!keys.contains(spawnId) && !entityIds.contains(spawnId)) {
        throw ValidationException(
          'Map metadata defaultSpawnId "$spawnId" does not match any spawn key or spawn entity id on this map',
        );
      }
    }
  }

  static void _validateMapEvent(
    MapData map,
    MapEventDefinition event, {
    required Set<String> layerIds,
    required Set<String>? knownScriptIds,
  }) {
    final eventId = _requireNonBlank(event.id, 'Map event ID cannot be empty');
    final layerId = _requireNonBlank(
      event.position.layerId,
      'Map event $eventId has empty layerId',
    );
    if (!layerIds.contains(layerId)) {
      throw ValidationException(
        'Map event $eventId references unknown layer: $layerId',
      );
    }
    _validatePositionInBounds(
      GridPos(x: event.position.x, y: event.position.y),
      map.size,
      errorLabel: 'Map event $eventId position',
    );
    if (event.pages.isEmpty) {
      throw ValidationException(
        'Map event $eventId must contain at least one page',
      );
    }
    for (final key in event.metadata.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Map event $eventId has an empty metadata key',
        );
      }
    }

    final pageNumbers = <int>{};
    for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
      final page = event.pages[pageIndex];
      if (page.pageNumber < 0) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] has negative pageNumber: ${page.pageNumber}',
        );
      }
      if (!pageNumbers.add(page.pageNumber)) {
        throw ValidationException(
          'Map event $eventId has duplicate pageNumber: ${page.pageNumber}',
        );
      }
      _validateMapEventPage(
        eventId: eventId,
        pageIndex: pageIndex,
        page: page,
        knownScriptIds: knownScriptIds,
      );
    }
  }

  static void _validateMapEventPage({
    required String eventId,
    required int pageIndex,
    required MapEventPage page,
    required Set<String>? knownScriptIds,
  }) {
    for (final key in page.metadata.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] has an empty metadata key',
        );
      }
    }
    final script = page.script;
    if (script != null) {
      final scriptId = _requireNonBlank(
        script.scriptId,
        'Map event $eventId page[$pageIndex] has empty scriptId',
      );
      if (knownScriptIds != null && !knownScriptIds.contains(scriptId)) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] references unknown script: $scriptId',
        );
      }
      final startNode = script.startNode?.trim();
      if (startNode != null && startNode.isEmpty) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] startNode must be null or non-empty',
        );
      }
    }
    final condition = page.condition;
    if (condition != null) {
      _validateScriptCondition(
        condition,
        contextLabel: 'Map event $eventId page[$pageIndex] condition',
      );
    }
  }

  static void _validateScriptCondition(
    ScriptCondition condition, {
    required String contextLabel,
  }) {
    for (final key in condition.params.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException('$contextLabel has an empty param key');
      }
    }
    switch (condition.type) {
      case ScriptConditionType.allOf:
      case ScriptConditionType.anyOf:
        if (condition.children.isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires at least one child',
          );
        }
        for (var i = 0; i < condition.children.length; i++) {
          _validateScriptCondition(
            condition.children[i],
            contextLabel: '$contextLabel.children[$i]',
          );
        }
        return;
      case ScriptConditionType.not:
        if (condition.children.length != 1) {
          throw ValidationException(
            '$contextLabel not requires exactly one child',
          );
        }
        _validateScriptCondition(
          condition.children.first,
          contextLabel: '$contextLabel.children[0]',
        );
        return;
      case ScriptConditionType.flagIsSet:
      case ScriptConditionType.flagIsUnset:
        final flagName = condition.params[ScriptConditionParams.flagName];
        if (flagName == null || flagName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty flagName',
          );
        }
        return;
      case ScriptConditionType.eventIsConsumed:
        final eventId = condition.params[ScriptConditionParams.eventId];
        if (eventId == null || eventId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel eventIsConsumed requires a non-empty eventId',
          );
        }
        return;
      case ScriptConditionType.playerOnMap:
        final mapId = condition.params[ScriptConditionParams.mapId];
        if (mapId == null || mapId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel playerOnMap requires a non-empty mapId',
          );
        }
        return;
      case ScriptConditionType.variableEquals:
      case ScriptConditionType.variableGreaterThan:
      case ScriptConditionType.variableLessThan:
        final variableName =
            condition.params[ScriptConditionParams.variableName];
        final value = condition.params[ScriptConditionParams.value];
        if (variableName == null || variableName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty variableName',
          );
        }
        if (value == null || value.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty value',
          );
        }
        return;
      case ScriptConditionType.fieldAbilityUnlocked:
        final ability = condition.params[ScriptConditionParams.ability];
        if (ability == null || ability.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel fieldAbilityUnlocked requires a non-empty ability',
          );
        }
        return;
      case ScriptConditionType.partyHasMove:
      case ScriptConditionType.partyHasUsableMove:
        final moveId = condition.params[ScriptConditionParams.moveId];
        if (moveId == null || moveId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty moveId',
          );
        }
        return;
    }
  }

  static void _validateLayer(MapLayer layer, int expectedCellCount) {
    final layerId = _requireNonBlank(layer.id, 'Layer ID cannot be empty');
    _requireNonBlank(layer.name, 'Layer $layerId name cannot be empty');
    if (layer.opacity < 0.0 || layer.opacity > 1.0) {
      throw ValidationException(
        'Layer $layerId has invalid opacity: ${layer.opacity}',
      );
    }

    layer.map<void>(
      tile: (tileLayer) {
        final layerTilesetId = tileLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isEmpty) {
          throw ValidationException(
              'Tile layer $layerId has an empty tilesetId');
        }
        if (tileLayer.tiles.length != expectedCellCount) {
          throw ValidationException(
            'Tile layer $layerId has invalid tile count: expected $expectedCellCount, got ${tileLayer.tiles.length}',
          );
        }
        for (var i = 0; i < tileLayer.tiles.length; i++) {
          if (tileLayer.tiles[i] < 0) {
            throw ValidationException(
              'Tile layer $layerId has negative tile ID at index $i: ${tileLayer.tiles[i]}',
            );
          }
        }
      },
      collision: (collisionLayer) {
        if (collisionLayer.collisions.length != expectedCellCount) {
          throw ValidationException(
            'Collision layer $layerId has invalid collision count: expected $expectedCellCount, got ${collisionLayer.collisions.length}',
          );
        }
      },
      terrain: (terrainLayer) {
        if (terrainLayer.terrains.length != expectedCellCount) {
          throw ValidationException(
            'Terrain layer $layerId has invalid terrain count: expected $expectedCellCount, got ${terrainLayer.terrains.length}',
          );
        }
      },
      path: (pathLayer) {
        if (pathLayer.cells.length != expectedCellCount) {
          throw ValidationException(
            'Path layer $layerId has invalid cell count: expected $expectedCellCount, got ${pathLayer.cells.length}',
          );
        }
        for (final key in pathLayer.properties.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
                'Path layer $layerId has an empty property key');
          }
        }
        final triggerIds = <String>{};
        for (var i = 0; i < pathLayer.animationTriggers.length; i++) {
          final trigger = pathLayer.animationTriggers[i];
          final resolvedId =
              trigger.id.trim().isEmpty ? 'rule_$i' : trigger.id.trim();
          if (!triggerIds.add(resolvedId)) {
            throw ValidationException(
              'Path layer $layerId has duplicate animation trigger id: $resolvedId',
            );
          }
          if (trigger.mode == PathAnimationPlaybackMode.loopWhileActive &&
              trigger.trigger != PathAnimationTriggerType.whileInside) {
            throw ValidationException(
              'Path layer $layerId trigger[$resolvedId] mode loopWhileActive requires trigger whileInside',
            );
          }
          if (trigger.trigger == PathAnimationTriggerType.whileInside &&
              trigger.mode != PathAnimationPlaybackMode.loopWhileActive) {
            throw ValidationException(
              'Path layer $layerId trigger[$resolvedId] trigger whileInside requires mode loopWhileActive',
            );
          }
        }
      },
      object: (_) {},
    );
  }

  static String _resolveElementPrimaryTilesetId(ProjectElementEntry element) {
    final frameTilesetId = element.frames.primaryFrame.tilesetId.trim();
    if (frameTilesetId.isNotEmpty) {
      return frameTilesetId;
    }
    return element.tilesetId.trim();
  }

  static String _requireNonBlank(String value, String message) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ValidationException(message);
    }
    return trimmed;
  }

  static void _validatePositionInBounds(
    GridPos pos,
    GridSize mapSize, {
    required String errorLabel,
  }) {
    if (pos.x < 0 ||
        pos.y < 0 ||
        pos.x >= mapSize.width ||
        pos.y >= mapSize.height) {
      throw ValidationException(
        '$errorLabel is out of map bounds at (${pos.x}, ${pos.y})',
      );
    }
  }

  static void _validateUniqueIds<T>(
    List<T> items,
    String Function(T item) idSelector, {
    required String duplicateMessagePrefix,
  }) {
    final ids = <String>{};
    for (final item in items) {
      final id = idSelector(item).trim();
      if (id.isEmpty) continue;
      if (!ids.add(id)) {
        throw ValidationException('$duplicateMessagePrefix: $id');
      }
    }
  }
}

```

### `packages/map_core/test/project_trainer_validation_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTrainerEntry validation', () {
    test('rejects battleDifficulty values outside the authored 1..10 range',
        () {
      final manifest = ProjectManifest(
        name: 'trainer_validation_test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'rookie',
            name: 'Rookie',
            trainerClass: 'Trainer',
            battleDifficulty: 11,
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.toString(),
            'message',
            contains('battleDifficulty'),
          ),
        ),
      );
    });

    test('rejects trainer battle background paths that escape the project', () {
      final manifest = ProjectManifest(
        name: 'trainer_validation_test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'rookie',
            name: 'Rookie',
            trainerClass: 'Trainer',
            battleBackgroundRelativePath: '../outside.png',
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.toString(),
            'message',
            contains('battleBackgroundRelativePath'),
          ),
        ),
      );
    });
  });
}

```

### `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

// ---------------------------------------------------------------------------
// Helpers internes
// ---------------------------------------------------------------------------

String _generateUniqueTrainerId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'trainer' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = project.trainers.map((t) => t.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

// Le lot 7 continue à garder le manifest comme source de vérité.
//
// On normalise donc seulement les listes éditées depuis l'UI :
// - trim ;
// - suppression des entrées vides ;
// - aucun "smart merge" ni déduction implicite.
List<String> _normalizeTrainerStringList(Iterable<String> rawValues) {
  return rawValues
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

String? _normalizeOptionalTrainerRelativePath(String? rawValue) {
  final trimmed = rawValue?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return p.posix.normalize(trimmed.replaceAll(r'\', '/'));
}

// ---------------------------------------------------------------------------
// Use cases — dresseurs
// ---------------------------------------------------------------------------

class CreateTrainerUseCase {
  CreateTrainerUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required String trainerClass,
    int? battleDifficulty,
    String? battleBackgroundRelativePath,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    List<String> tags = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Trainer name cannot be empty');
    }
    final trimmedClass = trainerClass.trim();
    if (trimmedClass.isEmpty) {
      throw const EditorValidationException('Trainer class cannot be empty');
    }
    final trainer = ProjectTrainerEntry(
      id: _generateUniqueTrainerId(project, trimmedName),
      name: trimmedName,
      trainerClass: trimmedClass,
      battleDifficulty: battleDifficulty,
      battleBackgroundRelativePath: _normalizeOptionalTrainerRelativePath(
        battleBackgroundRelativePath,
      ),
      characterId:
          characterId?.trim().isEmpty == true ? null : characterId?.trim(),
      portraitElementId: portraitElementId?.trim().isEmpty == true
          ? null
          : portraitElementId?.trim(),
      battleThemeId:
          battleThemeId?.trim().isEmpty == true ? null : battleThemeId?.trim(),
      victoryThemeId: victoryThemeId?.trim().isEmpty == true
          ? null
          : victoryThemeId?.trim(),
      tags: _normalizeTrainerStringList(tags),
    );
    final updated = project.copyWith(
      trainers: [...project.trainers, trainer],
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateTrainerUseCase {
  UpdateTrainerUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? battleDifficulty = _unset,
    Object? battleBackgroundRelativePath = _unset,
    Object? characterId = _unset,
    Object? portraitElementId = _unset,
    Object? battleThemeId = _unset,
    Object? victoryThemeId = _unset,
    List<String>? tags,
  }) async {
    final index = project.trainers.indexWhere((t) => t.id == trainerId);
    if (index < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final current = project.trainers[index];
    final trimmedName = name?.trim() ?? current.name;
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Trainer name cannot be empty');
    }
    final trimmedClass = trainerClass?.trim() ?? current.trainerClass;
    if (trimmedClass.isEmpty) {
      throw const EditorValidationException('Trainer class cannot be empty');
    }
    var updatedTrainer = current.copyWith(
      name: trimmedName,
      trainerClass: trimmedClass,
      tags: tags == null ? current.tags : _normalizeTrainerStringList(tags),
    );
    if (!identical(battleDifficulty, _unset)) {
      updatedTrainer = updatedTrainer.copyWith(
        battleDifficulty: battleDifficulty as int?,
      );
    }
    if (!identical(battleBackgroundRelativePath, _unset)) {
      updatedTrainer = updatedTrainer.copyWith(
        battleBackgroundRelativePath: _normalizeOptionalTrainerRelativePath(
          battleBackgroundRelativePath as String?,
        ),
      );
    }
    if (!identical(characterId, _unset)) {
      final v = (characterId as String?)?.trim();
      updatedTrainer = updatedTrainer.copyWith(
        characterId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(portraitElementId, _unset)) {
      final v = (portraitElementId as String?)?.trim();
      updatedTrainer = updatedTrainer.copyWith(
        portraitElementId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(battleThemeId, _unset)) {
      final v = (battleThemeId as String?)?.trim();
      updatedTrainer = updatedTrainer.copyWith(
        battleThemeId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(victoryThemeId, _unset)) {
      final v = (victoryThemeId as String?)?.trim();
      updatedTrainer = updatedTrainer.copyWith(
        victoryThemeId: (v == null || v.isEmpty) ? null : v,
      );
    }
    final trainers = List<ProjectTrainerEntry>.from(project.trainers);
    trainers[index] = updatedTrainer;
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

const Object _unset = Object();

class DeleteTrainerUseCase {
  DeleteTrainerUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
  }) async {
    final index = project.trainers.indexWhere((t) => t.id == trainerId);
    if (index < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final trainers = List<ProjectTrainerEntry>.from(project.trainers)
      ..removeAt(index);
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

// ---------------------------------------------------------------------------
// Use cases — équipe Pokémon
// ---------------------------------------------------------------------------

class AddTrainerPokemonUseCase {
  AddTrainerPokemonUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const [],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final index = project.trainers.indexWhere((t) => t.id == trainerId);
    if (index < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final trimmedSpecies = speciesId.trim();
    if (trimmedSpecies.isEmpty) {
      throw const EditorValidationException('Species ID cannot be empty');
    }
    if (level <= 0) {
      throw const EditorValidationException('Level must be positive');
    }
    final pokemon = ProjectTrainerPokemonEntry(
      speciesId: trimmedSpecies,
      level: level,
      moves: _normalizeTrainerStringList(moves),
      heldItemId:
          heldItemId?.trim().isEmpty == true ? null : heldItemId?.trim(),
      formId: formId?.trim().isEmpty == true ? null : formId?.trim(),
      gender: gender?.trim().isEmpty == true ? null : gender?.trim(),
      shiny: shiny,
    );
    final trainer = project.trainers[index];
    final updatedTrainer = trainer.copyWith(team: [...trainer.team, pokemon]);
    final trainers = List<ProjectTrainerEntry>.from(project.trainers);
    trainers[index] = updatedTrainer;
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateTrainerPokemonUseCase {
  UpdateTrainerPokemonUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _unset,
    Object? formId = _unset,
    Object? gender = _unset,
    bool? shiny,
  }) async {
    final trainerIndex = project.trainers.indexWhere((t) => t.id == trainerId);
    if (trainerIndex < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final trainer = project.trainers[trainerIndex];
    if (pokemonIndex < 0 || pokemonIndex >= trainer.team.length) {
      throw EditorNotFoundException(
        'Pokemon index $pokemonIndex out of range for trainer $trainerId',
      );
    }
    final current = trainer.team[pokemonIndex];
    final trimmedSpecies = speciesId?.trim() ?? current.speciesId;
    if (trimmedSpecies.isEmpty) {
      throw const EditorValidationException('Species ID cannot be empty');
    }
    final newLevel = level ?? current.level;
    if (newLevel <= 0) {
      throw const EditorValidationException('Level must be positive');
    }
    var updatedPokemon = current.copyWith(
      speciesId: trimmedSpecies,
      level: newLevel,
      moves: moves == null ? current.moves : _normalizeTrainerStringList(moves),
      shiny: shiny ?? current.shiny,
    );
    if (!identical(heldItemId, _unset)) {
      final v = (heldItemId as String?)?.trim();
      updatedPokemon = updatedPokemon.copyWith(
        heldItemId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(formId, _unset)) {
      final v = (formId as String?)?.trim();
      updatedPokemon = updatedPokemon.copyWith(
        formId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(gender, _unset)) {
      final v = (gender as String?)?.trim();
      updatedPokemon = updatedPokemon.copyWith(
        gender: (v == null || v.isEmpty) ? null : v,
      );
    }
    final team = List<ProjectTrainerPokemonEntry>.from(trainer.team);
    team[pokemonIndex] = updatedPokemon;
    final updatedTrainer = trainer.copyWith(team: team);
    final trainers = List<ProjectTrainerEntry>.from(project.trainers);
    trainers[trainerIndex] = updatedTrainer;
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteTrainerPokemonUseCase {
  DeleteTrainerPokemonUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final trainerIndex = project.trainers.indexWhere((t) => t.id == trainerId);
    if (trainerIndex < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final trainer = project.trainers[trainerIndex];
    if (pokemonIndex < 0 || pokemonIndex >= trainer.team.length) {
      throw EditorNotFoundException(
        'Pokemon index $pokemonIndex out of range for trainer $trainerId',
      );
    }
    final team = List<ProjectTrainerPokemonEntry>.from(trainer.team)
      ..removeAt(pokemonIndex);
    final updatedTrainer = trainer.copyWith(team: team);
    final trainers = List<ProjectTrainerEntry>.from(project.trainers);
    trainers[trainerIndex] = updatedTrainer;
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

```

### `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/content_studio_providers.dart';
import '../../../app/providers/core_providers.dart';
import '../../../app/providers/editor_workspace_providers.dart';
import '../../../app/providers/use_case_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/map_tool_preview.dart';
import '../../../application/models/path_autotile_set.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/editor_map_session_coordinator.dart';
import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../../../application/services/element_collision_profile_generator.dart';
import '../../../application/services/entity_editing_service.dart';
import '../../../application/services/gameplay_zone_editing_service.dart';
import '../../../application/services/map_connection_editing_service.dart';
import '../../../application/services/path_autotile_resolver.dart';
import '../../../application/services/path_layer_editing_coordinator.dart';
import '../../../application/services/placed_element_instance_indexer.dart';
import '../../../application/services/terrain_painting_coordinator.dart';
import '../../../application/services/terrain_preset_resolver.dart';
import '../../../application/services/terrain_preset_selection_coordinator.dart';
import '../../../application/services/trigger_editing_service.dart';
import '../../../application/services/warp_editing_service.dart';
import '../application/editor_workspace_controller.dart';
import '../application/map_editing_controller.dart';
import '../application/map_selection_controller.dart';
import '../application/project_content_controller.dart';
import '../application/project_session_controller.dart';
import '../application/project_session_models.dart';
import '../tools/editor_tool.dart';
import 'editor_state.dart';

part 'editor_notifier.g.dart';

/// Valeur sentinelle pour les paramètres optionnels nullable dans [EditorNotifier].
const Object _trainerUnset = Object();
const String _lastOpenedProjectManifestKey = 'lastOpenedProjectManifestPath';
const String _editorSessionFileName = 'editor_session_state.json';
const MethodChannel _macOsFileAccessChannel =
    MethodChannel('map_editor/file_access');

@riverpod
class EditorNotifier extends _$EditorNotifier {
  EditorWorkspaceController get _editorWorkspaceController =>
      ref.read(editorWorkspaceControllerProvider);
  MapEditingController get _mapEditingController => MapEditingController(
        mutationCoordinator: _editorMapMutationCoordinator,
      );
  MapSelectionController get _mapSelectionController => MapSelectionController(
        terrainPresetSelectionCoordinator: _terrainPresetSelectionCoordinator,
      );
  ProjectContentController get _projectContentController =>
      ref.read(projectContentControllerProvider);
  ProjectSessionController get _projectSessionController =>
      const ProjectSessionController();
  TerrainPresetResolver get _terrainPresetResolver =>
      ref.read(terrainPresetResolverProvider);
  TerrainPresetSelectionCoordinator get _terrainPresetSelectionCoordinator =>
      ref.read(terrainPresetSelectionCoordinatorProvider);
  PathAutotileResolver get _pathAutotileResolver =>
      ref.read(pathAutotileResolverProvider);
  EditorMapSessionCoordinator get _editorMapSessionCoordinator =>
      ref.read(editorMapSessionCoordinatorProvider);
  EditorMapMutationCoordinator get _editorMapMutationCoordinator =>
      ref.read(editorMapMutationCoordinatorProvider);
  ProjectWorkspaceFactory get _projectWorkspaceFactory =>
      ref.read(projectWorkspaceFactoryProvider);
  ProjectWorkspace? get _projectWorkspace {
    final projectRootPath = state.projectSession.projectRootPath;
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return null;
    }
    return _projectWorkspaceFactory.create(projectRootPath);
  }

  WarpEditingService get _warpEditingService =>
      ref.read(warpEditingServiceProvider);
  EntityEditingService get _entityEditingService =>
      ref.read(entityEditingServiceProvider);
  TriggerEditingService get _triggerEditingService =>
      ref.read(triggerEditingServiceProvider);
  GameplayZoneEditingService get _gameplayZoneEditingService =>
      ref.read(gameplayZoneEditingServiceProvider);
  MapConnectionEditingService get _mapConnectionEditingService =>
      ref.read(mapConnectionEditingServiceProvider);
  TerrainPaintingCoordinator get _terrainPaintingCoordinator =>
      ref.read(terrainPaintingCoordinatorProvider);
  PathLayerEditingCoordinator get _pathLayerEditingCoordinator =>
      ref.read(pathLayerEditingCoordinatorProvider);
  ElementCollisionProfileGenerator get _elementCollisionProfileGenerator =>
      ref.read(elementCollisionProfileGeneratorProvider);
  PlacedElementInstanceIndexer get _placedElementInstanceIndexer =>
      ref.read(placedElementInstanceIndexerProvider);

  TerrainPresetSelection _currentTerrainPresetSelection() {
    final selection = state.selection;
    return TerrainPresetSelection(
      selectionMode: selection.terrainSelectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
    );
  }

  EditorState _copyStateWithTerrainPresetSelection(
    EditorState source,
    TerrainPresetSelection selection, {
    String? statusMessage,
    String? errorMessage,
    EditorToolType? activeTool,
  }) {
    return source.copyWith(
      terrainSelectionMode: selection.selectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
      activeTool: activeTool ?? source.activeTool,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  EditorState build() {
    return const EditorState();
  }

  /// Returns the persisted manifest path of the most recently opened project.
  ///
  /// This is intentionally tiny and file-based (single JSON file in app support)
  /// to keep startup deterministic and avoid introducing extra dependencies.
  Future<String?> getLastOpenedProjectManifestPath() async {
    try {
      final file = await _sessionStateFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final value = decoded[_lastOpenedProjectManifestKey];
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // Startup memory should never crash the editor. Any corrupted or
      // unreadable state is treated as "no remembered project".
      return null;
    }
  }

  /// Attempts to load the last opened project (if any).
  ///
  /// Returns true only when a project was actually restored.
  Future<bool> restoreLastOpenedProjectIfAny() async {
    // Do not override an already loaded project.
    if (state.project != null) {
      return false;
    }
    // On macOS sandbox, a plain path is not enough after restart.
    // We first ask native code to resolve a security-scoped bookmark if any.
    final manifestPath = await _resolveLastProjectManifestFromMacOsBookmark() ??
        await getLastOpenedProjectManifestPath();
    if (manifestPath == null) {
      return false;
    }
    if (!await File(manifestPath).exists()) {
      // Clear stale memory so the app won't re-check a dead path forever.
      await _clearLastOpenedProjectMemory();
      return false;
    }
    if (!await _isManifestReadable(manifestPath)) {
      // macOS can report that the path exists but still deny read access
      // (Desktop/Documents permission not granted to the app process).
      //
      // In that case we do NOT call `loadProject`, otherwise we'd surface a
      // noisy PathAccessException on every launch.
      await _clearLastOpenedProjectMemory();
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Dernier projet détecté, mais accès refusé par macOS. Ouvrez-le manuellement pour réautoriser l’accès.',
      );
      return false;
    }
    // Auto-restore must be resilient:
    // - no noisy startup error toast if macOS denies access to remembered path
    //   (common when the path is on Desktop/Documents and the app lost grant).
    // - no endless retry loop on next launch if access is denied.
    await loadProject(
      manifestPath,
      silentOnError: true,
      rememberAsRecent: false,
    );
    final restored = state.project != null;
    if (!restored) {
      // Important anti-loop guard:
      // if we failed to restore (permissions / deleted file / parse error),
      // drop the remembered path so startup stays clean next launch.
      await _clearLastOpenedProjectMemory();
    }
    return restored;
  }

  Future<void> createProject(String name, String directory) async {
    debugPrint('EditorNotifier: createProject($name, $directory)');
    try {
      final useCase = ref.read(createProjectUseCaseProvider);
      final manifest = await useCase.execute(name, directory);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: directory,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "$name" created successfully',
      );
      await _rememberLastOpenedProjectManifest(
        p.join(directory, 'project.json'),
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating project: $e');
      state = state.copyWith(errorMessage: 'Failed to create project: $e');
    }
  }

  Future<void> loadProject(
    String manifestPath, {
    bool silentOnError = false,
    bool rememberAsRecent = true,
  }) async {
    // Keep this trace for explicit user actions, but avoid noisy startup logs
    // when running a silent auto-restore attempt.
    if (!silentOnError) {
      debugPrint('EditorNotifier: loadProject($manifestPath)');
    }
    try {
      final useCase = ref.read(loadProjectUseCaseProvider);
      final manifest = await useCase.execute(manifestPath);
      final projectDir = p.dirname(manifestPath);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: projectDir,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "${manifest.name}" loaded',
      );
      if (rememberAsRecent) {
        await _rememberLastOpenedProjectManifest(manifestPath);
      }
    } catch (e) {
      if (!silentOnError) {
        debugPrint('EditorNotifier: Error loading project: $e');
      }
      if (silentOnError) {
        // Silent mode is used by startup auto-restore.
        // We intentionally avoid surfacing an intrusive error toast at launch.
        state = state.copyWith(
          errorMessage: null,
          statusMessage:
              'Impossible de rouvrir automatiquement le dernier projet. Ouvrez-le manuellement une fois pour réautoriser l’accès.',
        );
      } else {
        state = state.copyWith(errorMessage: 'Failed to load project: $e');
      }
    }
  }

  Future<bool> _isManifestReadable(String manifestPath) async {
    final file = File(manifestPath);
    try {
      // A tiny read is enough to validate real OS-level authorization.
      // We do not rely only on `exists()` because TCC can still block reads.
      await file.openRead(0, 1).first;
      return true;
    } on FileSystemException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<File> _sessionStateFile() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final editorDir = Directory(
      p.join(appSupportDir.path, 'rpg_map_editor'),
    );
    if (!await editorDir.exists()) {
      await editorDir.create(recursive: true);
    }
    return File(p.join(editorDir.path, _editorSessionFileName));
  }

  Future<void> _rememberLastOpenedProjectManifest(String manifestPath) async {
    try {
      final file = await _sessionStateFile();
      final payload = <String, dynamic>{
        _lastOpenedProjectManifestKey: manifestPath,
      };
      await file.writeAsString(jsonEncode(payload));
      // Also remember a security-scoped bookmark when running on macOS.
      // This is the durable way to re-open a user-selected folder under sandbox.
      await _rememberMacOsProjectBookmark(manifestPath);
    } catch (_) {
      // Non-critical: failing to persist recent project must not block editing.
    }
  }

  Future<void> _clearLastOpenedProjectMemory() async {
    try {
      final file = await _sessionStateFile();
      if (await file.exists()) {
        await file.delete();
      }
      await _clearMacOsProjectBookmark();
    } catch (_) {
      // Best effort cleanup only.
    }
  }

  Future<void> _rememberMacOsProjectBookmark(String manifestPath) async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel.invokeMethod<void>(
        'rememberProjectPath',
        <String, dynamic>{'manifestPath': manifestPath},
      );
    } catch (_) {
      // Best effort only: path JSON persistence remains as fallback.
    }
  }

  Future<String?> _resolveLastProjectManifestFromMacOsBookmark() async {
    if (!Platform.isMacOS) {
      return null;
    }
    try {
      final path = await _macOsFileAccessChannel
          .invokeMethod<String>('resolveLastProjectManifestPath');
      if (path == null) {
        return null;
      }
      final trimmed = path.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearMacOsProjectBookmark() async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel
          .invokeMethod<void>('clearRememberedProjectPath');
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> updateProjectSettings({
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('EditorNotifier: updateProjectSettings()');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectSettingsUseCaseProvider);
      final updated =
          await useCase.execute(fs, project, name: name, settings: settings);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Project settings saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating project settings: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update project settings: $e',
      );
    }
  }

  Future<void> saveActiveMap() async {
    endMapStroke();
    final map = state.activeMap;
    final path = state.activeMapPath;
    if (map == null || path == null) return;

    debugPrint('EditorNotifier: saveActiveMap()');
    state = _projectSessionController.markMapSaving(state);

    try {
      final useCase = ref.read(saveMapUseCaseProvider);
      await useCase.execute(
        map,
        path,
        projectDialogueContext: state.project,
      );

      state = _projectSessionController.markMapSaved(
        current: state,
        map: map,
        statusMessage: 'Map "${map.id}" saved',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error saving map: $e');
      state = _projectSessionController.markMapSaveFailed(
        current: state,
        errorMessage: 'Failed to save map: $e',
      );
    }
  }

  Future<void> createMap(String id, int width, int height,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'EditorNotifier: createMap($id, $width, $height) in group $groupId');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height,
          groupId: groupId, role: role);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: project,
        current: _currentTerrainPresetSelection(),
      );
      final updatedProject = project.copyWith(maps: [
        ...project.maps,
        ProjectMapEntry(
          id: id,
          name: id,
          relativePath: fs.getMapRelativePath(id),
          groupId: groupId,
          role: role,
        )
      ]);
      state = _projectSessionController.openMapDocument(
        current: state.copyWith(project: updatedProject),
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.getMapPath(id),
          presetSelection: presetSelection,
          selectedTilesetEditorId:
              _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
            map,
          ),
        ),
        statusMessage: 'Map "$id" created successfully',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error creating map: $e');
      state = state.copyWith(errorMessage: 'Failed to create map: $e');
    }
  }

  Future<void> loadMap(String relativePath) async {
    debugPrint('EditorNotifier: loadMap($relativePath)');
    final fs = _projectWorkspace;
    if (fs == null) return;

    try {
      final useCase = ref.read(loadMapUseCaseProvider);
      final project = state.project;
      final loadedMap = await useCase.execute(fs, relativePath);
      final map = project == null
          ? loadedMap
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: loadedMap,
              project: project,
            );
      final presetSelection = project == null
          ? _currentTerrainPresetSelection()
          : _terrainPresetSelectionCoordinator.normalize(
              project: project,
              current: _currentTerrainPresetSelection(),
            );
      final preservedSelectedTilesetEditorId = state.selectedTilesetEditorId;
      final nextSelectedTilesetEditorId =
          preservedSelectedTilesetEditorId != null &&
                  preservedSelectedTilesetEditorId.isNotEmpty &&
                  project != null &&
                  project.tilesets.any(
                    (tileset) => tileset.id == preservedSelectedTilesetEditorId,
                  )
              ? preservedSelectedTilesetEditorId
              : _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
                  map,
                );
      state = _projectSessionController.openMapDocument(
        current: state,
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.resolveMapPath(relativePath),
          presetSelection: presetSelection,
          selectedTilesetEditorId: nextSelectedTilesetEditorId,
        ),
        statusMessage: 'Map "${map.id}" loaded',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error loading map: $e');
      state = state.copyWith(errorMessage: 'Failed to load map: $e');
    }
  }

  /// Charge une "snapshot" de map par id SANS changer la map active.
  ///
  /// Pourquoi cette API existe:
  /// - certains workspaces (ex: Cutscene Studio) doivent proposer des
  ///   dropdowns guidés (PNJ/triggers) pour n'importe quelle map du projet;
  /// - on ne veut pas forcer un changement de contexte utilisateur vers cette
  ///   map juste pour lire ses entités;
  /// - on garde donc une lecture non destructive (read-only) côté éditeur.
  ///
  /// Contrat:
  /// - retourne la `activeMap` si c'est déjà la bonne map (inclut les edits
  ///   non sauvegardés en cours, utile pour une UX cohérente);
  /// - sinon lit le fichier map depuis le disque;
  /// - retourne `null` si le contexte projet est incomplet ou en cas d'erreur.
  Future<MapData?> loadMapSnapshotById(String mapId) async {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      return null;
    }
    final project = state.project;
    final workspace = _projectWorkspace;
    if (project == null || workspace == null) {
      return null;
    }

    final activeMap = state.activeMap;
    if (activeMap != null && activeMap.id == normalizedMapId) {
      return activeMap;
    }

    ProjectMapEntry? entry;
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedMapId) {
        entry = mapEntry;
        break;
      }
    }
    if (entry == null) {
      return null;
    }

    try {
      final mapPath = workspace.resolveMapPath(entry.relativePath);
      final repo = ref.read(mapRepositoryProvider);
      return await repo.loadMap(mapPath);
    } catch (error) {
      debugPrint(
        'EditorNotifier: loadMapSnapshotById($normalizedMapId) failed: $error',
      );
      return null;
    }
  }

  Future<void> resizeActiveMap(int width, int height) async {
    final map = state.activeMap;
    if (map == null) return;

    debugPrint('EditorNotifier: resizeActiveMap(${width}x$height)');
    try {
      final useCase = ref.read(resizeMapUseCaseProvider);
      final resized = useCase.execute(map, width, height);
      final project = state.project;
      final committed = project == null
          ? resized
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: resized,
              project: project,
            );

      if (committed == map) {
        state = state.copyWith(
          statusMessage: 'Map "${map.id}" is already ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final hovered = state.hoveredTile;
      final nextHovered = (hovered != null &&
              (hovered.x < 0 ||
                  hovered.y < 0 ||
                  hovered.x >= width ||
                  hovered.y >= height))
          ? null
          : hovered;
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        hoveredTile: nextHovered,
        updateHoveredTile: true,
        statusMessage: 'Map "${map.id}" resized to ${width}x$height',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error resizing map: $e');
      state = state.copyWith(errorMessage: 'Failed to resize map: $e');
    }
  }

  void updateMapMetadata(MapMetadata metadata) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(updateMapMetadataUseCaseProvider);
      final updated = useCase.execute(
        map,
        metadata,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Carte : propriétés enregistrées',
      );
    } catch (e) {
      debugPrint('EditorNotifier: updateMapMetadata failed: $e');
      state = state.copyWith(
        errorMessage: 'Échec des propriétés de carte : $e',
      );
    }
  }

  Future<void> renameMap(String oldId, String newId) async {
    debugPrint('EditorNotifier: renameMap($oldId -> $newId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, oldId, newId);
      state = _projectSessionController.afterMapRenamed(
        current: state,
        updatedProject: updatedProject,
        oldId: oldId,
        newId: newId,
        newPath: fs.getMapPath(newId),
        statusMessage: 'Map renamed to "$newId"',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming map: $e');
      state = state.copyWith(errorMessage: 'Failed to rename map: $e');
    }
  }

  Future<void> deleteMap(String mapId) async {
    debugPrint('EditorNotifier: deleteMap($mapId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId);
      state = _projectSessionController.afterMapDeleted(
        current: state,
        updatedProject: updatedProject,
        deletedMapId: mapId,
        statusMessage: 'Map "$mapId" deleted',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting map: $e');
      state = state.copyWith(errorMessage: 'Failed to delete map: $e');
    }
  }

  Future<void> duplicateMap(String sourceId) async {
    debugPrint('EditorNotifier: duplicateMap($sourceId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(duplicateMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, sourceId);

      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map "$sourceId" duplicated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error duplicating map: $e');
      state = state.copyWith(errorMessage: 'Failed to duplicate map: $e');
    }
  }

  Future<void> createGroup(String name, MapGroupType type,
      {String? parentId}) async {
    debugPrint('EditorNotifier: createGroup($name, $type, parent: $parentId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, name, type, parentId: parentId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group "$name" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating group: $e');
      state = state.copyWith(errorMessage: 'Failed to create group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    debugPrint('EditorNotifier: deleteGroup($groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting group: $e');
      state = state.copyWith(errorMessage: 'Failed to delete group: $e');
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    debugPrint('EditorNotifier: renameGroup($groupId -> $newName)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, groupId, newName);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming group: $e');
      state = state.copyWith(errorMessage: 'Failed to rename group: $e');
    }
  }

  Future<void> moveMapToGroup(String mapId, String? groupId) async {
    debugPrint('EditorNotifier: moveMapToGroup($mapId -> $groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(moveMapToGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving map: $e');
      state = state.copyWith(errorMessage: 'Failed to move map: $e');
    }
  }

  List<ProjectTilesetEntry> getAssignableTilesetsForActiveMap() {
    final project = state.project;
    final activeMap = state.activeMap;
    if (project == null || activeMap == null) return const [];
    try {
      final useCase = ref.read(resolveAssignableTilesetsForMapUseCaseProvider);
      return useCase.execute(project, activeMap.id);
    } catch (_) {
      return const [];
    }
  }

  Future<void> importProjectTileset({
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
    String? libraryFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(importProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        sourcePath: sourcePath,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        folderId: libraryFolderId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId:
            updated.tilesets.isNotEmpty ? updated.tilesets.last.id : null,
        selectedTilesetElementGroupId: null,
        statusMessage: 'Tileset "$name" imported',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error importing tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to import tileset: $e');
    }
  }

  Future<void> updateProjectTileset({
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
    String? libraryFolderId,
    bool clearLibraryFolder = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        sortOrder: sortOrder,
        folderId: libraryFolderId,
        clearLibraryFolder: clearLibraryFolder,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to update tileset: $e');
    }
  }

  Future<void> reorderProjectTileset(String tilesetId, int direction) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(reorderProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        direction: direction,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset reordered',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error reordering tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to reorder tileset: $e');
    }
  }

  Future<void> createTilesetLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentFolderId: parentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create tileset folder: $e',
      );
    }
  }

  Future<void> renameTilesetLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset folder: $e',
      );
    }
  }

  Future<void> moveTilesetLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        newParentFolderId: newParentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset folder: $e',
      );
    }
  }

  Future<void> deleteTilesetLibraryFolder(String folderId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete tileset folder: $e',
      );
    }
  }

  Future<void> assignTilesetToLibraryFolder({
    required String tilesetId,
    required String folderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(assignTilesetToLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to folder',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to folder: $e',
      );
    }
  }

  Future<void> moveTilesetToLibraryRoot(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetToLibraryRootUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to library root',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset to library root: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to library root: $e',
      );
    }
  }

  Future<void> deleteProjectTileset(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(fs, project, tilesetId);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      String? selectedTilesetEditorId = state.selectedTilesetEditorId;
      var workspaceMode = state.workspaceMode;
      var activeBrush =
          _clearBrushIfTilesetRemoved(state.activeBrush, tilesetId);
      if (selectedTilesetEditorId == tilesetId) {
        selectedTilesetEditorId =
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
          state.activeMap,
          preferredLayerId: state.activeLayerId,
        );
        if (selectedTilesetEditorId != null &&
            !updated.tilesets.any((t) => t.id == selectedTilesetEditorId)) {
          selectedTilesetEditorId =
              updated.tilesets.isNotEmpty ? updated.tilesets.first.id : null;
        }
        if (selectedTilesetEditorId == null) {
          workspaceMode = EditorWorkspaceMode.map;
        }
      }
      state = state.copyWith(
        project: updated,
        workspaceMode: workspaceMode,
        activeBrush: activeBrush,
        selectedTilesetEditorId: selectedTilesetEditorId,
        selectedTilesetElementGroupId: null,
        terrainSelectionMode: presetSelection.selectionMode,
        selectedTerrainType: presetSelection.selectedTerrainType,
        selectedTerrainPresetId: presetSelection.selectedTerrainPresetId,
        selectedPathPresetId: presetSelection.selectedPathPresetId,
        selectedTerrainPresetByType:
            presetSelection.selectedTerrainPresetByType,
        statusMessage: 'Tileset deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to delete tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveLayer(String tilesetId) async {
    final project = state.project;
    final map = state.activeMap;
    final mapPath = state.activeMapPath;
    final layerId = state.activeLayerId;
    if (project == null || map == null || mapPath == null || layerId == null) {
      return;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Active layer must be a tile layer to assign a tileset',
      );
      return;
    }

    try {
      final useCase = ref.read(assignTilesetToMapUseCaseProvider);
      final updatedMap = await useCase.execute(
        project,
        map,
        mapPath,
        layerId,
        tilesetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Tileset "$tilesetId" assigned to layer "${layer.name}"',
        updateSavedSnapshot: true,
      );
      state = state.copyWith(
        workspaceMode: EditorWorkspaceMode.map,
        activeBrush: const EditorBrush.none(),
        selectedTilesetEditorId: tilesetId,
        selectedTilesetElementGroupId: null,
        paletteCategoryFilter: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning layer tileset: $e');
      state =
          state.copyWith(errorMessage: 'Failed to assign layer tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveMap(String tilesetId) async {
    await assignTilesetToActiveLayer(tilesetId);
  }

  ProjectTilesetEntry? getActiveTilesetEntry() {
    return getSelectedTilesetEntry();
  }

  String? getActiveTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getActiveTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  PathAutotileSet? getSelectedPathAutotileSet() {
    return _pathAutotileResolver.resolve(
      selectedPreset: getSelectedPathPreset(),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  PathAutotileSet? getPathAutotileSetForPresetId(String? presetId) {
    return _pathAutotileResolver.resolve(
      selectedPreset: getPathPresetById(presetId),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  Map<String, PathAutotileSet> getPathAutotileSetsByPresetId() {
    final result = <String, PathAutotileSet>{};
    for (final preset in getPathPresets()) {
      final resolved = getPathAutotileSetForPresetId(preset.id);
      if (resolved != null) {
        result[preset.id] = resolved;
      }
    }
    return result;
  }

  List<ProjectTerrainPreset> getTerrainPresets({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listTerrainPresets(
      project,
      terrainType: terrainType,
    );
  }

  List<ProjectPathPreset> getPathPresets() {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPathPresets(project);
  }

  List<ProjectPresetCategory> getPresetCategories({
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPresetCategories(
      project,
      kind: kind,
      parentCategoryId: parentCategoryId,
    );
  }

  ProjectPresetCategory? getPresetCategoryById({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPresetCategoryById(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  String? resolvePresetCategoryPath({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolvePresetCategoryPath(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  ProjectTerrainPreset? getTerrainPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findTerrainPresetById(project, presetId);
  }

  ProjectPathPreset? getPathPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPathPresetById(project, presetId);
  }

  ProjectTerrainPreset? getSelectedTerrainPreset({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return null;
    final type = terrainType ?? state.selectedTerrainType;
    return _terrainPresetResolver.resolveSelectedTerrainPreset(
      project,
      terrainType: type,
      selectedTerrainPresetId: state.selectedTerrainPresetId,
      selectedTerrainPresetByType: state.selectedTerrainPresetByType,
    );
  }

  ProjectPathPreset? getSelectedPathPreset() {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolveSelectedPathPreset(
      project,
      selectedPathPresetId: state.selectedPathPresetId,
    );
  }

  Map<TerrainType, ProjectTerrainPreset> getTerrainPresetByType() {
    final result = <TerrainType, ProjectTerrainPreset>{};
    for (final type in TerrainType.values) {
      if (!type.isBackgroundPaintable) continue;
      final preset = getSelectedTerrainPreset(terrainType: type);
      if (preset != null) {
        result[type] = preset;
      }
    }
    return result;
  }

  void selectMapWorkspace() {
    state = _editorWorkspaceController.selectMapWorkspace(state);
  }

  void selectTilesetWorkspace(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      workspaceMode: tilesetId == null
          ? EditorWorkspaceMode.map
          : EditorWorkspaceMode.tileset,
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
    );
  }

  /// Ouvre le workspace Pokédex des lots 12-13.
  ///
  /// Ce changement reste volontairement une simple navigation :
  /// - aucune donnee Pokemon n'est chargee ici ;
  /// - aucun service Pokemon n'est appele ici ;
  /// - l'ecran central gerera lui-meme la lecture simple necessaire au lot 13.
  ///
  /// Cela garde la responsabilite du notifier tres claire :
  /// il route vers un workspace, mais ne commence pas une logique Pokédex riche.
  void selectPokedexWorkspace() {
    state = _editorWorkspaceController.selectPokedexWorkspace(state);
  }

  /// Ouvre le workspace central "Trainer Studio".
  ///
  /// Cette navigation reste volontairement minimale :
  /// - aucun pipeline trainer parallèle n'est créé ici ;
  /// - aucune donnée locale n'est préchargée depuis le notifier ;
  /// - la surface centrale réutilise le même flux trainer que la sidebar,
  ///   via les méthodes existantes du notifier.
  void selectTrainerWorkspace() {
    state = _editorWorkspaceController.selectTrainerWorkspace(state);
  }

  /// Ouvre le workspace central "Global Story".
  ///
  /// Ce changement est purement une navigation d'espace de travail:
  /// - aucune mutation map/tileset n'est exécutée,
  /// - aucune donnée narrative n'est modifiée ici.
  void selectGlobalStoryWorkspace() {
    state = _editorWorkspaceController.selectGlobalStoryWorkspace(state);
  }

  /// Ouvre le workspace central "Step".
  void selectStepWorkspace() {
    state = _editorWorkspaceController.selectStepWorkspace(state);
  }

  /// Ouvre le workspace central "Cutscene".
  void selectCutsceneWorkspace() {
    state = _editorWorkspaceController.selectCutsceneWorkspace(state);
  }

  /// Bascule vers Dialogue Studio (bibliothèque + canvas + inspecteur).
  void selectDialogueWorkspace() {
    state = _editorWorkspaceController.selectDialogueWorkspace(state);
  }

  /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
  Future<void> saveProjectDialogueYarnBody({
    required String dialogueId,
    required String yarnBody,
  }) async {
    state = await _projectContentController.saveProjectDialogueYarnBody(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      yarnBody: yarnBody,
    );
  }

  void selectTilesetEditorContext(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
      errorMessage: null,
    );
  }

  ProjectTilesetEntry? getSelectedTilesetEntry() {
    final project = state.project;
    if (project == null) return null;

    final selectedId = state.selectedTilesetEditorId;
    if (selectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == selectedId) {
          return tileset;
        }
      }
    }

    final map = state.activeMap;
    final activeLayerId = state.activeLayerId;
    if (map != null && activeLayerId != null) {
      final activeLayer = _findLayerById(map, activeLayerId);
      if (activeLayer is TileLayer) {
        final layerTilesetId = activeLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
          for (final tileset in project.tilesets) {
            if (tileset.id == layerTilesetId) {
              return tileset;
            }
          }
        }
      }
    }

    final brushTilesetId = getActiveBrushTilesetId();
    if (brushTilesetId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == brushTilesetId) {
          return tileset;
        }
      }
    }

    if (project.tilesets.isEmpty) return null;
    return project.tilesets.first;
  }

  String? getSelectedTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getSelectedTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getTilesetAbsolutePathById(String tilesetId) {
    final fs = _projectWorkspace;
    if (fs == null) return null;
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getActiveBrushTilesetId() {
    final brush = state.activeBrush;
    if (brush is TileEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is PaletteEntryEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      return element?.tilesetId;
    }
    return null;
  }

  List<TilesetElementGroup> getSelectedTilesetElementGroups() {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return const [];
    final groups = List<TilesetElementGroup>.from(
      tileset.elementGroups,
      growable: false,
    );
    groups.sort((a, b) {
      if (a.parentGroupId == b.parentGroupId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentGroupId ?? '';
      final parentB = b.parentGroupId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  void selectTilesetElementGroupFilter(String? groupId) {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return;
    if (groupId != null &&
        !tileset.elementGroups.any((group) => group.id == groupId)) {
      return;
    }
    state = state.copyWith(selectedTilesetElementGroupId: groupId);
  }

  Future<void> createTilesetElementGroup(
    String tilesetId,
    String name, {
    String? parentGroupId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        parentGroupId: parentGroupId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset group: $e',
      );
    }
  }

  Future<void> createTilesetElementSubgroup(
    String tilesetId,
    String parentGroupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementSubgroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        parentGroupId: parentGroupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset subgroup created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset subgroup: $e',
      );
    }
  }

  Future<void> renameTilesetElementGroup(
    String tilesetId,
    String groupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        groupId: groupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset group: $e',
      );
    }
  }

  List<ProjectElementEntry> getSelectedTilesetElements({
    String? tilesetGroupId,
    bool includeDescendants = true,
  }) {
    final project = state.project;
    final selectedTileset = getSelectedTilesetEntry();
    if (project == null || selectedTileset == null) return const [];
    try {
      final useCase = ref.read(resolveTilesetElementsUseCaseProvider);
      return useCase.execute(
        project,
        tilesetId: selectedTileset.id,
        tilesetGroupId: tilesetGroupId,
        includeDescendants: includeDescendants,
      );
    } catch (_) {
      return const [];
    }
  }

  List<ProjectElementCategory> getElementCategories() {
    final project = state.project;
    if (project == null) return const [];
    final categories = List<ProjectElementCategory>.from(
      project.elementCategories,
      growable: false,
    );
    categories.sort((a, b) {
      if (a.parentCategoryId == b.parentCategoryId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentCategoryId ?? '';
      final parentB = b.parentCategoryId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  ProjectElementCategory? getElementCategoryById(String categoryId) {
    final project = state.project;
    if (project == null) return null;
    for (final category in project.elementCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  ProjectElementEntry? getProjectElementById(String elementId) {
    final project = state.project;
    if (project == null) return null;
    for (final element in project.elements) {
      if (element.id == elementId) {
        return element;
      }
    }
    return null;
  }

  List<ProjectElementEntry> getVisibleProjectElementsForActiveMap({
    bool includeAll = false,
    bool globalOnly = false,
    bool acrossAllTilesets = false,
  }) {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return const [];

    List<ProjectElementEntry> resolved;
    final activeTilesetId = getSelectedTilesetEntry()?.id;
    if (includeAll) {
      resolved = project.elements.where((element) {
        if (!acrossAllTilesets && element.tilesetId != activeTilesetId) {
          return false;
        }
        return true;
      }).toList(growable: false);
    } else if (globalOnly) {
      resolved = project.elements
          .where(
            (element) =>
                (acrossAllTilesets || element.tilesetId == activeTilesetId) &&
                element.groupId == null,
          )
          .toList(growable: false);
    } else {
      if (!acrossAllTilesets && activeTilesetId == null) {
        return const [];
      }
      try {
        final useCase = ref.read(resolveVisibleProjectElementsUseCaseProvider);
        resolved = useCase.execute(
          project,
          tilesetId: acrossAllTilesets ? null : activeTilesetId,
          mapId: map.id,
        );
      } catch (_) {
        resolved = const [];
      }
    }

    resolved.sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return resolved;
  }

  Future<void> createElementCategory(
    String name, {
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> createElementSubcategory(
    String parentCategoryId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementSubcategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        parentCategoryId: parentCategoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element subcategory created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create subcategory: $e');
    }
  }

  Future<void> renameElementCategory(String categoryId, String name) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> createProjectElement({
    required String name,
    required String categoryId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    ElementCollisionProfile? collisionProfile,
    String? tilesetId,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    final selectedTileset = getSelectedTilesetEntry();
    final effectiveTilesetId = tilesetId ?? selectedTileset?.id;
    if (effectiveTilesetId == null) {
      state = state.copyWith(errorMessage: 'No tileset selected');
      return;
    }
    try {
      final useCase = ref.read(createProjectElementUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: effectiveTilesetId,
        categoryId: categoryId,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        tilesetGroupId: tilesetGroupId,
        source: source,
        groupId: groupId,
        recommendedLayerId: recommendedLayerId,
        tags: tags,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.projectElement(elementId: result.element.id),
        selectedTilesetEditorId: result.element.tilesetId,
        selectedTilesetElementGroupId: result.element.tilesetGroupId,
        statusMessage: 'Element "${result.element.name}" created',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> updateProjectElement({
    required String elementId,
    String? name,
    ElementPresetKind? presetKind,
    ElementCollisionProfile? collisionProfile,
    bool clearCollisionProfile = false,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    TilesetSourceRect? source,
    List<TilesetVisualFrame>? frames,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
        name: name,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        clearCollisionProfile: clearCollisionProfile,
        categoryId: categoryId,
        tilesetGroupId: tilesetGroupId,
        clearTilesetGroupId: clearTilesetGroupId,
        groupId: groupId,
        clearGroupId: clearGroupId,
        recommendedLayerId: recommendedLayerId,
        clearRecommendedLayerId: clearRecommendedLayerId,
        source: source,
        frames: frames,
        tags: tags,
      );
      String? selectedTilesetElementGroupId =
          state.selectedTilesetElementGroupId;
      final selectedElementId = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId,
        orElse: () => null,
      );
      if (selectedElementId == elementId) {
        if (clearTilesetGroupId) {
          selectedTilesetElementGroupId = null;
        } else if (tilesetGroupId != null) {
          selectedTilesetElementGroupId = tilesetGroupId;
        }
      }
      state = state.copyWith(
        project: updated,
        selectedTilesetElementGroupId: selectedTilesetElementGroupId,
        statusMessage: 'Element updated',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update element: $e');
    }
  }

  Future<void> deleteProjectElement(String elementId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
      );
      final activeBrush = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId == elementId
            ? const EditorBrush.none()
            : state.activeBrush,
        orElse: () => state.activeBrush,
      );
      state = state.copyWith(
        project: updated,
        activeBrush: activeBrush,
        statusMessage: 'Element deleted',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete element: $e');
    }
  }

  Future<ElementCollisionProfile?> generateElementCollisionProfile({
    required String tilesetId,
    required TilesetSourceRect source,
    required ElementPresetKind presetKind,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final project = state.project;
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return null;
    }
    final tilesetPath = getTilesetAbsolutePathById(tilesetId);
    if (tilesetPath == null || tilesetPath.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Tileset path not found');
      return null;
    }
    try {
      final profile = await _elementCollisionProfileGenerator.generate(
        tilesetImagePath: tilesetPath,
        source: source,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        presetKind: presetKind,
        padding: padding,
      );
      state = state.copyWith(
        statusMessage:
            'Collision auto-générée (${profile.cells.length} cellule${profile.cells.length > 1 ? 's' : ''})',
        errorMessage: null,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to generate collision profile: $e',
      );
      return null;
    }
  }

  void _resyncPlacedElementsForActiveMapFromProject() {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return;
    }
    final synced = _placedElementInstanceIndexer.syncAllTileLayers(
      map: map,
      project: project,
    );
    if (identical(synced, map) || synced == map) {
      return;
    }
    _applyMapMutation(
      previousMap: map,
      updatedMap: synced,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: 'Instances d’éléments synchronisées',
    );
  }

  List<TilesetPaletteEntry> getActivePaletteEntries() {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return const [];
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  ProjectTilesetEntry? getTilesetById(String tilesetId) {
    final project = state.project;
    if (project == null) return null;
    for (final tileset in project.tilesets) {
      if (tileset.id == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  List<TilesetPaletteEntry> getPaletteEntriesForTileset(String tilesetId) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  TilesetPaletteEntry? getPaletteEntryById({
    required String tilesetId,
    required String entryId,
  }) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    for (final entry in tileset.paletteEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  TilesetPaletteEntry? getActivePaletteEntryById(String entryId) {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return null;
    return getPaletteEntryById(tilesetId: tilesetId, entryId: entryId);
  }

  void setPaletteCategoryFilter(PaletteCategory? category) {
    state = state.copyWith(paletteCategoryFilter: category);
  }

  void selectPaletteTile(int tileId) {
    if (tileId <= 0) return;
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.tile(
        tileId: tileId,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectPaletteEntry(String entryId) {
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    final entry =
        getPaletteEntryById(tilesetId: selectedTileset.id, entryId: entryId);
    if (entry == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.paletteEntry(
        entryId: entry.id,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectProjectElement(String elementId) {
    final element = getProjectElementById(elementId);
    if (element == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.projectElement(elementId: element.id),
      selectedTilesetEditorId: element.tilesetId,
      selectedTilesetElementGroupId: element.tilesetGroupId,
      selectedPlacedElementInstanceId: null,
    );
  }

  Future<void> createPaletteEntry({
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;

    try {
      final useCase = ref.read(createTilesetPaletteEntryUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        name: name,
        category: category,
        source: source,
        recommendedLayerId: recommendedLayerId,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.paletteEntry(
          entryId: result.entry.id,
          tilesetId: tileset.id,
        ),
        statusMessage: 'Palette element "${result.entry.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating palette entry: $e');
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> upsertPaletteEntryForTile({
    required int tileId,
    required int columns,
    required PaletteCategory category,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;
    if (tileId <= 0 || columns <= 0) return;

    final sourceIndex = tileId - 1;
    final sourceX = sourceIndex % columns;
    final sourceY = sourceIndex ~/ columns;

    TilesetPaletteEntry? existing;
    for (final entry in tileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width == 1 &&
          ps.height == 1 &&
          ps.x == sourceX &&
          ps.y == sourceY) {
        existing = entry;
        break;
      }
    }

    final rect = TilesetSourceRect(x: sourceX, y: sourceY);
    final entry = TilesetPaletteEntry(
      id: existing?.id ?? 'tile_$tileId',
      name: existing?.name.isNotEmpty == true ? existing!.name : 'tile_$tileId',
      category: category,
      frames: existing == null
          ? [TilesetVisualFrame(source: rect)]
          : [
              TilesetVisualFrame(source: rect),
              ...existing.frames.skip(1),
            ],
      recommendedLayerId: recommendedLayerId,
    );

    try {
      final useCase = ref.read(upsertTilesetPaletteEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        entry: entry,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Palette entry updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating palette entry: $e');
      state =
          state.copyWith(errorMessage: 'Failed to update palette entry: $e');
    }
  }

  void paintSelectedBrushAt(
    GridPos pos, {
    required Map<String, int> tilesetColumnsById,
  }) {
    final layerContext = _resolveActiveTileLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final resolvedBrush = _resolveActiveBrushPattern(
      tilesetColumnsById: tilesetColumnsById,
      emitErrors: true,
    );
    if (resolvedBrush == null) return;
    final preparedMap = _prepareMapForBrushTileset(
      map: layerContext.map,
      layerId: layerContext.layerId,
      activeLayer: layerContext.layer,
      brushTilesetId: resolvedBrush.tilesetId,
    );
    if (preparedMap == null) return;
    _paintPattern(
      map: preparedMap,
      layerId: layerContext.layerId,
      pos: pos,
      pattern: resolvedBrush.pattern,
      failureLabel: resolvedBrush.failureLabel,
    );
  }

  void paintCollisionAt(GridPos pos) {
    final layerContext = _resolveActiveCollisionLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final footprint = _resolveCollisionFootprint(emitErrors: true);
    if (footprint == null) return;
    _paintCollisionPattern(
      map: layerContext.map,
      layerId: layerContext.layerId,
      pos: pos,
      patternSize: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  void paintTerrainAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active editable layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TerrainLayer) {
      final footprint = _resolveTerrainFootprint(emitErrors: true);
      if (footprint == null) return;
      _paintTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: state.selectedTerrainType,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final footprint = _resolvePathFootprint();
      final selectedPathPreset = getSelectedPathPreset();
      if (activeLayer.presetId.trim().isEmpty && selectedPathPreset != null) {
        try {
          final presetAssigned = _pathLayerEditingCoordinator.assignPreset(
            map: map,
            layerId: layerId,
            presetId: selectedPathPreset.id,
          );
          _paintPathPattern(
            map: presetAssigned,
            previousMap: map,
            layerId: layerId,
            pos: pos,
            patternSize: footprint.size,
            failureLabel: footprint.failureLabel,
          );
        } catch (e) {
          _setPaintError('Failed to assign path preset: $e');
        }
        return;
      }
      _paintPathPattern(
        map: map,
        previousMap: map,
        layerId: layerId,
        pos: pos,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  void fillActiveTerrainLayer(TerrainType terrain) {
    final layerContext = _resolveActiveTerrainLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final map = layerContext.map;
    final layerId = layerContext.layerId;
    try {
      final committed = _terrainPaintingCoordinator.fill(
        map: map,
        layerId: layerId,
        terrain: terrain,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        statusMessage: 'Terrain layer filled with ${terrain.name}',
      );
    } catch (e) {
      _setPaintError('Failed to fill terrain layer: $e');
    }
  }

  void assignPathPresetToActivePathLayer(String presetId) {
    final layerContext = _resolveActivePathLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final normalizedPresetId = presetId.trim();
    if (layerContext.layer.presetId.trim() == normalizedPresetId) {
      final preset = getPathPresetById(normalizedPresetId);
      state = state.copyWith(
        statusMessage: preset == null
            ? 'Path layer preset unchanged'
            : 'Path layer preset: ${preset.name}',
        errorMessage: null,
      );
      return;
    }
    try {
      final updated = _pathLayerEditingCoordinator.assignPreset(
        map: layerContext.map,
        layerId: layerContext.layerId,
        presetId: normalizedPresetId,
      );
      final preset = getPathPresetById(normalizedPresetId);
      _applyMapMutation(
        previousMap: layerContext.map,
        updatedMap: updated,
        preferredActiveLayerId: layerContext.layerId,
        statusMessage: preset == null
            ? 'Path layer preset assigned'
            : 'Path layer preset: ${preset.name}',
      );
    } catch (e) {
      _setPaintError('Failed to assign path preset: $e');
    }
  }

  void eraseAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TileLayer) {
      final pattern = _resolveErasePattern(emitErrors: true);
      if (pattern == null) return;
      _erasePattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        failureLabel: pattern.failureLabel,
      );
      return;
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: true);
      if (collisionFootprint == null) return;
      _eraseCollisionPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: collisionFootprint.size,
        failureLabel: collisionFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: true);
      if (terrainFootprint == null) return;
      _eraseTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: terrainFootprint.size,
        failureLabel: terrainFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      _erasePathPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pathFootprint.size,
        failureLabel: pathFootprint.failureLabel,
      );
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  MapWarp? getSelectedWarp() {
    return _warpEditingService.findSelectedWarp(
      state.activeMap,
      state.selectedWarpId,
    );
  }

  MapConnection? getMapConnection(MapConnectionDirection direction) {
    return _mapConnectionEditingService.findConnection(
      state.activeMap,
      direction,
    );
  }

  MapEntity? getSelectedEntity() {
    return _entityEditingService.findSelectedEntity(
      state.activeMap,
      state.selectedEntityId,
    );
  }

  MapTrigger? getSelectedTrigger() {
    return _triggerEditingService.findSelectedTrigger(
      state.activeMap,
      state.selectedTriggerId,
    );
  }

  MapEventDefinition? getSelectedMapEvent() {
    final map = state.activeMap;
    final selectedMapEventId = state.selectedMapEventId;
    if (map == null || selectedMapEventId == null) {
      return null;
    }
    return findMapEventById(map, selectedMapEventId);
  }

  void placeOrSelectMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = findMapEventAtPos(
      map,
      pos.x,
      pos.y,
      preferredLayerId: state.activeLayerId,
    );
    if (existing != null) {
      selectMapEvent(existing.id);
      return;
    }
    addMapEventAt(pos);
  }

  void addMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = _resolveEventPlacementLayerId(map);
    if (layerId == null) {
      state = state.copyWith(
        errorMessage: 'No layer available to place a map event',
      );
      return;
    }
    final eventId = _generateUniqueMapEventId(map);
    final created = MapEventDefinition(
      id: eventId,
      title: eventId,
      position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
      pages: const [
        MapEventPage(
          pageNumber: 0,
          message: '',
        ),
      ],
    );
    try {
      final updated = addMapEventToMap(map, event: created);
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: created.id,
        statusMessage: 'Event "${created.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create event: $e');
    }
  }

  void selectMapEvent(String? eventId) {
    final map = state.activeMap;
    if (map == null) return;
    if (eventId == null) {
      state = state.copyWith(
        selectedMapEventId: null,
        errorMessage: null,
      );
      return;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Event not found: $eventId');
      return;
    }
    state = state.copyWith(
      selectedMapEventId: event.id,
      errorMessage: null,
    );
  }

  void updateSelectedMapEvent({
    required String id,
    required String title,
    required MapEventType type,
    required String layerId,
    required int x,
    required int y,
    required List<MapEventPage> pages,
  }) {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    updateMapEvent(
      eventId: selectedMapEventId,
      id: id,
      title: title,
      type: type,
      position: EventPosition(layerId: layerId, x: x, y: y),
      pages: pages,
    );
  }

  void updateMapEvent({
    required String eventId,
    String? id,
    String? title,
    MapEventType? type,
    EventPosition? position,
    List<MapEventPage>? pages,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        id: id,
        title: title,
        type: type,
        position: position,
        pages: pages,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId:
            id?.trim().isNotEmpty == true ? id!.trim() : eventId,
        statusMessage: 'Event updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update event: $e');
    }
  }

  void deleteSelectedMapEvent() {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    deleteMapEvent(selectedMapEventId);
  }

  void deleteMapEvent(String eventId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = removeMapEventFromMap(
        map,
        eventId: eventId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: state.selectedMapEventId == eventId
            ? null
            : state.selectedMapEventId,
        statusMessage: 'Event deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete event: $e');
    }
  }

  void placeOrSelectEntityAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _entityEditingService.findEntityAtPos(map, pos);
    if (existing != null) {
      selectEntity(existing.id);
      return;
    }
    addEntityAt(
      pos,
      kind: state.selectedEntityKind,
    );
  }

  void addEntityAt(
    GridPos pos, {
    required MapEntityKind kind,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.addEntityAt(
        map,
        pos,
        kind: kind,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.createdEntity.id,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity "${result.createdEntity.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create entity: $e');
    }
  }

  void selectEntity(String? entityId) {
    final map = state.activeMap;
    if (map == null) return;
    if (entityId == null) {
      state = state.copyWith(
        selectedEntityId: null,
        npcWaypointPlacementEntityId: null,
        errorMessage: null,
      );
      return;
    }
    final entity = _entityEditingService.findSelectedEntity(map, entityId);
    if (entity == null) {
      state = state.copyWith(errorMessage: 'Entity not found: $entityId');
      return;
    }
    state = state.copyWith(
      selectedEntityId: entity.id,
      selectedEntityKind: entity.kind,
      npcWaypointPlacementEntityId:
          state.npcWaypointPlacementEntityId == entity.id
              ? state.npcWaypointPlacementEntityId
              : null,
      errorMessage: null,
    );
  }

  /// Active le mode "placement waypoint" sur l'entité NPC sélectionnée.
  ///
  /// Ce mode est volontairement porté par l'état éditeur (et non local panel),
  /// afin que le canvas puisse router le clic map de manière explicite.
  bool startNpcWaypointPlacementForSelectedEntity() {
    final map = state.activeMap;
    final selectedEntityId = state.selectedEntityId;
    if (map == null || selectedEntityId == null || selectedEntityId.isEmpty) {
      return false;
    }
    final entity =
        _entityEditingService.findSelectedEntity(map, selectedEntityId);
    if (entity == null || entity.kind != MapEntityKind.npc) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires a selected NPC.',
      );
      return false;
    }
    final movement = entity.npc?.movement ?? const MapEntityNpcMovementConfig();
    if (movement.mode != MapEntityNpcMovementMode.patrol) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires NPC movement mode "patrol".',
      );
      return false;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage: 'Waypoint placement enabled for "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  /// Désactive explicitement le mode placement waypoint.
  void cancelNpcWaypointPlacement({String? statusMessage}) {
    if (state.npcWaypointPlacementEntityId == null) {
      return;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: null,
      statusMessage: statusMessage ?? 'Waypoint placement disabled',
      errorMessage: null,
    );
  }

  /// Traite un clic map en mode placement waypoint.
  ///
  /// Retourne `true` si le clic a été consommé par ce mode.
  /// Retourne `false` si aucun mode placement actif (ou session invalide).
  bool addNpcWaypointAt(GridPos position) {
    final placementEntityId = state.npcWaypointPlacementEntityId;
    if (placementEntityId == null || placementEntityId.trim().isEmpty) {
      return false;
    }
    final map = state.activeMap;
    if (map == null) {
      cancelNpcWaypointPlacement(statusMessage: 'Waypoint placement cancelled');
      return false;
    }
    final entity = _entityEditingService.findSelectedEntity(
      map,
      placementEntityId,
    );
    if (entity == null || entity.kind != MapEntityKind.npc) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC no longer valid)',
      );
      return false;
    }
    final npc = entity.npc ?? const MapEntityNpcData();
    if (npc.movement.mode != MapEntityNpcMovementMode.patrol) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC not in patrol mode)',
      );
      return false;
    }

    final nextWaypoints = <GridPos>[
      ...npc.movement.waypoints,
      position,
    ];
    final nextNpc = npc.copyWith(
      movement: npc.movement.copyWith(waypoints: nextWaypoints),
    );
    updateEntity(
      entityId: entity.id,
      npc: nextNpc,
    );
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage:
          'Waypoint (${position.x}, ${position.y}) added to "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  void selectEntityKind(MapEntityKind kind) {
    state = _mapSelectionController.selectEntityKind(
      current: state,
      kind: kind,
    );
  }

  void updateSelectedEntity({
    required String id,
    required String name,
    required MapEntityKind kind,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
    required bool blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    updateEntity(
      entityId: selectedEntityId,
      id: id,
      name: name,
      kind: kind,
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
      properties: properties,
      blocksMovement: blocksMovement,
      npc: npc,
      sign: sign,
      item: item,
      spawn: spawn,
      editorVisual: editorVisual,
    );
  }

  void updateEntity({
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
    bool? blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.updateEntity(
        map,
        entityId: entityId,
        id: id,
        name: name,
        kind: kind,
        pos: pos,
        size: size,
        properties: properties,
        blocksMovement: blocksMovement,
        npc: npc,
        sign: sign,
        item: item,
        spawn: spawn,
        editorVisual: editorVisual,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity updated',
      );
      if (kind != null && kind != state.selectedEntityKind) {
        state = state.copyWith(selectedEntityKind: kind);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update entity: $e');
    }
  }

  void deleteSelectedEntity() {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    deleteEntity(selectedEntityId);
  }

  void deleteEntity(String entityId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _entityEditingService.deleteEntity(
        map,
        entityId: entityId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId:
            state.selectedEntityId == entityId ? null : state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete entity: $e');
    }
  }

  void placeOrSelectTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _triggerEditingService.findTriggerAtPos(map, pos);
    if (existing != null) {
      selectTrigger(existing.id);
      return;
    }
    addTriggerAt(pos);
  }

  void addTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.addTriggerAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.createdTrigger.id,
        statusMessage: 'Trigger "${result.createdTrigger.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trigger: $e');
    }
  }

  void selectTrigger(String? triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    if (triggerId == null) {
      state = state.copyWith(
        selectedTriggerId: null,
        errorMessage: null,
      );
      return;
    }
    final trigger = _triggerEditingService.findSelectedTrigger(map, triggerId);
    if (trigger == null) {
      state = state.copyWith(errorMessage: 'Trigger not found: $triggerId');
      return;
    }
    state = state.copyWith(
      selectedTriggerId: trigger.id,
      errorMessage: null,
    );
  }

  void updateSelectedTrigger({
    required String id,
    required String name,
    required TriggerType type,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
  }) {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    updateTrigger(
      triggerId: selectedTriggerId,
      id: id,
      name: name,
      type: type,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      properties: properties,
    );
  }

  void updateTrigger({
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.updateTrigger(
        map,
        triggerId: triggerId,
        id: id,
        name: name,
        type: type,
        area: area,
        properties: properties,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.selectedTriggerId,
        statusMessage: 'Trigger updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trigger: $e');
    }
  }

  void deleteSelectedTrigger() {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    deleteTrigger(selectedTriggerId);
  }

  void deleteTrigger(String triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _triggerEditingService.deleteTrigger(
        map,
        triggerId: triggerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId == triggerId
            ? null
            : state.selectedTriggerId,
        statusMessage: 'Trigger deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trigger: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Gameplay zones
  // ---------------------------------------------------------------------------

  MapGameplayZone? getSelectedGameplayZone() {
    return _gameplayZoneEditingService.findSelectedZone(
      state.activeMap,
      state.selectedGameplayZoneId,
    );
  }

  void placeOrSelectGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _gameplayZoneEditingService.findZoneAtPos(map, pos);
    if (existing != null) {
      selectGameplayZone(existing.id);
      return;
    }
    addGameplayZoneAt(pos);
  }

  void addGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.addZoneAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" created',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  void selectGameplayZone(String? zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    if (zoneId == null) {
      state = state.copyWith(selectedGameplayZoneId: null);
      return;
    }
    final zone = _gameplayZoneEditingService.findSelectedZone(map, zoneId);
    if (zone == null) {
      state = state.copyWith(errorMessage: 'Zone not found: $zoneId');
      return;
    }
    state = state.copyWith(selectedGameplayZoneId: zone.id);
  }

  void updateSelectedGameplayZone({
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? hazard,
    Object? special,
  }) {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    updateGameplayZone(
      zoneId: selectedZoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      hazard: hazard,
      special: special,
    );
  }

  void updateGameplayZone({
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? hazard,
    Object? special,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.updateZone(
        map,
        zoneId: zoneId,
        id: id,
        name: name,
        kind: kind,
        area: area,
        priority: priority,
        encounter: encounter,
        movement: movement,
        hazard: hazard,
        special: special,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone updated',
      );
      state = state.copyWith(selectedGameplayZoneId: result.selectedZoneId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update zone: $e');
    }
  }

  void deleteSelectedGameplayZone() {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    deleteGameplayZone(selectedZoneId);
  }

  void deleteGameplayZone(String zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated =
          _gameplayZoneEditingService.deleteZone(map, zoneId: zoneId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone deleted',
      );
      if (state.selectedGameplayZoneId == zoneId) {
        state = state.copyWith(selectedGameplayZoneId: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete zone: $e');
    }
  }

  // Drag-to-draw ─────────────────────────────────────────────────────────────

  /// Met à jour l'aire de tracé en cours (fantôme visible sur le canvas).
  void setGameplayZoneDraftArea(MapRect area) {
    state = state.copyWith(gameplayZoneDraftArea: area);
  }

  /// Valide le tracé et crée la zone persistée.
  void commitGameplayZoneDraft() {
    final draft = state.gameplayZoneDraftArea;
    if (draft == null) return;
    state = state.copyWith(gameplayZoneDraftArea: null);
    final map = state.activeMap;
    if (map == null) return;
    // Clamp la zone dans les limites de la map
    final clampedArea = _clampRectToMap(draft, map.size);
    if (clampedArea == null) return;
    try {
      final result =
          _gameplayZoneEditingService.addZoneInRect(map, clampedArea);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" créée',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  /// Annule le tracé en cours sans créer de zone.
  void cancelGameplayZoneDraft() {
    state = state.copyWith(gameplayZoneDraftArea: null);
  }

  static MapRect? _clampRectToMap(MapRect rect, GridSize mapSize) {
    final x = rect.pos.x.clamp(0, mapSize.width - 1);
    final y = rect.pos.y.clamp(0, mapSize.height - 1);
    final w = rect.size.width.clamp(1, mapSize.width - x);
    final h = rect.size.height.clamp(1, mapSize.height - y);
    if (w <= 0 || h <= 0) return null;
    return MapRect(
        pos: GridPos(x: x, y: y), size: GridSize(width: w, height: h));
  }

  void placeOrSelectWarpAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _warpEditingService.findWarpAtPos(map, pos);
    if (existing != null) {
      selectWarp(existing.id);
      return;
    }
    addWarpAt(pos);
  }

  void addWarpAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.addWarpAt(map, project, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.createdWarp.id,
        statusMessage: 'Warp "${result.createdWarp.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create warp: $e');
    }
  }

  void selectWarp(String? warpId) {
    final map = state.activeMap;
    if (map == null) return;
    if (warpId == null) {
      state = state.copyWith(
        selectedWarpId: null,
        errorMessage: null,
      );
      return;
    }
    final warp = _warpEditingService.findSelectedWarp(map, warpId);
    if (warp == null) {
      state = state.copyWith(errorMessage: 'Warp not found: $warpId');
      return;
    }
    state = state.copyWith(
      selectedWarpId: warp.id,
      errorMessage: null,
    );
  }

  void updateSelectedWarp({
    required String id,
    required String targetMapId,
    required int targetPosX,
    required int targetPosY,
    required MapWarpTriggerMode triggerMode,
    required List<EntityFacing> allowedApproachFacings,
    required WarpTriggerPadding triggerPadding,
  }) {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    updateWarp(
      warpId: selectedWarpId,
      id: id,
      targetMapId: targetMapId,
      targetPos: GridPos(x: targetPosX, y: targetPosY),
      triggerMode: triggerMode,
      allowedApproachFacings: allowedApproachFacings,
      triggerPadding: triggerPadding,
    );
  }

  Future<void> createReciprocalWarpForSelectedWarp() async {
    final fs = _projectWorkspace;
    final project = state.project;
    final sourceMap = state.activeMap;
    final selectedWarpId = state.selectedWarpId;
    if (fs == null) {
      state = state.copyWith(errorMessage: 'No project filesystem available');
      return;
    }
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return;
    }
    if (sourceMap == null) {
      state = state.copyWith(errorMessage: 'No active map loaded');
      return;
    }
    if (selectedWarpId == null) {
      state = state.copyWith(errorMessage: 'No warp selected');
      return;
    }
    try {
      final selectedWarp =
          _warpEditingService.requireSelectedWarp(sourceMap, selectedWarpId);
      final result = await _warpEditingService.createReciprocalWarp(
        fs,
        project,
        sourceMap: sourceMap,
        sourceWarp: selectedWarp,
      );

      if (result.targetIsSourceMap) {
        _applyMapMutation(
          previousMap: sourceMap,
          updatedMap: result.updatedTargetMap,
          preferredActiveLayerId: state.activeLayerId,
          preferredSelectedWarpId: selectedWarpId,
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
        );
      } else {
        state = state.copyWith(
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create return warp: $e');
    }
  }

  void updateWarp({
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
    MapWarpTriggerMode? triggerMode,
    List<EntityFacing>? allowedApproachFacings,
    WarpTriggerPadding? triggerPadding,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.updateWarp(
        map,
        project,
        warpId: warpId,
        id: id,
        pos: pos,
        targetMapId: targetMapId,
        targetPos: targetPos,
        triggerMode: triggerMode,
        allowedApproachFacings: allowedApproachFacings,
        triggerPadding: triggerPadding,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.selectedWarpId,
        statusMessage: 'Warp updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update warp: $e');
    }
  }

  void deleteSelectedWarp() {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    deleteWarp(selectedWarpId);
  }

  void deleteWarp(String warpId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _warpEditingService.deleteWarp(
        map,
        warpId: warpId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId:
            state.selectedWarpId == warpId ? null : state.selectedWarpId,
        statusMessage: 'Warp deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete warp: $e');
    }
  }

  Future<void> saveMapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final map = state.activeMap;
    if (fs == null || project == null || map == null) return;
    try {
      final updatedMap = await _mapConnectionEditingService.upsertConnection(
        fs,
        project,
        sourceMap: map,
        direction: direction,
        targetMapId: targetMapId,
        offset: offset,
      );
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        targetMapId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage:
            '${direction.name.toUpperCase()} connection saved to "${targetEntry.name}"',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save map connection: $e',
      );
    }
  }

  void deleteMapConnection(MapConnectionDirection direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = _mapConnectionEditingService.deleteConnection(
        map,
        direction: direction,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage: '${direction.name.toUpperCase()} connection deleted',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete map connection: $e',
      );
    }
  }

  Future<void> openConnectedMap(MapConnectionDirection direction) async {
    final project = state.project;
    final connection = getMapConnection(direction);
    if (project == null || connection == null) {
      state = state.copyWith(
        errorMessage: 'No ${direction.name} connection available',
      );
      return;
    }
    try {
      endMapStroke();
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        connection.targetMapId,
      );
      await loadMap(targetEntry.relativePath);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to open connected map: $e',
      );
    }
  }

  MapToolPreview? resolveMapToolPreview({
    GridPos? hoveredTile,
    required Map<String, int> tilesetColumnsById,
  }) {
    if (hoveredTile == null) return null;
    final tool = state.activeTool;
    if (tool != EditorToolType.tilePaint &&
        tool != EditorToolType.terrainPaint &&
        tool != EditorToolType.collisionPaint &&
        tool != EditorToolType.eraser) {
      return null;
    }
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) return null;
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) return null;

    if (tool == EditorToolType.tilePaint) {
      if (activeLayer is! TileLayer) return null;
      final resolvedBrush = _resolveActiveBrushPattern(
        tilesetColumnsById: tilesetColumnsById,
        emitErrors: false,
      );
      if (resolvedBrush == null) return null;
      final compatibility = _resolveLayerBrushCompatibility(
        activeLayer,
        resolvedBrush.tilesetId,
      );
      final validity = compatibility == _BrushLayerCompatibility.incompatible
          ? MapToolPreviewValidity.invalid
          : MapToolPreviewValidity.valid;
      return MapToolPreview.paint(
        origin: hoveredTile,
        size: resolvedBrush.pattern.size,
        tilesetId: resolvedBrush.tilesetId,
        tiles: resolvedBrush.pattern.tiles,
        validity: validity,
      );
    }

    if (tool == EditorToolType.terrainPaint) {
      if (activeLayer is TerrainLayer) {
        final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
        if (terrainFootprint == null) return null;
        return MapToolPreview.terrainPaint(
          origin: hoveredTile,
          size: terrainFootprint.size,
          terrain: state.selectedTerrainType,
          validity: MapToolPreviewValidity.valid,
        );
      }
      if (activeLayer is PathLayer) {
        final pathFootprint = _resolvePathFootprint();
        return MapToolPreview.pathPaint(
          origin: hoveredTile,
          size: pathFootprint.size,
          validity: MapToolPreviewValidity.valid,
        );
      }
      return null;
    }

    if (tool == EditorToolType.collisionPaint) {
      if (activeLayer is! CollisionLayer) return null;
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionPaint(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }

    if (activeLayer is TileLayer) {
      final erasePattern = _resolveErasePattern(emitErrors: false);
      if (erasePattern == null) return null;
      return MapToolPreview.erase(
        origin: hoveredTile,
        size: erasePattern.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionErase(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
      if (terrainFootprint == null) return null;
      return MapToolPreview.terrainErase(
        origin: hoveredTile,
        size: terrainFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      return MapToolPreview.pathErase(
        origin: hoveredTile,
        size: pathFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    return null;
  }

  void paintSelectedTileAt(GridPos pos) {
    beginMapStroke();
    paintSelectedBrushAt(pos, tilesetColumnsById: const {});
    endMapStroke();
  }

  void beginMapStroke() {
    state = _mapEditingController.beginStroke(state);
  }

  void endMapStroke() {
    state = _mapEditingController.endStroke(state);
  }

  void undoMap() {
    endMapStroke();
    final restored = _mapEditingController.undo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  void redoMap() {
    endMapStroke();
    final restored = _mapEditingController.redo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  EditorBrush _clearBrushIfTilesetRemoved(EditorBrush brush, String tilesetId) {
    if (brush is TileEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is PaletteEntryEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element != null && element.tilesetId == tilesetId) {
        return const EditorBrush.none();
      }
    }
    return brush;
  }

  _PaintPattern _buildPatternFromSource(
    TilesetSourceRect source, {
    required int tilesetColumns,
  }) {
    final tiles = List<int>.filled(
      source.width * source.height,
      0,
      growable: false,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final sourceX = source.x + x;
        final sourceY = source.y + y;
        tiles[y * source.width + x] = sourceY * tilesetColumns + sourceX + 1;
      }
    }
    return _PaintPattern(
      size: GridSize(width: source.width, height: source.height),
      tiles: tiles,
    );
  }

  _ResolvedBrushPattern? _resolveActiveBrushPattern({
    required Map<String, int> tilesetColumnsById,
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) return null;

    if (brush is TileEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected tile brush does not have a valid tileset');
        }
        return null;
      }
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'tile',
        pattern: _PaintPattern(
          size: const GridSize(width: 1, height: 1),
          tiles: <int>[brush.tileId],
        ),
      );
    }

    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
            'Selected palette brush does not have a valid tileset',
          );
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'palette entry',
        pattern: _buildPatternFromSource(
          entry.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      final tilesetId = element.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected project element does not have a tileset');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'element',
        pattern: _buildPatternFromSource(
          element.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    return null;
  }

  _ErasePattern? _resolveErasePattern({
    required bool emitErrors,
  }) {
    final footprint = _resolveBrushFootprint(emitErrors: emitErrors);
    if (footprint == null) return null;
    return _ErasePattern(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveCollisionFootprint({
    required bool emitErrors,
  }) {
    if (state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    return _resolveBrushFootprint(emitErrors: emitErrors);
  }

  _ResolvedBrushFootprint? _resolveTerrainFootprint({
    required bool emitErrors,
  }) {
    final footprint = _terrainPaintingCoordinator.resolveFootprint(
      terrain: state.selectedTerrainType,
    );
    return _ResolvedBrushFootprint(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveBrushFootprint({
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is TileEditorBrush) {
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
              'Selected palette brush does not have a valid tileset');
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: entry.frames.primarySource.width,
          height: entry.frames.primarySource.height,
        ),
        failureLabel: 'palette entry',
      );
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: element.frames.primarySource.width,
          height: element.frames.primarySource.height,
        ),
        failureLabel: 'element',
      );
    }
    return null;
  }

  void _paintPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required _PaintPattern pattern,
    required String failureLabel,
  }) {
    try {
      final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        tiles: pattern.tiles,
        clipToMapBounds: true,
      );
      final project = state.project;
      final committed = project == null
          ? painted
          : _placedElementInstanceIndexer.syncLayer(
              map: painted,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint $failureLabel: $e');
    }
  }

  void _erasePattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final project = state.project;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        final committed = project == null
            ? erased
            : _placedElementInstanceIndexer.syncLayer(
                map: erased,
                project: project,
                layerId: layerId,
              );
        _applyMapMutation(
          previousMap: map,
          updatedMap: committed,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }

      final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase $failureLabel: $e');
    }
  }

  void _paintCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(paintCollisionOnMapUseCaseProvider);
        final painted = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: painted,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(paintCollisionPatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: painted,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint collision $failureLabel: $e');
    }
  }

  void _eraseCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseCollisionOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(eraseCollisionPatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase collision $failureLabel: $e');
    }
  }

  void _paintTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required TerrainType terrain,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _terrainPaintingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: terrain,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint terrain $failureLabel: $e');
    }
  }

  void _paintPathPattern({
    required MapData map,
    required MapData previousMap,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _pathLayerEditingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: previousMap,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint path $failureLabel: $e');
    }
  }

  void _eraseTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _terrainPaintingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase terrain $failureLabel: $e');
    }
  }

  void _erasePathPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _pathLayerEditingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase path $failureLabel: $e');
    }
  }

  void _setPaintError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  _ActiveTileLayerContext? _resolveActiveTileLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active tile layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TileLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a tile layer');
      }
      return null;
    }
    return _ActiveTileLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveCollisionLayerContext? _resolveActiveCollisionLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active collision layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! CollisionLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a collision layer');
      }
      return null;
    }
    return _ActiveCollisionLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveTerrainLayerContext? _resolveActiveTerrainLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active terrain layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TerrainLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a terrain layer');
      }
      return null;
    }
    return _ActiveTerrainLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  PathLayerBrushFootprint _resolvePathFootprint() {
    return _pathLayerEditingCoordinator.resolveFootprint();
  }

  _ActivePathLayerContext? _resolveActivePathLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active path layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! PathLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a path layer');
      }
      return null;
    }
    return _ActivePathLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _BrushLayerCompatibility _resolveLayerBrushCompatibility(
    TileLayer activeLayer,
    String brushTilesetId,
  ) {
    final currentTilesetId = activeLayer.tilesetId?.trim();
    if (currentTilesetId == brushTilesetId) {
      return _BrushLayerCompatibility.compatible;
    }
    if (currentTilesetId == null ||
        currentTilesetId.isEmpty ||
        _isTileLayerEmpty(activeLayer)) {
      return _BrushLayerCompatibility.rebindable;
    }
    return _BrushLayerCompatibility.incompatible;
  }

  MapData? _prepareMapForBrushTileset({
    required MapData map,
    required String layerId,
    required TileLayer activeLayer,
    required String brushTilesetId,
  }) {
    final compatibility = _resolveLayerBrushCompatibility(
      activeLayer,
      brushTilesetId,
    );
    if (compatibility == _BrushLayerCompatibility.compatible) {
      return map;
    }
    if (compatibility == _BrushLayerCompatibility.incompatible) {
      _setPaintError(
        'Layer "${activeLayer.name}" already contains tiles from another source',
      );
      return null;
    }

    final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
    final layerIndex = updatedLayers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      _setPaintError('Active layer not found: $layerId');
      return null;
    }
    final layer = updatedLayers[layerIndex];
    if (layer is! TileLayer) {
      _setPaintError('Active layer is not a tile layer');
      return null;
    }
    updatedLayers[layerIndex] = layer.copyWith(tilesetId: brushTilesetId);
    final updatedMap = map.copyWith(
      layers: updatedLayers,
      tilesetId: map.tilesetId.trim().isEmpty ? brushTilesetId : map.tilesetId,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: layerId,
      statusMessage: 'Layer "${activeLayer.name}" updated for current brush',
      partOfStroke: true,
    );
    state = state.copyWith(
      selectedTilesetEditorId: brushTilesetId,
      selectedTilesetElementGroupId: null,
      paletteCategoryFilter: null,
    );
    return updatedMap;
  }

  bool _isTileLayerEmpty(TileLayer layer) {
    for (final tile in layer.tiles) {
      if (tile != 0) return false;
    }
    return true;
  }

  void addMapLayer({
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.execute(
        map,
        kind: kind,
        name: name,
        tileTilesetId: tileTilesetId,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add layer: $e');
    }
  }

  void renameMapLayer(String layerId, String name) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(renameMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        name: name,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Layer renamed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename layer: $e');
    }
  }

  void deleteMapLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final removedIndex = _findLayerIndexById(map, layerId);
    if (removedIndex < 0) return;
    try {
      final useCase = ref.read(deleteMapLayerUseCaseProvider);
      final updated = useCase.execute(map, layerId: layerId);
      final nextActiveLayerId = state.activeLayerId == layerId
          ? _editorMapSessionCoordinator.resolveFallbackLayerIdAfterDeletion(
              updated,
              removedIndex: removedIndex,
            )
          : _editorMapSessionCoordinator.resolveActiveLayerId(
              updated,
              preferredLayerId: state.activeLayerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: nextActiveLayerId,
        statusMessage: 'Layer deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete layer: $e');
    }
  }

  void deleteAllMapLayers() {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(deleteAllMapLayersUseCaseProvider);
      final updated = useCase.execute(map);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId:
            _editorMapSessionCoordinator.resolveActiveLayerId(updated),
        statusMessage: 'All layers removed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove all layers: $e');
    }
  }

  void moveMapLayerUp(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void moveMapLayerDown(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerForward(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerBackward(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void _moveMapLayer(String layerId, int direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(moveMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        direction: direction,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  void reorderMapLayers(int oldIndex, int newIndex) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(reorderMapLayersUseCaseProvider);
      final updated = useCase.execute(
        map,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  /// Places [layerId] before [beforeIndex] (0 = top of list, [layers.length] = bottom).
  void moveMapLayerBeforeIndex(String layerId, int beforeIndex) {
    final map = state.activeMap;
    if (map == null) return;
    final oldIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (oldIndex < 0) return;
    reorderMapLayers(oldIndex, beforeIndex);
  }

  void setMapLayerVisibility(String layerId, bool isVisible) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerVisibilityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        isVisible: isVisible,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: isVisible ? 'Layer shown' : 'Layer hidden',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update layer: $e');
    }
  }

  void setMapLayerOpacity(String layerId, double opacity) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerOpacityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        opacity: opacity,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update layer opacity: $e');
    }
  }

  void selectTool(EditorToolType tool) {
    state = _mapSelectionController.selectTool(
      current: state,
      tool: tool,
    );
  }

  void selectTerrainType(TerrainType terrain) {
    state = _mapSelectionController.selectTerrainType(
      current: state,
      terrain: terrain,
    );
  }

  void selectTerrainPreset(String? presetId) {
    state = _mapSelectionController.selectTerrainPreset(
      current: state,
      preset: getTerrainPresetById(presetId),
    );
  }

  void selectPathPreset(String? presetId) {
    state = _mapSelectionController.selectPathPreset(
      current: state,
      preset: getPathPresetById(presetId),
    );
  }

  void selectPathPresetForActivePathLayer(String? presetId) {
    final preset = getPathPresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Path preset not found');
      return;
    }
    selectPathPreset(presetId);
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! PathLayer) {
      return;
    }
    assignPathPresetToActivePathLayer(preset.id);
  }

  void selectTerrainPaintMode({
    TerrainType? terrainType,
  }) {
    state = _mapSelectionController.selectTerrainPaintMode(
      current: state,
      terrainType: terrainType,
    );
  }

  void selectPathPaintMode() {
    state = _mapSelectionController.selectPathPaintMode(
      current: state,
      selectedPathPreset: getSelectedPathPreset(),
    );
  }

  Future<void> createTerrainPreset({
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    String tilesetId = '',
    List<TerrainPresetVariant> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create terrain preset: $e',
      );
    }
  }

  Future<void> updateTerrainPreset({
    required String presetId,
    String? name,
    TerrainType? terrainType,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<TerrainPresetVariant>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selectedPreset =
          _terrainPresetResolver.findTerrainPresetById(updated, presetId) ??
              (throw EditorNotFoundException(
                'Terrain preset not found: $presetId',
              ));
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selectedPreset,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update terrain preset: $e',
      );
    }
  }

  Future<void> deleteTerrainPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete terrain preset: $e',
      );
    }
  }

  Future<void> createPathPreset({
    required String name,
    PathSurfaceKind surfaceKind = PathSurfaceKind.path,
    String? categoryId,
    String tilesetId = '',
    List<PathPresetVariantMapping> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        activeTool: EditorToolType.terrainPaint,
        statusMessage: 'Path preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create path preset: $e');
    }
  }

  Future<void> updatePathPreset({
    required String presetId,
    String? name,
    PathSurfaceKind? surfaceKind,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<PathPresetVariantMapping>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updatePathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selected = updated.pathPresets.firstWhere(
        (preset) => preset.id == presetId,
        orElse: () => throw EditorNotFoundException(
          'Path preset not found: $presetId',
        ),
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selected,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update path preset: $e');
    }
  }

  List<PathLayer> getPathLayersForPreset(String presetId) {
    final map = state.activeMap;
    if (map == null) return const [];
    return map.layers
        .whereType<PathLayer>()
        .where((l) => l.presetId.trim() == presetId.trim())
        .toList(growable: false);
  }

  void applyPathLayerAnimationTriggers({
    required String layerId,
    required List<PathAnimationTriggerRule> triggers,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationTriggers(
        map,
        layerId: layerId,
        triggers: triggers,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation triggers updated',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to update animation triggers: $e');
    }
  }

  void setPathLayerAnimationMode({
    required String layerId,
    required PathAnimationMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationModeInMap(
        map,
        layerId: layerId,
        mode: mode,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation mode updated',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update animation mode: $e');
    }
  }

  Future<void> deletePathPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePathPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete path preset: $e');
    }
  }

  Future<void> createPresetCategory({
    required String name,
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        kind: kind,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> renamePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renamePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> deletePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
      );
      final selection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Category deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete category: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Encounter tables
  // ---------------------------------------------------------------------------

  Future<void> createEncounterTable({
    required String name,
    required EncounterKind encounterKind,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table created',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create encounter table: $e');
    }
  }

  Future<void> updateEncounterTable({
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter table: $e');
    }
  }

  Future<void> deleteEncounterTable(String tableId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterTableUseCaseProvider);
      final updated = await useCase.execute(fs, project, tableId: tableId);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter table: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Project dialogues (bibliothèque)
  // ---------------------------------------------------------------------------

  void selectProjectDialogue(String? dialogueId) {
    state = _projectContentController.selectProjectDialogue(state, dialogueId);
  }

  Future<void> createProjectDialogue({
    required String name,
    String? folderId,
  }) async {
    state = await _projectContentController.createProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      folderId: folderId,
    );
  }

  Future<void> importProjectDialogue({
    required String absoluteSourcePath,
    required String displayName,
    String? folderId,
  }) async {
    state = await _projectContentController.importProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      absoluteSourcePath: absoluteSourcePath,
      displayName: displayName,
      folderId: folderId,
    );
  }

  Future<void> renameProjectDialogue({
    required String dialogueId,
    required String newName,
  }) async {
    state = await _projectContentController.renameProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      newName: newName,
    );
  }

  Future<void> deleteProjectDialogue(String dialogueId) async {
    state = await _projectContentController.deleteProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  Future<void> createDialogueLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    state = await _projectContentController.createDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      parentFolderId: parentFolderId,
    );
  }

  Future<void> renameDialogueLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    state = await _projectContentController.renameDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      name: name,
    );
  }

  Future<void> moveDialogueLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    state = await _projectContentController.moveDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      newParentFolderId: newParentFolderId,
    );
  }

  Future<void> deleteDialogueLibraryFolder(String folderId) async {
    state = await _projectContentController.deleteDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
    );
  }

  Future<void> assignDialogueToLibraryFolder({
    required String dialogueId,
    required String folderId,
  }) async {
    state = await _projectContentController.assignDialogueToLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      folderId: folderId,
    );
  }

  Future<void> moveDialogueToLibraryRoot(String dialogueId) async {
    state = await _projectContentController.moveDialogueToLibraryRoot(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  // ---------------------------------------------------------------------------
  // Narrative Studio - scénarios
  // ---------------------------------------------------------------------------
  //
  // Ce bloc réintroduit des mutations scénario ciblées, mais dans un cadre
  // beaucoup plus strict que l'ancien "Scenario Graph" générique:
  // - surface d'édition centrale (Cutscene Studio v1 guidé),
  // - opérations explicites create / update / delete,
  // - persistance via use-cases dédiés + validation `ProjectValidator`.
  //
  // Frontière volontaire:
  // - ce notifier orchestre la mutation et la UX (messages, sélection),
  // - la logique métier de validation/persistance reste dans les use-cases.
  // ---------------------------------------------------------------------------

  Future<void> createProjectScenario(ScenarioAsset scenario) async {
    state = await _projectContentController.createProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenario: scenario,
    );
  }

  Future<void> updateProjectScenario({
    required String scenarioId,
    required ScenarioAsset scenario,
  }) async {
    state = await _projectContentController.updateProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
      scenario: scenario,
    );
  }

  Future<void> deleteProjectScenario(String scenarioId) async {
    state = await _projectContentController.deleteProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
    );
  }

  Future<void> addEncounterEntry({
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(addEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry added',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add encounter entry: $e');
    }
  }

  Future<void> updateEncounterEntry({
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter entry: $e');
    }
  }

  Future<void> deleteEncounterEntry({
    required String tableId,
    required int entryIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter entry: $e');
    }
  }

  void activateFirstTerrainLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is TerrainLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.terrain,
        name: 'Terrain',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No terrain layer found in this map',
    );
  }

  void activateFirstPathLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is PathLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.path,
        name: 'Path',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No path layer found in this map',
    );
  }

  void setCollisionBrushSizeMode(CollisionBrushSizeMode mode) {
    if (state.collisionBrushSizeMode == mode) return;
    state = state.copyWith(
      collisionBrushSizeMode: mode,
      statusMessage: mode == CollisionBrushSizeMode.singleTile
          ? 'Collision brush: 1x1'
          : 'Collision brush: brush footprint',
      errorMessage: null,
    );
  }

  void toggleCollisionBrushSizeMode() {
    setCollisionBrushSizeMode(
      state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile
          ? CollisionBrushSizeMode.brushFootprint
          : CollisionBrushSizeMode.singleTile,
    );
  }

  void setActiveLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final selectedLayer = _findLayerById(map, layerId);
    if (selectedLayer == null) {
      state = state.copyWith(errorMessage: 'Layer not found: $layerId');
      return;
    }
    state = state.copyWith(
      activeLayerId: layerId,
      selectedPlacedElementInstanceId: null,
      errorMessage: null,
    );
    _coerceActiveToolIfIncompatibleWithLayer();
  }

  void setTilesElementsPanelMode(TilesElementsPanelMode mode) {
    if (state.tilesElementsPanelMode == mode) {
      return;
    }
    state = state.copyWith(
      tilesElementsPanelMode: mode,
      errorMessage: null,
    );
  }

  void selectPlacedElementInstance({
    required String? instanceId,
    String? elementId,
    String? layerId,
  }) {
    if (state.selectedPlacedElementInstanceId == instanceId) {
      return;
    }
    state = state.copyWith(
      selectedPlacedElementInstanceId: instanceId,
      errorMessage: null,
    );
    if (instanceId == null) {
      debugPrint('[editor][elements] selected placed instance cleared');
      return;
    }
    final safeElementId = elementId?.trim() ?? '';
    final safeLayerId = layerId?.trim() ?? '';
    debugPrint(
      '[editor][elements] selected placed instance id=$instanceId elementId=$safeElementId layer=$safeLayerId',
    );
  }

  void setPlacedElementInstanceCollisionApplied({
    required String instanceId,
    required bool applyCollision,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.applyCollision == applyCollision) {
      return;
    }
    final updatedMap = setMapPlacedElementCollisionApplied(
      map,
      instanceId: trimmedId,
      applyCollision: applyCollision,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage:
          'Collision ${applyCollision ? 'activée' : 'désactivée'} pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceAnimationConfig({
    required String instanceId,
    required MapPlacedElementAnimation? animation,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.animation == animation) {
      return;
    }
    final updatedMap = setMapPlacedElementAnimation(
      map,
      instanceId: trimmedId,
      animation: animation,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: animation == null
          ? 'Animation réinitialisée pour ${previous.elementId}'
          : 'Animation mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceBehaviors({
    required String instanceId,
    required List<MapPlacedElementBehavior> behaviors,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (listEquals(previous.behaviors, behaviors)) {
      return;
    }
    final updatedMap = setMapPlacedElementBehaviors(
      map,
      instanceId: trimmedId,
      behaviors: behaviors,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: behaviors.isEmpty
          ? 'Comportements réinitialisés pour ${previous.elementId}'
          : 'Comportements mis à jour pour ${previous.elementId}',
    );
  }

  void deletePlacedElementInstance({
    required String instanceId,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final instance = map.placedElements[index];
    final layer = _findLayerById(map, instance.layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Placed element layer is not a tile layer: ${instance.layerId}',
      );
      return;
    }

    final project = state.project;
    var patternSize = const GridSize(width: 1, height: 1);
    if (project != null) {
      ProjectElementEntry? element;
      for (final entry in project.elements) {
        if (entry.id == instance.elementId) {
          element = entry;
          break;
        }
      }
      if (element != null) {
        final source = element.frames.primarySource;
        patternSize = GridSize(
          width: source.width > 0 ? source.width : 1,
          height: source.height > 0 ? source.height : 1,
        );
      }
    }

    try {
      late final MapData erased;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
        );
      } else {
        final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
          patternSize: patternSize,
          clipToMapBounds: true,
        );
      }

      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: instance.layerId,
            );

      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Instance supprimée (${instance.elementId})',
      );
      debugPrint(
        '[editor][elements] deleted placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete placed element instance: $e',
      );
    }
  }

  /// Bascule vers la sélection si l’outil courant ne peut pas agir sur le calque actif.
  void _coerceActiveToolIfIncompatibleWithLayer() {
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      state,
    );
  }

  void updateHoveredTile(GridPos? pos) {
    if (state.hoveredTile != pos) {
      state = state.copyWith(hoveredTile: pos);
    }
  }

  void pan(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void zoom(double delta) {
    final newZoom = (state.zoom + delta).clamp(0.1, 5.0);
    state = state.copyWith(zoom: newZoom);
  }

  void _applyMapMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? preferredSelectedEntityId,
    String? preferredSelectedMapEventId,
    String? preferredSelectedWarpId,
    String? preferredSelectedTriggerId,
    bool partOfStroke = false,
    bool updateSavedSnapshot = false,
    GridPos? hoveredTile,
    bool updateHoveredTile = false,
    String? statusMessage,
  }) {
    final next = _mapEditingController.applyMutation(
      current: state,
      previousMap: previousMap,
      updatedMap: updatedMap,
      preferredActiveLayerId: preferredActiveLayerId,
      preferredSelectedEntityId: preferredSelectedEntityId,
      preferredSelectedMapEventId: preferredSelectedMapEventId,
      preferredSelectedWarpId: preferredSelectedWarpId,
      preferredSelectedTriggerId: preferredSelectedTriggerId,
      partOfStroke: partOfStroke,
      updateSavedSnapshot: updateSavedSnapshot,
      hoveredTile: hoveredTile,
      updateHoveredTile: updateHoveredTile,
      statusMessage: statusMessage,
    );
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      next,
    );
  }

  int _findLayerIndexById(MapData map, String layerId) {
    return map.layers.indexWhere((layer) => layer.id == layerId);
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  String? _resolveEventPlacementLayerId(MapData map) {
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId != null &&
        activeLayerId.isNotEmpty &&
        map.layers.any((layer) => layer.id == activeLayerId)) {
      return activeLayerId;
    }
    if (map.layers.isNotEmpty) {
      return map.layers.first.id;
    }
    return null;
  }

  String _generateUniqueMapEventId(MapData map) {
    final ids = map.events.map((event) => event.id).toSet();
    if (!ids.contains('event')) {
      return 'event';
    }
    var index = 1;
    while (ids.contains('event_$index')) {
      index++;
    }
    return 'event_$index';
  }

  // ---------------------------------------------------------------------------
  // Characters (bibliothèque personnages)
  // ---------------------------------------------------------------------------

  void selectCharacter(String? characterId) {
    state = state.copyWith(selectedCharacterId: characterId);
  }

  Future<void> createCharacter({
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId:
            updated.characters.isNotEmpty ? updated.characters.last.id : null,
        statusMessage: 'Character created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create character: $e');
    }
  }

  Future<void> updateCharacter({
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Character updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update character: $e');
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId: state.selectedCharacterId == characterId
            ? null
            : state.selectedCharacterId,
        statusMessage: 'Character deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete character: $e');
    }
  }

  Future<void> upsertCharacterAnimation({
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(upsertCharacterAnimationUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        animState: animState,
        direction: direction,
        frames: frames,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Animation updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update animation: $e');
    }
  }

  Future<void> setPlayerCharacter(String? characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(setPlayerCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: characterId == null
            ? 'Player character cleared'
            : 'Player character set',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to set player character: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Trainers (bibliothèque dresseurs)
  // ---------------------------------------------------------------------------

  void selectTrainer(String? trainerId) {
    state = state.copyWith(selectedTrainerId: trainerId);
  }

  Future<bool> createTrainer({
    required String name,
    required String trainerClass,
    int? battleDifficulty,
    String? battleBackgroundRelativePath,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    List<String> tags = const <String>[],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(createTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: battleDifficulty,
        battleBackgroundRelativePath: battleBackgroundRelativePath,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId:
            updated.trainers.isNotEmpty ? updated.trainers.last.id : null,
        statusMessage: 'Trainer created',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trainer: $e');
      return false;
    }
  }

  Future<bool> updateTrainer({
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? battleDifficulty = _trainerUnset,
    Object? battleBackgroundRelativePath = _trainerUnset,
    Object? characterId = _trainerUnset,
    Object? portraitElementId = _trainerUnset,
    Object? battleThemeId = _trainerUnset,
    Object? victoryThemeId = _trainerUnset,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: battleDifficulty,
        battleBackgroundRelativePath: battleBackgroundRelativePath,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Trainer updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trainer: $e');
      return false;
    }
  }

  Future<bool> deleteTrainer(String trainerId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId: state.selectedTrainerId == trainerId
            ? null
            : state.selectedTrainerId,
        statusMessage: 'Trainer deleted',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trainer: $e');
      return false;
    }
  }

  Future<bool> addTrainerPokemon({
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const <String>[],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(addTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon added',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add Pokémon: $e');
      return false;
    }
  }

  Future<bool> updateTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _trainerUnset,
    Object? formId = _trainerUnset,
    Object? gender = _trainerUnset,
    bool? shiny,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update Pokémon: $e');
      return false;
    }
  }

  Future<bool> deleteTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon removed',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove Pokémon: $e');
      return false;
    }
  }
}

class _PaintPattern {
  const _PaintPattern({
    required this.size,
    required this.tiles,
  });

  final GridSize size;
  final List<int> tiles;
}

enum _BrushLayerCompatibility {
  compatible,
  rebindable,
  incompatible,
}

class _ResolvedBrushPattern {
  const _ResolvedBrushPattern({
    required this.tilesetId,
    required this.failureLabel,
    required this.pattern,
  });

  final String tilesetId;
  final String failureLabel;
  final _PaintPattern pattern;
}

class _ResolvedBrushFootprint {
  const _ResolvedBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ErasePattern {
  const _ErasePattern({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ActiveTileLayerContext {
  const _ActiveTileLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TileLayer layer;
}

class _ActiveCollisionLayerContext {
  const _ActiveCollisionLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final CollisionLayer layer;
}

class _ActiveTerrainLayerContext {
  const _ActiveTerrainLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TerrainLayer layer;
}

class _ActivePathLayerContext {
  const _ActivePathLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final PathLayer layer;
}

```

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../app/providers/core/repository_providers.dart';
import '../../app/providers/pokedex/pokedex_providers.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/local_catalog_lookup_service.dart';
import '../../application/services/pokemon_items_catalog_lookup_service.dart';
import '../../application/services/pokemon_moves_catalog_lookup_service.dart';
import '../../application/services/pokemon_species_lookup_service.dart';
import '../../application/use_cases/load_pokemon_items_catalog_use_case.dart';
import '../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

// Keep the trainer library in one Dart library so we can split the corrective
// pass into neighboring `part` files without changing visibility or adding a
// new trainer-specific architecture.
part 'trainer_library_panel_support.dart';
part 'trainer_library_panel_trainer_widgets.dart';
part 'trainer_library_panel_pokemon_widgets.dart';
part 'trainer_library_panel_workspace_widgets.dart';

const PokemonSpeciesLookupService _speciesLookupService =
    PokemonSpeciesLookupService();
const PokemonMovesCatalogLookupService _movesLookupService =
    PokemonMovesCatalogLookupService();
const PokemonItemsCatalogLookupService _itemsLookupService =
    PokemonItemsCatalogLookupService();
const String _trainerLevelValidationMessage =
    'Level must be between 1 and 100.';
const List<String> _trainerFallbackGenderValues = <String>[
  'male',
  'female',
  'genderless',
  'any',
];
final List<int> _trainerLevelValues = List<int>.generate(
  100,
  (index) => index + 1,
  growable: false,
);

class TrainerLibraryPanel extends ConsumerStatefulWidget {
  const TrainerLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<TrainerLibraryPanel> createState() =>
      _TrainerLibraryPanelState();
}

class _TrainerLibraryPanelState extends ConsumerState<TrainerLibraryPanel> {
  // -------------------------------------------------------------------------
  // Formulaire de création d'un trainer
  // -------------------------------------------------------------------------

  final _newNameController = TextEditingController();
  final _newClassController = TextEditingController();
  final _newPortraitController = TextEditingController();
  final _newBattleThemeController = TextEditingController();
  final _newVictoryThemeController = TextEditingController();
  final _newTagsController = TextEditingController();
  final _trainerSearchController = TextEditingController();
  String? _newCharacterId;
  int? _newBattleDifficulty = 4;
  String? _newBattleBackgroundRelativePath;
  bool _showCreateForm = false;
  bool _showCreateAdvanced = false;
  String? _createTrainerValidationMessage;

  // -------------------------------------------------------------------------
  // Formulaire d'édition du trainer sélectionné
  // -------------------------------------------------------------------------

  String? _editingTrainerId;
  final _editNameController = TextEditingController();
  final _editClassController = TextEditingController();
  final _editPortraitController = TextEditingController();
  final _editBattleThemeController = TextEditingController();
  final _editVictoryThemeController = TextEditingController();
  final _editTagsController = TextEditingController();
  String? _editCharacterId;
  int? _editBattleDifficulty;
  String? _editBattleBackgroundRelativePath;
  bool _showEditAdvanced = false;
  String? _editTrainerValidationMessage;

  // -------------------------------------------------------------------------
  // Draft partagé pour ajout / édition d'un Pokémon de team
  // -------------------------------------------------------------------------

  String? _activePokemonTrainerId;
  int? _editingPokemonIndex;
  final _pokemonSpeciesController = TextEditingController();
  final _pokemonLevelController = TextEditingController(text: '1');
  final _pokemonItemController = TextEditingController();
  final _pokemonFormController = TextEditingController();
  final _pokemonGenderController = TextEditingController();
  late final List<TextEditingController> _pokemonMoveControllers =
      List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );
  bool _pokemonShiny = false;
  String? _pokemonValidationMessage;

  // -------------------------------------------------------------------------
  // Références locales réutilisées par la surface auteur
  // -------------------------------------------------------------------------

  String? _referenceProjectRootPath;
  Future<_TrainerReferenceData>? _referenceDataFuture;
  final Map<String, Future<PokedexSpeciesDetail?>> _speciesDetailFutureCache =
      <String, Future<PokedexSpeciesDetail?>>{};

  @override
  void initState() {
    super.initState();
    // The roster filter stays local to the trainer surface. It is not part of
    // editor-wide state and should never leak into the notifier.
    _trainerSearchController.addListener(_handleRosterSearchChanged);
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newClassController.dispose();
    _newPortraitController.dispose();
    _newBattleThemeController.dispose();
    _newVictoryThemeController.dispose();
    _newTagsController.dispose();
    _trainerSearchController
      ..removeListener(_handleRosterSearchChanged)
      ..dispose();

    _editNameController.dispose();
    _editClassController.dispose();
    _editPortraitController.dispose();
    _editBattleThemeController.dispose();
    _editVictoryThemeController.dispose();
    _editTagsController.dispose();

    _pokemonSpeciesController.dispose();
    _pokemonLevelController.dispose();
    _pokemonItemController.dispose();
    _pokemonFormController.dispose();
    _pokemonGenderController.dispose();
    for (final controller in _pokemonMoveControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _handleRosterSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    _ensureReferenceDataForState(state);

    final content = project == null
        ? Center(
            child: Text(
              'No project loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : FutureBuilder<_TrainerReferenceData>(
            future: _referenceDataFuture,
            initialData: const _TrainerReferenceData.loading(),
            builder: (context, snapshot) {
              final references =
                  snapshot.data ?? const _TrainerReferenceData.loading();
              return widget.embedded
                  ? _buildEmbeddedTrainerLibrary(
                      context: context,
                      state: state,
                      project: project,
                      notifier: notifier,
                      references: references,
                    )
                  : _buildTrainerStudioWorkspace(
                      context: context,
                      state: state,
                      project: project,
                      notifier: notifier,
                      references: references,
                    );
            },
          );

    if (widget.embedded) {
      return content;
    }
    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(context),
      child: content,
    );
  }

  // -------------------------------------------------------------------------
  // Chargement des références locales
  // -------------------------------------------------------------------------

  void _ensureReferenceDataForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (_referenceProjectRootPath == projectRootPath &&
        _referenceDataFuture != null) {
      return;
    }

    _referenceProjectRootPath = projectRootPath;
    _speciesDetailFutureCache.clear();

    final workspace = _workspaceForState(state);
    _referenceDataFuture = workspace == null
        ? Future<_TrainerReferenceData>.value(
            const _TrainerReferenceData.unavailable(),
          )
        : _loadReferenceData(workspace);
  }

  Future<void> _refreshReferenceData(EditorState state) async {
    final workspace = _workspaceForState(state);
    if (workspace == null) {
      return;
    }

    setState(() {
      _speciesDetailFutureCache.clear();
      _referenceDataFuture = _loadReferenceData(workspace);
    });
  }

  ProjectWorkspace? _workspaceForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return null;
    }
    return ref.read(projectWorkspaceFactoryProvider).create(projectRootPath);
  }

  Future<_TrainerReferenceData> _loadReferenceData(
    ProjectWorkspace workspace,
  ) async {
    final speciesLoader = ref.read(pokedexEntryLoaderProvider);
    final movesLoader = ref.read(pokedexMovesCatalogLoaderProvider);
    final itemsLoader = ref.read(loadPokemonItemsCatalogUseCaseProvider);

    List<PokemonDatabaseIndexEntry> speciesEntries = const [];
    String speciesMessage =
        'Aucune espèce locale disponible. La saisie brute reste possible.';
    var isSpeciesAvailable = false;

    try {
      speciesEntries = await speciesLoader(workspace);
      isSpeciesAvailable = speciesEntries.isNotEmpty;
      speciesMessage = speciesEntries.isEmpty
          ? 'Aucune espèce locale n’a encore été indexée. La saisie brute reste possible.'
          : 'Recherche locale active sur ${speciesEntries.length} espèces du projet.';
    } catch (error) {
      speciesMessage =
          'Impossible de charger les espèces locales. La saisie brute reste possible.';
    }

    late final PokemonMovesCatalogView movesCatalogView;
    try {
      movesCatalogView = await movesLoader(workspace);
    } catch (error) {
      // The panel should degrade honestly if a loader blows up unexpectedly.
      // We keep the authoring surface usable with raw IDs instead of leaving
      // the future in an error state that the current builder does not render.
      movesCatalogView = const PokemonMovesCatalogView(
        entries: <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message:
            'Impossible de charger le catalogue local des attaques. La saisie brute reste possible.',
      );
    }

    late final PokemonItemsCatalogView itemsCatalogView;
    try {
      itemsCatalogView = await itemsLoader.execute(workspace);
    } catch (error) {
      itemsCatalogView = const PokemonItemsCatalogView(
        entries: <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        message:
            'Impossible de charger le catalogue local des objets. La saisie brute reste possible.',
      );
    }

    return _TrainerReferenceData(
      speciesEntries: speciesEntries,
      isSpeciesAvailable: isSpeciesAvailable,
      speciesMessage: speciesMessage,
      movesCatalogView: movesCatalogView,
      itemsCatalogView: itemsCatalogView,
    );
  }

  Future<PokedexSpeciesDetail?> _loadSpeciesDetailIfPossible(
    ProjectWorkspace workspace,
    String rawSpeciesId,
  ) {
    final speciesId = rawSpeciesId.trim();
    if (speciesId.isEmpty) {
      return Future<PokedexSpeciesDetail?>.value(null);
    }

    final existingFuture = _speciesDetailFutureCache[speciesId];
    if (existingFuture != null) {
      return existingFuture;
    }

    final loader = ref.read(pokedexSpeciesDetailLoaderProvider);
    final future = loader(workspace, speciesId)
        .then<PokedexSpeciesDetail?>((detail) => detail)
        .catchError((_) => null);
    _speciesDetailFutureCache[speciesId] = future;
    return future;
  }

  // -------------------------------------------------------------------------
  // Trainer CRUD
  // -------------------------------------------------------------------------

  Future<void> _handleCreateTrainer({
    required EditorNotifier notifier,
    required ProjectManifest project,
  }) async {
    final validation = _validateTrainerDraft(
      project: project,
      name: _newNameController.text,
      trainerClass: _newClassController.text,
      battleDifficulty: _newBattleDifficulty,
      battleBackgroundRelativePath: _newBattleBackgroundRelativePath,
      portraitElementId: _newPortraitController.text,
    );
    setState(() {
      _createTrainerValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final success = await notifier.createTrainer(
      name: _newNameController.text,
      trainerClass: _newClassController.text,
      battleDifficulty: _newBattleDifficulty,
      battleBackgroundRelativePath: _newBattleBackgroundRelativePath,
      characterId: _newCharacterId,
      portraitElementId: _newPortraitController.text,
      battleThemeId: _newBattleThemeController.text,
      victoryThemeId: _newVictoryThemeController.text,
      tags: _splitCommaSeparatedValues(_newTagsController.text),
    );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_resetCreateTrainerDraft);
      return;
    }

    setState(() {
      _createTrainerValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to create trainer.';
    });
  }

  Future<void> _handleUpdateTrainer({
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ProjectTrainerEntry trainer,
  }) async {
    final validation = _validateTrainerDraft(
      project: project,
      name: _editNameController.text,
      trainerClass: _editClassController.text,
      battleDifficulty: _editBattleDifficulty,
      battleBackgroundRelativePath: _editBattleBackgroundRelativePath,
      portraitElementId: _editPortraitController.text,
    );
    setState(() {
      _editTrainerValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final success = await notifier.updateTrainer(
      trainerId: trainer.id,
      name: _editNameController.text,
      trainerClass: _editClassController.text,
      battleDifficulty: _editBattleDifficulty,
      battleBackgroundRelativePath: _editBattleBackgroundRelativePath,
      characterId: _editCharacterId,
      portraitElementId: _editPortraitController.text,
      battleThemeId: _editBattleThemeController.text,
      victoryThemeId: _editVictoryThemeController.text,
      tags: _splitCommaSeparatedValues(_editTagsController.text),
    );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_closeTrainerEditor);
      return;
    }

    setState(() {
      _editTrainerValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to update trainer.';
    });
  }

  Future<void> _handleDeleteTrainer({
    required EditorNotifier notifier,
    required ProjectTrainerEntry trainer,
  }) async {
    final success = await notifier.deleteTrainer(trainer.id);
    if (!mounted || !success) {
      return;
    }
    setState(() {
      if (_editingTrainerId == trainer.id) {
        _closeTrainerEditor();
      }
      if (_activePokemonTrainerId == trainer.id) {
        _closePokemonEditor();
      }
    });
  }

  String? _validateTrainerDraft({
    required ProjectManifest project,
    required String name,
    required String trainerClass,
    required int? battleDifficulty,
    required String? battleBackgroundRelativePath,
    required String portraitElementId,
  }) {
    if (name.trim().isEmpty) {
      return 'Trainer name cannot be empty.';
    }
    if (trainerClass.trim().isEmpty) {
      return 'Trainer class cannot be empty.';
    }

    final portraitId = portraitElementId.trim();
    if (portraitId.isNotEmpty &&
        !project.elements.any((element) => element.id == portraitId)) {
      return 'Portrait element "$portraitId" does not exist in this project.';
    }

    if (battleDifficulty != null &&
        (battleDifficulty < 1 || battleDifficulty > 10)) {
      return 'Battle difficulty must stay between 1 and 10.';
    }

    final normalizedBattleBackgroundPath =
        _normalizeOptionalField(battleBackgroundRelativePath ?? '');
    if (normalizedBattleBackgroundPath != null) {
      final normalizedPath =
          normalizedBattleBackgroundPath.replaceAll(r'\', '/');
      if (normalizedPath.startsWith('/') ||
          normalizedPath.startsWith('\\') ||
          normalizedPath.contains(':\\') ||
          normalizedPath.contains(':/') ||
          normalizedPath.contains('..')) {
        return 'Battle background image must stay inside the project as a relative path.';
      }
    }

    return null;
  }

  void _resetCreateTrainerDraft() {
    _showCreateForm = false;
    _showCreateAdvanced = false;
    _createTrainerValidationMessage = null;
    _newNameController.clear();
    _newClassController.clear();
    _newPortraitController.clear();
    _newBattleThemeController.clear();
    _newVictoryThemeController.clear();
    _newTagsController.clear();
    _newCharacterId = null;
    _newBattleDifficulty = 4;
    _newBattleBackgroundRelativePath = null;
  }

  void _openCreateTrainerForm() {
    setState(() {
      _showCreateForm = true;
      _createTrainerValidationMessage = null;
      _editingTrainerId = null;
      _closePokemonEditor();
    });
  }

  void _toggleCreateAdvanced() {
    setState(() {
      _showCreateAdvanced = !_showCreateAdvanced;
    });
  }

  void _setNewCharacterId(String? characterId) {
    setState(() {
      _newCharacterId = characterId;
    });
  }

  void _cancelCreateTrainerDraft() {
    setState(_resetCreateTrainerDraft);
  }

  ProjectTrainerEntry? _selectedTrainerForWorkspace(
    ProjectManifest project,
    EditorState state,
  ) {
    final selectedTrainerId = state.selectedTrainerId;
    if (selectedTrainerId != null) {
      for (final trainer in project.trainers) {
        if (trainer.id == selectedTrainerId) {
          return trainer;
        }
      }
    }
    return project.trainers.isEmpty ? null : project.trainers.first;
  }

  void _selectTrainerForWorkspace(String? trainerId) {
    // The central workspace owns the detailed trainer authoring experience.
    // Switching roster selection should therefore also clean up any draft that
    // belongs to another trainer, instead of leaving a stale editor visible in
    // the wrong context.
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
    setState(() {
      if (_showCreateForm && trainerId != null) {
        _resetCreateTrainerDraft();
      }
      if (_editingTrainerId != null && _editingTrainerId != trainerId) {
        _closeTrainerEditor();
      }
      if (_activePokemonTrainerId != null &&
          _activePokemonTrainerId != trainerId) {
        _closePokemonEditor();
      }
    });
  }

  void _startEditingTrainer(ProjectTrainerEntry trainer) {
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainer.id);
    setState(() {
      _editingTrainerId = trainer.id;
      _editNameController.text = trainer.name;
      _editClassController.text = trainer.trainerClass;
      _editPortraitController.text = trainer.portraitElementId ?? '';
      _editBattleThemeController.text = trainer.battleThemeId ?? '';
      _editVictoryThemeController.text = trainer.victoryThemeId ?? '';
      _editTagsController.text = trainer.tags.join(', ');
      _editCharacterId = trainer.characterId;
      _editBattleDifficulty = trainer.battleDifficulty;
      _editBattleBackgroundRelativePath =
          trainer.battleBackgroundRelativePath;
      _showEditAdvanced = false;
      _editTrainerValidationMessage = null;
      _showCreateForm = false;
      _closePokemonEditor();
    });
  }

  void _toggleEditAdvanced() {
    setState(() {
      _showEditAdvanced = !_showEditAdvanced;
    });
  }

  void _setEditCharacterId(String? characterId) {
    setState(() {
      _editCharacterId = characterId;
    });
  }

  void _cancelTrainerEditor() {
    setState(_closeTrainerEditor);
  }

  void _setNewBattleDifficulty(double value) {
    setState(() {
      _newBattleDifficulty = value.round().clamp(1, 10);
      _createTrainerValidationMessage = null;
    });
  }

  void _setEditBattleDifficulty(double value) {
    setState(() {
      _editBattleDifficulty = value.round().clamp(1, 10);
      _editTrainerValidationMessage = null;
    });
  }

  void _clearNewBattleDifficulty() {
    setState(() {
      _newBattleDifficulty = null;
      _createTrainerValidationMessage = null;
    });
  }

  void _clearEditBattleDifficulty() {
    setState(() {
      _editBattleDifficulty = null;
      _editTrainerValidationMessage = null;
    });
  }

  Future<void> _pickCreateBattleBackground() async {
    await _pickBattleBackgroundImage(
      createMode: true,
    );
  }

  Future<void> _pickEditBattleBackground() async {
    await _pickBattleBackgroundImage(
      createMode: false,
    );
  }

  void _clearCreateBattleBackground() {
    setState(() {
      _newBattleBackgroundRelativePath = null;
      _createTrainerValidationMessage = null;
    });
  }

  void _clearEditBattleBackground() {
    setState(() {
      _editBattleBackgroundRelativePath = null;
      _editTrainerValidationMessage = null;
    });
  }

  Future<void> _pickBattleBackgroundImage({
    required bool createMode,
  }) async {
    final projectRootPath =
        ref.read(editorNotifierProvider).projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      setState(() {
        if (createMode) {
          _createTrainerValidationMessage =
              'A valid project workspace is required before linking a battle background image.';
        } else {
          _editTrainerValidationMessage =
              'A valid project workspace is required before linking a battle background image.';
        }
      });
      return;
    }

    final pickedAbsolutePath =
        await _pickBattleBackgroundAbsolutePath(projectRootPath);
    if (pickedAbsolutePath == null) {
      return;
    }

    final relativePath = _normalizePickedBattleBackgroundPath(
      createMode: createMode,
      projectRootPath: projectRootPath,
      pickedAbsolutePath: pickedAbsolutePath,
    );
    if (relativePath == null) {
      return;
    }

    setState(() {
      if (createMode) {
        _newBattleBackgroundRelativePath = relativePath;
        _createTrainerValidationMessage = null;
      } else {
        _editBattleBackgroundRelativePath = relativePath;
        _editTrainerValidationMessage = null;
      }
    });
  }

  Future<String?> _pickBattleBackgroundAbsolutePath(String projectRootPath) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>[
        'png',
        'jpg',
        'jpeg',
        'webp',
        'bmp',
        'gif',
      ],
      withData: false,
    );
    return result?.files.single.path?.trim();
  }

  String? _normalizePickedBattleBackgroundPath({
    required bool createMode,
    required String projectRootPath,
    required String pickedAbsolutePath,
  }) {
    final normalizedProjectRoot = p.normalize(projectRootPath);
    final normalizedAbsolutePath = p.normalize(pickedAbsolutePath);
    final relativePath = p.posix.normalize(
      p.relative(normalizedAbsolutePath, from: normalizedProjectRoot),
    );

    if (relativePath == '.' ||
        relativePath.startsWith('..') ||
        p.isAbsolute(relativePath)) {
      setState(() {
        const message =
            'This lot only links project-local images. Move the background into the project folder, then pick it again.';
        if (createMode) {
          _createTrainerValidationMessage = message;
        } else {
          _editTrainerValidationMessage = message;
        }
      });
      return null;
    }
    return relativePath;
  }

  // -------------------------------------------------------------------------
  // Draft Pokémon team
  // -------------------------------------------------------------------------

  bool get _isAddingPokemon =>
      _activePokemonTrainerId != null && _editingPokemonIndex == null;

  bool _isEditingPokemon(
    String trainerId,
    int pokemonIndex,
  ) {
    return _activePokemonTrainerId == trainerId &&
        _editingPokemonIndex == pokemonIndex;
  }

  void _closePokemonEditor() {
    _activePokemonTrainerId = null;
    _editingPokemonIndex = null;
    _resetPokemonDraftFields();
  }

  void _cancelPokemonEditor() {
    setState(_closePokemonEditor);
  }

  void _setPokemonShiny(bool value) {
    setState(() {
      _pokemonShiny = value;
    });
  }

  // Keeping the shared Pokémon draft reset in one place avoids tiny
  // field-reset mismatches between add/edit/cancel flows.
  void _resetPokemonDraftFields() {
    _pokemonValidationMessage = null;
    _pokemonSpeciesController.clear();
    _pokemonLevelController.text = '1';
    _pokemonItemController.clear();
    _pokemonFormController.clear();
    _pokemonGenderController.clear();
    _clearTextControllers(_pokemonMoveControllers);
    _pokemonShiny = false;
  }

  void _startAddingPokemon(String trainerId) {
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = null;
      _resetPokemonDraftFields();
      _closeTrainerEditor();
      _showCreateForm = false;
    });
  }

  void _startEditingPokemon(
    String trainerId,
    int pokemonIndex,
    ProjectTrainerPokemonEntry pokemon,
  ) {
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = pokemonIndex;
      _pokemonValidationMessage = null;
      _pokemonSpeciesController.text = pokemon.speciesId;
      _pokemonLevelController.text = pokemon.level.toString();
      _pokemonItemController.text = pokemon.heldItemId ?? '';
      _pokemonFormController.text = pokemon.formId ?? '';
      _pokemonGenderController.text = pokemon.gender ?? '';
      for (var i = 0; i < _pokemonMoveControllers.length; i++) {
        _pokemonMoveControllers[i].text =
            i < pokemon.moves.length ? pokemon.moves[i] : '';
      }
      _pokemonShiny = pokemon.shiny;
      _closeTrainerEditor();
      _showCreateForm = false;
    });
  }

  Future<void> _handleSavePokemonDraft({
    required EditorNotifier notifier,
    required ProjectWorkspace workspace,
    required _TrainerReferenceData references,
  }) async {
    final trainerId = _activePokemonTrainerId;
    if (trainerId == null) {
      return;
    }

    final speciesDetail = await _loadSpeciesDetailIfPossible(
        workspace, _pokemonSpeciesController.text);
    final validation = _validatePokemonDraft(
      references: references,
      speciesDetail: speciesDetail,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _pokemonValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final draft = _buildPokemonDraft();
    if (draft.level == null || draft.level! < 1 || draft.level! > 100) {
      setState(() {
        _pokemonValidationMessage = _trainerLevelValidationMessage;
      });
      return;
    }

    final success = _editingPokemonIndex == null
        ? await notifier.addTrainerPokemon(
            trainerId: trainerId,
            speciesId: draft.speciesId,
            level: draft.level!,
            moves: draft.moves,
            heldItemId: draft.heldItemId,
            formId: draft.formId,
            gender: draft.gender,
            shiny: draft.shiny,
          )
        : await notifier.updateTrainerPokemon(
            trainerId: trainerId,
            pokemonIndex: _editingPokemonIndex!,
            speciesId: draft.speciesId,
            level: draft.level!,
            moves: draft.moves,
            heldItemId: draft.heldItemId,
            formId: draft.formId,
            gender: draft.gender,
            shiny: draft.shiny,
          );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_closePokemonEditor);
      return;
    }

    setState(() {
      _pokemonValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to save trainer Pokémon.';
    });
  }

  Future<void> _handleDeletePokemon({
    required EditorNotifier notifier,
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final success = await notifier.deleteTrainerPokemon(
      trainerId: trainerId,
      pokemonIndex: pokemonIndex,
    );
    if (!mounted || !success) {
      return;
    }

    setState(() {
      if (_isEditingPokemon(trainerId, pokemonIndex)) {
        _closePokemonEditor();
      }
    });
  }

  _TrainerPokemonDraft _buildPokemonDraft() {
    return _TrainerPokemonDraft(
      speciesId: _pokemonSpeciesController.text.trim(),
      level: int.tryParse(_pokemonLevelController.text.trim()),
      moves: _pokemonMoveControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      heldItemId: _normalizeOptionalField(_pokemonItemController.text),
      formId: _normalizeOptionalField(_pokemonFormController.text),
      gender: _normalizeOptionalField(_pokemonGenderController.text),
      shiny: _pokemonShiny,
    );
  }

  String? _validatePokemonDraft({
    required _TrainerReferenceData references,
    required PokedexSpeciesDetail? speciesDetail,
  }) {
    final draft = _buildPokemonDraft();
    if (draft.speciesId.isEmpty) {
      return 'Species ID cannot be empty.';
    }

    if (draft.level == null || draft.level! < 1 || draft.level! > 100) {
      return _trainerLevelValidationMessage;
    }

    if (references.isSpeciesAvailable &&
        _speciesLookupService.findById(
                references.speciesEntries, draft.speciesId) ==
            null) {
      return 'Species "${draft.speciesId}" is not present in the local Pokédex.';
    }

    final seenMoveIds = <String>{};
    for (var i = 0; i < draft.moves.length; i++) {
      final moveId = draft.moves[i];
      final normalizedMoveId = moveId.toLowerCase();
      if (!seenMoveIds.add(normalizedMoveId)) {
        // Duplicate move picks make the authoring UI ambiguous and are not
        // accepted by the trainer contract. The guided dropdown already hides
        // used moves, but the raw fallback must still respect the same rule
        // even when the move catalog is temporarily unavailable.
        return 'Move ${i + 1} duplicates another selected move: $moveId';
      }
      if (references.movesCatalogView.isAvailable) {
        if (_movesLookupService.findById(
              references.movesCatalogView.entries,
              moveId,
            ) ==
            null) {
          return 'Move ${i + 1} references an unknown local move: $moveId';
        }
      }
    }

    if (references.itemsCatalogView.isAvailable &&
        draft.heldItemId != null &&
        draft.heldItemId!.isNotEmpty &&
        _itemsLookupService.findById(
              references.itemsCatalogView.entries,
              draft.heldItemId!,
            ) ==
            null) {
      return 'Held item "${draft.heldItemId}" is not present in the local items catalog.';
    }

    final availableForms = speciesDetail == null
        ? const <String>[]
        : _buildSpeciesFormSuggestions(speciesDetail.species);
    if (availableForms.isNotEmpty &&
        draft.formId != null &&
        draft.formId!.isNotEmpty &&
        !availableForms.contains(draft.formId)) {
      return 'Form "${draft.formId}" does not match the selected species.';
    }

    final availableGenders = speciesDetail == null
        ? const <String>[]
        : _buildTrainerGenderSuggestions(speciesDetail.species);
    if (availableGenders.isNotEmpty &&
        draft.gender != null &&
        draft.gender!.isNotEmpty &&
        !availableGenders.contains(draft.gender)) {
      return 'Gender "${draft.gender}" does not match the selected species.';
    }

    return null;
  }

  // -------------------------------------------------------------------------
  // Construction UI
  // -------------------------------------------------------------------------

  // Trainer edition is a presentation concern only. Keeping this reset local
  // avoids pushing UI mode flags into the notifier or the use cases.
  void _closeTrainerEditor() {
    _editingTrainerId = null;
    _editTrainerValidationMessage = null;
    _showEditAdvanced = false;
    _editBattleDifficulty = null;
    _editBattleBackgroundRelativePath = null;
  }
}

```

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

// ---------------------------------------------------------------------------
// Widgets trainer
// ---------------------------------------------------------------------------

class _TrainerReferencesBanner extends StatelessWidget {
  const _TrainerReferencesBanner({
    required this.references,
    required this.onRefresh,
  });

  final _TrainerReferenceData references;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final itemState = references.itemsCatalogView.isAvailable
        ? '${references.itemsCatalogView.entries.length} items'
        : 'items indisponibles';
    final moveState = references.movesCatalogView.isAvailable
        ? '${references.movesCatalogView.entries.length} moves'
        : 'moves indisponibles';
    final speciesState = references.isSpeciesAvailable
        ? '${references.speciesEntries.length} espèces'
        : 'espèces indisponibles';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Trainer Studio references · $speciesState · $moveState · $itemState',
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  key: const Key('trainer-library-refresh-references-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(1, 28),
                  onPressed: onRefresh,
                  child: const Text(
                    'Refresh',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              references.speciesMessage,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.movesCatalogView.isAvailable
                  ? references.movesCatalogView.description
                  : _buildAuthorFacingCatalogUnavailableMessage(
                      subjectLabel: 'move data',
                      fallbackMessage:
                          'Guided move suggestions stay unavailable until the local catalog can be read.',
                      technicalMessage: references.movesCatalogView.message,
                    ),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.itemsCatalogView.isAvailable
                  ? references.itemsCatalogView.description
                  : _buildAuthorFacingCatalogUnavailableMessage(
                      subjectLabel: 'item data',
                      fallbackMessage:
                          'Raw item IDs stay possible while the local catalog is unavailable.',
                      technicalMessage: references.itemsCatalogView.message,
                    ),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerOperationBanner extends StatelessWidget {
  const _TrainerOperationBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentJade;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TrainerEditorCard extends StatelessWidget {
  const _TrainerEditorCard({
    super.key,
    required this.title,
    required this.accent,
    required this.nameController,
    required this.classController,
    required this.portraitController,
    required this.battleThemeController,
    required this.victoryThemeController,
    required this.tagsController,
    required this.battleDifficulty,
    required this.battleBackgroundRelativePath,
    required this.projectRootPath,
    required this.characters,
    required this.elements,
    required this.selectedCharacterId,
    required this.validationMessage,
    required this.showAdvanced,
    required this.createMode,
    required this.onToggleAdvanced,
    required this.onBattleDifficultyChanged,
    required this.onClearBattleDifficulty,
    required this.onPickBattleBackground,
    required this.onClearBattleBackground,
    required this.onSelectCharacter,
    required this.onCancel,
    required this.onSubmit,
  });

  final String title;
  final Color accent;
  final TextEditingController nameController;
  final TextEditingController classController;
  final TextEditingController portraitController;
  final TextEditingController battleThemeController;
  final TextEditingController victoryThemeController;
  final TextEditingController tagsController;
  final int? battleDifficulty;
  final String? battleBackgroundRelativePath;
  final String? projectRootPath;
  final List<ProjectCharacterEntry> characters;
  final List<ProjectElementEntry> elements;
  final String? selectedCharacterId;
  final String? validationMessage;
  final bool showAdvanced;
  final bool createMode;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<double> onBattleDifficultyChanged;
  final VoidCallback onClearBattleDifficulty;
  final VoidCallback onPickBattleBackground;
  final VoidCallback onClearBattleBackground;
  final ValueChanged<String?> onSelectCharacter;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final knownPortraitIds = elements.map((element) => element.id).toSet();
    final portraitId = portraitController.text.trim();
    final portraitIsKnown =
        portraitId.isEmpty || knownPortraitIds.contains(portraitId);
    final displayedBattleDifficulty = (battleDifficulty ?? 4).toDouble();
    final hasExplicitBattleBackground =
        (battleBackgroundRelativePath?.trim().isNotEmpty ?? false);
    final absoluteBattleBackgroundPath =
        !hasExplicitBattleBackground || projectRootPath == null
            ? null
            : p.join(projectRootPath!, battleBackgroundRelativePath!.trim());
    final battleBackgroundFile = absoluteBattleBackgroundPath == null
        ? null
        : File(absoluteBattleBackgroundPath);
    final battleBackgroundExists =
        battleBackgroundFile != null && battleBackgroundFile.existsSync();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorEmbeddedSectionLabel(title),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-name-field'
                  : 'trainer-library-edit-name-field',
            ),
            controller: nameController,
            placeholder: 'Name (e.g. Ash)',
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-class-field'
                  : 'trainer-library-edit-class-field',
            ),
            controller: classController,
            placeholder: 'Class (e.g. Pokémon Trainer)',
          ),
          const SizedBox(height: 6),
          _TrainerCharacterPicker(
            characters: characters,
            selectedCharacterId: selectedCharacterId,
            onSelected: onSelectCharacter,
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.18),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          battleDifficulty == null
                              ? 'Battle difficulty · legacy fallback'
                              : 'Battle difficulty · ${battleDifficulty!}/10',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        key: Key(
                          createMode
                              ? 'trainer-library-create-difficulty-clear-button'
                              : 'trainer-library-edit-difficulty-clear-button',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(1, 24),
                        onPressed: onClearBattleDifficulty,
                        child: Text(
                          battleDifficulty == null ? 'Use 4/10' : 'Use fallback',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  CupertinoSlider(
                    key: Key(
                      createMode
                          ? 'trainer-library-create-difficulty-slider'
                          : 'trainer-library-edit-difficulty-slider',
                    ),
                    value: displayedBattleDifficulty,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: onBattleDifficultyChanged,
                  ),
                  Text(
                    battleDifficulty == null
                        ? 'No explicit difficulty is stored yet. Moving the slider authors a real 1..10 value for runtime routing.'
                        : 'Trainer difficulty stays authored in project data and is later routed to a small internal opponent profile set.',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(1, 24),
            alignment: Alignment.centerLeft,
            onPressed: onToggleAdvanced,
            child: Text(
              showAdvanced
                  ? 'Hide optional references'
                  : 'Show optional references',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (showAdvanced) ...[
            const SizedBox(height: 8),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-portrait-field'
                    : 'trainer-library-edit-portrait-field',
              ),
              controller: portraitController,
              placeholder: 'Raw portrait element ID (optional)',
            ),
            if (!portraitIsKnown)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Portrait element ID is not present in the project elements.',
                  style: TextStyle(
                    color: EditorChrome.inspectorJoyCoral,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-battle-theme-field'
                    : 'trainer-library-edit-battle-theme-field',
              ),
              controller: battleThemeController,
              placeholder: 'Raw battle theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-victory-theme-field'
                    : 'trainer-library-edit-victory-theme-field',
              ),
              controller: victoryThemeController,
              placeholder: 'Raw victory theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-tags-field'
                    : 'trainer-library-edit-tags-field',
              ),
              controller: tagsController,
              placeholder: 'Tags (comma separated, optional)',
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: EditorChrome.islandFillElevated(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Battle background image (optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasExplicitBattleBackground
                          ? battleBackgroundRelativePath!.trim()
                          : 'No explicit trainer background selected.',
                      style: TextStyle(
                        color: hasExplicitBattleBackground
                            ? EditorChrome.primaryLabel(context)
                            : subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        key: Key(
                          createMode
                              ? 'trainer-library-create-background-preview'
                              : 'trainer-library-edit-background-preview',
                        ),
                        height: 88,
                        child: ColoredBox(
                          color: EditorChrome.islandFillElevated(context),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: battleBackgroundExists
                                          ? <Color>[
                                              accent.withValues(alpha: 0.85),
                                              EditorChrome.accentJade
                                                  .withValues(alpha: 0.72),
                                            ]
                                          : <Color>[
                                              EditorChrome.accentCoral
                                                  .withValues(alpha: 0.65),
                                              EditorChrome.accentWarm
                                                  .withValues(alpha: 0.38),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Icon(
                                    battleBackgroundExists
                                        ? CupertinoIcons.photo_fill_on_rectangle_fill
                                        : CupertinoIcons.exclamationmark_triangle_fill,
                                    color: CupertinoColors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasExplicitBattleBackground
                                            ? (battleBackgroundExists
                                                ? 'Project image linked'
                                                : 'Linked file missing')
                                            : 'No explicit image linked',
                                        style: TextStyle(
                                          color: EditorChrome.primaryLabel(
                                            context,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hasExplicitBattleBackground
                                            ? (battleBackgroundExists
                                                ? 'Runtime will try this trainer-specific image before the contextual background.'
                                                : 'Runtime will ignore this missing file and fall back honestly to the contextual background.')
                                            : 'Choose a project-local image to override the contextual battle background for this trainer.',
                                        style: TextStyle(
                                          color: subtle,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CupertinoButton(
                          key: Key(
                            createMode
                                ? 'trainer-library-create-background-pick-button'
                                : 'trainer-library-edit-background-pick-button',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(1, 28),
                          onPressed: onPickBattleBackground,
                          child: const Text(
                            'Choose image',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        CupertinoButton(
                          key: Key(
                            createMode
                                ? 'trainer-library-create-background-clear-button'
                                : 'trainer-library-edit-background-clear-button',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(1, 28),
                          onPressed: onClearBattleBackground,
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This lot links a project-local image by relative path. If the file disappears later, runtime falls back honestly instead of faking support.',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ces refs optionnelles restent brutes pour le moment. Le fond de combat trainer reste un simple chemin relatif projet qui override le fond contextuel côté runtime ; battle theme, victory theme et tags restent conservés tels quels.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          if (validationMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              validationMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onCancel,
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 6),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onSubmit,
                child: Text(
                  createMode ? 'Create' : 'Save',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrainerCharacterPicker extends StatelessWidget {
  const _TrainerCharacterPicker({
    required this.characters,
    required this.selectedCharacterId,
    required this.onSelected,
  });

  final List<ProjectCharacterEntry> characters;
  final String? selectedCharacterId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    ProjectCharacterEntry? selected;
    for (final character in characters) {
      if (character.id == selectedCharacterId) {
        selected = character;
        break;
      }
    }
    final label = selected?.name ?? 'None';

    return Align(
      alignment: Alignment.centerLeft,
      child: PushButton(
        controlSize: ControlSize.regular,
        secondary: true,
        onPressed: () async {
          final picked = await showCupertinoListPicker<ProjectCharacterEntry?>(
            context: context,
            title: 'Trainer Character',
            items: [null, ...characters],
            labelOf: (value) => value?.name ?? 'None',
          );
          onSelected(picked?.id);
        },
        child: Text('Character: $label'),
      ),
    );
  }
}

```

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

// Trainer Studio lot 8-2 keeps a single source of truth:
// - the sidebar (`embedded: true`) is now only a launcher / summary surface;
// - the central workspace (`embedded: false`) owns the real authoring UI;
// - both views still reuse the same local state, notifier calls and lookup
//   services from `TrainerLibraryPanel`.
extension _TrainerLibraryWorkspaceRendering on _TrainerLibraryPanelState {
  Widget _buildEmbeddedTrainerLibrary({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
  }) {
    final selectedTrainer = _selectedTrainerForWorkspace(project, state);
    final totalTeamPokemon = project.trainers.fold<int>(
      0,
      (sum, trainer) => sum + trainer.team.length,
    );
    final subtle = EditorChrome.subtleLabel(context);

    void openStudio() {
      if (selectedTrainer != null) {
        notifier.selectTrainer(selectedTrainer.id);
      }
      notifier.selectTrainerWorkspace();
    }

    return ListView(
      padding: kInspectorTileBodyPadding,
      children: [
        EditorSidebarListRow(
          key: const Key('trainer-library-studio-entry'),
          selected: state.workspaceMode == EditorWorkspaceMode.trainer,
          onTap: openStudio,
          leading: const MacosIcon(CupertinoIcons.person_3_fill),
          title: const Text('Trainer Studio'),
          subtitle: const Text(
            'Open the main workspace to create trainers, teams and battle rosters.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: EditorChrome.accentCoral.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${project.trainers.length} trainers • $totalTeamPokemon team Pokémon',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedTrainer == null
                      ? 'No trainer selected yet. Open Trainer Studio to create your first roster.'
                      : 'Current focus: ${selectedTrainer.name} • ${selectedTrainer.trainerClass}\n'
                          '${_buildRosterPreview(selectedTrainer, references)}',
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        CupertinoButton.filled(
          key: const Key('trainer-library-open-studio-button'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: openStudio,
          child: const Text('Open Trainer Studio'),
        ),
        const SizedBox(height: 8),
        Text(
          'Detailed editing now lives in the center workspace so trainers, team cards and guided selectors all stay visible together.',
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerStudioWorkspace({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
  }) {
    final visibleTrainer = _selectedTrainerForWorkspace(project, state);
    final workspace = _workspaceForState(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rosterWidth = constraints.maxWidth >= 1440 ? 320.0 : 280.0;
        final editorWidth = constraints.maxWidth >= 1440 ? 430.0 : 390.0;
        // The main shell can shrink the center stage a lot once both side
        // panels are visible. When that happens, keeping the original
        // three-column layout would crush the detail pane down to unusable
        // widths. We keep the same authoring surface, but fold it into a
        // stacked layout so the central workspace stays readable instead of
        // silently overflowing.
        final useCompactLayout =
            constraints.maxWidth < rosterWidth + editorWidth + 360;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TrainerStudioHeaderCard(
                onNewTrainer: _openCreateTrainerForm,
                referencesBanner: _TrainerReferencesBanner(
                  references: references,
                  onRefresh: () => _refreshReferenceData(state),
                ),
                operationBanner: (state.errorMessage ?? '').trim().isEmpty &&
                        (state.statusMessage ?? '').trim().isEmpty
                    ? null
                    : _TrainerOperationBanner(
                        message:
                            (state.errorMessage?.trim().isNotEmpty ?? false)
                                ? state.errorMessage!.trim()
                                : state.statusMessage!.trim(),
                        isError:
                            (state.errorMessage?.trim().isNotEmpty ?? false),
                      ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: useCompactLayout
                    ? _buildCompactTrainerStudioBody(
                        context: context,
                        state: state,
                        project: project,
                        notifier: notifier,
                        references: references,
                        visibleTrainer: visibleTrainer,
                        workspace: workspace,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: rosterWidth,
                            child: _buildTrainerRosterPane(
                              context: context,
                              state: state,
                              project: project,
                              references: references,
                              visibleTrainer: visibleTrainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTrainerDetailWorkspacePane(
                              context: context,
                              project: project,
                              notifier: notifier,
                              references: references,
                              visibleTrainer: visibleTrainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: editorWidth,
                            child: _buildTrainerEditorWorkspacePane(
                              context: context,
                              workspace: workspace,
                              visibleTrainer: visibleTrainer,
                              references: references,
                              notifier: notifier,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactTrainerStudioBody({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
    required ProjectWorkspace? workspace,
  }) {
    // This is intentionally a stacked version of the same three surfaces.
    // We do not create a second trainer editor; we only reflow the existing
    // roster/detail/editor panes so the workspace remains usable inside the
    // narrower center shell.
    final detailHeight = _showCreateForm || _editingTrainerId != null
        ? 560.0
        : visibleTrainer == null
            ? 320.0
            : 500.0;
    final editorHeight = _activePokemonTrainerId == visibleTrainer?.id
        ? 760.0
        : visibleTrainer == null
            ? 260.0
            : 320.0;

    return ListView(
      children: [
        SizedBox(
          height: 300,
          child: _buildTrainerRosterPane(
            context: context,
            state: state,
            project: project,
            references: references,
            visibleTrainer: visibleTrainer,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: detailHeight,
          child: _buildTrainerDetailWorkspacePane(
            context: context,
            project: project,
            notifier: notifier,
            references: references,
            visibleTrainer: visibleTrainer,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: editorHeight,
          child: _buildTrainerEditorWorkspacePane(
            context: context,
            workspace: workspace,
            visibleTrainer: visibleTrainer,
            references: references,
            notifier: notifier,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerRosterPane({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    return _TrainerStudioPane(
      key: const Key('trainer-library-roster-pane'),
      title: 'Trainer Roster',
      subtitle: 'Search, browse and pick the trainer you want to author.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            key: const Key(
              'trainer-library-roster-search-field',
            ),
            controller: _trainerSearchController,
            placeholder: 'Search by name, class, id or tag',
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildTrainerRosterList(
              context: context,
              state: state,
              project: project,
              references: references,
              visibleTrainer: visibleTrainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerDetailWorkspacePane({
    required BuildContext context,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    return _TrainerStudioPane(
      key: const Key('trainer-library-detail-pane'),
      title: 'Trainer Detail',
      subtitle: 'Identity, optional refs and the current battle team.',
      child: _buildTrainerDetailPane(
        context: context,
        project: project,
        notifier: notifier,
        references: references,
        visibleTrainer: visibleTrainer,
      ),
    );
  }

  Widget _buildTrainerEditorWorkspacePane({
    required BuildContext context,
    required ProjectWorkspace? workspace,
    required ProjectTrainerEntry? visibleTrainer,
    required _TrainerReferenceData references,
    required EditorNotifier notifier,
  }) {
    return _TrainerStudioPane(
      key: const Key('trainer-library-editor-pane'),
      title: 'Guided Pokémon Editor',
      subtitle:
          'Pick species, moves, forms and items with local search when available.',
      child: _buildPokemonEditorPane(
        context: context,
        workspace: workspace,
        visibleTrainer: visibleTrainer,
        references: references,
        notifier: notifier,
      ),
    );
  }

  Widget _buildTrainerRosterList({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    final filtered = project.trainers
        .where(
          (trainer) =>
              _trainerMatchesSearch(trainer, _trainerSearchController.text),
        )
        .toList(growable: false);
    final subtle = EditorChrome.subtleLabel(context);

    if (project.trainers.isEmpty) {
      return Center(
        child: Text(
          'No trainers yet.\nUse the button above to create your first roster.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No trainer matches this search.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('trainer-library-roster-scroll'),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trainer = filtered[index];
        return _TrainerStudioRosterCard(
          key: Key('trainer-library-roster-row-${trainer.id}'),
          trainer: trainer,
          selected: visibleTrainer?.id == trainer.id,
          preview: _buildRosterPreview(trainer, references),
          onTap: () => _selectTrainerForWorkspace(trainer.id),
        );
      },
    );
  }

  String _buildRosterPreview(
    ProjectTrainerEntry trainer,
    _TrainerReferenceData references,
  ) {
    if (trainer.team.isEmpty) {
      return 'No Pokémon assigned yet';
    }
    final preview = trainer.team.take(3).map((pokemon) {
      final species = _speciesLookupService.findById(
        references.speciesEntries,
        pokemon.speciesId,
      );
      return species?.primaryName ?? pokemon.speciesId;
    }).join(', ');
    final suffix = trainer.team.length > 3 ? '…' : '';
    return '$preview$suffix';
  }

  Widget _buildTrainerDetailPane({
    required BuildContext context,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    if (_showCreateForm) {
      return ListView(
        key: const Key('trainer-library-detail-scroll'),
        children: [
          _TrainerEditorCard(
            key: const Key('trainer-library-create-card'),
            title: 'NEW TRAINER',
            accent: EditorChrome.accentCoral,
            nameController: _newNameController,
            classController: _newClassController,
            portraitController: _newPortraitController,
            battleThemeController: _newBattleThemeController,
            victoryThemeController: _newVictoryThemeController,
            tagsController: _newTagsController,
            battleDifficulty: _newBattleDifficulty,
            battleBackgroundRelativePath: _newBattleBackgroundRelativePath,
            projectRootPath: ref.read(editorNotifierProvider).projectRootPath,
            characters: project.characters,
            elements: project.elements,
            selectedCharacterId: _newCharacterId,
            validationMessage: _createTrainerValidationMessage,
            showAdvanced: _showCreateAdvanced,
            createMode: true,
            onToggleAdvanced: _toggleCreateAdvanced,
            onBattleDifficultyChanged: _setNewBattleDifficulty,
            onClearBattleDifficulty: _clearNewBattleDifficulty,
            onPickBattleBackground: _pickCreateBattleBackground,
            onClearBattleBackground: _clearCreateBattleBackground,
            onSelectCharacter: _setNewCharacterId,
            onCancel: _cancelCreateTrainerDraft,
            onSubmit: () => _handleCreateTrainer(
              notifier: notifier,
              project: project,
            ),
          ),
        ],
      );
    }

    if (visibleTrainer == null) {
      return _TrainerStudioEmptyState(
        title: 'No trainer selected',
        body:
            'Pick a trainer from the roster or create a new one to start authoring a full battle team.',
        actionLabel: 'Create Trainer',
        onAction: _openCreateTrainerForm,
      );
    }

    final subtle = EditorChrome.subtleLabel(context);
    final isEditing = _editingTrainerId == visibleTrainer.id;
    final isAddingPokemon =
        _isAddingPokemon && _activePokemonTrainerId == visibleTrainer.id;

    return ListView(
      key: const Key('trainer-library-detail-scroll'),
      children: [
        if (isEditing)
          _TrainerEditorCard(
            key: Key('trainer-library-edit-card-${visibleTrainer.id}'),
            title: 'EDIT TRAINER',
            accent: EditorChrome.accentCoral,
            nameController: _editNameController,
            classController: _editClassController,
            portraitController: _editPortraitController,
            battleThemeController: _editBattleThemeController,
            victoryThemeController: _editVictoryThemeController,
            tagsController: _editTagsController,
            battleDifficulty: _editBattleDifficulty,
            battleBackgroundRelativePath: _editBattleBackgroundRelativePath,
            projectRootPath: ref.read(editorNotifierProvider).projectRootPath,
            characters: project.characters,
            elements: project.elements,
            selectedCharacterId: _editCharacterId,
            validationMessage: _editTrainerValidationMessage,
            showAdvanced: _showEditAdvanced,
            createMode: false,
            onToggleAdvanced: _toggleEditAdvanced,
            onBattleDifficultyChanged: _setEditBattleDifficulty,
            onClearBattleDifficulty: _clearEditBattleDifficulty,
            onPickBattleBackground: _pickEditBattleBackground,
            onClearBattleBackground: _clearEditBattleBackground,
            onSelectCharacter: _setEditCharacterId,
            onCancel: _cancelTrainerEditor,
            onSubmit: () => _handleUpdateTrainer(
              notifier: notifier,
              project: project,
              trainer: visibleTrainer,
            ),
          )
        else
          _TrainerStudioIdentityCard(
            trainer: visibleTrainer,
            onEdit: () => _startEditingTrainer(visibleTrainer),
            onDelete: () => _handleDeleteTrainer(
              notifier: notifier,
              trainer: visibleTrainer,
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'TEAM (${visibleTrainer.team.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            CupertinoButton(
              key: Key(
                  'trainer-library-add-pokemon-button-${visibleTrainer.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(1, 32),
              onPressed: () {
                if (isAddingPokemon) {
                  _cancelPokemonEditor();
                } else {
                  _startAddingPokemon(visibleTrainer.id);
                }
              },
              child: Text(
                isAddingPokemon ? 'Cancel' : 'Add Pokémon',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibleTrainer.team.isEmpty)
          Text(
            'This trainer has no team yet. You can save the trainer now and add battle Pokémon right after.',
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        for (var i = 0; i < visibleTrainer.team.length; i++) ...[
          _TrainerPokemonSummaryRow(
            key: Key('trainer-library-pokemon-row-${visibleTrainer.id}-$i'),
            pokemon: visibleTrainer.team[i],
            speciesEntry: _speciesLookupService.findById(
              references.speciesEntries,
              visibleTrainer.team[i].speciesId,
            ),
            isSpeciesCatalogAvailable: references.isSpeciesAvailable,
            moveCatalogView: references.movesCatalogView,
            itemCatalogView: references.itemsCatalogView,
            onEdit: () => _startEditingPokemon(
                visibleTrainer.id, i, visibleTrainer.team[i]),
            onDelete: () => _handleDeletePokemon(
              notifier: notifier,
              trainerId: visibleTrainer.id,
              pokemonIndex: i,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildPokemonEditorPane({
    required BuildContext context,
    required ProjectWorkspace? workspace,
    required ProjectTrainerEntry? visibleTrainer,
    required _TrainerReferenceData references,
    required EditorNotifier notifier,
  }) {
    final subtle = EditorChrome.subtleLabel(context);

    if (workspace == null) {
      return Center(
        child: Text(
          'Trainer saves need a valid project workspace.\nNo workspace is currently available.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (visibleTrainer == null) {
      return Center(
        child: Text(
          'Select a trainer first.\nThe guided Pokémon editor will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (_activePokemonTrainerId != visibleTrainer.id) {
      return const _TrainerStudioEmptyState(
        title: 'No Pokémon selected',
        body:
            'Choose “Add Pokémon” or edit one of the trainer team cards to open the guided editor here.',
      );
    }

    final editorTitle =
        _editingPokemonIndex == null ? 'NEW TEAM POKÉMON' : 'EDIT TEAM POKÉMON';

    return ListView(
      key: const Key('trainer-library-editor-scroll'),
      children: [
        Text(
          '${visibleTrainer.name} • $editorTitle',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        _TrainerPokemonEditorCard(
          key: _editingPokemonIndex == null
              ? Key('trainer-library-add-pokemon-card-${visibleTrainer.id}')
              : Key(
                  'trainer-library-edit-pokemon-card-${visibleTrainer.id}-${_editingPokemonIndex!}',
                ),
          trainerId: visibleTrainer.id,
          references: references,
          speciesController: _pokemonSpeciesController,
          levelController: _pokemonLevelController,
          itemController: _pokemonItemController,
          formController: _pokemonFormController,
          genderController: _pokemonGenderController,
          moveControllers: _pokemonMoveControllers,
          shiny: _pokemonShiny,
          validationMessage: _pokemonValidationMessage,
          onToggleShiny: _setPokemonShiny,
          onCancel: _cancelPokemonEditor,
          onSave: () => _handleSavePokemonDraft(
            notifier: notifier,
            workspace: workspace,
            references: references,
          ),
          loadSpeciesDetail: (speciesId) =>
              _loadSpeciesDetailIfPossible(workspace, speciesId),
        ),
      ],
    );
  }
}

class _TrainerStudioHeaderCard extends StatelessWidget {
  const _TrainerStudioHeaderCard({
    required this.onNewTrainer,
    required this.referencesBanner,
    required this.operationBanner,
  });

  final VoidCallback onNewTrainer;
  final Widget referencesBanner;
  final Widget? operationBanner;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentCoral.withValues(alpha: 0.07),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trainer Studio',
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create and edit project trainers in one readable workspace: roster on the left, team detail in the middle, guided Pokémon editing on the right.',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton.filled(
                  key: const Key('trainer-library-new-trainer-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: const Size(1, 34),
                  onPressed: onNewTrainer,
                  child: const Text('New Trainer'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            referencesBanner,
            if (operationBanner != null) ...[
              const SizedBox(height: 10),
              operationBanner!,
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainerStudioPane extends StatelessWidget {
  const _TrainerStudioPane({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _TrainerStudioRosterCard extends StatelessWidget {
  const _TrainerStudioRosterCard({
    super.key,
    required this.trainer,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final ProjectTrainerEntry trainer;
  final bool selected;
  final String preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.accentCoral.withValues(alpha: 0.1),
              )
            : EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? EditorChrome.accentCoral.withValues(alpha: 0.5)
              : CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        onPressed: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trainer.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _TrainerStudioMiniBadge(
                  label: '${trainer.team.length} mon',
                  selected: selected,
                ),
                if (trainer.battleDifficulty != null) ...[
                  const SizedBox(width: 6),
                  _TrainerStudioMiniBadge(
                    label: 'AI ${trainer.battleDifficulty}',
                    selected: selected,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${trainer.trainerClass} • ${trainer.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerStudioMiniBadge extends StatelessWidget {
  const _TrainerStudioMiniBadge({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? EditorChrome.accentCoral
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrainerStudioIdentityCard extends StatelessWidget {
  const _TrainerStudioIdentityCard({
    required this.trainer,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerEntry trainer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trainer.trainerClass} • ${trainer.id}',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(1, 32),
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(1, 32),
                  onPressed: onDelete,
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                ),
              ],
            ),
            if (trainer.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in trainer.tags) _TrainerMetaChip(label: tag),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              [
                if ((trainer.characterId ?? '').trim().isNotEmpty)
                  'Character: ${trainer.characterId!.trim()}',
                if ((trainer.portraitElementId ?? '').trim().isNotEmpty)
                  'Portrait: ${trainer.portraitElementId!.trim()}',
                if ((trainer.battleThemeId ?? '').trim().isNotEmpty)
                  'Battle theme: ${trainer.battleThemeId!.trim()}',
                if ((trainer.victoryThemeId ?? '').trim().isNotEmpty)
                  'Victory theme: ${trainer.victoryThemeId!.trim()}',
                if (trainer.battleDifficulty != null)
                  'Difficulty: ${trainer.battleDifficulty}/10',
                if ((trainer.battleBackgroundRelativePath ?? '').trim().isNotEmpty)
                  'Background: ${trainer.battleBackgroundRelativePath!.trim()}',
              ].isEmpty
                  ? 'No optional refs configured yet. You can still author a complete battle team right away.'
                  : [
                      if ((trainer.characterId ?? '').trim().isNotEmpty)
                        'Character: ${trainer.characterId!.trim()}',
                      if ((trainer.portraitElementId ?? '').trim().isNotEmpty)
                        'Portrait: ${trainer.portraitElementId!.trim()}',
                      if ((trainer.battleThemeId ?? '').trim().isNotEmpty)
                        'Battle theme: ${trainer.battleThemeId!.trim()}',
                      if ((trainer.victoryThemeId ?? '').trim().isNotEmpty)
                        'Victory theme: ${trainer.victoryThemeId!.trim()}',
                      if (trainer.battleDifficulty != null)
                        'Difficulty: ${trainer.battleDifficulty}/10',
                      if ((trainer.battleBackgroundRelativePath ?? '')
                          .trim()
                          .isNotEmpty)
                        'Background: ${trainer.battleBackgroundRelativePath!.trim()}',
                    ].join('\n'),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerMetaChip extends StatelessWidget {
  const _TrainerMetaChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrainerStudioEmptyState extends StatelessWidget {
  const _TrainerStudioEmptyState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              CupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

```

### `packages/map_editor/test/trainer_library_panel_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/trainer_library_panel.dart';

void main() {
  Future<void> pumpTrainerPanel(
    WidgetTester tester,
    ProviderContainer container, {
    bool embedded = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: embedded ? 420 : 1280,
                height: 1800,
                child: embedded
                    ? const TrainerLibraryPanel(embedded: true)
                    : const TrainerLibraryPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settleTrainerUi(WidgetTester tester) async {
    // The macOS-styled surface keeps a few short implicit animations alive.
    // A bounded settle loop is enough for this panel and avoids tests hanging
    // forever when a real workspace path introduces extra async churn.
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openTrainerDropdown(
    WidgetTester tester,
    String keyPrefix,
  ) async {
    final button = find.byKey(Key('$keyPrefix-dropdown-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await settleTrainerUi(tester);
    expect(find.byKey(Key('$keyPrefix-dropdown-menu')), findsOneWidget);
  }

  Future<void> filterTrainerDropdown(
    WidgetTester tester,
    String keyPrefix,
    String query,
  ) async {
    final searchField = find.byKey(Key('$keyPrefix-search-field'));
    if (searchField.evaluate().isEmpty) {
      await openTrainerDropdown(tester, keyPrefix);
    }
    await tester.enterText(find.byKey(Key('$keyPrefix-search-field')), query);
    await settleTrainerUi(tester);
  }

  Future<void> selectTrainerDropdownSuggestion(
    WidgetTester tester,
    String keyPrefix,
    String id, {
    String? query,
  }) async {
    if (query != null) {
      await filterTrainerDropdown(tester, keyPrefix, query);
    } else {
      final menu = find.byKey(Key('$keyPrefix-dropdown-menu'));
      if (menu.evaluate().isEmpty) {
        await openTrainerDropdown(tester, keyPrefix);
      }
    }
    await tester.tap(find.byKey(Key('$keyPrefix-suggestion-$id')));
    await settleTrainerUi(tester);
  }

  Future<void> selectTrainerLevel(
    WidgetTester tester,
    int level,
  ) async {
    final popup = find.byKey(
      const Key('trainer-library-pokemon-level-popup'),
    );
    await tester.ensureVisible(popup);
    await tester.tap(popup);
    await settleTrainerUi(tester);

    final option = find.byKey(
      Key('trainer-library-pokemon-level-option-$level'),
    );
    expect(option, findsWidgets);
    await tester.tap(option.last);
    await settleTrainerUi(tester);
  }

  Future<void> selectTrainerGender(
    WidgetTester tester,
    String gender,
  ) async {
    final option = find.byKey(
      Key('trainer-library-pokemon-gender-option-$gender'),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await settleTrainerUi(tester);
  }

  testWidgets('embedded mode acts as a launcher for the main Trainer Studio',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_embedded',
      project: ProjectManifest(
        name: 'trainers_panel_embedded',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container, embedded: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('trainer-library-open-studio-button')),
        findsOneWidget);
    expect(find.byKey(const Key('trainer-library-new-trainer-button')),
        findsNothing);
    expect(find.text('Trainer Studio'), findsWidgets);

    await tester
        .tap(find.byKey(const Key('trainer-library-open-studio-button')));
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.trainer,
    );
    expect(
      container.read(editorNotifierProvider).selectedTrainerId,
      'misty',
    );
  });

  testWidgets(
      'creates a trainer and saves a complete team entry with assisted refs',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-new-trainer-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-create-name-field')),
      'Misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-class-field')),
      'Gym Leader',
    );
    await tester.tap(find.text('Show optional references'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-battle-theme-field')),
      'battle_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-victory-theme-field')),
      'victory_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-tags-field')),
      ' rival, gym ',
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final trainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(trainer.name, 'Misty');
    expect(trainer.battleDifficulty, 4);
    expect(trainer.battleThemeId, 'battle_misty');
    expect(trainer.victoryThemeId, 'victory_misty');
    expect(trainer.tags, <String>['rival', 'gym']);

    await tester.tap(
      find.byKey(Key('trainer-library-add-pokemon-button-${trainer.id}')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      findsNothing,
    );
    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );

    await selectTrainerLevel(tester, 12);
    await selectTrainerGender(tester, 'female');

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-move-0',
      'tackle',
      query: 'tackle',
    );

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-move-1',
      'growl',
      query: 'growl',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-dropdown-button')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-item',
      'oran_berry',
      query: 'oran',
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-form-suggestion-blossom'),
      ),
    );
    await tester.pumpAndSettle();

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await settleTrainerUi(tester);
    tester.widget<CupertinoButton>(savePokemonButton).onPressed!.call();
    await settleTrainerUi(tester);

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 12);
    expect(pokemon.moves, <String>['tackle', 'growl']);
    expect(pokemon.heldItemId, 'oran_berry');
    expect(pokemon.formId, 'blossom');
    expect(pokemon.gender, 'female');
    expect(pokemon.shiny, isFalse);
    expect(
      find.byKey(Key('trainer-library-pokemon-row-${trainer.id}-0')),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows trainer difficulty and background authoring controls in the editor',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(_FakeProjectRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: ProjectManifest(
        name: 'trainer_picker_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'mira',
            name: 'Mira',
            trainerClass: 'Rookie',
            battleDifficulty: 6,
            battleBackgroundRelativePath: 'assets/battle_backgrounds/mira.png',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    expect(find.textContaining('AI 6'), findsOneWidget);

    await tester.tap(find.text('Edit').first);
    await settleTrainerUi(tester);

    expect(
      find.byKey(const Key('trainer-library-edit-difficulty-slider')),
      findsOneWidget,
    );

    await tester.tap(find.text('Show optional references'));
    await settleTrainerUi(tester);

    expect(
      find.text('assets/battle_backgrounds/mira.png'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-edit-background-pick-button')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('trainer-library-edit-background-clear-button')),
    );
    await settleTrainerUi(tester);
    expect(
      find.text('No explicit trainer background selected.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the active species selection stable while the dropdown search changes',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => const <PokemonDatabaseIndexEntry>[
            PokemonDatabaseIndexEntry(
              id: 'bulbasaur',
              nationalDex: 1,
              primaryName: 'Bulbasaur',
              genIntroduced: 1,
              types: <String>['grass', 'poison'],
              isEnabledInProject: true,
              refs: PokemonDatabaseIndexRefs(
                learnset: 'bulbasaur',
                evolution: 'bulbasaur',
                media: 'bulbasaur',
              ),
            ),
            PokemonDatabaseIndexEntry(
              id: 'caterpie',
              nationalDex: 10,
              primaryName: 'Caterpie',
              genIntroduced: 1,
              types: <String>['bug'],
              isEnabledInProject: true,
              refs: PokemonDatabaseIndexRefs(
                learnset: 'caterpie',
                evolution: 'caterpie',
                media: 'caterpie',
              ),
            ),
          ],
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await settleTrainerUi(tester);

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'caterpie',
      query: 'cater',
    );

    expect(
      find.byKey(const Key('trainer-library-pokemon-selected-species-status')),
      findsOneWidget,
    );
    expect(find.textContaining('Selected species: Caterpie'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const Key('trainer-library-pokemon-species-dropdown-button'),
        ),
        matching: find.text('Caterpie'),
      ),
      findsOneWidget,
    );

    await openTrainerDropdown(tester, 'trainer-library-pokemon-species');
    await filterTrainerDropdown(
      tester,
      'trainer-library-pokemon-species',
      'pikachu',
    );

    expect(
      find.byKey(const Key('trainer-library-pokemon-species-search-empty')),
      findsOneWidget,
    );
    expect(
      find.text('No local species match this search.'),
      findsOneWidget,
    );
    expect(find.textContaining('Selected species: Caterpie'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-close-button'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Selected species: Caterpie'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-clear-button'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No species selected yet.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const Key('trainer-library-pokemon-species-dropdown-button'),
        ),
        matching: find.text('Select a Pokémon species'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows guided move suggestions from the selected learnset and level',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );

    await selectTrainerLevel(tester, 12);

    expect(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      findsNothing,
    );
    await filterTrainerDropdown(
      tester,
      'trainer-library-pokemon-move-0',
      'vine',
    );

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-vine_whip'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Lv.7'), findsWidgets);

    await filterTrainerDropdown(
      tester,
      'trainer-library-pokemon-move-0',
      'razor',
    );

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-razor_leaf'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-empty')),
      findsOneWidget,
    );
  });

  testWidgets('shows inline validation when a move is unknown locally',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );
    await selectTrainerLevel(tester, 10);
    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await settleTrainerUi(tester);
    tester.widget<CupertinoButton>(savePokemonButton).onPressed!.call();
    await settleTrainerUi(tester);

    expect(
      find.text('Move 1 references an unknown local move: missing_move'),
      findsOneWidget,
    );
    expect(
      container.read(editorNotifierProvider).project!.trainers.single.team,
      isEmpty,
    );
  });

  testWidgets(
      'blocks duplicate moves in both guided selection and raw fallback save',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await settleTrainerUi(tester);

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );
    await selectTrainerLevel(tester, 12);
    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-move-0',
      'tackle',
      query: 'tackle',
    );

    await filterTrainerDropdown(
      tester,
      'trainer-library-pokemon-move-1',
      'tackle',
    );
    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-1-search-empty'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-move-1-close-button'),
      ),
    );
    await settleTrainerUi(tester);

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-1-field')),
      'TACKLE',
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await settleTrainerUi(tester);
    tester.widget<CupertinoButton>(savePokemonButton).onPressed!.call();
    await settleTrainerUi(tester);

    expect(
      find.text('Move 2 duplicates another selected move: TACKLE'),
      findsOneWidget,
    );
    expect(
      container.read(editorNotifierProvider).project!.trainers.single.team,
      isEmpty,
    );
  });

  testWidgets(
      'does not invent a base form suggestion when the local species detail has none',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(
                  forms: const PokemonSpeciesForms(
                    baseFormId: 'bulbasaur',
                    isBaseForm: true,
                    formId: '',
                    otherForms: <String>[],
                  ),
                )
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );

    await tester.scrollUntilVisible(
      find.text(
        'No local form suggestion is available for this species. The raw fallback remains available.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No local form suggestion is available for this species. The raw fallback remains available.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-form-suggestion-base')),
      findsNothing,
    );
  });

  testWidgets(
      'shows a dedicated genderless choice when the selected species has no gender',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(
                  breeding: const PokemonSpeciesBreeding(
                    genderRatio: <String, double>{'genderless': 1.0},
                    eggGroups: <String>['undiscovered'],
                    hatchCycles: 120,
                  ),
                )
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await settleTrainerUi(tester);

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-gender-option-genderless'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-gender-option-male')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-gender-option-female')),
      findsNothing,
    );
    expect(
      find.text('This species is genderless in the local Pokédex.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps species and form messaging honest when local species assistance is unavailable',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => throw StateError('species loader exploded'),
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, __) async => throw StateError('detail loader exploded'),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Impossible de charger les espèces locales. La saisie brute reste possible.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await selectTrainerLevel(tester, 10);
    await tester.scrollUntilVisible(
      find.text(
        'Unable to verify local forms for this species right now. The raw fallback remains available.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to verify local forms for this species right now. The raw fallback remains available.',
      ),
      findsOneWidget,
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await tester.pumpAndSettle();
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.speciesId, 'bulbasaur');

    await tester.scrollUntilVisible(
      find.text(
        'Local species index unavailable. The raw value is kept as-is.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Local species index unavailable. The raw value is kept as-is.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the trainer surface usable when moves and items lookups fail unexpectedly',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => throw StateError('moves loader exploded'),
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogError: StateError('items loader exploded'),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Unable to load the local move data for this project.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Unable to load the local item data for this project.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );
    await selectTrainerLevel(tester, 10);
    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      'mystery_item',
    );

    final savePokemonButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('trainer-library-pokemon-save-button')),
    );
    savePokemonButton.onPressed!.call();
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 10);
    expect(pokemon.moves, <String>['missing_move']);
    expect(pokemon.heldItemId, 'mystery_item');
  });

  testWidgets(
      'keeps raw move fallback available when the local learnset is unavailable',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(learnset: null)
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );
    await selectTrainerLevel(tester, 12);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No local learnset is available for this species. Guided move suggestions are unavailable, but raw IDs stay possible.',
      ),
      findsWidgets,
    );

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'tackle',
    );

    final savePokemonButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('trainer-library-pokemon-save-button')),
    );
    savePokemonButton.onPressed!.call();
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.moves, <String>['tackle']);
  });
}

const List<PokemonDatabaseIndexEntry> _speciesEntries =
    <PokemonDatabaseIndexEntry>[
  PokemonDatabaseIndexEntry(
    id: 'bulbasaur',
    nationalDex: 1,
    primaryName: 'Bulbasaur',
    genIntroduced: 1,
    types: <String>['grass', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
    ),
  ),
];

const PokemonMovesCatalogView _movesCatalogView = PokemonMovesCatalogView(
  entries: <PokemonMoveCatalogEntryView>[
    PokemonMoveCatalogEntryView(
      id: 'growl',
      name: 'Growl',
      type: 'normal',
      category: 'status',
      pp: 40,
    ),
    PokemonMoveCatalogEntryView(
      id: 'tackle',
      name: 'Tackle',
      type: 'normal',
      category: 'physical',
      power: 40,
      pp: 35,
    ),
    PokemonMoveCatalogEntryView(
      id: 'vine_whip',
      name: 'Vine Whip',
      type: 'grass',
      category: 'physical',
      power: 45,
      pp: 25,
    ),
    PokemonMoveCatalogEntryView(
      id: 'razor_leaf',
      name: 'Razor Leaf',
      type: 'grass',
      category: 'physical',
      power: 55,
      pp: 25,
    ),
  ],
  isAvailable: true,
  description: 'Catalogue local des attaques.',
);

const PokemonCatalogFile _itemsCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'items',
  meta: PokemonDataMeta(description: 'Catalogue local des objets.'),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'oran_berry',
      'name': 'Oran Berry',
      'aliases': <String>['oran'],
    },
  ],
);

final Map<String, PokedexSpeciesDetail> _detailsById =
    <String, PokedexSpeciesDetail>{
  'bulbasaur': _buildDetail(),
};

PokedexSpeciesDetail _buildDetail({
  PokemonSpeciesForms forms = const PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
    otherForms: <String>['blossom'],
  ),
  PokemonLearnsetFile? learnset = const PokemonLearnsetFile(
    speciesId: 'bulbasaur',
    startingMoves: <String>['tackle'],
    relearnMoves: <String>['growl'],
    levelUp: <PokemonLearnsetLevelUpEntry>[
      PokemonLearnsetLevelUpEntry(
        moveId: 'vine_whip',
        level: 7,
        source: 'level-up',
        versionGroup: 'project',
      ),
      PokemonLearnsetLevelUpEntry(
        moveId: 'razor_leaf',
        level: 20,
        source: 'level-up',
        versionGroup: 'project',
      ),
    ],
  ),
  PokemonSpeciesBreeding breeding = const PokemonSpeciesBreeding(
    genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
    eggGroups: <String>['monster', 'grass'],
    hatchCycles: 20,
  ),
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: 'bulbasaur',
      slug: 'bulbasaur',
      nationalDex: 1,
      names: <String, String>{'en': 'Bulbasaur'},
      speciesName: <String, String>{'en': 'Seed Pokemon'},
      genIntroduced: 1,
      typing: const PokemonSpeciesTyping(types: <String>['grass', 'poison']),
      baseStats: const PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: const PokemonSpeciesAbilities(primary: 'overgrow'),
      breeding: breeding,
      progression: const PokemonSpeciesProgression(
        growthRateId: 'medium_slow',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: forms,
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: const PokemonSpeciesRefs(
        learnset: 'bulbasaur',
        evolution: 'bulbasaur',
        media: 'bulbasaur',
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'green',
        flavorText: 'A strange seed was planted on its back at birth.',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(starterEligible: true),
      sourceMeta:
          const PokemonSpeciesSourceMeta(seededBy: 'test', seedVersion: 1),
    ),
    learnset: learnset,
    evolution: const PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: const PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{},
    ),
  );
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    lastSavedProject = project;
  }
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory(this.workspace);

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRoot) => workspace;
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  static const String projectRootValue = '/tmp';

  @override
  String get projectManifestPath => '$projectRootValue/project.json';

  @override
  String get projectRoot => projectRootValue;

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '$projectRootValue/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) =>
      '$projectRootValue/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRootValue/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) =>
      '$projectRootValue/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.catalogByKey = const <String, PokemonCatalogFile>{},
    this.catalogError,
  });

  final Map<String, PokemonCatalogFile> catalogByKey;
  final Object? catalogError;

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    if (catalogError != null) {
      throw catalogError!;
    }
    final catalog = catalogByKey[catalogKey];
    if (catalog == null) {
      throw EditorNotFoundException('Missing catalog: $catalogKey');
    }
    return catalog;
  }

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }
}

```

### `packages/map_editor/test/trainer_use_cases_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/trainer_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  late _FakeProjectRepository repository;
  const workspace = _FakeWorkspace();

  setUp(() {
    repository = _FakeProjectRepository();
  });

  group('trainer use cases', () {
    test('create trainer trims optional refs and normalizes tags', () async {
      final useCase = CreateTrainerUseCase(repository);

      final updated = await useCase.execute(
        workspace,
        _project(),
        name: '  Misty  ',
        trainerClass: '  Gym Leader  ',
        battleDifficulty: 7,
        battleBackgroundRelativePath:
            r' assets\battle_backgrounds\misty.png ',
        battleThemeId: ' battle_theme ',
        victoryThemeId: ' victory_theme ',
        tags: <String>[' rival ', ' ', ' gym '],
      );

      final trainer = updated.trainers.single;
      expect(trainer.id, 'misty');
      expect(trainer.name, 'Misty');
      expect(trainer.trainerClass, 'Gym Leader');
      expect(trainer.battleDifficulty, 7);
      expect(
        trainer.battleBackgroundRelativePath,
        'assets/battle_backgrounds/misty.png',
      );
      expect(trainer.battleThemeId, 'battle_theme');
      expect(trainer.victoryThemeId, 'victory_theme');
      expect(trainer.tags, <String>['rival', 'gym']);
      expect(repository.savedProjects.single.trainers.single.name, 'Misty');
    });

    test('update trainer can author and clear difficulty/background fields',
        () async {
      final useCase = UpdateTrainerUseCase(repository);

      final updated = await useCase.execute(
        workspace,
        _project(
          trainers: const <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'misty',
              name: 'Misty',
              trainerClass: 'Gym Leader',
            ),
          ],
        ),
        trainerId: 'misty',
        battleDifficulty: 9,
        battleBackgroundRelativePath:
            'assets/battle_backgrounds/misty_evening.png',
      );

      final authoredTrainer = updated.trainers.single;
      expect(authoredTrainer.battleDifficulty, 9);
      expect(
        authoredTrainer.battleBackgroundRelativePath,
        'assets/battle_backgrounds/misty_evening.png',
      );

      final cleared = await useCase.execute(
        workspace,
        updated,
        trainerId: 'misty',
        battleDifficulty: null,
        battleBackgroundRelativePath: '',
      );

      final clearedTrainer = cleared.trainers.single;
      expect(clearedTrainer.battleDifficulty, isNull);
      expect(clearedTrainer.battleBackgroundRelativePath, isNull);
    });

    test('add/update trainer pokemon keeps data normalized and stable',
        () async {
      final addUseCase = AddTrainerPokemonUseCase(repository);
      final updateUseCase = UpdateTrainerPokemonUseCase(repository);

      final projectWithPokemon = await addUseCase.execute(
        workspace,
        _project(
          trainers: const <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'misty',
              name: 'Misty',
              trainerClass: 'Gym Leader',
            ),
          ],
        ),
        trainerId: 'misty',
        speciesId: '  staryu  ',
        level: 18,
        moves: const <String>[' water_gun ', '', ' rapid_spin '],
        heldItemId: ' mystic_water ',
        formId: ' base ',
        gender: ' female ',
        shiny: true,
      );

      final addedPokemon = projectWithPokemon.trainers.single.team.single;
      expect(addedPokemon.speciesId, 'staryu');
      expect(addedPokemon.moves, <String>['water_gun', 'rapid_spin']);
      expect(addedPokemon.heldItemId, 'mystic_water');
      expect(addedPokemon.formId, 'base');
      expect(addedPokemon.gender, 'female');
      expect(addedPokemon.shiny, isTrue);

      final updatedProject = await updateUseCase.execute(
        workspace,
        projectWithPokemon,
        trainerId: 'misty',
        pokemonIndex: 0,
        speciesId: ' starmie ',
        level: 21,
        moves: const <String>[' psybeam ', ' recover '],
        heldItemId: '',
        formId: '',
        gender: '',
        shiny: false,
      );

      final updatedPokemon = updatedProject.trainers.single.team.single;
      expect(updatedPokemon.speciesId, 'starmie');
      expect(updatedPokemon.level, 21);
      expect(updatedPokemon.moves, <String>['psybeam', 'recover']);
      expect(updatedPokemon.heldItemId, isNull);
      expect(updatedPokemon.formId, isNull);
      expect(updatedPokemon.gender, isNull);
      expect(updatedPokemon.shiny, isFalse);
    });

    test('rejects an empty species id before save', () async {
      final addUseCase = AddTrainerPokemonUseCase(repository);

      expect(
        () => addUseCase.execute(
          workspace,
          _project(
            trainers: const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: 'misty',
                name: 'Misty',
                trainerClass: 'Gym Leader',
              ),
            ],
          ),
          trainerId: 'misty',
          speciesId: '   ',
          level: 12,
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });
}

ProjectManifest _project({
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
}) {
  return ProjectManifest(
    name: 'trainer_use_case_test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
  );
}

class _FakeProjectRepository implements ProjectRepository {
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedProjects.add(project);
  }
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

```

### `packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart`

```dart
import 'package:path/path.dart' as p;
import 'package:map_core/map_core.dart';

import '../../application/battle_start_request.dart';
import '../../application/runtime_map_bundle.dart';
import 'runtime_trainer_battle_overrides.dart';

/// Clé minimale de fond de combat pour le lot 2.
///
/// Garde-fous de périmètre :
/// - on ne construit pas un système générique de theming ;
/// - on ne transporte que des familles visuelles immédiatement utiles ;
/// - on garde la vraie logique de peinture dans le backdrop runtime, pas dans
///   le battle-core ni dans un registre global de palettes.
enum BattleBackgroundKey {
  fallbackField,
  wildOutdoor,
  trainerOutdoor,
  indoor,
}

/// Spec minimale de fond de combat consommée par la scène runtime.
///
/// Le contrat reste volontairement petit :
/// - une seule clé résolue ;
/// - pas de taxonomie de biome large ;
/// - pas de dépendance à des assets non présents ;
/// - pas de promesse de personnalisation future plus large que ce lot.
final class BattleBackgroundSpec {
  const BattleBackgroundSpec({
    required this.key,
    this.explicitImageAbsolutePath,
  });

  const BattleBackgroundSpec.fallbackField()
      : key = BattleBackgroundKey.fallbackField,
        explicitImageAbsolutePath = null;

  const BattleBackgroundSpec.explicitImage({
    required BattleBackgroundKey fallbackKey,
    required String absolutePath,
  })  : key = fallbackKey,
        explicitImageAbsolutePath = absolutePath;

  final BattleBackgroundKey key;
  final String? explicitImageAbsolutePath;

  bool get hasExplicitImage =>
      (explicitImageAbsolutePath?.trim().isNotEmpty ?? false);

  String get debugLabel => switch (key) {
        BattleBackgroundKey.fallbackField => 'fallback_field',
        BattleBackgroundKey.wildOutdoor => 'wild_outdoor',
        BattleBackgroundKey.trainerOutdoor => 'trainer_outdoor',
        BattleBackgroundKey.indoor => 'indoor',
      } +
      (hasExplicitImage ? '+explicit_image' : '');
}

/// Résout le fond de combat à partir du contexte runtime déjà disponible.
///
/// Frontière volontairement stricte :
/// - ce seam vit dans `map_runtime` parce qu'il traduit un contexte overworld
///   vers une ambiance de scène ;
/// - il ne dépend pas du moteur battle ;
/// - il ne modifie aucun contrat battle-core ;
/// - il n'essaie pas de devenir un moteur universel de biome ou de thème.
///
/// Chaîne de résolution retenue pour le lot 2 :
/// 1. vérité indoor explicite de la map actuelle ;
/// 2. type indoor-like de la map actuelle ;
/// 3. rôle indoor-like dans le manifeste projet ;
/// 4. nature trainer vs wild de la requête ;
/// 5. fallback stable côté overlay si aucun contexte n'est injecté.
///
/// Champs volontairement NON utilisés maintenant :
/// - `MapMetadata.tags` : trop libres, pas assez canoniques pour un lot borné ;
/// - `ProjectTrainerEntry.trainerClass` : utile produit plus tard, mais trop
///   instable pour piloter honnêtement le décor maintenant ;
/// - `ProjectTrainerEntry.battleThemeId` : tentant, mais ce repo n'a pas
///   encore de pipeline d'assets battle dédiée à respecter ici ;
/// - `ProjectEncounterTable.tags` : décrivent les rencontres, pas forcément la
///   scène de combat.
final class BattleBackgroundResolver {
  const BattleBackgroundResolver();

  BattleBackgroundSpec resolve({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    final contextualKey = _resolveContextualKey(
      request: request,
      bundle: bundle,
    );

    final explicitTrainerBackgroundAbsolutePath =
        _resolveExplicitTrainerBackgroundAbsolutePath(
      request: request,
      bundle: bundle,
    );
    if (explicitTrainerBackgroundAbsolutePath != null) {
      return BattleBackgroundSpec.explicitImage(
        fallbackKey: contextualKey,
        absolutePath: explicitTrainerBackgroundAbsolutePath,
      );
    }

    return BattleBackgroundSpec(
      key: contextualKey,
    );
  }

  BattleBackgroundKey _resolveContextualKey({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    if (_isIndoorMap(bundle)) {
      return BattleBackgroundKey.indoor;
    }

    return switch (request) {
      TrainerBattleStartRequest() => BattleBackgroundKey.trainerOutdoor,
      WildBattleStartRequest() => BattleBackgroundKey.wildOutdoor,
    };
  }

  String? _resolveExplicitTrainerBackgroundAbsolutePath({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    final trainer = findTrainerEntryForBattleRequest(
      request: request,
      manifest: bundle.manifest,
    );
    final relativePath = trainer?.battleBackgroundRelativePath?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }

    return p.normalize(
      p.join(bundle.projectRootDirectory, relativePath),
    );
  }

  bool _isIndoorMap(RuntimeMapBundle bundle) {
    final metadata = bundle.map.mapMetadata;
    if (metadata.isIndoor) {
      return true;
    }
    if (_isIndoorMapType(metadata.mapType)) {
      return true;
    }

    final mapEntry = _findMapEntry(
      manifest: bundle.manifest,
      mapId: bundle.map.id,
    );
    if (mapEntry == null) {
      return false;
    }
    return _isIndoorMapRole(mapEntry.role);
  }

  ProjectMapEntry? _findMapEntry({
    required ProjectManifest manifest,
    required String mapId,
  }) {
    for (final entry in manifest.maps) {
      if (entry.id == mapId) {
        return entry;
      }
    }
    return null;
  }

  bool _isIndoorMapType(MapType mapType) {
    return switch (mapType) {
      MapType.building ||
      MapType.interior ||
      MapType.cave ||
      MapType.facility =>
        true,
      _ => false,
    };
  }

  bool _isIndoorMapRole(MapRole role) {
    return switch (role) {
      MapRole.interior ||
      MapRole.basement ||
      MapRole.upper_floor ||
      MapRole.gate ||
      MapRole.room ||
      MapRole.connector =>
        true,
      _ => false,
    };
  }
}

```

### `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Ton visuel minimal pour les commandes rendues dans la battle box.
///
/// Garde-fous de périmètre :
/// - on ne crée pas un système de thème global ;
/// - on encode uniquement quelques accents utiles pour distinguer les vraies
///   familles de choix déjà supportées par le moteur ;
/// - toute décision reste adossée à `BattleDecisionRequest.allowedChoices`.
enum BattleCommandChoiceTone {
  attack,
  special,
  support,
  switching,
  neutral,
}

/// Entrée de choix rendue dans la command box.
///
/// Cette structure reste strictement présentative :
/// - la vérité des choix vient toujours de `BattleDecisionRequest` ;
/// - le runtime ne crée ici ni faux menu, ni fausse famille d'action ;
/// - le découpage `title/subtitle/tone` ne sert qu'à mieux restituer un choix
///   déjà légal dans une UI plus proche d'une vraie battle box.
class BattleCommandChoiceEntry {
  const BattleCommandChoiceEntry({
    required this.choice,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final PlayerBattleChoice choice;
  final String title;
  final String subtitle;
  final BattleCommandChoiceTone tone;
}

/// Panneau bas de commandes et de narration.
///
/// Dans le lot 4b, on rapproche la composition de l'esprit du gif de
/// référence :
/// - une vraie narration lisible à gauche ;
/// - une grille de commandes lisible à droite quand c'est honnête ;
/// - aucun bouton factice de type `Bag` ou `Pokemon` si le moteur ne les
///   expose pas réellement.
class BattleCommandPanelComponent extends PositionComponent {
  BattleCommandPanelComponent({
    required Vector2 position,
    required Vector2 size,
    required this.onChoiceSelected,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 30,
        );

  final void Function(PlayerBattleChoice choice) onChoiceSelected;

  PositionComponent? _promptPanel;
  PositionComponent? _commandsPanel;
  TextComponent? _battleLabelText;
  TextComponent? _promptText;
  TextComponent? _narrationBodyText;
  TextComponent? _commandTitleText;
  TextComponent? _hintText;
  final List<_BattleChoiceCardComponent> _choiceComponents =
      <_BattleChoiceCardComponent>[];

  bool get narrationPanelMounted => _promptPanel != null;
  bool get commandPanelMounted => _commandsPanel != null;
  String get currentPromptText => _promptText?.text ?? '';
  String get currentNarrationText => _narrationBodyText?.text ?? '';

  @override
  Future<void> onLoad() async {
    final promptWidth = (size.x * 0.38).clamp(250.0, 350.0).toDouble();
    const spacing = 16.0;
    final commandsWidth = size.x - promptWidth - spacing;

    _promptPanel = PositionComponent(
      position: Vector2(16, 14),
      size: Vector2(promptWidth - 8, size.y - 28),
      anchor: Anchor.topLeft,
      priority: 31,
    );
    await add(_promptPanel!);

    _commandsPanel = PositionComponent(
      position: Vector2(promptWidth + spacing, 14),
      size: Vector2(commandsWidth - 8, size.y - 28),
      anchor: Anchor.topLeft,
      priority: 31,
    );
    await add(_commandsPanel!);

    _battleLabelText = TextComponent(
      text: '',
      position: Vector2(16, 14),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xCC55657D),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
    await _promptPanel!.add(_battleLabelText!);

    _promptText = TextComponent(
      text: '',
      position: Vector2(16, 34),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF1D2634),
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
    await _promptPanel!.add(_promptText!);

    _narrationBodyText = TextComponent(
      text: '',
      position: Vector2(16, 104),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF435064),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
    await _promptPanel!.add(_narrationBodyText!);

    _commandTitleText = TextComponent(
      text: 'COMMANDES',
      position: Vector2(16, 16),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xCCEAEEF8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
    await _commandsPanel!.add(_commandTitleText!);

    _hintText = TextComponent(
      text: 'Fleches / clic / entree',
      position: Vector2(_commandsPanel!.size.x - 16, _commandsPanel!.size.y - 14),
      anchor: Anchor.bottomRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0x99E8EEF8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    await _commandsPanel!.add(_hintText!);
  }

  void sync({
    required String battleLabel,
    required String prompt,
    required List<String> narrationLines,
    required List<BattleCommandChoiceEntry> choices,
    required int selectedIndex,
  }) {
    _battleLabelText?.text = battleLabel.toUpperCase();
    _promptText?.text = prompt;

    final clippedNarration = narrationLines.isEmpty
        ? const <String>['Le combat attend la prochaine action.']
        : narrationLines.take(4).toList(growable: false);
    _narrationBodyText?.text = clippedNarration.join('\n');

    _renderChoices(
      choices: choices,
      selectedIndex: selectedIndex,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rootRect = Offset.zero & Size(size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rootRect, const Radius.circular(28)),
      Paint()..color = const Color(0xE7EEF2FB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rootRect, const Radius.circular(28)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF53637B),
    );

    final shadowRect = Rect.fromLTWH(14, size.y - 18, size.x - 28, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(999)),
      Paint()..color = const Color(0x220E1520),
    );

    if (_promptPanel != null) {
      final promptRect = Rect.fromLTWH(
        _promptPanel!.position.x,
        _promptPanel!.position.y,
        _promptPanel!.size.x,
        _promptPanel!.size.y,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(promptRect, const Radius.circular(22)),
        Paint()..color = const Color(0xFFF6F1EA),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(promptRect, const Radius.circular(22)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFD5CCBD),
      );
    }

    if (_commandsPanel != null) {
      final commandsRect = Rect.fromLTWH(
        _commandsPanel!.position.x,
        _commandsPanel!.position.y,
        _commandsPanel!.size.x,
        _commandsPanel!.size.y,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(commandsRect, const Radius.circular(24)),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[
              Color(0xFF253449),
              Color(0xFF1D2738),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(commandsRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(commandsRect, const Radius.circular(24)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0x3DFFFFFF),
      );
    }
  }

  void _renderChoices({
    required List<BattleCommandChoiceEntry> choices,
    required int selectedIndex,
  }) {
    for (final component in _choiceComponents) {
      component.removeFromParent();
    }
    _choiceComponents.clear();

    if (_commandsPanel == null) {
      return;
    }

    const contentTop = 40.0;
    final availableWidth = _commandsPanel!.size.x - 32;
    final availableHeight = _commandsPanel!.size.y - 68;

    if (choices.isEmpty) {
      final emptyState = _BattleChoiceCardComponent(
        entry: const BattleCommandChoiceEntry(
          choice: PlayerBattleChoiceContinue(),
          title: 'Aucune commande',
          subtitle: 'Le moteur ne propose actuellement aucun choix interactif.',
          tone: BattleCommandChoiceTone.neutral,
        ),
        position: Vector2(16, contentTop),
        size: Vector2(availableWidth, 72),
        isSelected: false,
        isInteractive: false,
        onPressed: (_) {},
      );
      _choiceComponents.add(emptyState);
      _commandsPanel!.add(emptyState);
      return;
    }

    final useGrid = choices.length <= 4;
    if (useGrid) {
      const gap = 12.0;
      final cardWidth = (availableWidth - gap) / 2;
      final rows = (choices.length / 2).ceil();
      final cardHeight = rows > 1
          ? ((availableHeight - ((rows - 1) * gap)) / rows).clamp(66.0, 88.0)
          : 88.0;

      for (var i = 0; i < choices.length; i++) {
        final row = i ~/ 2;
        final column = i % 2;
        final card = _BattleChoiceCardComponent(
          entry: choices[i],
          position: Vector2(
            16 + ((cardWidth + gap) * column),
            contentTop + ((cardHeight + gap) * row),
          ),
          size: Vector2(cardWidth, cardHeight),
          isSelected: i == selectedIndex,
          isInteractive: true,
          onPressed: onChoiceSelected,
        );
        _choiceComponents.add(card);
        _commandsPanel!.add(card);
      }
      return;
    }

    var y = contentTop;
    for (var i = 0; i < choices.length; i++) {
      final card = _BattleChoiceCardComponent(
        entry: choices[i],
        position: Vector2(16, y),
        size: Vector2(availableWidth, 64),
        isSelected: i == selectedIndex,
        isInteractive: true,
        onPressed: onChoiceSelected,
      );
      _choiceComponents.add(card);
      _commandsPanel!.add(card);
      y += 72;
    }
  }
}

class _BattleChoiceCardComponent extends PositionComponent with TapCallbacks {
  _BattleChoiceCardComponent({
    required this.entry,
    required Vector2 position,
    required Vector2 size,
    required this.isSelected,
    required this.isInteractive,
    required this.onPressed,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 32,
        );

  final BattleCommandChoiceEntry entry;
  final bool isSelected;
  final bool isInteractive;
  final void Function(PlayerBattleChoice choice) onPressed;

  TextComponent? _titleText;
  TextComponent? _subtitleText;

  @override
  Future<void> onLoad() async {
    _titleText = TextComponent(
      text: entry.title,
      position: Vector2(16, 14),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color:
              isInteractive ? const Color(0xFFF8FBFF) : const Color(0x88F8FBFF),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      priority: 33,
    );
    await add(_titleText!);

    _subtitleText = TextComponent(
      text: entry.subtitle,
      position: Vector2(16, size.y - 14),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: TextStyle(
          color:
              isInteractive ? const Color(0xCCE6EEF8) : const Color(0x77E6EEF8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      priority: 33,
    );
    await add(_subtitleText!);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.x <= size.x &&
        point.y >= 0 &&
        point.y <= size.y;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isInteractive) {
      return;
    }
    onPressed(entry.choice);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    final palette = _paletteFor(entry.tone);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..shader = LinearGradient(
          colors: isInteractive
              ? <Color>[
                  palette.primary,
                  palette.secondary,
                ]
              : <Color>[
                  const Color(0xFF445166),
                  const Color(0xFF384457),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 1.5
        ..color = isSelected
            ? const Color(0xFFF7F0D4)
            : const Color(0x35FFFFFF),
    );

    final accentRect = Rect.fromLTWH(10, 10, size.x - 20, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(accentRect, const Radius.circular(999)),
      Paint()..color = const Color(0x24FFFFFF),
    );
  }

  _BattleChoicePalette _paletteFor(BattleCommandChoiceTone tone) {
    return switch (tone) {
      BattleCommandChoiceTone.attack => const _BattleChoicePalette(
          primary: Color(0xFFDE7B58),
          secondary: Color(0xFFB54F4B),
        ),
      BattleCommandChoiceTone.special => const _BattleChoicePalette(
          primary: Color(0xFF5B84D6),
          secondary: Color(0xFF3758A8),
        ),
      BattleCommandChoiceTone.support => const _BattleChoicePalette(
          primary: Color(0xFF5FAD86),
          secondary: Color(0xFF3D7F64),
        ),
      BattleCommandChoiceTone.switching => const _BattleChoicePalette(
          primary: Color(0xFF8D79D6),
          secondary: Color(0xFF6655AC),
        ),
      BattleCommandChoiceTone.neutral => const _BattleChoicePalette(
          primary: Color(0xFF637890),
          secondary: Color(0xFF46586F),
        ),
    };
  }
}

class _BattleChoicePalette {
  const _BattleChoicePalette({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;
}

```

### `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

```dart
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

import 'battle_command_panel_component.dart';
import 'battle_background_resolver.dart';
import 'battle_debug_panel_component.dart';
import 'battle_scene_backdrop_component.dart';
import 'battle_scene_combatant_component.dart';
import 'battle_scene_hud_component.dart';

/// Retourne le prompt de décision à afficher pour la requête courante.
///
/// Ce helper reste volontairement pur parce que le lot 1 ne doit surtout pas
/// recréer une logique de commande parallèle dans la présentation :
/// - la vérité de ce qu'on attend du joueur reste `BattleDecisionRequest` ;
/// - l'UI ne fait que reformuler cette vérité de manière plus lisible.
String buildBattleDecisionPromptForOverlay(BattleDecisionRequest request) {
  return switch (request) {
    BattleTurnChoiceRequest() => 'Que doit faire le joueur ?',
    BattleForcedReplacementRequest() =>
      'Le joueur doit remplacer son Pokémon K.O.',
    BattleContinueRequest() => 'Le joueur doit continuer un tour forcé',
    BattleWaitRequest(:final reason) => switch (reason) {
        BattleWaitReason.battleFinished => 'Combat terminé',
        BattleWaitReason.resolvingTurn => 'Résolution du tour en cours',
        BattleWaitReason.activeFaintedWithoutReplacement =>
          'Aucun remplaçant disponible',
        BattleWaitReason.noLegalChoice => 'Aucune décision légale disponible',
      },
  };
}

/// Construit les lignes de restitution d'un tour pour l'overlay runtime.
///
/// La vraie source de vérité de narration reste `BattleTurnResult.timeline`.
/// Le lot 1 améliore uniquement la composition visuelle de cette narration.
List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
  if (turnResult.timeline.isEmpty &&
      (turnResult.executions.isNotEmpty ||
          turnResult.statusEvents.isNotEmpty ||
          turnResult.volatileEvents.isNotEmpty ||
          turnResult.fieldEvents.isNotEmpty ||
          turnResult.stealthRockEvents.isNotEmpty ||
          turnResult.spikesEvents.isNotEmpty ||
          turnResult.switchEvents.isNotEmpty)) {
    throw StateError(
      'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
    );
  }

  final lines = <String>[];
  for (final event in turnResult.timeline) {
    switch (event) {
      case BattleTurnExecutionEvent(:final execution):
        final attacker = _overlayCombatantLabelForSide(execution.attackerSide);
        lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts',
        );
      case BattleTurnStatusEvent(:final event):
        lines.add(_formatOverlayStatusEvent(event));
      case BattleTurnVolatileEvent(:final event):
        lines.add(_formatOverlayVolatileEvent(event));
      case BattleTurnFieldEvent(:final event):
        lines.add(_formatOverlayFieldEvent(event));
      case BattleTurnStealthRockEvent(:final event):
        lines.add(_formatOverlayStealthRockEvent(event));
      case BattleTurnSpikesEvent(:final event):
        lines.add(_formatOverlaySpikesEvent(event));
      case BattleTurnSwitchEvent(:final event):
        lines.add(_formatOverlaySwitchEvent(event));
    }
  }

  return List<String>.unmodifiable(lines);
}

/// Construit les lignes de narration visibles dans la command box.
///
/// Invariant important du lot 1 :
/// - on reste adossé à la timeline observable du moteur ;
/// - quand aucun tour n'est disponible, on retombe sur la requête courante ;
/// - on n'invente pas de narration "UI-only".
List<String> buildBattleNarrationLinesForOverlay(BattleSession session) {
  final currentTurn = session.state.currentTurn;
  if (currentTurn != null) {
    final lines = buildBattleTurnLinesForOverlay(currentTurn);
    if (lines.isNotEmpty) {
      final startIndex = lines.length > 4 ? lines.length - 4 : 0;
      return List<String>.unmodifiable(lines.sublist(startIndex));
    }
  }

  if (session.state.isFinished && session.state.outcome != null) {
    return List<String>.unmodifiable(<String>[
      _buildOutcomeHeadline(session.state.outcome!),
    ]);
  }

  return List<String>.unmodifiable(<String>[
    buildBattleDecisionPromptForOverlay(session.decisionRequest),
  ]);
}

/// Construit les lignes du panneau debug optionnel.
///
/// Ce panneau ne sert qu'au diagnostic local. Il doit rester :
/// - explicitement dérivé de la vérité battle/runtime déjà existante ;
/// - explicitement séparé de l'UI de combat normale.
List<String> buildBattleDebugLinesForOverlay(
  BattleSession session, {
  required int selectedIndex,
}) {
  return List<String>.unmodifiable(<String>[
    'phase: ${session.state.phase.name}',
    'request: ${session.decisionRequest.runtimeType}',
    'choix: ${session.decisionRequest.allowedChoices.length}',
    'selection: $selectedIndex',
    'joueur: ${session.state.player.speciesId} ${session.state.player.currentHp}/${session.state.player.maxHp}',
    'ennemi: ${session.state.enemy.speciesId} ${session.state.enemy.currentHp}/${session.state.enemy.maxHp}',
  ]);
}

String _formatOverlaySwitchEvent(BattleSwitchEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleSwitchEventKind.switched => event.wasForced
        ? '$actor remplace ${event.fromSpeciesId} par ${event.toSpeciesId}'
        : '$actor switch de ${event.fromSpeciesId} vers ${event.toSpeciesId}',
    BattleSwitchEventKind.replacementRequired =>
      '$actor doit remplacer ${event.fromSpeciesId} K.O.',
  };
}

String _formatOverlayStatusEvent(BattleStatusEvent event) {
  final actor = _overlayCombatantLabelForSide(event.targetSide);
  final status = event.status.name.toUpperCase();
  return switch (event.kind) {
    BattleStatusEventKind.applied =>
      '$actor reçoit le statut $status (${event.sourceMoveId})',
    BattleStatusEventKind.blockedExistingMajorStatus =>
      '$actor garde déjà ${event.existingStatus!.name.toUpperCase()} '
          'et ignore $status',
    BattleStatusEventKind.preventedAction =>
      '$actor ne peut pas agir à cause de $status',
    BattleStatusEventKind.residualDamage =>
      '$actor subit ${event.damage} dégâts résiduels ($status'
          '${event.toxicCounter == null ? '' : ', compteur ${event.toxicCounter}'}'
          ')',
  };
}

String _formatOverlayVolatileEvent(BattleVolatileEvent event) {
  final actor = _overlayCombatantLabelForSide(event.actorSide);
  final target = event.targetSide == null
      ? null
      : _overlayCombatantLabelForSide(event.targetSide!);

  return switch (event.kind) {
    BattleVolatileEventKind.protectActivated => '$actor active Protect',
    BattleVolatileEventKind.protectBlocked =>
      '${target ?? 'La cible'} bloque l’attaque avec Protect',
    BattleVolatileEventKind.protectBroken =>
      '$actor perce Protect sur ${target ?? 'la cible'}',
    BattleVolatileEventKind.rechargeRequired =>
      '$actor doit recharger au tour suivant',
    BattleVolatileEventKind.rechargeTurnSpent =>
      '$actor passe son tour pour recharger',
    BattleVolatileEventKind.chargeStarted =>
      '$actor commence à charger ${event.sourceMoveId ?? 'son attaque'}',
    BattleVolatileEventKind.chargeReleased =>
      '$actor libère ${event.sourceMoveId ?? 'son attaque chargée'}',
  };
}

String _formatOverlayFieldEvent(BattleFieldEvent event) {
  return switch (event.kind) {
    BattleFieldEventKind.weatherSet =>
      'Le champ passe à ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherResidualDamage =>
      '${_overlayCombatantLabelForSide(event.targetSide!)} subit ${event.damage} dégâts de ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherExpired =>
      '${_overlayWeatherLabel(event.weather!)} prend fin',
    BattleFieldEventKind.pseudoWeatherSet =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} devient actif',
    BattleFieldEventKind.pseudoWeatherCleared =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} est dissipé',
    BattleFieldEventKind.pseudoWeatherExpired =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} prend fin',
  };
}

String _formatOverlayStealthRockEvent(BattleStealthRockEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleStealthRockEventKind.set => 'Stealth Rock est posé du côté $actor',
    BattleStealthRockEventKind.alreadyPresent =>
      'Stealth Rock est déjà posé du côté $actor',
    BattleStealthRockEventKind.damagedOnEntry =>
      '$actor subit ${event.damage} dégâts de Stealth Rock à l’entrée',
  };
}

String _formatOverlaySpikesEvent(BattleSpikesEvent event) {
  final actor = event.targetSlot == null
      ? _overlayCombatantLabelForSide(event.side)
      : _overlayCombatantLabelForSide(event.targetSlot!.side);
  return switch (event.kind) {
    BattleSpikesEventKind.setLayer =>
      'Spikes monte à ${event.layers} couche(s) du côté $actor',
    BattleSpikesEventKind.alreadyAtMaxLayers =>
      'Spikes est déjà à ${event.layers} couche(s) du côté $actor',
    BattleSpikesEventKind.damagedOnEntry =>
      '$actor subit ${event.damage} dégâts de Spikes à l’entrée (${event.layers} couche(s))',
  };
}

String _overlayCombatantLabelForSide(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
}

String _overlayWeatherLabel(BattleWeatherId weather) {
  return switch (weather) {
    BattleWeatherId.rain => 'la pluie',
    BattleWeatherId.sandstorm => 'la tempête de sable',
  };
}

String _overlayPseudoWeatherLabel(BattlePseudoWeatherId pseudoWeather) {
  return switch (pseudoWeather) {
    BattlePseudoWeatherId.trickRoom => 'Trick Room',
  };
}

String _buildOutcomeHeadline(BattleOutcome outcome) {
  return switch (outcome.type) {
    BattleOutcomeType.victory => 'Victoire !',
    BattleOutcomeType.defeat => 'Défaite...',
    BattleOutcomeType.runaway => 'Fuite réussie !',
    BattleOutcomeType.captured => 'Capture réussie !',
  };
}

/// Overlay de combat lot 1.
///
/// Responsabilité :
/// - garder le runtime battle branché sur les mêmes vérités métier ;
/// - composer une scène de combat lisible ;
/// - déléguer le rendu concret aux composants de présentation du runtime.
///
/// Garde-fous :
/// - aucune logique battle n'entre ici ;
/// - aucune logique parallèle aux requests ou à la timeline n'est créée ;
/// - aucun resolver de background contextuel n'est introduit ici ;
/// - aucun seam IA n'est introduit ici.
class BattleOverlayComponent extends PositionComponent {
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
    this.backgroundSpec = const BattleBackgroundSpec.fallbackField(),
    this.showDebugPanel = false,
  })  : _session = session,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  BattleSession _session;

  final void Function(PlayerBattleChoice choice) onPlayerChoice;
  final BattleBackgroundSpec backgroundSpec;

  /// Le debug reste volontairement opt-in.
  ///
  /// Le lot 1 doit sortir l'UI normale du mode "debug panel". On garde donc un
  /// interrupteur explicite au lieu de laisser le debug redéfinir l'apparence
  /// par défaut du combat.
  final bool showDebugPanel;

  BattleSceneBackdropComponent? _backdrop;
  BattleSceneCombatantComponent? _enemyCombatant;
  BattleSceneCombatantComponent? _playerCombatant;
  BattleSceneHudComponent? _enemyHud;
  BattleSceneHudComponent? _playerHud;
  BattleCommandPanelComponent? _commandPanel;
  BattleDebugPanelComponent? _debugPanel;
  TextComponent? _outcomeBanner;

  int _selectedIndex = 0;

  @visibleForTesting
  bool get commandPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get narrationPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get debugPanelMounted => _debugPanel != null;

  @visibleForTesting
  BattleBackgroundKey get currentBackgroundKey => backgroundSpec.key;

  @visibleForTesting
  String get currentPromptText =>
      buildBattleDecisionPromptForOverlay(_session.decisionRequest);

  @visibleForTesting
  String get currentNarrationText =>
      buildBattleNarrationLinesForOverlay(_session).join('\n');

  @override
  Future<void> onLoad() async {
    // Le layout du lot 1 reste volontairement local et concret :
    // - on assume une scène plein écran ;
    // - on place des zones stables joueur/ennemi ;
    // - on garde un seul panneau bas pour narration + commandes ;
    // - on évite volontairement un système de layout générique.
    const padding = 24.0;
    final commandPanelHeight = (size.y * 0.3).clamp(186.0, 224.0).toDouble();
    final commandPanelY = size.y - commandPanelHeight - 18;

    final enemyHudSize = Vector2(
      (size.x * 0.31).clamp(240.0, 320.0).toDouble(),
      98,
    );
    final playerHudSize = Vector2(
      (size.x * 0.34).clamp(250.0, 340.0).toDouble(),
      106,
    );

    final enemyCombatantSize = Vector2(
      (size.x * 0.24).clamp(220.0, 310.0).toDouble(),
      (size.y * 0.26).clamp(136.0, 182.0).toDouble(),
    );
    final playerCombatantSize = Vector2(
      (size.x * 0.3).clamp(250.0, 350.0).toDouble(),
      (size.y * 0.31).clamp(166.0, 222.0).toDouble(),
    );

    _backdrop = BattleSceneBackdropComponent(
      size: size.clone(),
      backgroundSpec: backgroundSpec,
    );
    await add(_backdrop!);

    _enemyCombatant = BattleSceneCombatantComponent(
      position: Vector2(size.x - enemyCombatantSize.x - 116, 92),
      size: enemyCombatantSize,
      isPlayerSide: false,
      speciesLabel: _session.state.enemy.speciesId,
    );
    await add(_enemyCombatant!);

    _playerCombatant = BattleSceneCombatantComponent(
      position: Vector2(62, commandPanelY - playerCombatantSize.y - 12),
      size: playerCombatantSize,
      isPlayerSide: true,
      speciesLabel: _session.state.player.speciesId,
    );
    await add(_playerCombatant!);

    _enemyHud = BattleSceneHudComponent(
      position: Vector2(padding, padding),
      size: enemyHudSize,
      ownerLabel: 'ENNEMI',
      combatant: _session.state.enemy,
      isPlayerSide: false,
    );
    await add(_enemyHud!);

    _playerHud = BattleSceneHudComponent(
      position: Vector2(
        size.x - playerHudSize.x - padding,
        commandPanelY - playerHudSize.y - 10,
      ),
      size: playerHudSize,
      ownerLabel: 'JOUEUR',
      combatant: _session.state.player,
      isPlayerSide: true,
    );
    await add(_playerHud!);

    _commandPanel = BattleCommandPanelComponent(
      position: Vector2(padding, commandPanelY),
      size: Vector2(size.x - (padding * 2), commandPanelHeight),
      onChoiceSelected: onPlayerChoice,
    );
    await add(_commandPanel!);

    if (showDebugPanel) {
      _debugPanel = BattleDebugPanelComponent(
        position: Vector2(size.x - 248, 32),
        size: Vector2(216, 148),
      );
      await add(_debugPanel!);
    }

    _syncVisualState();
  }

  /// Met à jour l'overlay avec une nouvelle session immutable.
  ///
  /// Invariants runtime préservés :
  /// - `BattleSession` reste la seule source de vérité d'état ;
  /// - `BattleDecisionRequest` reste la seule source de vérité des commandes ;
  /// - `BattleTurnResult.timeline` reste la seule source de vérité narrative.
  ///
  /// Le fond n'est volontairement pas recalculé ici :
  /// - le lot 2 le résout à l'ouverture du combat à partir du contexte runtime ;
  /// - l'évolution du tour ne doit pas recréer une logique parallèle de décor ;
  /// - un vrai resolver contextuel plus riche restera un sujet futur côté
  ///   runtime, pas un effet secondaire de `BattleSession`.
  void updateState(BattleSession newSession) {
    _session = newSession;
    _clampSelectionToCurrentChoices();
    _syncVisualState();
  }

  bool moveSelectionUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      _syncPanelsOnly();
      return true;
    }
    return false;
  }

  bool moveSelectionDown() {
    final choices = _session.decisionRequest.allowedChoices;
    if (_selectedIndex < choices.length - 1) {
      _selectedIndex++;
      _syncPanelsOnly();
      return true;
    }
    return false;
  }

  PlayerBattleChoice? getSelectedChoice() {
    final choices = _session.decisionRequest.allowedChoices;
    if (choices.isEmpty) {
      return null;
    }
    if (_selectedIndex < 0 || _selectedIndex >= choices.length) {
      return null;
    }
    return choices[_selectedIndex];
  }

  bool validateSelectedChoice() {
    final selectedChoice = getSelectedChoice();
    if (selectedChoice == null) {
      return false;
    }
    onPlayerChoice(selectedChoice);
    return true;
  }

  void _syncVisualState() {
    _enemyCombatant?.sync(speciesLabel: _session.state.enemy.speciesId);
    _playerCombatant?.sync(speciesLabel: _session.state.player.speciesId);
    _enemyHud?.sync(combatant: _session.state.enemy);
    _playerHud?.sync(combatant: _session.state.player);
    _syncPanelsOnly();
    _syncOutcomeBanner();
  }

  void _syncPanelsOnly() {
    _clampSelectionToCurrentChoices();

    _commandPanel?.sync(
      battleLabel: _titleForSession(),
      prompt: buildBattleDecisionPromptForOverlay(_session.decisionRequest),
      narrationLines: buildBattleNarrationLinesForOverlay(_session),
      choices: _buildChoiceEntries(_session.decisionRequest),
      selectedIndex: _selectedIndex,
    );

    _debugPanel?.sync(
      lines: buildBattleDebugLinesForOverlay(
        _session,
        selectedIndex: _selectedIndex,
      ),
    );
  }

  void _syncOutcomeBanner() {
    if (!_session.state.isFinished || _session.state.outcome == null) {
      _outcomeBanner?.removeFromParent();
      _outcomeBanner = null;
      return;
    }

    final outcome = _session.state.outcome!;
    final bannerText = _buildOutcomeHeadline(outcome);
    final bannerColor = outcome.isVictory || outcome.isCaptured
        ? const Color(0xFF8AE36A)
        : const Color(0xFFFF8E75);

    if (_outcomeBanner == null) {
      _outcomeBanner = TextComponent(
        text: bannerText,
        position: Vector2(size.x / 2, size.y * 0.17),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: TextStyle(
            color: bannerColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        priority: 45,
      );
      add(_outcomeBanner!);
      return;
    }

    _outcomeBanner!.text = bannerText;
    _outcomeBanner!.textRenderer = TextPaint(
      style: TextStyle(
        color: bannerColor,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  List<BattleCommandChoiceEntry> _buildChoiceEntries(
    BattleDecisionRequest request,
  ) {
    return List<BattleCommandChoiceEntry>.unmodifiable(
      request.allowedChoices.map(
        (choice) => _entryForChoice(request, choice),
      ),
    );
  }

  BattleCommandChoiceEntry _entryForChoice(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    if (choice is PlayerBattleChoiceFight) {
      final move = _session.state.player.moves[choice.moveIndex];
      final moveKind = switch (move.category) {
        BattleMoveCategory.physical => 'Physique',
        BattleMoveCategory.special => 'Speciale',
        BattleMoveCategory.status => 'Statut',
        null => 'Technique',
      };
      final moveType = move.type.toUpperCase();
      final powerLabel = move.power > 0 ? 'Puissance ${move.power}' : 'Sans degats directs';
      return BattleCommandChoiceEntry(
        choice: choice,
        title: move.name,
        subtitle: '$moveType · $moveKind · $powerLabel',
        tone: switch (move.category) {
          BattleMoveCategory.physical => BattleCommandChoiceTone.attack,
          BattleMoveCategory.special => BattleCommandChoiceTone.special,
          BattleMoveCategory.status || null => BattleCommandChoiceTone.support,
        },
      );
    }

    if (choice is PlayerBattleChoiceSwitch) {
      final reserve = _session.state.playerReserve[choice.reserveIndex];
      final isForcedReplacement = request is BattleForcedReplacementRequest;
      final verb = isForcedReplacement ? 'Remplacer' : 'Switch';
      return BattleCommandChoiceEntry(
        choice: choice,
        title: '$verb ${reserve.speciesId}',
        subtitle: 'Reserve · ${reserve.currentHp}/${reserve.maxHp} PV',
        tone: BattleCommandChoiceTone.switching,
      );
    }

    if (choice is PlayerBattleChoiceContinue) {
      if (request case BattleContinueRequest(:final reason)) {
        if (reason == BattleContinueReason.pendingChargeRelease) {
          return BattleCommandChoiceEntry(
            choice: choice,
            title: 'Continuer',
            subtitle: 'Liberer l attaque chargee',
            tone: BattleCommandChoiceTone.neutral,
          );
        }
        if (reason == BattleContinueReason.mustRecharge) {
          return BattleCommandChoiceEntry(
            choice: choice,
            title: 'Continuer',
            subtitle: 'Tour de recharge force',
            tone: BattleCommandChoiceTone.neutral,
          );
        }
      }
      return BattleCommandChoiceEntry(
        choice: choice,
        title: 'Continuer',
        subtitle: 'Aucune autre commande legale',
        tone: BattleCommandChoiceTone.neutral,
      );
    }

    if (choice is PlayerBattleChoiceCapture) {
      return BattleCommandChoiceEntry(
        choice: choice,
        title: 'Capturer',
        subtitle: 'Tentative de capture supportee',
        tone: BattleCommandChoiceTone.special,
      );
    }

    if (choice is PlayerBattleChoiceRun) {
      return BattleCommandChoiceEntry(
        choice: choice,
        title: 'Fuir',
        subtitle: 'Tentative de fuite supportee',
        tone: BattleCommandChoiceTone.attack,
      );
    }

    return BattleCommandChoiceEntry(
      choice: choice,
      title: 'Action inconnue',
      subtitle: 'Choix legal mais non habille',
      tone: BattleCommandChoiceTone.neutral,
    );
  }

  void _clampSelectionToCurrentChoices() {
    final choices = _session.decisionRequest.allowedChoices;
    if (choices.isEmpty) {
      _selectedIndex = 0;
      return;
    }
    if (_selectedIndex >= choices.length) {
      _selectedIndex = choices.length - 1;
    }
    if (_selectedIndex < 0) {
      _selectedIndex = 0;
    }
  }

  String _titleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat dresseur';
    }
    return 'Combat sauvage';
  }
}

```

### `packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart`

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../infrastructure/tile_image_loader.dart';
import 'battle_background_resolver.dart';

/// Fond de scène par défaut pour le lot 1.
///
/// Garde-fous de périmètre :
/// - ce composant vit côté `map_runtime` parce qu'il ne transporte aucune
///   vérité métier battle ; il ne fait que peindre une ambiance de scène ;
/// - après le lot 2, il reste volontairement borné à la consommation d'une
///   petite spec déjà résolue ;
/// - il ne résout lui-même ni biome, ni map, ni trainer, ni encounter ;
/// - ce vrai seam de résolution appartient explicitement au runtime amont.
class BattleSceneBackdropComponent extends PositionComponent {
  BattleSceneBackdropComponent({
    required Vector2 size,
    BattleBackgroundSpec backgroundSpec =
        const BattleBackgroundSpec.fallbackField(),
  })  : _backgroundSpec = backgroundSpec,
        super(
          size: size,
          anchor: Anchor.topLeft,
          priority: 0,
        );

  BattleBackgroundSpec _backgroundSpec;
  ui.Image? _explicitImage;
  String? _explicitImageSourcePath;
  bool _didExplicitImageLoadFail = false;

  @visibleForTesting
  BattleBackgroundKey get currentBackgroundKey => _backgroundSpec.key;

  @visibleForTesting
  bool get hasResolvedExplicitImage => _explicitImage != null;

  @visibleForTesting
  bool get didExplicitImageLoadFail => _didExplicitImageLoadFail;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _syncExplicitImage();
  }

  /// Le backdrop reste un consommateur passif de spec.
  ///
  /// Pourquoi ce setter existe déjà :
  /// - il garde le composant localement testable ;
  /// - il laisse le lot 2 injecter une variation de contexte visible ;
  /// - il ne promet pas pour autant un système de theming plus large.
  void sync({
    required BattleBackgroundSpec backgroundSpec,
  }) {
    _backgroundSpec = backgroundSpec;
    _syncExplicitImage();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    final palette = _paletteFor(_backgroundSpec.key);

    if (_explicitImage != null) {
      _renderExplicitImage(canvas, rect, palette);
      _renderFloor(canvas, palette);
      _renderForegroundAccent(canvas, palette);
      return;
    }

    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.y),
        palette.skyColors,
        const <double>[0.0, 0.36, 0.72, 1.0],
      );
    canvas.drawRect(rect, skyPaint);

    final horizonGlowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.x * palette.glowCenterDx, size.y * palette.glowCenterDy),
        size.x * palette.glowRadiusScale,
        <Color>[
          palette.glowColor,
          palette.glowColor.withValues(alpha: 0.08),
          const Color(0x00000000),
        ],
        const <double>[0.0, 0.45, 1.0],
      );
    canvas.drawRect(rect, horizonGlowPaint);

    _renderMidground(canvas, palette);
    _renderFloor(canvas, palette);
    _renderForegroundAccent(canvas, palette);
  }

  Future<void> _syncExplicitImage() async {
    final explicitImagePath = _backgroundSpec.explicitImageAbsolutePath?.trim();
    if (explicitImagePath == null || explicitImagePath.isEmpty) {
      _explicitImage = null;
      _explicitImageSourcePath = null;
      _didExplicitImageLoadFail = false;
      return;
    }

    if (_explicitImage != null && _explicitImageSourcePath == explicitImagePath) {
      return;
    }

    try {
      final image = await loadImageFromFilePath(explicitImagePath);
      _explicitImage = image;
      _explicitImageSourcePath = explicitImagePath;
      _didExplicitImageLoadFail = false;
    } catch (_) {
      _explicitImage = null;
      _explicitImageSourcePath = explicitImagePath;
      _didExplicitImageLoadFail = true;
    }
  }

  void _renderExplicitImage(
    Canvas canvas,
    Rect rect,
    _BattleBackdropPalette palette,
  ) {
    final image = _explicitImage!;
    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final fitted = applyBoxFit(BoxFit.cover, imageSize, rect.size);
    final inputSubrect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & imageSize,
    );
    final outputSubrect = Alignment.center.inscribe(
      fitted.destination,
      rect,
    );
    canvas.drawImageRect(image, inputSubrect, outputSubrect, Paint());

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, size.y),
          <Color>[
            const Color(0x6610141E),
            palette.bandColor.withValues(alpha: 0.18),
            const Color(0xB80B1017),
          ],
          const <double>[0.0, 0.45, 1.0],
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.x * 0.52, size.y * 0.32),
          size.x * 0.46,
          <Color>[
            palette.glowColor.withValues(alpha: 0.16),
            const Color(0x00000000),
          ],
        ),
    );
  }

  void _renderMidground(Canvas canvas, _BattleBackdropPalette palette) {
    switch (_backgroundSpec.key) {
      case BattleBackgroundKey.fallbackField:
        _renderFallbackBands(canvas, palette);
      case BattleBackgroundKey.wildOutdoor:
        _renderWildHills(canvas, palette);
      case BattleBackgroundKey.trainerOutdoor:
        _renderTrainerBanners(canvas, palette);
      case BattleBackgroundKey.indoor:
        _renderIndoorPanels(canvas, palette);
    }
  }

  void _renderFallbackBands(Canvas canvas, _BattleBackdropPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.08, size.y * 0.18, size.x * 0.62, 22),
        const Radius.circular(14),
      ),
      Paint()..color = palette.bandColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.28, size.y * 0.28, size.x * 0.52, 18),
        const Radius.circular(12),
      ),
      Paint()..color = palette.softBandColor,
    );
  }

  void _renderWildHills(Canvas canvas, _BattleBackdropPalette palette) {
    final hillPaint = Paint()..color = palette.bandColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.22, size.y * 0.55),
        width: size.x * 0.48,
        height: size.y * 0.22,
      ),
      hillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.66, size.y * 0.5),
        width: size.x * 0.66,
        height: size.y * 0.28,
      ),
      Paint()..color = palette.softBandColor,
    );
  }

  void _renderTrainerBanners(Canvas canvas, _BattleBackdropPalette palette) {
    final leftPath = Path()
      ..moveTo(0, size.y * 0.16)
      ..lineTo(size.x * 0.2, size.y * 0.12)
      ..lineTo(size.x * 0.34, size.y * 0.46)
      ..lineTo(0, size.y * 0.42)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = palette.bandColor);

    final rightPath = Path()
      ..moveTo(size.x, size.y * 0.12)
      ..lineTo(size.x * 0.78, size.y * 0.08)
      ..lineTo(size.x * 0.6, size.y * 0.42)
      ..lineTo(size.x, size.y * 0.38)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = palette.softBandColor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.28, size.y * 0.22, size.x * 0.44, 14),
        const Radius.circular(10),
      ),
      Paint()..color = palette.ribbonColor,
    );
  }

  void _renderIndoorPanels(Canvas canvas, _BattleBackdropPalette palette) {
    final wallRect = Rect.fromLTWH(
        size.x * 0.08, size.y * 0.14, size.x * 0.84, size.y * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(wallRect, const Radius.circular(26)),
      Paint()..color = palette.bandColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        wallRect.deflate(12),
        const Radius.circular(18),
      ),
      Paint()..color = palette.softBandColor,
    );

    final spotlightPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.x * 0.5, size.y * 0.62),
        size.x * 0.24,
        <Color>[
          palette.ribbonColor,
          palette.ribbonColor.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(Offset.zero & Size(size.x, size.y), spotlightPaint);
  }

  void _renderFloor(Canvas canvas, _BattleBackdropPalette palette) {
    final floorPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.y * 0.58),
        Offset(0, size.y),
        palette.floorColors,
        const <double>[0.0, 0.34, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.58, size.x, size.y * 0.42),
      floorPaint,
    );
  }

  void _renderForegroundAccent(Canvas canvas, _BattleBackdropPalette palette) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.24, size.y * 0.73),
        width: size.x * 0.24,
        height: size.y * 0.06,
      ),
      Paint()..color = palette.floorAccentColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.74, size.y * 0.41),
        width: size.x * 0.18,
        height: size.y * 0.05,
      ),
      Paint()..color = palette.softBandColor.withValues(alpha: 0.45),
    );
  }

  _BattleBackdropPalette _paletteFor(BattleBackgroundKey key) {
    return switch (key) {
      BattleBackgroundKey.fallbackField => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF16243B),
            Color(0xFF263B5D),
            Color(0xFF4F7A79),
            Color(0xFF99A56E),
          ],
          floorColors: <Color>[
            Color(0x14000000),
            Color(0x4411161E),
            Color(0xCC0B0E14),
          ],
          glowColor: Color(0x55FFF7C8),
          bandColor: Color(0x12FFFFFF),
          softBandColor: Color(0x10FFFFFF),
          ribbonColor: Color(0x16FFFFFF),
          floorAccentColor: Color(0x24000000),
          glowCenterDx: 0.52,
          glowCenterDy: 0.42,
          glowRadiusScale: 0.42,
        ),
      BattleBackgroundKey.wildOutdoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF10304D),
            Color(0xFF215F6B),
            Color(0xFF5A9A6F),
            Color(0xFFB9C97A),
          ],
          floorColors: <Color>[
            Color(0x18050C08),
            Color(0x66151F12),
            Color(0xD012140F),
          ],
          glowColor: Color(0x6BFFF2B4),
          bandColor: Color(0x4C3E6F58),
          softBandColor: Color(0x384FA172),
          ribbonColor: Color(0x26E6FFD0),
          floorAccentColor: Color(0x38456A35),
          glowCenterDx: 0.44,
          glowCenterDy: 0.38,
          glowRadiusScale: 0.34,
        ),
      BattleBackgroundKey.trainerOutdoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF2A163C),
            Color(0xFF6D3151),
            Color(0xFFB75A45),
            Color(0xFFE0AE61),
          ],
          floorColors: <Color>[
            Color(0x180B0608),
            Color(0x6B2D1517),
            Color(0xD0140D12),
          ],
          glowColor: Color(0x75FFD4A4),
          bandColor: Color(0x523E1B43),
          softBandColor: Color(0x4FA33E57),
          ribbonColor: Color(0x40FFE2A0),
          floorAccentColor: Color(0x42321A25),
          glowCenterDx: 0.5,
          glowCenterDy: 0.32,
          glowRadiusScale: 0.3,
        ),
      BattleBackgroundKey.indoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF141729),
            Color(0xFF232742),
            Color(0xFF394063),
            Color(0xFF6B6A78),
          ],
          floorColors: <Color>[
            Color(0x1A020305),
            Color(0x8036374A),
            Color(0xD0111219),
          ],
          glowColor: Color(0x4CC9D9FF),
          bandColor: Color(0x5B252A3B),
          softBandColor: Color(0x643C435D),
          ribbonColor: Color(0x3838F0FF),
          floorAccentColor: Color(0x3B727A95),
          glowCenterDx: 0.5,
          glowCenterDy: 0.24,
          glowRadiusScale: 0.24,
        ),
    };
  }
}

final class _BattleBackdropPalette {
  const _BattleBackdropPalette({
    required this.skyColors,
    required this.floorColors,
    required this.glowColor,
    required this.bandColor,
    required this.softBandColor,
    required this.ribbonColor,
    required this.floorAccentColor,
    required this.glowCenterDx,
    required this.glowCenterDy,
    required this.glowRadiusScale,
  });

  final List<Color> skyColors;
  final List<Color> floorColors;
  final Color glowColor;
  final Color bandColor;
  final Color softBandColor;
  final Color ribbonColor;
  final Color floorAccentColor;
  final double glowCenterDx;
  final double glowCenterDy;
  final double glowRadiusScale;
}

```

### `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`

```dart
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// Placeholder visuel de combattant pour la battle scene runtime.
///
/// Le lot 4b modernise la lecture de scène sans mentir :
/// - toujours aucun sprite battle dédié ;
/// - toujours aucune dépendance battle-core ;
/// - mais une silhouette plus vivante, avec une plateforme plus lisible et un
///   vrai ancrage joueur/ennemi inspiré du rythme du gif de référence.
class BattleSceneCombatantComponent extends PositionComponent {
  BattleSceneCombatantComponent({
    required Vector2 position,
    required Vector2 size,
    required this.isPlayerSide,
    required String speciesLabel,
  })  : _speciesLabel = speciesLabel,
        super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 10,
        );

  final bool isPlayerSide;

  String _speciesLabel;
  TextComponent? _speciesText;
  TextComponent? _monogramText;

  @override
  Future<void> onLoad() async {
    _speciesText = TextComponent(
      text: _speciesLabel,
      position: Vector2(size.x / 2, size.y - 8),
      anchor: Anchor.bottomCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF8FBFF),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      priority: 13,
    );
    await add(_speciesText!);

    _monogramText = TextComponent(
      text: _speciesMonogram(_speciesLabel),
      position: Vector2(size.x * 0.54, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xF8FFFFFF),
          fontSize: 34,
          fontWeight: FontWeight.w900,
        ),
      ),
      priority: 13,
    );
    await add(_monogramText!);
  }

  void sync({
    required String speciesLabel,
  }) {
    _speciesLabel = speciesLabel;
    _speciesText?.text = _speciesLabel;
    _monogramText?.text = _speciesMonogram(_speciesLabel);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final platformRect = Rect.fromCenter(
      center: Offset(size.x * 0.56, size.y * 0.8),
      width: size.x * (isPlayerSide ? 0.86 : 0.7),
      height: isPlayerSide ? 34 : 28,
    );
    canvas.drawOval(
      platformRect,
      Paint()..color = const Color(0x995E4E34),
    );
    canvas.drawOval(
      platformRect.deflate(5),
      Paint()..color = const Color(0xFFD8C59E),
    );

    final shadowRect = Rect.fromCenter(
      center: Offset(size.x * 0.54, size.y * 0.69),
      width: size.x * 0.42,
      height: size.y * 0.12,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = const Color(0x33000000),
    );

    final auraRect = Rect.fromCenter(
      center: Offset(size.x * (isPlayerSide ? 0.48 : 0.58), size.y * 0.42),
      width: size.x * (isPlayerSide ? 0.64 : 0.48),
      height: size.y * 0.54,
    );
    canvas.drawOval(
      auraRect,
      Paint()
        ..shader = RadialGradient(
          colors: isPlayerSide
              ? const <Color>[
                  Color(0x667AA9F4),
                  Color(0x00000000),
                ]
              : const <Color>[
                  Color(0x66B9D27A),
                  Color(0x00000000),
                ],
        ).createShader(auraRect),
    );

    _renderSilhouette(canvas);
  }

  void _renderSilhouette(Canvas canvas) {
    final primaryColor =
        isPlayerSide ? const Color(0xFF3E4B7E) : const Color(0xFF6B87B7);
    final secondaryColor =
        isPlayerSide ? const Color(0xFF7DB4F7) : const Color(0xFFD7E8FF);

    final bodyRect = Rect.fromCenter(
      center: Offset(size.x * 0.52, size.y * 0.44),
      width: size.x * (isPlayerSide ? 0.42 : 0.28),
      height: size.y * (isPlayerSide ? 0.48 : 0.34),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(34)),
      Paint()..color = primaryColor,
    );

    final chestRect = Rect.fromCenter(
      center: Offset(size.x * 0.54, size.y * 0.46),
      width: bodyRect.width * 0.72,
      height: bodyRect.height * 0.68,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chestRect, const Radius.circular(28)),
      Paint()..color = secondaryColor.withValues(alpha: 0.88),
    );

    final headRect = Rect.fromCircle(
      center: Offset(size.x * 0.5, size.y * 0.22),
      radius: isPlayerSide ? size.x * 0.11 : size.x * 0.085,
    );
    canvas.drawOval(
      headRect,
      Paint()..color = secondaryColor,
    );

    final accentPath = Path();
    if (isPlayerSide) {
      accentPath
        ..moveTo(size.x * 0.3, size.y * 0.44)
        ..lineTo(size.x * 0.14, size.y * 0.3)
        ..lineTo(size.x * 0.2, size.y * 0.58)
        ..close();
    } else {
      accentPath
        ..moveTo(size.x * 0.6, size.y * 0.34)
        ..lineTo(size.x * 0.8, size.y * 0.2)
        ..lineTo(size.x * 0.74, size.y * 0.5)
        ..close();
    }
    canvas.drawPath(accentPath, Paint()..color = primaryColor.withValues(alpha: 0.92));
  }

  String _speciesMonogram(String speciesLabel) {
    final trimmed = speciesLabel.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}

```

### `packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart`

```dart
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// HUD de combattant pour la scène de combat.
///
/// Le lot 4b rapproche ce HUD d'une lecture battle-like plus premium, tout en
/// restant honnête :
/// - on n'invente aucune donnée absente du moteur ;
/// - on n'ouvre pas de nouveau système d'UI générique ;
/// - on reformate seulement des informations déjà vraies dans `BattleSession`.
class BattleSceneHudComponent extends PositionComponent {
  BattleSceneHudComponent({
    required Vector2 position,
    required Vector2 size,
    required this.ownerLabel,
    required BattleCombatant combatant,
    required this.isPlayerSide,
  })  : _combatant = combatant,
        super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: 20,
        );

  final String ownerLabel;
  final bool isPlayerSide;
  BattleCombatant _combatant;

  TextComponent? _ownerText;
  TextComponent? _speciesText;
  TextComponent? _levelText;
  TextComponent? _hpLabelText;
  TextComponent? _hpText;
  TextComponent? _statusText;
  RectangleComponent? _hpBarFill;

  @override
  Future<void> onLoad() async {
    _ownerText = TextComponent(
      text: ownerLabel,
      position: Vector2(16, 10),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xB34D5A6D),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
    await add(_ownerText!);

    _speciesText = TextComponent(
      text: _combatant.speciesId,
      position: Vector2(16, 26),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF202738),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await add(_speciesText!);

    _levelText = TextComponent(
      text: '',
      position: Vector2(size.x - 16, 30),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF3C4758),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await add(_levelText!);

    _statusText = TextComponent(
      text: '',
      position: Vector2(size.x - 16, 14),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF5A6579),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
    await add(_statusText!);

    _hpLabelText = TextComponent(
      text: 'HP',
      position: Vector2(16, size.y - 40),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFB87D2F),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    await add(_hpLabelText!);

    final hpBarBackground = RectangleComponent(
      position: Vector2(42, size.y - 36),
      size: Vector2(size.x - 58, 10),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFFABB5C1),
      priority: 21,
    );
    await add(hpBarBackground);

    _hpBarFill = RectangleComponent(
      position: Vector2(42, size.y - 36),
      size: Vector2(size.x - 58, 10),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFF62C06E),
      priority: 22,
    );
    await add(_hpBarFill!);

    _hpText = TextComponent(
      text: '',
      position: Vector2(size.x - 16, size.y - 18),
      anchor: Anchor.bottomRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF364355),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    await add(_hpText!);

    sync(combatant: _combatant);
  }

  void sync({
    required BattleCombatant combatant,
  }) {
    _combatant = combatant;
    _speciesText?.text = combatant.speciesId;
    _levelText?.text = 'Lv.${combatant.level}';
    _statusText?.text = _statusLabel(combatant);
    _hpText?.text = isPlayerSide
        ? '${combatant.currentHp}/${combatant.maxHp}'
        : '${((combatant.currentHp / (combatant.maxHp <= 0 ? 1 : combatant.maxHp)) * 100).round()}%';

    final safeMaxHp = combatant.maxHp <= 0 ? 1 : combatant.maxHp;
    final hpRatio = (combatant.currentHp / safeMaxHp).clamp(0.0, 1.0);
    _hpBarFill?.size = Vector2((size.x - 58) * hpRatio, 10);
    _hpBarFill?.paint.color = _hpColor(hpRatio);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final panelRect = Offset.zero & Size(size.x, size.y);

    canvas.drawShadow(
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(panelRect, const Radius.circular(20)),
        ),
      const Color(0x55000000),
      10,
      true,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(20)),
      Paint()..color = const Color(0xFFF3F0E8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(20)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF798394),
    );

    final accentRect = Rect.fromLTWH(12, 12, size.x - 24, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(accentRect, const Radius.circular(999)),
      Paint()
        ..color =
            isPlayerSide ? const Color(0xFF86B7F2) : const Color(0xFFB4C18D),
    );
  }

  String _statusLabel(BattleCombatant combatant) {
    if (combatant.isFainted) {
      return 'K.O.';
    }
    final status = combatant.majorStatus;
    if (status == null) {
      return '';
    }
    return status.id.name.toUpperCase();
  }

  Color _hpColor(double hpRatio) {
    if (hpRatio <= 0.25) {
      return const Color(0xFFD35B49);
    }
    if (hpRatio <= 0.5) {
      return const Color(0xFFD9A84B);
    }
    return const Color(0xFF62C06E);
  }
}

```

### `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

```dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../../domain/repositories/game_save_repository.dart';
import '../../../src/application/load_game_use_case.dart';
import '../../../src/application/save_game_use_case.dart';
import '../../../src/infrastructure/file_game_save_repository.dart';
import '../../application/battle_start_request.dart';
import '../../application/cutscene_runtime_models.dart';
import '../../application/cutscene_runtime_runner.dart';
import '../../application/dialogue_runtime_models.dart';
import '../../application/encounter_to_battle_request.dart';
import '../../application/field_move_dialogue.dart';
import '../../application/global_story_chapter_runtime.dart';
import '../../application/load_dialogue_content.dart';
import '../../application/load_runtime_map_bundle.dart';
import '../../application/map_entity_runtime_predicate_evaluator.dart';
import '../../application/movement_feedback.dart';
import '../../application/npc_overworld_movement_defaults.dart';
import '../../application/npc_runtime_presence.dart';
import '../../application/placed_behavior_runtime_cooldown.dart';
import '../../application/resolve_dialogue.dart';
import '../../application/runtime_battle_setup_mapper.dart';
import '../../application/runtime_battle_outcome_apply.dart';
import '../../application/runtime_character_refs.dart';
import '../../application/runtime_map_bundle.dart';
import '../../application/runtime_story_branching.dart';
import '../../application/scenario_runtime/scenario_runtime_executor.dart';
import '../../application/scenario_runtime/scenario_runtime_models.dart';
import '../../application/scenario_runtime_completion_gate.dart';
import '../../application/script_runtime_controller.dart';
import '../../application/script_runtime_state.dart';
import '../../application/scripted_entity_movement_controller.dart';
import '../../application/scripted_entity_movement_models.dart';
import '../../application/scripted_npc_anchor_passability.dart';
import '../../application/step_studio_completion_runtime.dart';
import '../../application/step_studio_world_presence_runtime.dart';
import '../../application/story_flags_manager.dart';
import '../../application/trainer_battle_request.dart';
import '../../infrastructure/tile_image_loader.dart';
import 'battle_overlay_component.dart';
import 'battle_background_resolver.dart';
import 'battle_transition_overlay_component.dart';
import 'dialogue_overlay_component.dart';
import 'map_layers_component.dart';
import 'overworld_actor_component.dart';
import 'player_component.dart';
import 'runtime_trainer_battle_overrides.dart';
import 'warp_transition_overlay_component.dart';

const double _kViewportTilesX = 15.0;
const double _kViewportTilesY = 11.0;
const double _kWaterRequiresSurfMessageCooldownMs = 900;
const GameplayEncounterPolicy _kEncounterPolicy = GameplayEncounterPolicy(
  chancePerStep: 0.12,
);

enum _RuntimeFlowPhase {
  overworld,
  dialogue,
  mapTransition,
  battleTransition,
  battle,
}

class PlayableMapGame extends FlameGame with KeyboardEvents {
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required this.projectFilePath,
    SaveData? saveData,
    GameSaveRepository? saveRepository,
    this.bundleTransformer,
    this.runtimeCutscenes = const <RuntimeCutsceneAsset>[],
  })  : _bundle = bundle,
        _gameState = normalizeLoadedGameState(
          saveData == null
              ? const GameState(saveId: 'default')
              : gameStateFromSaveData(saveData),
        ),
        _saveRepo = saveRepository ?? FileGameSaveRepository() {
    if (bundleTransformer != null) {
      _bundle = bundleTransformer!(_bundle);
    }
    _saveGameUseCase = SaveGameUseCase(_saveRepo);
    _loadGameUseCase = LoadGameUseCase(_saveRepo);
  }

  final String projectFilePath;
  final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
  final List<RuntimeCutsceneAsset> runtimeCutscenes;
  RuntimeMapBundle _bundle;
  GameState _gameState;
  late GameplayWorldState _world;
  late PlayerComponent _player;
  String _activeMapId = '';
  String? _previousMapId;
  _RuntimeFlowPhase _flowPhase = _RuntimeFlowPhase.overworld;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  LogicalKeyboardKey? _lastMoveKey;
  TriggeredWarp? _pendingWarp;
  TriggeredConnection? _pendingConnection;
  BattleStartRequest? _pendingBattleRequest;
  PlacedElementInteracted? _pendingPlacedElementBehavior;
  DialogueOverlayComponent? _dialogueOverlay;
  BattleTransitionOverlayComponent? _battleTransitionOverlay;
  BattleOverlayComponent? _battleOverlay;
  WarpTransitionOverlayComponent? _warpTransitionOverlay;
  TextComponent? _notification;
  final List<OverworldActorComponent> _npcActors = [];
  final Map<String, _LoadedPlayableMap> _loadedMapsById = {};
  final Map<String, Future<_LoadedPlayableMap?>> _loadMapFutureById = {};
  final math.Random _encounterRandom = math.Random();
  final GridPathfinder _followPathfinder = const GridPathfinder();
  final RuntimeBattleSetupMapper _battleSetupMapper =
      const RuntimeBattleSetupMapper();
  final BattleBackgroundResolver _battleBackgroundResolver =
      const BattleBackgroundResolver();
  final PlacedBehaviorCooldownGate _placedBehaviorCooldownGate =
      PlacedBehaviorCooldownGate();
  final StoryFlagsManager _storyFlags = const StoryFlagsManager();
  final RuntimeStoryBranching _storyBranching = const RuntimeStoryBranching();
  final ScenarioRuntimeExecutor _scenarioRuntime =
      const ScenarioRuntimeExecutor();

  /// Cache de l’index Step Studio ↔ cutscenes locales (invalidé quand [_bundle] change).
  StepCompletionCutsceneIndex? _cachedStepCompletionIndex;
  RuntimeMapBundle? _cachedStepCompletionBundleForIndex;

  /// Cache des `worldChanges` parsés (une entrée par ligne JSON) pour le manifeste courant.
  List<StepStudioWorldPresenceRule> _cachedStepStudioWorldRules =
      const <StepStudioWorldPresenceRule>[];
  ProjectManifest? _cachedStepStudioWorldRulesManifest;

  void _ensureStepStudioWorldRulesForManifest(ProjectManifest manifest) {
    if (identical(_cachedStepStudioWorldRulesManifest, manifest)) {
      return;
    }
    _cachedStepStudioWorldRulesManifest = manifest;
    _cachedStepStudioWorldRules =
        buildStepStudioWorldPresenceRuleList(manifest.scenarios);
  }

  late final CutsceneRuntimeRunner _cutsceneRunner =
      _buildCutsceneRuntimeRunner();
  CutsceneChoiceRequest? _pendingCutsceneChoiceRequest;
  ScriptedEntityMovementController? _scriptedEntityMovementController;
  final Map<String, GridPos> _runtimeNpcPositions = <String, GridPos>{};
  // Réservations temporaires d'occupation pour PNJ scriptés en cours de pas.
  //
  // Frontière intentionnelle:
  // - `GameplayWorldState` reste la source canonique des positions *commitées*.
  // - pendant une interpolation visuelle d'un pas PNJ, on réserve aussi les
  //   cellules de destination pour éviter les traversées joueur<->PNJ / PNJ<->PNJ.
  final Map<String, Set<GridPos>> _scriptedNpcReservedOccupiedCellsByEntity =
      <String, Set<GridPos>>{};
  double _runtimeClockMs = 0;
  double _lastWaterRequiresSurfMessageAtMs = -1000000000;
  void Function()? _pendingPostDialogueAction;
  bool _awaitingSurfConfirmation = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showBehaviorDebugOverlay = false;
  bool _showFpsOverlay = false;
  TextComponent? _behaviorDebugOverlay;
  TextComponent? _fpsOverlay;
  double _fpsAccumulatorSeconds = 0.0;
  int _fpsFrameCount = 0;
  double _currentFps = 0.0;
  String _lastBehaviorDebugLine = 'Aucun behavior déclenché';
  GridPos? _debugTileMarkerPos;
  String? _debugTileMarkerLabel;
  RectangleComponent? _debugTileMarkerFill;
  RectangleComponent? _debugTileMarkerBorder;
  TextComponent? _debugTileMarkerText;
  final Map<String, _NpcCollisionDebugVisual> _npcCollisionDebugByEntityId =
      <String, _NpcCollisionDebugVisual>{};

  ScriptRuntimeController? _activeScriptController;
  bool _isAwaitingScriptResume = false;
  Set<String> _activeScenarioTriggerIds = <String>{};
  _PendingScenarioFollowRequest? _pendingScenarioFollowRequest;
  _PendingScenarioTransitionMapRequest? _pendingScenarioTransitionMapRequest;
  final Map<String, _PendingScenarioNpcWarpEntry>
      _pendingScenarioNpcWarpEntries = <String, _PendingScenarioNpcWarpEntry>{};
  final Map<String, _PendingScenarioMoveContinuation>
      _pendingScenarioMoveContinuationsByEntity =
      <String, _PendingScenarioMoveContinuation>{};
  // File d'attente des scénarios ayant atteint `end` mais dont la complétion
  // doit attendre la fin réelle des effets runtime visibles.
  final List<_PendingScenarioReachedEnd> _pendingScenarioReachedEndQueue =
      <_PendingScenarioReachedEnd>[];
  String? _lastScenarioCompletionBlockReason;

  // Save/Load system
  final GameSaveRepository _saveRepo;
  late SaveGameUseCase _saveGameUseCase;
  late LoadGameUseCase _loadGameUseCase;

  // Battle system (map_battle integration)
  BattleSession? _battleSession;
  RuntimeActiveBattleContext? _activeBattleContext;

  // Battle flow hardening
  bool _isBattleResolving =
      false; // Lock pour empêcher spam clavier pendant résolution

  // Line of Sight (LoS) trainer detection
  final Set<String> _triggeredTrainerBattles = {}; // Anti-retrigger lock

  bool get showCollisionOverlay => _showCollisionOverlay;

  void setCollisionOverlayVisible(bool visible) {
    _showCollisionOverlay = visible;
    for (final loaded in _loadedMapsById.values) {
      loaded.backgroundLayers.showCollisionOverlay = visible;
    }
  }

  bool get showNpcCollisionDebugOverlay => _showNpcCollisionDebugOverlay;

  void setNpcCollisionDebugOverlayVisible(bool visible) {
    _showNpcCollisionDebugOverlay = visible;
    if (!isLoaded) {
      return;
    }
    _syncNpcCollisionDebugOverlay();
  }

  bool get showBehaviorDebugOverlay => _showBehaviorDebugOverlay;
  bool get showFpsOverlay => _showFpsOverlay;
  double get currentFps => _currentFps;

  /// Active/désactive l'affichage du compteur FPS dans le viewport runtime.
  ///
  /// Ce toggle est utilisé par l'example host pour un contrôle manuel.
  /// Le compteur est volontairement optionnel pour éviter toute pollution
  /// visuelle par défaut.
  void setFpsOverlayVisible(bool visible) {
    _showFpsOverlay = visible;
    if (!_showFpsOverlay) {
      _fpsOverlay?.removeFromParent();
      _fpsOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureFpsOverlay();
  }

  MovementMode get playerMovementMode {
    if (isLoaded) {
      return _world.player.movementMode;
    }
    return _gameState.playerMovementMode;
  }

  bool get isSurfing => playerMovementMode == MovementMode.surf;

  ({String mapId, int playerX, int playerY, String facing, String movementMode})
      get saveLoadInfo {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return (
      mapId: _gameState.currentMapId,
      playerX: _gameState.playerPosition.x,
      playerY: _gameState.playerPosition.y,
      facing: _gameState.playerFacing.name,
      movementMode: _gameState.playerMovementMode.name,
    );
  }

  GameState get gameStateSnapshot {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return _gameState;
  }

  @visibleForTesting
  String get debugFlowPhaseName => _flowPhase.name;

  @visibleForTesting
  void debugApplyBattleOutcomeForTest({
    required RuntimeActiveBattleContext context,
    required BattleOutcome outcome,
  }) {
    // Seam de test volontairement fin :
    // - on ne contourne pas la logique réelle de fin de combat ;
    // - on évite en revanche de devoir piloter tout l'overlay Flame au clavier
    //   pour prouver les garanties lot 15 ;
    // - le runtime garde donc un point d'entrée stable pour tester le write-back
    //   + la reprise overworld sans créer d'API produit parallèle.
    _activeBattleContext = context;
    _flowPhase = _RuntimeFlowPhase.battle;
    _onBattleFinished(outcome);
  }

  @visibleForTesting
  void debugSetPlayerStateForTest({
    required GridPos position,
    required Direction facing,
    MovementMode movementMode = MovementMode.walk,
  }) {
    // Petit seam de test volontaire :
    // - il permet de placer le joueur sur une cellule précise avant un scénario
    //   de reprise runtime ;
    // - il évite d'écrire un test d'input Flame plus fragile que la logique que
    //   l'on cherche réellement à prouver ici ;
    // - il ne sert pas au produit, uniquement à valider la cohérence du lot 15.
    _world = _world.withPlayer(
      _world.player.copyWith(
        pos: position,
        facing: facing,
        movementMode: movementMode,
      ),
    );
    _player.syncState(_world.player, snapToGrid: true);
    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    _syncCameraToPlayer();
  }

  void _syncGameStateFromWorld({String? mapIdOverride}) {
    final mapId = mapIdOverride ?? _activeMapId;
    _gameState = _gameState.copyWith(
      currentMapId: mapId,
      playerPosition: _world.player.pos,
      playerFacing: _world.player.facing.asFacing,
      playerMovementMode: _world.player.movementMode,
    );
  }

  /// Filtre spatial PNJ : d’abord [MapEntityNpcData.visibilityRule], puis
  /// les `worldChanges` Step Studio (même [mapId] / [entity.id] que l’authoring).
  ///
  /// Les règles Step Studio sont relues via [_ensureStepStudioWorldRulesForManifest]
  /// **à chaque évaluation** pour éviter une liste [worldRules] capturée une fois
  /// et obsolète si le cache manifeste est invalidé.
  NpcMapPresencePredicate _npcPresencePredicateFor(ProjectManifest manifest) {
    return (String mapId, MapEntity npcEntity) {
      _ensureStepStudioWorldRulesForManifest(manifest);
      return isNpcRuntimePresentOnMap(
        gameState: _gameState,
        manifest: manifest,
        stepStudioWorldRules: _cachedStepStudioWorldRules,
        mapId: mapId,
        entity: npcEntity,
      );
    };
  }

  /// Dialogue effectif : variantes ordonnées puis dialogue par défaut du PNJ.
  DialogueRef? _resolveNpcDialogueRef(MapEntity entity) {
    final npc = entity.npc;
    if (npc == null) {
      return null;
    }
    return MapEntityRuntimePredicateEvaluator(
      gameState: _gameState,
      chapterIndex:
          buildGlobalStoryChapterStepIndex(_bundle.manifest.scenarios),
    ).resolveNpcDialogue(npc);
  }

  void _refreshWorldNpcPresence() {
    if (!isLoaded) {
      return;
    }
    _world = _world.withNpcMapPresencePredicate(
      _npcPresencePredicateFor(_bundle.manifest),
    );
    // Retirer les acteurs Flame des PNJ désormais absents (évite toute dérive
    // visuelle / hit test si un composant repasse « visible » par défaut).
    _detachAbsentNpcActorsFromAllLoadedMaps();
    _syncNpcRenderVisibility();
    _syncNpcCollisionDebugOverlay();
    // Patrouilles / réservations / LoS trainer : mêmes règles que le gameplay
    // (un PNJ « absent » ne doit plus consommer ces systèmes parallèles).
    _stopGameplaySideEffectsForAbsentNpcs();
  }

  /// Retire les [OverworldActorComponent] pour tout PNJ avec personnage dont le
  /// prédicat de présence est faux (cartes chargées / voisines incluses).
  void _detachAbsentNpcActorsFromAllLoadedMaps() {
    for (final loaded in _loadedMapsById.values) {
      final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
      final mapId = loaded.bundle.map.id;
      final toRemove = <String>[];
      for (final entity in loaded.bundle.map.entities) {
        if (entity.kind != MapEntityKind.npc) {
          continue;
        }
        final charId = resolveNpcCharacterId(entity, loaded.bundle.manifest);
        if (charId == null || charId.isEmpty) {
          continue;
        }
        if (npcPred(mapId, entity)) {
          continue;
        }
        if (loaded.npcActorByEntityId.containsKey(entity.id)) {
          toRemove.add(entity.id);
        }
      }
      for (final rawId in toRemove) {
        final id = rawId.trim();
        if (id.isEmpty) {
          continue;
        }
        _scriptedEntityMovementController?.stopPatrol(id);
        _scriptedEntityMovementController?.untrackEntity(id);
        _scriptedNpcReservedOccupiedCellsByEntity.remove(id);
        _runtimeNpcPositions.remove(id);
        _triggeredTrainerBattles.remove(id);
        if (_pendingScenarioFollowRequest?.leaderEntityId == id) {
          _pendingScenarioFollowRequest = null;
        }
        _pendingScenarioNpcWarpEntries.remove(id);
        _pendingScenarioMoveContinuationsByEntity.remove(id);
        _purgeMountedNpcActorForEntity(entityId: id, loaded: loaded);
      }
    }
  }

  void _purgeMountedNpcActorForEntity({
    required String entityId,
    required _LoadedPlayableMap loaded,
  }) {
    final actor = loaded.npcActorByEntityId.remove(entityId);
    if (actor != null) {
      loaded.npcActors.remove(actor);
      _npcActors.remove(actor);
      actor.removeFromParent();
    }
    final visual = _npcCollisionDebugByEntityId.remove(entityId);
    visual?.spriteRect.removeFromParent();
    visual?.collisionRect.removeFromParent();
    visual?.anchorMarker.removeFromParent();
  }

  /// Arrête tout effet runtime **hors** [GameplayWorldState] qui pourrait encore
  /// cibler un PNJ filtré par [NpcMapPresencePredicate] (patrouille, réservation
  /// de cases, lock trainer).
  void _stopGameplaySideEffectsForAbsentNpcs() {
    final controller = _scriptedEntityMovementController;
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (pred(mapId, entity)) {
        continue;
      }
      controller?.stopPatrol(entity.id);
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entity.id);
      _runtimeNpcPositions.remove(entity.id);
      _triggeredTrainerBattles.remove(entity.id);
    }
    _applyNpcOverworldDefaultMovement();
  }

  void _syncNpcRenderVisibility() {
    for (final loaded in _loadedMapsById.values) {
      _applyNpcVisibilityToLoadedMap(loaded);
    }
  }

  void _applyNpcVisibilityToLoadedMap(_LoadedPlayableMap loaded) {
    final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
    loaded.backgroundLayers.npcMapPresencePredicate = npcPred;
    loaded.foregroundLayers.npcMapPresencePredicate = npcPred;
    for (final entity in loaded.bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final present = npcPred(loaded.bundle.map.id, entity);
      // Trace "source de vérité -> rendu" :
      // on journalise la décision finale de présence pour chaque PNJ afin de
      // diagnostiquer rapidement un cas "la règle existe mais l'acteur reste visible".
      debugPrint(
        '[step_studio_trace] npc_presence_applied map=${loaded.bundle.map.id} entity=${entity.id} present=$present',
      );
      loaded.npcActorByEntityId[entity.id]?.setGameplayVisible(present);
    }
  }

  RuntimeMapBundle _resolveRuntimeBundle(RuntimeMapBundle bundle) {
    final transform = bundleTransformer;
    if (transform == null) {
      return bundle;
    }
    return transform(bundle);
  }

  void setPlayerMovementMode(MovementMode movementMode) {
    if (!isLoaded) {
      return;
    }
    if (_world.player.movementMode == movementMode) {
      return;
    }
    _world = _world.withPlayer(
      _world.player.copyWith(movementMode: movementMode),
    );
    _syncGameStateFromWorld();
    _player.syncState(_world.player);
  }

  void setSurfingEnabled(bool enabled) {
    setPlayerMovementMode(enabled ? MovementMode.surf : MovementMode.walk);
  }

  /// Lance un déplacement scripté ponctuel pour un PNJ.
  ///
  /// API runtime publique pensée pour une future orchestration cutscene:
  /// - start movement
  /// - poll status
  /// - wait until completed/failed
  ScriptedEntityMovementStatus startScriptedNpcMove({
    required String entityId,
    required GridPos destination,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        targetPos: destination,
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.moveEntityTo(
      entityId: entityId,
      destination: destination,
    );
  }

  /// Active une patrouille simple (waypoints) pour un PNJ.
  ScriptedEntityMovementStatus startScriptedNpcPatrol({
    required String entityId,
    required List<GridPos> waypoints,
    bool loop = true,
    int pauseDurationMs = 0,
    int stepDurationMs = 200,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.startPatrol(
      ScriptedEntityPatrolRoute(
        entityId: entityId,
        waypoints: waypoints,
        loop: loop,
        pauseDurationMs: pauseDurationMs,
        stepDurationMs: stepDurationMs,
      ),
    );
  }

  void stopScriptedNpcPatrol(String entityId) {
    _scriptedEntityMovementController?.stopPatrol(entityId);
  }

  ScriptedEntityMovementStatus scriptedNpcMovementStatus(String entityId) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.statusOf(entityId);
  }

  /// true si une cutscene runtime est en cours d'exécution.
  bool get isCutsceneRunning => _cutsceneRunner.isRunning;

  /// Identifiant de la cutscene active, `null` si aucune.
  String? get activeCutsceneId => _cutsceneRunner.activeCutsceneId;

  /// Snapshot détaillé du runner cutscene.
  CutsceneRuntimeStatus get cutsceneStatus => _cutsceneRunner.status;

  /// Requête de choix en attente (si la cutscene attend une décision joueur).
  CutsceneChoiceRequest? get pendingCutsceneChoiceRequest =>
      _pendingCutsceneChoiceRequest;

  bool get hasPendingCutsceneChoice => _pendingCutsceneChoiceRequest != null;

  /// Dernier choix résolu pendant la cutscene active.
  CutsceneChoiceResult? get lastCutsceneChoiceResult =>
      _cutsceneRunner.lastChoiceResult;

  /// Démarre une cutscene fournie explicitement.
  ///
  /// Cette API est utile pour des déclenchements runtime directs (tests,
  /// scripts d'initialisation, futur bridge Step -> Cutscene).
  bool startCutscene(RuntimeCutsceneAsset cutscene) {
    if (!isLoaded) {
      return false;
    }
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  /// Démarre une cutscene depuis le registre runtime injecté au game host.
  ///
  /// Retourne `false` si l'ID est introuvable ou si une cutscene est déjà active.
  bool startCutsceneById(String cutsceneId) {
    if (!isLoaded) {
      return false;
    }
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final cutscene = _findRuntimeCutsceneById(normalized);
    if (cutscene == null) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  bool resolvePendingCutsceneChoiceByIndex(int selectedIndex) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByIndex(selectedIndex);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  bool resolvePendingCutsceneChoiceByValue(String selectedValue) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByValue(selectedValue);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  void setBehaviorDebugOverlayVisible(bool visible) {
    _showBehaviorDebugOverlay = visible;
    if (!visible) {
      _behaviorDebugOverlay?.removeFromParent();
      _behaviorDebugOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureBehaviorDebugOverlay();
  }

  void setDebugTileMarker({
    required GridPos? position,
    String? label,
  }) {
    _debugTileMarkerPos = position;
    _debugTileMarkerLabel = label;
    if (!isLoaded) {
      return;
    }
    _applyDebugTileMarker();
  }

  @override
  Future<void> onLoad() async {
    try {
      _world = GameplayWorldState.fromMap(
        _bundle.map,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
      debugPrint(
        '[runtime] Map loaded: ${_bundle.map.id}, spawn at (${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } on GameplaySpawnResolutionException catch (e) {
      debugPrint(
          '[runtime] Spawn resolution failed ($e), falling back to (0,0)');
      _world = GameplayWorldState.initial(
        map: _bundle.map,
        playerPos: const GridPos(x: 0, y: 0),
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
    }
    final images =
        await loadTilesetImagesById(_bundle.tilesetAbsolutePathsById);
    _activeMapId = _bundle.map.id;
    final rootMap = await _mountLoadedMap(
      bundle: _bundle,
      tileImagesById: images,
      originCellX: 0,
      originCellY: 0,
    );
    final playerChar = _resolvePlayerCharacter(_bundle);
    _player = PlayerComponent(
      bundle: _bundle,
      state: _world.player,
      characterEntry: playerChar,
      tileImages: images,
      mapOrigin: _originPixelsOf(rootMap),
    );
    await world.add(_player);
    _syncGameStateFromWorld();
    _configureCameraViewport();
    _syncCameraToPlayer();
    _preloadActiveMapConnections();
    _ensureBehaviorDebugOverlay();
    _ensureFpsOverlay();
    _applyDebugTileMarker();
    _resetScriptedNpcMovementController();
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
    );
    return super.onLoad();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;
    final key = event.logicalKey;

    // IMPORTANT: Handle battle phase FIRST before movement keys
    // Otherwise arrow keys will be captured by movement handler
    if (_flowPhase == _RuntimeFlowPhase.battle) {
      // Navigation dans les choix du combat
      // ↑/↓ pour naviguer, E/Space/Enter pour valider, Escape pour fuir
      final overlay = _battleOverlay;
      if (overlay != null) {
        // ↑ : sélection précédente (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowUp && event is KeyDownEvent) {
          final changed = overlay.moveSelectionUp();
          debugPrint('[battle] ArrowUp pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // ↓ : sélection suivante (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowDown && event is KeyDownEvent) {
          final changed = overlay.moveSelectionDown();
          debugPrint('[battle] ArrowDown pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // E / Space / Enter : validation du choix sélectionné
        // CRITICAL: Only process KeyDownEvent, NOT KeyRepeatEvent!
        // KeyRepeatEvent is sent when key is held down, which causes multiple validations
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.enter)) {
          // CRITICAL: Re-check phase AFTER getting into this block
          // Because the phase might have changed during this same key event processing
          // (e.g., last attack of the battle finished it)
          if (_flowPhase != _RuntimeFlowPhase.battle) {
            debugPrint(
                '[battle] Validate key pressed but phase changed to $_flowPhase, IGNORING');
            return KeyEventResult.ignored;
          }
          // Also check if overlay is still valid (might have been removed)
          if (_battleOverlay == null) {
            debugPrint(
                '[battle] Validate key pressed but overlay is null, IGNORING');
            return KeyEventResult.ignored;
          }
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint(
              '[battle] Validate key pressed (E/Space/Enter), selectedChoice=$selectedChoice');
          final validated = overlay.validateSelectedChoice();
          debugPrint('[battle] validateSelectedChoice returned=$validated');
          return KeyEventResult.handled;
        }
        // Escape : tentative de fuite (seulement si l'action est disponible)
        if (event is KeyDownEvent && key == LogicalKeyboardKey.escape) {
          // Vérifier si l'action "Fuir" est disponible dans les choix
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint('[battle] Escape pressed, selectedChoice=$selectedChoice');
          if (selectedChoice is PlayerBattleChoiceRun) {
            overlay.validateSelectedChoice();
            debugPrint('[battle] Escape validated (run selected)');
            return KeyEventResult.handled;
          }
          // Si "Fuir" n'est pas sélectionné, ne rien faire
          debugPrint('[battle] Escape ignored (run not selected)');
          return KeyEventResult.ignored;
        }
      } else {
        debugPrint('[battle] Keyboard event but overlay is null!');
      }
      return KeyEventResult.ignored;
    }

    // Pendant une cutscene active en overworld, on bloque les entrées joueur
    // directes (déplacement/interact) pour garder la scène déterministe.
    if (isCutsceneRunning && _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Déplacement scripté joueur (scénario / cutscene): pas d’entrées clavier.
    if (_suppressOverworldInputForScriptedPlayerMovement() &&
        _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Handle movement keys (but NOT during battle)
    if (_isMovementKey(key)) {
      if (_flowPhase == _RuntimeFlowPhase.dialogue) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        if ((_dialogueOverlay?.isShowingChoices ?? false) && isDown) {
          if (key == LogicalKeyboardKey.arrowUp) {
            _moveChoiceCursor(-1);
          } else if (key == LogicalKeyboardKey.arrowDown) {
            _moveChoiceCursor(1);
          }
        }
        return KeyEventResult.handled;
      }
      if (_flowPhase != _RuntimeFlowPhase.overworld) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (isDown) {
        _pressedKeys.add(key);
        _lastMoveKey = key;
      } else if (isUp) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
      }
      return KeyEventResult.handled;
    }

    if (_flowPhase == _RuntimeFlowPhase.mapTransition ||
        _flowPhase == _RuntimeFlowPhase.battleTransition) {
      return KeyEventResult.ignored;
    }
    if (!isDown) return KeyEventResult.ignored;

    if (_flowPhase == _RuntimeFlowPhase.dialogue) {
      final overlay = _dialogueOverlay!;
      if (overlay.isShowingChoices) {
        if (key == LogicalKeyboardKey.arrowUp) {
          _moveChoiceCursor(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _moveChoiceCursor(1);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _confirmDialogueChoice();
          return KeyEventResult.handled;
        }
      } else {
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _advanceDialogue();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.keyE || key == LogicalKeyboardKey.space)) {
      _handleInteract();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateFps(dt);
    _runtimeClockMs += dt * 1000;
    _placedBehaviorCooldownGate.prune(nowMs: _runtimeClockMs);
    _updateActorDepthOrdering();
    _syncCameraToPlayer();
    _syncNpcCollisionDebugOverlay();

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }

    final pendingWarp = _pendingWarp;
    if (pendingWarp != null && !_player.isStepping) {
      _pendingWarp = null;
      _handleWarp(pendingWarp);
      return;
    }

    final pendingConnection = _pendingConnection;
    if (pendingConnection != null && !_player.isStepping) {
      _pendingConnection = null;
      _handleConnection(pendingConnection);
      return;
    }

    final pendingBattleRequest = _pendingBattleRequest;
    if (pendingBattleRequest != null && !_player.isStepping) {
      _pendingBattleRequest = null;
      _startBattleHandoff(pendingBattleRequest);
      return;
    }

    final pendingPlacedElementBehavior = _pendingPlacedElementBehavior;
    if (pendingPlacedElementBehavior != null && !_player.isStepping) {
      _pendingPlacedElementBehavior = null;
      _executePlacedElementBehavior(
        element: pendingPlacedElementBehavior.element,
        behavior: pendingPlacedElementBehavior.behavior,
        trigger: pendingPlacedElementBehavior.trigger,
      );
      return;
    }

    // Tick du système de déplacement scripté PNJ.
    //
    // Ce tick reste dans le flux overworld pour ce MVP:
    // - pas d'exécution pendant dialogue/battle transition;
    // - base propre pour un futur "wait movement" en cutscene.
    _scriptedEntityMovementController?.update(dt);
    _processPendingScenarioNpcWarpEntries();
    _processPendingScenarioMoveContinuations();
    _processPendingScenarioFollowRequest();
    _processPendingScenarioTransitionMapRequest();
    _processPendingScenarioReachedEndCompletions();

    // Tick runner cutscene MVP (séquentiel).
    _cutsceneRunner.update(dt);
    _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    if (isCutsceneRunning) {
      // Tant que la cutscene n'est pas terminée, on ne laisse pas la boucle
      // input joueur déplacer le player.
      return;
    }

    _driveMovement();
  }

  void _updateActorDepthOrdering() {
    _player.priority = 1000 + _player.footPoint.y.round();
    for (final actor in _npcActors) {
      actor.priority = 1000 + actor.depthSortY.round();
    }
  }

  bool _isMovementKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyD;
  }

  GameplayIntent? _intentFromPressedKeys() {
    Direction? dirFor(LogicalKeyboardKey key) {
      if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
        return Direction.north;
      }
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.keyS) {
        return Direction.south;
      }
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.keyA) {
        return Direction.west;
      }
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.keyD) {
        return Direction.east;
      }
      return null;
    }

    final preferred = _lastMoveKey;
    if (preferred != null && _pressedKeys.contains(preferred)) {
      final d = dirFor(preferred);
      if (d != null) {
        return MoveIntent(d);
      }
    }

    for (final key in _pressedKeys) {
      final d = dirFor(key);
      if (d != null) {
        return MoveIntent(d);
      }
    }
    return null;
  }

  void _driveMovement() {
    if (_suppressOverworldInputForScriptedPlayerMovement()) {
      _clearPressedMovementKeys();
      return;
    }
    if (_player.isStepping) {
      return;
    }

    final intent = _intentFromPressedKeys();
    if (intent == null) {
      _player.syncState(_world.player);
      return;
    }
    final attemptedDirection = intent is MoveIntent ? intent.direction : null;
    final attemptedX = attemptedDirection == null
        ? null
        : _world.player.pos.x + attemptedDirection.dx;
    final attemptedY = attemptedDirection == null
        ? null
        : _world.player.pos.y + attemptedDirection.dy;
    final attemptedOutOfBounds = attemptedX != null &&
        attemptedY != null &&
        (attemptedX < 0 ||
            attemptedY < 0 ||
            attemptedX >= _world.map.size.width ||
            attemptedY >= _world.map.size.height);

    // Collision runtime stricte contre les destinations PNJ réservées.
    //
    // Sans ce garde-fou, un joueur peut entrer dans la case cible d'un PNJ en
    // interpolation (avant commit canonique), créant un effet de traversée.
    if (attemptedDirection != null &&
        attemptedX != null &&
        attemptedY != null &&
        _isCellReservedByScriptedNpc(
          GridPos(x: attemptedX, y: attemptedY),
        )) {
      _world =
          _world.withPlayer(_world.player.copyWith(facing: attemptedDirection));
      _player.syncState(_world.player);
      return;
    }

    final previousPlayerPos = _world.player.pos;
    final result = stepGameplayWorld(_world, intent);
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);

    if (result is Blocked) {
      if (result.reason == GameplayMovementBlockReason.waterRequiresSurf) {
        _handleWaterBlocked();
      }
      if (attemptedOutOfBounds && attemptedDirection != null) {
        final direction = switch (attemptedDirection) {
          Direction.north => MapConnectionDirection.north,
          Direction.south => MapConnectionDirection.south,
          Direction.east => MapConnectionDirection.east,
          Direction.west => MapConnectionDirection.west,
        };
        debugPrint(
          '[connection] no connection for direction=${direction.name} map=${_bundle.map.id}',
        );
      }
      _player.syncState(_world.player);
      return;
    }

    if (result is Moved) {
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _checkStepEncounter();
      _checkTrainerLineOfSight(); // Check LoS only when player position changes
      _dispatchScenarioTriggerEnterFromMovement(
        previousPos: previousPlayerPos,
        currentPos: _world.player.pos,
      );
      return;
    }

    if (result is WarpTriggered) {
      if (result.warp.triggerMode == MapWarpTriggerMode.onEnter) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player, snapToGrid: true);
      }
      _pendingWarp = result.warp;
      debugPrint(
        '[warp] Triggered warp ${result.warp.warpId} mode=${result.warp.triggerMode.name} -> map=${result.warp.targetMapId} pos=(${result.warp.targetPos.x}, ${result.warp.targetPos.y})',
      );
      return;
    }

    if (result is ConnectionTriggered) {
      _player.syncState(_world.player);
      _pendingConnection = result.connection;
      debugPrint(
        '[connection] exit detected map=${_bundle.map.id} direction=${result.connection.direction.name} target=${result.connection.targetMapId} offset=${result.connection.offset} source=(${result.connection.sourcePos.x}, ${result.connection.sourcePos.y})',
      );
      return;
    }

    if (result is PlacedElementInteracted) {
      final isMovementTrigger =
          result.trigger == MapPlacedElementTriggerType.onEnter ||
              result.trigger == MapPlacedElementTriggerType.onExit ||
              result.trigger == MapPlacedElementTriggerType.onNear;
      if (isMovementTrigger) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player);
      }
      _pendingPlacedElementBehavior = result;
      final behaviorId = result.behavior.id.trim().isEmpty
          ? 'legacy'
          : result.behavior.id.trim();
      debugPrint(
        '[placed_behavior] queued trigger=${result.trigger.name} scope=${result.behavior.triggerScope.name} instance=${result.element.id} behavior=$behaviorId effect=${result.behavior.effect.type.name}',
      );
      _updateBehaviorDebugLine(
        'Queued ${result.trigger.name}/${result.behavior.triggerScope.name} · ${result.behavior.effect.type.name} · ${result.element.id}#$behaviorId',
      );
      return;
    }
  }

  void _checkStepEncounter() {
    final encounterKind = _world.player.movementMode == MovementMode.surf
        ? EncounterKind.surf
        : EncounterKind.walk;
    final pos = _world.player.pos;
    debugPrint(
      '[encounter] checking at x=${pos.x} y=${pos.y} kind=${encounterKind.name}',
    );
    final check = checkEncounterAtPlayerPosition(
      world: _world,
      project: _bundle.manifest,
      encounterKind: encounterKind,
      random: _encounterRandom,
      policy: _kEncounterPolicy,
    );
    _logEncounterCheck(check);
    if (!check.triggered) {
      return;
    }
    final encounter = check.encounter;
    if (encounter == null) {
      return;
    }
    final request = buildBattleStartRequestFromEncounter(
      encounter: encounter,
      world: _world,
    );
    _pendingBattleRequest = request;
    debugPrint(
      '[battle] battle request created kind=${request.kind.name} source=${request.source.name} requestId=${request.requestId}',
    );
    debugPrint(
      '[battle] wild payload species=${encounter.speciesId} level=${encounter.level} map=${encounter.mapId} zone=${encounter.zoneId}',
    );
  }

  /// Détecte les entrées dans des triggers de map pour alimenter les sources
  /// scénario `sourceTriggerEnter`.
  ///
  /// Le calcul est local et déterministe:
  /// - on lit les triggers couvrant l'ancienne position,
  /// - on lit les triggers couvrant la nouvelle position,
  /// - on déclenche uniquement les IDs présents dans "nouvelle - ancienne".
  void _dispatchScenarioTriggerEnterFromMovement({
    required GridPos previousPos,
    required GridPos currentPos,
  }) {
    // On privilégie l'état mémorisé pour éviter de recalculer l'ancienne
    // couverture à chaque tick. Un fallback de sécurité reste possible.
    final previousIds = _activeScenarioTriggerIds.isEmpty
        ? _scenarioRuntime.triggerIdsAtPosition(
            map: _bundle.map,
            pos: previousPos,
          )
        : _activeScenarioTriggerIds;
    final currentIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: currentPos,
    );
    _activeScenarioTriggerIds = currentIds;
    final enteredIds =
        currentIds.difference(previousIds).toList(growable: false)..sort();
    for (final triggerId in enteredIds) {
      _dispatchScenarioRuntimeSource(
        ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: _activeMapId,
          triggerId: triggerId,
        ),
      );
    }
  }

  /// Point d'entrée unique pour les déclenchements runtime du Scenario Graph.
  ///
  /// Cette méthode centralise:
  /// - le guard de phase (overworld/script actif),
  /// - l'appel à l'exécuteur scénario,
  /// - le branchement vers les effets runtime (dialogue/script/message),
  /// - la synchronisation de GameState lorsque le flow mutera des flags.
  ScenarioRuntimeExecutionResult _dispatchScenarioRuntimeSource(
    ScenarioRuntimeSourceEvent sourceEvent,
  ) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: flow is not in overworld phase.',
      );
    }
    final activeScript = _activeScriptController;
    if (activeScript != null && !activeScript.isTerminated) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: a script is already running.',
      );
    }
    final scenarios = _bundle.manifest.scenarios;
    if (scenarios.isEmpty) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'No scenario available in current manifest.',
      );
    }

    final result = _scenarioRuntime.dispatch(
      scenarios: scenarios,
      sourceEvent: sourceEvent,
      context: _buildScenarioRuntimeExecutionContext(),
    );

    // Step Studio : on ne complète pas sur "flow reached end" uniquement.
    // La completion est validée quand les effets runtime visibles sont terminés.
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'dispatch:${sourceEvent.type.name}',
    );

    // On maintient une trace explicite en logs pour faciliter le debug.
    if (result.status == ScenarioRuntimeExecutionStatus.noMatchingSource) {
      return result;
    }
    debugPrint(
      '[scenario_runtime] source=${sourceEvent.type.name} map=${sourceEvent.mapId} trigger=${sourceEvent.triggerId ?? '-'} entity=${sourceEvent.entityId ?? '-'} status=${result.status.name} scenario=${result.scenarioId ?? '-'} sourceNode=${result.sourceNodeId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
    return result;
  }

  /// Contexte partagé dispatch / continuation : inclut le filtre Step Studio
  /// pour ne pas relancer une cutscene locale dont la step est déjà complétée.
  ScenarioRuntimeExecutionContext _buildScenarioRuntimeExecutionContext() {
    return ScenarioRuntimeExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      shouldSkipScenario: _shouldSkipLocalScenarioForCompletedStep,
      openDialogue: _openScenarioDialogueById,
      runScript: _runScenarioScriptById,
      showMessage: (message) => _showNotification(message),
      moveCharacter: ({
        required entityId,
        required targetKind,
        required targetId,
        required waitForCompletion,
        runtimeSourceId,
      }) {
        return _runScenarioMoveCharacter(
          entityId: entityId,
          targetKind: targetKind,
          targetId: targetId,
          waitForCompletion: waitForCompletion,
          runtimeSourceId: runtimeSourceId,
        );
      },
      followCharacter: ({
        required leaderEntityId,
      }) {
        return _runScenarioFollowCharacter(leaderEntityId: leaderEntityId);
      },
      faceCharacter: ({
        required entityId,
        required direction,
      }) {
        return _runScenarioFaceCharacter(
          entityId: entityId,
          direction: direction,
        );
      },
      transitionMap: ({
        required mapId,
        required warpId,
      }) {
        return _runScenarioTransitionMap(
          mapId: mapId,
          warpId: warpId,
        );
      },
    );
  }

  /// Index Step Studio mis en cache tant que le bundle courant est inchangé
  /// (évite de re-parser le JSON à chaque déclencheur).
  StepCompletionCutsceneIndex _stepCompletionIndexForCurrentBundle() {
    if (!identical(_cachedStepCompletionBundleForIndex, _bundle)) {
      _cachedStepCompletionBundleForIndex = _bundle;
      _cachedStepCompletionIndex =
          buildStepCompletionCutsceneIndex(_bundle.manifest.scenarios);
    }
    return _cachedStepCompletionIndex!;
  }

  /// Si la cutscene [scenarioId] est la condition de fin d’une step déjà
  /// enregistrée dans [PlayerProgression.completedStepIds], on ignore ce
  /// scénario pour permettre à un autre candidat de matcher (ou aucun).
  bool _shouldSkipLocalScenarioForCompletedStep(String scenarioId) {
    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId == null) {
      return false;
    }
    return _gameState.progression.completedStepIds.contains(stepId);
  }

  /// Capture un résultat scénario et décide si la completion doit être :
  /// - appliquée immédiatement;
  /// - ou différée jusqu'à la fin réelle des effets runtime visibles.
  void _handleScenarioRuntimeCompletionResult(
    ScenarioRuntimeExecutionResult result, {
    required String origin,
  }) {
    if (result.status != ScenarioRuntimeExecutionStatus.reachedEnd) {
      return;
    }
    final scenarioId = result.scenarioId?.trim();
    if (scenarioId == null || scenarioId.isEmpty) {
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason == null) {
      _applyScenarioReachedEndCompletion(
          scenarioId: scenarioId, origin: origin);
      return;
    }
    for (final pending in _pendingScenarioReachedEndQueue) {
      if (pending.scenarioId == scenarioId) {
        debugPrint(
          '[step_studio_trace] completion_deferred_duplicate scenario=$scenarioId origin=$origin reason="$blockingReason"',
        );
        return;
      }
    }
    _pendingScenarioReachedEndQueue.add(
      _PendingScenarioReachedEnd(
        scenarioId: scenarioId,
        origin: origin,
        queuedAtMs: _runtimeClockMs,
      ),
    );
    debugPrint(
      '[step_studio_trace] completion_deferred scenario=$scenarioId origin=$origin reason="$blockingReason"',
    );
  }

  /// Applique réellement la completion progression pour un scénario qui a
  /// atteint `end` ET dont la mise en scène runtime est terminée.
  void _applyScenarioReachedEndCompletion({
    required String scenarioId,
    required String origin,
  }) {
    var progression = _gameState.progression;
    var changed = false;

    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId != null) {
      debugPrint(
        '[step_studio_trace] runtime_mark_step_completed_candidate scenario=$scenarioId step=$stepId before=${progression.completedStepIds}',
      );
      final nextSteps = appendCompletedStepIdIfAbsent(
        progression.completedStepIds,
        stepId,
      );
      if (!identical(nextSteps, progression.completedStepIds)) {
        progression = progression.copyWith(completedStepIds: nextSteps);
        changed = true;
        debugPrint(
          '[step_studio] step "$stepId" completed (cutscene "$scenarioId" reached end).',
        );
        debugPrint(
          '[step_studio_trace] runtime_completed_steps_updated scenario=$scenarioId step=$stepId after=${progression.completedStepIds}',
        );
      }
    }

    ScenarioAsset? scenarioAsset;
    for (final s in _bundle.manifest.scenarios) {
      if (s.id == scenarioId) {
        scenarioAsset = s;
        break;
      }
    }
    if (scenarioAsset != null &&
        scenarioAsset.scope == ScenarioScope.localEventFlow) {
      final nextCut = appendCompletedCutsceneIdIfAbsent(
        progression.completedCutsceneIds,
        scenarioId,
      );
      if (!identical(nextCut, progression.completedCutsceneIds)) {
        progression = progression.copyWith(completedCutsceneIds: nextCut);
        changed = true;
        debugPrint(
          '[runtime] local scenario "$scenarioId" marked completed (predicate cutsceneCompleted).',
        );
      }
    }

    if (changed) {
      _gameState = _gameState.copyWith(progression: progression);
      _refreshWorldNpcPresence();
    }
    debugPrint(
      '[step_studio_trace] completion_applied scenario=$scenarioId origin=$origin completedSteps=${_gameState.progression.completedStepIds} completedCutscenes=${_gameState.progression.completedCutsceneIds}',
    );
  }

  /// Retourne la raison bloquante empêchant de finaliser la cutscene.
  ///
  /// Tant qu'une raison existe, on ne matérialise pas les effects de progression
  /// (`completedStepIds`, `completedCutsceneIds`).
  String? _scenarioCompletionBlockingReason() {
    return scenarioRuntimeCompletionBlockingReason(
      isOverworldFlow: _flowPhase == _RuntimeFlowPhase.overworld,
      flowPhaseName: _flowPhase.name,
      isDialogueOpen: _dialogueOverlay != null,
      isCutsceneRunnerActive: isCutsceneRunning,
      hasPendingFollowCharacter: _pendingScenarioFollowRequest != null,
      hasPendingMoveContinuations:
          _pendingScenarioMoveContinuationsByEntity.isNotEmpty,
      hasPendingNpcWarpEntries: _pendingScenarioNpcWarpEntries.isNotEmpty,
      hasPendingTransitionMapRequest:
          _pendingScenarioTransitionMapRequest != null,
      hasPendingRuntimeWarp: _pendingWarp != null,
      hasPendingRuntimeConnection: _pendingConnection != null,
      isPlayerStepInProgress: _player.isStepping,
    );
  }

  /// Dès que les effets visibles sont terminés, on applique les complétions
  /// différées dans l'ordre d'arrivée.
  void _processPendingScenarioReachedEndCompletions() {
    if (_pendingScenarioReachedEndQueue.isEmpty) {
      _lastScenarioCompletionBlockReason = null;
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason != null) {
      if (_lastScenarioCompletionBlockReason != blockingReason) {
        debugPrint(
          '[step_studio_trace] completion_gate_blocked reason="$blockingReason" queue=${_pendingScenarioReachedEndQueue.length}',
        );
        _lastScenarioCompletionBlockReason = blockingReason;
      }
      return;
    }
    if (_lastScenarioCompletionBlockReason != null) {
      debugPrint(
        '[step_studio_trace] completion_gate_unblocked queue=${_pendingScenarioReachedEndQueue.length}',
      );
      _lastScenarioCompletionBlockReason = null;
    }
    final pendingItems =
        List<_PendingScenarioReachedEnd>.from(_pendingScenarioReachedEndQueue);
    _pendingScenarioReachedEndQueue.clear();
    for (final pending in pendingItems) {
      final waitMs = (_runtimeClockMs - pending.queuedAtMs).round();
      debugPrint(
        '[step_studio_trace] completion_deferred_flush scenario=${pending.scenarioId} waitedMs=$waitMs origin=${pending.origin}',
      );
      _applyScenarioReachedEndCompletion(
        scenarioId: pending.scenarioId,
        origin: 'deferred:${pending.origin}',
      );
    }
  }

  /// Ouvre un dialogue projet à partir d'un `dialogueId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _openScenarioDialogueById(
    String dialogueId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedDialogueId = dialogueId.trim();
    if (normalizedDialogueId.isEmpty) {
      return false;
    }
    final opened = _tryOpenDialogue(
      runtimeSourceId ?? 'scenario',
      DialogueRef(
        dialogueId: normalizedDialogueId,
        startNode: startNode,
      ),
      'Dialogue introuvable: $normalizedDialogueId',
    );
    if (opened && runtimeSourceId != null && runtimeSourceId.isNotEmpty) {
      _scheduleScenarioContinuationAfterDialogue(runtimeSourceId);
    }
    return opened;
  }

  void _scheduleScenarioContinuationAfterDialogue(String runtimeSourceId) {
    if (!runtimeSourceId.startsWith('scenario:')) {
      return;
    }
    final previous = _pendingPostDialogueAction;
    _pendingPostDialogueAction = () {
      previous?.call();
      _resumeScenarioAfterRuntimeSource(runtimeSourceId);
    };
  }

  void _resumeScenarioAfterRuntimeSource(String runtimeSourceId) {
    final parts = runtimeSourceId.split(':');
    if (parts.length != 4) {
      return;
    }
    final scenarioId = parts[1].trim();
    final sourceNodeId = parts[2].trim();
    final resumeAfterNodeId = parts[3].trim();
    if (scenarioId.isEmpty ||
        sourceNodeId.isEmpty ||
        resumeAfterNodeId.isEmpty) {
      return;
    }
    final result = _scenarioRuntime.dispatchContinuation(
      scenarios: _bundle.manifest.scenarios,
      scenarioId: scenarioId,
      sourceNodeId: sourceNodeId,
      resumeAfterNodeId: resumeAfterNodeId,
      context: _buildScenarioRuntimeExecutionContext(),
    );
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'continuation:$runtimeSourceId',
    );
    debugPrint(
      '[scenario_runtime] continuation source=$runtimeSourceId status=${result.status.name} scenario=${result.scenarioId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
  }

  bool _runScenarioMoveCharacter({
    required String entityId,
    required String targetKind,
    required String targetId,
    required bool waitForCompletion,
    String? runtimeSourceId,
  }) {
    final trimmedEntity = entityId.trim();
    if (trimmedEntity == 'player') {
      _scriptedEntityMovementController?.syncTrackedEntityPosition(
        trimmedEntity,
        _world.player.pos,
      );
    }
    final destination = _resolveScenarioMoveTarget(
      targetKind: targetKind,
      targetId: targetId,
    );
    if (destination == null) {
      debugPrint(
        '[scenario_runtime] moveCharacter target unresolved kind=$targetKind targetId=$targetId',
      );
      return false;
    }
    var resolvedDestination = destination;
    var entityApproachCandidates = const <GridPos>[];
    if (targetKind == 'entity') {
      entityApproachCandidates = _resolveScenarioEntityApproachCandidates(
        moverEntityId: entityId,
        targetEntityId: targetId,
        primaryDestination: destination,
      );
      if (entityApproachCandidates.isEmpty) {
        debugPrint(
          '[scenario_runtime] moveCharacter entity target has no reachable adjacent cell entity=$entityId target=$targetId',
        );
        return false;
      }
      resolvedDestination = entityApproachCandidates.first;
    }
    var started = startScriptedNpcMove(
      entityId: entityId,
      destination: resolvedDestination,
    );
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        final fallbackCandidates = _resolveScenarioWarpApproachCandidates(
          entityId: entityId,
          warp: warp,
          primaryDestination: destination,
        );
        for (final candidate in fallbackCandidates) {
          final fallbackStarted = startScriptedNpcMove(
            entityId: entityId,
            destination: candidate,
          );
          if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
            resolvedDestination = candidate;
            started = fallbackStarted;
            debugPrint(
              '[scenario_runtime] moveCharacter warp fallback entity=$entityId warp=${warp.id} destination=(${candidate.x},${candidate.y})',
            );
            break;
          }
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'entity') {
      final fallbackCandidates = entityApproachCandidates.isNotEmpty
          ? entityApproachCandidates.skip(1)
          : _resolveScenarioEntityApproachCandidates(
              moverEntityId: entityId,
              targetEntityId: targetId,
              primaryDestination: destination,
            );
      for (final candidate in fallbackCandidates) {
        final fallbackStarted = startScriptedNpcMove(
          entityId: entityId,
          destination: candidate,
        );
        if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
          resolvedDestination = candidate;
          started = fallbackStarted;
          debugPrint(
            '[scenario_runtime] moveCharacter entity fallback entity=$entityId target=$targetId destination=(${candidate.x},${candidate.y})',
          );
          break;
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed) {
      debugPrint(
        '[scenario_runtime] moveCharacter failed entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y})',
      );
      return false;
    }
    if (targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        _pendingScenarioNpcWarpEntries[entityId] = _PendingScenarioNpcWarpEntry(
          entityId: entityId,
          warpId: warp.id,
          warpPos: warp.pos,
          approachPos: resolvedDestination,
        );
      }
    } else {
      _pendingScenarioNpcWarpEntries.remove(entityId);
    }
    if (waitForCompletion) {
      final runtimeSource = runtimeSourceId?.trim() ?? '';
      if (runtimeSource.startsWith('scenario:') && trimmedEntity.isNotEmpty) {
        _pendingScenarioMoveContinuationsByEntity[trimmedEntity] =
            _PendingScenarioMoveContinuation(
          entityId: trimmedEntity,
          runtimeSourceId: runtimeSource,
          targetKind: targetKind,
        );
      }
      debugPrint(
        '[scenario_runtime] moveCharacter started entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y}) waitForCompletion=true',
      );
    } else {
      _pendingScenarioMoveContinuationsByEntity.remove(trimmedEntity);
    }
    return true;
  }

  bool _runScenarioTransitionMap({
    required String mapId,
    required String warpId,
  }) {
    final normalizedMapId = mapId.trim();
    final normalizedWarpId = warpId.trim();
    if (normalizedMapId.isEmpty || normalizedWarpId.isEmpty) {
      debugPrint(
        '[scenario_runtime] transitionMap invalid mapId="$mapId" warpId="$warpId"',
      );
      return false;
    }
    _pendingScenarioTransitionMapRequest = _PendingScenarioTransitionMapRequest(
      mapId: normalizedMapId,
      warpId: normalizedWarpId,
    );
    debugPrint(
      '[scenario_runtime] transitionMap scheduled map=$normalizedMapId warp=$normalizedWarpId',
    );
    return true;
  }

  void _processPendingScenarioTransitionMapRequest() {
    final pending = _pendingScenarioTransitionMapRequest;
    if (pending == null) {
      return;
    }

    // On attend la fin du suivi (followCharacter) pour ne pas couper la scène.
    if (_pendingScenarioFollowRequest != null) {
      return;
    }
    if (_player.isStepping) {
      return;
    }

    _pendingScenarioTransitionMapRequest = null;
    unawaited(_executeScenarioTransitionMapRequest(pending));
  }

  Future<void> _executeScenarioTransitionMapRequest(
    _PendingScenarioTransitionMapRequest request,
  ) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint(
        '[scenario_runtime] transitionMap ignored: flow=${_flowPhase.name}',
      );
      return;
    }
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: request.mapId,
      );
      final targetBundle = _resolveRuntimeBundle(loadedBundle);
      MapWarp? targetWarp;
      for (final candidate in targetBundle.map.warps) {
        if (candidate.id == request.warpId) {
          targetWarp = candidate;
          break;
        }
      }
      if (targetWarp == null) {
        debugPrint(
          '[scenario_runtime] transitionMap failed: warp "${request.warpId}" not found on map "${request.mapId}"',
        );
        _showNotification('Transition impossible (warp introuvable)');
        return;
      }

      final transition = TriggeredWarp(
        warpId: 'scenario:${request.warpId}',
        targetMapId: targetBundle.map.id,
        targetPos: targetWarp.pos,
        triggerMode: MapWarpTriggerMode.onEnter,
      );
      debugPrint(
        '[scenario_runtime] transitionMap start map=${transition.targetMapId} warp=${request.warpId} pos=(${transition.targetPos.x},${transition.targetPos.y})',
      );
      await _handleWarp(transition);
    } catch (e, st) {
      debugPrint(
        '[scenario_runtime] transitionMap failed map=${request.mapId} warp=${request.warpId}: $e\n$st',
      );
      _showNotification('Transition impossible');
    }
  }

  MapWarp? _findMapWarpById(String warpId) {
    final normalized = warpId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final warp in _world.map.warps) {
      if (warp.id == normalized) {
        return warp;
      }
    }
    return null;
  }

  List<GridPos> _resolveScenarioWarpApproachCandidates({
    required String entityId,
    required MapWarp warp,
    required GridPos primaryDestination,
  }) {
    final currentPos = _resolveScenarioEntityPosition(entityId) ?? warp.pos;
    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};

    // Anneaux autour du warp: on essaie de rester proche de la porte tout en
    // respectant le footprint collision réel du PNJ (souvent 2x2).
    const maxRadius = 4;
    for (var radius = 1; radius <= maxRadius; radius++) {
      for (var dx = -radius; dx <= radius; dx++) {
        final top = GridPos(x: warp.pos.x + dx, y: warp.pos.y - radius);
        if (_addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: top,
          entityId: entityId,
        )) {
          // no-op
        }
        final bottom = GridPos(x: warp.pos.x + dx, y: warp.pos.y + radius);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: bottom,
          entityId: entityId,
        );
      }
      for (var dy = -radius + 1; dy <= radius - 1; dy++) {
        final left = GridPos(x: warp.pos.x - radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: left,
          entityId: entityId,
        );
        final right = GridPos(x: warp.pos.x + radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: right,
          entityId: entityId,
        );
      }
    }

    candidates.sort((a, b) {
      final aDoor = (a.x - warp.pos.x).abs() + (a.y - warp.pos.y).abs();
      final bDoor = (b.x - warp.pos.x).abs() + (b.y - warp.pos.y).abs();
      if (aDoor != bDoor) {
        return aDoor.compareTo(bDoor);
      }
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      return aCurrent.compareTo(bCurrent);
    });
    return candidates;
  }

  List<GridPos> _resolveScenarioEntityApproachCandidates({
    required String moverEntityId,
    required String targetEntityId,
    required GridPos primaryDestination,
  }) {
    final currentPos =
        _resolveScenarioEntityPosition(moverEntityId) ?? primaryDestination;

    MapRect targetRect;
    if (targetEntityId == 'player') {
      targetRect = MapRect(
        pos: _world.player.pos,
        size: const GridSize(width: 1, height: 1),
      );
    } else {
      MapEntity? targetEntity;
      for (final entry in _world.map.entities) {
        if (entry.id == targetEntityId) {
          targetEntity = entry;
          break;
        }
      }
      if (targetEntity == null) {
        return const <GridPos>[];
      }
      targetRect = resolveEntityCollisionFootprint(targetEntity);
    }

    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};
    for (final cell in _adjacentCellsAroundRect(targetRect)) {
      if (!seen.add(cell)) {
        continue;
      }
      if (!_isWithinMapBounds(_world.map, cell)) {
        continue;
      }
      if (!_isScenarioNpcAnchorPassable(
          entityId: moverEntityId, anchor: cell)) {
        continue;
      }
      candidates.add(cell);
    }

    candidates.sort((a, b) {
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      if (aCurrent != bCurrent) {
        return aCurrent.compareTo(bCurrent);
      }
      final aTarget =
          (a.x - targetRect.pos.x).abs() + (a.y - targetRect.pos.y).abs();
      final bTarget =
          (b.x - targetRect.pos.x).abs() + (b.y - targetRect.pos.y).abs();
      return aTarget.compareTo(bTarget);
    });
    return candidates;
  }

  bool _addWarpApproachCandidate({
    required Set<GridPos> seen,
    required List<GridPos> out,
    required GridPos candidate,
    required String entityId,
  }) {
    if (!seen.add(candidate)) {
      return false;
    }
    if (!_isWithinMapBounds(_world.map, candidate)) {
      return false;
    }
    if (!_isScenarioNpcAnchorPassable(entityId: entityId, anchor: candidate)) {
      return false;
    }
    out.add(candidate);
    return true;
  }

  bool _isScenarioNpcAnchorPassable({
    required String entityId,
    required GridPos anchor,
  }) {
    if (entityId.trim() == 'player') {
      return _isPlayerScriptedMoveAnchorPassable(anchor);
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: anchor,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    return probe.passable;
  }

  bool _isPlayerScriptedMoveAnchorPassable(GridPos anchor) {
    final mode = _world.player.movementMode;
    if (_world.movementBlockReasonAt(
          x: anchor.x,
          y: anchor.y,
          movementMode: mode,
        ) !=
        null) {
      return false;
    }
    for (final cell
        in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
      if (cell.x == anchor.x && cell.y == anchor.y) {
        return false;
      }
    }
    return true;
  }

  GridPos? _resolveScenarioEntityPosition(String entityId) {
    if (entityId == 'player') {
      return _world.player.pos;
    }
    final runtimePos = _runtimeNpcPositions[entityId];
    if (runtimePos != null) {
      return runtimePos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == entityId) {
        return entity.pos;
      }
    }
    return null;
  }

  GridPos? _resolveScenarioMoveTarget({
    required String targetKind,
    required String targetId,
  }) {
    final map = _world.map;
    switch (targetKind) {
      case 'warp':
        for (final warp in map.warps) {
          if (warp.id == targetId) {
            return warp.pos;
          }
        }
        return null;
      case 'spawn':
        for (final entity in map.entities) {
          if (entity.kind == MapEntityKind.spawn && entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      case 'entity':
        if (targetId == 'player') {
          return _world.player.pos;
        }
        for (final entity in map.entities) {
          if (entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      default:
        return null;
    }
  }

  bool _suppressOverworldInputForScriptedPlayerMovement() {
    final status = scriptedNpcMovementStatus('player');
    return status.state == ScriptedEntityMovementState.moving;
  }

  void _clearPressedMovementKeys() {
    _pressedKeys.removeWhere(_isMovementKey);
    if (_lastMoveKey != null && !_pressedKeys.contains(_lastMoveKey!)) {
      _lastMoveKey = null;
    }
  }

  void _processPendingScenarioNpcWarpEntries() {
    if (_pendingScenarioNpcWarpEntries.isEmpty) {
      return;
    }
    final entityIds =
        _pendingScenarioNpcWarpEntries.keys.toList(growable: false)..sort();
    for (final entityId in entityIds) {
      final pending = _pendingScenarioNpcWarpEntries[entityId];
      if (pending == null) {
        continue;
      }
      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        debugPrint(
          '[scenario_runtime] npc warp canceled entity=$entityId warp=${pending.warpId} reason="${status.failureReason ?? 'move failed'}"',
        );
        _pendingScenarioNpcWarpEntries.remove(entityId);
        continue;
      }
      if (status.state != ScriptedEntityMovementState.completed) {
        final stillPresent = _resolveScenarioEntityPosition(entityId) != null;
        if (!stillPresent) {
          _pendingScenarioNpcWarpEntries.remove(entityId);
        }
        continue;
      }
      _pendingScenarioNpcWarpEntries.remove(entityId);
      _completeScenarioNpcWarpEntry(pending);
    }
  }

  void _processPendingScenarioMoveContinuations() {
    if (_pendingScenarioMoveContinuationsByEntity.isEmpty) {
      return;
    }
    final entityIds = _pendingScenarioMoveContinuationsByEntity.keys
        .toList(growable: false)
      ..sort();
    for (final entityId in entityIds) {
      final pending = _pendingScenarioMoveContinuationsByEntity[entityId];
      if (pending == null) {
        continue;
      }

      if (pending.targetKind == 'warp' && _pendingWarp != null) {
        // Le déplacement est "fini" uniquement après consommation effective du
        // warp joueur et retour en overworld.
        continue;
      }

      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        continue;
      }
      if (status.state == ScriptedEntityMovementState.completed ||
          status.state == ScriptedEntityMovementState.idle) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        _resumeScenarioAfterRuntimeSource(pending.runtimeSourceId);
      }
    }
  }

  void _completeScenarioNpcWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    if (pending.entityId.trim() == 'player') {
      _completeScenarioPlayerWarpEntry(pending);
      return;
    }
    final removed = _despawnNpcFromActiveMap(pending.entityId);
    if (!removed) {
      debugPrint(
        '[scenario_runtime] npc warp failed to remove entity=${pending.entityId} warp=${pending.warpId}',
      );
      return;
    }
    debugPrint(
      '[scenario_runtime] npc entered warp entity=${pending.entityId} warp=${pending.warpId} approach=(${pending.approachPos.x},${pending.approachPos.y})',
    );
  }

  void _completeScenarioPlayerWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    final warp = _findMapWarpById(pending.warpId);
    if (warp == null) {
      debugPrint(
        '[scenario_runtime] player warp failed: warp "${pending.warpId}" not found on map "${_bundle.map.id}"',
      );
      return;
    }
    _pendingWarp = TriggeredWarp(
      warpId: warp.id,
      targetMapId: warp.targetMapId,
      targetPos: warp.targetPos,
      triggerMode: warp.triggerMode,
    );
    debugPrint(
      '[scenario_runtime] player reached warp=${warp.id} -> map=${warp.targetMapId} target=(${warp.targetPos.x},${warp.targetPos.y})',
    );
  }

  bool _despawnNpcFromActiveMap(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == normalized);
    if (index < 0) {
      return false;
    }

    final updatedEntities = List<MapEntity>.from(entities)..removeAt(index);
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );

    final loaded = _loadedMapsById[_activeMapId];
    if (loaded != null) {
      _purgeMountedNpcActorForEntity(entityId: normalized, loaded: loaded);
    }

    _scriptedNpcReservedOccupiedCellsByEntity.remove(normalized);
    _runtimeNpcPositions.remove(normalized);
    _triggeredTrainerBattles.remove(normalized);
    if (_pendingScenarioFollowRequest?.leaderEntityId == normalized) {
      _pendingScenarioFollowRequest = null;
    }
    _pendingScenarioNpcWarpEntries.remove(normalized);
    _pendingScenarioMoveContinuationsByEntity.remove(normalized);
    _scriptedEntityMovementController?.untrackEntity(normalized);
    _syncGameStateFromWorld();
    return true;
  }

  bool _runScenarioFollowCharacter({
    required String leaderEntityId,
  }) {
    _pendingScenarioFollowRequest = _PendingScenarioFollowRequest(
      leaderEntityId: leaderEntityId,
      requestedAtMs: _runtimeClockMs,
    );
    debugPrint(
      '[scenario_runtime] followCharacter activated leader=$leaderEntityId',
    );
    // On traite la première itération immédiatement pour éviter un frame de latence.
    _processPendingScenarioFollowRequest();
    return true;
  }

  void _processPendingScenarioFollowRequest() {
    final pending = _pendingScenarioFollowRequest;
    if (pending == null) {
      return;
    }
    final leaderPos = _resolveScenarioLeaderPosition(pending.leaderEntityId);
    if (leaderPos == null) {
      debugPrint(
        '[scenario_runtime] followCharacter canceled leader unresolved=${pending.leaderEntityId}',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: pending.leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final leaderMovement = scriptedNpcMovementStatus(pending.leaderEntityId);
    final leaderTravelDirection = _resolveLeaderTravelDirection(
      pending: pending,
      leaderPos: leaderPos,
      movementStatus: leaderMovement,
    );
    final preferredTrailingSide = leaderTravelDirection == null
        ? null
        : _oppositeDirection(leaderTravelDirection);
    final playerPos = _world.player.pos;
    final playerAdjacentToLeader = _isPosAdjacentToRect(playerPos, leaderRect);

    // Condition de fin:
    // - leader immobile
    // - joueur déjà adjacent au footprint réel du leader.
    if (leaderMovement.state != ScriptedEntityMovementState.moving &&
        playerAdjacentToLeader) {
      debugPrint(
        '[scenario_runtime] followCharacter completed leader=${pending.leaderEntityId} player=(${playerPos.x},${playerPos.y})',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }

    // Si le joueur est déjà en interpolation, on attend le prochain tick.
    if (_player.isStepping) {
      return;
    }

    final canReuseCachedPath = pending.cachedPath != null &&
        pending.cachedPathDestination != null &&
        pending.cachedPathLeaderPos != null &&
        pending.cachedPathLeaderPos!.x == leaderPos.x &&
        pending.cachedPathLeaderPos!.y == leaderPos.y;
    if (canReuseCachedPath) {
      final nextPos = _nextFollowPathStep(
        path: pending.cachedPath!,
        currentPos: playerPos,
      );
      if (nextPos != null) {
        final stepped = _stepPlayerAlongFollowPath(
          leaderEntityId: pending.leaderEntityId,
          leaderPos: leaderPos,
          destination: pending.cachedPathDestination!,
          nextPos: nextPos,
          preferredTrailingSide: preferredTrailingSide,
        );
        if (stepped) {
          pending.consecutiveBlockedSteps = 0;
          return;
        }
        pending.consecutiveBlockedSteps += 1;
        _clearPendingFollowPathCache(pending);
        if (leaderMovement.state != ScriptedEntityMovementState.moving &&
            pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
        return;
      }
      _clearPendingFollowPathCache(pending);
    }

    final followPlan = _resolveFollowPathPlanNearLeader(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      preferredSide: preferredTrailingSide,
      strictPreferredSide:
          leaderMovement.state == ScriptedEntityMovementState.moving,
    );
    if (followPlan == null) {
      if (leaderMovement.state != ScriptedEntityMovementState.moving) {
        pending.consecutiveBlockedSteps += 1;
        if (pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled no reachable trailing path leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
      }
      return;
    }
    pending.consecutiveBlockedSteps = 0;

    // Si on est déjà au meilleur point, on attend la prochaine évolution leader.
    if (followPlan.path.length <= 1 ||
        (followPlan.destination.x == playerPos.x &&
            followPlan.destination.y == playerPos.y)) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    pending.cachedPath = followPlan.path;
    pending.cachedPathDestination = followPlan.destination;
    pending.cachedPathLeaderPos = leaderPos;
    final nextPos = _nextFollowPathStep(
      path: followPlan.path,
      currentPos: playerPos,
    );
    if (nextPos == null) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    final stepped = _stepPlayerAlongFollowPath(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      destination: followPlan.destination,
      nextPos: nextPos,
      preferredTrailingSide: preferredTrailingSide,
    );
    if (!stepped) {
      pending.consecutiveBlockedSteps += 1;
      _clearPendingFollowPathCache(pending);
      if (leaderMovement.state != ScriptedEntityMovementState.moving &&
          pending.consecutiveBlockedSteps >= 10) {
        debugPrint(
          '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
        );
        _pendingScenarioFollowRequest = null;
      }
    }
  }

  bool _stepPlayerAlongFollowPath({
    required String leaderEntityId,
    required GridPos leaderPos,
    required GridPos destination,
    required GridPos nextPos,
    required Direction? preferredTrailingSide,
  }) {
    final currentPos = _world.player.pos;
    final direction = _directionBetweenAdjacent(
      from: currentPos,
      to: nextPos,
    );
    if (direction == null) {
      debugPrint(
        '[scenario_runtime] followCharacter invalid non-adjacent path step leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }

    final result = stepGameplayWorld(_world, MoveIntent(direction));
    if (result is! Moved) {
      debugPrint(
        '[scenario_runtime] followCharacter path step blocked leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);
    _player.startStep(
      _world.player,
      durationSeconds: PlayerComponent.kDefaultStepSeconds,
    );
    _dispatchScenarioTriggerEnterFromMovement(
      previousPos: currentPos,
      currentPos: _world.player.pos,
    );
    debugPrint(
      '[scenario_runtime] followCharacter stepping leader=$leaderEntityId leaderPos=(${leaderPos.x},${leaderPos.y}) trailingSide=${preferredTrailingSide?.name ?? '-'} destination=(${destination.x},${destination.y}) next=(${nextPos.x},${nextPos.y}) playerPos=(${_world.player.pos.x},${_world.player.pos.y})',
    );
    return true;
  }

  bool _runScenarioFaceCharacter({
    required String entityId,
    required String direction,
  }) {
    final facing = _parseEntityFacing(direction);
    if (facing == null) {
      debugPrint(
        '[scenario_runtime] faceCharacter invalid direction="$direction"',
      );
      return false;
    }
    if (entityId == 'player') {
      final next =
          _world.player.copyWith(facing: _directionFromEntityFacing(facing));
      _world = _world.withPlayer(next);
      _syncGameStateFromWorld();
      _player.syncState(_world.player, snapToGrid: true);
      return true;
    }
    final normalizedEntityId = entityId.trim();
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[normalizedEntityId];
    if (actor != null) {
      final movement = scriptedNpcMovementStatus(normalizedEntityId);
      if (movement.state == ScriptedEntityMovementState.moving ||
          actor.isStepping) {
        debugPrint(
          '[scenario_runtime] faceCharacter deferred entity=$normalizedEntityId while moving',
        );
        return true;
      }
      actor.setMotion(facing, CharacterAnimationState.idle);
      return true;
    }

    // Tolérance runtime: si l’entité n’a pas d’acteur visuel actuellement
    // monté (ex: map context différente), on tente au moins de persister
    // l’orientation dans l’état map; sinon on ignore sans bloquer le flow.
    if (_setEntityFacingStateOnly(normalizedEntityId, facing)) {
      debugPrint(
        '[scenario_runtime] faceCharacter applied state-only entity="$normalizedEntityId"',
      );
      return true;
    }
    debugPrint(
      '[scenario_runtime] faceCharacter entity unresolved="$normalizedEntityId" (ignored)',
    );
    return true;
  }

  bool _setEntityFacingStateOnly(String entityId, EntityFacing facing) {
    if (entityId.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return false;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return false;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );
    _syncGameStateFromWorld();
    return true;
  }

  EntityFacing? _parseEntityFacing(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'north':
        return EntityFacing.north;
      case 'south':
        return EntityFacing.south;
      case 'east':
        return EntityFacing.east;
      case 'west':
        return EntityFacing.west;
      default:
        return null;
    }
  }

  Direction _directionFromEntityFacing(EntityFacing facing) {
    switch (facing) {
      case EntityFacing.north:
        return Direction.north;
      case EntityFacing.south:
        return Direction.south;
      case EntityFacing.east:
        return Direction.east;
      case EntityFacing.west:
        return Direction.west;
    }
  }

  GridPos? _resolveScenarioLeaderPosition(String leaderEntityId) {
    final movementStatus = scriptedNpcMovementStatus(leaderEntityId);
    if (movementStatus.entityId == leaderEntityId) {
      return movementStatus.currentPos;
    }
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[leaderEntityId];
    final actorGridPos = actor?.gridPos;
    if (actorGridPos != null) {
      return actorGridPos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        return entity.pos;
      }
    }
    return null;
  }

  _FollowPathPlan? _resolveFollowPathPlanNearLeader({
    required String leaderEntityId,
    required GridPos leaderPos,
    required Direction? preferredSide,
    required bool strictPreferredSide,
  }) {
    final currentPlayerPos = _world.player.pos;
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final candidates = <GridPos>[];
    final preferredCandidates = <GridPos>{};
    if (preferredSide != null) {
      final trailing = _cellsAlongRectSide(leaderRect, preferredSide).toList();
      candidates.addAll(trailing);
      preferredCandidates.addAll(trailing);
    }
    if (!strictPreferredSide) {
      candidates.addAll(_adjacentCellsAroundRect(leaderRect));
    }
    final deduplicated = candidates.toSet().toList(growable: false);
    deduplicated.sort((a, b) {
      final aPreferred = preferredCandidates.contains(a) ? 0 : 1;
      final bPreferred = preferredCandidates.contains(b) ? 0 : 1;
      if (aPreferred != bPreferred) {
        return aPreferred.compareTo(bPreferred);
      }
      final da =
          (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
      final db =
          (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
      return da.compareTo(db);
    });
    for (final candidate in deduplicated) {
      if (!_canPlacePlayerAt(candidate)) {
        continue;
      }
      final path = _computeFollowPlayerPath(
        start: currentPlayerPos,
        goal: candidate,
      );
      if (path == null) {
        continue;
      }
      return _FollowPathPlan(
        destination: candidate,
        path: path,
      );
    }

    // Si la cible "derrière" est impossible en déplacement, on autorise un
    // fallback adjacent pour éviter les blocages durs dans les couloirs.
    if (strictPreferredSide) {
      final relaxedCandidates =
          _adjacentCellsAroundRect(leaderRect).toSet().toList(growable: false);
      relaxedCandidates.sort((a, b) {
        final da =
            (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
        final db =
            (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
        return da.compareTo(db);
      });
      for (final candidate in relaxedCandidates) {
        if (!_canPlacePlayerAt(candidate)) {
          continue;
        }
        final path = _computeFollowPlayerPath(
          start: currentPlayerPos,
          goal: candidate,
        );
        if (path == null) {
          continue;
        }
        return _FollowPathPlan(
          destination: candidate,
          path: path,
        );
      }
    }

    if (_isPosAdjacentToRect(currentPlayerPos, leaderRect) &&
        _canPlacePlayerAt(currentPlayerPos)) {
      return _FollowPathPlan(
        destination: currentPlayerPos,
        path: <GridPos>[currentPlayerPos],
      );
    }
    return null;
  }

  List<GridPos>? _computeFollowPlayerPath({
    required GridPos start,
    required GridPos goal,
  }) {
    final result = _followPathfinder.findPath(
      bounds: _world.map.size,
      start: start,
      goal: goal,
      isPassable: (x, y) {
        if (x == start.x && y == start.y) {
          return true;
        }
        final cell = GridPos(x: x, y: y);
        if (!_isWithinMapBounds(_world.map, cell)) {
          return false;
        }
        if (_isCellReservedByScriptedNpc(cell)) {
          return false;
        }
        final trial = _world.withPlayer(_world.player.copyWith(pos: cell));
        return !trial.isBlocked(x, y);
      },
    );
    if (!result.foundPath) {
      return null;
    }
    return result.path;
  }

  Direction? _directionBetweenAdjacent({
    required GridPos from,
    required GridPos to,
  }) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    if (dx == 0 && dy == -1) return Direction.north;
    if (dx == 0 && dy == 1) return Direction.south;
    if (dx == 1 && dy == 0) return Direction.east;
    if (dx == -1 && dy == 0) return Direction.west;
    return null;
  }

  GridPos? _nextFollowPathStep({
    required List<GridPos> path,
    required GridPos currentPos,
  }) {
    if (path.length < 2) {
      return null;
    }
    final currentIndex = path.indexWhere(
      (cell) => cell.x == currentPos.x && cell.y == currentPos.y,
    );
    if (currentIndex < 0 || currentIndex + 1 >= path.length) {
      return null;
    }
    return path[currentIndex + 1];
  }

  void _clearPendingFollowPathCache(_PendingScenarioFollowRequest pending) {
    pending.cachedPath = null;
    pending.cachedPathDestination = null;
    pending.cachedPathLeaderPos = null;
  }

  MapRect _resolveScenarioLeaderCollisionFootprint({
    required String leaderEntityId,
    required GridPos fallbackAnchor,
  }) {
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        final footprint = resolveEntityCollisionFootprint(entity);
        final offsetX = footprint.pos.x - entity.pos.x;
        final offsetY = footprint.pos.y - entity.pos.y;
        return MapRect(
          pos: GridPos(
            x: fallbackAnchor.x + offsetX,
            y: fallbackAnchor.y + offsetY,
          ),
          size: footprint.size,
        );
      }
    }
    return MapRect(
      pos: fallbackAnchor,
      size: const GridSize(width: 1, height: 1),
    );
  }

  Iterable<GridPos> _adjacentCellsAroundRect(MapRect rect) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final yielded = <GridPos>{};

    for (var x = left; x <= right; x++) {
      final north = GridPos(x: x, y: top - 1);
      if (yielded.add(north)) {
        yield north;
      }
      final south = GridPos(x: x, y: bottom + 1);
      if (yielded.add(south)) {
        yield south;
      }
    }
    for (var y = top; y <= bottom; y++) {
      final west = GridPos(x: left - 1, y: y);
      if (yielded.add(west)) {
        yield west;
      }
      final east = GridPos(x: right + 1, y: y);
      if (yielded.add(east)) {
        yield east;
      }
    }
  }

  Iterable<GridPos> _cellsAlongRectSide(MapRect rect, Direction side) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    switch (side) {
      case Direction.north:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: top - 1);
        }
      case Direction.south:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: bottom + 1);
        }
      case Direction.east:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: right + 1, y: y);
        }
      case Direction.west:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: left - 1, y: y);
        }
    }
  }

  Direction? _resolveLeaderTravelDirection({
    required _PendingScenarioFollowRequest pending,
    required GridPos leaderPos,
    required ScriptedEntityMovementStatus movementStatus,
  }) {
    final previous = pending.lastLeaderPos;
    pending.lastLeaderPos = leaderPos;
    if (previous != null) {
      final dx = leaderPos.x - previous.x;
      final dy = leaderPos.y - previous.y;
      final fromDelta = _directionFromDelta(dx, dy);
      if (fromDelta != null) {
        pending.lastLeaderTravelDirection = fromDelta;
        return fromDelta;
      }
    }
    if (movementStatus.state == ScriptedEntityMovementState.moving &&
        movementStatus.targetPos != null) {
      final target = movementStatus.targetPos!;
      final dx = target.x - leaderPos.x;
      final dy = target.y - leaderPos.y;
      final fromTargetVector = _directionFromDelta(dx, dy);
      if (fromTargetVector != null) {
        pending.lastLeaderTravelDirection = fromTargetVector;
        return fromTargetVector;
      }
    }
    return pending.lastLeaderTravelDirection;
  }

  Direction? _directionFromDelta(int dx, int dy) {
    if (dx == 0 && dy == 0) {
      return null;
    }
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? Direction.east : Direction.west;
    }
    return dy >= 0 ? Direction.south : Direction.north;
  }

  Direction _oppositeDirection(Direction direction) {
    switch (direction) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }

  bool _isPosAdjacentToRect(GridPos pos, MapRect rect) {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final isInside =
        pos.x >= left && pos.x <= right && pos.y >= top && pos.y <= bottom;
    if (isInside) {
      return false;
    }
    final dx =
        pos.x < left ? left - pos.x : (pos.x > right ? pos.x - right : 0);
    final dy =
        pos.y < top ? top - pos.y : (pos.y > bottom ? pos.y - bottom : 0);
    return math.max(dx, dy) == 1;
  }

  bool _canPlacePlayerAt(GridPos pos) {
    if (!_isWithinMapBounds(_world.map, pos)) {
      return false;
    }
    final trial = _world.withPlayer(_world.player.copyWith(pos: pos));
    return !trial.isBlocked(pos.x, pos.y);
  }

  /// Lance un script projet à partir d'un `scriptId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _runScenarioScriptById(
    String scriptId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedScriptId = scriptId.trim();
    if (normalizedScriptId.isEmpty) {
      return false;
    }
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      return false;
    }
    ScriptAsset? scriptAsset;
    for (final entry in _bundle.manifest.scripts) {
      if (entry.id == normalizedScriptId) {
        scriptAsset = entry.asset;
        break;
      }
    }
    if (scriptAsset == null) {
      debugPrint('[scenario_runtime] script not found: $normalizedScriptId');
      return false;
    }
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: startNode,
      runtimeSourceId: runtimeSourceId ?? 'scenario',
    );
    return true;
  }

  void _logEncounterCheck(GameplayEncounterCheckResult check) {
    final kind = check.encounterKind?.name ?? EncounterKind.walk.name;
    switch (check.status) {
      case GameplayEncounterCheckStatus.noZone:
        debugPrint('[encounter] no compatible zone');
        return;
      case GameplayEncounterCheckStatus.noEncounterTableId:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} has no encounter table id (kind=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.encounterTableNotFound:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} not found',
        );
        return;
      case GameplayEncounterCheckStatus.encounterKindMismatch:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} kind mismatch (expected=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.emptyEncounterTable:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} has no valid entries',
        );
        return;
      case GameplayEncounterCheckStatus.rollFailed:
        debugPrint(
          '[encounter] matched zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'}',
        );
        debugPrint(
          '[encounter] rolled no encounter roll=${check.roll?.toStringAsFixed(3) ?? 'n/a'}',
        );
        return;
      case GameplayEncounterCheckStatus.triggered:
        final encounter = check.encounter;
        if (encounter == null) {
          debugPrint('[encounter] triggered status without payload');
          return;
        }
        debugPrint(
          '[encounter] matched zone=${encounter.zoneId} table=${encounter.tableId}',
        );
        debugPrint(
          '[encounter] triggered species=${encounter.speciesId} level=${encounter.level} kind=${encounter.encounterKind.name}',
        );
        return;
    }
  }

  /// Démarre le handoff de combat.
  ///
  /// [request] - La requête de combat (wild ou trainer).
  ///
  /// Cette méthode :
  /// 1. Stocke la requête pour le mapping vers BattleSetup
  /// 2. Passe en phase battleTransition
  /// 3. Affiche l'overlay de transition
  void _startBattleHandoff(BattleStartRequest request) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }
    _flowPhase = _RuntimeFlowPhase.battleTransition;
    _notification?.removeFromParent();
    _notification = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    debugPrint(
      '[battle] transition started requestId=${request.requestId} kind=${request.kind.name}',
    );
    final overlay = BattleTransitionOverlayComponent(
      request: request,
      viewportSize: camera.viewport.size,
      onFinished: () {
        // Le mapping vers BattleSetup peut maintenant lire le vrai projet et
        // échouer explicitement. On déclenche donc l'ouverture de manière async
        // au lieu de supposer qu'un setup placeholder sera toujours disponible.
        unawaited(_openBattleOverlay(request));
      },
    );
    camera.viewport.add(overlay);
    _battleTransitionOverlay = overlay;
  }

  /// Ouvre l'overlay de combat après la transition.
  ///
  /// [request] - La requête de combat.
  ///
  /// Cette méthode :
  /// 1. Mappe BattleStartRequest → BattleSetup
  /// 2. Crée la BattleSession
  /// 3. Affiche BattleOverlayComponent avec la session
  Future<void> _openBattleOverlay(BattleStartRequest request) async {
    if (_flowPhase != _RuntimeFlowPhase.battleTransition) {
      return;
    }
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    try {
      // BE10 recadré élargit légèrement cet invariant runtime :
      // - on mémorise toujours le slot actif exact utilisé au handoff ;
      // - mais on mémorise aussi l'ordre actif + réserves réellement injecté
      //   dans le combat ;
      // - cela permet ensuite un write-back honnête si le joueur switch.
      //
      // Pourquoi ici :
      // - la sélection se fait sur le vrai GameState runtime, juste avant le
      //   mapping vers BattleSetup ;
      // - on réutilise ensuite ce mapping stable au moment du write-back ;
      // - on évite ainsi le bug classique "recalculer le premier Pokémon
      //   jouable après le combat", qui casserait la cohérence dès qu'un
      //   switch a déplacé l'actif.
      final playerLineup =
          _battleSetupMapper.selectPlayerBattleLineup(_gameState.party);

      // Le lot 9 remplace enfin le setup placeholder par un mapping réel
      // depuis la save runtime et les données projet.
      final setup = await _toBattleSetup(
        request,
        playerPartyIndex: playerLineup.activeIndex,
      );

      // Lot 12 pose le premier write runtime honnête du "seen" :
      // l'espèce ennemie n'est marquée vue qu'une fois le handoff réellement
      // résolu et le combat effectivement prêt à s'ouvrir.
      //
      // On évite volontairement de marquer plus tôt :
      // - une simple case d'herbe ne suffit pas ;
      // - un setup qui échoue ne doit rien écrire ;
      // - aucune capture n'est ouverte ici.
      _gameState = markSpeciesSeenInGameState(
        _gameState,
        setup.enemyPokemon.speciesId,
      );
      _flowPhase = _RuntimeFlowPhase.battle;

      // Lot 4 garde le routing de difficulté côté runtime :
      // - la donnée produit vit sur le trainer du projet ;
      // - `map_battle` ne doit recevoir qu'une policy déjà choisie ;
      // - `battle_session.dart` ne redevient donc pas le cerveau de la
      //   difficulté.
      final opponentPolicy = resolveRuntimeTrainerOpponentPolicy(
        request: request,
        manifest: _bundle.manifest,
      );

      // Créer la session de combat
      _battleSession = createBattleSession(
        setup,
        opponentPolicy: opponentPolicy,
      );
      _activeBattleContext = RuntimeActiveBattleContext(
        request: request,
        playerPartyIndex: playerLineup.activeIndex,
        playerPartySlotIndicesByLineupIndex: playerLineup.lineupPartyIndices,
      );

      // Lot 2 garde la résolution de fond intégralement côté runtime :
      // - le battle-core n'a aucune connaissance de décor ;
      // - on se limite au contexte déjà disponible ici (request + map active) ;
      // - on n'introduit pas encore de resolver contextuel plus large que ce
      //   besoin visible immédiat.
      final backgroundSpec = _battleBackgroundResolver.resolve(
        request: request,
        bundle: _bundle,
      );

      // Afficher l'overlay de combat avec la session
      final overlay = BattleOverlayComponent(
        session: _battleSession!,
        viewportSize: camera.viewport.size,
        backgroundSpec: backgroundSpec,
        onPlayerChoice: _onPlayerBattleChoice,
      );
      camera.viewport.add(overlay);
      _battleOverlay = overlay;
      debugPrint(
        '[battle] overlay opened requestId=${request.requestId} kind=${request.kind.name}',
      );
    } on RuntimeBattleSetupException catch (error) {
      _cancelBattleHandoff(
        userMessage: error.message,
        debugDetails: error.debugDetails,
      );
    } catch (error, stackTrace) {
      _cancelBattleHandoff(
        userMessage:
            'Impossible de démarrer le combat avec les données locales du projet.',
        debugDetails: '$error\n$stackTrace',
      );
    }
  }

  /// Mappe BattleStartRequest → BattleSetup.
  ///
  /// [request] - La requête de combat depuis le runtime.
  ///
  /// Retourne un BattleSetup pur pour le moteur de combat.
  Future<BattleSetup> _toBattleSetup(
    BattleStartRequest request, {
    int? playerPartyIndex,
  }) {
    return _battleSetupMapper.map(
      bundle: _bundle,
      gameState: _gameState,
      request: request,
      playerPartyIndex: playerPartyIndex,
    );
  }

  void _cancelBattleHandoff({
    required String userMessage,
    String? debugDetails,
  }) {
    // On nettoie explicitement tout état battle partiellement initialisé.
    // Ce helper évite qu'un mapping KO laisse le runtime coincé en transition.
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _activeBattleContext = null;
    _isBattleResolving = false;
    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint(
      '[battle] handoff cancelled message="$userMessage" details=${debugDetails ?? 'n/a'}',
    );
    _showNotification(userMessage);
  }

  /// Gère le choix du joueur pendant le combat.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode :
  /// 1. Applique le choix via BattleSession.applyChoice()
  /// 2. Met à jour l'UI
  /// 3. Vérifie si le combat est fini
  /// 4. Si fini, appelle _onBattleFinished()
  ///
  /// **Lock anti-spam** : `_isBattleResolving` empêche le spam clavier
  /// pendant la résolution d'un tour.
  void _onPlayerBattleChoice(PlayerBattleChoice choice) {
    if (_battleSession == null) {
      return;
    }

    // Lock anti-spam : empêcher traitement multiple pendant résolution
    if (_isBattleResolving) {
      debugPrint('[battle] choice ignored: already resolving');
      return;
    }
    _isBattleResolving = true;

    try {
      // Appliquer le choix (retourne une nouvelle session immutable)
      _battleSession = _battleSession!.applyChoice(choice);

      // Mettre à jour l'UI avec le nouvel état
      final overlay = _battleOverlay;
      overlay?.updateState(_battleSession!);

      // Vérifier si le combat est fini
      if (_battleSession!.state.isFinished) {
        _onBattleFinished(_battleSession!.state.outcome!);
      }
    } finally {
      // Unlock après résolution (ou après fin de combat)
      // Si combat fini, _onBattleFinished() va reset l'état de toute façon
      if (_flowPhase == _RuntimeFlowPhase.battle) {
        _isBattleResolving = false;
      }
    }
  }

  /// Gère la fin du combat.
  ///
  /// [outcome] - Le résultat du combat.
  ///
  /// Cette méthode :
  /// 1. Applique le résultat au vrai GameState runtime
  /// 2. Nettoie l'overlay (SUPPRIME du parent)
  /// 3. Retourne à l'overworld
  void _onBattleFinished(BattleOutcome outcome) {
    debugPrint('[battle] battle finished outcome=${outcome.type.name}');

    // Le lot 10 normalise ici tout le write-back post-combat :
    // - PV du lineup joueur écrits sur les slots exacts mémorisés ;
    // - flag trainer_defeated uniquement sur une vraie victoire trainer ;
    // - aucune tentative de recalcul du Pokémon actif après la fin du combat.
    final activeBattleContext = _activeBattleContext;
    if (activeBattleContext != null) {
      final previousState = _gameState;
      _gameState = applyRuntimeBattleOutcomeToGameState(
        gameState: _gameState,
        context: activeBattleContext,
        outcome: outcome,
        storyFlagsManager: _storyFlags,
      );

      if (outcome.isDefeat) {
        _applyWhiteoutLiteAfterPlayerDefeat(
          activeBattleContext,
          activePlayerLineupIndex: outcome.finalState.player.lineupIndex,
        );
      }

      if (outcome.isVictory &&
          activeBattleContext.request is TrainerBattleStartRequest) {
        final trainerRequest =
            activeBattleContext.request as TrainerBattleStartRequest;
        debugPrint(
          '[battle] trainer marked as defeated: ${trainerRequest.trainerId}',
        );
      }

      // On ne refresh la présence PNJ que si les story flags ont réellement
      // changé ; cela garde le retour overworld minimal pour wild/defeat/run.
      if (!identical(previousState.storyFlags, _gameState.storyFlags) &&
          previousState.storyFlags != _gameState.storyFlags) {
        _refreshWorldNpcPresence();
      }
    }

    // Nettoyer et retourner à l'overworld
    // IMPORTANT: Il faut SUPPRIMER l'overlay du parent, pas juste mettre à null
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _activeBattleContext = null;
    _isBattleResolving = false; // Reset lock anti-spam

    // NOTE: NE PAS clear _triggeredTrainerBattles ici!
    // Le lock doit rester actif tant que le joueur est dans la LoS du trainer.
    // Si on clear le lock ici, le trainer sera re-déclenché immédiatement
    // car le joueur est probablement encore dans sa zone de LoS.
    //
    // Le lock sera clear automatiquement quand le joueur quittera la LoS,
    // via le mécanisme de réarmement dans _checkTrainerLineOfSight():
    //   if (_triggeredTrainerBattles.contains(entity.id)) {
    //     if (!inLoS) _triggeredTrainerBattles.remove(entity.id);
    //   }
    //
    // Et même si le lock est encore actif, le trainer ne sera pas re-déclenché
    // car il est marqué defeated dans storyFlags (guard dans _checkTrainerLineOfSight).

    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint('[battle] overworld resumed');
  }

  void _applyWhiteoutLiteAfterPlayerDefeat(
    RuntimeActiveBattleContext activeBattleContext, {
    required int activePlayerLineupIndex,
  }) {
    // Le whiteout-lite reste volontairement plus petit que BE10 :
    // - le moteur battle sait maintenant switcher et porter une vraie réserve ;
    // - mais cette reprise overworld ne cherche toujours pas à ouvrir un vrai
    //   centre Pokémon, ni une politique riche de défaite ;
    // - on garde donc un simple filet de sécurité post-combat.
    //
    // Le lot 15 reste donc volontairement borné :
    // 1. on garde le write-back lot 10 fidèle aux PV réellement sortis du combat ;
    // 2. puis on évite seulement le softlock total avec une reprise minimale ;
    // 3. on n'ouvre ni centre Pokémon, ni économie, ni pénalité complexe.
    _gameState = applyRuntimeDefeatRecoveryToGameState(
      gameState: _gameState,
      playerPartyIndex: activeBattleContext.playerPartyIndex,
      activePlayerLineupIndex: activePlayerLineupIndex,
      playerPartySlotIndicesByLineupIndex:
          activeBattleContext.playerPartySlotIndicesByLineupIndex,
    );

    final respawn = _resolveWhiteoutLiteRespawn(activeBattleContext);
    _world = _buildSafeWorldState(
      map: _bundle.map,
      project: _bundle.manifest,
      preferredPos: respawn.pos,
      fallbackFacing: respawn.facing,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
    );

    // On reste volontairement sur la carte courante :
    // - aucun "last heal center" persistant n'existe encore dans l'architecture ;
    // - aucun warp multi-map spécial whiteout n'est authoré ;
    // - réutiliser le spawn joueur déjà défini sur la map courante est donc le
    //   point de reprise le plus honnête disponible aujourd'hui.
    _player.syncState(_world.player, snapToGrid: true);
    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    _configureCameraViewport();
    _syncCameraToPlayer();
    _preloadActiveMapConnections();
    _pruneLoadedMapsToActiveNeighborhood();
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _refreshWorldNpcPresence();
    _showNotification('Défaite... retour au point de reprise');
  }

  GameplayPlayerState _resolveWhiteoutLiteRespawn(
    RuntimeActiveBattleContext activeBattleContext,
  ) {
    try {
      return resolveInitialPlayerSpawn(_bundle.map);
    } catch (_) {
      // Fallback minimal :
      // - si la map courante n'a pas de spawn joueur exploitable, on repart de
      //   la position overworld mémorisée au moment du handoff combat ;
      // - `_buildSafeWorldState` gardera ensuite le dernier mot pour éviter une
      //   cellule bloquée et trouver un point sûr si nécessaire.
      return GameplayPlayerState(
        pos: activeBattleContext.request.returnContext.playerPos,
        facing: activeBattleContext.request.returnContext.playerFacing,
      );
    }
  }

  void _handleInteract() {
    final result = stepGameplayWorld(_world, const InteractIntent());
    _world = result.world;
    _consumePathAnimationSignals(result.pathAnimationSignals);
    var scenarioHandledEntityInteraction = false;

    switch (result) {
      case NothingToInteract():
        if (result.pathAnimationSignals.isNotEmpty) {
          debugPrint('[interact] Path animation trigger');
          return;
        }
        debugPrint('[interact] Nothing to interact with');
        _showNotification('...');
      case NpcInteracted(:final entity):
        debugPrint('[interact] NPC: ${entity.id}');
        _faceNpcTowardPlayer(entity.id);
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _handleNpcInteraction(entity);
        }
      case SignInteracted(:final entity):
        debugPrint('[interact] Sign: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _tryOpenDialogue(
              entity.id, entity.sign?.dialogue, entity.inspectorHeadline);
        }
      case ItemInteracted(:final entity):
        debugPrint('[interact] Item: ${entity.id}');
        _showNotification(entity.inspectorHeadline);
      case EntityInteracted(:final entity):
        debugPrint('[interact] Entity: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _showNotification(entity.inspectorHeadline);
        }
      case PlacedElementInteracted(
          :final element,
          :final behavior,
          :final trigger,
        ):
        debugPrint('[interact] PlacedElement: ${element.id}');
        _executePlacedElementBehavior(
          element: element,
          behavior: behavior,
          trigger: trigger,
        );
      default:
        break;
    }

    if (result is NothingToInteract ||
        (result is EntityInteracted && !scenarioHandledEntityInteraction)) {
      _tryInteractWithMapEvent();
    }
  }

  bool _tryDispatchScenarioEntityInteraction(String entityId) {
    final result = _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.entityInteract(
        mapId: _activeMapId,
        entityId: entityId,
      ),
    );
    return result.handled;
  }

  void _tryInteractWithMapEvent() {
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      debugPrint('[interact] blocked: script is active');
      return;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[interact] blocked: flow phase is $_flowPhase');
      return;
    }

    final facing = _world.player.facing;
    final tx = _world.player.pos.x + facing.dx;
    final ty = _world.player.pos.y + facing.dy;

    final map = _bundle.map;
    MapEventDefinition? event;
    for (final e in map.events) {
      if (e.position.x == tx && e.position.y == ty) {
        event = e;
        break;
      }
    }

    if (event == null) return;

    final activePage = _storyBranching.resolveEventPage(event, _gameState);

    if (activePage == null) return;

    if (activePage.page.isDisabled) return;

    debugPrint('[interact] MapEvent: ${event.id} page=${activePage.pageIndex}');
    _handleMapEventInteraction(event, activePage);
  }

  void _handleMapEventInteraction(
    MapEventDefinition event,
    ActiveEventPage page,
  ) {
    if (page.page.script != null) {
      final message = page.page.message?.trim();
      if (message != null && message.isNotEmpty) {
        _showNotification(message);
      }
      _executeEventScript(event, page, page.page.script!);
    } else if (page.page.message != null && page.page.message!.isNotEmpty) {
      _showNotification(page.page.message!);
    } else {
      _showNotification('...');
    }
  }

  void _executeEventScript(
    MapEventDefinition event,
    ActiveEventPage page,
    ScriptRef scriptRef,
  ) {
    final scriptAsset = _bundle.manifest.scripts
        .firstWhere(
          (s) => s.id == scriptRef.scriptId,
          orElse: () =>
              throw StateError('Script not found: ${scriptRef.scriptId}'),
        )
        .asset;
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: scriptRef.startNode,
      runtimeSourceId: event.id,
    );
  }

  /// Démarrage générique d'exécution script.
  ///
  /// Cette méthode factorise le chemin script:
  /// - scripts de pages d'event map,
  /// - scripts déclenchés par le Scenario Runtime Bridge.
  void _startScriptExecution({
    required ScriptAsset script,
    String? startNodeId,
    required String runtimeSourceId,
  }) {
    final context = ScriptExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      onDialogueOpened: (dialogue) {
        _openDialogueForScriptSource(runtimeSourceId, dialogue);
      },
      onWarpRequested: (mapId, x, y) {
        _pendingWarp = TriggeredWarp(
          warpId: 'script_warp',
          targetMapId: mapId,
          targetPos: GridPos(x: x, y: y),
          triggerMode: MapWarpTriggerMode.onEnter,
        );
      },
    );

    _activeScriptController = ScriptRuntimeController(
      script: script,
      context: context,
      startNodeId: startNodeId,
    );
    _isAwaitingScriptResume = false;
    _runScriptStep();
  }

  void _runScriptStep() {
    final controller = _activeScriptController;
    if (controller == null) {
      return;
    }

    if (controller.isTerminated) {
      _activeScriptController = null;
      _isAwaitingScriptResume = false;
      return;
    }

    if (controller.isSuspended) {
      _isAwaitingScriptResume = true;
      return;
    }

    final result = controller.step();

    if (result is ScriptCommandResultSuspended) {
      _isAwaitingScriptResume = true;
      if (result.reason == ScriptSuspendReason.waitingForDialogue) {
        _flowPhase = _RuntimeFlowPhase.dialogue;
      }
      return;
    }

    _runScriptStep();
  }

  void _openDialogueForScriptSource(
      String runtimeSourceId, YarnDialogueRef dialogueRef) {
    final resolved = resolveDialogue(
      entityId: runtimeSourceId,
      ref: DialogueRef(
        dialogueId: '',
        scriptPathRelative: dialogueRef.filePath,
        startNode: dialogueRef.startNode,
      ),
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      debugPrint(
          '[script] failed to resolve dialogue: ${dialogueRef.filePath}');
      _runScriptStep();
      return;
    }

    loadDialogueContent(resolved).then((session) {
      if (session == null) {
        debugPrint('[script] failed to load dialogue');
        _runScriptStep();
        return;
      }

      _pendingPostDialogueAction = () {
        _flowPhase = _RuntimeFlowPhase.overworld;
        if (_isAwaitingScriptResume) {
          _isAwaitingScriptResume = false;
          _runScriptStep();
        }
      };

      _openDialogue(session);
    });
  }

  void _consumePathAnimationSignals(List<PathAnimationSignal> signals) {
    if (signals.isEmpty) {
      return;
    }
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final signal in signals) {
      switch (signal.kind) {
        case PathAnimationSignalKind.trigger:
          final backgroundApplied =
              active.backgroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] trigger ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] trigger layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
        case PathAnimationSignalKind.setActive:
          final activeValue = signal.active ?? false;
          final backgroundApplied =
              active.backgroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] active ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] active layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
      }
    }
  }

  void _executePlacedElementBehavior({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    if (!behavior.enabled) {
      return;
    }
    final effect = behavior.effect;
    final cooldownKey = _buildPlacedBehaviorCooldownKey(
      element: element,
      behavior: behavior,
      trigger: trigger,
    );
    final cooldownOverride = _resolvePlacedBehaviorCooldownOverride(behavior);
    if (!_placedBehaviorCooldownGate.canTrigger(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
    )) {
      final remainingMs = _placedBehaviorCooldownGate.remainingMs(
        key: cooldownKey,
        nowMs: _runtimeClockMs,
      );
      debugPrint(
        '[placed_behavior] cooldown blocked trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name} remainingMs=${remainingMs.toStringAsFixed(0)}',
      );
      _updateBehaviorDebugLine(
        'Cooldown ${effect.type.name} (${remainingMs.toStringAsFixed(0)} ms) · ${element.id}#${cooldownKey.behaviorId} (${behavior.triggerScope.name})',
      );
      return;
    }
    debugPrint(
      '[placed_behavior] trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name}',
    );
    var effectApplied = false;
    switch (effect.type) {
      case MapPlacedElementEffectType.showMessage:
        final text = effect.message?.trim() ?? '';
        if (text.isEmpty) {
          debugPrint(
            '[placed_behavior] showMessage ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=empty_message',
          );
          return;
        }
        _showNotification(text);
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.openDialogue:
        effectApplied =
            _tryOpenDialogue(element.id, effect.dialogue, element.elementId);
        break;
      case MapPlacedElementEffectType.setAnimationEnabled:
        final enabled = effect.animationEnabled;
        if (enabled == null) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=missing_value',
          );
          return;
        }
        final currentEnabled = _resolvePlacedElementAnimationEnabled(
          element.id,
        );
        if (currentEnabled == enabled) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_change value=$enabled',
          );
          _updateBehaviorDebugLine(
            'Animation déjà ${enabled ? 'active' : 'inactive'} · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        }
        _applyPlacedElementAnimationEnabled(
          instanceId: element.id,
          enabled: enabled,
        );
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.playAnimationOnce:
        final triggered =
            _playPlacedElementAnimationOnce(instanceId: element.id);
        if (!triggered) {
          debugPrint(
            '[placed_behavior] playAnimationOnce ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_animatable_frames',
          );
          _updateBehaviorDebugLine(
            'Animation 1x indisponible · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        } else {
          debugPrint(
            '[placed_behavior] playAnimationOnce started instance=${element.id} behavior=${cooldownKey.behaviorId} strategy=restart',
          );
        }
        effectApplied = true;
        break;
    }
    if (!effectApplied) {
      return;
    }
    _placedBehaviorCooldownGate.markTriggered(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
      overrideDuration: cooldownOverride,
    );
    _updateBehaviorDebugLine(
      'Triggered ${trigger.name}/${behavior.triggerScope.name} -> ${effect.type.name} · ${element.id}#${cooldownKey.behaviorId}',
    );
  }

  bool _playPlacedElementAnimationOnce({
    required String instanceId,
  }) {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return false;
    }
    final fromBackground =
        loaded.backgroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    final fromForeground =
        loaded.foregroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    return fromBackground || fromForeground;
  }

  void _applyPlacedElementAnimationEnabled({
    required String instanceId,
    required bool enabled,
  }) {
    try {
      final updatedMap = setMapPlacedElementAnimationEnabled(
        _world.map,
        instanceId: instanceId,
        enabled: enabled,
      );
      _world = GameplayWorldState.initial(
        map: updatedMap,
        playerPos: _world.player.pos,
        playerFacing: _world.player.facing,
        playerMovementMode: _world.player.movementMode,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
      _bundle = RuntimeMapBundle(
        manifest: _bundle.manifest,
        map: updatedMap,
        projectRootDirectory: _bundle.projectRootDirectory,
        tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
      );
      final activeLoaded = _loadedMapsById[_activeMapId];
      if (activeLoaded != null) {
        activeLoaded.backgroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        activeLoaded.foregroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        _loadedMapsById[_activeMapId] = _LoadedPlayableMap(
          bundle: _bundle,
          originCellX: activeLoaded.originCellX,
          originCellY: activeLoaded.originCellY,
          backgroundLayers: activeLoaded.backgroundLayers,
          foregroundLayers: activeLoaded.foregroundLayers,
          npcActors: activeLoaded.npcActors,
          npcActorByEntityId: activeLoaded.npcActorByEntityId,
        );
      }
      debugPrint(
        '[placed_behavior] setAnimationEnabled applied instance=$instanceId enabled=$enabled',
      );
    } catch (e, st) {
      debugPrint(
        '[placed_behavior] setAnimationEnabled failed instance=$instanceId enabled=$enabled error=$e\n$st',
      );
      _showNotification('Animation update failed');
    }
  }

  bool _tryOpenDialogue(
      String entityId, DialogueRef? ref, String fallbackLabel) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) return false;
    if (_dialogueOverlay != null) return false;
    if (!_npcEntityAllowedOnActiveMapForDialogue(entityId)) {
      debugPrint('[dialogue] blocked: npc absent entityId=$entityId');
      return false;
    }

    final resolved = resolveDialogue(
      entityId: entityId,
      ref: ref,
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      _showNotification(fallbackLabel);
      return false;
    }

    loadDialogueContent(resolved).then((session) {
      if (_dialogueOverlay != null) return;
      if (session == null) {
        debugPrint('[dialogue] failed to load session for entity=$entityId');
        _showNotification(fallbackLabel);
        return;
      }
      debugPrint('[dialogue] opening dialogue for entity=$entityId');
      _openDialogue(session);
    });
    return true;
  }

  void _openDialogue(DialogueSession session) {
    _notification?.removeFromParent();
    _notification = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
    _flowPhase = _RuntimeFlowPhase.dialogue;

    final overlay = DialogueOverlayComponent(
      session: session,
      viewportSize: camera.viewport.size,
      onFinished: () {
        debugPrint('[dialogue] dialogue closed');
        _dialogueOverlay = null;
        _flowPhase = _RuntimeFlowPhase.overworld;
        _awaitingSurfConfirmation = false;
        final action = _pendingPostDialogueAction;
        _pendingPostDialogueAction = null;
        action?.call();
      },
    );
    camera.viewport.add(overlay);
    _dialogueOverlay = overlay;
    final openedState = session.state;
    if (openedState is DialogueShowingLine) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} text="${openedState.text}"');
    } else if (openedState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} choice count=${openedState.choices.length}');
    }
  }

  void _advanceDialogue() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.advance();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  void _moveChoiceCursor(int delta) {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    overlay.moveCursor(delta);
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      debugPrint('[dialogue] choice moved selected=${state.selectedIndex}');
    }
  }

  void _confirmDialogueChoice() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      final idx = state.selectedIndex;
      debugPrint(
          '[dialogue] choice confirmed index=$idx text="${state.choices[idx].text}"');
      if (_awaitingSurfConfirmation) {
        if (idx == 0) {
          _pendingPostDialogueAction = () {
            setSurfingEnabled(true);
            debugPrint('[surf] mode activated via dialogue choice');
          };
        }
        _awaitingSurfConfirmation = false;
      }
    }
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.confirmChoice();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  /// Garde-fou : tout dialogue / combat PNJ passe par ici ou [_tryOpenDialogue].
  bool _npcEntityAllowedOnActiveMapForDialogue(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return true;
    }
    MapEntity? found;
    for (final e in _world.map.entities) {
      if (e.id == normalized) {
        found = e;
        break;
      }
    }
    if (found == null) {
      return true;
    }
    if (found.kind != MapEntityKind.npc) {
      return true;
    }
    return _npcPresencePredicateFor(_bundle.manifest)(
      _world.map.id,
      found,
    );
  }

  void _handleNpcInteraction(MapEntity entity) {
    if (!_npcPresencePredicateFor(_bundle.manifest)(_world.map.id, entity)) {
      debugPrint('[interact] ignored absent npc=${entity.id}');
      return;
    }
    final trainerId = entity.npc?.trainerId?.trim();

    // Cas 1: pas de trainerId → dialogue normal
    if (trainerId == null || trainerId.isEmpty) {
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 2: trainer déjà battu → defeat dialogue ou fallback
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint(
        '[interact] trainer already defeated trainer=$trainerId npc=${entity.id}',
      );
      _openDefeatDialogue(entity);
      return;
    }

    // Cas 3: trainerId invalide → log + fallback dialogue
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint(
        '[battle] trainer not found: $trainerId for npc=${entity.id}, fallback to dialogue',
      );
      _showNotification('Dresseur introuvable.');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 4: trainer non battu → battle normal
    // Vérifier aussi _triggeredTrainerBattles pour éviter double déclenchement
    if (_triggeredTrainerBattles.contains(entity.id)) {
      debugPrint(
        '[interact] trainer battle already triggered (LoS lock) trainer=$trainerId npc=${entity.id}',
      );
      // Ne pas déclencher un autre battle, mais ne pas bloquer l'interaction non plus
      // Juste ignorer silencieusement
      return;
    }

    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
        '[battle] trainer battle triggered npc=${entity.id} trainer=$trainerId',
      );
      // Lock ANTI-RETRIGGER avant de déclencher
      _triggeredTrainerBattles.add(entity.id);
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    }
  }

  void _openDefeatDialogue(MapEntity entity) {
    final defeatRef = entity.npc?.defeatDialogueRef;
    if (defeatRef != null) {
      debugPrint('[interact] opening defeat dialogue npc=${entity.id}');
      _tryOpenDialogue(entity.id, defeatRef, entity.inspectorHeadline);
    } else if (_resolveNpcDialogueRef(entity) != null) {
      debugPrint(
          '[interact] no defeat dialogue, fallback to normal dialogue npc=${entity.id}');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
    } else {
      debugPrint(
          '[interact] no dialogue for defeated trainer npc=${entity.id}');
      _showNotification('Le dresseur est déjà vaincu.');
    }
  }

  /// DEBUG-ONLY: Marque un trainer comme battu.
  ///
  /// **À n'utiliser qu'en debug/dev pour tester le flux de défaite.**
  /// Tant que le gameplay de combat n'est pas implémenté, ce mécanisme
  /// permet de simuler une victoire pour vérifier le defeat dialogue.
  ///
  /// En production, ce flag devrait être positionné automatiquement
  /// après une vraie victoire en combat.
  void debugMarkTrainerAsDefeated(String trainerId) {
    final trimmedId = trainerId.trim();
    if (trimmedId.isEmpty) {
      debugPrint('[debug] invalid trainerId, ignored');
      return;
    }
    _gameState = _storyFlags.markTrainerDefeated(_gameState, trimmedId);
    debugPrint('[debug] trainer $trimmedId marked as defeated');
    _refreshWorldNpcPresence();
  }

  /// Vérifie la Line of Sight (LoS) des trainers et déclenche automatiquement
  /// le battle si le joueur est détecté.
  ///
  /// **Conditions de déclenchement :**
  /// 1. Runtime stable : overworld, pas de dialogue, pas de battle pending
  /// 2. Trainer avec trainerId valide et lineOfSightRange > 0
  /// 3. Trainer non déjà battu (flag trainer_defeated:{id})
  /// 4. Joueur dans la LoS du trainer (checkLineOfSight)
  /// 5. Trainer pas déjà dans _triggeredTrainerBattles (anti-retrigger)
  ///
  /// **Réarmement :**
  /// - Quand le joueur sort de la LoS → lock retirée
  /// - Sur changement de map → toutes les locks retirées
  ///
  /// **Origine du calcul :**
  /// - Depuis entity.pos du NPC
  /// - Axe cardinal uniquement (nord/sud/est/ouest)
  /// - Aucune diagonale
  /// - Obstacles via world.isBlocked() sur les cases STRICTEMENT entre
  ///   le NPC et le joueur (exclut case du NPC et case du joueur)
  void _checkTrainerLineOfSight() {
    // Condition de stabilité runtime stricte
    if (_flowPhase != _RuntimeFlowPhase.overworld) return;
    if (_dialogueOverlay != null) return;
    if (_pendingBattleRequest != null) return;

    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!_npcPresencePredicateFor(_bundle.manifest)(
        _world.map.id,
        entity,
      )) {
        continue;
      }

      final trainerId = entity.npc?.trainerId;
      if (trainerId == null || trainerId.isEmpty) continue;

      final losRange = entity.npc?.lineOfSightRange ?? 0;
      if (losRange <= 0) continue;

      // Vérifier si déjà battu
      if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) continue;

      // Anti-retrigger : ignorer si déjà déclenché dans cette session
      if (_triggeredTrainerBattles.contains(entity.id)) {
        // Réarmement : si joueur sort de LoS, retirer le lock
        final inLoS = checkLineOfSight(
          npcPos: entity.pos,
          npcFacing: entity.npc!.facing,
          lineOfSightRange: losRange,
          playerPos: _world.player.pos,
          world: _world,
        );
        if (!inLoS) {
          _triggeredTrainerBattles.remove(entity.id);
        }
        continue;
      }

      // Check LoS
      final inLoS = checkLineOfSight(
        npcPos: entity.pos,
        npcFacing: entity.npc!.facing,
        lineOfSightRange: losRange,
        playerPos: _world.player.pos,
        world: _world,
      );

      if (inLoS) {
        // Lock anti-retrigger AVANT de déclencher
        _triggeredTrainerBattles.add(entity.id);
        _triggerTrainerBattle(entity);
      }
    }
  }

  /// Déclenche un battle trainer (appelé par interaction manuelle OU LoS auto).
  ///
  /// **Factorisation :** Cette méthode factorise UNIQUEMENT le démarrage du battle.
  /// Elle ne gère PAS :
  /// - La vérification trainer déjà battu (déjà fait par l'appelant)
  /// - Le defeat dialogue (géré par _handleNpcInteraction pour interaction manuelle)
  ///
  /// **Gestion d'erreur :**
  /// - trainerId invalide → log + notification + pas de crash
  /// - Battle request null → log + pas de battle
  void _triggerTrainerBattle(MapEntity entity) {
    final trainerId = entity.npc?.trainerId;
    if (trainerId == null || trainerId.isEmpty) {
      debugPrint('[trainer] no trainerId for entity=${entity.id}');
      return;
    }

    // Vérifier si déjà battu (pour LoS — interaction manuelle a déjà son check)
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint('[trainer] already defeated trainer=$trainerId');
      return;
    }

    // Vérifier trainer valide
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint('[trainer] not found trainer=$trainerId entity=${entity.id}');
      _showNotification('Dresseur introuvable.');
      return;
    }

    // Créer battle request
    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
          '[trainer] battle triggered trainer=$trainerId entity=${entity.id}');
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    } else {
      debugPrint(
          '[trainer] battle request failed trainer=$trainerId entity=${entity.id}');
    }
  }

  void _showNotification(String text) {
    _notification?.removeFromParent();
    final paint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        backgroundColor: Color(0xAA000000),
      ),
    );
    final component = TextComponent(
      text: text,
      textRenderer: paint,
      anchor: Anchor.topCenter,
    );
    component.position = Vector2(
      camera.viewport.size.x / 2,
      camera.viewport.size.y - 48,
    );
    camera.viewport.add(component);
    _notification = component;
    Future.delayed(const Duration(seconds: 2), () {
      if (_notification == component) {
        component.removeFromParent();
        _notification = null;
      }
    });
  }

  void _handleWaterBlocked() {
    final delta = _runtimeClockMs - _lastWaterRequiresSurfMessageAtMs;
    if (delta < _kWaterRequiresSurfMessageCooldownMs) {
      return;
    }
    _lastWaterRequiresSurfMessageAtMs = _runtimeClockMs;

    final evaluation = evaluateSurfAttempt(
      gameState: _gameState,
      isTargetWater: true,
    );
    final yarnNode = surfEvaluationToYarnNode(evaluation);
    if (yarnNode == null) {
      return;
    }

    final session = loadSurfDialogueSession(yarnNode);
    if (session == null) {
      debugPrint('[surf] failed to load dialogue node=$yarnNode');
      _showNotification(waterRequiresSurfFeedbackMessage);
      return;
    }

    debugPrint(
        '[surf] evaluation=${evaluation.runtimeType} -> dialogue=$yarnNode');

    if (evaluation is CanPromptSurf) {
      _awaitingSurfConfirmation = true;
    }
    _openDialogue(session);
  }

  /// Sauvegarde l'état actuel de la partie.
  ///
  /// Retourne `true` si la sauvegarde a réussi.
  Future<bool> saveGame() async {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    debugPrint(
      '[step_studio_trace] runtime_save_requested map=$_activeMapId completedStepIds=${_gameState.progression.completedStepIds} completedCutsceneIds=${_gameState.progression.completedCutsceneIds}',
    );
    return _saveGameUseCase.execute(_gameState);
  }

  /// Charge l'état de la partie et resync complètement le runtime.
  ///
  /// Retourne `true` si le chargement a réussi.
  /// Retourne `false` si aucune sauvegarde n'existe ou en cas d'échec.
  ///
  /// Effets de bord :
  /// - Modifie `_gameState`
  /// - Modifie `_activeMapId`
  /// - Recharge la map courante
  /// - Reconstruit `_world` avec la position/facing du joueur
  /// - Resync `_player` avec le nouveau `_world`
  /// - Resync caméra / streaming / bounds
  ///
  /// **Note** : Cette méthode ne restaure pas les overlays actifs (dialogue,
  /// battle transition) ni les états transitoires. Elle restaure uniquement
  /// l'état principal du runtime.
  ///
  /// **Limitation** : La phase destructive (à partir de `_gameState = loadedState`)
  /// n'est pas transactionnelle. En cas d'échec pendant le chargement de la map
  /// ou le remontage des layers, le runtime peut rester dans un état partiellement
  /// modifié. Aucun rollback n'est implémenté dans ce lot. Cette limitation sera
  /// adressée dans un futur lot si nécessaire.
  Future<bool> loadGame() async {
    // 1. Charger loadedState
    final rawLoadedState = await _loadGameUseCase.execute();
    if (rawLoadedState == null) {
      debugPrint('[load] no save found');
      return false;
    }
    final loadedState = normalizeLoadedGameState(rawLoadedState);

    // 2. Charger newBundle (avec error handling)
    RuntimeMapBundle newBundle;
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: loadedState.currentMapId,
      );
      newBundle = _resolveRuntimeBundle(loadedBundle);
    } catch (e, st) {
      debugPrint('[load] failed to load map: $e\n$st');
      return false;
    }

    // 3. Charger newImages (avec error handling)
    Map<String, ui.Image> newImages;
    try {
      newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
    } catch (e, st) {
      debugPrint('[load] failed to load tileset images: $e\n$st');
      return false;
    }

    // 4-16. Phase destructive (protégée par try/catch)
    try {
      // 4. Restaurer GameState
      _gameState = loadedState;

      // 5. Nettoyer l'état transitoire
      _clearTransientUiState();

      // 6. Unmount anciennes maps
      _unmountAllLoadedMaps();

      // 7. Assigner _bundle = newBundle
      _bundle = newBundle;

      // 8. Monter nouvelle map
      await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );

      // 9. Reconstruire _world
      _world = GameplayWorldState.initial(
        map: newBundle.map,
        project: newBundle.manifest,
        playerPos: loadedState.playerPosition,
        playerFacing: loadedState.playerFacing.asDirection,
        playerMovementMode: loadedState.playerMovementMode,
        npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
      );

      // 10. Mettre _activeMapId + reset contrôleur PNJ scripté
      _activeMapId = loadedState.currentMapId;
      _resetScriptedNpcMovementController();

      // 10. Resync _player
      _player.setMapOrigin(Vector2(0, 0), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);

      // 11. Synchroniser GameState
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);

      // 12-15. Resync caméra / streaming / bounds
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _applyDebugTileMarker();
      _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
        map: _bundle.map,
        pos: _world.player.pos,
      );

      _refreshWorldNpcPresence();

      debugPrint('[load] game loaded from saveId=${loadedState.saveId}');
      return true;
    } catch (e, st) {
      debugPrint('[load] failed during destructive phase: $e\n$st');
      return false;
    }
  }

  PlacedBehaviorRuntimeKey _buildPlacedBehaviorCooldownKey({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    final trimmedBehaviorId = behavior.id.trim();
    final behaviorId = trimmedBehaviorId.isEmpty ? 'legacy' : trimmedBehaviorId;
    return PlacedBehaviorRuntimeKey(
      instanceId: element.id,
      behaviorId: behaviorId,
      trigger: trigger,
      effectType: behavior.effect.type,
    );
  }

  Duration? _resolvePlacedBehaviorCooldownOverride(
    MapPlacedElementBehavior behavior,
  ) {
    final cooldownMs = behavior.cooldownMs;
    if (cooldownMs == null) {
      return null;
    }
    if (cooldownMs <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: cooldownMs);
  }

  bool _resolvePlacedElementAnimationEnabled(String instanceId) {
    for (final instance in _world.map.placedElements) {
      if (instance.id != instanceId) {
        continue;
      }
      return instance.animation?.enabled ?? false;
    }
    return false;
  }

  void _ensureBehaviorDebugOverlay() {
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    final existing = _behaviorDebugOverlay;
    if (existing != null) {
      existing.text = _lastBehaviorDebugLine;
      return;
    }
    final overlay = TextComponent(
      text: _lastBehaviorDebugLine,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          backgroundColor: Color(0xAA111111),
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 10),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _behaviorDebugOverlay = overlay;
  }

  void _ensureFpsOverlay() {
    if (!_showFpsOverlay) {
      return;
    }
    final existing = _fpsOverlay;
    if (existing != null) {
      existing.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
      return;
    }
    final overlay = TextComponent(
      text: 'FPS ${_currentFps.toStringAsFixed(1)}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.lightGreenAccent,
          backgroundColor: Color(0xAA111111),
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 28),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _fpsOverlay = overlay;
  }

  void _updateFps(double dt) {
    _fpsAccumulatorSeconds += dt;
    _fpsFrameCount += 1;

    // Fenêtre courte de 250ms: stable sans être trop lente.
    if (_fpsAccumulatorSeconds < 0.25) {
      return;
    }
    _currentFps = _fpsFrameCount / _fpsAccumulatorSeconds;
    _fpsAccumulatorSeconds = 0.0;
    _fpsFrameCount = 0;

    if (_showFpsOverlay) {
      _ensureFpsOverlay();
      _fpsOverlay?.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
    }
  }

  void _updateBehaviorDebugLine(String line) {
    _lastBehaviorDebugLine = line;
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    _ensureBehaviorDebugOverlay();
    final overlay = _behaviorDebugOverlay;
    if (overlay == null) {
      return;
    }
    overlay.text = line;
  }

  Future<void> _handleWarp(TriggeredWarp warp) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[warp] ignored: flow=${_flowPhase.name}');
      return;
    }
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    final sourceBundle = _bundle;
    final sourceWorld = _world;
    final sourceMapId = _activeMapId;
    final sourcePos = _world.player.pos;
    final sourceFacing = _world.player.facing;
    WarpTransitionOverlayComponent? overlay;
    var swapCompleted = false;
    try {
      _clearTransientUiState();
      overlay = WarpTransitionOverlayComponent(
        viewportSize: camera.viewport.size,
      );
      camera.viewport.add(overlay);
      _warpTransitionOverlay = overlay;
      debugPrint(
        '[warp] start transition warp=${warp.warpId} map=$sourceMapId -> ${warp.targetMapId} target=(${warp.targetPos.x}, ${warp.targetPos.y})',
      );
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: warp.targetMapId,
      );
      final newBundle = _resolveRuntimeBundle(loadedBundle);
      debugPrint('[warp] target map loaded id=${newBundle.map.id}');
      final transitionSpec = _resolveWarpTransitionSpec(
        sourceMap: sourceBundle.map,
        targetMap: newBundle.map,
      );
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade out durationMs=${transitionSpec.fadeOut.inMilliseconds}',
        );
        await overlay.fadeOut(duration: transitionSpec.fadeOut);
      }
      if (!_isWithinMapBounds(newBundle.map, warp.targetPos)) {
        throw StateError(
          'warp target out of bounds map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y}) size=${newBundle.map.size.width}x${newBundle.map.size.height}',
        );
      }
      final newWorld = GameplayWorldState.initial(
        map: newBundle.map,
        playerPos: warp.targetPos,
        playerFacing: sourceFacing,
        project: newBundle.manifest,
        tileWidth: newBundle.manifest.settings.tileWidth,
        tileHeight: newBundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
      );
      if (newWorld.isBlocked(warp.targetPos.x, warp.targetPos.y)) {
        throw StateError(
          'warp target blocked map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      debugPrint('[warp] loading target map visuals id=${newBundle.map.id}');
      final newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
      _unmountAllLoadedMaps();
      final root = await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = newBundle;
      _world = newWorld;
      _activeMapId = newBundle.map.id;
      _previousMapId = null;
      _triggeredTrainerBattles.clear(); // Reset LoS locks on map change
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      swapCompleted = true;
      debugPrint(
        '[warp] player placed at map=${newBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade in durationMs=${transitionSpec.fadeIn.inMilliseconds}',
        );
        await overlay.fadeIn(duration: transitionSpec.fadeIn);
      }
      debugPrint('[warp] transition completed');
    } catch (e, st) {
      debugPrint('[warp] transition failed: $e\n$st');
      _showNotification('Warp failed');
      if (!swapCompleted) {
        await _recoverFromWarpFailure(
          sourceBundle: sourceBundle,
          sourceWorld: sourceWorld,
          sourceMapId: sourceMapId,
        );
      }
      if (overlay != null) {
        await overlay.fadeIn(duration: const Duration(milliseconds: 140));
      }
    } finally {
      _warpTransitionOverlay?.close();
      _warpTransitionOverlay = null;
      _flowPhase = _RuntimeFlowPhase.overworld;
      debugPrint(
        '[warp] gameplay unlocked map=$_activeMapId pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      if (swapCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
      if (_activeMapId == sourceMapId &&
          _world.player.pos.x == sourcePos.x &&
          _world.player.pos.y == sourcePos.y) {
        _player.syncState(_world.player, snapToGrid: true);
      }
    }
  }

  _WarpTransitionSpec _resolveWarpTransitionSpec({
    required MapData sourceMap,
    required MapData targetMap,
  }) {
    final sourceIndoor = sourceMap.mapMetadata.isIndoor ||
        sourceMap.mapMetadata.mapType == MapType.building ||
        sourceMap.mapMetadata.mapType == MapType.interior ||
        sourceMap.mapMetadata.mapType == MapType.cave ||
        sourceMap.mapMetadata.mapType == MapType.facility;
    final targetIndoor = targetMap.mapMetadata.isIndoor ||
        targetMap.mapMetadata.mapType == MapType.building ||
        targetMap.mapMetadata.mapType == MapType.interior ||
        targetMap.mapMetadata.mapType == MapType.cave ||
        targetMap.mapMetadata.mapType == MapType.facility;
    final duration = sourceIndoor == targetIndoor
        ? const Duration(milliseconds: 170)
        : const Duration(milliseconds: 230);
    return _WarpTransitionSpec(
      style: _WarpTransitionStyle.fade,
      fadeOut: duration,
      fadeIn: duration,
    );
  }

  Future<void> _recoverFromWarpFailure({
    required RuntimeMapBundle sourceBundle,
    required GameplayWorldState sourceWorld,
    required String sourceMapId,
  }) async {
    if (_loadedMapsById.isNotEmpty && _activeMapId == sourceMapId) {
      _bundle = sourceBundle;
      _world = sourceWorld;
      _syncGameStateFromWorld(mapIdOverride: sourceMapId);
      _player.syncState(_world.player, snapToGrid: true);
      _configureCameraViewport();
      _syncCameraToPlayer();
      debugPrint('[warp] rollback no-op (source map still mounted)');
      return;
    }

    try {
      _unmountAllLoadedMaps();
      final loadedFallbackBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: sourceMapId,
      );
      final fallbackBundle = _resolveRuntimeBundle(loadedFallbackBundle);
      final fallbackWorld = _buildSafeWorldState(
        map: fallbackBundle.map,
        project: fallbackBundle.manifest,
        preferredPos: sourceWorld.player.pos,
        fallbackFacing: sourceWorld.player.facing,
        tileWidth: fallbackBundle.manifest.settings.tileWidth,
        tileHeight: fallbackBundle.manifest.settings.tileHeight,
      );
      final fallbackImages =
          await loadTilesetImagesById(fallbackBundle.tilesetAbsolutePathsById);
      final root = await _mountLoadedMap(
        bundle: fallbackBundle,
        tileImagesById: fallbackImages,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = fallbackBundle;
      _world = fallbackWorld;
      _activeMapId = fallbackBundle.map.id;
      _previousMapId = null;
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      debugPrint(
        '[warp] rollback restored map=${fallbackBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } catch (e, st) {
      debugPrint('[warp] rollback failed: $e\n$st');
    }
  }

  GameplayWorldState _buildSafeWorldState({
    required MapData map,
    required ProjectManifest project,
    required GridPos preferredPos,
    required Direction fallbackFacing,
    required int tileWidth,
    required int tileHeight,
  }) {
    final safePos = _isWithinMapBounds(map, preferredPos)
        ? preferredPos
        : const GridPos(x: 0, y: 0);
    final world = GameplayWorldState.initial(
      map: map,
      playerPos: safePos,
      playerFacing: fallbackFacing,
      project: project,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(project),
    );
    if (!world.isBlocked(safePos.x, safePos.y)) {
      return world;
    }

    try {
      final spawn = resolveInitialPlayerSpawn(map);
      final spawnWorld = GameplayWorldState.initial(
        map: map,
        playerPos: spawn.pos,
        playerFacing: fallbackFacing,
        project: project,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(project),
      );
      if (!spawnWorld.isBlocked(spawn.pos.x, spawn.pos.y)) {
        return spawnWorld;
      }
    } catch (_) {}

    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        if (!world.isBlocked(x, y)) {
          return GameplayWorldState.initial(
            map: map,
            playerPos: GridPos(x: x, y: y),
            playerFacing: fallbackFacing,
            project: project,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            npcMapPresencePredicate: _npcPresencePredicateFor(project),
          );
        }
      }
    }

    return world;
  }

  bool _isWithinMapBounds(MapData map, GridPos pos) {
    return pos.x >= 0 &&
        pos.y >= 0 &&
        pos.x < map.size.width &&
        pos.y < map.size.height;
  }

  Future<void> _handleConnection(TriggeredConnection connection) async {
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    var transitionCompleted = false;
    try {
      _clearTransientUiState();
      debugPrint(
        '[connection] attempting map=${_bundle.map.id} direction=${connection.direction.name} target=${connection.targetMapId} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y})',
      );
      final source = _loadedMapsById[_activeMapId];
      if (source == null) {
        debugPrint(
            '[connection] source map visuals missing for id=$_activeMapId');
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      final target = await _ensureConnectionTargetLoaded(
        source: source,
        connection: connection,
      );
      if (target == null) {
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      debugPrint('[connection] resolved target map=${target.bundle.map.id}');
      final targetPos = resolveConnectedMapTargetPos(
        sourcePos: connection.sourcePos,
        sourceSize: source.bundle.map.size,
        targetSize: target.bundle.map.size,
        direction: connection.direction,
        offset: connection.offset,
      );
      if (targetPos == null) {
        debugPrint(
          '[connection] invalid entry coordinates direction=${connection.direction.name} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y}) sourceSize=${source.bundle.map.size.width}x${source.bundle.map.size.height} targetSize=${target.bundle.map.size.width}x${target.bundle.map.size.height}',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection invalid');
        return;
      }
      debugPrint(
        '[connection] computed entry pos=(${targetPos.x}, ${targetPos.y})',
      );
      final newWorld = GameplayWorldState.initial(
        map: target.bundle.map,
        playerPos: targetPos,
        playerFacing: _world.player.facing,
        project: target.bundle.manifest,
        tileWidth: target.bundle.manifest.settings.tileWidth,
        tileHeight: target.bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate:
            _npcPresencePredicateFor(target.bundle.manifest),
      );
      if (newWorld.isBlocked(targetPos.x, targetPos.y)) {
        debugPrint(
          '[connection] blocked entry map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection blocked');
        return;
      }
      _bundle = target.bundle;
      _world = newWorld;
      _previousMapId = _activeMapId;
      _activeMapId = target.bundle.map.id;
      _resetScriptedNpcMovementController();
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      final fromPx = _player.position.clone();
      final targetOriginPx = _originPixelsOf(target);
      final toPx = Vector2(
        targetOriginPx.x + targetPos.x * _cellWidth,
        targetOriginPx.y + targetPos.y * _cellHeight,
      );
      debugPrint(
        '[connection] player step pixels from=(${fromPx.x.toStringAsFixed(1)}, ${fromPx.y.toStringAsFixed(1)}) to=(${toPx.x.toStringAsFixed(1)}, ${toPx.y.toStringAsFixed(1)})',
      );
      _player.setMapOrigin(targetOriginPx, snapToGrid: false);
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _configureCameraViewport();
      final visibleSize = camera.viewfinder.visibleGameSize;
      debugPrint(
        '[connection] camera after transition focus=(${_player.focusPoint.x.toStringAsFixed(1)}, ${_player.focusPoint.y.toStringAsFixed(1)}) viewport=(${(visibleSize?.x ?? 0).toStringAsFixed(1)}, ${(visibleSize?.y ?? 0).toStringAsFixed(1)})',
      );
      debugPrint(
        '[connection] transition complete -> map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
      );
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      transitionCompleted = true;
    } catch (e, st) {
      debugPrint('[connection] transition failed: $e\n$st');
      _player.syncState(_world.player, snapToGrid: true);
      _showNotification('Connection failed');
    } finally {
      _flowPhase = _RuntimeFlowPhase.overworld;
      if (transitionCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
    }
  }

  void _clearTransientUiState() {
    _pendingWarp = null;
    _pendingConnection = null;
    // CRITICAL: Do NOT clear _pendingBattleRequest if a battle is active!
    // This would cancel a pending wild encounter battle.
    // Only clear if we're in overworld phase (no battle in progress).
    if (_flowPhase == _RuntimeFlowPhase.overworld) {
      _pendingBattleRequest = null;
    }
    _pendingPlacedElementBehavior = null;
    _notification?.removeFromParent();
    _notification = null;
    _dialogueOverlay?.removeFromParent();
    _dialogueOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    // Blindage défensif lot 10 :
    // ce reset central est utilisé par plusieurs chemins runtime (load, warp,
    // connection). Si un contexte battle survivait ici, on garderait en
    // mémoire un slot party et une requête de combat qui ne correspondent plus
    // à l'état overworld courant. On l'efface donc explicitement avec le reste
    // de l'UI transitoire.
    _activeBattleContext = null;
    _warpTransitionOverlay?.removeFromParent();
    _warpTransitionOverlay = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
  }

  void _unmountAllLoadedMaps() {
    final ids = _loadedMapsById.keys.toList(growable: false);
    for (final id in ids) {
      _unmountLoadedMap(id);
    }
    _loadedMapsById.clear();
    _loadMapFutureById.clear();
  }

  void _applyDebugTileMarker() {
    _debugTileMarkerFill?.removeFromParent();
    _debugTileMarkerFill = null;
    _debugTileMarkerBorder?.removeFromParent();
    _debugTileMarkerBorder = null;
    _debugTileMarkerText?.removeFromParent();
    _debugTileMarkerText = null;

    final pos = _debugTileMarkerPos;
    if (pos == null) {
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return;
    }
    final origin = _originPixelsOf(loaded);
    final x = origin.x + pos.x * _cellWidth;
    final y = origin.y + pos.y * _cellHeight;
    final size = Vector2(_cellWidth, _cellHeight);

    final fill = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()..color = const ui.Color(0x66FF9800),
      priority: 150000,
    );
    final border = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()
        ..color = const ui.Color(0xFFFF6D00)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
      priority: 150001,
    );
    world.add(fill);
    world.add(border);
    _debugTileMarkerFill = fill;
    _debugTileMarkerBorder = border;

    final label = _debugTileMarkerLabel?.trim();
    if (label == null || label.isEmpty) {
      return;
    }
    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(x + 2, y + 2),
      priority: 150002,
    );
    world.add(text);
    _debugTileMarkerText = text;
  }

  void _clearNpcCollisionDebugOverlay() {
    final ids = _npcCollisionDebugByEntityId.keys.toList(growable: false);
    for (final id in ids) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _syncNpcCollisionDebugOverlay() {
    if (!_showNpcCollisionDebugOverlay) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final origin = _originPixelsOf(loaded);
    final seen = <String>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final actor = loaded.npcActorByEntityId[entity.id];
      if (actor == null) {
        continue;
      }
      seen.add(entity.id);
      final visual = _npcCollisionDebugByEntityId.putIfAbsent(entity.id, () {
        final spriteRect = RectangleComponent(
          priority: 200000,
          paint: ui.Paint()
            ..color = const ui.Color(0xAA00E5FF)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final collisionRect = RectangleComponent(
          priority: 200001,
          paint: ui.Paint()
            ..color = const ui.Color(0xAAFF1744)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final anchorMarker = CircleComponent(
          radius: 3.0,
          priority: 200002,
          paint: ui.Paint()..color = const ui.Color(0xFFFFEA00),
        );
        world.add(spriteRect);
        world.add(collisionRect);
        world.add(anchorMarker);
        return _NpcCollisionDebugVisual(
          spriteRect: spriteRect,
          collisionRect: collisionRect,
          anchorMarker: anchorMarker,
        );
      });

      // 1) Bounding box visuelle réelle du sprite.
      visual.spriteRect
        ..position = actor.position.clone()
        ..size = actor.size.clone();

      // 2) Footprint collision gameplay (grille -> pixels).
      final footprint = resolveEntityCollisionFootprint(entity);
      visual.collisionRect
        ..position = Vector2(
          origin.x + footprint.pos.x * _cellWidth,
          origin.y + footprint.pos.y * _cellHeight,
        )
        ..size = Vector2(
          footprint.size.width * _cellWidth,
          footprint.size.height * _cellHeight,
        );

      // 3) Point d'ancrage logique MapEntity.pos (top-left cellule logique).
      visual.anchorMarker.position = Vector2(
        origin.x + entity.pos.x * _cellWidth + (_cellWidth / 2) - 3,
        origin.y + entity.pos.y * _cellHeight + (_cellHeight / 2) - 3,
      );
    }

    final stale = _npcCollisionDebugByEntityId.keys
        .where((id) => !seen.contains(id))
        .toList(growable: false);
    for (final id in stale) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _unmountLoadedMap(String mapId) {
    _clearNpcCollisionDebugOverlay();
    final loaded = _loadedMapsById.remove(mapId);
    if (loaded == null) {
      return;
    }
    loaded.backgroundLayers.removeFromParent();
    loaded.foregroundLayers.removeFromParent();
    for (final actor in loaded.npcActors) {
      actor.removeFromParent();
      _npcActors.remove(actor);
    }
  }

  Future<_LoadedPlayableMap> _mountLoadedMap({
    required RuntimeMapBundle bundle,
    required Map<String, ui.Image> tileImagesById,
    required int originCellX,
    required int originCellY,
  }) async {
    final npcPred = _npcPresencePredicateFor(bundle.manifest);
    final backgroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      showCollisionOverlay: _showCollisionOverlay,
      npcMapPresencePredicate: npcPred,
    );
    backgroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    backgroundLayers.priority = 0;
    await world.add(backgroundLayers);

    final foregroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      renderPass: MapLayerRenderPass.foreground,
      showCollisionOverlay: false,
      npcMapPresencePredicate: npcPred,
    );
    foregroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    foregroundLayers.priority = 100000;
    await world.add(foregroundLayers);

    final npcActors = <OverworldActorComponent>[];
    final npcActorByEntityId = <String, OverworldActorComponent>{};
    final charById = {for (final c in bundle.manifest.characters) c.id: c};
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final originPx =
        _originPixels(originCellX: originCellX, originCellY: originCellY);
    for (final entity in bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!npcPred(bundle.map.id, entity)) {
        // Pas de création d'acteur si la règle runtime dit "absent".
        debugPrint(
          '[step_studio_trace] npc_mount_skipped map=${bundle.map.id} entity=${entity.id} reason=presence_predicate_false',
        );
        continue;
      }
      final charId = resolveNpcCharacterId(entity, bundle.manifest);
      if (charId == null || charId.isEmpty) continue;
      final char = charById[charId];
      if (char == null) continue;
      final actor = OverworldActorComponent(
        character: char,
        tileImages: tileImagesById,
        tileWidth: bundle.manifest.settings.tileWidth,
        tileHeight: bundle.manifest.settings.tileHeight,
        cellWidth: cw,
        cellHeight: ch,
        facing: entity.npc?.facing ?? EntityFacing.south,
      );
      actor.configureGridPlacement(
        pos: entity.pos,
        footprint: entity.size,
        mapOrigin: originPx,
        snapToGrid: true,
      );
      npcActors.add(actor);
      npcActorByEntityId[entity.id] = actor;
      _npcActors.add(actor);
      await world.add(actor);
      debugPrint(
        '[step_studio_trace] npc_mount_added map=${bundle.map.id} entity=${entity.id}',
      );
    }

    final loaded = _LoadedPlayableMap(
      bundle: bundle,
      originCellX: originCellX,
      originCellY: originCellY,
      backgroundLayers: backgroundLayers,
      foregroundLayers: foregroundLayers,
      npcActors: npcActors,
      npcActorByEntityId: npcActorByEntityId,
    );
    _loadedMapsById[bundle.map.id] = loaded;
    _applyNpcVisibilityToLoadedMap(loaded);
    return loaded;
  }

  Future<_LoadedPlayableMap?> _ensureConnectionTargetLoaded({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
  }) async {
    final targetMapId = connection.targetMapId;
    final existing = _loadedMapsById[targetMapId];
    if (existing != null) {
      final expected = _computeConnectedOriginCells(
        source: source,
        connection: connection,
        targetSize: existing.bundle.map.size,
      );
      if (expected.x != existing.originCellX ||
          expected.y != existing.originCellY) {
        debugPrint(
          '[connection] origin mismatch target=$targetMapId existing=(${existing.originCellX}, ${existing.originCellY}) expected=(${expected.x}, ${expected.y})',
        );
      }
      return existing;
    }
    final inFlight = _loadMapFutureById[targetMapId];
    if (inFlight != null) {
      return await inFlight;
    }

    Future<_LoadedPlayableMap?> load() async {
      try {
        final loadedBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: targetMapId,
        );
        final bundle = _resolveRuntimeBundle(loadedBundle);
        final origin = _computeConnectedOriginCells(
          source: source,
          connection: connection,
          targetSize: bundle.map.size,
        );
        final images =
            await loadTilesetImagesById(bundle.tilesetAbsolutePathsById);
        final loaded = await _mountLoadedMap(
          bundle: bundle,
          tileImagesById: images,
          originCellX: origin.x,
          originCellY: origin.y,
        );
        debugPrint(
          '[connection] loaded map=${bundle.map.id} origin=(${origin.x}, ${origin.y})',
        );
        return loaded;
      } catch (e, st) {
        debugPrint(
            '[connection] load failed target=$targetMapId error=$e\n$st');
        return null;
      }
    }

    final future = load();
    _loadMapFutureById[targetMapId] = future;
    try {
      return await future;
    } finally {
      final current = _loadMapFutureById[targetMapId];
      if (identical(current, future)) {
        _loadMapFutureById.remove(targetMapId);
      }
    }
  }

  _GridCellPos _computeConnectedOriginCells({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
    required GridSize targetSize,
  }) {
    return switch (connection.direction) {
      MapConnectionDirection.east => _GridCellPos(
          x: source.originCellX + source.bundle.map.size.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.west => _GridCellPos(
          x: source.originCellX - targetSize.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.north => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY - targetSize.height,
        ),
      MapConnectionDirection.south => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY + source.bundle.map.size.height,
        ),
    };
  }

  void _preloadActiveMapConnections() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final connection in active.bundle.map.connections) {
      _ensureConnectionTargetLoaded(
        source: active,
        connection: TriggeredConnection(
          direction: connection.direction,
          targetMapId: connection.targetMapId,
          offset: connection.offset,
          sourcePos: _world.player.pos,
        ),
      );
    }
  }

  void _pruneLoadedMapsToActiveNeighborhood() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    final keep = <String>{
      active.bundle.map.id,
      ...active.bundle.map.connections.map((c) => c.targetMapId),
    };
    final previousMapId = _previousMapId;
    if (previousMapId != null && previousMapId.isNotEmpty) {
      keep.add(previousMapId);
    }
    final toRemove = _loadedMapsById.keys
        .where((id) => !keep.contains(id))
        .toList(growable: false);
    for (final id in toRemove) {
      _unmountLoadedMap(id);
    }
  }

  Vector2 _originPixels({
    required int originCellX,
    required int originCellY,
  }) {
    return Vector2(originCellX * _cellWidth, originCellY * _cellHeight);
  }

  Vector2 _originPixelsOf(_LoadedPlayableMap map) {
    return _originPixels(
      originCellX: map.originCellX,
      originCellY: map.originCellY,
    );
  }

  ProjectCharacterEntry? _resolvePlayerCharacter(RuntimeMapBundle bundle) {
    return resolveDefaultPlayerCharacter(bundle.manifest);
  }

  void _faceNpcTowardPlayer(String entityId) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return;
    }
    final playerFacing = _world.player.facing;
    final npcFacing = switch (playerFacing) {
      Direction.north => EntityFacing.south,
      Direction.south => EntityFacing.north,
      Direction.east => EntityFacing.west,
      Direction.west => EntityFacing.east,
    };
    actor.setMotion(npcFacing, CharacterAnimationState.idle);
  }

  /// Construit le runner cutscene MVP avec callbacks runtime concrets.
  ///
  /// Le runner reste découplé de Flame; `PlayableMapGame` lui injecte juste
  /// les opérations nécessaires.
  CutsceneRuntimeRunner _buildCutsceneRuntimeRunner() {
    return CutsceneRuntimeRunner(
      context: CutsceneRuntimeContext(
        openDialogue: (dialogueId, {startNode}) {
          return _openScenarioDialogueById(
            dialogueId,
            startNode: startNode,
            runtimeSourceId: 'cutscene',
          );
        },
        isDialogueOpen: () => _dialogueOverlay != null,
        requestChoice: (request) {
          _pendingCutsceneChoiceRequest = request;
          return true;
        },
        resolveCutsceneById: _findRuntimeCutsceneById,
        moveNpcTo: ({required entityId, required destination}) {
          return startScriptedNpcMove(
            entityId: entityId,
            destination: destination,
          );
        },
        readNpcMovementStatus: (entityId) {
          return scriptedNpcMovementStatus(entityId);
        },
        faceNpc: ({required entityId, required facing}) {
          return _setNpcFacing(entityId, facing);
        },
        emitOutcome: (outcomeId) {
          _emitCutsceneOutcome(outcomeId);
        },
        setFlag: (flagName) {
          _gameState = _storyFlags.set(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        clearFlag: (flagName) {
          _gameState = _storyFlags.clear(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        isFlagSet: (flagName) => _storyFlags.isSet(_gameState, flagName),
        isOutcomeSet: (outcomeId) =>
            _storyFlags.isSet(_gameState, scenarioOutcomeFlagName(outcomeId)),
      ),
    );
  }

  RuntimeCutsceneAsset? _findRuntimeCutsceneById(String cutsceneId) {
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final candidate in runtimeCutscenes) {
      if (candidate.id == normalized) {
        return candidate;
      }
    }
    return null;
  }

  /// Oriente explicitement un PNJ (étape `faceNpc` de cutscene).
  ///
  /// On met à jour:
  /// - l'acteur visuel (immédiat),
  /// - la map runtime en mémoire (facing npc), pour rester cohérent avec les
  ///   futures logiques gameplay lisant l'orientation d'entité.
  bool _setNpcFacing(String entityId, EntityFacing facing) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    actor.setMotion(facing, CharacterAnimationState.idle);

    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return true;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return true;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
      playerMovementMode: _world.player.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );
    return true;
  }

  /// Émet un outcome depuis une cutscene.
  ///
  /// MVP:
  /// 1) on persiste l'outcome comme flag `scenario.outcome.*`,
  /// 2) on tente une transition vers un scénario global via `sourceOutcome`.
  void _emitCutsceneOutcome(String outcomeId) {
    final normalized = outcomeId.trim();
    if (normalized.isEmpty) {
      return;
    }
    _gameState =
        _storyFlags.set(_gameState, scenarioOutcomeFlagName(normalized));
    _refreshWorldNpcPresence();
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.outcomeReceived(
        outcomeId: normalized,
      ),
    );
  }

  /// (Re)crée le contrôleur de déplacement scripté pour la map active.
  ///
  /// Cette méthode est appelée:
  /// - au chargement initial,
  /// - après warp/connection/load game (changement de map).
  ///
  /// On repart à chaque fois d'un snapshot propre des PNJ actifs pour éviter
  /// toute dérive d'état entre maps.
  void _resetScriptedNpcMovementController() {
    _runtimeNpcPositions
      ..clear()
      ..addAll(_collectCurrentNpcPositions());
    _runtimeNpcPositions['player'] = _world.player.pos;
    _scriptedNpcReservedOccupiedCellsByEntity.clear();

    final controller = ScriptedEntityMovementController(
      mapSize: _world.map.size,
      isCellBlocked: _isNpcCellBlockedForRoutePlanning,
      startEntityStep: _startScriptedNpcStep,
      isEntityStepping: _isScriptedNpcStepping,
      onEntityPositionCommitted: _commitScriptedNpcPosition,
      validateEntityStep: _validateScriptedNpcStepRuntimeCollision,
    );
    controller.replaceTrackedEntities(_runtimeNpcPositions);
    _scriptedEntityMovementController = controller;
    _applyNpcOverworldDefaultMovement();
  }

  void _applyNpcOverworldDefaultMovement() {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return;
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        controller.stopPatrol(entity.id);
        continue;
      }
      final route = resolveNpcDefaultPatrolRoute(entity);
      if (route == null) {
        controller.stopPatrol(entity.id);
        continue;
      }
      controller.startPatrol(route);
    }
  }

  Map<String, GridPos> _collectCurrentNpcPositions() {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return const <String, GridPos>{};
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    final byId = <String, GridPos>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        continue;
      }
      // On ne suit que les PNJ présents **et** encore montés en acteur.
      if (!loaded.npcActorByEntityId.containsKey(entity.id)) {
        continue;
      }
      byId[entity.id] = entity.pos;
    }
    return byId;
  }

  bool _isNpcCellBlockedForRoutePlanning(
    int x,
    int y, {
    String? ignoreEntityId,
  }) {
    final normalizedIgnore = ignoreEntityId?.trim();
    if (normalizedIgnore == null || normalizedIgnore.isEmpty) {
      return _world.isBlocked(x, y);
    }
    if (normalizedIgnore == 'player') {
      final mode = _world.player.movementMode;
      if (_world.movementBlockReasonAt(
            x: x,
            y: y,
            movementMode: mode,
          ) !=
          null) {
        return true;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == x && cell.y == y) {
          return true;
        }
      }
      return false;
    }

    // Pathfinding anchor validation:
    // - `x,y` est la position logique MapEntity.pos (top-left),
    // - on valide le footprint collision réel (important pour NPC 2x2),
    // - on ignore l'auto-collision de l'entité courante.
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: normalizedIgnore,
      anchorPos: GridPos(x: x, y: y),
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: normalizedIgnore,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] blocked anchor entity=$normalizedIgnore anchor=($x,$y) reason="${probe.reason}" footprint=${probe.evaluatedCollisionCells.map((c) => '(${c.x},${c.y})').join(',')}',
      );
    }
    return !probe.passable;
  }

  String? _validateScriptedNpcStepRuntimeCollision({
    required String entityId,
    required GridPos from,
    required GridPos to,
  }) {
    if (entityId.trim() == 'player') {
      final mode = _world.player.movementMode;
      final block = _world.movementBlockReasonAt(
        x: to.x,
        y: to.y,
        movementMode: mode,
      );
      if (block != null) {
        debugPrint(
          '[npc_patrol] runtime step rejected entity=player from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason=${block.name}',
        );
        return block.name;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == to.x && cell.y == to.y) {
          debugPrint(
            '[npc_patrol] runtime step rejected entity=player to=(${to.x},${to.y}) reason=dynamic_blocker',
          );
          return 'Dynamic blocker at destination.';
        }
      }
      return null;
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: to,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] runtime step rejected entity=$entityId from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason="${probe.reason}"',
      );
      return probe.reason;
    }
    return null;
  }

  /// Cellules dynamiques à bloquer pour un pas NPC scripté.
  ///
  /// Frontière conceptuelle:
  /// - collision "statique" (layers + entités map) => via GameplayWorldState;
  /// - collision "dynamique" hors map entities (joueur) => injectée ici.
  ///
  /// On inclut volontairement:
  /// 1) la cellule logique canonique du joueur (`_world.player.pos`);
  /// 2) la cellule visuelle actuelle au niveau des pieds du player pendant
  ///    l'interpolation de pas.
  ///
  /// Le point (2) évite les traversées visuelles quand la simulation logique a
  /// déjà commité un déplacement joueur mais que le sprite est encore en train
  /// d'animer son pas.
  Iterable<GridPos> _scriptedNpcDynamicBlockedCells({
    String? ignoreEntityId,
  }) sync* {
    final activeFollowLeader = _pendingScenarioFollowRequest?.leaderEntityId;
    final ignorePlayerForLeader = activeFollowLeader != null &&
        ignoreEntityId != null &&
        ignoreEntityId == activeFollowLeader;

    if (!ignorePlayerForLeader) {
      final canonical = _world.player.pos;
      yield canonical;

      final rendered = _renderedPlayerFootGridCell();
      if (rendered != null &&
          (rendered.x != canonical.x || rendered.y != canonical.y)) {
        yield rendered;
      }
    }

    // Réservations de destination des autres PNJ en cours de pas.
    for (final entry in _scriptedNpcReservedOccupiedCellsByEntity.entries) {
      if (ignoreEntityId != null && entry.key == ignoreEntityId) {
        continue;
      }
      yield* entry.value;
    }
  }

  GridPos? _renderedPlayerFootGridCell() {
    final origin = _player.mapOrigin;
    if (_cellWidth <= 0 || _cellHeight <= 0) {
      return null;
    }
    final foot = _player.footPoint;
    final cellX = ((foot.x - origin.x) / _cellWidth).floor();
    final cellY = ((foot.y - 1 - origin.y) / _cellHeight).floor();
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= _world.map.size.width ||
        cellY >= _world.map.size.height) {
      return null;
    }
    return GridPos(x: cellX, y: cellY);
  }

  bool _startScriptedNpcStep({
    required String entityId,
    required GridPos from,
    required GridPos to,
    required EntityFacing facing,
    double? durationSeconds,
  }) {
    if (entityId.trim() == 'player') {
      final walkFacing = _directionFromEntityFacing(facing);
      final nextState = _world.player.copyWith(pos: to, facing: walkFacing);
      _player.startStep(
        nextState,
        durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
      );
      _reserveScriptedNpcStepOccupiedCells(
        entityId: entityId,
        fromAnchorPos: from,
        toAnchorPos: to,
      );
      return true;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    final started = actor.startGridStep(
      to: to,
      facing: facing,
      durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
    );
    if (!started) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return false;
    }
    _reserveScriptedNpcStepOccupiedCells(
      entityId: entityId,
      fromAnchorPos: from,
      toAnchorPos: to,
    );
    return true;
  }

  bool _isScriptedNpcStepping(String entityId) {
    if (entityId.trim() == 'player') {
      return _player.isStepping;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    return actor?.isStepping ?? false;
  }

  void _commitScriptedNpcPosition(String entityId, GridPos position) {
    if (entityId.trim() == 'player') {
      final from = _world.player.pos;
      final facing = _directionBetweenAdjacent(from: from, to: position) ??
          _world.player.facing;
      _world = _world.withPlayer(
        _world.player.copyWith(pos: position, facing: facing),
      );
      _runtimeNpcPositions['player'] = position;
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld();
      return;
    }
    _runtimeNpcPositions[entityId] = position;
    _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
    _world = _world.withEntityPosition(entityId, position);
  }

  bool _isCellReservedByScriptedNpc(GridPos cell) {
    for (final cells in _scriptedNpcReservedOccupiedCellsByEntity.values) {
      if (cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  void _reserveScriptedNpcStepOccupiedCells({
    required String entityId,
    required GridPos fromAnchorPos,
    required GridPos toAnchorPos,
  }) {
    if (entityId.trim() == 'player') {
      _scriptedNpcReservedOccupiedCellsByEntity[entityId] = <GridPos>{
        GridPos(x: fromAnchorPos.x, y: fromAnchorPos.y),
        GridPos(x: toAnchorPos.x, y: toAnchorPos.y),
      };
      return;
    }
    final entity = _world.map.entities
        .where((candidate) => candidate.id == entityId)
        .cast<MapEntity?>()
        .firstWhere((candidate) => candidate != null, orElse: () => null);
    if (entity == null) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }

    // Réservation "anti-traversée visuelle":
    // - footprint collision de la destination (cohérence gameplay stricte),
    // - footprint visuel grille du NPC sur source + destination (cohérence
    //   perceptuelle pendant l'interpolation visuelle du sprite).
    final reserved = <GridPos>{}
      ..addAll(_resolveEntityCollisionCellsAtAnchor(entity, toAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, fromAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, toAnchorPos));
    if (reserved.isEmpty) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }
    _scriptedNpcReservedOccupiedCellsByEntity[entityId] = reserved;
  }

  Set<GridPos> _resolveEntityCollisionCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final moved = entity.copyWith(pos: anchorPos);
    return resolveEntityCollisionCells(moved).where(_isInMapBounds).toSet();
  }

  Set<GridPos> _resolveEntityVisualCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final cells = <GridPos>{};
    for (var dy = 0; dy < entity.size.height; dy++) {
      for (var dx = 0; dx < entity.size.width; dx++) {
        final cell = GridPos(
          x: anchorPos.x + dx,
          y: anchorPos.y + dy,
        );
        if (_isInMapBounds(cell)) {
          cells.add(cell);
        }
      }
    }
    return cells;
  }

  bool _isInMapBounds(GridPos cell) {
    return cell.x >= 0 &&
        cell.y >= 0 &&
        cell.x < _world.map.size.width &&
        cell.y < _world.map.size.height;
  }

  double get _cellWidth =>
      _bundle.manifest.settings.tileWidth *
      _bundle.manifest.settings.displayScale;

  double get _cellHeight =>
      _bundle.manifest.settings.tileHeight *
      _bundle.manifest.settings.displayScale;

  void _configureCameraViewport() {
    final cw = _bundle.cellWidth;
    final ch = _bundle.cellHeight;
    final mw = _bundle.map.size.width * cw;
    final mh = _bundle.map.size.height * ch;
    final vw = math.min(_kViewportTilesX * cw, mw);
    final vh = math.min(_kViewportTilesY * ch, mh);
    camera.viewfinder.visibleGameSize = Vector2(vw, vh);
  }

  void _syncCameraToPlayer() {
    if (!isLoaded) {
      return;
    }
    final focus = _player.focusPoint;
    camera.viewfinder.position = Vector2(
      focus.x.roundToDouble(),
      focus.y.roundToDouble(),
    );
  }
}

class _LoadedPlayableMap {
  _LoadedPlayableMap({
    required this.bundle,
    required this.originCellX,
    required this.originCellY,
    required this.backgroundLayers,
    required this.foregroundLayers,
    required this.npcActors,
    required this.npcActorByEntityId,
  });

  final RuntimeMapBundle bundle;
  final int originCellX;
  final int originCellY;
  final MapLayersComponent backgroundLayers;
  final MapLayersComponent foregroundLayers;
  final List<OverworldActorComponent> npcActors;
  final Map<String, OverworldActorComponent> npcActorByEntityId;
}

class _NpcCollisionDebugVisual {
  _NpcCollisionDebugVisual({
    required this.spriteRect,
    required this.collisionRect,
    required this.anchorMarker,
  });

  final RectangleComponent spriteRect;
  final RectangleComponent collisionRect;
  final CircleComponent anchorMarker;
}

class _GridCellPos {
  const _GridCellPos({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;
}

class _PendingScenarioFollowRequest {
  _PendingScenarioFollowRequest({
    required this.leaderEntityId,
    required this.requestedAtMs,
  });

  final String leaderEntityId;
  final double requestedAtMs;
  GridPos? lastLeaderPos;
  Direction? lastLeaderTravelDirection;
  List<GridPos>? cachedPath;
  GridPos? cachedPathDestination;
  GridPos? cachedPathLeaderPos;
  int consecutiveBlockedSteps = 0;
}

class _PendingScenarioTransitionMapRequest {
  const _PendingScenarioTransitionMapRequest({
    required this.mapId,
    required this.warpId,
  });

  final String mapId;
  final String warpId;
}

class _PendingScenarioNpcWarpEntry {
  const _PendingScenarioNpcWarpEntry({
    required this.entityId,
    required this.warpId,
    required this.warpPos,
    required this.approachPos,
  });

  final String entityId;
  final String warpId;
  final GridPos warpPos;
  final GridPos approachPos;
}

class _PendingScenarioMoveContinuation {
  const _PendingScenarioMoveContinuation({
    required this.entityId,
    required this.runtimeSourceId,
    required this.targetKind,
  });

  final String entityId;
  final String runtimeSourceId;
  final String targetKind;
}

class _PendingScenarioReachedEnd {
  const _PendingScenarioReachedEnd({
    required this.scenarioId,
    required this.origin,
    required this.queuedAtMs,
  });

  final String scenarioId;
  final String origin;
  final double queuedAtMs;
}

class _FollowPathPlan {
  const _FollowPathPlan({
    required this.destination,
    required this.path,
  });

  final GridPos destination;
  final List<GridPos> path;
}

enum _WarpTransitionStyle {
  fade,
}

class _WarpTransitionSpec {
  const _WarpTransitionSpec({
    required this.style,
    required this.fadeOut,
    required this.fadeIn,
  });

  final _WarpTransitionStyle style;
  final Duration fadeOut;
  final Duration fadeIn;
}

```

### `packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import '../../application/battle_start_request.dart';

/// Résout la policy adverse réellement utilisée par le runtime pour une requête.
///
/// Ce helper pur existe pour deux besoins immédiats du lot 4b :
/// - durcir la preuve que la difficulté authored côté trainer est bien relue
///   dans le vrai flow runtime ;
/// - éviter de laisser cette lecture enterrée dans une méthode privée géante de
///   `PlayableMapGame`, donc difficile à verrouiller honnêtement par test.
///
/// Garde-fous de périmètre :
/// - ce helper reste runtime-local et ne fuit pas dans `map_battle` ;
/// - il ne rouvre ni scripts trainer, ni switch intelligent, ni lot 5 ;
/// - il route seulement la difficulté produit déjà présente vers le seam
///   `BattleOpponentPolicy` ouvert au lot 3.
BattleOpponentPolicy resolveRuntimeTrainerOpponentPolicy({
  required BattleStartRequest request,
  required ProjectManifest manifest,
}) {
  if (request is! TrainerBattleStartRequest) {
    return const BattleFirstLegalOpponentPolicy();
  }

  final trainer = findTrainerEntryForBattleRequest(
    request: request,
    manifest: manifest,
  );
  return battleOpponentPolicyForDifficulty(trainer?.battleDifficulty);
}

/// Relit le trainer authored réellement visé par une requête de combat.
///
/// Pourquoi ce seam existe :
/// - le runtime a déjà `trainerId` dans `TrainerBattleStartRequest` ;
/// - les données produit restent dans `ProjectManifest.trainers` ;
/// - plusieurs lots ont maintenant besoin de la même relecture honnête
///   (difficulté, background explicite) sans recopier la logique.
ProjectTrainerEntry? findTrainerEntryForBattleRequest({
  required BattleStartRequest request,
  required ProjectManifest manifest,
}) {
  if (request is! TrainerBattleStartRequest) {
    return null;
  }

  final normalizedTrainerId = request.trainerId.trim();
  for (final trainer in manifest.trainers) {
    if (trainer.id == normalizedTrainerId) {
      return trainer;
    }
  }
  return null;
}

```

### `packages/map_runtime/test/battle_overlay_component_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_debug_panel_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_backdrop_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_hud_component.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleMoveData _tackle({
  int power = 40,
}) {
  return BattleMoveData(
    id: 'tackle',
    name: 'Tackle',
    power: power,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
  );
}

RuntimeMapBundle _runtimeBundle({
  MapMetadata mapMetadata = const MapMetadata(),
  MapRole mapRole = MapRole.exterior,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Lot 2 Battle Background Tests',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'field_map',
          name: 'Field Map',
          relativePath: 'maps/field_map.json',
          role: mapRole,
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
    ),
    map: MapData(
      id: 'field_map',
      name: 'Field Map',
      size: const GridSize(width: 4, height: 3),
      mapMetadata: mapMetadata,
    ),
    projectRootDirectory: '/tmp/lot2_battle_backgrounds',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.north,
    ),
    mapId: 'field_map',
    zoneId: 'grass_zone',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'sparkitten',
    level: 6,
    minLevel: 6,
    maxLevel: 6,
    weight: 1,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.north,
    ),
    trainerId: 'trainer_rookie',
    npcEntityId: 'npc_rookie',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<String> _writeTinyBattleBackgroundImage() async {
  final directory = await Directory.systemTemp.createTemp(
    'battle_overlay_background_',
  );
  final file = File('${directory.path}/trainer_background.png');
  await file.writeAsBytes(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGOMmnbnPwMDAwMTiABhACpmAs+3EdpKAAAAAElFTkSuQmCC',
    ),
  );
  return file.path;
}

void main() {
  group('BattleBackgroundResolver lot 2 context resolution', () {
    const resolver = BattleBackgroundResolver();

    test('resolves an outdoor wild family from a real wild request', () {
      final spec = resolver.resolve(
        request: _wildRequest(),
        bundle: _runtimeBundle(),
      );

      expect(spec.key, equals(BattleBackgroundKey.wildOutdoor));
    });

    test('resolves an outdoor trainer family from a real trainer request', () {
      final spec = resolver.resolve(
        request: _trainerRequest(),
        bundle: _runtimeBundle(),
      );

      expect(spec.key, equals(BattleBackgroundKey.trainerOutdoor));
    });

    test('prioritizes indoor map truth over the battle kind when needed', () {
      final spec = resolver.resolve(
        request: _trainerRequest(),
        bundle: _runtimeBundle(
          mapMetadata: const MapMetadata(
            isIndoor: true,
            mapType: MapType.interior,
          ),
          mapRole: MapRole.interior,
        ),
      );

      expect(spec.key, equals(BattleBackgroundKey.indoor));
    });
  });

  group('BattleOverlayComponent Phase C decision prompts', () {
    test('uses the request type instead of a flat choice list heuristic', () {
      final freeTurnSession = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(freeTurnSession.decisionRequest),
        equals('Que doit faire le joueur ?'),
      );

      final forcedReplacementSession = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(
          forcedReplacementSession.decisionRequest,
        ),
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );

      final continueSession = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(continueSession.decisionRequest),
        equals('Le joueur doit continuer un tour forcé'),
      );
    });
  });

  group('BattleOverlayComponent BE10A chronology', () {
    test('renders a voluntary switch before the later enemy attack', () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 35,
          currentHp: 35,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 50,
            currentHp: 50,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          stats: _stats(speed: 100, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final switchIndex =
          lines.indexWhere((line) => line.contains('Joueur switch de'));
      final attackIndex =
          lines.indexWhere((line) => line.contains('Ennemi utilise Tackle'));

      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(attackIndex, greaterThanOrEqualTo(0));
      expect(switchIndex, lessThan(attackIndex));
    });

    test('rejects bucket-only turn results because chronology would be false',
        () {
      const bucketOnlyTurn = BattleTurnResult(
        playerAction: BattleActionNone(),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(id: 'tackle', name: 'Tackle', power: 40),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 12,
            didHit: true,
          ),
        ],
      );

      expect(
        () => buildBattleTurnLinesForOverlay(bucketOnlyTurn),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'renders end-of-turn residuals before forced replacement markers after a double KO',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        isTrainerBattle: true,
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final residualIndex = lines.indexWhere(
        (line) => line.contains('dégâts résiduels (PSN)'),
      );
      final enemyReplacementIndex = lines.indexWhere(
        (line) => line.contains('Ennemi remplace lead_enemy par bench_enemy'),
      );
      final playerReplacementIndex = lines.indexWhere(
        (line) => line.contains('Joueur doit remplacer lead_player K.O.'),
      );

      expect(residualIndex, greaterThanOrEqualTo(0));
      expect(enemyReplacementIndex, greaterThan(residualIndex));
      expect(playerReplacementIndex, greaterThan(enemyReplacementIndex));
    });

    test('renders Stealth Rock set and switch-in damage from timeline events',
        () {
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'stealth_rock',
            name: 'Stealth Rock',
            power: 0,
            target: BattleMoveTarget.opponentSide,
            setsStealthRock: true,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'stealth_rock',
              name: 'Stealth Rock',
              power: 0,
              target: BattleMoveTarget.opponentSide,
              setsStealthRock: true,
            ),
            targetKind: BattleMoveExecutionTargetKind.side,
            targetSideRef: BattleSideId.enemy,
            damage: 0,
            didHit: true,
          ),
        ],
        stealthRockEvents: <BattleStealthRockEvent>[
          BattleStealthRockEvent.set(
            side: BattleSideId.enemy,
            sourceMoveId: 'stealth_rock',
          ),
          BattleStealthRockEvent.damagedOnEntry(
            side: BattleSideId.enemy,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 10,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'stealth_rock',
                name: 'Stealth Rock',
                power: 0,
                target: BattleMoveTarget.opponentSide,
                setsStealthRock: true,
              ),
              targetKind: BattleMoveExecutionTargetKind.side,
              targetSideRef: BattleSideId.enemy,
              damage: 0,
              didHit: true,
            ),
          ),
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.set(
              side: BattleSideId.enemy,
              sourceMoveId: 'stealth_rock',
            ),
          ),
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.damagedOnEntry(
              side: BattleSideId.enemy,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 10,
            ),
          ),
        ],
      );

      final lines = buildBattleTurnLinesForOverlay(turn);

      expect(
        lines,
        contains('Stealth Rock est posé du côté Ennemi'),
      );
      expect(
        lines,
        contains('Ennemi subit 10 dégâts de Stealth Rock à l’entrée'),
      );
    });

    test(
        'renders Spikes layer growth and switch-in damage from timeline events',
        () {
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'spikes',
            name: 'Spikes',
            power: 0,
            target: BattleMoveTarget.opponentSide,
            setsSpikes: true,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'spikes',
              name: 'Spikes',
              power: 0,
              target: BattleMoveTarget.opponentSide,
              setsSpikes: true,
            ),
            targetKind: BattleMoveExecutionTargetKind.side,
            targetSideRef: BattleSideId.enemy,
            damage: 0,
            didHit: true,
          ),
        ],
        spikesEvents: <BattleSpikesEvent>[
          BattleSpikesEvent.setLayer(
            side: BattleSideId.enemy,
            layers: 2,
          ),
          BattleSpikesEvent.damagedOnEntry(
            side: BattleSideId.enemy,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 13,
            layers: 2,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'spikes',
                name: 'Spikes',
                power: 0,
                target: BattleMoveTarget.opponentSide,
                setsSpikes: true,
              ),
              targetKind: BattleMoveExecutionTargetKind.side,
              targetSideRef: BattleSideId.enemy,
              damage: 0,
              didHit: true,
            ),
          ),
          BattleTurnSpikesEvent(
            BattleSpikesEvent.setLayer(
              side: BattleSideId.enemy,
              layers: 2,
            ),
          ),
          BattleTurnSpikesEvent(
            BattleSpikesEvent.damagedOnEntry(
              side: BattleSideId.enemy,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 13,
              layers: 2,
            ),
          ),
        ],
      );

      final lines = buildBattleTurnLinesForOverlay(turn);

      expect(
        lines,
        contains('Spikes monte à 2 couche(s) du côté Ennemi'),
      );
      expect(
        lines,
        contains('Ennemi subit 13 dégâts de Spikes à l’entrée (2 couche(s))'),
      );
    });
  });

  group('BattleOverlayComponent lot 1 scene composition', () {
    test(
        'uses a stable fallback background when no runtime context is injected',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.currentBackgroundKey,
        equals(BattleBackgroundKey.fallbackField),
      );
    });

    test(
        'mounts a structured battle scene with backdrop, battler zones, huds, command box and narration box by default',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.children.whereType<BattleSceneBackdropComponent>(),
        hasLength(1),
      );
      expect(
        overlay.children.whereType<BattleSceneCombatantComponent>(),
        hasLength(2),
      );
      expect(
        overlay.children.whereType<BattleSceneHudComponent>(),
        hasLength(2),
      );
      expect(overlay.commandPanelMounted, isTrue);
      expect(overlay.narrationPanelMounted, isTrue);
      expect(overlay.children.whereType<BattleDebugPanelComponent>(), isEmpty);
      expect(overlay.debugPanelMounted, isFalse);
    });

    test('mounts the resolved background family inside the backdrop layer',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        backgroundSpec: const BattleBackgroundSpec(
          key: BattleBackgroundKey.trainerOutdoor,
        ),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final backdrop =
          overlay.children.whereType<BattleSceneBackdropComponent>().single;

      expect(
        overlay.currentBackgroundKey,
        equals(BattleBackgroundKey.trainerOutdoor),
      );
      expect(
        backdrop.currentBackgroundKey,
        equals(BattleBackgroundKey.trainerOutdoor),
      );
    });

    test('loads an authored explicit trainer image when the spec resolves one',
        () async {
      final explicitImagePath = await _writeTinyBattleBackgroundImage();
      final backdrop = BattleSceneBackdropComponent(
        size: Vector2(960, 540),
        backgroundSpec: BattleBackgroundSpec.explicitImage(
          absolutePath: explicitImagePath,
          fallbackKey: BattleBackgroundKey.trainerOutdoor,
        ),
      );

      await backdrop.onLoad();
      expect(backdrop.currentBackgroundKey, BattleBackgroundKey.trainerOutdoor);
      expect(backdrop.hasResolvedExplicitImage, isTrue);
    });

    test('keeps the debug panel opt-in and separate from the normal battle UI',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        showDebugPanel: true,
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.children.whereType<BattleDebugPanelComponent>(),
        hasLength(1),
      );
      expect(overlay.debugPanelMounted, isTrue);
      expect(overlay.commandPanelMounted, isTrue);
      expect(overlay.narrationPanelMounted, isTrue);
    });

    test('updateState refreshes the visible prompt and selected choice source',
        () async {
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(overlay.currentPromptText, equals('Que doit faire le joueur ?'));
      expect(overlay.getSelectedChoice(), isA<PlayerBattleChoiceFight>());

      final forcedReplacementSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'benchmate',
            lineupIndex: 1,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );

      overlay.updateState(forcedReplacementSession);

      expect(
        overlay.currentPromptText,
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );
      expect(overlay.getSelectedChoice(), isA<PlayerBattleChoiceSwitch>());
    });
  });
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
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/runtime_trainer_battle_overrides.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase A golden battle-ready slice smoke', () {
    const mapper = RuntimeBattleSetupMapper();
    const backgroundResolver = BattleBackgroundResolver();

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
      final trainerNpc = bundle.map.entities.firstWhere(
        (entity) => entity.id == 'npc_trainer_rookie',
      );
      final request = buildTrainerBattleRequestFromNpc(
        entity: trainerNpc,
        manifest: bundle.manifest,
        world: world,
        createdAtEpochMs: 1,
      );

      expect(request, isNotNull);
      final trainerEntry = bundle.manifest.trainers
          .cast<ProjectTrainerEntry?>()
          .firstWhere((entry) => entry?.id == request!.trainerId);
      expect(trainerEntry, isNotNull);
      expect(trainerEntry!.battleDifficulty, equals(4));
      expect(
        trainerEntry.battleBackgroundRelativePath,
        equals('assets/battle_backgrounds/trainer_rookie.png'),
      );

      final routedPolicy = resolveRuntimeTrainerOpponentPolicy(
        request: request!,
        manifest: bundle.manifest,
      );
      expect(routedPolicy, isA<BattleHighestPowerOpponentPolicy>());

      final setup = await mapper.map(
        bundle: bundle,
        gameState: gameState,
        request: request,
      );
      expect(setup.isTrainerBattle, isTrue);
      final session = createBattleSession(
        setup,
        opponentPolicy: routedPolicy,
      );

      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, equals('sproutle'));
      expect(session.state.enemy.speciesId, equals('sparkitten'));
    });

    test(
        'the versioned golden slice resolves distinct wild and trainer backgrounds',
        () async {
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
      ).encounter!;
      final wildRequest = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final trainer = bundle.map.entities.firstWhere(
        (entity) => entity.id == 'npc_trainer_rookie',
      );
      final trainerRequest = buildTrainerBattleRequestFromNpc(
        entity: trainer,
        manifest: bundle.manifest,
        world: world,
        createdAtEpochMs: 1,
      )!;

      expect(
        backgroundResolver.resolve(request: wildRequest, bundle: bundle).key,
        equals(BattleBackgroundKey.wildOutdoor),
      );
      expect(
        backgroundResolver.resolve(request: trainerRequest, bundle: bundle).key,
        equals(BattleBackgroundKey.trainerOutdoor),
      );
      expect(
        backgroundResolver
            .resolve(request: trainerRequest, bundle: bundle)
            .explicitImageAbsolutePath,
        endsWith(
          p.join('assets', 'battle_backgrounds', 'trainer_rookie.png'),
        ),
      );
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

### `examples/playable_runtime_host/golden_battle_slice/assets/battle_backgrounds/trainer_rookie.png`

```base64
iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGOMmnbnPwMDAwMTiABhACpmAs+3EdpKAAAAAElFTkSuQmCC
```
