# NS-SCENES-V1-132 — Cinematic Camera Target / Zoom Editor UI V0

## 1. Resume executif

Statut : DONE.

Le Cinematic Builder expose maintenant l'authoring no-code Camera Target / Zoom dans l'inspecteur Camera :

- modes : `Réinitialiser le cadrage`, `Maintenir le cadrage`, `Cadrer une cible` ;
- cible focus : `Centre de la scène`, `Acteur`, `Repère` ;
- pickers lisibles pour les acteurs de la cinematique et les reperes de scene ;
- plan camera : `Plan large`, `Plan moyen`, `Gros plan` ;
- message explicite : `Cadrage configuré, preview réelle à venir.`

Le lot reste strictement authoring UI. Aucun centre camera, zoom numerique, pan, interpolation, renderer camera reel, runtime, Flame, GameState ou mutation du viewport editor n'a ete ajoute.

## 2. Rappel V1-131

Precondition verifiee avant implementation : V1-131 existe dans `map_core`.

Elements trouves :

```text
CinematicTimelineCameraMode.focus
CinematicCameraTargetKind
CinematicCameraZoomPreset
CinematicCameraTargetBinding
CinematicTimelineCameraFocusBinding
cinematicTimelineCameraFocusBindingOf
addCinematicTimelineCameraFocusStep
```

Le lot V1-132 consomme donc le modele core existant, sans recreer de modele local dans `map_editor`.

## 3. Audit initial

Etat initial Git : branche `main`, worktree propre au Gate 0.

Regles lues :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

`codex_rules.md` est absent ; `codex_rule.md` est present et a ete applique.

Passes :

- passe UI : inspecteur Camera, bindings typés, labels no-code ;
- passe tests : RED partiel puis GREEN V1-132, regressions V1-124/V1-129/Library ;
- passe Visual Gate : capture PNG generee et verifiee ;
- passe anti-scope : aucun runtime/Flame/GameState/Selbrume/assets/pubspec touche.

## 4. Decisions UI

Le mode `focus` active un binding valide immediatement :

```text
target = sceneCenter
zoomPreset = medium
```

Ce choix evite un etat focus incomplet des la premiere activation.

Les changements de cible utilisent exclusivement les bindings typés V1-131 :

```dart
CinematicCameraTargetBinding.sceneCenter()
CinematicCameraTargetBinding.actor(actorId: actorId)
CinematicCameraTargetBinding.stagePoint(stagePointId: stagePointId)
```

Les changements de zoom recreent un `CinematicTimelineCameraFocusBinding` en preservant la cible selectionnee.

Reset et hold passent `cameraFocusBinding: null` a l'operation core, qui nettoie les metadata cible/zoom.

## 5. Fichiers modifies

Code :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

Rapports / roadmaps :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_132_cinematic_camera_target_zoom_editor_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_132_evidence_pack.md`

Visual Gate :

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_132_cinematic_camera_target_zoom_editor_ui_v0.png`

## 6. Comportement ajoute

Code principal ajoute dans `cinematic_builder_workspace.dart` :

```dart
class _CameraModeControls extends StatelessWidget {
  const _CameraModeControls({
    required this.asset,
    required this.step,
    required this.onUpdateBasicBlock,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    final currentMode = cinematicTimelineCameraModeOf(step);
    final focusBinding = _cameraFocusBindingOrDefault(step);
    final targetKind = focusBinding.target.kind;
    final actors = asset.requiredActors;
    final stagePoints =
        asset.stageContext?.stagePoints ?? const <CinematicStagePoint>[];
    const modes = [
      CinematicTimelineCameraMode.reset,
      CinematicTimelineCameraMode.hold,
      CinematicTimelineCameraMode.focus,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KeyValue(
          label: 'Mode caméra',
          value: currentMode == null
              ? 'Mode à choisir'
              : _cameraModeLabel(currentMode),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final mode in modes)
              _InlineControlAction(
                label: _cameraModeLabel(mode),
                button: PokeMapButton(
                  key: ValueKey('cinematic-builder-camera-mode-${mode.name}'),
                  onPressed: () {
                    onUpdateBasicBlock(
                      step,
                      cameraMode: mode,
                      cameraFocusBinding:
                          mode == CinematicTimelineCameraMode.focus
                              ? focusBinding
                              : null,
                    );
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentMode == mode,
                  leading: Icon(_cameraModeIcon(mode)),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (currentMode == CinematicTimelineCameraMode.reset)
          const _MutedText(
              'Réinitialise le cadrage caméra. Aucune cible requise.')
        else if (currentMode == CinematicTimelineCameraMode.hold)
          const _MutedText('Conserve le cadrage courant. Aucune cible requise.')
        else if (currentMode == CinematicTimelineCameraMode.focus) ...[
          const _SectionTitle(title: 'Cible', subtitle: 'Choix no-code'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InlineControlAction(
                label: _cameraTargetKindLabel(
                  CinematicCameraTargetKind.sceneCenter,
                ),
                button: PokeMapButton(
                  key: const ValueKey(
                    'cinematic-builder-camera-target-sceneCenter',
                  ),
                  onPressed: () => _updateFocusTarget(
                    CinematicCameraTargetBinding.sceneCenter(),
                    focusBinding.zoomPreset,
                  ),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected:
                      targetKind == CinematicCameraTargetKind.sceneCenter,
                  leading: const Icon(CupertinoIcons.scope),
                  child: const SizedBox.shrink(),
                ),
              ),
              _InlineControlAction(
                label: _cameraTargetKindLabel(CinematicCameraTargetKind.actor),
                button: PokeMapButton(
                  key: const ValueKey(
                    'cinematic-builder-camera-target-actor',
                  ),
                  onPressed: actors.isEmpty
                      ? null
                      : () => _updateFocusTarget(
                            CinematicCameraTargetBinding.actor(
                              actorId: _selectedCameraTargetActorId(
                                    focusBinding,
                                    asset,
                                  ) ??
                                  actors.first.actorId,
                            ),
                            focusBinding.zoomPreset,
                          ),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: targetKind == CinematicCameraTargetKind.actor,
                  leading: const Icon(CupertinoIcons.person_crop_circle),
                  child: const SizedBox.shrink(),
                ),
              ),
              _InlineControlAction(
                label: _cameraTargetKindLabel(
                  CinematicCameraTargetKind.stagePoint,
                ),
                button: PokeMapButton(
                  key: const ValueKey(
                    'cinematic-builder-camera-target-stagePoint',
                  ),
                  onPressed: stagePoints.isEmpty
                      ? null
                      : () => _updateFocusTarget(
                            CinematicCameraTargetBinding.stagePoint(
                              stagePointId: _selectedCameraTargetStagePointId(
                                    focusBinding,
                                    stagePoints,
                                  ) ??
                                  stagePoints.first.id,
                            ),
                            focusBinding.zoomPreset,
                          ),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected:
                      targetKind == CinematicCameraTargetKind.stagePoint,
                  leading: const Icon(CupertinoIcons.location),
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (targetKind == CinematicCameraTargetKind.sceneCenter)
            const _MutedText(
              'Cadrage sur le centre de la carte / scène préparée.',
            )
          else if (targetKind == CinematicCameraTargetKind.actor) ...[
            const _KeyValue(label: 'Acteur à cadrer', value: 'Liste actorisée'),
            const SizedBox(height: 6),
            if (actors.isEmpty)
              const _MutedText('Aucun acteur disponible.')
            else
              _InspectorDropdownField<String>(
                key: const ValueKey(
                  'cinematic-builder-camera-target-actor-dropdown',
                ),
                value: _selectedCameraTargetActorId(focusBinding, asset),
                hint: 'Choisir un acteur',
                items: [
                  for (final actor in actors)
                    MacosPopupMenuItem<String>(
                      key: ValueKey(
                        'cinematic-builder-camera-target-actor-${actor.actorId}',
                      ),
                      value: actor.actorId,
                      child: Text(_actorDisplayLabel(actor)),
                    ),
                ],
                onChanged: (actorId) {
                  if (actorId == null) {
                    return;
                  }
                  _updateFocusTarget(
                    CinematicCameraTargetBinding.actor(actorId: actorId),
                    focusBinding.zoomPreset,
                  );
                },
              ),
          ] else ...[
            const _KeyValue(label: 'Repère à cadrer', value: 'Repère de scène'),
            const SizedBox(height: 6),
            if (stagePoints.isEmpty)
              const _MutedText(
                'Aucun repère disponible. Ajoutez d’abord un repère dans la preview.',
              )
            else
              _InspectorDropdownField<String>(
                key: const ValueKey(
                  'cinematic-builder-camera-target-stage-point-dropdown',
                ),
                value: _selectedCameraTargetStagePointId(
                  focusBinding,
                  stagePoints,
                ),
                hint: 'Choisir un repère',
                items: [
                  for (final point in stagePoints)
                    MacosPopupMenuItem<String>(
                      key: ValueKey(
                        'cinematic-builder-camera-target-stage-point-${point.id}',
                      ),
                      value: point.id,
                      child: Text(point.label),
                    ),
                ],
                onChanged: (stagePointId) {
                  if (stagePointId == null) {
                    return;
                  }
                  _updateFocusTarget(
                    CinematicCameraTargetBinding.stagePoint(
                      stagePointId: stagePointId,
                    ),
                    focusBinding.zoomPreset,
                  );
                },
              ),
          ],
          if (stagePoints.isEmpty &&
              targetKind != CinematicCameraTargetKind.stagePoint) ...[
            const SizedBox(height: 6),
            const _MutedText(
              'Aucun repère disponible. Ajoutez d’abord un repère dans la preview.',
            ),
          ],
          const SizedBox(height: 8),
          const _SectionTitle(title: 'Plan', subtitle: 'Preset de cadrage'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final zoomPreset in CinematicCameraZoomPreset.values)
                _InlineControlAction(
                  label: _cameraZoomPresetLabel(zoomPreset),
                  button: PokeMapButton(
                    key: ValueKey(
                      'cinematic-builder-camera-zoom-${zoomPreset.name}',
                    ),
                    onPressed: () {
                      onUpdateBasicBlock(
                        step,
                        cameraMode: CinematicTimelineCameraMode.focus,
                        cameraFocusBinding: CinematicTimelineCameraFocusBinding(
                          target: focusBinding.target,
                          zoomPreset: zoomPreset,
                        ),
                      );
                    },
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    isSelected: focusBinding.zoomPreset == zoomPreset,
                    leading: Icon(_cameraZoomPresetIcon(zoomPreset)),
                    child: const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const _MutedText('Cadrage configuré, preview réelle à venir.'),
        ] else
          const _MutedText(
            'Mode caméra non reconnu. Choisissez un mode no-code pour corriger ce bloc.',
          ),
      ],
    );
  }

  void _updateFocusTarget(
    CinematicCameraTargetBinding target,
    CinematicCameraZoomPreset zoomPreset,
  ) {
    onUpdateBasicBlock(
      step,
      cameraMode: CinematicTimelineCameraMode.focus,
      cameraFocusBinding: CinematicTimelineCameraFocusBinding(
        target: target,
        zoomPreset: zoomPreset,
      ),
    );
  }
}
```

Helpers no-code ajoutes :

```dart
String _cameraModeLabel(CinematicTimelineCameraMode mode) {
  return switch (mode) {
    CinematicTimelineCameraMode.reset => 'Réinitialiser le cadrage',
    CinematicTimelineCameraMode.hold => 'Maintenir le cadrage',
    CinematicTimelineCameraMode.focus => 'Cadrer une cible',
  };
}

String _cameraTargetKindLabel(CinematicCameraTargetKind kind) {
  return switch (kind) {
    CinematicCameraTargetKind.sceneCenter => 'Centre de la scène',
    CinematicCameraTargetKind.actor => 'Acteur',
    CinematicCameraTargetKind.stagePoint => 'Repère',
  };
}

String _cameraZoomPresetLabel(CinematicCameraZoomPreset preset) {
  return switch (preset) {
    CinematicCameraZoomPreset.wide => 'Plan large',
    CinematicCameraZoomPreset.medium => 'Plan moyen',
    CinematicCameraZoomPreset.close => 'Gros plan',
  };
}

CinematicTimelineCameraFocusBinding _cameraFocusBindingOrDefault(
  CinematicTimelineStep step,
) {
  return cinematicTimelineCameraFocusBindingOf(step) ??
      CinematicTimelineCameraFocusBinding(
        target: CinematicCameraTargetBinding.sceneCenter(),
        zoomPreset: CinematicCameraZoomPreset.medium,
      );
}
```

## 7. Diagnostics UI

Les diagnostics core V1-131 restent la source de verite. Le lot V1-132 ajoute les garde-fous UI suivants :

- mode inconnu : message no-code de correction par les boutons ;
- focus sans repere disponible : message `Aucun repère disponible. Ajoutez d’abord un repère dans la preview.` ;
- acteurs absents : bouton acteur desactive et message humain ;
- metadata camera brutes masquees du workflow principal pour les steps authoring-owned.

## 8. Tests executes

Commandes vertes :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-132"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-129"
flutter test --reporter=compact test/cinematics_library_workspace_test.dart --name "adds a basic block"
```

Resultats :

```text
V1-132 : +11 All tests passed!
V1-124 : +7 All tests passed!
V1-129 : +4 All tests passed!
Library add basic block : +1 All tests passed!
```

Analyse :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultat : exit 0, uniquement 35 infos `prefer_const_*` non fatales dans les gros fichiers existants/tests. Aucune erreur ou warning fatal.

Note verification : deux tentatives de tests lancees en parallele ont declenche un crash Flutter `PathNotFoundException` sur `build/unit_test_assets/NativeAssetsManifest.json`. Les memes commandes relancees sequentiellement sont passees.

## 9. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_132_cinematic_camera_target_zoom_editor_ui_v0.png
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff   220K Jun 15 00:35 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_132_cinematic_camera_target_zoom_editor_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_132_cinematic_camera_target_zoom_editor_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
dd171023d04b1f2d3270e5756a693d8deeff215d53af06d2bf962a7894b0c10b  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_132_cinematic_camera_target_zoom_editor_ui_v0.png
```

La capture montre un bloc Camera selectionne, le mode `Cadrer une cible`, les controles de cible, les controles `Plan large` / `Plan moyen` / `Gros plan`, le message preview future, la preview et la timeline.

## 10. Non-objectifs respectes

Non ajoutes :

- geometrie camera reelle ;
- `centerX` / `centerY` ;
- zoom numerique ;
- pan camera ;
- interpolation ;
- preview camera reelle ;
- runtime ;
- Flame ;
- GameState ;
- mutation viewport editor ;
- coordonnees libres ;
- waypoints camera ;
- migration JSON ;
- Selbrume.

## 11. Limites restantes

La camera reste configuree en authoring et symbolique en preview. Le prochain lot doit produire un etat derive de geometrie camera avant tout rendu reel.

## 12. Prochain lot recommande

`NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0`

Objectif : produire un etat de geometrie camera derive cote read model playback : target resolue, centre symbolique/geometrique et intention de zoom, avec diagnostics, sans renderer UI reel, runtime, Flame, GameState ni mutation viewport.

## 13. Auto-critique finale

Points solides :

- l'UI passe par les bindings typés V1-131 ;
- les libelles principaux sont humains ;
- reset/hold nettoient via l'operation core ;
- aucun ID technique n'est le workflow principal ;
- la Visual Gate couvre l'UI demandee.

Risques restants :

- les infos `prefer_const_*` restent nombreuses dans le fichier de test et le Builder, mais elles sont non fatales et preexistantes au style local ;
- le crash Flutter parallele rappelle que les tests `flutter test` de ce package doivent etre lances sequentiellement sur cette machine ;
- les diagnostics camera inconnus dependent toujours du coeur V1-131 et du rendu existant de diagnostics dans l'inspecteur.

Verdict : `NS-SCENES-V1-132 : DONE`.
