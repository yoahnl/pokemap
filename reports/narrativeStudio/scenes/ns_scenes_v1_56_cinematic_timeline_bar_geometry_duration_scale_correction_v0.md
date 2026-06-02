# NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0

Date : 2026-06-02  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0`  
Prochain lot recommande : `NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0`

## 1. Resume executif

V1-56 corrige la geometrie visuelle des barres de timeline du Cinematic Builder et, apres retours explicites de Karim, le ratio utile de la timeline : largeur de la zone temporelle, epaisseur des rangées, hauteur des barres et chrome au-dessus/sous la grille.

Le lot V1-56 prevu initialement pour la navigation clavier a ete remplace par ce correctif a la demande de Karim. Objectif : respecter les proportions de l'image cible et faire en sorte que les barres soient de vrais rectangles temporels, pas des badges visuels presque fixes.

Les barres utilisent maintenant le meme repere horizontal que les ticks et le curseur : `startMs` pilote la position X, `visualDurationMs` pilote la largeur, et le curseur reste aligne sur le debut du bloc selectionne. Le sandbox preview ne capte plus l'espace vertical restant au detriment de la timeline. La colonne `Pistes` est plus compacte, l'axe temporel recupere plus de largeur, et les rangées/barres sont plus épaisses pour se rapprocher de l'objectif visuel.

Evidence Pack : `reports/narrativeStudio/scenes/ns_scenes_v1_56_evidence_pack.md`.

## 2. Gate 0

Etat avant edits V1-56 : working tree propre.

```text
/Users/karim/Project/pokemonProject
main
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
```

Decision : partir du commit V1-54/V1-55 propre, sans revert, sans operation Git d'ecriture.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/brainstorming/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- rapports et evidence packs V1-51, V1-52, V1-54 et V1-55
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- tests core time layout/lane

## 4. Design Gate — Bar Geometry / Duration Scale Correction V0

1. V1-56 est un correctif visuel de geometrie, pas une nouvelle capacite d'edition.
2. La demande produit vient de Karim : respecter les proportions de l'image cible.
3. Les barres doivent lire comme des rectangles temporels.
4. La position horizontale reste derivee de `CinematicTimelineTimeBlock.startMs`.
5. La largeur visible est derivee de `CinematicTimelineTimeBlock.visualDurationMs`.
6. Le fallback de duree reste gere par le read model V1-51.
7. Le code ne persiste aucun `startMs`, `endMs`, `cursorTimeMs` ou `playbackTimeMs`.
8. Ticks, barres et curseur partagent le meme contenu scrollable et la meme origine X.
9. Le tick `0 ms` devient une key mesurable en test widget.
10. Le tick `500 ms` devient une key mesurable pour verifier l'echelle.
11. Les barres visuelles deviennent mesurables via `cinematic-builder-time-visual-bar-<stepId>`.
12. La barre 500 ms Camera doit avoir une largeur proche de l'ecart tick 0 -> tick 500.
13. La barre `actorFace` doit demarrer au tick 500 ms.
14. La barre `actorMove` 1000 ms doit etre environ deux fois plus large que la barre Camera 500 ms.
15. Le test impose `actorMove >= camera * 1.9`.
16. Le curseur selectionne reste centre sur le tick du bloc selectionne.
17. La largeur minimale visuelle est fixee a 72 px pour eviter l'effet badge fixe tout en conservant la lisibilite.
18. La largeur minimale reste uniquement une protection de lisibilite.
19. Les barres utilisent une variante `PokeMapCard.borderRadius` plus compacte pour lire plus rectangulaire.
20. Les IDs techniques ne sont pas promus en UX principale.
21. Le hover V1-55 reste fonctionnel apres correction de geometrie.
22. Les transport controls restent disabled.
23. Aucun seek/scrubber n'est ajoute.
24. Aucun drag/drop, resize ou reorder n'est ajoute.
25. Aucun fichier runtime/gameplay/battle/examples n'est modifie.
26. Visual Gate produite : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png`.
27. Apres retour Karim, le ratio vertical est corrige : la timeline ne se contente pas d'un panneau haut, la grille utile doit aussi etre haute.
28. Le preview sandbox est plafonne/compacte pour ne plus absorber l'espace vertical.
29. La grille temporelle devient mesurable via `cinematic-builder-time-grid-viewport`.
30. La piste Audio doit rester visible dans la grille sur la surface de reference.
31. Apres second retour Karim, la largeur utile de l'axe est corrigee sans cacher les labels : la colonne `Pistes` doit rester dans une plage lisible de 124 a 136 px.
32. Apres nouveau retour Karim, l'en-tete/badges/transport ne doivent plus rendre la grille minuscule : la grille doit commencer a moins de 90 px du panneau timeline.
33. La grille temporelle utile doit faire au moins 335 px sur la surface 1663x926.
34. La zone temporelle doit occuper au moins 83 % de la grille.
35. Les rangées ne doivent plus etre fines : hauteur attendue >= 46 px.
36. Les barres ne doivent plus etre maigres : hauteur visuelle attendue >= 34 px.
37. Le detail de hover ne doit pas deplacer la grille sous la souris ; il est affiche en overlay non interactif.
38. Les controles de transport sont icon-only pour respecter les proportions et liberer la grille.
39. Apres la reprise finale demandee par Karim, la colonne de pistes affiche des labels complets, sans meta `1 / Acteur / 0` qui provoquait les ellipses.
40. Les lanes acteurs affichent le nom humain court (`Professor`, `Rival`, ou labels projet comme `Joueur`/`Lysa`) au lieu du prefixe `Acteur:`.

## 5. Scope realise

- Ajout de keys de mesure pour le contenu temporel, les ticks et les barres visuelles.
- Remplacement de l'echelle fallback fixe par un plancher `pixelsPerMs` plus direct.
- Ajout de `_timelineBarWidth(...)` pour centraliser largeur derivee + minimum.
- Reduction de `_timelineBarMinWidth` de 96 px a 72 px.
- Ajout de `PokeMapCard.borderRadius` dans le design system.
- Barres de timeline rendues plus rectangulaires avec `borderRadius: 6`.
- Retrait du badge index volumineux dans les barres au profit d'un numero compact.
- Split vertical responsive preview/timeline avec priorite a la timeline.
- Preview sandbox compacte quand sa hauteur devient reduite.
- Key `cinematic-builder-time-grid-viewport` pour mesurer la grille utile.
- Colonne de pistes reglee a 128 px pour garder les labels complets comme dans la reference.
- Axe temporel agrandi a 34 px.
- Rangées timeline agrandies a 48 px.
- Barres timeline agrandies a 36 px.
- Badges timeline affiches en ligne horizontale compacte au lieu de plusieurs lignes.
- Detail hover affiche en overlay non interactif pour ne plus deplacer la grille.
- Controles transport passes en icon-only, toujours disabled, sans texte visible sous la timeline.
- Meta de cellule piste retiree (`1`, `Acteur`, `0`) pour ne plus tronquer les labels.
- Labels acteurs courts dans la colonne timeline.
- Test widget de geometrie temporelle et non-mutation.
- Test widget de proportion utile preview/timeline.
- Visual Gate V1-56 en 1663x926.
- Roadmaps mises a jour : V1-56 est DONE et le clavier devient V1-57.

## 6. Contrat temporel confirme

Confirme :

- `startMs` reste derive par le read model, puis mappe en pixels ;
- `visualDurationMs` reste derive par le read model, puis mappe en largeur ;
- le curseur selectionne reste derive de `selectedStepId` ;
- la timeline ne stocke aucune nouvelle position temporelle ;
- le projet n'est pas mute par la selection, le hover, la mesure ou la capture.

## 7. Compatibilite V1-51 a V1-55

Preserve :

- axe temporel V1-51 ;
- lanes temporelles ;
- fallback visuel de duree ;
- curseur de selection V1-52 ;
- transport controls placeholders V1-53, maintenant icon-only pour ce correctif de proportions ;
- densite/proportions V1-54 ;
- hover details V1-55 ;
- inspecteur et preview sandbox.

## 8. Restrictions anti-scope

Confirme :

- pas de playback ;
- pas de timer, ticker ou animation de lecture ;
- pas de seek ;
- pas de scrubber ;
- pas de drag/drop ;
- pas de resize ;
- pas de reorder ;
- pas de zoom temporel ;
- pas de runtime preview ;
- pas de modification `map_runtime`, `map_gameplay`, `map_battle` ou `examples` ;
- pas de mutation JSON ou persistence temporelle.

## 9. Design system

Le changement UI reste dans le design system :

- `PokeMapCard` expose `borderRadius` avec valeur par defaut `12`.
- Les usages existants ne changent pas car la valeur par defaut preserve l'ancien rendu.
- Le Cinematic Builder demande seulement `borderRadius: 6` pour les barres temporelles.
- Aucun hardcoded `Color(...)`, `Colors.*`, `0xFF` ou `0xff` n'a ete ajoute dans les fichiers UI touches.

## 10. Tests ajoutes ou modifies

Ajoute :

- `renders timeline bars with corrected duration geometry`
- `balances sandbox preview and useful timeline grid proportions`
- `captures V1-56 timeline bar geometry correction when requested`

Le test de geometrie verifie :

- origine ticks/barres ;
- largeur Camera 500 ms ;
- debut `actorFace` a 500 ms ;
- debut et largeur `actorMove` 1000 ms ;
- `actorMove` au moins 1.9 fois plus large que Camera ;
- curseur aligne sur le tick selectionne ;
- labels hover/modes preserves ;
- absence de Seek/Scrubber ;
- absence de mutation `ProjectManifest`.

Le test de proportion utile verifie :

- timeline panel >= 420 px sur surface 1663x926 ;
- grille temporelle utile a moins de 90 px du haut du panneau timeline ;
- grille temporelle utile >= 335 px ;
- grille utile >= 78 % de la hauteur preview ;
- colonne pistes entre 124 et 136 px ;
- zone temporelle >= 83 % de la grille ;
- labels `Caméra`, acteur et `Dialogue` visibles avec largeur suffisante ;
- rangée Camera >= 46 px ;
- barre Camera >= 34 px ;
- piste Audio visible dans la grille ;
- preview sandbox <= 450 px ;
- timeline placee sous le preview.

## 11. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
```

Preuve fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
sha256 21c3f6cc18b1008286ad15d0be7afa857f9ff5a0bdcae49ff5fa2bf69f79776f
-rw-r--r--  1 karim  staff  233392 Jun  2 22:59 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
```

Observation visuelle : la grille commence immediatement sous les badges, la colonne `Pistes` est lisible avec les labels complets, les rangées/barres ont davantage de poids visuel et les controles de transport ne mangent plus l'espace vertical. La barre Camera couvre 0 -> 500 ms, `actorFace` demarre au tick 500 ms, `actorMove` demarre vers 1100 ms et couvre environ 1000 ms. Le curseur est aligne sur le bloc selectionne.

## 12. Validation

Commandes vertes :

- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders timeline bars with corrected duration geometry'`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and useful timeline grid proportions'`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
- `cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_56_CAPTURE_CINEMATIC_TIMELINE_BAR_GEOMETRY=true --reporter=compact test/cinematic_builder_workspace_test.dart`
- `cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart`
- `cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/design_system/pokemap_card.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart`

Limite hors scope :

- `cd packages/map_editor && flutter analyze` complet echoue sur 344 issues preexistantes, principalement le convertisseur Pokemon SDK (`pokemon_sdk_move_catalog_converter.dart`) et des infos/warnings hors fichiers V1-56.

## 13. Roadmap

V1-56 est propose DONE.

Prochain lot recommande :

```text
NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0
```
