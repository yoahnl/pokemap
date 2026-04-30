# Lot PathPattern-14-bis — Path Studio Creation UX Correction V0

## 1. Résumé exécutif
Verdict : lot terminé. Le geste principal du Path Studio est maintenant `Nouveau chemin`, avec un brouillon local indépendant de tout `ProjectPathPreset` legacy. Le flux legacy existe encore, mais uniquement comme action secondaire `Depuis un path existant`. Aucune sauvegarde, aucune mutation du manifest et aucune modification `map_core` n’ont été introduites.

Le bouton principal crée un `PathStudioNewPathDraft` côté `map_editor`, sans frames héritées, sans base legacy, avec une grille placeholder `1×1` / `2×2`. L’inspector du nouveau chemin ne présente plus `Preset de base` ni `Base path preset id`. Le dropdown legacy reste visible seulement dans l’inspector du flux secondaire.

Context Mode : disponible et utilisé pour l’audit et les sorties volumineuses. Stat MCP disponible : `1.7M tokens saved`, `82.0% reduction`, version `v1.0.103`.

## 2. Audit initial
Commandes exécutées avant modification :
```text
pwd
git status --short
git diff --stat
git diff --name-status
find .. -name AGENTS.md -print
find packages/map_editor/lib/src/features/path_studio packages/map_editor/test/path_pattern -maxdepth 1 -type f | sort
git ls-files packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart packages/map_editor/test/path_pattern/path_studio_panel_test.dart packages/map_editor/test/path_pattern/path_pattern_draft_test.dart reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
rg -n "Nouveau preset|Nouveau chemin|Créer un chemin|Depuis un path existant|Structure héritée|PathPatternDraft|path-studio-draft|basePathPresetId|Preset de base|Base path preset id|Aucun preset Path de base|Aucun path existant|Brouillon" packages/map_editor/lib/src/features/path_studio packages/map_editor/test/path_pattern reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
```
Constats initiaux :
- `PathStudioPanel` existait et contenait un bouton principal `Nouveau preset`.
- Le clic principal appelait directement le draft legacy `PathPatternDraft`, construit depuis `createInitialPathPatternDraftFromManifest`.
- Si `manifest.pathPresets` était vide, le flux principal affichait `Aucun preset Path de base disponible` et ne créait rien.
- Le dropdown `path-studio-draft-base-popup` vivait dans l’inspector du brouillon legacy et exposait la base technique comme étape normale.
- `path_pattern_draft.dart`, `path_pattern_draft_test.dart` et `pathpattern_14_draft_editor_state_v0.md` étaient déjà non suivis avant le 14-bis. Ils sont considérés comme artefacts préexistants du lot 14 et ne sont pas créés par ce lot.
- Aucun `AGENTS.md` plus profond n’existe dans `packages/map_editor`; le `AGENTS.md` racine s’applique.

État Git initial observé :
```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart
?? packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
?? reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
```
Diff stat initial observé :
```text
 .../features/path_studio/path_studio_panel.dart    | 888 ++++++++++++++++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 149 +++-
 2 files changed, 1016 insertions(+), 21 deletions(-)
```
Diff name-status initial observé :
```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 3. Problème UX constaté
Le Lot 14 était techniquement cohérent avec le modèle actuel, mais le bouton principal racontait un geste technique : choisir un ancien path comme base. Le produit attendu est différent : le premier geste doit être `je crée un nouveau chemin`, puis seulement ensuite les contraintes techniques peuvent apparaître.

Le problème exact était donc double :
- le libellé `Nouveau preset` exposait le vocabulaire interne ;
- l’absence de `ProjectPathPreset` legacy bloquait la création, alors que le nouveau brouillon doit exister même sans legacy path.

## 4. Stratégie retenue
- Ajouter un modèle local `PathStudioNewPathDraft` côté `map_editor`, sans dépendance à `ProjectPathPreset`, `ProjectManifest`, JSON ou codec.
- Transformer le bouton principal en `Nouveau chemin`, qui crée ce nouveau draft local.
- Garder `PathPatternDraft` legacy, mais le déclencher seulement via `Depuis un path existant`.
- Séparer l’inspector et la grille du nouveau chemin pour afficher des placeholders `À configurer` / `Aucune tuile` au lieu de sources legacy.
- Conserver `Dupliquer` et `Enregistrer` désactivés.
- Corriger l’overflow du header intégré via un `Wrap` local des actions, révélé par `editor_shell_page_smoke_test.dart`.

## 5. Fichiers créés
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart` : modèle local du brouillon nouveau chemin.
- `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart` : tests unitaires du nouveau brouillon.
- `reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md` : présent rapport.

## 6. Fichiers modifiés
- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` : bouton principal renommé, état `PathStudioNewPathDraft`, UI nouveau chemin, flux secondaire legacy, header responsive.
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart` : tests widget mis à jour pour le nouveau flux principal et le flux secondaire.

## 7. Fichiers supprimés
Aucun fichier supprimé.

## 8. Nouveau flux “Nouveau chemin”
Le flux principal crée `PathStudioNewPathDraft` avec :
- `id = draft-new-path` ;
- `name = Nouveau chemin` ;
- centre initial `1×1` ;
- cellule sélectionnée `0,0` ;
- état dirty local ;
- issues locales informatives `tilesetNotConfigured` et `cellsNotConfigured`.

La grille affiche des cellules placeholder :
- `A` en `1×1` ;
- `A/B/C/D` en `2×2` ;
- texte `À configurer` et `Aucune tuile` ;
- aucune source `x,y` legacy.

L’inspector du nouveau chemin affiche : nom, taille, cellules, cellule sélectionnée, état non sauvegardé, sauvegarde non disponible et prochaine étape tileset/tuiles. Il ne contient pas `Preset de base` ni `Base path preset id`.

## 9. Flux secondaire “Depuis un path existant”
Le flux legacy du Lot 14 reste disponible via `Depuis un path existant`. Il conserve `PathPatternDraft`, le centre `cross` et le changement de base, mais son vocabulaire est maintenant explicite : `Motif depuis path existant`, `Structure héritée`, `Path existant réutilisé`.

Si `manifest.pathPresets` est vide, ce flux secondaire affiche `Aucun path existant disponible`. Le flux principal `Nouveau chemin` continue de fonctionner dans ce cas.

## 10. Comportements volontairement non faits
- Pas de sauvegarde dans `ProjectManifest.pathPatternPresets`.
- Pas de création persistée de `ProjectPathPreset`.
- Pas de mutation du manifest.
- Pas de repository, service de persistance, provider complexe ou save flow.
- Pas de modification `map_core`, `ProjectManifest`, codecs, generated files ou build_runner.
- Pas de vrai tile picker, frame picker, drag and drop, preview PNG, preview animée, duplication persistée ou suppression.
- Pas de painter, canvas render, runtime, gameplay, battle, Surface Studio, TSX/TMX, Mistral, PixelLab ou MCP.

## 11. Tests exécutés
### Test ciblé nouveau draft
Commande :
```text
cd packages/map_editor
flutter test test/path_pattern/path_studio_new_path_draft_test.dart
```
Sortie complète :
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart                                                                       
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart                                                                       
00:01 +0: PathStudioNewPathDraft creates an initial draft without a legacy ProjectPathPreset                                                                                                           
00:01 +1: PathStudioNewPathDraft creates an initial draft without a legacy ProjectPathPreset                                                                                                           
00:01 +1: PathStudioNewPathDraft resizes a 1x1 draft to 2x2 placeholder cells                                                                                                                          
00:01 +2: PathStudioNewPathDraft resizes a 1x1 draft to 2x2 placeholder cells                                                                                                                          
00:01 +2: PathStudioNewPathDraft resizes a 2x2 draft back to 1x1 and clamps selection                                                                                                                  
00:01 +3: PathStudioNewPathDraft resizes a 2x2 draft back to 1x1 and clamps selection                                                                                                                  
00:01 +3: PathStudioNewPathDraft renames the draft locally                                                                                                                                             
00:01 +4: PathStudioNewPathDraft renames the draft locally                                                                                                                                             
00:01 +4: PathStudioNewPathDraft empty name exposes nameRequired without blocking local editing                                                                                                        
00:01 +5: PathStudioNewPathDraft empty name exposes nameRequired without blocking local editing                                                                                                        
00:01 +5: PathStudioNewPathDraft selects a placeholder cell by exact local coordinates                                                                                                                 
00:01 +6: PathStudioNewPathDraft selects a placeholder cell by exact local coordinates                                                                                                                 
00:02 +6: PathStudioNewPathDraft selects a placeholder cell by exact local coordinates                                                                                                                 
00:02 +6: All tests passed!                                                                                                                                                                            
```

### Régression draft legacy
Commande :
```text
cd packages/map_editor
flutter test test/path_pattern/path_pattern_draft_test.dart
```
Sortie complète :
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart                                                                               
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart                                                                               
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart                                                                               
00:02 +0: PathPatternDraft creates an initial draft from the legacy cross center                                                                                                                       
00:02 +1: PathPatternDraft creates an initial draft from the legacy cross center                                                                                                                       
00:02 +1: PathPatternDraft returns null when a manifest has no legacy base path preset                                                                                                                 
00:02 +2: PathPatternDraft returns null when a manifest has no legacy base path preset                                                                                                                 
00:02 +2: PathPatternDraft resizes a 1x1 draft to a 2x2 center with copied cross frames                                                                                                                
00:02 +3: PathPatternDraft resizes a 1x1 draft to a 2x2 center with copied cross frames                                                                                                                
00:02 +3: PathPatternDraft resizes a 2x2 draft back to a valid 1x1 center                                                                                                                              
00:02 +4: PathPatternDraft resizes a 2x2 draft back to a valid 1x1 center                                                                                                                              
00:02 +4: PathPatternDraft changes base while preserving name and current size                                                                                                                         
00:02 +5: PathPatternDraft changes base while preserving name and current size                                                                                                                         
00:02 +5: PathPatternDraft empty draft name exposes a local nameRequired issue                                                                                                                         
00:02 +6: PathPatternDraft empty draft name exposes a local nameRequired issue                                                                                                                         
00:02 +6: All tests passed!                                                                                                                                                                            
```

### Test widget Path Studio
Commande :
```text
cd packages/map_editor
flutter test test/path_pattern/path_studio_panel_test.dart
```
Sortie complète :
```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart                                                                                
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart                                                                                
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart                                                                                
00:02 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists                                                                                                                 
00:03 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists                                                                                                                 
00:03 +1: PathStudioPanel renders a dark empty state when no PathPattern preset exists                                                                                                                 
00:03 +1: PathStudioPanel lists presets and updates summary and inspector selection                                                                                                                    
00:03 +2: PathStudioPanel lists presets and updates summary and inspector selection                                                                                                                    
00:03 +2: PathStudioPanel filters presets locally and clears selection on no result                                                                                                                    
00:03 +3: PathStudioPanel filters presets locally and clears selection on no result                                                                                                                    
00:03 +3: PathStudioPanel creates a new path draft without legacy base presets                                                                                                                         
00:04 +3: PathStudioPanel creates a new path draft without legacy base presets                                                                                                                         
00:04 +4: PathStudioPanel creates a new path draft without legacy base presets                                                                                                                         
00:04 +4: PathStudioPanel new path draft does not force existing legacy path choices                                                                                                                   
00:04 +5: PathStudioPanel new path draft does not force existing legacy path choices                                                                                                                   
00:04 +5: PathStudioPanel resizes the new path draft to 2x2 and selects a cell                                                                                                                         
00:04 +6: PathStudioPanel resizes the new path draft to 2x2 and selects a cell                                                                                                                         
00:04 +6: PathStudioPanel edits new path draft name and keeps save disabled                                                                                                                            
00:04 +7: PathStudioPanel edits new path draft name and keeps save disabled                                                                                                                            
00:04 +7: PathStudioPanel secondary legacy flow changes inherited structure locally                                                                                                                    
00:04 +8: PathStudioPanel secondary legacy flow changes inherited structure locally                                                                                                                    
00:04 +8: PathStudioPanel empty new path name shows a local diagnostic                                                                                                                                 
00:04 +9: PathStudioPanel empty new path name shows a local diagnostic                                                                                                                                 
00:04 +9: PathStudioPanel secondary legacy flow reports missing existing paths                                                                                                                         
00:05 +9: PathStudioPanel secondary legacy flow reports missing existing paths                                                                                                                         
00:05 +10: PathStudioPanel secondary legacy flow reports missing existing paths                                                                                                                        
00:05 +10: All tests passed!                                                                                                                                                                           
```

## 12. Analyze exécuté
Commande :
```text
cd packages/map_editor
flutter analyze lib/src/features/path_studio test/path_pattern
```
Sortie complète :
```text
Analyzing 2 items...                                            
No issues found! (ran in 2.8s)
```

## 13. Régressions exécutées
- `cd packages/map_editor && flutter test test/path_pattern/` → `00:05 +59: All tests passed!                                                                                                                                                                           `
- `cd packages/map_editor && flutter test test/editor_shell_page_smoke_test.dart` → `00:05 +7: All tests passed!                                                                                                                                                                            `
- `cd packages/map_editor && flutter test test/top_toolbar_test.dart` → `00:03 +5: All tests passed!                                                                                                                                                                            `
- `cd packages/map_editor && flutter test test/editor_selectors_test.dart` → `00:02 +8: All tests passed!                                                                                                                                                                            `
- `cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart` → `00:00 +14: All tests passed!                                                                                                                                                                           `
- `cd packages/map_core && dart test test/project_manifest_path_pattern_presets_test.dart` → `00:00 +8: All tests passed!                                                                                                                                                                            `
- `cd packages/map_core && dart test test/project_path_pattern_preset_json_codec_test.dart` → `00:00 +9: All tests passed!                                                                                                                                                                            `
- `cd packages/map_core && dart test test/project_path_pattern_preset_json_golden_test.dart` → `00:00 +6: All tests passed!                                                                                                                                                                            `
- `cd packages/map_core && dart test test/project_path_pattern_preset_test.dart` → `00:00 +5: All tests passed!                                                                                                                                                                            `
- `cd packages/map_core && dart test test/path_center_pattern_test.dart` → `00:00 +17: All tests passed!                                                                                                                                                                           `
- `cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart` → `00:00 +6: All tests passed!                                                                                                                                                                            `

Note : les tests `editor_shell_page_smoke_test.dart` et `top_toolbar_test.dart` émettent l’avertissement connu `Falling back on slow accent color resolution` de `macos_ui`; les commandes finissent à `All tests passed!`.

## 14. git status final
```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
?? packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
?? packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
?? reports/pathPattern/pathpattern_14_bis_creation_ux_correction_v0.md
?? reports/pathPattern/pathpattern_14_draft_editor_state_v0.md
```

## 15. git diff --stat
```text
 .../features/path_studio/path_studio_panel.dart    | 1717 +++++++++++++++++++-
 .../test/path_pattern/path_studio_panel_test.dart  |  218 ++-
 2 files changed, 1860 insertions(+), 75 deletions(-)
```

## 16. git diff --name-status
```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

Vérification ciblée `map_core` :
```text
(aucune ligne)
```

## 17. Evidence Pack
### Contenu complet — packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
```dart
enum PathStudioNewPathDraftIssueCode {
  nameRequired,
  tilesetNotConfigured,
  cellsNotConfigured,
}

final class PathStudioNewPathDraftCell {
  const PathStudioNewPathDraftCell({
    required this.localX,
    required this.localY,
    required this.label,
  });

  final int localX;
  final int localY;
  final String label;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraftCell &&
            localX == other.localX &&
            localY == other.localY &&
            label == other.label;
  }

  @override
  int get hashCode => Object.hash(localX, localY, label);
}

final class PathStudioNewPathDraft {
  PathStudioNewPathDraft({
    required this.id,
    required this.name,
    required this.centerWidth,
    required this.centerHeight,
    required this.selectedCellX,
    required this.selectedCellY,
    required this.isDirty,
  })  : assert(centerWidth > 0),
        assert(centerHeight > 0),
        assert(selectedCellX >= 0 && selectedCellX < centerWidth),
        assert(selectedCellY >= 0 && selectedCellY < centerHeight);

  final String id;
  final String name;
  final int centerWidth;
  final int centerHeight;
  final int selectedCellX;
  final int selectedCellY;
  final bool isDirty;

  String get centerPatternLabel => '$centerWidth×$centerHeight';

  int get centerCellCount => centerWidth * centerHeight;

  List<PathStudioNewPathDraftCell> get cells {
    final result = <PathStudioNewPathDraftCell>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < centerHeight; y += 1) {
      for (var x = 0; x < centerWidth; x += 1) {
        result.add(
          PathStudioNewPathDraftCell(
            localX: x,
            localY: y,
            label: String.fromCharCode(labelCode),
          ),
        );
        labelCode += 1;
      }
    }
    return List<PathStudioNewPathDraftCell>.unmodifiable(result);
  }

  PathStudioNewPathDraftCell get selectedCell {
    return cells.firstWhere(
      (cell) => cell.localX == selectedCellX && cell.localY == selectedCellY,
    );
  }

  List<PathStudioNewPathDraftIssueCode> get issues {
    final result = <PathStudioNewPathDraftIssueCode>[];
    if (name.trim().isEmpty) {
      result.add(PathStudioNewPathDraftIssueCode.nameRequired);
    }
    result.add(PathStudioNewPathDraftIssueCode.tilesetNotConfigured);
    result.add(PathStudioNewPathDraftIssueCode.cellsNotConfigured);
    return List<PathStudioNewPathDraftIssueCode>.unmodifiable(result);
  }

  PathStudioNewPathDraft copyWith({
    String? id,
    String? name,
    int? centerWidth,
    int? centerHeight,
    int? selectedCellX,
    int? selectedCellY,
    bool? isDirty,
  }) {
    return PathStudioNewPathDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      centerWidth: centerWidth ?? this.centerWidth,
      centerHeight: centerHeight ?? this.centerHeight,
      selectedCellX: selectedCellX ?? this.selectedCellX,
      selectedCellY: selectedCellY ?? this.selectedCellY,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraft &&
            id == other.id &&
            name == other.name &&
            centerWidth == other.centerWidth &&
            centerHeight == other.centerHeight &&
            selectedCellX == other.selectedCellX &&
            selectedCellY == other.selectedCellY &&
            isDirty == other.isDirty;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        centerWidth,
        centerHeight,
        selectedCellX,
        selectedCellY,
        isDirty,
      );
}

PathStudioNewPathDraft createInitialPathStudioNewPathDraft() {
  return PathStudioNewPathDraft(
    id: 'draft-new-path',
    name: 'Nouveau chemin',
    centerWidth: 1,
    centerHeight: 1,
    selectedCellX: 0,
    selectedCellY: 0,
    isDirty: true,
  );
}

PathStudioNewPathDraft resizePathStudioNewPathDraftCenter({
  required PathStudioNewPathDraft draft,
  required int width,
  required int height,
}) {
  return draft.copyWith(
    centerWidth: width,
    centerHeight: height,
    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
    isDirty: true,
  );
}

PathStudioNewPathDraft renamePathStudioNewPathDraft(
  PathStudioNewPathDraft draft,
  String name,
) {
  return draft.copyWith(name: name, isDirty: true);
}

PathStudioNewPathDraft selectPathStudioNewPathDraftCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  if (localX < 0 ||
      localY < 0 ||
      localX >= draft.centerWidth ||
      localY >= draft.centerHeight) {
    throw RangeError.range(localX, 0, draft.centerWidth - 1, 'localX');
  }
  return draft.copyWith(
    selectedCellX: localX,
    selectedCellY: localY,
  );
}
```

### Contenu complet — packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';

void main() {
  group('PathStudioNewPathDraft', () {
    test('creates an initial draft without a legacy ProjectPathPreset', () {
      final draft = createInitialPathStudioNewPathDraft();

      expect(draft.id, 'draft-new-path');
      expect(draft.name, 'Nouveau chemin');
      expect(draft.centerWidth, 1);
      expect(draft.centerHeight, 1);
      expect(draft.centerPatternLabel, '1×1');
      expect(draft.centerCellCount, 1);
      expect(draft.selectedCellX, 0);
      expect(draft.selectedCellY, 0);
      expect(draft.isDirty, isTrue);
      expect(draft.cells.map((cell) => cell.label), ['A']);
      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('resizes a 1x1 draft to 2x2 placeholder cells', () {
      final draft = createInitialPathStudioNewPathDraft();

      final resized = resizePathStudioNewPathDraftCenter(
        draft: draft,
        width: 2,
        height: 2,
      );

      expect(resized.centerPatternLabel, '2×2');
      expect(resized.centerCellCount, 4);
      expect(
        resized.cells.map((cell) => (cell.localX, cell.localY, cell.label)),
        [
          (0, 0, 'A'),
          (1, 0, 'B'),
          (0, 1, 'C'),
          (1, 1, 'D'),
        ],
      );
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('resizes a 2x2 draft back to 1x1 and clamps selection', () {
      final twoByTwo = resizePathStudioNewPathDraftCenter(
        draft: createInitialPathStudioNewPathDraft(),
        width: 2,
        height: 2,
      );
      final selected = selectPathStudioNewPathDraftCell(
        draft: twoByTwo,
        localX: 1,
        localY: 1,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: selected,
        width: 1,
        height: 1,
      );

      expect(resized.centerWidth, 1);
      expect(resized.centerHeight, 1);
      expect(resized.centerCellCount, 1);
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('renames the draft locally', () {
      final draft = renamePathStudioNewPathDraft(
        createInitialPathStudioNewPathDraft(),
        'Route claire',
      );

      expect(draft.name, 'Route claire');
      expect(draft.isDirty, isTrue);
    });

    test('empty name exposes nameRequired without blocking local editing', () {
      final draft = renamePathStudioNewPathDraft(
        createInitialPathStudioNewPathDraft(),
        '   ',
      );

      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.nameRequired,
        PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('selects a placeholder cell by exact local coordinates', () {
      final draft = resizePathStudioNewPathDraftCenter(
        draft: createInitialPathStudioNewPathDraft(),
        width: 2,
        height: 2,
      );

      final selected = selectPathStudioNewPathDraftCell(
        draft: draft,
        localX: 1,
        localY: 0,
      );

      expect(selected.selectedCellX, 1);
      expect(selected.selectedCellY, 0);
      expect(selected.selectedCell.label, 'B');
    });
  });
}
```

### Rapport créé
Le contenu complet du rapport créé est le présent document Markdown. Une inclusion récursive de ce fichier dans lui-même rendrait le rapport non fini ; cette limite est explicitée dans la critique du prompt.

### Diff complet réel — fichiers modifiés
```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index a2b00e1b..10bb75c2 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -4,7 +4,9 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
 import '../editor/state/editor_selectors.dart';
+import 'path_pattern_draft.dart';
 import 'path_pattern_editor_read_model.dart';
+import 'path_studio_new_path_draft.dart';
 import 'path_studio_theme.dart';
 
 /// Workspace branché au shell global de l'éditeur.
@@ -45,6 +47,11 @@ class PathStudioPanel extends StatefulWidget {
 
 class _PathStudioPanelState extends State<PathStudioPanel> {
   String _searchQuery = '';
+  PathStudioNewPathDraft? _newPathDraft;
+  bool _newPathDraftSelected = false;
+  PathPatternDraft? _draft;
+  bool _draftSelected = false;
+  String? _draftMessage;
 
   /// Index dans `readModel.presets`, pas id métier.
   ///
@@ -58,6 +65,11 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     super.didUpdateWidget(oldWidget);
     if (oldWidget.manifest != widget.manifest) {
       _selectedSourceIndex = null;
+      _newPathDraft = null;
+      _newPathDraftSelected = false;
+      _draft = null;
+      _draftSelected = false;
+      _draftMessage = null;
     }
   }
 
@@ -68,7 +80,11 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     );
     final query = _searchQuery.trim().toLowerCase();
     final filtered = _filteredCards(readModel, query);
-    final selected = _selectedCard(filtered);
+    final selected = _newPathDraftSelected || _draftSelected
+        ? null
+        : _selectedCard(filtered);
+    final selectedNewPathDraft = _newPathDraftSelected ? _newPathDraft : null;
+    final selectedDraft = _draftSelected ? _draft : null;
 
     return DecoratedBox(
       decoration: const BoxDecoration(
@@ -81,6 +97,8 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
           children: [
             _PathStudioHeader(
               summary: readModel.summary,
+              onCreateNewPathDraft: _createNewPathDraft,
+              onCreateLegacyDraft: _createLegacyDraft,
             ),
             const SizedBox(height: 16),
             Expanded(
@@ -92,26 +110,69 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                     child: _PresetSidebar(
                       readModel: readModel,
                       filteredCards: filtered,
+                      newPathDraft: _newPathDraft,
+                      newPathDraftSelected: _newPathDraftSelected,
+                      newPathDraftMatchesQuery: _newPathDraft == null ||
+                          query.isEmpty ||
+                          _matchesNewPathDraftQuery(_newPathDraft!, query),
+                      draft: _draft,
+                      draftSelected: _draftSelected,
+                      draftMatchesQuery: _draft == null ||
+                          query.isEmpty ||
+                          _matchesDraftQuery(_draft!, query),
+                      draftMessage: _draftMessage,
                       selectedSourceIndex: selected?.sourceIndex,
                       onQueryChanged: (value) {
                         setState(() => _searchQuery = value);
                       },
+                      onSelectNewPathDraft: () {
+                        setState(() {
+                          _newPathDraftSelected = true;
+                          _draftSelected = false;
+                        });
+                      },
+                      onSelectDraft: () {
+                        setState(() {
+                          _newPathDraftSelected = false;
+                          _draftSelected = true;
+                        });
+                      },
                       onSelect: (sourceIndex) {
-                        setState(() => _selectedSourceIndex = sourceIndex);
+                        setState(() {
+                          _newPathDraftSelected = false;
+                          _draftSelected = false;
+                          _selectedSourceIndex = sourceIndex;
+                        });
                       },
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: _CenterWorkspace(
+                      newPathDraft: selectedNewPathDraft,
+                      draft: selectedDraft,
                       selected: selected?.card,
                       hasAnyPreset: readModel.presets.isNotEmpty,
+                      onNewPathSizeChanged: _resizeNewPathDraft,
+                      onNewPathCellSelected: _selectNewPathDraftCell,
+                      onDraftSizeChanged: _resizeDraft,
+                      onDraftCellSelected: _selectDraftCell,
                     ),
                   ),
                   const SizedBox(width: 16),
                   SizedBox(
                     width: 326,
-                    child: _PresetInspector(selected: selected?.card),
+                    child: _PresetInspector(
+                      manifest: widget.manifest,
+                      newPathDraft: selectedNewPathDraft,
+                      draft: selectedDraft,
+                      selected: selected?.card,
+                      onNewPathNameChanged: _renameNewPathDraft,
+                      onNewPathSizeChanged: _resizeNewPathDraft,
+                      onDraftNameChanged: _renameDraft,
+                      onDraftBaseChanged: _changeDraftBase,
+                      onDraftSizeChanged: _resizeDraft,
+                    ),
                   ),
                 ],
               ),
@@ -150,6 +211,29 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
         .any((field) => field.toLowerCase().contains(query));
   }
 
+  bool _matchesDraftQuery(PathPatternDraft draft, String query) {
+    final fields = [
+      draft.name,
+      draft.id,
+      draft.basePathPresetId,
+      draft.centerPatternLabel,
+    ];
+    return fields.any((field) => field.toLowerCase().contains(query));
+  }
+
+  bool _matchesNewPathDraftQuery(
+    PathStudioNewPathDraft draft,
+    String query,
+  ) {
+    final fields = [
+      draft.name,
+      draft.id,
+      draft.centerPatternLabel,
+      'nouveau chemin',
+    ];
+    return fields.any((field) => field.toLowerCase().contains(query));
+  }
+
   _IndexedPresetCard? _selectedCard(List<_IndexedPresetCard> filtered) {
     if (filtered.isEmpty) {
       return null;
@@ -161,6 +245,155 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     }
     return filtered.first;
   }
+
+  void _createNewPathDraft() {
+    setState(() {
+      _newPathDraft = createInitialPathStudioNewPathDraft();
+      _newPathDraftSelected = true;
+      _draftSelected = false;
+      _draftMessage = null;
+    });
+  }
+
+  void _createLegacyDraft() {
+    if (widget.manifest.pathPresets.isEmpty) {
+      setState(() {
+        _draftMessage = 'Aucun path existant disponible';
+        _newPathDraftSelected = false;
+        _draftSelected = false;
+      });
+      return;
+    }
+    try {
+      final draft = createInitialPathPatternDraftFromManifest(
+        manifest: widget.manifest,
+      );
+      setState(() {
+        _draft = draft;
+        _newPathDraftSelected = false;
+        _draftSelected = draft != null;
+        _draftMessage = draft == null
+            ? 'Aucun path existant disponible'
+            : 'Brouillon non sauvegardé';
+      });
+    } on ArgumentError {
+      setState(() {
+        _draftMessage =
+            'Le preset Path de base ne contient pas de centre cross';
+        _newPathDraftSelected = false;
+        _draftSelected = false;
+      });
+    }
+  }
+
+  void _renameNewPathDraft(String name) {
+    final draft = _newPathDraft;
+    if (draft == null) {
+      return;
+    }
+    setState(() {
+      _newPathDraft = renamePathStudioNewPathDraft(draft, name);
+    });
+  }
+
+  void _resizeNewPathDraft(int width, int height) {
+    final draft = _newPathDraft;
+    if (draft == null) {
+      return;
+    }
+    setState(() {
+      _newPathDraft = resizePathStudioNewPathDraftCenter(
+        draft: draft,
+        width: width,
+        height: height,
+      );
+    });
+  }
+
+  void _selectNewPathDraftCell(int localX, int localY) {
+    final draft = _newPathDraft;
+    if (draft == null) {
+      return;
+    }
+    setState(() {
+      _newPathDraft = selectPathStudioNewPathDraftCell(
+        draft: draft,
+        localX: localX,
+        localY: localY,
+      );
+    });
+  }
+
+  void _renameDraft(String name) {
+    final draft = _draft;
+    if (draft == null) {
+      return;
+    }
+    setState(() => _draft = renamePathPatternDraft(draft, name));
+  }
+
+  void _resizeDraft(int width, int height) {
+    final draft = _draft;
+    final base = _basePathPresetForDraft(draft);
+    if (draft == null || base == null) {
+      return;
+    }
+    setState(() {
+      _draft = resizePathPatternDraftCenter(
+        draft: draft,
+        basePathPreset: base,
+        width: width,
+        height: height,
+      );
+    });
+  }
+
+  void _changeDraftBase(String basePathPresetId) {
+    final draft = _draft;
+    if (draft == null) {
+      return;
+    }
+    final base = _basePathPresetById(basePathPresetId);
+    if (base == null) {
+      return;
+    }
+    setState(() {
+      _draft = changePathPatternDraftBase(
+        draft: draft,
+        basePathPreset: base,
+      );
+    });
+  }
+
+  void _selectDraftCell(int localX, int localY) {
+    final draft = _draft;
+    if (draft == null) {
+      return;
+    }
+    setState(() {
+      _draft = selectPathPatternDraftCell(
+        draft: draft,
+        localX: localX,
+        localY: localY,
+      );
+    });
+  }
+
+  ProjectPathPreset? _basePathPresetForDraft(PathPatternDraft? draft) {
+    if (draft == null) {
+      return null;
+    }
+    return _basePathPresetById(draft.basePathPresetId);
+  }
+
+  ProjectPathPreset? _basePathPresetById(String id) {
+    for (final preset in widget.manifest.pathPresets) {
+      if (preset.id == id) {
+        return preset;
+      }
+    }
+    return null;
+  }
 }
 
 class _IndexedPresetCard {
@@ -194,9 +427,13 @@ class _PathStudioProjectMissingState extends StatelessWidget {
 class _PathStudioHeader extends StatelessWidget {
   const _PathStudioHeader({
     required this.summary,
+    required this.onCreateNewPathDraft,
+    required this.onCreateLegacyDraft,
   });
 
   final PathPatternEditorSummary summary;
+  final VoidCallback onCreateNewPathDraft;
+  final VoidCallback onCreateLegacyDraft;
 
   @override
   Widget build(BuildContext context) {
@@ -256,23 +493,40 @@ class _PathStudioHeader extends StatelessWidget {
               ],
             ),
           ),
-          _SummaryPill(label: 'Presets', value: '${summary.totalCount}'),
-          const SizedBox(width: 8),
-          _SummaryPill(label: 'Prêts', value: '${summary.readyCount}'),
-          const SizedBox(width: 12),
-          const _ShellActionButton(
-            icon: CupertinoIcons.plus,
-            label: 'Nouveau preset',
-          ),
-          const SizedBox(width: 8),
-          const _ShellActionButton(
-            icon: CupertinoIcons.square_on_square,
-            label: 'Dupliquer',
-          ),
-          const SizedBox(width: 8),
-          const _ShellActionButton(
-            icon: CupertinoIcons.floppy_disk,
-            label: 'Enregistrer',
+          Flexible(
+            flex: 2,
+            child: Wrap(
+              alignment: WrapAlignment.end,
+              crossAxisAlignment: WrapCrossAlignment.center,
+              spacing: 8,
+              runSpacing: 8,
+              children: [
+                _SummaryPill(label: 'Presets', value: '${summary.totalCount}'),
+                _SummaryPill(label: 'Prêts', value: '${summary.readyCount}'),
+                _ShellActionButton(
+                  icon: CupertinoIcons.plus,
+                  label: 'Nouveau chemin',
+                  hint: 'nouveau brouillon',
+                  onPressed: onCreateNewPathDraft,
+                ),
+                _ShellActionButton(
+                  icon: CupertinoIcons.arrow_down_doc,
+                  label: 'Depuis un path existant',
+                  hint: 'flux avancé',
+                  onPressed: onCreateLegacyDraft,
+                ),
+                const _ShellActionButton(
+                  icon: CupertinoIcons.square_on_square,
+                  label: 'Dupliquer',
+                  hint: 'lot futur',
+                ),
+                const _ShellActionButton(
+                  icon: CupertinoIcons.floppy_disk,
+                  label: 'Enregistrer',
+                  hint: 'lot futur',
+                ),
+              ],
+            ),
           ),
         ],
       ),
@@ -328,17 +582,21 @@ class _ShellActionButton extends StatelessWidget {
   const _ShellActionButton({
     required this.icon,
     required this.label,
+    this.hint = 'lot futur',
+    this.onPressed,
   });
 
   final IconData icon;
   final String label;
+  final String hint;
+  final VoidCallback? onPressed;
 
   @override
   Widget build(BuildContext context) {
     return CupertinoButton(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
       minimumSize: Size.zero,
-      onPressed: null,
+      onPressed: onPressed,
       disabledColor: PathStudioTheme.surfaceRaised.withValues(alpha: 0.72),
       color: PathStudioTheme.accent,
       borderRadius: BorderRadius.circular(13),
@@ -347,7 +605,9 @@ class _ShellActionButton extends StatelessWidget {
         children: [
           MacosIcon(
             icon,
-            color: PathStudioTheme.textMuted.withValues(alpha: 0.72),
+            color: onPressed == null
+                ? PathStudioTheme.textMuted.withValues(alpha: 0.72)
+                : CupertinoColors.white,
             size: 15,
           ),
           const SizedBox(width: 8),
@@ -357,15 +617,19 @@ class _ShellActionButton extends StatelessWidget {
               Text(
                 label,
                 style: TextStyle(
-                  color: PathStudioTheme.textSecondary.withValues(alpha: 0.7),
+                  color: onPressed == null
+                      ? PathStudioTheme.textSecondary.withValues(alpha: 0.7)
+                      : CupertinoColors.white,
                   fontSize: 12,
                   fontWeight: FontWeight.w800,
                 ),
               ),
-              const Text(
-                'lot futur',
+              Text(
+                hint,
                 style: TextStyle(
-                  color: PathStudioTheme.textMuted,
+                  color: onPressed == null
+                      ? PathStudioTheme.textMuted
+                      : CupertinoColors.white.withValues(alpha: 0.72),
                   fontSize: 9,
                   fontWeight: FontWeight.w700,
                 ),
@@ -382,15 +646,33 @@ class _PresetSidebar extends StatelessWidget {
   const _PresetSidebar({
     required this.readModel,
     required this.filteredCards,
+    required this.newPathDraft,
+    required this.newPathDraftSelected,
+    required this.newPathDraftMatchesQuery,
+    required this.draft,
+    required this.draftSelected,
+    required this.draftMatchesQuery,
+    required this.draftMessage,
     required this.selectedSourceIndex,
     required this.onQueryChanged,
+    required this.onSelectNewPathDraft,
+    required this.onSelectDraft,
     required this.onSelect,
   });
 
   final PathPatternEditorReadModel readModel;
   final List<_IndexedPresetCard> filteredCards;
+  final PathStudioNewPathDraft? newPathDraft;
+  final bool newPathDraftSelected;
+  final bool newPathDraftMatchesQuery;
+  final PathPatternDraft? draft;
+  final bool draftSelected;
+  final bool draftMatchesQuery;
+  final String? draftMessage;
   final int? selectedSourceIndex;
   final ValueChanged<String> onQueryChanged;
+  final VoidCallback onSelectNewPathDraft;
+  final VoidCallback onSelectDraft;
   final ValueChanged<int> onSelect;
 
   @override
@@ -453,23 +735,47 @@ class _PresetSidebar extends StatelessWidget {
   }
 
   Widget _buildPresetList() {
-    if (readModel.presets.isEmpty) {
-      return const _SidebarNotice(
+    final newPathDraftCard = newPathDraft;
+    final draftCard = draft;
+    if (readModel.presets.isEmpty &&
+        newPathDraftCard == null &&
+        draftCard == null) {
+      return _SidebarNotice(
         title: 'Aucun motif PathPattern',
-        message: 'Les presets apparaîtront ici après le lot création.',
+        message: draftMessage ??
+            'Cliquez sur Nouveau chemin pour créer un brouillon local.',
       );
     }
-    if (filteredCards.isEmpty) {
+    final newPathVisible = newPathDraftCard != null && newPathDraftMatchesQuery;
+    final legacyDraftVisible = draftCard != null && draftMatchesQuery;
+    if (filteredCards.isEmpty && !newPathVisible && !legacyDraftVisible) {
       return const _SidebarNotice(
         title: 'Aucun preset trouvé',
         message: 'Essayez un autre nom, id ou preset de base.',
       );
     }
+    final draftCount = (newPathVisible ? 1 : 0) + (legacyDraftVisible ? 1 : 0);
     return ListView.separated(
-      itemCount: filteredCards.length,
+      itemCount: filteredCards.length + draftCount,
       separatorBuilder: (_, __) => const SizedBox(height: 10),
       itemBuilder: (context, index) {
-        final entry = filteredCards[index];
+        if (newPathDraftCard != null && newPathVisible && index == 0) {
+          return _NewPathDraftListCard(
+            draft: newPathDraftCard,
+            selected: newPathDraftSelected,
+            onTap: onSelectNewPathDraft,
+          );
+        }
+        final legacyIndex = newPathVisible ? 1 : 0;
+        if (draftCard != null && legacyDraftVisible && index == legacyIndex) {
+          return _DraftListCard(
+            draft: draftCard,
+            selected: draftSelected,
+            onTap: onSelectDraft,
+          );
+        }
+        final presetIndex = index - draftCount;
+        final entry = filteredCards[presetIndex];
         return _PresetListCard(
           key: Key('path-studio-preset-card-${entry.sourceIndex}'),
           card: entry.card,
@@ -481,6 +787,182 @@ class _PresetSidebar extends StatelessWidget {
   }
 }
 
+class _NewPathDraftListCard extends StatelessWidget {
+  const _NewPathDraftListCard({
+    required this.draft,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final PathStudioNewPathDraft draft;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    return GestureDetector(
+      onTap: onTap,
+      child: Container(
+        key: const Key('path-studio-new-path-draft-card'),
+        padding: const EdgeInsets.all(12),
+        decoration: BoxDecoration(
+          color: selected
+              ? Color.lerp(
+                  PathStudioTheme.surfaceStrong,
+                  PathStudioTheme.accentCyan,
+                  0.22,
+                )
+              : PathStudioTheme.surfaceRaised,
+          borderRadius: BorderRadius.circular(16),
+          border: Border.all(
+            color: selected
+                ? PathStudioTheme.accentCyan
+                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
+            width: selected ? 2 : 1,
+          ),
+        ),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Row(
+              children: [
+                Expanded(
+                  child: Text(
+                    draft.name,
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
+                    style: const TextStyle(
+                      color: PathStudioTheme.textPrimary,
+                      fontSize: 13,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                ),
+                const _StatusChip(
+                  label: 'Nouveau chemin',
+                  color: PathStudioTheme.accentCyan,
+                ),
+              ],
+            ),
+            const SizedBox(height: 8),
+            const Text(
+              'Brouillon chemin • Non sauvegardé',
+              style: TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 11,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 10),
+            Row(
+              children: [
+                _MiniMetric(
+                  icon: CupertinoIcons.square_grid_2x2,
+                  label: draft.centerPatternLabel,
+                ),
+                const SizedBox(width: 8),
+                const _MiniMetric(
+                  icon: CupertinoIcons.wand_stars,
+                  label: 'à configurer',
+                ),
+              ],
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _DraftListCard extends StatelessWidget {
+  const _DraftListCard({
+    required this.draft,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final PathPatternDraft draft;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    return GestureDetector(
+      onTap: onTap,
+      child: Container(
+        key: const Key('path-studio-draft-card'),
+        padding: const EdgeInsets.all(12),
+        decoration: BoxDecoration(
+          color: selected
+              ? Color.lerp(
+                  PathStudioTheme.surfaceStrong,
+                  PathStudioTheme.accentCyan,
+                  0.22,
+                )
+              : PathStudioTheme.surfaceRaised,
+          borderRadius: BorderRadius.circular(16),
+          border: Border.all(
+            color: selected
+                ? PathStudioTheme.accentCyan
+                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
+            width: selected ? 2 : 1,
+          ),
+        ),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Row(
+              children: [
+                Expanded(
+                  child: Text(
+                    draft.name,
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
+                    style: const TextStyle(
+                      color: PathStudioTheme.textPrimary,
+                      fontSize: 13,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                ),
+                const _StatusChip(
+                  label: 'Depuis path existant',
+                  color: PathStudioTheme.accentCyan,
+                ),
+              ],
+            ),
+            const SizedBox(height: 8),
+            const Text(
+              'Structure héritée • Non sauvegardé',
+              style: TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 11,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 10),
+            Row(
+              children: [
+                _MiniMetric(
+                  icon: CupertinoIcons.square_grid_2x2,
+                  label: draft.centerPatternLabel,
+                ),
+                const SizedBox(width: 8),
+                _MiniMetric(
+                  icon: draft.animatedCellCount > 0
+                      ? CupertinoIcons.play_circle
+                      : CupertinoIcons.circle,
+                  label: draft.animatedCellCount > 0 ? 'animé' : 'statique',
+                ),
+              ],
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
 class _SidebarCounter extends StatelessWidget {
   const _SidebarCounter({required this.value});
 
@@ -703,62 +1185,811 @@ class _MiniMetric extends StatelessWidget {
     required this.label,
   });
 
-  final IconData icon;
+  final IconData icon;
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return Row(
+      mainAxisSize: MainAxisSize.min,
+      children: [
+        MacosIcon(icon, size: 12, color: PathStudioTheme.textMuted),
+        const SizedBox(width: 4),
+        Text(
+          label,
+          style: const TextStyle(
+            color: PathStudioTheme.textSecondary,
+            fontSize: 11,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _CenterWorkspace extends StatelessWidget {
+  const _CenterWorkspace({
+    required this.newPathDraft,
+    required this.draft,
+    required this.selected,
+    required this.hasAnyPreset,
+    required this.onNewPathSizeChanged,
+    required this.onNewPathCellSelected,
+    required this.onDraftSizeChanged,
+    required this.onDraftCellSelected,
+  });
+
+  final PathStudioNewPathDraft? newPathDraft;
+  final PathPatternDraft? draft;
+  final PathPatternPresetCardModel? selected;
+  final bool hasAnyPreset;
+  final void Function(int width, int height) onNewPathSizeChanged;
+  final void Function(int localX, int localY) onNewPathCellSelected;
+  final void Function(int width, int height) onDraftSizeChanged;
+  final void Function(int localX, int localY) onDraftCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final newPathDraft = this.newPathDraft;
+    if (newPathDraft != null) {
+      return _NewPathCenterWorkspace(
+        draft: newPathDraft,
+        onSizeChanged: onNewPathSizeChanged,
+        onCellSelected: onNewPathCellSelected,
+      );
+    }
+    final draft = this.draft;
+    if (draft != null) {
+      return _DraftCenterWorkspace(
+        draft: draft,
+        onSizeChanged: onDraftSizeChanged,
+        onCellSelected: onDraftCellSelected,
+      );
+    }
+    final card = selected;
+    if (card == null) {
+      return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
+    }
+
+    return SingleChildScrollView(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          _WorkflowSteps(status: card.status),
+          const SizedBox(height: 14),
+          _SelectedSummary(card: card),
+          const SizedBox(height: 14),
+          _CenterPatternPlaceholder(card: card),
+          const SizedBox(height: 14),
+          _DiagnosticsCard(card: card),
+        ],
+      ),
+    );
+  }
+}
+
+class _NewPathCenterWorkspace extends StatelessWidget {
+  const _NewPathCenterWorkspace({
+    required this.draft,
+    required this.onSizeChanged,
+    required this.onCellSelected,
+  });
+
+  final PathStudioNewPathDraft draft;
+  final void Function(int width, int height) onSizeChanged;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return SingleChildScrollView(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          const _NewPathBanner(),
+          const SizedBox(height: 14),
+          const _NewPathWorkflowSteps(),
+          const SizedBox(height: 14),
+          _NewPathSummary(draft: draft),
+          const SizedBox(height: 14),
+          _NewPathCenterPatternEditor(
+            draft: draft,
+            onSizeChanged: onSizeChanged,
+            onCellSelected: onCellSelected,
+          ),
+          const SizedBox(height: 14),
+          _NewPathDiagnosticsCard(draft: draft),
+        ],
+      ),
+    );
+  }
+}
+
+class _NewPathBanner extends StatelessWidget {
+  const _NewPathBanner();
+
+  @override
+  Widget build(BuildContext context) {
+    return const _SectionCard(
+      title: 'Brouillon nouveau chemin',
+      icon: CupertinoIcons.pencil_outline,
+      trailing: _StatusChip(
+        label: 'Non sauvegardé',
+        color: PathStudioTheme.warning,
+      ),
+      child: Text(
+        'Ce brouillon représente un nouveau chemin complet. La sélection du tileset et la configuration des bords arriveront dans un lot futur.',
+        style: TextStyle(
+          color: PathStudioTheme.textSecondary,
+          fontSize: 13,
+          height: 1.4,
+        ),
+      ),
+    );
+  }
+}
+
+class _NewPathWorkflowSteps extends StatelessWidget {
+  const _NewPathWorkflowSteps();
+
+  @override
+  Widget build(BuildContext context) {
+    return const _SectionCard(
+      title: 'Création guidée',
+      icon: CupertinoIcons.list_bullet,
+      child: Wrap(
+        spacing: 10,
+        runSpacing: 10,
+        children: [
+          _StepPill(index: 1, label: 'Nouveau chemin', active: true),
+          _StepArrow(),
+          _StepPill(index: 2, label: 'Motif du centre', active: true),
+          _StepArrow(),
+          _StepPill(index: 3, label: 'Tileset', active: false),
+        ],
+      ),
+    );
+  }
+}
+
+class _NewPathSummary extends StatelessWidget {
+  const _NewPathSummary({required this.draft});
+
+  final PathStudioNewPathDraft draft;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      title: 'Résumé du nouveau chemin',
+      icon: CupertinoIcons.doc_text,
+      child: Wrap(
+        spacing: 10,
+        runSpacing: 10,
+        children: [
+          _InfoTile(label: 'Nom', value: draft.name),
+          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
+          _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
+          const _InfoTile(label: 'Contenu', value: 'À configurer'),
+          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
+        ],
+      ),
+    );
+  }
+}
+
+class _NewPathCenterPatternEditor extends StatelessWidget {
+  const _NewPathCenterPatternEditor({
+    required this.draft,
+    required this.onSizeChanged,
+    required this.onCellSelected,
+  });
+
+  final PathStudioNewPathDraft draft;
+  final void Function(int width, int height) onSizeChanged;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      title: 'Motif du centre',
+      icon: CupertinoIcons.square_grid_2x2,
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          const Text(
+            'Chaque cellule existe déjà dans le futur motif, mais son contenu visuel n’est pas encore choisi.',
+            style: TextStyle(
+              color: PathStudioTheme.textSecondary,
+              fontSize: 13,
+              height: 1.35,
+            ),
+          ),
+          const SizedBox(height: 14),
+          CupertinoSlidingSegmentedControl<String>(
+            key: const Key('path-studio-new-path-size-control'),
+            groupValue: draft.centerPatternLabel,
+            onValueChanged: (value) {
+              if (value == '1×1') {
+                onSizeChanged(1, 1);
+              } else if (value == '2×2') {
+                onSizeChanged(2, 2);
+              }
+            },
+            children: const {
+              '1×1': Padding(
+                key: Key('path-studio-new-path-size-1x1'),
+                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
+                child: Text('1×1'),
+              ),
+              '2×2': Padding(
+                key: Key('path-studio-new-path-size-2x2'),
+                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
+                child: Text('2×2'),
+              ),
+            },
+          ),
+          const SizedBox(height: 18),
+          _NewPathPatternGrid(
+            draft: draft,
+            onCellSelected: onCellSelected,
+          ),
+          const SizedBox(height: 14),
+          _NewPathSelectedCellDetails(draft: draft),
+        ],
+      ),
+    );
+  }
+}
+
+class _NewPathPatternGrid extends StatelessWidget {
+  const _NewPathPatternGrid({
+    required this.draft,
+    required this.onCellSelected,
+  });
+
+  final PathStudioNewPathDraft draft;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final rows = <Widget>[];
+    for (var y = 0; y < draft.centerHeight; y += 1) {
+      final cells = <Widget>[];
+      for (var x = 0; x < draft.centerWidth; x += 1) {
+        final cell = draft.cells.firstWhere(
+          (candidate) => candidate.localX == x && candidate.localY == y,
+        );
+        cells.add(
+          _NewPathPatternCell(
+            key: Key('path-studio-new-path-cell-$x-$y'),
+            cell: cell,
+            selected: draft.selectedCellX == x && draft.selectedCellY == y,
+            onTap: () => onCellSelected(x, y),
+          ),
+        );
+      }
+      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
+    }
+
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(
+        color: PathStudioTheme.backgroundAlt,
+      ),
+      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
+    );
+  }
+}
+
+class _NewPathPatternCell extends StatelessWidget {
+  const _NewPathPatternCell({
+    super.key,
+    required this.cell,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final PathStudioNewPathDraftCell cell;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    return GestureDetector(
+      onTap: onTap,
+      child: Container(
+        width: 112,
+        height: 92,
+        margin: const EdgeInsets.all(6),
+        padding: const EdgeInsets.all(10),
+        decoration: BoxDecoration(
+          color: Color.lerp(
+            PathStudioTheme.surfaceStrong,
+            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
+            selected ? 0.32 : 0.16,
+          ),
+          borderRadius: BorderRadius.circular(16),
+          border: Border.all(
+            color: selected
+                ? PathStudioTheme.accentHover
+                : PathStudioTheme.accentCyan.withValues(alpha: 0.45),
+            width: selected ? 2 : 1,
+          ),
+        ),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Text(
+              cell.label,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 18,
+                fontWeight: FontWeight.w900,
+              ),
+            ),
+            const Spacer(),
+            const Text(
+              'À configurer',
+              style: TextStyle(
+                color: PathStudioTheme.textSecondary,
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const Text(
+              'Aucune tuile',
+              style: TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 10,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _NewPathSelectedCellDetails extends StatelessWidget {
+  const _NewPathSelectedCellDetails({required this.draft});
+
+  final PathStudioNewPathDraft draft;
+
+  @override
+  Widget build(BuildContext context) {
+    final cell = draft.selectedCell;
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            'Cellule ${cell.label}',
+            style: const TextStyle(
+              color: PathStudioTheme.textPrimary,
+              fontSize: 13,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            'Position ${cell.localX},${cell.localY}',
+            style: const TextStyle(
+              color: PathStudioTheme.textSecondary,
+              fontSize: 12,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const Text(
+            'Aucune tuile configurée pour cette cellule.',
+            style: TextStyle(
+              color: PathStudioTheme.textMuted,
+              fontSize: 11,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _NewPathDiagnosticsCard extends StatelessWidget {
+  const _NewPathDiagnosticsCard({required this.draft});
+
+  final PathStudioNewPathDraft draft;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      title: 'Diagnostics locaux',
+      icon: CupertinoIcons.check_mark_circled,
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: draft.issues
+            .map(
+              (issue) => Padding(
+                padding: const EdgeInsets.only(bottom: 8),
+                child: _DiagnosticRow(
+                  icon: CupertinoIcons.info_circle_fill,
+                  color: issue == PathStudioNewPathDraftIssueCode.nameRequired
+                      ? PathStudioTheme.warning
+                      : PathStudioTheme.accentCyan,
+                  title: _newPathDraftIssueLabel(issue),
+                  message: _newPathDraftIssueDescription(issue),
+                ),
+              ),
+            )
+            .toList(growable: false),
+      ),
+    );
+  }
+}
+
+class _DraftCenterWorkspace extends StatelessWidget {
+  const _DraftCenterWorkspace({
+    required this.draft,
+    required this.onSizeChanged,
+    required this.onCellSelected,
+  });
+
+  final PathPatternDraft draft;
+  final void Function(int width, int height) onSizeChanged;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return SingleChildScrollView(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          const _DraftBanner(),
+          const SizedBox(height: 14),
+          const _WorkflowSteps(
+            status: PathPatternPresetReadinessStatus.needsReview,
+          ),
+          const SizedBox(height: 14),
+          _DraftSummary(draft: draft),
+          const SizedBox(height: 14),
+          _DraftCenterPatternEditor(
+            draft: draft,
+            onSizeChanged: onSizeChanged,
+            onCellSelected: onCellSelected,
+          ),
+          const SizedBox(height: 14),
+          _DraftDiagnosticsCard(draft: draft),
+        ],
+      ),
+    );
+  }
+}
+
+class _DraftBanner extends StatelessWidget {
+  const _DraftBanner();
+
+  @override
+  Widget build(BuildContext context) {
+    return const _SectionCard(
+      title: 'Motif depuis path existant',
+      icon: CupertinoIcons.pencil_outline,
+      trailing: _StatusChip(
+        label: 'Non sauvegardé',
+        color: PathStudioTheme.warning,
+      ),
+      child: Text(
+        'Ce brouillon réutilise temporairement une structure héritée. Il reste local et non sauvegardé.',
+        style: TextStyle(
+          color: PathStudioTheme.textSecondary,
+          fontSize: 13,
+          height: 1.4,
+        ),
+      ),
+    );
+  }
+}
+
+class _DraftSummary extends StatelessWidget {
+  const _DraftSummary({required this.draft});
+
+  final PathPatternDraft draft;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      title: 'Résumé du brouillon',
+      icon: CupertinoIcons.doc_text,
+      child: Wrap(
+        spacing: 10,
+        runSpacing: 10,
+        children: [
+          _InfoTile(label: 'Nom', value: draft.name),
+          _InfoTile(label: 'Structure héritée', value: draft.basePathPresetId),
+          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
+          _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
+          _InfoTile(label: 'Frames', value: '${draft.centerFrameCount}'),
+          _InfoTile(
+            label: 'Animation',
+            value: '${draft.animatedCellCount} cellules',
+          ),
+          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
+        ],
+      ),
+    );
+  }
+}
+
+class _DraftCenterPatternEditor extends StatelessWidget {
+  const _DraftCenterPatternEditor({
+    required this.draft,
+    required this.onSizeChanged,
+    required this.onCellSelected,
+  });
+
+  final PathPatternDraft draft;
+  final void Function(int width, int height) onSizeChanged;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      title: 'Motif du centre',
+      icon: CupertinoIcons.square_grid_2x2,
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          const Text(
+            'Le motif du centre sera répété dans les grandes zones pleines.',
+            style: TextStyle(
+              color: PathStudioTheme.textSecondary,
+              fontSize: 13,
+              height: 1.35,
+            ),
+          ),
+          const SizedBox(height: 14),
+          CupertinoSlidingSegmentedControl<String>(
+            key: const Key('path-studio-draft-size-control'),
+            groupValue: draft.centerPatternLabel,
+            onValueChanged: (value) {
+              if (value == '1×1') {
+                onSizeChanged(1, 1);
+              } else if (value == '2×2') {
+                onSizeChanged(2, 2);
+              }
+            },
+            children: const {
+              '1×1': Padding(
+                key: Key('path-studio-draft-size-1x1'),
+                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
+                child: Text('1×1'),
+              ),
+              '2×2': Padding(
+                key: Key('path-studio-draft-size-2x2'),
+                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
+                child: Text('2×2'),
+              ),
+            },
+          ),
+          const SizedBox(height: 18),
+          _DraftPatternGrid(
+            draft: draft,
+            onCellSelected: onCellSelected,
+          ),
+          const SizedBox(height: 14),
+          _DraftSelectedCellDetails(draft: draft),
+        ],
+      ),
+    );
+  }
+}
+
+class _DraftPatternGrid extends StatelessWidget {
+  const _DraftPatternGrid({
+    required this.draft,
+    required this.onCellSelected,
+  });
+
+  final PathPatternDraft draft;
+  final void Function(int localX, int localY) onCellSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final rows = <Widget>[];
+    var labelCode = 'A'.codeUnitAt(0);
+    for (var y = 0; y < draft.centerPattern.size.height; y += 1) {
+      final cells = <Widget>[];
+      for (var x = 0; x < draft.centerPattern.size.width; x += 1) {
+        final cell = draft.centerPattern.cellAt(x, y);
+        cells.add(
+          _DraftPatternCell(
+            key: Key('path-studio-draft-cell-$x-$y'),
+            label: String.fromCharCode(labelCode),
+            cell: cell,
+            selected: draft.selectedCellX == x && draft.selectedCellY == y,
+            onTap: () => onCellSelected(x, y),
+          ),
+        );
+        labelCode += 1;
+      }
+      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
+    }
+
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(
+        color: PathStudioTheme.backgroundAlt,
+      ),
+      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
+    );
+  }
+}
+
+class _DraftPatternCell extends StatelessWidget {
+  const _DraftPatternCell({
+    super.key,
+    required this.label,
+    required this.cell,
+    required this.selected,
+    required this.onTap,
+  });
+
   final String label;
+  final PathCenterPatternCell cell;
+  final bool selected;
+  final VoidCallback onTap;
 
   @override
   Widget build(BuildContext context) {
-    return Row(
-      mainAxisSize: MainAxisSize.min,
-      children: [
-        MacosIcon(icon, size: 12, color: PathStudioTheme.textMuted),
-        const SizedBox(width: 4),
-        Text(
-          label,
-          style: const TextStyle(
-            color: PathStudioTheme.textSecondary,
-            fontSize: 11,
-            fontWeight: FontWeight.w700,
+    final source = cell.frames.first.source;
+    return GestureDetector(
+      onTap: onTap,
+      child: Container(
+        width: 112,
+        height: 92,
+        margin: const EdgeInsets.all(6),
+        padding: const EdgeInsets.all(10),
+        decoration: BoxDecoration(
+          color: Color.lerp(
+            PathStudioTheme.surfaceStrong,
+            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
+            selected ? 0.32 : 0.16,
+          ),
+          borderRadius: BorderRadius.circular(16),
+          border: Border.all(
+            color: selected
+                ? PathStudioTheme.accentHover
+                : PathStudioTheme.accentCyan.withValues(alpha: 0.45),
+            width: selected ? 2 : 1,
           ),
         ),
-      ],
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Text(
+              label,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 18,
+                fontWeight: FontWeight.w900,
+              ),
+            ),
+            const Spacer(),
+            Text(
+              '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''}',
+              style: const TextStyle(
+                color: PathStudioTheme.textSecondary,
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            Text(
+              cell.frames.length > 1 ? 'animé' : 'statique',
+              style: const TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 10,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            Text(
+              'source ${source.x},${source.y}',
+              style: const TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 10,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ],
+        ),
+      ),
     );
   }
 }
 
-class _CenterWorkspace extends StatelessWidget {
-  const _CenterWorkspace({
-    required this.selected,
-    required this.hasAnyPreset,
-  });
+class _DraftSelectedCellDetails extends StatelessWidget {
+  const _DraftSelectedCellDetails({required this.draft});
 
-  final PathPatternPresetCardModel? selected;
-  final bool hasAnyPreset;
+  final PathPatternDraft draft;
 
   @override
   Widget build(BuildContext context) {
-    final card = selected;
-    if (card == null) {
-      return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
-    }
-
-    return SingleChildScrollView(
+    final cell = draft.selectedCell;
+    final source = cell.frames.first.source;
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(),
       child: Column(
-        crossAxisAlignment: CrossAxisAlignment.stretch,
+        crossAxisAlignment: CrossAxisAlignment.start,
         children: [
-          _WorkflowSteps(status: card.status),
-          const SizedBox(height: 14),
-          _SelectedSummary(card: card),
-          const SizedBox(height: 14),
-          _CenterPatternPlaceholder(card: card),
-          const SizedBox(height: 14),
-          _DiagnosticsCard(card: card),
+          const Text(
+            'Cellule sélectionnée',
+            style: TextStyle(
+              color: PathStudioTheme.textPrimary,
+              fontSize: 13,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            'Position ${cell.localX},${cell.localY}',
+            style: const TextStyle(
+              color: PathStudioTheme.textSecondary,
+              fontSize: 12,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          Text(
+            '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''} • source ${source.x},${source.y}',
+            style: const TextStyle(
+              color: PathStudioTheme.textMuted,
+              fontSize: 11,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
         ],
       ),
     );
   }
 }
 
+class _DraftDiagnosticsCard extends StatelessWidget {
+  const _DraftDiagnosticsCard({required this.draft});
+
+  final PathPatternDraft draft;
+
+  @override
+  Widget build(BuildContext context) {
+    final issues = draft.issues;
+    return _SectionCard(
+      title: 'Diagnostics locaux',
+      icon: CupertinoIcons.check_mark_circled,
+      child: issues.isEmpty
+          ? const _DiagnosticRow(
+              icon: CupertinoIcons.check_mark_circled_solid,
+              color: PathStudioTheme.success,
+              title: 'Aucune erreur locale',
+              message: 'Le brouillon est éditable en mémoire.',
+            )
+          : Column(
+              crossAxisAlignment: CrossAxisAlignment.stretch,
+              children: issues
+                  .map(
+                    (issue) => Padding(
+                      padding: const EdgeInsets.only(bottom: 8),
+                      child: _DiagnosticRow(
+                        icon: CupertinoIcons.exclamationmark_triangle_fill,
+                        color: PathStudioTheme.warning,
+                        title: _draftIssueLabel(issue),
+                        message: _draftIssueDescription(issue),
+                      ),
+                    ),
+                  )
+                  .toList(growable: false),
+            ),
+    );
+  }
+}
+
 class _NoSelectionCenter extends StatelessWidget {
   const _NoSelectionCenter({required this.hasAnyPreset});
 
@@ -1112,12 +2343,48 @@ class _DiagnosticsCard extends StatelessWidget {
 }
 
 class _PresetInspector extends StatelessWidget {
-  const _PresetInspector({required this.selected});
+  const _PresetInspector({
+    required this.manifest,
+    required this.newPathDraft,
+    required this.draft,
+    required this.selected,
+    required this.onNewPathNameChanged,
+    required this.onNewPathSizeChanged,
+    required this.onDraftNameChanged,
+    required this.onDraftBaseChanged,
+    required this.onDraftSizeChanged,
+  });
 
+  final ProjectManifest manifest;
+  final PathStudioNewPathDraft? newPathDraft;
+  final PathPatternDraft? draft;
   final PathPatternPresetCardModel? selected;
+  final ValueChanged<String> onNewPathNameChanged;
+  final void Function(int width, int height) onNewPathSizeChanged;
+  final ValueChanged<String> onDraftNameChanged;
+  final ValueChanged<String> onDraftBaseChanged;
+  final void Function(int width, int height) onDraftSizeChanged;
 
   @override
   Widget build(BuildContext context) {
+    final newPathDraft = this.newPathDraft;
+    if (newPathDraft != null) {
+      return _NewPathInspector(
+        draft: newPathDraft,
+        onNameChanged: onNewPathNameChanged,
+        onSizeChanged: onNewPathSizeChanged,
+      );
+    }
+    final draft = this.draft;
+    if (draft != null) {
+      return _LegacyDraftInspector(
+        manifest: manifest,
+        draft: draft,
+        onNameChanged: onDraftNameChanged,
+        onBaseChanged: onDraftBaseChanged,
+        onSizeChanged: onDraftSizeChanged,
+      );
+    }
     final card = selected;
     return Container(
       decoration: PathStudioTheme.panelDecoration(),
@@ -1170,6 +2437,289 @@ class _PresetInspector extends StatelessWidget {
   }
 }
 
+class _NewPathInspector extends StatelessWidget {
+  const _NewPathInspector({
+    required this.draft,
+    required this.onNameChanged,
+    required this.onSizeChanged,
+  });
+
+  final PathStudioNewPathDraft draft;
+  final ValueChanged<String> onNameChanged;
+  final void Function(int width, int height) onSizeChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(),
+      padding: const EdgeInsets.all(16),
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            const Text(
+              'Propriétés du nouveau chemin',
+              style: TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 16,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 14),
+            const _StatusChip(
+              label: 'Brouillon non sauvegardé',
+              color: PathStudioTheme.warning,
+            ),
+            const SizedBox(height: 14),
+            const _InspectorLabel('Nom'),
+            CupertinoTextField(
+              key: const Key('path-studio-new-path-name-field'),
+              placeholder: draft.name,
+              onChanged: onNameChanged,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+              ),
+              placeholderStyle: const TextStyle(
+                color: PathStudioTheme.textSecondary,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+              ),
+              decoration: BoxDecoration(
+                color: PathStudioTheme.surfaceRaised,
+                borderRadius: BorderRadius.circular(12),
+                border: Border.all(color: PathStudioTheme.border),
+              ),
+              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
+            ),
+            const SizedBox(height: 12),
+            const _InspectorLabel('Taille du centre'),
+            CupertinoSlidingSegmentedControl<String>(
+              groupValue: draft.centerPatternLabel,
+              onValueChanged: (value) {
+                if (value == '1×1') {
+                  onSizeChanged(1, 1);
+                } else if (value == '2×2') {
+                  onSizeChanged(2, 2);
+                }
+              },
+              children: const {
+                '1×1': Padding(
+                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                  child: Text('1×1'),
+                ),
+                '2×2': Padding(
+                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                  child: Text('2×2'),
+                ),
+              },
+            ),
+            const SizedBox(height: 14),
+            _InspectorRow(label: 'ID temporaire', value: draft.id),
+            _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
+            _InspectorRow(
+              label: 'Cellule sélectionnée',
+              value: 'Cellule ${draft.selectedCell.label}',
+            ),
+            const _InspectorRow(
+              label: 'État',
+              value: 'Brouillon non sauvegardé',
+            ),
+            const _InspectorRow(
+              label: 'Sauvegarde',
+              value: 'Non disponible dans ce lot',
+            ),
+            const _InspectorRow(
+              label: 'Prochaine étape',
+              value: 'Choisir un tileset et définir les tuiles',
+            ),
+            const SizedBox(height: 14),
+            _NewPathDiagnosticsCard(draft: draft),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _LegacyDraftInspector extends StatelessWidget {
+  const _LegacyDraftInspector({
+    required this.manifest,
+    required this.draft,
+    required this.onNameChanged,
+    required this.onBaseChanged,
+    required this.onSizeChanged,
+  });
+
+  final ProjectManifest manifest;
+  final PathPatternDraft draft;
+  final ValueChanged<String> onNameChanged;
+  final ValueChanged<String> onBaseChanged;
+  final void Function(int width, int height) onSizeChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(),
+      padding: const EdgeInsets.all(16),
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            const Text(
+              'Propriétés du motif depuis path existant',
+              style: TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 16,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 14),
+            const _StatusChip(
+              label: 'Brouillon non sauvegardé',
+              color: PathStudioTheme.warning,
+            ),
+            const SizedBox(height: 14),
+            const _InspectorLabel('Nom'),
+            CupertinoTextField(
+              key: const Key('path-studio-draft-name-field'),
+              placeholder: draft.name,
+              onChanged: onNameChanged,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+              ),
+              placeholderStyle: const TextStyle(
+                color: PathStudioTheme.textSecondary,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+              ),
+              decoration: BoxDecoration(
+                color: PathStudioTheme.surfaceRaised,
+                borderRadius: BorderRadius.circular(12),
+                border: Border.all(color: PathStudioTheme.border),
+              ),
+              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
+            ),
+            const SizedBox(height: 12),
+            const _InspectorLabel('Structure héritée'),
+            _DraftBasePopup(
+              manifest: manifest,
+              draft: draft,
+              onBaseChanged: onBaseChanged,
+            ),
+            const SizedBox(height: 12),
+            const _InspectorLabel('Taille du centre'),
+            CupertinoSlidingSegmentedControl<String>(
+              groupValue: draft.centerPatternLabel,
+              onValueChanged: (value) {
+                if (value == '1×1') {
+                  onSizeChanged(1, 1);
+                } else if (value == '2×2') {
+                  onSizeChanged(2, 2);
+                }
+              },
+              children: const {
+                '1×1': Padding(
+                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                  child: Text('1×1'),
+                ),
+                '2×2': Padding(
+                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                  child: Text('2×2'),
+                ),
+              },
+            ),
+            const SizedBox(height: 14),
+            _InspectorRow(label: 'ID temporaire', value: draft.id),
+            _InspectorRow(
+              label: 'Path existant réutilisé',
+              value: draft.basePathPresetId,
+            ),
+            _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
+            _InspectorRow(label: 'Frames', value: '${draft.centerFrameCount}'),
+            _InspectorRow(
+              label: 'Cellules animées',
+              value: '${draft.animatedCellCount}',
+            ),
+            _InspectorRow(
+              label: 'Transparent color',
+              value: draft.transparentColor?.toHexRgb() ?? 'Aucune',
+            ),
+            const _InspectorRow(
+              label: 'État',
+              value: 'Brouillon non sauvegardé',
+            ),
+            const SizedBox(height: 14),
+            _DraftDiagnosticsCard(draft: draft),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _DraftBasePopup extends StatelessWidget {
+  const _DraftBasePopup({
+    required this.manifest,
+    required this.draft,
+    required this.onBaseChanged,
+  });
+
+  final ProjectManifest manifest;
+  final PathPatternDraft draft;
+  final ValueChanged<String> onBaseChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return MacosPopupButton<String>(
+      key: const Key('path-studio-draft-base-popup'),
+      value: draft.basePathPresetId,
+      onChanged: (value) {
+        if (value != null) {
+          onBaseChanged(value);
+        }
+      },
+      items: [
+        for (final preset in manifest.pathPresets)
+          MacosPopupMenuItem<String>(
+            value: preset.id,
+            child: SizedBox(
+              width: 220,
+              child: Text(
+                '${preset.name} (${preset.id})',
+                overflow: TextOverflow.ellipsis,
+              ),
+            ),
+          ),
+      ],
+    );
+  }
+}
+
+class _InspectorLabel extends StatelessWidget {
+  const _InspectorLabel(this.label);
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 6),
+      child: Text(
+        label,
+        style: const TextStyle(
+          color: PathStudioTheme.textMuted,
+          fontSize: 10,
+          fontWeight: FontWeight.w800,
+        ),
+      ),
+    );
+  }
+}
+
 class _InspectorEmptyState extends StatelessWidget {
   const _InspectorEmptyState();
 
@@ -1439,3 +2989,36 @@ String _issueDescription(PathPatternPresetIssueCode issue) {
       'Plusieurs ProjectPathPreset legacy correspondent à la même base.',
   };
 }
+
+String _draftIssueLabel(PathPatternDraftIssueCode issue) {
+  return switch (issue) {
+    PathPatternDraftIssueCode.nameRequired => 'Nom requis',
+  };
+}
+
+String _draftIssueDescription(PathPatternDraftIssueCode issue) {
+  return switch (issue) {
+    PathPatternDraftIssueCode.nameRequired =>
+      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
+  };
+}
+
+String _newPathDraftIssueLabel(PathStudioNewPathDraftIssueCode issue) {
+  return switch (issue) {
+    PathStudioNewPathDraftIssueCode.nameRequired => 'Nom requis',
+    PathStudioNewPathDraftIssueCode.tilesetNotConfigured => 'Tileset à choisir',
+    PathStudioNewPathDraftIssueCode.cellsNotConfigured =>
+      'Cellules à configurer',
+  };
+}
+
+String _newPathDraftIssueDescription(PathStudioNewPathDraftIssueCode issue) {
+  return switch (issue) {
+    PathStudioNewPathDraftIssueCode.nameRequired =>
+      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
+    PathStudioNewPathDraftIssueCode.tilesetNotConfigured =>
+      'La sélection du tileset arrivera dans un lot futur.',
+    PathStudioNewPathDraftIssueCode.cellsNotConfigured =>
+      'Les cellules existent déjà mais aucune tuile n’est encore choisie.',
+  };
+}
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 56a8ddbb..d7abbfc0 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -94,18 +94,15 @@ void main() {
       expect(find.text('Aucun preset sélectionné'), findsWidgets);
     });
 
-    testWidgets('shows shell actions as visibly disabled placeholders',
+    testWidgets('creates a new path draft without legacy base presets',
         (tester) async {
       await _pumpPathStudio(
         tester,
-        manifest: _manifest(
-          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
-          pathPatternPresets: [_pathPatternPreset(id: 'water')],
-        ),
+        manifest: _manifest(),
       );
 
-      final newPresetButton = tester.widget<CupertinoButton>(
-        find.widgetWithText(CupertinoButton, 'Nouveau preset'),
+      final newPathButton = tester.widget<CupertinoButton>(
+        find.widgetWithText(CupertinoButton, 'Nouveau chemin'),
       );
       final duplicateButton = tester.widget<CupertinoButton>(
         find.widgetWithText(CupertinoButton, 'Dupliquer'),
@@ -114,10 +111,208 @@ void main() {
         find.widgetWithText(CupertinoButton, 'Enregistrer'),
       );
 
-      expect(newPresetButton.onPressed, isNull);
+      expect(find.text('Nouveau preset'), findsNothing);
+      expect(newPathButton.onPressed, isNotNull);
       expect(duplicateButton.onPressed, isNull);
       expect(saveButton.onPressed, isNull);
       expect(find.text('lot futur'), findsWidgets);
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
+      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
+      expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
+      expect(find.text('Nouveau chemin'), findsWidgets);
+      expect(find.text('1×1'), findsWidgets);
+      expect(find.text('Aucun preset Path de base disponible'), findsNothing);
+      expect(find.text('Preset de base'), findsNothing);
+      expect(find.text('Base path preset id'), findsNothing);
+      expect(
+        find.byKey(const Key('path-studio-new-path-cell-0-0')),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('new path draft does not force existing legacy path choices',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [
+            _legacyPathPreset(id: 'mountain-rock', name: 'mountain rock'),
+            _legacyPathPreset(id: 'tall_grass', name: 'tall_grass'),
+          ],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
+      expect(find.text('mountain rock'), findsNothing);
+      expect(find.text('tall_grass'), findsNothing);
+      expect(
+        find.byKey(const Key('path-studio-draft-base-popup')),
+        findsNothing,
+      );
+    });
+
+    testWidgets('resizes the new path draft to 2x2 and selects a cell',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(const Key('path-studio-new-path-size-2x2')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        find.byKey(const Key('path-studio-new-path-cell-0-0')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('path-studio-new-path-cell-1-0')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('path-studio-new-path-cell-0-1')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('path-studio-new-path-cell-1-1')),
+        findsOneWidget,
+      );
+      expect(find.text('A'), findsWidgets);
+      expect(find.text('B'), findsWidgets);
+      expect(find.text('C'), findsWidgets);
+      expect(find.text('D'), findsWidgets);
+      expect(find.text('À configurer'), findsWidgets);
+      expect(find.text('Aucune tuile'), findsWidgets);
+      expect(find.textContaining('source '), findsNothing);
+
+      final bottomRightCell =
+          find.byKey(const Key('path-studio-new-path-cell-1-1'));
+      await tester.ensureVisible(bottomRightCell);
+      await tester.pumpAndSettle();
+      await tester.tap(bottomRightCell);
+      await tester.pumpAndSettle();
+
+      expect(find.text('Cellule sélectionnée'), findsWidgets);
+      expect(find.text('Position 1,1'), findsWidgets);
+      expect(find.text('Cellule D'), findsWidgets);
+    });
+
+    testWidgets('edits new path draft name and keeps save disabled',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-new-path-name-field')),
+        'Route brouillon',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Route brouillon'), findsWidgets);
+      final saveButton = tester.widget<CupertinoButton>(
+        find.widgetWithText(CupertinoButton, 'Enregistrer'),
+      );
+      expect(saveButton.onPressed, isNull);
+    });
+
+    testWidgets('secondary legacy flow changes inherited structure locally',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [
+            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
+            _legacyPathPreset(
+              id: 'legacy-sand',
+              name: 'Base sable',
+              crossSourceX: 5,
+            ),
+          ],
+        ),
+      );
+
+      await tester.tap(
+        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-draft-name-field')),
+        'Mer brouillon',
+      );
+      await tester.pumpAndSettle();
+
+      final popup = tester.widget<MacosPopupButton<String>>(
+        find.byKey(const Key('path-studio-draft-base-popup')),
+      );
+      popup.onChanged?.call('legacy-sand');
+      await tester.pumpAndSettle();
+
+      expect(find.text('Propriétés du motif depuis path existant'),
+          findsOneWidget);
+      expect(find.text('Structure héritée'), findsWidgets);
+      expect(find.text('Mer brouillon'), findsWidgets);
+      expect(find.text('legacy-sand'), findsWidgets);
+      expect(find.text('source 5,0'), findsWidgets);
+      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
+    });
+
+    testWidgets('empty new path name shows a local diagnostic', (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('path-studio-new-path-name-field')),
+        '   ',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Nom requis'), findsWidgets);
+    });
+
+    testWidgets('secondary legacy flow reports missing existing paths',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(),
+      );
+
+      await tester.tap(
+        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Aucun path existant disponible'), findsWidgets);
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+
+      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
+      expect(find.text('Aucun path existant disponible'), findsNothing);
     });
   });
 }
@@ -163,11 +358,18 @@ ProjectManifest _manifest({
 ProjectPathPreset _legacyPathPreset({
   required String id,
   String name = 'Legacy Water',
+  int crossSourceX = 0,
 }) {
   return ProjectPathPreset(
     id: id,
     name: name,
     surfaceKind: PathSurfaceKind.water,
+    variants: [
+      PathPresetVariantMapping(
+        variant: TerrainPathVariant.cross,
+        frames: [_frame(crossSourceX)],
+      ),
+    ],
   );
 }
 
```

### Diff /dev/null complet — path_studio_new_path_draft.dart
```diff
--- /dev/null	2026-04-30 21:00:03
+++ packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart	2026-04-30 20:47:36
@@ -0,0 +1,184 @@
+enum PathStudioNewPathDraftIssueCode {
+  nameRequired,
+  tilesetNotConfigured,
+  cellsNotConfigured,
+}
+
+final class PathStudioNewPathDraftCell {
+  const PathStudioNewPathDraftCell({
+    required this.localX,
+    required this.localY,
+    required this.label,
+  });
+
+  final int localX;
+  final int localY;
+  final String label;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathStudioNewPathDraftCell &&
+            localX == other.localX &&
+            localY == other.localY &&
+            label == other.label;
+  }
+
+  @override
+  int get hashCode => Object.hash(localX, localY, label);
+}
+
+final class PathStudioNewPathDraft {
+  PathStudioNewPathDraft({
+    required this.id,
+    required this.name,
+    required this.centerWidth,
+    required this.centerHeight,
+    required this.selectedCellX,
+    required this.selectedCellY,
+    required this.isDirty,
+  })  : assert(centerWidth > 0),
+        assert(centerHeight > 0),
+        assert(selectedCellX >= 0 && selectedCellX < centerWidth),
+        assert(selectedCellY >= 0 && selectedCellY < centerHeight);
+
+  final String id;
+  final String name;
+  final int centerWidth;
+  final int centerHeight;
+  final int selectedCellX;
+  final int selectedCellY;
+  final bool isDirty;
+
+  String get centerPatternLabel => '$centerWidth×$centerHeight';
+
+  int get centerCellCount => centerWidth * centerHeight;
+
+  List<PathStudioNewPathDraftCell> get cells {
+    final result = <PathStudioNewPathDraftCell>[];
+    var labelCode = 'A'.codeUnitAt(0);
+    for (var y = 0; y < centerHeight; y += 1) {
+      for (var x = 0; x < centerWidth; x += 1) {
+        result.add(
+          PathStudioNewPathDraftCell(
+            localX: x,
+            localY: y,
+            label: String.fromCharCode(labelCode),
+          ),
+        );
+        labelCode += 1;
+      }
+    }
+    return List<PathStudioNewPathDraftCell>.unmodifiable(result);
+  }
+
+  PathStudioNewPathDraftCell get selectedCell {
+    return cells.firstWhere(
+      (cell) => cell.localX == selectedCellX && cell.localY == selectedCellY,
+    );
+  }
+
+  List<PathStudioNewPathDraftIssueCode> get issues {
+    final result = <PathStudioNewPathDraftIssueCode>[];
+    if (name.trim().isEmpty) {
+      result.add(PathStudioNewPathDraftIssueCode.nameRequired);
+    }
+    result.add(PathStudioNewPathDraftIssueCode.tilesetNotConfigured);
+    result.add(PathStudioNewPathDraftIssueCode.cellsNotConfigured);
+    return List<PathStudioNewPathDraftIssueCode>.unmodifiable(result);
+  }
+
+  PathStudioNewPathDraft copyWith({
+    String? id,
+    String? name,
+    int? centerWidth,
+    int? centerHeight,
+    int? selectedCellX,
+    int? selectedCellY,
+    bool? isDirty,
+  }) {
+    return PathStudioNewPathDraft(
+      id: id ?? this.id,
+      name: name ?? this.name,
+      centerWidth: centerWidth ?? this.centerWidth,
+      centerHeight: centerHeight ?? this.centerHeight,
+      selectedCellX: selectedCellX ?? this.selectedCellX,
+      selectedCellY: selectedCellY ?? this.selectedCellY,
+      isDirty: isDirty ?? this.isDirty,
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathStudioNewPathDraft &&
+            id == other.id &&
+            name == other.name &&
+            centerWidth == other.centerWidth &&
+            centerHeight == other.centerHeight &&
+            selectedCellX == other.selectedCellX &&
+            selectedCellY == other.selectedCellY &&
+            isDirty == other.isDirty;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        id,
+        name,
+        centerWidth,
+        centerHeight,
+        selectedCellX,
+        selectedCellY,
+        isDirty,
+      );
+}
+
+PathStudioNewPathDraft createInitialPathStudioNewPathDraft() {
+  return PathStudioNewPathDraft(
+    id: 'draft-new-path',
+    name: 'Nouveau chemin',
+    centerWidth: 1,
+    centerHeight: 1,
+    selectedCellX: 0,
+    selectedCellY: 0,
+    isDirty: true,
+  );
+}
+
+PathStudioNewPathDraft resizePathStudioNewPathDraftCenter({
+  required PathStudioNewPathDraft draft,
+  required int width,
+  required int height,
+}) {
+  return draft.copyWith(
+    centerWidth: width,
+    centerHeight: height,
+    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
+    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
+    isDirty: true,
+  );
+}
+
+PathStudioNewPathDraft renamePathStudioNewPathDraft(
+  PathStudioNewPathDraft draft,
+  String name,
+) {
+  return draft.copyWith(name: name, isDirty: true);
+}
+
+PathStudioNewPathDraft selectPathStudioNewPathDraftCell({
+  required PathStudioNewPathDraft draft,
+  required int localX,
+  required int localY,
+}) {
+  if (localX < 0 ||
+      localY < 0 ||
+      localX >= draft.centerWidth ||
+      localY >= draft.centerHeight) {
+    throw RangeError.range(localX, 0, draft.centerWidth - 1, 'localX');
+  }
+  return draft.copyWith(
+    selectedCellX: localX,
+    selectedCellY: localY,
+  );
+}
```

### Diff /dev/null complet — path_studio_new_path_draft_test.dart
```diff
--- /dev/null	2026-04-30 21:00:03
+++ packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart	2026-04-30 20:46:01
@@ -0,0 +1,115 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';
+
+void main() {
+  group('PathStudioNewPathDraft', () {
+    test('creates an initial draft without a legacy ProjectPathPreset', () {
+      final draft = createInitialPathStudioNewPathDraft();
+
+      expect(draft.id, 'draft-new-path');
+      expect(draft.name, 'Nouveau chemin');
+      expect(draft.centerWidth, 1);
+      expect(draft.centerHeight, 1);
+      expect(draft.centerPatternLabel, '1×1');
+      expect(draft.centerCellCount, 1);
+      expect(draft.selectedCellX, 0);
+      expect(draft.selectedCellY, 0);
+      expect(draft.isDirty, isTrue);
+      expect(draft.cells.map((cell) => cell.label), ['A']);
+      expect(draft.issues, [
+        PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
+        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
+      ]);
+    });
+
+    test('resizes a 1x1 draft to 2x2 placeholder cells', () {
+      final draft = createInitialPathStudioNewPathDraft();
+
+      final resized = resizePathStudioNewPathDraftCenter(
+        draft: draft,
+        width: 2,
+        height: 2,
+      );
+
+      expect(resized.centerPatternLabel, '2×2');
+      expect(resized.centerCellCount, 4);
+      expect(
+        resized.cells.map((cell) => (cell.localX, cell.localY, cell.label)),
+        [
+          (0, 0, 'A'),
+          (1, 0, 'B'),
+          (0, 1, 'C'),
+          (1, 1, 'D'),
+        ],
+      );
+      expect(resized.selectedCellX, 0);
+      expect(resized.selectedCellY, 0);
+    });
+
+    test('resizes a 2x2 draft back to 1x1 and clamps selection', () {
+      final twoByTwo = resizePathStudioNewPathDraftCenter(
+        draft: createInitialPathStudioNewPathDraft(),
+        width: 2,
+        height: 2,
+      );
+      final selected = selectPathStudioNewPathDraftCell(
+        draft: twoByTwo,
+        localX: 1,
+        localY: 1,
+      );
+
+      final resized = resizePathStudioNewPathDraftCenter(
+        draft: selected,
+        width: 1,
+        height: 1,
+      );
+
+      expect(resized.centerWidth, 1);
+      expect(resized.centerHeight, 1);
+      expect(resized.centerCellCount, 1);
+      expect(resized.selectedCellX, 0);
+      expect(resized.selectedCellY, 0);
+    });
+
+    test('renames the draft locally', () {
+      final draft = renamePathStudioNewPathDraft(
+        createInitialPathStudioNewPathDraft(),
+        'Route claire',
+      );
+
+      expect(draft.name, 'Route claire');
+      expect(draft.isDirty, isTrue);
+    });
+
+    test('empty name exposes nameRequired without blocking local editing', () {
+      final draft = renamePathStudioNewPathDraft(
+        createInitialPathStudioNewPathDraft(),
+        '   ',
+      );
+
+      expect(draft.issues, [
+        PathStudioNewPathDraftIssueCode.nameRequired,
+        PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
+        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
+      ]);
+    });
+
+    test('selects a placeholder cell by exact local coordinates', () {
+      final draft = resizePathStudioNewPathDraftCenter(
+        draft: createInitialPathStudioNewPathDraft(),
+        width: 2,
+        height: 2,
+      );
+
+      final selected = selectPathStudioNewPathDraftCell(
+        draft: draft,
+        localX: 1,
+        localY: 0,
+      );
+
+      expect(selected.selectedCellX, 1);
+      expect(selected.selectedCellY, 0);
+      expect(selected.selectedCell.label, 'B');
+    });
+  });
+}
```

## 18. Auto-review
- Le bis a-t-il modifié autre chose que le nécessaire ? Oui, uniquement les fichiers Path Studio et tests ciblés nécessaires, plus ce rapport. Les artefacts Lot 14 déjà non suivis restent présents mais n’ont pas été supprimés.
- Le read model a-t-il été réécrit inutilement ? Non, `path_pattern_editor_read_model.dart` n’a pas été modifié.
- Le nouveau draft dépend-il d’un path legacy ? Non, `PathStudioNewPathDraft` ne dépend ni de `ProjectPathPreset` ni de `ProjectManifest`.
- Les tests couvrent-ils réellement les cas V0 ? Oui : création sans legacy, absence de dropdown legacy, 1×1/2×2 placeholders, sélection cellule, nom vide, flux secondaire legacy, save/duplicate désactivés.
- Le dropdown legacy est-il limité au flux secondaire ? Oui, il est rendu par `_LegacyDraftInspector` uniquement.
- Les bases absentes et le flux secondaire vide sont-ils bien distingués ? Oui, `Nouveau chemin` fonctionne sans base, `Depuis un path existant` affiche `Aucun path existant disponible`.
- L’ordre et les presets existants restent-ils stables ? Oui, le read-only existant n’a pas été réécrit.
- Tous les non-objectifs sont-ils respectés ? Oui : pas de save flow, pas de manifest mutation, pas de `map_core`, pas de painter/canvas/runtime/gameplay/battle.

## 19. Review séparée si disponible
Reviewer séparé : sub-agent `Archimedes`, review-only, sans édition de fichiers.

Verdict reviewer : le code du 14-bis est propre pour la correction UX demandée. Aucun finding bloquant sur le code. Le reviewer a signalé l’artefact préexistant `reports/pathPattern/pathpattern_14_draft_editor_state_v0.md` comme hors périmètre si on l’associait au 14-bis. Décision : ne pas supprimer cet artefact car il était déjà présent avant ce lot ; le documenter comme préexistant.

Contrôles reviewer notables :
- aucun changement `map_core` ;
- le draft principal `Nouveau chemin` ne dépend pas de `ProjectPathPreset` ;
- dropdown legacy seulement dans le flux secondaire ;
- save désactivé et aucune mutation manifest ;
- plus de libellé principal `Nouveau preset` ;
- aucun import runtime/renderer accidentel dans les fichiers changés.

## 20. Critique du prompt
Clair : le prompt identifie précisément le problème produit : le flux principal devait raconter `je crée un chemin`, pas `je choisis une base legacy`. Les non-objectifs étaient suffisamment bornés pour éviter la sauvegarde et le vrai tile picker.

Ambigu : le prompt demande un rapport avec contenu complet de tous les fichiers créés, ce qui inclut littéralement le rapport lui-même. Cette exigence est auto-référentielle si elle est prise au pied de la lettre. J’ai donc inclus le contenu complet des fichiers source/test créés et considéré que le présent document est lui-même le contenu complet du rapport.

Discutable : le prompt demandait un lot court tout en exigeant un rapport très volumineux avec diff complet. Le coût documentaire devient supérieur au changement produit. Pour une suite plus fluide, un format Evidence Pack standardisé par lot serait plus robuste.

Choix pris : `tilesetNotConfigured` et `cellsNotConfigured` sont des issues informatives du draft, affichées en diagnostic local sans empêcher l’édition, puisque la sauvegarde n’existe pas encore.

Décision à valider avant Lot 15 : est-ce que le nouveau chemin draft doit rester un modèle UI pur ou commencer à préparer un vrai `ProjectPathPreset` local non persisté pour les bords/coins/jonctions ?

## 21. Risques / limites
- `path_studio_panel.dart` reste très gros. Le 14-bis a limité le refactor, mais un futur lot devrait extraire les panneaux nouveau draft et legacy draft pour maintenir la lisibilité.
- Le nouveau draft ne contient pas encore de tuiles, frames, tileset ni bordures ; il est volontairement non sauvegardable.
- Les diagnostics `tilesetNotConfigured` / `cellsNotConfigured` sont informatifs ; une future phase de sauvegarde devra décider quelles issues deviennent bloquantes.
- Le rapport Lot 14 préexistant reste visible en untracked ; il n’est pas un livrable du 14-bis.

## 22. Prochaine étape recommandée
Lot 15 recommandé : extraire les sous-panneaux Path Studio puis ajouter un premier choix local de tileset/tuiles pour remplir les cellules du `PathStudioNewPathDraft`, toujours sans sauvegarde manifest tant que le modèle complet de nouveau chemin n’est pas validé.

## 23. Checklist finale
- [x] Audit initial réalisé avant modification.
- [x] Git utilisé uniquement en lecture.
- [x] Aucun commit / push / reset / restore / stash / checkout.
- [x] map_core non modifié.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Aucun save flow.
- [x] Aucune mutation manifest.
- [x] Aucun painter.
- [x] Aucun canvas render.
- [x] Aucun runtime.
- [x] Aucun gameplay / battle.
- [x] Aucun tall grass.
- [x] Le bouton principal ne raconte plus “preset technique” mais “nouveau chemin”.
- [x] Nouveau chemin fonctionne même sans ProjectPathPreset legacy.
- [x] Nouveau chemin ne demande pas immédiatement de path existant.
- [x] Le dropdown legacy n’apparaît que dans le flux secondaire.
- [x] Le flux secondaire est clairement nommé “depuis un path existant” ou équivalent.
- [x] La taille 1×1 fonctionne dans le nouveau draft.
- [x] La taille 2×2 fonctionne dans le nouveau draft.
- [x] Les cellules du nouveau draft sont des placeholders, pas des frames legacy.
- [x] Enregistrer reste désactivé ou non opérationnel.
- [x] Dupliquer reste désactivé ou non opérationnel.
- [x] Les tests ciblés passent.
- [x] Les régressions pertinentes passent ou les échecs hors lot sont documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.

## 24. Confirmation explicite des non-objectifs
- Pas de sauvegarde dans `ProjectManifest.pathPatternPresets`.
- Pas de création persistée de `ProjectPathPreset`.
- Pas de mutation réelle du manifest.
- Pas de repository, service de persistance, provider Riverpod complexe, notifier ou controller.
- Pas de modification `map_core`, `ProjectManifest`, codecs PathPattern, generated files ou build_runner.
- Pas de painter, canvas render, runtime render, gameplay, battle, tall grass, Surface Studio, TSX/TMX, Mistral, PixelLab ou MCP ajouté.
- Pas de tile picker, frame picker, drag and drop, preview PNG réelle, preview animée réelle, duplication persistée ou suppression.
