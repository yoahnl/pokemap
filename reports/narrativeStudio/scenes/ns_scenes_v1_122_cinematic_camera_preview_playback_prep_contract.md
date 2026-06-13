# NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract

## 1. Résumé exécutif

V1-122 est une clôture documentaire : aucun code produit, aucun package, aucun runtime, aucun screenshot et aucune Visual Gate n'ont été créés.

Décision : le modèle actuel ne suffit pas pour une UI caméra fiable. `CinematicPreviewPlaybackFrame.cameraPose` existe, mais seulement comme placeholder `supported: false` avec `activeStepId`. Le prochain lot doit donc être `NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0`, puis `NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0`.

Option retenue : Option F, split read model puis renderer, avec Option C comme cible d'architecture : une caméra virtuelle editor-only, séparée du viewport d'édition.

## 2. Gate 0

- Lot exécuté : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`.
- Scope : doc-only / architecture-review / interaction-contract / UX-contract / technical-prep.
- Interprétation du prompt : conforme au repo ; le prompt demande explicitement de ne pas coder.
- Conflit documenté : `codex_rule.md` demande tests/build pour les lots généraux, mais V1-122 interdit les modifications packages, tests nouveaux, screenshots et code produit. La validation retenue est donc audit read-only + `git diff --check` + checks anti-scope.
- État initial Git : branche `main`, working tree initial propre.

## 3. Fichiers lus

Règles lues : `AGENTS.md`, `agent_rules.md`, `codex_rule.md`, `skills/README.md`, `skills/using-superpowers/SKILL.md`, `skills/test-driven-development/SKILL.md`, `skills/verification-before-completion/SKILL.md`. `codex_rules.md` est absent.

Rapports récents lus ou audités : V1-110, V1-111, V1-112, V1-113, V1-116, V1-117, V1-118, V1-119, V1-120, V1-121, Evidence Pack V1-121, `road_map_scenes.md`, `road_map_scene_builder_authoring.md`.

Rapports caméra/timeline/backdrop lus ou audités : V1-45, V1-51, V1-71, V1-82, V1-83, V1-84, V1-95, V1-95-bis.

Code lu en lecture seule : `cinematic_preview_playback_plan.dart`, `cinematic_timeline_time_layout_read_model.dart`, `cinematic_actor_display_preview_model.dart`, `cinematic_map_backdrop_preview_model.dart`, `cinematic_asset.dart`, `cinematic_authoring_operations.dart`, `map_core.dart`, et les widgets/editor demandés autour du Builder, du backdrop, des overlays, du fade et de la Library.

Tests lus en lecture seule : `cinematic_preview_playback_plan_test.dart`, `cinematic_timeline_time_layout_read_model_test.dart`, `cinematic_builder_workspace_test.dart`, `cinematics_library_workspace_test.dart`.

## 4. Rappel V1-121

V1-121 a branché la preview des blocs `Fondu` sur `CinematicPreviewPlaybackFrame.fadeState`. Le fade est editor-only, passif, au-dessus de la scène preview, et suit Play/Pause/Stop/Reset/seek/scrub sans runtime, Flame, GameState ni mutation projet.

Point utile pour la caméra : le fade consomme une source de vérité déjà calculée côté read model. La caméra doit suivre la même discipline : pas de recalcul temporel ou spatial dans l'UI.

## 5. Problème produit

Le Builder sait maintenant lire une preview locale : actors, manual path, animation, seek/scrub et fade. Mais un bloc `Camera` reste une intention de timeline. Il ne modifie pas le cadrage visible et ne porte pas encore assez d'informations pour le faire honnêtement.

Le risque principal est de confondre le viewport d'édition, déjà doté de `Carte entière`, `Vue scène`, zoom et pan locaux, avec la future caméra cinématique. Cette confusion rendrait Stop/Reset/seek/scrub ambigus et pourrait faire croire à une caméra runtime alors que la preview reste editor-only.

## 6. Définitions

- Editor Viewport : outil d'auteur pour regarder, paner, zoomer et éditer la scène dans le Builder.
- Cinematic Camera : intention de mise en scène portée par la timeline cinématique.
- Camera Preview : rendu editor-only de cette intention pendant la lecture ou le scrub.
- Camera Frame : résultat visuel à un temps donné après application de l'état caméra.
- Shot : portion temporelle de mise en scène produite par un bloc `Camera`.
- Camera Pose : état de caméra à un instant, par exemple centre, zoom, cible et progression.
- Camera Target : acteur, repère, position stage ou centre de scène que la caméra vise.
- Camera Zoom : facteur de cadrage cinématique, distinct du zoom d'édition.
- Camera Pan : déplacement du cadrage cinématique, distinct du pan d'édition.
- Camera Cut : changement instantané de cadrage.
- Camera Interpolation : transition temporelle entre deux poses caméra.
- Camera Playback State : source de vérité pure consommée par l'UI pour rendre la caméra au temps courant.
- Preview Framing : cadrage local du backdrop editor, existant aujourd'hui pour `Carte entière` / `Vue scène`.
- Map Backdrop Viewport : zone de rendu du décor map dans la preview.
- Stage Map Coordinates : coordonnées en tuiles ou sous-tuiles dans l'espace scène/map.
- Screen Coordinates : pixels locaux dans le widget de preview.
- Camera-safe area : zone visible garantie après cadrage caméra, utile pour ne pas masquer acteurs et repères importants.

Distinction non négociable : Editor Viewport = outil d'édition ; Cinematic Camera = intention cinématique ; Playback Camera Preview = visualisation editor-only ; Runtime Camera = hors scope.

## 7. Audit du bloc Camera existant

Stockage : les blocs Camera sont des `CinematicTimelineStep` de `kind: CinematicTimelineStepKind.camera`, avec `durationMs` et `metadata`.

Champs disponibles dans le modèle générique : `id`, `kind`, `label`, `durationMs`, `actorId`, `targetId`, `dialogueText`, `assetRef`, `metadata`. Le bloc Camera V0 utilise surtout `metadata['camera.mode']`.

Modes existants : `CinematicTimelineCameraMode.reset` et `CinematicTimelineCameraMode.hold`.

Durée : `cinematicTimelineDefaultCameraDurationMs = 500`, avec validation durée minimale commune.

Limite : aucun champ dédié ne décrit centre, zoom, cible, pan, easing, cut/interpolation ou safe area. Les tests existants vérifient même que le bloc Camera ajouté par la palette conserve `actorId == null` et `targetId == null`.

## 8. Audit du playback plan / cameraPose

Le plan V1-110 expose bien `CinematicCameraPlaybackPose`, mais sa structure actuelle est minimale :

```dart
final class CinematicCameraPlaybackPose {
  const CinematicCameraPlaybackPose({
    required this.supported,
    this.activeStepId,
  });

  final bool supported;
  final String? activeStepId;
}
```

Quand un item camera est actif, `frameAt` produit :

```dart
CinematicCameraPlaybackPose(
  supported: false,
  activeStepId: item.stepId,
)
```

Le plan ajoute aussi un diagnostic info `cinematicPreviewPlaybackCameraUnsupported` avec le message no-code : `La caméra de ce bloc sera cadrée dans un lot suivant.` Les capabilities indiquent `supportsCamera: false`.

Conclusion claire : le modèle actuel ne suffit pas ; V1-123 doit d'abord étendre la source de vérité core/read model.

## 9. Audit viewport / pan / zoom editor

Le backdrop editor possède déjà `CinematicBackdropPreviewFramingState` avec `mode`, `zoom`, `panTiles`, `showDetails` et `showGrid`. Les contrôles visibles sont `Carte entière`, `Vue scène`, zoom -, reset zoom, recentrage et zoom +.

Ces valeurs sont locales et editor-only. Elles servent à lire/éditer la scène, pas à décrire une intention cinématique. La future caméra ne doit donc pas les muter, ni les utiliser comme source de vérité durable.

## 10. Options comparées

Option A — Réutiliser le viewport d'édition comme caméra : refusée. Rapide, mais mélange outil auteur et caméra cinématique ; risque de casser `Carte entière`, `Vue scène`, pan et zoom.

Option B — Cadre caméra overlay uniquement : acceptable comme fallback ou première preuve visuelle, mais insuffisant comme trajectoire produit si l'objectif est de prévisualiser un cadrage réel.

Option C — Caméra virtuelle editor-only séparée du viewport : cible d'architecture retenue. Elle est fidèle, lisible et protège le viewport, mais exige un read model caméra clair.

Option D — Caméra runtime / Flame : refusée. Anti-scope massif, fuite runtime/GameState/Flame, et non nécessaire pour le Builder.

Option E — Reporter entièrement la caméra : sûr, mais trop faible après actors/fade/seek. À conserver seulement tant que le modèle est explicitement unsupported.

Option F — Split read model puis renderer : retenue. Le repo prouve que `cameraPose` est un placeholder ; séparer V1-123 read model et V1-124 UI évite une UI qui devine.

## 11. Décision retenue

Décision : Option F maintenant, Option C comme architecture cible.

V1-123 doit créer ou enrichir un `CinematicCameraPlaybackState` pur côté `map_core`, consommable par `frameAt`, sans UI et sans runtime. V1-124 branchera ensuite ce state dans le Builder pour rendre le cadrage ou un cadre de caméra.

## 12. Source de vérité future

La source de vérité caméra dépend du temps ; elle doit donc être calculée ou exposée par `map_core`.

Contrat recommandé :

```text
CinematicCameraPlaybackState
- activeStepId
- supported
- mode
- targetKind
- targetId
- centerX
- centerY
- zoom
- progress
- diagnostics
```

`map_editor` ne doit pas recalculer `startMs`, `endMs`, `durationMs`, progression ou diagnostics core. Il rend uniquement l'état produit par le plan.

## 13. Sémantique caméra V0

Le bloc Camera existant ne contient pas assez d'informations pour une caméra complète. La sémantique V0 réaliste est donc :

- support minimal `reset` / `hold` explicite dans le read model ;
- `reset` revient à un cadrage scène ou centre sûr si la scène est disponible ;
- `hold` garde le cadrage précédent si le read model peut le déterminer, sinon diagnostic partiel ;
- pas de zoom libre tant que le modèle ne le porte pas ;
- pas de pan libre tant que le modèle ne le porte pas ;
- cut instantané possible seulement s'il est explicite ;
- interpolation seulement si `progress` et deux poses sûres existent ;
- pas de follow actor permanent implicite ;
- pas de shake, collision, clamp gameplay, pathfinding ou runtime camera.

## 14. Séparation editor viewport / cinematic camera

Règles :

- `Carte entière` et `Vue scène` restent des contrôles d'édition.
- Le zoom editor local reste un outil d'auteur.
- Le pan editor local reste un outil d'auteur.
- La caméra cinématique ne réécrit jamais ces valeurs.
- Play/Pause/Stop/Reset/seek/scrub mettent à jour seulement le temps playback et donc le `Camera Playback State`.
- Sélectionner un bloc Camera peut afficher un aperçu discret ou un cadre, mais ne doit pas déplacer le temps ni muter le viewport.

## 15. Composition des couches

Ordre futur recommandé :

1. décor / map backdrop ;
2. couches foreground/background existantes ;
3. acteurs / animations ;
4. chemins et repères authoring si affichés ;
5. transform caméra preview ou cadre caméra ;
6. fade overlay V1-121 au-dessus de la scène ;
7. timeline, inspector, palette et UI hors caméra.

Le fade doit rester au-dessus du rendu caméra. Les acteurs sont dans la scène et doivent donc être affectés par le cadrage caméra. Les panneaux UI et la timeline restent hors caméra.

## 16. Interaction Play/Pause/Stop/Reset

Play : la caméra suit `frameAt(playbackTimeMs)` comme les acteurs et le fade.

Pause : la caméra reste figée au temps courant ; le viewport d'édition ne change pas.

Stop / Reset : `playbackTimeMs` revient à 0, puis la caméra preview revient à l'état calculé pour 0. Le Selection Cursor, le Mouse Time Probe et le viewport d'édition restent inchangés.

## 17. Interaction Seek/Scrub

Click-to-seek et drag-to-scrub doivent mettre à jour le `Camera Playback State` par le même chemin que Play. Le seek ne sélectionne pas automatiquement un bloc Camera, ne crée pas de Mouse Time Probe, et ne mute aucun pan/zoom editor.

## 18. Interaction Selection Cursor / Mouse Time Probe

Contrat maintenu :

- Selection Cursor = sélection auteur.
- Mouse Time Probe = inspection temporelle.
- Playback Playhead = temps courant.
- Camera Preview = rendu de la scène au temps courant.

Le Mouse Time Probe ne pilote pas la caméra playback. Clear probe ne reset pas la caméra. Stop/Reset reset la caméra uniquement via `time=0`.

## 19. Interaction actors / paths / stage points

`actorMove` reste calculé par le plan. La walking animation reste calculée par le resolver/renderer preview. Les manual paths et stage points restent authoring-only, mais s'ils sont affichés dans la scène, ils peuvent être cadrés avec elle en mode playback camera.

La caméra peut cadrer un acteur ; elle ne modifie jamais sa position. Elle peut faire sortir visuellement un repère du cadre ; elle ne le supprime pas.

## 20. Diagnostics / fallback caméra

Messages recommandés :

- `Caméra non prévisualisée dans cette version.`
- `Cadrage caméra incomplet.`
- `Cible caméra introuvable.`
- `Zoom caméra indisponible.`
- `Prévisualisation caméra partielle.`

À éviter en UX principale : `cameraPose unsupported`, `cameraState null`, `targetId`, `payload`, `JSON`, `runtime`.

Sévérités : info pour caméra ignorée volontairement ; warning pour cible manquante ou preview partielle ; error seulement si une future règle rend la scène impossible à prévisualiser.

## 21. Tests futurs

Tests core V1-123 :

- camera block produces camera playback state ;
- unsupported camera mode produces diagnostic ;
- progress est clampé ;
- `frameAt(t)` retourne un état déterministe ;
- unknown target ne crash pas et produit un diagnostic ;
- `supportsCamera` reflète réellement l'état supporté.

Tests editor V1-124 :

- preview caméra visible pendant un bloc Camera actif ;
- Play/Pause/Stop/Reset mettent à jour ou figent correctement la caméra ;
- click-to-seek et drag-to-scrub mettent à jour la caméra ;
- pan/zoom editor non mutés ;
- Selection Cursor et Mouse Time Probe inchangés ;
- fade overlay reste au-dessus ;
- actors restent synchronisés.

Tests anti-scope : aucun runtime, Flame, GameState, CameraComponent, PlayableMapGame, mutation ProjectManifest/CinematicAsset/MapData, coordonnées libres ou couleurs hardcodées.

## 22. Visual Gate future

Si V1-123 reste read model pur : pas de Visual Gate obligatoire.

Pour V1-124 UI : capture attendue avec Cinematic Builder ouvert, timeline visible, bloc Camera visible, Playback Playhead sur un temps camera actif, preview montrant cadrage ou cadre caméra, statut no-code, acteurs/fade si disponibles, et aucun label runtime/Flame/GameState.

## 23. Non-objectifs confirmés

Pas de code produit, pas de `map_core`, pas de `map_editor`, pas de runtime, pas de Flame, pas de GameState, pas de screenshot, pas de Visual Gate, pas de V1-123 démarré, pas de tests nouveaux, pas de CameraComponent, pas de PlayableMapGame, pas de pathfinding, pas de collision, pas de coordonnées libres.

## 24. Roadmap proposée

V1-122 : DONE documentaire.

Prochain lot recommandé : `NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0`.

Lot suivant proposé : `NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0`.

## 25. Commandes exécutées

Commandes initiales :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Commandes d'audit : `wc -l` sur rapports demandés, `rg` sur rapports/code/tests, `sed` sur règles, prompt, roadmaps et zones de code ciblées.

Validation finale : voir Evidence Pack V1-122 pour les sorties exactes.

Tests/build : non lancés volontairement. Raison : lot documentaire avec interdiction explicite de modifier packages/tests/code et pas d'implémentation à valider par Flutter/Dart. La validation applicable est `git diff --check` + anti-scope.

## 26. git diff --check/stat/name-only/status final

Les sorties finales exactes sont reproduites dans l'Evidence Pack V1-122 après création des rapports et mise à jour des roadmaps.

## 27. Risques restants

- Le futur `Camera Playback State` doit éviter de sur-modéliser trop tôt zoom/pan/interpolation.
- `hold` est ambigu sans pose précédente explicite ; V1-123 devra décider s'il produit un diagnostic ou une pose stable.
- L'UI V1-124 devra être très claire pour ne pas confondre framing editor et caméra cinématique.
- Le cadrage des overlays authoring-only devra être choisi explicitement : inclus dans scène cadrée ou superposé hors caméra.

## 28. Auto-critique

Ce qui est bien tranché : le modèle actuel est insuffisant, la source de vérité future doit être core/read model, le viewport d'édition ne doit pas être muté, et le split V1-123/V1-124 est nécessaire.

Ce qui reste incertain : la sémantique exacte de `reset` et `hold`, le niveau de support zoom/pan V0, et le choix entre transform réelle de scène ou cadre overlay pour la première UI.

Risque principal : coder trop vite V1-124 sans V1-123 ferait mentir la preview ou la ferait dépendre d'états editor locaux.

Bis documentaire recommandé : non. Le contrat est suffisant pour lancer V1-123 read model.

## 29. Verdict final

`NS-SCENES-V1-122 : DONE documentaire.`

Camera Preview Playback : contrat cadré.

Editor Viewport : séparé de Cinematic Camera.

Runtime Camera / Flame / GameState : hors scope.

Source de vérité future : définie côté read model/core.

Sémantique Camera V0 : définie prudemment.

Aucun code produit modifié. Aucun screenshot. V1-123 non démarré.

## 30. Prochain lot recommandé

`NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0`

Objectif : produire un état caméra pur, déterministe et diagnostiqué depuis le playback plan, sans UI et sans runtime, pour permettre ensuite une intégration visuelle honnête en V1-124.
