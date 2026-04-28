# Lot 88-quater — Surface Mapping Editor like Path Mapping Editor V0

## Résumé exécutif honnête
Le lot est validable côté implémentation ciblée : l'éditeur de mapping Surface ne repose plus sur une liste/dropdown abstraite comme point d'entrée principal. Il expose maintenant un schéma de slots visuels, inspiré du Path Mapping Editor, où l'utilisateur sélectionne un slot de surface puis clique une colonne d'atlas/animation pour l'assigner directement.

Ce lot n'a pas modifié `map_core`, les schémas JSON, `ProjectManifest`, `map_runtime`, `map_gameplay` ou `map_battle`. Le save flow et le dirty state existants de Surface Studio sont conservés : la mutation reste le callback `role -> animationId` déjà branché au catalogue de travail.

Limite honnête : la preview visuelle des colonnes reste symbolique côté mapping editor de preset existant, car ce sous-écran ne reçoit pas encore l'image atlas décodée. La réparation importante ici est le modèle mental et l'interaction : slot visuel actif -> clic colonne -> assignation immédiate.

## Audit initial
### Gate 0 — status initial avant modification
```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
?? reports/surface/surface_engine_lot_88_ter_surface_studio_visual_role_mapping_layout_repair.md

git diff --stat
 .../surface_studio_role_mapping_editor.dart        | 895 ++++++++++++++++++---
 ...ce_studio_vertical_atlas_animation_preview.dart |  52 +-
 .../surface_studio/surface_studio_panel_test.dart  |  13 +-
 .../surface_studio_role_mapping_editor_test.dart   | 113 ++-
 ...udio_vertical_atlas_animation_preview_test.dart |  50 +-
 5 files changed, 973 insertions(+), 150 deletions(-)

git log --oneline -n 10
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
```

Le status initial était non vide. Ces changements sont traités comme préexistants du Lot 88-ter, sauf les modifications listées plus bas pour le 88-quater.

### Commandes d'audit lancées
```text
rg -n "Path Mapping|PathMapping|mapping editor|Mapping des|variant|slot|tileset|tile picker|Path.*Mapping|PathVariant|path mapping|Mapping" packages/map_editor/lib packages/map_editor/test
rg -n "SurfaceStudioRoleMapping|surface_role_mapping|Galerie des colonnes|Rôles Surface|SurfaceStudioPaintableSurfacesPanel|Modifier le mapping|mappingEditor|variantAnimations" packages/map_editor/lib/src/features/surface_studio packages/map_editor/test/surface_studio
rg -n "SurfaceVariantRole|standardSurfaceVariantRoleOrder|SurfaceVariantAnimationRef|animationIdForRole|variantAnimations" packages/map_core/lib packages/map_editor/lib packages/map_editor/test
rg -n "runPathMapping|PathMappingAssistant|MappingAssistant|TerrainPathVariant|path.*assistant|assistant" packages/map_editor/lib packages/map_editor/test -g '*.dart'
```

### Architecture constatée
- Le Path Mapping Editor est dans `packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart` et `packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart`.
- Son UX clé est : schéma de variantes à gauche, instruction explicite, slot actif, puis clic dans le tileset à droite pour assigner.
- Le Surface mapping editor du 88-ter était déjà passé d'un dropdown à une galerie de colonnes, mais le flux central restait encore : choisir une colonne puis cliquer un bouton d'assignation. Le slot visuel n'était pas le point d'entrée.
- La mutation catalogue est déjà correctement centralisée dans `SurfaceStudioPanel` via `SurfaceStudioRoleMappingEditor.onRoleAnimationChanged`, qui modifie le catalogue de travail et marque le dirty state.

### Problèmes observés
- Le mapping Surface ne copiait pas encore l'interaction principale du Path Mapping Editor : sélectionner un slot puis cliquer une source pour mapper.
- Les rôles étaient visibles, mais encore proches d'une liste abstraite.
- Le bouton d'entrée disait `Modifier le mapping`, ce qui ne signalait pas assez l'expérience visuelle.
- Le test d'intégration dirty/save utilisait encore l'ancien modèle d'assignation et devait couvrir le flux réel demandé.

## Implémentation
### Nouvelle UI de mapping visuel
Dans `SurfaceStudioRoleMappingEditor` :
- ajout d'un `Schéma des slots Surface` ;
- ajout de slots cliquables avec clés `surface_role_slot_<role>` ;
- affichage d'un slot actif ;
- regroupement visuel des rôles : forme principale 3x3, centre/continuités, jonctions et coins intérieurs ;
- glyphes de connexion dessinés par `CustomPainter` pour donner une lecture visuelle sans demander de connaître les enums ;
- détail du rôle actif conservé, avec explication humaine ;
- résumé des colonnes, assignées, non assignées, doublons, rôles manquants.

### Interaction slot -> colonne
Le flux principal devient :
1. l'utilisateur clique un slot dans le schéma ;
2. l'utilisateur clique une colonne dans la galerie ;
3. le callback `SurfaceVariantRole -> animationId` est appelé immédiatement ;
4. l'état optimiste local donne un feedback immédiat ;
5. le parent reconstruit ensuite le catalogue de travail comme avant.

Le bouton `Assigner cette colonne au rôle` reste disponible comme filet ergonomique, mais le nouveau flux ne dépend plus de lui.

### Corrections preview/layout
- La galerie reste contrainte par cartes avec largeur calculée.
- Les slots utilisent `Wrap` et `LayoutBuilder` pour éviter une grille cassante.
- Les labels longs utilisent `maxLines` et `overflow`.
- Le panneau peut se présenter en deux colonnes quand la largeur le permet, ou s'empiler proprement quand il est étroit.
- Le bouton du panneau surfaces devient `Modifier le mapping visuel`.

### Flux utilisateur désormais possible
- Ouvrir Surface Studio.
- Sélectionner une surface peignable.
- Cliquer `Modifier le mapping visuel`.
- Sélectionner un slot comme `Bord haut`.
- Cliquer une colonne/animation comme `Water Horizontal`.
- Voir le dirty state Surface Studio.
- Sauvegarder via le flux existant.

## Tests
### Tests ajoutés / modifiés
- `surface_studio_role_mapping_editor_test.dart`
  - ajout du test `visual slot then column click assigns the selected role` ;
  - vérification des slots visuels `cross`, `cornerNE`, `teeNorth` ;
  - vérification du résumé de validation ;
  - conservation des tests doublon, état vide, layout sans overflow.
- `surface_studio_panel_test.dart`
  - le test dirty/save flow utilise maintenant `Modifier le mapping visuel`, sélectionne `surface_role_slot_endNorth`, clique une colonne, puis sauvegarde.

### Commandes lancées et résultats
```text
cd packages/map_editor && flutter test test/surface_studio/surface_studio_role_mapping_editor_test.dart
=> 00:02 +7: All tests passed!

cd packages/map_editor && flutter test test/surface_studio/surface_studio_role_mapping_preview_test.dart
=> 00:01 +1: All tests passed!

cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart --plain-name '88-bis.1'
=> 00:02 +1: All tests passed!

cd packages/map_editor && flutter test test/surface_studio
=> 00:14 +405: All tests passed!

cd packages/map_editor && flutter test test/surface_painter
=> 00:03 +42: All tests passed!

cd packages/map_editor && flutter test test/map_selection_controller_test.dart
=> 00:02 +5: All tests passed!
```

### Analyse ciblée
```text
cd packages/map_editor && flutter analyze lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart test/surface_studio/surface_studio_role_mapping_editor_test.dart test/surface_studio/surface_studio_panel_test.dart
Analyzing 4 items...
No issues found! (ran in 1.3s)
```

### Analyse globale
```text
cd packages/map_editor && flutter analyze lib test
Analyzing 2 items...
417 issues found. (ran in 2.1s)
```

La dette globale est préexistante et hors lot. Les premiers problèmes remontés concernent notamment :
- `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart` : paramètres/typages Pokémon moves manquants (`dbSymbol`, `PokemonMoveAimedTarget`, `PokemonMoveFlags`, etc.) ;
- `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart` : méthode `fetchPokemonSdkStudioProjectPayload` absente ;
- de nombreux tests hors Surface Studio avec `ProjectManifest` sans `surfaceCatalog` ;
- divers lints historiques (`prefer_const`, `deprecated_member_use`, etc.).

Les fichiers Dart touchés par le lot sont clean en analyse ciblée.

## Fichiers
### Fichiers créés
- `reports/surface/surface_engine_lot_88_quater_surface_mapping_editor_like_path_mapping.md` — ce rapport.

### Fichiers modifiés par le Lot 88-quater
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

### Fichiers présents au status initial comme préexistants Lot 88-ter
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart` — déjà modifié avant le 88-quater, puis modifié par ce lot.
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart` — préexistant, non modifié par ce lot.
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart` — déjà modifié avant le 88-quater, puis modifié par ce lot.
- `packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart` — déjà modifié avant le 88-quater, puis modifié par ce lot.
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart` — préexistant, non modifié par ce lot.
- `reports/surface/surface_engine_lot_88_ter_surface_studio_visual_role_mapping_layout_repair.md` — préexistant, non modifié par ce lot.

### Fichiers supprimés
Aucun.

## Gate final — état avant insertion récursive de ce rapport
```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
?? reports/surface/surface_engine_lot_88_ter_surface_studio_visual_role_mapping_layout_repair.md

git diff --stat
 .../surface_studio_paintable_surfaces_panel.dart   |    2 +-
 .../surface_studio_role_mapping_editor.dart        | 1465 ++++++++++++++++++--
 ...ce_studio_vertical_atlas_animation_preview.dart |   52 +-
 .../surface_studio/surface_studio_panel_test.dart  |   18 +-
 .../surface_studio_role_mapping_editor_test.dart   |  166 ++-
 ...udio_vertical_atlas_animation_preview_test.dart |   50 +-
 6 files changed, 1603 insertions(+), 150 deletions(-)

find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
<aucune sortie>

git diff --check
<aucune sortie>
```

## Gate final — status final après création du rapport
```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
?? reports/surface/surface_engine_lot_88_quater_surface_mapping_editor_like_path_mapping.md
?? reports/surface/surface_engine_lot_88_ter_surface_studio_visual_role_mapping_layout_repair.md

git diff --stat
 .../surface_studio_paintable_surfaces_panel.dart   |    2 +-
 .../surface_studio_role_mapping_editor.dart        | 1465 ++++++++++++++++++--
 ...ce_studio_vertical_atlas_animation_preview.dart |   52 +-
 .../surface_studio/surface_studio_panel_test.dart  |   18 +-
 .../surface_studio_role_mapping_editor_test.dart   |  166 ++-
 ...udio_vertical_atlas_animation_preview_test.dart |   50 +-
 6 files changed, 1603 insertions(+), 150 deletions(-)

find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
<aucune sortie>

git diff --check
<aucune sortie>
```

- Aucun fichier présent au status initial n'a disparu du status final.
- Le nouveau fichier hors code apparu est ce rapport 88-quater.
- Le rapport 88-ter reste préexistant et non modifié par ce lot.
- Aucun fichier temporaire `_gen_*.py`, `build_*.py` ou `*.tmp` n'est présent.

## Périmètre explicitement non touché
- `map_core` non modifié.
- `ProjectManifest` non modifié.
- modèles Surface non modifiés.
- codecs JSON non modifiés.
- `map_runtime` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- aucun renderer runtime Surface créé.
- aucune animation clock runtime créée.
- aucun changement JSON.
- aucun nouveau provider/repository/service Surface.
- Surface Painter préservé.

## Limites restantes
- La galerie de colonnes du preset editor affiche encore une preview symbolique, pas l'image atlas réelle. Pour afficher les vraies tuiles ici, il faudra injecter l'image/tileset décodée dans ce sous-écran, ce qui dépasse le lot ciblé.
- Le modèle persistant reste `role -> animationId`. Les variantes multiples du centre sont mieux exposées visuellement via plusieurs rôles (`isolated`, `cross`, `horizontal`, `vertical`), mais il n'y a pas de collection multi-animation pour un même rôle.
- Le Path Mapping Editor complet peut cliquer directement dans une image tileset ; le Surface Mapping Editor clique dans des cartes d'animations/colonnes déjà générées. C'est cohérent avec le modèle Surface actuel, mais moins direct qu'un vrai atlas picker.

## Autocritique finale
Le lot corrige le cœur de l'interaction, mais il ne rend pas encore le mapping aussi visuel que le Path Mapping Editor original, car il ne montre pas l'atlas réel dans ce panneau. Le compromis est volontaire : brancher l'image source dans ce sous-écran aurait élargi le périmètre vers la résolution d'assets Surface Studio. Le résultat est beaucoup plus compréhensible qu'une liste de rôles, mais le prochain vrai gain visuel serait de réutiliser le painter/picker atlas du Path Mapping Editor pour sélectionner une colonne directement sur l'image.

## Regard critique sur le prompt
Le prompt demande “comme Path Mapping Editor”, mais Surface Studio manipule aujourd'hui des animations générées depuis colonnes, pas des cellules de tileset brutes. La transposition exacte n'est donc pas gratuite. Le prompt mentionne aussi le centre/plein multi-éléments, mais le modèle actuel ne permet pas plusieurs animations pour un même rôle sans changement de schéma ; le lot peut seulement mieux exposer les rôles proches du centre. Enfin, demander le contenu complet de tous les fichiers modifiés rend le rapport très volumineux, surtout avec des tests Surface Studio déjà longs.

## Contenu complet des fichiers modifiés par le Lot 88-quater
### `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_role_mapping_preview.dart';

const Color _accent = Color(0xFF2DD4BF);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);

/// Une animation Surface présentée comme une colonne d'atlas modifiable.
///
/// Dans les catalogues générés depuis un atlas vertical, chaque animation
/// correspond en pratique à une colonne. Le modèle persistant reste
/// rôle -> animationId ; cette vue reconstruit juste une lecture visuelle
/// colonne -> rôles pour que l'utilisateur n'édite plus une liste abstraite.
class SurfaceStudioRoleMappingColumnOption {
  const SurfaceStudioRoleMappingColumnOption({
    required this.animation,
    required this.atlasId,
    required this.columnIndex,
    required this.rowIndex,
    required this.assignedRoles,
  });

  final ProjectSurfaceAnimation animation;
  final String atlasId;
  final int columnIndex;
  final int rowIndex;
  final List<SurfaceVariantRole> assignedRoles;

  String get animationId => animation.id;

  int get frameCount => animation.frameCount;

  bool get isAssigned => assignedRoles.isNotEmpty;

  bool get hasDuplicateAssignment => assignedRoles.length > 1;
}

/// Analyse locale du preset courant pour alimenter la UI visuelle.
///
/// Elle ne valide pas le catalogue au sens métier global : elle résume seulement
/// ce que l'utilisateur doit voir pour corriger un mapping dans le catalogue de
/// travail Surface Studio.
class SurfaceStudioRoleMappingAnalysis {
  SurfaceStudioRoleMappingAnalysis._({
    required this.columns,
    required this.assignedColumnCount,
    required this.unassignedColumnCount,
    required this.duplicateAnimationCount,
    required this.missingRoleCount,
  });

  final List<SurfaceStudioRoleMappingColumnOption> columns;
  final int assignedColumnCount;
  final int unassignedColumnCount;
  final int duplicateAnimationCount;
  final int missingRoleCount;

  factory SurfaceStudioRoleMappingAnalysis.fromCatalog({
    required ProjectSurfaceCatalog catalog,
    required ProjectSurfacePreset preset,
  }) {
    final rolesByAnimation = <String, List<SurfaceVariantRole>>{};
    for (final ref in preset.variantAnimations.refs) {
      rolesByAnimation
          .putIfAbsent(ref.animationId, () => <SurfaceVariantRole>[])
          .add(ref.role);
    }

    final columns = <SurfaceStudioRoleMappingColumnOption>[];
    for (final animation in catalog.animations) {
      final firstFrame = animation.timeline.frames.first;
      columns.add(
        SurfaceStudioRoleMappingColumnOption(
          animation: animation,
          atlasId: firstFrame.tileRef.atlasId,
          columnIndex: firstFrame.tileRef.column,
          rowIndex: firstFrame.tileRef.row,
          assignedRoles: List<SurfaceVariantRole>.unmodifiable(
            rolesByAnimation[animation.id] ?? const <SurfaceVariantRole>[],
          ),
        ),
      );
    }

    columns.sort((a, b) {
      final atlas = a.atlasId.compareTo(b.atlasId);
      if (atlas != 0) {
        return atlas;
      }
      final col = a.columnIndex.compareTo(b.columnIndex);
      if (col != 0) {
        return col;
      }
      return a.animation.id.compareTo(b.animation.id);
    });

    final assigned = columns.where((column) => column.isAssigned).length;
    final duplicates =
        columns.where((column) => column.hasDuplicateAssignment).length;
    final missingRoles = standardSurfaceVariantRoleOrder
        .where((role) => !preset.containsRole(role))
        .length;

    return SurfaceStudioRoleMappingAnalysis._(
      columns: List<SurfaceStudioRoleMappingColumnOption>.unmodifiable(columns),
      assignedColumnCount: assigned,
      unassignedColumnCount: columns.length - assigned,
      duplicateAnimationCount: duplicates,
      missingRoleCount: missingRoles,
    );
  }

  SurfaceStudioRoleMappingColumnOption? columnByAnimationId(String? id) {
    if (id == null) {
      return null;
    }
    for (final column in columns) {
      if (column.animation.id == id) {
        return column;
      }
    }
    return null;
  }
}

class SurfaceStudioRoleMappingEditor extends StatefulWidget {
  const SurfaceStudioRoleMappingEditor({
    super.key,
    required this.catalog,
    required this.preset,
    this.onRoleAnimationChanged,
  });

  final ProjectSurfaceCatalog catalog;
  final ProjectSurfacePreset preset;
  final void Function(SurfaceVariantRole role, String animationId)?
      onRoleAnimationChanged;

  @override
  State<SurfaceStudioRoleMappingEditor> createState() =>
      _SurfaceStudioRoleMappingEditorState();
}

class _SurfaceStudioRoleMappingEditorState
    extends State<SurfaceStudioRoleMappingEditor> {
  SurfaceVariantRole _selectedRole = SurfaceVariantRole.cross;
  String? _selectedAnimationId;
  final Map<SurfaceVariantRole, String> _optimisticRoleAnimationIds =
      <SurfaceVariantRole, String>{};

  @override
  void didUpdateWidget(covariant SurfaceStudioRoleMappingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog != oldWidget.catalog ||
        widget.preset != oldWidget.preset) {
      _optimisticRoleAnimationIds.clear();
      final analysis = SurfaceStudioRoleMappingAnalysis.fromCatalog(
        catalog: widget.catalog,
        preset: widget.preset,
      );
      if (analysis.columnByAnimationId(_selectedAnimationId) == null) {
        _selectedAnimationId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final analysis = SurfaceStudioRoleMappingAnalysis.fromCatalog(
      catalog: widget.catalog,
      preset: widget.preset,
    );
    final selectedColumn = _resolveSelectedColumn(analysis);

    return Container(
      key: const ValueKey('surface_role_mapping_editor'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Édition du mapping de surface',
            style: TextStyle(
              color: label,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Surface sélectionnée : ${widget.preset.name}',
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Un atlas fournit des colonnes, une animation lit les frames d’une colonne, et un rôle indique où cette animation sera utilisée dans la surface.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (analysis.columns.isEmpty)
            _NoAnimationsState(subtle: subtle, label: label)
          else ...[
            _MappingSummary(analysis: analysis),
            const SizedBox(height: 10),
            _MappingWorkspace(
              analysis: analysis,
              preset: widget.preset,
              selectedRole: _selectedRole,
              selectedColumn: selectedColumn,
              selectedRoleAnimationId:
                  _effectiveAnimationIdForRole(_selectedRole),
              onRoleSelected: _selectRole,
              onColumnSelected: _selectColumn,
              onColumnAssigned: widget.onRoleAnimationChanged == null
                  ? null
                  : _assignColumnToSelectedRole,
            ),
          ],
        ],
      ),
    );
  }

  SurfaceStudioRoleMappingColumnOption? _resolveSelectedColumn(
    SurfaceStudioRoleMappingAnalysis analysis,
  ) {
    final explicit = analysis.columnByAnimationId(_selectedAnimationId);
    if (explicit != null) {
      return explicit;
    }
    final roleAnimationId = widget.preset.animationIdForRole(_selectedRole);
    final currentForRole = analysis.columnByAnimationId(roleAnimationId);
    if (currentForRole != null) {
      return currentForRole;
    }
    if (analysis.columns.isNotEmpty) {
      return analysis.columns.first;
    }
    return null;
  }

  String? _effectiveAnimationIdForRole(SurfaceVariantRole role) {
    return _optimisticRoleAnimationIds[role] ??
        widget.preset.animationIdForRole(role);
  }

  void _selectRole(SurfaceVariantRole role) {
    setState(() {
      _selectedRole = role;
      _selectedAnimationId =
          _effectiveAnimationIdForRole(role) ?? _selectedAnimationId;
    });
  }

  void _selectColumn(SurfaceStudioRoleMappingColumnOption column) {
    setState(() {
      _selectedAnimationId = column.animationId;
    });
  }

  void _assignColumnToSelectedRole(
    SurfaceStudioRoleMappingColumnOption column,
  ) {
    setState(() {
      _selectedAnimationId = column.animationId;
      // Le parent reconstruit normalement le catalogue de travail après le
      // callback. Cette écriture optimiste rend le retour visuel immédiat dans
      // les tests isolés et dans le cas d'un frame avant propagation Riverpod.
      _optimisticRoleAnimationIds[_selectedRole] = column.animationId;
    });
    widget.onRoleAnimationChanged?.call(_selectedRole, column.animationId);
  }
}

class _MappingWorkspace extends StatelessWidget {
  const _MappingWorkspace({
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedColumn,
    required this.selectedRoleAnimationId,
    required this.onRoleSelected,
    required this.onColumnSelected,
    required this.onColumnAssigned,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final SurfaceStudioRoleMappingColumnOption? selectedColumn;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption> onColumnSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption>? onColumnAssigned;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotPane = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SurfaceSlotSchema(
              analysis: analysis,
              preset: preset,
              selectedRole: selectedRole,
              selectedRoleAnimationId: selectedRoleAnimationId,
              onRoleSelected: onRoleSelected,
            ),
            const SizedBox(height: 10),
            _RoleDetail(
              preset: preset,
              selectedRole: selectedRole,
              selectedColumn: selectedColumn,
              currentColumn:
                  analysis.columnByAnimationId(selectedRoleAnimationId),
              canAssign: onColumnAssigned != null && selectedColumn != null,
              onAssign: selectedColumn == null || onColumnAssigned == null
                  ? null
                  : () => onColumnAssigned!(selectedColumn!),
            ),
          ],
        );

        final columnPane = _ColumnGallery(
          analysis: analysis,
          selectedRole: selectedRole,
          selectedAnimationId: selectedColumn?.animationId,
          selectedRoleAnimationId: selectedRoleAnimationId,
          onColumnSelected: onColumnSelected,
          onColumnAssigned: onColumnAssigned,
        );

        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: slotPane),
              const SizedBox(width: 10),
              Expanded(flex: 4, child: columnPane),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            slotPane,
            const SizedBox(height: 10),
            columnPane,
          ],
        );
      },
    );
  }
}

class _NoAnimationsState extends StatelessWidget {
  const _NoAnimationsState({
    required this.subtle,
    required this.label,
  });

  final Color subtle;
  final Color label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context)
            .withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucune animation disponible.',
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Générez d’abord les animations depuis l’atlas.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MappingSummary extends StatelessWidget {
  const _MappingSummary({required this.analysis});

  final SurfaceStudioRoleMappingAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_mapping_summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé du mapping',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetricChip('Colonnes : ${analysis.columns.length}'),
              _MetricChip('Assignées : ${analysis.assignedColumnCount}'),
              _MetricChip('Non assignées : ${analysis.unassignedColumnCount}'),
              _MetricChip(
                'Doublons : ${analysis.duplicateAnimationCount}',
                color: analysis.duplicateAnimationCount > 0 ? _danger : _accent,
              ),
              _MetricChip(
                'Rôles manquants : ${analysis.missingRoleCount}',
                color: analysis.missingRoleCount > 0 ? _warning : _accent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            analysis.duplicateAnimationCount > 0
                ? 'Un même extrait de colonne est utilisé par plusieurs rôles. Vérifiez que c’est volontaire.'
                : 'Chaque colonne assignée pointe vers un rôle unique.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SurfaceSlotSchema extends StatelessWidget {
  const _SurfaceSlotSchema({
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.onRoleSelected,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  static const List<SurfaceVariantRole> _mainSurfaceShape =
      <SurfaceVariantRole>[
    SurfaceVariantRole.cornerNW,
    SurfaceVariantRole.endNorth,
    SurfaceVariantRole.cornerNE,
    SurfaceVariantRole.endWest,
    SurfaceVariantRole.cross,
    SurfaceVariantRole.endEast,
    SurfaceVariantRole.cornerSW,
    SurfaceVariantRole.endSouth,
    SurfaceVariantRole.cornerSE,
  ];

  static const List<SurfaceVariantRole> _centerVariants = <SurfaceVariantRole>[
    SurfaceVariantRole.isolated,
    SurfaceVariantRole.horizontal,
    SurfaceVariantRole.vertical,
  ];

  static const List<SurfaceVariantRole> _junctionVariants =
      <SurfaceVariantRole>[
    SurfaceVariantRole.teeNorth,
    SurfaceVariantRole.teeEast,
    SurfaceVariantRole.teeSouth,
    SurfaceVariantRole.teeWest,
  ];

  static const List<SurfaceVariantRole> _innerCornerVariants =
      <SurfaceVariantRole>[
    SurfaceVariantRole.innerCornerNE,
    SurfaceVariantRole.innerCornerSE,
    SurfaceVariantRole.innerCornerSW,
    SurfaceVariantRole.innerCornerNW,
  ];

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_slot_schema'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Schéma des slots Surface',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cliquez un slot, puis une colonne',
            style: TextStyle(
              color: _accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Le slot représente la position logique de la tile dans une surface continue.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}',
            key: const ValueKey('surface_role_active_slot_label'),
            style: const TextStyle(
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _SurfaceSlotGrid(
            roles: _mainSurfaceShape,
            columns: 3,
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            onRoleSelected: onRoleSelected,
          ),
          const SizedBox(height: 10),
          Text(
            'Centre et continuités',
            style: TextStyle(
              color: label,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _SurfaceSlotWrap(
            roles: _centerVariants,
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            onRoleSelected: onRoleSelected,
          ),
          const SizedBox(height: 10),
          Text(
            'Jonctions et coins intérieurs',
            style: TextStyle(
              color: label,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _SurfaceSlotWrap(
            roles: const <SurfaceVariantRole>[
              ..._junctionVariants,
              ..._innerCornerVariants,
            ],
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            onRoleSelected: onRoleSelected,
          ),
        ],
      ),
    );
  }
}

class _SurfaceSlotGrid extends StatelessWidget {
  const _SurfaceSlotGrid({
    required this.roles,
    required this.columns,
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.onRoleSelected,
  });

  final List<SurfaceVariantRole> roles;
  final int columns;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final available = constraints.maxWidth - (gap * (columns - 1));
        final cellWidth = available / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final role in roles)
              SizedBox(
                width: cellWidth,
                child: _SurfaceRoleSlot(
                  role: role,
                  column: _columnForRole(role),
                  selected: role == selectedRole,
                  isSelectedRoleAssignment:
                      selectedRole == role && selectedRoleAnimationId != null,
                  onTap: () => onRoleSelected(role),
                ),
              ),
          ],
        );
      },
    );
  }

  SurfaceStudioRoleMappingColumnOption? _columnForRole(
    SurfaceVariantRole role,
  ) {
    final animationId = role == selectedRole
        ? selectedRoleAnimationId
        : preset.animationIdForRole(role);
    return analysis.columnByAnimationId(animationId);
  }
}

class _SurfaceSlotWrap extends StatelessWidget {
  const _SurfaceSlotWrap({
    required this.roles,
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.onRoleSelected,
  });

  final List<SurfaceVariantRole> roles;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final role in roles)
          SizedBox(
            width: 112,
            child: _SurfaceRoleSlot(
              role: role,
              column: _columnForRole(role),
              selected: role == selectedRole,
              isSelectedRoleAssignment:
                  selectedRole == role && selectedRoleAnimationId != null,
              onTap: () => onRoleSelected(role),
            ),
          ),
      ],
    );
  }

  SurfaceStudioRoleMappingColumnOption? _columnForRole(
    SurfaceVariantRole role,
  ) {
    final animationId = role == selectedRole
        ? selectedRoleAnimationId
        : preset.animationIdForRole(role);
    return analysis.columnByAnimationId(animationId);
  }
}

class _SurfaceRoleSlot extends StatelessWidget {
  const _SurfaceRoleSlot({
    required this.role,
    required this.column,
    required this.selected,
    required this.isSelectedRoleAssignment,
    required this.onTap,
  });

  final SurfaceVariantRole role;
  final SurfaceStudioRoleMappingColumnOption? column;
  final bool selected;
  final bool isSelectedRoleAssignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final linked = column != null || isSelectedRoleAssignment;
    final color = linked ? _accent : _warning;
    return GestureDetector(
      key: ValueKey('surface_role_slot_${role.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.20)
              : EditorChrome.elevatedPanelBackground(context)
                  .withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.90)
                : color.withValues(alpha: 0.34),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SurfaceRoleGlyph(role: role, selected: selected, linked: linked),
            const SizedBox(height: 5),
            Text(
              surfaceStudioRoleMappingLabel(role),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 9.6,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              column == null ? 'À lier' : 'Col ${column!.columnIndex}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: column == null ? subtle : _accent,
                fontSize: 8.7,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceRoleGlyph extends StatelessWidget {
  const _SurfaceRoleGlyph({
    required this.role,
    required this.selected,
    required this.linked,
  });

  final SurfaceVariantRole role;
  final bool selected;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 26,
      child: CustomPaint(
        painter: _SurfaceRoleGlyphPainter(
          role: role,
          selected: selected,
          linked: linked,
        ),
      ),
    );
  }
}

class _SurfaceRoleGlyphPainter extends CustomPainter {
  const _SurfaceRoleGlyphPainter({
    required this.role,
    required this.selected,
    required this.linked,
  });

  final SurfaceVariantRole role;
  final bool selected;
  final bool linked;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.24;
    final active = selected ? _accent : _accent.withValues(alpha: 0.82);
    final inactive = linked
        ? _accent.withValues(alpha: 0.24)
        : _warning.withValues(alpha: 0.22);
    final activePaint = Paint()
      ..color = active
      ..strokeWidth = selected ? 3 : 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final inactivePaint = Paint()
      ..color = inactive
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = (linked ? _accent : _warning).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, inactivePaint);

    final connections = _surfaceRoleConnections(role);
    final north = Offset(center.dx, 1.5);
    final east = Offset(size.width - 1.5, center.dy);
    final south = Offset(center.dx, size.height - 1.5);
    final west = Offset(1.5, center.dy);

    void drawArm(bool enabled, Offset target) {
      canvas.drawLine(center, target, enabled ? activePaint : inactivePaint);
    }

    drawArm(connections.north, north);
    drawArm(connections.east, east);
    drawArm(connections.south, south);
    drawArm(connections.west, west);

    final notch = _surfaceInnerCornerAlignment(role);
    if (notch != null) {
      final notchCenter = Offset(
        center.dx + notch.dx * radius * 1.35,
        center.dy + notch.dy * radius * 1.35,
      );
      canvas.drawCircle(
        notchCenter,
        4,
        Paint()
          ..color = _danger.withValues(alpha: 0.60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceRoleGlyphPainter oldDelegate) {
    return oldDelegate.role != role ||
        oldDelegate.selected != selected ||
        oldDelegate.linked != linked;
  }
}

class _ColumnGallery extends StatelessWidget {
  const _ColumnGallery({
    required this.analysis,
    required this.selectedRole,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
    required this.onColumnSelected,
    required this.onColumnAssigned,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final SurfaceVariantRole selectedRole;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption> onColumnSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption>? onColumnAssigned;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_column_gallery'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galerie des colonnes',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez une colonne pour l’assigner au slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardWidth = width >= 248 ? (width - 8) / 2 : width;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final column in analysis.columns)
                    SizedBox(
                      width: cardWidth,
                      child: _ColumnCard(
                        column: column,
                        selected: column.animationId == selectedAnimationId,
                        assignedToSelectedRole:
                            column.animationId == selectedRoleAnimationId,
                        onTap: () {
                          onColumnSelected(column);
                          onColumnAssigned?.call(column);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColumnCard extends StatelessWidget {
  const _ColumnCard({
    required this.column,
    required this.selected,
    required this.assignedToSelectedRole,
    required this.onTap,
  });

  final SurfaceStudioRoleMappingColumnOption column;
  final bool selected;
  final bool assignedToSelectedRole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final statusColor = assignedToSelectedRole
        ? _accent
        : column.hasDuplicateAssignment
            ? _danger
            : column.isAssigned
                ? _accent
                : _warning;
    return GestureDetector(
      key: ValueKey('surface_role_column_card_${column.animationId}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.15)
              : EditorChrome.elevatedPanelBackground(context)
                  .withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _accent.withValues(alpha: 0.82)
                : statusColor.withValues(alpha: 0.35),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Col ${column.columnIndex}',
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _StatusPill(
                  label: column.hasDuplicateAssignment
                      ? 'Doublon'
                      : assignedToSelectedRole
                          ? 'Assigné au slot actif'
                          : column.isAssigned
                              ? 'Assignée'
                              : 'Non assignée',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 7),
            _ColumnMiniPreview(column: column),
            const SizedBox(height: 7),
            Text(
              column.animation.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${column.frameCount} frame(s) · ${column.atlasId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: subtle, fontSize: 9.5, height: 1.2),
            ),
            if (column.assignedRoles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                column.assignedRoles
                    .map(surfaceStudioRoleMappingLabel)
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColumnMiniPreview extends StatelessWidget {
  const _ColumnMiniPreview({required this.column});

  final SurfaceStudioRoleMappingColumnOption column;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return Center(
      child: Container(
        key: ValueKey('surface_role_column_preview_${column.animationId}'),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accent.withValues(alpha: 0.42)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'C${column.columnIndex}',
              style: const TextStyle(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                for (var i = 0; i < column.frameCount.clamp(1, 6); i++)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.30 + i * 0.07),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Frame 1',
              style: TextStyle(color: subtle, fontSize: 8.5, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDetail extends StatelessWidget {
  const _RoleDetail({
    required this.preset,
    required this.selectedRole,
    required this.selectedColumn,
    required this.currentColumn,
    required this.canAssign,
    this.onAssign,
  });

  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final SurfaceStudioRoleMappingColumnOption? selectedColumn;
  final SurfaceStudioRoleMappingColumnOption? currentColumn;
  final bool canAssign;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final selected = selectedColumn;
    final current = currentColumn;
    return _Panellet(
      key: const ValueKey('surface_role_detail_panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détail du rôle',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}',
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _roleExplanation(selectedRole),
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          SurfaceStudioRoleMappingPreview(
            preset: preset,
            selectedRole: selectedRole,
            onRoleSelected: (_) {},
          ),
          const SizedBox(height: 10),
          _DetailLine(
            label: 'Animation actuelle du rôle',
            value: current == null
                ? 'Aucune colonne liée'
                : 'Col ${current.columnIndex} — ${current.animation.name}',
          ),
          _DetailLine(
            label: 'Colonne sélectionnée',
            value: selected == null
                ? 'Aucune'
                : 'Col ${selected.columnIndex} — ${selected.animation.name}',
          ),
          const SizedBox(height: 10),
          CupertinoButton(
            key: const ValueKey('surface_role_assign_column'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: _accent.withValues(alpha: 0.72),
            disabledColor:
                EditorChrome.islandFillElevated(context).withValues(alpha: 0.6),
            onPressed: canAssign ? onAssign : null,
            child: const Text('Assigner cette colonne au rôle'),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label : $value',
        style: TextStyle(
          color: labelColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.label, {this.color = _accent});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Panellet extends StatelessWidget {
  const _Panellet({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context)
            .withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: child,
    );
  }
}

({bool north, bool east, bool south, bool west}) _surfaceRoleConnections(
  SurfaceVariantRole role,
) {
  return switch (role) {
    SurfaceVariantRole.isolated => (
        north: false,
        east: false,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endNorth => (
        north: true,
        east: false,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endEast => (
        north: false,
        east: true,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endSouth => (
        north: false,
        east: false,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.endWest => (
        north: false,
        east: false,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.horizontal => (
        north: false,
        east: true,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.vertical => (
        north: true,
        east: false,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.cornerNE => (
        north: true,
        east: true,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.cornerSE => (
        north: false,
        east: true,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.cornerSW => (
        north: false,
        east: false,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.cornerNW => (
        north: true,
        east: false,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.innerCornerNE => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerSE => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerSW => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerNW => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.teeNorth => (
        north: true,
        east: true,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.teeEast => (
        north: true,
        east: true,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.teeSouth => (
        north: false,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.teeWest => (
        north: true,
        east: false,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.cross => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
  };
}

Offset? _surfaceInnerCornerAlignment(SurfaceVariantRole role) {
  return switch (role) {
    SurfaceVariantRole.innerCornerNE => const Offset(1, -1),
    SurfaceVariantRole.innerCornerSE => const Offset(1, 1),
    SurfaceVariantRole.innerCornerSW => const Offset(-1, 1),
    SurfaceVariantRole.innerCornerNW => const Offset(-1, -1),
    _ => null,
  };
}

String _roleExplanation(SurfaceVariantRole role) {
  switch (role) {
    case SurfaceVariantRole.isolated:
      return 'Plein : tuile utilisée pour une cellule seule ou un centre simple sans voisin compatible.';
    case SurfaceVariantRole.endNorth:
      return 'Bord haut : limite supérieure d’une zone de surface.';
    case SurfaceVariantRole.endEast:
      return 'Bord droit : limite droite d’une zone de surface.';
    case SurfaceVariantRole.endSouth:
      return 'Bord bas : limite inférieure d’une zone de surface.';
    case SurfaceVariantRole.endWest:
      return 'Bord gauche : limite gauche d’une zone de surface.';
    case SurfaceVariantRole.horizontal:
      return 'Horizontal : segment qui continue vers la gauche et la droite.';
    case SurfaceVariantRole.vertical:
      return 'Vertical : segment qui continue vers le haut et le bas.';
    case SurfaceVariantRole.cornerNE:
      return 'Coin haut droit : angle extérieur supérieur droit.';
    case SurfaceVariantRole.cornerSE:
      return 'Coin bas droit : angle extérieur inférieur droit.';
    case SurfaceVariantRole.cornerSW:
      return 'Coin bas gauche : angle extérieur inférieur gauche.';
    case SurfaceVariantRole.cornerNW:
      return 'Coin haut gauche : angle extérieur supérieur gauche.';
    case SurfaceVariantRole.innerCornerNE:
      return 'Coin intérieur haut droit : creux interne orienté vers le haut droit.';
    case SurfaceVariantRole.innerCornerSE:
      return 'Coin intérieur bas droit : creux interne orienté vers le bas droit.';
    case SurfaceVariantRole.innerCornerSW:
      return 'Coin intérieur bas gauche : creux interne orienté vers le bas gauche.';
    case SurfaceVariantRole.innerCornerNW:
      return 'Coin intérieur haut gauche : creux interne orienté vers le haut gauche.';
    case SurfaceVariantRole.teeNorth:
      return 'Jonction T haut : branche qui rejoint gauche, droite et haut.';
    case SurfaceVariantRole.teeEast:
      return 'Jonction T droite : branche qui rejoint haut, bas et droite.';
    case SurfaceVariantRole.teeSouth:
      return 'Jonction T bas : branche qui rejoint gauche, droite et bas.';
    case SurfaceVariantRole.teeWest:
      return 'Jonction T gauche : branche qui rejoint haut, bas et gauche.';
    case SurfaceVariantRole.cross:
      return 'Croix : jonction centrale multi-branches ou centre d’une grande zone continue.';
  }
}

```
### `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const Color _accent = Color(0xFF2DD4BF);

/// Panneau final du workflow : les surfaces réellement peignables.
///
/// Les presets restent l’unité technique du catalogue, mais l’UI parle ici de
/// surfaces à peindre pour éviter que l’utilisateur confonde atlas, animations
/// et résultat final utilisable dans l’éditeur de map.
class SurfaceStudioPaintableSurfacesPanel extends StatelessWidget {
  const SurfaceStudioPaintableSurfacesPanel({
    super.key,
    required this.readModel,
    this.selectedPresetId,
    this.onCreateSurfacePressed,
    this.onSaveCatalogPressed,
    this.onPresetSelected,
    this.onEditMappingPressed,
    this.mappingEditor,
  });

  final SurfaceStudioReadModel readModel;
  final String? selectedPresetId;
  final VoidCallback? onCreateSurfacePressed;
  final VoidCallback? onSaveCatalogPressed;
  final ValueChanged<String>? onPresetSelected;
  final ValueChanged<String>? onEditMappingPressed;
  final Widget? mappingEditor;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final presets = readModel.presets;
    final hasAnimations = readModel.summary.animationCount > 0;
    final hasSurfaces = presets.isNotEmpty;

    return Container(
      key: const ValueKey('surface_studio_paintable_surfaces_panel'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Surfaces prêtes à peindre',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ces surfaces seront disponibles dans l’éditeur de map pour peindre vos niveaux.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (!hasSurfaces)
            _EmptyPaintableState(hasAnimations: hasAnimations)
          else
            for (var i = 0; i < presets.length; i++) ...[
              _PaintableSurfaceRow(
                row: presets[i],
                selected: presets[i].id == selectedPresetId,
                onSelect: onPresetSelected == null
                    ? null
                    : () => onPresetSelected!(presets[i].id),
                onEditMapping: onEditMappingPressed == null
                    ? null
                    : () => onEditMappingPressed!(presets[i].id),
              ),
              if (i != presets.length - 1) const SizedBox(height: 8),
            ],
          if (mappingEditor != null) ...[
            const SizedBox(height: 12),
            mappingEditor!,
          ],
          const SizedBox(height: 12),
          CupertinoButton(
            key: const ValueKey('surface_studio_guidance_create_surface'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            color: _accent.withValues(alpha: 0.72),
            disabledColor: EditorChrome.islandFillElevated(context)
                .withValues(alpha: 0.72),
            onPressed: onCreateSurfacePressed,
            child: const Text('Créer une surface'),
          ),
          if (onCreateSurfacePressed == null) ...[
            const SizedBox(height: 6),
            Text(
              hasAnimations
                  ? 'Utilisez le bloc “Créer une surface à peindre” après avoir généré les animations.'
                  : 'Générez d’abord les animations depuis l’atlas.',
              style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
            ),
          ],
          if (onSaveCatalogPressed != null) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surface_studio_guidance_save_catalog'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              onPressed: onSaveCatalogPressed,
              child: const Text('Sauvegarder le catalogue'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPaintableState extends StatelessWidget {
  const _EmptyPaintableState({required this.hasAnimations});

  final bool hasAnimations;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasAnimations
                ? 'Animations détectées, mais aucune surface peignable.'
                : 'Aucune surface prête à peindre',
            style: TextStyle(
              color: label,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasAnimations
                ? 'Créez une surface à partir des animations générées.'
                : 'Générez des animations depuis un atlas, puis créez une surface peignable.',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.95),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaintableSurfaceRow extends StatelessWidget {
  const _PaintableSurfaceRow({
    required this.row,
    required this.selected,
    this.onSelect,
    this.onEditMapping,
  });

  final SurfaceStudioPresetReadModel row;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onEditMapping;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final content = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected
            ? _accent.withValues(alpha: 0.12)
            : EditorChrome.islandFillElevated(context).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? _accent.withValues(alpha: 0.68)
              : EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Peignable',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID : ${row.id}',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          Text(
            '${row.referencedAnimationIds.length} animation(s) liée(s)',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          if (onEditMapping != null) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              key: ValueKey('surface_paintable_edit_mapping_${row.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              onPressed: onEditMapping,
              child: const Text('Modifier le mapping visuel'),
            ),
          ],
        ],
      ),
    );
    if (onSelect == null) {
      return content;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: content,
    );
  }
}

```
### `packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_mapping_editor.dart';

void main() {
  testWidgets('editor lists roles, current animation and missing roles',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Édition du mapping de surface'), findsOneWidget);
    expect(find.text('Surface sélectionnée : Water Surface'), findsOneWidget);
    expect(find.text('Centre / plein'), findsWidgets);
    expect(find.text('Bord haut'), findsWidgets);
    expect(find.textContaining('Water Cross'), findsWidgets);
    expect(find.text('Animation manquante'), findsWidgets);
    expect(find.textContaining('ProjectSurfacePreset'), findsNothing);
    expect(find.textContaining('SurfaceVariantAnimationRef'), findsNothing);
    expect(find.textContaining('copyWith'), findsNothing);
  });

  testWidgets('changing a role animation invokes the callback', (tester) async {
    SurfaceVariantRole? changedRole;
    String? changedAnimationId;
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (role, animationId) {
            changedRole = role;
            changedAnimationId = animationId;
          },
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('surface_role_column_card_anim-horizontal')),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('surface_role_assign_column')),
      220,
    );
    await tester.tap(find.byKey(const ValueKey('surface_role_assign_column')));
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.cross);
    expect(changedAnimationId, 'anim-horizontal');
  });

  testWidgets('visual slot then column click assigns the selected role',
      (tester) async {
    SurfaceVariantRole? changedRole;
    String? changedAnimationId;
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (role, animationId) {
            changedRole = role;
            changedAnimationId = animationId;
          },
        ),
      ),
    );

    expect(find.text('Schéma des slots Surface'), findsOneWidget);
    expect(find.text('Cliquez un slot, puis une colonne'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('surface_role_slot_endNorth')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('surface_role_active_slot_label')),
      findsOneWidget,
    );
    expect(find.text('Slot actif : Bord haut'), findsWidgets);
    expect(find.textContaining('limite supérieure'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('surface_role_column_card_anim-horizontal')),
    );
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.endNorth);
    expect(changedAnimationId, 'anim-horizontal');
    expect(find.text('Assigné au slot actif'), findsOneWidget);
  });

  testWidgets('visual gallery exposes columns, selection and mapping summary',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Galerie des colonnes'), findsOneWidget);
    expect(find.text('Col 0'), findsWidgets);
    expect(find.text('Col 1'), findsOneWidget);
    expect(find.text('Assigné au slot actif'), findsOneWidget);
    expect(find.text('Non assignée'), findsOneWidget);
    expect(find.text('Résumé du mapping'), findsOneWidget);
    expect(find.text('Schéma des slots Surface'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('surface_role_slot_cross')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('surface_role_slot_cornerNE')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('surface_role_slot_teeNorth')),
      findsOneWidget,
    );
    expect(find.text('Colonnes : 2'), findsOneWidget);
    expect(find.text('Assignées : 1'), findsOneWidget);
    expect(find.text('Non assignées : 1'), findsOneWidget);
    expect(find.textContaining('Rôles manquants'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('surface_role_column_card_anim-horizontal')),
    );
    await tester.pump();

    expect(find.textContaining('Colonne sélectionnée : Col 1'), findsOneWidget);
    expect(find.textContaining('Water Horizontal'), findsWidgets);
  });

  testWidgets('duplicate animation assignments are visible', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _duplicateCatalog(),
          preset: _duplicateCatalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.textContaining('Doublons : 1'), findsOneWidget);
    expect(find.text('Doublon'), findsWidgets);
  });

  testWidgets('role detail explains the selected role without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 330,
          child: SurfaceStudioRoleMappingEditor(
            catalog: _catalog(),
            preset: _catalog().presetById('water-surface')!,
            onRoleAnimationChanged: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Détail du rôle'), findsOneWidget);
    expect(find.textContaining('jonction centrale'), findsOneWidget);
  });

  testWidgets('shows clear copy when no animation is available',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: ProjectSurfaceCatalog(presets: [_catalog().presets.first]),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Aucune animation disponible.'), findsOneWidget);
    expect(
      find.text('Générez d’abord les animations depuis l’atlas.'),
      findsOneWidget,
    );
  });
}

Widget _wrap(Widget child) {
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: Material(
        child: SingleChildScrollView(
          child: Center(child: child),
        ),
      ),
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  return ProjectSurfaceCatalog(
    animations: [
      _animation('anim-cross', 'Water Cross', column: 0),
      _animation('anim-horizontal', 'Water Horizontal', column: 1),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'anim-cross',
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectSurfaceCatalog _duplicateCatalog() {
  final catalog = _catalog();
  return ProjectSurfaceCatalog(
    animations: catalog.animations,
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'anim-cross',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.horizontal,
              animationId: 'anim-cross',
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectSurfaceAnimation _animation(
  String id,
  String name, {
  required int column,
}) =>
    ProjectSurfaceAnimation(
      id: id,
      name: name,
      timeline: SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'atlas',
              column: column,
              row: 0,
            ),
            durationMs: 100,
          ),
        ],
      ),
    );

```
### `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

```dart
// Tests widget — Surface Studio panel (Lot 52).
// Imports `map_core` en API publique uniquement (pas de `map_core/src/...`).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';

void main() {
  group('SurfaceStudioPanel (Lot 52)', () {
    testWidgets('1. title Surface Studio is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('2. read-only badge is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      // Bandeau panneau + inspecteur (Lot 59).
      expect(find.text('Lecture seule'), findsNWidgets(2));
    });

    testWidgets('3. three counters are zero for empty catalog', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
    });

    testWidgets('4. empty catalog shows empty state copy', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('5. minimal catalog shows 1/1/1', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets('6. non-empty shows catalog browser content', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });

    testWidgets('7. clean diagnostics for minimal coherent catalog',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('8. warning state when unused atlas', (tester) async {
      final rm = _warningReadModel();
      expect(rm.hasWarnings, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      // Atlas orphelin + animation non référencée par un preset (presets vides)
      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
      expect(find.text('Atlas inutilisé'), findsOneWidget);
      expect(find.text('Animation inutilisée'), findsOneWidget);
    });

    testWidgets('9. error state when preset animation missing', (tester) async {
      final rm = _errorReadModel();
      expect(rm.hasErrors, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
      expect(
        find.text('Animation manquante dans un preset'),
        findsOneWidget,
      );
    });

    testWidgets('10. future action label import visible (pas Créer un atlas)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
        findsOneWidget,
      );
    });

    testWidgets('11. future import action disabled (onPressed null)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final b = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(b.onPressed, isNull);
    });

    testWidgets('12. section placeholder titles are visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Actions auteur'), findsOneWidget);
    });

    testWidgets('13. SurfaceStudioPanelFromManifest uses manifest catalog',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets('14. manifest is not mutated after pump', (tester) async {
      final cat = _minimalWaterCatalog();
      final before = cat.atlases.length;
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(manifest.surfaceCatalog.atlases.length, before);
    });

    testWidgets(
      '15. does not require provider setup — panel builds without ProviderScope',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurfaceStudioPanel(readModel: _emptyReadModel()),
            ),
          ),
        );
        expect(find.text('Surface Studio'), findsOneWidget);
      },
    );

    testWidgets('16. content is in a scrollable', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('17. no internal domain type names in user-visible strings',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });

    testWidgets('18. error read model does not throw on build', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. warning read model does not throw on build',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _warningReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. displayed counts match read model summary',
        (tester) async {
      final rm = _minimalWaterReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(rm.summary.atlasCount, 1);
      expect(rm.summary.animationCount, 1);
      expect(rm.summary.presetCount, 1);
    });

    testWidgets(
        '22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
          matching: find.byType(TextField),
        ),
        findsWidgets,
      );
    });

    testWidgets('23. no save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.textContaining('Sauvegarder'), findsNothing);
      expect(find.textContaining('Enregistrer'), findsNothing);
      expect(find.textContaining('Save'), findsNothing);
    });

    testWidgets('22. panel shows catalog browser for minimal catalog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
    });

    testWidgets('24. test file uses public map_core only (smoke)',
        (tester) async {
      // Vérification statique : seul `package:map_core/map_core.dart` est importé.
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('25. Lot 55 — clean diagnostics view in panel', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('26. Lot 55 — error diagnostics visible in panel',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Erreurs'), findsOneWidget);
    });

    testWidgets('27. Lot 55 — browser and diagnostics cohabit (minimal cat)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });

    testWidgets(
        '48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('58.21 — Aucune sélection au départ (catalogue minimal)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets('58.22 — sélection atlas après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(find.text('Atlas sélectionné'), findsWidgets);
      expect(find.text('water-atlas'), findsWidgets);
    });

    testWidgets('58.23 — sélection animation après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      expect(find.text('water-isolated-loop'), findsWidgets);
    });

    testWidgets('58.24 — sélection preset après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(find.text('Preset sélectionné'), findsWidgets);
      expect(find.text('water-surface'), findsWidgets);
    });

    testWidgets('58.25 — changement de sélection remplace la précédente',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      final t = tester
          .widgetList<Text>(find.byType(Text))
          .map((e) => e.data ?? '')
          .join('\n');
      expect(t.contains('Atlas sélectionné'), isFalse);
    });

    testWidgets('58.26 — sélection ne mute pas surfaceCatalog', (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets('58.27 — pas de TextField dans inspecteur après sélections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Modifier',
        'Supprimer',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('59.20 — inspecteur none au départ', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
    });

    testWidgets('59.21 — inspecteur atlas après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
          find.descendant(of: insp, matching: find.text('Inspecteur Surface')),
          findsOneWidget);
      expect(
        find.descendant(of: insp, matching: find.text('Atlas sélectionné')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-atlas'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.22 — inspecteur animation après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-isolated-loop'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.23 — inspecteur preset après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-surface'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.24 — changement de sélection met l’inspecteur à jour',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-isolated-loop'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: insp,
          matching: find.text('Atlas sélectionné'),
        ),
        findsNothing,
      );
    });

    testWidgets('59.25 — inspecteur ne mute pas le manifest', (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets(
        '59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    testWidgets('59.27 — pas de libellés édition/save (Lot 59)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Modifier',
        'Supprimer',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets('60.1 — Préparation atlas (brouillon) visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(find.text('Atlas source').first);
      expect(find.text('Atlas source'), findsWidgets);
      expect(
        find.textContaining('Brouillon : rien n’est écrit sur le disque'),
        findsOneWidget,
      );
    });

    testWidgets('61.1 — action création atlas dans le catalogue de travail',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(
        find.text('Créer l’atlas dans le catalogue de travail'),
      );
      expect(
        find.text('Créer l’atlas dans le catalogue de travail'),
        findsOneWidget,
      );
    });

    testWidgets(
        '61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, '
        'inspecteur', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot61-a');
      await tester.enterText(nameF, 'Lot61 A');
      await tester.enterText(tsF, 'tileset-x');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(2),
      );
      expect(find.text('Lot61 A'), findsWidgets);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets(
        '61.3 — créer second atlas : compteur 2, animations/presets inchangés',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'grass-a');
      await tester.enterText(nameF, 'Grass');
      await tester.enterText(tsF, 'ts-g');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(2),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
      expect(find.text('grass-a'), findsWidgets);
    });

    testWidgets('62.0 — pas de dirty au départ (vide + minimal)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
    });

    testWidgets('62.1 — dirty après création locale', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'dirty-a');
      await tester.enterText(nameF, 'D');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(
        find.textContaining('sauvegarde projet non effectuée'),
        findsWidgets,
      );
    });

    testWidgets(
        '62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'rs-a');
      await tester.enterText(nameF, 'R');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsOneWidget,
      );
      expect(find.text('rs-a'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets(
        '62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'grass-x');
      await tester.enterText(nameF, 'Grass');
      await tester.enterText(tsF, 'ts');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('grass-x'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
    });

    testWidgets('62.4 — A puis B puis reset (source vide)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      for (final row in <String>['lot62-a', 'lot62-b']) {
        final idF = find.byKey(const ValueKey('atlas_draft_id'));
        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
        final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
        await tester.ensureVisible(idF);
        await tester.enterText(idF, row);
        await tester.enterText(nameF, row);
        await tester.enterText(tsF, 't');
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.tap(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.pump();
      }
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('lot62-a'), findsWidgets);
      expect(find.text('lot62-b'), findsWidgets);
      expect(find.text('Aucune sélection'), findsNothing);
      expect(find.text('Atlas sélectionné'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('62.5 — readModel parent change : resync, dirty off, X absent',
        (tester) async {
      final w = _wrap(
        SurfaceStudioPanel(readModel: _emptyReadModel()),
      );
      await tester.pumpWidget(w);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'ext-x');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(find.text('ext-x'), findsWidgets);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(readModel: _minimalWaterReadModel()),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets(
        '62.6 — pas d’action fantôme Créer un atlas, vraie action présente',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text('Créer l’atlas dans le catalogue de travail'),
        findsOneWidget,
      );
    });

    testWidgets('62.7 — no save flow libellés interdits', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('atlas_draft_id')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('atlas_draft_id')),
        'z',
      );
      await tester.enterText(
          find.byKey(const ValueKey('atlas_draft_name')), 'N');
      await tester.enterText(
          find.byKey(const ValueKey('atlas_draft_tileset_advanced')), 'T');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder le projet',
        'Enregistrer le projet',
        'Sauvegarder maintenant',
        'Save project',
        'Write to disk',
        'Écrire sur disque',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });
  });

  group('SurfaceStudioPanel (Lot 63)', () {
    testWidgets(
        '63.1 — sans modification : pas d’action préparation, callback jamais',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) => calls++,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepActionLabel),
        findsNothing,
      );
      expect(calls, 0);
    });

    testWidgets(
        '63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé',
        (tester) async {
      ProjectSurfaceCatalog? received;
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) {
              calls++;
              received = c;
            },
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'prep-one');
      await tester.enterText(nameF, 'P');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      expect(prep, findsOneWidget);
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(calls, 1);
      expect(received, isNotNull);
      expect(received!.atlases.length, 1);
      expect(received!.atlases.first.id, 'prep-one');
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsOneWidget,
      );
    });

    testWidgets(
        '63.3 — sans callback : stable, message not connected, pas de bouton',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'nccb');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.text(SurfaceStudioPanel.savePrepNotConnectedNote),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
        findsNothing,
      );
    });

    testWidgets('63.4 — resync parent : dirty off, atlas source, pas d’accusé',
        (tester) async {
      ProjectSurfaceCatalog? out;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) => out = c,
          ),
        ),
      );
      var idF = find.byKey(const ValueKey('atlas_draft_id'));
      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
      var tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'sync-x');
      await tester.enterText(nameF, 'S');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(out, isNotNull);
      final synced = buildSurfaceStudioReadModelFromCatalog(out!);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: synced,
            onSurfaceCatalogSaveRequested: (c) => out = c,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsNothing,
      );
      expect(find.text('sync-x'), findsWidgets);
    });

    testWidgets('63.5 — reset après préparation : clean, accusé nettoyé, vide',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      var idF = find.byKey(const ValueKey('atlas_draft_id'));
      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
      var tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'reset-p');
      await tester.enterText(nameF, 'R');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsNothing,
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('63.6 — A puis B puis préparation : ordre des atlas',
        (tester) async {
      ProjectSurfaceCatalog? got;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) => got = c,
          ),
        ),
      );
      for (final row in <(String, String, String)>[
        ('lot63-a', 'A', 'ta'),
        ('lot63-b', 'B', 'tb'),
      ]) {
        final idF = find.byKey(const ValueKey('atlas_draft_id'));
        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
        final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
        await tester.ensureVisible(idF);
        await tester.enterText(idF, row.$1);
        await tester.enterText(nameF, row.$2);
        await tester.enterText(tsF, row.$3);
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.tap(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.pump();
      }
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(got, isNotNull);
      expect(got!.atlases.length, 2);
      expect(got!.atlases[0].id, 'lot63-a');
      expect(got!.atlases[1].id, 'lot63-b');
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
    });

    testWidgets('66.1 — header compact et repères workflow visibles',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_workflow_header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_workflow_steps')),
        findsOneWidget,
      );
    });

    testWidgets(
        '66.2 — préparation atlas au-dessus du catalogue (ordre vertical)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final yPrep = tester
          .getTopLeft(
            find.byKey(const ValueKey('surface_studio_authoring_main_title')),
          )
          .dy;
      final yCat = tester.getTopLeft(find.text('Catalogue Surface')).dy;
      expect(yPrep, lessThan(yCat));
    });

    testWidgets('66.3 — bandeau dirty visible si catalogue de travail modifié',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'x');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('surface_studio_catalog_status_strip')),
        findsOneWidget,
      );
    });

    testWidgets('66.4 — inspecteur, catalogue, diagnostics toujours présents',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('66.5 — pas de libellés techniques dans l’UI principale',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceAtlas'), findsNothing);
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(find.textContaining('copyWith'), findsNothing);
    });

    testWidgets('85.1 — workflow guidé Surface Studio visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      expect(
        find.text(
            'Créer des surfaces peintes à partir d’un atlas, étape par étape.'),
        findsOneWidget,
      );
      expect(find.text('1. Atlas'), findsOneWidget);
      expect(find.text('2. Grille'), findsOneWidget);
      expect(find.text('3. Animations'), findsOneWidget);
      expect(find.text('4. Surfaces prêtes à peindre'), findsOneWidget);
      expect(find.text('Assistant de création'), findsOneWidget);
      expect(find.text('Ce que vous faites ici'), findsOneWidget);
      expect(find.text('Atlas source'), findsWidgets);
      expect(find.text('Découpage et validation'), findsOneWidget);
      expect(find.text('Animations détectées'), findsOneWidget);
      expect(find.text('Surfaces prêtes à peindre'), findsWidgets);
    });

    testWidgets(
        '85.2 — animations présentes sans surfaces peignables : état explicite',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _animationsOnlyReadModel())),
      );

      expect(
        find.text('Animations détectées, mais aucune surface peignable.'),
        findsOneWidget,
      );
      expect(
        find.text('Créez une surface à partir des animations générées.'),
        findsOneWidget,
      );
    });

    testWidgets('85.3 — surfaces peignables listées dans le panneau dédié',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      final panel = find.byKey(
        const ValueKey('surface_studio_paintable_surfaces_panel'),
      );
      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text('Water Surface')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('Peignable')),
        findsOneWidget,
      );
    });

    testWidgets('85.4 — CTA création surface et sauvegarde visibles',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );

      expect(find.text('Créer une surface'), findsOneWidget);
      expect(find.text('Sauvegarder le catalogue'), findsOneWidget);
    });

    testWidgets('85-bis.1 — workflow desktop en quatre zones côte à côte',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      final grid =
          find.byKey(const ValueKey('surface_studio_workflow_desktop_grid'));
      final assistant =
          find.byKey(const ValueKey('surface_studio_workflow_assistant_lane'));
      final atlas =
          find.byKey(const ValueKey('surface_studio_workflow_atlas_lane'));
      final animations =
          find.byKey(const ValueKey('surface_studio_workflow_animations_lane'));
      final surfaces =
          find.byKey(const ValueKey('surface_studio_workflow_surfaces_lane'));
      final advanced =
          find.byKey(const ValueKey('surface_studio_advanced_details'));

      expect(grid, findsOneWidget);
      expect(assistant, findsOneWidget);
      expect(atlas, findsOneWidget);
      expect(animations, findsOneWidget);
      expect(surfaces, findsOneWidget);
      expect(advanced, findsOneWidget);

      final assistantLeft = tester.getTopLeft(assistant).dx;
      final atlasLeft = tester.getTopLeft(atlas).dx;
      final animationsLeft = tester.getTopLeft(animations).dx;
      final surfacesLeft = tester.getTopLeft(surfaces).dx;
      expect(assistantLeft, lessThan(atlasLeft));
      expect(atlasLeft, lessThan(animationsLeft));
      expect(animationsLeft, lessThan(surfacesLeft));

      final workflowTop = tester.getTopLeft(grid).dy;
      expect(
        (tester.getTopLeft(assistant).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(atlas).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(animations).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(surfaces).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(tester.getTopLeft(advanced).dy, greaterThan(workflowTop));
    });

    testWidgets(
        '88-bis.1 — modifier le mapping met le catalogue de travail dirty et sauvegardable',
        (tester) async {
      ProjectSurfaceCatalog? saved;
      await tester.binding.setSurfaceSize(const Size(1600, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _roleMappingCatalog(),
            ),
            onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
          ),
        ),
      );

      final editButton =
          find.byKey(const ValueKey('surface_paintable_edit_mapping_water'));
      await tester.ensureVisible(editButton);
      expect(find.text('Modifier le mapping visuel'), findsOneWidget);
      await tester.tap(editButton);
      await tester.pump();

      expect(find.text('Édition du mapping de surface'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('surface_role_slot_endNorth')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_role_column_card_water-horizontal')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('surface_role_column_card_water-horizontal')),
      );
      await tester.pump();

      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );

      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();

      expect(saved, isNotNull);
      expect(
        saved!
            .presetById('water')!
            .animationIdForRole(SurfaceVariantRole.endNorth),
        'water-horizontal',
      );
      expect(
        saved!
            .presetById('water')!
            .animationIdForRole(SurfaceVariantRole.horizontal),
        'water-horizontal',
      );
    });
  });

  group('SurfaceStudioPanel (Lot 67–69)', () {
    testWidgets('67–68.1 — édition nom atlas, dirty, compteurs stables',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('atlas_draft_name')),
        'Renamed Water',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
      );
      await tester.pump();
      expect(find.text('Renamed Water'), findsWidgets);
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets(
        '67–68.2 — création atlas avec sélection animation : sélection inchangée',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'z2');
      await tester.enterText(nameF, 'Z2');
      await tester.enterText(tsF, 't2');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
    });

    testWidgets('69.1 — atlas utilisé : pas de préparation suppression',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _warningReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final usedLine = find.textContaining('used-atlas');
      await tester.ensureVisible(usedLine.first);
      await tester.tap(usedLine.first);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
        findsNothing,
      );
    });

    testWidgets('69.2 — atlas inutilisé : supprimer et sélection nettoyée',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _warningReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final orphanLine = find.textContaining('orphan-atlas');
      await tester.ensureVisible(orphanLine.first);
      await tester.tap(orphanLine.first);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
      );
      await tester.pump();
      expect(find.textContaining('orphan-atlas'), findsNothing);
      expect(find.text('Aucune sélection'), findsOneWidget);
    });
  });

  group('SurfaceStudioPanel (Lot 64)', () {
    testWidgets(
        '64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(ProjectSurfaceCatalog()),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot64-a');
      await tester.enterText(nameF, 'L');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.manifestMemoryUpdatedNote),
        findsOneWidget,
      );
      expect(find.text('lot64-a'), findsWidgets);
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsWidgets,
      );
    });

    testWidgets('64.2 — onProjectManifestChanged une fois, atlas dans manifest',
        (tester) async {
      var calls = 0;
      late ProjectManifest out;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(
              ProjectSurfaceCatalog(),
            ),
            onProjectManifestChanged: (m) {
              calls++;
              out = m;
            },
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'cb-one');
      await tester.enterText(nameF, 'C');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pump();
      expect(calls, 1);
      expect(out.surfaceCatalog.atlases.length, 1);
      expect(out.surfaceCatalog.atlases.first.id, 'cb-one');
      expect(out.name, 'Test');
    });

    testWidgets('64.3 — onProjectManifestChanged absent : pas d’exception',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(ProjectSurfaceCatalog()),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'nccb64');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '64.4 — changement de manifest parent externe (FromManifest) : resync',
        (tester) async {
      const extKey = ValueKey<String>('lot64_from_manifest');
      final a = _manifest(ProjectSurfaceCatalog());
      final b = _manifest(
        _minimalWaterCatalog(),
      );
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            key: extKey,
            manifest: a,
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'orph');
      await tester.enterText(nameF, 'O');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            key: extKey,
            manifest: b,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  // MacosApp + thème sombre : même [EditorChrome] que l’éditeur réel.
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: child,
    ),
  );
}

SurfaceStudioReadModel _emptyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
}

SurfaceStudioReadModel _minimalWaterReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
}

SurfaceStudioReadModel _warningReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
}

SurfaceStudioReadModel _animationsOnlyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
}

SurfaceStudioReadModel _errorReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithMissingAnimation());
}

SurfaceAtlasGeometry _geom() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _roleMappingCatalog() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );

  ProjectSurfaceAnimation animation(String id, String name, int column) {
    return ProjectSurfaceAnimation(
      id: id,
      name: name,
      timeline: SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'water-atlas',
              column: column,
              row: 0,
            ),
            durationMs: 120,
          ),
        ],
      ),
    );
  }

  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [
      animation('water-cross', 'Water Cross', 0),
      animation('water-horizontal', 'Water Horizontal', 1),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water Surface',
        categoryId: 'water',
        sortOrder: 3,
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'water-cross',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.horizontal,
              animationId: 'water-horizontal',
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = _geom();
  final used = ProjectSurfaceAtlas(
    id: 'used-atlas',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final unused = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'O',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'a',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, unused],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogWithMissingAnimation() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'missing-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      ),
    ],
  );
}

ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: catalog,
  );
}

```
