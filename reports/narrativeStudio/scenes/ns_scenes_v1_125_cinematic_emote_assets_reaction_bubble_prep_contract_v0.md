# NS-SCENES-V1-125 — Cinematic Emote Assets / Reaction Bubble Prep Contract V0

## 1. Résumé exécutif

Statut : `NS-SCENES-V1-125 : DONE documentaire`.

Ce lot cadre le futur système d’emotes cinématiques du Cinematic Builder sans implémenter de code produit. Les deux assets fournis par Karim à la racine du repo ont été audités :

- `/Users/karim/Project/pokemonProject/emotions.png`
- `/Users/karim/Project/pokemonProject/emotions2.png`

Décision retenue : `Option B future + Option C + Option F`.

- Les assets racine sont des candidats, pas des chemins produit finaux.
- Une future intégration devra les placer dans un chemin officiel, recommandé : `assets/cinematics/emotes/`.
- Le futur système doit passer par un catalogue typé avec IDs stables, labels no-code et rects techniques internes.
- Le bloc timeline futur recommandé est `actorEmote`.
- Les emotes V0 sont attachées aux acteurs et restent séparées des FX libres.

Aucun code Dart/Flutter n’a été généré ou modifié dans ce lot.

## 2. Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat: cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
```

Interprétation : `git status`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0. Le repo était propre avant V1-125.

## 3. Fichiers lus

Règles lues :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Écart : `codex_rules.md` est absent.

Rapports relus :

- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_123_cinematic_camera_playback_state_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_101_cinematic_stage_point_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_102_cinematic_preview_point_placement_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Code et tests lus en lecture seule :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart`

## 4. Rappel V1-124

V1-124 a branché l’état `CinematicPreviewPlaybackFrame.cameraPose` dans le Cinematic Builder avec un overlay/cadre caméra editor-only, des labels no-code et des diagnostics honnêtes.

Limite restante de V1-124 : la caméra reste symbolique. Le centre, le zoom, la cible et le pan réel ne sont pas encore authorables. Cette limite reste pertinente, mais le présent lot accepte de reporter Camera Target / Zoom en backlog pour privilégier les emotes.

## 5. Justification du pivot roadmap

La roadmap précédente recommandait :

```text
NS-SCENES-V1-125 — Cinematic Camera Target / Zoom Authoring Prep Contract
```

Le pivot vers les emotes est justifié pour quatre raisons :

- V1-124 donne déjà une caméra V0 suffisante pour continuer la démonstration du Builder.
- Les réactions visuelles sont plus immédiatement perceptibles dans une cinématique que le réglage fin de la caméra.
- Karim a fourni deux atlas candidats déjà présents dans le repo.
- Le Builder sait déjà afficher la map, les acteurs, le playback, les mouvements, les animations, le fade et le cadre caméra : il manque maintenant des réactions simples au-dessus des acteurs.

Camera Target / Zoom n’est pas abandonné. Il est replanifié en backlog :

```text
NS-SCENES-V1-129 — Cinematic Camera Target / Zoom Authoring Prep Contract
```

## 6. Audit des assets emotions.png / emotions2.png

Commande :

```bash
ls -lh /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
file /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
shasum -a 256 /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
sips -g pixelWidth -g pixelHeight /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff   849B Jun 14 12:59 /Users/karim/Project/pokemonProject/emotions.png
-rw-r--r--@ 1 karim  staff   1.9K Jun 14 12:59 /Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png:  PNG image data, 128 x 48, 8-bit colormap, non-interlaced
/Users/karim/Project/pokemonProject/emotions2.png: PNG image data, 128 x 48, 8-bit colormap, non-interlaced
09b9627648f16012042610ec159b95167e84559c6b4ae0fef09eb834d283ac9f  /Users/karim/Project/pokemonProject/emotions.png
f337639b596d145b306d3300b5f8144bc9387f329fd9fda743accfccb03643b0  /Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png
  pixelWidth: 128
  pixelHeight: 48
/Users/karim/Project/pokemonProject/emotions2.png
  pixelWidth: 128
  pixelHeight: 48
```

Déduction fiable :

- Les deux fichiers existent.
- Les deux fichiers sont des PNG `128 x 48`.
- Les deux fichiers sont des PNG à palette 8-bit, non interlacés.
- Si les frames sont uniformes en `16 x 16`, la grille est `8 colonnes x 3 lignes`, soit `24 slots`.

Hypothèse visuelle :

- `emotions.png` contient l’atlas principal de réactions : exclamation, question, colère/agacement, coeur, musique, pensée/silence et bulles neutres.
- `emotions2.png` semble plus sparse : il contient surtout des bases/bulles neutres ou variantes de fallback, avec beaucoup de cellules visuellement vides.

Statut produit :

- Ces fichiers sont des assets candidats.
- Ils ne doivent pas être chargés depuis la racine du repo dans le code produit final.
- Ils ne doivent pas être déplacés ou copiés dans V1-125.

## 7. Problème produit

Le Cinematic Builder sait déjà montrer une scène animée, mais il ne sait pas encore afficher des réactions simples :

- surprise ;
- interrogation ;
- colère ;
- coeur ;
- musique ;
- pensée ;
- alerte ;
- bulle neutre ;
- silence/hésitation.

Le problème n’est pas seulement graphique. Il faut décider :

- comment nommer les réactions en no-code ;
- comment mapper l’atlas vers un catalogue stable ;
- comment éviter le workflow `frame 12` ;
- comment attacher une emote à un acteur ;
- comment gérer la durée ;
- comment faire suivre l’emote pendant `actorMove` ;
- comment exposer l’état dans `frameAt(timeMs)` ;
- comment diagnostiquer asset, frame, acteur ou position manquants.

## 8. Définitions

`Emote` : réaction visuelle courte, destinée à exprimer un état ou une intention.

`Reaction Bubble` : bulle ou pictogramme affiché au-dessus d’un acteur pour matérialiser l’emote.

`Emote Atlas` : image contenant plusieurs frames d’emotes dans une grille.

`Emote Frame` : cellule technique de l’atlas. Elle est interne au catalogue, pas exposée comme choix utilisateur principal.

`Emote Catalog` : registre typé liant un ID stable, un label no-code, une description, un atlas et une frame rect.

`Emote ID` : identifiant stable du catalogue, par exemple `question` ou `heart`.

`Emote Slot` : position technique dans l’atlas. Ne doit pas être le workflow principal.

`Emote Target` : cible visuelle de l’emote. En V0, la cible recommandée est un acteur.

`Actor Emote` : bloc timeline attachant une emote à un acteur pendant une durée.

`Stage Emote` : emote attachée à un repère/stage point. Hors scope V0, possible plus tard.

`Emote Duration` : durée pendant laquelle l’emote est visible dans la preview.

`Emote Playback State` : état dérivé par le playback plan pour savoir quelles emotes sont actives à un temps donné.

`Emote Fallback` : comportement lisible quand l’acteur, la position, l’atlas ou la frame manque.

`Emote Preview Overlay` : couche de rendu editor-only affichant les emotes au-dessus des acteurs dans la preview.

Distinctions non négociables :

- Emote : réaction courte attachée acteur.
- FX : effet visuel plus libre, indépendant d’un acteur, reporté.
- Dialogue bubble : système de dialogue, pas une emote.
- Actor label : label d’authoring, pas une emote.
- Stage Point : repère de scène, pas une emote.

## 9. Audit actor/playback/asset pipeline existant

Constats utiles :

- `CinematicTimelineStepKind.actorEmote` existe déjà dans `cinematic_asset.dart`.
- Le playback plan traite déjà `actorPoses`, `fadeState` et `cameraPose`.
- `frameAt(timeMs)` est la bonne source future pour exposer les emotes actives, comme pour fade/camera/actor poses.
- Le renderer acteur sait déjà afficher des sprites/frames pendant le playback editor-only.
- L’asset pipeline cinematic existant passe par des registries/chargements editor-only, notamment `CinematicTilesetAssetRegistry`, mais il n’existe pas encore de registry emote.
- Le projet n’a pas de dossier racine `assets/` actuellement détecté par `find`.
- `packages/map_runtime/pubspec.yaml` déclare déjà des assets runtime pour `assets/battle_animations/`, mais V1-125 ne doit pas toucher aux pubspec.

Sortie ciblée `actorEmote` :

```text
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart:296:    CinematicTimelineStepKind.actorEmote =>
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart:383:    CinematicTimelineStepKind.actorEmote =>
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:666:      case CinematicTimelineStepKind.actorEmote:
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:800:      case CinematicTimelineStepKind.actorEmote:
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:1127:    CinematicTimelineStepKind.actorEmote ||
packages/map_core/lib/src/models/cinematic_asset.dart:8:  actorEmote,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11990:    CinematicTimelineStepKind.actorEmote => 'Émotion acteur',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12499:    CinematicTimelineStepKind.actorEmote => CupertinoIcons.person_crop_circle,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12560:    CinematicTimelineStepKind.actorEmote =>
```

Sortie ciblée playback :

```text
435:    required List<CinematicActorPlaybackPose> actorPoses,
436:    this.fadeState,
437:    CinematicCameraPlaybackPose? cameraPose,
440:        actorPoses = List<CinematicActorPlaybackPose>.unmodifiable(actorPoses),
441:        cameraPose =
442:            cameraPose ?? const CinematicCameraPlaybackPose.inactive(),
451:  final List<CinematicActorPlaybackPose> actorPoses;
452:  final CinematicFadePlaybackState? fadeState;
453:  final CinematicCameraPlaybackPose cameraPose;
536:  CinematicPreviewPlaybackFrame frameAt(int timeMs) =>
742:  CinematicFadePlaybackState? fadeState;
743:  var cameraPose = const CinematicCameraPlaybackPose.inactive();
815:    actorPoses: posesByActorId.values.toList(),
816:    fadeState: fadeState,
817:    cameraPose: cameraPose,
```

## 10. Options comparées

Option A — Charger directement `emotions.png` depuis la racine du projet.

Verdict : refusée. C’est rapide mais non portable, local à la machine de Karim, fragile en CI/build et contraire au statut “asset candidat”.

Option B — Déplacer/copier les assets dans un dossier officiel d’assets.

Verdict : retenue pour un futur lot. C’est portable et propre, mais cela nécessite une décision de chemin, un asset registry et probablement une mise à jour pubspec ou une convention de projet. Interdit en V1-125.

Option C — Créer un catalogue emote typé basé sur atlas + frame rects.

Verdict : retenue. C’est robuste, testable, compatible diagnostics et no-code. Les frame rects restent des données techniques internes.

Option D — Utiliser uniquement un enum fixe d’emotes sans catalogue asset.

Verdict : acceptable seulement comme raccourci interne, pas comme contrat principal. L’enum seul ne suffit pas à diagnostiquer les atlas/frame rects ni à préparer des packs d’emotes.

Option E — Laisser l’utilisateur choisir une frame libre dans l’atlas.

Verdict : refusée en V0. C’est flexible mais trop technique et contraire au no-code.

Option F — Séparer Emote et FX dès maintenant.

Verdict : retenue. L’emote V0 reste actor-bound ; les FX libres sont un système futur distinct.

## 11. Décision retenue

Décision globale :

```text
Option B future + Option C + Option F
```

Concrètement :

- V1-126 doit implémenter le modèle core authoring du bloc `actorEmote` et le catalogue V0.
- Les assets doivent rester candidats tant qu’ils ne sont pas intégrés dans un chemin officiel.
- Les choix utilisateur doivent passer par labels et aperçus no-code, pas par `row`, `column`, `frameIndex` ou `sourceRect`.
- `actorEmote` est attaché à un acteur et suit l’acteur pendant le playback.
- Les FX libres, stage emotes et coordonnées libres sont reportés.

## 12. Contrat modèle futur

Noms indicatifs alignés avec le style existant :

- `CinematicEmoteAtlas`
- `CinematicEmoteCatalogEntry`
- `CinematicEmoteId`
- `CinematicActorEmoteBinding`
- `CinematicEmotePlaybackState`
- `CinematicActorEmotePlaybackPose`

Bloc timeline futur :

```text
CinematicTimelineStepKind.actorEmote
```

Champs V0 recommandés :

- `actorId` : requis, référence un acteur cinematic.
- `emoteId` : requis, référence une entrée de catalogue.
- `durationMs` : requis, borné par presets.
- `verticalOffsetPreset` : optionnel, valeur par défaut `aboveHead`.

Stocké :

- acteur ;
- emote ;
- durée ;
- éventuel preset de placement.

Dérivé :

- frame rect ;
- atlas ;
- position écran à partir de `actorPose` ;
- visibilité active à partir de `frameAt(timeMs)`.

Diagnostiqué :

- acteur manquant ;
- acteur sans position ;
- emote inconnue ;
- atlas manquant ;
- frame invalide ;
- durée invalide.

Hors scope :

- stagePoint target ;
- coordonnées libres ;
- FX libres ;
- animation multi-frame complexe ;
- runtime/Flame/GameState.

## 13. Catalogue emotes V0 proposé

Hypothèse technique commune :

- atlas principal : `emotions.png`
- dimensions : `128 x 48`
- grille probable : `8 x 3`
- frame probable : `16 x 16`

Catalogue V0 proposé, à valider en V1-126 avec inspection visuelle produit :

| ID stable | Label no-code | Description | Atlas candidat | Rect technique secondaire |
|---|---|---|---|---|
| `surprise` | Surprise | Réaction forte ou découverte soudaine. | `emotions.png` | row 0, col 0, rect `(0, 0, 16, 16)` |
| `alert` | Alerte | Attention immédiate. | `emotions.png` | row 0, col 1, rect `(16, 0, 16, 16)` |
| `anger` | Colère | Agacement ou colère courte. | `emotions.png` | row 0, col 2, rect `(32, 0, 16, 16)` |
| `thought` | Pensée | Pensée ou réflexion. | `emotions.png` | row 0, col 4, rect `(64, 0, 16, 16)` |
| `question` | Question | Interrogation. | `emotions.png` | row 1, col 4, rect `(64, 16, 16, 16)` |
| `music` | Musique | Chant, joie ou note musicale. | `emotions.png` | row 1, col 2, rect `(32, 16, 16, 16)` |
| `idea` | Idée | Compréhension ou idée soudaine. | `emotions.png` | row 1, col 3, rect `(48, 16, 16, 16)` |
| `heart` | Coeur | Affection ou joie douce. | `emotions.png` | row 2, col 2, rect `(32, 32, 16, 16)` |
| `strongHeart` | Coeur fort | Affection plus marquée. | `emotions.png` | row 2, col 3, rect `(48, 32, 16, 16)` |
| `sweat` | Gêne | Malaise, peur légère ou embarras. | `emotions.png` | row 2, col 4, rect `(64, 32, 16, 16)` |
| `silence` | Silence | Hésitation ou silence. | `emotions.png` | row 2, col 6, rect `(96, 32, 16, 16)` |
| `neutral` | Bulle neutre | Bulle neutre/fallback. | `emotions2.png` | row 0, col 0, rect `(0, 0, 16, 16)` |

Important : les rects sont des données internes de catalogue. Elles ne doivent pas apparaître comme workflow principal dans l’inspecteur.

## 14. Relation actors

Décision V0 :

- Une emote est liée à un acteur.
- Si l’acteur se déplace, l’emote suit la position `actorPose` courante.
- Si l’acteur est supprimé ou introuvable, l’emote reste dans la timeline mais produit un diagnostic no-code.
- Si l’acteur n’a pas de position au temps courant, la preview tente une position statique connue ; sinon elle n’affiche pas l’emote.
- L’emote se place au-dessus de la tête/sprite acteur, pas au-dessus du label authoring.

Diagnostics V0 :

- `emoteMissingActor`
- `emoteActorWithoutPosition`
- `emoteActorNotRenderable`

## 15. Relation timeline / duration

Décision V0 :

- `durationMs` contrôle la visibilité.
- Durée par défaut recommandée : `800 ms`.
- Presets no-code : `Court`, `Normal`, `Long`.
- Pas de keyframes.
- Pas de fade-in/fade-out en V0.
- Pas de boucle animée tant que l’atlas ne prouve pas une animation multi-frame.

Bornes futures recommandées :

- minimum : `200 ms`
- défaut : `800 ms`
- maximum : `3000 ms` pour V0 editor-friendly

## 16. Relation playback / seek / scrub

Décision :

- L’état actif doit être calculé dans `map_core` par le playback plan.
- `CinematicPreviewPlaybackFrame` doit exposer les emotes actives, comme il expose déjà `actorPoses`, `fadeState` et `cameraPose`.
- Play affiche les emotes actives.
- Pause fige l’état.
- Click-to-seek et drag-to-scrub recalculent les emotes via `frameAt(timeMs)`.
- Stop/Reset reviennent à l’état de `timeMs = 0`.
- Aucune mutation de `CinematicAsset`, `ProjectManifest` ou `MapData`.

## 17. Relation renderer preview

Décision :

- L’emote est un élément cinematic final preview-only, pas un simple chrome d’authoring.
- Elle est rendue dans la scène au-dessus du sprite acteur.
- Elle devrait être sous le fade, car le fade représente la composition cinématique finale.
- Les labels/handles restent du chrome editor et peuvent rester au-dessus.
- L’overlay emote doit être `IgnorePointer`.
- Il ne doit pas bloquer Stage Point drag, seek/scrub, sélection de barre ou actor overlay.

## 18. Relation assets / asset registry

Chemins comparés :

- `assets/cinematics/emotes/` : recommandé, projet clair, domaine cinematic explicite.
- `packages/map_editor/assets/cinematics/emotes/` : possible pour assets editor-only embarqués, mais moins aligné avec assets projet.
- `assets/pokemap/cinematics/emotes/` : explicite mais plus verbeux.
- racine repo : refusé.

Décision future recommandée :

```text
assets/cinematics/emotes/emotions.png
assets/cinematics/emotes/emotions2.png
```

Intégration future probable :

- création du dossier officiel ;
- copie/déplacement contrôlé dans un lot futur ;
- catalog asset registry editor-only ;
- test d’existence ;
- validation dimensions/grille ;
- cache/preload image pour la preview ;
- fallback no-code si image absente.

V1-125 ne crée aucun dossier, ne copie aucun asset et ne modifie aucun pubspec.

## 19. UX future inspecteur

Structure recommandée :

```text
Bloc Emote

Acteur
[Picker acteur]

Réaction
[Picker emote visuel]

Durée
[Court] [Normal] [Long]
```

États :

- aucun acteur : `Ajoutez d’abord un acteur à la scène.`
- catalogue indisponible : `Bibliothèque d’emotes indisponible.`
- acteur introuvable : `Acteur introuvable.`
- emote inconnue : `Emote indisponible.`

Interdits UX :

- `actorId` comme saisie libre ;
- `emoteId` comme saisie libre ;
- `frameIndex` ;
- `sourceRect` ;
- `atlas path` ;
- JSON.

## 20. Diagnostics futurs

| Code | Déclencheur | Sévérité | Message no-code | Effet preview | Test futur |
|---|---|---|---|---|---|
| `emoteMissingActor` | `actorId` inconnu | error | Acteur de l’emote introuvable. | Emote masquée. | actorEmote avec acteur absent |
| `emoteActorWithoutPosition` | acteur connu sans position résolue | warning | Position de l’acteur indisponible. | Emote masquée ou fallback statique. | frameAt pendant pose absente |
| `emoteMissingCatalogEntry` | `emoteId` inconnu | error | Emote indisponible. | Emote masquée. | catalog sans ID |
| `emoteMissingAtlas` | atlas absent | error | Image d’emote introuvable. | Emote fallback ou masquée. | atlas manquant |
| `emoteInvalidFrame` | rect hors grille | error | Prévisualisation de l’emote partielle. | Emote fallback ou masquée. | rect invalide |
| `emoteAssetUnavailable` | image non chargée | warning | Bibliothèque d’emotes indisponible. | Emote fallback temporaire. | registry retourne null |
| `emoteDurationInvalid` | durée hors bornes | error | Durée d’emote invalide. | Bloc diagnostiqué, preview bornée ou masquée. | duration 0 / trop longue |

Interdits dans les messages principaux : `atlasRect`, `sourceRect`, `frameIndex`, `row`, `column`, `assetPath`, `emotions.png`.

## 21. Tests futurs

Assets/catalog :

- atlas file exists in official asset location ;
- atlas dimensions match expected grid ;
- catalog entries have unique IDs ;
- catalog entries point to valid frame rects ;
- missing atlas produces diagnostic ;
- invalid frame produces diagnostic.

Core model :

- `actorEmote` serializes/deserializes ;
- old cinematic JSON remains compatible ;
- missing actor produces diagnostic ;
- missing emote catalog entry produces diagnostic ;
- invalid duration produces diagnostic ;
- changing `emoteId` does not mutate actor.

Authoring operations :

- add `actorEmote` block ;
- update actor ;
- update emote ;
- update duration ;
- remove `actorEmote` ;
- switching actor keeps emote ;
- deleting actor surfaces diagnostic.

Playback read model :

- `frameAt` during emote block exposes active emote ;
- `frameAt` outside block exposes no emote ;
- emote follows actor pose during `actorMove` ;
- pause/seek/scrub are deterministic through `frameAt` ;
- missing actor pose returns diagnostic.

Editor UI :

- palette adds Emote block ;
- inspector shows actor picker ;
- inspector shows emote picker no-code ;
- no `frameIndex`/`sourceRect` visible ;
- preview shows emote above actor ;
- preview hides emote outside duration ;
- seek/scrub updates emote ;
- fade composition remains correct.

Anti-scope :

- no runtime/Flame/GameState ;
- no root absolute asset path in product code ;
- no hardcoded Selbrume/Timi/Lysa/Jean ;
- no pathfinding/collision.

## 22. Non-objectifs confirmés

Non réalisés :

- V1-126 ;
- code Dart ;
- tests Dart/Flutter nouveaux ;
- screenshot ;
- Visual Gate ;
- déplacement/copie de `emotions.png` ou `emotions2.png` ;
- modification pubspec ;
- modèle Emote codé ;
- catalogue Emote codé ;
- bloc timeline Emote codé ;
- inspecteur Emote ;
- renderer Emote ;
- preview Emote ;
- asset registry Emote ;
- runtime cinematic playback ;
- Flame ;
- GameState ;
- pathfinding/collision ;
- hardcode Selbrume/Timi/Lysa/Jean.

## 23. Roadmap proposée

Prochain lot exact recommandé :

```text
NS-SCENES-V1-126 — Cinematic Emote Core Model / Asset Catalog V0
```

Objectif : implémenter le modèle core authoring du bloc `actorEmote` et le catalogue emote V0, avec JSON backward-compatible, diagnostics et tests, sans UI ni renderer.

Suite prévisionnelle :

- `NS-SCENES-V1-127 — Cinematic Emote Block Editor UI V0`
- `NS-SCENES-V1-128 — Cinematic Emote Preview Playback UI V0`
- `NS-SCENES-V1-129 — Cinematic Camera Target / Zoom Authoring Prep Contract`

## 24. Commandes exécutées

Commandes d’audit et de preuve :

- `pwd`
- `git branch --show-current`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git diff --name-only`
- `git log --oneline -n 10`
- `ls -lh AGENTS.md agent_rules.md codex_rule.md codex_rules.md skills/README.md skills/using-superpowers/SKILL.md skills/test-driven-development/SKILL.md skills/verification-before-completion/SKILL.md skills/writing-plans/SKILL.md 2>&1`
- `ls -lh /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png`
- `file /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png`
- `shasum -a 256 /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png`
- `sips -g pixelWidth -g pixelHeight /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png`
- `git ls-files -- emotions.png emotions2.png`
- `find /Users/karim/Project/pokemonProject -maxdepth 4 \( -name 'emotions.png' -o -name 'emotions2.png' \) -print`
- `rg -n "actorEmote" ...`
- `rg -n "actorPoses|fadeState|cameraPose|frameAt" ...`
- `rg -n "assets:|CinematicTilesetAssetRegistry|rootBundle|ImageProvider|ui\.Image|tilesetsDirectoryPath|getTilesetRelativePath" ...`
- `find assets -maxdepth 3 -type d -print 2>&1`

Tests Dart/Flutter : non lancés, car V1-125 est strictement documentaire et aucun package n’a été modifié.

## 25. git diff --check/stat/name-only/status final

Commande :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Sortie `git diff --check` :

```text
Sortie : <vide>
```

Sortie `git diff --stat` :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 53 +++++++++++++-------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 56 +++++++++++++++-------
 2 files changed, 74 insertions(+), 35 deletions(-)
```

Sortie `git diff --name-only` :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Sortie `git status --short --untracked-files=all` :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_125_cinematic_emote_assets_reaction_bubble_prep_contract_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_125_evidence_pack.md
```

Note : les deux nouveaux rapports sont non indexés, donc `git diff --stat` ne les compte pas ; ils sont visibles dans `git status`.

Checks anti-scope :

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_125*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_126*' -print
```

Sortie :

```text
Sortie : <vide>
```

Contrôle roadmap :

Commande :

```bash
rg -n "NS-SCENES-V1-125 — Cinematic Camera Target / Zoom Authoring Prep Contract" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Sortie :

```text
Sortie : <vide>
```

## 26. Risques restants

- La lecture sémantique de certaines cellules de `emotions.png` reste visuelle et peut être corrigée par Karim/design en V1-126.
- `emotions2.png` semble sparse ; son rôle exact doit rester fallback/base bubble tant qu’il n’est pas validé.
- Le choix `assets/cinematics/emotes/` est recommandé, mais le repo n’a pas encore de dossier racine `assets/`.
- Le modèle actor-only est volontairement restrictif ; les stage emotes ou FX libres devront être cadrés plus tard.
- La composition exacte avec fade et chrome authoring devra être prouvée visuellement en V1-128.

## 27. Auto-critique

Ce qui est bien tranché :

- refus du chargement depuis la racine ;
- refus du choix par frame libre ;
- séparation Emote/FX ;
- `actorEmote` comme bloc V0 ;
- V1-126 comme prochain lot unique.

Ce qui reste incertain :

- les labels exacts de certaines cellules ;
- le rôle précis de `emotions2.png` ;
- le chemin officiel d’assets si le projet décide de privilégier des assets embarqués editor-only plutôt que des assets projet ;
- la suffisance d’un modèle actor-only si Karim veut très vite des réactions sur un repère ou un objet de map.

Fiabilité de l’hypothèse `16 x 16 / 8 x 3` :

- forte sur la base des dimensions `128 x 48` et de l’inspection visuelle ;
- pas encore une vérité de catalogue codée.

Un bis documentaire n’est pas recommandé : V1-126 peut démarrer directement avec un test-driven core model/catalog si cette décision est acceptée.

## 28. Verdict final

```text
NS-SCENES-V1-125 : DONE documentaire.
Emote Assets / Reaction Bubble : contrat cadré.
Assets racine : audités.
Catalogue V0 : proposé.
actorEmote : cadré.
Assets product path futur : recommandé.
Runtime / Flame / GameState : hors scope.
Aucun code produit modifié.
Aucun asset déplacé/copié.
Aucun screenshot.
V1-126 : recommandé, non démarré.
```

## 29. Prochain lot recommandé

```text
NS-SCENES-V1-126 — Cinematic Emote Core Model / Asset Catalog V0
```
