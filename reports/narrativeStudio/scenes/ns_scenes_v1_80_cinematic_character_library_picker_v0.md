# NS-SCENES-V1-80 — Cinematic Character Library Picker V0

## 1. Résumé

Statut : DONE.

Demandeur : Karim. Le lot a ete lance par Karim via le prompt du prochain lot, avec autorisation d'utiliser des sub agents au besoin.

V1-80 expose dans le Cinematic Builder un picker no-code Character Library pour les acteurs `cinematicOnly`. Le picker consomme le modele V1-79 `CinematicActorAppearanceBinding` / `stageContext.actorAppearanceBindings`, sans modifier `map_core`.

## 2. Objectif

Permettre a un acteur de cinematique lie en `Cinématique uniquement` de choisir un vrai `ProjectCharacterEntry` depuis `ProjectManifest.characters`, sans champ ID libre, sans JSON brut, sans preview reelle, sans runtime et sans override des acteurs `player`, `mapEntity` ou `unbound`.

## 3. Gate 0

```bash
pwd
```

```text
/Users/karim/Project/pokemonProject
```

```bash
git branch --show-current
git status --short --untracked-files=all
```

```text
main
```

Statut avant edition : sortie `git status --short --untracked-files=all` vide.

```bash
git diff --stat
git diff --name-only
```

```text

```

Dernier historique pertinent :

```text
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
```

## 4. Scope réalisé

- Passage de `ProjectManifest.characters` jusqu'au Cinematic Builder.
- Nouveaux callbacks editor pour `upsertCinematicActorAppearanceBinding` et `removeCinematicActorAppearanceBinding`.
- Section `Apparence` par acteur dans le Stage Context.
- Picker no-code des personnages Character Library pour `cinematicOnly`.
- Details visibles : nom, tileset, frame size, tags, id technique discret.
- Etats explicites : aucun personnage choisi, bibliotheque vide, reference cassee.
- Etats herites/desactives pour `player`, `mapEntity` et `unbound`.
- Readiness preview future enrichie pour les apparences d'acteurs.
- Diagnostics V1-79 humanises dans l'editor.
- Visual Gate V1-80.

## 5. Hors scope respecté

Pas de preview reelle, pas de runtime, pas de playback, pas de timer, pas de pathfinding, pas de collision, pas de warp/spawn/GameState, pas de modification Character Library, pas de creation/edition/suppression de personnage, pas de `stageContext.mapId`, pas de `characterId` dans `CinematicActorBinding`, pas de donnees Selbrume/Mael/Lysa/Port des Brisants, pas d'image IA et pas de `gpt-image-2`.

## 6. Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_80_cinematic_character_library_picker_v0.png`

## 7. Code généré — callbacks Builder

```dart
typedef UpsertCinematicActorAppearanceBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorAppearanceBinding binding,
});

typedef RemoveCinematicActorAppearanceBindingCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
});
```

Ces callbacks restent editor-only et deleguent aux operations core V1-79.

## 8. Code généré — application dans le canvas narratif

```dart
Future<bool> _upsertCinematicActorAppearanceBinding({
  required String cinematicId,
  required CinematicActorAppearanceBinding binding,
}) async {
  final project = widget.project;
  if (project == null) {
    return false;
  }
  try {
    final result = upsertCinematicActorAppearanceBinding(
      project,
      cinematicId: cinematicId,
      binding: binding,
    );
    widget.editorNotifier.applyInMemoryProjectManifest(
      result.updatedProject,
      statusMessage: 'Cinematic actor appearance updated',
    );
    return true;
  } on ArgumentError {
    return false;
  }
}
```

Le remove utilise la meme logique avec `removeCinematicActorAppearanceBinding`.

## 9. Code généré — sélection Character Library

```dart
_StageActorAppearanceSection(
  actor: actor,
  selectedKind: selectedKind,
  appearanceBinding: _actorAppearanceBindingFor(stageContext, actor.actorId),
  characters: widget.characters,
  showPicker: _showCharacterPicker,
  onTogglePicker: () {
    setState(() => _showCharacterPicker = !_showCharacterPicker);
  },
  onCharacterSelected: (character) async {
    await widget.onUpsertActorAppearanceBinding(
      CinematicActorAppearanceBinding(
        actorId: actor.actorId,
        characterId: character.id,
      ),
    );
    if (mounted) {
      setState(() => _showCharacterPicker = false);
    }
  },
  onClear: () => widget.onRemoveActorAppearanceBinding(actor.actorId),
)
```

La selection cree uniquement un `CinematicActorAppearanceBinding`. Elle ne mute pas `CinematicActorBinding`, les acteurs requis, la timeline ou les durees.

## 10. Code généré — etats UI

```dart
String _appearanceDisabledMessage(CinematicActorBindingKind? selectedKind) {
  return switch (selectedKind) {
    CinematicActorBindingKind.player => 'Apparence héritée du joueur.',
    CinematicActorBindingKind.mapEntity =>
      'Apparence héritée de l’entité de map.',
    CinematicActorBindingKind.cinematicOnly =>
      'Choisis un personnage dans la Character Library.',
    CinematicActorBindingKind.unbound || null =>
      'Lie d’abord l’acteur en Cinématique uniquement pour choisir un personnage.',
  };
}
```

Les acteurs non `cinematicOnly` n'ont pas de picker actif.

## 11. Code généré — readiness apparences

```dart
if (appearance == null) {
  return _item(
    'Apparences acteurs',
    CinematicStagePreviewReadinessItemKind.incomplete,
    '${_actorDisplayLabel(actor)} n’a pas encore de personnage',
  );
}
final character = _characterById(characters, appearance.characterId);
if (character == null) {
  return _item(
    'Apparences acteurs',
    CinematicStagePreviewReadinessItemKind.blocking,
    '${_actorDisplayLabel(actor)} pointe vers un personnage absent',
  );
}
```

Une ref cassee bloque la future preview ; un asset Character Library incomplet reste a completer sans activer de preview reelle.

## 12. Tests ajoutés

- `selects character library entry for cinematic only actor`
- `shows empty character library message for cinematic only actor`
- `keeps appearance picker disabled for inherited actor bindings`
- `clears broken character library reference explicitly`
- `updates readiness for cinematic only character appearances`
- `captures V1-80 cinematic character library picker when requested`

## 13. Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_80_cinematic_character_library_picker_v0.png
```

Commande demandee executee :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_80_CAPTURE_CINEMATIC_CHARACTER_PICKER=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat : la suite Builder avec capture V1-80 termine sur `All tests passed!`.

## 14. Vérifications

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'selects character library entry for cinematic only actor'
```

```text
00:02 +1: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:23 +134: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

```text
00:04 +13: All tests passed!
```

```bash
cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

```text
Analyzing 6 items...
No issues found! (ran in 2.1s)
```

Verification finale combinee :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

```text
00:23 +148: All tests passed!
```

`flutter analyze` global `packages/map_editor` reste rouge sur dette Pokemon SDK preexistante hors lot, notamment `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

## 15. Anti-scope

Checks effectues :

- aucun `CharacterLibraryPanel` modifie ou importe ;
- aucune creation/edition/suppression de personnage ajoutee ;
- aucun champ texte `characterId` ou Character Library manuel ;
- aucun `Color(0x...)` / `Colors.*` dans les fichiers produit modifies ;
- aucun playback/timer/runtime/pathfinding/collision/GameState ;
- `characterId` reste limite au binding d'apparence et aux tests.

## 16. Limites connues

La preview reste une sandbox. Les warnings `characterAssetMissingSprite` et `characterAssetMissingPreviewData` preparent la future preview mais ne dessinent aucun acteur. V1-81 est recommande pour polir les diagnostics de drift apres selection.

## 17. Statut roadmap proposé

`NS-SCENES-V1-80 — Cinematic Character Library Picker V0` : DONE.

Prochain lot exact recommande :

```text
NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0
```
