# NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0

## 1. Résumé exécutif

Statut : DONE.

Le Cinematic Builder permet maintenant d’ajouter et d’éditer un bloc `actorEmote` via une entrée de palette no-code `Émotion`. L’inspecteur affiche un workflow humain : choix de l’acteur, choix de la réaction depuis le catalogue V0, durée éditable, résumé et diagnostics no-code.

Ce lot ne rend pas encore la bulle d’émotion dans la preview. Il ne charge pas `emotions.png` / `emotions2.png`, ne modifie aucun pubspec, ne touche pas runtime/Flame/GameState et ne démarre pas V1-129.

## 2. Gate 0

```text
$ pwd
/Users/karim/Project/pokemonProject

$ git branch --show-current
main

$ git status --short --untracked-files=all

$ git diff --stat

$ git diff --name-only

$ git log --oneline -n 10
d864d502 NS-SCENES-V1-128 — Cinematic Timeline Zoom Controller V0
9e6d5c6e NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0
bf27192e NS-SCENES-V1-126 — Cinematic Emote Core Model Asset Catalog V0
7806431f NS-SCENES-V1-125 — Cinematic Emote Assets Reaction Bubble Prep Contract V0
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
```

État initial : worktree propre, aucun `selbrume/project.json` dirty.

Note : le commit HEAD porte le libellé `NS-SCENES-V1-128 — Cinematic Timeline Zoom Controller V0`, mais le lot exécuté ici est le V1-128 officiel demandé par le prompt : `Cinematic Emote Block Editor UI V0`. Je n’ai pas renommé l’historique Git.

## 3. Fichiers lus

Règles lues : `AGENTS.md`, `agent_rules.md`, `codex_rule.md`, `skills/README.md`, `skills/using-superpowers/SKILL.md`, `skills/test-driven-development/SKILL.md`, `skills/verification-before-completion/SKILL.md`, `skills/writing-plans/SKILL.md`.

Fichier absent documenté : `codex_rules.md` n’existe pas dans le repo.

Rapports / roadmaps audités : V1-120, V1-121, V1-124, V1-125, V1-126, V1-127, `road_map_scenes.md`, `road_map_scene_builder_authoring.md`.

Core audité : `cinematic_asset.dart`, `cinematic_emote_catalog.dart`, `cinematic_authoring_operations.dart`, `cinematic_diagnostics.dart`, `cinematic_preview_playback_plan.dart`, lane/time layout read models et export `map_core.dart`.

Editor/tests audités : Builder cinematic, Library cinematic, preview map backdrop, actor display overlay, playback actor overlay adapter, fade/camera overlays, tests Builder/Library/stage point/core emote.

## 4. Rappel V1-126 / V1-127

V1-126 fournit le modèle core : kind canonique `CinematicTimelineStepKind.actorEmote`, `actorId` sur le step, `emoteId` en metadata `actor.emoteId`, catalogue V0 typé, opérations pures add/update et diagnostics.

V1-127 expose les emotes actives dans `CinematicPreviewPlaybackFrame.activeEmotes`, mais sans UI, renderer, overlay ou asset loading.

## 5. Audit UI actorEmote existant

Verdict : avant V1-128, le core savait créer/diagnostiquer un bloc `actorEmote`, mais le Builder ne proposait pas d’entrée de palette ni d’inspecteur dédié. Les blocs existants wait/fade/camera/actorFace/actorMove avaient déjà les conventions nécessaires : callbacks parent, sélection du step créé, contrôles durée, pickers no-code et tests widget.

`activeEmotes` était uniquement préparé dans le read model V1-127 ; aucun rendu visuel n’était branché dans l’UI.

## 6. Décision d’architecture

Le Builder reste un client editor-only des opérations pures V1-126. L’écran parent applique les mutations au `ProjectManifest` en mémoire, comme les autres blocs d’authoring. Aucun modèle core n’a été modifié.

Les IDs `actorId` / `emoteId` restent techniques : ils servent aux clés de test et aux opérations, mais le workflow principal affiche les labels acteur et émotion.

## 7. Palette Émotion

Ajout d’une carte `Émotion` dans la palette des blocs cinématiques. Elle est activée si la cinématique possède au moins un acteur requis, selon la convention des blocs acteurs.

## 8. Inspecteur actorEmote

L’inspecteur du step `actorEmote` affiche :

- Type : `Émotion`
- Durée : durée editable existante
- Résumé : `Acteur affiche Réaction`
- Acteur : picker no-code
- Réaction : picker no-code depuis `cinematicEmoteCatalog`

Les sections techniques `Id`, `Kind`, `Metadata`, `actor.emoteId`, `frameIndex`, `sourceRect` ou `atlasRect` ne sont pas le workflow principal.

## 9. Picker acteur

Le picker liste les `requiredActors` de la cinématique et met à jour uniquement `actorId` sur le step. Changer l’acteur ne change pas l’émotion.

## 10. Picker réaction

Le picker liste les labels français du catalogue V0. Changer la réaction met à jour uniquement l’emote du step. Le picker n’affiche ni sprite atlas ni frame rect.

## 11. Durée

La durée utilise le même composant d’édition que les autres blocs authoring-owned. Le step garde `durationMs`; aucune durée dupliquée en metadata n’a été ajoutée.

## 12. Résumé timeline / labels

Le bloc ajouté ou édité reçoit un label humain, par exemple `Professor affiche Surprise`, `Rival affiche Question` ou `Professor affiche Coeur`. La timeline affiche ce résumé au lieu d’un label brut `actorEmote`.

## 13. Diagnostics UI

Les diagnostics core restent no-code côté inspecteur. Les tests vérifient aussi que les libellés techniques (`actor.emoteId`, `frameIndex`, `sourceRect`, `atlas`) ne deviennent pas le workflow principal.

## 14. Relation activeEmotes V1-127

V1-128 ne recalcule pas `activeEmotes` côté UI. Le bloc authoré est prêt pour le playback state V1-127, mais le rendu visuel est explicitement reporté à V1-129.

## 15. Relation assets / absence de rendu

Aucun asset image n’est chargé. `emotions.png` et `emotions2.png` ne sont ni copiés, ni déplacés, ni référencés par `Image.asset`, `rootBundle`, `ui.Image` ou `decodeImage`.

## 16. Non-objectifs confirmés

Non démarrés : V1-129, renderer emote, overlay emote, sprite atlas emote, runtime, Flame, GameState, SceneRuntimeExecutor, CinematicRuntimeAdapter, Timeline Zoom, Camera Target / Zoom, pubspec, assets racine, données Selbrume.

## 17. Hygiène de diff

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` : palette, inspecteur, callbacks locaux, contrôles actorEmote.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart` : passage des callbacks actorEmote au Builder.
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` : branchement aux opérations pures core add/update.
- `packages/map_editor/test/cinematic_builder_workspace_test.dart` : tests V1-128, fixture et Visual Gate.
- `packages/map_editor/test/cinematics_library_workspace_test.dart` : callbacks de harness.
- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-128 DONE, prochain lot V1-129.
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-128 DONE, prochain lot V1-129.

Fichiers créés :

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_128_evidence_pack.md`

Confirmation : pas de reformat global ; `dart format` a été lancé uniquement sur deux fichiers déjà modifiés et a répondu `0 changed`.

## Code généré / zones modifiées pertinentes

Callbacks Builder :

```dart
typedef AddCinematicActorEmoteStepCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required String emoteId,
  int? durationMs,
  String? afterStepId,
});

typedef UpdateCinematicActorEmoteStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  String? emoteId,
  int? durationMs,
});
```

Ajout / update dans le Builder :

```dart
Future<void> _addActorEmote() async {
  final actor = widget.asset.requiredActors.isEmpty
      ? null
      : widget.asset.requiredActors.first;
  if (actor == null) {
    return;
  }
  final createdStepId = await widget.onAddActorEmoteStep(
    cinematicId: widget.asset.id,
    actorId: actor.actorId,
    emoteId: cinematicDefaultActorEmoteId,
    durationMs: cinematicTimelineDefaultActorEmoteDurationMs,
    afterStepId: _selectedStepId,
  );
  if (!mounted || createdStepId == null) {
    return;
  }
  setState(() => _selectedStepId = createdStepId);
}

Future<void> _updateActorEmote(
  CinematicTimelineStep step, {
  String? actorId,
  String? emoteId,
  int? durationMs,
}) async {
  if (!isCinematicTimelineActorEmoteStep(step)) {
    return;
  }
  final updated = await widget.onUpdateActorEmoteStep(
    cinematicId: widget.asset.id,
    stepId: step.id,
    actorId: actorId,
    emoteId: emoteId,
    durationMs: durationMs,
  );
  if (!mounted || !updated || durationMs == null) {
    return;
  }
  setState(() {
    _timelineProbeTimeMs = null;
    _timelineProbeSnapHint = null;
  });
}
```

Palette :

```dart
class _ActorEmotePaletteTile extends StatelessWidget {
  const _ActorEmotePaletteTile({
    required this.asset,
    required this.onAddActorEmote,
  });

  final CinematicAsset asset;
  final _AddActorEmoteCallback onAddActorEmote;

  @override
  Widget build(BuildContext context) {
    final hasActors = asset.requiredActors.isNotEmpty;
    final description = hasActors
        ? 'Afficher une réaction'
        : 'Ajoutez un acteur pour afficher une réaction';
    return Stack(
      children: [
        PokeMapCard(
          onTap: hasActors ? onAddActorEmote : null,
          child: Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.chat_bubble,
                tone: PokeMapTone.brand,
                size: 30,
                iconSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StrongText('Émotion'),
                    const SizedBox(height: 2),
                    _MutedText(description),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: _TestHidden(
            hitTestable: true,
            child: PokeMapButton(
              key: const ValueKey(
                'cinematic-builder-palette-actor-emote-button',
              ),
              onPressed: hasActors ? onAddActorEmote : null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
```

Inspecteur actorEmote :

```dart
class _ActorEmoteControls extends StatelessWidget {
  const _ActorEmoteControls({
    required this.asset,
    required this.step,
    required this.onUpdateActorEmote,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final _UpdateActorEmoteCallback onUpdateActorEmote;

  @override
  Widget build(BuildContext context) {
    final selectedEmoteId = cinematicTimelineActorEmoteEmoteIdOf(step);
    final selectedEmote = cinematicEmoteCatalogEntryById(selectedEmoteId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _SectionTitle(title: 'Acteur', subtitle: 'Picker requis'),
        const SizedBox(height: 8),
        if (asset.requiredActors.isEmpty)
          const _MutedText('Ajoutez un acteur requis pour choisir qui réagit.')
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final actor in asset.requiredActors)
                _InlineControlAction(
                  label: _actorDisplayLabel(actor),
                  button: PokeMapButton(
                    key: ValueKey(
                      'cinematic-builder-actor-emote-actor-${actor.actorId}',
                    ),
                    onPressed: () {
                      onUpdateActorEmote(step, actorId: actor.actorId);
                    },
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: step.actorId == actor.actorId,
                    leading: const Icon(CupertinoIcons.person_crop_circle),
                    child: const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        _KeyValue(
          label: 'Réaction',
          value: selectedEmote?.label ?? 'Réaction à choisir',
        ),
        const _SectionTitle(title: 'Émotion', subtitle: 'Choix no-code'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final emote in cinematicEmoteCatalog)
              _InlineControlAction(
                label: emote.label,
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-emote-emote-${emote.id}',
                  ),
                  onPressed: () {
                    onUpdateActorEmote(step, emoteId: emote.id);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: selectedEmoteId == emote.id,
                  leading: const Icon(CupertinoIcons.chat_bubble),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        if (selectedEmote != null) ...[
          const SizedBox(height: 6),
          _MutedText(selectedEmote.description),
        ],
        const SizedBox(height: 8),
        _DurationEditorControls(
          currentDurationMs: _editableDurationMs(step),
          explicitDurationMs: step.durationMs,
          minDurationMs: _editableDurationMinimumMs(step),
          keyPrefix: 'cinematic-builder-actor-emote-duration',
          onDurationChanged: (durationMs) {
            return onUpdateActorEmote(step, durationMs: durationMs);
          },
        ),
      ],
    );
  }
}
```

Parent workspace :

```dart
Future<String?> _addCinematicTimelineActorEmote({
  required String cinematicId,
  required String actorId,
  required String emoteId,
  int? durationMs,
  String? afterStepId,
}) async {
  final project = widget.project;
  if (project == null) {
    return null;
  }
  try {
    final result = addCinematicTimelineActorEmoteStep(
      project,
      cinematicId: cinematicId,
      actorId: actorId,
      emoteId: emoteId,
      durationMs: durationMs,
      afterStepId: afterStepId,
    );
    widget.editorNotifier.applyInMemoryProjectManifest(
      result.updatedProject,
      statusMessage: 'Cinematic actor emote block created',
    );
    return result.step.id;
  } on ArgumentError {
    return null;
  }
}
```

Tests V1-128 ajoutés :

```dart
testWidgets('V1-128 palette adds actor emote block', (tester) async { ... });
testWidgets('V1-128 actor emote inspector lets user choose actor', (tester) async { ... });
testWidgets(
  'V1-128 actor emote inspector lets user choose no-code emote and duration',
  (tester) async { ... },
);
testWidgets(
  'captures V1-128 cinematic emote block editor ui visual gate',
  (tester) async { ... },
);
```

## 18. Tests RED

Phase RED exécutée avant implémentation avec :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-128"
```

Résultat : exit 1. Échecs attendus :

```text
Expected Émotion, found 0.
Expected Réaction, found 0.
Bad state: No element for missing emote button key before implementation.
```

## 19. Tests GREEN

Après implémentation :

```text
$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-128"
... +4: All tests passed!
```

## 20. Tests exécutés

```text
$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
... +7: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
... +5: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
... +9: All tests passed!

$ flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
... +26: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
... +263: All tests passed!

$ dart test --reporter=compact test/cinematic_emote_catalog_test.dart
... +3: All tests passed!

$ dart test --reporter=compact test/cinematic_authoring_operations_test.dart
... +71: All tests passed!

$ dart test --reporter=compact test/cinematic_diagnostics_test.dart
... +55: All tests passed!

$ dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
... +20: All tests passed!
```

Test helper dédié non lancé : aucun fichier `test/cinematic_emote_picker_test.dart` n’a été créé.

## 21. Analyse statique

```text
$ flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
Analyzing 2 items...
35 issues found. (ran in 1.9s)
```

Sortie complète : uniquement des infos `prefer_const_constructors` / `prefer_const_literals_to_create_immutables`, commande exit 0 grâce à `--no-fatal-infos`.

```text
$ dart analyze
Analyzing map_core...
No issues found!
```

## 22. Build macOS debug

```text
$ flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 23. Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
```

Preuve :

```text
$ ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
-rw-r--r--  1 karim  staff   196K Jun 14 18:39 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png

$ file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

$ shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
9b5996752af56ec06f9fd1752704f357162116c0e1edaeab708e28c7e7d3e7e1  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
```

Verdict visuel : Builder ouvert, palette `Émotion`, timeline avec bloc emote, inspecteur actorEmote, acteur sélectionné, réaction `Question`, durée visible, preview map visible, aucune bulle emote ou sprite atlas rendu.

## 24. Checks anti-scope

Avant les ajouts documentaires, les recherches diff code ont été exécutées :

```text
$ git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|ImageProvider|ui\.Image|rootBundle|decodeImage|Image\.asset|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-129" || true
Sortie : <vide>

$ git diff --name-only -- assets emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml
Sortie : <vide>

$ git diff --unified=0 | rg -n "EmotePreviewOverlay|emote overlay|drawEmote|paintEmote|activeEmotes.*Widget|activeEmotes.*paint|emotions\.png|emotions2\.png" || true
Sortie : <vide>

$ git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml
Sortie : <vide>

$ find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_129*' -print
Sortie : <vide>
```

## 25. Roadmaps mises à jour

`road_map_scenes.md` et `road_map_scene_builder_authoring.md` marquent V1-128 DONE et recommandent :

```text
NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0
```

V1-129 n’est pas démarré.

## 26. git diff final

```text
$ git diff --check
Sortie : <vide>

$ git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    | 338 +++++++++++++++++++--
 .../cinematics/cinematics_library_workspace.dart   |  22 ++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  62 ++++
 .../test/cinematic_builder_workspace_test.dart     | 310 +++++++++++++++++++
 .../test/cinematics_library_workspace_test.dart    |  36 +++
 .../scenes/road_map_scene_builder_authoring.md     |  54 ++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  58 ++--
 7 files changed, 812 insertions(+), 68 deletions(-)

$ git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

$ git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_128_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_128_cinematic_emote_block_editor_ui_v0.png
```

Note : les fichiers non suivis nouveaux sont visibles dans `git status`, pas dans `git diff --stat/name-only`.

## 27. Risques restants

- Le picker réaction est textuel ; sans sprite, le choix peut rester abstrait.
- Les labels du catalogue V0 sont suffisants pour démarrer, mais V1-129 devra valider leur lisibilité avec rendu visuel.
- L’inspecteur est fonctionnel mais dense, car il partage le même espace que les autres contrôles cinematic.
- Le résumé timeline humain est présent, mais il dépend des labels disponibles au moment de l’édition.

## 28. Auto-critique

L’UI est utilisable par une personne non technique parce qu’elle expose `Émotion`, `Acteur`, `Réaction`, `Durée` et des labels français. L’absence de sprites dans le picker rend toutefois le choix moins immédiat qu’un vrai aperçu visuel. Ce n’est pas un échec V1-128 : c’est précisément le verrou de V1-129.

Les diagnostics sont visibles via le workflow no-code, mais un futur bis pourrait encore polir les empty states si l’utilisateur travaille avec une cinématique sans acteur requis.

## 29. Verdict final

```text
NS-SCENES-V1-128 : DONE.
Emote Block Editor UI : implémenté.
Palette Émotion : active.
Inspecteur actorEmote : actif.
Picker acteur : actif.
Picker réaction : actif.
Durée : visible/éditable selon conventions existantes.
Diagnostics : visibles en no-code.
Timeline label : humain.
Rendu visuel emote : non démarré.
Assets racine : non déplacés, non copiés.
pubspec : non modifié.
Runtime / Flame / GameState : non touchés.
Visual Gate : créée.
V1-129 : recommandé, non démarré.
```

## 30. Prochain lot recommandé

`NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0`

Raison : le core, le playback state et l’authoring UI existent. Le prochain verrou propre est de rendre visuellement `frame.activeEmotes + frame.actorPoses` dans la preview playback editor-only.
